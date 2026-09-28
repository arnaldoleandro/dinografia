# Métricas de escrita no Studio

A avenida A–Z registra tentativas no **Output do cliente durante Play no Studio**. Não é necessário instalar nada. Procure pelo prefixo `Dinografia escrita`; copie as linhas e envie junto da sua percepção e da letra testada. Termine a letra ou feche a atividade com × antes de encerrar Play para obter o resumo. ↻ registra a tentativa anterior como reiniciada.

Os registros não incluem nome, UserId, idade, coordenadas do gesto ou identificadores da conta. Não são enviados a serviço externo nem persistidos pelo jogo; ficam no Output/log local do Studio. As médias reiniciam ao iniciar outro Play. Em uma experiência publicada, o registro fica desligado por padrão.

## O que aparece

Uma linha `[Dinografia escrita]` contém JSON com o resumo da tentativa. Outra, `[Dinografia escrita media]`, contém médias das tentativas concluídas da mesma letra e tipo de entrada (mouse/toque) na sessão atual. Cancelamentos e reinícios continuam nos registros individuais, mas não entram nessas médias.

| Campo | Significado |
| --- | --- |
| `attempt`, `letter`, `outcome` | Número local, letra e resultado: completed, cancelled, restarted ou interface_closed. |
| `seconds` | Do primeiro contato de escrita à conclusão local, incluindo pausas; exclui animação inicial da câmera e espera da resposta do servidor. Em tentativa incompleta, termina ao fechar/reiniciar. |
| `contactSeconds` | Tempo mantendo dedo/mouse pressionado, inclusive parado. Interrupções como perda de foco encerram o contato. |
| `contacts` | Pressões físicas usadas na escrita; o clique que abre a atividade não conta. Voltar à faixa sem levantar o dedo não cria novo contato. |
| `checkpoints` | Segundos desde o primeiro contato até 25%, 50%, 75%, 90% e 100% de cobertura. |
| `coverage` | Progresso entre 0 e 1; 1 representa conclusão tolerante, não cobertura geométrica perfeita. |
| `movingWithoutAdvanceSeconds` | Estimativa de tempo de movimento amostrado sem ganhar cobertura; cada intervalo é limitado a 0,25 s para não transformar uma longa pausa em movimento. |
| `longestMovingWithoutAdvanceSeconds` | Maior sequência estimada de movimento sem avanço, interrompida por avanço, levantamento, saída do painel ou salto grande. |
| `pathPanelWidths` | Distância desenhada em unidades da largura do painel; não soma deslocamentos entre contatos nem saltos maiores que 0,22. |
| `advancingPath`, `repeatedPath`, `rejectedPath` | Partes dessa distância com ganho de cobertura, sobre região já aceita ou sem aceitação pelo validador. Não equivalem a acertos/erros pedagógicos. |
| `meanGuideDistance` | Distância média ao guia, ponderada pelo caminho amostrado, em largura do painel: 0,03 equivale a 3%. É desvio do molde, não avaliação de caligrafia. |
| `directionReversals` | Mudanças maiores que 120° entre deslocamentos significativos (mínimo 0,015 da largura). Curvas, vértices e retornos naturais também podem contar. |
| `panelExits` | Episódios em que o contato saiu do painel; não confundir com sair apenas da faixa da letra. |
| `samples`, `largePointerJumps` | Quantidade de amostras analisadas e saltos maiores que 0,22 da largura, descartados da distância. |
| `input`, `viewport`, `rule`, `tolerance` | Mouse/toque, tamanho da tela, versão da regra e tolerância para contextualizar a comparação. |

## Comparar com a percepção

Anote algo como “B: pareceu prender no final” junto das linhas daquela tentativa. Se 90% foi atingido cedo e 100% demorou, investigamos as áreas finais. Muitos contatos indicam interrupções, mas não demonstram travamento sozinhos. Muito movimento sem avanço ou sobre cobertura repetida ajuda a localizar tentativas de completar regiões já pintadas.

Compare preferencialmente a mesma letra, dispositivo, orientação e versão do jogo. Faça poucas tentativas confortáveis e preserve também os cancelamentos: olhar apenas a média das conclusões esconderia dificuldades. Letras têm comprimentos e quantidades de partes diferentes, portanto o tempo bruto de B e I não é uma comparação justa de habilidade.

Esses dados descrevem interação com esta atividade, não medem FPS, latência real do touchscreen, aprendizagem ou precisão clínica. A fluidez visual continua exigindo observação. Para acompanhar evolução ao longo do tempo, guarde os resumos por data e contexto de teste fora do repositório público; não é necessário identificar a criança nos logs. Exportação estruturada entre sessões e relatórios históricos ficam para uma etapa futura.