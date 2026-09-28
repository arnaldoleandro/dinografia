# Produção de áudio — trabalho futuro

Este guia é um backlog de produção. Não adiciona nem substitui os sons atuais. As durações, níveis e taxas sugeridos abaixo são pontos de partida para escuta no jogo, não requisitos do Roblox nem garantia de conforto.

## Obter sons e registrar a origem

1. Procurar primeiro no Creator Store, usando termos como `creature greeting`, `soft growl` e `animal breath`; ouvir o trecho inteiro antes de escolher.
2. Para arquivos externos, preferir criação própria ou licença que permita edição, uso na experiência e, separadamente, distribuição do arquivo no repositório público. No [Freesound](https://freesound.org/help/faq/#licenses), a licença varia por arquivo; CC0 facilita a reutilização e CC BY exige atribuição. Não tratar o rótulo de um upload como prova da origem de um áudio de filme.
3. Efeitos de interface podem partir de pacotes como [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds), publicado com CC0.
4. Para sons famosos de filmes, identificar o titular e obter uma licença que cubra a utilização pretendida antes de importar. Outra opção é produzir uma vocalização original com caráter cinematográfico, usando gravações próprias ou fontes licenciadas, sem extrair a trilha do filme.
5. Registrar título, autor público, URL, licença e versão, data de obtenção, modificações, permissão de redistribuição e ID Roblox. Guardar comprovações privadas fora do repositório; publicar apenas créditos necessários e documentação técnica, sem dados pessoais.

## Gravar e editar

- Gravar em um cômodo silencioso com cortinas, tapete ou outros materiais que reduzam reflexões; afastar o microfone de ventilação, teclado e superfícies que vibrem. Não gravar conversas ou mídia ao fundo.
- Usar microfone fixo e gravar várias tomadas curtas, incluindo alguns segundos de silêncio do ambiente. Um gravador de celular serve para ensaios; escolher equipamento definitivo somente depois de avaliar as tomadas.
- Arquivar o original em **WAV PCM, 48 kHz, 24 bits**, quando o gravador suportar. Não há benefício em converter uma gravação comprimida para fingir qualidade superior. Preservar o original para edição.
- Preferir **mono** para a voz de um animal ou mecanismo localizado. Reservar **estéreo** para ambiência ou música; conferir a compatibilidade mono.
- Deixar margem antes da saturação, remover ruído apenas quando necessário e aparar silêncios excessivos. Aplicar pequenas entradas e saídas graduais para evitar estalos.
- Equalizar e comparar os sons em conjunto. A normalização de picos isoladamente não iguala o volume percebido; não amplificar tudo automaticamente. Avaliar agudos persistentes, graves que desaparecem em alto-falantes pequenos e sobreposição de efeitos.

## Cues e durações iniciais

| Uso | Duração sugerida | Condição futura |
| --- | --- | --- |
| Blue cumprimenta | 0,4–1,5 s | Aproximação, com intervalo mínimo e sem repetir a cada passo |
| Blue curiosa ou contente | 0,5–2 s | Interação ou chegada, escolhendo entre variantes |
| Blue em repouso | 1–3 s | Evento ocasional; longos intervalos silenciosos |
| Libertação | 1–3 s | Uma vez por abertura válida, sem empilhar vozes |
| Rabisco | Loop de 1–3 s | Apenas enquanto o traço avança |
| Motor | Loop de 2–5 s | Início e parada acompanhando o movimento real |
| Confirmação/giroflex | 0,2–1 s | Sinal breve, sem competir com a voz |

Para loops, testar a emenda e usar transição cruzada quando necessário; conferir também parada, reversão e retomada. Evitar um ataque ou silêncio longo dentro do trecho repetido. Esses tempos serão ajustados à animação e à escuta.

## Exportar, importar e organizar

Manter o master WAV e exportar preferencialmente WAV para importar. OGG Vorbis pode ser uma alternativa menor: ensaiar **96–128 kb/s mono** ou **160–192 kb/s estéreo**, ouvindo os artefatos antes de aceitar. Esses valores são recomendações de exportação, não controles da compressão final da plataforma. Evitar sucessivas recompressões de MP3/OGG.

O Roblox aceita uma faixa/stream em **MP3, OGG, WAV ou FLAC**, abaixo de **20 MB e 7 minutos**, com taxa de amostragem de até **48 kHz**. A importação transcodifica o arquivo; áudio privado precisa de permissão para a experiência e aprovação de moderação. Conferir os requisitos novamente ao executar esta etapa. [Requisitos oficiais de áudio](https://create.roblox.com/docs/audio/assets).

Organização proposta para quando os arquivos forem produzidos:

- `assets/audio/source/`: masters e projetos de edição cuja redistribuição foi autorizada; material restrito fica fora do repositório.
- `assets/audio/export/`: derivados aprovados, por exemplo `velociraptor_greeting_01.wav` e `gate_motor_loop_01.ogg`.
- `assets/audio/licenses/`: licenças públicas e créditos necessários, sem contratos ou dados pessoais.
- `src/audio/Objects/`: objetos usados pelo jogo, mantendo a separação existente entre assets e lógica.
- `docs/audio-assets.md`: origem, IDs, permissões e instruções de reprodução do conjunto efetivamente usado.

Revisar metadados das futuras exportações para não publicar nome de usuário, caminhos locais ou localização de gravação; manter atribuições obrigatórias. Este guia não altera nem apaga os metadados existentes.

## Aceite antes de integrar

- [ ] Asset carrega para uma conta de teste autorizada na experiência privada, sem depender da conta que o enviou.
- [ ] Cada evento é audível em volume baixo, sem mascarar os demais; modo desligado interrompe tudo.
- [ ] Fones, alto-falante de tablet e computador testados, com início em volume baixo e escolha livre de silenciar.
- [ ] Sem cortes na repetição, estalos, acúmulo de vozes ou som após destruir o animal/encerrar a sessão.
- [ ] Motor acompanha exatamente abertura, fechamento e reversão; sons respeitam a distância definida.
- [ ] Origem e licença verificadas; gravações, exportações e créditos conferidos antes de enviar ao remoto.
