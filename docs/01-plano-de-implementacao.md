# Projeto B2 — Plano de implementação

TRA-48 · Data Challenge: tempo de táxi na partida em SBGR · versão de 14/11/2026 (revista à noite com as decisões do grupo)

Grupo: Henri Leonardo dos Santos Lima, Antonio Garcia e Gilberto Patri. Os scripts estão em `R/` (`TRA48_B2_01` a `05`).

Este é o roteiro de execução do projeto, do carregamento da base à submissão de 18/11, à
apresentação de 25/11 e ao relatório de 02/12. Cada etapa diz **o que fazer, com qual método
de aula, com qual função de qual Lab e qual figura ou tabela ela gera para o relatório**.

A regra que manda em tudo: **o código segue o padrão dos Labs da professora Mayara**: mesma
estrutura de arquivo, mesmas funções, mesmos pacotes, mesmos nomes de objeto. Personalizamos
só o visual das figuras.

---

## 1. Inventário do material — conferido contra o Classroom em 14/11

Todas as aulas do 2º bimestre tiveram Lab, e todo o material publicado está na pasta
`~/ITA/08-semestre/TRA-48/aulas/2-bimestre/labs/`. **Não falta nada.**

| Aula | Conteúdo dos slides | Roteiro | Dados | Na pasta |
|---|---|---|---|:-:|
| 1 | Exploração e visualização de dados, PCA, *bootstrap* | `TRA48_Lab1.R` | `TRA48_Lab1_data.Rda` (chegadas em CGH) | ✅ |
| 2 | Clusterização: k-means, hierárquica, validação | `TRA48_Lab2.R` | `TRA48_Lab2_data.Rda` + `_tracks.Rda` | ✅ |
| 3 | Mistura gaussiana (GMM), EM, BIC | `TRA48_Lab3.R` | usa os dados do Lab2 | ✅ |
| 4 | Supervisionado I: validação cruzada, kNN, árvores, regressão logística, **métricas de regressão (MAE, MAPE, RMSE)** | `TRA48_Lab4.R` | `TRA48_Lab4_data.Rda` | ✅ |
| 5 | Supervisionado II: SVM, redes neurais e **problemas de regressão** (regressão linear, kNN, árvore e rede para *y* contínuo) | `TRA48_Lab5.R` | usa os dados do Lab4 | ✅ |
| 6 | Detecção de anomalias; classes desbalanceadas; métricas especializadas | `TRA48_Lab6.R` | `TRA48_Lab6_data.Rda` (atrasos de voo) | ✅ |
| Projeto | Enunciado | — | `data_project.Rda` | ✅ |

O aviso de 10/11 também reenviou o `TRA48_Lab2_data_tracks.Rda`, mas o roteiro do Lab6 não o usa.

**Uma observação que muda o plano:** todos os Labs supervisionados são de **classificação**. O
projeto é de **regressão**: o `taxitime` é contínuo, em segundos. A ponte entre os dois está nos
slides finais da Aula 5 (*Regression Problems*), que mostram a versão de regressão de cada método,
e no slide 36 da Aula 4, que define as três métricas pedidas. O plano adapta cada função dos
Labs para regressão sem trocar de pacote.

---

## 2. O padrão de código da professora — o que vamos copiar

Extraído dos seis roteiros.

**Estrutura de arquivo**

```r
##############
# INTRODUÇÃO #
##############

# LABx: <tema>

# Ir para o diretório onde o dataset ... se encontra
setwd('~/Desktop/')
# Carregar o dataset
load("arquivo.Rda")

# <descrição da base em comentário>

# Instalar e carregar os pacotes que serão utilizados
install.packages('tree')
library(tree)


###############################
# ETAPA 1: <NOME EM MAIÚSCULAS> #
###############################

# <comentário explicando o que vai ser feito e por quê>
```

**Convenções que se repetem em todos os Labs**

- Um arquivo por tema, dividido em `ETAPA 1, 2, 3…` com o cabeçalho de `#` acima.
- Comentário em português **antes** de cada linha relevante, explicando o porquê, e comentário
  **depois** do resultado, interpretando o número ("Árvore obtida tem 12 folhas e erro de 11,3%").
- `set.seed(1)` imediatamente antes de qualquer sorteio.
- Gráficos em R base: `plot`, `hist`, `boxplot`, `barplot`, `pairs`, `par(mfrow=…)`; `corrplot` e
  `pheatmap` para correlação.
- Sem funções próprias: tudo é escrito em linha, mesmo que repetido (veja a acurácia recalculada
  a cada método no Lab4).
- Nomes de objeto fixos, que vamos manter:

| Método | Nomes usados pela professora |
|---|---|
| Partição | `idxtrain`, `data_train`, `data_test` (Lab6) |
| Árvore | `tree_model`, `cv_results`, `min_idx`, `optimal_tree_size`, `best_pruned_tree_model` |
| kNN | `knn_model`, `idx`, `k_range`, `crossvalidation_…`, `optimal_k`, `best_knn_model` |
| SVM | `svm_model`, `cv_results`, `best_svm_model` |
| Rede neural | `nn_model` |
| Regressão | `lr_model` (no Lab4 é a logística; para a linear usaremos `lm_model`) |
| Previsão | `yhat` |
| PCA | `pca_out`, `pve` |
| Clusterização | `kmeans_out`, `clusterid`, `centroids`, `hc_average_out`, `gmm_out`, `s_index` |

