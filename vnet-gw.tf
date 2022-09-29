#######################################################################
## Create VNET Gateway - onprem
#######################################################################
resource "azurerm_public_ip" "vnet-gw-onprem-pubip-1" {
    name                = "vnet-gw-onprem-pubip-1"
    location            = var.location-onprem
    resource_group_name = azurerm_resource_group.vwan-microhack-spoke-rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
    #zones               = ["1","2","3"]    
  }
  
  resource "azurerm_public_ip" "vnet-gw-onprem-pubip-2" {
    name                = "vnet-gw-onprem-pubip-2"
    location            = var.location-onprem
    resource_group_name = azurerm_resource_group.vwan-microhack-spoke-rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
    #zones               = ["1","2","3"]    
  }
  resource "azurerm_virtual_network_gateway" "vnet-gw-onprem" {
    name                = "vnet-gw-onprem"
    location            = var.location-onprem
    resource_group_name = azurerm_resource_group.vwan-microhack-spoke-rg.name
  
    type     = "Vpn"
    vpn_type = "RouteBased"
  
    active_active = false
    enable_bgp    = true
    sku           = "VpnGw1"
  
    bgp_settings{
      asn = 64000
    } 

    ip_configuration {
      name                          = "vnet-gw-onprem-ip-config-1"
      public_ip_address_id          = azurerm_public_ip.vnet-gw-onprem-pubip-1.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.onprem-gateway-subnet.id
    }
    #ip_configuration {
    #  name                          = "vnet-gw-onprem-ip-config-2"
    #  public_ip_address_id          = azurerm_public_ip.vnet-gw-onprem-pubip-2.id
    #  private_ip_address_allocation = "Dynamic"
    #  subnet_id                     = azurerm_subnet.onprem-gateway-subnet.id
    #}
  }

#######################################################################
## Create Local Network Gateways - for we-hub
#######################################################################

resource "azurerm_local_network_gateway" "we-hub" {
  name                = "we-hub1"
  resource_group_name = azurerm_resource_group.vwan-microhack-spoke-rg.name
  location            = var.location-onprem
  gateway_address     = azurerm_virtual_hub.microhack-we-hub
  address_space       = ["192.168.0.0/16"]
}

#######################################################################
## Create connection Onprem - we-hub
#######################################################################

resource "azurerm_virtual_network_gateway_connection" "onprem-we-hub1" {
  name                = "cient1-we-hub1"
  location            = var.location-onprem
  resource_group_name = azurerm_resource_group.vwan-microhack-spoke-rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vnet-gw-onprem.id
  local_network_gateway_id   = azurerm_local_network_gateway.we-hub.id
  shared_key = var.we-hub_gateway_shared_key

  # NB there is no way to change the ike sa lifetime from its fixed value of 28800 seconds.
  # see https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-devices#ipsec
  # see https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-ipsecikepolicy-rm-powershell
  # see https://www.terraform.io/docs/providers/azurerm/r/virtual_network_gateway_connection.html
  ipsec_policy {
    dh_group         = "DHGroup2048"
    ike_encryption   = "AES128"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES128"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_datasize      = 104857600  # [KB] (104857600KB = 100GB)
    sa_lifetime      = 27000      # [Seconds] (27000s = 7.5h)
  }
}
