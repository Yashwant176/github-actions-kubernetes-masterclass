#!/bin/bash

set -e

echo " Starting deployment..."

echo " Pulling latest code..."
git pull origin main

echo " Deploying Docker Compose stack..."
docker-compose pull
docker-compose up -d

echo "☸️ Applying Kubernetes manifests..."
kubectl apply -f k8s/

echo "Deployment completed successfully!"
