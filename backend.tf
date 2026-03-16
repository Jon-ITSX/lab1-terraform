# =============================================================================
# REMOTE STATE BACKEND — GCS
# Stores terraform.tfstate in a shared GCS bucket (team: sidestep-error).
# The SA has storage.objectAdmin on this bucket.
#
# Initialise locally:
#   terraform init
# =============================================================================

terraform {
  backend "gcs" {
    bucket = "chas-tf-state-sidestep-error"
    prefix = "lab1/jon-eskilsson"
  }
}