# M3 — cobertura estática de player, biblioteca, efeitos e componentes

Estado examinado: checkout integrado `feat/m3` em `f201cd4af341e2f9332cbb2d0e441da8d6b5d296` (inclui `a5db9f42c0` e a correção Off `afedc938b1`). Referências: `build-m3/reference/export/manifest.json`, seus PNGs e `.specs/features/redesign/reference/inventory.json`. Os primeiros 103 nomes dos dois inventários coincidem, na mesma ordem, após retirar o sufixo numérico do PNG; por isso os IDs abaixo são associações inequívocas. `Components.png` e `Designs.png` não possuem node ID nesse inventário. Esta atualização estreita revisou bindings/caminhos novos contra o fonte; não executou build, player, captura integrada ou comparação de pixels. “Implementado” significa caminho de código ligado a API real, não paridade visual nem sucesso nativo. Os 19 Settings, 11 Onboarding e `Keyboard Shortcuts.png` já constam em `m3-coverage-settings.md` e não se repetem aqui.

## Telas de player e biblioteca

| Export (node ID) | Cobertura funcional no código integrado | Estado visual e lacuna concreta |
| --- | --- | --- |
| `Icon.png` (`42:356`) | Asset de identidade; não é fluxo de player. | Referência visual de ícone, sem critério funcional autônomo. |
| `Player.png` (`187:328`) | `Player.qml`, `TopBar`, `ControlBar`, `PlaylistPane` usam player e fila reais. | Composição geral de vídeo/queue presente; densidade, proporções e estado exato do PNG requerem captura. |
| `Player-1.png` (`970:3308`) | Grid da biblioteca e mini player ligado a `MainCtx.videoSurfaceProvider`. | Exemplo com mídia ilustrativa: capa e dados dependem da biblioteca real; posição/overlay exigem prova visual. |
| `Player-2.png` (`970:3792`) | Lista da biblioteca e mini player com o mesmo playback. | Variante de lista: não é um segundo player; composição e menu não aferidos pixel a pixel. |
| `Player-3.png` (`970:2703`) | `VideoAllDisplay`, `VideoGridDisplay`, cabeçalho e ordenação de modelos reais. | Cards, busca e toolbar têm implementação; conteúdo/capas do export não são dados garantidos. |
| `Player-4.png` (`970:4028`) | Mesmo fluxo da biblioteca com lista e alternância de vista. | Variante visual de lista; estado de seleção e alinhamento precisam de captura integrada. |
| `Player-5.png` (`6261:15078`) | `HomePage` liga recentes/continue watching e atalhos para conteúdo real. | Blocos e mini player dependem de histórico e mídia indexada; não há dados exemplares fixos. |
| `Player-6.png` (`247:445`) | Superfície de vídeo, navegação e controles do player. | Referência de estado limpo/controles; a visibilidade varia com hover e `minimalView`. |
| `Player - Music.png` (`4767:23726`) | `MusicView` contém `AudioContent`, capa de mídia, metadados, controles, letra e `ArtworkBackdrop` borrado. | Capa/arte e letra vêm da mídia; amostra exata e distribuição visual não aferidas em runtime. |
| `Player - Music-1.png` (`4778:25123`) | Mesma tela de música junto da fila real (`PlaylistPane`). | Layout com fila existe conceitualmente; largura, blur e contraste dependem de captura. |
| `Player - hide UI.png` (`3328:11554`) | `HideUIAction` alterna `MainCtx.minimalView` com ação Show/Hide. | Ocultação da chrome usa estado real; a imagem de referência não comprova que toda sobreposição desapareça em cada condição. |
| `Player - Light.png` (`2425:13624`) | `VLCStyle.redesign` oferece ramificações Light/System; `LibraryMiniPlayer` aplica cores claras específicas. | Paleta do player, fila e header não foi comparada visualmente nesta revisão; tema claro não equivale a inverter todas as cores. |
| `Miniplayer.png` (`970:3091`) | `LibraryMiniPlayer` reúne `PIPPlayer`, seek em `Player.position`, título/metadados e `MiniPlayerQueue`; `MainDisplay` o monta com vídeo embutido. | Cartão expandido/compacto e controles sobre vídeo aproximam os estados do export; composição de cada estado, foco e drag precisam de teste. Áudio sem vídeo usa outro mini player (`MiniPlayer.qml`), não este cartão. |
| `Open network stream.png` (`6216:13614`) | `OpenMediaButton` chama `DialogsProvider.openNetDialog()` e há `openUrlDialog()` nativo que converte URL e adiciona à playlist. | O modal customizado do PNG, entrada multilinha e “Add to playlist” nomeada não foram encontrados como tela QML equivalente; fluxo abre diálogo nativo. |
| `new playlist.png` (`6259:14954`) | `PlaylistCreateDialog` solicita título + arquivo(s), chama `MLPlaylistListModel.create` e respeita `transactionPending`. | Não há drop zone/capa de playlist nem criação vazia nesse popup; o botão só habilita com pelo menos um arquivo. Persistência precisa de prova de reinício. |

