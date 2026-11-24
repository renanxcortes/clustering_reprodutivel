# Aula mais didática (distância, ligações, k-means) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Acrescentar à aula figuras de distância/matriz com bonequinhos, figuras das ligações single/complete/average/Ward sobre um exemplo de 6 clientes, a demonstração de que as três primeiras falham na base real, e um GIF do k-means, sem colocar código de desenho no `.R` dos alunos.

**Architecture:** Os dados de exemplo ficam definidos uma vez em `tools/exemplo.R`. O `tools/kmeans_passos.R` implementa o k-means passo a passo (uma função pura e testável). O `tools/figuras.R` usa os dois para gravar PNGs e o GIF em `figuras/` (versionada). O `.qmd` insere as imagens com Markdown e ganha blocos curtos para os alunos rodarem sobre o exemplo e sobre a base real. O `tools/build.R` continua gerando `.R` e `.html`.

**Tech Stack:** R ≥ 4.5, ggplot2, gifski (só para gerar o GIF), cluster, testthat, Quarto.

**Spec:** `docs/superpowers/specs/2026-11-24-didatica-distancia-agrupamento-design.md`

## Global Constraints

- `aula_clustering.qmd` é a fonte única; nunca edite `aula_clustering.R` à mão: rode `Rscript tools/build.R`.
- Nenhum código de desenho (ggplot das figuras, gifski) entra no `.qmd`/`.R`; as figuras são inseridas com `![legenda](figuras/arquivo.png)`.
- Nenhum pacote novo nas máquinas do laboratório: o `.qmd` só usa tidyverse e cluster (base R para os dendrogramas do exemplo).
- Todo número citado no texto do `.qmd` deve ser conferido na saída impressa do R.
- Textos em português, sem fórmulas nas figuras; as regras são escritas em palavras ("a menor distância", "a maior", "a média", "ficam menos espalhados").
- Paleta dos grupos: `firebrick`, `steelblue`, `darkgreen` (a da aula atual). Bonequinhos desenhados em ggplot, sem fontes de emoji.
- O GIF deve ter **no máximo 2 MB** (ele é embutido no HTML).
- As seções de primeiro nível continuam 9 no `.R` (teste `^# ([1-8]|6b)[.] .+ ----$`); comentários novos nos blocos não podem casar com esse padrão.
- Ward continua o hierárquico do resto da aula: `hc_ward`, `grupos_hc`, `k_escolhido = 3L` e todo o texto das seções 5 a 8 ficam inalterados.
- Nesta máquina o `Rscript` não está no PATH do bash: use `"$(ls -d "/c/Program Files/R"/R-*/bin/Rscript.exe | tail -1)"`. Abaixo, `Rscript` significa esse executável.

## Review Focus

- **Versão diferente do R/pacotes muda os tamanhos na base real:** o texto afirma que single/complete/average "falham"; o teste da Task 5 exige que o maior grupo tenha > 90% dos clientes em cada uma.
- **Exemplo do `.qmd` divergindo do `tools/exemplo.R`** (alguém edita um número só num lugar): o teste da Task 5 compara `env$exemplo` com `exemplo_clientes()`.
- **Figura citada no `.qmd` que não existe ou não foi regerada:** o teste da Task 6 confere que todo `figuras/*.png|gif` citado existe.
- **GIF pesado demais para o HTML embutido:** a Task 4 testa o tamanho em ≤ 2 MB.
- **Grupo vazio numa iteração do k-means animado:** a Task 2 testa que `kmeans_passos()` mantém o centro anterior quando um grupo fica vazio (sem `NaN`).

---

## O exemplo de 6 clientes (valores fixados, conferidos no R)

| nome | renda | gasto |
|---|---|---|
| Ana | 2 | 2 |
| Bruno | 3 | 2 |
| Carla | 3 | 4 |
| Diego | 6 | 5 |
| Elisa | 8 | 8 |
| Fábio | 9 | 7 |

Propriedades que as figuras e o texto usam:
- Ana–Diego: Δrenda 4, Δgasto 3, distância **5** (triângulo 3-4-5; figura 1).
- Os passos 1–3 são iguais nas quatro ligações: {Ana, Bruno} (1,0), {Elisa, Fábio} (1,41), Carla entra em {Ana, Bruno}.
- **Passo 4, "Diego vai para qual grupo?"** Distâncias de Diego: até Ana 5,0, Bruno 4,24, Carla 3,16; até Elisa 3,61, Fábio 3,61.
  - single: menor até {A,B,C} = 3,16 < 3,61 → Diego entra em {Ana, Bruno, Carla};
  - complete: maior até {A,B,C} = 5,0 > 3,61 → Diego entra em {Elisa, Fábio};
  - average: média até {A,B,C} = 4,13 > 3,61 → {Elisa, Fábio};
  - Ward: {Elisa, Fábio} (altura 4,08).
