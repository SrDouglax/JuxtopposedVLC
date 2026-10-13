#
# Qt-based interface module
#

qt6 = import('qt6')

qt_include_dir = include_directories('.')

qt_extra_deps = []
qt_extra_flags = ['-DQT_STRICT_ITERATORS','-DQT_USE_QSTRINGBUILDER','-DQT_NO_CAST_TO_ASCII','-DQT_NO_CAST_FROM_BYTEARRAY']
qt_cppargs = []
qt_link_args = [gc_sections_linkargs]

qt6_dep = dependency('qt6',
    # Note that Qt < 6.2.5 does not provide pc files!
    version: '>=6.2',
    modules: [
        'Core', 'Gui', 'Widgets', 'Qml',
        'Quick', 'QuickControls2'
        ],
    private_headers: true,
    required: get_option('qt'))

# Qt module doesn't provide the framework path to moc executable, so we
# need to help moc find them. It's needed for QtQml/ module registration.
if host_machine.system() == 'darwin' and qt6_dep.found()
    qt_libdir = qt6_dep.get_variable(pkgconfig: 'libdir', configtool: '-query QT_INSTALL_LIBS')
    qt_extra_flags += '-F' + qt_libdir
endif

subdir('buildsystem/headers')
subdir('buildsystem/sources')
qrc_files = files('assets.qrc')
if host_system == 'windows'
  qrc_files += files('windows.qrc')
endif

ui_sources = files(
    'dialogs/extended/equalizer.ui',
    'dialogs/extended/video_effects.ui',
    'dialogs/fingerprint/fingerprintdialog.ui',
    'dialogs/firstrun/firstrunwizard.ui',
    'dialogs/help/about.ui',
    'dialogs/help/update.ui',
    'dialogs/messages/messages_panel.ui',
    'dialogs/open/open.ui',
    'dialogs/open/open_capture.ui',
    'dialogs/open/open_disk.ui',
    'dialogs/open/open_file.ui',
    'dialogs/open/open_net.ui',
    'dialogs/podcast/podcast_configuration.ui',
    'dialogs/preferences/sprefs_audio.ui',
    'dialogs/preferences/sprefs_input.ui',
    'dialogs/preferences/sprefs_interface.ui',
    'dialogs/preferences/sprefs_medialibrary.ui',
    'dialogs/preferences/sprefs_subtitles.ui',
    'dialogs/preferences/sprefs_video.ui',
    'dialogs/sout/profiles.ui',
    'dialogs/sout/sout.ui',
    'dialogs/vlm/vlm.ui',
)

subdir('buildsystem/qml')

