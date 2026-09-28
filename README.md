# Dinografia

Letras e aventuras com dinossauros. Primeiro protótipo: **V de velociraptor**.

## Avenida A–Z — versão para teste

A avenida reúne **26 letras e o primeiro animal de cada letra da lista**, em 13 pares de jaulas. Cada letra tem uma faixa de escrita mais larga, pintura por aproximação e abertura da porta. Comece em qualquer parte, desenhe na ordem e direção que preferir e retome livremente após levantar o dedo. O ponto amarelo sugere uma área que falta; não é obrigatório segui-lo. Pequenas lacunas são aceitas, mas os traços principais precisam ser pintados.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-avenue.ps1
```

Abra **`build/Dinografia-AvenidaAZ.rbxlx`** no Studio e clique em **Play**. O cenário é criado ao iniciar o jogo. Comece no A, alterne os lados da avenida e avance até Z e a saída. **Minha coleção** mostra as 26 espécies e o que já foi obtido. Repetir uma letra abre a porta novamente, sem duplicar a coleta.

Cada jogador tem sua coleção durante a sessão; ela sobrevive ao respawn, mas ainda não é salva entre entradas no jogo. As portas são compartilhadas. Até seis animais próximos ficam expostos e os seis coletados mais recentes acompanham o jogador em miniatura. Todos os 26 permanecem registrados na coleção. Os acompanhantes são visuais locais, sem colisão; outros jogadores ainda não veem sua comitiva.

Os modelos são **originais, procedurais e provisórios**, com silhuetas diferentes por espécie. A avenida usa um velociraptor estilizado; a Blue original continua no protótipo V abaixo. Consulte [modelos e substituição futura](docs/dinosaur-models.md), [validação da avenida](docs/validacao-avenida.md), [backlog](docs/backlog.md) e [produção de áudio](docs/audio-production.md).

Para sincronizar esta versão, execute `.\.tools\rojo\7.7.0\rojo.exe serve alphabet.project.json` e conecte a `localhost:34874`. Abra o arquivo da avenida ao testar; o arquivo antigo continua sendo apenas a atividade V.

Esta versão foi compilada e teve a lógica testada automaticamente. **Aparência, conforto, áudio, multiplayer e desempenho ainda exigem validação no Studio e no dispositivo. Não é uma versão aprovada para publicação.**

Durante Play no Studio, o Output registra tempos, contatos e movimento sem avanço por tentativa, além das médias por letra. Veja [como coletar e interpretar as métricas](docs/writing-metrics.md).

## Preparar e gerar o protótipo V

No Windows x64, execute na raiz do repositório:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-rojo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-prototype.ps1
```

O instalador baixa o Rojo 7.7.0 oficial e verifica o SHA256. O build usa `prototype.project.json`, `src/` e `assets/`; não depende de configurações do editor, memória de agente ou arquivos de referência locais.

No Roblox Studio, use **File > Open from File** e abra `build/Dinografia-PrimeiroV.rbxlx`. Não é necessário conectar o Rojo para jogar esse arquivo. Após gerar uma atualização, pare o Play e reabra o arquivo.

## Jogar

Clique em **Play**, aproxime-se da jaula e toque/clique no V da porta. A câmera enquadra a porta; no próximo toque, percorra o sulco começando no ponto amarelo. A tinta preenche a letra conforme o movimento. Ao concluir, a câmera recua, o giroflex acende, a porta sobe e Blue é liberada.

É possível levantar o dedo e retomar, usar ↻ para recomeçar ou × para sair. Mouse também funciona. O sulco simula profundidade na superfície da porta. Após a abertura, Blue segue o jogador e descansa. A porta tenta fechar automaticamente após 18 segundos, quando Blue e jogadores estiverem fora da jaula e da passagem. Se alguém entrar durante a descida, ela reabre. Ao fechar, o V fica pronto para outra escrita e outra abertura; Blue continua livre. A liberação é compartilhada e dura a sessão, inclusive entre respawns de Blue.

A fluidez da escrita foi confirmada em teste manual. Consulte o [roteiro de validação](docs/validacao-prototipo.md) para os demais casos de física, navegação, respawn e dispositivos.

## Áudio

O controle **Som** alterna entre desligado, baixo (padrão) e normal. A escrita permanece utilizável sem áudio. A pintura emite som apenas enquanto avança; conclusão, giroflex, motor e Blue têm efeitos próprios. O motor acompanha abertura e fechamento, incluindo reversão por obstrução. Consulte [fontes e permissões de áudio](docs/audio-assets.md).

## Testes

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-luau.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prototype.ps1
```

O instalador baixa o Luau 0.739 oficial com SHA256 fixo. O teste compila os scripts, executa 88 testes de letras, catálogo, coleção, projeção, pintura e ciclo da porta, e gera os dois jogos. Esses testes não executam o motor Roblox; a validação no Studio e em touchscreen continua necessária.

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
- `src/audio/`: objetos de som, configuração de volume e controlador de reprodução.
- `assets/`: modelos, iluminação e fontes de áudio do projeto.
- `tests/`: testes automatizados da lógica pura.
- `scripts/`: instalação de ferramentas, build e testes reproduzíveis.
- `docs/validacao-prototipo.md`: roteiro de testes no motor.

Configurações pessoais de editor, memória de agente, inspeções, fontes antigas, credenciais, ferramentas baixadas e builds ficam fora do versionamento. O `.gitignore` não remove conteúdo já presente no histórico e não detecta dados pessoais inseridos em arquivos de código ou documentação.

Trabalhar na branch `work/desenvolvimento-inicial`; integrar à `main` somente após aprovação da versão. Os assets extraídos preservam sua origem de terceiros; a licença do repositório não redefine os direitos desses assets.

Referências: [instalação do Rojo](https://rojo.space/docs/v7/getting-started/installation/) e [formato do projeto](https://rojo.space/docs/v7/project-format/).
