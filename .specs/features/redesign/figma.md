# Referência e inventário do Figma

Fonte: [VLC Redesign — Community](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=0-1), arquivo `fQSxoEi1zmnD5fQacw0qGs`, página `0:1`. Consulta em 12/10/2026, verificação documental concluída em 13/10/2026 (America/Recife). O conector não retornou número de versão/revisão do Figma; a referência fica congelada pelos IDs, dimensões e conteúdo resumido do [snapshot](reference/inventory.json), não por uma versão inexistente.

A [matriz de cobertura](coverage.md) substitui o inventário inicial de 57 telas: contém **103 frames superiores**, dos quais 57 são telas/variantes e 46 são grupos de componentes. Cada ID tem estado conhecido, nível de inspeção, candidatos Qt/QML/C++, lacuna, tarefa/fatia e critério de prova. Grupos incluem miniplayer, menus, efeitos, equalizador, perfis, opções de legenda, sidebar e controles; não se confundem com cada camada atômica do arquivo.

## Evidência visual direta

| Node | Conteúdo inspecionado | Proveniência |
| --- | --- | --- |
| [187:328](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=187-328) | Player de referência | Contexto+screenshot da etapa inicial, reaproveitados |
| [970:2703](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=970-2703) | Biblioteca em grid com miniplayer | T02: contexto+screenshot |
| [4767:23726](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=4767-23726) | Música, capa/fundo blur e waveform | T02: contexto+screenshot |
| [2107:5604](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=2107-5604) | Editor de controles do player | T02: contexto+screenshot |
| [2160:8732](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=2160-8732) | Layout personalizado com sidebar e barra em duas linhas | T02: contexto+screenshot |
| [999:5047](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=999-5047) | Settings global: tema/cor/idioma/diagnóstico | T02: contexto+screenshot |
| [3062:11911](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=3062-11911) | Privacidade/histórico/Last.fm | T02: contexto+screenshot |
| [1899:3055](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=1899-3055) | Onboarding inicial e escolha de pasta | T02: contexto+screenshot |
| [970:3091](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=970-3091) | Variantes de miniplayer/queue/hover | T02: contexto+screenshot |
| [6114:13610](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=6114-13610) | Equalizador expandido/recolhido | T02: contexto+screenshot |
| [6648:20666](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=6648-20666) | Menu de perfis Movies/Shows/Music/Work | T02: contexto+screenshot |

Os outros 92 IDs têm evidência estrutural, sem inspeção visual direta. Chamadas posteriores de metadados/contexto foram recusadas pelo limite do plano Starter; não acrescentaram evidência visual. Antes de implementar um ID estrutural, obter o contexto de alta fidelidade e estados relevantes. O limite não impede produzir esta matriz, mas impede prometer fidelidade dos detalhes não consultados.

## Dimensões, estilo e recursos

Players: 1920×1080. Settings: 1048×865. Onboarding: 1090×759. Modais de legenda/atalhos: 1048×800. Stream: 1048×631. Nova playlist: 713×589. Dimensões dos 46 grupos estão no snapshot.

Inter Regular/Medium, paleta Dark, métricas e efeitos retornados ficam registrados na matriz e no snapshot. Tokens Light e variantes exatas de accent continuam pendentes; não inverter automaticamente o Dark. A referência não autoriza depender de fontes desta máquina.

T02 baixou **0 assets**. SVGs/capas/thumbnails foram identificados nos contextos; arquivos locais/licenças/callsites/geometria serão verificados na tarefa visual consumidora. URLs temporárias não foram persistidas nem entram no runtime. Screenshots inspecionados são referência, nunca implementação ou asset da interface. O snapshot não copia o React/Tailwind gerado pelo conector.

## Situação funcional

A base de código mapeada é `392bc1d0abdb7396b6c97fef206efa1d23868e19`; símbolos e caminhos publicados aparecem na matriz. Controladores existentes são candidatos confirmados por fonte, ainda sem prova de integração com o redesign. **0/103 entradas têm aparência e função comprovadas no aplicativo redesenhado.** Nenhum build, smoke Linux ou teste nativo Windows foi executado por T02.

A entrega de T02 é o inventário rastreável para implementação incremental; R02 continua aberto. Metadados completos por frame superior não equivalem a inspeção visual de todos os estados, nem a implementação do Figma completo.

## Referência complementar do vídeo

A [transcrição e sua síntese funcional](video.md), fornecidas em 13/10/2026,
registram a intenção das escolhas, 16 requisitos narrativos e critérios de
comportamento para M1–M3. Ela complementa os frames sem substituir medidas,
tokens e inspeção visual. Play à esquerda no padrão e o layout customizado
central são tratados separadamente; fila e playlists também preservam papéis
distintos. Propostas sem equivalente comprovado continuam exigindo lógica real.
