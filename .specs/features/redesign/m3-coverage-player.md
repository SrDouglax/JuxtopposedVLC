# M3 — cobertura estática de player, biblioteca, efeitos e componentes

Estado examinado: checkout integrado `feat/m3` em `9581b880e0bddc613616dedd953f211a20db5e28`. Referências: `build-m3/reference/export/manifest.json`, seus PNGs e `.specs/features/redesign/reference/inventory.json`. Os primeiros 103 nomes dos dois inventários coincidem, na mesma ordem, após retirar o sufixo numérico do PNG; por isso os IDs abaixo são associações inequívocas. `Components.png` e `Designs.png` não possuem node ID nesse inventário. Esta é uma revisão de fonte e exports, sem build, execução, captura integrada ou comparação de pixels. “Ligado” significa ação/binding para API real, não paridade visual nem sucesso nativo. Os 19 Settings, 11 Onboarding e `Keyboard Shortcuts.png` já constam em `m3-coverage-settings.md` e não se repetem aqui.

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

`ToolbarEditorDialog` usa `MainCtx.controlbarProfileModel`: seleção, New, Clone, Delete, Save e Cancel (`reload()`). `ToolbarEditor` e `ToolbarEditorButtonList` usam drag and drop sobre seções reais do control bar e catálogo `PlayerControlbarControls.controlList`. O editor integrado é uma janela própria com prévia no seu corpo, enquanto os exports situam o modal sobre um player contextual; faltam IDs/delegates reais para vários controles desenhados, como HDR, Zoom, Favorite e File Name. Não se deve adicionar botões sem ação apenas para preencher a imagem.

| Export (node ID) | Cobertura e diferença específica |
| --- | --- |
| `Player - customize.png` (`2107:5604`) | Entrada Customize abre editor real; catálogo e zonas DND existem, mas dimensões/contexto do modal diferem da referência. |
| `Player - customize-1.png` (`2160:6137`) | Perfil selecionável pelo `controlbarProfileModel`; nomes e quantidade vêm do usuário, não de presets fixos da imagem. |
| `Player - customize-2.png` (`2160:6564`) | Arraste do catálogo para seção do player via `ToolbarEditor`; controles sem ID no catálogo permanecem ausentes. |
| `Player - customize-3.png` (`2160:7005`) | Reordenação por DND nas seções; precisa exercício visual e funcional de hit target e feedback de drop. |
| `Player - customize-4.png` (`2160:7437`) | Remoção ao arrastar controle posicionado para a lista; Cancel recarrega o perfil salvo. |
| `Player - customize-5.png` (`2160:7869`) | Save chama `controlbarProfileModel.save()`; persistência após reinício não foi verificada nesta revisão. |
| `Player - customize-6.png` (`6587:19923`) | Variante de perfil/edição reaproveita o editor real; catálogo mostrado no PNG excede os controles com delegate. |
| `Player - customize-7.png` (`2160:8301`) | Exemplo pós-edição: o control bar usa o perfil ativo, mas resultado visual específico depende das escolhas salvas. |
| `Player - customize-8.png` (`2160:8732`) | Outra disposição pós-edição; sem prova nativa da posição exata dos botões a 720/1080 px. |
| `Profiles.png` (`6648:20666`) | `ProfilesMenu` lista perfis **existentes** do modelo, marca `selectedProfile`, salva a troca e abre o editor em “New profile…”. New não cria imediatamente: criação/clonagem e Save estão no editor. “Movies/Shows/Music/Work” do PNG não são perfis garantidos nem modos de playback; perfis atuais configuram apenas layout de toolbar. |

## Efeitos de áudio e vídeo

`EffectsDialog` abre tabs Audio/Video. `AudioEffects` e `VideoEffects` são pontes C++ para filtros do core, com begin/save/cancel e disponibilidade condicionada à mídia/filtro instalado. O visual é uma janela estreita com seções; falta comparação renderizada com o export. Há microcopy incorreta em estados sem mídia: “Play audio/video to preview and edit audioBridge.” expõe o identificador interno. `AudioContent` tem botão `Player.toggleVisualization()`, mas a revisão não encontrou seletor QML de modos de visualização. O ícone de HDR existente em assets não estabelece controle HDR.