- Com k = 2: single separa {Elisa, Fábio}; complete/average/Ward separam {Ana, Bruno, Carla} × {Diego, Elisa, Fábio}.
- Alturas finais: single 3,61; complete 8,60; average 6,47; ward.D2 11,09.

---

### Task 1: Dados de exemplo compartilhados

**Files:**
- Create: `tools/exemplo.R`
- Create: `tests/test_figuras.R`

**Interfaces:**
- Produces: `exemplo_clientes() -> tibble(nome: chr, renda: dbl, gasto: dbl)` (6 linhas, ordem da tabela acima); `exemplo_matriz() -> matrix 6×2` (colunas `renda`, `gasto`, `rownames` = nomes); `exemplo_gif() -> list(x = matrix n×2, centros_iniciais = matrix 3×2)`.

- [ ] **Step 1: Write the failing tests** em `tests/test_figuras.R` (raiz resolvida como em `test_aula.R`; `source(file.path(raiz, "tools/exemplo.R"))`):

```r
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
```

- [ ] **Step 2:** Run `Rscript -e 'testthat::test_file("tests/test_figuras.R")'`. Expected: FAIL (`exemplo_clientes` não existe).
- [ ] **Step 3:** Implemente `tools/exemplo.R` com os valores da tabela. `exemplo_gif()`: `set.seed(2026)` local (use `withr::with_seed(2026, ...)`), 3 nuvens 2D, 15 pontos cada; centros iniciais escolhidos pelo builder de modo que a Task 2 dê de 3 a 6 iterações.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git add tools/exemplo.R tests/test_figuras.R && git commit -m "Dados de exemplo para as figuras da aula"`

### Task 2: k-means passo a passo

**Files:**
- Create: `tools/kmeans_passos.R`
- Modify: `tests/test_figuras.R`

**Interfaces:**
- Consumes: `exemplo_gif()`.
- Produces: `kmeans_passos(x: matrix n×2, centros: matrix k×2, max_iter = 20L) -> list(centros: list de matrizes k×2, atribuicoes: list de inteiros de tamanho n, iter: integer)`. `centros[[1]]` são os iniciais; `atribuicoes[[i]]` é feita com `centros[[i]]`; `centros[[i + 1]]` são as médias de `atribuicoes[[i]]`. Para quando a atribuição não muda; `iter` = número de atualizações de centros. Grupo vazio mantém o centro anterior.

- [ ] **Step 1: Write the failing tests:**

```r
test_that("kmeans_passos bate com o kmeans() do R", {
  g <- exemplo_gif()
  p <- kmeans_passos(g$x, g$centros_iniciais)
  km <- kmeans(g$x, centers = g$centros_iniciais, algorithm = "Lloyd", iter.max = 50)
  expect_equal(unname(tail(p$centros, 1)[[1]]), unname(km$centers))
  expect_equal(tail(p$atribuicoes, 1)[[1]], unname(km$cluster))
  expect_true(p$iter >= 3 && p$iter <= 6)
})

test_that("kmeans_passos não quebra com grupo vazio", {
  x <- cbind(c(0, 0.1, 10, 10.1), c(0, 0.1, 10, 10.1))
  p <- kmeans_passos(x, rbind(c(0, 0), c(10, 10), c(100, 100)))
  expect_false(anyNA(unlist(p$centros)))
  expect_equal(tail(p$centros, 1)[[1]][3, ], c(100, 100))
})
```

- [ ] **Step 2:** Run the tests. Expected: FAIL (`kmeans_passos` não existe).
- [ ] **Step 3:** Implemente `kmeans_passos()` (algoritmo de Lloyd). Se a contagem de iterações cair fora de 3:6, ajuste `centros_iniciais` em `tools/exemplo.R`, não o teste.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git commit -m "k-means passo a passo para a animação"`

### Task 3: Figuras estáticas (distância, matriz, ligações)

**Files:**
- Create: `tools/figuras.R` (fazendo `source()` de `tools/exemplo.R` e `tools/kmeans_passos.R`; grava em `figuras/`, criando a pasta)
- Create: `figuras/distancia_dois_clientes.png`, `figuras/matriz_distancias.png`, `figuras/ligacoes_regra.png`, `figuras/ligacoes_passos.png`
- Modify: `tests/test_figuras.R`

**Interfaces:**
- Consumes: `exemplo_clientes()`, `exemplo_matriz()`.
- Produces: os quatro PNGs (cerca de 1600×900 px, `dpi = 200`, legíveis em projetor).

