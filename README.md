# FreshBox SpA — Arquitectura Cloud EP1 (ARY1102)

Repositorio del encargo de Evaluación Parcial 1: análisis, diseño e
implementación de una arquitectura cloud base en AWS para FreshBox SpA
(catálogo online de productos orgánicos), con infraestructura como código
en Terraform.

## Estructura del repositorio

```
freshbox-cloud-architecture/
├── README.md
├── .gitignore
├── infra/                     <- Terraform (ver infra/README.md)
│   ├── main.tf
│   └── modules/ (network, security, ecr, alb, compute, database)
├── sql/
│   └── init.sql               <- esquema real: BD freshbox, tabla productos
├── src/                        <- codigo fuente de los 5 microservicios (agregar)
│   ├── microservicioFrontend/
│   └── microserviciosBackend/
│       ├── get-products/
│       ├── create-product/
│       ├── update-product/
│       └── delete-product/
├── docs/
│   └── FreshBox_Arquitectura_TOBE_v2.drawio   <- diagrama editable (agregar)
└── scripts/
    ├── ecr-push.sh                 <- build ARM64 + push (usado por el flujo Terraform)
    ├── user-data-ec2.sh            <- script de referencia del docente
    ├── deploy-containers.sh        <- script de referencia del docente
    ├── ecr-push-docente.sh         <- script de referencia del docente
    └── guia-docente-ep1.md         <- guia de implementacion del docente
```

## Arquitectura

Ver diagrama completo en `docs/FreshBox_Arquitectura_TOBE_v2.drawio`
(abrir en https://app.diagrams.net/).

VPC de 3 capas (Pública / Privada App / Privada Data), Multi-AZ. ALB con
1 Target Group (puerto 80) — el frontend (nginx) hace de reverse proxy
interno hacia los 4 microservicios backend. Auto Scaling Group con EC2 +
Docker (min:2/max:4, 5 contenedores por instancia). MySQL 8 en instancia
única + AWS Backup. 5 repositorios en Amazon ECR.

## Cómo desplegar

Ver instrucciones detalladas en [`infra/README.md`](infra/README.md).

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform plan && terraform apply
```

Luego construir y subir las imágenes:

```bash
./scripts/ecr-push.sh
```

## Prueba local (sin AWS)

```bash
docker compose build
docker compose up -d
```

- Frontend: http://localhost:8080
- API: http://localhost:3001/api/products

## Convención de commits

Conventional Commits: `feat:`, `fix:`, `docs:`, `infra:`, `chore:`

## Ramas

- `main`: versión estable / entregable
- `develop`: rama de trabajo activo

---
2026 — FreshBox SpA — Evaluación Parcial 1, Arquitectura Cloud (ARY1102)
