#!/usr/bin/env bash

##########################################################
##########################################################
###                                                    ###
###   Base                                             ###
###                                                    ###
###   This is a provisioning script that installs a    ###
###   base box with Docker on it                       ###
###                                                    ###
##########################################################
##########################################################

DOCKER_COMPOSE_VERSION=1.11.2
DOCKER_VERSION=17.03.0~ce-0~ubuntu-$(lsb_release -cs)

set -x # Print every command
set -u # Exit when a variable is unset
set -o # Exit if any pipe command fails
set -e # Exit on error

###########################
###########################
###                     ###
###   Install updates   ###
###                     ###
###########################
###########################
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

# Set locale to UK
sudo locale-gen en_GB.UTF-8

##########################################################################
##########################################################################
###                                                                    ###
###   Install Docker                                                   ###
###                                                                    ###
###   @link https://docs.docker.com/engine/installation/linux/ubuntu   ###
###                                                                    ###
##########################################################################
##########################################################################

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the stable Docker repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update repo
sudo apt-get update

# Install docker
sudo apt-get install -y "docker-ce=$DOCKER_VERSION"

# Create docker group
sudo groupadd docker || true

# Add current user to docker group
sudo usermod -aG docker "$USER"

# Install docker-compose
sudo curl -L \
    "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

# Configure docker to start on boot
sudo systemctl enable docker

# Clean up
sudo apt-get -y autoremove
sudo apt-get -y autoclean

# Reboot
sudo reboot
