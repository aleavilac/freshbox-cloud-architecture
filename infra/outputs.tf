output "alb_dns_name" {
  description = "Endpoint publico de la aplicacion. Frontend: http://<este_valor>/  |  API: http://<este_valor>/api/products"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_urls" {
  description = "URLs de los 5 repositorios ECR (para docker push antes del primer despliegue)."
  value       = module.ecr.repository_urls
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "mysql_private_ip" {
  value = module.database.primary_private_ip
}

output "asg_name" {
  value = module.compute.asg_name
}
