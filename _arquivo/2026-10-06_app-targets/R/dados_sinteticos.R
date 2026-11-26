# @produz base sintética de voos de partida, para desenvolver o pipeline antes
#         de 28/10 (decisao:D03)
# @consome nada
#
# A relação entre features e resposta é CONHECIDA e está escrita abaixo. É isso
# que permite que o teste afirme algo: um pipeline que não recupera o que foi
# plantado está errado, e dá para saber disso sem a base real.

#' Gera uma base sintética de tempos de táxi na partida.
#'
#' Estrutura plantada, em segundos:
#'
#'   taxi = 240
#'        + 18 * n_em_taxi        congestionamento no pátio: o termo dominante,
#'                                como aponta a literatura de taxi-out
#'        + 150 * (pista == "pista_longe")
#'        + 60  * pico            hora de pico
#'        + ruido                 normal, sd = 70
#'
#' Nenhum desses números é afirmação sobre a realidade: são a verdade de
#' laboratório que o teste verifica. Quando a base real chegar, a função sai do
#' pipeline e fica só nos testes.
#'
#' @param n número de voos
#' @param semente semente do gerador
#' @return data.frame com uma linha por voo
gerar_base_sintetica <- function(n = 4000, semente = 20262) {
  stopifnot(is.numeric(n), n > 0)
  set.seed(semente)

  # ordem temporal explícita: o split de T15 depende dela existir
  instante <- sort(stats::runif(n, 0, 90 * 24 * 3600))
  hora <- (instante / 3600) %% 24
  pico <- as.integer(hora >= 7 & hora <= 10 | hora >= 17 & hora <= 20)

  n_em_taxi <- stats::rpois(n, lambda = 3 + 5 * pico)
  pista <- sample(c("pista_perto", "pista_longe"), n, replace = TRUE, prob = c(0.65, 0.35))
  companhia <- sample(c("AAA", "BBB", "CCC"), n, replace = TRUE)

  taxi_s <- 240 +
    18 * n_em_taxi +
    150 * (pista == "pista_longe") +
    60 * pico +
    stats::rnorm(n, 0, 70)

  base <- data.frame(
    id_voo    = sprintf("V%05d", seq_len(n)),
    instante  = instante,
    hora      = hora,
    pico      = pico,
    n_em_taxi = n_em_taxi,
    pista     = pista,
    companhia = companhia,
    taxi_s    = taxi_s,
    stringsAsFactors = FALSE
  )

  # sujeira deliberada, para que a limpeza de T13 tenha o que limpar e os
  # testes possam verificar que ela limpa a quantidade certa
  base$taxi_s[sample(n, max(1, round(0.004 * n)))] <- NA_real_
  base$taxi_s[sample(n, max(1, round(0.003 * n)))] <- 7200  # acima do limiar

  base
}

#' Coeficientes verdadeiros da base sintética.
#'
#' Existe para que o teste não repita os números à mão — duplicar a verdade em
#' dois lugares garante que um dia eles divirjam.
coeficientes_sinteticos <- function() {
  list(
    intercepto = 240,
    n_em_taxi  = 18,
    pista_longe = 150,
    pico       = 60,
    sd_ruido   = 70
  )
}
