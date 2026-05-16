#!/bin/bash

echo " Kubernetes Pods"
kubectl get pods -n skillpulse

echo ""
echo " Kubernetes Services"
kubectl get svc -n skillpulse

echo ""
echo " Docker Containers"
docker ps

echo ""
echo " Node Disk Usage"
df -h

echo ""
echo " Node Memory Usage"
free -m
