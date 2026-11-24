# Design: aula simplificada (só hierárquico, euclidiano e Gower)

Data: 2026-11-24 · Base: branch `aula-didatica` (a aula completa com bonequinhos, quatro ligações e GIF)

## Intenção e porquê

O professor quer uma **segunda versão da aula**, `aula_clustering_simplificada`, para uma turma em que **PAM, k-means e afins são conceitos difíceis demais de explicar**. O objetivo é **simplificar os conceitos, não encurtar a aula**: tudo o que é simples (descritiva, preparação, distância, ligações, dendrograma) continua inteiro; saem as técnicas e as medidas que exigem ideias novas. A aula completa continua existindo, sem mudanças.

## Decisões já tomadas (pelo professor)

- **Só hierárquico:** sem k-means e sem PAM.
- **Gower como contraponto (caminho A):** as fichas finais vêm do **Ward euclidiano**; a Gower entra numa seção própria, mostrando como ela trata variáveis categóricas, que as ligações average e complete com Gower dão resultados diferentes, e que a complete com Gower reencontra a divisão por gasto ("a régua muda, a estrutura principal se mantém"). O estado civil só aparece decidindo um grupo no corte em 4. Não se usa Ward sobre `sqrt(Gower)` (adaptação difícil de justificar numa aula simples).
- **Arquivo independente (opção 1):** `aula_clustering_simplificada.qmd` é uma cópia da aula completa, editada livremente. O build gera os dois `.R` e os dois `.html`; há um arquivo de testes próprio.

## Objetivos

- Uma aula do problema de negócio até as fichas de segmento, usando só: média/desvio, distância euclidiana, matriz de distâncias, ligações (single, complete, average, Ward), dendrograma, Gower, PCA só para visualizar, perfil por médias.
- Mesma estrutura de arquivos e mesmas garantias da aula completa: `.R` gerado pelo `purl`, seções navegáveis no RStudio, testes de reprodutibilidade, tempo e sincronia.
- Reaproveitar as figuras de `figuras/` (exceto o GIF do k-means).

## Não objetivos

- Não mexer na aula completa (`aula_clustering.qmd`), além do necessário no `build.R` e no README.
- Não criar figuras novas. A seção Gower usa só código e tabelas. Se o builder achar que uma figura faz muita falta, ela vira proposta, não entra neste trabalho.
- Não compartilhar texto entre as duas aulas: a duplicação é aceita.

## Antiobjetivos

- Reintroduzir pela porta dos fundos conceitos que saíram: centroide como "centro do k-means", medoide, silhueta, WSS/cotovelo, `nstart`, sementes aleatórias. O Ward continua sendo explicado como "a fusão que menos aumenta o espalhamento" (com a figura); essa é a única ideia de "centro" que a aula usa.
- Referências quebradas a seções ou objetos que não existem na versão simplificada ("veremos na seção 5", "o PAM se sai melhor", `grupos_pam`, `medoides`).
- Frases das fichas que não batem com o perfil dos grupos do Ward.

## Restrições

- R ≥ 4.5; pacotes só tidyverse e cluster (o `daisy()` da Gower é do cluster).
- O `.qmd` cita números impressos; todo número no texto novo deve ser conferido no R.
- A descritiva e a preparação são iguais às da aula completa (mesmos números).
- O bloco Gower deixa de ser "bônus que pode pular": vira seção principal.

## Abordagens consideradas

1. **Cópia independente (escolhida).** Liberdade total no texto; custo: correções nas partes comuns precisam ser feitas nas duas aulas.
2. **Partes comuns em arquivos "filhos" incluídos nas duas aulas.** Evitaria duplicação, mas o texto comum cita seções de k-means/PAM, o `purl` não segue includes do Quarto, e a edição passaria a ser em vários arquivos. Descartada.
3. **Cópia com teste que acusa diferenças nos blocos de código comuns.** Protege só o código, não o texto, e adiciona manutenção. Descartada.

## O design

### Estrutura da aula simplificada (seções de primeiro nível)

1. **Problema de negócio e setup**: igual à completa (incluindo "Um mínimo de R"). Os pacotes continuam tidyverse e cluster (o comentário passa a dizer `daisy()`, sem `pam()` e `silhouette()`).
2. **Estatísticas descritivas**: igual.
3. **Preparação dos dados**: igual (limpeza, derivadas, escolha das variáveis, `log1p`, experimento da padronização, z-score). Só trocar referências a seções posteriores.
4. **Cluster hierárquico**: a seção 4 nova da aula completa (bonequinhos, matriz, quatro regras, falha na base real, Ward, dendrograma, alturas, corte em k = 3). Mudanças:
   - A justificativa de k = 3 vem **só do dendrograma**: as alturas das últimas fusões (147,4 → 82,5 → 42,2…). A frase "conferimos na seção 5 com cotovelo e silhueta" sai; entra uma frase honesta sobre o corte em 2 também ser defensável e o 3 ser escolhido por ser mais útil ao marketing (a mesma ideia da aula completa, sem a silhueta).
   - A frase do Ward que remete à WSS "na seção 5" sai.
