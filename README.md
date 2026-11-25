# Quem são os nossos clientes? — Segmentação de clientes com R

Material de uma aula prática, **100% guiada**, da disciplina **MAT02053 – Estatística Aplicada a Negócios (UFRGS)**. A aula foi pensada para alunos de graduação em Estatística que sabem **pouco ou nada de R**: eles rodam o código junto com o professor, bloco a bloco.

O repositório tem **duas versões** da aula:

- **`aula_clustering_simplificada`** (na raiz): a aula principal. Usa só o **cluster hierárquico**, com a distância euclidiana e a distância de Gower.
- **`versao_estendida/aula_clustering`**: a versão estendida, que acrescenta **k-means**, **k-medoides (PAM)**, silhueta e a comparação das técnicas. Veja [Versão estendida](#versão-estendida).

## O enredo

Somos a **equipe de dados de uma rede de varejo**. Hoje, toda campanha de marketing é enviada **igual para todos os clientes**. Queremos **segmentar** a base: dividir os clientes em grupos parecidos entre si e diferentes dos outros grupos, e entregar ao marketing uma **ficha por segmento**, com nome, perfil em linguagem de negócio, um cliente-exemplo e uma ação sugerida.

## O que os alunos aprendem (aula principal)

1. **Estatísticas descritivas** (ggplot2): renda, gasto total e por categoria, canais de compra, filhos, escolaridade e estado civil. Cada gráfico responde a uma pergunta de marketing e revela um problema dos dados.
2. **Preparação dos dados**: limpeza (renda ausente, renda extrema, anos de nascimento impossíveis, categorias sem sentido), variáveis derivadas, escolha das variáveis do agrupamento, **logaritmo** nos gastos e **padronização** (com um experimento que mostra por que ela é necessária).
3. **Cluster hierárquico** com a distância euclidiana: a matriz de distâncias e as ligações **single, complete, average e Ward** num exemplo de 6 clientes (com figuras de "bonequinhos"), por que as três primeiras falham nesta base, a **ligação de Ward**, o dendrograma e a escolha do *k* pelas alturas das fusões.
4. **Dados mistos e distância de Gower**: a conta à mão com as categóricas e o hierárquico com as ligações average e complete. A régua muda, mas a estrutura principal (a divisão por gasto) se mantém.
5. **Resultados para o negócio**: PCA para visualizar, perfil dos segmentos, nomes dados por regra (e não pelo número do grupo), **fichas de segmento**, o cliente mais parecido com o perfil médio de cada segmento e uma validação externa com a aceitação das campanhas (que não entraram no agrupamento).

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
| `aula_clustering_simplificada.R` | **Script da aula principal**, que os alunos rodam bloco a bloco (Ctrl + Enter). As seções aparecem no índice do RStudio |
| `aula_clustering_simplificada.html` | **Material de estudo**: o mesmo código com explicações e gráficos. Abre em qualquer navegador |
| `aula_clustering_simplificada.qmd` | **Fonte única** da aula principal (Quarto). O `.R` e o `.html` são gerados a partir dele |
| `versao_estendida/` | A **versão estendida** (`aula_clustering.R`, `.html` e `.qmd`), com k-means e PAM |
| `marketing_campaign.csv` | Os dados (usados pelas duas versões) |
| `figuras/` | Figuras das aulas (bonequinhos, ligações, GIF do k-means), já prontas |
| `tools/build.R` | Gera o `.R` (via `knitr::purl`) e o `.html` (via Quarto) de cada aula a partir do seu `.qmd` |
| `tools/figuras.R` | Gera as figuras e o GIF de `figuras/` (rodar só quando mudar alguma figura) |
| `tools/exemplo.R`, `tools/kmeans_passos.R` | Dados de exemplo e k-means passo a passo, usados pelo `figuras.R` |
| `tests/test_aula_simplificada.R`, `tests/test_aula.R`, `tests/test_figuras.R` | Testes automáticos da aula principal, da versão estendida e das figuras |

## Como rodar (alunos)

1. Abra o arquivo `clustering.Rproj` no RStudio. Se você baixou a pasta sem o `.Rproj`, use **Session > Set Working Directory > Choose Directory** e escolha a pasta `clustering`.
2. Abra `aula_clustering_simplificada.R` e rode bloco a bloco.
3. O primeiro bloco de pacotes **instala automaticamente** os que estiverem faltando: tidyverse e cluster.

Requisitos: R ≥ 4.5. O script completo roda em alguns segundos.

> **Dicas para o professor:**
> - Rode o bloco de instalação de pacotes nos computadores do laboratório **antes da aula**. Instalar o tidyverse do zero pode demorar. Confira também, no console de cada máquina:
>   ```r
>   sapply(c("tidyverse", "cluster"), requireNamespace)   # tudo TRUE
>   packageVersion("tidyverse") >= "2.0.0"                # TRUE (dmy() e list_rbind() exigem tidyverse >= 2.0 / purrr >= 1.0)
>   ```
> - Se o tempo apertar, trechos que dá para pular ou só comentar rapidamente: o "Um mínimo de R para começar" (seção 1), o histograma do `log1p` e o exemplo de `dist` com 3 clientes. Na seção 4, os blocos do exemplo de 6 clientes (a matriz e os 4 dendrogramas) e o "E na base real?" podem ser só mostrados e comentados com as figuras.

## Resultados da aula principal

- **k = 3.** As alturas das últimas fusões do Ward (147,4, 82,5, 42,2...) apontam 2 ou 3 grupos. A aula fica com 3, que são mais úteis para o marketing, e mostra essa escolha abertamente.
- **Três segmentos** (Ward euclidiano), nomeados em ordem crescente de gasto:
  - **Econômico** (838 clientes): renda mais baixa, gasto muito baixo, crianças pequenas em casa, visita muito o site mas compra pouco; 4% do gasto total.
  - **Caçador de ofertas** (549): renda intermediária, o que mais compra com desconto, compra bastante pelo site, adolescentes em casa; 21% do gasto.
  - **Premium** (825): maior renda e maior gasto (vinhos e carnes), a maioria sem filhos, compra na loja e pelo catálogo; 75% do gasto.
- **Gower:** a ligação average falha de novo (2.207 / 4 / 1). Cortada em 2 grupos, a complete reencontra a divisão por gasto do Ward: 821 dos 825 clientes de maior gasto ficam num grupo e 731 dos 838 de menor gasto no outro. O estado civil só decide um grupo no corte em 4 (187 clientes, todos "Sozinho").
- **Validação externa:** a aceitação da última campanha cresce com o gasto: **8,9%** (Econômico), **13,8%** (Caçador de ofertas) e **22,1%** (Premium). É uma associação esperada, não o efeito da campanha.
- A PCA usada para visualizar guarda **57,8%** da variação nos 2 primeiros componentes.

Os números exatos podem variar levemente com versões diferentes dos pacotes.

## Versão estendida

A pasta `versao_estendida/` guarda a aula completa (`aula_clustering.qmd`, `.R` e `.html`), para turmas que já podem ver mais técnicas. Ela tem a mesma descritiva, a mesma preparação e o mesmo hierárquico da aula principal, e acrescenta:

- **k-means** (com um GIF das iterações), o papel do `nstart` e a escolha do *k* pelo cotovelo e pela silhueta;
- **k-medoides (PAM)**, o medoide como "cliente-exemplo" e a robustez a outliers;
- **bônus (pode pular):** distância de Gower com o hierárquico (ligação média) e o PAM, e por que o k-means não aceita Gower;
- **comparação das técnicas** (tabelas cruzadas e silhueta média), com a escolha final do PAM.

Para rodar: abra o `clustering.Rproj` (na raiz) e depois `versao_estendida/aula_clustering.R`. Os dados e as figuras ficam na raiz, e o script roda a partir dela.

Principais resultados da versão estendida:

- **Silhuetas médias** (mesma distância euclidiana, k = 3): **0,217** no hierárquico, **0,242** no k-means e **0,230** no PAM. A silhueta do k-means prefere k = 2 (0,318).
- **Técnica final: PAM**, escolhida por entregar um cliente real (o medoide) como exemplo de cada segmento. Os segmentos têm **822 / 664 / 726** clientes, e a aceitação da última campanha é **8,5% / 13,9% / 23,6%**.
- O bloco **6b (bônus de Gower)** pode ser pulado: ele vai da linha `# 6b. Bônus ...` até `# ---- fim do bônus 6b ----`, e nenhuma seção seguinte usa objetos criados nele.

As duas versões são arquivos independentes: uma correção nas partes comuns (descritiva, preparação, hierárquico) precisa ser feita nas duas.

## Como editar o material (professor)

Os `.qmd` são a fonte. **Não edite `aula_clustering_simplificada.R` nem `versao_estendida/aula_clustering.R` à mão**, porque eles são sobrescritos pelo build. Depois de alterar um `.qmd`, rode a partir da raiz:

```bash
Rscript tools/build.R                                                 # gera o .R e o .html das DUAS aulas
Rscript -e 'testthat::test_file("tests/test_aula_simplificada.R")'     # testes da aula principal
Rscript -e 'testthat::test_file("tests/test_aula.R")'                  # testes da versão estendida
Rscript -e 'testthat::test_file("tests/test_figuras.R")'               # testes do exemplo e das figuras
```

O build usa o Quarto do PATH. Se ele não estiver no PATH, usa o Quarto que vem com o RStudio. A versão estendida é renderizada com o código rodando a partir da raiz (opção `knitr: opts_knit: root.dir: ".."` no cabeçalho do `.qmd`), e as figuras são referenciadas como `../figuras/...`.

As figuras de `figuras/` (bonequinhos, ligações e o GIF do k-means) **não** são geradas pelo build. Se mudar o exemplo de 6 clientes (`tools/exemplo.R`, que também está digitado nos dois `.qmd`) ou o visual de alguma figura, rode antes do build:

```bash
Rscript tools/figuras.R   # exige ggplot2, patchwork e gifski (este só na sua máquina, não no laboratório)
```

Os testes verificam, entre outras coisas:
- a leitura dos dados (2.240 × 29, MD5 do arquivo) e a mensagem de erro quando o aluno está na pasta errada;
- a limpeza e a preparação, incluindo que as campanhas não entram no agrupamento;
- o hierárquico (incluindo que single, complete e average falham nesta base) e a Gower;
- na aula principal: que não sobrou nada de k-means, PAM ou silhueta, e que o texto da Gower bate com os dados;
- na versão estendida: as três técnicas e que a aula funciona **pulando o bônus 6b**;
- que os nomes dos segmentos seguem o perfil (e não o número do grupo) e que as frases das fichas batem com o perfil;
- a reprodutibilidade e que cada script roda em menos de 2 minutos;
- que cada `.R` está sincronizado com o seu `.qmd` e tem as seções navegáveis.

Atenção: os textos dos `.qmd` citam os números impressos (tamanhos dos grupos, perfis, taxas). Se mudar os dados, as variáveis ou a técnica, **revise esses textos e as frases das fichas**.
