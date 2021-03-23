data "aws_availability_zones" "available" {}

variable "storage_size" {
  type = number
  default = 150
  description = "Size of volume for storing alpine packages"
}

variable "http_acl" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "lList of CIDR blocks to allow http traffic from"
}

variable "ssh_acl" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow ssh traffic from"
}

variable "availability_zone" {
  type = string
  default = "us-west-2a"
  description = "Availability zone where instance will be created"
}

variable "region" {
  type = string
  default = "us-west-2"
  description = "Region where instance will be created"
}

variable "ssh_keypair_name" {
  type = string
  description = "ssh keypair name, used for ssh authentication to the instances"
}

variable "subnet_id" {
  type = string
  description = "ID of subnet to place instance in"
}

variable "vpc_id" {
  type = string
  description = "ID of VPC to place instance in"
}

provider "aws" {
  region = var.region
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS ENA *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # CentOS
}

resource "aws_security_group" "web_server" {
  name        = "web_server"
  description = "Basic ACLs for webserver"
  vpc_id      = "var.vpc_id"

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = var.http_acl
    description = "http access"
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = var.ssh_acl
    description = "ssh access"
  }
}

resource "aws_ebs_volume" "jlk-alpine-rnd" {
  availability_zone = "us-west-2a"
  type              = "gp2"
  size              = var.storage_size

  tags = {
    Name = "jlk-alpine-rnd"
  }
}

resource "aws_instance" "alpine_mirror" {
  ami           = "data.aws_ami.centos.id"
  instance_type = "m3.large"
  # get spot instance in here...
  security_groups = ["aws_security_group.web_server.id"]
  subnet_id = "var.subnet_id"
  key_name = "var.ssh_keypair_name"

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
 }

  tags = {
    Name = "jlk-alpine-rnd"
  }
}

output "instance_ip_addr" {
  value = aws_instance.alpine_mirror.public_ip
  description = "The public IP address of the mirror server for ssh and http access."
}

resource "null_resource" "example" {}

resource "aws_volume_attachment" "data_drive" {
  device_name = "/dev/sdd"
  volume_id = "aws_ebs_volume.jlk-alpine-rnd.id"
  instance_id = "aws_instance.alpine_mirror.id"

  # Next line is here so provisioner doesn't run on destroy
  skip_destroy = true
}

resource "null_resource" "setup" {
  triggers = {
    volume_attachment = "aws_volume_attachment.data_drive.id"
  }

  connection {
    type = "ssh"
    user = "centos"
    host = "element(aws_instance.alpine_mirror.*.public_ip, 0)"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "provisioning-scripts"
    destination = "/home/centos/provisioning-scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/centos/provisioning-scripts/*",
      "sudo /home/centos/provisioning-scripts/setup-server.sh",
      "sudo /home/centos/provisioning-scripts/setup-cron.sh",
    ]
  }
}
