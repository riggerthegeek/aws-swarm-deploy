#!/usr/bin/env sh

###########################################################
###########################################################
###                                                     ###
###   Run                                               ###
###                                                     ###
###   This is a series of scripts that manage how       ###
###   to set up a Swarm cluster. It builds a base       ###
###   image using Packer (if nothing present or         ###
###   current one too old), then provisions the AWS     ###
###   boxes using Terraform. Finally, it configures     ###
###   the Swarm cluster and deploys the Docker images   ###
###   using Ansible                                     ###
###                                                     ###
###########################################################
###########################################################

errExit () {

  if [ $1 \> 0 ]; then
    echo "Script exited with $1"
    exit $1
  fi
}

if [ -z $AWS_KEY_PAIR ]; then
  echo "Please provide a KEY_PAIR"
  exit 1
fi

# Configure AWS
aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
aws configure set output "json"
aws configure set region "$AWS_REGION"

##################
##################
###            ###
###   Packer   ###
###            ###
##################
##################

echo "Creating a new AMI with Packer"

rm -Rf ./packer/tmp
mkdir -p ./packer/tmp
cp ./packer/base/base.sh ./packer/tmp

python ./scripts/generate_packer_file.py
errExit $?

# Validate the Packer stuff
packer validate ./packer/tmp/base.json

# Now run the Packer stuff
packer build ./packer/tmp/base.json -machine-readable | tee ./packer-build.out

AMI_LIST=$(python ./scripts/get_ami_id.py ./packer-build.out)

rm -Rf ./packer-build.out ./packer/tmp

echo "Packer step done"

#####################
#####################
###               ###
###   Terraform   ###
###               ###
#####################
#####################

echo "Provisioning the AWS instances using Terraform"

# Use main AWS vars if not set
if [ -z $TERRAFORM_ACCESS_KEY ]; then
  TERRAFORM_ACCESS_KEY="$AWS_ACCESS_KEY"
fi

if [ -z $TERRAFORM_SECRET_KEY ]; then
  TERRAFORM_SECRET_KEY="$AWS_SECRET_KEY"
fi

if [ -z $TERRAFORM_REMOTE_S3_BUCKET_REGION ]; then
  TERRAFORM_REMOTE_S3_BUCKET_REGION="$AWS_REGION"
fi

# This is where we'll come back to

# Configure the AWS variables
TF_DIR="$PWD/terraform/swarm"
TFVARS_FILE="$TF_DIR/terraform.tfvars"

rm -rf "$TF_DIR"
mkdir -p "$TF_DIR"

rm -Rf "$TFVARS_FILE" "$TF_DIR/.terraform"

echo "bucket = \"$TERRAFORM_REMOTE_S3_BUCKET_NAME\"" >> "$TFVARS_FILE"
echo "key = \"$TERRAFORM_REMOTE_S3_BUCKET_KEY\"" >> "$TFVARS_FILE"
echo "region = \"$TERRAFORM_REMOTE_S3_BUCKET_REGION\"" >> "$TFVARS_FILE"
echo "access_key = \"$TERRAFORM_ACCESS_KEY\"" >> "$TFVARS_FILE"
echo "secret_key = \"$TERRAFORM_SECRET_KEY\"" >> "$TFVARS_FILE"

# Generate the Terraform modules
python ./scripts/generate_terraform_modules.py "$TF_DIR" "$AMI_LIST"

# Initialise Terraform - can't get this to work correctly in Python script
(cd "$TF_DIR"; terraform init -input=false -get=true -backend=true -backend-config="$TFVARS_FILE")
errExit $?

# Run the Terraform stuff
python ./scripts/terraform.py "$TF_DIR" "$AMI_LIST"
errExit $?

echo "Terraform step done"

###################
###################
###             ###
###   Ansible   ###
###             ###
###################
###################

echo "Setting up Docker Swarm with Ansible"

# This is not immediately connectible
sleep 30

ANSIBLE_HOSTS="./ansible/hosts"

# Generate the hosts file
python ./scripts/generate_host_file.py "$ANSIBLE_HOSTS" "$AWS_KEY_PAIR" "swarm"
errExit $?

# Configure the Swarm
ansible-playbook -i "$ANSIBLE_HOSTS" ./ansible/playbooks/swarm.yml
errExit $?

echo "Ansible step done"
