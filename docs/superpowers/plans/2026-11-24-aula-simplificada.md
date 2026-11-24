# Aula simplificada (só hierárquico) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar `aula_clustering_simplificada.qmd` (e o `.R`/`.html` gerados), uma cópia da aula completa sem k-means, PAM, silhueta e comparação de técnicas, com a Gower como seção principal de contraponto e as fichas vindas do Ward euclidiano.

**Architecture:** O arquivo é uma cópia independente de `aula_clustering.qmd`, editada por cortes e reescritas. O `tools/build.R` passa a gerar as duas aulas. Um novo `tests/test_aula_simplificada.R` roda o `.R` simplificado num ambiente limpo, como o `test_aula.R` faz com a aula completa.

**Tech Stack:** R ≥ 4.5, tidyverse, cluster (`daisy`), Quarto, knitr::purl, testthat.

**Spec:** `docs/superpowers/specs/2026-11-24-aula-simplificada-design.md`

## Global Constraints

- A aula completa (`aula_clustering.qmd`, `.R`, `.html`, `tests/test_aula.R`) não muda.
- Pacotes: só tidyverse e cluster.
- O `.R` simplificado nunca é editado à mão: `Rscript tools/build.R`.
- Todo número citado no texto da simplificada é conferido na saída impressa do R. Números copiados da aula completa que dependem do PAM (tamanhos, perfil, % do gasto, validação, clientes-exemplo) **mudam** e precisam ser reescritos.
- Seções de primeiro nível no `.R`: exatamente 6, padrão `^# [1-6][.] .+ ----$`: 1 Problema de negócio e setup, 2 Estatísticas descritivas, 3 Preparação dos dados, 4 Cluster hierárquico, 5 Hierárquico com dados mistos: distância de Gower, 6 Resultados para o negócio.
- Sem sorteio: nenhum `set.seed` e nenhuma das palavras silhueta, k-means, PAM, medoide, WSS, cotovelo ou `nstart` no `.qmd`, exceto numa única linha de "Para fechar" que contém "outras técnicas".
- Gower: **não** afirmar que o estado civil decide a divisão com k = 2 ou 3. A mensagem é "a régua muda, a estrutura principal se mantém", e o grupo só de "Sozinho" aparece em k = 4.
- O cliente-exemplo é "o cliente mais parecido com o perfil médio do grupo" (o mais perto da média do segmento em `dados_pad`); o texto não usa a palavra "centroide".
- Nenhuma frase das fichas compara `NumWebPurchases` entre Premium e Caçador de ofertas (5,52 × 5,46).
- `Rscript` = `"$(ls -d "/c/Program Files/R"/R-*/bin/Rscript.exe | tail -1)"` nesta máquina.

## Review Focus

- **Referência a seção ou técnica que não existe mais** ("na seção 7", "o PAM se sai melhor", "grupo do PAM" numa legenda): o leitor esperaria texto coerente. Teste na Task 2: nenhuma "seção 7" ou "seção 8" e nenhum termo proibido.
- **Número velho copiado do PAM** (8,5% / 13,9% / 23,6%; 822 / 664 / 726; IDs 5267, 10260 e 10383): o teste da Task 2 confere que esses valores não aparecem no `.qmd` simplificado.
- **Aula simplificada quebrando ao rodar do zero num ambiente limpo** (um objeto de seção cortada ainda referenciado, como `grupos_pam`, `medoides` ou `tecnica_final`): o teste "roda e não cria objetos de k-means/PAM" da Task 2.
- **Texto da Gower contradizendo os dados:** os testes da Task 3 fixam as propriedades citadas (average > 90%; complete com k = 2 concordando com o Ward; grupo só de "Sozinho" em k = 4).
- **Duas aulas fora de sincronia com o build:** o teste de sincronia `.qmd` ↔ `.R` da Task 1 vale para a simplificada.

---

### Task 1: Esqueleto da aula simplificada, build e testes básicos

**Files:**
- Create: `aula_clustering_simplificada.qmd` (cópia de `aula_clustering.qmd`; muda só o YAML: `title: "Quem são os nossos clientes? (versão simplificada)"`, `subtitle: "Segmentação de clientes com cluster hierárquico e distância de Gower"`)
- Modify: `tools/build.R` (um laço sobre `c("aula_clustering", "aula_clustering_simplificada")`: `purl` para `<nome>.R` e `quarto render <nome>.qmd`)
- Create: `tests/test_aula_simplificada.R`

**Interfaces:**
- Produces: `rodar_simplificada(arquivo = "aula_clustering_simplificada.R") -> environment` e `env_s` no topo do arquivo de testes. Os demais testes usam `env_s`.

