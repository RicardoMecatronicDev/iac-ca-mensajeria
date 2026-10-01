terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cross-devops"
    storage_account_name = "stcrosstfstate01"
    container_name       = "noprod"
    key                  = "mensajeria-noprod.tfstate"
    use_azuread_auth     = true
  }
}
