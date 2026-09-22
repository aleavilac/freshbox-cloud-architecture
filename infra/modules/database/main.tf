# =====================================================================
# MODULO: database
# EC2 + MySQL 8 - instancia UNICA en subred privada Data AZ1a,
# segun la guia oficial del docente. Alta disponibilidad y DR se
# resuelven con AWS Backup (snapshot diario, retencion 7 dias),
# no con una replica Multi-AZ en vivo.
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
}

data "aws_iam_instance_profile" "lab" {
  name = var.lab_instance_profile_name
}

resource "aws_instance" "primary" {
  ami                    = data.aws_ami.al2023_arm64.id
  instance_type          = var.instance_type
  subnet_id              = var.data_subnet_ids[0] # AZ1a
  vpc_security_group_ids = [var.sg_data_id]

  iam_instance_profile = data.aws_iam_instance_profile.lab.name

  # Cifrado EBS obligatorio segun guia del docente
  root_block_device {
    volume_size = 16
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data_primary.sh.tpl", {
    db_name          = var.db_name
    db_user          = var.db_user
    db_password      = var.db_password
    db_root_password = var.db_root_password
    init_sql_content = var.init_sql_content
  }))

  tags = {
    Name = "${var.project_name}-mysql"
    Tier = "data"
  }
}

# --------------------------- AWS Backup (DR) ---------------------------
resource "aws_backup_vault" "this" {
  name = "${var.project_name}-backup-vault"
}

resource "aws_backup_plan" "this" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-snapshot"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 6 * * ? *)" # 06:00 UTC diario

    lifecycle {
      delete_after = 7 # retencion 7 dias
    }
  }
}

resource "aws_backup_selection" "this" {
  name         = "${var.project_name}-backup-selection"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = data.aws_iam_instance_profile.lab.role_arn

  resources = [
    aws_instance.primary.arn,
  ]
}
