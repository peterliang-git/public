output "web_server_instance_id" {
  value       = aws_instance.web_server.id
  description = "The id of the web server."
}

output "web_server_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "The public IP address of the web server."
}