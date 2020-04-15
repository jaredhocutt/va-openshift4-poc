#!/usr/bin/env bash

PARENT_DIR="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"

mkdir -p ${PARENT_DIR}/bin
cd ${PARENT_DIR}/bin

# echo
# echo "Downloading OpenShift installer and clients"
# echo

# curl -O http://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.8/openshift-client-linux-4.3.8.tar.gz
# curl -O http://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.8/openshift-install-linux-4.3.8.tar.gz
# tar xvf openshift-client-linux-4.3.8.tar.gz oc kubectl
# tar xvf openshift-install-linux-4.3.8.tar.gz openshift-install
# rm -f openshift-client-linux-4.3.8.tar.gz openshift-install-linux-4.3.8.tar.gz

echo
echo "Downloading Terraform"
echo

curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip
rm -f terraform_0.12.24_linux_amd64.zip

echo
echo
echo "##########################################################################"
echo
echo "The required dependencies have been updated. Update your PATH to use them:"
echo
echo "export PATH=${PARENT_DIR}/bin:\$PATH"
echo
echo "##########################################################################"
echo

