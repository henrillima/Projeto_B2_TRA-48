# Alvos do Projeto B2.
#
#   make b2        roda os scripts R 01 a 05 (logs em resultados/logs/) e abre a galeria
#   make galeria   só remonta e abre figuras/index.html
#
# Banco de governança:
#
#   make validar   schema + integridade do grafo
#   make build     YAML -> DuckDB
#   make site      gera _site/
#   make serve     serve _site/ em http://localhost:8000
#   make tudo      validar + build + site
#   make limpar    apaga os artefatos

DATA   := governanca/data
SCHEMA := governanca/schema/grafo.schema.json
DB     := governanca/build/grafo.duckdb
SITE   := _site

.PHONY: tudo validar build site serve limpar b2 galeria

tudo: site

b2:
	bash scripts/rodar_b2.sh

galeria:
	bash scripts/galeria_b2.sh

validar:
	uv run python governanca/tools/validar.py $(DATA) $(SCHEMA)

build: validar
	uv run python governanca/tools/build.py --src $(DATA) --schema $(SCHEMA) --out $(DB)

site: build
	uv run python governanca/tools/site.py --db $(DB) --out $(SITE) --repo .

serve: site
	@echo "  http://localhost:8000"
	@cd $(SITE) && python3 -m http.server 8000

limpar:
	rm -rf governanca/build $(SITE)
