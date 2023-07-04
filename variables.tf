variable "credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
}

variable "project_name" {
  description = "Name of the GCP project"
  type        = string
}

variable "project_id" {
  description = "ID of the GCP project"
  type        = string
}

variable "org_id" {
  description = "ID of the GCP organization"
  type        = string
}

variable "service_account_id" {
  description = "ID of the GCP service account"
  type        = string
}