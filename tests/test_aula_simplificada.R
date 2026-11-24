# Testes da versão simplificada da aula. Rodar a partir da raiz do projeto:
#   Rscript -e 'testthat::test_file("tests/test_aula_simplificada.R")'
library(testthat)

raiz <- normalizePath(if (file.exists("aula_clustering_simplificada.qmd") ||
                          file.exists("aula_clustering.qmd")) "." else "..")

# Roda o script simplificado num ambiente limpo e devolve esse ambiente
rodar_simplificada <- function(arquivo = "aula_clustering_simplificada.R") {
  env <- new.env()
  withr::with_dir(raiz, {
    set.seed(NULL)
    sys.source(arquivo, envir = env)
  })
  env
}

env_s <- rodar_simplificada()

test_that("simplificada: dados carregados", {
  expect_equal(dim(env_s$clientes_raw), c(2240L, 29L))
  expect_equal(nrow(env_s$clientes), 2212L)
})

test_that("simplificada: erro claro fora do projeto", {
  s <- file.path(raiz, "aula_clustering_simplificada.R")
  withr::with_dir(tempdir(), expect_error(sys.source(s, envir = new.env()), "clustering.Rproj"))
})

test_that("simplificada: script sincronizado com o qmd", {
  tmp <- tempfile(fileext = ".R")
  withr::with_dir(raiz, knitr::purl("aula_clustering_simplificada.qmd", tmp, documentation = 0, quiet = TRUE))
  expect_identical(readLines(tmp), readLines(file.path(raiz, "aula_clustering_simplificada.R")))
})

test_that("simplificada: título próprio", {
  qmd <- readLines(file.path(raiz, "aula_clustering_simplificada.qmd"), encoding = "UTF-8")
  expect_true(any(grepl("versão simplificada", qmd)))
})
