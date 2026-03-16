# GitHub-regler och CI-beslut (Lab 1)

Detta dokument beskriver varför projektet är konfigurerat som det är.

## 1) GitHub Branch protection för `main`

Konfiguration:

[X] Require pull request before merge
[ ] Require at least 1 approval - Ej satt eftersom jag är ensam i projektet i nuläget.
[X] Require status checks to pass
[X] Require branch to be up to date before merge
[X] Block force pushes
[X] Block deletions
[ ] Require code scanning results to pass - Ej aktiverat. CodeQL är primärt för applikationskod. IaC-säkerhetsskanning hanteras av Trivy i CI-pipelinen.


## 2) Secrets (minimerad exponering)

I `Settings -> Secrets and variables -> Actions` används följande **secrets**:

- `GCP_SA_KEY` (JSON för delad service account)
- `GCP_PROJECT_ID` (obligatorisk - GCP-projekt-ID)
- `STUDENT_ID` (obligatorisk - Studentidentifierare)
- `GCS_BUCKET` (obligatorisk — GCS-bucket för remote state)
- `GCP_REGION` (valfri - standardvärde: `europe-north1`)
- `GCP_ZONE` (valfri - standardvärde: `europe-north1-b`)
- `GCP_MACHINE_TYPE` (valfri - standardvärde: `e2-micro`)

Jag valde att använda secrets på GitHub i stället för variables för att minska synlighet av metadata i repository-inställningarna och loggar.

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

Den ursprungliga koded verkade vara ett minimalt exempel. Min workflow innehåller två extra delar för bättre drift i CI:

- `env`:
  - Samlar gemensamma variabler på ett ställe (`TF_VAR_*`, `TF_IN_AUTOMATION`).
  - Minskar duplicering i varje jobb/steg.
  - Säkerställer att `plan`/`apply` får samma indata i alla körningar.

- `concurrency`:
  - Hindrar att flera körningar på samma branch krockar med varandra.
  - Minskar risk för race conditions, särskilt när `plan` och `apply` finns i samma workflow.

## 5) Lokal körning med service account

Service account-nyckeln lagras inte lokalt.

Det innebär att `terraform plan/apply` i normalfallet körs i GitHub Actions där `GCP_SA_KEY` finns som Secret.

Lokal körning av `plan/apply` med samma nyckelmodell kräver att nyckeln hämtas tillfälligt, vilket jag valt att undvika av säkerhetsskäl.

`terraform.tfvars` hålls lokal och ignoreras av git.

## 6) Förbättringspunkt: Node 24-migrering

Workflowen sätter `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` per jobb för att minska risk inför GitHubs Node 24-övergång. 2026-06-02.

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

- Jag har valt att behålla den ursprungliga baseline (`e2-micro`) som default via variabel.
- Gör `zone` konfigurerbar.
- I CI-`apply` testas flera zoner automatiskt om felet är just kapacitetsbrist.

Motivering:

- Minimal avvikelse från grundkoden.
- Stabilare leverans i faktisk kursmiljö där zonkapacitet varierar.
- Fallback triggas endast vid tydligt kapacitetsfel; andra fel stoppar direkt.

## 9) Backupstrategi: skillnad mot den ursprungliga minimalkoden

Originalkoden är en enkel och pedagogisk baseline som jag tolkar som ett exempel.

Nuvarande implementation gör samma sak (daglig snapshot policy + retention), men med tydligare resurshantering:

- Boot-disken skapas explicit som `google_compute_disk`.
- Snapshot fästs i policy på den explicita disken via `google_compute_disk_resource_policy_attachment`.
- Koden använder `var.zone` i stället för hårdkodad `${var.region}-a`.
- Snapshotparametrar (`start_time`, `retention_days`) styrs via variabler.

Motivering:

- Mindre implicit beteende och färre antaganden om namn/ordning.
- Stabilare i CI när zonkapacitet varierar.
- Enklare att justera utan att ändra resurslogik.
- Fortfarande i linje med kravet: backupstrategi via snapshot policy i Terraform.

## 10) Guardrail: VM redan skapad utan matchande state

I CI-apply finns en kontroll som avbryter gracefully om VM redan finns i GCP ("already exists") men saknas i state. Med GCS-backend aktiv speglar state alltid verkligheten och kontrollen behövs sällan — den är behållen som extra skyddsnät.

