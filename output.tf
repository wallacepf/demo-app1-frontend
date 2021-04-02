output "app_url" {
  value = "http://${module.ec2_frontend.public_ip[0]}"
}
