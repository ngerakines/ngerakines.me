---
layout: post
title: Terraform, Docker Swarm, and AWS
---

This is a guide to using Terraform to create docker swarm clusters (swarm mode, *not* swarm engine) in AWS. The goal that I started out with was to have a single terraform configuration set that would automatically bring up a docker swarm cluster. I've also added some example configuration for lighting up services within that cluster once it is created.

## Requirements

Before you start, you'll need both packer and terraform installed locally.

    $ terraform --version
    Terraform v0.7.10
    $ packer --version
    0.12.0

You'll also need AWS credentials either set as environment variables for both terraform and packer to read or configured with the AWS command line tool.

Lastly, this guide assumes you have an SSH key in the environment you are creating the cluster in. Please check for references to the `foo` SSH key in the  configuration in this guide and replace it with your own.

## Terraform Variables

To start, create a file called `variables.tf` and put the following configuration inside of it. In this guide, I'm using **us-west-2**, so be aware of where that region is referenced.

```
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "vpc_key" {
  description = "A unique identifier for the VPC."
  default     = "nickg"
}

variable "cluster_manager_count" {
    description = "Number of manager instances for the cluster."
    default = 1
}

variable "cluster_node_count" {
    description = "Number of node instances for the cluster."
    default = 3
}
```

## VPC Configuration

I like to use VPCs as a way of isolating environments and resources. The first thing I do is create some configuration for all of the vpc/environment infrastructure. VPCs also provide some added security and force you to think through access controls. Using Terraform, creating VPC configuration is relatively painless.

```
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.vpc_key}-ig"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_network_acl" "network" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [
    "${aws_subnet.a.id}",
    "${aws_subnet.b.id}",
    "${aws_subnet.c.id}"
  ]

  ingress {
    from_port = 0
    to_port = 0
    rule_no = 100
    action = "allow"
    protocol = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port = 0
    to_port = 0
    rule_no = 100
    action = "allow"
    protocol = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags {
    Name = "${var.vpc_key}-network"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "${var.vpc_key}-route"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_route_table_association" "a" {
  route_table_id = "${aws_route_table.main.id}"
  subnet_id = "${aws_subnet.a.id}"
}

resource "aws_route_table_association" "b" {
  route_table_id = "${aws_route_table.main.id}"
  subnet_id = "${aws_subnet.b.id}"
}

resource "aws_route_table_association" "c" {
  route_table_id = "${aws_route_table.main.id}"
  subnet_id = "${aws_subnet.c.id}"
}

resource "aws_subnet" "a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block,8,1)}"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.vpc_key}-a"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_subnet" "b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block,8,2)}"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.vpc_key}-b"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_subnet" "c" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block,8,3)}"
  availability_zone = "${var.aws_region}c"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.vpc_key}-c"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.25.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    VPC = "${var.vpc_key}"
    Name = "${var.vpc_key}-vpc"
    Terraform = "Terraform"
  }
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "vcp_cidr_1" {
  value = "${cidrhost(aws_vpc.vpc.cidr_block,1)}"
}
output "vcp_cidr_sub_1" {
  value = "${cidrsubnet(aws_vpc.vpc.cidr_block,8,1)}"
}

output "vpc_subnet_a" {
  value = "${aws_subnet.a.id}"
}
output "vpc_subnet_b" {
  value = "${aws_subnet.b.id}"
}
output "vpc_subnet_c" {
  value = "${aws_subnet.c.id}"
}
```

The above configuration belongs in a file named `provider.tf`. With it, the VPC, along with subnets, routes, and gateways are created and a few variables made available to `terraform output`.

Next, we'll create a security group for our cluster. Normally, I'd recommend creating multiple security groups that are port specific (i.e. `sg.http.tf` would be a security group that exports ports 80, 8080, and 443.), but because swarm clusters may have a variety of services running on them, you can easily hit the 5 security group limit on EC2 instances. Instead, put the following configuration into a file named `swarm-sg.tf`.

