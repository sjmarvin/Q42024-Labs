variable "auth_token" {
  type        = string
  description = "My Metal API key" ##located in Metal Console > My Profile > API keys tab
  sensitive   = true
}

variable "equinix_client_id" {
  type        = string
  description = "My API Consumer Key" ## located under 'My Apps' in developer portal. This argument can also be specified with the EQUINIX_API_CLIENTID shell environment variable."
  sensitive   = true
}

variable "equinix_client_secret" {
  type        = string
  description = "My API Consumer secret" ## located under 'My Apps' in developer portal. This argument can also be specified with the EQUINIX_API_CLIENTSECRET shell environment variable."
  sensitive   = true
}

variable "metal_project_id" {
  type        = string
  description = "smarvin-lab-ID"
}

variable "plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "c3.small.x86"
}

variable "operating_system" {
  type        = string
  description = "OS you want to deploy"
  default     = "ubuntu_20_04"
}


variable "metro1" {
  type        = string
  description = "Metal A-side Metro"
  default     = "da"
}

variable "metro2" {
 type        = string
 description = "Metal Z-side metro"
 default     = "sv"
}

variable "vxlan" {
  type        = string
  description = "VXLAN Network Identifier"
  default     = "47"
}

variable "conn_id" {
  type        = string
  description = "Metal's connection ID in metal's portal"
  default     = "Connection_ID"
}

variable "aside_port" {
  type        = string
  description = "Metal's dedicated port ID in fabric portal"
  default     = "aside_port"
}
