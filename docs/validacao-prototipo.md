# Validação do primeiro V

## Estado

A primeira versão do V na porta foi aprovada em teste manual, incluindo fluidez e alinhamento do ponteiro, e integrada à main como candidata a testes, sem publicação pública no Roblox. A revisão atual acrescenta áudio e fechamento automático; esses recursos ainda requerem teste no motor. O Codex não executou o Studio ou tablet. Testes locais verificam sintaxe Luau, lógica do percurso, projeção, ciclo da porta e build Rojo.

O arquivo para testar é `build/Dinografia-PrimeiroV.rbxlx`, gerado por `scripts/build-prototype.ps1`. Abra usando File > Open from File; o cenário original continua intacto. Play inicia o construtor do paddock, jaula e Blue. No menu Window, abra Output para registrar eventuais erros.

## Roteiro no Studio

1. **Nascimento:** Blue deve estar inteiramente dentro da jaula, com pés próximos ao piso. Ela fica imóvel enquanto presa, embora a animação Idle possa mover o corpo. Paredes/porta começam no piso, sem passagem por baixo.
2. **Colisão:** antes de completar a atividade, tente aproximar-se e passar pela porta/paredes. Não deve haver passagem física pela jaula fechada. Após a liberação, Blue não deve empurrar o avatar, mas deve colidir com paredes e chão.
3. **Atividade:** aproxime-se e clique/toque no V visível na porta, inclusive começando de um ângulo lateral. O primeiro toque enquadra a porta; o próximo inicia a pintura. O avatar e a câmera devem parar de responder aos controles de movimento. O sulco e o ponto amarelo devem coincidir com o toque; paredes devem ocultar o V normalmente.
4. **Percurso:** trace de cima à esquerda até a ponta e depois para cima à direita. Teste toque apenas nos extremos, atalho horizontal e início invertido: não devem concluir.
5. **Continuidade:** a tinta deve preencher o sulco progressivamente. Saia da faixa, solte e retome no ponto amarelo; o progresso deve permanecer. × sai, ↻ reinicia. Reabrir começa uma nova tentativa; concluir não exige cronômetro ou som.
6. **Liberação:** ao concluir, a câmera recua para mostrar a jaula. O giroflex no alto da parede frontal acende e gira; após 1,1 s, a porta sobe durante 1,6 s com o painel acompanhando. Blue deve permanecer presa até a abertura terminar. Os controles voltam automaticamente; ande para Blue sair, seguir e descansar. Fechar a interface durante a sequência não deve interromper a abertura. Espere a porta fechar antes de iniciar outro V. Afaste-se com Blue da jaula/passagem; após pelo menos 18 segundos aberta, a porta deve descer e a tinta deve ser reiniciada. Repita o V: giroflex e porta devem funcionar novamente, mantendo Blue livre.
7. **Navegação:** ande ao redor de obstáculos, pare e volte a andar. Blue deve tentar recalcular caminhos sem teleportar. Observe especialmente saída da porta, travamentos, tremores e desníveis.
8. **Avatar:** use Reset Character durante a atividade e durante o passeio. A interface deve fechar e o personagem novo deve recuperar controles; Blue deve poder acompanhá-lo.
9. **Respawn de Blue:** durante Play, na visão do servidor, selecione Workspace > Blue > Body > Humanoid e coloque Health em 0. Deve nascer exatamente uma nova Blue após cerca de 3 segundos. Se a porta já foi liberada, a nova Blue mantém a liberação. Se a porta estiver fechada ou fechando, ela deve reabrir antes de Blue recuperar o movimento. Teste também durante o giroflex/abertura: Blue só deve ganhar movimento com a porta completamente aberta. Repetir algumas vezes e observar Output.
10. **Portão do paddock:** clicar rapidamente no botão não deve deslocar as posições finais das folhas do portão.

Registre o comportamento observado e erros do Output, incluindo os passos para reproduzir. Falhas de carregamento das animações podem depender das permissões dos assets na experiência usada.

## Tablet

Depois da verificação no Studio: validar em paisagem e retrato, um dedo e toque adicional, interrupção do toque, mudança de orientação e reabertura da atividade. Verificar se o traço acompanha o dedo e se os controles de câmera/avatar são restaurados ao fechar. O emulador ajuda no layout, mas não substitui o dispositivo real.

