###### BACKEND & PROVIDER

terraform {
required_providers {
azurerm = {
source = "hashicorp/azurerm"
version = "3.49.0"
}
}
}
provider "azurerm" {
    features{}
}
### Create ressource group
resource "azurerm_resource_group" "demo-resource-group" {
  name     = "terraform-demo"
  location = "West Europe"
}
resource "azurerm_storage_account" "demo-storage-account" {
  name                     = "algostoragedemo"
  resource_group_name      = azurerm_resource_group.demo-resource-group.name
  location                 = azurerm_resource_group.demo-resource-group.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}
data "azurerm_key_vault" "terraform-backend-vault" {

 resource_group_name = "terraform-demo"

 name = "algonautkeyvault1"

}

data "azurerm_key_vault_secret" "sql_admin" {
  name         = "adminname"
  key_vault_id = data.azurerm_key_vault.terraform-backend-vault.id
}

data "azurerm_key_vault_secret" "sql_password" {
  name         = "adminpassword"
  key_vault_id = data.azurerm_key_vault.terraform-backend-vault.id
}

resource "azurerm_mssql_server" "demo-server-algonaut" {
  name                         = "demosqlserveralgonaut"
  resource_group_name          = azurerm_resource_group.demo-resource-group.name
  location                     = azurerm_resource_group.demo-resource-group.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.sql_admin.value
  administrator_login_password = data.azurerm_key_vault_secret.sql_password.value

  tags = {
    environment = "production"
  }
}

resource "azurerm_mssql_database" "example" {
  name                = "algonautsqldatabase"
  server_id         = azurerm_mssql_server.demo-server-algonaut.id
}

resource "azurerm_data_factory" "df" {
  name                = "algodatafactory"
  resource_group_name = azurerm_resource_group.demo-resource-group.name
  location            = azurerm_resource_group.demo-resource-group.location
  tags = {
    environment = "dev"
  }
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "sql_database" {
  name                = "az_dbsql_demosqlserveralgonaut"
   data_factory_id   = azurerm_data_factory.df.id
   connection_string = "Server=tcp:${data.azurerm_key_vault_secret.sql_admin.value}.database.windows.net;Database=algonautsqldatabase;User ID=${data.azurerm_key_vault_secret.sql_admin.value};Password=${data.azurerm_key_vault_secret.sql_password.value};Encrypt=true;Connection Timeout=30;" # Construct the connection string using the retrieved secrets
}


