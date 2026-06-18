
# default provider configuration
provider "azurerm" {
  features {}
}
# provider-1 configuration
provider "azurerm" {
  alias    = "provider-1"
  features {}
  subscription_id = "SUBSCRIPTION_ID_1"
  tenant_id       = "TENANT_ID_1"
}
# provider-2 configuration
provider "azurerm" {
  alias    = "provider-2"
  features {}
  virtual_machine {
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true
  } 
  subscription_id = "SUBSCRIPTION_ID_2"
  tenant_id       = "TENANT_ID_2"
}