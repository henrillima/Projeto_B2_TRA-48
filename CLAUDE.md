# Projeto B2 — TRA-48 · Data Challenge: predição do tempo de táxi na partida

Instruções de projeto. Leia isto inteiro antes de tocar em qualquer arquivo.

---

## 1. O que é este repositório

Projeto do 2º bimestre da disciplina **TRA-48 — Inteligência Analítica: Dados, Modelos e
Decisões** (ITA, 8º semestre, 2026.2). Professores: **Marcelo Xavier Guterres** e
**Mayara Condé Rocha Murça, Maj Eng**.

O problema, nas palavras do enunciado:

> Desenvolvimento de **modelo preditivo do tempo de táxi de uma aeronave durante a partida**
> usando métodos de **aprendizado de máquina supervisionado**.

Projeto em grupo. A composição do grupo ainda não está definida — `pendencia:P01`.

### Prazos duros

| Data | Entrega |
| --- | --- |
| **28/10** | Disponibilização da base de dados (treino e teste) |
| **18/11** | Submissão das previsões para a base de teste |
| **25/11** | Apresentação do projeto — **30% do 2º bimestre** |
| **02/12** | Entrega do relatório — **100% do exame** |

---

## 2. O que o relatório precisa conter

As seis seções são do slide 7 do planejamento do 2º bimestre. Não são sugestão de roteiro: são
a lista contra a qual o trabalho será lido.

1. Descrição do problema de estudo e motivação.
2. Descrição do **pré-processamento** da base — por exemplo, construção de novas features.
3. **Análise exploratória** com visualizações gráficas (boxplot, scatterplot, correlograma) e
   estatísticas descritivas.
4. Descrição dos **métodos** e do processo de treinamento. **Mínimo de 2 métodos de aprendizado
   supervisionado.**
5. Apresentação e interpretação dos **resultados**, com indicação do modelo final escolhido.
   Comparação de desempenho preditivo com **histograma de erros** e métricas **RMSE, MAE, MAPE**.
6. Conclusões.

**Consequência operacional.** O item 2 cobra o *porquê* de cada transformação, e o item 5 cobra
o vínculo entre modelo e métrica. Nenhum dos dois se reconstrói de memória em 01/12. É isso que
justifica a camada de governança aqui — ver §4 e `decisao:D04`.

---

## 3. Layout do repositório

```
.
├── CLAUDE.md                    ← este arquivo
├── README.md
├── R/                           ← A ANÁLISE: cinco scripts no padrão dos Labs (decisao:D05)
│   ├── TRA48_B2_01_exploracao.R        item 3 do relatório
│   ├── TRA48_B2_02_preprocessamento.R  item 2
│   ├── TRA48_B2_03_modelos.R           item 4
│   ├── TRA48_B2_04_avaliacao.R         item 5
│   └── TRA48_B2_05_submissao.R         entrega de 18/11
├── figuras/                     PNGs gerados pelos scripts (prefixo = número do script)
├── resultados/                  tabelas agregadas (.csv/.txt) e logs; nada linha a linha da base
├── docs/                        plano do bimestre e plano de implementação
├── governanca/                  grafo de governança (YAML → DuckDB → site)
├── relatorio/                   LaTeX do relatório (template ~/ITA/_template/Relatório)
├── _arquivo/                    estrutura aposentada de 06/10 (targets/tidymodels), só histórico
└── .github/workflows/
```

A base (`data_project.Rda`) e os `.Rda` intermediários ficam FORA do repositório, na pasta
`~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/`.
A submissão é gravada em `entrega/` dentro dessa pasta.

---


## 4. Stack e decisões já tomadas

Não reabra estas sem registrar uma decisão que supersede a anterior.

| Camada | Escolha | Decisão |
| --- | --- | --- |
| Repositório | Próprio, infraestrutura de governança importada do B1 | `decisao:D01` |
| **Código da análise** | **R no padrão exato dos Labs da professora**: um script por tema, `INTRODUÇÃO` + `ETAPA n`, `setwd` + `load`, `set.seed(1)`, sem funções próprias, nomes de objeto dos Labs | `decisao:D05` (substitui a D02) |
| **Pacotes** | Só os de aula: base, `tree`, `caret`, `e1071`, `neuralnet`, `cluster`, `mclust`, `corrplot`, `pheatmap` | `decisao:D05` |
| Métodos | Baseline, regressão linear, árvore, kNN, SVM (extensão declarada), rede neural | `decisao:D05` |
| Validação | Partição 75/25 do Lab6; hiperparâmetros por validação cruzada dentro do treino; média do MSE dos folds | `decisao:D05` |
| Governança | Mantida, apesar de não haver nota de processo | `decisao:D04` *(provisória)* |
| Banco do grafo | DuckDB, grafo emulado em `node` + `edge` | herdada do B1 |

`targets`, `tidymodels`, `ranger`, `xgboost` e `renv` foram aposentados em 14/11: não foram dados
em aula, e a regra do project é que método e convenção diferentes dos da professora são erro.
A estrutura antiga está em `_arquivo/2026-10-06_app-targets/`.

---


## 5. Regras invioláveis

1. **Nunca commite `governanca/build/` nem arquivos `.Rda`.** São artefatos ou material da disciplina.
   A única fonte de verdade é o texto em `governanca/data/` e o código em `R/`.

2. **Nunca escreva direto no `.duckdb`.** Escrever no grafo é editar YAML e commitar.