```
resource "aws_security_group" "swarm" {
  name        = "${var.vpc_key}-sg-swarm"
  description = "Security group for swarm cluster instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
      from_port   = 2375
      to_port     = 2377
      protocol    = "tcp"
      cidr_blocks = [
        "${aws_vpc.vpc.cidr_block}"
      ]
  }

  ingress {
      from_port   = 7946
      to_port     = 7946
      protocol    = "tcp"
      cidr_blocks = [
        "${aws_vpc.vpc.cidr_block}"
      ]
  }

  ingress {
      from_port   = 7946
      to_port     = 7946
      protocol    = "udp"
      cidr_blocks = [
        "${aws_vpc.vpc.cidr_block}"
      ]
  }

  ingress {
      from_port   = 4789
      to_port     = 4789
      protocol    = "tcp"
      cidr_blocks = [
        "${aws_vpc.vpc.cidr_block}"
      ]
  }

  ingress {
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      cidr_blocks = [
        "${aws_vpc.vpc.cidr_block}"
      ]
  }

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  tags {
    Name = "${var.vpc_key}-sg-swarm"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

output "sg_swarm" {
  value = "${aws_security_group.swarm.id}"
}
```

In the above configuration, there are a handful of rules defined.

* The egress (outbound) rule allows for instances in the security group to make outgoing connections to any IP addresses on any port.
* TCP connections made to ports 2375 through 2377 can be made from any instance within the VPC. These ports are used by docker and are **insecure**, so we want to prevent outside access to them. The reason the insecure docker port is used is explained later in this guide.
* TCP and UDP connections to 7946 and then TCP connections to 4789 are also possible from instances within the VPC. These ports are used by docker for cluster management.
* TCP connections to ports 22, 80, and 443 can be made from any IP address.

I'm a fan of using bastion servers, so I'm going to add a few steps to create one. The security group for that EC2 instance allows outbound connections and inbound SSH connections. The following configuration should be put into a file named `bastion-sg.tf`.

```
resource "aws_security_group" "bastion" {
  name        = "${var.vpc_key}-sg-bastion"
  description = "Security group for bastion instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  tags {
    Name = "${var.vpc_key}-sg-bastion"
    VPC = "${var.vpc_key}"
    Terraform = "Terraform"
  }
}

output "sg_bastion" {
  value = "${aws_security_group.bastion.id}"
}
```

A quick run of `terraform plan` should show 12 resources to be added.

```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_internet_gateway.main
...
+ aws_network_acl.network
...
+ aws_route_table.main
...
+ aws_route_table_association.a
...
+ aws_route_table_association.b
...
+ aws_route_table_association.c
...
+ aws_security_group.bastion
...
+ aws_security_group.swarm
...
+ aws_subnet.a
...
+ aws_subnet.b
...
+ aws_subnet.c
...
+ aws_vpc.vpc
...
Plan: 12 to add, 0 to change, 0 to destroy.
```

Our 12 resources are ready and the next step is to run `terraform apply`.

```
$ terraform apply
...
aws_route_table_association.a: Creation complete
aws_route_table_association.b: Creation complete
aws_route_table_association.c: Creation complete
aws_network_acl.network: Creation complete

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

sg_bastion = sg-11a68368
sg_swarm = sg-1ea68367
vcp_cidr_1 = 10.25.0.1
vcp_cidr_sub_1 = 10.25.1.0/24
vpc_id = vpc-6d8b4b0a
vpc_subnet_a = subnet-ff0def98
vpc_subnet_b = subnet-86dcd8f0
vpc_subnet_c = subnet-f3d3a5ab
```

## Docker AMI

Now, we are going to switch gears a little and turn to packer to make the rest of the process a little easier. The following packer configuration describes the build and setup process for an AMI that is based on Ubuntu 16.10 that has docker installed, configured, and ready to use.

