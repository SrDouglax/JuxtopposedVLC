# Estado

Atualizado em 13/10/2026, America/Recife. M0 entregue como fundação, com limites de Windows registrados. M1 ainda não iniciado.

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

## Em execução / pendente

- Windows: SRT de acesso/saída, x265 e GME importam runtime GCC não disponível na busca restrita do carregador. Copiar DLLs para a raiz não resolveu; a tentativa está preservada em windows.md. Corrigir linkagem e validar esses plugins antes do aceite completo Windows. GUI/vídeo/áudio, DPI e caminhos Windows ainda não comprovados.
- Figma: quota do conector limitou inspeção visual. IDs estruturais precisam de contexto visual antes de sua implementação.
- Linux: Qt Quick em software e decodificação por CPU; aceleração GPU/hardware ainda sem prova. Áudio capturado em sink de teste, sem comprovação nos alto-falantes.
- Nenhum redesign iniciado; M1 depende das provas da fundação.

## Organização

- Coordenador conduz base/build Linux, revisão e integração.
- Frente de design executa T02; frente Windows prepara e acompanha T04.
- Nenhum subagente usa Astra. Execução dos subagentes autorizada pelo pedido de fazer M0.
- Windows build depende de T01, em paralelo ao baseline Linux: mesma base original e runner remoto, sem disputa local de recursos.

## Próxima ação

M1 começa por contrato visual, shell e barra funcional sobre os controllers existentes. A correção Windows W01 pode ocorrer em paralelo, sem alterar o carregador. As intenções da transcrição acompanham o Figma; nenhuma tela redesenhada foi implementada em M0.
