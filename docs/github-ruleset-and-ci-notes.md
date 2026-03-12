# GitHub-regler och CI-beslut (Lab 1)

Detta dokument beskriver varför projektet är konfigurerat som det är.

## 1) Branch protection för `main`

Rekommenderad konfiguration:

- Require pull request before merge
- Require at least 1 approval
- Require status checks to pass
- Require branch to be up to date before merge
- Block force pushes
- Block deletions

## 2) Secrets (minimerad exponering)

I `Settings -> Secrets and variables -> Actions` används följande **secrets**:

- `GCP_SA_KEY` (JSON för delad service account)
- `GCP_PROJECT_ID`
- `STUDENT_ID`
- `GCP_REGION` (valfri)
- `GCP_ZONE` (valfri)
- `GCP_MACHINE_TYPE` (valfri)

Vi använder secrets i stället för variables för att minska synlighet av metadata i repository-inställningarna och loggar.

## 3) CI-strategi

Workflow: `.github/workflows/terraform.yml`

- `lint`: Terraform `fmt`
- `security`: Trivy med blockerande `CRITICAL`
- `validate`: Terraform `validate`
- `plan`/`apply`: använder `GCP_SA_KEY` både via `google-github-actions/auth` och som `TF_VAR_gcp_sa_key_json`

Syfte:

- Samma autentiseringsmodell lokalt och i CI
- Inga hemligheter i repo
- Tydlig blockering av kritiska säkerhetsfynd

## 4) Varför vår workflow har `env` och `concurrency`

Utbildarens kod är ett minimalt exempel. Vår workflow innehåller två extra delar för bättre drift i CI:

- `env`:
  - Samlar gemensamma variabler på ett ställe (`TF_VAR_*`, `TF_IN_AUTOMATION`).
  - Minskar duplicering i varje jobb/steg.
  - Säkerställer att `plan`/`apply` får samma indata i alla körningar.

- `concurrency`:
  - Hindrar att flera körningar på samma branch krockar med varandra.
  - Minskar risk för race conditions, särskilt när `plan` och `apply` finns i samma workflow.

## 5) Lokal körning med service account

Lokal Terraform-körning använder samma nyckelmodell som CI:

```powershell
$env:TF_VAR_gcp_sa_key_json = Get-Content -Raw .\gcp-sa-key.json
```

`terraform.tfvars` hålls lokal och ignoreras av git.

## 6) Förbättringspunkt: Node 24-migrering

Workflowen sätter `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` per jobb för att minska risk inför GitHubs Node 24-övergång.

## 7) Säkerhetsbeslut: nyckeln lagras endast i GitHub Secrets

För att minska risken för kompromettering lagras `GCP_SA_KEY` endast i GitHub Secrets och inte som lokal fil i utvecklingsmiljön.

Konsekvens:

- `terraform plan/apply` körs i första hand i GitHub Actions.
- Lokal körning med samma service account är inte möjlig utan att nyckeln tillfälligt hämtas lokalt.

Motivering:

- Mindre exponering av hemligheter på utvecklarmaskiner.
- Lägre risk för oavsiktlig läckage via filer, backup eller felaktig hantering.

## 8) Beslut vid kapacitetsfel: zon-fallback i apply

Problem:

- `apply` misslyckade periodvis när vald zon saknade kapacitet för `e2-micro`.

Vald lösning:

- Vi behåller utbildarens baseline (`e2-micro`) som default via variabel.
- Vi gör `zone` konfigurerbar.
- I CI-`apply` testas flera zoner automatiskt om felet är just kapacitetsbrist.

Motivering:

- Minimal avvikelse från utbildarens grundkod.
- Stabilare leverans i faktisk kursmiljö där zonkapacitet varierar.
- Fallback triggas endast vid tydligt kapacitetsfel; andra fel stoppar direkt.
