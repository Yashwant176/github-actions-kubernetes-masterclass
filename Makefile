CLUSTER  ?= skillpulse
NAMESPACE ?= skillpulse

# Update with your DockerHub username
BACKEND_IMAGE  ?= yashwant176/skillpulse-backend:latest
FRONTEND_IMAGE ?= yashwant176/skillpulse-frontend:latest

.PHONY: up down build load apply status logs mysql restart \
        monitor deploy rollback cleanup backup restore \
        k8s-restart k8s-health docker-health security-scan

up: ## One-shot: build images, create cluster, load images, apply manifests
	$(MAKE) build
	kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) apply
	@echo
	@echo " SkillPulse is live at http://localhost:8888"
	@echo

build: ## Build backend + frontend images for the host's architecture
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load: ## Load built images into kind cluster
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

apply: ## Apply Kubernetes manifests and wait for rollouts
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml

	kubectl rollout status statefulset/mysql -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

down: ## Delete kind cluster
	kind delete cluster --name $(CLUSTER)

status: ## Quick Kubernetes health snapshot
	kubectl get pods,svc,endpoints -n $(NAMESPACE)

logs: ## Tail logs from all workloads
	kubectl logs -n $(NAMESPACE) \
	-l 'app in (mysql,backend,frontend)' \
	--all-containers \
	--tail=50 \
	-f \
	--max-log-requests=10

mysql: ## Open MySQL shell
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- \
	mysql -uskillpulse -pskillpulse123 skillpulse

restart: ## Rebuild images and restart deployments
	$(MAKE) build
	$(MAKE) load

	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)

	kubectl rollout status deployment/backend -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

monitor: ## Run monitoring checks
	./scripts/monitoring-check.sh

deploy: ## Deploy application stack
	./scripts/deploy.sh

rollback: ## Rollback Kubernetes deployments
	./scripts/rollback.sh

cleanup: ## Cleanup Docker + Kubernetes junk
	./scripts/cleanup.sh

backup: ## Backup MySQL database
	./scripts/backup.sh

restore: ## Restore MySQL database
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make restore FILE=backups/backup.sql"; \
		exit 1; \
	fi
	./scripts/restore.sh $(FILE)

k8s-restart: ## Restart Kubernetes deployments
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)

k8s-health: ## Check Kubernetes health
	kubectl get pods -n $(NAMESPACE)
	kubectl get svc -n $(NAMESPACE)

docker-health: ## Check Docker containers
	docker ps

security-scan: ## Run Trivy scans locally
	trivy image $(BACKEND_IMAGE)
	trivy image $(FRONTEND_IMAGE)
