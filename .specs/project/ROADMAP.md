# Roadmap

## Marcos e critérios de saída

| Marco | Resultado | Critério de saída |
| --- | --- | --- |
| M0 — Fundação | Base reproduzível e escopo mapeado | VLC original roda no Linux; build Windows produz artefato ou registra impedimento; SHA, toolchain, matriz Figma e baseline documentados |
| M1 — Primeiro player | Janela, navegação e controles redesenhados | Vídeo real, abrir arquivo, play/pause, seek, volume, fullscreen e estado vazio; comparação visual com frames alvo; Windows fica para validação final |
| M2 — Uso diário | Playlists, biblioteca, faixas, legendas, histórico | Fluxos persistem entre sessões, estados de erro funcionam, acentos/caminhos reais; primeiro smoke nativo Windows realizado ou explicitamente pendente |
| M3 — Cobertura completa | Música, miniplayer, personalização, temas, onboarding e configurações | Todos os nodes inventariados classificados e tratados; nenhuma ação visível simulada; exceções somente por decisão explícita |
| M4 — Distribuição Linux | Pacote instalável e mantível | Teste em ambiente limpo, plugins, recursos, perfil, atualização, regressão direcionada e desempenho frente ao baseline |
| M5 — Distribuição Windows | Mesmo produto no Windows | Pacote e execução nativos, caminhos, fontes, DPI, vídeo, áudio e fullscreen testados; nenhuma promessa baseada apenas em cross-build |

Windows participa do desenho da arquitetura desde M0. Por decisão de 13/10/2026, builds e testes Windows ficam manuais e concentrados após a interface consolidada, antes da distribuição. Durante M1–M3, desenvolver e validar no Linux mantendo os manifests, recursos locais e código sem dependências exclusivas de Linux. A compatibilidade da revisão nova no Windows permanece pendente até essa rodada.

## Frentes de subagentes

Papéis reutilizáveis, não seis processos obrigatoriamente simultâneos. Preferência por até três implementadores ativos, conforme independência de arquivos e capacidade de build. Nenhum usa Astra.

| Frente | Responsabilidade | Área provável | Limite |
| --- | --- | --- | --- |
| A — Base e plataformas | Toolchain, Linux, cross-build Windows, CI e pacotes | `contrib/`, `extras/`, scripts de build existentes | Não redesenhar UI nem substituir build upstream |
| B — Visual e navegação | Tokens, componentes visuais, temas, janela e sidebar | `modules/gui/qt/style/`, `widgets/`, `maininterface/` | Não criar controladores de reprodução |
| C — Player | Controles, faixas, legendas, fullscreen e miniplayer | `modules/gui/qt/player/` | Preservar superfície de vídeo e controllers internos |
| D — Biblioteca | Coleções, playlists, busca, ordenação e histórico | `modules/gui/qt/medialibrary/`, `playlist/` | Reutilizar dados existentes antes de propor novo armazenamento |
| E — Preferências | Configurações, onboarding, perfis e personalização | `modules/gui/qt/dialogs/` e pontos confirmados no mapeamento | Não duplicar fonte de verdade das configurações |
| F — Verificação | Revisão independente, imagens, regressões e portabilidade | Testes e evidências específicas da entrega | Não corrigir código de outra frente sem atribuição explícita |
| Coordenador | Escopo, contratos, tarefas, integração e aceite técnico | Arquivos compartilhados e branch de integração | Não aceitar apenas o relato de sucesso do implementador |

As áreas são fronteiras iniciais. Cada tarefa recebe uma lista exata de arquivos autorizados após inspeção. Dois subagentes não editam simultaneamente o mesmo arquivo, incluindo manifests, recursos QML e registro de módulos.

## Ordem de ativação

1. M0: A estabelece a base; B inventaria o Figma e os componentes existentes. Sem implementação visual antes da prova do VLC original.
2. M1: B entrega contrato visual e shell; C adapta controles dependentes desse contrato; A mantém build Linux e estrutura multiplataforma. Validação de vídeo é serializada na máquina.
3. M2: C e D trabalham em fatias independentes; E pode mapear configurações, sem modificar componentes compartilhados.
4. M3: B e E completam temas/personalização e preferências; C ou D completam recursos restantes conforme dependências reais.
5. M4/M5: A prepara pacotes; F revisa a versão integrada; coordenador resolve pendências e registra evidência.

## Contrato de delegação

Cada subagente recebe: objetivo único, requisito, node IDs, SHA/base, worktree, arquivos permitidos, dependências, interfaces acordadas, casos de teste e critério de conclusão.

Cada entrega informa: status completo/parcial/bloqueado, diff/commit, arquivos alterados, testes executados, resultado observado, capturas quando houver UI e limitações. Check falho ou inexistente não vira sucesso.

Uma branch/worktree por tarefa de código; integração serial pelo coordenador. Builds usam diretórios próprios; testes com configurações, biblioteca e mídia isoladas. Recursos compartilhados de GPU/áudio e validação visual nativa não rodam em paralelo por padrão.

## Manutenção

Fixar a base por SHA e incorporar upstream em momentos controlados. Primeiro provar a versão original da nova base; depois revalidar as áreas afetadas pelos patches. Evitar formatação em massa e refatorações externas ao redesign.

Revisar riscos ao fim de cada marco, sem reabrir decisões já comprovadas quando nada relevante mudou.
