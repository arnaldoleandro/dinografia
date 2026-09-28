# Backlog de evolução

Uma versão integrada à `main` é candidata a testes. Publicação pública exige aceite de jogabilidade, conforto, desempenho e direitos dos assets; gerar o jogo ou passar testes automatizados não substitui esse aceite. Não publicar automaticamente.

## Prioridade atual e retorno dos testes

A aparência atual dos animais foi considerada suficiente pelo usuário para esta etapa; melhorias de modelos ficam depois da jogabilidade e dos assets de áudio. A avaliação inicial da avenida foi positiva, com travamentos relatados em curvas como as do B.

1. Ajustar e validar fluidez, aproximação, retomada livre e conclusão da escrita com mouse e touchscreen.
2. Após o aceite da jogabilidade, produzir/importar os áudios educativos e as confirmações faladas.
3. Depois, retomar refinamento ou aquisição de modelos de dinossauros.

- [x] Implementar cobertura por aproximação, liberdade de ordem/direção e preservação da pintura fora da faixa.
- [ ] Validar a nova escrita em uso real, especialmente B, curvas, cruzamentos e diferentes gestos infantis; ajustar tolerância conforme o teste.
- [ ] Confirmar que lacunas pequenas não frustram e que traços importantes continuam necessários para concluir a letra.

## Voz e associação entre letra e som — após a jogabilidade

- [ ] Acrescentar voz às confirmações hoje escritas, preservando o texto e o funcionamento com áudio desligado.
- [ ] Associar a forma da letra ao seu nome e ao som que representa, distinguindo nome da letra de fonema; revisar os exemplos em português com apoio pedagógico antes da gravação.
- [ ] Planejar letras com múltiplos sons, dígrafos e nomes de animais cuja pronúncia não seja um exemplo simples; não tratar uma gravação por letra como regra universal.
- [ ] Permitir ouvir novamente por escolha do jogador, sem bloquear a escrita nem repetir locuções a cada movimento.
- [ ] Usar falas curtas, previsíveis, sem sobreposição, com volume controlável e silêncio entre eventos; validar conforto individual em uso real.
- [ ] Preparar roteiro, licença/autorização da voz, gravação e assets conforme o guia de áudio, somente após o aceite da jogabilidade.
- [ ] Revisar acessibilidade e objetivos pedagógicos antes da publicação; a experiência ainda não tem eficácia pedagógica ou adequação clínica validada.

## Jornada do alfabeto

- [ ] Validar a jornada completa A–Z em uma avenida/corredor legível, com direção de percurso, saída e indicação dos animais coletados.
- [ ] Comparar a jornada linear com setores menores antes de investir em um labirinto; medir orientação e tempo de deslocamento em sessões reais.
- [ ] Conferir cada letra com mouse e toque: início, curva, cruzamento, troca de traço, levantar o dedo, retomada, cancelamento e nova tentativa.
- [ ] Testar jaulas repetidas, abertura simultânea, fechamento obstruído, respawn e saída de jogador sem duplicar recompensas ou prender animais.
- [ ] Definir o comportamento multiplayer de coleta, acompanhamento e progresso; não pressupor que aprovação em sessão solo resolve disputa entre jogadores.
- [ ] Revisar nomes, explicações e classificação educativa de cada criatura antes da publicação, inclusive os casos especiais Dimetrodon, Pteranodon e o apelido Rex.

## Modelos finais — um por letra

Cada item só termina com origem e licença registradas, inspeção dos scripts importados, silhueta reconhecível, escala/pivô corretos, colisão simples, movimento validado e custo medido no dispositivo de referência. Um modelo provisório permite testar a lógica, mas não conta como aceite visual final.

| Letra | Modelo escolhido | Aceite final |
| --- | --- | --- |
| A | Alossauro | Pendente |
| B | Braquiossauro | Pendente |
| C | Carnotauro | Pendente |
| D | Dimetrodon | Pendente |
| E | Estegossauro | Pendente |
| F | Fukuiraptor | Pendente |
| G | Giganotossauro | Pendente |
| H | Hadrossauro | Pendente |
| I | Iguanodon | Pendente |
| J | Jobaria | Pendente |
| K | Kentrossauro | Pendente |
| L | Lambeossauro | Pendente |
| M | Megalossauro | Pendente |
| N | Nodossauro | Pendente |
| O | Oviraptor | Pendente |
| P | Pteranodon | Pendente |
| Q | Qianzhousaurus | Pendente |
| R | Rex (Tyrannosaurus rex) | Pendente |
| S | Suchomimus | Pendente |
| T | Triceratops | Pendente |
| U | Utahraptor | Pendente |
| V | Velociraptor | Pendente; modelo atual em teste |
| W | Wuerhosaurus | Pendente |
| X | Xenoceratops | Pendente |
| Y | Yutyrannus | Pendente |
| Z | Zuniceratops | Pendente |

## Áudio de Blue e dos demais animais — futuro

- [ ] Produzir variantes de cumprimento, curiosidade, contentamento e repouso conforme o [guia de produção de áudio](audio-production.md).
- [ ] Fazer Blue responder à aproximação e às interações, além do som de libertação; definir intervalos mínimos e períodos de silêncio.
- [ ] Variar os eventos ocasionais, evitando repetição imediata do mesmo arquivo e sons simultâneos em todos os animais.
- [ ] Priorizar sons próximos e limitar vozes concorrentes quando vários animais seguirem o jogador; interromper tarefas e áudio ao remover o animal.
- [ ] Avaliar referências cinematográficas: obter autorização para gravações reconhecíveis de filmes ou criar efeitos originais com fontes licenciadas. Não importar extrações sem direitos verificados.
- [ ] Preparar gravação, masters, exportações, créditos e permissões de experiência conforme o guia; testar audibilidade sem depender do log de carregamento.
- [ ] Manter a experiência compreensível no silêncio e os controles de volume acessíveis durante toda a jornada.

## Desempenho e conforto antes da publicação

- [ ] Medir no Roblox em tablet real: tempo de entrada, memória, quadros por segundo e resposta do toque com 1, 5, 10 e 26 animais coletados.
- [ ] Comparar renderização e simulação de todo o percurso com setores/streaming; registrar métricas antes de escolher a configuração final.
- [ ] Validar formação do grupo seguidor em curvas, portas, passagens estreitas e mudanças de direção, sem empurrar ou cobrir o jogador.
- [ ] Limitar atualizações de navegação e animação distantes; testar a recuperação de seguidores sem saltos visíveis nem bloqueio permanente.
- [ ] Testar reconexão, respawn, latência e dois ou mais jogadores; decidir e documentar se o progresso deve persistir entre sessões.
- [ ] Conferir enquadramento da câmera, oclusão pelo avatar, tamanho dos alvos, telas pequenas e mudança de orientação.
- [ ] Executar uma sessão completa com todos os efeitos, verificando fadiga sonora, frequência dos sinais e facilidade de silenciar.
- [ ] Registrar aceite manual por letra e dispositivo; resolver falhas de movimento, áudio, conforto e direitos antes de tornar a experiência pública.
