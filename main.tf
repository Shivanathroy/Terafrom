
###########Create a resource group in Azure###########

resource "azurerm_resource_group" "terrafrom-rg" {
  name     = "rg-terraform"
  location = "East US"
}
############Create a virtual network in Azure###########
resource "azurerm_virtual_network" "terrafrom-vnet" {
  name                = "vnet-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terrafrom-rg.location
  resource_group_name = azurerm_resource_group.terrafrom-rg.name
}
############Create a subnet in Azure###########
resource "azurerm_subnet" "terrafrom-subnet" {
  name                 = "subnet-terraform"
  resource_group_name  = azurerm_resource_group.terrafrom-rg.name
  virtual_network_name = azurerm_virtual_network.terrafrom-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "terrafrom-nic" {
  name                = "nic-terraform"
  location            = azurerm_resource_group.terrafrom-rg.location
  resource_group_name = azurerm_resource_group.terrafrom-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terrafrom-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "terrafrom-vm" {
  name                = "vm-terraform"
  resource_group_name = azurerm_resource_group.terrafrom-rg.name
  location            = azurerm_resource_group.terrafrom-rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terrafrom-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

resource "azurerm_network_security_group" "terrafrom-nsg" {
  name                = "nsg-terraform"
  location            = azurerm_resource_group.terrafrom-rg.location
  resource_group_name = azurerm_resource_group.terrafrom-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_public_ip" "terrafrom-pip" {
  name                = "pip-terraform"
  location            = azurerm_resource_group.terrafrom-rg.location
  resource_group_name = azurerm_resource_group.terrafrom-rg.name

  allocation_method   = "Static"   # ✅ THIS makes it static
  sku                 = "Standard"
}