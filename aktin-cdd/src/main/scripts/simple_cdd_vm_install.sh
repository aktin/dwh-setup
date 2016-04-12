#!/usr/bin/env bash

${install_root1}
${install_root2}

MY_PATH=$install_root
CDD_PATH=


# install needed packages
apt-get update
apt-get install -y sudo wget curl dos2unix unzip sed bc simple-cdd 

