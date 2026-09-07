.PHONY: help up down status chaos port-forward logs clean loki

help:
	@echo "Kubernetes GitOps & Observability Platform — Developer CLI"
	@echo "=========================================================="
	@echo "  make up            Bootstrap 3-node Kind cluster, Ingress, ArgoCD & Prometheus/Loki"
	@echo "  make down          Teardown and destroy the local cluster"
	@echo "  make status        View all running pods, nodes, and GitOps applications"
	@echo "  make chaos         Run interactive SRE chaos demonstrations"
	@echo "  make loki          Run Loki distributed log aggregation verification"
	@echo "  make port-forward  Expose ArgoCD (8080) and Grafana (3000) locally"
	@echo "  make clean         Remove local kubeconfig and temporary logs"

up:
	./scripts/setup.sh

down:
	./scripts/teardown.sh

status:
	@echo "=== Node Topology ==="
	kubectl get nodes -o wide
	@echo "\n=== ArgoCD Applications ==="
	kubectl get applications -n argocd || true
	@echo "\n=== Workload Pods (prod) ==="
	kubectl get pods,svc,hpa -n prod
	@echo "\n=== Monitoring Pods (monitoring) ==="
	kubectl get pods -n monitoring

chaos:
	./scripts/simulate_chaos.sh

loki:
	./scripts/simulate_chaos.sh loki

port-forward:
	@echo "Starting background port-forwards..."
	@kubectl port-forward svc/argocd-server -n argocd 8080:80 >/dev/null 2>&1 &
	@kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 >/dev/null 2>&1 &
	@echo "ArgoCD UI available at: http://localhost:8080"
	@echo "Grafana UI available at: http://localhost:3000"

clean:
	rm -f kubeconfig *.log
