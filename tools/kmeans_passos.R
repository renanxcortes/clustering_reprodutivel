# K-means passo a passo (algoritmo de Lloyd), guardando cada etapa para a animação.
# centros[[1]] são os centros iniciais; atribuicoes[[i]] usa centros[[i]];
# centros[[i + 1]] são as médias dos grupos de atribuicoes[[i]].
# Para quando ninguém muda de grupo. Grupo vazio mantém o centro anterior.
kmeans_passos <- function(x, centros, max_iter = 20L) {
  x <- as.matrix(x)
  centros <- as.matrix(centros)
  lista_centros <- list(centros)
  lista_atrib <- list()
  anterior <- NULL
  for (i in seq_len(max_iter)) {
    # Distância ao quadrado de cada ponto a cada centro; o grupo é o centro mais próximo
    d2 <- sapply(seq_len(nrow(centros)), function(j) colSums((t(x) - centros[j, ])^2))
    atrib <- max.col(-d2, ties.method = "first")
    if (identical(atrib, anterior)) break
    lista_atrib[[i]] <- atrib
    novos <- centros
    for (j in seq_len(nrow(centros))) {
      if (any(atrib == j)) novos[j, ] <- colMeans(x[atrib == j, , drop = FALSE])
    }
    centros <- novos
    lista_centros[[i + 1]] <- centros
    anterior <- atrib
  }
  list(centros = lista_centros, atribuicoes = lista_atrib, iter = length(lista_atrib))
}
