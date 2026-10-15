# External track associations

Attachments reuse the native media-library File API first. Its File table can
reject an external MRL that already belongs to another media entry, including
an audio file independently added to the library. Shared files therefore use
VLC's existing per-media `VLC_ML_PLAYBACK_STATE_APP_SPECIFIC` metadata slot.
This requires no database schema change or additional storage service.

The extension value starts with `#vlc-redesign-tracks:1` followed by a newline.
Each following line contains `a` (audio) or `s` (subtitle), a tab, and the fully
encoded local file URL. Writers reject unknown extension payloads instead of
overwriting them and cap the final payload, including appended records, at 2 MiB. Readers ignore unknown
versions, oversized values and non-file URLs. URLs come from validated readable
local files; the encoded representation protects the line delimiters.

The player loads native File attachments and shared metadata before restoring
optional history state. It deduplicates against slaves already present on the
input item. Disabling remembered history for a filename therefore does not
prevent its explicit attachments from loading. The media library's native
clear-history operation resets playback counters and positions, preserving
extension metadata. Removing the media entry removes its associated metadata.

The private native audit registers the MP3 as a standalone playlist item, then
attaches the same file to another video. It checks that saving succeeds and
that opening that video exposes a second real audio track. The saved extension
value is also inspectable in the private fixture database. Cancellation and
partial-save errors retain the existing association model's revision checks
and explicit reporting of any already-saved assignments.


For a single file, each source has an explicit selected state. Both the UI and
native save path reject an empty selection and persist only selected sources.
Folder and playlist targets keep the source-to-destination matching view.

Online Save requests session credentials only when needed. Search, login and
link retrieval use the native OpenSubtitles service. After retrieving a link,
Save waits for MLSubtitleAssociations::linkReady, emitted after download,
validation and source insertion; an intermediate busy=false is not a completion
signal. The target/source selectors remain locked during the operation, and
closing the dialog cancels requests and clears session credentials.

The UI probe uses a private HTTPS CONNECT fixture that accepts only its two
fixture domains and never forwards traffic. A process-local certificate and
proxy exercise the actual QtNetwork search, login, download and association
chain with fictitious credentials. This proves the local integration and race
handling, not authentication or quota behavior against the public service.
