# GitHub Ruleset and CI Decisions (Lab 1)

Detta dokument beskriver vilka GitHub-regler och CI-val som används i `lab1-terraform`, och varfor.

## 1) Branch ruleset för `main`

Rekommenderad ruleset i GitHub:

- Require pull request before merge
- Require at least 1 approval
- Require status checks to pass
- Require branch to be up to date before merge
- Block force pushes
- Block deletions

### Varför

- Tvingar all kod genom PR-flodet.
- Sakerstaller att CI (lint, scan, validate, plan) ar gron innan merge.
- Minskar risk for att osakra eller obekraftade andringar hamnar i `main`.

## 2) Secrets and repository variables

Konfigurera i `Settings -> Secrets and variables -> Actions`:

### Secret

- `GCP_SA_KEY`: JSON-key for GCP service account

### Variables

- `GCP_PROJECT_ID`: target project for Terraform
- `STUDENT_ID`: anvands i namngivning av resurser
- `GCP_REGION` (valfri): default fallback i workflow ar `europe-north1`

### Varfor

- Inga kansliga varder i repo.
- `terraform.tfvars` kan vara lokalt och ignoreras i git.
- CI far samma styrning oavsett utvecklares lokala miljo.

## 3) Workflow strategy

Workflow fil: `.github/workflows/terraform.yml`

- `lint` (terraform fmt check)
- `security` (Trivy IaC scan, blockerar CRITICAL/HIGH)
- `validate` (terraform init -backend=false + validate)
- `plan` (autentiserad med `GCP_SA_KEY`)
- `apply` endast pa:
  - `push` till `main`, eller
  - manuell `workflow_dispatch`

### Varfor plan/apply delas upp

- PR ska visa vad som kommer andras (`plan`) utan att skapa resurser.
- `apply` sker bara i kontrollerade scenarier (main/manuell korning).
- Minskar risk for oavsiktliga kostnader och oonskade infrastrukturandringar.

## 4) Why `terraform.tfvars` is not committed

`terraform.tfvars` ska inte trackas i git.

### Varfor

- Filen innehaller ofta miljo- eller identitetsdata.
- Historik-lackage undviks.
- Samma kodbas kan anvandas i flera miljoer med olika GitHub variables/secrets.

## 5) Evidence for report

Ta screenshots pa:

- PR med gron pipeline
- Plan-jobb i PR
- Apply-jobb efter merge/manual run
- Secret/variables config (utan att visa hemlig data)
- Branch ruleset for `main`
