# Modelos do alfabeto

O catálogo escolhe o primeiro animal de cada letra da lista do projeto. Os 26 modelos são **silhuetas estilizadas originais geradas com peças do Roblox**, sem downloads, IDs inventados, scripts de terceiros ou dependências de permissões de assets. São modelos provisórios jogáveis para validar as atividades; não são modelos adquiridos na biblioteca nem reconstruções científicas precisas.

`src/shared/DinosaurCatalog.luau` contém dados independentes do motor: `Entries` em ordem A–Z e `ByLetter`. `src/server/DinosaurModels.luau` expõe `Create(entry)`, retornando um `Model` com `Root` como `PrimaryPart`, pivô ao nível do chão e frente em `-Z`. As peças são ancoradas, sem colisão e sem toque; o modelo não tem scripts, Humanoid ou animações importadas. Pode ser reposicionado com `PivotTo` como exposição ou acompanhante cosmético. Esses modelos não substituem o rig original da Blue na atividade inicial.

As famílias visuais incluem bípedes, pescoços longos, animais com placas, armaduras, chifres, cristas, vela dorsal e asas. Os tons são deliberadamente inventados. Proporções são compactadas para caber nas estações; tamanho relativo entre espécies não é uma informação educativa. Os atributos `Species`, `Letter`, `Classification`, `ModelKind` e `GroundOffset` documentam cada modelo criado.

| Letras | Silhueta base | Principais diferenças |
| --- | --- | --- |
| A, C, F, G, M, Q, R, S, Y | Terópode bípede | Cabeças, braços, focinhos, sobrancelhas, chifres e detalhes dorsais |
| B, J | Saurópode | Pescoço longo de alturas diferentes |
| D | Sinapsídeo | Vela dorsal |
| E, K, W | Estegossauro | Placas, espinhos da cauda e ombros |
| H, I, L | Ornitópode | Bico, polegares e crista |
| N | Animal com armadura | Placas arredondadas no dorso e espinhos laterais |
| O, U, V | Bípede compacto | Bico/crista, penas estilizadas ou faixa azul |
| P | Pterossauro | Asas abertas, bico e crista |
| T, X, Z | Ceratopsiano | Gola, quantidade de chifres e tamanho da gola |

Dimetrodon é um sinapsídeo, não um dinossauro ([Harvard Museum of Natural History](https://whatsinaname.hmnh.harvard.edu/dimetrodon)). Pteranodon é um pterossauro, também não um dinossauro ([Natural History Museum](https://www.nhm.ac.uk/discover/the-truth-about-pterosaurs.html)). Ambos foram mantidos por fazerem parte da seleção solicitada, com a classificação explícita no catálogo.

## Substituição artística futura

Pesquisar modelos no Creator Store, conferir autor e permissão, inspecionar o conteúdo antes de incorporá-lo e remover scripts não necessários. Avaliar geometria, texturas, proporções, desempenho móvel e legibilidade da espécie. Para um modelo externo, adaptar o pivô e a frente à mesma convenção e manter os metadados do catálogo. Um asset público não implica permissão de redistribuir seu arquivo no Git; registrar origem e condições antes de versionar.

Validação automatizada cobre a seleção A–Z, os dados, as famílias suportadas e as classificações. A aparência das peças e seus movimentos precisa ser revisada no Studio, especialmente na tela pequena.
