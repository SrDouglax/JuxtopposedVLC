# Contrato de referência M1 — player e shell

Status: referências recuperadas e assets preparados; sem implementação, build ou aceite visual do aplicativo nesta tarefa. Nodes: `187:328` (player) e `970:2703` (biblioteca/shell). Canvas Figma: **1920×1080** em ambos; PNGs originais recuperados: **1024×576**. A captura é referência, nunca asset da UI. Redução da captura: 1024/1920; não transformar medidas do PNG em constantes do app.

## Proveniência e integridade

| Referência | Fonte recuperada | Resultado |
| --- | --- | --- |
| Player `187:328` | Consulta original do root em 2026-10-13T02:31:14.203Z; cache `functions.store fc` exportado pelo root | Código completo em `player187/context-0.txt` e `player187/design-context.tsx` (69.882 chars com newline). Instruções originais `context-1.txt` a `context-4.txt`, reunidas em `instructions.txt`. |
| Shell `970:2703` | Consulta original M0 em 2026-10-13T02:50:20.658Z; cache `functions.store figma970:2703` | Resultado integral em `shell970/original-result.json`; código em `design-context.tsx` (47.858 chars com newline); instruções em `instructions.txt`. |
| Screenshot player | `response_item` do rollout root, linha 51; base64 completo | `player187/screenshot.png`, 84.931 bytes; SHA256 `daec4123c8b772bf295726cfe24359e7075f4495f792763676e2c44c3ffdc613`. |
| Screenshot shell | `response_item` do rollout M0 de 23:48:26, linha 70; base64 completo | `shell970/screenshot.png`, 114.747 bytes; SHA256 `d7ea9db32cba82bbfc8d403bcabbce5102bb288697cd1db1b728b8b33da3c3cd`. |

Os eventos MCP do rollout truncam o JSON no meio do código. `player187/design-context.partial.tsx` e `rollout-mcp-result.partial.json` preservam essa evidência parcial; **não são base para implementar**. Usar os arquivos completos recuperados dos caches. Não houve nova chamada MCP. A revisão/número de versão do Figma continua não fornecida.

## Tokens comuns e diferenças por frame

| Papel | Player `187:328` | Shell `970:2703` |
| --- | --- | --- |
| Accent/Logo/Main | `#D37918` | `#D37918` |
| Accent background | `#371F06` | `#371F06` |
| FG principal exportado | `#8F8F8F`; outros estilos `#969696/#6B6B6B` | `#8F8F8F`; outros estilos `#969696/#6B6B6B/#404040` |
| Topbar | `#1B1B1B` | `rgba(25,25,25,0.95)` |
| Panel background | `#191919`; escuro `#090909/#0E0E0E` | `#191919`; exterior sidebar `#0E0E0E`; também `#151515/#090909` |
| Divider | `#222222/#373737` | `#222222` |
| Fonte no contexto completo | Inter Regular | Inter Regular e Semi_Bold |
| Blur | Estilo Figma: BACKGROUND_BLUR raio 50; React exportado `backdrop-blur-[25px]` | Mesma diferença de representação |
| Cantos | 6 px em controles/barra; 4 px no progresso/handle | 6 px sidebar; 12 px thumbs; 14 px mini/painéis conforme contexto |

Não converter a diferença de blur em raio QML arbitrário. Preservar superfície de vídeo/backends e comparar resultado nativo; se efeito não puder ser comprovado, registrar limitação. Tokens Light e demais estados fora destes contextos continuam fora da prova.

## Geometria nativa do frame e adaptação Qt/QML

