variable "GCP_AUTH_JSON" {

}
variable "GCP_PROJECT" {
  type        = string
  description = "Project id"
}

variable "GCP_REGION" {
  type        = string
  description = "Region"
  default     = "europe-west2"
}

variable "GCP_ZONE" {
  type        = string
  description = "Region"
  default     = "europe-west2-b"
}

variable "gcp_sql_root_user_name" {
  default = "deptrack-root"
}

variable "gcp_sql_root_user_pw" {}

variable "authorized_network" {}

variable "database_name" {
  default = "deptrack-master"
}

variable "database_version" {
  default = "MYSQL_5_7"
}

variable "k8s_cluster_name" {
  description = "GKE cluster name"
  default     = "dtrack-prod-cluster"
}

variable "initial_node_count" {
  description = "Number of worker VMs to initially create"
  default     = 3
}
variable "max_node_count" {
  description = "Maximum number of worker nodes"
  default     = 10
}

variable "node_machine_type" {
  description = "GCE machine type"
  default     = "n1-standard-1"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  default     = "30"
}

variable "environment" {
  description = "value passed to Environment tag"
  default     = "dtrack-prod"
}
