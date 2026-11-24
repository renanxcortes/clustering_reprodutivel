# Gera as figuras da aula em figuras/ (PNG e o GIF do k-means).
# Rodar a partir da raiz do projeto:  Rscript tools/figuras.R
# Rode de novo sempre que mudar o exemplo (tools/exemplo.R) ou o visual; depois, rode tools/build.R.
# Exige ggplot2 e patchwork; o GIF exige também gifski (só na máquina de quem gera as figuras).

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})
source("tools/exemplo.R")
source("tools/kmeans_passos.R")

dir.create("figuras", showWarnings = FALSE)

cores_grupos <- c("firebrick", "steelblue", "darkgreen")
cor_texto <- "grey20"

salvar <- function(grafico, arquivo, largura = 8, altura = 4.5) {
  ggsave(file.path("figuras", arquivo), grafico, width = largura, height = altura,
         dpi = 200, bg = "white")
}

tema_plano <- function() {
  theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"),
          plot.caption = element_text(hjust = 0.5, size = 12, colour = cor_texto))
}

eixos_plano <- function() {
  list(coord_equal(xlim = c(0, 10.5), ylim = c(0, 10.5), expand = FALSE),
       scale_x_continuous(breaks = seq(0, 10, 2)),
       scale_y_continuous(breaks = seq(0, 10, 2)),
       labs(x = "renda", y = "gasto"))
}

# ---- Bonequinhos -------------------------------------------------------------
# Cada cliente vira um bonequinho centrado no seu ponto (cabeça, corpo, braços, pernas)
camada_bonequinhos <- function(df, cor = cor_texto, escala = 0.7, nomes = TRUE, tam_nome = 3.6) {
  s <- escala
  seg <- do.call(rbind, lapply(seq_len(nrow(df)), function(i) {
    x <- df$renda[i]; y <- df$gasto[i]
    # corpo, braço esquerdo, braço direito, perna esquerda, perna direita
    data.frame(x    = c(x,            x,             x,             x,            x),
               y    = c(y + 0.30 * s, y + 0.15 * s,  y + 0.15 * s,  y - 0.25 * s, y - 0.25 * s),
               xend = c(x,            x - 0.32 * s,  x + 0.32 * s,  x - 0.25 * s, x + 0.25 * s),
               yend = c(y - 0.25 * s, y - 0.12 * s,  y - 0.12 * s,  y - 0.75 * s, y - 0.75 * s),
               cor = if (length(cor) > 1) cor[i] else cor)
  }))
  cab <- data.frame(x = df$renda, y = df$gasto + 0.52 * s,
                    cor = if (length(cor) > 1) cor else rep(cor, nrow(df)))
  camadas <- list(
    geom_segment(data = seg, aes(x = x, y = y, xend = xend, yend = yend, colour = I(cor)),
                 linewidth = 1.3, lineend = "round", inherit.aes = FALSE),
    geom_point(data = cab, aes(x = x, y = y, colour = I(cor)), size = 5.5 * s / 0.7, inherit.aes = FALSE)
  )
  if (nomes) {
    rot <- data.frame(x = df$renda, y = df$gasto - 0.85 * s, nome = df$nome,
                      cor = if (length(cor) > 1) cor else rep(cor, nrow(df)))
    camadas <- c(camadas, list(geom_text(data = rot, aes(x = x, y = y, label = nome, colour = I(cor)),
                                         size = tam_nome, vjust = 1, inherit.aes = FALSE)))
  }
  camadas
}

# Contorno suave em volta de um grupo de clientes (envoltória de círculos em volta de cada um)
contorno_grupo <- function(df, raio = 0.75) {
  ang <- seq(0, 2 * pi, length.out = 40)
  pts <- do.call(rbind, lapply(seq_len(nrow(df)), function(i)
    data.frame(x = df$renda[i] + raio * cos(ang), y = df$gasto[i] + raio * sin(ang) - 0.1)))
  pts[chull(pts$x, pts$y), ]
}

camada_contorno <- function(df, cor, raio = 0.75) {
  geom_polygon(data = contorno_grupo(df, raio), aes(x = x, y = y),
               fill = cor, alpha = 0.10, colour = cor, linewidth = 0.6, inherit.aes = FALSE)
}

fmt <- function(v, casas = 1) formatC(v, format = "f", digits = casas, decimal.mark = ",")

ex <- exemplo_clientes()
m_ex <- exemplo_matriz()
d_ex <- as.matrix(dist(m_ex))
pegar <- function(nomes) ex[match(nomes, ex$nome), ]