| Área | Medidas extraídas | Fonte exata do contexto |
| --- | --- | --- |
| Topbar dos dois frames | altura 40; padding 6; ícones raiz 24×24; blocos laterais 300; title 14 px Regular | Player linha 665 em diante; shell linha 83 em diante |
| Player sidebar aberta | 427×986, abaixo do topo; variante `playlists` | Player linha 768: call `Sidebar(...property1=playlists)` |
| Player control bar | altura 54; padding horizontal 20/vertical 11; gap entre grupos 20 | Player linha 769, node `491:2000` |
| Previous/play/next | gap 8; prev/next padding 3×2 e glyph 24; play largura 54, padding L17/R15/Y2, glyph 24, raio 6 | Player linhas 770–783 |
| Current time/duration | slots 76×28, padding 8×2; texto 15 px Regular | Player linhas 786/791; definições no início |
| Seek | track flexível, altura 28, raio 6; inset 2; fill altura 24/raio 4; handle 8×24 | Player linhas 787–790; widths/posição atuais exportadas são **estado demonstrativo**, derivar de position/length |
| Volume | wrapper 88×28; SVG background 89×27.3633, fill 86×24.56, mask 33×30 | Player definição Volume linhas 65–84 e call linha 803; preservar offsets/mask do contexto |
| Player controles da direita | grupos gap 8 e 12; wrapper usual largura 30/padding 4; glyph raiz 24 | Player linha 793 em diante |
| Shell sidebar | largura 217; exterior padding 8; interior padding X16/Y12, gap 14, raio 6; labels 14 px; gap ícone/texto 8 | Shell linhas 150–245 |
| Shell header de conteúdo | navegação/breadcrumb, contador, sort/view/search e menu; medidas constam no contexto | Shell linhas 257–341 |
| Shell grid de referência | item largura 316; gap colunas 20/linhas 40; gap thumbnail/texto 20; thumbs aspecto 160:90/raio 12; nomes 16 px | Shell linha 344 em diante; layout precisa responder à janela, sem hardcode de 15 itens |
| MiniPlayer no shell | posição e geometria fornecidas pelo contexto completo; vídeo e metadados são dados reais | Shell seção final; smoke M1 não comprova todos os estados M3 |

Usar `VLCStyle`/`MainCtx.dp` para escala e os layouts QML nativos; dimensões são do estado de referência a 100%, não coordenadas absolutas para qualquer janela. Fontes/ícones devem resolver por qrc em Linux e Windows. Interação e texto traduzível continuam nos controllers/modelos; nomes/tempos de “The Wand” não entram como dados do produto.

## Assets locais e nomes sugeridos

Mapa executável para cópia/registro pelo root: **`m1-assets-map.json`**. Contém caminho local, URL original, símbolo, hash, dimensões da raiz e destino/qrc sugeridos por entrada. Manifests integrais por frame: `player187/assets-manifest.json` e `shell970/assets-manifest.json`.

| Nome qrc sugerido sob `qrc:/redesign/` | Arquivo original e origem | Slot/observação |
| --- | --- | --- |
| `logo.svg` | shell `29ba5.svg` | topbar; raiz 24×24 |
| `home.svg` / `video.svg` | shell `27471.svg` / `b610e.svg` | sidebar; raiz 24×24 |
| `network.svg` / `playlists.svg` / `recent.svg` | shell `6db55.svg` / `c9326.svg` / `50e8b.svg` | sidebar; raiz 24×24 |
| `add.svg` / `search.svg` / `sort.svg` / `grid.svg` / `menu.svg` | shell `bfdda.svg` / `764ef.svg` / `80d5a.svg` / `97a9d.svg` / `54fdc.svg` | slots do shell; raiz 24×24 |
| `sidebar.svg` | shell `d7959.svg` | raiz 24×24, slot interno do toggle 18×18; preservar wrapper |
| `minimize.svg` / `maximize.svg` / `fullscreen.svg` / `close.svg` | shell `928df.svg` / `dccb1.svg` / `d41b8.svg` / `9c2da.svg` | controles topbar; `d41b8.svg` **não é play** |
| `play.svg` / `previous.svg` / `next.svg` | player `4ecaf.svg` / `1f761.svg` / `617e8.svg` | play call linha 777; prev/next resolvidos pela função Icon linha 151 |
| `volume-background.svg` / `volume-fill.svg` / `volume-mask.svg` | player `07eaa.svg` / `2be1c.svg` / `f1da4.svg` | partes do volume; não substituir por triângulo redesenhado nem ignorar mask |
| `settings.svg` | `1b0f7.svg` | função Icon(settings) dos contextos |
| `music-shell-literal.svg` | shell `1b0f7.svg` | Slot Music do shell linha 189 referencia literalmente o mesmo asset de settings; conflito registrado abaixo |
| `music-player.svg` | player `beb21.svg` | função Icon(name=music), referência diferente do slot literal do shell |

