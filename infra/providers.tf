provider "aws" {
  region = var.aws_region

  # IMPORTANTE - AWS Academy Learner Lab:
  # No se usan Access Keys hardcodeadas en el codigo (nunca se deben commitear).
  # El provider toma las credenciales automaticamente desde variables de entorno:
  #   AWS_ACCESS_KEY_ID
  #   AWS_SECRET_ACCESS_KEY
  #   AWS_SESSION_TOKEN   <-- obligatorio en Academy (credenciales temporales)
  #
  # Estas se copian desde el panel "AWS Details" -> "AWS CLI" del Learner Lab
  # y se exportan en la terminal ANTES de correr terraform:
  #
  #   export AWS_ACCESS_KEY_ID="..."
  #   export AWS_SECRET_ACCESS_KEY="..."
  #   export AWS_SESSION_TOKEN="..."
  #
  # Duran unas pocas horas: si terraform apply falla con error de
  # autenticacion/expiracion, hay que refrescar estas 3 variables.

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "ep1-evaluacion"
      ManagedBy   = "terraform"
    }
  }
}
