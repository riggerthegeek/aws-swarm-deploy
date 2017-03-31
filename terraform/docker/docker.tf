##########################
##########################
###                    ###
###   Backend Config   ###
###                    ###
##########################
##########################
terraform {
  required_version = ">= 0.9.0"
  backend "s3" {}
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

######################
######################
###                ###
###   Networking   ###
###                ###
######################
######################

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "docker-vpc"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}${var.availability_zone}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.default.id}"
}

###########################
###########################
###                     ###
###   Security groups   ###
###                     ###
###########################
###########################

resource "aws_security_group" "all_outgoing" {
  name = "all_outgoing_access"
  description = "Open all outgoing connections"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

#################################################################################################################
#################################################################################################################
###                                                                                                           ###
###   Create a security group Docker swarm                                                                    ###
###   @link https://docs.docker.com/engine/swarm/swarm-tutorial/#open-protocols-and-ports-between-the-hosts   ###
###                                                                                                           ###
#################################################################################################################
#################################################################################################################
resource "aws_security_group" "docker_swarm" {
  name = "docker_swarm_access"
  description = "Allow Docker swarm to access the VPC"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 2377
    to_port = 2377
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 7946
    to_port = 7946
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 7946
    to_port = 7946
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# Create a security group for HTTP access
resource "aws_security_group" "http" {
  name = "http_access"
  description = "Allow HTTP(S) access from anywhere"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# Create a security group for SSH access
resource "aws_security_group" "ssh" {
  name = "ssh_access"
  description = "Allow SSH access from anywhere"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

################################
################################
###                          ###
###   Create the instances   ###
###                          ###
################################
################################

# Docker Manager box(es)
resource "aws_instance" "docker_manager_instance" {
  ami = "${var.ami}"
  instance_type = "${lookup(var.manager_instance_types, count.index, var.base_instance)}"
  key_name = "${var.key_pair}"
  subnet_id = "${aws_subnet.default.id}"
  count = "${var.manager_instances}"
  vpc_security_group_ids = [
    "${aws_vpc.default.default_security_group_id}",
    "${aws_security_group.all_outgoing.id}",
    "${aws_security_group.docker_swarm.id}",
    "${aws_security_group.http.id}",
    "${aws_security_group.ssh.id}"
  ]
  tags = {
    Name = "${var.manager_name} ${count.index + 1}"
  }
}

# Docker Worker box(es)
resource "aws_instance" "docker_worker_instance" {
  ami = "${var.ami}"
  instance_type = "${lookup(var.worker_instance_types, count.index, var.base_instance)}"
  key_name = "${var.key_pair}"
  subnet_id = "${aws_subnet.default.id}"
  count = "${var.worker_instances}"
  vpc_security_group_ids = [
    "${aws_vpc.default.default_security_group_id}",
    "${aws_security_group.all_outgoing.id}",
    "${aws_security_group.docker_swarm.id}",
    "${aws_security_group.http.id}",
    "${aws_security_group.ssh.id}"
  ]
  tags = {
    Name = "${var.worker_name} ${count.index + 1}"
  }
}
