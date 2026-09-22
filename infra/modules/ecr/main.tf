# =====================================================================
# MODULO: ecr
# 5 repositorios (1 por contenedor): frontend + 4 microservicios backend
# Nombres planos (freshbox-frontend, no freshbox/frontend) para calzar
# exactamente con scripts/ecr-push.sh y scripts/deploy-containers.sh
# =====================================================================

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repository_names)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = each.value
    Project = var.project_name
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Mantener solo las ultimas 10 imagenes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
