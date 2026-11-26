# @produz modelos ajustados e previsões
# @consome as partições
#
# Por ora só o BASELINE. Floresta aleatória (tarefa:T31) e gradient boosting
# (tarefa:T32) entram depois que renv estiver fixado (tarefa:T04) — colocar
# `library(ranger)` aqui antes disso produziria um pipeline que não roda do zero,
# que é a forma mais barata de mentir sobre reprodutibilidade.

#' Ajusta o baseline: regressão linear nas features óbvias.
#'
#' Serve de régua. Sem régua não se sabe se o modelo bom é bom — e um baseline
#' linear em dado operacional costuma ser mais difícil de bater do que se espera.
ajustar_baseline <- function(treino) {
  stopifnot(is.data.frame(treino), nrow(treino) > 10)
  stats::lm(taxi_s ~ n_em_taxi + pista + pico + hora_sin + hora_cos, data = treino)
}

#' Previsão de qualquer modelo que implemente predict().
prever <- function(modelo, novos) {
  as.numeric(stats::predict(modelo, newdata = novos))
}
