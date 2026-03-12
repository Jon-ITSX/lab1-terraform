# Lab 1 - Terraform + GCP

Detta repo innehåller Terraform-kod som skapar en Linux-VM i GCP och kör kontroller i GitHub Actions.

## Innehåll

- Linux-VM (`google_compute_instance`)
- Startup-script för grundhärdning
- Trivy IaC-scan med blockerande `CRITICAL`
- Terraform `fmt`, `validate`, `plan`, `apply`

## Autentisering (viktigt)

Enligt utbildarens instruktion används delad service account-nyckel (`GCP_SA_KEY`).

1. Hämta nyckeln via Mission Control -> Credentials -> Request `GCP_SA_KEY`.
2. Lägg in nyckeln i GitHub som repository secret: `GCP_SA_KEY`.
3. Lokalt: sätt miljövariabeln `TF_VAR_gcp_sa_key_json` till hela JSON-innehållet.

PowerShell-exempel lokalt:

```powershell
$env:TF_VAR_gcp_sa_key_json = Get-Content -Raw .\gcp-sa-key.json
```

## Konfiguration

Skapa en lokal `terraform.tfvars` från `terraform.example.tfvars`.

Exempel:

```hcl
project_id   = "your-project-id"
region       = "europe-north1"
zone         = "europe-north1-b"
machine_type = "e2-micro"
student_id   = "fornamn-efternamn"
```

## Körning lokalt

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Secrets i GitHub

Lägg till följande repository secrets:

- `GCP_SA_KEY`
- `GCP_PROJECT_ID`
- `STUDENT_ID`
- `GCP_REGION` (valfri)
- `GCP_ZONE` (valfri)
- `GCP_MACHINE_TYPE` (valfri)

## Hantering av kapacitetsfel i zon

Vi har gjort `zone` till en explicit variabel i Terraform och lagt till automatisk zon-fallback i CI-`apply`.

Skälet är att GCP ibland saknar kapacitet i en enskild zon för `e2-micro`.
Med denna lösning kan pipelinen automatiskt prova nästa zon utan att vi ändrar grundkoden från utbildaren.

## Evidens till inlämning (G)

Lägg screenshots i `docs/screenshots/`:

- Terraform apply klart (VM skapad)
- Snapshot policy i GCP
- Grön pipeline
- Minst en PR med synlig pipelinekörning

Tillagda screenshots:

- `docs/screenshots/01-gcp-vm-overview.png` (översikt av VM-instans(er) i GCP Console)
- `docs/screenshots/02-gcp-vm-details.png` (detaljvy för skapad VM i GCP Console)
- `docs/screenshots/01-pr-to-main.png` (PR mot `main` med synlig pipelinekörning)



