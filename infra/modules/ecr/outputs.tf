output "repository_urls" {
  description = "URL completa de cada repositorio ECR (para docker push/pull)."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}
