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

**TODO: Include directions for install `pipenv`**

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

cluster_name: va-ocp43
base_domain: va.govcloud.rdht.io

rhcos_ami: ami-63516602
keypair_name: default
```

Run playbook:

```bash
ansible-playbook -e @vars/govcloud.yml playbooks/create_infrastructure.yml -v
```
