terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.gcp_sa_key_json
}

resource "google_compute_disk" "vm_boot_disk" {
  name = "${var.student_id}-lab1-vm-boot"
  type = "pd-balanced"
  zone = var.zone
  size = 20

  image = "ubuntu-os-cloud/ubuntu-2204-lts"
}

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

  labels = {
    student = var.student_id
    course  = "devsecops-2026"
    lab     = "1"
  }

  tags = ["lab1", "ssh"]

  depends_on = [google_compute_disk_resource_policy_attachment.boot_disk_backup_policy]
}
