# Gera os scripts das aulas e os HTMLs a partir dos .qmd (as únicas fontes):
#   aula_clustering_simplificada.qmd       -> aula principal (só hierárquico)
#   versao_estendida/aula_clustering.qmd   -> versão estendida (hierárquico, k-means e PAM)
# Rodar a partir da raiz do projeto:  Rscript tools/build.R
# Nunca edite os .R das aulas à mão: eles são sobrescritos aqui.

quarto <- Sys.which("quarto")
if (quarto == "") {
  quarto <- "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
}

for (aula in c("aula_clustering_simplificada", "versao_estendida/aula_clustering")) {
  knitr::purl(paste0(aula, ".qmd"), output = paste0(aula, ".R"),
              documentation = 0, quiet = TRUE)
  status <- system2(quarto, c("render", paste0(aula, ".qmd")))
  if (status != 0) stop("quarto render falhou em ", aula)
}
