.PHONY: diagrams hooks

## Regenerate the Terraform diagrams (Mermaid in README + SVG in docs/diagrams).
diagrams:
	@./scripts/gen-diagrams.sh

## Enable the local pre-commit hook that keeps the diagrams fresh on every commit.
hooks:
	@git config core.hooksPath .githooks && echo "core.hooksPath -> .githooks"
