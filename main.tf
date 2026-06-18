# Resource Group
resource "azurerm_resource_group" "tf_rg" {
  name     = "my-tf-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "tf_vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name
}

# Subnet
resource "azurerm_subnet" "tf_subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.tf_rg.name
  virtual_network_name = azurerm_virtual_network.tf_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP (Standard SKU)
resource "azurerm_public_ip" "tf_pip" {
  count               = 2
  name                = "tf-public-ip-${count.index}"
  resource_group_name = azurerm_resource_group.tf_rg.name
  location            = azurerm_resource_group.tf_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "tf_nic" {
  count               = 2
  name                = "tf-nic-${count.index}"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_pip[count.index].id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "tf_nsg" {
  name                = "tf-nsg"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name

  # Allow SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"   # change to your IP for security
    destination_address_prefix = "*"
  }

  # Allow Outbound (important for Standard SKU)
  security_rule {
    name                       = "Allow-Outbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSG to NIC
resource "azurerm_network_interface_security_group_association" "tf_nsg_assoc" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.tf_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.tf_nsg.id
}

# Linux VM
resource "azurerm_linux_virtual_machine" "tf_vm" {
  count               = 2
  name                = "tf-vm-${count.index}"
  resource_group_name = azurerm_resource_group.tf_rg.name
  location            = azurerm_resource_group.tf_rg.location
  size                = "Standard_D2s_v3"

  admin_username = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.tf_nic[count.index].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/shivanathroy/.ssh/id_rsa.pub")  # 🔥 FIXED PATH
  }

  disable_password_authentication = true
}