# =====================================================================
# MODULO: compute
# Launch Template + Auto Scaling Group para la capa App (EC2 + Docker)
# min:2 / max:4, distribuido en 2 AZs, autoregistrado en el Target Group.
#
# NOTA sobre la decision ASG vs 2 EC2 fijas: la guia del docente usa
# 2 instancias fijas (APP-1/APP-2), pero la pauta de evaluacion exige
# explicitamente "Auto Scaling Group" como criterio de validacion
# (1.7.1 y 2.4). Se prioriza la pauta de evaluacion: un ASG con
# min=2/max=4 sigue cumpliendo "2 instancias Multi-AZ con contenedores
# corriendo" (criterio del docente) y ademas satisface el requisito
# explicito de escalabilidad automatica.
# =====================================================================

data "aws_ami" "al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance Profile pre-existente de AWS Academy (LabRole / LabInstanceProfile).
# En cuentas Academy NO es posible crear roles IAM propios.
data "aws_iam_instance_profile" "lab" {
  name = var.lab_instance_profile_name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.al2023_arm64.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab.name
  }

  vpc_security_group_ids = [var.sg_app_id]

  # Cifrado EBS obligatorio segun guia del docente
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 16
      volume_type = "gp3"
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data_app.sh.tpl", {
    aws_region   = var.aws_region
    ecr_registry = var.ecr_registry
    db_host      = var.db_host
    db_name      = var.db_name
    db_user      = var.db_user
    db_password  = var.db_password
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
      Tier = "app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                       = "${var.project_name}-asg-app"
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  desired_capacity           = var.asg_desired_capacity
  vpc_zone_identifier        = var.app_subnet_ids
  target_group_arns          = var.target_group_arns
  health_check_type          = "ELB"
  health_check_grace_period  = 420

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }

  timeouts {
    delete = "10m"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

