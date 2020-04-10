terraform {
  backend "s3" {}
}

provider "aws" {}

###############################################################################
# Data
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "rhel7" {
  most_recent = true
  owners      = ["219670896067"]

  filter {
    name   = "name"
    values = ["RHEL-7.7_HVM-20191119-x86_64-2-Hourly2-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# Locals
###############################################################################

locals {
  kubernetes_cluster_shared_tag = map(
    "kubernetes.io/cluster/${var.cluster_name}", "shared"
  )

  kubernetes_cluster_owned_tag = map(
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )

  public_subnets = [
    aws_subnet.public0,
    aws_subnet.public1,
    aws_subnet.public2
  ]

  private_subnets = [
    aws_subnet.private0,
    aws_subnet.private1,
    aws_subnet.private2
  ]
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "openshift" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_vpc_dhcp_options" "openshift" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "openshift" {
  vpc_id          = aws_vpc.openshift.id
  dhcp_options_id = aws_vpc_dhcp_options.openshift.id
}

resource "aws_internet_gateway" "openshift" {
  vpc_id = aws_vpc.openshift.id

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_subnet" "public0" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-public-${data.aws_availability_zones.available.names[0]}"
    )
  )
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 1)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-public-${data.aws_availability_zones.available.names[1]}"
    )
  )
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 2)
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-public-${data.aws_availability_zones.available.names[2]}"
    )
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.openshift.id
  }

  tags = {
    Name = "${var.cluster_name}-public"
  }
}

resource "aws_route_table_association" "public0" {
  subnet_id      = aws_subnet.public0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "natgw_public0" {
  vpc = true

  tags = {
    Name = "${var.cluster_name}-natgw-${data.aws_availability_zones.available.names[0]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_eip" "natgw_public1" {
  vpc = true

  tags = {
    Name = "${var.cluster_name}-natgw-${data.aws_availability_zones.available.names[1]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_eip" "natgw_public2" {
  vpc = true

  tags = {
    Name = "${var.cluster_name}-natgw-${data.aws_availability_zones.available.names[2]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public0" {
  subnet_id     = aws_subnet.public0.id
  allocation_id = aws_eip.natgw_public0.id

  tags = {
    Name = "${var.cluster_name}-${data.aws_availability_zones.available.names[0]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public1" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.natgw_public1.id

  tags = {
    Name = "${var.cluster_name}-${data.aws_availability_zones.available.names[1]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public2" {
  subnet_id     = aws_subnet.public2.id
  allocation_id = aws_eip.natgw_public2.id

  tags = {
    Name = "${var.cluster_name}-${data.aws_availability_zones.available.names[2]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_subnet" "private0" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 3)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-private-${data.aws_availability_zones.available.names[0]}"
    )
  )
}

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 4)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-private-${data.aws_availability_zones.available.names[1]}"
    )
  )
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 5)
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-private-${data.aws_availability_zones.available.names[2]}"
    )
  )
}

resource "aws_route_table" "private0" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public0.id
  }

  tags = {
    Name = "${var.cluster_name}-private-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public1.id
  }

  tags = {
    Name = "${var.cluster_name}-private-${data.aws_availability_zones.available.names[1]}"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public2.id
  }

  tags = {
    Name = "${var.cluster_name}-private-${data.aws_availability_zones.available.names[2]}"
  }
}

resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.private0.id
  route_table_id = aws_route_table.private0.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

###############################################################################
# Load Balancing
###############################################################################

resource "aws_lb" "masters_ext" {
  name               = "${var.cluster_name}-ext"
  internal           = true
  load_balancer_type = "network"

  subnets = [
    aws_subnet.private0.id,
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-ext"
    )
  )
}

resource "aws_lb" "masters_int" {
  name               = "${var.cluster_name}-int"
  internal           = true
  load_balancer_type = "network"

  subnets = [
    aws_subnet.private0.id,
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-int"
    )
  )
}

resource "aws_lb_target_group" "api" {
  name     = "${var.cluster_name}-api"
  vpc_id   = aws_vpc.openshift.id
  port     = 6443
  protocol = "TCP"
}

resource "aws_lb_target_group" "api_int" {
  name     = "${var.cluster_name}-api-int"
  vpc_id   = aws_vpc.openshift.id
  port     = 6443
  protocol = "TCP"
}

resource "aws_lb_target_group" "machine_config" {
  name     = "${var.cluster_name}-machine-config"
  vpc_id   = aws_vpc.openshift.id
  port     = 22623
  protocol = "TCP"
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.masters_ext.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_listener" "api_int" {
  load_balancer_arn = aws_lb.masters_int.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_int.arn
  }
}

resource "aws_lb_listener" "machine_config" {
  load_balancer_arn = aws_lb.masters_int.arn
  port              = 22623
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.machine_config.arn
  }
}

resource "aws_lb_target_group_attachment" "api_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.api.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_int_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.api_int.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_int_bootstrap" {
  target_group_arn = aws_lb_target_group.api_int.arn
  target_id        = aws_instance.bootstrap.id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "machine_config_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.machine_config.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 22623
}

resource "aws_lb_target_group_attachment" "machine_config_bootstrap" {
  target_group_arn = aws_lb_target_group.machine_config.arn
  target_id        = aws_instance.bootstrap.id
  port             = 22623
}

###############################################################################
# Security Groups
###############################################################################

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion"
  description = "${var.cluster_name} bastion security group"
  vpc_id      = aws_vpc.openshift.id

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

