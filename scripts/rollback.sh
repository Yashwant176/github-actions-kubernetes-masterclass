#!/bin/bash

set -e

echo " Rolling back Kubernetes deployments..."

kubectl rollout undo deployment/backend -n skillpulse
kubectl rollout undo deployment/frontend -n skillpulse

echo "Rollback completed!"
