# @produz métricas de erro e o histograma de erros
# @consome observado e previsto
#
# RMSE, MAE e MAPE são exigidos nominalmente pelo item 5 do enunciado, assim
# como o histograma de erros. Implementados aqui em base R, em um lugar só, para
# que a tabela do relatório e a figura do relatório não possam divergir.

#' Raiz do erro quadrático médio.
rmse <- function(observado, previsto) {
  sqrt(mean((observado - previsto)^2))
}

#' Erro absoluto médio.
mae <- function(observado, previsto) {
  mean(abs(observado - previsto))
}

#' Erro percentual absoluto médio, em pontos percentuais.
#'
#' MAPE explode quando o observado se aproxima de zero. Se a base real tiver
#' táxis muito curtos, este número deixa de medir o que interessa — e aí a
#' providência é dizer isso no relatório, não esconder a instabilidade. O
#' argumento `piso` existe para tornar a exclusão explícita e contável, nunca
#' silenciosa.
mape <- function(observado, previsto, piso = 0) {
  usar <- abs(observado) > piso
  valor <- mean(abs((observado[usar] - previsto[usar]) / observado[usar])) * 100
  structure(valor, excluidos = sum(!usar), n = sum(usar))
}

#' Avalia um conjunto de previsões.
#'
#' @param quais vetor com os nomes das métricas desejadas
#' @return data.frame de uma linha
avaliar <- function(observado, previsto, quais = c("rmse", "mae", "mape")) {
  stopifnot(length(observado) == length(previsto))
  completo <- !is.na(observado) & !is.na(previsto)
  o <- observado[completo]; p <- previsto[completo]

  fn <- list(rmse = rmse, mae = mae, mape = function(a, b) as.numeric(mape(a, b)))
  desconhecida <- setdiff(quais, names(fn))
  if (length(desconhecida)) {
    stop("métrica não implementada: ", paste(desconhecida, collapse = ", "), call. = FALSE)
  }

  out <- as.data.frame(lapply(quais, function(m) fn[[m]](o, p)))
  names(out) <- quais
  out$n <- length(o)
  out$descartados_na <- sum(!completo)
  out
}

#' Dados do histograma de erros (previsto menos observado).
#'
#' Devolve os dados, não o gráfico: assim a mesma contagem serve à figura e à
#' frase do relatório que descreve a figura.
histograma_erros <- function(observado, previsto, bins = 40) {
  erro <- previsto - observado
  erro <- erro[is.finite(erro)]
  h <- graphics::hist(erro, breaks = bins, plot = FALSE)
  list(
    erro      = erro,
    centros   = h$mids,
    contagem  = h$counts,
    resumo    = stats::quantile(erro, c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99)),
    vies      = mean(erro)
  )
}
