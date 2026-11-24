# Testes do material da aula. Rodar a partir da raiz do projeto:
#   Rscript -e 'testthat::test_file("tests/test_aula.R")'
library(testthat)

raiz <- normalizePath(if (file.exists("aula_clustering.qmd")) "." else "..")

# Roda o script gerado num ambiente limpo e devolve esse ambiente
rodar_script <- function(arquivo = "aula_clustering.R") {
  env <- new.env()
  withr::with_dir(raiz, {
    set.seed(NULL)
    sys.source(arquivo, envir = env)
  })
  env
}

env <- rodar_script()

test_that("dados carregados", {
  expect_equal(dim(env$clientes_raw), c(2240L, 29L))
  expect_equal(sum(is.na(env$clientes_raw$Income)), 24L)
  expect_equal(unname(tools::md5sum(file.path(raiz, "marketing_campaign.csv"))),
               "3b624fc2bdbe29fa5fb01bdd577f78cd")
})

test_that("erro claro fora do projeto", {
  script <- file.path(raiz, "aula_clustering.R")
  withr::with_dir(tempdir(), {
    expect_error(sys.source(script, envir = new.env()), "clustering.Rproj")
    expect_error(sys.source(script, envir = new.env()), "Set Working Directory")
  })
})

test_that("script sincronizado com o qmd", {
  tmp <- tempfile(fileext = ".R")
  withr::with_dir(raiz, knitr::purl("aula_clustering.qmd", tmp, documentation = 0, quiet = TRUE))
  expect_identical(readLines(tmp), readLines(file.path(raiz, "aula_clustering.R")))
})

test_that("descritiva gera gráficos no HTML", {
  html <- readLines(file.path(raiz, "aula_clustering.html"), warn = FALSE)
  expect_gte(sum(lengths(regmatches(html, gregexpr("<img", html)))), 5)
})

test_that("figuras citadas no qmd existem", {
  qmd <- paste(readLines(file.path(raiz, "aula_clustering.qmd"), encoding = "UTF-8"), collapse = "\n")
  figs <- unique(regmatches(qmd, gregexpr("figuras/[A-Za-z0-9_]+[.](png|gif)", qmd))[[1]])
  expect_true("figuras/kmeans_iteracoes.gif" %in% figs)
  expect_gte(length(figs), 5)
  for (f in figs) expect_true(file.exists(file.path(raiz, f)), info = f)
})

test_that("limpeza e preparação", {
  expect_equal(nrow(env$clientes), 2212L)   # 2240 - 24 NA - 1 renda alta - 3 nascidos < 1920 (conferido no R em 2026-11-17)
  expect_false(anyNA(env$clientes[env$vars_cluster]))
  expect_lte(max(env$clientes$Income), 2e5)
  expect_true(all(env$clientes$Idade < 100))
  expect_setequal(unique(env$clientes$Marital_Status), c("Casado/Junto", "Sozinho"))
  expect_false(any(c("Z_CostContact", "Z_Revenue") %in% names(env$clientes)))
  expect_false(any(grepl("^Accepted|^Response$|^Complain$", env$vars_cluster)))
  expect_equal(unname(round(colMeans(env$dados_pad), 8)), rep(0, length(env$vars_cluster)))
  expect_equal(unname(apply(env$dados_pad, 2, sd)), rep(1, length(env$vars_cluster)))
})

test_that("hierárquico e k-means", {
  n <- nrow(env$clientes)
  expect_equal(env$hc_ward$method, "ward.D2")
  expect_equal(env$avaliacao_k$k, 2:8)
  expect_true(env$k_escolhido %in% 2:8)
  expect_length(env$grupos_hc, n); expect_length(env$grupos_km, n)
  expect_setequal(unique(env$grupos_hc), seq_len(env$k_escolhido))
  expect_setequal(unique(env$grupos_km), seq_len(env$k_escolhido))
  expect_gte(env$km$iter, 1); expect_equal(length(env$km$size), env$k_escolhido)
})


test_that("exemplo do qmd é o mesmo das figuras", {
  source(file.path(raiz, "tools", "exemplo.R"), local = TRUE)
  expect_equal(as.data.frame(env$exemplo), as.data.frame(exemplo_clientes()))
  expect_setequal(names(env$hc_exemplo), c("single", "complete", "average", "ward"))
})

test_that("single, complete e average falham na base real", {
  n <- nrow(env$clientes)
  for (h in list(env$hc_single, env$hc_complete, env$hc_average))
    expect_gt(max(table(cutree(h, k = 3))) / n, 0.9)
  expect_equal(c(env$hc_single$method, env$hc_complete$method, env$hc_average$method),
               c("single", "complete", "average"))
})

