resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-aks-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoint {
    service = "Microsoft.Storage"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-ads-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "veleroaks${var.environment}"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v3"
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  node_provisioning_profile {
    mode = "Manual"
  }

  # Distinct from the vnet range (10.0.0.0/16) to avoid CIDR overlap with the AKS subnet
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }
}

# Création d'un node dédié pour la base de données MySQL
resource "azurerm_kubernetes_cluster_node_pool" "db_pool" {
  name                  = "dbpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  
  vm_size               = "Standard_D2s_v5"
  
  node_count            = 1                  
  mode                  = "User"

  node_labels = {
    workload = "database"
    db_type  = "mysql"
  }

  node_taints = [
    "workload=database:NoSchedule"
  ]
}