# ---- Figura 1: distância entre dois clientes --------------------------------
ana <- pegar("Ana"); diego <- pegar("Diego")
fig1 <- ggplot() +
  camada_bonequinhos(ex[!ex$nome %in% c("Ana", "Diego"), ], cor = "grey80") +
  annotate("segment", x = ana$renda, y = ana$gasto, xend = diego$renda, yend = ana$gasto,
           colour = "steelblue", linewidth = 1, linetype = "22") +
  annotate("segment", x = diego$renda, y = ana$gasto, xend = diego$renda, yend = diego$gasto,
           colour = "darkgreen", linewidth = 1, linetype = "22") +
  annotate("segment", x = ana$renda, y = ana$gasto, xend = diego$renda, yend = diego$gasto,
           colour = "firebrick", linewidth = 1.6) +
  annotate("label", x = (ana$renda + diego$renda) / 2 + 0.4, y = ana$gasto - 1.35,
           label = "diferença na renda: 6 − 2 = 4", colour = "steelblue", size = 3.8,
           linewidth = 0) +
  annotate("label", x = diego$renda + 0.3, y = (ana$gasto + diego$gasto) / 2,
           label = "diferença no gasto:\n5 − 2 = 3", colour = "darkgreen", size = 3.8,
           hjust = 0, linewidth = 0) +
  annotate("label", x = 2.6, y = 6.3, label = "distância = √(4² + 3²) = 5",
           colour = "firebrick", fontface = "bold", size = 4.3, linewidth = 0) +
  camada_bonequinhos(rbind(ana, diego)) +
  eixos_plano() +
  labs(title = "Distância entre Ana e Diego",
       caption = "É o teorema de Pitágoras: com 15 variáveis, a conta é a mesma, com 15 diferenças.") +
  tema_plano()
salvar(fig1, "distancia_dois_clientes.png", largura = 7, altura = 6.5)

# ---- Figura 2: matriz de distâncias -----------------------------------------
pares <- t(combn(ex$nome, 2))
linhas_pares <- data.frame(
  x = ex$renda[match(pares[, 1], ex$nome)], y = ex$gasto[match(pares[, 1], ex$nome)],
  xend = ex$renda[match(pares[, 2], ex$nome)], yend = ex$gasto[match(pares[, 2], ex$nome)])
plano2 <- ggplot() +
  geom_segment(data = linhas_pares, aes(x = x, y = y, xend = xend, yend = yend),
               colour = "grey75", linewidth = 0.4) +
  camada_bonequinhos(ex) +
  eixos_plano() +
  labs(title = "Os 6 clientes", subtitle = "cada linha cinza é um par: 15 pares") +
  tema_plano()

tab <- expand.grid(linha = ex$nome, coluna = ex$nome, stringsAsFactors = FALSE)
tab$dist <- d_ex[cbind(tab$linha, tab$coluna)]
i_l <- match(tab$linha, ex$nome); i_c <- match(tab$coluna, ex$nome)
tab$parte <- ifelse(i_l == i_c, "diagonal", ifelse(i_l > i_c, "baixo", "cima"))
tab$linha <- factor(tab$linha, levels = rev(ex$nome))
tab$coluna <- factor(tab$coluna, levels = ex$nome)
matriz2 <- ggplot(tab, aes(x = coluna, y = linha)) +
  geom_tile(aes(fill = ifelse(tab$parte == "baixo", dist, NA)), colour = "white", linewidth = 1) +
  geom_tile(data = tab[tab$parte != "baixo", ], fill = "grey95", colour = "white", linewidth = 1) +
  geom_text(aes(label = fmt(dist), colour = I(ifelse(tab$parte == "baixo", "black", "grey65"))),
            size = 4) +
  scale_fill_gradient(low = "#fde0c5", high = "#c0392b", na.value = "grey95", guide = "none") +
  scale_x_discrete(position = "top") +
  labs(title = "A matriz de distâncias",
       subtitle = "diagonal = 0 (distância de alguém até ele mesmo)\nparte de cima = espelho da de baixo",
       x = NULL, y = NULL) +
  coord_equal() +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(), plot.title = element_text(face = "bold"))
fig2 <- plano2 + matriz2 + plot_layout(widths = c(1, 1))
salvar(fig2, "matriz_distancias.png", largura = 12, altura = 6)

