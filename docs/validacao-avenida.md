# Validação da avenida A–Z

Estado: código compilado, 88 verificações de lógica aprovadas e builds Rojo gerados. Nenhuma sessão de Play foi controlada automaticamente; os itens abaixo são aceites pendentes no motor, não resultados já comprovados. A versão não deve ser publicada antes desse aceite.

## Retorno manual desta etapa

O usuário testou a avenida e considerou a aparência dos modelos suficiente para a etapa atual. Relatou melhora na rapidez e liberdade da escrita por aproximação. Ainda há interesse em substituir o preenchimento por desenho livre com reconhecimento, em uma experiência separada após consolidar esta versão. Este aceite parcial não encerra os testes de touchscreen, multiplayer, desempenho ou conforto para publicação.

## Abrir a versão certa

Execute `scripts/build-avenue.ps1`, abra `build/Dinografia-AvenidaAZ.rbxlx` e use Play. A avenida é gerada pelo servidor ao iniciar; o mapa pode parecer vazio em modo de edição. Para atualizar um arquivo já aberto, pare o Play e reabra o build. A sincronização usa `alphabet.project.json`, porta 34874.

## Percurso e letras

- Percorra A–Z, incluindo curvas B/C/G/O/Q/S e traços separados A/E/F/H/I/K/T/X. O amarelo deve acompanhar o contato; ao levantar o dedo, sugere uma região ainda não pintada. É permitido começar em outro lugar e inverter ordem e direção dos traços.
- Levante o dedo, saia do sulco e retome em qualquer parte da letra. Confirme que o progresso é preservado, sem pintar uma linha entre dois toques separados.
- Toque só nas pontas, rabisque num único lugar, omita um traço importante e tente saltar uma letra. Não deve liberar o animal. Escrever ao contrário ou em outra ordem deve funcionar.
- Verifique mouse, touchscreen, tela estreita, redimensionamento, fechamento da atividade e respawn durante a escrita. A câmera deve devolver o controle e não entrar na jaula oposta.
- Complete a letra, confira giroflex e abertura, saia da passagem e aguarde o fechamento. Refaça a letra; a porta deve abrir e a contagem não deve aumentar novamente.
- Fique na passagem durante o fechamento. A porta deve reabrir. Não use os acompanhantes como obstáculos: eles são cosméticos sem colisão.

## Escrita por aproximação

A faixa aceita afastamento do guia de até 6,5% da largura do painel, em vez de exigir alcançar cada vértice. A conclusão exige 92% de cobertura total e 85% de cada traço; são parâmetros iniciais para teste, não critérios pedagógicos validados. Testar especialmente o B com curvas arredondadas, retomadas no meio, movimentos rápidos e pouca precisão. O cliente e o servidor usam as mesmas regras. Toques isolados e saltos grandes não pintam o caminho entre os pontos.

A pintura é local: começar pela parte inferior não pode preencher automaticamente a parte superior. O ponto de contato deve acompanhar o mouse/dedo sem ficar preso no guia. Avaliar se o preenchimento visual, a faixa ampliada e a indicação das partes restantes são claros no dispositivo real.

## Coleção e acompanhantes

- Confira nome, letra e silhueta de cada espécie. Os modelos são provisórios e estilizados, não representações científicas aprovadas.
- O animal deve sair pela frente da própria jaula antes de se juntar ao caminho percorrido pelo jogador.
- Abra Minha coleção: todos os animais adquiridos devem permanecer marcados após a sétima coleta, embora apenas seis acompanhem visivelmente.
- Teste curvas, paradas, retorno pela avenida, entrada em jaulas já abertas e respawn. Observe sobreposição de acompanhantes, caminhos que cruzam portas e variação de altura.
- Após coletar Z, entre na área verde da saída. Deve aparecer “Passeio completo”. Passar pela saída antes não conclui a jornada.
- Fechar e entrar de novo reinicia a coleção nesta versão. Persistência é trabalho futuro.

## Dois jogadores e desempenho

Use o teste de servidor com dois clientes. A coleta é pessoal e a porta é compartilhada: apenas quem concluiu recebe o animal; o outro pode realizar a atividade após o fechamento. Teste dois envios simultâneos, desconexão durante a abertura e respawn.

Os modelos expostos e seguidores são locais: cada jogador vê a própria coleção. Conferir no dispositivo real tempo de entrada, taxa de quadros, memória, escrita sem engasgos e câmera. Limites atuais: seis exposições próximas, seis seguidores, uma superfície detalhada de escrita; acompanhantes atualizados a 20 Hz. Esses limites são decisões de implementação, não medições de desempenho.

## Áudio e conforto

A avenida reaproveita o conjunto de áudio existente para todas as espécies. Vocalizações específicas e mais interações estão no backlog. Confira sincronização da porta, ausência de sobreposição de sons, volume baixo inicial, mute e conforto em sessões curtas, com o usuário controlando o volume. Sons de filmes exigem fonte autorizada; veja `audio-production.md`.