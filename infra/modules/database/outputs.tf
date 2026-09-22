output "primary_private_ip" {
  value = aws_instance.primary.private_ip
}

output "primary_instance_id" {
  value = aws_instance.primary.id
}