resource "aws_security_group_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"

  from_port   = 22
  to_port     = 22
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "bootstrap" {
  name        = "${var.cluster_name}-bootstrap"
  description = "${var.cluster_name} bootstrap security group"
  vpc_id      = aws_vpc.openshift.id

  tags = {
    Name = "${var.cluster_name}-bootstrap"
  }
}

resource "aws_security_group_rule" "bootstrap_egress" {
  security_group_id = aws_security_group.bootstrap.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bootstrap_ingress_vpc" {
  security_group_id = aws_security_group.bootstrap.id
  type              = "ingress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-master"
  description = "${var.cluster_name} master security group"
  vpc_id      = aws_vpc.openshift.id

  tags = {
    Name = "${var.cluster_name}-master"
  }
}

resource "aws_security_group_rule" "master_egress" {
  security_group_id = aws_security_group.master.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master_ingress_vpc" {
  security_group_id = aws_security_group.master.id
  type              = "ingress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker"
  description = "${var.cluster_name} worker security group"
  vpc_id      = aws_vpc.openshift.id

  tags = {
    Name = "${var.cluster_name}-worker"
  }
}

resource "aws_security_group_rule" "worker_egress" {
  security_group_id = aws_security_group.worker.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "worker_ingress_vpc" {
  security_group_id = aws_security_group.worker.id
  type              = "ingress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.vpc_cidr]
}

# resource "aws_security_group" "cluster" {
#   name        = "${var.cluster_name}-cluster"
#   description = "${var.cluster_name} security group"
#   vpc_id      = aws_vpc.openshift.id

#   tags = {
#     Name = "${var.cluster_name}-cluster"
#   }
# }

# resource "aws_security_group_rule" "cluster_egress" {
#   security_group_id = aws_security_group.cluster.id
#   type              = "egress"

#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "cluster_ingress_vpc" {
#   security_group_id = aws_security_group.cluster.id
#   type              = "ingress"

#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = [var.vpc_cidr]
# }

###############################################################################
# IAM
###############################################################################

resource "aws_iam_role" "bootstrap" {
  name = "${var.cluster_name}-bootstrap-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "bootstrap" {
  name = "${var.cluster_name}-bootstrap-policy"
  role = aws_iam_role.bootstrap.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "ec2:Describe*",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "ec2:AttachVolume",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "ec2:DetachVolume",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "s3:GetObject",
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "bootstrap" {
  name = "${var.cluster_name}-bootstrap-profile"
  role = aws_iam_role.bootstrap.name
}

resource "aws_iam_role" "master" {
  name = "${var.cluster_name}-master-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "master" {
  name = "${var.cluster_name}-master-policy"
  role = aws_iam_role.master.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "ec2:*",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "elasticloadbalancing:*",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "iam:PassRole",
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "s3:GetObject",
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "master" {
  name = "${var.cluster_name}-master-profile"
  role = aws_iam_role.master.name
}

resource "aws_iam_role" "worker" {
  name = "${var.cluster_name}-worker-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "worker" {
  name = "${var.cluster_name}-worker-policy"
  role = aws_iam_role.worker.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "ec2:Describe*",
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_name}-worker-profile"
  role = aws_iam_role.worker.name
}

###############################################################################
# EC2
###############################################################################

resource "aws_instance" "bastion" {
  instance_type = "t3.medium"
  ami           = data.aws_ami.rhel7.id
  subnet_id     = local.public_subnets[0].id
  key_name      = var.keypair_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.bastion.id, aws_security_group.master.id]
  iam_instance_profile        = aws_iam_instance_profile.master.name
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

resource "aws_instance" "bootstrap" {
  instance_type = "m5.xlarge"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[0].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.bootstrap.id, aws_security_group.master.id]
  iam_instance_profile        = aws_iam_instance_profile.bootstrap.name
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/bootstrap.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-bootstrap"
    )
  )

  depends_on = [aws_instance.bastion]
}

resource "aws_instance" "masters" {
  count = 3

  instance_type = "m5.xlarge"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[count.index].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.master.id]
  iam_instance_profile        = aws_iam_instance_profile.master.name
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/master.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-master-${count.index}"
    )
  )

  depends_on = [aws_instance.bastion]
}

resource "aws_instance" "workers" {
  count = 3

  instance_type = "m5.xlarge"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[count.index].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.worker.id]
  iam_instance_profile        = aws_iam_instance_profile.worker.name
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/worker.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_name}-worker-${count.index}"
    )
  )

  depends_on = [aws_instance.bastion]
}

###############################################################################
# Route53
###############################################################################

resource "aws_route53_zone" "private" {
  name = var.base_domain

  vpc {
    vpc_id = aws_vpc.openshift.id
  }

  tags = merge(
    local.kubernetes_cluster_owned_tag,
    map(
      "Name", "${var.cluster_name}.${var.base_domain}"
    )
  )
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${var.cluster_name}.${var.base_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.masters_ext.dns_name]
}

resource "aws_route53_record" "api_int" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api-int.${var.cluster_name}.${var.base_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.masters_int.dns_name]
}

resource "aws_route53_record" "etcd" {
  count = 3

  zone_id = aws_route53_zone.private.zone_id
  name    = "etcd-${count.index}.${var.cluster_name}.${var.base_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.masters[count.index].private_ip]
}

resource "aws_route53_record" "etcd_srv" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "_etcd-server-ssl._tcp.${var.cluster_name}.${var.base_domain}"
  type    = "SRV"
  ttl     = "300"
  records = [
    "0 10 2380 etcd-0.${var.cluster_name}.${var.base_domain}.",
    "0 10 2380 etcd-1.${var.cluster_name}.${var.base_domain}.",
    "0 10 2380 etcd-2.${var.cluster_name}.${var.base_domain}."
  ]
}
