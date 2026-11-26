# Proyecto final · Infraestructura como código con Terraform

Curso G2601118 · Módulo 6

Plantilla del proyecto final. Partes de la red y los servidores de los módulos 4 y 5; tu trabajo es completar el entorno de producción, aplicar las medidas de seguridad que señala Trivy, poner en marcha el CI/CD y documentarlo.

## Lista de comprobación

- [X] `envs/pro` completado (dos zonas, dos servidores y el bucket de logs)
- [X] Trivy sin hallazgos HIGH o CRITICAL: corrigiendo o justificando cada uno
- [X] IMDSv2 y disco cifrado en `modules/servidor_web`
- [X] Bucket de logs cifrado y sin acceso público en `modules/logs`
- [X] `.github/workflows/ci.yml` completado
- [X] CI en verde (en GitHub o con `./scripts/ci.sh`)
- [X] Despliegue de prueba correcto (en GitHub o con `./scripts/despliegue-prueba.sh`)
- [X] `dev` y `pro` desplegados en AWS o en Floci
- [X] `DOCUMENTACION.md` completado
- [ ] `entrega.zip` generado con `./scripts/empaquetar.sh`
- [X] Todo destruido al terminar

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `bootstrap/` | Bucket S3 del estado (estado local) |
| `modules/red` | VPC, subredes públicas e Internet Gateway |
| `modules/servidor_web` | Grupo de seguridad e instancia EC2 con nginx |
| `modules/logs` | Bucket S3 de logs: privado, cifrado y con caducidad |
| `envs/dev`, `envs/pro` | Un directorio por entorno, cada uno con su estado en S3 |
| `scripts/` | `ci.sh`, `despliegue-prueba.sh` y `empaquetar.sh` |
| `.github/workflows/` | CI, despliegue de prueba y despliegue en AWS (opcional) |
| `extras/oidc` | Rol de AWS para GitHub Actions con OIDC (opcional) |

Requisitos: Terraform 1.11 o posterior, la AWS CLI y Docker (o TFLint y Trivy instalados).

> **Floci tiene que escuchar en `http://localhost:4566`.** Esa dirección está fija en los `providers.tf` y en `backend-floci.hcl`; si lo arrancas en otro puerto, Terraform no lo encontrará. Por ejemplo: `docker run -d --name floci -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock floci/floci:latest-compat`

## Desplegar en local

```bash
# 1. Bucket del estado
cd bootstrap
cp ../envs/dev/terraform.tfvars.example terraform.tfvars   # y rellénalo
terraform init && terraform apply

# 2. Cada entorno (primero dev, después pro)
cd ../envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=../../backend-aws.hcl         # AWS: pon tu bucket en el fichero
# Floci: terraform init -backend-config=../../backend-floci.hcl -backend-config="bucket=<tu bucket>"
terraform apply
```

## CI/CD

| Workflow | Cuándo | Qué hace |
| --- | --- | --- |
| `ci.yml` | Cada push y pull request | `scripts/ci.sh`: fmt, validate, TFLint y Trivy |
| `despliegue-prueba.yml` | Push a `main` o a mano | Arranca Floci y ejecuta `scripts/despliegue-prueba.sh` |
| `despliegue-aws.yml` | A mano (opcional) | plan y apply en AWS con OIDC |

Sin GitHub, los mismos scripts se ejecutan en local:

```bash
./scripts/ci.sh
./scripts/despliegue-prueba.sh      # con Floci arrancado en localhost:4566
```

`despliegue-prueba.sh` solo despliega en Floci, nunca en AWS, y trabaja sobre una copia temporal del proyecto: no usa tus `terraform.tfvars`, tu estado ni tus `.terraform/`. Si no tienes Floci en local, usa el workflow `Despliegue de prueba` de GitHub Actions, que levanta su propio Floci.

## Entrega

```bash
./scripts/empaquetar.sh             # genera entrega.zip con los ficheros versionados
```

## Destruir

En orden inverso: `envs/pro`, `envs/dev` y, por último, `bootstrap`.
