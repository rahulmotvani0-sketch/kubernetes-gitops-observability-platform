# 5-Minute Live Interview Screen-Share Demo Script
**Author:** Rahul Motvani ([GitHub](https://github.com/rahulmotvani0-sketch) · [Portfolio](https://rahul.techiking.com))

---

## 🎯 Purpose
This script is designed for senior DevOps / Platform Engineer / SRE interviews (e.g. micro1). In just 5 minutes on a live screen-share, you can demonstrate real mastery of **Kubernetes multi-node topology, GitOps with ArgoCD, SRE RED metrics in Grafana, and automated chaos self-healing**.

---

## ⏱️ Minute-by-Minute Demonstration Flow

### Minute 0:00 – 1:00: Cluster Architecture & Topology
1. **Action:** Open terminal and run:
   ```bash
   kubectl get nodes -o wide
   ```
2. **Talking Point:**
   > "I've architected a reproducible multi-node Kubernetes platform running locally on Kind. We have a dedicated control plane node and two isolated worker nodes mapped to availability zones `local-zone-a` and `local-zone-b`. Inbound traffic enters via NGINX Ingress Controller bound to host ports 80 and 443."

---

### Minute 1:00 – 2:15: GitOps Control Plane (ArgoCD App-of-Apps)
1. **Action:** Switch to browser and open **ArgoCD UI** (`http://localhost:30080` or `http://localhost:8080`).
2. **Action:** Show the `root-platform-apps` tree expanding to `cloudnative-store` and `platform-observability`.
3. **Talking Point:**
   > "Rather than deploying workloads imperatively, the entire platform is driven by GitOps using the ArgoCD App-of-Apps pattern. The root application continuously monitors my GitHub repository. Any change to our Kubernetes manifests in Git triggers an automated zero-downtime rolling update. Notice that `selfHeal: true` is enabled, meaning manual cluster drift is automatically reverted within seconds."

---

### Minute 2:15 – 3:30: SRE Observability & RED Metrics in Grafana
1. **Action:** Switch to browser tab at **Grafana** (`http://localhost:30000` or `http://localhost:3000`).
2. **Action:** Open the pre-loaded dashboard **"SRE Golden Signals & RED Metrics — CloudNative Store"**.
3. **Talking Point:**
   > "Here is our SRE observability stack powered by the Prometheus Operator and Alertmanager. We monitor Google's Golden Signals using the RED method: Request Rate in requests per second, Error Rate tracking 4xx and 5xx percentages, and Duration measuring latency percentiles (p50, p95, p99). We also track CPU/Memory saturation to verify our Horizontal Pod Autoscalers."

---

### Minute 3:30 – 4:30: Chaos Scenario 1 — Traffic Surge & HPA Scale-Up
1. **Action:** In terminal, run:
   ```bash
   ./scripts/simulate_chaos.sh hpa
   ```
2. **Action:** Watch terminal output show concurrent requests dispatching and pods scaling up from 2 to 6.
3. **Action:** Switch to Grafana and show the live RPS spike and active replica count increase.
4. **Talking Point:**
   > "I'm generating concurrent load against the API. Notice our Horizontal Pod Autoscaler dynamically detects the CPU threshold breach and scales our deployment from 2 to 6 replicas. Once load subsides, the configured 120-second stabilization window prevents pod flapping during cooldown."

---

### Minute 4:30 – 5:00: Chaos Scenario 2 — Pod Deletion & GitOps Auto-Healing
1. **Action:** In terminal, run:
   ```bash
   ./scripts/simulate_chaos.sh heal
   ```
2. **Talking Point:**
   > "Now let's simulate an infrastructure failure. I forcefully terminate an active backend pod. Kubernetes immediately reschedules a replacement container within 2 seconds. If an engineer were to manually delete or tamper with the Deployment manifest in the cluster, ArgoCD detects the out-of-sync drift against Git and restores the desired state immediately. This gives us complete zero-downtime resilience."

---

### Minute 5:00 – 5:30: Bonus — Distributed Log Exploration in Loki (LogQL)
1. **Action:** Switch to Grafana Explore tab (`http://localhost:30000/explore`) and select **Loki** as the datasource.
2. **Action:** Run query `{namespace="prod", app="store-backend-api"} |= "error"` or run:
   ```bash
   make loki
   ```
3. **Talking Point:**
   > "Finally, metrics only tell you THAT something failed; logs tell you WHY. We run Promtail as a DaemonSet streaming all container output across our 3 Kind nodes into Grafana Loki. In a single pane of glass, our engineers can jump directly from a Prometheus error spike to the exact stack traces in Loki using LogQL queries, slashing Mean Time to Resolution (MTTR)."