# ---- Figura 3: as quatro regras para "Diego vai para qual grupo?" ------------
g_abc <- pegar(c("Ana", "Bruno", "Carla"))
g_ef <- pegar(c("Elisa", "Fábio"))
linha_ate <- function(nome, cor, tipo = "solid", largura = 1.2) {
  alvo <- pegar(nome)
  annotate("segment", x = diego$renda, y = diego$gasto, xend = alvo$renda, yend = alvo$gasto,
           colour = cor, linewidth = largura, linetype = tipo)
}
d_diego <- d_ex["Diego", ]
media_abc <- mean(d_diego[c("Ana", "Bruno", "Carla")])
media_ef <- mean(d_diego[c("Elisa", "Fábio")])

# Ward: aumento do espalhamento (soma das distâncias ao quadrado até o centro) ao incluir Diego
espalhamento <- function(nomes) {
  m <- m_ex[nomes, , drop = FALSE]
  sum(sweep(m, 2, colMeans(m))^2)
}
aum_abc <- espalhamento(c("Ana", "Bruno", "Carla", "Diego")) - espalhamento(c("Ana", "Bruno", "Carla"))
aum_ef <- espalhamento(c("Elisa", "Fábio", "Diego")) - espalhamento(c("Elisa", "Fábio"))

base_regra <- function(titulo, rodape, camadas) {
  ggplot() +
    camada_contorno(g_abc, "firebrick") +
    camada_contorno(g_ef, "steelblue") +
    camadas +
    camada_bonequinhos(g_abc, cor = "firebrick", tam_nome = 3.2) +
    camada_bonequinhos(g_ef, cor = "steelblue", tam_nome = 3.2) +
    camada_bonequinhos(diego, tam_nome = 3.2) +
    eixos_plano() +
    labs(title = titulo, caption = rodape) +
    tema_plano() +
    theme(axis.title = element_blank(), axis.text = element_blank(), panel.grid = element_blank(),
          panel.border = element_rect(colour = "grey85", fill = NA))
}

p_single <- base_regra(
  "single: a MENOR distância",
  paste0("até o vermelho: ", fmt(d_diego["Carla"]), "   até o azul: ", fmt(d_diego["Elisa"]),
         "\nDiego vai para o VERMELHO"),
  list(linha_ate("Carla", "firebrick"), linha_ate("Elisa", "steelblue")))

p_complete <- base_regra(
  "complete: a MAIOR distância",
  paste0("até o vermelho: ", fmt(d_diego["Ana"]), "   até o azul: ", fmt(d_diego["Fábio"]),
         "\nDiego vai para o AZUL"),
  list(linha_ate("Ana", "firebrick"), linha_ate("Fábio", "steelblue")))

p_average <- base_regra(
  "average: a MÉDIA das distâncias",
  paste0("até o vermelho: ", fmt(media_abc), "   até o azul: ", fmt(media_ef),
         "\nDiego vai para o AZUL"),
  c(lapply(c("Ana", "Bruno", "Carla"), linha_ate, cor = "firebrick", largura = 0.7),
    lapply(c("Elisa", "Fábio"), linha_ate, cor = "steelblue", largura = 0.7)))

centro <- function(nomes) colMeans(m_ex[nomes, , drop = FALSE])
c_abc <- centro(c("Ana", "Bruno", "Carla", "Diego"))
c_ef <- centro(c("Elisa", "Fábio", "Diego"))
raios <- function(nomes, c0, cor) {
  m <- m_ex[nomes, , drop = FALSE]
  list(annotate("segment", x = m[, 1], y = m[, 2], xend = c0[1], yend = c0[2],
                colour = cor, linewidth = 0.7, linetype = "22"),
       annotate("point", x = c0[1], y = c0[2], shape = 4, size = 4, stroke = 1.6, colour = cor))
}
p_ward <- base_regra(
  "Ward: o MENOS espalhado",
  paste0("aumento do espalhamento: vermelho ", fmt(aum_abc), "   azul ", fmt(aum_ef),
         "\nDiego vai para o AZUL"),
  c(raios(c("Ana", "Bruno", "Carla", "Diego"), c_abc, "firebrick"),
    raios(c("Elisa", "Fábio", "Diego"), c_ef, "steelblue")))

fig3 <- (p_single | p_complete | p_average | p_ward) +
  plot_annotation(
    title = "Diego vai para qual grupo? Depende da regra de junção",
    subtitle = "Vermelho = {Ana, Bruno, Carla}; azul = {Elisa, Fábio}. No Ward, o ✕ é o centro do grupo já com Diego.",
    theme = theme(plot.title = element_text(face = "bold", size = 16)))
salvar(fig3, "ligacoes_regra.png", largura = 16, altura = 5.6)