```
{
  "builders": [
    {
      "ami_name": "docker-swarm {{timestamp}}",
      "ami_virtualization_type": "hvm",
      "associate_public_ip_address": "true",
      "instance_type": "t2.small",
      "region": "us-west-2",
      "source_ami_filter": {
        "filters": {
          "name": "*ubuntu-yakkety-16.10-amd64-server-*",
          "root-device-type": "ebs",
          "virtualization-type": "hvm"
        },
        "most_recent": true
      },
      "ssh_username": "ubuntu",
      "subnet_id": "subnet-ff0def98",
      "tags": {
        "OS_Version": "Ubuntu",
        "Release": "16.10"
      },
      "type": "amazon-ebs",
      "security_group_ids": ["sg-11a68368"]
    }
  ],
  "post-processors": null,
  "provisioners": [
    {
      "destination": "/tmp/docker.options",
      "source": "docker.options",
      "type": "file"
    },
    {
      {% assign vars = '{{ .Vars }}' %}{% assign path = '{{ .Path }}' %}"execute_command": "{{ vars }} sudo -E sh '{{ path }}'",
      "inline": [
        "apt-get install -y aptitude",
        "aptitude -y update",
        "aptitude install -y docker docker-compose unzip",
        "mv /tmp/docker.options /etc/default/docker",
        "systemctl enable docker.service",
        "usermod -aG docker ubuntu"
      ],
      "type": "shell"
    }
  ]
}

```

In the above file, `docker.json`, a new AMI is defined that installs some packages and uploads a docker options file. The reason I do this extra step is because performing package installation for each instance with terraform can be slow and sometimes inconsistent. When using this for your own images, be sure to change the **subnet_id** and **security\_group\_ids** attributes to the outputted **vpc\_subnet\_a** and **sg_bastion** values. The reason we use the bastion security group is packer must be able to remote in via SSH and then fetch packages from package repositories.

```
DOCKER_OPTS=-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
```

The above block is the contents of the `docker.options` file. This file is used by the docker daemon on startup to ensure that the daemon is accessible both through the insecure 2375 port as well as the `/var/run/docker.sock` unix pipe.

Create the AMI using the `packer` executable:

```
$ packer build docker.json
amazon-ebs output will be in this color.

==> amazon-ebs: Prevalidating AMI Name...
    amazon-ebs: Found Image ID: ami-cbd276ab
==> amazon-ebs: Creating temporary keypair: packer_5831ec0d-07df-fdcb-a57c-cd4629838918
==> amazon-ebs: Launching a source AWS instance...
    amazon-ebs: Instance ID: i-e884067d
==> amazon-ebs: Waiting for instance (i-e884067d) to become ready...
==> amazon-ebs: Waiting for SSH to become available...
==> amazon-ebs: Connected to SSH!
==> amazon-ebs: Uploading docker.options => /tmp/docker.options
==> amazon-ebs: Provisioning with shell script: /var/folders/w8/pm2dt6252rs86wc8zsn_70sh0000gn/T/packer-shell852678079
    amazon-ebs: Reading package lists...
    ...
==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: docker-swarm 1479666701
    amazon-ebs: AMI: ami-1a6cc07a
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Adding tags to AMI (ami-1a6cc07a)...
    amazon-ebs: Adding tag: "OS_Version": "Ubuntu"
    amazon-ebs: Adding tag: "Release": "16.10"
==> amazon-ebs: Tagging snapshot: snap-f90080ae
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

us-west-2: ami-1a6cc07a
```

The process of creating the AMI can take a few minutes, your mileage may vary.

To make this process even better, create a throw-away VPC with a subnet and security group ahead of time. The instance type of the AMI we are building requires that the instance used to create the AMI inside of a VPC, but it can be any VPC and does not have to be the one we plan on deploying it to.

If it isn't obvious, once you create the AMI for one VPC, you can use the same AMI in other VPC configurations provided they are in the same region.

## Bastion Setup

Next we can go back to creating Terraform configuration for the bastion and docker swarm instances.

