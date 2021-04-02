terraform {
  required_providers {
    aws = {
      version = "~>3.0"
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "myterraformcloud"
    workspaces = {
      name = "demo-app1-nw"
    }
  }
}

data "terraform_remote_state" "backend" {
  backend = "remote"
  config = {
    organization = "myterraformcloud"
    workspaces = {
      name = "demo-app1-backend"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_string" "random" {
  length  = 8
  upper   = false
  special = false
}

data "aws_ami" "frontend_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

locals {
  frontend_user_data = <<EOF
#!/bin/bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install npm consul -y
cd /home/ubuntu
mkdir frontend
wget https://frontend-hc-step1.s3-us-west-2.amazonaws.com/frontend.tar.gz
tar -xvzf frontend.tar.gz -C frontend/
cd frontend
npm i
echo "API_URL=${data.terraform_remote_state.backend.outputs.backend_api_url}" > .env
source .env
npm run build
sudo npm start
EOF
}

module "ec2_frontend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~>2.0"

  instance_count = var.frontend_instance_count

  name                        = "frontend-${random_string.random.id}"
  ami                         = data.aws_ami.frontend_ami.id
  instance_type               = var.frontend_instance_type
  key_name                    = "tf_lab_key"
  subnet_ids                  = data.terraform_remote_state.vpc.outputs.public_subnets
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.frontend_security_group_id]
  associate_public_ip_address = true

  user_data_base64 = base64encode(local.frontend_user_data)


  tags = var.common_tags

}
