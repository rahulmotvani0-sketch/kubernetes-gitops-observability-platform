# SRE Incident Response Runbook
**Platform:** Kubernetes GitOps & Observability Platform  
**Author:** Rahul Motvani ([GitHub](https://github.com/rahulmotvani0-sketch) · [Portfolio](https://rahul.techiking.com))

---

## 1. Alert: HighHttpErrorRate

### Severity: `CRITICAL`
* **Trigger:** HTTP 5xx error rate > 5% for 2 consecutive minutes.
* **SLO Impact:** Breaches availability SLO (99.9% target).

### Triage & Diagnostics:
1. Identify the failing microservice via Grafana RED dashboard:
   ```bash
   kubectl logs -n prod -l app.kubernetes.io/name=store-backend-api --tail=100 | grep -i "error"
   ```
2. Check Redis connection latency and status:
   ```bash
   kubectl exec -it -n prod $(kubectl get pod -n prod -l app.kubernetes.io/name=redis-cache -o jsonpath='{.items[0].metadata.name}') -- redis-cli ping
   ```
3. Inspect Ingress controller error logs:
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
   ```

### Remediation:
* If backend pods are failing upstream database queries, check connection pool saturation.
* If a bad release was merged to Git, revert the commit in Git; ArgoCD will automatically roll back the deployment.

---

## 2. Alert: PodCrashLooping

### Severity: `WARNING`
* **Trigger:** Pod restarts > 2 times in 5 minutes.
* **Impact:** Potential service degradation and memory exhaustion.

### Triage & Diagnostics:
1. Identify failing container exit codes:
   ```bash
   kubectl describe pod -n prod <pod-name> | grep -E "Exit Code|Last State"
   ```
   * **Exit Code 137:** OOMKilled (Container exceeded memory limit).
   * **Exit Code 1:** Unhandled application runtime exception.
2. View previous container termination logs:
   ```bash
   kubectl logs -n prod <pod-name> --previous
   ```

### Remediation:
* If Exit Code 137 (OOMKilled), increase memory requests and limits in `gitops/manifests/app/backend.yaml`. Commit to Git and sync via ArgoCD.

---

## 3. Alert: HighMemorySaturation

### Severity: `WARNING`
* **Trigger:** Container memory usage > 85% of limit for 3 minutes.
* **Impact:** Risk of impending OOMKill event.

### Triage & Diagnostics:
1. Check real-time resource utilization:
   ```bash
   kubectl top pods -n prod
   ```
2. Check for memory leaks in heap dumps or event queues.

---

## 4. Alert: DeploymentReplicaMismatch

### Severity: `WARNING`
* **Trigger:** Available pods != desired replicas for > 3 minutes.
* **Impact:** Reduced capacity and inability to absorb traffic surges.

### Triage & Diagnostics:
1. Inspect deployment events:
   ```bash
   kubectl describe deployment -n prod <deployment-name>
   ```
2. Check for node scheduling pressure or resource starvation:
   ```bash
   kubectl get nodes
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```
