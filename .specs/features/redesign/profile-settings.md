# Profile settings contract

Each control-bar profile persists a versioned `Settings` snapshot alongside its
name and layout in `ControlbarProfileModel/Profiles`. A newly created profile
starts with the currently applied values; a clone copies the source layout and
current settings. On selection, the outgoing profile captures current values,
the incoming values are applied, and only then is the selected layout announced.
The menu saves the selection; the toolbar editor keeps its existing Save/Cancel
boundary. Older profiles without `Settings` inherit the current configuration
until they are saved.

The snapshot includes the redesign theme and accent, developer-mode setting,
the supported VLC options in the redesign Settings catalog, local and global
shortcuts in its shortcut editor, and the native audio/video effect filter
chains and parameters. Available options are determined at runtime, so a
missing optional VLC module does not create a synthetic setting. An active
audio or video output receives effect values immediately; with no active output
the saved VLC configuration applies to the next output. Other VLC options that
take effect only after restart still require restart when switched.

Account identities and secrets, Last.fm credentials and endpoint, proxy
credentials and endpoint, remote-control interfaces, log/recording/subtitle
paths, file-location typed options, and process-wide instance management stay
global. Interface language is also global: on Linux it follows the system; on
Windows it remains in native Preferences. This boundary keeps profile files
from duplicating credentials or machine-specific paths. Existing user data and
library state are never copied into a profile.

Selection validates the snapshot before announcing the new profile. If an
appearance write, live output update, or VLC configuration save fails, the
previous configuration and appearance are restored and the profile selection
stays put. The menu displays the failure. A failed toolbar-editor save keeps
the editor open. The snapshot is stored with the layout, so an editor Cancel
reloads the last saved selection and values.