**Pacotes e funções por método.** Só estes; nada que não tenha aparecido em aula.

| Método | Pacote | Função | Lab |
|---|---|---|---|
| Estatística descritiva | base | `summary`, `apply`, `aggregate` | 1 |
| Correlograma | `corrplot` | `corrplot` | 1 |
| Heatmap | `pheatmap` | `pheatmap` | 1 |
| PCA | base | `prcomp(x, scale=TRUE)` | 1 |
| k-means | base | `kmeans(x, k, nstart=20)` | 2 |
| Hierárquica | base | `hclust(dist(x), method='average')`, `cutree` | 2 |
| Silhouette | `cluster` | `silhouette`, `sortSilhouette` | 2, 3 |
| GMM | `mclust` | `Mclust` | 3 |
| Árvore | `tree` | `tree`, `tree.control`, `cv.tree`, `prune.tree` | 4, 6 |
| kNN | `caret` | `createFolds`; `knn3` → **`knnreg`** na regressão | 4 |
| Regressão | base | `glm` (logística) → **`lm`** na regressão linear | 4 |
| SVM | `e1071` | `svm`, `tune` | 5, 6 |
| Rede neural | `neuralnet` | `neuralnet(…, linear.output=…)` | 5 |

`knnreg` é a função irmã da `knn3` no mesmo pacote `caret`. `lm` é a regressão linear do slide
*Linear Regression* da Aula 5. São as duas únicas funções novas, e cada uma é a contraparte de
regressão de uma função usada em aula.

---

## 3. Mapa dos métodos de aula → uso no projeto

| Aula | Método | Entra no projeto como | Item do relatório |
|---|---|---|:-:|
| 1 | Estatísticas descritivas, barplot, histograma, boxplot, scatterplot, `pairs`, correlograma, heatmap | Análise exploratória completa | 3 |
| 1 | PCA | Exploração da estrutura das variáveis numéricas | 3 |
| 1 | *Bootstrap* | Intervalo de confiança do RMSE e comparação entre modelos | 5 |
| 2 | k-means, hierárquica, silhouette | Detecção de anomalias pela abordagem de clusterização (Aula 6) | 2 |
| 3 | GMM | Detecção de anomalias pela abordagem estatística (baixa probabilidade) | 2 |
| 4 | Validação cruzada (*hold-out*, *k-fold*) | Desenho de validação de todo o projeto | 4 |
| 4 | Árvore de decisão (CART) | **Modelo M2: árvore de regressão** | 4, 5 |
| 4 | kNN | **Modelo M3: kNN de regressão** | 4, 5 |
| 4 | Regressão logística | Não se aplica: a saída é contínua. Citar no relatório como excluída e explicar por quê | 4 |
| 4 | MAE, MAPE, RMSE | Métricas de comparação | 5 |
| 5 | Regressão linear (mínimos quadrados) e transformação de variável | **Modelo M1: regressão linear**, com e sem `log(taxitime)` | 4, 5 |
| 5 | SVM | **Modelo M4: SVM de regressão** | 4, 5 |
| 5 | Redes neurais | **Modelo M5: rede neural de regressão** | 4, 5 |
| 6 | Detecção de anomalias | Identificar voos com táxi anômalo e testar o efeito de tratá-los | 2 |
| 6 | Pesos para classes desbalanceadas | Não se aplica: é técnica de classificação | — |

São **cinco métodos supervisionados**, mais um *baseline*. O enunciado pede no mínimo dois.

> **SVM de regressão.** Os slides da Aula 5 apresentam o SVM só para classificação e, na parte de
> regressão, citam kNN, CART e ANN. A mesma função `svm()` do `e1071` faz regressão sozinha quando
> *y* é numérico (*ε-regression*). Entra no projeto, mas no relatório deve aparecer como extensão
> do que foi visto em aula, com uma frase explicando a diferença. **Decidido em 14/11: entra como
> extensão declarada.**

---

## 4. Fatos da base que condicionam o plano

Levantados em 14/11 a partir do `data_project.Rda`. Todos devem ser reconferidos no R, na Etapa 1.

