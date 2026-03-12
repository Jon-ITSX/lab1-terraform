variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-north1"
}

variable "zone" {
  description = "GCP Zone (settable to avoid temporary capacity issues in a specific zone)."
  type        = string
  default     = "europe-north1-b"
}

variable "student_id" {
  description = "Your student identifier"
  type        = string
}

variable "gcp_sa_key_json" {
  description = "Service account key JSON content for Terraform provider authentication."
  type        = string
  sensitive   = true
}
