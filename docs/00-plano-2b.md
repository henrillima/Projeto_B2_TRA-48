# Plano do 2º bimestre — TRA-48

Fonte: `TRA48_2B_2026.pdf` (planejamento do 2º bimestre, Prof.ª Mayara Condé Rocha Murça) e
e-mail da professora de 06/10/2026 sobre a mudança de horário.

---

## 1. Calendário

O PDF lista as semanas em **quartas-feiras**. O e-mail de 06/10, atendendo a pedido do
representante de turma, **move as aulas para quinta-feira, 14h–17h**, exceto as **semanas 3 e 6,
que permanecem na quarta, 9h–12h**. A tabela abaixo já aplica a reconciliação.

| Sem. | Data (PDF) | Data/hora efetiva | Conteúdo | Lab |
| :--: | --- | --- | --- | :--: |
| 1 | qua 07/10 | **qui 08/10, 14h–17h** | Introdução ao aprendizado de máquina · Exploração e visualização de dados | Lab1 |
| 2 | qua 14/10 | **qui 15/10, 14h–17h** | Aprendizado não-supervisionado: clusterização · k-médias · hierárquica | Lab2 |
| 3 | qua 21/10 | **qua 21/10, 9h–12h** | Modelo de mistura gaussiana · Validação de clusters | Lab3 |
| 4 | qua 28/10 | **qui 29/10, 14h–17h** | Aprendizado supervisionado: classificação e regressão · kNN · árvores de decisão · SVM | Lab4 |
| 5 | qua 04/11 | **qui 05/11, 14h–17h** | Regressão logística · redes neurais · seleção de modelos e avaliação preditiva | Lab5 |
| 6 | qua 11/11 | **qua 11/11, 9h–12h** | Detecção de anomalias | Lab6 |
| 7 | qua 18/11 | **18/11, 9:00** | Prova B2 liberada no Classroom · submissão das previsões do B2 | — |
| 8 | qua 25/11 | **25/11 ou 26/11** | Apresentação do Projeto B2 | — |
| — | qua 02/12 | **02/12** | Entrega do relatório do Projeto B2 | — |

`pendencia:P03` registra o que não está claro: se a mudança para quinta alcança a apresentação
da semana 8 e a liberação da base na semana 4 (28/10). A liberação da Prova B2 tem hora
explícita no PDF e foi mantida.

Material postado no Classroom **semanalmente, nas quartas-feiras, após as aulas**. Dúvidas pelo
Classroom ou em mayara.conde@gp.ita.br.

---

## 2. Avaliação

| Período | Composição |
| --- | --- |
| 1º bimestre | Prova B1 — 100% |
| 2º bimestre | Prova B2 — **70%** + Apresentação do Projeto B2 — **30%** |
| Exame | Relatório do Projeto B2 — **100%** |

O Projeto B1 (localização de vertiportos) não aparece na composição. `pendencia:P04`.

### Prova B2

Individual, **com consulta permitida** a todo o material do curso. Liberada no Classroom em
**18/11 às 9:00**, com **48 horas** para submissão via Google Forms — portanto até **20/11, 9:00**.
Cobre o conteúdo das semanas 1 a 6.

---

## 3. Projeto B2 — marcos e dependências

```
  08/10 ─ Lab1          ┐
  15/10 ─ Lab2          │  aprendizado dos métodos
  21/10 ─ Lab3          │  (nenhum bloqueia o pipeline)
  29/10 ─ Lab4          ┘
                        │
  28/10 ─ BASE LIBERADA ──► T11 dicionário ─► T12 ingestão ─► T13 limpeza
                                                           └► T14 features ─► T20..T22 EDA
                                                                            └► T15 split
                                                                                 └► T30 baseline
                                                                                      └► T31 floresta
                                                                                      └► T32 boosting
                                                                                           └► T33 tuning
                                                                                                └► T34 comparação
                                                                                                     └► T35 modelo final
  18/11 ─ SUBMISSÃO ◄──────────────────────────────────────────────────────────────────────────────────┘
  25/11 ─ APRESENTAÇÃO
  02/12 ─ RELATÓRIO
```

O caminho crítico tem **três semanas** entre a liberação da base e a submissão, e nessas mesmas
três semanas caem Lab4, Lab5, Lab6 e a Prova B2. É por isso que `decisao:D03` manda construir e
testar o pipeline inteiro antes de 28/10, contra base sintética: quando o dado chegar, o que
sobra é trocar a fonte e investigar o que o dado real tem de diferente do esperado.

### O que precisa estar pronto em 27/10

- [ ] Pipeline `targets` completo rodando sobre a base sintética (T03, T06)
- [ ] Ambiente R fixado por `renv.lock` (T04)
- [ ] Figuras da EDA geradas com dado sintético, só esperando a troca da fonte (T21)
- [ ] Baseline, floresta e boosting treinando e reportando RMSE, MAE e MAPE (T30–T32)
- [ ] Rotina de submissão escrita, formato a confirmar quando a base chegar (T40)
- [ ] Revisão de literatura escrita (T43)
- [ ] Grupo definido e frentes divididas (T05)

Se essa lista estiver fechada em 27/10, as três semanas seguintes são sobre o dado, não sobre
infraestrutura.

---

## 4. Conteúdo exigido no relatório

Slide 7 do planejamento, literal:

1. Descrição do problema de estudo e motivação.
2. Descrição do pré-processamento da base (ex.: construção de novas features).
3. Análise exploratória da base, com uso de visualizações gráficas (ex.: boxplot, scatterplot,
   correlograma) e estatísticas descritivas.
4. Descrição dos métodos utilizados e do processo de treinamento dos modelos — **mínimo de 2
   métodos de aprendizado de máquina supervisionado**.
5. Apresentação e interpretação dos resultados obtidos, com a indicação do modelo final
   escolhido — comparação do desempenho preditivo dos modelos apresentando **histograma de
   erros** e métricas como **RMSE, MAE, MAPE**.
6. Conclusões do trabalho.

---

## 5. Material de aula

Fica na pasta da disciplina, não neste repositório:
`~/ITA/08-semestre/TRA-48/2-bimestre/` — `aulas/`, `labs/`, `projeto-b2/`, `prova-b2/`, `notas/`.

**Lab1, 08/10:** notebook com **RStudio instalado** e o arquivo **`TRA48_Lab1_data.Rda`**
(em `2-bimestre/labs/lab1/`). Testar `load("TRA48_Lab1_data.Rda")` antes da aula — `tarefa:T44`.
