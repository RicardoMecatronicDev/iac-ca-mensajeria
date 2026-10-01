resource "azurerm_api_management" "main" {
  name                = local.apim_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Consumption_0"
  tags                = local.common_tags
}

# validate-jwt espera la clave simetrica codificada en base64
resource "azurerm_api_management_named_value" "jwt_secret" {
  name                = "jwt-secret"
  display_name        = "jwt-secret"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  value               = base64encode(var.jwt_secret)
  secret              = true
}

resource "azurerm_api_management_api" "mensajeria" {
  name                  = "mensajeria-api"
  display_name          = "Mensajeria API"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  path                  = ""
  protocols             = ["https"]
  service_url           = "https://${azurerm_container_app.api.ingress[0].fqdn}"
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "post_devops" {
  operation_id        = "post-devops"
  api_name            = azurerm_api_management_api.mensajeria.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "POST DevOps"
  method              = "POST"
  url_template        = "/DevOps"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_policy" "jwt" {
  api_name            = azurerm_api_management_api.mensajeria.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <validate-jwt header-name="X-JWT-KWY" failed-validation-httpcode="401" failed-validation-error-message="ERROR">
          <issuer-signing-keys>
            <key>{{jwt-secret}}</key>
          </issuer-signing-keys>
        </validate-jwt>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML

  depends_on = [azurerm_api_management_named_value.jwt_secret]
}

# Cualquier metodo distinto de POST responde ERROR (sin exigir JWT)
locals {
  blocked_methods = toset(["GET", "PUT", "PATCH", "DELETE"])
}

resource "azurerm_api_management_api_operation" "blocked" {
  for_each = local.blocked_methods

  operation_id        = "${lower(each.key)}-devops"
  api_name            = azurerm_api_management_api.mensajeria.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "${each.key} DevOps"
  method              = each.key
  url_template        = "/DevOps"

  response {
    status_code = 405
  }
}

resource "azurerm_api_management_api_operation_policy" "blocked" {
  for_each = local.blocked_methods

  api_name            = azurerm_api_management_api.mensajeria.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  operation_id        = azurerm_api_management_api_operation.blocked[each.key].operation_id

  xml_content = <<-XML
    <policies>
      <inbound>
        <return-response>
          <set-status code="405" reason="Method Not Allowed" />
          <set-header name="Content-Type" exists-action="override">
            <value>text/plain</value>
          </set-header>
          <set-body>ERROR</set-body>
        </return-response>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}
