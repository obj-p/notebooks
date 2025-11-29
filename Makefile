KERNEL_NAME  := notebooks
PIPX         ?= $(shell command -v pipx)
PYTHON       ?= $(shell command -v python3)
PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PRE_COMMIT_VERSION = 4.2.0
BIN_PRE_COMMIT     = bin/pre-commit-$(PRE_COMMIT_VERSION).pyz
PRE_COMMIT         = $(PYTHON) $(BIN_PRE_COMMIT)

$(BIN_PRE_COMMIT): ## download pre-commit
	@curl --create-dirs --output-dir bin -LO \
		https://github.com/pre-commit/pre-commit/releases/download/v$(PRE_COMMIT_VERSION)/pre-commit-$(PRE_COMMIT_VERSION).pyz

.PHONY: bootstrap
bootstrap: prerequisites ## bootstrap the project
	$(MAKE) pipx-install
	$(PIPX) ensurepath
	$(MAKE) venv
	$(MAKE) ipykernel
	$(MAKE) $(BIN_PRE_COMMIT)
	$(PRE_COMMIT) install --hook-type pre-commit --hook-type pre-push

.PHONY: brew
brew: ## brew bundle dependencies (e.g. pipx)
	@brew bundle

.PHONY: help
help: ## show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@bash scripts/help-mk.sh $(MAKEFILE_LIST)

.PHONY: ipykernel
ipykernel: ## install the ipykernel
	@. venv/bin/activate && \
		python -m ipykernel install --user --display-name $(PROJECT_ROOT) --name $(KERNEL_NAME)

.PHONY: uninstall-ipykernel
uninstall-ipykernel: ## uninstall the ipykernel
	@jupyter kernelspec uninstall $(KERNEL_NAME)

.PHONY: lab
lab: ## run jupyter-lab
	@JUPYTER_DEFAULT_KERNEL=$(KERNEL_NAME) jupyter-lab .

.PHONY: pipx-install
pipx-install: ## pipx install dependencies (e.g. jupyterlab)
	@$(PIPX) install jupyterlab --include-deps

.PHONY: pre-commit
pre-commit: ## pre-commit run
	@$(PRE_COMMIT) run

.PHONY: pre-push
pre-push: ## pre-commit run --hook-stage pre-push
	@$(PRE_COMMIT) run --hook-stage pre-push

.PHONY: prerequisites
prerequisites: ## check for required development prerequisites
	@missing=""; \
	if [ -z "$(PIPX)" ]; then missing="$$missing pipx"; fi; \
	if [ -z "$(PYTHON)" ]; then missing="$$missing python3"; fi; \
	if [ -n "$$missing" ]; then \
		printf "\033[31m[ERROR]\033[0m Missing prerequisites:$$missing\n"; \
		exit 1; \
	fi

.PHONY: venv
venv: ## make virtual environment
	@$(PYTHON) -m venv venv
	@. venv/bin/activate && pip install --upgrade pip && pip install -e ".[jupyter]"
