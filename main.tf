provider "aws" {
  region = var.region
}
# ------------------------
# Generate SSH Key Pair
# ------------------------
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "allow_ports" {
  name        = var.sg_name
  description = "Allow SSH and MySQL access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}

# ------------------------
# EC2 Instance
# ------------------------
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ports.id]

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install docker -y
  systemctl start docker
  systemctl enable docker
  docker run -d --name mysql-db -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 mysql:latest
EOF


  tags = {
    Name = var.instance_name
  }
}
