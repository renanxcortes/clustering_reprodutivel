# Testes dos dados de exemplo e das figuras. Rodar a partir da raiz do projeto:
#   Rscript -e 'testthat::test_file("tests/test_figuras.R")'
library(testthat)

raiz <- normalizePath(if (file.exists("aula_clustering.qmd")) "." else "..")
source(file.path(raiz, "tools", "exemplo.R"))

test_that("exemplo de 6 clientes tem as propriedades das figuras", {
  ex <- exemplo_clientes()
  expect_equal(ex$nome, c("Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio"))
  d <- as.matrix(dist(exemplo_matriz()))
  expect_equal(d["Ana", "Diego"], 5)
  hc <- lapply(c(single = "single", complete = "complete", average = "average", ward = "ward.D2"),
               function(m) hclust(dist(exemplo_matriz()), method = m))
  g <- sapply(hc, cutree, k = 2)
  expect_equal(unname(g["Diego", "single"]), unname(g["Ana", "single"]))     # single: Diego com Ana
  for (m in c("complete", "average", "ward"))
    expect_equal(unname(g["Diego", m]), unname(g["Elisa", m]))              # demais: Diego com Elisa
  expect_equal(round(sapply(hc, function(h) max(h$height)), 2),
               c(single = 3.61, complete = 8.60, average = 6.47, ward = 11.09))
})

test_that("dados do GIF", {
  g <- exemplo_gif()
  expect_true(is.matrix(g$x) && ncol(g$x) == 2 && nrow(g$x) >= 30 && nrow(g$x) <= 60)
  expect_equal(dim(g$centros_iniciais), c(3L, 2L))
  expect_identical(exemplo_gif(), exemplo_gif())                            # semente fixa
})