5. **Hierárquico com dados mistos: a distância de Gower** (o antigo bônus 6b, promovido e reescrito sem PAM):
   - Motivação (variáveis categóricas), como a Gower mede (a conta à mão com 2 clientes), `daisy()`.
   - Hierárquico com Gower usando **average** e **complete**, com os tamanhos dos grupos (conferidos em 2026-11-24, k = 3: average 2207/4/1; complete 1357/851/4). Mensagem: a average repete o problema da base real; a complete separa a base em **dois** grandes grupos (k = 2: 1357/855; o corte em 3 só separa 4 clientes).
   - **Mensagem da seção (decisão do professor, caminho a): "a régua muda, a estrutura principal se mantém".** Cruzar a complete com Gower (k = 2) com os grupos do Ward euclidiano: a divisão segue o gasto (o grupo 1 tem 821 dos 825 Premium; o grupo 2, 731 dos 838 Econômicos; os Caçadores de ofertas se dividem entre os dois, 429/120). Mostrar também a tabela com `Marital_Status` no k = 2: a proporção de casados é parecida nos dois grupos (852/505 × 576/279), então o estado civil **não** decide a divisão principal. Em uma ou duas frases, mostrar o corte em k = 4: surge um grupo de **187 clientes, todos "Sozinho"**. A categórica pesa, mas só nos cortes mais baixos da árvore. Isso liga com a conta à mão (uma categórica diferente vale 1 inteiro).
   - A frase da conta à mão "Guarde essa observação: ela vai aparecer nos resultados" é ajustada para apontar para o corte em 4 desta seção.
   - Conclusão: os segmentos por comportamento de compra são robustos à troca da régua; seguimos com o Ward euclidiano (mais simples, com as variáveis de compra).
   - **Não afirmar** em lugar nenhum que o estado civil decide a divisão com k = 2 ou 3.
   - A nota sobre Ward com `sqrt(dist_gower)` sai (ou vira uma linha "existe, mas fica fora desta aula"). A seção "Por que o k-means não aceita Gower?" sai.
6. **Resultados para o negócio** (a antiga seção 8, adaptada):
   - `grupos_final <- grupos_hc` (sem "escolha da técnica"; uma frase diz que os segmentos vêm do Ward euclidiano).
   - PCA só para visualizar: igual, com legenda e texto trocando "grupo do PAM" por "grupo do Ward". O texto que citava a silhueta baixa passa a dizer que os grupos se tocam e formam um contínuo (sem "silhueta").
   - Perfil, regra dos nomes (ordem do gasto total médio), gráfico de perfil e fichas: mesmo código; **as frases fixas das fichas são revistas** contra o perfil do Ward. O que foi conferido: os nomes Econômico (838), Caçador de ofertas (549) e Premium (825) seguem a ordem do gasto. O Caçador tem o maior `NumDealsPurchases` (3,8) e `Teenhome` (0,78), o Premium o maior `Sem_filhos_prop` (0,59), vinhos, carnes, catálogo e loja, e o Econômico o maior `Kidhome`. **Quase empate em `NumWebPurchases`** (Premium 5,52 × Caçador 5,46): nenhuma frase pode afirmar quem "mais compra pelo site" entre esses dois.
   - **Cliente-exemplo** sem medoide: para cada segmento, o cliente cuja linha em `dados_pad` está mais perto (distância euclidiana) da **média do segmento em `dados_pad`**. Texto: "o cliente mais parecido com o perfil médio do grupo". Não usar a palavra "centroide".
   - Validação externa com as campanhas: igual (números conferidos com o Ward: última campanha 8,9% / 13,8% / 22,1%).
   - "Para fechar": reescrito sem k-means e PAM, mencionando que existem outras técnicas (uma linha, sem explicá-las).
- **Sai:** seções 5 (k-means), 6 (PAM) e 7 (comparação das técnicas); toda menção a silhueta, WSS, cotovelo, `nstart`, `set.seed` (a aula simplificada não tem sorteio nenhum).

### Arquivos

- Criar `aula_clustering_simplificada.qmd` (título: "Quem são os nossos clientes? (versão simplificada)"; subtítulo citando cluster hierárquico e distância de Gower). Ele gera `aula_clustering_simplificada.R` e `aula_clustering_simplificada.html`.
- `tools/build.R`: gera as duas aulas.
- Criar `tests/test_aula_simplificada.R` com o mesmo espírito do `test_aula.R`:
  - dados carregados;
  - erro claro fora do projeto;
  - `.R` sincronizado com o `.qmd`;
  - limpeza;
  - exemplo igual ao `tools/exemplo.R`;
  - as três ligações falham na base real;
  - Ward e k;
  - Gower (`dist_gower` misto; `hc_gower_average` e `hc_gower_complete` com os métodos certos; o maior grupo da average com k = 3 tem mais de 90% dos clientes; a complete com k = 2 tem os dois grupos com mais de 20% dos clientes e concorda com o Ward em mais de 70% dos Premium e Econômicos; com k = 4, a complete tem um grupo só de "Sozinho");
  - `grupos_final` igual a `grupos_hc`;
  - nomes seguem o perfil, e as frases das fichas batem com o perfil (sem afirmar sobre `NumWebPurchases` entre Premium e Caçador);
  - cliente-exemplo é cliente real de cada segmento;
  - **nenhum objeto de k-means/PAM existe** (`km`, `pam_euc`, `medoides`, `avaliacao_k`);
  - o texto não menciona "silhueta", "k-means", "PAM", "medoide", "WSS" fora da frase final que cita outras técnicas;
  - reprodutível;
  - roda em menos de 2 minutos;
  - seções navegáveis (o número de seções de primeiro nível no `.R` é 6);
  - figuras citadas existem.
- README: nova linha na tabela de arquivos, um parágrafo "Versão simplificada" explicando o que muda e quando usar, e o comando de teste novo.

## O que fica com o builder

- A redação de todos os textos adaptados, conferindo cada número no R.
- O formato exato das tabelas cruzadas (k = 2 para a mensagem principal e k = 4 para a nota sobre o estado civil estão decididos).
- Quais frases das fichas mudam (desde que batam com o perfil e o teste as proteja).
- Se a seção Gower deve reaproveitar a conta à mão com os mesmos 2 clientes da aula completa (recomendado).