## Editor, perfis e menus do player

`ToolbarEditorDialog` agora é um `Popup` modal sobre o `T.Overlay.overlay` do player e usa `MainCtx.controlbarProfileModel`: seleção, New, Clone, Delete, Save e Cancel (`reload()`). `ToolbarEditor` e `ToolbarEditorButtonList` fazem drag and drop nas seções reais do control bar; `PlayerControlbarControls.controlList` inclui delegates ativos para HDR, Zoom, Favorite, File Name, Artist Name, Duration, Frame Rate, Resolution, Divider e High Resolution Time. O editor coloca seu painel sobre a superfície atual e uma faixa de drop no rodapé, mas posição exata e feedback de arraste ainda exigem captura. Perfis salvos também armazenam um subconjunto seguro de configurações, aparência, tema e atalhos; segredos, caminhos e integrações globais ficam fora do snapshot.

| Export (node ID) | Cobertura e diferença específica |
| --- | --- |
| `Player - customize.png` (`2107:5604`) | Entrada Customize abre o overlay modal sobre o player real; catálogo e zonas DND existem. Tamanho e composição exatos ainda não foram comparados com o PNG. |
| `Player - customize-1.png` (`2160:6137`) | Perfil selecionável pelo `controlbarProfileModel`; nomes e quantidade vêm do usuário, não de presets fixos da imagem. |
| `Player - customize-2.png` (`2160:6564`) | Arraste do catálogo para seção do player via `ToolbarEditor`; HDR, Zoom, Favorite e metadados agora têm IDs/delegates reais, sem presumir que cada ícone da amostra tenha equivalente. |
| `Player - customize-3.png` (`2160:7005`) | Reordenação por DND nas seções; precisa exercício visual e funcional de hit target e feedback de drop. |
| `Player - customize-4.png` (`2160:7437`) | Remoção ao arrastar controle posicionado para a lista; Cancel recarrega o perfil salvo. |
| `Player - customize-5.png` (`2160:7869`) | Save chama `controlbarProfileModel.save()`; persistência após reinício não foi verificada nesta revisão. |
| `Player - customize-6.png` (`6587:19923`) | Variante de perfil/edição reaproveita editor e catálogo ligados ao modelo real; não há prova de equivalência de cada controle visível no PNG. |
| `Player - customize-7.png` (`2160:8301`) | Exemplo pós-edição: o control bar usa o perfil ativo, mas resultado visual específico depende das escolhas salvas. |
| `Player - customize-8.png` (`2160:8732`) | Outra disposição pós-edição; sem prova nativa da posição exata dos botões a 720/1080 px. |
| `Profiles.png` (`6648:20666`) | `ProfilesMenu` lista perfis **existentes**, marca `selectedProfile`, salva a troca e abre o editor em “New profile…”. New não cria imediatamente: criação/clonagem e Save estão no editor. Perfis agora guardam layout e snapshots seguros de preferências/aparência/atalhos, aplicados com rollback em falha; “Movies/Shows/Music/Work” do PNG não são nomes garantidos. Não há prova nativa do efeito completo ou persistência após reinício. |

