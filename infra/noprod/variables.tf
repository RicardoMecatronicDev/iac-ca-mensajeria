variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "location" {
  type        = string
  description = "Azure region principal"
  default     = "eastus2"
}

variable "project" {
  type        = string
  description = "Nombre del proyecto (minusculas, sin espacios)"
  default     = "mensajeria"
}

variable "environment" {
  type        = string
  description = "Ambiente de despliegue"
  default     = "noprod"

  validation {
    condition     = contains(["noprod", "prod"], var.environment)
    error_message = "environment debe ser noprod o prod."
  }
}

variable "equipo" {
  type        = string
  description = "Nombre del equipo propietario del recurso"
  default     = "comunicaciones"
}

variable "min_replicas" {
  type        = number
  description = "Replicas minimas de la Container App"
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "Replicas maximas de la Container App"
  default     = 2
}

variable "target_port" {
  type        = number
  description = "Puerto del contenedor. 80 mientras se use la imagen placeholder; el pipeline de la app lo ajusta"
  default     = 80
}

variable "container_image" {
  type        = string
  description = "Imagen inicial (placeholder). El pipeline de la app la reemplaza"
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "api_key" {
  type        = string
  description = "API Key que exige el endpoint"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "Clave de firma HS256 de los JWT (minimo 32 caracteres)"
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 32
    error_message = "jwt_secret debe tener al menos 32 caracteres."
  }
}

variable "publisher_name" {
  type        = string
  description = "Nombre del publisher de API Management"
}

variable "publisher_email" {
  type        = string
  description = "Correo del publisher de API Management"
}