| Fato | Valor | Consequência |
|---|---|---|
| Objetos | `data_train` 6.426 × 14 e `data_test` 1.607 × 14, ambos `data.table` | Converter com `as.data.frame()` logo após o `load` |
| Vazamento | `taxitime = crwy − cpush` exatamente; `crwy` vem preenchido no teste | **`crwy` nunca entra em nenhum modelo** |
| `adep` | Sempre `SBGR` | Descartar |
| `taxitime` | Mediana 827 s, média 871 s, dp 271 s, mín. 434 s, máx. 2.168 s | — |
| Assimetria | 1,20 em `taxitime` e 0,32 em `log(taxitime)` | Testar o log na regressão linear |
| Anômalos | 223 voos acima de Q3 + 1,5·IQR (1.003 + 1,5·325 s); nenhum abaixo de Q1 − 1,5·IQR | Etapa de detecção de anomalias |
| `nactive` | De 0 a 23; correlação 0,68 com `taxitime` | A variável mais forte |
| `runway` | 10L: mediana 751 s (4.562 voos); 28R: mediana 985 s (1.864 voos) | Efeito de ~234 s: a cabeceira tem que entrar |
| `wtc` | M: 804 s; H: 1.060 s (medianas) | Entra |
| `wx` | 0: 824 s; 1: 1.011 s (medianas; 141 voos com `wx = 1`) | Entra |
| Vento | Direção correlacionada com a cabeceira (mediana de 110° na 10L e 290° na 28R). Vento calmo é codificado como direção 0 e velocidade 0 (239 voos) | Usar componentes vetoriais, não o ângulo cru |
| `ades` | **96 destinos**; 16 com menos de 10 voos; `SDSC` aparece só no teste | O pacote `tree` não aceita fator com mais de 32 níveis: agrupar |
| `acfttype` | 21 tipos; `B763` com 1 voo | Agrupar os raros |
| `airline` | 10 companhias, todas no treino e no teste | Entra direto |
| Hora local | Picos de mediana à 0 h, às 9 h e às 18 h; pouquíssimos voos entre 2 h e 4 h | Hora como variável; faixa horária na regressão linear |
| Treino × teste | Os dois cobrem janeiro inteiro, intercalados | Divisão aleatória, como no Lab6 |

---

## 5. Desenho da validação

É exatamente o processo do slide 7 da Aula 4, com a partição do Lab6.

```
data_project.Rda
├── data_train (6.426, com taxitime) ──► renomeado para  data
│        │
│        │  ETAPA 1 do Lab6: set.seed(1); sample 75% / 25%
│        ├──► data_train (4.819)   treino + validação cruzada dos hiperparâmetros
│        │                         (cv.tree, createFolds, tune — as funções de cada Lab)
│        └──► data_test  (1.607)   NUNCA usado para escolher hiperparâmetro.
│                                  Só no fim: compara os modelos M0–M5
│                                  com RMSE, MAE, MAPE e histograma de erros
│
│        modelo final escolhido ──► retreinado com os 6.426 voos
│
└── data_test (1.607, sem taxitime) ──► renomeado para  data_final
                                        previsão ──► submissão de 18/11
```

`0,75 × 6.426 = 4.819,5`, e o `sample` usa 4.819. A nossa base de teste interna fica com
**1.607 voos, o mesmo tamanho da base de teste da professora.**

**Média ou mediana entre os *folds*?** O slide 9 da Aula 4 diz *"smallest average validation
error"*. O código do kNN no Lab4 usa `apply(accuracy, 1, median)`. **Decidido em 14/11:** os
scripts calculam e mostram as duas, mas a escolha é pela **média do MSE dos *folds***. Motivo: a
métrica do desafio é o RMSE, raiz de uma média de erros quadráticos sobre todos os voos; a média
dos *folds* estima exatamente isso, e a mediana descarta justamente os *folds* com cauda pesada,
que são os que mais pesam no RMSE. `cv.tree` (soma do desvio) e `tune` (média) já agregam assim.

---

## 6. Estrutura dos arquivos

O código mora no repositório da disciplina, como manda a regra das pastas. A base fica fora do
git: é material da disciplina, e o repositório é público.

```
~/dev/ita/Projeto_B2_TRA-48/
├── R/
│   ├── TRA48_B2_01_exploracao.R        → item 3 do relatório
│   ├── TRA48_B2_02_preprocessamento.R  → item 2
│   ├── TRA48_B2_03_modelos.R           → item 4
│   ├── TRA48_B2_04_avaliacao.R         → item 5
│   └── TRA48_B2_05_submissao.R         → entrega de 18/11
├── figuras/       PNGs gerados pelos scripts, com o nome da figura no relatório
├── resultados/    tabela_metricas.csv, hiperparametros.txt (pequenos e citáveis)
├── relatorio/     LaTeX (template: ~/ITA/_template/Relatório)
└── apresentacao/
```

Cada script segue a estrutura da seção 2. Eles conversam por `save()`/`load()`, que é o mesmo
mecanismo dos Labs: o 02 salva `data_project_prep.Rda`, o 03 salva os modelos e as previsões, e
assim por diante. Os `.Rda` intermediários ficam na pasta da base, fora do git.

O `setwd` no topo de cada script aponta para a pasta onde está o `data_project.Rda`, no lugar do
`~/Desktop/` dos Labs.

**O que sai do repositório.** A estrutura com `targets`, `tidymodels`, `ranger` e `xgboost` que
montamos em 06/10 (`app/`, `decisao:D02`, tarefas T03, T04, T06, T31 e T32) usa métodos e
ferramentas que não foram dados em aula. Pela regra do material de aula como referência, ela
precisa ser substituída por este plano. Ver seção 12.

---

## 7. Script 01 — Exploração (item 3 do relatório)

Modelo: `TRA48_Lab1.R`, Etapas 1 a 3.

```r
load("data_project.Rda")
data <- as.data.frame(data_train)          # 6.426 voos com taxitime
data_final <- as.data.frame(data_test)     # 1.607 voos a prever
class(data$cpush)                          # conferir: POSIXct em UTC
```

