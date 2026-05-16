#!/bin/bash

set -e

echo " Cleaning Docker resources..."

docker system prune -af

echo " Cleaning unused Kubernetes resources..."

kubectl delete pods --field-selector=status.phase=Succeeded -n skillpulse || true

echo "Cleanup completed!"
