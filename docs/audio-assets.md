# Áudio do Dinografia

Objetos, IDs, volumes e equalização em `src/audio/Objects`; controlador em `src/audio`. Áudios hospedados no Roblox, sem redistribuição das gravações no repositório. Fontes ProSoundEffects verificadas como públicas, gratuitas e aprovadas no catálogo; metadados em `assets/audio/catalog-metadata.json`.

| Objeto | Fonte | Volume-base | PlaybackSpeed |
| --- | --- | --- | --- |
| Paint | [Writing Soft Scraping Movements 1](https://create.roblox.com/store/asset/9120981044) | 0,75 | 0,85 |
| Complete | [Magic Glows Soft Clusters Of Chiming Hits 1](https://create.roblox.com/store/asset/9116394545) | 0,56 | 0,75 |
| Motor | [Hollow Rumble 2](https://create.roblox.com/store/asset/9112795571) | 0,07 | 1,00 |
| Beacon | [Tone Clusters Short Burst Of Soft Beep Tones](https://create.roblox.com/store/asset/9126132982) | 0,38 | 0,55 |
| Blue | [Goliath Vocal Deep Growling Voice 18](https://create.roblox.com/store/asset/9114628357) | 0,40 | 1,00 |

O motor anterior foi substituído por uma gravação descrita como ruído grave contínuo. Equalização: HighGain -30 dB e MidGain -12 dB, sem reforço de graves. O arquivo tem 76,8 s, mas toca somente durante o movimento, com entrada e saída suavizadas. Rabisco e Blue receberam aumento individual; o plim mantém asset, pitch e equalização, com aumento pequeno de volume. O volume geral não aumentou.

Blue usa uma vocalização de criatura grave e articulada, de 1,2 s segundo o catálogo. A voz soprosa anterior carregava e era disparada, mas não foi ouvida no teste manual. Dispara ao receber Open, sem depender da observação do estado intermediário Opening pelo cliente. Perto da jaula sua atenuação é menor. Os parâmetros e descrições não garantem conforto ou audibilidade; avaliar no Studio e no dispositivo final, começando pelo modo baixo.

## Diagnóstico

No Studio, Output informa carregamento/falha por nome e registra Playing Blue quando a reprodução é acionada. No Explorer do cliente, SoundService > DinografiaAudio contém LoadState, PlayCount e PeakLoudness. O pico mede o sinal da fonte, não o volume físico percebido. Sons curtos não são reproduzidos atrasados se ainda estiverem carregando; repetir a interação após carregar. Ausência de som exige distinguir carregamento, disparo e volume.

## Permissões e troca

Crédito: Pro Sound Effects. Uso na experiência conforme [documentação de áudio Roblox](https://create.roblox.com/docs/audio/assets); não são declarados CC0. Disponibilidade de catálogo não garante carregamento futuro. Editar SoundId, Volume e PlaybackSpeed no objeto correspondente, preservando o nome. Para som externo, importar na conta Roblox e conceder permissão à experiência. Não é necessário tornar o jogo público.
## Sincronização e diagnóstico por registros

Registros locais do Studio confirmaram carregamento dos cinco assets e chamadas Playing Beacon/Playing Blue. Portanto, ausência percebida não foi atribuída a falha do notebook. O motor agora usa o trecho 8–10 s do drone, evitando reiniciar seus primeiros instantes a cada movimento; a adequação desse recorte ainda exige escuta. A reprodução acompanha mudanças reais na altura da porta, com tolerância curta para intervalos de replicação e fade de 25 ms.

A atenuação usa a distância do avatar, não da câmera, evitando que o recuo da câmera altere o volume durante a sequência. O giroflex mantém pitch baixo, mas seu filtro foi aliviado (HighGain -6 / MidGain 0) para preservar o tom; Blue usa HighGain -9 / MidGain 0. Os passos do avatar, o rabisco e o plim não foram modificados nesta revisão. No Studio, o fim dos efeitos pontuais registra o pico do sinal da fonte para separar reprodução silenciosa de falha de disparo. Isso não equivale a medição acústica nem comprova conforto.