### ETAPA 1 — Estatísticas descritivas

- `summary(data)`; `apply(x, 2, mean)` e `apply(x, 2, var)` nas numéricas (Lab1).
- `aggregate(taxitime ~ runway, data, FUN=median)`, e o mesmo para `wtc`, `wx` e `airline`.
- Tabela para o relatório: n, média, mediana, dp, mín. e máx. do `taxitime`, geral e por cabeceira.

### ETAPA 2 — Visualizações

Cada gráfico responde uma pergunta; a pergunta vai na legenda do relatório.

| Gráfico | Pergunta |
|---|---|
| `hist(taxitime)` e `hist(log(taxitime))` | Qual é a forma da distribuição? O log a simetriza? |
| `boxplot(taxitime)` | Quantos voos estão fora do padrão? |
| `barplot` de voos por companhia, cabeceira, `wtc` e hora | Como a amostra está distribuída? |
| `boxplot(taxitime ~ runway)` | Quanto a cabeceira muda o táxi? |
| `boxplot(taxitime ~ wtc)`, `~ wx`, `~ airline` | Aeronave pesada, meteorologia e companhia importam? |
| `boxplot(taxitime ~ hora)` | Existe padrão ao longo do dia? |
| `plot(nactive, taxitime, col=runway)` | O congestionamento explica o táxi? Do mesmo jeito nas duas cabeceiras? |
| `pairs(~ taxitime + nactive + wind_speed + hora, data)` | Relações entre pares |
| `corrplot(cor(x))` e `pheatmap` | Correlações entre as numéricas |
| `plot(wind_direction, runway)` | Confirmar que a cabeceira acompanha o vento |

### ETAPA 3 — PCA

`pca_out <- prcomp(x, scale=TRUE)` nas numéricas, com o gráfico de PVE e o de PVE acumulada, como
no Lab1. Com poucas variáveis numéricas a PCA é sobretudo ilustrativa: entra no relatório só se
mostrar estrutura. Se não mostrar, uma frase dizendo isso é melhor do que uma figura vazia.

**Saída:** 10 a 12 figuras em `figuras/` e a tabela descritiva.

---

## 8. Script 02 — Pré-processamento (item 2 do relatório)

### ETAPA 1 — Juntar para transformar igual

Para que treino e submissão recebam **exatamente** as mesmas transformações, sem escrever função,
empilhamos as duas bases, transformamos uma vez e separamos de novo:

```r
data$origem_base <- 'treino'; data_final$origem_base <- 'final'
all <- rbind(data, data_final)
```

### ETAPA 2 — Descartar o que não pode ou não precisa entrar

| Variável | Motivo |
|---|---|
| `crwy` | Vazamento: é a resposta (`taxitime = crwy − cpush`) e não existe no momento do pushback |
| `adep` | Constante (sempre SBGR) |
| `id` | Identificador. Fica guardado para montar a submissão, mas não entra em modelo |
| `cpush` | Substituído pelas variáveis de calendário abaixo |

### ETAPA 3 — Construção de variáveis (*features*)

Todas usam só o que se sabe **no momento do pushback**.

| Nova variável | Como | Por quê |
|---|---|---|
| `hora` | `as.POSIXlt(cpush, tz='America/Sao_Paulo')$hour` | Picos ao longo do dia; a base está em UTC |
| `faixa` | `cut(hora, c(-1,5,9,13,17,21,23))`, como fator | Hora não linear para a regressão linear |
| `dia_semana` | `as.POSIXlt(…)$wday`, como fator | Padrão semanal de demanda |
| `domestico` | Prefixo ICAO de `ades` em {SB, SD, SI, SJ, SN, SS, SW} → 1; senão 0 | Resolve o limite de 32 níveis e o `SDSC`, que só aparece no teste |
| `regiao` | Primeira letra do ICAO de `ades`, agrupada nos níveis `dom`, `am_sul`, `am_norte`, `europa`, `outros` | Voo longo, aeronave pesada e posição de gate. Níveis sem espaço nem acento: a rede neural monta a fórmula pelos nomes das colunas do `model.matrix` |
| `acft` | `acfttype` com os tipos de menos de 30 voos agrupados em `outros_M` e `outros_H` (pela `wtc`), contados **só em `data`** | `B763` com 1 voo quebra a previsão se cair só na base de teste. O `tree` aceita fator de até 32 níveis, e os 21 tipos já passariam; o problema aqui são os níveis raros |
| `vento_ns`, `vento_lo` | `wind_speed·cos(dir)` e `wind_speed·sin(dir)`, com dir em radianos, em kt | O ângulo cru trata 350° e 10° como distantes; o vento calmo (0, 0) vira (0, 0) sem caso especial |
| `log_taxitime` | `log(taxitime)` | Variável transformada para a regressão linear (Aula 5) |

Conferências obrigatórias:

- Os prefixos ICAO do Brasil e as letras de região devem ser checados no **ICAO Doc 7910**
  (*Location Indicators*) antes de entrar no relatório.
