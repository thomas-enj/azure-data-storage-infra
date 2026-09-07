data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  current_object_id   = data.azurerm_client_config.current.object_id
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.aks_location
  environment         = var.environment
}

module "storage" {
  source              = "./modules/storage"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  environment         = var.environment
  corporate_ip        = var.corporate_ip
  aks_subnet_id       = module.aks.node_subnet_id
  key_vault_id        = module.keyvault.key_vault_id
  key_vault_key_name  = module.keyvault.key_name
}

module "identity" {
  source              = "./modules/identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  environment         = var.environment
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  storage_account_id  = module.storage.storage_account_id
}