## Efeitos de áudio e vídeo

`EffectsDialog` abre tabs Audio/Video. `AudioEffects` e `VideoEffects` são pontes C++ para filtros do core, com begin/save/cancel e disponibilidade condicionada à mídia/filtro instalado. O visual é uma janela estreita com seções; falta comparação renderizada com o export. A microcopy no estado sem áudio foi corrigida para “Play audio to preview and edit audio effects.”. `AudioVisualizationDialog` lista `Player.audioVisualization` e seleciona com `toggleIndex`; `HdrOutputDialog` usa a ponte `HdrOutput` e as escolhas nativas de `pl-output-hint`. Ambos têm abertura ligada ao player, mas resultado visual e dispositivo efetivo ainda não foram exercitados.

| Export (node ID) | Cobertura e lacuna |
| --- | --- |
| `Audio - Compressor Settings.png` (`536:1513`) | `FilterSection`/`FilterPanel` usam filtro real `compressor` e propriedades do bridge; sliders e liga/desliga dependem de áudio ativo. |
| `Audio - Equalizer.png` (`6114:13610`) | `EqualizerPanel` liga equalizador, bandas, preset VLC e two-pass; valores podem variar da amostra do PNG. |
| `Audio - Spatializer Settings.png` (`536:1703`) | Seção `spatializer` real; controles só operam se módulo disponível. |
| `Audio - Stereo Widener.png` (`612:1223`) | Seção `stereo_widen` real; mesma condição de disponibilidade. |
| `Video - Essential.png` (`536:1855`) | `VideoEffectsPanel` expõe filtros reais como adjust/sharpen e congêneres; agrupamento/copy não são equivalentes integrais do PNG. |
| `Video - Crop.png` (`543:990`) | `CropPanel` usa API real de crop; prévia/valores variam com vídeo. |
| `Video - Colors.png` (`614:1430`) | Filtros de cor do `VideoEffects` existem (`adjust`, `colorthres`, `sepia` etc.); não há garantia de controles 1:1 com a amostra. |
| `Audio Visualizer.png` (`2372:8639`) | **Implementado no código:** botão em `AudioContent` abre `AudioVisualizationDialog` com modos reais de `Player.audioVisualization`, seleção/estado do modelo e opção Disabled; nomes dependem dos módulos VLC instalados. Visual e troca efetiva de módulo não validados nativamente. |
| `HDR Options.png` (`2372:8733`) | **Implementado parcialmente:** controle HDR abre `HdrOutputDialog`; `HdrOutput` consulta `pl-output-hint`, permite apenas Auto/Off/HDR10/HLG se o renderer libplacebo expuser esses valores e salva para o próximo playback. HDR10+ e Dolby Vision aparecem desabilitados, pois não têm valor nativo nesse backend; saída efetiva depende de renderer, GPU, driver e display compatíveis. Não há prova visual ou de saída HDR em hardware. |
| `EQ presets.png` (`2372:8487`) | Presets do equalizador vêm da API VLC no `EqualizerPanel`; nomes/seleção dependem do core. |
| `EQ.png` (`3178:16769`) | Fragmento de sliders/equalização coberto pelo painel real; espaçamento e cores não aferidos. |

## Associação de legendas e menus da biblioteca

