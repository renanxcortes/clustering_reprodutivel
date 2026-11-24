# Design: aula mais didática em distância, hierárquico e k-means

Data: 2026-11-24 · Material: `aula_clustering.qmd` (MAT02053, UFRGS)

## Intenção e porquê

A turma nunca viu análise multivariada. Hoje a seção 4 explica a matriz de distâncias só com texto e uma saída de `dist()` de 3 clientes, apresenta o hierárquico direto pela ligação de Ward (pouco intuitiva: "o que menos aumenta a variação dentro dos grupos") e a seção 5 descreve o k-means só em uma lista de passos. O professor quer que os alunos **vejam**:

1. o que é a distância entre dois clientes e o que é a matriz de distâncias (com "bonequinhos");
2. a regra de junção de dois grupos nas ligações **single, complete e average**, ao longo da construção do dendrograma;
3. o k-means iterando: atribuição → centroides se movem → nova atribuição, até estabilizar (GIF).

## Decisões já tomadas (pelo professor)

- **Opção A para o hierárquico:** single, complete e average são ensinadas num exemplo pequeno, com figuras. Depois os alunos rodam as três na base real e veem que falham (um grupo gigante + poucos outliers). Isso motiva apresentar o **Ward por último**, como a ligação que mantém os grupos compactos. O Ward continua sendo o hierárquico usado no resto da aula (`hc_ward`, `grupos_hc`, `k_escolhido`, seção 7).
- **Caminho 1 para as figuras:** um script separado, `tools/figuras.R`, gera PNGs e o GIF numa pasta `figuras/` versionada no repositório. O `.qmd` só insere as imagens com Markdown. Nenhum código de desenho entra no `.R` dos alunos.

Resultado conferido nos dados reais (2.212 clientes, 15 variáveis padronizadas, distância euclidiana), tamanhos com k = 3:

| Ligação | k = 3 |
|---|---|
| single | 2208 / 3 / 1 |
| complete | 2199 / 9 / 4 |
| average | 2205 / 4 / 3 |
| ward.D2 | 838 / 825 / 549 |

## Objetivos

- Figuras que um aluno sem base entenda sem o professor do lado.
- Um único **exemplo de brinquedo** que costura as três partes (minha proposta, abaixo).
- Os alunos rodam, no `.R`, poucas linhas sobre o exemplo pequeno (matriz `dist` dele e `hclust` com as três ligações), além do teste das três ligações na base real.
- O `.html` continua um arquivo único (`embed-resources: true`), com as imagens e o GIF embutidos.

## Não objetivos

- Não mudar a escolha de k, o k-means final, o PAM, o bônus de Gower, a comparação ou as fichas. Os números citados no texto dessas seções continuam válidos.
- Não animar o PAM nem o hierárquico (o hierárquico tem figuras estáticas por etapa).
- Não exigir pacote novo nas máquinas do laboratório.

## Antiobjetivos (seria um fracasso mesmo funcionando)

- O script dos alunos ficar mais longo com código de ggplot que eles não entendem.
- Figuras com notação matemática pesada (somatórios, fórmulas de ligação). A regra deve ser lida na figura em palavras: "a menor distância", "a maior distância", "a média das distâncias".
- O exemplo de brinquedo contradizer o que acontece nos dados reais sem que o texto explique.

## Restrições

- `aula_clustering.qmd` é a fonte única; `tools/build.R` gera `.R` (purl) e `.html` (Quarto). O `.R` não é editado à mão.
- O `.qmd` cita números impressos; qualquer número novo no texto deve ser conferido no R.
- `tests/test_aula.R` precisa continuar passando, e o teste de "imagens no HTML" (≥ 5 `<img>`) continua valendo.
- Pacotes disponíveis hoje na máquina do professor: ggplot2 e png sim; **gifski, gganimate e magick não**. O `tools/figuras.R` vai exigir **gifski** (só na máquina do professor).
- Ambiente Windows, R ≥ 4.5.

## Abordagens consideradas

1. **Script separado gera as imagens (escolhida).** `tools/figuras.R` + pasta `figuras/`. Mantém o `.R` dos alunos limpo e o build rápido. O custo é ter um passo a mais quando uma figura muda.
2. **Código das figuras no `.qmd` com `echo: false` e `purl: false`, GIF via gganimate.** Tudo num lugar, mas o build fica lento, passa a depender do gganimate e do gifski, e o `.qmd` fica poluído. Descartada.
3. **SVG desenhado à mão para os diagramas, R só para o GIF.** Visual de livro, mas as figuras não saem dos dados e são difíceis de manter. Descartada.

## O design

### Exemplo de brinquedo (minha proposta)

Seis clientes com nome (por exemplo Ana, Bruno, Carla, Diego, Elisa, Fábio), com **2 variáveis** já em escala comparável (por exemplo "renda" e "gasto", ambas de 0 a 10, ou z-scores arredondados), para caberem num plano. Os pontos são escolhidos para formar dois grupinhos e um cliente intermediário, de modo que **single, complete e average produzam dendrogramas visivelmente diferentes** (pelo menos uma junção em ordem ou altura diferente). Os dados ficam definidos **uma vez** (um `tibble` pequeno) e aparecem no `.qmd` (para os alunos rodarem) e no `tools/figuras.R` (para desenhar). A coerência entre os dois é garantida por teste.

Para o GIF do k-means, seis pontos são poucos. A proposta é um segundo conjunto 2D com cerca de 30 a 60 pontos simulados com semente fixa, em 3 nuvens, e **centroides iniciais escolhidos para que a animação dure de 3 a 6 iterações visíveis**. Os bonequinhos ficam no exemplo de 6 clientes; no GIF, os clientes são pontos (bonequinhos demais poluem).

