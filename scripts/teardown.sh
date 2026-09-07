#!/usr/bin/env bash
# Clean teardown script for the Kind Kubernetes platform

set -eo pipefail

CLUSTER_NAME="k8s-platform"

echo "Deleting local Kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME"
echo "Cluster deleted. All resources and temporary containers released."
