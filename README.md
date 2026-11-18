# Quem são os nossos clientes? — Segmentação de clientes com R

Material de uma aula prática, **100% guiada**, da disciplina **MAT02053 – Estatística Aplicada a Negócios (UFRGS)**. A aula foi pensada para alunos de graduação em Estatística que sabem **pouco ou nada de R**: eles rodam o código junto com o professor, bloco a bloco.

## O enredo

Somos a **equipe de dados de uma rede de varejo**. Hoje, toda campanha de marketing é enviada **igual para todos os clientes**. Queremos **segmentar** a base: dividir os clientes em grupos parecidos entre si e diferentes dos outros grupos, e entregar ao marketing uma **ficha por segmento**, com nome, perfil em linguagem de negócio, um cliente-exemplo e uma ação sugerida.

## O que os alunos aprendem

1. **Estatísticas descritivas** (ggplot2): renda, gasto total e por categoria, canais de compra, filhos, escolaridade e estado civil. Cada gráfico responde a uma pergunta de marketing e revela um problema dos dados.
2. **Preparação dos dados**: limpeza (renda ausente, renda extrema, anos de nascimento impossíveis, categorias sem sentido), variáveis derivadas, escolha das variáveis do agrupamento, **logaritmo** nos gastos e **padronização** (com um experimento que mostra por que ela é necessária).
3. **Três técnicas de agrupamento**, todas com as mesmas 15 variáveis, a mesma distância euclidiana e o mesmo *k*:
   - **cluster hierárquico** (ligação de Ward) e o dendrograma;
   - **k-means**, o papel do `nstart` e a escolha do *k* pelo cotovelo e pela silhueta;
   - **k-medoides (PAM)**, o medoide como "cliente-exemplo" e a robustez a outliers.
4. **Bônus (pode pular):** dados mistos e **distância de Gower**, com o hierárquico (ligação média) e o PAM, e por que o k-means não aceita Gower.
5. **Comparação das técnicas**: tabelas cruzadas (rótulos arbitrários) e silhueta média, e a escolha final pesando números e utilidade para o negócio.
6. **Resultados para o negócio**: PCA para visualizar, perfil dos segmentos, nomes dados por regra (e não pelo número do grupo), **fichas de segmento** e uma validação externa com a aceitação das campanhas (que não entraram no agrupamento).

## Os dados