### Figuras (todas geradas por `tools/figuras.R`, em `figuras/`)

1. **`distancia_dois_clientes.png`:** dois bonequinhos no plano renda × gasto, com o triângulo retângulo (diferença em renda, diferença em gasto) e a hipotenusa rotulada com a distância. É o "Pitágoras" já mencionado na seção 3.
2. **`matriz_distancias.png`:** à esquerda, os 6 bonequinhos no plano, com algumas distâncias desenhadas; à direita, a matriz 6 × 6 como tabela colorida (diagonal 0, simetria destacada, com a metade de baixo igual à saída do `dist()`).
3. **`ligacoes_regra.png`:** três painéis lado a lado (single | complete | average). Os mesmos dois grupos do exemplo, com a(s) linha(s) que definem a distância entre eles: a menor (single), a maior (complete) e todas as linhas com a média anotada (average). Uma frase curta em cada painel.
4. **`ligacoes_passos.png` (ou uma figura por ligação):** a construção do dendrograma passo a passo para cada ligação, lado a lado com os grupos sendo formados no plano. Formato a definir pelo builder: uma grade "passo × ligação" ou três figuras. Deve deixar visível onde as ligações divergem.
5. **`kmeans_iteracoes.gif`:** cada iteração mostra dois quadros, "atribuição" (pontos coloridos pelo centro mais próximo) e "atualização" (o centroide anda até a média, com uma seta ou rastro da posição anterior), com um título do tipo "Iteração 2: recalculando os centroides". O GIF termina com uma pausa no quadro final ("ninguém mudou de grupo: fim"). O algoritmo é implementado à mão no script (para capturar cada passo), e o resultado final é conferido contra `kmeans(..., algorithm = "Lloyd")` com os mesmos centros iniciais.
6. **(Opcional) `kmeans_iteracoes_estatico.png`:** os quadros do GIF numa grade, para quem imprime o material.

Estilo: ggplot2, paleta consistente com a aula atual (firebrick / steelblue / darkgreen para os grupos), textos em português, fonte legível em projetor. Os bonequinhos são desenhados em ggplot (cabeça = círculo, corpo = segmento ou forma simples) ou com um caractere/glyph, à escolha do builder, **sem depender de fontes de emoji do sistema**.

### Mudanças no `.qmd`

- **Seção 4, "Distância entre clientes e a matriz de distâncias":** antes do exemplo de 3 clientes, entram as figuras 1 e 2 e um bloco curto em que os alunos rodam `dist()` no exemplo de 6 clientes e reconhecem os números da figura. O exemplo atual com 3 clientes reais e a conta à mão continua.
- **Nova subseção "Como juntar dois grupos? Single, complete e average"**, no lugar de "A ligação de Ward": explicação em palavras + figura 3 + figura 4 + bloco em que os alunos rodam `hclust()` com as três ligações no exemplo de 6 clientes e plotam os três dendrogramas (`par(mfrow = c(1, 3))`, base R, poucas linhas).
- **Nova subseção "E na base real?":** os alunos rodam as três ligações em `dist_euc` e veem `table(cutree(..., k = 3))` de cada uma. O texto explica a falha: a base é um contínuo, então single "encadeia" e average e complete isolam outliers (o texto final só pode afirmar o que for conferido nos dados).
- **Subseção "A ligação de Ward"** (mantida, reescrita como desfecho): "junta os dois grupos que, ao se unirem, ficam menos espalhados", ligada à intuição de "grupos compactos" e à WSS que reaparece no k-means. O código `hc_ward`, o dendrograma, as alturas, `k_escolhido` e o `cutree` continuam como estão.
- **Seção 5, "A ideia do k-means":** o GIF entra logo depois da lista dos 4 passos, com uma legenda que liga cada quadro a um passo.
- **Bônus 6b:** a frase "trocamos a ligação... usamos a ligação média" passa a remeter à figura de average da seção 4. O conteúdo não muda.
- **README:** a lista de "O que os alunos aprendem" passa a citar single/complete/average + Ward; a seção "Como editar" ganha o passo `Rscript tools/figuras.R` (com a nota de que ele exige `gifski`); a tabela de arquivos ganha `tools/figuras.R` e `figuras/`; as dicas para o professor indicam quais blocos novos podem ser pulados.

### Testes

- O que já existe continua (incluindo `hc_ward$method == "ward.D2"`).
- Novo: os arquivos de `figuras/` referenciados no `.qmd` existem.
- Novo: o exemplo de brinquedo no `.qmd` é igual ao usado em `tools/figuras.R` (por exemplo, um arquivo de dados compartilhado ou comparação dos valores).
- Novo: nas três ligações sobre a base real, o maior grupo com k = 3 tem mais de 90% dos clientes (protege o texto "falham" contra mudanças de dados ou de versão).
- Novo: no exemplo de 6 clientes, pelo menos duas ligações dão dendrogramas diferentes (a figura 4 depende disso).
- O teste de tempo (< 2 min) continua; as três ligações extras na base real custam poucos segundos.

## O que fica com o builder

- As coordenadas exatas dos 6 clientes e do conjunto do GIF (respeitando as propriedades acima).
- O desenho dos bonequinhos e o layout das figuras 2 e 4.
- O número de quadros e o tempo por quadro do GIF (meta: arquivo de até ~2 MB, porque ele é embutido no HTML).
- Onde guardar os dados do exemplo para o `.qmd` e o `figuras.R` compartilharem (no `.qmd` inline, conferido por teste, ou num `.csv` pequeno).
- A redação final dos textos, conferindo no R todo número citado.