| Export (node ID) | Cobertura e lacuna |
| --- | --- |
| `Audio - Compressor Settings.png` (`536:1513`) | `FilterSection`/`FilterPanel` usam filtro real `compressor` e propriedades do bridge; sliders e liga/desliga dependem de áudio ativo. |
| `Audio - Equalizer.png` (`6114:13610`) | `EqualizerPanel` liga equalizador, bandas, preset VLC e two-pass; valores podem variar da amostra do PNG. |
| `Audio - Spatializer Settings.png` (`536:1703`) | Seção `spatializer` real; controles só operam se módulo disponível. |
| `Audio - Stereo Widener.png` (`612:1223`) | Seção `stereo_widen` real; mesma condição de disponibilidade. |
| `Video - Essential.png` (`536:1855`) | `VideoEffectsPanel` expõe filtros reais como adjust/sharpen e congêneres; agrupamento/copy não são equivalentes integrais do PNG. |
| `Video - Crop.png` (`543:990`) | `CropPanel` usa API real de crop; prévia/valores variam com vídeo. |
| `Video - Colors.png` (`614:1430`) | Filtros de cor do `VideoEffects` existem (`adjust`, `colorthres`, `sepia` etc.); não há garantia de controles 1:1 com a amostra. |
| `Audio Visualizer.png` (`2372:8639`) | Há `Player.toggleVisualization()` no player, porém não o dropdown Disabled/Spectrometer/Scope/Spectrum/Waveform do export. Lacuna de escolha de modo e estado selecionado. |
| `HDR Options.png` (`2372:8733`) | Não foi encontrada UI QML nem ponte para Auto/Off/HDR10/HDR10+/Dolby Vision/HLG; apenas ícone HDR. Gap funcional e visual, não marcar M3 concluído por presença do asset. |
| `EQ presets.png` (`2372:8487`) | Presets do equalizador vêm da API VLC no `EqualizerPanel`; nomes/seleção dependem do core. |
| `EQ.png` (`3178:16769`) | Fragmento de sliders/equalização coberto pelo painel real; espaçamento e cores não aferidos. |

## Associação de legendas e menus da biblioteca

`SubtitleAssociationsDialog` usa `MLSubtitleAssociations` para associar arquivo(s) de legenda a mídia de arquivo, pasta ou playlist; há seleção de arquivo local, destinos, assign, Save/Cancel. Alvo é apresentado como rótulo do contexto em que foi aberto, não como seletor livre; a origem é apenas “From Computer”. Assim, os caminhos OpenSubtitles e From Link da referência são lacunas reais. As ações “Add subtitles…” aparecem em menus de mídia/playlist apropriados, mas dependem de seleção e backend disponível.