**Diferença a revisar:** o código gerado para shell Music referencia `imgFrame1/1b0f7.svg`, também usado por settings; a função Icon(music) do player usa `beb21.svg`. Os dois são assets originais, mas não equivalências automaticamente intercambiáveis. Conferir o slot na captura/Figma e registrar decisão; não substituir silenciosamente por glyph do VLC ou redesenho. O mapa conserva os nomes distintos.

SVGs baixados diretamente pelas URLs dos contextos originais, conforme suas instruções: **43 player + 23 shell**, todos HTTP 200, arquivo não vazio e hash verificado. Algumas cópias compartilham conteúdo; o mapa registra a origem exata. PNGs de vídeo/thumbnails foram apenas consultados por HEAD (HTTP 200), sem download. Vídeo/capas/thumbnails são dados dinâmicos; **nenhum raster demonstrativo foi preparado para o app**.

Não alterar width/height raiz dos SVGs nem usar 100% global para redimensionar assets. Preservar posições/wrappers/offsets do contexto; validar geometria efetiva no render QML antes de considerar T05/T06/T08 aceitos. URLs temporárias ficam somente nesta referência ignorada, nunca em QML runtime.

## Inter oficial e empacotamento

Fonte oficial: [Inter](https://rsms.me/inter/), repositório [rsms/inter](https://github.com/rsms/inter), commit `353b61b9f4430d5f420d56605a6e7993e0941470`. Arquivos locais: `fonts/InterVariable.ttf` e `fonts/LICENSE.txt`. Proveniência e URLs pinadas: `fonts/manifest.json`.

- TTF: 879.708 bytes; SHA256 `4989b125924991b90d05b2d16e0e388c48f7d5bb8b30539bbf9c755278d0ccaf`.
- Licença SIL Open Font License 1.1: 4.380 bytes; SHA256 `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a`.
- `fc-scan` confirma família **Inter Variable** e instâncias Regular/Medium/SemiBold, entre outras.
- FontTools não está disponível no Python consultado; nenhum pacote foi instalado e nenhuma fonte modificada/instanciada.
- Alias qrc esperado pelo shell pode ser `qrc:///fonts/Inter-Regular.ttf`, apontando para o arquivo **variable original**. Não declarar que esse alias é uma Regular estática; FontLoader.name deve usar a família efetivamente carregada. Pesos 400/500/600 para Regular/Medium/SemiBold.
- Empacotar licença junto da fonte e verificar seleção/renderização no Qt 6.4. A versão de Inter do Figma não foi retornada; família/pesos estão identificados, métricas/glyphs finais ainda precisam comparação visual.

## Reuso confirmado e fronteiras M1

Reusar `MainInterface.qml`, `MainDisplay.qml`, `SideNavigationPane.qml`, `SideNavigationDelegate.qml`, `MenuTopbar.qml`/`LocalTopbar.qml`, `VLCStyle.qml`/ColorContext e widgets CSD para janela/navegação/escala. Não substituir asset exato por ícone VLC apenas por já existir um glyph.

Para reprodução, `ControlBar.qml`, `PlayerControlLayout.qml`, `SliderBar.qml`, `VolumeWidget.qml`, `PlaylistController` e `PlayerController` já fornecem bindings e comandos reais. A adaptação visual deve preservá-los, incluindo seekable/pausable/muted/fullscreen e estados sem mídia. Não editar ou trocar a superfície de vídeo para reproduzir screenshot.

Este contrato prepara T05/T06/T08; não implementa grid/miniplayer/playlist de M2/M3 por o frame shell conter essas áreas. Nenhum botão pode simular uma ação indisponível. Liberar alterações visuais permanece decisão do root após revisão do contrato e definição dos arquivos atribuídos.