if qt6_dep.found()
    qt_rcc_extra_arguments = []
    qt_zstd_check = '''
    #include <qconfig.h>
    #if QT_FEATURE_zstd != 1
    #error "Qt can not decompress zstd. Resources are going to be compressed using zlib."
    #endif
    '''
    if not cpp.compiles(qt_zstd_check, dependencies: qt6_dep, name: 'Qt supports decompressing zstd')
        qt_rcc_extra_arguments += '--no-zstd'
    endif

    atomic_lib = cc.find_library('atomic', required: false)
    if atomic_lib.found()
        qt_extra_deps += atomic_lib
        qt_extra_flags += '-DQT_HAS_LIBATOMIC'
    endif

    prog_python = find_program('python3')
    modules_qrc = []
    foreach module : qml_modules
        #generates 'res.qrc', 'qmldir.qrc', 'qmldir',
        run_command(
            prog_python,
            meson.current_source_dir() / 'scripts/genqrc.py',
            '-o', meson.current_build_dir() / module['outdir'] / 'res.qrc',
            '--prefix', 'qt/qml' / module['outdir'],
            '--sources', module.get('sources', []) + module.get('singletons', []),
            check: true,
        )
        run_command(
            prog_python,
            meson.current_source_dir() / 'scripts/genqmldir.py',
            '-o', meson.current_build_dir() / module['outdir'] / 'qmldir',
            '--module', module['name'],
            '--prefix', 'qt/qml',
            '--sources', module.get('sources', []),
            '--singletons', module.get('singletons', []),
            check: true,
        )
        run_command(
            prog_python,
            meson.current_source_dir() / 'scripts/genqrc.py',
            '-o', meson.current_build_dir() / module['outdir'] / 'qmldir.qrc',
            '--prefix', 'qt/qml' / module['outdir'],
            '--sources', [meson.current_build_dir() / module['outdir'] / 'qmldir'],
            check: true,
        )
        module_qrc = qt6.preprocess(
            module['target'] + '_assets',
            qresources: files(
                meson.current_build_dir() / module['outdir'] / 'res.qrc',
                meson.current_build_dir() / module['outdir'] / 'qmldir.qrc',
            ),
            include_directories: qt_include_dir,
            dependencies: qt6_dep,
            rcc_extra_arguments: qt_rcc_extra_arguments
        )

        #FIXME copy every files to the outdir module so they can be used by qt tooling

        qmllibs += static_library(
            'qml_module' + module['target'],
            module_qrc,
            dependencies: qt6_dep)
    endforeach

    qt_static_check = '''
    #include <qconfig.h>
    #ifndef QT_STATIC
    # error Qt using shared libraries
    #endif
    '''

    if cpp.compiles(qt_static_check, dependencies: qt6_dep, name: 'Qt6 compiled with static libraries')
        qt_install_bin_directory = qt6_dep.get_variable(pkgconfig: 'bindir', configtool: '-query QT_INSTALL_BINS')
        qmake6 = find_program(qt_install_bin_directory + '/qmake6', required: true)
        if qmake6.found()
            qmake_additional_params = []
            if get_option('buildtype') == 'debug'
                qmake_additional_params += '--debug'
            endif
            qtcflags = run_command(
                prog_python,
                meson.current_source_dir() / 'scripts/static_dirs.py',
                '--qmake', qmake6.full_path(),
                '--pro', meson.current_source_dir() / 'qt6.pro',
                '--builddir', meson.current_build_dir(),
                '--cflags',
                qmake_additional_params,
                check: false,
            )
            if qtcflags.returncode() == 0
                qt_extra_flags += qtcflags.stdout().split()
            else
                warning('Failed to get static Qt compilation flags: ' + qtcflags.stderr())
            endif
            qtlflags = run_command(
                prog_python,
                meson.current_source_dir() / 'scripts/static_dirs.py',
                '--qmake', qmake6.full_path(),
                '--pro', meson.current_source_dir() / 'qt6.pro',
                '--builddir', meson.current_build_dir(),
                '--libs', '--ldflags',
                qmake_additional_params,
                check: false,
            )
            if qtlflags.returncode() == 0
                qt_link_args += qtlflags.stdout().split()
            else
                warning('Failed to get static Qt link flags: ' + qtlflags.stderr())
            endif
        else
            warning('Failed to find qmake6 to get static Qt variables')
        endif
    endif

    qt6pre_qrc = qt6.preprocess(
        qresources: qrc_files,
        include_directories: qt_include_dir,
        dependencies: qt6_dep,
        rcc_extra_arguments: qt_rcc_extra_arguments)

    qt_sources = files('qt.cpp')

    subdir('shaders')

    # Qt plugins
    if host_system == 'windows'
        qt_extra_deps += [
            cc.find_library('dwmapi'),
            cc.find_library('comctl32'),
        ]
    endif

    qt_xcb_check = '''
    #include <qtgui-config.h>
    #if QT_FEATURE_xcb != 1
    #error "Qt doesn't have xcb support"
    #endif
    '''
    qt_features_xcb = cpp.compiles(qt_xcb_check, dependencies: qt6_dep, name: 'Qt features xcb')

    if x11_dep.found() and xcb_dep.found() and qt_features_xcb
        qt_extra_deps += xcb_dep
        qt_extra_deps += x11_dep
        qt_extra_flags += '-DQT_HAS_XCB'
        if xcb_damage_dep.found() and xcb_xfixes_dep.found()
            qt_extra_deps += [
                xcb_render_dep,
                xcb_composite_dep,
                xcb_damage_dep,
                xcb_xfixes_dep
            ]
            qt_extra_flags += '-DQT_HAS_X11_COMPOSITOR'
        endif
    endif

    if get_option('qt_qml_debug')
        qt_extra_flags += '-DQT_QML_DEBUG'
    endif

    #check private headers
    if cpp.has_header('private/qquickitem_p.h', dependencies: qt6_dep) \
      and cpp.has_header('private/qquickwindow_p.h', dependencies: qt6_dep)
        qt_extra_flags += '-DQT_DECLARATIVE_PRIVATE'
    endif

    if cpp.has_header('qpa/qplatformnativeinterface.h', dependencies: qt6_dep)
        qt_extra_flags += '-DQT_GUI_PRIVATE'
    endif

    qt_wayland_gui_private = cpp.has_header(
        'qpa/qplatformnativeinterface.h', dependencies: qt6_dep)

    if have_wayland and qt_wayland_gui_private
        qt_extra_flags += '-DQT_HAS_WAYLAND_COMPOSITOR'
        qt_extra_deps += wayland_deps[0]

        qt_wl_xdg_shell_xml = wayland_protocols_dir / 'stable/xdg-shell/xdg-shell.xml'

        qt_wl_xdg_shell_hdr = custom_target(
            'qt-wayland-xdg-shell-client-header',
            output: 'xdg-shell-client-protocol.h',
            input: qt_wl_xdg_shell_xml,
            command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],
        )
        qt_wl_xdg_shell_code = custom_target(
            'qt-wayland-xdg-shell-code',
            output: 'xdg-shell-protocol.c',
            input: qt_wl_xdg_shell_xml,
            command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],
        )

        qt_wayland_sources = [
            files(
                'maininterface/qt_wayland_plugin.c',
                'maininterface/compositor_wayland_module.c',
                'maininterface/compositor_wayland_module.h',
                'util/csdmenu_wayland.c',
                'util/csdmenu_wayland.h',
                'util/csdmenu_module.h',
            ),
            qt_wl_xdg_shell_hdr,
            qt_wl_xdg_shell_code,
        ]

        qt_wayland_cargs = ['-DQT_HAS_WAYLAND_PROTOCOLS']

        if qt6_dep.version().version_compare('>= 6.5')
            qt_wayland_cargs += '-DQT_HAS_WAYLAND_FRACTIONAL_SCALING'
            qt_wl_viewporter_xml = wayland_protocols_dir / 'stable/viewporter/viewporter.xml'
            qt_wl_viewporter_hdr = custom_target(
                'qt-wayland-viewporter-client-header',
                output: 'viewporter-client-protocol.h',
                input: qt_wl_viewporter_xml,
                command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],
            )
            qt_wl_viewporter_code = custom_target(
                'qt-wayland-viewporter-code',
                output: 'viewporter-protocol.c',
                input: qt_wl_viewporter_xml,
                command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],
            )
            qt_wayland_sources += [qt_wl_viewporter_hdr, qt_wl_viewporter_code]
        endif

        vlc_modules += {
            'name': 'qt_wayland',
            'sources': qt_wayland_sources,
            'c_args': qt_wayland_cargs,
            'include_directories': [qt_include_dir],
            'dependencies': [wayland_deps[0], m_lib],
            'plugin_dir' : 'gui',
        }
    endif

    if host_system == 'windows'
        qt_cppargs += libcom_cppflags
    endif

    #Qt GTK theme module
    gtk_dep = dependency(
        'gtk+-3.0',
        version: '>=3.20',
        required: get_option('qt_gtk').disable_auto_if(host_system in ['windows', 'darwin'])
    )

    vlc_modules += {
        'name' : 'qt_gtktheme',
        'sources' : files(
            'style/gtkthemeprovider/gtk_compat.cpp',
            'style/gtkthemeprovider/gtk_compat.h',
            'style/gtkthemeprovider/gtkthemeprovider.cpp',
            'style/gtkthemeprovider/gtk_util.cpp',
            'style/gtkthemeprovider/gtk_util.h',
            'style/gtkthemeprovider/nav_button_provider_gtk.cpp',
            'style/gtkthemeprovider/nav_button_provider_gtk.h',
            'style/gtkthemeprovider/scoped_gobject.h'
        ),
        'dependencies' : [gtk_dep, qt6_dep],
        'plugin_dir' : 'gui',
        'enabled' : gtk_dep.found()
    }

    if gtk_dep.found()
        qt_extra_flags += '-DQT_HAS_GTK'
    endif

    if host_system == 'windows'
        qt_plugin_sources += files('maininterface/win32windoweffects_module.cpp',
                              'maininterface/win32windoweffects_module.hpp')
    else
        kf6WindowSystem_dep = dependency('KF6WindowSystem',
                                         version: '>=6.0.0',
                                         required: false)
        if (kf6WindowSystem_dep.found())
            vlc_modules += {
                'name' : 'qtwindoweffects',
                'sources' : files(
                    'maininterface/windoweffects_module.hpp',
                    'maininterface/kwindowsystem_module.cpp',
                ),
                'dependencies' : [kf6WindowSystem_dep, qt6_dep],
                'plugin_dir' : 'gui',
            }
        endif
    endif

    vlc_modules += {
        'name' : 'qt_x11',
        'include_directories' : qt_include_dir,
        'sources' : files(
            'maininterface/qt_x11_plugin.c',
            'maininterface/compositor_x11_utils.hpp',
            'maininterface/compositor_x11_utils.cpp',
            'util/csdmenu_module.h',
            'util/csdmenu_x11.cpp',
            'util/csdmenu_x11.h'
        ),
        'dependencies' : [xcb_dep, xcb_render_dep, xcb_xfixes_dep],
        'plugin_dir' : 'gui',
        'enabled': xcb_dep.found() and xcb_render_dep.found() and xcb_xfixes_dep.found(),
    }

    qt6pre_files = qt6.preprocess(ui_files: ui_sources,
        moc_headers: moc_headers,
        moc_extra_arguments: qt_extra_flags,
        include_directories: qt_include_dir,
        dependencies: qt6_dep,
        rcc_extra_arguments: qt_rcc_extra_arguments)

    # TODO support qmlcachegen

    vlc_modules += {
        'name' : 'qt',
        'sources' : [qt6pre_files, qt6pre_qrc, shader_targets, shaders_processed, qt_sources, qt_plugin_sources],
        'extra_files' : [shader_files],
        'dependencies' : [qt_extra_deps, qt6_dep, corefoundation_dep],
        'include_directories' : qt_include_dir,
        'c_args' : qt_extra_flags,
        'cpp_args' : [qt_extra_flags, qt_cppargs],
        'link_args' : qt_link_args,
        'link_with' : qmllibs,
        'plugin_dir' : 'gui',
    }

    vlc_tests += {
        'name': 'base_model_test',
        'sources': files(
            'tests/test_base_model.cpp',
            'util/base_model.cpp',
            'util/base_model.hpp',
            'util/base_model_p.hpp'),
        'moc_headers': files(
            'util/base_model.hpp',
            'util/listcache.hpp',
            'util/locallistcacheloader.hpp'),
        'suite': ['qt'],
        'link_with': [libvlccore],
        'link_args': qt_link_args,
        'dependencies': [qt6_dep, qt_extra_deps],
    }

    qtest_qt6_dep = dependency('qt6', version: '=' + qt6_dep.version(), modules: ['Test'], required: false)
    if qtest_qt6_dep.found()
        vlc_tests += {
            'name': 'test_qt_ml_model',
            'sources': files(
                'tests/test_ml_model.cpp',
                'tests/vlc_stub_modules.cpp',
                'util/base_model.cpp',
                'util/vlctick.cpp',
                'medialibrary/mlbasemodel.cpp',
                'medialibrary/medialib.cpp',
                'medialibrary/mlthreadpool.cpp',
                'playlist/playlist_controller.cpp',
                'playlist/playlist_item.cpp',
            ),
            'moc_sources': files(
                'tests/test_ml_model.cpp'
            ),
            'moc_headers': files(
                'tests/vlc_stub_modules.cpp',
                'util/base_model.hpp',
                'util/listcache.hpp',
                'util/locallistcacheloader.hpp',
                'util/vlctick.hpp',
                'medialibrary/mlqmltypes.hpp',
                'medialibrary/mlbasemodel.hpp',
                'medialibrary/medialib.hpp',
                'medialibrary/mlthreadpool.hpp',
                'playlist/playlist_controller.hpp',
                'playlist/playlist_item.hpp',
            ),
            'suite': ['qt'],
            'include_directories' : qt_include_dir,
            'link_with': [libvlccore, libvlc],
            'link_args': qt_link_args,
            'dependencies': [qt6_dep, qt_extra_deps, qtest_qt6_dep],
        }

        vlc_tests += {
            'name': 'test_qt_navigation_model',
            'sources': files(
                'tests/vlc_stub_modules.cpp',
                'tests/test_navigation_model.cpp',
                'maininterface/navigationmodel.hpp',
                'maininterface/navigationmodel.cpp'
            ),
            'moc_sources': files(
                'tests/test_navigation_model.cpp'
            ),
            'moc_headers': files(
                'maininterface/navigationmodel.hpp'
            ),
            'suite': ['qt'],
            'include_directories' : qt_include_dir,
            'link_with': [libvlccore, libvlc],
            'dependencies': [qt6_dep, qt_extra_deps, qtest_qt6_dep]
        }


        vlc_tests += {
            'name': 'test_qt_renderer_manager',
            'sources': files(
                'tests/vlc_stub_modules.cpp',
                'tests/test_renderer_manager_model.cpp',
                'util/renderer_manager.hpp',
                'util/renderer_manager.cpp'
            ),
            'moc_sources': files(
                'tests/test_renderer_manager_model.cpp'
            ),
            'moc_headers': files(
                'util/renderer_manager.hpp'
            ),
            'suite': ['qt'],
            'include_directories' : qt_include_dir,
            'link_with': [libvlccore, libvlc],
            'link_args': qt_link_args,
            'dependencies': [qt6_dep, qt_extra_deps, qtest_qt6_dep]
        }

        vlc_tests += {
            'name': 'test_qt_thread_runner',
            'sources': files(
                'tests/test_thread_runner.cpp',
                'medialibrary/mlthreadpool.cpp',
                'medialibrary/mlthreadpool.hpp'
            ),
            'moc_sources': files(
                'tests/test_thread_runner.cpp'
            ),
            'moc_headers': files(
                'medialibrary/mlthreadpool.hpp'
            ),
            'suite': ['qt'],
            'include_directories' : qt_include_dir,
            'link_args': qt_link_args,
            'dependencies': [qt6_dep, qtest_qt6_dep]
        }


        vlc_tests += {
            'name': 'test_qt_dialog_model',
            'sources': files(
                'tests/vlc_stub_modules.cpp',
                'tests/test_vlc_dialog_model.cpp',
                'dialogs/dialogs/dialogmodel.hpp',
                'dialogs/dialogs/dialogmodel.cpp'
            ),
            'moc_sources': files(
                'tests/test_vlc_dialog_model.cpp'
            ),
            'moc_headers': files(
                'dialogs/dialogs/dialogmodel.hpp'
            ),
            'suite': ['qt'],
            'include_directories' : qt_include_dir,
            'link_with': [libvlccore, libvlc],
            'link_args': qt_link_args,
            'dependencies': [qt6_dep, qt_extra_deps, qtest_qt6_dep],
        }
    endif

    quicktest_qt6_dep = dependency('qt6', version: '=' + qt6_dep.version(), modules: ['QuickTest'], required: false)
    if quicktest_qt6_dep.found() and  qtest_qt6_dep.found()
        qml_test_moc = qt6.compile_moc(
            headers : files('tests/qml_test.hpp'),
            dependencies : [quicktest_qt6_dep, qt6_dep]
        )
        qml_test = executable(
          'qml_test',
          [files('tests/qml_test.cpp', 'tests/qml_test.hpp'), qml_test_moc],
          qt6pre_qrc,
          build_by_default: false,
          dependencies: [quicktest_qt6_dep, qt6_dep, qtest_qt6_dep],
          link_with: qmllibs,
          cpp_args: ['-DQUICK_TEST_SOURCE_DIR="' + meson.current_source_dir() + '/tests"']
        )
        foreach test_name, test_file : qml_tests
              test(test_name, qml_test, args: ['-input', test_file], suite:'qt')
        endforeach
    endif

endif
