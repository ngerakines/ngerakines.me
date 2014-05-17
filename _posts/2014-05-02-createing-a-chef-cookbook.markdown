---
layout: post
title: Creating a Chef Cookbook
---


In May, I wrote a cookbook for the [s3ninja](https://github.com/scireum/s3ninja) project and wanted to share the how I go about writing application cookbooks. This cookbook is primarily used to test another project that I'm working on, [tram](https://github.com/ngerakines/tram). In the tram cookbook, I include this cookbook for use in the cookbook integration tests, so this is an interesting use case for an application that can stand on it's own as well as be included in an application stack if needed.

# Step 1: What are we creating here?

There are a few things that I wanted to get out of this:

1. An application cookbook that can be used to release the s3ninja application
2. Support for both Centos and Ubuntu
3. Cookbook unit tests
4. Cookbook integration tests

My local cookbook development environment is pretty simple. I've got Ruby 1.9.3 installed through RVM as well as the chef, berkshelf, foodcritic, test-kitchen, rspec and chefspec gems. I'm also using a somewhat recent version of VirtualBox.

For this project, chef and berkshelf are required for general cookbook development and testing. Foodcritic is used as a sanity checking tool to make sure my cookbooks don't contain anything that is too far from the generally accepted development patterns used by the community. For unit testing I'll be using chefspec and for integration testing I'll be using test-kitchen and serverspec to create test suites that can be executed against different OS configurations.

# Step 2: Creating the cookbook

With the development environment configured and ready, I started by creating a new cookbook using berkshelf:

```bash
$ cd ~/development/ngerakines
$ berkshelf cookbook s3ninja
$ mv s3ninja s3ninja-chef-cookbook
```

This cookbook exists outside of the s3ninja project for a few reasons, the primary one being that I'm not the maintainer of the s3ninja project and I'm not sure that they use chef. Alternatively, I would place the cookbook in the "cookbooks/s3ninja" directory within the s3ninja project repository.

What the `berkshelf cookbook s3ninja` command does is create a new directory with the cookbook's name and places a skeleton cookbook within it. Within that cookbook are a few key files to note and update:

```ruby
name             's3ninja'
maintainer       'Nick Gerakines'
maintainer_email 'nick@gerakines.net'
license          'MIT'
description      'Installs/Configures s3ninja'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'yum', '~> 3.2.0'
depends 'apt', '~> 2.3.10'
depends 'java', '~> 1.22.0'

supports 'centos', '>= 5.8'
supports 'ubuntu', '>= 12.04'
```

In the above `metadata.rb` file, you can see what the cookbook name is, who maintains it, the version and then what cookbooks it depends on and what operating systems it supports. This file is important because it is used to define and describe the cookbook.

In the `attributes/default.rb` file, I'm going to list all attributes specific to the cookbook and application. In this cookbook we just have one so far, the source location of the s3ninja package.

```ruby
default[:s3ninja][:package_source] = "https://github.com/ngerakines/s3ninja/releases/download/latest/s3ninja.zip"
```

Next we have our `Berksfile` file. This file is used by berkshelf to describe where and how the cookbook dependencies are retrieved by berkshelf.

```ruby
site :opscode

metadata

cookbook 'apt'
cookbook 'yum'
cookbook 'java'
```

This cookbook uses community cookbooks, so this file doesn't have to contain anything special.

As for recipes, the `recipes/default.rb` is going to be our entry point to the application cookbook and should provide everything that falls under the "sane defaults" category of cookbook work. In this case, that work would be to make sure the application's dependencies are installed, the application unpacked and services defined. When writing cookbooks, I write recipes to align with intent, so we'll break things out into "app" and "deployment" recipes.

With that, our `recipes/default.rb` file is going to simply include the app and deployment recipes:

```ruby
include_recipe 's3ninja::app'
include_recipe 's3ninja::deployment'
```

The `recipes/app.rb` is going to do the heavy lifting of fetching the prepare the s3ninja application environment, s3ninja package, unpack it and configure it. The first thing that is done is include the dependant recipes and set any attributes needed.

```ruby
include_recipe 'apt::default'
include_recipe 'yum::default'

node.default['java']['jdk_version'] = 7

include_recipe 'java::default'
```

In this case, we include the apt, yum and java default recipes. Before the `java::default` recipe is included, we want to ensure that Java 7 is installed because the s3ninja application package is compiled against it. Even though this recipe is going to be running against both Centos and Ubuntu environments, we are including both the apt and yum default recipes. We rely on them to intelligently exclude themselves from running if the node doesn't support them.

Next we want to create the s3ninja user, group and prepare the directories that house the unpacked application.

```ruby
user 's3ninja' do
  username 's3ninja'
  home '/home/s3ninja'
  action :remove
  action :create
  supports ({ :manage_home => true })
end

group 's3ninja' do
  group_name 's3ninja'
  members 's3ninja'
  action :remove
  action :create
end

package 'unzip' do
  action :install
end
```

Next, we fetch the release package, unpackage it and then do any follow-up tasks. In this case, we want to make sure that permissions are correct for the application files.

```ruby
remote_file "#{Chef::Config[:file_cache_path]}/s3ninja.zip" do
  source node[:s3ninja][:package_source]
end

bash 'extract_app' do
  cwd '/home/s3ninja/'
  code <<-EOH
    unzip #{Chef::Config[:file_cache_path]}/s3ninja.zip
    EOH
  not_if { ::File.exists?('/home/s3ninja/sirius.sh') }
end

execute 'chown -R s3ninja:s3ninja /home/s3ninja/'

file '/home/s3ninja/sirius.sh' do
  mode 00777
end
```

There are a few things going on here that aren't great. The first is that we are installing unzip and then use a bash block to unzip the downloaded archive. Ideally, we'd use a cookbook recipe that can unpack the zip file that contains the application. We then follow up with an execution of the `chown` command to ensure that everything inside the home directory is owned by the s3ninja user and group. The `/home/s3ninja/sirius.sh` is also re-permissioned incase it was packaged or unpackaged in a way that looses the execute permission.

Next, the `recipes/deployment.rb` recipe file will create and place the init script as well as define the s3ninja service.

```ruby
template '/etc/init.d/s3ninja' do
  source 's3ninja-init.erb'
  mode 0777
  owner 'root'
  group 'root'
end

service 's3ninja' do
  provider Chef::Provider::Service::Init
  action [:start]
end
```

# Step 3: Unit tests with ChefSpec

Chefspec is a set of rpsec extensions that let cookbook authors quickly test that their cookbook is doing everything as expected. It also has the ability to show you what parts of your cookbook aren't covered with tests.

The chefspec test files reside in the `spec/recipes` directory within the cookbook project and have a file suffix of `_spec.rb`. What I like to do is have one test file for each recipe in the cookbook.

* spec/recipes/default_spec.rb
* spec/recipes/app_spec.rb
* spec/recipes/deployment_spec.rb

Each test file includes platform version mocking, and ends up looking like this:

```ruby
require 'chefspec'
require 'chefspec/berkshelf'
ChefSpec::Coverage.start!

platforms = {
  "ubuntu" => ['12.04', '13.10'],
  "centos" => ['5.9', '6.5']
}

describe 's3ninja::recipe' do
  platforms.each do |platform_name, platform_versions|
    platform_versions.each do |platform_version|
      context "on #{platform_name} #{platform_version}" do

        let(:chef_run) do
          ChefSpec::Runner.new(platform: platform_name, version: platform_version) do |node|
            node.set['lsb']['codename'] = 'foo'
          end.converge('s3ninja::recipe')
        end

        ## Test code goes here.

      end
    end
  end
end

```

For the `spec/recipes/default_spec.rb` file, we want to make sure that it is simply including the `s3ninja::app` and `s3ninja::deployment` recipes with the following test code:

```ruby
it 'Includes dependent receipes' do
  expect(chef_run).to include_recipe('s3ninja::app')
  expect(chef_run).to include_recipe('s3ninja::deployment')
end
```

The `spec/recipes/app_spec.rb` file is a bit longer, but includes all of the actions of the app recipe:

```ruby
it 'includes dependent receipes' do
  expect(chef_run).to include_recipe('apt::default')
  expect(chef_run).to include_recipe('yum::default')
  expect(chef_run).to include_recipe('java::default')
end

it 'creates the user and groups' do
  expect(chef_run).to create_user('s3ninja')
  expect(chef_run).to create_group('s3ninja')
end

it 'installs required packages' do
  expect(chef_run).to install_package('unzip')
end

it 'downloads and unpacks the application package' do
  expect(chef_run).to create_remote_file('/var/chef/cache/s3ninja.zip')
  expect(chef_run).to run_bash('extract_app')
  expect(chef_run).to run_execute('chown -R s3ninja:s3ninja /home/s3ninja/')
  expect(chef_run).to create_file('/home/s3ninja/sirius.sh')
end
```

The `spec/recipes/deployment_spec.rb` has similar code, but again, verifies the actions of the deployment recipe:

```ruby
it 'places the init script and starts the service' do
  expect(chef_run).to create_template('/etc/init.d/s3ninja')
  expect(chef_run).to start_service('s3ninja')
end
```

The tests can be run using the `rspec` command:

```bash
$ rspec
........................

Finished in 1.65 seconds
24 examples, 0 failures

ChefSpec Coverage report generated...

  Total Resources:   9
  Touched Resources: 9
  Touch Coverage:    100.0%

You are awesome and so is your test coverage! Have a fantastic day!


ChefSpec Coverage report generated...

  Total Resources:   9
  Touched Resources: 9
  Touch Coverage:    100.0%

You are awesome and so is your test coverage! Have a fantastic day!


ChefSpec Coverage report generated...

  Total Resources:   9
  Touched Resources: 9
  Touch Coverage:    100.0%

You are awesome and so is your test coverage! Have a fantastic day!
```

# Step 4: Integration tests with ServerSpec

Even though this cookbook is going to be used as a component of another cookbook's tests, I still need to make sure that everything is setup and working properly. With test-kitchen, we can configure different operating systems (platforms) and test suites and it will execute each permutation.

The first thing to do is update the `.kitchen.yml` file with the platforms that we want the integration tests to run on. In this case, we want to ensure that the cookbook works on ubuntu 12.04, ubuntu 13.10, centos 6.5 and centos 5.8.

```yaml
---
driver:
  name: vagrant

provisioner:
  name: chef_solo

platforms:
  - name: ubuntu-12.04
  - name: ubuntu-13.10
  - name: centos-6.5
  - name: centos-5.8
    driver:
      box_url: https://dl.dropbox.com/u/17738575/CentOS-5.8-x86_64.box

suites:
  - name: default
    run_list:
      - recipe[s3ninja::default]
    attributes:
```

Then we create some test files to execute. In this project, I have all of the integration test logic in the `test/integration/default/serverspec/localhost/s3ninja_spec.rb` file:

```ruby
require 'spec_helper'

describe 's3ninja' do

  describe 'app' do

    describe file('/home/s3ninja') do
      it { should be_directory }
    end

    describe file('/home/s3ninja/sirius.sh') do
      it { should be_file }
      it { should be_executable }
    end

  end

  describe 'service' do

    describe file('/etc/init.d/s3ninja') do
      it { should be_file }
    end

    describe port(9444) do
      it { should be_listening }
    end

  end

end
```

In it, we ensure that the application directory and startup script both exist. Then we ensure that the init script used to start the service exists, that the service is listening on the default port and several test commands complete successfully. Personally, I like doing minimal application testing within the cookbook integration test to ensure everything is working as expected.

To run integration tests, I use the `kitchen` command to view and run them.

```bash
$ kitchen list
Instance             Driver   Provisioner  Last Action
default-ubuntu-1204  Vagrant  ChefSolo     <Not Created>
default-ubuntu-1310  Vagrant  ChefSolo     <Not Created>
default-centos-65    Vagrant  ChefSolo     <Not Created>
default-centos-58    Vagrant  ChefSolo     <Not Created>
$ kitchen test
-----> Starting Kitchen (v1.2.1)
-----> Cleaning up any prior instances of <default-ubuntu-1204>
-----> Destroying <default-ubuntu-1204>...
       Finished destroying <default-ubuntu-1204> (0m0.00s).
-----> Testing <default-ubuntu-1204>
-----> Creating <default-ubuntu-1204>...
       Bringing machine 'default' up with 'virtualbox' provider...
       [default] Importing base box 'opscode-ubuntu-12.04'...
...
s3ninja       
  app       
    File "/home/s3ninja"       
      should be directory       
    File "/home/s3ninja/sirius.sh"       
      should be file       
      should be executable       
  service       
    File "/etc/init.d/s3ninja"       
      should be file       
    Port "9444"       
      should be listening       
       
       Finished in 0.04707 seconds
5 examples, 0 failures       
       Finished verifying <default-centos-58> (0m1.46s).
-----> Destroying <default-centos-58>...
       [default] Forcing shutdown of VM...
       [default] Destroying VM and associated drives...
       Vagrant instance <default-centos-58> destroyed.
       Finished destroying <default-centos-58> (0m2.36s).
       Finished testing <default-centos-58> (17m46.48s).
-----> Kitchen is finished. (28m30.02s)
```

# Tieing things off

There are a few additional files used by the cookbook and tests, so take a look at the [s3ninja-chef-cookbook](https://github.com/ngerakines/s3ninja-chef-cookbook) to see a complete picture of what it looks like. To see how this cookbook is being used, check out the [tram-chef-cookbook](https://github.com/ngerakines/tram-chef-cookbook). In it, I have this cookbook being referenced in an embedded test cookbook for integration testing.
