# Organização das branches

A branch central do fork é **`redesign`**, criada a partir da versão integrada de `feat/m3` em 14/10/2026. Ela reúne M0, M1, M2 e a implementação atual de M3, incluindo as correções de player, biblioteca, preferências, legendas e menus. É a base para os próximos marcos e correções do redesign.

| Branch | Papel |
| --- | --- |
| `redesign` | Integração do desenvolvimento do fork e branch padrão no GitHub. |
| `chore/m0` | Histórico da fundação, build e validação inicial. |
| `feat/m1` | Histórico da primeira entrega de shell e player no Linux. |
| `feat/m2` | Histórico da biblioteca, faixas e legendas. |
| `feat/m3` | Histórico da integração de M3 antes da centralização. |
| `master` | Histórico upstream preservado; não é a base de desenvolvimento do redesign. |

As branches auxiliares de implementação e documentação estão preservadas. A auditoria Git encontrou o checkout principal e as nove worktrees sem alterações pendentes. A incorporação foi conferida por ancestralidade, equivalência de patches e comparação dos arquivos nos casos integrados com ajustes posteriores. Não é necessário reaplicar as versões antigas desses arquivos sobre a integração atual.

Para trabalho novo, crie uma branch curta a partir de `redesign`, como `fix/effects-panel` ou `feat/m4`. Integre somente a mudança revisada e suas evidências. As branches dos marcos registram entregas anteriores; não devem acumular novas correções após a centralização.

Builds, caches, perfis de execução e exports locais continuam fora do Git. O código, scripts, documentação e evidências selecionadas estão versionados.

## Estado da entrega

A revisão de M3 está em [parity.md](../features/redesign/parity.md), com as correções e as evidências atuais. Os efeitos de áudio foram integrados ao painel do player. As divergências conhecidas dos estados revisados foram corrigidas e verificadas no Linux; igualdade pixel a pixel de todos os nodes e runtime Windows permanecem sem comprovação.

O remoto `origin` aponta para [SrDouglax/JuxtopposedVLC](https://github.com/SrDouglax/JuxtopposedVLC). O remoto `upstream` aponta para [VideoLAN/VLC](https://github.com/videolan/vlc); publicar o redesign usa `origin`.
