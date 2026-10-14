# JuxtopposedVLC

A VLC fork implementing [Juxtopposed's VLC Redesign (Community)](https://www.figma.com/design/fQSxoEi1zmnD5fQacw0qGs/VLC-Redesign--Community-?node-id=0-1) with VLC's existing Qt/QML interface and playback engine.

Development is **Linux-first**, with Windows portability tracked throughout the project. The upstream VLC history is preserved, and **`redesign` is the default integration branch** of this fork.

## Development status

M0 established the build foundation; M1 introduced the redesigned shell and player; M2 added library and track/subtitle workflows. M3 integrates player settings, effects, profiles, customization and subtitle tools, with ongoing visual refinement.

This is an **in-progress development build**. Linux has native build and runtime validation. Full visual parity with the reference, release packaging and current Windows UI validation remain unfinished. The original VLC platform list below describes upstream VLC, not the validation status of this redesign.

## Build and run on Linux

The development environment uses Docker. You need a Linux desktop with an accessible Wayland socket or authenticated X11 display to open the application.

```sh
git clone --branch redesign https://github.com/SrDouglax/JuxtopposedVLC.git
cd JuxtopposedVLC

docker build -t juxtopposed-vlc-m0-linux -f extras/juxtopposed/linux.Dockerfile .
docker run -d --name juxtopposed-vlc-m0-linux \
  --cpus=1 --memory=2g --memory-swap=2g \
  -v "$PWD:/work" juxtopposed-vlc-m0-linux sleep infinity
docker exec -e M0_JOBS=1 juxtopposed-vlc-m0-linux sh extras/juxtopposed/linux.sh
docker stop juxtopposed-vlc-m0-linux

./extras/juxtopposed/open.sh
```

After the build is available, use `open.sh` again to launch it. You can also pass a media file:

```sh
./extras/juxtopposed/open.sh /path/to/video.mp4
```

The launcher uses a separate development profile, Qt Quick software rendering and CPU decoding. It keeps the installed VLC profile separate and exposes your home directory read-only at **`/media/home`** inside the application. Build outputs, caches and runtime profiles are excluded from Git.

The example limits compilation to one CPU, 2 GiB of RAM and no container swap; `M0_JOBS` controls build parallelism. This is a development setup, not an optimized release build.

## Project documentation

- [Project scope and requirements](.specs/project/PROJECT.md)
- [Roadmap](.specs/project/ROADMAP.md)
- [Branches and integration workflow](.specs/project/BRANCHES.md)
- [Foundation and Linux build details](.specs/features/redesign/foundation.md)
- [M1: shell and player](.specs/features/redesign/m1.md)
- [M2: library and subtitles](.specs/features/redesign/m2.md)
- [M3: implementation, validation and remaining work](.specs/features/redesign/m3.md)
- [Windows build and validation](.specs/features/redesign/windows.md)
- [Design coverage](.specs/features/redesign/coverage.md)
- [Design intent and video reference](.specs/features/redesign/video.md)

Development notes and detailed validation reports are currently mostly written in Brazilian Portuguese.

For redesign changes, submit a pull request to [this fork](https://github.com/SrDouglax/JuxtopposedVLC/pulls). Create a focused branch from `redesign` and include relevant validation. Upstream VLC contribution, licensing and support information follows below.

# VLC media player

**VLC** is a libre and open source **media player** and **multimedia engine**,
focused on **playing everything**, and **running everywhere**.

**VLC** can play most multimedia files, discs, streams, devices and is also able to
convert, encode, **stream** and manipulate streams into numerous formats.

VLC is used by many over the world, on numerous platforms, for very different use cases.

The **engine of VLC** can be embedded into 3rd party applications, and is called *libVLC*.

**VLC** is part of the [VideoLAN project](https://videolan.org) and
is developed and supported by a community of volunteers.

The VideoLAN project was started at the university [École Centrale Paris](https://www.centralesupelec.fr/) who
relicensed VLC under the GPLv2 license in February 2001. Since then, VLC has
been downloaded **billions** of times.

## License

**VLC** is released under the GPLv2 *(or later)* license.
*On some platforms, it is de facto GPLv3, because of the licenses of dependencies*.

**libVLC**, the engine is released under the LGPLv2 *(or later)* license. \
This allows embedding the engine in 3rd party applications, while letting them to be licensed under other licenses.

# Platforms

VLC is available for the following platforms:
- [Windows] *(from 7 and later, including UWP platforms and all versions of Windows 10)*
- [macOS] *(10.10 and later)*
- [GNU/Linux] and affiliated
- [BSD] and affiliated
- [Android] *(4.2 and later)*, including Android TV and Android Auto
- [iOS] *(9 and later)*, including AppleTV and iPadOS
- Haiku, OS/2 and a few others.

[Windows]: https://www.videolan.org/vlc/download-windows.html
[macOS]: https://www.videolan.org/vlc/download-macosx.html
[GNU/Linux]: https://www.videolan.org/vlc/#download
[BSD]: https://www.videolan.org/vlc/download-freebsd.html
[Android]: https://www.videolan.org/vlc/download-android.html
[iOS]: https://www.videolan.org/vlc/download-ios.html

Not all platforms receive the same amount of care, due to our limited resources.

**Nota Bene**: The [Android app](https://code.videolan.org/videolan/vlc-android/) and
the [iOS app](https://code.videolan.org/videolan/vlc-ios/) are located in different repositories
than the main one.

# Contributing & Community

**VLC** is maintained by a community of people, and VideoLAN is not paying any of them.\
The community is composed of developers, helpers, maintainers, designers and writers that want
this open source project to thrive.

The main development of VLC is done in the C language, but this repository also contains
plenty of C++, Obj-C, asm and Rust.

Other repositories linked to vlc are done in languages including Kotlin/Java [(Android)](https://code.videolan.org/videolan/vlc-android/),
Swift [(iOS)](https://code.videolan.org/videolan/vlc-ios/), and C# [(libVLCSharp)](https://code.videolan.org/videolan/libvlcsharp/).

We need help with the following tasks:
- Coding
- Packaging for Windows, macOS and Linux distributions
- Technical writing for the documentation
- Design
- Support
- Community management and communication.

Please contribute :)

We are on IRC. You can find us on the **#videolan** channel on *[Libera.chat]*.

[Libera.chat]: https://libera.chat

## Contributions

Contributions are now done through Merge Requests on our [GitLab repository](https://code.videolan.org/videolan/vlc/).

CI and discussions should be resolved before a Merge Request can be merged.

# libVLC

**libVLC** is an embeddable engine for 3rd party applications and frameworks.

It runs on the same platforms as VLC *(and sometimes on more)* and can provide playback,
streaming and conversion of multimedia files and streams.


**libVLC** has numerous bindings for other languages, such as C++, Python and C#.

# Support

## Links

Some useful links that might help you:

- [VLC web site](https://www.videolan.org/vlc/)
- [Support](https://www.videolan.org/support/)
- [Forums](https://forum.videolan.org/)
- [Wiki](https://wiki.videolan.org/)
- [Developer's Corner](https://wiki.videolan.org/Developers_Corner)
- [VLC hacking guide](https://wiki.videolan.org/Hacker_Guide)
- [Bugtracker](https://code.videolan.org/videolan/vlc/-/issues)
- [VideoLAN web site](https://www.videolan.org/)

## Source Code sitemap
```
ABOUT-NLS          - Notes on the Free Translation Project.
AUTHORS            - VLC authors.
COPYING            - The GPL license.
COPYING.LIB        - The LGPL license.
INSTALL            - Installation and building instructions.
NEWS               - Important modifications between the releases.
README             - Project summary.
THANKS             - VLC contributors.

bin/               - VLC binaries.
bindings/          - libVLC bindings to other languages.
compat/            - compatibility library for operating systems missing
                     essential functionalities.
contrib/           - Facilities for retrieving external libraries and building
                     them for systems that don't have the right versions.
doc/               - Miscellaneous documentation.
extras/analyser    - Code analyser and editor specific files.
extras/buildsystem - Different build system specific files.
extras/misc        - Files that don't fit in the other extras/ categories.
extras/package     - VLC packaging specific files such as spec files.
extras/tools/      - Facilities for retrieving external building tools needed
                     for systems that don't have the right versions.
include/           - Header files.
lib/               - libVLC source code.
modules/           - VLC plugins and modules. Most of the code is here.
po/                - VLC translations.
share/             - Common resource files.
src/               - libvlccore source code.
test/              - Testing system.
```