- [ ] **Step 1: Write the failing tests** em `tests/test_aula_simplificada.R`. O cabeçalho é igual ao de `test_aula.R`: `raiz`, uma função que faz `sys.source` num ambiente novo, e `env_s <- rodar_simplificada()`.

```r
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
```

- [ ] **Step 2:** Run `Rscript -e 'testthat::test_file("tests/test_aula_simplificada.R")'`. Expected: erro, porque `aula_clustering_simplificada.R` não existe.
- [ ] **Step 3:** Crie a cópia com o YAML novo, altere o `tools/build.R` e rode `Rscript tools/build.R`. Expected: as duas aulas renderizam.
- [ ] **Step 4:** Run the new tests and `test_aula.R`. Expected: PASS nos dois.
- [ ] **Step 5: Commit** `git add aula_clustering_simplificada.* tools/build.R tests/test_aula_simplificada.R && git commit -m "Esqueleto da aula simplificada e build das duas aulas"`

### Task 2: Cortar k-means, PAM e comparação; resultados sobre o Ward

**Files:**
- Modify: `aula_clustering_simplificada.qmd`, regenerando `.R` e `.html`
- Modify: `tests/test_aula_simplificada.R`

**Interfaces:**
- Consumes: `env_s` (Task 1).
- Produces, no ambiente da aula: `hc_ward`, `grupos_hc`, `k_escolhido = 3L`, `grupos_final` (idêntico a `grupos_hc`), `perfil_segmentos`, `clientes_seg`, `fichas`, `resposta_por_segmento`, `clientes_exemplo` (tibble com uma linha por segmento e colunas `segmento`, `ID`, além das variáveis de perfil mostradas). Não existem `km`, `avaliacao_k`, `pam_euc`, `grupos_pam`, `medoides`, `tecnica_final` nem `comparacao_tecnicas`.

O que muda no `.qmd`:
- **Saem:** as seções 5 (k-means), 6 (PAM) e 7 (comparação).
- **Bônus 6b, por enquanto:** o bloco continua, mas sem as subseções "PAM com Gower", "Por que o k-means não aceita Gower?" e "Os segmentos mudaram…". Ele é reescrito na Task 3.
- **Seção 4:**
  - o parágrafo das alturas justifica k = 3 só pelo dendrograma: o corte em 2 também é defensável, e 3 é mais útil ao marketing;
  - a frase do Ward sobre a WSS "na seção 5" sai.
- **Pacotes:** o comentário do bloco de pacotes cita só o `daisy()`.
- **Antiga seção 8 vira 6:**
  - `grupos_final <- grupos_hc`, com uma frase dizendo que os segmentos vêm do Ward euclidiano;
  - nas legendas e no texto da PCA, "grupo do PAM" vira "grupo do Ward", e a frase sobre a silhueta vira "os grupos se tocam: são fatias de um contínuo";
  - as frases fixas das fichas são conferidas contra o perfil do Ward;
  - a subseção dos clientes-exemplo é reescrita: "o cliente mais parecido com o perfil médio do grupo", calculado com `dados_pad` e `grupos_final`;
  - todos os números do texto (tamanhos, % do gasto, perfil, validação, IDs) são atualizados;
  - "Para fechar" é reescrito, com uma única linha que contém "outras técnicas".

- [ ] **Step 1: Write the failing tests:**

```r
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
  for (p in c("[Ss]ilhueta", "k-means", "\\bPAM\\b", "[Mm]edoide", "\\bWSS\\b", "[Cc]otovelo", "nstart", "set\\.seed",
              "seção 7", "seção 8", "8,5%", "23,6%", "5267", "10260", "10383"))
    expect_false(grepl(p, txt), info = p)
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
```

(Antes da Task 3, a seção Gower ainda tem o número "6b". Por isso, o teste de seções navegáveis só fica verde ao fim da Task 3; isso é esperado.)

- [ ] **Step 2:** Run the tests. Expected: FAIL nos testes novos.
- [ ] **Step 3:** Edite o `.qmd`, rode `Rscript tools/build.R` e confira no `.html` cada número reescrito.
- [ ] **Step 4:** Run the tests. Expected: PASS em todos, exceto "seções navegáveis" (fica para a Task 3).
- [ ] **Step 5: Commit** `git commit -m "Aula simplificada: sem k-means e PAM, resultados sobre o Ward"`

### Task 3: Seção 5, hierárquico com Gower

**Files:**
- Modify: `aula_clustering_simplificada.qmd` (o antigo bloco 6b vira `# 5. Hierárquico com dados mistos: distância de Gower`; a antiga seção 8 vira 6), regenerando `.R` e `.html`
- Modify: `tests/test_aula_simplificada.R`

