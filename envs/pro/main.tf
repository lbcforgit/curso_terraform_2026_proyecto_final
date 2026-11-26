# ENTORNO PRO · Complétalo tomando como modelo envs/dev/main.tf
#   - dos zonas: eu-west-1a y eu-west-1b
#   - dos servidores, a y b, con los mensajes "Producción · servidor A" y "Producción · servidor B"
#   - además, el bucket de logs (módulo logs), que solo existe en este entorno

locals {
  entorno     = "pro"
  nombre_base = "${var.prefijo}-${local.entorno}"
  zonas       = ["eu-west-1a", "eu-west-1b"]

  servidores = {
    a = { mensaje = "Producción · servidor A" }
    b = { mensaje = "Producción · servidor B" }
  }

  subred_de = { for i, k in keys(local.servidores) : k => i % length(local.zonas) }
}

module "red" {
  source = "../../modules/red"

  nombre   = local.nombre_base
  vpc_cidr = "10.0.0.0/16"
  zonas    = local.zonas
}

module "web" {
  source   = "../../modules/servidor_web"
  for_each = local.servidores

  nombre    = "${local.nombre_base}-${each.key}"
  vpc_id    = module.red.vpc_id
  subred_id = module.red.subred_publica_ids[local.subred_de[each.key]]
  mensaje   = each.value.mensaje
  ami_id    = var.ami_id

  depends_on = [module.red]
}

# Bucket de logs: escribe aquí la llamada al módulo logs
# (source "../../modules/logs" y nombre "${local.nombre_base}-logs")

module "logs" {
  source = "../../modules/logs"
  nombre = "${local.nombre_base}-logs"
}