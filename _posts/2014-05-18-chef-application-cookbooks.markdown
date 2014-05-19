---
layout: post
title: Chef Application Cookbooks
---

This is a follow up to the blog post [Creating A Chef Cookbook](http://ngerakines.me/2014/05/02/createing-a-chef-cookbook/). Since writing that blog post, I created the [preview](https://github.com/ngerakines/preview) project and several cookbooks for it. With it, I've done a few things differently and believe that they represent some notable trends in the chef community.

## Embed Application Cookbooks in Application Repositories

Instead of having a separate git repository for each cookbook, all of the cookbooks for the preview application are in the *preview* git repository in the 'cookbooks' directory. 

Practically, this doesn't change anything for the cookbook itself. In projects that reference this cookbook that use berkshelf, I have to update the Berksfile to point to the project repository and the subdirectory that contains the cookbook. When a cookbook is uploaded to a chef server, the location is irrelevant.

There is one thing that I do want to make very clear: The application build process doesn't build or prepare the cookbooks. The cookbooks are independently built, tested and released. I've seen projects where the cookbook is "generated" as part of the build process for the application and I feel strongly against that.

## Create Environment Cookbooks

To learn more about the environment cookbook pattern, read the [The Environment Cookbook Pattern](http://blog.vialstudios.com/the-environment-cookbook-pattern/) written by [Jamie Winsor](https://github.com/reset).

In addition to the primary "preview" application cookbook, I created an environment cookbook called "preview_prod". This cookbook is used to represent the default configuration, files and actions needed to release the preview application into a production-like environment.

When looking at environment cookbooks, it is really important to note that these don't contain node information and attributes, but rather represent what a configuration of the application cookbook looks like in a given environment.

In the case of the `preview_prod/metadata.rb` file, I list several attributes that are required by the cookbook:

```ruby
name             'preview_prod'
maintainer       'Nick Gerakines'
maintainer_email 'nick@gerakines.net'
license          'MIT'
description      'Installs/Configures preview_prod'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.2'

depends 'preview'

supports 'centos'

recipe 'preview_prod::node', 'Configures and prepares a preview application node.'
recipe 'preview_prod::storage', 'Configures and prepares a storage node.'

attribute 'preview_prod/node_id',
  :display_name => 'The id of the preview node.',
  :required => 'required',
  :type => 'string',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/cassandra_hosts',
  :display_name => 'The cassandra hosts used by the preview node.',
  :required => 'required',
  :type => 'array',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/edge_host',
  :display_name => 'The base url used to request assets from the cluster.',
  :required => 'required',
  :type => 'string',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/s3Key',
  :display_name => 'The S3 key used to store generated assets.',
  :required => 'required',
  :type => 'string',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/s3Secret',
  :display_name => 'The S3 secret key used to store generated assets.',
  :required => 'required',
  :type => 'string',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/s3Host',
  :display_name => 'The S3 host used to store generated assets.',
  :required => 'required',
  :type => 'string',
  :recipes => ['preview_prod::node']

attribute 'preview_prod/s3Buckets',
  :display_name => 'The S3 buckets used to store generated assets.',
  :required => 'required',
  :type => 'array',
  :recipes => ['preview_prod::node']
```

Even though the `preview_prod::node` and `preview_prod::storage` recipes describe how to create production-like preview cluster nodes separately, the `preview_pod::default` exists to allow engineers to deploy to a single, full-stack node. This follows the idea that the default recipe's purpose should be to represent the most common and simple use for engineers that are new to the cookbook.

In the `preview_prod::node` recipe, we are using the preview_prod required and unsatisfied attributes to override attributes that have default values in the `preview` cookbook:

```ruby
node.override[:preview][:config][:common][:nodeId] = normal[:preview_prod][:node_id]
node.override[:preview][:config][:storage][:engine] = 'cassandra'
node.override[:preview][:config][:storage][:cassandraKeyspace] = 'preview'
node.override[:preview][:config][:storage][:cassandraKeyspace] = normal[:preview_prod][:cassandra_hosts]
node.override[:preview][:config][:simpleApi][:edgeBaseUrl] = normal[:preview_prod][:edge_host]
node.override[:preview][:config][:uploader][:engine] = "s3"
node.override[:preview][:config][:uploader][:s3Key] = normal[:preview_prod][:s3Key]
node.override[:preview][:config][:uploader][:s3Secret] = normal[:preview_prod][:s3Secret]
node.override[:preview][:config][:uploader][:s3Host] = normal[:preview_prod][:s3Host]
node.override[:preview][:config][:uploader][:s3Buckets] = normal[:preview_prod][:s3Buckets]

include_recipe 'preview::default'
```

Your mileage may vary in terms of what a production cookbook should look like. The preview project is open source and public, but for internal environment cookbooks you may have default values or databag references for attribute values.

## Build Cookbook

This is another pattern that I'm using at work and really like: Creating a cookbook to bootstrap a development environment. Again, this is another take on the environment cookbook pattern

Specifically for this project, this cookbook installs the version of the golang compiler required to build the preview application as well as tools git. In the `preview_build/recipes/default.rb` file, this looks like:

```ruby
include_recipe 'golang::default'

node.default['go']['packages'] = ['github.com/gpmgo/gopm']

include_recipe 'golang::packages'
```

The preview project is open source and public, so I'm using travis-ci ([https://travis-ci.org/ngerakines/preview](https://travis-ci.org/ngerakines/preview)) to compile the application and run the short tests. The build cookbook pattern is useful if you've got a build environment and CI that has a build agent. The cookbook would be applied to the build agent and the `chef-client` command executed at the beginning of the build agent run to ensure that it is up to date.

For a disposable build environment, we can use environment variables to create a GOPATH dynamically:

```bash
GOPATH=gopath-`date +%s`
echo "export GOPATH=$GOPATH" > env-gopath
```

Then, your commands would look like:

    $ . path/to/env-gopath
    $ go get ./...
    $ go build
    $ go test ./... -test.short
    $ rm -rfv $GOPATH && env-gopath

Practically, it makes sense to use something like [gopm](https://github.com/gpmgo/gopm) to fetch specific versions of the packages used. The above script could be updated to use gopm instead

## Application Integration Test Cookbook

For this project, I took it one step further and created an additional cookbook called preview_test that contains recipes, configuration and files to run integration tests. This cookbook is still heavily in development as I'm using it to learn how to effectively use [chef-metal](https://github.com/opscode/chef-metal) and [kitchen-metal](https://github.com/doubt72/kitchen-metal). I'll put up another blog post when I've got something demonstrable.
