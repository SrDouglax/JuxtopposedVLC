# M3 — cobertura estática de Settings, Onboarding e atalhos

Estado examinado: checkout integrado `feat/m3` em `883e32d826c4f5c8e3e8ff26c9b200f20b8499d3`, incluindo alterações locais ainda não commitadas em `Dialogs.qml`, `SettingsDialog.qml` e outros componentes. Referências: 19 arquivos `Settings - *.png`, 11 `Onboarding*.png` e `Keyboard Shortcuts.png` em `build-m3/reference/export/`. Esta é uma comparação de imagens exportadas com código, sem build, abertura do VLC ou captura da UI integrada. “Ligado” abaixo significa que existe binding ou ação para uma API real; não significa paridade visual ou comportamento nativo verificado.

## Arquitetura e alcance comum

- `dialogs/dialogs/qml/SetupDialogs.qml` abre `SettingsDialog.qml` e `OnboardingDialog.qml` a pedido do `DialogsProvider`, e chama onboarding automaticamente quando `OnboardingController.needsSetup` é verdadeiro. `SettingsDialog.qml` também abre `ShortcutsDialog.qml`.
- `SettingsDialog.qml` fornece busca, navegação em 13 categorias, rolagem, Reset category, Apply/Cancel e encaminhamento de Advanced Options para as preferências nativas. `ConfigModel` prepara alterações, verifica conflitos com mudanças externas e só grava via `config_SaveConfigFile` no Apply; Cancel descarta o estado preparado. `PrefsCatalog::entries` é uma lista selecionada de opções reais do VLC; `reload()` omite opções ausentes nesta instalação. Assim, seção e campo podem variar por build e nenhum export de Settings está integralmente implementado só por existir a categoria.
- `SettingsOptionRow.qml` apresenta boolean, escolha enumerada, slider limitado ou texto; `SettingsPresentation.qml` agrupa e renomeia opções selecionadas para a linguagem visual do export. Falta representação específica para vários campos compostos da referência. O botão Advanced Options abre uma janela nativa separada; não expande o painel desenhado no export.
- A aparência escura usa Inter e tokens `VLCStyle.redesign`; o tema claro tem ramificações de cor. `SettingsDialog` mantém um rodapé Apply/Cancel/Reset de 63 px que não está visível nos exports de Settings; isso também reduz a área de conteúdo em relação às imagens. Não houve comparação de pixels nem verificação de 720/1080 px. Os PNGs de Settings têm 1078×895 px com sombra externa; onboarding tem 1114×783 px, e atalhos 1078×830 px.

## Settings — mapa dos 19 exports

