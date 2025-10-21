.PHONY: help build up down logs restart clean health stats scale

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker-compose -f docker-compose.yml build --no-cache

up: ## Start the container
	docker-compose -f docker-compose.yml up -d

down: ## Stop the container
	docker-compose -f docker-compose.yml down

logs: ## Tail container logs
	docker-compose -f docker-compose.yml logs -f app

restart: down up ## Restart the container

health: ## Check container health
	docker inspect --format='{{json .State.Health}}' nextjs-app | jq

stats: ## Show resource usage
	docker stats nextjs-app --no-stream

clean: ## Clean up everything
	docker-compose -f docker-compose.yml down -v
	docker system prune -f

# Production commands
prod-build: ## Build production image with consistent build ID
	./scripts/build-production.sh

prod-up: ## Start production with scaling
	docker-compose -f docker-compose.prod.yml up -d

prod-down: ## Stop production
	docker-compose -f docker-compose.prod.yml down

prod-scale: ## Scale to N instances (make prod-scale N=5)
	docker-compose -f docker-compose.prod.yml up -d --scale app=$(N)

prod-logs: ## View production logs
	docker-compose -f docker-compose.prod.yml logs -f

prod-rebuild: ## Rebuild and restart production
	./scripts/build-production.sh && docker-compose -f docker-compose.prod.yml up -d --scale app=10

prod-check-build: ## Check build ID consistency across all containers
	./scripts/check-build-id.sh

# Quick deploy
deploy: ## Quick rebuild and deploy
	docker-compose build && docker-compose up -d

# Testing
test-health: ## Test health endpoint
	curl -f http://localhost:3000/api/hello || exit 1

test-distribution: ## Test container distribution
	./scripts/test-container-distribution.sh

test-balancing: ## Test load balancing
	./scripts/test-load-balancing.sh

test-stress: ## Run heavy load test with 10 instances
	bash ./scripts/stress-test.sh 10 100 10000 60

test-stress-heavy: ## Run HEAVY stress test (10 instances, 200 concurrent, 20k requests, 120s sustained)
	bash ./scripts/stress-test.sh 10 200 20000 120

test-stress-extreme: ## Run EXTREME stress test (10 instances, 500 concurrent, 50k requests, 300s sustained)
	bash ./scripts/stress-test.sh 10 500 50000 300

test-all: ## Run all tests
	./scripts/test-load-balancing.sh && ./scripts/test-container-distribution.sh

