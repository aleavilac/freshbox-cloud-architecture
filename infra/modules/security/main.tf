# =====================================================================
# MODULO: security
# 3 Security Groups encadenados (principio de minimo privilegio):
#   SG-ALB  <- Internet (80/443)
#   SG-APP  <- SG-ALB   (80)   [nginx expone TODO en el puerto 80;
#                                los backends 3001-3004 solo se hablan
#                                entre contenedores via red Docker interna,
#                                nunca necesitan quedar abiertos a nivel SG]
#   SG-DATA <- SG-APP   (3306)
# =====================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "SG-ALB: permite 80/443 desde Internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-alb" }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "SG-APP: permite trafico HTTP (puerto 80, nginx) solo desde SG-ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Frontend (nginx, reverse proxy interno) desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-app" }
}

resource "aws_security_group" "data" {
  name        = "${var.project_name}-sg-data"
  description = "SG-DATA: permite MySQL solo desde SG-APP"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL desde capa App"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-data" }
}

# =====================================================================
# EC2 Instance Connect Endpoint (SSM no esta disponible en esta cuenta
# Academy - "Systems Manager default role not enabled"). Este es el
# metodo alternativo para conectarse por SSH a instancias en subredes
# PRIVADAS, sin IP publica, sin bastion, desde el navegador o AWS CLI.
# =====================================================================

resource "aws_security_group" "eic" {
  name        = "${var.project_name}-sg-eic"
  description = "SG del EC2 Instance Connect Endpoint"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-eic" }
}

# Permite que el trafico SSH que sale del Instance Connect Endpoint
# llegue a las instancias de la capa App (agregado a SG-APP)
resource "aws_security_group_rule" "app_ssh_from_eic" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.eic.id
  description               = "SSH desde EC2 Instance Connect Endpoint (debug, sin SSM)"
}

# Igual para la capa Data (por si se necesita entrar a revisar MySQL directamente)
resource "aws_security_group_rule" "data_ssh_from_eic" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.data.id
  source_security_group_id = aws_security_group.eic.id
  description               = "SSH desde EC2 Instance Connect Endpoint (debug, sin SSM)"
}
