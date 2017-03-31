# AWS Swarm Deploy

Automated deployment to a Docker Swarm cluster on AWS

## Packer

This builds the Amazon Machine Image (AMI). This is the base image for installing software. This will be publicly
visible by default.

 - Ubuntu 16.04
 - Docker CE 17.03.0
 - Docker Compose 1.11.2
 
To run:

    packer build \
        -var 'aws_access_key=<access_key>' \
        -var 'aws_secret_key=<secret_key>' \
        base/base.json
        
### Options

  - `aws_access_key` **REQUIRED** 
  - `aws_secret_key` **REQUIRED**
  - `ami_name`: Defaults to "_docker-17.03-ce_"
  - `description`: Defaults to "_Ubuntu 16.04, Docker 17.03-ce_"
  - `name`: Defaults to "_Ubuntu Docker_"
  - `region`: Defaults to "_eu-west-1_"
  - `source_ami`: Defaults to "_ami-405f7226_"
  - `ssh_username`: Defaults to "_ubuntu_"
