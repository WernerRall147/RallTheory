terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
    backend "azurerm" {
        resource_group_name  = "<Resource Group>"
        storage_account_name = "<Storage Account>"
        container_name       = "<Container>"
        key                  = "<tfstate file name>"
    }

}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}



resource "azurerm_resource_group" "rg" {
  name     = "<Resource Group Name>"
  location = "<Location>"
  tags = {
    Owner = "<Owner>"
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "<Name>"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "vnet1" {
   name = "vnet1"
   location = azurerm_resource_group.rg.location
   address_space = ["10.0.0.0/16"]
   resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet1" {
   name = "sub1"
   virtual_network_name = azurerm_virtual_network.vnet1.name
   resource_group_name = azurerm_resource_group.rg.name
   address_prefix = "10.0.10.0/24"
}

resource "azurerm_virtual_network" "vnet2" {
   name = "vnet2"
   location = azurerm_resource_group.rg.location
   address_space = ["11.0.0.0/16"]
   resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet2" {
   name = "sub2"
   virtual_network_name = azurerm_virtual_network.vnet2.name
   resource_group_name = azurerm_resource_group.rg.name
   address_prefix = "11.0.10.0/24"
}

resource "azurerm_network_interface" "nic" {
     name = "nic"
     location = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name

     ip_configuration {
         name = "ipconfig"
         subnet_id = azurerm_subnet.subnet2.id
         private_ip_address_allocation = "Dynamic"
         public_ip_address_id = azurerm_public_ip.pip.id
    }
}

resource "azurerm_public_ip" "pip" {
  name = "pip"
  location = azurerm_resource_group.rg.location
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method = "Dynamic"
  domain_name_label = "<Domain Label>"
}

data "azurerm_managed_disk" "OSDisk1" {
name = "OSDisk1"
resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_machine" "vm" {
  name = "<VMName>"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size = "Standard_DS1_v2"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]

  storage_os_disk {
    os_type = "Linux"
    name              = "OSDisk1"
    create_option     = "Attach"
    managed_disk_id = data.azurerm_managed_disk.OSDisk1.id
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }

}

