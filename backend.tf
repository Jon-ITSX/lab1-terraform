# =============================================================================
# REMOTE STATE BACKEND — GCS (partial configuration)
# Bucket and prefix are injected at runtime via -backend-config flags so that
# sensitive bucket names are kept out of the repository.
#
# CI (GitHub Actions): bucket and prefix come from the GCS_BUCKET secret.
# Local init:
#   terraform init \
#     -backend-config="bucket=$GCS_BUCKET" \
#     -backend-config="prefix=lab1/jon-eskilsson"
# =============================================================================

terraform {
  backend "gcs" {}
}