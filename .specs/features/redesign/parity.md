# M3 parity closure

Working branch: `fix/m3-parity`, based on `redesign` at `4cbf799bd2`.
Reference: the supplied ZIP, SHA-256
`e031eebbb6a7689bb36f0137a535a579625f2725ed0cfd90b957a5f05178f87e`.
The older M3 coverage documents are historical; this document and
`evidence/m3/parity/result.json` record the current review.

## Scope of the screen review

The comparison covers the M3 screen families below, using actual VLC models,
media and configuration. Example filenames, artwork, installed devices,
configured key bindings and module availability remain native data. Unavailable
options retain their place with a disabled control instead of a simulated action.

| Family | Reference states | Reconciled composition and behavior |
| --- | --- | --- |
| Settings | 19 exports, including duplicates and expanded variants | All 13 categories; section order, titles, controls, Advanced Options, inline effects and capability states. General and Performance have their reference-specific expanded groups. |
| Onboarding | 11 exports | Welcome, nine accent previews and six shortcut pairs per column. System swatch has rounded corners; key labels show actual bindings, and Escape rolls the preview back. |
| Customization | Nine exports | 31 controls in nine columns; editable header and footer; physical add, move, reorder and remove; Cancel, new draft profile, Save and reload. Intentionally empty header sections persist. |
| Music | Two exports | Cover/title/waveform and the 426 px source pane on the left. Back/forward, breadcrumb, search, native sort/context actions, grid/list and playback retain the source playlist. |
| Track associations | Four exports, three unique images | Folder matching, selectable single-file tracks and online results. Search/language controls share the source row. Header, row spacing, file icon, rounded corners and footer follow the export. |
| Player panels and forms | Controls/effects/navigation, contexts, Network and New Playlist | Player popovers follow the originating control; active icon, toggle, Escape, outside click, tabs and scrolling use the native UI. Network and playlist forms use actual URL/model actions. |

This is a screen-composition and interaction review. It does not claim automated
pixel equality for every one of the 103 nodes, every hover state or every
platform represented by the complete 105-image archive.

## Corrections with native consequences

- Night mode uses the approved native compressor preset: RMS/peak 0.3, attack
  20 ms, release 250 ms, threshold -20 dB, ratio 4:1, knee 6 dB and makeup 4 dB.
  Turning it off restores the previous compressor values and enabled state;
  canceling the settings transaction also restores them.
- Picture parameters now refresh when the video bridge becomes available.
  All five sliders use their actual native ranges rather than the temporary
  generic 0..1 range. Precise seeking, subtitle shadow, screensaver and resume
  controls map back to their native values.
- Header controls use compact rows, separate from the footer timeline layout.
  Editor centering accounts for the horizontal ListView header offset.
  Cross-section/removal drops defer destruction of the source delegate until
  Drag.drop() returns. The previous synchronous removal could terminate Qt
  while its drag/layout code still referenced that delegate.
- Online Save waits for `MLSubtitleAssociations::linkReady` after a validated
  download and source insertion, then saves the association. It does not treat
  an intermediate busy=false notification as completion. Empty selections are
  rejected by both the UI and native save path.
- Shared external audio/subtitle files use existing per-media extension metadata
  when the library's File table already owns their MRL elsewhere. Loading these
  explicit associations remains independent of history exclusion. See
  [associations.md](associations.md).
- The source pane clears its search when moving between levels. Playlist sort
  criteria map to native sorting, and playing one source item preserves its
  playlist ID/name instead of losing the source context.
- Q opens the queue through the configured button, with a fallback when that
  button was removed. The open popup handles its closing key locally while
  global playback shortcuts are frozen. The fallback uses the actual footer
  boundary. Ctrl+L retains the existing source/file-browser shortcut.
- Bipolar audio/subtitle delay sliders fill between zero and the current value.
  Zero has no colored fill; positive and negative values retain their native
  millisecond behavior. External subtitle actions use the exported 20 px icons
  with compact spacing and transparent resting backgrounds.

## Verification

One build or native session at a time, using one CPU and a 2 GiB memory limit
with no container swap. All runtime checks use private X11/software rendering,
private profiles and fixture media; the installed user profile is untouched.

- Incremental Linux Qt/core/FreeType builds pass.
- Settings pass at 100% and 150%: 13 categories and scrolling, native Picture
  ranges, seeking/shadow, compressor apply/restore/cancel, normalizer, wheel
  direction, subtitle pixel size, Escape rollback and close/save/reopen.
- The integrated audit passes contexts, physical customization gestures,
  header/footer migration and reload, header popup geometry, associations,
  actual second audio track, PCM waveform and source-pane navigation/actions.
- An additional customization run passes eight repeated cross-section transfers
  as well as the normal move/remove/reorder/Cancel/Save checks.
- The independent association run passes actual QtNetwork HTTPS search, login,
  download and native saving against a private API fixture. It also checks
  target locking, cleared credentials, empty-selection rejection and folder
  matching. The fixture never forwards requests to the public service.
- Onboarding passes the nine accent changes, shortcut layout, Escape and preview
  rollback. Existing unchanged Finish/Skip/restart backend evidence is retained.
- Final panels pass at 1920x1080 and 720x540, including active icons, tabs,
  filter expansion, second click, Escape and outside click. Physical Q opens
  and closes the queue; with its button removed, the fallback also toggles and
  stays above the complete footer.
  Additional checks cover zero-origin fill and native +500/-4000 ms delay values
  for both audio and subtitles.
- Existing unchanged proof is retained for network/playlist forms, miniplayer
  gestures, window geometry across three restarts, 17 history matching cases,
  native included/excluded history database state and actual FreeType rendering.
  32px glyph dimensions remain 214x23 at 360p/720p; 64px yields 428x47.

## Evidence and boundaries

`evidence/m3/parity/` contains selected current captures, probe results, reference
mapping and artifact hashes. Private build/debug files remain outside Git.

Windows builds remain deferred by agreement. Real OpenSubtitles authentication,
quotas and public-service availability have not been proved with a real account.
HDR hardware/GPU output, RHI rendering and optional remote/scrobbling services
are outside this Linux software-renderer proof. Their availability is displayed
from native capabilities; no unsupported success is simulated.

M4 has not been started. No README, upstream synchronization, remote branch,
GitHub default-branch or publishing action belongs to this correction.