| Export (node ID) | Cobertura e diferença específica |
| --- | --- |
| `Add Subtitles to Playlist/Folder.png` (`1911:7545`) | Modal base, associação persistida pelo backend; o alvo é derivado da abertura e a origem só aceita arquivo local. |
| `Add Subtitles to Playlist/Folder-1.png` (`3336:11929`) | Variação de destino múltiplo: `destinations` e `assign(source,destination)` existem; a disposição exata das linhas não foi aferida. |
| `Add Subtitles to Playlist/Folder-2.png` (`1919:8707`) | Variante da lista de legendas; estados vazios/ocupados existem, mas busca online e URL não. |
| `Add Subtitles to Playlist/Folder-3.png` (`1919:9278`) | Seleção/atribuição por linha existe; pesquisa/filtro de idiomas do exemplo não foi encontrada. |
| `subtitle multiple.png` (`1915:8397`) | Vários sources/destinations no `MLSubtitleAssociations` e combobox por linha. |
| `subtitle one.png` (`1919:9121`) | Uma legenda/destino usa o mesmo diálogo, com contagem/label dinâmicos. |
| `target.png` (`1959:5325`) | Mostra opções de alvo no export; no código `targetKind` é rótulo do contexto, sem dropdown para trocar alvo dentro do modal. |
| `origin.png` (`1963:5465`) | Mostra Computer/OpenSubtitles/Link; só `chooseFiles()` local está ligado. |
| `sub filename.png` (`6456:13892`) | Fragmento do matching de nome de legenda; `sub-autodetect-fuzzy` é opção real em Settings Subtitles, já descrita na matriz de Settings. Não é o diálogo de associação. |
| `media.png` (`2404:9167`) | Fragmento de opção de mídia; os menus usam seleção/modelo, sem equivalência visual isolada confirmada. |
| `playlist.png` (`2459:9352`) | Fragmento de ação playlist; os modelos e menus de playlist reais não implicam estilo idêntico. |
| `context menu.png` (`2107:5903`) | `MLContextMenu` oferece Play, Enqueue, favoritos, playlist, informação, legenda e ações condicionais; implementado como `NativeMenu`, não popover QML idêntico. |
| `folder context menu.png` (`2139:8935`) | Ações de pasta dependem do modelo/seleção; visual do menu nativo difere do cartão escuro desenhado. |
| `file context menu.png` (`2404:13340`) | `MLContextMenu` oferece ações de arquivo reais, condicionais à mídia; não assumir todas as opções simultâneas do PNG. |
| `playlist context menu.png` (`2459:9389`) | Menu de playlist com operações de modelo; contagem, seleção e ações variam com playlist real. |
| `right-click menu.png` (`6065:13616`) | Menu contextual de player/mídia ligado a ações reais existentes; apresentação exata e itens do export não foram validados em runtime. |
| `menu.png` (`6062:13354`) | Fragmento de menu; `PlayerMenu`, `PersonalizationActions` e menus nativos cobrem ações, sem reprodução 1:1 comprovada. |

## Primitivos e estados de referência

Estas imagens são peças da biblioteca visual, não telas completas. Elas servem para avaliar forma, seleção, hover, foco e contraste quando os fluxos acima forem capturados. O código usa `VLCStyle.redesign`, componentes `Widgets`, assets `qrc:///redesign` e modelos reais. A presença de um componente genérico ou asset não confirma cada variante desenhada.

| Export (node ID) | Destino provável e limite da revisão |
| --- | --- |
| `Icon Wrapper.png` (`177:98`) | Ícones/containers de controles; não há fluxo isolado. |
| `volume.png` (`244:184`) | Controle de volume do player; valor real vem de `Player`, estados visuais não comparados. |
| `Controls.png` (`491:1780`) | `ControlBar` e editor de toolbar; depende do perfil ativo. |
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
| `option.png` (`2107:5935`) | Opção de menu/editor; ação concreta depende de delegate e contexto. |
| `Dropdown.png` (`2372:8300`) | `Widgets.ComboBoxExt` e dropdowns de efeitos/settings; variantes específicas acima podem faltar. |
| `Setting Preset.png` (`2372:8834`) | Preset/seleção visual; bindings reais exigem opção VLC correspondente. |
| `setting category.png` (`3021:9835`) | Categoria de Settings; mapeamento funcional consta em `m3-coverage-settings.md`. |
| `Values-1.png` (`3176:16556`) | Fragmento de valor de efeito; não há funcionalidade autônoma. |

`Components.png` e `Designs.png` são pranchas de referência sem node ID no inventário e sem fluxo executável. Não contam como duas telas implementadas.

## Provas que ainda mudam a decisão

1. Capturar no VLC integrado player vídeo/música, Light, Hide UI, biblioteca grid/list, mini player compacto/expandido, editor/perfis, efeitos e associação de legendas em 1920×1080 e 720 px. Conferir foco, hover, drag/drop, estados vazios e recorte/scroll; esta revisão não alega paridade visual.
2. Exercitar com mídia real: seek, fila, mudança de perfil e persistência após reinício; Save/Cancel de efeitos; associação de legenda a arquivo/pasta/playlist e reprodução subsequente. Código estático prova caminhos, não resultado persistido.
3. Decidir escopo das lacunas demonstradas: seletor HDR, modos de visualizer, OpenSubtitles/Link, alvo selecionável, busca de idioma e controles sem ID no editor. Corrigir também a microcopy `audioBridge` antes de declarar acabamento do diálogo de efeitos.
