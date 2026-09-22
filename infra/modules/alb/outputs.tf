output "alb_dns_name" {
  description = "Endpoint publico del ALB. Frontend y API completa (via proxy interno de nginx) se acceden desde aqui."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN del (unico) Target Group. El ASG registra sus instancias aqui."
  value       = aws_lb_target_group.app.arn
}
