# M0 — Fundação

Execução iniciada em 12/10/2026, entregue em 13/10/2026, America/Recife. M0 é a fundação; os limites de Windows abaixo não representam aceite completo dessa plataforma.

## Base e repositório

- Fork: [SrDouglax/JuxtopposedVLC](https://github.com/SrDouglax/JuxtopposedVLC), confirmado como filho de `videolan/vlc` pela API GitHub.
- Base upstream fixa: `392bc1d0abdb7396b6c97fef206efa1d23868e19`.
- Linha: VLC 4.0 em desenvolvimento, interface Qt6/QML. Essa escolha reaproveita os componentes modernos; não é uma promessa de estabilidade de release.
- Branch de execução: `chore/m0`. Histórico upstream preservado; `origin` aponta para o fork e `upstream` para VideoLAN.
- Plano anterior preservado em `.specs/` antes do checkout. Nenhuma alteração na interface ou no motor integra M0.

## Linux

Host Zorin 18.1, base Ubuntu 24.04, x86_64, sessão Wayland com XWayland disponível. Qt6Core local 6.4.2, mas faltavam ferramentas/dependências Quick. Evitar alterar o Qt instalado.

Build isolado em Docker Ubuntu 24.04, imagem base fixada por digest; dependências de distribuição e Qt6 6.4.2. O configure upstream exige Qt >= 6.2. A biblioteca de mídia exige >= 0.13.0, mas a distribuição oferece 0.12.3: usar contrib upstream 0.13.2, isolado no diretório de build.

Autotools escolhido conforme documentação upstream; Meson continua experimental para o build do VLC. O uso de Meson no contrib medialibrary segue seu build próprio.

Comandos reproduzíveis:

```sh
docker build -t juxtopposed-vlc-m0-linux -f extras/juxtopposed/linux.Dockerfile .
docker run -d --name juxtopposed-vlc-m0-linux --cpus=2 --memory=4g --memory-swap=6g \
  -v "$PWD:/work" juxtopposed-vlc-m0-linux sleep infinity
docker exec juxtopposed-vlc-m0-linux sh extras/juxtopposed/linux.sh
docker exec juxtopposed-vlc-m0-linux dbus-run-session -- bash extras/juxtopposed/smoke.sh

# Abrir no desktop do host, sem instalar sobre o VLC existente:
./extras/juxtopposed/open.sh
# Abrir a mídia sintética usada no baseline:
./extras/juxtopposed/open.sh build-m0/fixtures/baseline.mkv
```

`M0_JOBS` controla paralelismo; padrão 1 nesta máquina. Diretórios `build-m0/` são ignorados pelo Git. Não instalar sobre o VLC do usuário.

Flags iniciais: GUI Qt e medialibrary habilitadas; skins2, NLS e módulos Rust desabilitados; C/C++ solicitados com `-O0 -g0`. O configure acrescenta `-Og` ao final, portanto essa é a otimização efetiva do baseline. Isso não é configuração final de distribuição nem benchmark de release. Comparações futuras devem usar a mesma configuração.

Wayland habilitado explicitamente. Ubuntu fornece `wayland-scanner` 1.22, mas
o compositor Qt da base exige >=1.23. O script instala somente o scanner 1.23.1
em `build-m0/deps`, validado por SHA256. As bibliotecas cliente Wayland 1.22 e o
Qt da distribuição continuam em uso. O configure deve ativar os compositores
Qt X11 e Wayland; o script falha se algum deles for omitido silenciosamente.

## Prova Linux X11

Compilação real concluída com GCC 13.3.0, Qt 6.4.2 e medialibrary contrib tag
0.13.2 (`pkg-config` declara 0.13.0). Executável usado:
`build-m0/linux/vlc`, que chama `bin/vlc-static` com os plugins locais.
Nenhum código do motor/interface upstream foi modificado.

O [smoke](../../../extras/juxtopposed/smoke.sh) abre o aplicativo Qt original
em Xvfb 1280×800, compositor X11, Openbox e perfil isolado. A mídia é gerada
localmente: H.264 640×360/24 fps, AAC com seno de 440 Hz, duração 120 s e SRT
em português. Hashes e logs ficam em `build-m0/evidence/`.

- Janela Qt, vídeo integrado, legenda e controles observados na
  [captura](evidence/linux-x11.png).
- Áudio recebido pelo sink PulseAudio de teste: PCM RMS 2893,22 em 2 s.
- Tecla Space pausa e retoma; posição permanece estável durante a pausa.
- Seek via MPRIS avança 15 s, verificado após o decoder atualizar a posição.
- Ctrl+Down reduz o volume de 1,0 para 0,9499969482.
- Tecla F entra e sai de fullscreen; propriedade MPRIS confirmada em ambos.
- Quit encerra o processo com código zero.
- [Resultado persistido](evidence/linux-x11.txt): PASS.

Snapshot de recursos aos 4 s do processo: RSS 251.632 KiB (~246 MiB), CPU 19,7%
e VSZ 5.391.340 KiB. É uma amostra de inicialização em software, não um
benchmark estável nem uma comparação com o VLC distribuído.

O renderer RHI/OpenGL em Xvfb/llvmpipe falhou na base original. O smoke usa
`QT_QUICK_BACKEND=software`; nenhuma correção do motor foi incluída. A captura
prova a aplicação Linux real em servidor X virtual. O áudio foi capturado em
sink de teste; não comprova escuta nos alto-falantes. Aceleração por GPU e
hardware decoding continuam sem prova.

## Abertura no desktop

`open.sh` escolhe Wayland quando o socket do host existe, ou X11 autenticado.
Usa `build-m0/desktop` para configuração/cache/dados, Qt Quick em software e
decodificação por CPU. Mapeia a pasta pessoal somente para leitura em
`/media/home`, além do checkout necessário para executar o build. Compartilha
apenas os sockets de display/áudio necessários e mantém sua própria sessão
D-Bus. O perfil e a instalação normal do VLC não são usados.

O lançador foi executado no desktop Wayland do host. O plugin `qtwayland`
carregou, e a reprodução usou `wl_shm` com vídeo integrado ao compositor Qt.
PlaybackStatus/posição confirmaram reprodução; pausa manteve posição estável,
retomada funcionou e fullscreen foi ativado/desativado via MPRIS.
[Resultado](evidence/linux-wayland.txt) e
[módulos carregados](evidence/linux-wayland-modules.txt) estão persistidos.
O teste no desktop ficou mudo; a prova de áudio é a captura PCM do smoke X11.
Não houve captura de pixels do desktop Wayland: a imagem publicada é do Xvfb.

A [versão executada](evidence/linux-version.txt) após habilitar Wayland é
`4.0.0-dev-39363-g93c5244285`. A prova X11 ocorreu antes dessa recompilação,
na revisão `a0c7d625121f36113551ecaf14f4832ed7c3bec9`; ambas contêm o mesmo
código upstream de interface/motor. O rebuild acrescentou suporte Wayland,
sem alterar o código de reprodução.

Logs completos permanecem no build; publicar resultados e recortes necessários ao diagnóstico, sem arquivos privados.

As [versões dos pacotes do container](evidence/linux-packages.tsv) foram
registradas. A imagem base é fixada, mas os pacotes APT vêm dos repositórios
da distribuição; o ambiente não promete reprodução byte a byte após futuras
atualizações desses repositórios.

## Windows

Preparação independente da prova Linux: usa a mesma base upstream inalterada e runner remoto, portanto T04 passa a depender de T01. A alteração na ordem evita disputa de recursos sem remover nenhum critério de aceite.

Rota: imagem oficial VideoLAN pinada + contrib upstream validado por checksum + cross-build MinGW/Autotools + pacote portátil e evidência. Detalhes e resultados em [windows.md](windows.md).

## Critérios

| Prova | Estado atual |
| --- | --- |
| Fork remoto e checkout | Comprovados |
| Bootstrap Autotools | Executado com sucesso |
| Ambiente Linux isolado | Imagem construída; digest local `15065908430a82f6320b0a24d5ba31473165b34db1f4cbadb683105f6c43e6b7` |
| Build Linux Qt + medialibrary | Comprovado, com compositores X11 e Wayland |
| Reprodução e interações Linux | Smoke X11 PASS |
| Captura nativa e recursos | Captura da aplicação Qt em Xvfb e snapshot registrados |
| Desktop Wayland | Lançador executado; reprodução, pausa/retomada e fullscreen via MPRIS comprovados |
| Matriz Figma → código | 103 frames: 57 telas/variantes + 46 grupos; 11 inspeções visuais |
| Build e artefato Windows | Cross-build aprovado e pacote portátil 11788020301 publicado |
| Carregamento nativo Windows | Versão/exit 0 aprovados; quatro plugins em aviso, diagnóstico em windows.md |

Os critérios de fundação T01–T04 foram atendidos com essas limitações explícitas.
GUI/reprodução Windows e a correção da linkagem de quatro plugins permanecem
abertos antes do aceite completo Windows. Nenhum redesign ou correção do motor
foi incluído. A [transcrição do vídeo](video.md) complementa o inventário Figma
como referência de intenção e comportamento para M1–M3.
