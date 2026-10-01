terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cross-devops"
    storage_account_name = "stcrosstfstate01"
    container_name       = "prod"
    key                  = "mensajeria-prod.tfstate"
    use_azuread_auth     = true
  }
}
