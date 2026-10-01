# iac-ca-mensajeria

Infraestructura como código (Terraform) en Azure para una API de mensajería sobre **Azure Container Apps**. Es la parte de **infraestructura** de una prueba técnica DevOps; el código de la aplicación vive en [`python-api-mensajeria`](https://github.com/RicardoMecatronicDev/python-api-mensajeria).

## Arquitectura

```
cliente (curl)
    │ HTTPS
    ▼
API Management (Consumption)       valida el JWT, bloquea métodos distintos de POST
    │
    ▼
Container Apps (ingress)           balanceador integrado
    ├─ réplica 1 ┐
    └─ réplica 2 ┘ ...hasta 5    escala por carga HTTP
    ▲
    └── imagen desde Azure Container Registry (acceso por identidad, sin contraseñas)
```

## Recursos por ambiente

| Recurso | Nombre en prod | Características |
|---|---|---|
| Resource Group | `rg-mensajeria-prod` | |
| Log Analytics | `log-mensajeria-prod-01` | 30 días de retención |
| Container Registry | `acrmensajeriaprod01` | Basic, sin usuario admin |
| Identidad administrada | `id-mensajeria-prod-api` | Rol `AcrPull` sobre el registry |
| Container Apps Environment | `cae-mensajeria-prod-01` | |
| Container App | `ca-mensajeria-prod-api` | 0.25 vCPU, 0.5 GiB; **2 a 5 réplicas** |
| API Management | `apim-mensajeria-prod-01` | Consumption, `validate-jwt` |

El ambiente de pruebas (`noprod`) es idéntico, con 1 a 2 réplicas. Los nombres salen de la variable `environment`, así que no hay valores repetidos entre ambientes. Todos los recursos llevan los tags `region`, `equipo`, `proyecto`, `managed-by` y `environment`.

## Escalabilidad y balanceo

- El **ingress** de Container Apps reparte el tráfico entre réplicas.
- **Mínimo 2 réplicas en prod**, para cumplir el balanceador con al menos dos nodos.
- Regla de escalado HTTP: se crea una réplica nueva al superar **50 peticiones concurrentes** por réplica, hasta el máximo.

## Estructura

```
infra/noprod/     un archivo .tf por tipo de recurso
infra/prod/       misma estructura, otros valores
.github/workflows/terraform_noprod.yml
.github/workflows/terraform_prod.yml
```

Cada ambiente es autónomo y tiene su propio estado remoto (Azure Storage, un contenedor por ambiente) y su propio workflow.

## Pipeline de Terraform

| Evento | Qué pasa |
|---|---|
| Push a `feature/*` o PR | `fmt`, `init`, `validate` y **`plan`** |
| Merge a `master` | `plan` → **aprobación manual** → `apply` |

- Autenticación por **OIDC**: sin contraseñas ni claves guardadas.
- La aprobación es un *environment* de GitHub con revisor obligatorio, distinto para cada ambiente.
- Los valores sensibles viajan como secrets de GitHub y se enmascaran en los logs.

## Decisiones de diseño

- **La imagen inicial es un marcador de posición.** La infraestructura se crea antes de que exista la imagen de la app. Terraform ignora los cambios de imagen y de puerto (`lifecycle.ignore_changes`); los actualiza el pipeline de la aplicación.
- **Un ACR por ambiente.** La imagen se construye una vez y se promueve de noprod a prod copiándola entre registries.
- **API Management en tier Consumption:** cobra por uso (el primer millón de llamadas es gratis) y despliega en minutos.
- **Métodos distintos de POST** responden `405 ERROR` desde APIM, con una operación y una política por método.

## Costo estimado

| | USD/mes |
|---|---|
| Noprod | ~9 a 11 |
| Prod | ~15 |
| **Total** | **~25** |

El ACR (~USD 0.17 al día cada uno) es el único costo fijo; el resto cobra por uso. Precios de lista de Azure para `eastus2`.

## Limitaciones conocidas

- Los secretos (API Key y clave del JWT) quedan en el estado de Terraform, que está en un storage con acceso por Azure AD. Para producción real convendría Key Vault.
- El estado remoto y la identidad de OIDC se crean fuera de este repositorio.