Conteúdo de cada figura:
1. `distancia_dois_clientes.png`: os 6 clientes em cinza claro; Ana e Diego como bonequinhos com nome, os catetos rotulados "renda: 6 − 2 = 4" e "gasto: 5 − 2 = 3", e a hipotenusa "distância = 5".
2. `matriz_distancias.png`: à esquerda, os 6 bonequinhos no plano; à direita, a matriz 6×6 (`geom_tile` + valores com 1 casa decimal), com a diagonal 0 em destaque, o triângulo inferior com cor forte e o superior esmaecido (com a nota "igual ao de baixo").
3. `ligacoes_regra.png`: 4 painéis com título "Diego vai para qual grupo?". Em cada painel, {Ana, Bruno, Carla} e {Elisa, Fábio} são contornados e Diego aparece no meio:
   - single: a linha mais curta até cada grupo (3,2 × 3,6);
   - complete: a mais longa (5,0 × 3,6);
   - average: todas as linhas, com as médias (4,1 × 3,6);
   - Ward: o espalhamento (segmentos de cada cliente até o centro do grupo) dos dois grupos candidatos já com Diego.

   No rodapé de cada painel, a regra em palavras e a decisão.
4. `ligacoes_passos.png`: na linha de cima, os passos 1–3 ("iguais nas quatro ligações"). Na linha de baixo, um dendrograma por ligação (a partir de `hclust`), destacando onde Diego entrou. O builder escolhe como desenhar o dendrograma em ggplot.

- [ ] **Step 1: Write the failing test:**

```r
test_that("figuras estáticas existem", {
  for (f in c("distancia_dois_clientes", "matriz_distancias", "ligacoes_regra", "ligacoes_passos"))
    expect_true(file.exists(file.path(raiz, "figuras", paste0(f, ".png"))), info = f)
})
```

- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implemente `tools/figuras.R` para as quatro figuras e rode `Rscript tools/figuras.R`.
- [ ] **Step 4:** Abra cada PNG e confira: valores iguais às propriedades listadas acima, texto legível, nenhum rótulo sobreposto. Run the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git add tools/figuras.R figuras/*.png tests/test_figuras.R && git commit -m "Figuras de distância e das ligações"`

### Task 4: GIF do k-means

**Files:**
- Modify: `tools/figuras.R`
- Create: `figuras/kmeans_iteracoes.gif`
- Modify: `tests/test_figuras.R`

**Interfaces:**
- Consumes: `exemplo_gif()`, `kmeans_passos()`.
- Produces: `figuras/kmeans_iteracoes.gif`.

Quadros, em ordem:
1. "Início: 3 centros sorteados" (pontos cinza, centros como ✕ grandes).
2. Para cada iteração i: "Iteração i: cada cliente vai para o centro mais próximo" (pontos coloridos), seguido de "Iteração i: cada centro vai para a média do seu grupo" (seta da posição antiga até a nova).
3. Final: "Ninguém mudou de grupo: fim!".

O primeiro quadro e o último ficam cerca de 3× mais tempo na tela; os demais, cerca de 1,2 s. Os eixos ficam fixos em todos os quadros. O GIF é gerado com `gifski::save_gif()` (instale o `gifski` se faltar: `install.packages("gifski")`, só nesta máquina).

- [ ] **Step 1: Write the failing test:**

```r
test_that("GIF do k-means existe e é leve", {
  f <- file.path(raiz, "figuras", "kmeans_iteracoes.gif")
  expect_true(file.exists(f))
  expect_lte(file.size(f), 2 * 1024^2)
})
```

- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Acrescente o GIF ao `tools/figuras.R` e rode-o.
- [ ] **Step 4:** Abra o GIF e confira que os quadros seguem a ordem, os centros se movem e as cores batem com os centros. Run the tests. Expected: PASS.
- [ ] **Step 5: Commit** `git commit -m "GIF das iterações do k-means"`

### Task 5: Seção 4 do `.qmd` (distância, ligações, falha na base real, Ward)

**Files:**
- Modify: `aula_clustering.qmd:517-599` (seção 4), regenerando `aula_clustering.R` e `aula_clustering.html`
- Modify: `tests/test_aula.R`

**Interfaces:**
- Consumes: as figuras da Task 3 e `exemplo_clientes()` (só no teste).
- Produces, no ambiente do script: `exemplo` (tibble igual a `exemplo_clientes()`), `dist_exemplo`, `hc_exemplo` (lista nomeada `single`, `complete`, `average`, `ward` de `hclust`), `hc_single`, `hc_complete`, `hc_average` (sobre `dist_euc`). `hc_ward`, `grupos_hc` e `k_escolhido` continuam como estão.

Nova ordem da seção 4:
1. Texto atual de abertura.
2. "Distância entre clientes e a matriz de distâncias": figura 1 → figura 2 → um bloco em que os alunos criam `exemplo` (um `tibble()` digitado, com os 6 valores) e rodam `dist(exemplo[, c("renda", "gasto")])` com os nomes nas linhas, reconhecendo os números da figura → o exemplo atual com 3 clientes reais, a conta à mão e `dist_euc`, sem mudanças.
3. "Como juntar dois grupos? Quatro regras": o texto explica que o hierárquico começa com cada cliente sozinho e repete "junte os dois grupos mais próximos" → a figura 4 (passos 1–3 iguais) → a figura 3 e as quatro regras em palavras, com o Ward como "o que mantém os grupos compactos" → um bloco com `hc_exemplo` e `par(mfrow = c(2, 2))` + 4 `plot()` com títulos, terminando com `par(mfrow = c(1, 1))`.
4. "E na base real?": `hc_single`, `hc_complete`, `hc_average` sobre `dist_euc` e `table(cutree(hc_x, k = 3))` para cada um. O texto cita os tamanhos impressos (conferidos: 2208/3/1, 2199/9/4, 2205/4/3) e explica, sem afirmar além do que foi conferido, que a base é um contínuo: elas isolam poucos clientes muito diferentes em vez de dividir a base.
5. "A ligação de Ward", reescrita como desfecho: retoma o painel do Ward, diz que é a regra usada daqui em diante, e o código `hc_ward` fica igual. O dendrograma, as alturas e o corte ficam iguais.

- [ ] **Step 1: Write the failing tests** (em `test_aula.R`):

```r
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
```

- [ ] **Step 2:** Run `Rscript -e 'testthat::test_file("tests/test_aula.R")'`. Expected: FAIL nos dois testes novos.
- [ ] **Step 3:** Edite o `.qmd` e rode `Rscript tools/build.R`. Confira no `.html` cada número citado.
- [ ] **Step 4:** Run `test_aula.R` e `test_figuras.R`. Expected: tudo PASS (incluindo "script roda rápido" e "seções navegáveis" = 9).
- [ ] **Step 5: Commit** `git add aula_clustering.qmd aula_clustering.R aula_clustering.html tests/test_aula.R && git commit -m "Seção 4: matriz de distâncias e as quatro ligações com figuras"`

### Task 6: GIF na seção 5, referência no bônus e README

**Files:**
- Modify: `aula_clustering.qmd` ("A ideia do k-means"; parágrafo do bônus 6b em `:933`), regenerando `.R` e `.html`
- Modify: `README.md`
- Modify: `tests/test_aula.R`

Conteúdo:
- Seção 5: o GIF vem logo após a lista dos 4 passos, com uma legenda que liga quadros a passos ("✕ = centro; a cada iteração, os passos 2 e 3 se repetem").
- 6b: "Usamos a **ligação média** ... (a regra do painel *average* da figura da seção 4)"; o resto fica igual.
- README:
  - item 3 de "O que os alunos aprendem": "cluster hierárquico: as ligações single, complete e average num exemplo de 6 clientes, por que falham nesta base, e a ligação de Ward";
  - tabela de arquivos: `tools/figuras.R`, `tools/exemplo.R`, `tools/kmeans_passos.R`, `figuras/`;
  - "Como editar": `Rscript tools/figuras.R` antes do build quando mudar figura (exige `gifski`), e `tests/test_figuras.R` no comando de testes;
  - dicas para o professor: os blocos do exemplo de 6 clientes e "E na base real?" podem ser só comentados se faltar tempo.

- [ ] **Step 1: Write the failing test:**

```r
test_that("figuras citadas no qmd existem", {
  qmd <- paste(readLines(file.path(raiz, "aula_clustering.qmd"), encoding = "UTF-8"), collapse = "\n")
  figs <- unique(regmatches(qmd, gregexpr("figuras/[A-Za-z0-9_]+\\.(png|gif)", qmd))[[1]])
  expect_true("figuras/kmeans_iteracoes.gif" %in% figs)
  expect_gte(length(figs), 5)
  for (f in figs) expect_true(file.exists(file.path(raiz, f)), info = f)
})
```

- [ ] **Step 2:** Run the tests. Expected: FAIL (o GIF ainda não é citado).
- [ ] **Step 3:** Edite o `.qmd` e o README e rode `Rscript tools/build.R`.
- [ ] **Step 4:** Run `test_aula.R` e `test_figuras.R`. Expected: tudo PASS. Abra o `.html` e confira que as 5 figuras aparecem e o GIF anima.
- [ ] **Step 5: Commit** `git add -A aula_clustering.* README.md tests/test_aula.R && git commit -m "GIF do k-means na aula e README atualizado"`
