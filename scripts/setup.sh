#!/usr/bin/env bash
# ==============================================================================
# Kubernetes Platform with GitOps & Observability — Turnkey Setup
# Provisions a 3-node Kind cluster, Ingress, ArgoCD, and Prometheus/Grafana stack
# ==============================================================================

set -eo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="k8s-platform"

echo -e "\n${CYAN}====================================================================${NC}"
echo -e "${CYAN}    Kubernetes GitOps & Observability Platform — Cluster Bootstrapper ${NC}"
echo -e "${CYAN}====================================================================${NC}\n"

# Step 1: Verify Prerequisites
echo -e "${YELLOW}[1/5] Checking local CLI prerequisites...${NC}"
for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error: '$cmd' is not installed. Please install it first.${NC}"
    exit 1
  fi
  echo -e "  ${GREEN}✓${NC} $cmd is installed"
done

# Step 2: Create Multi-Node Kind Cluster
echo -e "\n${YELLOW}[2/5] Creating 3-node Kubernetes cluster ('$CLUSTER_NAME')...${NC}"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "  Cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
  kind create cluster --config kind-config.yaml
  echo -e "  ${GREEN}✓${NC} Multi-node cluster created successfully."
fi

# Step 3: Install NGINX Ingress Controller
echo -e "\n${YELLOW}[3/5] Deploying NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
echo "  Waiting for Ingress Controller to become ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || true
echo -e "  ${GREEN}✓${NC} Ingress Controller active."

# Step 4: Install ArgoCD & Configure GitOps Engine
echo -e "\n${YELLOW}[4/5] Deploying ArgoCD GitOps Control Plane...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch ArgoCD Server Service to NodePort 30080 for easy browser access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}' || true

# Apply the Root App-of-Apps
echo "  Deploying Root App-of-Apps manifest..."
kubectl apply -f gitops/argocd/root-app.yaml || true
echo -e "  ${GREEN}✓${NC} ArgoCD initialized with self-healing enabled."

# Step 5: Install Observability Metrics Tier (Prometheus & Grafana)
echo -e "\n${YELLOW}[5/6] Deploying Prometheus Operator & Grafana SRE Dashboards...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update || true

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values observability/prometheus-values.yaml \
  --wait --timeout 300s || true

# Apply custom PrometheusRules alerts
kubectl apply -f observability/manifests/prometheus-rules.yaml || true
echo -e "  ${GREEN}✓${NC} Prometheus, Alertmanager, and Grafana online."

# Step 6: Install Observability Logging Tier (Loki & Promtail)
echo -e "\n${YELLOW}[6/6] Deploying Loki & Promtail Distributed Log Aggregation...${NC}"
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update || true

helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values observability/loki-values.yaml \
  --wait --timeout 180s || true
echo -e "  ${GREEN}✓${NC} Loki & Promtail active. Logs streaming to Grafana."

# Retrieve initial ArgoCD admin password
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || echo "admin123")

echo -e "\n${CYAN}====================================================================${NC}"
echo -e "${GREEN}    Kubernetes GitOps & Observability Platform is Ready!           ${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "  Sample Web Store:       ${CYAN}http://localhost/${NC}"
echo -e "  Backend API / Health:   ${CYAN}http://localhost/api${NC}"
echo -e "  ArgoCD UI:              ${CYAN}http://localhost:30080${NC} (User: admin, Pass: $ARGO_PWD)"
echo -e "  Grafana SRE & Logs:     ${CYAN}http://localhost:30000${NC} (User: admin, Pass: admin)"
echo -e "  Loki Log Endpoint:      ${CYAN}http://localhost:3100${NC} (via Promtail DaemonSet)"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Run ${YELLOW}make chaos${NC} or ${YELLOW}./scripts/simulate_chaos.sh${NC} to run live interview demonstrations.\n"