- **Componente de vento de proa (opcional).** Exige o rumo **verdadeiro** de cada cabeceira de
  SBGR, porque a direção do vento no METAR é verdadeira e o número da pista é magnético. Esse
  rumo sai da **AIP Brasil, AD 2 SBGR** (AISWEB). Sem essa fonte, a variável não entra.
- **Pushbacks recentes (opcional).** Número de voos com `cpush` nos 15 ou 30 minutos anteriores,
  contado em `all`, que junta treino e teste e onde todos os voos são reais. Só olha para trás, então
  não vaza. A base é uma amostra das partidas, então a contagem é parcial. Entra só se melhorar o
  RMSE no *hold-out*.

### ETAPA 4 — Fatores e separação

Converter para fator **em `all`**, antes de separar. Assim treino e teste têm os mesmos níveis e o
`predict` não quebra. Depois:

```r
data <- all[all$origem_base=='treino',]
data_final <- all[all$origem_base=='final',]
```

### ETAPA 5 — Partição treino/teste (cópia da Etapa 1 do Lab6)

```r
set.seed(1)
idxtrain <- sample(1:nrow(data), 0.75*nrow(data))
data_train <- data[idxtrain,]
data_test <- data[-idxtrain,]
```

### ETAPA 6 — Detecção de anomalias (Aula 6)

Só em `data_train`. A base de teste da professora também tem voos anômalos, então **detectar não é
o mesmo que remover**. A remoção é um experimento, decidido pelo *hold-out* no Script 04.

1. **Estatística** (Aula 1 e Aula 6): boxplot e regra 1,5·IQR, por cabeceira.
2. **Clusterização** (Aula 6, com o código do Lab2): `kmeans` em `scale(cbind(nactive, taxitime))`, com
   k escolhido pelo cotovelo e conferido por `silhouette`. Para cada voo, `r_i` = distância ao
   centroide / distância média do cluster, como no slide da Aula 6. Voos com `r_i` alto são candidatos.
3. **GMM** (Lab3): `Mclust` nas mesmas duas variáveis. Voos em região de baixa probabilidade são
   candidatos.
4. Figura: `plot(nactive, taxitime)` com os anômalos destacados pelos três critérios.
5. Saída: a coluna `anomalo` (0/1) em `data_train`, usada no experimento do Script 04.

### ETAPA 7 — Matrizes numéricas normalizadas (para kNN e rede neural)

O slide 16 da Aula 4 manda normalizar no kNN, e a rede neural precisa de entradas numéricas.

```r
X_train <- model.matrix(~ nactive + hora + dia_semana + runway + wtc + acft + airline +
                          domestico + regiao + vento_ns + vento_lo + wx, data_train)[,-1]
X_test  <- model.matrix(~ <mesma fórmula>, data_test)[,-1]
centro <- apply(X_train, 2, mean); escala <- apply(X_train, 2, sd)
X_train_s <- scale(X_train, center=centro, scale=escala)
X_test_s  <- scale(X_test,  center=centro, scale=escala)
```

Média e desvio padrão vêm **só do treino** e são aplicados ao teste. Colunas com `sd = 0` no treino
(nível ausente) saem antes do `scale`.

**Saída:** `save(data, data_final, data_train, data_test, X_train_s, X_test_s, centro, escala, file='data_project_prep.Rda')`

---

## 9. Script 03 — Modelos (item 4 do relatório)

Uma ETAPA por método, na ordem da tabela. Todos treinam em `data_train` com os hiperparâmetros
escolhidos por validação cruzada **dentro** de `data_train`, e todos guardam `yhat_<método>` sobre
`data_test`.

Fórmula comum (os métodos de fórmula recebem esta; kNN e rede recebem as matrizes da Etapa 7):

```r
taxitime ~ nactive + hora + dia_semana + runway + wtc + acft + airline + domestico + regiao + vento_ns + vento_lo + wx
```

### ETAPA 1 — M0: *baseline*

```r
yhat_base <- rep(mean(data_train$taxitime), nrow(data_test))
```

Sem régua não se sabe se um modelo é bom. Vale também a mediana por cabeceira como segunda régua.

### ETAPA 2 — M1: regressão linear (Aula 5)

```r
lm_model <- lm(taxitime ~ nactive + faixa + dia_semana + runway + wtc + acft + airline +
                 domestico + regiao + vento_ns + vento_lo + wx, data=data_train)
summary(lm_model)          # coeficientes interpretáveis: o item 5 do relatório agradece
yhat_lm <- predict(lm_model, data_test)

lm_log_model <- lm(log(taxitime) ~ <mesmos termos>, data=data_train)
yhat_lmlog <- exp(predict(lm_log_model, data_test))
```

Aqui a hora entra como `faixa` (fator), porque a relação dela com o táxi não é linear. A versão
com log segue o slide *"transform variables so that a linear model may become applicable"*.
Comparamos as duas pelo RMSE **em segundos**, já com a volta pelo `exp`.

### ETAPA 3 — M2: árvore de regressão (Lab4, Etapa 1, e Lab6, Etapa 2)

