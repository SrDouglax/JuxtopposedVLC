# Tarefas de M0 e M1

Status: M0 entregue na branch `chore/m0`, com limitações do baseline Windows registradas; M1 ainda planejado. A [transcrição do vídeo](video.md) complementa os critérios visuais/funcionais.

| Entrega de M0 | Estado em 13/10/2026 | Evidência |
| --- | --- | --- |
| T01 | Concluída | Fork, SHA, toolchains e build isolado em foundation.md |
| T02 | Concluída como inventário | 103 IDs em coverage.md; 11 inspeções visuais, 92 estruturais |
| T03 | Concluída com limites registrados | Smoke X11 PASS, captura, áudio PCM, recursos e prova Wayland em foundation.md |
| T04 | Concluída como baseline | Cross-build, pacote e versão/exit 0 nativos comprovados; quatro plugins Windows pendentes em W01 |

Este backlog detalha a fundação e a primeira fatia funcional. M2–M5 estão no roadmap; serão decompostos a partir do inventário real, antes de executar cada marco. Evitar uma lista fictícia de centenas de tarefas antes de conhecer o código.

## Ferramentas e política de testes

Coordenador escolhe ferramentas dentro do escopo autorizado: Git e shell para checkout/build; conector Figma com `figma-design-to-code` para nodes e assets; testes Qt/VLC existentes; captura da aplicação nativa quando disponível. Browser não é evidência do aplicativo Qt. Sem Astra.

Aplicar a matriz em `design.md`. Comandos concretos são produzidos por T01/T03; tarefas posteriores só começam quando seus checks forem reproduzíveis. Nenhum teste é transferido para a tarefa final como substituto da validação local.

## Dependências

| Tarefa | Depende de | Responsável | Entrega única |
| --- | --- | --- | --- |
| T01 | — | A | Base/toolchain fixada |
| T02 | — | B | Matriz Figma → código e comportamento |
| T03 | T01 | A | Baseline Linux original |
| T04 | T01 | A | Baseline de build Windows |
| T05 | T02, T03 | B | Contrato visual reutilizável |
| T06 | T05 | B | Shell principal redesenhado |
| T07 | T03 | C | Extração coesa de Player.qml, se necessária |
| T08 | T06, T07 | C | Barra de reprodução funcional redesenhada |
| T09 | T04, T08 | Coordenador/F | Aceite da primeira fatia integrada |

T01/T02 podem ocorrer em paralelo. T03/T04 também: ambos provam a mesma base upstream inalterada, e Windows usa runner remoto. Depois de T03, T05/T07 podem ocorrer em paralelo somente após conferir arquivos permitidos e capacidade da máquina. T07 não deve alterar arquivos de T05. Capturas com vídeo/áudio são serializadas.

## Definições

### T01 — Fixar base e toolchain

- **Onde:** checkout upstream, documentação de build e branch dedicada; preservar `.specs` existente.
- **Reutiliza:** histórico Git, instruções upstream, sistema de build e contribs.
- **Requisitos:** R04, R05, R07.
- **Aceite:** SHA registrado; linha Qt/QML escolhida com justificativa; dependências e versões identificadas; árvore sem alterações inesperadas; comandos de build/teste derivados dos arquivos reais. Registrar se o fork remoto foi criado ou ainda está local.
- **Verificação:** inspeção Git e configuração da toolchain; não afirmar compilação nesta tarefa.
- **Bloqueio:** dependências incompatíveis devem ser resolvidas em ambiente isolado, sem trocar Qt do sistema indiscriminadamente.

### T02 — Mapear o design para funções reais

- **Onde:** `figma.md` e matriz de cobertura ao lado dele.
- **Reutiliza:** metadados já obtidos, nodes específicos, código Qt existente.
- **Requisitos:** R01, R02, R08.
- **Aceite:** cada tela/variante identificada tem node ID, estado, comportamento, candidato de reaproveitamento, lacuna e critério de prova. Distinguir cobertura estrutural de inspeção visual. Registrar tokens, fontes/assets e referência congelada por data/versão disponível.
- **Verificação:** consistência de IDs e links; nenhuma função marcada existente sem evidência de código.
- **Granularidade:** uma matriz de rastreabilidade, não implementação de todas as telas.

### T03 — Provar o VLC original no Linux

- **Onde:** build isolado e documentação do baseline.
- **Reutiliza:** configuração upstream e mídia de teste não privada.
- **Requisitos:** R01, R03, R07.
- **Aceite:** executar a versão compilada; abrir vídeo, ouvir áudio, pausar, buscar, mudar volume, usar legenda e fullscreen; registrar backend gráfico e limitações. Capturar janela original e medir baseline mínimo de recursos com mídia identificada.
- **Verificação:** build real + fluxo nativo; perfil de teste isolado. Registrar comandos exatos, versão Qt, plugins e executável usado.
- **Bloqueio:** falha original não é atribuída ao redesign. Se não houver método de observar a UI nativa, registrar a limitação e não substituir por mock web.

### T04 — Provar build Windows e definir CI

- **Onde:** cadeia upstream Windows, build isolado e configuração de CI quando houver repositório remoto.
- **Reutiliza:** scripts e dependências de `extras/package/win32`.
- **Requisitos:** R04, R05.
- **Aceite:** produzir artefato Windows da mesma base; registrar toolchain, recursos e plugins; definir job repetível para alterações relevantes. Identificar ambiente disponível para smoke nativo futuro.
- **Verificação:** cross-build real ou build nativo. Se CI não puder ser executada, diferenciar configuração escrita de job comprovado. Cross-build não prova reprodução Windows.
- **Bloqueio:** ausência de host nativo não impede build, mas mantém a prova de runtime pendente.

### T05 — Entregar contrato visual compartilhado