`SubtitleAssociationsDialog` usa `MLSubtitleAssociations` para associar arquivos de legenda a mídia, pasta ou playlist; `SubtitleSourceControls` expõe **alvo selecionável** (`targets`/`selectTarget`) e origens Computer, Link HTTPS direto e OpenSubtitles. O backend baixa links com limite de tamanho/cancelamento e associa às mídias reais; `OpenSubtitlesPanel` usa API REST, busca por título/idioma, seleção de resultado e download autenticado. Requer chave de API do usuário e, para download, conta/credenciais e quota válidas; não há matching automático garantido para todo episódio. O player ativo abre associação local por `LangButton` → `TracksMenu` → `SubtitleTracksPanel`, além dos menus da biblioteca. A mesma aba traz slider de delay, marcas de voz/texto via `DelayEstimator` e preset persistido por pasta/série em `MainDisplay`; o formato v2 distingue Off explícito e lê presets v1. Sem execução, não se comprova download, associação, restauração em mídia seguinte ou exatidão visual.

| Export (node ID) | Cobertura e diferença específica |
| --- | --- |
| `Add Subtitles to Playlist/Folder.png` (`1911:7545`) | Modal ligado a destinos reais, com alvo selecionável e Computer/Link/OpenSubtitles; arquivo e pasta/destino exercitados com Link HTTPS; associação persistida após reinício. Playlist sem prova nova específica. |
| `Add Subtitles to Playlist/Folder-1.png` (`3336:11929`) | Variação de destino múltiplo: `destinations` e `assign(source,destination)` existem; a disposição exata das linhas não foi aferida. |
| `Add Subtitles to Playlist/Folder-2.png` (`1919:8707`) | Variante da lista de legendas; URL HTTPS e busca OpenSubtitles por título/idioma estão ligadas, sujeitas a rede, chave e conta. |
| `Add Subtitles to Playlist/Folder-3.png` (`1919:9278`) | Seleção/atribuição por linha e busca com campo de idioma existem; não há prova de matching automático nem equivalência visual do filtro do PNG. |
| `subtitle multiple.png` (`1915:8397`) | Vários sources/destinations no `MLSubtitleAssociations` e combobox por linha. |
| `subtitle one.png` (`1919:9121`) | Uma legenda/destino usa o mesmo diálogo, com contagem/label dinâmicos. |
| `target.png` (`1959:5325`) | `subtitleTargetPicker` usa catálogo real `associations.targets` e `selectTarget`; a lista depende do item/playlist/pasta disponível no contexto. |
| `origin.png` (`1963:5465`) | `subtitleOriginPicker` alterna Computer, Link e OpenSubtitles, todos com ação ligada; rede exige HTTPS e OpenSubtitles exige credenciais válidas. |
| `sub filename.png` (`6456:13892`) | Fragmento do matching de nome de legenda; `sub-autodetect-fuzzy` é opção real em Settings Subtitles, já descrita na matriz de Settings. Não é o diálogo de associação. |
| `media.png` (`2404:9167`) | Fragmento de opção de mídia; os menus usam seleção/modelo, sem equivalência visual isolada confirmada. |
| `playlist.png` (`2459:9352`) | Fragmento de ação playlist; os modelos e menus de playlist reais não implicam estilo idêntico. |
| `context menu.png` (`2107:5903`) | `MLContextMenu` oferece Play, Enqueue, favoritos, playlist, informação, associação de legenda e ações condicionais; implementado como `NativeMenu`, não popover QML idêntico. |
| `folder context menu.png` (`2139:8935`) | Ações de pasta dependem do modelo/seleção; visual do menu nativo difere do cartão escuro desenhado. |
| `file context menu.png` (`2404:13340`) | `MLContextMenu` oferece ações de arquivo reais, condicionais à mídia; não assumir todas as opções simultâneas do PNG. |
| `playlist context menu.png` (`2459:9389`) | Menu de playlist com operações de modelo; contagem, seleção e ações variam com playlist real. |
| `right-click menu.png` (`6065:13616`) | Menu contextual de player/mídia ligado a ações reais existentes; apresentação exata e itens do export não foram validados em runtime. |
| `menu.png` (`6062:13354`) | Fragmento de menu; `PlayerMenu`, `PersonalizationActions`, `TracksMenu` e menus nativos cobrem ações reais, sem reprodução 1:1 comprovada. |