`marketing_campaign.csv` é a base *Customer Personality Analysis*, do Kaggle ([imakash3011/customer-personality-analysis](https://www.kaggle.com/datasets/imakash3011/customer-personality-analysis)). A cópia usada aqui foi baixada do espelho público `https://raw.githubusercontent.com/LiaoliaoQJ/mkt/main/marketing_campaign%202.csv` (MD5 `3b624fc2bdbe29fa5fb01bdd577f78cd`). São **2.240 clientes** e **29 colunas**. Apesar da extensão `.csv`, o arquivo é **separado por TAB**, por isso o script usa `read_tsv()`. A moeda não é informada na fonte, então os valores aparecem como "unidades monetárias". O arquivo já está na pasta: **nada é baixado durante a aula**.

| Variável | Significado |
|---|---|
| `ID` | identificador do cliente |
| `Year_Birth` | ano de nascimento |
| `Education` | escolaridade (Basic, 2n Cycle, Graduation, Master, PhD) |
| `Marital_Status` | estado civil |
| `Income` | renda anual da família (24 valores ausentes) |
| `Kidhome`, `Teenhome` | número de crianças e de adolescentes em casa |
| `Dt_Customer` | data de cadastro como cliente |
| `Recency` | dias desde a última compra |
| `MntWines`, `MntFruits`, `MntMeatProducts`, `MntFishProducts`, `MntSweetProducts`, `MntGoldProds` | gasto nos últimos 2 anos com vinhos, frutas, carnes, peixes, doces e produtos "ouro" |
| `NumDealsPurchases` | compras feitas com desconto |
| `NumWebPurchases`, `NumCatalogPurchases`, `NumStorePurchases` | compras pelo site, pelo catálogo e na loja |
| `NumWebVisitsMonth` | visitas ao site no último mês |
| `AcceptedCmp1` a `AcceptedCmp5` | aceitou a 1ª, ..., 5ª campanha (1 = sim) |
| `Response` | aceitou a última campanha (1 = sim) |
| `Complain` | reclamou nos últimos 2 anos (1 = sim) |
| `Z_CostContact`, `Z_Revenue` | constantes (mesmo valor para todos); são descartadas |

As campanhas (`AcceptedCmp*`, `Response`) e `Complain` **não entram** no agrupamento: aparecem só na validação final.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `aula_clustering.R` | **Script da aula**, que os alunos rodam bloco a bloco (Ctrl + Enter). As seções aparecem no índice do RStudio |
| `aula_clustering.html` | **Material de estudo**: o mesmo código com explicações e gráficos. Abre em qualquer navegador |
| `aula_clustering.qmd` | **Fonte única** do material (Quarto). O `.R` e o `.html` são gerados a partir dele |
| `marketing_campaign.csv` | Os dados |
| `tools/build.R` | Gera o `.R` (via `knitr::purl`) e o `.html` (via Quarto) a partir do `.qmd` |
| `tests/test_aula.R` | Testes automáticos do material |

## Como rodar (alunos)

1. Abra o arquivo `clustering.Rproj` no RStudio. Se você baixou a pasta sem o `.Rproj`, use **Session > Set Working Directory > Choose Directory** e escolha a pasta `clustering`.
2. Abra `aula_clustering.R` e rode bloco a bloco.
3. O primeiro bloco de pacotes **instala automaticamente** os que estiverem faltando: tidyverse e cluster.

Requisitos: R ≥ 4.5. O script completo roda em alguns segundos.

> **Dicas para o professor:**
> - Rode o bloco de instalação de pacotes nos computadores do laboratório **antes da aula**. Instalar o tidyverse do zero pode demorar. Confira também, no console de cada máquina:
>   ```r
>   sapply(c("tidyverse", "cluster"), requireNamespace)   # tudo TRUE
>   packageVersion("tidyverse") >= "2.0.0"                # TRUE (dmy() e list_rbind() exigem tidyverse >= 2.0 / purrr >= 1.0)
>   ```
> - O bloco **6b (bônus: distância de Gower) pode ser pulado** se o tempo estiver curto. Nenhuma seção seguinte usa objetos criados nele. No script, ele vai da linha `# 6b. Bônus ...` até `# ---- fim do bônus 6b ----`.
> - Se o tempo apertar, outros trechos que dá para pular ou só comentar rapidamente (além do 6b): o "Um mínimo de R para começar" (seção 1), o histograma do `log1p`, a tabela de centroides e o exemplo de `dist` com 3 clientes.

## Como editar o material (professor)

O `.qmd` é a fonte. **Não edite `aula_clustering.R` à mão**, porque ele é sobrescrito pelo build. Depois de alterar o `.qmd`, rode a partir desta pasta:

```bash
Rscript tools/build.R                              # gera aula_clustering.R e aula_clustering.html
Rscript -e 'testthat::test_file("tests/test_aula.R")'  # roda os testes
```

O build usa o Quarto do PATH. Se ele não estiver no PATH, usa o Quarto que vem com o RStudio.

Os testes verificam, entre outras coisas:
- a leitura dos dados (2.240 × 29, MD5 do arquivo) e a mensagem de erro quando o aluno está na pasta errada;
- a limpeza e a preparação, incluindo que as campanhas não entram no agrupamento;
- as três técnicas e o bônus de Gower;
- que a aula funciona **pulando o bônus 6b**;
- que os nomes dos segmentos seguem o perfil (e não o número do grupo) e que as frases das fichas batem com o perfil;
- a reprodutibilidade, ou seja, que duas execuções dão grupos e silhuetas idênticos;
- que o script roda em menos de 2 minutos;
- que o `.R` está sincronizado com o `.qmd` e tem as seções navegáveis.

Atenção: os textos do `.qmd` citam os números impressos (tamanhos dos grupos, silhuetas, perfis). Se mudar os dados, as variáveis ou a técnica, **revise esses textos e as frases das fichas**.

## Principais resultados

- **k = 3.** O dendrograma e o cotovelo da WSS apontam 3 grupos. A silhueta do k-means prefere k = 2 (0,318 contra 0,242), e a aula mostra essa divergência abertamente: 3 segmentos são mais úteis para o marketing.
- **Técnica final: PAM.** As silhuetas médias (mesma distância euclidiana) são **0,217** no hierárquico, **0,242** no k-means e **0,230** no PAM. O k-means tem a melhor silhueta, mas a diferença é pequena e as duas técnicas colocam 94% dos clientes nos mesmos grupos. O PAM foi escolhido por entregar um cliente real (o medoide) como exemplo de cada segmento.
- **Três segmentos**, nomeados em ordem crescente de gasto:
  - **Econômico** (822 clientes): renda mais baixa, gasto muito baixo, crianças pequenas em casa, visita muito o site mas compra pouco; 4% do gasto total.
  - **Caçador de ofertas** (664): renda intermediária, o que mais compra com desconto e pelo site, adolescentes em casa; 28% do gasto.
  - **Premium** (726): maior renda e maior gasto (vinhos e carnes), a maioria sem filhos, compra na loja e pelo catálogo; 68% do gasto.
- **Validação externa:** a aceitação da última campanha cresce com o gasto: **8,5%** (Econômico), **13,9%** (Caçador de ofertas) e **23,6%** (Premium). É uma associação esperada, não o efeito da campanha.
- A PCA usada para visualizar guarda **57,8%** da variação nos 2 primeiros componentes.

Os números exatos podem variar levemente com versões diferentes dos pacotes.