```
resource "aws_instance" "bastion" {
    ami = "ami-1a6cc07a"
    instance_type = "t2.small"
    count = "1"
    associate_public_ip_address = "true"
    key_name = "foo"
    subnet_id = "${aws_subnet.a.id}"
    vpc_security_group_ids = [
      "${aws_security_group.bastion.id}"
    ]

    root_block_device = {
      volume_size = 10
    }

    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/foo")}"
      agent = false
    }

    tags {
      Name = "${var.vpc_key}-bastion"
      VPC = "${var.vpc_key}"
      Terraform = "Terraform"
    }
}

output "bastion_host" {
  value = "${aws_instance.bastion.public_dns}"
}
```

Put the contents of the above configuration block into the file `bastion.tf`. The bastion host is a **t2.small** because it is only used as a gateway to run commands within the VPC. The bastion host is also a good candidate for installing VPN software (open VPN).

```
$ terraform plan
...
Plan: 1 to add, 0 to change, 0 to destroy.
```

The output of `terraform plan` should confirm that there is one resource being added.

```
terraform apply
aws_vpc.vpc: Refreshing state... (ID: vpc-6d8b4b0a)
aws_subnet.c: Refreshing state... (ID: subnet-f3d3a5ab)
...
aws_instance.bastion: Creating...
...
aws_instance.bastion: Still creating... (10s elapsed)
aws_instance.bastion: Still creating... (20s elapsed)
aws_instance.bastion: Still creating... (30s elapsed)
aws_instance.bastion: Creation complete

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

bastion_host = ec2-35-162-132-222.us-west-2.compute.amazonaws.com
sg_bastion = sg-11a68368
sg_swarm = sg-1ea68367
vcp_cidr_1 = 10.25.0.1
vcp_cidr_sub_1 = 10.25.1.0/24
vpc_id = vpc-6d8b4b0a
vpc_subnet_a = subnet-ff0def98
vpc_subnet_b = subnet-86dcd8f0
vpc_subnet_c = subnet-f3d3a5ab
```

The **bastion_host** variable should now be available in the output. Next we create our docker swarm cluster.

## Swarm Setup

The next and final step is to create the configuration for our swarm managers and nodes. Be sure to update the `ami` attributes with the id of your own AMI.

```
resource "aws_instance" "swarm-manager" {
    ami = "ami-1a6cc07a"
    instance_type = "t2.small"
    count = "${var.cluster_manager_count}"
    associate_public_ip_address = "true"
    key_name = "foo"
    subnet_id = "${aws_subnet.a.id}"
    vpc_security_group_ids      = [
      "${aws_security_group.swarm.id}"
    ]

    root_block_device = {
      volume_size = 100
    }

    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/foo")}"
      agent = false
    }

    tags {
      Name = "${var.vpc_key}-manager-${count.index}"
      VPC = "${var.vpc_key}"
      Terraform = "Terraform"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo docker swarm init"
      ]
    }

    depends_on = [
      "aws_instance.bastion"
    ]
}

resource "aws_instance" "swarm-node" {
    ami = "ami-1a6cc07a"
    instance_type = "t2.small"
    count = "${var.cluster_node_count}"
    associate_public_ip_address = "true"
    key_name = "foo"
    subnet_id = "${aws_subnet.a.id}"
    vpc_security_group_ids = [
      "${aws_security_group.swarm.id}"
    ]

    root_block_device = {
      volume_size = 100
    }

    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/foo")}"
      agent = false
    }

    tags {
      Name = "${var.vpc_key}-node-${count.index}"
      VPC = "${var.vpc_key}"
      Terraform = "Terraform"
    }

    provisioner "remote-exec" {
      inline = [
        "docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q worker)"
      ]
    }

    depends_on = [
      "aws_instance.swarm-manager"
    ]
}

resource "null_resource" "cluster" {
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.swarm-node.*.id)}"
  }

  connection {
    host = "${aws_instance.bastion.public_dns}"
    user = "ubuntu"
    private_key = "${file("~/.ssh/foo")}"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "docker -H ${element(aws_instance.swarm-manager.*.private_ip, 0)}:2375 network create --driver overlay appnet",
      "docker -H ${element(aws_instance.swarm-manager.*.private_ip, 0)}:2375 service create --name nginx --mode global --publish 80:80 --network appnet nginx"
    ]
  }
}

output "swarm_managers" {
  value = "${concat(aws_instance.swarm-manager.*.public_dns)}"
}

output "swarm_nodes" {
  value = "${concat(aws_instance.swarm-node.*.public_dns)}"
}

```

