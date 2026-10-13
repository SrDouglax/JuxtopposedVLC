# Windows — M0

Base upstream auditada: `392bc1d0abdb7396b6c97fef206efa1d23868e19`.

## Caminho de build

O job `win64` em `extras/ci/gitlab-ci.yml` usa Autotools e a imagem oficial
`registry.videolan.org/vlc-debian-win64-posix:20260611225331`. A consulta ao
registry em 12/10/2026 (America/Recife; 13/10 em UTC) confirmou imagem Linux amd64 pública e o digest imutável
`sha256:8e83e800036f8f4a6da1031a6b80c2b5bad8337259c072ffa22398baaeaad880`.

A imagem fornece GCC/MinGW POSIX para `x86_64-w64-mingw32`, Autotools, ferramentas
Qt de host, Meson/CMake, Wine, NSIS e ferramentas de empacotamento. Os comandos
de versão são registrados pelo job; disponibilidade no manifesto não comprova
que o toolchain foi executado.

O script upstream `extras/ci/get-contrib-sha.sh win64` produz
`a5538c557d276378d5ba0f8f8010a8b87eaa6f78` para esta base. Seu contrib oficial está
disponível em [artifacts.videolan.org](https://artifacts.videolan.org/vlc/win64/vlc-contrib-x86_64-w64-mingw32-a5538c557d276378d5ba0f8f8010a8b87eaa6f78.tar.zst).
O pacote tem 649.065.005 bytes e o arquivo oficial `SHA512SUM` inclui:

```text
7504d2d80be566f1caced13c8acf45af67059dc159d987a5d4e82c8912ed6fc4435fba714670e53c786bd83accf6c441f1ad345d3c97c04b5bf0ab60341f8d0d
```

A regra fonte do contrib fixa Qt 6.8.3. O pacote pré-compilado efetivamente usado
registrou `target_header=6.8.0` e `host_qmake=6.8.0`, embora o inventário também
contenha headers privados em pastas 6.8.3. Essa divergência entre regra fonte e
metadados do prebuilt é preservada como limitação do baseline oficial. O job lê
o header QtCore e registra separadamente o qmake de host. Esse pacote não fornece
`Qt6Core.pc`. Não utiliza o Qt 6.4.2 do Linux local.

## Execução repetível

`/.github/workflows/m0-windows.yml` usa runner GitHub `ubuntu-24.04`, a imagem
fixada pelo digest acima e `JOBS=2`. Pode ser iniciado manualmente, por push em
`chore/m0`/`master` e por PR com mudanças relevantes de fonte/build/QML.

`/.github/scripts/windows.sh --check` faz somente HEAD no pacote e leitura do
checksum oficial. A execução sem argumentos baixa o contrib, verifica SHA512,
valida a leitura do arquivo e chama:

```sh
sh extras/package/win32/m0-build.generated.sh -a x86_64 -p -x -o "$M0_OUTPUT/windows"
```

O script gerado é uma cópia temporária do `build.sh` upstream no mesmo diretório.
As duas cláusulas que normalmente iniciariam recompilação completa dos contribs
após falha de `make prebuilt` viram falha imediata. A cópia é removida ao terminar.
Se o formato upstream dessas cláusulas mudar, o wrapper falha e exige revisão.
Isso evita transformar uma falha de download/extração em um build pesado.

O pacote portátil contém GUI Qt, executável, DLLs, plugins e recursos do
empacotamento upstream `package-win-common`. O job verifica `vlc.exe` como PE32+
x86-64, `libvlc.dll`, `libvlccore.dll`, plugin Qt e plugin avcodec; registra todas
as DLLs, remove símbolos dos binários empacotados e gera `windows.zip` e SHA256.
Logs, fonte SHA, contrib SHA/checksum, imagem/tamanho, versões e lista de recursos
são publicados como artifact do job. Instalação MSI/NSIS não integra este primeiro
build portátil. Um segundo job `windows-latest` baixa esse mesmo pacote, confere
SHA256, extrai e executa `vlc.exe --version --intf=dummy`, com timeout de 30 segundos.
Registra versão do runner, saída e código de retorno. Define `PWD` para o diretório
real do executável, pois a ajuda do VLC Windows usa essa variável para dispensar
a janela de console e espera por RETURN; exige saída contendo `VLC version`.
Esse teste comprova somente carregamento nativo básico; não testa a GUI ou reprodução.
O input manual opcional `artifact_run_id` permite repetir somente esse teste usando
o pacote já publicado por outra execução, sem recompilar. O resultado distingue
o SHA do pacote (arquivo de evidência do build) do SHA do workflow de verificação.
Se a criação do ZIP falhar mas houver `windows/vlc.exe`, uma etapa separada
preserva a pasta portátil em um artifact de recuperação. Essa pasta só é enviada
quando o ZIP não existe, evitando duplicar o pacote; um artifact de recuperação
não conta como build aprovado e exige revisão da falha antes de uso.

## Recursos

Manifesto remoto: 2.446.482.952 bytes em camadas comprimidas da imagem (~2,28 GiB),
além de ~619 MiB do contrib. A imagem extraída não foi baixada ou medida localmente.
Medição no primeiro runner: imagem com 7.246.930.340 bytes (~6,75 GiB),
77 GiB livres após pull/contrib e 13 GiB RAM disponível. Estimativa inicial restante:
3–5 GiB para contrib e 2–4 GiB para build/pacote; esses valores são orçamento.
O job exige pelo menos
20 GiB livres antes de baixar a imagem e registra o tamanho real depois do pull.

O host local tinha apenas ~17 GiB livres e ~2 GiB de RAM disponível na auditoria.
Nenhuma imagem, dependência grande ou build Windows foi iniciado nele, e nenhum
dado do usuário foi removido. A execução remota evita pressionar essa máquina.
O runner público padrão tem 4 CPUs/16 GiB RAM; o disco disponível deve ser
medido pelo próprio job, pois a referência GitHub garante 14 GiB e não garante
que o orçamento de 20 GiB esteja disponível.

## Evidência e pendências

Comprovado na preparação: base Git, algoritmo/SHA dos contribs, HTTP 200 e tamanho
do pacote, checksum oficial correspondente, manifesto/digest da imagem pública,
sintaxe Bash, parse YAML e etapas esperadas do workflow. Essas verificações
não executaram o compilador nem produziram o artefato Windows.

Primeira execução publicada: [run 38339351306](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38339351306)
no commit `90df6849023a394fd05ac89516a0bc24cf7d874f`. Compilação e
`package-win-common` concluíram; `vlc.exe` foi reconhecido como PE32+ x86-64 e a
lista de DLLs contém 411 arquivos, incluindo verificações aprovadas de Qt/avcodec.
A etapa falhou depois, na coleta de versão via `pkg-config Qt6Core`, porque esse
metadado não existe no contrib. O ZIP ainda não tinha sido criado e o runner
efêmero encerrou, portanto não há pacote recuperável dessa execução. A correção
lê o header real e gera/publica o ZIP antes desse metadado adicional. GCC executado:
14-posix; Make: 4.4.1. O qmake de host usado pelo configure é 6.8.0; a versão do
header target será confirmada na próxima execução.

Segunda execução: [run 38341757506](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38341757506)
no commit `93c524428590416991e9a55c1746463ce493c553`. O job `win64` terminou com
**success** e publicou o [artifact Windows 11788020301](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38341757506/artifacts/11788020301),
com 91.663.350 bytes. O `windows.zip` interno tem 91.748.644 bytes e SHA256:

```text
03b2071bffffe2b0547d6e4d5975658a0248bf246da5e72d8a9fb94b12540537
```

No runner nativo `win25-vs2026/20260925.250.1`, o executável saiu com código 0 e
imprimiu `VLC version 4.0.0-dev Otto Chriek (4.0.0-dev-39363-g93c5244285)`.
O job falhou depois em um `Select-String` com argumentos posicionais invertidos;
a correção usa `-LiteralPath`/`-Pattern` explicitamente e `--ignore-config` para
perfil isolado. O teste corrigido reutiliza esse artifact, sem recompilar.

O [smoke corrigido 38343492003](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38343492003)
terminou com **success**, reutilizando o artifact da segunda execução. `win64`
foi **skipped**, sem novo build. SHA do pacote: `93c524428590416991e9a55c1746463ce493c553`;
SHA do workflow de verificação: `c56181b7dfa5e700ce44475f950f6734d25c33ce`.
O [artifact nativo 11788165664](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38343492003/artifacts/11788165664)
tem 1.814 bytes e conserva resultado, stdout/stderr, imports e inventário das
DLLs da raiz. Com `--ignore-config`, versão/exit 0 foram novamente comprovados.

Há avisos reais `error 126` em quatro plugins: SRT de acesso/saída, x265 e GME.
`dumpbin /DEPENDENTS` confirmou que os quatro importam `libgcc_s_seh-1.dll`.
A raiz do pacote contém apenas `libvlc.dll` e `libvlccore.dll`; o runtime GCC não
foi empacotado. As outras dependências listadas são bibliotecas Windows normais.
Essa ausência explica os quatro erros de carregamento; versão/exit 0 não prova
que esses plugins funcionem. A pendência pertence ao empacotamento do baseline,
antes de uma distribuição Windows completa; não foi feita migração de toolchain
ou mudança no núcleo do VLC para contorná-la.

Os metadados pequenos Qt/checksum/imagem foram lidos seletivamente do arquivo
remoto via HTTP Range (1.851 bytes de um artifact com ~87 MiB), sem baixar o ZIP
Windows inteiro para a máquina local.

Evidência pequena persistida em `evidence/windows-build.txt` e
`evidence/windows-native/` (resultado, stdout/stderr, imports e DLLs da raiz).

Compilação, pacote e carregamento nativo básico foram comprovados. Permanecem
pendentes o runtime GCC dos quatro plugins e smoke nativo Windows para
janela/vídeo/áudio, fullscreen, DPI e caminhos com espaços/acentos. Nenhum host
Windows interativo foi identificado. M0 registra esse baseline; não representa
suporte Windows completo ou aceite visual/funcional do redesign.

## Tentativa de reparo e limite confirmado

O [run 38344175553](https://github.com/SrDouglax/JuxtopposedVLC/actions/runs/38344175553)
reutilizou o pacote original, validou seu checksum e copiou `libgcc_s_seh-1.dll`
e `libwinpthread-1.dll` da mesma imagem oficial. Hashes confirmaram que nenhum
arquivo existente do aplicativo foi alterado. O job de empacotamento passou;
o teste nativo falhou com os mesmos quatro `error 126`, apesar de versão/exit 0.
O ZIP dessa tentativa tem SHA256
`0bd78e92aad12becbf740563583195c062036287f34d045069736f5bffe568a2`.
A [evidência da tentativa](evidence/windows-repaired/) fica preservada; esse
pacote não substitui o artifact original como baseline de M0.

A causa adicional está no carregador upstream: `bin/winvlc.c:116–122` remove o
CWD da busca e estabelece `LOAD_LIBRARY_SEARCH_SYSTEM32`;
`src/win32/plugin.c:64` carrega os plugins com essa mesma restrição. Os runtimes
copiados para a raiz do pacote não são procurados ao resolver as dependências.
Copiar DLLs para outro diretório ou afrouxar essa política não é uma solução
incluída em M0.

O upstream acrescenta `-static-libgcc` a `CXXFLAGS` em `configure.ac:323–326`.
Os quatro módulos afetados usam fontes C e bibliotecas externas; a próxima
investigação deve confirmar seus comandos finais de link e ligar o runtime
estaticamente na etapa apropriada. Isso requer nova compilação e prova nativa;
ainda não foi implementado nem comprovado.

A tentativa de helper/reparo automático foi removida por não resolver o problema.
O CI mantém o critério original de M0: checksum, versão e exit 0. Os erros dos
plugins permanecem no stderr, no contador `plugin_load_errors` e em warning
visível do job. Não se afirma aprovação dos plugins ou de GUI/reprodução.
O gate experimental de zero erros não foi atingido; seu resultado falho está
preservado, separado do smoke básico aprovado.

M0 entrega o build/pacote e esse diagnóstico. A correção de linkagem permanece
obrigatória antes do aceite completo Windows e da distribuição; o carregador e
o núcleo não foram alterados, e nenhuma nova tentativa igual foi disparada.

## Fontes

- [CI upstream da base](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/extras/ci/gitlab-ci.yml)
- [Build Windows upstream](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/extras/package/win32/build.sh)
- [Prebuilt contrib e mudança de prefixo](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/contrib/src/main.mak)
- [SHA512 oficial](https://artifacts.videolan.org/vlc/win64/SHA512SUM)
- [Recursos dos runners GitHub](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Parâmetros de Select-String](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-string?view=powershell-7.5)

- [Carregamento dos plugins Windows](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/src/win32/plugin.c#L64)
- [Política de busca de DLLs](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/bin/winvlc.c#L116)
- [Flag do runtime C++](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/configure.ac#L323)
