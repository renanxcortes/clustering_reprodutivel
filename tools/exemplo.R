# Dados de exemplo usados nas figuras (tools/figuras.R) e conferidos pelos testes.
# O exemplo de 6 clientes é digitado também no aula_clustering.qmd: se mudar aqui,
# mude lá (o teste "exemplo do qmd é o mesmo das figuras" acusa a diferença).

# Seis clientes com duas variáveis na mesma escala (0 a 10)
exemplo_clientes <- function() {
  tibble::tibble(
    nome  = c("Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio"),
    renda = c(2, 3, 3, 6, 8, 9),
    gasto = c(2, 2, 4, 5, 8, 7)
  )
}

# O mesmo exemplo como matriz, com os nomes nas linhas (para dist() e hclust())
exemplo_matriz <- function() {
  ex <- exemplo_clientes()
  m <- as.matrix(ex[, c("renda", "gasto")])
  rownames(m) <- ex$nome
  m
}

# Pontos do GIF do k-means: 3 nuvens de 15 clientes e 3 centros iniciais
# escolhidos de propósito longe das nuvens, para a animação ter várias iterações
exemplo_gif <- function() {
  x <- withr::with_seed(2026, {
    centros <- rbind(c(2, 2), c(8, 3), c(5, 8))
    do.call(rbind, lapply(1:3, function(i)
      cbind(rnorm(15, centros[i, 1], 1), rnorm(15, centros[i, 2], 1))))
  })
  colnames(x) <- c("renda", "gasto")
  centros_iniciais <- rbind(c(1, 9), c(2, 8), c(3, 9))
  colnames(centros_iniciais) <- c("renda", "gasto")
  list(x = x, centros_iniciais = centros_iniciais)
}
