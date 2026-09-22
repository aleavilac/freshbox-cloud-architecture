# FreshBox SpA — Infraestructura Terraform (EP1 Arquitectura Cloud)

Infraestructura como código (IaC) que despliega la arquitectura TO-BE de
FreshBox SpA en AWS: VPC de 3 capas, ALB, Auto Scaling Group con EC2+Docker,
MySQL con AWS Backup, y 5 repositorios ECR.

Alineada con los scripts oficiales de referencia del docente
(`../scripts/user-data-ec2.sh`, `deploy-containers.sh`, `ecr-push-docente.sh`,
`guia-docente-ep1.md`) — mismos nombres de recursos, mismos puertos, mismo
patron de despliegue (docker run individuales, no docker-compose en AWS).

## Arquitectura desplegada

| Capa | Recurso | Detalle |
|---|---|---|
| Publica | VPC + 2 subredes publicas | CIDR 10.0.0.0/22, Multi-AZ |
| Publica | Internet Gateway + NAT Gateway | Salida a Internet |
| Publica | Application Load Balancer | 1 Target Group (puerto 80) |
| Privada App | Auto Scaling Group (EC2 t4g.small + Docker) | min:2 / max:4, Multi-AZ, 5 contenedores por instancia |
| Privada Data | EC2 MySQL 8 (AZ1a) | Instancia unica + AWS Backup (snapshot diario, retencion 7 dias) |
| — | Amazon ECR | 5 repositorios (freshbox-frontend + 4 backend) |
| Seguridad | 3 Security Groups encadenados | SG-ALB → SG-APP (puerto 80) → SG-DATA (puerto 3306) |
| Seguridad | Cifrado EBS | Habilitado en EC2 App y EC2 Data |

### Como funciona el ruteo de /api/products (importante)

El ALB tiene **un solo Target Group en el puerto 80**. El contenedor
`frontend` (nginx) recibe TODO el trafico y actua como **reverse proxy
interno**: sirve los archivos estaticos en `/` y reenvia `/api/products`
hacia el backend correspondiente (`freshbox-get-products:3001`,
`freshbox-create-product:3002`, etc.) usando el nombre de contenedor
dentro de la red Docker `freshbox-net`. El ALB nunca conecta directo a
los puertos 3001-3004. Esto requiere que `nginx.conf` (dentro del codigo
fuente del frontend) tenga configurado el `proxy_pass` correspondiente.

## Decision de diseño: ASG vs. 2 EC2 fijas (documentado)

La guia de referencia del docente usa 2 instancias EC2 fijas
("APP-1"/"APP-2"). Este proyecto usa en su lugar un **Auto Scaling Group
(min:2/max:4)**, porque la pauta de evaluacion exige explicitamente
"Auto Scaling Group" como criterio de validacion (puntos 1.7.1 y 2.4 de
la pauta). El ASG sigue cumpliendo el criterio del docente de "2
instancias Multi-AZ con contenedores corriendo", y ademas agrega
escalabilidad automatica real.

## Decision de diseño: Base de datos unica vs. Multi-AZ con replica

Se optó por una **instancia unica MySQL + AWS Backup**, igual que la guia
del docente, porque el termino "Multi-AZ" en la pauta de evaluacion
siempre aparece junto a ALB y ASG ("componentes de alta disponibilidad:
ALB, Multi-AZ, ASG") y nunca se exige explicitamente una replica de base
de datos. La subred privada Data de AZ1b se mantiene en la VPC por
segmentacion de red y como base para una futura ampliacion, pero no aloja
ninguna instancia en esta version.

## Estructura de este directorio

```
infra/
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf
├── terraform.tfvars.example
└── modules/
    ├── network/       # VPC, subredes, IGW, NAT, route tables
    ├── security/       # Security Groups SG-ALB / SG-APP / SG-DATA
    ├── ecr/             # 5 repositorios Docker (nombres planos)
    ├── alb/              # Load Balancer + 1 Target Group (puerto 80)
    ├── compute/            # Launch Template + Auto Scaling Group (capa App)
    └── database/            # EC2 MySQL unica + AWS Backup
```

## Prerrequisitos

1. Terraform >= 1.5.0 instalado localmente.
2. Sesion activa de **AWS Academy Learner Lab** con el laboratorio iniciado.
3. Los 5 microservicios ya construidos (`../src/`), listos para build+push.

## Configurar credenciales (obligatorio en cada sesion del Lab)

AWS Academy entrega credenciales **temporales** que expiran en unas horas.
Antes de correr Terraform, copia desde **AWS Details → AWS CLI**:

```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

## Despliegue paso a paso

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform validate
terraform plan
terraform apply       # escribe "yes" para confirmar
```

```bash
terraform output
```

- `alb_dns_name` → endpoint publico. Frontend: `http://<alb_dns_name>/`,
  API: `http://<alb_dns_name>/api/products`
- `ecr_repository_urls` → URLs para el `docker push`

## Orden de despliegue de la aplicacion

1. `terraform apply` (crea la infra + repos ECR vacios). Las instancias
   App fallaran el primer `docker pull` porque las imagenes aun no
   existen — esperado.
2. `../scripts/ecr-push.sh` (build ARM64 + push de las 5 imagenes).
3. Refresca el ASG para que las instancias corran `user_data` de nuevo
   con las imagenes ya disponibles:

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name $(terraform output -raw asg_name)
```

## Notas de diseño

- **LabInstanceProfile**: AWS Academy no permite crear roles IAM propios;
  se referencia el rol pre-existente via `data "aws_iam_instance_profile"`.
- **t4g.small (ARM/Graviton)**: igual al README original del proyecto.
  Las imagenes Docker deben construirse para `linux/arm64`.
- **NAT Gateway unico** por defecto (ahorro de costos en el Lab). Cambiar
  `single_nat_gateway = false` para 1 NAT por AZ.
- **HTTPS/ACM**: fuera de alcance de esta EP1 (requiere dominio propio).
- **Health check del Target Group** usa GET "/" — requiere que el
  frontend (nginx) responda 200 en la raiz.

## Destruir la infraestructura (al finalizar la evaluacion)

```bash
terraform destroy
```

Ejecutar `destroy` **antes** de cerrar la sesion del Lab si es posible;
las credenciales temporales pueden dejar recursos huerfanos si expiran
primero.