The above configuration is put into the file `swarm.tf`. There are a few tricks here that are worth pointing out.

* The **count** attribute is used for both the manager and node instance resources. With it, we can quickly scale up or down the swarm cluster size.
* The swarm manager is created first by having a **depends_on** block in the swarm node instance resource. This instructs Terraform to ensure all of the managers are created before attempting to create the node instances. The swarm manager also has a **depends_on** block that references the bastion instance. To see a graph of what configuration dependencies looks like, you can run `terraform graph | dot -Tpng > graph.png` provided you have the `dot` executable installed.
* When the manager instance is brought up, it will run `docker swarm init` to initialize a docker swarm and set itself as the manager. With the above configuration, each manager will attempt to initialize a swarm which probably isn't what you want. Instead, the initialization process for managers that are not manager 0 should be to join the first manager. Pull requests are welcome.
* When a node is brought up, it will attempt to join the cluster as a node. This is done through a little bit of trickery to first get the worker token from the docker manager using the insecure port 2375 and then join that manager on port 2377.
* Finally, a null resource is used to initialize the services in the newly create docker swarm cluster. In this example, a network is created and the nginx container deployed as a global service. Instead of ssh'ing into the manager or one of the notes, we use the bastion host previously created.

A quick run of `terraform plan` should show 5 resources being added.

```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.

aws_vpc.vpc: Refreshing state... (ID: vpc-6d8b4b0a)
...

+ aws_instance.swarm-manager
...
+ aws_instance.swarm-node.0
...
+ aws_instance.swarm-node.1
...
+ aws_instance.swarm-node.2
...
+ null_resource.cluster
...

Plan: 5 to add, 0 to change, 0 to destroy.
```

If everything looks good, wrap up by running `terraform apply`.

```
terraform apply
aws_vpc.vpc: Refreshing state... (ID: vpc-6d8b4b0a)
...
aws_instance.swarm-manager: Creating...
aws_instance.swarm-manager: Still creating... (30s elapsed)
aws_instance.swarm-manager: Provisioning with 'remote-exec'...
...
aws_instance.swarm-manager: Still creating... (1m20s elapsed)
aws_instance.swarm-manager (remote-exec): Connecting to remote host via SSH...
aws_instance.swarm-manager (remote-exec):   Host: 35.161.74.23
aws_instance.swarm-manager (remote-exec):   User: ubuntu
aws_instance.swarm-manager (remote-exec):   Password: false
aws_instance.swarm-manager (remote-exec):   Private key: true
aws_instance.swarm-manager (remote-exec):   SSH Agent: false
aws_instance.swarm-manager (remote-exec): Connected!
aws_instance.swarm-manager: Still creating... (1m30s elapsed)
aws_instance.swarm-manager: Still creating... (1m40s elapsed)
aws_instance.swarm-manager (remote-exec): Swarm initialized: current node (48zhf6irfztflzs8hayvh00de) is now a manager.
aws_instance.swarm-manager (remote-exec): To add a worker to this swarm, run the following command:
aws_instance.swarm-manager (remote-exec):     docker swarm join \
aws_instance.swarm-manager (remote-exec):     --token SWMTKN-1-1bv8qd5uhbbpsnvsldtdzrey9i1zjicdt7tl0vc19rd2gjatua-b4sj9z04bcoxma6y2mqa895b6 \
aws_instance.swarm-manager (remote-exec):     10.25.1.183:2377
aws_instance.swarm-manager (remote-exec): To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
aws_instance.swarm-manager: Creation complete
aws_instance.swarm-node.0: Creating...
...
aws_instance.swarm-node.2: Creating...
...
aws_instance.swarm-node.1: Creating...
...
aws_instance.swarm-node.2: Still creating... (1m20s elapsed)
aws_instance.swarm-node.2 (remote-exec): Connected!
aws_instance.swarm-node.1 (remote-exec): This node joined a swarm as a worker.
aws_instance.swarm-node.1: Creation complete
aws_instance.swarm-node.0 (remote-exec): This node joined a swarm as a worker.
aws_instance.swarm-node.0: Creation complete
aws_instance.swarm-node.2: Creation complete
null_resource.cluster: Creating...
...
null_resource.cluster: Provisioning with 'remote-exec'...
null_resource.cluster (remote-exec): Connecting to remote host via SSH...
null_resource.cluster (remote-exec):   Host: ec2-35-162-132-222.us-west-2.compute.amazonaws.com
null_resource.cluster (remote-exec):   User: ubuntu
null_resource.cluster (remote-exec):   Password: false
null_resource.cluster (remote-exec):   Private key: true
null_resource.cluster (remote-exec):   SSH Agent: false
null_resource.cluster (remote-exec): Connected!
null_resource.cluster (remote-exec): b9wf0tp83vffrvr75e1wyosck
null_resource.cluster (remote-exec): 9r8w1l62ndmed6ezn4j7dfzgg
null_resource.cluster: Creation complete

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

bastion_host = ec2-35-162-132-222.us-west-2.compute.amazonaws.com
sg_bastion = sg-11a68368
sg_swarm = sg-1ea68367
swarm_managers = [
    ec2-35-161-74-23.us-west-2.compute.amazonaws.com
]
swarm_nodes = [
    ec2-35-163-94-198.us-west-2.compute.amazonaws.com,
    ec2-35-160-137-242.us-west-2.compute.amazonaws.com,
    ec2-35-163-36-83.us-west-2.compute.amazonaws.com
]
vcp_cidr_1 = 10.25.0.1
vcp_cidr_sub_1 = 10.25.1.0/24
vpc_id = vpc-6d8b4b0a
vpc_subnet_a = subnet-ff0def98
vpc_subnet_b = subnet-86dcd8f0
vpc_subnet_c = subnet-f3d3a5ab
```

