############################################
############################################
###                                      ###
###   Docker                             ###
###                                      ###
###   An Alpine container that enables   ###
###   everything to run                  ###
###                                      ###
############################################
############################################

FROM python:2.7-alpine

MAINTAINER Simon Emms <simon@slashdevslashnull.it>

# Create a deploy user
RUN adduser -D -u 1000 deploy

# Set the work directory and add the project files to it
WORKDIR /opt/deploy
ADD . /opt/deploy

# Environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV AWS_ACCESS_KEY=
ENV AWS_BASE_AMI_ID="eu-west-1=ami-405f7226"
ENV AWS_KEY_PAIR=
ENV AWS_REGION="eu-west-1"
ENV AWS_SECRET_KEY=
ENV TERRAFORM_MANAGER_INSTANCES=
ENV TERRAFORM_WORKER_INSTANCES=
ENV TERRAFORM_REMOTE_S3_BUCKET_KEY=
ENV TERRAFORM_REMOTE_S3_BUCKET_NAME=
ENV TERRAFORM_REMOTE_S3_BUCKET_REGION=
ENV TERRAFORM_ACCESS_KEY=
ENV TERRAFORM_SECRET_KEY=

ENV CPU_TYPE=amd64
ENV PACKER_VERSION="1.0.0"
ENV TERRAFORM_VERSION="0.9.2"

####################################
####################################
###                              ###
###   Install the dependencies   ###
###                              ###
####################################
####################################

# Install Ansible
RUN apk --update add sudo groff \
  && apk --update add openssl ca-certificates \
  && apk --update add --virtual \
    build-dependencies \
    python-dev \
    libffi-dev \
    openssl-dev \
    build-base \
    sshpass \
    openssh-client \
  && pip install --upgrade pip cffi \
  && pip install ansible \
  && mkdir -p /etc/ansible

# Install Packer
RUN apk add --no-cache --virtual curl \
  && curl -SLO "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${CPU_TYPE}.zip" \
  && curl -SLO "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" \
  && grep " packer_${PACKER_VERSION}_linux_${CPU_TYPE}.zip\$" packer_${PACKER_VERSION}_SHA256SUMS | sha256sum -c - \
  && unzip "packer_${PACKER_VERSION}_linux_${CPU_TYPE}.zip" -d  /bin \
  && rm "packer_${PACKER_VERSION}_linux_${CPU_TYPE}.zip" "packer_${PACKER_VERSION}_SHA256SUMS"

# Install Terraform
RUN apk add --no-cache --virtual curl \
  && curl -SLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${CPU_TYPE}.zip" \
  && curl -SLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
  && grep " terraform_${TERRAFORM_VERSION}_linux_${CPU_TYPE}.zip\$" terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c - \
  && unzip "terraform_${TERRAFORM_VERSION}_linux_${CPU_TYPE}.zip" -d /bin \
  && rm "terraform_${TERRAFORM_VERSION}_linux_${CPU_TYPE}.zip" "terraform_${TERRAFORM_VERSION}_SHA256SUMS"

# Install AWSCLI
RUN pip install awscli

# Create SSH key
RUN su - deploy -c "ssh-keygen -f /home/deploy/.ssh/id_rsa -t rsa -N \"\" "

# Check versions
# https://github.com/mitchellh/packer/issues/3370
RUN ansible --version \
  && packer --version || true \
  && terraform --version || true \
  && aws --version

# Use the deploy user
USER deploy

CMD [ "sh", "scripts/run.sh" ]
