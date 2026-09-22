# =====================================================================
# MODULO: security — VERSION "5 PUERTOS" (Plan B)
# SG-ALB y SG-APP ahora abren tambien 3001-3004, porque el ALB
# habla directo con cada contenedor backend (ya no todo pasa por
# nginx en el puerto 80).
# =====================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "SG-ALB: permite 80/443 y 3001-3004 desde Internet (patron 5 puertos)"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP desde Internet (frontend)"
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

  ingress {
    description = "APIs backend (get/create/update/delete-product) desde Internet"
    from_port   = 3001
    to_port     = 3004
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
  description = "SG-APP: permite 80 y 3001-3004 SOLO desde SG-ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Frontend desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "APIs backend desde ALB"
    from_port       = 3001
    to_port         = 3004
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

# EC2 Instance Connect Endpoint (igual que en el Plan A, sin cambios)
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

resource "aws_security_group_rule" "app_ssh_from_eic" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.eic.id
  description               = "SSH desde EC2 Instance Connect Endpoint (debug)"
}

resource "aws_security_group_rule" "data_ssh_from_eic" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.data.id
  source_security_group_id = aws_security_group.eic.id
  description               = "SSH desde EC2 Instance Connect Endpoint (debug)"
}
