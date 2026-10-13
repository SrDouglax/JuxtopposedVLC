# M2 — Correção de fidelidade visual

Correção Linux de 13/10/2026 em `feat/m2`. Código compilado e exercitado:
`009ca20a7f111b1164ef0e0474e780e8d655af4a` (sidebar corrigida após a rodada `665c0bffe4`).
A documentação posterior não altera o binário.

## Referências e resultado

- Biblioteca/shell `970:2703`: contexto completo recuperado do cache M1,
  [captura congelada](reference/m1/shell970.png) e medidas do canvas 1920×1080.
  A imagem 1024×576 é uma redução, não a escala de implementação.
- Painel de faixas: variante Controls audio `496:2495`, consultada no Figma público
  pelo navegador. Três abas Video/Audio/Subtitles, seleção com ícone original e
  sublinhado laranja. Playback permanece no rodapé para conservar taxa/capítulos/bookmarks.
- Add Subtitles `1911:7545`: frame 1048×800, barra superior compacta, linhas com
  mídia à esquerda, arquivo SRT à direita e conector pontilhado, Cancel à esquerda,
  Save à direita. A seleção usa arquivos e destinos reais do modelo ML.
- Recursos SVG do shell e PNGs exportados pelo usuário foram copiados sem redesenho
  ou recoloração. [Proveniência e hashes](evidence/m2-visual/assets.json).
  Correção do mapa antigo: `764ef.svg` é sort, `80d5a.svg` é search e `97a9d.svg`
  é plus. A grade usa o PNG grid original, não o SVG plus nomeado grid no cache.

| Área | Alteração aplicada | Evidência nativa |
| --- | --- | --- |
| Biblioteca | Sidebar 217 px, navegação plana; thumbnails 316×178, raio 12, margens/gaps horizontais 20, gap vertical 40, títulos Inter regular 16 com intervalo 20 | [1920×1080 corrigida](evidence/m2-visual/sidebar-expanded.png) |
| Cabeçalho | Breadcrumb, contagem real, sort, alternância de vista, busca permanente 325×34, adicionar pasta e abrir mídia com ações existentes | [Busca](evidence/m2-visual/library-search.png), [lista](evidence/m2-visual/library-list.png) |
| Miniplayer | Card 391 px com padding 8, vídeo 375×211, seek e metadados; width reduzida abaixo de 900 px | [1280×720](evidence/m2-visual/library-1280.png), [720×540](evidence/m2-visual/library-pip-720.png) |
| Playlist | Breadcrumb mantém a categoria e o nome da coleção; ações quebram linha quando necessário | [720×540](evidence/m2-visual/playlist-720.png) |
| Faixas | Abas e ícones originais, check laranja, dispositivo e faixas reais; rodapé sem corte de texto | [Áudio 2](evidence/m2-visual/tracks-audio-second.png), [None](evidence/m2-visual/tracks-audio-none.png), [720×540](evidence/m2-visual/tracks-720.png) |
| Legendas | Modal e linhas alinhados ao frame, destino editável sem moldura permanente de combobox | [Matching](evidence/m2-visual/subtitles-matched.png), [atribuição manual pequena](evidence/m2-visual/subtitles-manual-720.png) |

Na captura de 1920, os cinco cards começam em x=237/573/909/1245/1581 e y=132.
O conteúdo do miniplayer ocupa 375×211 e o card fica a 6 px das bordas inferior/direita.
Os vídeos coloridos são fixtures locais reais decodificadas pelo VLC, não imagens
ou dados demonstrativos inseridos na interface.

## Verificação proporcional

Build incremental Qt Autotools passou. Registros dos componentes novos em
Autotools/Meson e existência de todos os arquivos qrc conferidos. `git diff --check` passou.
Execução nativa em Ubuntu 24.04, Qt 6.4.2, X11/Xvfb, Qt Quick software, escala 1.
Capturas cobrem 1920×1080, 1280×720 e 720×540.

- Seek do miniplayer levou a posição a ~60,7 s; clique de pausa retornou `Paused`
  por MPRIS. Botão de fila abriu a fila real. [Valores](evidence/m2-visual/seek.txt),
  [pausa](evidence/m2-visual/paused.txt), [fila](evidence/m2-visual/mini-queue.png).
- Áudio 2, áudio None e restauração, legenda 2, Off e restauração conferidos no
  popup nativo. Playback permaneceu acessível em janela pequena; botão 0,5×
  retornou [Rate=0.5](evidence/m2-visual/rate.txt) por MPRIS. Show Preferences
  abriu a janela nativa de preferências; Escape fechou sem salvar.
- Matching e alteração manual das linhas de legenda funcionaram. Cancel deixou
  o banco inalterado. Save fechou o modal, preservando exatamente duas associações
  corretas e sem duplicação. [Resultado com SHA/hash](evidence/m2-visual/result.json).
- Busca/lista reutilizam a prova da sessão visual-final; alterações posteriores
  limitaram-se ao Flow de ações da playlist e largura do miniplayer pequeno.
  As provas funcionais M2 de persistência/reinício continuam em [m2.md](m2.md).

A sessão final não teve componente indisponível, TypeError, loop de binding ou
asset ausente nas telas exercitadas. O aviso anterior `MainDisplay.qml:120 scaleAxis`
continua presente neste Qt. Não houve alteração no núcleo nesta correção.

## Limites do aceite

Aceite das diferenças acima nas telas M2 conferidas. Não é declaração de igualdade
pixel a pixel de todos os frames do redesign. Dados, seleção, traduções e número
de dispositivos variam conforme o perfil e a mídia. O painel conserva controles
adicionais de delay e Playback. O topo do modal mostra o número real de destinos;
o serviço atual não fornece um caminho agregado para imitar o exemplo do Figma.
GPU/RHI, Wayland, outros temas, DPI 150%/200% e Windows não foram comprovados nesta
rodada. A rodada Windows permanece para o final acordado; os caminhos comuns e
os manifests foram preservados. Música e preferências completas seguem o escopo M3.

## Correção do recuo da seleção da sidebar

A captura anterior deixou passar um erro: o destaque ocupava x=0…215,
fora do painel interno com margem de 8 px. O fundo dos delegates agora usa
insets de 8 px dos dois lados; o conteúdo inclui o padding de 16 px do painel
e wrappers de ícone 30/32 px presentes no contexto do Figma. O modo recolhido
conserva um padding próprio para manter os ícones dentro da largura disponível.

Build incremental passou. Pixels da captura nativa confirmam o destaque em
x=8…207 e a margem externa preservada em 1920×1080 e 720×540. Hover de Add item
e alternância expandido/recolhido também foram conferidos. Não foram repetidos
os fluxos M2 sem relação com esse ajuste. [Captura pequena](evidence/m2-visual/sidebar-720.png),
[resultado e hash do binário](evidence/m2-visual/sidebar-result.json).
