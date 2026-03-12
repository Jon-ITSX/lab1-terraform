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

variable "machine_type" {
  description = "Machine type for the VM. Default keeps educator baseline."
  type        = string
  default     = "e2-micro"
}

variable "student_id" {
  description = "Your student identifier"
  type        = string
}

variable "snapshot_start_time_utc" {
  description = "Daily snapshot start time in UTC, format HH:MM."
  type        = string
  default     = "03:00"
}

variable "snapshot_retention_days" {
  description = "Number of days snapshots are retained."
  type        = number
  default     = 7
}

variable "gcp_sa_key_json" {
  description = "Service account key JSON content for Terraform provider authentication."
  type        = string
  sensitive   = true
}
