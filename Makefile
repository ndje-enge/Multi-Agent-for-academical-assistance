# ==============================================================================
# Installation & Setup
# ==============================================================================

# Install dependencies using uv package manager
install:
	@command -v uv >/dev/null 2>&1 || { echo "uv is not installed. Installing uv..."; curl -LsSf https://astral.sh/uv/0.8.13/install.sh | sh; source $HOME/.local/bin/env; }
	uv sync --dev

# Clean and reinstall everything (fix for missing packages)
reinstall:
	@echo "🔧 Cleaning and reinstalling all dependencies..."
	rm -rf .venv uv.lock
	@command -v uv >/dev/null 2>&1 || { echo "uv is not installed. Installing uv..."; curl -LsSf https://astral.sh/uv/0.8.13/install.sh | sh; source $HOME/.local/bin/env; }
	uv cache clean
	uv sync --dev
	@echo "✅ Reinstallation complete!"
	@echo "Verify with: make verify"

# Verify installation
verify:
	@echo "🔍 Verifying installation..."
	@uv run python -c "import google.adk; print('✅ google-adk OK')" || echo "❌ google-adk missing"
	@uv run python -c "import vertexai; print('✅ vertexai OK')" || echo "❌ vertexai missing"
	@uv run python -c "import langchain_google_vertexai; print('✅ langchain-google-vertexai OK')" || echo "❌ langchain-google-vertexai missing"
	@uv run python -c "from app.multi_agents import orchestrator_agent; print('✅ multi-agents architecture OK')" || echo "❌ architecture import failed"
	@echo ""
	@echo "Total packages installed:"
	@uv pip list | wc -l

# ==============================================================================
# Playground Targets
# ==============================================================================

# Launch local dev playground
playground:
	@echo "==============================================================================="
	@echo "| 🚀 Starting your agent playground...                                        |"
	@echo "|                                                                             |"
	@echo "| 💡 Try asking: How to save a pandas dataframe to CSV?                       |"
	@echo "|                                                                             |"
	@echo "| 🔍 IMPORTANT: Select the 'app' folder to interact with your agent.          |"
	@echo "==============================================================================="
	uv run adk web . --port 8501 --reload_agents

# ==============================================================================
# Backend Deployment Targets
# ==============================================================================

# Deploy the agent remotely
backend:
	# Export dependencies to requirements file using uv export.
	uv export --no-hashes --no-header --no-dev --no-emit-project --no-annotate > .requirements.txt 2>/dev/null || \
	uv export --no-hashes --no-header --no-dev --no-emit-project > .requirements.txt && uv run app/agent_engine_app.py


# ==============================================================================
# Infrastructure Setup
# ==============================================================================

# Set up development environment resources using Terraform
setup-dev-env:
	PROJECT_ID=$$(gcloud config get-value project) && \
	(cd deployment/terraform/dev && terraform init && terraform apply --var-file vars/env.tfvars --var dev_project_id=$$PROJECT_ID --auto-approve)

# ==============================================================================
# Data Ingestion (RAG capabilities)
# ==============================================================================

# Run the data ingestion pipeline for RAG capabilities
data-ingestion:
	PROJECT_ID=$$(gcloud config get-value project) && \
	(cd data_ingestion && uv run data_ingestion_pipeline/submit_pipeline.py \
		--project-id=$$PROJECT_ID \
		--region="us-central1" \
		--data-store-id="mon-agent-scolaire-datastore" \
		--data-store-region="us" \
		--service-account="mon-agent-scolaire-rag@$$PROJECT_ID.iam.gserviceaccount.com" \
		--pipeline-root="gs://$$PROJECT_ID-mon-agent-scolaire-rag" \
		--pipeline-name="data-ingestion-pipeline")

# ==============================================================================
# Testing & Code Quality
# ==============================================================================

# Run unit and integration tests
test:
	uv run pytest tests/unit && uv run pytest tests/integration

# Run code quality checks (codespell, ruff, mypy)
lint:
	uv sync --dev --extra lint
	uv run codespell
	uv run ruff check . --diff
	uv run ruff format . --check --diff
	uv run mypy .