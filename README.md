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
  - `ami_groups`: Defaults to "_all_" (publicly visible)
  - `ami_name`: Defaults to "_docker-17.03-ce_"
  - `description`: Defaults to "_Ubuntu 16.04, Docker 17.03-ce_"
  - `name`: Defaults to "_Ubuntu Docker_"
  - `region`: Defaults to "_eu-west-1_"
  - `source_ami`: Defaults to "_ami-405f7226_"
  - `ssh_username`: Defaults to "_ubuntu_"
    
## Terraform

This provisions the number of different machines to run the stack.

### Apply

This will create or update the instances:

    terraform apply \
        -var access_key=<access_key> \
        -var secret_key=<secret_key>

### Destroy

This will destroy all the instances:

    terraform destroy \
        -var access_key=<access_key> \
        -var secret_key=<secret_key>

### Remote State

Storing the remote state enables this to be shared by a team or done from a continuous integration box. **IMPORTANT:**
this will not create the S3 bucket. This must be done manually beforehand.

You can store the remote state in S3 quite easily by running the following command:

    terraform remote config \
        -backend=s3 \
        -backend-config="bucket=<s3_bucket_name>" \
        -backend-config="key=<s3_file_name>" \
        -backend-config="region=<aws_region>" \
        -backend-config="access_key=<access_key>" \
        -backend-config="secret_key=<secret_key>"
