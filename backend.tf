# =============================================================================
# REMOTE STATE BACKEND — GCS
# Stores terraform.tfstate in a GCS bucket for shared, persistent state.
# Bucket name and prefix are passed at runtime via -backend-config flags
# in the CI pipeline (see .github/workflows/terraform.yml).
#
# Initialise locally:
#   terraform init \
#     -backend-config="bucket=BUCKET-NAME" \
#     -backend-config="prefix=terraform/state"
# =============================================================================

terraform {
  backend "gcs" {}
}
