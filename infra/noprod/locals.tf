locals {
  common_tags = {
    region       = var.location
    equipo       = var.equipo
    proyecto     = var.project
    "managed-by" = "terraform"
    environment  = var.environment
  }

  # Nombres segun convencion BIT
  rg_name       = "rg-${var.project}-${var.environment}"
  log_name      = "log-${var.project}-${var.environment}-01"
  acr_name      = "acr${var.project}${var.environment}01"
  identity_name = "id-${var.project}-${var.environment}-api"
  cae_name      = "cae-${var.project}-${var.environment}-01"
  ca_name       = "ca-${var.project}-${var.environment}-api"
  apim_name     = "apim-${var.project}-${var.environment}-01"
}
