provider "azurerm" {
  features {}
}
###########Create a resource group in Azure###########

resource "azurerm_resource_group" "terrafrom-rg" {
  name     = "rg-terraform"
  location = "East US"
}
