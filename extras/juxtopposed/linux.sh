#!/bin/sh
# Isolated baseline build; run inside the image from linux.Dockerfile.
set -eu
cd /work
jobs=${M0_JOBS:-1}
mkdir -p build-m0/contrib build-m0/linux build-m0/logs
export PKG_CONFIG_PATH="/work/build-m0/deps/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/work/build-m0/deps/lib:${LD_LIBRARY_PATH:-}"

# Ubuntu's scanner 1.22 is older than VLC's requirement. Build only the
# generator; the distro's Wayland client libraries and Qt remain in use.
if ! pkg-config --atleast-version=1.23.0 wayland-scanner; then
    cd /work/build-m0
    archive=wayland-1.23.1.tar.xz
    curl --fail --location --retry 3 \
        "https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.23.1/downloads/$archive" \
        --output "$archive"
    echo "864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed  $archive" \
        | sha256sum --check
    tar -xf "$archive"
    meson setup wayland-scanner-build wayland-1.23.1 \
        --prefix=/work/build-m0/deps --libdir=lib --buildtype=release \
        -Dlibraries=false -Dscanner=true -Dtests=false \
        -Ddocumentation=false -Ddtd_validation=false > logs/wayland-scanner.log 2>&1
    meson compile -C wayland-scanner-build --jobs "$jobs" >> logs/wayland-scanner.log 2>&1
    meson install -C wayland-scanner-build --no-rebuild >> logs/wayland-scanner.log 2>&1
    cd /work
fi

if ! pkg-config --atleast-version=0.13.0 medialibrary; then
    cd /work/build-m0/contrib
    ../../contrib/bootstrap --prefix=/work/build-m0/deps --disable-all --enable-medialibrary
    make -j"$jobs" .medialibrary > ../logs/medialibrary.log 2>&1
    cd /work
fi

./bootstrap > build-m0/logs/bootstrap.log 2>&1
cd build-m0/linux
/work/configure --disable-nls --disable-skins2 --disable-rust --enable-wayland \
    --enable-qt --enable-medialibrary CFLAGS='-O0 -g0' CXXFLAGS='-O0 -g0' \
    > ../logs/configure.log 2>&1
if ! grep -q '^[^#].*-DQT_HAS_X11_COMPOSITOR' modules/gui/qt/Makefile; then
    echo 'Qt X11 video composition was disabled; inspect configure.log before building.' >&2
    exit 1
fi
if ! grep -q '^[^#].*-DQT_HAS_WAYLAND_COMPOSITOR' modules/gui/qt/Makefile; then
    echo 'Qt Wayland video composition was disabled; inspect configure.log before building.' >&2
    exit 1
fi
make -j"$jobs" > ../logs/linux-build.log 2>&1
