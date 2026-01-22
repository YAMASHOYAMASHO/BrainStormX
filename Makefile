.PHONY: help install run test build clean doctor

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	flutter pub get

run: ## Run the app in debug mode
	flutter run

test: ## Run tests
	flutter test

build-apk: ## Build Android APK
	flutter build apk --release

build-web: ## Build web app
	flutter build web

clean: ## Clean build files
	flutter clean

doctor: ## Check Flutter installation
	flutter doctor -v

analyze: ## Analyze code
	flutter analyze

format: ## Format code
	dart format .

format-check: ## Check code formatting
	dart format --output=none --set-exit-if-changed .
