---
title: "Kubernetes Consul Mutator"
date: "2023-04-11"
---

Earlier this year, I ran into an interesting problem at work where we wanted to be able to restart pods across multiple deployments when a specific Consul key changed. I went through a couple of ideas with the team, and the one that I landed on was having a small Kubernetes operator that would watch for changes and then update the deployments, triggering a rolling restart.

Although this isn't a unique problem, I didn't immediately find any existing solutions that would work for us. It was also a good opportunity to roll of my sleeves and introduce some rust to our tech stack. I've been using rust in some personal projects, so I was excited to get to use it at work.

At a high level, the daemon was going to do several things:

* Track the relationship between deployments and the consul keys that impact them.
* Watch for changes to consul keys and update relevant deployments.

The way that I decided to do this was with Kubernetes annotations. When a deployment resource is created with a `k8s-consul-mutator.io/key-*` annotation, the deamon tracks that deployment/key relationship. When a change is detected in the consul key, the daemon updates the deployment with the annotations `k8s-consul-mutator.io/checksum-*` and `k8s-consul-mutator.io/last-updated` which triggers the rolling restart.

This turn into the following requirements:

* Deployments can be created, updated, and deleted, so the daemon needs to be able to handle all of these cases. When deployments are updated or deleted, their associated consul key watches need to be created or removed accordingly.
* When the daemon restarts, it needs to learn about existing deployments to spin up watches for them. That implies that it shouldn't attempt to re-write annotations on deployments that have correct and accurate checksums already.
* Deployments may care about multiple consul keys, so per-deployment references to keys may vary.
* Consul keys may be updated multiple times relatively quickly, so the daemon needs to debounce changes to avoid unnecessary churn.

What this practically looks like is a Rust Kubernetes operator and mutating admission controller that has async workers to watch for consul changes and implement deployement change actions.

I started by creating [github.com/ngerakines/k8s-consul-mutator-rs](https://github.com/ngerakines/k8s-consul-mutator-rs) as an axum web application that uses the tokio, k8s-openapi, and kube crates to listen for incoming deployment resource events both as an admission hook and as a Kubernetes resource watcher. I really like how the kube library is structured and the feature system allows for listening to events like `kube::runtime::watcher::Event::Deleted` and `kube::runtime::watcher::Event::Applied` in a generic way that lets you build against different Kubernetes versions.

Internally, there is a `KeyManager` trait that is used to abstract the storage layer that tracks deployments and their configuration. The default implementation is `MemoryKeyManager` and keeps values in-memory, but I'm confident that a Redis implementation would be pretty easy to write.

As the daemon starts up, the async Kubernetes operator listening to cluster events kicks off and the Axum HTTP server listens for and processes admission controller events. Additionally, a background loop starts that manages consul watch threads. This manager is responsible for both creating and destroy consul watch events as deployments are created, updated, and deleted. The `consulrs` crate is used in this area of the application.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  annotations:
    k8s-consul-mutator.io/key-config: app/config
```

The above annotation for the app deployment would result in the following mutation.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  annotations:
    k8s-consul-mutator.io/key-config: app/config
    k8s-consul-mutator.io/checksum-config: md5-e80ca0bfa6b0c57f6360e22f1aebabc5
    k8s-consul-mutator.io/last-updated: 2023-02-17T21:51:13.479453+00:00
spec:
  template:
    metadata:
      annotations:
        k8s-consul-mutator.io/checksum-config: md5-e80ca0bfa6b0c57f6360e22f1aebabc5
        k8s-consul-mutator.io/last-updated: 2023-02-17T21:51:13.479453+00:00
```

The README includes all of the configuration options and the TESTING instructions go through full end-to-end testing instructions using minikube.

This project is open source under the MIT license and is available at: https://github.com/ngerakines/k8s-consul-mutator-rs
