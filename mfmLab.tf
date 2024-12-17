terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
    }
  }
}
provider "equinix" {
  auth_token    = var.auth_token
  client_id     = var.equinix_client_id
  client_secret = var.equinix_client_secret
}

## allocate same vlans for both Metros

resource "equinix_metal_vlan" "VLAN" {
  description = "Metal VLAN"
  metro       = var.aside
  project_id  = var.metal_project_id
  vxlan       = var.vxlan
}


## create metal Aside
resource "equinix_metal_device" "server_A" {
  hostname         = "AsideServer"
  plan             = var.plan
  metro            = var.aside
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.metal_project_id
  user_data        = data.cloudinit_config.config1.rendered
}

data "cloudinit_config" "config1" {
  gzip          = false # not supported on Equinix Metal
  base64_encode = false # not supported on Equinix Metal

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config1.cfg", {
      VLAN_ID_0  = equinix_metal_vlan.my_vlan1.vxlan
    })
  }
}

resource "equinix_metal_device_network_type" "port_type_test1" {
  device_id = equinix_metal_device.server_A.id
  type      = "hybrid-bonded"
}

resource "equinix_metal_port_vlan_attachment" "vlan_attach_test1" {
  device_id = equinix_metal_device_network_type.port_type_test1.id
  port_name = "bond0"  
  vlan_vnid = equinix_metal_vlan.my_vlan1.vxlan
}

## create metal node2

resource "equinix_metal_vlan" "my_vlan2" {
  description = "Metal's metro VLAN"
  metro       = var.zside
  project_id  = var.metal_project_id
  vxlan       = var.vxlan
}
resource "equinix_metal_device" "metal_node2" {
  hostname         = "ZsideServer"
  plan             = var.plan
  metro            = var.zside
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.metal_project_id
  user_data        = data.cloudinit_config.config2.rendered
}

data "cloudinit_config" "config2" {
  gzip          = false # not supported on Equinix Metal
  base64_encode = false # not supported on Equinix Metal

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config2.cfg", {
      VLAN_ID_0  = equinix_metal_vlan.my_vlan2.vxlan
    })
  }
}

resource "equinix_metal_device_network_type" "port_type_test2" {
  device_id = equinix_metal_device.server_Z.id
  type      = "hybrid-bonded"
}

resource "equinix_metal_port_vlan_attachment" "vlan_attach_test2" {
  device_id = equinix_metal_device_network_type.port_type_test2.id
  port_name = "bond0" 
  vlan_vnid = equinix_metal_vlan.my_vlan2.vxlan
}

## Create a VC via dedciated port in metro1

/* this is the "Interconnection ID" of the "DA-Metal-to-Fabric-Dedicated-Redundant-Port" via Metal's portal*/

data "equinix_metal_connection" "metro1_port" {
  connection_id = var.conn_id
}

resource "equinix_metal_virtual_circuit" "metro1_vc" {
  connection_id = var.conn_id
  project_id    = var.metal_project_id
  port_id       = data.equinix_metal_connection.metro1_port.ports[0].id
  vlan_id       = equinix_metal_vlan.my_vlan1.vxlan
  nni_vlan      = equinix_metal_vlan.my_vlan1.vxlan
  name          = "sjm-vc-tf"
}


## Request a Metal shared connection and get a z-side token from Metal

resource "equinix_metal_connection" "example" {
  name               = "sjm-tf-metal-port"
  project_id         = var.metal_project_id
  type               = "shared"
  redundancy         = "primary"
  metro              = var.zside
  speed              = "10Gbps"
  service_token_type = "z_side"
  contact_email      = "smarvin@equinix.com"
  vlans              = [equinix_metal_vlan.my_vlan2.vxlan]
}

## Use the token from "equinix_metal_connectio.example" to setup VC in fabric portal. 
## A-side port is  your Metal owned dedicated port in Equinix Fabric portal

resource "equinix_fabric_connection" "fabConn" {
  name = "sjm-tf-metalport-fabric"
  type = "EVPL_VC"
  bandwidth = 50
  notifications {
    type   = "ALL"
    emails = ["sjm@equinix.com"]
  }
  order {
    purchase_order_number = ""
  }
  a_side {
    access_point {
      type = "COLO"
      port {
        uuid = var.aside_port
      }
      link_protocol {
        type     = "DOT1Q"
        vlan_tag = equinix_metal_vlan.my_vlan1.vxlan
      }
      location {
        metro_code  = var.aside
      }
    }
  }
  z_side {
    service_token {
      uuid = equinix_metal_connection.example.service_tokens.0.id
    }
  }
}

## Output the metal node names and IPs, so you can login via 'ssh root@IP' 

output "Aside_name" {
  value       = equinix_metal_device.metal_node1.hostname
  description = "Your metal_node1 hostname:"
}

output "Aside_IP" {
  value       = equinix_metal_device.metal_node1.access_public_ipv4
  description = "Your metal_node1 IP:"
}

output "My_Metro1_VLAN" {
  value = equinix_metal_vlan.my_vlan1.vxlan
}

output "Zside_name" {
  value       = equinix_metal_device.metal_node2.hostname
  description = "Your metal_node2 hostname:"
}

output "Zside_IP" {
  value       = equinix_metal_device.metal_node2.access_public_ipv4
  description = "Your metal_node2 IP:"
}
output "Zside_VLAN" {
  value = equinix_metal_vlan.my_vlan2.vxlan
}

output "Z_side_Service_Token" {
  value = equinix_metal_connection.example.service_tokens.0.id
}
output "Z_side_VC_UUID" {
  value = equinix_fabric_connection.fabConn.id
}