## Decisões desta versão

- V guiado aprovado pelo usuário; tolerância ajustável em `src/shared/Config.luau`.
- V desenhado por SurfaceGui na porta, com bordas/sombra simulando um sulco. Não é uma cavidade física no metal. Progresso de pintura local por jogador; conclusão e giroflex/porta compartilhados pelo servidor.
- Câmera frontal para escrever e enquadramento amplo para a liberação; proporção de tela considerada na distância. A conversão de pixels em raio e coordenadas da porta tem testes matemáticos; correspondência visual real depende do teste no motor.
- Cliente dá feedback imediato; servidor reavalia amostras ordenadas, limita o tamanho do payload e consome cada sessão uma única vez.
- Sem tempo limite pedagógico. Há mensagens de tentativa novamente quando não chega resposta da conexão.
- Um dedo por vez; mouse como apoio. Levantar o dedo é permitido; pontos espaçados não pulam trechos.
- Blue começa ancorada dentro da jaula. Após a liberação, um único controlador cria caminhos serialmente, considera obstáculos e timeout de waypoint, sem reposicionar por falha de navegação.
- O original Follow/Orbit/Patrol fica preservado no RBXL; esta versão usa seguir/descansar para reduzir os comportamentos a validar.
- A liberação é compartilhada na sessão; não há persistência, recompensa monetária, analytics nem integração de IA no jogo.
- Assets mantidos em `assets/` vieram da exportação fornecida. Scripts antigos não rodam em paralelo: o template fica em ServerStorage e seu script herdado de colisão é removido do clone antes de entrar no Workspace.

Referências de implementação: [pathfinding](https://create.roblox.com/docs/characters/pathfinding), [grupos de colisão](https://create.roblox.com/docs/workspace/collisions), [ownership físico](https://create.roblox.com/docs/physics/network-ownership) e [Rojo syncback](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0).


### Revisão de fluidez

Testar movimentos lentos e rápidos nos dois braços e na ponta do V. A tinta deve avançar continuamente, sem blocos ou costura central. Levantar e retomar não deve apagar ou recuar a tinta. Comparar mouse e touchscreen; observar se a suavização acompanha o gesto sem atraso perceptível. Foram adicionados cinco testes matemáticos da pintura; a fluidez e o alinhamento foram confirmados pelo usuário na primeira versão; repetir como regressão após esta alteração.


### Alinhamento do ponteiro

Após a troca para ScreenPointToRay, conferir se clicar no centro do ponto amarelo inicia/retoma o traço sem precisar clicar abaixo dele. Verificar início, ponta e segundo braço, mouse e toque, janela redimensionada e orientação retrato/paisagem. Os testes locais não verificam o inset real do Roblox.

## Áudio e repetição da porta

- Em mouse e toque, pintar lentamente/rápido, parar o movimento, sair da faixa e levantar: som de pintura não deve ficar preso ou recomeçar em cada amostra.
- Conclusão deve tocar uma vez após validação do servidor. Ouvir motor apenas durante movimento, sinal breve no giroflex e vocalização de Blue ao abrir.
- Alternar desligado/baixo/normal durante pintura, conclusão e abertura. Não alterar volume para outros jogadores; repetir a atividade sem áudio deve continuar possível.
- Conferir Output para falhas de carregamento/permissão. Testar também no aplicativo Roblox com experiência privada: sucesso do build não comprova disponibilidade dos áudios.
- Afaste avatar e Blue completamente da jaula e dos quatro studs à frente da porta; membros e cauda na região também impedem fechar. Esperar 18 segundos após abrir e observar fechamento/pintura limpa.
- Ficar dentro da jaula ou na passagem deve impedir fechamento, sem contagem regressiva. Entrar durante a descida deve fazê-la reabrir sem esmagamento.
- Testar Blue morrendo com porta fechada, aberta e fechando; confirmar uma única Blue e saída reaberta antes do movimento.
- Com dois jogadores, concluir em paralelo: apenas uma abertura; tentativas pendentes devem terminar sem travar controles. Novas tentativas só começam com porta fechada.
- Repetir ao menos três ciclos de escrita/abertura/fechamento; conferir que Blue já liberada não é teleportada nem reancorada.