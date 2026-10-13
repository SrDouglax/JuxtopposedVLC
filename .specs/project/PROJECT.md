# JuxtopposedVLC

Plano inicial — 12/10/2026. Nome de trabalho, sem definição de marca pública.

## Objetivo

Criar um fork do VLC com a experiência do redesign da Juxtopposed em Qt/QML, reaproveitando o motor, os controladores e as integrações existentes. Entregar primeiro no Linux e manter a mesma interface utilizável no Windows.

O coordenador executa o trabalho, distribui tarefas quando necessário, revisa as entregas, integra e verifica. O usuário não precisa coordenar subagentes ou executar etapas técnicas rotineiras.

## Decisões confirmadas

- Fork do VLC; interface nativa Qt/QML e C++ existente.
- Linux como primeira plataforma de uso diário; Windows como requisito arquitetural desde o início.
- Figma completo como objetivo final; entregas incrementais funcionais.
- Não recriar codecs, reprodução ou uma aplicação separada em torno de libVLC.
- Planejar frentes de subagentes; ativá-los apenas quando houver tarefa concreta que justifique delegação.
- Não usar Astra em nenhuma frente deste projeto. Verificar o modelo antes de delegar; se o pai usar Astra, escolher explicitamente outro modelo suportado com contexto mínimo.

## Requisitos

| ID | Requisito | Prova esperada |
| --- | --- | --- |
| R01 | Preservar reprodução real e recursos internos do VLC | Comparação antes/depois com a mesma mídia e configuração |
| R02 | Cobrir todas as telas e estados do Figma | Matriz por node ID, implementação, comportamento e evidência visual |
| R03 | Linux utilizável | Pacote testado, vídeo/áudio/legendas, persistência e fluxos principais |
| R04 | Não criar impedimentos para Windows | Build desde a fundação, mesma UI, validação nativa por marcos |
| R05 | Manter o fork atualizável | Base fixada, patches por responsabilidade, teste de atualização upstream |
| R06 | Validar trabalho delegado antes de integrar | Revisão do diff, checks proporcionais e evidência do executável integrado |
| R07 | Preservar dados e instalação do usuário | Perfis de teste isolados; sem sobrescrever o VLC instalado |
| R08 | Preservar acessibilidade e localização | Navegação por teclado, foco, nomes acessíveis e textos traduzíveis |

## Escopo e entregas

A primeira entrega visual é uma fatia do produto final: player, controles e navegação principal reproduzindo mídia real. Ela não encerra o objetivo do Figma completo.

O restante inclui biblioteca, playlists, música, miniplayer, personalização, temas, configurações e onboarding. Funções inéditas sugeridas pelo design precisam de implementação real, além da aparência.

macOS, dispositivos móveis, novos codecs e troca do motor ficam fora do escopo inicial. O código existente dessas plataformas será preservado.

## Decisões da fundação e pontos abertos

- Linux x86_64 comprovado em X11 e Wayland; Windows x86_64 compilado e carregamento básico comprovado, com quatro plugins em aviso. Não prometer arquiteturas adicionais sem validação.
- Base fixa: `392bc1d0abdb7396b6c97fef206efa1d23868e19`, linha moderna Qt6/QML do VLC 4.0 em desenvolvimento. Builds e limites estão em foundation.md/windows.md.
- Formato de distribuição Linux será escolhido depois da prova de vídeo e plugins. Não antecipar AppImage, Flatpak ou pacote específico como decisão tomada.
- Estimar cada fatia antes de implementá-la, a partir do inventário e dos comportamentos novos da transcrição. Paralelismo não elimina as dependências de build, renderização e integração.

## Navegação

- [Roadmap e divisão de responsabilidades](ROADMAP.md)
- [Arquitetura e critérios de verificação](../features/redesign/design.md)
- [Tarefas iniciais e dependências](../features/redesign/tasks.md)
- [Inventário inicial do Figma](../features/redesign/figma.md)
- [Intenção e critérios derivados do vídeo](../features/redesign/video.md)
- [Estado e próxima ação](STATE.md)
