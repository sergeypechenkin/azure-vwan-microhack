 
  resource "azurerm_virtual_wan" "microhack-vwan" {
    name                = "microhack-vwan"
    resource_group_name = azurerm_resource_group.vwan-microhack-hub-rg.name
    location            = var.location-vwan
  }
  
  resource "azurerm_virtual_hub" "microhack-we-hub" {
    name                = "microhack-we-hub"
    resource_group_name = azurerm_resource_group.vwan-microhack-hub-rg.name
    location            = var.location-vwan-we-hub
    virtual_wan_id      = azurerm_virtual_wan.microhack-vwan.id
    address_prefix      = "192.168.0.0/24"
  }
  
  resource "azurerm_vpn_gateway" "microhack-we-hub-vng" {
    name                = "microhack-we-hub-vng"
    location            = var.location-vwan-we-hub
    resource_group_name = azurerm_resource_group.vwan-microhack-hub-rg.name
    virtual_hub_id      = azurerm_virtual_hub.microhack-we-hub.id
    timeouts {
      create = "4h"
      update = "4h"
      read = "10m"
      delete = "4h"
      
    }
  }



#######################################################################
## Create a VPN Site - to change varuables
#######################################################################


  resource "azurerm_vpn_site" "region1-officesite1" {
  name                = "${var.region1}-officesite-01"
  location            = azurerm_resource_group.region1-rg1.location
  resource_group_name = azurerm_resource_group.region1-rg1.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_cidrs = ["10.100.0.0/24"]
  link {
    name       = "Office-Link-1"
    ip_address = "10.1.0.0"
    speed_in_mbps = "20"
  }
}

#######################################################################
## Create a VPN Site connection - to change varuables
#######################################################################

resource "azurerm_vpn_gateway_connection" "region1-officesite1" {
  name               = "${var.region1}-officesite1-conn"
  vpn_gateway_id     = azurerm_vpn_gateway.region1-gateway1.id
  remote_vpn_site_id = azurerm_vpn_site.region1-officesite1.id

  vpn_link {
    name             = "link1"
    vpn_site_link_id = azurerm_vpn_site.region1-officesite1.link[0].id
  }
}

