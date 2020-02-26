provider "azurerm" {
    version         = "1.27"
    client_id       = "9b8d3806-1391-4100-aa7c-e382575b2bd9"
    client_secret   = "7kK6oo30dqTvnXimQIE/=:njhLXRBh-w"
    tenant_id       = "c3902891-109d-409f-a046-8454e72af7d5"
    subscription_id = "b37804fd-9149-4e72-8aa5-30d8256b2fe0"
}
resource "azurerm_resource_group" "rg" {
  name     = "tfex-recovery_vaultmadhurhappy"
  location = "eastus"
}
data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "clientcon" {
}
data "azurerm_client_config" "client_config" {}
resource "azurerm_role_assignment" "roleassignm" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.client_config.service_principal_object_id

}

resource "azurerm_virtual_network" "vnbyterraform" {
    resource_group_name = azurerm_resource_group.rg.name
    name = "vmvndata"
    location = "${azurerm_resource_group.rg.location}"
    address_space = ["10.0.0.0/16"]
    
}
resource "azurerm_subnet" "subnet" {
    resource_group_name = "${azurerm_resource_group.rg.name}"
    name = "vmsubnet"
    virtual_network_name = "${ azurerm_virtual_network.vnbyterraform.name}"
    address_prefix = "10.0.2.0/24"
  }
resource "azurerm_public_ip" "pip" {
    name = "vmpip"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${azurerm_resource_group.rg.location}"
    tags = {
        environment = "stag"
    }
    allocation_method = "Dynamic"
  
}
resource "azurerm_network_interface" "nid" {
    name = "vmniddata"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${azurerm_resource_group.rg.location}"
    ip_configuration {
        name = "nidvmdata"
        private_ip_address_allocation = "Dynamic"
        subnet_id = azurerm_subnet.subnet.id
        public_ip_address_id = azurerm_public_ip.pip.id
        
       
    } 
}


resource "azurerm_virtual_machine" "vm1" {
  name = "testvmwithbackupp"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location = "${azurerm_resource_group.rg.location}"
  vm_size = "Standard_DS1_v2"
  network_interface_ids = ["${azurerm_network_interface.nid.id}"]
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }

}
resource "azurerm_recovery_services_vault" "vault" {
  name                = "recoverymadhur-test"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  tags = {
      Environment = "stag"
  }
}
resource "azurerm_recovery_services_protection_policy_vm" "policyjc" {
    name = "vmbackcyindia"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    recovery_vault_name = "${azurerm_recovery_services_vault.vault.name}"
    
    backup {
        frequency = "Daily"
        time = "23:00"
    }
    retention_daily  {
        count =14
    }
    
}
resource "azurerm_recovery_services_protected_vm" "protectedvm" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
 
  recovery_vault_name = "${azurerm_recovery_services_vault.vault.name}"
  source_vm_id        = "${azurerm_virtual_machine.vm1.id}"
  backup_policy_id    = "${azurerm_recovery_services_protection_policy_vm.policyjc.id}"
}

output "Public-Ip-Address" {
  value = "data.azurerm_public_ip.pip.ip_address"
}




