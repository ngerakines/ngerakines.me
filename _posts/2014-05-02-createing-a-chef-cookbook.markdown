---
layout: post
title: Creating a Chef Cookbook
category: posts
---

**This is a work in progress.**

This blog post is going to walk through the creation of ths s3ninja cookbook.

 * I started an open source project called [Tram](https://github.com/ngerakines/tram), a daemon that caches HTTP resources.
 * On of the features of Tram is that it supports S3 buckets for data storage.
 * In an effort to create an integration and development environment, I wanted to simulate S3. I found s3ninja and it looks like a good fit.
 * Because I use vagrant for local development and testing, I wanted a way to quickly create and destroy a mock s3 endpoint with s3ninja.

# Step 1: Knowing what the desired outcome is

 * A cookbook that allows us to install and interact with s3ninja.
 * Support for Ubuntu 12.04, Ubuntu 13.10, Centos 5.8 and Centos 6.5
 * Unit tests with chefspec
 * Integration tests with serverspec

# Step 2: Creating the cookbook

 * To create this application cookbook, I used `berks cookbook s3ninja` and renamed the directory to "s3ninja-chef-cookbook"
 * I like having recipes split into purpose/intent.
   * The "app" recipe sets up the application user, group, working directory and unpacks the application package.
     * I like the pattern of having a user/group for applications.
     * The home directory for the user is where our application will be unpacked.
     * Note that I include the "apt" and "yum" recipes without making any distinction as to which OS may or may not be used.
     * Because the s3ninja application is a java website, I need to make sure a JVM is installed. By default, the java cookbook installs jdk6, but I need jdk7, so I set the proper attribute before including the java recipe.
     * The application package is hosted as a release on github. Installing the application is just a matter of downloading and extracting the application in the user home directory.
   * The "deployment" recipe sets up deployment components like the init script and service.
     * This application has it's own start/stop script, so I have a very small init script that makes calls to it.
     * The service definition is simple and references the init.d script.

# Step 3: Unit tests with ChefSpec

 * I only recently started using chefspec and love it. The biggested feature is that it allows me to ensure that changes to the cookbook are expected and explicit.
 * In the `spec/recipes/` directory, I create xxx_spec.rb files for each of my recipes.
 * In each test file, I have a map that contains the platform and versions that I want to mock.
 * Each block of the recipe corrosponding to the test file has a brief description and then expect rules for.

# Step 4: Integration tests with ServerSpec

 * Even though this cookbook is going to be used as a component of another cookbook's tests, I still need to make sure that everything is setup and working properly.
 * Using kitchen, I have a list of platforms that I want to run integration tests against.
 * Integration test files are kept in the `test/integration/default/serverspec/localhost/` directory.
 * I only have one integration test file, s3ninja_spec.rb. Because this application is fairly simple, I'm only really checking two things:
   * That configuration and setup is correct (i.e. Does home directory have the expected files?)
   * That the service is functional (i.e. Can I upload a file to a bucket and then retreive the file?)

# Developing against this cookbook

When working on tram, I've got two sets of tests. Normal unit tests and then integration tests. Integration tests are enabled and run when the `test.integration` flag is set while running `go test`.

    $ go test -test.integration

The integration tests assume that s3 service can be accessed, using a simple host override in the configuration on the localhost on port 9444. To expose the service to my host, I use the `kitchen converge default-ubuntu-1310` command to bootstrap an instance of Ubuntu 13.10 running s3ninja. The only change needed is the following kitchen configuration to have host (my osx laptop) forward requests on port 9444 to the service running inside of the vm.

# Summary

Writing cookbooks is a lot easier than you think. It only took about an hour to crank this one out and I'm pretty happy with the results.

To make this cookbook better, I'd consider the following:

 * In the `files/default` directory are upload and get bash scripts that are only used during integration tests. I'd like to move those into a test cookbook contained in the test directory.
 * The s3ninja application supports external configuration through a file in the working directory of the application. Attributes should exist that match the defaults and an option to set configuration values would be a nice touch.
 * Creating unit and integration tests to make sure the correct version of java was installed and is being used by the service.

