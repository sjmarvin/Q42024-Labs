terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
    }
  }
}

provider "equinix" {
  client_id     = "my_client_id"
  client_secret = "my_client_secret"
}
## Remove data fields and hardcode account number "1" in all account_number fields, instead
## data "equinix_network_account" "sv" {
## metro_code = "SV"
## project_id = "f1a596ed-d24a-497c-92a8-44e0923cee62"
## }

## data "equinix_network_account" "da" {
## metro_code = "DA"
## project_id = "f1a596ed-d24a-497c-92a8-44e0923cee62"
## }


resource "equinix_network_device" "c8000v-sv" {
  name            = "tf-c8kv-sv-sjm"
  metro_code      = "SV"
  type_code       = "C8000V"
  self_managed    = true
  byol            = true
  package_code    = "network-essentials"
  notifications   = ["smarvin@equinix.com"]
  hostname        = "C8KV-SV"
  account_number  = 1
  version         = "17.6.6a"
  core_count      = 2
  term_length     = 1
  ## license_token = "valid-license-token" -- no license-token required
  additional_bandwidth = 50
  ssh_key {
    username = "smarvin"
    key_name = "sjmkey"
  }
  acl_template_id = "c2c4264c-7243-4599-b94f-5ea3c2321eda"
}

resource "equinix_network_device" "c8000v-da" {
  name            = "tf-c8kv-da-sjm"
  metro_code      = "DA"
  type_code       = "C8000V"
  self_managed    = true
  byol            = true
  package_code    = "network-essentials"
  notifications   = ["smarvin@equinix.com"]
  hostname        = "C8KV-DA"
  account_number  = 1
  version         = "17.6.6a"
  core_count      = 2
  term_length     = 1
  ## license_token = "valid-license-token" -- no license-token required
  additional_bandwidth = 50
  ssh_key {
    username = "smarvin"
    key_name = "sjmkey"
  }
  acl_template_id = "c2c4264c-7243-4599-b94f-5ea3c2321eda"
}

resource "equinix_network_device_link" "tf-dlg" {
  name   = "tf-dlg-sjm"
  device {
    id           = equinix_network_device.c8000v-sv.uuid
    ## asn       = equinix_network_device.test.asn > 0 ? equinix_network_device.test.asn : 25658
    interface_id = 6
  }
  device {
    id           = equinix_network_device.c8000v-da.uuid
    ## asn       = equinix_network_device.test.secondary_device[0].asn > 0 ?  equinix_network_device.test.secondary_device[0].asn : 36641
    interface_id = 6
  }
  link {
    account_number  = 1
    src_metro_code  = equinix_network_device.c8000v-sv.metro_code
    dst_metro_code  = equinix_network_device.c8000v-da.metro_code
    throughput      = "50"
    throughput_unit = "Mbps"
  }
}
