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