- **Onde:** pontos existentes de `style/` e componentes comuns identificados em T02.
- **Reutiliza:** sistema de cores, métricas e componentes do VLC.
- **Requisitos:** R02, R04, R08.
- **Aceite:** cores, tipografia, espaçamentos, ícones e estados usados pela primeira tela correspondem à referência; preservar cone/laranja padrão e formas retangulares suavizadas conforme vídeo; consumidores acordados com C; recursos locais, sem URL temporária; estrutura admite os temas do Figma.
- **Verificação:** build/check QML disponível e captura dos componentes no app, com foco/hover/disabled. Não gerar testes que apenas repetem constantes de estilo.

### T06 — Adaptar shell e navegação principal

- **Onde:** componentes delimitados em `maininterface/`; arquivo grande exige extração antes de aumentar.
- **Reutiliza:** navegação e janela existentes, contrato T05.
- **Requisitos:** R02, R04, R08.
- **Aceite:** janela e sidebar fiéis à referência acordada; navegação funciona; redimensionamento e foco preservados; estado vazio e abrir arquivo continuam utilizáveis.
- **Verificação:** build + interação real e captura de referência e janela reduzida. Provar navegação por teclado; não mostrar botões falsos.

### T07 — Preparar Player.qml sem mudar comportamento

- **Onde:** `player/qml/Player.qml` e um componente extraído coeso, somente se T08 exigir editar o arquivo extenso.
- **Reutiliza:** superfície de vídeo, bindings e controllers existentes.
- **Requisitos:** R01, R05.
- **Aceite:** confirmar tamanho no SHA escolhido; extrair uma responsabilidade suficiente para respeitar o teto, sem redesenhar renderização; comportamento original equivalente. Se T08 puder usar pontos menores sem editar o arquivo extenso, registrar T07 como não necessária com evidência.
- **Verificação:** build + casos afetados de reprodução e fullscreen antes/depois. Não executar refatoração ampla para cumprir uma métrica.
- **Bloqueio:** se a extração ampliar materialmente o escopo, registrar impacto e reavaliar a fronteira antes de editar.

### T08 — Adaptar barra de reprodução

- **Onde:** componente de controles em `player/qml/` e integração mínima delimitada.
- **Reutiliza:** T05/T06, estado e comandos do player existente.
- **Requisitos:** R01, R02, R04, R08.
- **Aceite:** mídia real, play/pause, seek, duração, volume e fullscreen sincronizados; estados sem mídia e ao terminar corretos; aparência comparada ao frame alvo. A transcrição pede play à esquerda, barra discreta, seek espesso e volume em cone; reconciliar com o frame alvo antes de codificar. Fila de reprodução e playlists persistentes têm papéis distintos.
- **Verificação:** interação/testes QML adequados ao comportamento + smoke real com vídeo/áudio; erro de arquivo não causa tela enganosa ou crash. Testes de lógica nova acompanham a mudança.

### T09 — Integrar e aceitar M1

- **Onde:** branch de integração e evidência do marco.
- **Reutiliza:** provas válidas das tarefas, sem repetir checks caros sem mudança que as invalide.
- **Requisitos:** R01–R08 aplicáveis à primeira fatia.
- **Aceite:** revisão dos diffs; build Linux e Windows da revisão integrada; abrir mídia → reproduzir → buscar → fullscreen → retornar → fechar; screenshot real comparada ao Figma. Registrar claramente a cobertura parcial de R02 e runtime Windows pendente, se for o caso.
- **Verificação:** regressão direcionada às interações e fronteiras integradas; checks novos apenas onde a integração invalidou evidência anterior.
- **Saída:** atualizar estado, registrar pendências e detalhar M2. Não marcar Figma completo por concluir M1.

### W01 — Resolver linkagem do runtime Windows antes do aceite completo

- **Frente:** A — plataformas, em paralelo às tarefas visuais Linux; depende de T04.
- **Problema comprovado:** quatro plugins C (SRT entrada/saída, x265, GME) importam `libgcc_s_seh-1.dll`. A base restringe carregamento a SYSTEM32; empacotar DLLs na raiz não resolveu.
- **Onde:** flags e comandos de link Windows derivados da cadeia upstream. Não enfraquecer o carregador nem instalar runtimes em diretórios do sistema.
- **Aceite:** linkagem apropriada do runtime, novo cross-build/pacote e carregamento nativo sem os quatro erros. Confirmar ordem/flags de libtool no link C antes de alterar; a flag atual `-static-libgcc` está em CXXFLAGS.
- **Verificação:** imports dos quatro módulos, versão/exit 0 e contador de falhas de plugins. Depois, smoke Windows real de GUI/vídeo/áudio, separado da prova de compilação.
- **Estado:** não implementada. Obrigatória antes do aceite completo Windows e distribuição; não impede T05/T06/T07 no Linux.

## Validação do próprio plano

| Tarefa | Dependências da definição/ordem | Camada → prova exigida | Resultado da revisão |
| --- | --- | --- | --- |
| T01 | nenhuma | base → inspeção/configuração | Consistente |
| T02 | nenhuma | inventário → IDs/referências | Consistente |
| T03 | T01 | build/runtime → fluxo real | Consistente |
| T04 | T01 | plataforma → build real | Consistente |
| T05 | T02, T03 | estilo → build/captura | Consistente |
| T06 | T05 | interação → build/fluxo/captura | Consistente |
| T07 | T03 | refatoração → equivalência | Consistente |
| T08 | T06, T07 | interação → comportamento/fluxo | Consistente |
| T09 | T04, T08 | integração → diff/build/fluxo | Consistente |

Cada tarefa tem uma entrega coesa e sua própria verificação. Esta tabela verifica o planejamento; não registra execução ou testes aprovados.
