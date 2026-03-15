# =============================================================================
# TERRAFORM & PROVIDER
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Authenticates against GCP using a service account key passed as a variable.
# Credentials are marked sensitive in variables.tf and never printed in logs.
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.gcp_sa_key_json
}

# =============================================================================
# BOOT DISK
# Declared as a separate resource (not inline in the VM block) for two reasons:
#   1. The snapshot policy attachment resource requires an explicit disk reference.
#      An inline boot_disk block cannot be referenced by other resources.
#   2. A separate disk resource allows the disk to outlive the VM if needed,
#      which simplifies disaster recovery (see docs/dr-documentation.md).
# =============================================================================

resource "google_compute_disk" "vm_boot_disk" {
  name = "${var.student_id}-lab1-vm-boot"
  type = "pd-balanced"
  zone = var.zone
  size = 20

  image = "ubuntu-os-cloud/ubuntu-2204-lts"
}

# =============================================================================
# BACKUP — SNAPSHOT POLICY
# Creates a daily snapshot schedule and attaches it to the boot disk.
# Schedule time and retention period are configurable via variables.
# =============================================================================

resource "google_compute_resource_policy" "daily_snapshot_policy" {
  name   = "${var.student_id}-lab1-daily-snapshot-policy"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.snapshot_start_time_utc
      }
    }

    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "boot_disk_backup_policy" {
  name = google_compute_resource_policy.daily_snapshot_policy.name
  disk = google_compute_disk.vm_boot_disk.name
  zone = var.zone
}

# =============================================================================
# VM INSTANCE
# CIS Benchmark hardening applied via:
#   - Shielded VM (Secure Boot, vTPM, Integrity Monitoring)
#   - startup.sh (OS-level hardening on first boot)
#   - Labels for asset tracking
# =============================================================================

resource "google_compute_instance" "vm" {
  name         = "${var.student_id}-lab1-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    source = google_compute_disk.vm_boot_disk.self_link
  }

  network_interface {
    network = "default"
    access_config {} # Gives the VM an external IP address for SSH access
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    student = var.student_id
    course  = "devsecops-2026"
    lab     = "1"
  }

  tags = ["lab1", "ssh"]

  # Explicit dependency ensures the snapshot policy is attached to the disk
  # before the VM boots. Without this, Terraform might create the VM before
  # the backup policy is fully in place, leaving the first boot unprotected.
  depends_on = [google_compute_disk_resource_policy_attachment.boot_disk_backup_policy]
}
