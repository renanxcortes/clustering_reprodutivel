# Gera os scripts das aulas e os HTMLs a partir dos .qmd (as únicas fontes):
#   aula_clustering.qmd              -> aula completa
#   aula_clustering_simplificada.qmd -> versão simplificada (só hierárquico)
# Rodar a partir da raiz do projeto:  Rscript tools/build.R
# Nunca edite os .R das aulas à mão: eles são sobrescritos aqui.

quarto <- Sys.which("quarto")
if (quarto == "") {
  quarto <- "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
}

for (aula in c("aula_clustering", "aula_clustering_simplificada")) {
  knitr::purl(paste0(aula, ".qmd"), output = paste0(aula, ".R"),
              documentation = 0, quiet = TRUE)
  status <- system2(quarto, c("render", paste0(aula, ".qmd")))
  if (status != 0) stop("quarto render falhou em ", aula)
}
