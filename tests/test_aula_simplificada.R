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

test_that("simplificada: sem k-means nem PAM", {
  for (o in c("km", "avaliacao_k", "pam_euc", "grupos_pam", "medoides", "tecnica_final", "comparacao_tecnicas"))
    expect_false(exists(o, envir = env_s, inherits = FALSE), info = o)
  expect_identical(env_s$grupos_final, env_s$grupos_hc)
  expect_equal(env_s$hc_ward$method, "ward.D2")
})

test_that("simplificada: texto sem conceitos cortados nem números do PAM", {
  qmd <- readLines(file.path(raiz, "aula_clustering_simplificada.qmd"), encoding = "UTF-8")
  qmd <- qmd[!grepl("outras técnicas", qmd)]
  txt <- paste(qmd, collapse = "\n")
  for (p in c("[Ss]ilhueta", "k-means", "[^A-Za-z]PAM[^A-Za-z]", "[Mm]edoide", "[^A-Za-z]WSS[^A-Za-z]", "[Cc]otovelo", "nstart", "set[.]seed",
              "seção 7", "seção 8", "8,5%", "23,6%", "822 clientes", "664 clientes", "726 clientes"))
    expect_false(grepl(p, txt, perl = TRUE), info = p)
})

test_that("simplificada: nomes e fichas seguem o perfil do Ward", {
  p <- env_s$perfil_segmentos
  expect_equal(as.character(p$segmento[order(p$Gasto_total_medio)]), levels(env_s$clientes_seg$segmento))
  maior <- function(col) as.character(p$segmento[which.max(p[[col]])])
  expect_equal(maior("NumDealsPurchases_medio"), "Caçador de ofertas")
  expect_equal(maior("Teenhome_medio"), "Caçador de ofertas")
  expect_equal(maior("Kidhome_medio"), "Econômico")
  expect_equal(as.character(p$segmento[which.min(p$NumWebPurchases_medio)]), "Econômico")
  for (col in c("Sem_filhos_prop", "MntWines_medio", "MntMeatProducts_medio",
                "NumCatalogPurchases_medio", "NumStorePurchases_medio"))
    expect_equal(maior(col), "Premium", info = col)
  expect_equal(nrow(env_s$fichas), 3L)
})

test_that("simplificada: cliente-exemplo é cliente real do próprio segmento", {
  ex <- env_s$clientes_exemplo
  expect_equal(nrow(ex), 3L)
  expect_true(all(ex$ID %in% env_s$clientes$ID))
  seg_do_id <- as.character(env_s$clientes_seg$segmento[match(ex$ID, env_s$clientes_seg$ID)])
  expect_equal(seg_do_id, as.character(ex$segmento))
})

test_that("simplificada: reprodutível e rápida", {
  expect_lt(system.time(e2 <- rodar_simplificada())[["elapsed"]], 120)
  expect_identical(env_s$grupos_final, e2$grupos_final)
})

test_that("simplificada: seções navegáveis", {
  l <- readLines(file.path(raiz, "aula_clustering_simplificada.R"), encoding = "UTF-8")
  expect_equal(sum(grepl("^# [1-6][.] .+ ----$", l)), 6L)
})

test_that("simplificada: Gower", {
  n <- nrow(env_s$clientes)
  expect_equal(attr(env_s$dist_gower, "Metric"), "mixed")
  expect_equal(env_s$hc_gower_average$method, "average")
  expect_equal(env_s$hc_gower_complete$method, "complete")
  expect_gt(max(table(cutree(env_s$hc_gower_average, k = 3))) / n, 0.9)
  expect_gt(min(table(env_s$grupos_gower)) / n, 0.2)
  # a complete com Gower reencontra a divisão por gasto do Ward
  seg <- as.character(env_s$clientes_seg$segmento)
  dom <- function(s) {
    t <- table(env_s$grupos_gower[seg == s])
    list(grupo = names(which.max(t)), prop = max(t) / sum(t))
  }
  pr <- dom("Premium"); ec <- dom("Econômico")
  expect_gt(pr$prop, 0.7); expect_gt(ec$prop, 0.7)
  expect_false(pr$grupo == ec$grupo)
  # com k = 4 surge um grupo só de "Sozinho"
  g4 <- cutree(env_s$hc_gower_complete, k = 4)
  expect_true(any(tapply(env_s$clientes$Marital_Status == "Sozinho", g4, all)))
})

test_that("simplificada: figuras citadas existem", {
  txt <- paste(readLines(file.path(raiz, "aula_clustering_simplificada.qmd"), encoding = "UTF-8"), collapse = "\n")
  figs <- unique(regmatches(txt, gregexpr("figuras/[A-Za-z0-9_]+[.](png|gif)", txt))[[1]])
  expect_gte(length(figs), 4)
  expect_false("figuras/kmeans_iteracoes.gif" %in% figs)
  for (f in figs) expect_true(file.exists(file.path(raiz, f)), info = f)
})
