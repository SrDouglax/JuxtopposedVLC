# Estado

Atualizado em 13/10/2026, America/Recife. M0 entregue como fundação, com limites de Windows registrados. M1 entregue como primeira fatia Linux na branch `feat/m1`. M2 funcional entregue no Linux na branch `feat/m2`, com cobertura visual parcial explícita.

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
- Figma: quota do conector limitou inspeção visual. IDs estruturais precisam de contexto visual antes de sua implementação.
- Linux: Qt Quick em software e decodificação por CPU; aceleração GPU/hardware ainda sem prova. Áudio capturado em sink de teste, sem comprovação nos alto-falantes.
- M1: contrato visual, shell e player em frentes disjuntas; referências completas de `970:2703` e `187:328` recuperadas do cache da sessão. Shell e barra implementados; smoke integrado Linux PASS (mouse/teclado, seek, volume, fullscreen, resize, diálogo com acento/espaço e arquivo inexistente). T07 não necessária. T09 da fatia Linux aprovado; fidelidade integral e demais marcos seguem pendentes. Windows foi adiado para a rodada final após consolidar a interface, por decisão de 13/10/2026; workflow somente manual.

## Organização

- Em 13/10/2026, a execução de M3 foi reorganizada após pressão de RAM/swap no host. Nenhum subagente está ativo; as próximas correções ficam com o coordenador.
- Uma operação pesada por vez: encerrar a aplicação antes de compilar e encerrar a compilação antes do teste nativo. Builds incrementais com `make -j1`, `nice -n 19` e prioridade de I/O baixa; o scanner Meson também respeita `M0_JOBS` (padrão 1).
- O contêiner local `juxtopposed-vlc-m0-linux` está limitado a 2 GiB de RAM, sem swap (`memory-swap` igual a `memory`) e uma CPU. Permanece desligado durante inspeção/edição. Se esse teto impedir uma operação, registrar a falha e reavaliar antes de ampliar recursos.
- Fila imediata de M3: (1) diagnosticar a asserção ao abrir vídeo com legenda e corrigir a paleta do editor sobreposto; (2) build incremental e validação somente dos caminhos afetados; (3) concluir as verificações restantes de perfis/legendas e atualizar a evidência de entrega. Reaproveitar as provas já válidas de efeitos, timer e miniplayer.
- Servidores de outros projetos, perfis do usuário, downloads e artefatos de build permanecem preservados. Não esvaziar swap com `swapoff`: o host não tem RAM suficiente para absorvê-la.
- Coordenador conduz base/build Linux, revisão e integração.
- Frente de design executa T02; frente Windows prepara e acompanha T04.
- Nenhum subagente usa Astra. Execução dos subagentes autorizada pelo pedido de fazer M0.
- Windows build depende de T01, em paralelo ao baseline Linux: mesma base original e runner remoto, sem disputa local de recursos.

## Próxima ação

M3 em execução na branch `feat/m3`: música/waveform, preferências115 opções, onboarding, efeitos, atalhos/reset, perfis/personalização, timer e miniplayer integrados e exercitados no Linux. [Estado, prova e trabalho restante](../features/redesign/m3.md). [Evidência e hashes](../features/redesign/evidence/m3/result.json). O export completo de 105 PNGs está disponível e os 103 nodes têm revisão por export; isso não encerra a fidelidade integral. Próxima ação: composição/variantes restantes e recursos explicitamente listados no documento M3. Windows/W01 permanece para a rodada final.
