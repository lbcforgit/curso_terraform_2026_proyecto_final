# Documentación del proyecto

**Autor/a:** Luis Besteiro Calvo
**Opción:** Floci

## 1. Arquitectura

Cada entorno crea su propia VPC con el rango 10.0.0.0/16. Dentro de cada VPC, las subredes públicas comparten una tabla con la ruta 0.0.0.0/0 hacia el Internet Gateway. Cada instancia arranca con Ubuntu 24.04 y su script de inicialización instala nginx y escribe una página que identifica el entorno y el servidor.

| Recurso | dev | pro |
| --- | --- | --- |
| Zonas | 1 subred pública en `eu-west-1a` | 2 subredes públicas, una en `eu-west-1a` y otra en `eu-west-1b` |
| Servidores | 1 EC2 `t3.micro` con nginx: `luis-besteiro-dev-a` | 2 EC2 `t3.micro` con nginx: `luis-besteiro-pro-a` en la primera zona y `luis-besteiro-pro-b` en la segunda |
| Bucket de logs | No se crea | `luis-besteiro-pro-logs`, con versionado y caducidad a los 30 días tanto para objetos actuales como para versiones anteriores (desde que dejan de ser actuales) |
| Estado | S3 de Floci: `s3://luis-besteiro-tfstate-proyecto/dev/terraform.tfstate` | S3 de Floci: `s3://luis-besteiro-tfstate-proyecto/pro/terraform.tfstate` |

## 2. Cómo se ha organizado el código

Explica los módulos, los directorios de entorno y los bucles que usas.

## 3. Decisiones de seguridad

| Medida | Dónde | Por qué |
| --- | --- | --- |
| Bloqueo del acceso público a S3 | `bootstrap/main.tf` y `modules/logs/main.tf` | Los cuatro controles de acceso público protegen el estado y los logs frente a su exposición mediante ACL o políticas públicas. |
| Cifrado en reposo | Buckets de estado y de logs | Ambos configuran SSE-S3 con AES256 para cifrar los objetos almacenados. |
| Versionado | Buckets de estado y de logs | Permite recuperar versiones anteriores tras una sobrescritura o un borrado accidental, mientras se conserven. |
| Bloqueo del estado | `backend-floci.hcl` | `use_lockfile = true` evita que dos operaciones de Terraform escriban a la vez en el estado de un mismo entorno. |
| Entrada limitada a HTTP | `modules/servidor_web`, utilizado por ambos entornos | La única regla de entrada permite TCP/80 desde cualquier IPv4 para servir nginx. El grupo de seguridad no abre SSH. |
| Metadatos con token obligatorio | `modules/servidor_web/main.tf` | `http_tokens = "required"` exige IMDSv2 para consultar los metadatos de la instancia. |
| Cifrado del volumen raíz | `modules/servidor_web/main.tf` | `root_block_device.encrypted = true` protege en reposo los datos del disco de cada servidor. |

### Hallazgos de Trivy aceptados

Cada excepción (`#trivy:ignore:...`) debe estar justificada aquí y en un comentario junto al recurso.

| Regla | Severidad | Justificación |
| --- | --- | --- |
| `AWS-0132` | HIGH (alta) | En `bootstrap/main.tf` (estado) y `modules/logs/main.tf` (logs) se acepta SSE-S3 con AES256. El ejercicio mantiene el cifrado en reposo y prescinde de gestionar una clave propia en KMS. |
| `AWS-0164` | HIGH (alta) | En `modules/red/main.tf` las subredes asignan una IP pública al lanzar cada instancia. Así se puede acceder directamente a nginx en una práctica sin balanceador. |
| `AWS-0104` | CRITICAL (crítica) | En `modules/servidor_web/main.tf` se permite la salida a cualquier IPv4 con cualquier protocolo. El arranque necesita acceder a los repositorios para actualizar el índice de paquetes e instalar nginx. Para simplificar el laboratorio se acepta una regla más amplia que ese tráfico. |

## 4. CI/CD

Explica qué hace cada workflow y cuándo se ejecuta. Si no has usado GitHub, indica que has ejecutado los scripts en local.

## 5. Cómo desplegar

```bash
# Backend
cd bootstrap
terraform init && terraform apply
# Entorno dev
cd ../envs/dev
terraform init -backend-config=../../backend-floci.hcl -backend-config="bucket=bucket=luis-besteiro-tfstate-proyecto"
terraform apply
# Entorno pro
cd ../pro
terraform init -backend-config=../../backend-floci.hcl -backend-config="bucket=bucket=luis-besteiro-tfstate-proyecto"
terraform apply
## Destruir
terraform destroy
cd ../dev
terraform destroy
cd ../bootstrap
terraform destroy
```

## 6. Mejoras posibles

- **Alta disponibilidad del servicio web**. Añadir un balanceador con HTTPS. Un único nombre de acceso permitiría seguir atendiendo peticiones cuando una instancia dejase de responder.
- **Reducir la exposición de las instancias**. Con el balanceador en las subredes públicas, trasladar los servidores a subredes privadas, permitir la entrada desde el grupo de seguridad del balanceador y limitar la salida a los destinos necesarios para las actualizaciones.
