---
title: "GitHub Actions in Rust"
date: "2023-04-14"
---

Rust is a great language to create GitHub actions. In this post, I'll walk through how I created the [ngerakines/pr-has-issues-action](https://github.com/ngerakines/pr-has-issues-action) GitHub action.

For some context, I wanted a lightweight way to validate the content of a PR, specifically to ensure that the title and body are both not empty and contain at least on issue prefix. For example, if I were to create a PR with the title "Support account creation", I would want to ensure that the title contains at least one issue prefix, such as "ISSUE-1 Support account creation".

There are a few different ways to implement github actions with inputs, outputs, and environment variables. I wanted to keep this as simple as possible so I'm only looking at the GitHub action context associated with the triggering event. The expectation is that this action is used with `pull_request` events, so I'm looking for the `number`, `pull_request.title`, and `pull_request.body` values of that payload.

That event data is passed to the context as a mounted file and the `GITHUB_EVENT_PATH` environment variable provides the location to that JSON file. Because the action is just interacting with the file system, I can keep the number of dependencies low and the produced binary small.

Next is the action descriptor file at the root of the repository.

```yaml
name: 'PR Has Issues'
description: 'Checks for issues references in pull requests.'
inputs:
  prefixes:
    description: A comma separated list of key prefixes.
    required: true
runs:
  using: 'docker'
  image: 'ghcr.io/ngerakines/pr-has-issues-action:v3'
  args:
    - ${{ inputs.prefixes }}
```

You'll notice a couple of things here. First, the `runs.image: ...` value isn't simply `Dockerfile` as the GitHub documentation says, but instead is a reference to a container image. When I release a version, I'm first doing a build and push to [ghcr.io](https://ghcr.io/). If I didn't do that, each time the action is referenced, it would build it from scratch. This keeps it down to 2-3 seconds instead of 2-3 minutes.

One other thing that needs to be done, that may not be obvious is to ensure that the ghcr package that you've published is public. You'll need to nvagiate to the package from the repository and change the visibility from private (default) to public. If you don't do this, you'll get an error that the container doesn't exist when the action is used.

That's it! Pull requests and feedback is welcome.
