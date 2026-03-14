# Disaster Recovery (DR) – Lab 1 Terraform

## Scope

Dokumentet beskriver återhämtningsstrategin för Linux-VM:en och tillhörande infrastruktur som skapas i Lab 1 (GCP, region `europe-north1`).

---

## RPO – Recovery Point Objective

**Mål: ≤ 24 timmar**

Dagliga disk-snapshots körs kl. 03:00 UTC och behålls i 7 dagar. I värsta fall går maximalt en dags data förlorad.

| Parameter | Värde |
|-----------|-------|
| Schema | Dagligen (1 gång/dygn) |
| Starttid | 03:00 UTC |
| Retention | 7 dagar |
| Policy vid diskradering | `KEEP_AUTO_SNAPSHOTS` |

Terraform-resurs: `google_compute_resource_policy.daily_snapshot_policy`

---

## RTO – Recovery Time Objective

**Mål: ≤ 30 minuter**

| Steg | Uppskattad tid |
|------|---------------|
| Identifiera senaste snapshot | ~2 min |
| Skapa disk från snapshot (GCP) | ~5 min |
| `terraform apply` för ny VM | ~10 min |
| Verifiera VM och SSH-åtkomst | ~5 min |
| **Total** | **~22 min** |

---

## Återhämtningsprocedur

### Alternativ 1 – Terraform re-deploy (rekommenderat)

Förutsätter att remote state i GCS är intakt.

```bash
# 1. Verifiera tillgängliga snapshots
gcloud compute snapshots list \
  --filter="sourceDisk~STUDENT_ID-lab1-vm-boot" \
  --sort-by=~creationTimestamp \
  --limit=5 \
  --project=PROJECT_ID

# 2. (Vid behov) Ta bort trasig VM
terraform destroy -auto-approve

# 3. Återskapa infrastruktur
terraform apply -auto-approve
```

Alternativt trigga **Terraform CI**-pipelinen via `workflow_dispatch` på `main`.

### Alternativ 2 – Manuell disk-restore

Används när Terraform-state inte är tillgängligt eller VM:en måste återställas med data från en specifik snapshot.

```bash
# Skapa ny disk från snapshot
gcloud compute disks create STUDENT_ID-lab1-vm-boot-restored \
  --source-snapshot=SNAPSHOT-NAME \
  --zone=europe-north1-b \
  --project=PROJECT_ID

# Skapa VM med återställd disk (via Terraform import eller manuellt)
terraform import google_compute_disk.vm_boot_disk \
  projects/PROJECT_ID/zones/europe-north1-b/disks/STUDENT_ID-lab1-vm-boot-restored
terraform apply -auto-approve
```

---

## Zonfel (kapacitets- eller infrastrukturproblem)

Om en GCP-zon är otillgänglig, byt `zone`-variabeln och kör om pipelinen:

```bash
# Tillgängliga zoner i regionen
europe-north1-a
europe-north1-b  # default
europe-north1-c
```

CI-pipelinen har inbyggd zon-fallback som automatiskt provar `a → b → c` vid kapacitetsfel.

---

## Backup-verifiering

Kontrollera att snapshots tas regelbundet (bör ej vara äldre än 25 h):

```bash
gcloud compute snapshots list \
  --filter="sourceDisk~STUDENT_ID-lab1-vm-boot" \
  --sort-by=~creationTimestamp \
  --limit=3 \
  --format="table(name,creationTimestamp,diskSizeGb,status)" \
  --project=PROJECT_ID
```

---

## Begränsningar

| Begränsning | Kommentar |
|-------------|-----------|
| Regionsfel | Täcks ej – kräver multi-region strategi |
| GCS-bucket nere | Remote state otillgängligt → använd Alternativ 2 |
| Applikationsdata | Lagras på boot-disken, täcks av snapshot-strategin |

---

## Testplan

| Frekvens | Åtgärd |
|----------|--------|
| Varje vecka | Verifiera att senaste snapshot är < 24 h gammal |
| Kvartalsvis | Testa full restore till en separat testinstans |
| Vid DR-test | Mät faktisk RTO och jämför mot mål (≤ 30 min) |
| Vid avvikelse | Uppdatera detta dokument med ny bedömning |
