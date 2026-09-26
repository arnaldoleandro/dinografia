# Dinografia

Letras e aventuras com dinossauros. Primeiro protótipo: **V de velociraptor**.

## Preparar e gerar o jogo

No Windows x64, execute na raiz do repositório:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-rojo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-prototype.ps1
```

O instalador baixa o Rojo 7.7.0 oficial e verifica o SHA256. O build usa `prototype.project.json`, `src/` e `assets/`; não depende de configurações do editor, memória de agente ou arquivos de referência locais.

No Roblox Studio, use **File > Open from File** e abra `build/Dinografia-PrimeiroV.rbxlx`. Não é necessário conectar o Rojo para jogar esse arquivo. Após gerar uma atualização, pare o Play e reabra o arquivo.

## Jogar

Clique em **Play**, aproxime-se da jaula e toque/clique no V da porta. A câmera enquadra a porta; no próximo toque, percorra o sulco começando no ponto amarelo. A tinta preenche a letra conforme o movimento. Ao concluir, a câmera recua, o giroflex acende, a porta sobe e Blue é liberada.

É possível levantar o dedo e retomar, usar ↻ para recomeçar ou × para sair. Mouse também funciona. O sulco simula profundidade na superfície da porta. Após a abertura, Blue segue o jogador e descansa; repetir a atividade não fecha a jaula. A liberação é compartilhada e dura a sessão, inclusive entre respawns de Blue.

A fluidez da escrita foi confirmada em teste manual. Consulte o [roteiro de validação](docs/validacao-prototipo.md) para os demais casos de física, navegação, respawn e dispositivos.

## Testes

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-luau.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prototype.ps1
```

O instalador baixa o Luau 0.739 oficial com SHA256 fixo. O teste compila os scripts, executa 23 testes do percurso, projeção e suavização da pintura, e gera o jogo. Esses testes não executam o motor Roblox; a validação no Studio e em touchscreen continua necessária.

## Sincronizar com Rojo

Instale o plugin e sirva o protótipo:

```powershell
.\.tools\rojo\7.7.0\rojo.exe plugin install
.\.tools\rojo\7.7.0\rojo.exe serve prototype.project.json
```

Com a cópia do protótipo aberta no Studio, conecte o plugin a `localhost:34873`. A conexão local não exige login no Rojo. Encerre o servidor com `Ctrl+C`.

Para diagnosticar apenas a conexão, `default.project.json` e `scripts/build-rojo.ps1` oferecem um marcador mínimo em `ReplicatedStorage/DinografiaRojo/ConnectionCheck`, usando a porta 34872. Esse projeto não representa o jogo completo.

## Organização

- `src/`: código cliente, servidor e lógica compartilhada.
- `assets/`: modelos e iluminação necessários ao jogo.
- `tests/`: testes automatizados da lógica pura.
- `scripts/`: instalação de ferramentas, build e testes reproduzíveis.
- `docs/validacao-prototipo.md`: roteiro de testes no motor.

Configurações pessoais de editor, memória de agente, inspeções, fontes antigas, credenciais, ferramentas baixadas e builds ficam fora do versionamento. O `.gitignore` não remove conteúdo já presente no histórico e não detecta dados pessoais inseridos em arquivos de código ou documentação.

Trabalhar na branch `work/desenvolvimento-inicial`; integrar à `main` somente após aprovação da versão. Os assets extraídos preservam sua origem de terceiros; a licença do repositório não redefine os direitos desses assets.

Referências: [instalação do Rojo](https://rojo.space/docs/v7/getting-started/installation/) e [formato do projeto](https://rojo.space/docs/v7/project-format/).
