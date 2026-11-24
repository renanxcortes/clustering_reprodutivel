# 1. Problema de negócio e setup ----

# AULA: Quem são os nossos clientes? (MAT02053 - UFRGS)
# Somos a equipe de dados de uma rede de varejo e vamos segmentar os clientes
# para personalizar as campanhas. Rode o script bloco a bloco (Ctrl + Enter).
# Este arquivo é gerado a partir de aula_clustering.qmd (veja o HTML com as explicações).

# Criando um objeto chamado "gastos" com quatro valores
gastos <- c(100, 250, 300, 150)

# Aplicando uma função ao objeto: a média dos gastos
mean(gastos)

# O mesmo cálculo usando o pipe: "pegue gastos E ENTÃO calcule a média"
gastos |> mean()

# Pipes podem ser encadeados: média e então arredondamento com 1 casa
gastos |> mean() |> round(1)

# Lista de pacotes usados na aula
pacotes <- c("tidyverse",   # manipulação (dplyr), leitura (readr) e gráficos (ggplot2)
             "cluster")     # daisy() (distância de Gower)

# Quais ainda não estão instalados?
faltando <- pacotes[!sapply(pacotes, requireNamespace, quietly = TRUE)]

# Instala só os que faltam (se não faltar nenhum, não faz nada)
if (length(faltando) > 0) install.packages(faltando)

# Carrega os pacotes
library(tidyverse)
library(cluster)

# Conferindo se estamos na pasta certa antes de ler os dados
if (!file.exists("marketing_campaign.csv")) {
  stop("Não encontrei o arquivo marketing_campaign.csv. ",
       "Feche o RStudio e abra o arquivo clustering.Rproj ",
       "(ou use o menu Session > Set Working Directory > Choose Directory ",
       "e escolha a pasta clustering).")
}

# read_tsv() lê arquivos separados por TAB
clientes_raw <- read_tsv("marketing_campaign.csv")

# Primeira olhada: quantas linhas e colunas, e o tipo de cada coluna
glimpse(clientes_raw)

# 2. Estatísticas descritivas ----

# Selecionando algumas colunas-chave e pedindo o resumo estatístico de cada uma
clientes_raw |>
  select(Year_Birth, Income, Kidhome, Teenhome, Recency, MntWines, NumStorePurchases) |>
  summary()

