# Veterans Affairs (VA) OpenShift 4 PoC

## Setup

Download dependencies:

```bash
./scripts/download_dependencies.sh
```

Export `PATH` to include downloaded dependencies:

```bash
export PATH=$(pwd)/bin:$PATH
```

**TODO: Include directions for installing `pipenv`**

Setup your Python environment for Ansible:

```bash
pipenv install
```

Configure AWS profile:

```bash
aws configure --profile govcloud set aws_access_key_id YOUR_ACCESS_KEY
aws configure --profile govcloud set aws_secret_access_key YOUR_SECRET_KEY
aws configure --profile govcloud set region us-gov-west-1
```

## Create Infrastructure

Activate your Python environment:

```bash
pipenv shell
```

Export `AWS_PROFILE` and `AWS_REGION` to use:

```bash
export AWS_PROFILE=govcloud
export AWS_REGION=us-gov-west-1
```

Create a variable file at `vars/govcloud.yml`:

```yaml
---

openshift_version: 4.3.8

cluster_name: ocp43
base_domain: example.com

rhcos_ami: your_ami_id
keypair_name: default
keypair_path: ~/.ssh/path/to/key.pem

commercial_aws_access_key_id: your_access_key
commercial_aws_secret_access_key: your_secret_key
govcloud_aws_access_key_id: your_access_key
govcloud_aws_secret_access_key: your_secret_key

ssh_public_key: your_public_key
additional_authorized_keys:
  - your_public_key1
  - your_public_key2

pull_secret: 'your_pull_secret'
```

Run playbook:

```bash
ansible-playbook -e @vars/govcloud.yml playbooks/create_cluster.yml -v
```
