.PHONY: deploy

deploy:
	@echo "🚀 Deploying to GitHub Pages..."
	@chmod +x deploy.sh
	@./deploy.sh 