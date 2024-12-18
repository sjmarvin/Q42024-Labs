terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
     }
  }
}
 # Configuration options 
  # Credentials for only Equinix Metal resources provider "equinix" {
  auth_token = var.auth_token
  client_id = var.equinix_client_id
  client_secret = var.equinix_client_secret

}
# Create a new VLAN in metro "da"
resource "equinix_metal_vlan" "vlan1" {
  description = "VLAN in Dallas"
  metro       = var.metro1
  project_id  = var.metal_project_id
  vxlan       = 47
}

# Create a new server in metro "da"
resource "equinix_metal_device" "test" {
  hostname         = "sjmLab1"
  plan             = var.plan
  metro            = var.metro1
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.metal_project_id
  user_data = format("#!/bin/bash\napt update\napt install vlan\nmodprobe 8021q\necho '8021q' >> /etc/modules-load.d/networking.conf\nip link add link bond0 name bond0.%g type vlan id %g\nip addr add 192.168.100.10/24 brd 192.168.100.255 dev bond0.%g\nip link set dev bond0.%g up", equinix_metal_vlan.vlan1.vxlan, equinix_metal_vlan.vlan1.vxlan, equinix_metal_vlan.vlan1.vxlan, equinix_metal_vlan.vlan1.vxlan)
}

resource "equinix_metal_port_vlan_attachment" "test" {
  device_id = equinix_metal_device.test.id
  port_name = "bond0"
  vlan_vnid = equinix_metal_vlan.vlan1.vxlan
}

# Create a new VLAN in metro "sv"
resource "equinix_metal_vlan" "vlan2" {
  description = "VLAN in Silicon Valley"
  metro       = var.metro2
  project_id  = var.metal_project_id
  vxlan       = 47
}

# Create a new Server in metro "sv"
resource "equinix_metal_device" "test2" {
  hostname         = "sjmLab2"
  plan             = var.plan
  metro            = var.metro1
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.metal_project_id
  user_data = format("#!/bin/bash\napt update\napt install vlan\nmodprobe 8021q\necho '8021q' >> /etc/modules-load.d/networking.conf\nip link add link bond0 name bond0.%g type vlan id %g\nip addr add 192.168.100.20/24 brd 192.168.100.255 dev bond0.%g\nip link set dev bond0.%g up", equinix_metal_vlan.vlan2.vxlan, equinix_metal_vlan.vlan2.vxlan, equinix_metal_vlan.vlan2.vxlan,equinix_metal_vlan.vlan2.vxlan)
}

resource "equinix_metal_port_vlan_attachment" "test2" {
  device_id = equinix_metal_device.test2.id
  port_name = "bond0"
  vlan_vnid = equinix_metal_vlan.vlan2.vxlan
}

## Create VC via dedicated port in metro "da"
## this is the "Interconnection ID" of the "DA-Metal-to-Fabric-Dedicated-Redundant-Port" via Metal's portal
data "equinix_metal_connection" "metro1_port" {
  connection_id = var.conn_id
}

resource "equinix_metal_virtual_circuit" "metro1_vc" {
  connection_id = var.conn_id
  project_id    = var.metal_project_id
  port_id       = data.equinix_metal_connection.metro1_port.ports[0].id
  vlan_id       = equinix_metal_vlan.vlan1.vxlan
  nni_vlan      = equinix_metal_vlan.vlan1.vxlan
  name          = "sjm-tf-vc"
}
## Request a Metal connection and get a z-side token from Metal
resource "equinix_metal_connection" "example" {
  name               = "sjm-tf-metal-port"
  project_id         = var.metal_project_id
  type               = "shared"
  redundancy         = "primary"
  metro              = var.metro2
  speed              = "10Gbps"
  service_token_type = "z_side"
  contact_email      = "smarvin@equinix.com"
  vlans              = [equinix_metal_vlan.vlan2.vxlan]
}

## Use the token from "equinix_metal_connection.example" to setup VC in fabric portal:
## A-side port is your Metal owned dedicated port in Equinix Fabric portal

resource "equinix_fabric_connection" "this" {
  name = "sjm-metalport-fabric"
  type = "EVPL_VC"
  bandwidth = 50
  notifications {
    type   = "ALL"
    emails = ["smarvin@equinix.com"]
  }
  order {
    purchase_order_number = ""
  }
  a_side {
    access_point {
      type = "COLO"
      port {
        uuid = var.aside_port.id
      }
      link_protocol {
        type     = "DOT1Q"
        vlan_tag = equinix_metal_vlan.vlan1.vxlan
      }
        metro_code = var.metro1
      }
    }
  }
  z_side {
    service_token {
      uuid = equinix_metal_connection.example.service_tokens.0.id
    }
  }
}