| Export exato | Código ligado à tela | Lacuna concreta frente ao export |
| --- | --- | --- |
| `Settings - global.png` | `SettingsAppearance` oferece Light/Dark/System e nove acentos; `SettingsLanguageAction` e catálogo `general` cobrem avisos, atualização e logging. | Idioma não é dropdown inline: no Linux informa idioma do sistema; no Windows encaminha às preferências nativas. “Developer mode” não está no catálogo. |
| `Settings - global-1.png` | Mesma categoria; `general` também tem `stats` e `verbose`; botão Advanced Options. | Expansão inline da área avançada não existe; abre preferências nativas. Campos avançados mostrados no PNG dependem do catálogo, não de um painel expansível equivalente. |
| `Settings - interface.png` | `interface` liga `embedded-video`, `qt-video-autoresize`, tela de fullscreen, opacidade, auto-raise e notificações; `PersonalizationActions` abre editor real. | Skin/arquivo, lembrar tamanho/posição, decoração/título da janela e controles de auto-hide/compacto exibidos no PNG não estão no catálogo desta tela. |
| `Settings - interface-1.png` | Mesmo painel e encaminhamento para o editor de toolbar. | Região inferior de notificações/system tray e opções avançadas do export não são reproduzidas integralmente. |
| `Settings - privacy.png` | `save-recentplay`, `restore-playback-pos`, `restore-playback-states` e `metadata-network-access`; `SettingsPrivacyActions` confirma e chama `MLRecentMediaModel.clearHistory()`. | “Never remember items matching” e integração Last.fm/credenciais/URL do PNG não estão no catálogo. A limpeza exige mídia disponível, com estado desabilitado explícito. |
| `Settings - controls.png` | Botão abre `ShortcutsDialog` real; `hotkeys-y-wheel-mode` e `hotkeys-x-wheel-mode` usam opções do VLC. | Reset de todos os atalhos, quatro durações de salto, clique simples/duplo, direção inversa e remote/port do PNG não aparecem; `short-jump-size` está em Playback, não cobre as quatro durações. |
| `Settings - playback.png` | `playlist-autostart`, `rate`, qualidade/menu/faixas, repeat/loop/random, play-and-stop/start-paused e short-jump-size. | “Continue where you left off”, “pause when another app uses audio” e “when playback finishes” não estão mapeados como controles equivalentes; `repeat` e `loop` são duas opções VLC separadas, não um dropdown único do export. |
| `Settings - playback-1.png` | Mesma categoria; lista rola para mais opções reais quando disponíveis. | Variação de scroll do PNG não tem garantia de mesma ordem/densidade; demais campos específicos de Seeking não estão todos no catálogo. |
| `Settings - video.png` | `video`, `fullscreen`, `disable-screensaver`, `video-wallpaper`, deinterlace/mode, aspect-ratio e snapshot options. Há ação para `extendedDialog(video)`. | Hue, brightness, contrast, saturation, gamma e Reset picture do painel Picture não são inline; efeitos são janela nativa separada. |
| `Settings - video-1.png` | Mesmos bindings e rolagem da categoria Video. | Seções avançadas da parte inferior do export não têm expansão inline; opção disponível depende do VLC instalado. |
| `Settings - audio.png` | `audio`, `qt-max-volume`, `volume-save`, `volume-step`, replay gain/preamp e time stretching. Há ação para `extendedDialog(audio)`. | Output device/speaker setup, startup volume, normalization/night mode e outros controles de Output/Loudness do PNG não têm bindings nesta tela. |
| `Settings - audio-1.png` | A categoria continua usando opções reais e encaminha ao diálogo nativo de efeitos. | Equalizador/preset, dez bandas, two-pass, spatial audio e stereo widening do PNG não estão implementados inline em Settings. |
| `Settings - subtitles.png` | `spu`, `sub-language`, autodetecção de arquivo, fuzzy matching, pastas extras, `sub-text-scale` e `sub-delay`. | Text encoding, fonte, modo relativo/pixels, negrito, cores, opacidade, contorno e sombra do PNG não entram no catálogo apresentado. |
| `Settings - subtitles-1.png` | Mesmos bindings, scroll e seção Appearance limitada a escala/delay. | A variação do export com parâmetros de aparência permanece parcial pelos mesmos campos ausentes. |
| `Settings - library.png` | `media-library`, `auto-preparse`, `recursive`, `show-hiddenfiles`; seção Library/Folders. | Janela única, comportamento para arquivos do gerenciador e “add to playlist instead of replacing” não são oferecidos; política de artwork do PNG é somente `metadata-network-access` em Privacy, não um dropdown nesta tela. |
| `Settings - network.png` | `file-caching`, `disc-caching`, `network-caching`, `live-caching` e `ipv4-timeout`; Advanced Options nativo. | Preset de buffering, proxy/senha, verificação de certificado e preferência de cifra do PNG não estão na lista selecionada. |
| `Settings - performance.png` | `hw-dec`, `drop-late-frames`, `clock-jitter` e `high-priority`. | Post-processing, H.264 loop filter, threads, process priority, rescan plugins, encoder/decoder e demais campos Developer do PNG não têm equivalentes inline. |
| `Settings - recording.png` | `input-record-path`, `input-record-native`, `sout-display`, `sout-audio`, `sout-video`. | Caminho usa edição textual genérica (o editor de browse só é especial para `logfile`); descoberta/qualidade de cast, incluir legendas, preset/tuning de encoding não aparecem. |
| `Settings - extensions.png` | `SettingsExtensions.qml` usa `ServicesDiscoveryModel`: catálogo local/online, busca, instalação/remoção conforme estado, indicador de carregamento, estado vazio e indicação de extensão quebrada/não gerenciável; `qt-autoload-extensions`. | A aparência e os estados do catálogo online variam por fonte e rede; o checkbox “Installed only” e mensagem de catálogo vazio substituem a lista vazia fixa do PNG. Advanced Options ainda abre janela nativa. |

## Onboarding — mapa dos 11 exports

