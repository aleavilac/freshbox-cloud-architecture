# =====================================================================
# MODULO: alb — VERSION "5 PUERTOS" (Plan B)
# En vez de que nginx haga de reverse proxy interno, el ALB expone
# 5 listeners (80, 3001, 3002, 3003, 3004), cada uno con su propio
# Target Group apuntando DIRECTO al contenedor correspondiente.
#
# VENTAJA: elimina el riesgo de que nginx no resuelva el nombre del
# contenedor backend (el bug que nos costo horas).
# REQUISITO: el frontend (app.js) debe llamar a estos puertos
# DIRECTAMENTE (ej: http://<alb-dns>:3001/api/products), no a rutas
# relativas como fetch('/api/products'). Verificar antes de usar esta
# version.
# =====================================================================

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

locals {
  services = {
    frontend = {
      port    = 80
      path    = "/"
      matcher = "200"
    }
    get-products = {
      port    = 3001
      path    = "/health"
      matcher = "200"
    }
    create-product = {
      port    = 3002
      path    = "/health"
      matcher = "200"
    }
    update-product = {
      port    = 3003
      path    = "/health"
      matcher = "200"
    }
    delete-product = {
      port    = 3004
      path    = "/health"
      matcher = "200"
    }
  }
}

resource "aws_lb_target_group" "this" {
  for_each = local.services

  name     = "${var.project_name}-tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = each.value.path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = each.value.matcher
  }

  tags = { Name = "${var.project_name}-tg-${each.key}" }
}

resource "aws_lb_listener" "this" {
  for_each = local.services

  load_balancer_arn = aws_lb.this.arn
  port               = each.value.port
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}