# Histograma da renda: cada barra conta quantos clientes caem numa faixa de renda
clientes_raw |>
  ggplot(aes(x = Income)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white", na.rm = TRUE) +
  labs(x = "Renda anual (unidades monetárias)", y = "Número de clientes")

# Gasto total = soma das seis colunas de valor gasto (as que começam com "Mnt")
gasto_total_tmp <- clientes_raw |>
  mutate(gasto_total = MntWines + MntFruits + MntMeatProducts +
           MntFishProducts + MntSweetProducts + MntGoldProds)

# Histograma do gasto total
gasto_total_tmp |>
  ggplot(aes(x = gasto_total)) +
  geom_histogram(bins = 40, fill = "darkorange", color = "white") +
  labs(x = "Gasto total (unidades monetárias)", y = "Número de clientes")

# Comparando mediana e média do gasto total
gasto_total_tmp |>
  summarise(mediana = median(gasto_total), media = mean(gasto_total))

# Gasto médio de cada categoria, em formato "longo" (uma linha por cliente e categoria)
gasto_categoria <- clientes_raw |>
  select(starts_with("Mnt")) |>                         # só as seis colunas de gasto
  pivot_longer(everything(),                            # empilha todas as colunas
               names_to = "categoria", values_to = "gasto") |>
  group_by(categoria) |>                                # um grupo por categoria
  summarise(gasto_medio = mean(gasto))                  # média por categoria

# Gráfico de barras, ordenado do menor para o maior gasto médio
gasto_categoria |>
  ggplot(aes(x = reorder(categoria, gasto_medio), y = gasto_medio)) +
  geom_col(fill = "steelblue") +
  coord_flip() +                                        # barras na horizontal
  labs(x = "Categoria", y = "Gasto médio por cliente (unidades monetárias)")

# A mesma informação em números
gasto_categoria |> arrange(desc(gasto_medio))

# Média de compras em cada canal (NumDealsPurchases = compras feitas com desconto)
compras_canal <- clientes_raw |>
  select(NumStorePurchases, NumWebPurchases, NumCatalogPurchases, NumDealsPurchases) |>
  pivot_longer(everything(), names_to = "canal", values_to = "compras") |>
  group_by(canal) |>
  summarise(compras_medias = mean(compras))

# Gráfico de barras com a média de compras por canal
compras_canal |>
  ggplot(aes(x = reorder(canal, compras_medias), y = compras_medias)) +
  geom_col(fill = "darkgreen") +
  coord_flip() +
  labs(x = "Canal", y = "Número médio de compras por cliente")

# A mesma informação em números
compras_canal |> arrange(desc(compras_medias))

# Total de filhos em casa (crianças + adolescentes)
filhos_tmp <- clientes_raw |>
  mutate(filhos = Kidhome + Teenhome)

# Gráfico de barras do número de filhos
filhos_tmp |>
  ggplot(aes(x = factor(filhos))) +
  geom_bar(fill = "purple4") +
  labs(x = "Filhos em casa", y = "Número de clientes")

# Em números
filhos_tmp |> count(filhos)

# Gráfico de barras do nível de escolaridade (Education), ordenado pela frequência
clientes_raw |>
  ggplot(aes(x = reorder(Education, Education, length))) +
  geom_bar(fill = "firebrick") +
  coord_flip() +
  labs(x = "Escolaridade", y = "Número de clientes")

# Em números
clientes_raw |> count(Education, sort = TRUE)

# Contagem de clientes por estado civil, do mais ao menos frequente
clientes_raw |> count(Marital_Status, sort = TRUE)

# 3. Preparação dos dados ----

# Quantos clientes temos antes da limpeza?
nrow(clientes_raw)

# Passo 1: removendo quem não tem renda informada (NA)
passo1 <- clientes_raw |>
  filter(!is.na(Income))
nrow(passo1)                    # quantos sobraram?

# Passo 2: removendo a renda extrema (acima de 200.000)
passo2 <- passo1 |>
  filter(Income <= 200000)
nrow(passo2)

# Passo 3: removendo anos de nascimento impossíveis (antes de 1920)
passo3 <- passo2 |>
  filter(Year_Birth >= 1920)
nrow(passo3)

# Aplicando todas as regras de limpeza de uma vez, na mesma sequência dos passos acima
clientes <- clientes_raw |>
  filter(!is.na(Income),            # passo 1: renda informada
         Income <= 200000,          # passo 2: sem renda extrema
         Year_Birth >= 1920) |>     # passo 3: ano de nascimento plausível
  # Agrupando o estado civil em duas categorias
  # (x %in% c(...) pergunta "x é um destes valores?" e responde TRUE ou FALSE)
  mutate(Marital_Status = if_else(Marital_Status %in% c("Married", "Together"),
                                  "Casado/Junto", "Sozinho")) |>
  # Removendo as colunas constantes
  select(-Z_CostContact, -Z_Revenue) |>
  # Criando as variáveis derivadas
  mutate(Idade = 2014 - Year_Birth,
         Filhos = Kidhome + Teenhome,
         Gasto_total = MntWines + MntFruits + MntMeatProducts +
           MntFishProducts + MntSweetProducts + MntGoldProds,
         Compras_total = NumWebPurchases + NumCatalogPurchases + NumStorePurchases,
         # dmy() transforma o texto "dia-mês-ano" em data; a diferença entre datas é em dias
         Tempo_casa_dias = as.numeric(as.Date("2014-06-29") - dmy(Dt_Customer)))

# Conferindo: quantos clientes temos agora?
nrow(clientes)

# Como ficaram o estado civil e as novas variáveis?
clientes |> count(Marital_Status)
clientes |>
  select(Idade, Filhos, Gasto_total, Compras_total, Tempo_casa_dias) |>
  summary()

# Variáveis que entram no agrupamento (somente comportamento e perfil)
vars_cluster <- c("Income", "Idade", "Filhos", "Recency",
                  "MntWines", "MntFruits", "MntMeatProducts",
                  "MntFishProducts", "MntSweetProducts", "MntGoldProds",
                  "NumDealsPurchases", "NumWebPurchases", "NumCatalogPurchases",
                  "NumStorePurchases", "NumWebVisitsMonth")

# Quantas variáveis?
length(vars_cluster)

# Colocando o gasto original e o gasto em log lado a lado, para comparar
vinhos <- tibble(`Original` = clientes$MntWines,
                 `Com log1p` = log1p(clientes$MntWines)) |>
  pivot_longer(everything(), names_to = "escala", values_to = "valor") |>
  # fixando a ordem dos painéis: original primeiro
  mutate(escala = factor(escala, levels = c("Original", "Com log1p")))

# Dois histogramas, um por escala (cada painel tem seu próprio eixo x)
vinhos |>
  ggplot(aes(x = valor)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  facet_wrap(~ escala, scales = "free_x") +
  labs(x = "Gasto com vinhos", y = "Número de clientes")

# Média e mediana nas duas escalas
tibble(escala = c("Original", "Com log1p"),
       media = c(mean(clientes$MntWines), mean(log1p(clientes$MntWines))),
       mediana = c(median(clientes$MntWines), median(log1p(clientes$MntWines))))

# Tabela só com as variáveis do agrupamento; log1p() nas seis colunas que começam com "Mnt"
dados_cluster <- clientes[vars_cluster] |>
  mutate(across(starts_with("Mnt"), log1p))

# Conferindo: uma linha por cliente, 15 colunas, nenhum NA
dim(dados_cluster)
anyNA(dados_cluster)

# Desvio-padrão de cada variável, em ordem decrescente
sapply(dados_cluster, sd) |>
  round(2) |>
  sort(decreasing = TRUE)

# Padronizando: scale() subtrai a média e divide pelo desvio-padrão de cada coluna.
# Depois disso, cada variável tem média 0 e desvio-padrão 1 (guardamos o resultado em dados_pad)
dados_pad <- scale(dados_cluster)

# Função que acha os 3 vizinhos mais próximos do cliente 1 em uma matriz de dados
tres_vizinhos <- function(m) {
  # Diferença de cada cliente para o cliente 1, variável por variável
  dif <- sweep(m, 2, m[1, ])
  # Distância = raiz da soma dos quadrados das diferenças
  distancia <- sqrt(rowSums(dif^2))
  # Posições dos 3 mais próximos (a posição 1 é o próprio cliente, com distância 0)
  viz <- order(distancia)[2:4]
  # Tabela: quem são, quão longe estão e quanto da distância vem de Income
  tibble(vizinho = viz,
         distancia = round(distancia[viz], 2),
         pct_income = round(100 * dif[viz, "Income"]^2 / rowSums(dif[viz, ]^2), 1)) |>
    bind_cols(clientes[viz, c("Income", "Idade", "Filhos", "Gasto_total")])
}

# O cliente 1 (a referência)
clientes[1, c("Income", "Idade", "Filhos", "Gasto_total")]

# Vizinhos SEM padronizar
tres_vizinhos(as.matrix(dados_cluster))

# Vizinhos COM padronização
tres_vizinhos(dados_pad)

# Conferindo: toda coluna deve ter média 0 (arredondada) e desvio-padrão 1
round(colMeans(dados_pad), 4)
apply(dados_pad, 2, sd)

# Dimensão final da matriz que usaremos nas próximas seções
dim(dados_pad)

# 4. Cluster hierárquico ----

# Exemplo de brinquedo: 6 clientes com 2 variáveis (renda e gasto, de 0 a 10)
exemplo <- tibble(
  nome  = c("Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio"),
  renda = c(2, 3, 3, 6, 8, 9),
  gasto = c(2, 2, 4, 5, 8, 7)
)
exemplo

# Matriz só com as duas variáveis, com o nome de cada cliente nas linhas
m_exemplo <- as.matrix(exemplo[, c("renda", "gasto")])
rownames(m_exemplo) <- exemplo$nome

# Matriz de distâncias dos 6 clientes (arredondada em 1 casa)
dist_exemplo <- dist(m_exemplo)
round(dist_exemplo, 1)

# Matriz de distâncias de apenas 3 clientes (as 3 primeiras linhas de dados_pad)
dist(dados_pad[1:3, ]) |> round(2)

# Conferindo à mão a distância entre o cliente 1 e o cliente 2:
# diferença em cada variável, ao quadrado, somada, e a raiz
sqrt(sum((dados_pad[1, ] - dados_pad[2, ])^2)) |> round(2)

# Matriz de distâncias euclidianas entre TODOS os pares de clientes
dist_euc <- dist(dados_pad)

# Quantas distâncias foram calculadas? (um número para cada par de clientes)
length(dist_euc)

# As quatro regras de ligação aplicadas aos 6 clientes
hc_exemplo <- list(
  single   = hclust(dist_exemplo, method = "single"),
  complete = hclust(dist_exemplo, method = "complete"),
  average  = hclust(dist_exemplo, method = "average"),
  ward     = hclust(dist_exemplo, method = "ward.D2")
)

# Os quatro dendrogramas na mesma janela (dividida em 2 linhas e 2 colunas)
par(mfrow = c(2, 2))
plot(hc_exemplo$single,   main = "single",   xlab = "", sub = "", ylab = "Altura da fusão")
plot(hc_exemplo$complete, main = "complete", xlab = "", sub = "", ylab = "Altura da fusão")
plot(hc_exemplo$average,  main = "average",  xlab = "", sub = "", ylab = "Altura da fusão")
plot(hc_exemplo$ward,     main = "Ward",     xlab = "", sub = "", ylab = "Altura da fusão")
par(mfrow = c(1, 1))   # volta a janela gráfica ao normal

# As três ligações "intuitivas" na base real
hc_single   <- hclust(dist_euc, method = "single")
hc_complete <- hclust(dist_euc, method = "complete")
hc_average  <- hclust(dist_euc, method = "average")

# Tamanhos dos grupos quando cortamos cada árvore em 3 grupos
table(cutree(hc_single, k = 3))
table(cutree(hc_complete, k = 3))
table(cutree(hc_average, k = 3))

# Clustering hierárquico com a ligação de Ward, a partir da matriz de distâncias
hc_ward <- hclust(dist_euc, method = "ward.D2")

# O resultado guarda a sequência de fusões; conferindo o método usado
hc_ward$method

# Desenhando o dendrograma sem os rótulos dos clientes (labels = FALSE)
# hang = -1 alinha todos os clientes na base do gráfico
plot(hc_ward, labels = FALSE, hang = -1,
     main = "Dendrograma (Ward)", xlab = "Clientes", sub = "",
     ylab = "Altura da fusão")

# Alturas das 6 últimas fusões, da mais alta (a última, que junta tudo) para a mais baixa
rev(tail(hc_ward$height, 6)) |> round(1)

# Número de grupos (k): sugerido pelo dendrograma
k_escolhido <- 3L

# Cortando a árvore em k grupos: um número de grupo (1, 2, 3...) para cada cliente
grupos_hc <- cutree(hc_ward, k = k_escolhido)

# Quantos clientes em cada grupo?
table(grupos_hc)

# O mesmo dendrograma, com retângulos marcando os k grupos
plot(hc_ward, labels = FALSE, hang = -1,
     main = "Dendrograma (Ward) cortado em 3 grupos", xlab = "Clientes", sub = "",
     ylab = "Altura da fusão")
rect.hclust(hc_ward, k = k_escolhido, border = c("firebrick", "steelblue", "darkgreen"))

# 5. Hierárquico com dados mistos: distância de Gower ----

# Dados mistos: as 15 numéricas (já com log1p nos gastos) + 2 categóricas como factor
dados_gower <- dados_cluster |>
  mutate(Education = factor(clientes$Education),
         Marital_Status = factor(clientes$Marital_Status))

# Conferindo o tipo de cada coluna: "numeric" ou "factor"
sapply(dados_gower, class)

# Matriz de dissimilaridades de Gower entre todos os pares de clientes
# (não usamos scale(): a Gower divide cada diferença pela amplitude da variável)
dist_gower <- daisy(dados_gower, metric = "gower")

# "mixed" = a daisy reconheceu que há variáveis numéricas e categóricas
attr(dist_gower, "Metric")

# Resumo das dissimilaridades: todas entre 0 e 1
summary(as.vector(dist_gower))

# Os dois clientes que vamos comparar
# (as.data.frame() mostra todas as colunas e mantém os números das linhas da base: 1 e 3)
as.data.frame(dados_gower)[c(1, 3), ]

# Amplitude (maior valor - menor valor) de cada variável numérica
# (\(x) é um atalho do R para function(x): uma função pequena, escrita ali mesmo)
amplitude <- sapply(dados_gower[vars_cluster], \(x) max(x) - min(x))

# Parcela de cada numérica: |diferença| / amplitude (sempre entre 0 e 1)
# (unlist() transforma a linha da tabela num vetor simples de números, para fazer a conta)
parcela_num <- abs(unlist(dados_gower[1, vars_cluster]) -
                   unlist(dados_gower[3, vars_cluster])) / amplitude

# Parcela de cada categórica: 0 se a categoria é a mesma, 1 se é diferente
parcela_cat <- c(
  Education = as.numeric(dados_gower$Education[1] != dados_gower$Education[3]),
  Marital_Status = as.numeric(dados_gower$Marital_Status[1] != dados_gower$Marital_Status[3]))

# As 17 parcelas, arredondadas
round(c(parcela_num, parcela_cat), 3)

# Gower = média das 17 parcelas
mean(c(parcela_num, parcela_cat))

# O valor calculado pela daisy() para o mesmo par (linha 1, coluna 3)
as.matrix(dist_gower)[1, 3]

# Hierárquico com a matriz de Gower: ligação média (average) e completa (complete)
hc_gower_average  <- hclust(dist_gower, method = "average")
hc_gower_complete <- hclust(dist_gower, method = "complete")

# Tamanhos dos grupos quando cortamos cada árvore em 3 grupos
table(cutree(hc_gower_average, k = 3))
table(cutree(hc_gower_complete, k = 3))

# Cortando a árvore da complete (Gower) em 2 grupos
grupos_gower <- cutree(hc_gower_complete, k = 2)

# Tabela cruzada: grupos da Gower (linhas) × grupos do Ward euclidiano (colunas)
table(gower = grupos_gower, ward = grupos_hc)

# Ward euclidiano: gasto total médio de cada grupo (para saber quem gasta mais)
tapply(clientes$Gasto_total, grupos_hc, mean) |> round()

# Estado civil dentro de cada grupo da Gower
table(gower = grupos_gower, estado_civil = clientes$Marital_Status)

# Cortando a mesma árvore em 4 grupos: estado civil em cada grupo
table(gower_4 = cutree(hc_gower_complete, k = 4), estado_civil = clientes$Marital_Status)

# 6. Resultados para o negócio ----

# Os grupos que vão para o marketing: os do Ward euclidiano (seção 4)
grupos_final <- grupos_hc

# Conferindo: tamanho de cada grupo
table(grupos_final)

# PCA nos dados padronizados (as mesmas 15 variáveis do agrupamento)
pca <- prcomp(dados_pad)

# Variância explicada pelos 4 primeiros componentes:
# "Proportion of Variance" = de cada componente; "Cumulative Proportion" = acumulada
summary(pca)$importance[, 1:4] |> round(3)

# Peso de cada variável nos 2 primeiros componentes (ajuda a "ler" os eixos)
round(pca$rotation[, 1:2], 2)

# Nomes dos segmentos, do MENOR para o MAIOR gasto total médio (a regra é explicada na próxima seção)
nomes_segmentos <- c("Econômico", "Caçador de ofertas", "Premium")

# Gasto total médio de cada grupo do Ward; rank() dá a posição do grupo (1 = menor gasto)
gasto_medio_grupo <- tapply(clientes$Gasto_total, grupos_final, mean)
segmento_pca <- nomes_segmentos[rank(gasto_medio_grupo)[grupos_final]]

# Coordenadas de cada cliente nos 2 primeiros componentes, mais o nome do segmento
# (o 1º componente é multiplicado por -1 só para a direita significar "gasta mais")
pontos_pca <- tibble(CP1 = -pca$x[, "PC1"],
                     CP2 = pca$x[, "PC2"],
                     segmento = factor(segmento_pca, levels = nomes_segmentos))

# Gráfico de dispersão: um ponto por cliente, cor = segmento
pontos_pca |>
  ggplot(aes(x = CP1, y = CP2, color = segmento)) +
  geom_point(alpha = 0.5, size = 1.2) +
  labs(x = "1º componente (45,7%): quanto o cliente gasta",
       y = "2º componente (12,1%): desconto, internet e filhos",
       color = "Segmento")

# Perfil de cada grupo nas variáveis originais (médias; "_medio" no nome da coluna)
perfil_segmentos <- clientes |>
  mutate(grupo = grupos_final) |>
  group_by(grupo) |>
  summarise(n = n(),
            # across(): aplica a média a várias colunas de uma vez
            across(c(Income, Idade, Filhos, Kidhome, Teenhome, Recency,
                     Gasto_total, Compras_total, MntWines, MntMeatProducts,
                     NumDealsPurchases, NumWebPurchases, NumCatalogPurchases,
                     NumStorePurchases, NumWebVisitsMonth, Tempo_casa_dias),
                   mean, .names = "{.col}_medio"),
            Gasto_total_mediano = median(Gasto_total),
            # proporção de clientes sem filhos em casa
            Sem_filhos_prop = mean(Filhos == 0),
            # quanto (%) do gasto de TODA a base vem deste grupo
            Receita_pct = 100 * sum(Gasto_total) / sum(clientes$Gasto_total))

# Nomes dos segmentos, do MENOR para o MAIOR gasto total médio
nomes_segmentos <- c("Econômico", "Caçador de ofertas", "Premium")

# Regra: ordenar os grupos pelo gasto total médio e dar os nomes nessa ordem
# (o nome depende do perfil, e não do número que a técnica deu ao grupo)
perfil_segmentos <- perfil_segmentos |>
  arrange(Gasto_total_medio) |>
  mutate(segmento = factor(nomes_segmentos, levels = nomes_segmentos), .before = 1)

# Base de clientes com o nome do segmento de cada um
clientes_seg <- clientes |>
  mutate(grupo = grupos_final) |>
  left_join(perfil_segmentos |> select(grupo, segmento), by = "grupo")

# Quantos clientes em cada segmento?
clientes_seg |> count(segmento)

# O perfil "deitado": uma linha por variável e uma coluna por segmento (mais fácil de ler)
perfil_segmentos |>
  select(-grupo) |>
  pivot_longer(-segmento, names_to = "variavel", values_to = "valor") |>
  mutate(valor = round(valor, 2)) |>
  pivot_wider(names_from = segmento, values_from = valor) |>
  as.data.frame()

# Médias das variáveis padronizadas (dados_pad) dentro de cada segmento
medias_pad <- as_tibble(dados_pad) |>
  mutate(segmento = clientes_seg$segmento) |>
  group_by(segmento) |>
  summarise(across(everything(), mean)) |>
  # formato longo: uma linha por segmento e variável
  pivot_longer(-segmento, names_to = "variavel", values_to = "media_padronizada")

# Mapa de calor: cor = média padronizada; o número dentro de cada casa é o valor
medias_pad |>
  ggplot(aes(x = segmento, y = variavel, fill = media_padronizada)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(media_padronizada, 1)), size = 3) +
  # vermelho = abaixo da média, branco = na média, azul = acima da média
  scale_fill_gradient2(low = "firebrick", mid = "white", high = "steelblue", midpoint = 0) +
  labs(x = "Segmento", y = NULL, fill = "Média\npadronizada")

# Função auxiliar: número no formato brasileiro (ponto no milhar, vírgula decimal)
fmt <- function(x, casas = 0) {
  formatC(x, format = "f", digits = casas, big.mark = ".", decimal.mark = ",")
}

# Atalho para não repetir "perfil_segmentos$" (as linhas estão em ordem crescente de gasto)
p <- perfil_segmentos

# Resumo em palavras de cada segmento, na ordem: Econômico, Caçador de ofertas, Premium
resumos <- c(
  "Renda mais baixa e gasto muito baixo; famílias com crianças pequenas; visita bastante o site, mas compra pouco.",
  "Renda intermediária; o grupo que mais compra com desconto; compra bastante pelo site; famílias com adolescentes.",
  "Renda alta e o maior gasto, puxado por vinhos e carnes; a maioria sem filhos em casa; compra na loja e pelo catálogo e usa pouco desconto.")

# Ação de marketing sugerida para cada segmento, na mesma ordem
acoes <- c(
  "Canais baratos (e-mail, site): ofertas de entrada em itens básicos e infantis e um cupom para a primeira compra online, para transformar as muitas visitas ao site em compras. Evitar catálogo impresso, caro para quem gasta pouco.",
  "Promoções e programa de pontos: combos para a família (vinho + carne) com desconto progressivo e ofertas relâmpago no site. Objetivo: aumentar o valor de cada compra sem depender só de desconto.",
  "Relacionamento e exclusividade, não desconto: catálogo de vinhos e carnes selecionados, pré-lançamentos e degustações na loja. Objetivo: reter estes clientes, que geram a maior parte da receita.")

# As fichas: segmento, perfil (resumo + números do perfil real) e ação
# (sprintf() encaixa cada número, na ordem, no lugar de um %s do texto; %% vira o símbolo %)
fichas <- tibble(
  segmento = p$segmento,
  perfil = paste(resumos,
                 sprintf("%s clientes (%s%% do gasto total); renda média de %s; gasto médio de %s em 2 anos, em %s compras; %s filho(s) em casa; %s compras com desconto; %s visitas ao site por mês.",
                         fmt(p$n), fmt(p$Receita_pct), fmt(p$Income_medio),
                         fmt(p$Gasto_total_medio), fmt(p$Compras_total_medio, 1),
                         fmt(p$Filhos_medio, 2), fmt(p$NumDealsPurchases_medio, 1),
                         fmt(p$NumWebVisitsMonth_medio, 1))),
  acao = acoes)

# Mostrando cada ficha (strwrap quebra o texto longo em linhas de até 80 caracteres)
for (i in seq_len(nrow(fichas))) {
  cat("==== Segmento:", as.character(fichas$segmento[i]), "====\n")
  cat("PERFIL:", strwrap(fichas$perfil[i], 80), sep = "\n")
  cat("AÇÃO:", strwrap(fichas$acao[i], 80), sep = "\n")
  cat("\n")
}

# Para cada segmento: a linha da base do cliente mais perto do perfil médio do segmento
posicao_exemplo <- sapply(levels(clientes_seg$segmento), function(s) {
  linhas <- which(clientes_seg$segmento == s)        # clientes deste segmento
  media <- colMeans(dados_pad[linhas, ])             # perfil médio (variáveis padronizadas)
  dif <- sweep(dados_pad[linhas, ], 2, media)        # diferença de cada cliente até a média
  linhas[which.min(sqrt(rowSums(dif^2)))]            # o cliente com a menor distância
})

# Os clientes-exemplo, com algumas variáveis fáceis de interpretar
clientes_exemplo <- clientes_seg[posicao_exemplo, ] |>
  select(segmento, ID, Income, Idade, Filhos, Gasto_total, Compras_total,
         NumDealsPurchases, NumWebPurchases, NumWebVisitsMonth)
as.data.frame(clientes_exemplo)

# Taxas de aceite de campanhas em cada segmento
# Response = aceitou a última campanha (0 ou 1); a média de 0/1 é a proporção de "sim"
resposta_por_segmento <- clientes_seg |>
  group_by(segmento) |>
  summarise(n = n(),
            taxa_resposta = mean(Response),
            # aceitou ALGUMA das 6 campanhas (as 5 anteriores ou a última)?
            taxa_alguma_campanha = mean(AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 +
                                          AcceptedCmp4 + AcceptedCmp5 + Response > 0))
resposta_por_segmento

# Para comparar: taxa de resposta na base inteira
mean(clientes_seg$Response)

# Gráfico de barras com as duas taxas lado a lado, por segmento
resposta_por_segmento |>
  pivot_longer(c(taxa_resposta, taxa_alguma_campanha),
               names_to = "medida", values_to = "taxa") |>
  mutate(medida = if_else(medida == "taxa_resposta",
                          "Aceitou a última campanha", "Aceitou alguma campanha")) |>
  ggplot(aes(x = segmento, y = taxa, fill = medida)) +
  geom_col(position = "dodge") +
  # eixo y em porcentagem (scales vem junto com o tidyverse)
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Segmento", y = "Proporção de clientes", fill = NULL)
