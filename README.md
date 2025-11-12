Terraform + Docker + MySQL + Python Project Documentation

Platform: AWS (Infrastructure as Code using Terraform)
Tools: Terraform, Docker, Python, VS Code

Project Overview
This project demonstrates a fully automated infrastructure deployment using Terraform on AWS,
where an EC2 instance is provisioned with Docker installed automatically via user data.
A MySQL container is deployed inside Docker, and a Python script is executed to connect,
create databases and tables, and insert data dynamically.

Architecture Flow
1. Terraform provisions AWS infrastructure (VPC, Subnets, Security Groups, Key Pair, EC2 Instance).
2. EC2 User Data installs Docker and starts a MySQL container.
3. Python script connects to MySQL running inside Docker using the EC2 public IP.
4. The Python script automatically creates a database, table, and inserts data.
5. Terraform output provides instance details for access.

Terraform Configuration Files

[main.tf]
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


[variables.tf]
# AWS region
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

# EC2 instance settings
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

# Security Group name
variable "sg_name" {
  description = "Security group name"
  type        = string
}
variable "key_name" {
  description = "Key pair name to create and use for EC2 SSH access"
  type        = string
  default     = "terraform-generated-key"
}


[outputs.tf]
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ec2_instance.id
}

output "public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.allow_ports.id
}

output "subnet_id" {
  description = "Subnet ID of EC2 instance"
  value       = aws_instance.ec2_instance.subnet_id
}

output "vpc_id" {
  description = "VPC ID associated with the EC2 instance"
  value       = aws_instance.ec2_instance.vpc_security_group_ids
}
output "private_key_path" {
  description = "Path to the generated private key file"
  value       = local_file.private_key.filename
}


[terraform.tfvars]
region         = "ap-south-1"
ami_id = "ami-0305d3d91b9f22e84"
instance_type  = "t3.micro"
instance_name  = "Terraform-EC2-MySQL"
sg_name        = "allow-ssh-mysql"
key_name       = "terraform-generated-key"


Python Application (pypro.py)
import mysql.connector
from mysql.connector import Error
import time

DB_HOST = "3.110.136.103"  # Public IP of your EC2
DB_USER = "root"
DB_PASSWORD = "root"
DB_NAME = "company"

# ----------------------------------------
# Connect with Retry Logic
# ----------------------------------------
def get_connection(retries=10, delay=5):
    for attempt in range(1, retries + 1):
        try:
            print(f"[INFO] Connecting to MySQL (Attempt {attempt}/{retries})...")
            conn = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD
            )
            print("[SUCCESS] Connected to MySQL server.")
            return conn
        except Error as e:
            print(f"[WARN] Connection failed: {e}")
            time.sleep(delay)
    raise Exception("[ERROR] Could not connect to MySQL after multiple attempts.")

# ----------------------------------------
# Ensure DB & Table Exist
# ----------------------------------------
def setup_database(cursor):
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME};")
    cursor.execute(f"USE {DB_NAME};")
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS employees (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) UNIQUE,
            department VARCHAR(50)
        );
    """)
    print("[INFO] Database & table ready.")

# ----------------------------------------
# Insert Employees if not exist
# ----------------------------------------
def insert_employees(cursor, conn):
    employees = [
        ("Sukesh", "Engineering"),
        ("Harsha", "Finance"),
        ("Kranthi", "HR"),
        ("Abhi", "Security"),
        ("Venky", "Education"),
    ]

    sql = "INSERT IGNORE INTO employees (name, department) VALUES (%s, %s);"

    cursor.executemany(sql, employees)
    conn.commit()
    print("[INFO] Data inserted (duplicates skipped).")

# ----------------------------------------
# Display Data
# ----------------------------------------
def display_employees(cursor):
    cursor.execute("SELECT * FROM employees;")
    rows = cursor.fetchall()

    print("\n--- Employee Table ---")
    for row in rows:
        print(f"ID={row[0]}, Name={row[1]}, Dept={row[2]}")
    print("----------------------\n")

# ----------------------------------------
# Main Execution
# ----------------------------------------
try:
    conn = get_connection()
    cursor = conn.cursor()

    setup_database(cursor)
    insert_employees(cursor, conn)
    display_employees(cursor)

except Exception as e:
    print(f"[FATAL] Script failed: {e}")

finally:
    if cursor:
        cursor.close()
    if conn:
        conn.close()
    print("[INFO] Script finished.")


Execution Steps
1. Install Terraform and AWS CLI in your local machine or VS Code terminal.
2. Configure AWS credentials using `aws configure`.
3. Initialize the project folder:
  Install terraform
   terraform init
4. Plan the deployment:
   terraform plan
5. Apply the configuration:
   terraform apply -auto-approve
6. Verify infrastructure creation in AWS Management Console.
7. SSH into the EC2 instance using the key pair and open the docker container
8. Run the Python script in the VS code to validate MySQL database creation.
9. Confirm the database and tables exist by connecting to MySQL inside the container.

Validation Output
The Python script connects successfully to MySQL and creates the 'company' database
with an 'employees' table. Employee data is inserted and displayed in tabular format.

Troubleshooting
- If Terraform apply fails, ensure AWS credentials and permissions are valid.
- If Docker fails to start, verify the user data script syntax and EC2 instance logs (/var/log/cloud-init.log).
- Ensure MySQL container port (3306) is open in the Security Group for remote Python access.
- If Python connection fails, check that the public IP and credentials match.

Conclusion
This project demonstrates a real-world DevOps workflow integrating Terraform for infrastructure,
Docker for containerization, and Python for application-level automation.