**Interfaces:**
- Consumes: `grupos_hc` e a ordem dos segmentos (Task 2).
- Produces: `dados_gower`, `dist_gower`, `hc_gower_average`, `hc_gower_complete`, `grupos_gower` (`cutree(hc_gower_complete, k = 2)`).

Conteúdo da seção:
- **Motivação, conta à mão e `daisy()`:** iguais ao bônus atual, sem o aviso "pode pular" e sem os comentários `# ---- fim do bônus 6b ----`. A frase "Guarde essa observação" passa a apontar para o corte em 4, mais adiante nesta seção.
- **Average e complete:** um bloco com `table(cutree(..., k = 3))` para cada ligação.
- **A complete com k = 2:**
  - `table(gower = grupos_gower, ward = grupos_hc)`, com o texto dizendo que a divisão segue o gasto;
  - `table(gower = grupos_gower, estado_civil = clientes$Marital_Status)`, com o texto dizendo que a proporção de casados é parecida nos dois grupos.
- **Corte em 4:** uma linha de código com `table(cutree(hc_gower_complete, k = 4), clientes$Marital_Status)` e uma ou duas frases sobre o grupo só de "Sozinho".
- **Conclusão:** "a régua muda, a estrutura principal se mantém"; seguimos com o Ward euclidiano.
- **Ward com Gower:** no máximo uma frase dizendo que existe e fica fora desta aula, sem código.

- [ ] **Step 1: Write the failing tests:**

```r
test_that("simplificada: Gower", {
  n <- nrow(env_s$clientes)
  expect_equal(attr(env_s$dist_gower, "Metric"), "mixed")
  expect_equal(env_s$hc_gower_average$method, "average")
  expect_equal(env_s$hc_gower_complete$method, "complete")
  expect_gt(max(table(cutree(env_s$hc_gower_average, k = 3))) / n, 0.9)
  expect_gt(min(table(env_s$grupos_gower)) / n, 0.2)
  # a complete com Gower reencontra a divisão por gasto do Ward
  seg <- as.character(env_s$clientes_seg$segmento)
  dom <- function(s) { t <- table(env_s$grupos_gower[seg == s]); c(grupo = names(which.max(t)), prop = max(t) / sum(t)) }
  pr <- dom("Premium"); ec <- dom("Econômico")
  expect_gt(as.numeric(pr["prop"]), 0.7); expect_gt(as.numeric(ec["prop"]), 0.7)
  expect_false(pr["grupo"] == ec["grupo"])
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
```

- [ ] **Step 2:** Run the tests. Expected: FAIL (os objetos Gower novos não existem; "seções navegáveis" ainda falha).
- [ ] **Step 3:** Reescreva a seção, renumere a antiga 8 para 6, rode `Rscript tools/build.R` e confira cada número citado no `.html`.
- [ ] **Step 4:** Run `test_aula_simplificada.R`, `test_aula.R` e `test_figuras.R`. Expected: todos PASS.
- [ ] **Step 5: Commit** `git commit -m "Aula simplificada: seção de Gower como contraponto"`

### Task 4: README

**Files:**
- Modify: `README.md`
- Modify: `tests/test_aula_simplificada.R`

O README ganha:
- na tabela de arquivos, linhas para `aula_clustering_simplificada.R/.html/.qmd` e para `tests/test_aula_simplificada.R`;
- uma seção "## Versão simplificada" logo após "O que os alunos aprendem", dizendo:
  - para quem ela é (turma em que PAM e k-means seriam difíceis);
  - o que sai (k-means, PAM, silhueta, comparação);
  - o que muda (a Gower vira a seção 5; as fichas vêm do Ward; o cliente-exemplo é o mais parecido com o perfil médio);
  - os principais números dela (tamanhos 838/549/825 e taxas de resposta);
- em "Como editar", o comando do teste novo e a nota de que o `build.R` gera as duas aulas.

- [ ] **Step 1: Write the failing test:**

```r
test_that("README cita a versão simplificada", {
  rd <- paste(readLines(file.path(raiz, "README.md"), encoding = "UTF-8"), collapse = "\n")
  expect_match(rd, "## Versão simplificada")
  expect_match(rd, "aula_clustering_simplificada")
  expect_match(rd, "test_aula_simplificada")
})
```

- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Edite o README e confira os números citados com a saída do R.
- [ ] **Step 4:** Run os três arquivos de teste. Expected: todos PASS.
- [ ] **Step 5: Commit** `git commit -m "README: versão simplificada da aula"`
