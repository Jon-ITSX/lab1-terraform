# GitHub-regler och CI-beslut (Lab 1)

Detta dokument beskriver vilka GitHub-regler och CI-val som används i `lab1-terraform` och varför.

## 1) Branch protection för `main`

Rekommenderad konfiguration i GitHub:

- Require pull request before merge
- Require at least 1 approval
- Require status checks to pass
- Require branch to be up to date before merge
- Block force pushes
- Block deletions

### Varför

- Tvingar all kod genom PR-flödet.
- Säkerställer att CI (lint, security, validate, plan) är grön innan merge.
- Minskar risken för osäkra eller obekräftade ändringar i `main`.

## 2) Secrets och repository variables

Konfigurera i `Settings -> Secrets and variables -> Actions`.

### Secrets

- `GCP_SA_KEY`: JSON-nyckel för service account i GCP.

### Variables

- `GCP_PROJECT_ID`: målprojekt för Terraform.
- `STUDENT_ID`: används i namngivning av resurser.
- `GCP_REGION` (valfri): fallback i workflow är `europe-north1`.

### Varför

- Inga känsliga värden i repo.
- `terraform.tfvars` hålls lokalt och ignoreras i git.
- CI får samma styrning oavsett utvecklares lokala miljö.

## 3) Workflow-strategi

Workflow-fil: `.github/workflows/terraform.yml`

- `lint` (Terraform `fmt`-kontroll)
- `security` (Trivy IaC-skanning, blockerar `CRITICAL`)
- `validate` (`terraform init -backend=false` + `terraform validate`)
- `plan` (autentiserad med `GCP_SA_KEY`)
- `apply` endast vid:
  - push till `main`, eller
  - manuell `workflow_dispatch`

### Varför plan/apply delas upp

- PR ska visa vad som ändras (`plan`) utan att skapa resurser.
- `apply` sker bara i kontrollerade scenarier.
- Minskar risken för oavsiktliga kostnader och oönskade infrastrukturändringar.

## 4) Varför `terraform.tfvars` inte committas

`terraform.tfvars` ska inte trackas i git.

### Varför

- Filen innehåller ofta miljö- eller identitetsdata.
- Risken för läckage i historik minskar.
- Samma kod kan användas i flera miljöer med olika secrets/variables.

## 5) Förbättringspunkt: Node 24-migrering i GitHub Actions

GitHub har varnat för utfasning av Node 20 för flera actions.
För att minska risk har workflowen uppdaterats med:

- `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`

### Varför

- Vi testar kompatibilitet med Node 24 redan nu.
- Vi minskar risken för driftstörningar när GitHub ändrar default-runtime.
- Detta kan användas som förbättringspunkt i rapporten.

## 6) Evidens för rapport

Notering: `HIGH`-fynd loggas i Trivy-rapporten men blockerar inte merge.
Blockering sker på `CRITICAL`, enligt VG-kravet.

Ta screenshots på:

- PR med grön pipeline
- `plan`-jobb i PR (när IAM-behörighet finns)
- `apply`-jobb efter merge/manuell körning
- Secret/variables-konfiguration (utan att visa hemlig data)
- Branch protection för `main`
- Trivy-artifact med rapport
