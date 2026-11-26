# Pipeline do Projeto B2 — predição do tempo de táxi na partida.
#
#   Rscript -e 'targets::tar_make()'
#   Rscript -e 'targets::tar_visnetwork()'
#
# Enquanto pendencia:P02 estiver aberta (esquema da base desconhecido até 28/10),
# a fonte é a base SINTÉTICA de decisao:D03. Trocar a fonte é trocar um alvo.
#
# Nenhum número mágico abaixo desta linha: tudo o que é escolha vive em P.

library(targets)

tar_option_set(
  packages = c("stats", "utils"),
  format   = "rds",
  seed     = 20262   # regra 9 do CLAUDE.md: seed fixa, declarada aqui
)

lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source)

# ---------------------------------------------------------------- parâmetros
# Alterar aqui, nunca no meio de uma função.
P <- list(
  # base sintética (decisao:D03) — some quando a base real chegar
  n_voos_sinteticos   = 4000,
  semente_sintetica   = 20262,

  # split temporal (tarefa:T15). Aleatório vazaria futuro para o treino.
  frac_treino         = 0.70,
  frac_validacao      = 0.15,   # o resto é teste interno

  # limpeza (tarefa:T13) — limiares, não constantes enterradas
  taxi_min_s          = 60,     # abaixo disso, registro suspeito
  taxi_max_s          = 3600,   # acima disso, provável evento não-operacional
  frac_max_faltante   = 0.30,   # coluna com mais que isso sai, com nota

  # avaliação (tarefa:T34)
  metricas            = c("rmse", "mae", "mape"),
  bins_histograma     = 40,

  # grade de hiperparâmetros (tarefa:T33) — preenchida em T31/T32
  grade               = list()
)

# -------------------------------------------------------------------- alvos
list(
  tar_target(parametros, P),

  # ---- dados -------------------------------------------------------------
  # TROCAR AQUI quando a base real for liberada (28/10, tarefa:T11):
  # tar_target(bruto, ler_base("data/raw/<arquivo>"), format = "file")
  tar_target(bruto, gerar_base_sintetica(
    n = parametros$n_voos_sinteticos,
    semente = parametros$semente_sintetica
  )),

  tar_target(limpo, limpar(bruto, parametros)),
  tar_target(com_features, construir_features(limpo)),
  tar_target(particoes, dividir_temporal(com_features, parametros)),

  # ---- modelos -----------------------------------------------------------
  tar_target(baseline, ajustar_baseline(particoes$treino)),
  tar_target(pred_baseline, prever(baseline, particoes$validacao)),

  # tarefa:T31 e T32 entram aqui, com ranger e xgboost, depois de renv (T04).

  # ---- avaliação ---------------------------------------------------------
  tar_target(metricas_baseline, avaliar(
    observado = particoes$validacao$taxi_s,
    previsto  = pred_baseline,
    quais     = parametros$metricas
  )),

  tar_target(hist_erros_baseline, histograma_erros(
    observado = particoes$validacao$taxi_s,
    previsto  = pred_baseline,
    bins      = parametros$bins_histograma
  ))
)