# ---- Figura 4: os passos e os quatro dendrogramas ---------------------------
metodos <- c(single = "single", complete = "complete", average = "average", Ward = "ward.D2")
hcs <- lapply(metodos, function(m) hclust(dist(m_ex), method = m))

# Segmentos de um dendrograma desenhado em ggplot; destaca a fusão em que Diego entra
segmentos_dendrograma <- function(h) {
  n <- length(h$order)
  pos_folha <- numeric(n); pos_folha[h$order] <- seq_len(n)
  pos_no <- numeric(n - 1); alt_no <- h$height
  tem_diego <- logical(n - 1)
  diego_i <- which(h$labels == "Diego")
  segs <- list()
  for (i in seq_len(n - 1)) {
    filhos <- h$merge[i, ]
    xs <- sapply(filhos, function(f) if (f < 0) pos_folha[-f] else pos_no[f])
    ys <- sapply(filhos, function(f) if (f < 0) 0 else alt_no[f])
    pos_no[i] <- mean(xs)
    tem_diego[i] <- any(filhos == -diego_i)
    segs[[i]] <- data.frame(x = c(xs[1], xs[2], xs[1]), y = c(ys[1], ys[2], alt_no[i]),
                            xend = c(xs[1], xs[2], xs[2]), yend = c(alt_no[i], alt_no[i], alt_no[i]),
                            diego = tem_diego[i])
  }
  list(segs = do.call(rbind, segs),
       folhas = data.frame(x = pos_folha, nome = h$labels))
}

dendro <- function(nome_metodo) {
  h <- hcs[[nome_metodo]]
  s <- segmentos_dendrograma(h)
  ggplot() +
    geom_segment(data = s$segs, aes(x = x, y = y, xend = xend, yend = yend,
                                    colour = I(ifelse(diego, "darkorange", "grey30")),
                                    linewidth = I(ifelse(diego, 1.4, 0.8)))) +
    geom_text(data = s$folhas, aes(x = x, y = -0.25, label = nome,
                                   colour = I(ifelse(nome == "Diego", "darkorange", "grey20"))),
              angle = 90, hjust = 1, size = 3.6) +
    scale_y_continuous(limits = c(-2.3, 11.5), breaks = seq(0, 10, 2)) +
    labs(title = nome_metodo, y = "altura da fusão", x = NULL) +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
}

passo <- function(titulo, grupos) {
  camadas <- list()
  for (j in seq_along(grupos)) camadas <- c(camadas, list(camada_contorno(pegar(grupos[[j]]), cores_grupos[j], raio = 0.8)))
  ggplot() + camadas + camada_bonequinhos(ex, escala = 0.6, tam_nome = 3) +
    eixos_plano() + labs(title = titulo) + tema_plano() +
    theme(axis.title = element_blank(), axis.text = element_blank(), panel.grid = element_blank(),
          panel.border = element_rect(colour = "grey85", fill = NA),
          plot.title = element_text(size = 11, face = "bold"))
}
p1 <- passo(paste0("Passo 1: Ana + Bruno (", fmt(d_ex["Ana", "Bruno"]), ")"), list(c("Ana", "Bruno")))
p2 <- passo(paste0("Passo 2: Elisa + Fábio (", fmt(d_ex["Elisa", "Fábio"]), ")"),
            list(c("Ana", "Bruno"), c("Elisa", "Fábio")))
p3 <- passo("Passo 3: Carla entra com Ana e Bruno", list(c("Ana", "Bruno", "Carla"), c("Elisa", "Fábio")))
p4 <- ggplot() +
  annotate("text", x = 0, y = 0, size = 4.6, colour = "darkorange", fontface = "bold",
           label = "Passo 4: Diego vai\npara qual grupo?\n\nAqui as regras\ndiscordam\n(veja os dendrogramas)") +
  theme_void()

fig4 <- (p1 | p2 | p3 | p4) / (dendro("single") | dendro("complete") | dendro("average") | dendro("Ward")) +
  plot_layout(heights = c(1, 1.15)) +
  plot_annotation(
    title = "Construindo o dendrograma: os 3 primeiros passos são iguais nas quatro regras",
    subtitle = "Embaixo, os dendrogramas; em laranja, a fusão em que Diego entra. Repare também nas alturas: cada regra mede a distância entre grupos de um jeito.",
    theme = theme(plot.title = element_text(face = "bold", size = 16)))
salvar(fig4, "ligacoes_passos.png", largura = 15, altura = 9.5)

cat("Figuras estáticas gravadas em figuras/\n")
