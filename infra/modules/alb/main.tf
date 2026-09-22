# =====================================================================
# MODULO: alb
# ALB unico desplegado en las 2 subredes publicas (Multi-AZ).
# UN SOLO Target Group (puerto 80) segun la guia oficial del docente:
# el frontend (nginx) actua como reverse proxy interno hacia los 4
# backends (get/create/update/delete-product) usando el nombre de
# contenedor dentro de la red Docker "freshbox-net". El ALB nunca
# habla directo con los puertos 3001-3004: todo pasa por nginx:80.
# =====================================================================

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-tg-app" }
}

# Escucha HTTP:80 y reenvia TODO al target group unico.
# nginx (dentro del contenedor frontend) resuelve internamente:
#   /             -> archivos estaticos del frontend
#   /api/products -> proxy_pass hacia freshbox-get-products:3001 (GET),
#                     freshbox-create-product:3002 (POST), etc.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
