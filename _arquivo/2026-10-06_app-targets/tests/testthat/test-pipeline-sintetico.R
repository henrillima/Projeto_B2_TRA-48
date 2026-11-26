# O pipeline recupera o que a base sintética plantou?
#
# É esta a pergunta que dá sentido a decisao:D03: desenvolver antes de 28/10 só
# vale se houver como verificar o que foi desenvolvido. A base sintética tem
# relação conhecida, então o teste pode ser assertivo, e não apenas "rodou".
#
#   Rscript -e 'testthat::test_dir("app/tests/testthat")'

VERD <- coeficientes_sinteticos()

P_TESTE <- list(
  taxi_min_s = 60, taxi_max_s = 3600, frac_max_faltante = 0.30,
  frac_treino = 0.70, frac_validacao = 0.15
)

test_that("a base sintética sai com o tamanho e as colunas esperadas", {
  b <- gerar_base_sintetica(n = 1000, semente = 1)
  expect_equal(nrow(b), 1000)
  expect_true(all(c("taxi_s", "n_em_taxi", "pista", "pico", "instante") %in% names(b)))
  expect_true(any(is.na(b$taxi_s)))        # a sujeira deliberada está lá
  expect_true(any(b$taxi_s > 3600, na.rm = TRUE))
})

test_that("a base sintética é determinística dada a semente", {
  expect_identical(gerar_base_sintetica(500, 7), gerar_base_sintetica(500, 7))
  expect_false(identical(gerar_base_sintetica(500, 7), gerar_base_sintetica(500, 8)))
})

test_that("a limpeza remove exatamente os NA e os fora de faixa, e presta contas", {
  b <- gerar_base_sintetica(n = 2000, semente = 2)
  l <- limpar(b, P_TESTE)
  d <- attr(l, "descarte")

  expect_false(any(is.na(l$taxi_s)))
  expect_true(all(l$taxi_s >= P_TESTE$taxi_min_s & l$taxi_s <= P_TESTE$taxi_max_s))
  expect_equal(d$linhas_entrada, 2000)
  expect_equal(d$linhas_saida, nrow(l))
  expect_equal(d$linhas_entrada - d$sem_resposta - d$fora_da_faixa, d$linhas_saida)
})

test_that("o split é temporal: nenhum instante do treino é posterior à validação", {
  b <- construir_features(limpar(gerar_base_sintetica(2000, 3), P_TESTE))
  pt <- dividir_temporal(b, P_TESTE)

  expect_lt(max(pt$treino$instante), min(pt$validacao$instante))
  expect_lt(max(pt$validacao$instante), min(pt$teste$instante))
  expect_equal(nrow(pt$treino) + nrow(pt$validacao) + nrow(pt$teste), nrow(b))
})

test_that("o baseline recupera os coeficientes plantados", {
  b <- construir_features(limpar(gerar_base_sintetica(8000, 4), P_TESTE))
  pt <- dividir_temporal(b, P_TESTE)
  m <- ajustar_baseline(pt$treino)
  co <- stats::coef(m)

  # tolerâncias generosas de propósito: o teste existe para pegar erro de
  # pipeline (feature trocada, sinal invertido, split vazando), não para medir
  # precisão de estimador.
  expect_equal(unname(co[["n_em_taxi"]]), VERD$n_em_taxi, tolerance = 0.15)
  expect_equal(unname(co[["pistapista_longe"]]), VERD$pista_longe, tolerance = 0.20)
  expect_gt(unname(co[["pico"]]), 0)
})

test_that("o erro do baseline fica na ordem do ruído plantado", {
  b <- construir_features(limpar(gerar_base_sintetica(8000, 5), P_TESTE))
  pt <- dividir_temporal(b, P_TESTE)
  m <- ajustar_baseline(pt$treino)
  met <- avaliar(pt$validacao$taxi_s, prever(m, pt$validacao))

  # o ruído é normal com sd = 70, então nenhum modelo honesto vai muito abaixo
  # disso, e um RMSE muito acima indica feature perdida.
  expect_gt(met$rmse, 0.7 * VERD$sd_ruido)
  expect_lt(met$rmse, 1.6 * VERD$sd_ruido)
  expect_lt(met$mae, met$rmse)             # desigualdade válida sempre
  expect_equal(met$n, nrow(pt$validacao))
})

test_that("avaliar recusa métrica que não existe em vez de devolver NA", {
  expect_error(avaliar(1:10, 1:10, quais = c("rmse", "r2")), "não implementada")
})

test_that("o histograma de erros tem viés próximo de zero no baseline", {
  b <- construir_features(limpar(gerar_base_sintetica(8000, 6), P_TESTE))
  pt <- dividir_temporal(b, P_TESTE)
  m <- ajustar_baseline(pt$treino)
  h <- histograma_erros(pt$validacao$taxi_s, prever(m, pt$validacao), bins = 40)

  expect_equal(sum(h$contagem), length(h$erro))
  expect_lt(abs(h$vies), 0.3 * VERD$sd_ruido)
})