test_that("PAM", {
  expect_s3_class(env$pam_euc, "pam")
  expect_length(env$grupos_pam, nrow(env$clientes))
  expect_setequal(unique(env$grupos_pam), seq_len(env$k_escolhido))
  expect_equal(nrow(env$medoides), env$k_escolhido)
  expect_true(all(env$medoides$ID %in% env$clientes$ID))     # medoide é cliente real
})

test_that("bônus de Gower", {
  expect_s3_class(env$dist_gower, "dissimilarity")
  expect_equal(attr(env$dist_gower, "Metric"), "mixed")
  expect_equal(env$hc_gower$method, "average")
  expect_s3_class(env$pam_gower, "pam")
  expect_equal(nrow(env$tab_gower_vs_euc), env$k_escolhido)
})

test_that("aula funciona pulando o bônus", {
  linhas <- readLines(file.path(raiz, "aula_clustering.R"), encoding = "UTF-8")
  ini <- grep("^# 6b\\. ", linhas); fim <- grep("^# ---- fim do bônus 6b ----$", linhas)
  expect_length(ini, 1); expect_length(fim, 1)
  sem_bonus <- tempfile(fileext = ".R"); writeLines(linhas[-(ini:fim)], sem_bonus, useBytes = TRUE)
  env_sb <- rodar_script(sem_bonus)
  expect_false(exists("dist_gower", envir = env_sb, inherits = FALSE))
  expect_true(exists("fichas", envir = env_sb, inherits = FALSE))
})

test_that("comparação e resultados", {
  expect_setequal(env$comparacao_tecnicas$tecnica, c("hierarquico", "kmeans", "pam"))
  expect_true(env$tecnica_final %in% env$comparacao_tecnicas$tecnica)
  expect_equal(nrow(env$perfil_segmentos), env$k_escolhido)
  expect_equal(nrow(env$fichas), env$k_escolhido)
  expect_setequal(as.character(env$fichas$segmento), levels(env$clientes_seg$segmento))
  expect_true(all(env$resposta_por_segmento$taxa_resposta >= 0 & env$resposta_por_segmento$taxa_resposta <= 1))
})

test_that("nomes dos segmentos seguem o perfil, não o número do cluster", {
  p <- env$perfil_segmentos[order(env$perfil_segmentos$Gasto_total_medio), ]
  expect_equal(as.character(p$segmento), levels(env$clientes_seg$segmento))   # níveis ordenados por gasto
})

test_that("descrições das fichas batem com o perfil", {
  # As frases fixas das fichas (e o nome "Caçador de ofertas") dependem destes fatos;
  # só checamos diferenças claras (sem quase-empates)
  p <- env$perfil_segmentos
  maior <- function(col) as.character(p$segmento[which.max(p[[col]])])
  menor <- function(col) as.character(p$segmento[which.min(p[[col]])])
  expect_equal(maior("NumDealsPurchases_medio"), "Caçador de ofertas")    # 3,8 × 1,8 × 1,6
  expect_equal(maior("Teenhome_medio"), "Caçador de ofertas")             # adolescentes
  expect_equal(maior("Kidhome_medio"), "Econômico")                       # crianças pequenas
  expect_equal(menor("NumWebPurchases_medio"), "Econômico")               # compra pouco pelo site
  expect_equal(maior("Sem_filhos_prop"), "Premium")                       # maioria sem filhos
  expect_gt(p$Sem_filhos_prop[p$segmento == "Premium"], 0.5)
  expect_equal(maior("MntWines_medio"), "Premium")                        # vinhos...
  expect_equal(maior("MntMeatProducts_medio"), "Premium")                 # ...e carnes
  expect_equal(maior("NumCatalogPurchases_medio"), "Premium")             # catálogo
  expect_equal(maior("NumStorePurchases_medio"), "Premium")               # loja
})

test_that("reprodutível", {
  env2 <- rodar_script()
  expect_identical(env$grupos_km, env2$grupos_km)
  expect_identical(env$grupos_pam, env2$grupos_pam)
  expect_equal(env$comparacao_tecnicas, env2$comparacao_tecnicas)
})

test_that("script roda rápido", expect_lt(system.time(rodar_script())[["elapsed"]], 120))

test_that("script tem as seções navegáveis", {
  linhas <- readLines(file.path(raiz, "aula_clustering.R"), encoding = "UTF-8")
  expect_equal(sum(grepl("^# ([1-8]|6b)[.] .+ ----$", linhas)), 9L)
})

test_that("README existe e cita a fonte dos dados", {
  rd <- paste(readLines(file.path(raiz, "README.md"), encoding = "UTF-8"), collapse = "\n")
  expect_match(rd, "LiaoliaoQJ/mkt"); expect_match(rd, "imakash3011")
})
