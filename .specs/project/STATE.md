# Estado

Atualizado em 14/10/2026, America/Recife. M0 entregue como fundação, com limites de Windows registrados. M1 entregue como primeira fatia Linux na branch `feat/m1`. M2 funcional entregue no Linux na branch `feat/m2`, com cobertura visual parcial explícita.

O desenvolvimento integrado de M0–M3 está centralizado na branch `redesign`, criada a partir de `feat/m3`. As branches dos marcos ficam como histórico; próximos trabalhos partem de `redesign`. [Organização das branches e pendências](BRANCHES.md).

## Comprovado

- Fork [SrDouglax/JuxtopposedVLC](https://github.com/SrDouglax/JuxtopposedVLC) criado e confirmado pela API GitHub.
- Base `392bc1d0abdb7396b6c97fef206efa1d23868e19`, branch `chore/m0`, histórico upstream preservado.
- Bootstrap Autotools bem-sucedido; nenhum arquivo-fonte upstream alterado.
- Linux compilado em ambiente isolado: Ubuntu 24.04, GCC 13.3.0, Qt6 6.4.2 e medialibrary contrib tag 0.13.2.
- Smoke X11 PASS: janela Qt/vídeo/legenda, PCM de áudio, pausa/retomada, seek, volume, fullscreen e saída. Captura e snapshot de recursos persistidos em `features/redesign/evidence`.
- Compositor Wayland habilitado com scanner 1.23.1 isolado. Lançador `extras/juxtopposed/open.sh` abre no desktop do host com perfil separado; reprodução `wl_shm`, pausa/retomada e fullscreen via MPRIS comprovados.
- T02: inventário de 103 frames (57 telas/variantes + 46 grupos), IDs e candidatos reais Qt/QML; 11 inspeções visuais, 92 entradas estruturais.
- Windows: cross-build e pacote portátil comprovados no [run 38341757506](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38341757506). Carregamento nativo de versão/exit 0 aprovado no [run 38343492003](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38343492003), com quatro plugins em aviso.
- Transcrição do vídeo fornecida em 13/10/2026 incorporada à [referência de intenção e comportamento](../features/redesign/video.md), complementar ao Figma.

- M2: biblioteca, playlists persistentes, painel de faixas/capítulos/bookmarks, associação persistente de legendas locais, fila filtrada e retomada validados na aplicação Qt nativa. Build Qt + núcleo aprovado; perfis isolados, caminhos acentuados, reinício e erros de legendas conferidos. [Entrega e limites](../features/redesign/m2.md).

## Em execução / pendente

- Windows: SRT de acesso/saída, x265 e GME importam runtime GCC não disponível na busca restrita do carregador. Copiar DLLs para a raiz não resolveu; a tentativa está preservada em windows.md. Corrigir linkagem e validar esses plugins antes do aceite completo Windows. GUI/vídeo/áudio, DPI e caminhos Windows ainda não comprovados.
- Figma: os105 exports completos fornecidos pelo usuário substituíram a dependência da quota MCP; o aceite visual integral permanece pendente.
- Linux: Qt Quick em software e decodificação por CPU; aceleração GPU/hardware ainda sem prova. Áudio capturado em sink de teste, sem comprovação nos alto-falantes.
- M1: contrato visual, shell e player em frentes disjuntas; referências completas de `970:2703` e `187:328` recuperadas do cache da sessão. Shell e barra implementados; smoke integrado Linux PASS (mouse/teclado, seek, volume, fullscreen, resize, diálogo com acento/espaço e arquivo inexistente). T07 não necessária. T09 da fatia Linux aprovado; fidelidade integral e demais marcos seguem pendentes. Windows foi adiado para a rodada final após consolidar a interface, por decisão de 13/10/2026; workflow somente manual.

## Organização

- Em 13/10/2026, a execução de M3 foi reorganizada após pressão de RAM/swap no host. Nenhum subagente está ativo; as próximas correções ficam com o coordenador.
- Uma operação pesada por vez: encerrar a aplicação antes de compilar e encerrar a compilação antes do teste nativo. Builds incrementais com `make -j1`, `nice -n 19` e prioridade de I/O baixa; o scanner Meson também respeita `M0_JOBS` (padrão 1).
- O contêiner local `juxtopposed-vlc-m0-linux` está limitado a 2 GiB de RAM, sem swap (`memory-swap` igual a `memory`) e uma CPU. Permanece desligado durante inspeção/edição. Se esse teto impedir uma operação, registrar a falha e reavaliar antes de ampliar recursos.
- Fila funcional desta rodada M3 concluída: asserção, paletas, editor, perfis, associação/presets de legendas e Skip/reinício verificados; evidências registradas. Fila remanescente: aceite visual integral e verificações externas discriminadas em M3. O contêiner foi desligado ao terminar.
- Servidores de outros projetos, perfis do usuário, downloads e artefatos de build permanecem preservados. Não esvaziar swap com `swapoff`: o host não tem RAM suficiente para absorvê-la.
- Coordenador conduz base/build Linux, revisão e integração.
- Frente de design executa T02; frente Windows prepara e acompanha T04.
- Nenhum subagente usa Astra. Execução dos subagentes autorizada pelo pedido de fazer M0.
- Windows build depende de T01, em paralelo ao baseline Linux: mesma base original e runner remoto, sem disputa local de recursos.

## Próxima ação

M3 na branch `feat/m3`: implementação e validação funcional Linux atualizadas, catálogo de121 chaves candidatas, efeitos inline, perfis com preferências, editor sobreposto, HDR/visualizer e fontes/presets de legendas integrados. A cobertura visual integral continua sem aceite. [Estado, prova e trabalho restante](../features/redesign/m3.md). [Evidência e hashes](../features/redesign/evidence/m3/result.json). O export completo de 105 PNGs está disponível e os 103 nodes têm revisão por export; isso não encerra a fidelidade integral. Próxima ação: conferir a composição/variantes e equivalências de controles ainda registradas nos mapas, antes de declarar fidelidade integral ao Figma. Windows/W01 permanece para a rodada final.

- 14/10/2026: estrutura e controles principais dos três menus do player corrigidos a partir de `Controls.png`; quatro abas da engrenagem, faixas compactas, fila simples, ícones e toggle validados em Wayland/Linux. Evidências e limites em [M3](../features/redesign/m3.md). Paridade integral e Windows continuam pendentes.


## Sincronização upstream — 14/10/2026

Os21 commits de `videolan/vlc:master` até `d83cb23375405257164b5c073c6370e180608632` foram integrados na `redesign` pelo merge `6a4dd4e16b1157648062be0ef3fbb6d2f6e86e35`, sem conflitos. A integração preserva o histórico do redesign e passa a ter zero commits behind dessa revisão upstream.

Build incremental do plugin Qt no Linux aprovado. O smoke nativo Wayland, com perfil isolado, iniciou o VLC e validou os menus em1920×1080 e720×540, incluindo posição, toggle, ícones, seleção e controles principais. [Resultado e hash do plugin](evidence/upstream-2026-10-14.json) e [log das verificações](evidence/upstream-2026-10-14-ui.txt). Uma operação pesada por vez, `make -j1`,2 GiB de RAM, sem swap e uma CPU.

Windows/macOS e recompilação das dependências contrib atualizadas não foram exercitados. Avisos anteriores de `scaleAxis`/`inlineContentEnabled` permanecem. `git diff --check` aponta espaços herdados nos patches upstream de mad/Qt; os arquivos `.patch` foram preservados. A sincronização não resolve a posição do atalho Audio effects, que continua registrada como pendência.


## README internacional e nova sincronização — 14/10/2026

O README do fork foi reescrito em inglês, atualizado para M0–M3 e acompanhado de comandos de build/execução, crédito ao design e limites de validação. O conteúdo original do VLC foi preservado. Links relativos e sintaxe dos comandos foram verificados.

A atualização publicada `9d43532224` foi preservada. Os sete commits upstream restantes até `3127258a2d` foram integrados em uma branch dedicada; conflitos em quatro arquivos QML foram conciliados mantendo os imports aliased necessários ao redesign, e `EditorDummyButton` adotou `T.Label` do upstream. O plugin Qt e os targets de gaussianblur/accesstweaks compilaram no Linux, com uma CPU,2 GiB e sem swap.

A automação de menus falhou tanto em Wayland no desktop quanto em X11 isolado; não há aceite de runtime desta rodada. Os testes foram encerrados sem ampliar a tarefa para correções de interface. Essa limitação não deve ser confundida com as provas aprovadas das revisões anteriores.
