# Arquitetura e verificação

## Fluxo pretendido

Componentes QML do redesign → modelos/controladores existentes da interface Qt → núcleo e módulos existentes do VLC.

Manter uma UI comum a Linux e Windows. Detalhes de janela, sistema de arquivos, integração do sistema e composição de vídeo seguem as abstrações existentes do Qt/VLC. Não adicionar processos auxiliares Linux-only para executar funções do produto.

## Reaproveitamento e fronteiras

- Inspecionar `maininterface`, `player`, `playlist`, `medialibrary`, `dialogs`, `style` e `widgets` antes de criar componentes equivalentes.
- Reutilizar controladores internos; não colocar uma camada libVLC nova dentro do próprio VLC.
- Evitar troca da superfície de vídeo para facilitar sobreposições. Provar composição e aceleração na plataforma antes de qualquer alteração dessa integração.
- Centralizar cores, tipografia, dimensões e estados sobre o sistema de estilo já existente. Não copiar constantes para cada tela.
- Preservar IDs e semântica das preferências; distinguir seleção temporária, configuração persistida e estado da reprodução.
- Menus antigos podem continuar acessíveis durante a migração. Isso é transição, não prova de cobertura final do Figma.
- Novos comportamentos recebem lógica própria apenas depois de comprovada a ausência de equivalente.

## Compatibilidade Windows desde o início

- Usar URLs/caminhos e APIs de arquivo do Qt/VLC; evitar concatenar `/`, assumir nomes case-sensitive ou inserir caminhos locais fixos.
- Empacotar fontes, ícones e recursos de forma comum às plataformas, respeitando as permissões dos assets.
- Preservar navegação por teclado, acessibilidade, tradução e escalas de DPI; não depender das fontes instaladas nesta máquina.
- Código específico de plataforma fica nos pontos existentes de integração ou em adaptação pequena e delimitada.
- M0 comprovou o baseline Windows. Por decisão de 13/10/2026, o workflow é manual e novos builds/execução Windows ficam para a rodada final da interface. Durante as fatias Linux, manter APIs portáveis e manifests/recursos comuns. A validação final inclui smoke Windows nativo antes de distribuição.
- Wine/cross-build podem ajudar no diagnóstico, mas não substituem teste Windows nativo.

## Build e base

Reutilizar a cadeia upstream. No SHA consultado, a documentação classifica Meson como experimental e inadequado para release; priorizar o caminho Autotools existente. A versão de Qt e demais dependências será a exigida pela base fixada, sem supor que o Qt local é suficiente.

Obter o upstream com seu histórico e preservar estes documentos ao preparar o checkout. Configurar branch dedicada antes da primeira alteração de código. M0 criou o fork `SrDouglax/JuxtopposedVLC` e preparou a branch `chore/m0` com histórico preservado.

## Arquivos extensos

Aplicar a regra do projeto: preferir arquivos abaixo de 500 linhas e não aumentar arquivos manuais acima de 1.000. A pesquisa identificou `player/qml/Player.qml` com 1.401 linhas no SHA consultado. Antes de editá-lo, confirmar a contagem no checkout e fazer uma extração coesa com equivalência comprovada, ou apontar o bloqueio se o custo ampliar materialmente a tarefa. Não refatorar todo o upstream por contagem.

## Matriz de verificação

| Mudança | Verificação na própria tarefa | Paralelismo |
| --- | --- | --- |
| Documento/inventário | Links, IDs, dependências e consistência | Seguro em arquivos distintos |
| Estilo/layout QML | Build/check QML disponível + captura real e comparação com frame alvo | Build isolado; captura nativa serial |
| Interação QML | Caso de interação e estados; teste QML existente quando adequado + fluxo real | Perfil isolado; vídeo/áudio serial |
| Lógica C++/persistência | Teste unitário/integrado do comportamento alterado + fluxo consumidor | Apenas com dados e builds isolados |
| Build/recursos | Build da plataforma afetada e resolução de assets/plugins | Conforme CPU/RAM/disco disponíveis |
| Pacote | Instalar/abrir em ambiente limpo e smoke de reprodução | Ambientes separados |

Comandos exatos e contagens de testes serão registrados em T01/T03 a partir do checkout. Não inventar scripts ou declarar uma suíte inexistente. Cada tarefa de código inclui a prova do comportamento que introduz; a revisão final não substitui seus testes.

## Aceite visual e funcional

- Referência Figma por node ID, dimensão, tema e estado. Registrar versão/data e assets persistidos; URLs temporárias do Figma não entram no runtime.
- Capturar o aplicativo real com mídia de teste reutilizável. Uma imagem estática da tela não pode substituir os controles.
- Verificar espaço vazio, carregamento, indisponibilidade, erro, foco/hover e janela reduzida; complementar estados ausentes no design sem mudar sua intenção.
- Usar dimensões de referência e janela menor; verificar DPI 100%, 150% e 200% nos marcos relevantes.
- Linux: executar X11 e Wayland quando disponíveis, registrando separadamente o que não foi testado.
- Windows: verificar caminhos com espaços/acentos, seleção de arquivos, DPI, fullscreen e retorno à janela, vídeo/áudio e recursos do pacote.
- Comparar uso de CPU/memória e reprodução com o baseline na mesma máquina/mídia. Só estabelecer limites numéricos depois da medida inicial.

## Fontes consultadas

- [Qt do VLC](https://github.com/videolan/vlc/tree/392bc1d0abdb7396b6c97fef206efa1d23868e19/modules/gui/qt)
- [Documentação de build](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/doc/standalone/buildsystem.md)
- [Build Windows](https://github.com/videolan/vlc/blob/392bc1d0abdb7396b6c97fef206efa1d23868e19/extras/package/win32/build.sh)

Fontes confirmam estrutura e caminhos de build; não comprovam compilação ou execução deste fork.
