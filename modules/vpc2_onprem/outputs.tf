output "vpc_id" {
  value = aws_vpc.vpc2.id
}

output "public_subnet_2a_id" {
  value = aws_subnet.public_2a.id
}

output "private_subnet_2a_id" {
  value = aws_subnet.private_2a.id
}

output "private_subnet_2b_id" {
  value = aws_subnet.private_2b.id
}

output "private_subnet_2c_id" {
  value = aws_subnet.private_2c.id
}

output "control_plane_2a_private_ip" {
  value = aws_instance.control_plane_2a.private_ip
}

output "control_plane_2b_private_ip" {
  value = aws_instance.control_plane_2b.private_ip
}

output "control_plane_2c_private_ip" {
  value = aws_instance.control_plane_2c.private_ip
}

output "worker_2a_private_ip" {
  value = aws_instance.worker_2a.private_ip
}

output "worker_2b_private_ip" {
  value = aws_instance.worker_2b.private_ip
}

output "worker_2c_private_ip" {
  value = aws_instance.worker_2c.private_ip
}

output "nat_instance_public_ip" {
  value = aws_instance.nat_instance.public_ip
}