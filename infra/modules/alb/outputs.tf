output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

# Mapa completo (uno por servicio) para que el modulo compute
# registre las instancias en los 5 Target Groups a la vez.
output "target_group_arns" {
  value = [for tg in aws_lb_target_group.this : tg.arn]
}

output "target_group_arns_by_service" {
  description = "Util para depurar: ARN de cada Target Group por nombre de servicio."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}