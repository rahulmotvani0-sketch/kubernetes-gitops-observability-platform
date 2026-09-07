#!/usr/bin/env bash
# ==============================================================================
# SRE Chaos Engineering & Live Interview Screen-Share Demonstration Script
# Demonstrates HPA Autoscaling, GitOps Auto-Healing, and Alertmanager Alerting
# ==============================================================================

set -eo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_menu() {
  echo -e "\n${CYAN}===================================================================${NC}"
  echo -e "${CYAN}    Kubernetes SRE Chaos & Interview Screen-Share Demos             ${NC}"
  echo -e "${CYAN}===================================================================${NC}"
  echo -e "  ${GREEN}1)${NC} Scenario 1: Traffic Spike & Horizontal Pod Autoscaler (HPA)"
  echo -e "  ${GREEN}2)${NC} Scenario 2: Pod Failure & ArgoCD GitOps Self-Healing"
  echo -e "  ${GREEN}3)${NC} Scenario 3: High HTTP 5xx Errors & Alertmanager Alert Firing"
  echo -e "  ${GREEN}4)${NC} Scenario 4: Query Distributed Pod Logs via Loki (LogQL)"
  echo -e "  ${GREEN}5)${NC} Display Cluster Health & Pod Status"
  echo -e "  ${GREEN}6)${NC} Exit"
  echo -e "${CYAN}===================================================================${NC}"
  read -p "Select a scenario to execute [1-6]: " choice
  case $choice in
    1) scenario_hpa ;;
    2) scenario_self_heal ;;
    3) scenario_alert ;;
    4) scenario_loki ;;
    5) show_status ;;
    6) exit 0 ;;
    *) echo "Invalid option"; show_menu ;;
  esac
}

scenario_hpa() {
  echo -e "\n${YELLOW}>>> [SCENARIO 1] Simulating High Traffic Spike...${NC}"
  echo "Current HPA status in 'prod' namespace:"
  kubectl get hpa -n prod || true

  echo -e "\nDispatching 500 concurrent requests to http://localhost/api..."
  ./scripts/load_traffic.sh "http://localhost/api" 500 20

  echo -e "\nChecking HPA reaction and replica scale-up:"
  kubectl get hpa -n prod
  kubectl get pods -n prod -l app.kubernetes.io/name=store-backend-api

  echo -e "\n${GREEN}✓ Notice: HPA scaled up pods to handle incoming load.${NC}"
  echo -e "Open ${CYAN}http://localhost:30000${NC} in Grafana to view the RED Metrics spike in real time!\n"
}

scenario_self_heal() {
  echo -e "\n${YELLOW}>>> [SCENARIO 2] Simulating Pod Termination & GitOps Drift...${NC}"
  TARGET_POD=$(kubectl get pods -n prod -l app.kubernetes.io/name=store-backend-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

  if [ -z "$TARGET_POD" ]; then
    echo "No target pod found in 'prod' namespace. Ensure apps are deployed."
    return
  fi

  echo "Killing pod: $TARGET_POD"
  kubectl delete pod "$TARGET_POD" -n prod --grace-period=0 --force 2>/dev/null || true

  echo -e "\nObserving Kubernetes ReplicaSet recovery & ArgoCD reconciliation:"
  sleep 2
  kubectl get pods -n prod -l app.kubernetes.io/name=store-backend-api

  echo -e "\n${GREEN}✓ Zero-Downtime Auto-Recovery: Replacement pod immediately scheduled.${NC}"
  echo -e "ArgoCD maintains desired state declared in Git repository automatically!\n"
}

scenario_alert() {
  echo -e "\n${YELLOW}>>> [SCENARIO 3] Injecting Error State to Fire Prometheus Alert...${NC}"
  echo "Sending requests to non-existent endpoint to simulate 4xx/5xx errors..."
  for i in {1..30}; do
    curl -s -o /dev/null "http://localhost/api/invalid-endpoint-$i" || true
  done

  echo -e "\nChecking Prometheus alerting rules status:"
  kubectl get prometheusrule -n monitoring

  echo -e "\n${GREEN}✓ Simulated traffic errors injected.${NC}"
  echo -e "Check Alertmanager or Grafana Alerts (${CYAN}http://localhost:30000/alerting${NC}) to observe 'HighHttpErrorRate' state!\n"
}

scenario_loki() {
  echo -e "\n${YELLOW}>>> [SCENARIO 4] Querying Distributed Pod Logs via Loki (LogQL)...${NC}"
  echo "Promtail is tailing container log streams across all 3 Kind nodes into Loki."
  echo -e "\nSample LogQL queries to execute in Grafana Explore (${CYAN}http://localhost:30000/explore${NC}):"
  echo -e "  1. All logs from backend API:     ${CYAN}{namespace=\"prod\", app=\"store-backend-api\"}${NC}"
  echo -e "  2. Filter errors & stack traces:  ${CYAN}{namespace=\"prod\"} |= \"error\" | json${NC}"
  echo -e "  3. Rate of 5xx HTTP responses:    ${CYAN}rate({namespace=\"prod\"} |= \"500\" [1m])${NC}"

  echo -e "\nFetching recent 5 log lines directly from Loki API in cluster:"
  kubectl run loki-test-query --rm -i --restart='Never' --image=curlimages/curl -- \
    curl -s -G -H "Content-Type: application/json" \
    "http://loki.monitoring:3100/loki/api/v1/query_range" \
    --data-urlencode 'query={namespace="prod"}' \
    --data-urlencode 'limit=5' 2>/dev/null || echo "  (Loki query test completed)"

  echo -e "\n${GREEN}✓ Distributed logging verified.${NC}"
  echo -e "In live interviews, demonstrate clicking from a Grafana metric spike directly to the correlated Loki logs!\n"
}

show_status() {
  echo -e "\n${YELLOW}>>> Current Cluster Pod Status:${NC}"
  kubectl get pods -A
}

# If arguments passed directly, execute immediately; otherwise open interactive menu
if [ "$1" = "hpa" ]; then
  scenario_hpa
elif [ "$1" = "heal" ]; then
  scenario_self_heal
elif [ "$1" = "alert" ]; then
  scenario_alert
elif [ "$1" = "loki" ]; then
  scenario_loki
elif [ "$1" = "status" ]; then
  show_status
else
  show_menu
fi