```r
tree_model <- tree(taxitime ~ <fórmula comum>, data=data_train,
                   control=tree.control(nobs=nrow(data_train), mindev=0, minsize=10, mincut=5))
set.seed(1)
cv_results <- cv.tree(tree_model, FUN=prune.tree, K=10)
plot(cv_results$size, cv_results$dev, type="b")
min_idx <- which.min(cv_results$dev)
optimal_tree_size <- cv_results$size[min_idx]
best_pruned_tree_model <- prune.tree(tree_model, best=optimal_tree_size)
plot(best_pruned_tree_model); text(best_pruned_tree_model)
yhat_tree <- predict(best_pruned_tree_model, data_test)
```

**Ajuste de 14/11, depois da primeira execução real:** com `minsize=2, mincut=1` (o controle do Lab4)
o `tree` parou com *"maximum depth reached"*. Com *y* contínuo, quase toda folha só fica pura com 1 voo,
e a árvore passa de 30 níveis, o limite do pacote. Ficou `mindev=0` com o `minsize=10` e o `mincut=5`
padrão do `tree.control`. Numa simulação das mesmas regras com a nossa base, a árvore cheia fica com cerca
de 23 níveis e 750 a 1.000 folhas, bem maior que a podada. Quem decide o tamanho continua sendo a poda por
validação cruzada.

**Segundo ajuste, 18/11:** na execução real a `cv.tree` deu RMSE idêntico (155,9 s) para todos os tamanhos de
9 a 756 folhas, e o `which.min` ficou com a árvore inteira, só por ser o primeiro do empate. Causa: dentro de
cada fold a `cv.tree` recresce a árvore com o `tree.control` padrão (`mindev=0.01`), e não com o nosso
controle; as árvores dos folds ficam pequenas e árvores maiores não são avaliadas. O tamanho agora é escolhido
com o laço de validação cruzada do kNN do Lab4 (`createFolds`, 10 folds, mesmo controle em cada fold, poda em
cada tamanho, média do MSE). A `cv.tree` continua no script e aparece na figura, para mostrar o problema.

O código é o do Lab, sem o `type='class'`. Com *y* numérico, o `tree` mede a impureza do nó pelo
erro quadrático, exatamente como no slide da Aula 5. A árvore podada também é a melhor figura de
interpretação do relatório: mostra quais variáveis cortam primeiro.

### ETAPA 4 — M3: kNN de regressão (Lab4, Etapa 2)

```r
set.seed(1)
idx <- createFolds(data_train$taxitime, k=5)
k_range <- c(1,5,10,15,20,25,30,40,50)
rmse <- matrix(nrow=length(k_range), ncol=5)
for (i in 1:length(k_range)){
  for (fold in 1:5){
    knn_model <- knnreg(X_train_s[-idx[[fold]],], data_train$taxitime[-idx[[fold]]], k=k_range[i])
    yhat <- predict(knn_model, X_train_s[idx[[fold]],])
    rmse[i, fold] <- sqrt(mean((yhat - data_train$taxitime[idx[[fold]]])^2))
  }
}
crossvalidation_rmse <- apply(rmse, 1, mean)      # ver seção 5: média ou mediana
plot(k_range, crossvalidation_rmse, type='b')
optimal_k <- k_range[which.min(crossvalidation_rmse)]
best_knn_model <- knnreg(X_train_s, data_train$taxitime, k=optimal_k)
yhat_knn <- predict(best_knn_model, X_test_s)
```

É o laço do Lab4 linha por linha, com acurácia virando RMSE e `which.max` virando `which.min`.
Na regressão, o kNN prevê a média de *y* dos k vizinhos (slide da Aula 5).

### ETAPA 5 — M4: SVM de regressão (Lab5, Etapa 1, e Lab6, Etapa 3)

```r
set.seed(1)
cv_results <- tune(svm, taxitime ~ <fórmula comum>, data=data_train,
                   ranges=list(cost=c(0.1,1,10,100), kernel=c('linear','radial')))
summary(cv_results)
best_svm_model <- cv_results$best.model
yhat_svm <- predict(best_svm_model, data_test)
```

Com *y* numérico, o `svm` faz regressão e o `tune` escolhe pelo erro quadrático médio na validação
cruzada de 10 *folds*, o padrão da função e o mesmo dos Labs. O `svm` já normaliza as variáveis.
**Tempo:** 8 combinações × 10 *folds* em ~4.800 voos. Cronometrar uma combinação antes de rodar a
grade inteira.

### ETAPA 6 — M5: rede neural (Lab5, Etapa 2)

```r
media_y <- mean(data_train$taxitime); dp_y <- sd(data_train$taxitime)
data_nn <- data.frame(X_train_s, y=(data_train$taxitime - media_y)/dp_y)
f <- as.formula(paste('y ~', paste(colnames(X_train_s), collapse=' + ')))
nn_model <- neuralnet(f, data=data_nn, hidden=c(3), act.fct="logistic",
                      linear.output=TRUE, stepmax=1e6)
plot(nn_model)
yhat_nn <- predict(nn_model, data.frame(X_test_s))*dp_y + media_y
```

