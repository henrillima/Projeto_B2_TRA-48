# @produz base limpa, base com features, partições de treino/validação/teste
# @consome a base bruta
#
# Toda regra de descarte devolve, junto com o dado, QUANTAS linhas descartou.
# Descarte não contabilizado é viés não declarado — e o item 2 do relatório
# cobra exatamente esta prestação de contas.

#' Limpa a base aplicando os limiares de P.
#'
#' @param bruto data.frame da base bruta
#' @param p lista de parâmetros (ver _targets.R)
#' @return data.frame limpo, com o relatório de descarte no atributo "descarte"
limpar <- function(bruto, p) {
  stopifnot(is.data.frame(bruto), "taxi_s" %in% names(bruto))
  n0 <- nrow(bruto)

  sem_resposta <- is.na(bruto$taxi_s)
  fora_faixa <- !sem_resposta &
    (bruto$taxi_s < p$taxi_min_s | bruto$taxi_s > p$taxi_max_s)

  limpo <- bruto[!sem_resposta & !fora_faixa, , drop = FALSE]

  # colunas com faltante acima do limiar saem — mas nomeadas, não em silêncio
  frac_na <- vapply(limpo, function(col) mean(is.na(col)), numeric(1))
  demais <- names(frac_na)[frac_na > p$frac_max_faltante]
  if (length(demais)) limpo <- limpo[, setdiff(names(limpo), demais), drop = FALSE]

  attr(limpo, "descarte") <- list(
    linhas_entrada        = n0,
    sem_resposta          = sum(sem_resposta),
    fora_da_faixa         = sum(fora_faixa),
    colunas_removidas     = demais,
    linhas_saida          = nrow(limpo)
  )
  limpo
}

#' Constrói as features candidatas.
#'
#' Enquanto pendencia:P02 estiver aberta, isto opera sobre as colunas da base
#' sintética. Quando a base real chegar (tarefa:T14), as hipóteses listadas no
#' grafo são testadas contra as colunas que de fato existirem.
construir_features <- function(limpo) {
  d <- limpo
  d$hora_sin <- sin(2 * pi * d$hora / 24)   # hora é circular: 23h está perto de 0h
  d$hora_cos <- cos(2 * pi * d$hora / 24)
  d$pista <- factor(d$pista)
  d$companhia <- factor(d$companhia)
  d
}

#' Divide em treino, validação e teste interno respeitando a ordem temporal.
#'
#' Amostragem aleatória em série temporal vaza informação do futuro para o
#' treino e produz métrica otimista. Por isso o corte é por posição na ordem de
#' `instante`, não por sorteio.
dividir_temporal <- function(d, p) {
  stopifnot("instante" %in% names(d))
  d <- d[order(d$instante), , drop = FALSE]
  n <- nrow(d)
  i1 <- floor(p$frac_treino * n)
  i2 <- floor((p$frac_treino + p$frac_validacao) * n)
  stopifnot(i1 > 0, i2 > i1, i2 < n)

  list(
    treino    = d[seq_len(i1), , drop = FALSE],
    validacao = d[(i1 + 1):i2, , drop = FALSE],
    teste     = d[(i2 + 1):n, , drop = FALSE]
  )
}