## Primitivos e estados de referência

Estas imagens são peças da biblioteca visual, não telas completas. Elas servem para avaliar forma, seleção, hover, foco e contraste quando os fluxos acima forem capturados. O código usa `VLCStyle.redesign`, componentes `Widgets`, assets `qrc:///redesign` e modelos reais. A presença de um componente genérico ou asset não confirma cada variante desenhada.

| Export (node ID) | Destino provável e limite da revisão |
| --- | --- |
| `Icon Wrapper.png` (`177:98`) | Ícones/containers de controles; não há fluxo isolado. |
| `volume.png` (`244:184`) | Controle de volume do player; valor real vem de `Player`, estados visuais não comparados. |
| `Controls.png` (`491:1780`) | `ControlBar` e editor overlay com delegates reais; depende do perfil ativo e das escolhas salvas. |
| `thumbnail.png` (`2151:9673`) | `GridItem`/capas da medialibrary; depende de artwork indexada e fallback. |
| `Button.png` (`500:3063`) | Botões `Widgets`/controles do redesign; conjunto de estados precisa comparação renderizada. |
| `Toggle.png` (`536:1014`) | Switch/checkbox de filtros e settings; fragmento sem fluxo próprio. |
| `Values.png` (`804:1208`) | Rótulos de slider/valor em efeitos/controles; dados não devem ser fixados para igualar o desenho. |
| `play.png` (`848:1712`) | Play/pause do `Player`/`MainPlaylistController`, estado dinâmico. |
| `sidebar.png` (`848:1996`) | Navegação de `MainDisplay` para Home/Videos/Music/Network/Playlists/Recent; item ativo depende de rota. |
| `Sorting Options.png` (`856:2215`) | Sort/view de `LibraryHeader` e modelos de biblioteca; opções variam com a página. |
| `View Options.png` (`858:3290`) | Alternância grid/list de páginas de biblioteca; fragmento visual. |
| `Current Time.png` (`1904:7238`) | Tempo atual ligado a playback/seek; tipografia/estado isolado não aferidos. |
| `audio value.png` (`2245:9805`) | Valor de parâmetro de áudio no diálogo de efeitos; filtro ativo determina valor. |
| `Duration.png` (`1905:7312`) | Duração ligada à mídia; fragmento de label. |
| `option.png` (`2107:5935`) | Opção de menu/editor; catálogo atualizado liga IDs como HDR/Zoom/Favorite a delegates, sujeitos à disponibilidade no contexto. |
| `Dropdown.png` (`2372:8300`) | `Widgets.ComboBoxExt`, seletor de visualização e alvo/origem de legendas; estados exatos precisam de captura. |
| `Setting Preset.png` (`2372:8834`) | Preset do equalizador, perfis e preset de legenda usam fontes de verdade distintas; o fragmento visual não prova equivalência entre eles. |
| `setting category.png` (`3021:9835`) | Categoria de Settings; mapeamento funcional consta em `m3-coverage-settings.md`. |
| `Values-1.png` (`3176:16556`) | Fragmento de valor de efeito; não há funcionalidade autônoma. |

`Components.png` e `Designs.png` são pranchas de referência sem node ID no inventário e sem fluxo executável. Não contam como duas telas implementadas.

## Evidência funcional e aceite restante

A [rodada final](m3.md) registra editor overlay Save/Cancel, troca/reinício de perfis com configuração e efeitos, controles reais de FPS/resolução/favorito, Link HTTPS com hash e associação persistente, Off/750 ms entre episódios e faixas tardias, visualizer e capability HDR. Não há alegação de equivalência pixel a pixel.

Falta comparação renderizada integral de103 nodes/variantes,720 px e estados. HDR físico e OpenSubtitles autenticado exigem renderer/display e credenciais compatíveis; HDR10+/DV não são simulados. A revisão não transforma limitações em implementações concluídas.