**KABOOM BABY**

And with that, the cluster is up and the nginx service is running. We can verify that the nginx container has started and is running by making an HTTP request to it on port 80.

```
$ curl -vvs ec2-35-163-94-198.us-west-2.compute.amazonaws.com | head -n 10
* Rebuilt URL to: ec2-35-163-94-198.us-west-2.compute.amazonaws.com/
*   Trying 35.163.94.198...
* Connected to ec2-35-163-94-198.us-west-2.compute.amazonaws.com (35.163.94.198) port 80 (#0)
> GET / HTTP/1.1
> Host: ec2-35-163-94-198.us-west-2.compute.amazonaws.com
> User-Agent: curl/7.49.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.11.5
< Date: Sun, 20 Nov 2016 19:11:27 GMT
< Content-Type: text/html
< Content-Length: 612
< Last-Modified: Tue, 11 Oct 2016 15:03:01 GMT
< Connection: keep-alive
< ETag: "57fcff25-264"
< Accept-Ranges: bytes
<
{ [612 bytes data]
* Connection #0 to host ec2-35-163-94-198.us-west-2.compute.amazonaws.com left intact
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
...
```

## Misc

I organize my configuration by having folders for VPCs as well as folders for clusters:

```
vpcs/nickg/
clusters/nickg-consul/
clusters/nickg-stuff/
```

Each cluster has its own tfstate, but that leads to referencing things like the ID of the VPC the cluster is deployed to. To resolve this, I run the following command to create a tf.json file that can be put into the folder of my cluster configuration.

    $ terraform output -json > output.json
    $ cd path/to/cluster/config
    $ cp ../path/to/output.json vpc-variables.json
    $ jo variable="$(cat vpc-variables.json | jq 'with_entries(.value |= {type: .type, default: .value})')" > vpc-variables.tf.json

This uses the [jo](https://github.com/jpmens/jo) and [jq](https://stedolan.github.io/jq/) tools to transform the output json into a format that terraform can use.

If you have any questions, feedback, or see a bug then please email me or message me on Twitter.
