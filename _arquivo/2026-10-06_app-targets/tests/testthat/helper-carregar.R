# testthat carrega automaticamente todo helper-*.R antes dos testes.
#
# Carregamos as funções de app/R/ aqui porque este projeto não é um pacote R:
# sem isto, cada arquivo de teste teria de dar source() nos seus próprios
# arquivos, e um esquecimento viria como "object not found" em vez de falha
# legível.
#
# O caminho é relativo ao diretório dos testes, que é o que testthat::test_dir
# e targets usam. Nada de caminho absoluto (convenção do CLAUDE.md §8).

local({
  raiz_r <- normalizePath(file.path("..", "..", "R"), mustWork = FALSE)
  if (!dir.exists(raiz_r)) raiz_r <- normalizePath(file.path("app", "R"), mustWork = TRUE)
  invisible(lapply(
    list.files(raiz_r, pattern = "[.]R$", full.names = TRUE),
    source
  ))
})
