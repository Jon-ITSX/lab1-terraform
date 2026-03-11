# Lab 1 - Terraform + GCP

Detta repo innehåller Terraform-kod som skapar en Linux-VM i GCP med en backupstrategi via snapshot policy.

## Innehåll

- Linux-VM (`google_compute_instance`)
- Daglig snapshot policy för backup
- CI via GitHub Actions:
  - Terraform formatkontroll (`fmt`)
  - Säkerhetsskanning med Trivy
  - Terraform `validate`
  - Terraform `plan` och `apply` (beroende av IAM-behörigheter)

## Förberedelser

1. Skapa eller välj ett GCP-projekt.
2. Aktivera Compute Engine API.
3. Installera Terraform lokalt.
4. Autentisera mot GCP, till exempel:

```bash
gcloud auth application-default login
```

## Konfiguration

Skapa en lokal `terraform.tfvars` utifrån `terraform.example.tfvars` och fyll i dina värden.

Exempel:

```hcl
project_id = "your-project-id"
region     = "europe-north1"
student_id = "fornamn-efternamn"
```

## Körsteg lokalt

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Backupstrategi

Backup implementeras med snapshot policy i Terraform.
Policyn kopplas till disken för VM-instansen.

## GitHub Actions

Workflow finns i `.github/workflows/terraform.yml` och kör på:

- Pull requests mot `main`
- Push till `main`
- Manuell körning (`workflow_dispatch`)

## Evidens till inlämning (G)

Lägg screenshots i `docs/screenshots/` och referera dem här:

- [ ] Terraform apply klart (VM skapad i GCP)
- [ ] Snapshot policy synlig i GCP
- [ ] Grön pipeline i GitHub Actions
- [ ] Minst en PR med synlig pipelinekörning

Exempel:

- `docs/screenshots/01-terraform-apply.png`
- `docs/screenshots/02-snapshot-policy.png`
- `docs/screenshots/03-pr-pipeline.png`

## Nästa steg

1. Vänta in IAM-besked från utbildaren för `plan/apply` i GCP-projektet.
2. Kör ny pipeline och kontrollera Trivy-artifact.
3. Slutför README med faktiska screenshots inför inlämning.