3. **Nunca invente um dado.** Se um número não tem procedência rastreável, ele não entra.
   Quando não souber, escreva `[A CONFIRMAR]` e abra uma pendência.

4. **Nunca invente uma referência.** Autor, ano, periódico e DOI precisam ter sido vistos. Não
   se cita a formulação de um artigo que ninguém abriu.

5. **Toda tarefa se vincula a uma meta.** O validador falha se alguma não vincular.

6. **Estado derivável nunca se armazena.** "Bloqueada" não é coluna do kanban — é dedutível de
   uma pendência aberta apontando para a tarefa.

7. **Notas são append-only.** Nunca edite nem apague uma nota antiga; acrescente outra.

8. **Hiperparâmetros e limiares entram como parâmetros, nunca como constantes literais.**
   A grade de busca e os limiares ficam declarados no topo da etapa que os usa.

9. **`set.seed(1)` antes de todo sorteio**, como nos Labs. Submissão que não se
   reproduz é submissão que não se defende.

10. **Nenhuma métrica vai para o relatório sem experimento registrado.** O número da seção 5
    aponta para o nó `experimento` que o produziu, que aponta para o commit.

11. **Nunca rode `git` que modifica estado através da ponte de dispositivo remoto.** A ponte não
    apaga arquivos, então o git não consegue limpar o próprio `.git/index.lock` e o repositório
    trava. Comandos git são rodados pelo Henri no terminal dele.

12. **Versão de GitHub Action só entra se tiver sido lida na fonte autoritativa.** No B1, duas
    majors inventadas (`setup-uv@v9`, `upload-pages-artifact@v5`) mataram dois workflows com
    "unable to resolve action". A fonte é
    `raw.githubusercontent.com/actions/starter-workflows/main/pages/static.yml`.

---

## 6. O ciclo de trabalho

```
1. ABRIR      Consultar o grafo: o que está fazendo, o que está bloqueado
2. TRABALHAR  Mover a tarefa para `fazendo` ao começar
3. REGISTRAR  Decisões, fontes, experimentos com métricas, esta interação de IA
              COM CRÍTICA, notas nas tarefas tocadas
4. VALIDAR    make validar
5. COMMITAR   git add -A && git commit -m "..."   ← a mensagem cita os ids tocados
```

### O registro de IA exige crítica

Herdado do B1 e mantido por convicção, não por nota: *quem não consegue criticar a resposta não
a entendeu, e portanto não pode assiná-la.*

**Claude: ao fim de cada sessão substantiva, escreva você mesmo o rascunho do registro de
interação, incluindo a autocrítica.** Diga o que na sua própria resposta foi estimativa e não
medição, o que foi confirmado só em metadado, e onde outra escolha seria defensável. Registro
com `aceito: integral` e crítica vazia não passa no validador — `critica_humana` tem mínimo de
20 caracteres, e o espírito da regra pede muito mais que isso.

---

## 7. Comandos

```bash
make validar                 # schema + integridade do grafo
make site                    # gera _site/

# a análise, em ordem (cada script lê o .Rda salvo pelo anterior)
Rscript R/TRA48_B2_01_exploracao.R
Rscript R/TRA48_B2_02_preprocessamento.R
Rscript R/TRA48_B2_03_modelos.R      # o mais lento: SVM (~15 min) e rede neural
Rscript R/TRA48_B2_04_avaliacao.R
Rscript R/TRA48_B2_05_submissao.R
```

---


## 8. Convenções de código

- **R: o padrão dos Labs é a referência.** Cabeçalho `INTRODUÇÃO`, blocos `ETAPA n` em maiúsculas
  entre linhas de `#`, comentário em português antes de cada passo e interpretação do resultado
  depois, `set.seed(1)` antes de todo sorteio, nomes de objeto dos Labs (`tree_model`,
  `cv_results`, `optimal_k`, `best_svm_model`, `nn_model`, `yhat`…). Gráficos em R base.
- Liberdade só no visual: paleta e estilo definidos no topo de cada script.
- **Python:** só ferramentas de governança, com `uv`.
- **Nunca** commitar a base do challenge nem `.Rda` derivado dela.

---


## 9. Onde encontrar o quê

| Preciso de | Está em |
| --- | --- |
| Calendário, pesos e marcos do bimestre | `docs/00-plano-2b.md` |
| O enunciado oficial | `~/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/Projeto B2.pdf` |
| Material das aulas e dos Labs | `~/ITA/08-semestre/TRA-48/aulas/2-bimestre/labs/` |
| O plano de implementação | `docs/01-plano-de-implementacao.md` |
| Revisão de literatura de taxi-out | `docs/01-revisao-literatura.md` *(a escrever, T43)* |
| O estado atual do projeto | o grafo: `governanca/data/`, ou o site publicado |
| O projeto do 1º bimestre | `~/dev/ita/Projeto_B1_TRA-48` — sem prazo e sem cobrança |

---

## 10. Coisas que este projeto não vai fazer

- **Métodos que não foram dados em aula** (floresta aleatória, boosting, deep learning). `decisao:D05`.
- **Usar `crwy`.** `taxitime = crwy − cpush` exatamente; o horário de decolagem não existe no
  momento do pushback. `pendencia:P05`.
- **Feature engineering a partir de fonte externa não citável.** Meteorologia e dados de pátio
  só entram se vierem na base ou de fonte com procedência registrada como nó `fonte`.
- **Otimizar o MAPE.** Se a resposta tiver táxis muito curtos, MAPE explode e deixa de medir o
  que interessa. Ele é reportado porque o enunciado pede, não é o critério de escolha.
