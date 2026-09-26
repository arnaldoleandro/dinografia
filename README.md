# dinografia
Letras e aventuras com dinossauros

## Primeiro protótipo: V de velociraptor

No Studio, use **File > Open from File** e abra `build/Dinografia-PrimeiroV.rbxlx`. Clique em **Play**, aproxime-se da jaula e **toque/clique no V da porta**. A câmera enquadra a porta; no próximo toque, percorra o sulco começando no ponto amarelo. A pintura acompanha o progresso. Ao concluir, a câmera recua, o giroflex acende, a porta sobe e só então Blue é liberada. Os controles voltam automaticamente. É possível levantar o dedo e retomar, usar ↻ para recomeçar ou × para sair. Mouse também funciona.

O sulco é um efeito visual de profundidade desenhado na superfície da porta. A versão anterior, com botão e atividade na tela, foi testada satisfatoriamente pelo usuário; o usuário também confirmou a fluidez da apresentação na porta após os ajustes de pintura e alinhamento do ponteiro. Os demais casos do roteiro de validação continuam pendentes. Para carregar um build atualizado, pare o Play e reabra o arquivo. O backup local anterior é `build/Dinografia-PrimeiroV-anterior.rbxlx`.

Essa é uma cópia independente montada a partir dos assets do cenário exportado. O original `fontes para o projeto/primeiro_dinossauro.rbxl` permanece preservado. Não é necessário conectar Rojo para testar o arquivo gerado.

Para gerar novamente: **Ctrl+Shift+B** no VS Code, ou:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-prototype.ps1
```

O protótipo usa `prototype.project.json`. Para editar com sincronização, execute a tarefa **Rojo: servir protótipo (34873)** e conecte o plugin à porta **34873**, somente com a cópia do protótipo aberta. O projeto antigo da porta 34872 continua sendo apenas o marcador de conexão.

Colisão/respawn foram reorganizados: a jaula começa no piso, Blue nasce alinhada e fica parada enquanto presa; servidor valida o percurso antes de abrir a porta. Depois ela segue e descansa, sem órbita/patrulha nessa versão. O estado de liberação dura a sessão e é mantido no respawn. O primeiro usuário a completar libera a Blue compartilhada; repetir não fecha a jaula.

Ver [roteiro de validação](docs/validacao-prototipo.md) para testes no Studio e tablet. Ainda é necessária validação de física, animações e toque real; testes locais não executam o motor Roblox.

### Verificações locais

Luau 0.739 é usado somente nas verificações (o build requer apenas Rojo). Se necessário, execute `scripts/setup-luau.ps1` para baixar o pacote oficial com SHA256 fixo.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prototype.ps1
```

O comando compila os scripts, executa 23 testes do traçado compartilhado e da projeção do toque na porta e da suavização da pintura, e gera o protótipo. A extração dos assets preserva a origem de terceiros; a licença do repositório não redefine os direitos desses assets.

## Desenvolvimento local com Rojo

Trabalhar na branch `work/desenvolvimento-inicial`. Ler [handoff.md](handoff.md) antes de alterar o projeto; integrar à `main` somente após validar uma versão aceitável.

Rojo **7.7.0**, instalado localmente em `.tools/rojo/7.7.0/rojo.exe`. Executável e builds não entram no Git. Em outro clone, instalar pelo PowerShell na raiz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-rojo.ps1
.\.tools\rojo\7.7.0\rojo.exe plugin install
```

O instalador baixa o release oficial para Windows x64 e verifica o SHA256. A instalação do plugin grava na pasta de plugins do Studio. A conexão local não exige login no Rojo.

### Iniciar e validar

Para o marcador inicial, no VS Code: **Terminal > Run Task** e selecionar **Rojo: marcador de conexão (34872)** ou **Rojo: validar marcador**. Alternativamente:

```powershell
.\.tools\rojo\7.7.0\rojo.exe serve default.project.json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-rojo.ps1
```

O servidor usa `127.0.0.1:34872`. Iniciar apenas uma instância por vez; se a porta já estiver ocupada, reutilizar o servidor existente. Um servidor iniciado no terminal pode ser encerrado com `Ctrl+C`.

### Primeira conexão no Studio

1. Salvar uma cópia do jogo atual. Se o Studio já estava aberto durante a instalação, reiniciá-lo após salvar.
2. Abrir essa cópia e acessar o plugin **Rojo**, na aba **Plugins**.
3. Conectar a `localhost`, porta `34872`. Se o plugin solicitar acesso HTTP local, permitir essa conexão.
4. Conferir a prévia de sincronização, quando exibida: o mapeamento inicial cria apenas `ReplicatedStorage > DinografiaRojo > ConnectionCheck`. Se aparecerem remoções ou mudanças fora desse marcador, cancelar e revisar.
5. Confirmar no Explorer que `ConnectionCheck.Value` contém `Dinografia: Rojo conectado`.

O `default.project.json` preserva instâncias desconhecidas e não mapeia Workspace, Blue ou os scripts existentes. O RBXM em `src/` continua sendo uma fonte de referência, ainda fora da sincronização. Após comparar as fontes com o jogo completo, ampliaremos o mapeamento.

O build `build/dinografia-rojo-check.rbxlx` valida apenas essa configuração mínima; não é uma cópia do jogo completo. A sincronização dentro do Studio e o comportamento do jogo precisam ser verificados separadamente.

Referências: [instalação oficial](https://rojo.space/docs/v7/getting-started/installation/) e [formato do projeto](https://rojo.space/docs/v7/project-format/).