Muda uma coisa em relação ao Lab5: `linear.output=TRUE`, porque a saída é contínua (*"output
layer with one neuron"*, slide da Aula 5). A resposta é normalizada para a rede convergir e
desnormalizada na previsão.

A observação do próprio Lab5 vira tarefa: *"Deve-se sempre fazer um processo de validação cruzada
para definir o desenho ótimo da rede."* Usamos o mesmo laço `createFolds` do kNN sobre
`hidden ∈ { c(2), c(3), c(5), c(5,3) }`.

**Risco:** o `neuralnet` é lento e às vezes não converge com ~40 entradas. Se uma configuração
não convergir, ela sai da grade, e isso fica registrado no relatório.

**Saída:** `save(<todos os modelos e yhat_*>, file='modelos.Rda')` e `resultados/hiperparametros.txt`
com k ótimo, tamanho da árvore, *cost*/*kernel* e *hidden*.

---

## 10. Script 04 — Avaliação e escolha (item 5 do relatório)

### ETAPA 1 — Métricas

Fórmulas do slide 36 da Aula 4, com *y* em segundos:

```
RMSE [s] = √( (1/n) Σ (ŷᵢ − yᵢ)² )
MAE  [s] = (1/n) Σ |ŷᵢ − yᵢ|
MAPE [%] = (100/n) Σ |ŷᵢ − yᵢ| / yᵢ
```

As unidades fecham: no RMSE, √(s²) = s; no MAPE, s/s é adimensional, × 100 dá %. Como o
menor `taxitime` da base é 434 s, o MAPE é estável: não existe divisão por número perto de zero.

```r
erro <- yhat_tree - data_test$taxitime
RMSE <- sqrt(mean(erro^2)); MAE <- mean(abs(erro)); MAPE <- mean(abs(erro)/data_test$taxitime)*100
```

Repetido por modelo, em linha, como a acurácia no Lab4. Resultado: `tabela_metricas.csv` com
uma linha por modelo (M0, M1, M1-log, M2, M3, M4, M5).

### ETAPA 2 — Figuras de comparação

| Figura | Para quê |
|---|---|
| Histograma de erros de cada modelo, `par(mfrow=c(2,3))`, mesma escala | **Exigido pelo enunciado** |
| `barplot` do RMSE, do MAE e do MAPE por modelo | Comparação direta |
| `boxplot` dos erros por modelo | Viés (mediana fora do zero) e cauda |
| `plot(data_test$taxitime, yhat)` com a reta y = x, para o melhor modelo | Onde ele erra: táxis longos? |
| `boxplot(erro ~ runway)` e `boxplot(erro ~ cut(nactive, …))` | Erro por situação operacional |

### ETAPA 3 — Incerteza do RMSE (*bootstrap*, Aula 1)

```r
set.seed(1)
rmse_boot <- replicate(1000, { i <- sample(1:nrow(data_test), replace=TRUE); sqrt(mean(erro[i]^2)) })
quantile(rmse_boot, c(0.025, 0.975))
```

Fazer o mesmo para a **diferença** de RMSE entre os dois melhores modelos, reamostrando os mesmos
voos para os dois. Se o intervalo cruza o zero, os dois empatam, e o critério de desempate é o da
etapa 5.

### ETAPA 4 — Experimento das anomalias

Feito por validação cruzada dentro de `data_train` (5 *folds*, hiperparâmetros fixos), para não
gastar o `data_test` em escolha de pré-processamento. Os anômalos saem só dos *folds* de treino;
a validação continua com todos os voos. O mesmo esquema testa o `n_push30`. Só se adota uma
variante se o limite inferior do IC 95 % (*bootstrap* pareado) da redução de RMSE for maior que zero.

### ETAPA 5 — Escolha do modelo final

Critério, em ordem:

1. Menor RMSE no `data_test`, que é a métrica do ranking.
2. Se o *bootstrap* mostrar empate, o de menor MAE e cauda menor no histograma.
3. Persistindo o empate, o mais simples de explicar na arguição.

A escolha e o porquê vão por escrito no relatório e no grafo de governança.

---

## 11. Script 05 — Submissão (18/11, 9:00)

### ETAPA 1 — Retreinar o modelo escolhido com os 6.426 voos

Mesmo procedimento do Script 03, com `data` no lugar de `data_train` e a mesma semente. Para kNN e
rede, a normalização é recalculada com média e desvio padrão de `data`.

### ETAPA 2 — Prever `data_final`

### ETAPA 3 — Montar o arquivo

```r
load("data_project.Rda")                       # recarrega o data_test original
data_test$taxitime <- yhat_final[match(data_test$id, data_final$id)]
save(data_test, file='data_project_test_<NOMEDOGRUPO>.Rda')
```

Mantém o objeto, as colunas e a ordem exatamente como a professora entregou: só o `taxitime` muda.

### ETAPA 4 — Conferências antes de enviar

- [ ] 1.607 linhas, `sum(is.na(data_test$taxitime)) == 0`
- [ ] Todos os valores positivos e numa faixa plausível (comparar `summary` com o do treino)
- [ ] Os `id` conferem 1 a 1 com o arquivo original
- [ ] Abrir o arquivo salvo numa sessão nova do R e repetir as três conferências
- [ ] Nome do arquivo com o nome do grupo, como pede a tarefa

---

## 12. Relatório e apresentação

### Os seis itens → de onde sai cada um

| Item do enunciado | Conteúdo | Vem do |
|---|---|---|
| 1. Problema e motivação | O que é *taxi-out*; por que prever no pushback (sequenciamento de partidas, pushback na hora certa, combustível e emissões em solo) | Revisão de literatura (citar só o que foi lido) |
| 2. Pré-processamento | Seção 8 inteira: descarte do `crwy` e por quê; cada variável construída; agrupamentos; anomalias | Script 02 |
| 3. Análise exploratória | Tabela descritiva e as figuras da seção 7 | Script 01 |
| 4. Métodos e treinamento | Os 5 métodos, a validação cruzada de cada um e os hiperparâmetros escolhidos | Script 03 |
| 5. Resultados | Tabela de métricas, histogramas de erros, *bootstrap*, modelo final e interpretação (árvore podada e coeficientes da regressão linear) | Script 04 |
| 6. Conclusões | O que determina o táxi em SBGR, qual modelo e por quê, limitações (amostra de um mês; `nactive` como única medida de congestionamento) | — |

- **Formato:** LaTeX. Não há template da professora para este relatório, então usamos
  `~/ITA/_template/Relatório`.
- **Autoria:** Henri Leonardo dos Santos Lima, Antonio Garcia e Gilberto Patri.
- **Apresentação (25/11, 9:00):** 20 min + 10 de perguntas, cerca de 12 slides, na ordem dos seis
  itens. Os dois slides que mais rendem pergunta são o do `crwy` (por que ficou de fora) e o da
  escolha do modelo.

---

## 13. Cronograma

| Quando | O quê | Pronto quando |
|---|---|---|
| **sáb 14/11** | Etapa 0 (seção 14), Scripts 01 e 02 | Figuras da exploração; `data_project_prep.Rda` salvo |
| **dom 15/11** | Script 03: M0, M1, M2 e M3 | Os quatro `yhat` gerados |
| **seg 16/11** | Script 03: M4 e M5 (os mais lentos) | Seis modelos com hiperparâmetros escolhidos |
| **ter 17/11** | Script 04 completo; escolha; Script 05; **submissão até a noite** | Arquivo enviado com folga |
| qua 18 – sex 20/11 | **Prova B2** (liberada em 18/11 às 9:00, 48 h) | — |
| sáb 21 – ter 24/11 | Apresentação; ensaio cronometrado | 12 slides; 20 min |
| qua 25/11, 9:00 | **Apresentação** | — |
| 26/11 – ter 01/12 | Relatório em LaTeX | PDF revisado |
| qua 02/12, 9:00 | **Entrega do relatório** | — |

A janela até a submissão é curta: **quatro dias**, colados na Prova B2. Se apertar, a ordem de
corte é: M5 (rede neural), depois M4 (SVM), depois os experimentos opcionais (vento de proa,
pushbacks recentes, anomalias). M0, M1, M2 e M3 garantem uma submissão defensável com quatro
métodos.

**O modelo submetido em 18/11 é o modelo do relatório.** Depois da submissão, o trabalho é
interpretar e escrever, não trocar de modelo.

---

## 14. Etapa 0 — antes de abrir o R

- [x] **Grupo:** Henri Leonardo, Antonio Garcia e Gilberto Patri; `nome_grupo <- 'HenriAntonioGilberto'` no Script 05 (trocar se o grupo quiser outro). `pendencia:P01` fechada.
- [x] **`crwy`:** reconferido no teste (KS, correlação, medianas por cabeceira). O grupo decidiu **não** escrever à professora; o `crwy` fica fora do modelo. `pendencia:P05` fechada.
- [x] **Média × mediana:** média (seção 5).
- [ ] **Instalar os pacotes uma vez, no console:**
      `install.packages(c('tree','caret','e1071','neuralnet','corrplot','pheatmap','cluster','mclust'))`
- [x] **Repositório:** aposentar a estrutura de 06/10 (`app/` com `targets`) e registrar no grafo
      uma decisão que substitui a `D02`: código no padrão dos Labs, só com pacotes de aula. Tarefas
      T03, T04, T06, T31 e T32 viram as tarefas dos Scripts 01 a 05.

---

## 15. Decisões em aberto e riscos

| # | Questão | Proposta | Quem decide |
|---|---|---|---|
| 1 | Média ou mediana entre *folds* | **Decidido:** média do MSE | Grupo, 14/11 |
| 2 | Incluir SVM de regressão, que não está nos slides de regressão | **Decidido:** incluir, declarado como extensão | Grupo, 14/11 |
| 3 | Remover voos anômalos do treino | Só se a CV em `data_train` mostrar ganho (IC pareado > 0) | Script 04 |
| 4 | Componente de vento de proa | Só com o rumo verdadeiro da AIP Brasil | Quem buscar a fonte |
| 5 | Pushbacks recentes como variável | Só se a CV em `data_train` mostrar ganho (IC pareado > 0) | Script 04 |
| 6 | `neuralnet` lento ou sem convergir | Grade pequena; o que não convergir sai e é registrado | — |
| 7 | Professora corrigir a base de teste por causa do `crwy` | Reexecutar só o Script 05 com a base nova | — |
