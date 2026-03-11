# Lab 1 - Terraform + GCP

Detta repo innehaller Terraform-kod som skapar en Linux VM i GCP med en backup-strategi via snapshot policy.

## Innehall

- Linux VM (`google_compute_instance`)
- Boot-disk (`google_compute_disk`)
- Daglig snapshot policy (`google_compute_resource_policy`)
- CI via GitHub Actions:
  - Terraform format check
  - TFLint
  - Terraform validate
  - tfsec scan

## Forberedelser

1. Skapa eller valj ett GCP-projekt.
2. Aktivera Compute Engine API.
3. Installera Terraform lokalt.
4. Autentisera mot GCP, exempel:

```bash
gcloud auth application-default login
```

## Konfiguration

Uppdatera `terraform.tfvars`:

```hcl
project_id = "your-project-id"
region     = "europe-north1"
zone       = "europe-north1-a"
```

## Koersteg lokalt

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Backup-strategi

Snapshot policy skapas med daglig backup och retention i ett antal dagar (`snapshot_retention_days`).
Policyn kopplas till VM:ens boot-disk via `google_compute_disk_resource_policy_attachment`.

## GitHub Actions

Workflow finns i `.github/workflows/terraform.yml` och kor pa:

- Pull Requests
- Push till `main`

## Evidens till inlamning (G)

Lagg till screenshots i `docs/screenshots/` och referera dem har:

- [ ] Terraform apply klart (VM skapad i GCP)
- [ ] Snapshot policy synlig i GCP
- [ ] GitHub Actions gron pipeline (PR)
- [ ] Minst en PR med synlig pipeline-korning

Exempel:

- `docs/screenshots/01-terraform-apply.png`
- `docs/screenshots/02-snapshot-policy.png`
- `docs/screenshots/03-pr-pipeline.png`

## Att-goera efter denna grund

1. Skapa feature branch.
2. Gor en liten andring (t.ex. taggar eller machine type).
3. Push och oppna PR.
4. Ta screenshot pa pipeline i PR.
5. Merga nar pipeline ar gron.
