# Gera o script da aula e o HTML a partir de aula_clustering.qmd (a única fonte).
# Rodar a partir da raiz do projeto:  Rscript tools/build.R
# Nunca edite aula_clustering.R à mão: ele é sobrescrito aqui.

knitr::purl("aula_clustering.qmd", output = "aula_clustering.R",
            documentation = 0, quiet = TRUE)

quarto <- Sys.which("quarto")
if (quarto == "") {
  quarto <- "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
}
status <- system2(quarto, c("render", "aula_clustering.qmd"))
if (status != 0) stop("quarto render falhou")
