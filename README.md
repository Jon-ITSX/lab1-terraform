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
project_id = "your-project-id"
region     = "europe-north1"
student_id = "fornamn-efternamn"
```

## Körning lokalt

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## CI-variabler i GitHub

Lägg till följande repository variables:

- `GCP_PROJECT_ID`
- `STUDENT_ID`
- `GCP_REGION` (valfri)

## Evidens till inlämning (G)

Lägg screenshots i `docs/screenshots/`:

- Terraform apply klart (VM skapad)
- Snapshot policy i GCP
- Grön pipeline
- Minst en PR med synlig pipelinekörning


## Hantering av kapacitetsfel i zon

Vi har gjort zone till en explicit variabel i Terraform. Skälet är att GCP ibland saknar kapacitet i en specifik zon (t.ex. för 2-micro).

Genom att styra zon via variabel kan vi snabbt byta zon utan att ändra resurslogik, vilket ger stabilare leverans i CI och vid inlämning.

