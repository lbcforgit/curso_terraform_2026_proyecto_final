# MÓDULO servidor_web · Grupo de seguridad e instancia EC2 con nginx (el del módulo 5)

data "aws_ami" "ubuntu" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

locals {
  ami = coalesce(var.ami_id, one(data.aws_ami.ubuntu[*].id))
}

resource "aws_security_group" "web" {
  name        = "${var.nombre}-sg"
  description = "Servidor web: puertos de entrada configurables y salida a Internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.nombre}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "entrada" {
  for_each = { for p in var.puertos : tostring(p) => p }

  security_group_id = aws_security_group.web.id
  description       = "Entrada al puerto ${each.value}"
  cidr_ipv4         = var.origen_permitido
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"
}

# Excepción justificada: para una formación
# no tenemos proxy inverso.
#trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "todo" {
  security_group_id = aws_security_group.web.id
  description       = "Salida a Internet (actualizaciones e instalacion de paquetes)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "web" {
  ami                         = local.ami
  instance_type               = var.tipo_instancia
  subnet_id                   = var.subred_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>${var.nombre}</h1><p>${var.mensaje}</p>" > /var/www/html/index.html
    systemctl enable --now nginx
  EOT

  tags = {
    Name = var.nombre
  }
}