| Export exato | Código ligado à etapa | Diferença ou limite |
| --- | --- | --- |
| `Onboarding.png` | `OnboardingDialog` passo 0 e `WelcomeStep`: SVG de boas-vindas 141 px, texto, diretório sugerido por `QStandardPaths::MoviesLocation`, `FilePicker.chooseFolder`, Next; controller valida URL local, diretório legível e adiciona via `MLFoldersBaseModel`. | O export não mostra o consentimento online; a UI adiciona checkbox explícito de metadados/capas. Se não houver pasta Movies válida, mostra “No folder selected”; não inventa `~/Videos`. |
| `Onboarding-1.png` | `ThemeStep`: três opções Light/Dark/System, nove swatches; `previewTheme()` altera `ColorSchemeModel` e o acento é pré-visualizado com rollback em Cancel. | A amostra de player é decorativa, não um player tocando; a imagem exportada mostra um player como contexto visual. |
| `Onboarding-2.png` | `ShortcutsStep` usa `OnboardingController.activeShortcuts()` para mostrar somente atalhos `key-*` configurados; Back e Finish. | Teclas e quantidade podem diferir do exemplo; não existem valores hardcoded só para reproduzir a imagem. |
| `Onboarding-3.png` | Mesmo `ThemeStep`, swatch coral (`accentChoices`) e preview imediato. | Equivalência de tonalidade/renderização não aferida nativamente. |
| `Onboarding-4.png` | Mesmo `ThemeStep`, swatch amarelo e preview. | Idem. |
| `Onboarding-5.png` | Mesmo `ThemeStep`, swatch verde e preview. | Idem. |
| `Onboarding-6.png` | Mesmo `ThemeStep`, swatch ciano e preview. | Idem. |
| `Onboarding-7.png` | Mesmo `ThemeStep`, swatch azul e preview. | Idem. |
| `Onboarding-8.png` | Mesmo `ThemeStep`, swatch roxo e preview. | Idem. |
| `Onboarding-9.png` | Mesmo `ThemeStep`, swatch rosa e preview. | Idem. |
| `Onboarding-10.png` | Mesmo `ThemeStep`, swatch cinza e preview. | Idem. |

`OnboardingController.needsSetup` depende de `qt-privacy-ask` e conclusão local. Finish só emite `completed()` depois da confirmação da pasta no modelo ou sem pasta escolhida; persiste consentimento, marcador de privacidade e tema. Skip preserva consentimento preexistente e encerra o primeiro uso; reabrir por Settings não reaplica Skip. Cancel desfaz preview e não marca concluído. A UI salva o acento no sinal `completed()`; falha do controller mantém a janela aberta com erro. A persistência do acento em `MainCtx.setSettingValue` não apresenta tratamento de erro na UI, portanto não deve ser declarada comprovada sem teste de reinício.

## Keyboard Shortcuts.png

`ShortcutsDialog.qml` implementa busca, seletor All Fields/Action/Hotkey/Global Hotkey, colunas e grupos, captura, limpar e substituir conflito; `ShortcutsModel` enumera `CONFIG_ITEM_KEY` do core e lê/grava `key-*`/`global-key-*`. O modelo prepara mudanças, detecta conflito de atribuição e alteração externa, chama `config_SaveConfigFile` no Save e retorna erro em falha; Cancel descarta mudanças preparadas. Há aviso de reinício após Save. A lista, rótulos e teclas refletem a configuração instalada, então não reproduzem necessariamente os valores exemplares do PNG. As opções globais só existem para ações com chave `global-*`; a tela permite abrir a coluna vazia, mas a tentativa é recusada com erro do modelo. O Reset all prometido na imagem de `Settings - controls.png` não está conectado.

## Próximas provas necessárias

1. Capturar Settings (ao menos General, Controls, Video, Audio, Extensions), onboarding três passos e Keyboard Shortcuts em 1920×1080 e 720 px, com tema escuro e claro; comparar alinhamento/legibilidade, scroll e estados de popup com os PNGs. Nenhuma captura integrada foi feita nesta revisão.
2. Exercitar persistência com reinício: Apply/Cancel de opção VLC e tema/acento, Finish/Skip do onboarding, inclusão real de pasta e Save/Cancel/conflito de atalho. Fonte estática sustenta os caminhos, não o resultado final de runtime.
3. Decidir se as lacunas de catálogo acima são requisitos M3 ou se os diálogos nativos de preferências/efeitos são a saída aceita. Não preencher os espaços do export com controles sem API real.
