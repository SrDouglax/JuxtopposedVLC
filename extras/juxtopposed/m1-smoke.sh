#!/bin/bash
# Run inside the Linux build container. Uses a separate, disposable Qt profile.
set -euo pipefail
cd /work
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export SMOKE_OUT=/work/build-m1/evidence-final
export SMOKE_PROFILE=/work/build-m1/profile-final
export SMOKE_CSD=1
export SMOKE_HOOK=/work/extras/juxtopposed/m1-controls.sh
if [[ -d "$SMOKE_OUT" ]]; then
    mv "$SMOKE_OUT" "$SMOKE_OUT-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$SMOKE_PROFILE/config/vlc"
# Choose the inspected Dark reference only for this test profile.
printf '[MainWindow]\ncolor-scheme-index=2\nnavigation-panel-width=217\n' \
    > "$SMOKE_PROFILE/config/vlc/vlc-qt-interface.conf"
dbus-run-session -- bash extras/juxtopposed/smoke.sh
# Detect component creation failures that compilation alone does not reject.
if grep -E '\.qml:.*(Invalid property assignment|is not a type|Cannot assign|Binding loop)' "$SMOKE_OUT/vlc.log"; then
    echo 'QML runtime component validation failed' >&2
    exit 1
fi
