# Projeto B2 — TRA-48 · Data Challenge

**Predição do tempo de táxi de uma aeronave durante a partida com aprendizado de máquina
supervisionado.**

Disciplina **TRA-48 — Inteligência Analítica: Dados, Modelos e Decisões** · ITA, 8º semestre,
2026.2 · Professores Marcelo Xavier Guterres e Mayara Condé Rocha Murça, Maj Eng.

---

## O problema

Dado um voo de partida, prever quanto tempo a aeronave levará em táxi entre a saída do gate e a
decolagem. É um problema de **regressão** sobre dados operacionais de aeroporto, clássico em
gestão de tráfego aéreo: a previsão alimenta o sequenciamento de partidas e as decisões de
*pushback*, e o erro se paga em combustível queimado com motor ligado e em slot perdido.

A base de treino e teste é fornecida pela disciplina em **28/10**. Até lá o pipeline é
desenvolvido contra uma base sintética de brinquedo, com relação conhecida entre features e
resposta, para que os testes possam afirmar que ele recupera o que foi plantado
(`decisao:D03`).

## Entregas

| Data | Entrega | Peso |
| --- | --- | --- |
| 18/11 | Submissão das previsões para a base de teste | — |
| 25/11 | Apresentação do projeto | 30% do 2º bimestre |
| 02/12 | Relatório | 100% do exame |

## Como rodar

```bash
# governança
make validar      # schema + integridade do grafo
make site         # gera _site/ e abre com make serve

# análise
Rscript -e 'renv::restore()'
Rscript -e 'targets::tar_make()'
Rscript -e 'testthat::test_dir("app/tests/testthat")'
```

## Estrutura

- `governanca/` — o registro do processo. Fonte de verdade em YAML, compilada para DuckDB e
  publicada como site. Metas, tarefas com kanban, decisões com alternativas descartadas,
  pendências que bloqueiam tarefas, experimentos com métricas, e o log de interações de IA.
- `app/` — a análise em R, orquestrada por `targets`.
- `docs/` — plano do bimestre, revisão de literatura, convenções.
- `relatorio/` — o relatório de 02/12.

A infraestrutura de governança vem do [Projeto B1](https://github.com/henrillima/Projeto_B1_TRA-48)
do 1º bimestre (`decisao:D01`). Ela não sabe nada sobre o problema: é um grafo validado em CI com
um gerador de site estático.

## Estado

O grafo em `governanca/data/` é a resposta autoritativa. Em 06/10/2026: 5 metas, 27 tarefas,
4 decisões, 4 pendências abertas.

**Pendências que afetam o planejamento:** o grupo ainda não está definido (`P01`), o esquema da
base é desconhecido até 28/10 (`P02`), e não está confirmado se o Projeto B1 do 1º bimestre
segue valendo nota (`P04`).
