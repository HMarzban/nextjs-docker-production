.PHONY: help build up down logs scale rebuild check-build clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Core commands
build: ## Build production image with consistent build ID
	./scripts/build-production.sh

up: ## Start production containers
	docker compose -f docker-compose.prod.yml up -d

down: ## Stop production containers
	docker compose -f docker-compose.prod.yml down

logs: ## View container logs
	docker compose -f docker-compose.prod.yml logs -f

scale: ## Scale to N instances (make scale N=10)
	docker compose -f docker-compose.prod.yml up -d --scale app=$(N)

rebuild: ## Rebuild and restart with 10 instances
	./scripts/build-production.sh && docker compose -f docker-compose.prod.yml up -d --scale app=10

check-build: ## Check build ID consistency across containers
	./scripts/check-build-id.sh

clean: ## Stop containers and clean up
	docker compose -f docker-compose.prod.yml down -v
	docker system prune -f

# Testing
test-health: ## Test health endpoint
	curl -f http://localhost:3009/api/hello || exit 1

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

