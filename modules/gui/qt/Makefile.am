guidir = $(pluginsdir)/gui
gui_LTLIBRARIES =
gui_PLUGINS =
gui_RPATH =

if HAVE_PARTIAL_LINKING
noinst_LTLIBRARIES = $(gui_PLUGINS)
else
gui_LTLIBRARIES += $(gui_PLUGINS)
gui_RPATH += -rpath '$(guidir)'
endif


## Howto
# For each Q_OBJECT:
#   - Add *.moc.cpp to nodist_..._SOURCES
#   - Add *.cpp to ..._SOURCES
#   - Add *.hpp to ..._SOURCES
# For each UI
#   - Add *.ui to ..._UI
#   - Add *.h to nodist_..._SOURCES
# For each resource (icon, png, ...)
#   - Add it to DEPS_res
# For each qml and js resource
#   - Add it to ..._QML

CLEANFILES =

include ../../common.am

# Generate vlc_modules_list for Qt plugins
include ../../modulelist.mk

SUFFIXES += .ui .h .hpp .moc.cpp .qml .js .mjs .moc
TEST_EXTENSIONS = .qml
EXTRA_DIST = qt6.pro qtest.pro quicktest.pro scripts
vlc_qt_libs = $(QT_LIBS)
RCC_EXTRA_PARAMS =

all-local: $(VLC_QT_CHECK_DEP) $(QML_MODULE_STAMPS)

if !HAVE_QT_ZSTD
RCC_EXTRA_PARAMS += --no-zstd
endif

vlc_qt_check_SOURCES = vlc-qt-check.cpp plugins.hpp
vlc_qt_check_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) -fPIC $(CXXFLAGS_qt)
vlc_qt_check_CPPFLAGS = $(AM_CPPFLAGS) $(CPPFLAGS_qt)
vlc_qt_check_LDADD = $(vlc_qt_libs)
vlc_qt_check_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)

libqt_plugin_la_CPPFLAGS = $(AM_CPPFLAGS) $(CPPFLAGS_qt) \
	-DQT_STRICT_ITERATORS \
	-DQT_USE_QSTRINGBUILDER \
	-DQT_NO_CAST_TO_ASCII \
	-DQT_NO_CAST_FROM_BYTEARRAY \
	-I$(srcdir) -I$(builddir) \
	-I$(builddir)/dialogs/extended \
	-I$(builddir)/dialogs/fingerprint \
	-I$(builddir)/dialogs/firstrun \
	-I$(builddir)/dialogs/help \
	-I$(builddir)/dialogs/messages \
	-I$(builddir)/dialogs/open \
	-I$(builddir)/dialogs/podcast \
	-I$(builddir)/dialogs/preferences \
	-I$(builddir)/dialogs/sout \
	-I$(builddir)/dialogs/vlm

libqt_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) $(CXXFLAGS_qt) -fPIC
libqt_plugin_la_LIBADD = $(vlc_qt_libs)
if HAVE_LIBATOMIC
libqt_plugin_la_CXXFLAGS += -DQT_HAS_LIBATOMIC
libqt_plugin_la_LIBADD += -latomic
endif
libqt_plugin_la_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS) $(GC_SECTIONS_LDFLAGS)
if HAVE_OSX
libqt_plugin_la_LDFLAGS += -Wl,-framework,Cocoa
endif

if HAVE_X
if HAVE_XCB
libqt_plugin_la_CXXFLAGS += $(XCB_CFLAGS) -DQT_HAS_X11
libqt_plugin_la_LIBADD += $(XCB_LIBS) $(X_LIBS) $(X_PRE_LIB) -lX11
vlc_qt_check_CXXFLAGS += $(XCB_CFLAGS) -DQT_HAS_X11
endif
endif

if HAVE_WIN32
libqt_plugin_la_CXXFLAGS += $(LIBCOMCXXFLAGS)
libqt_plugin_la_LIBADD += $(LIBCOM) -lcomctl32 -luuid -ldwmapi
endif
if UPDATE_CHECK
libqt_plugin_la_CPPFLAGS += -DUPDATE_CHECK
endif
if QT_QML_DEBUG
libqt_plugin_la_CPPFLAGS += -DQT_QML_DEBUG
endif
if HAVE_QT_GTK
libqt_plugin_la_CPPFLAGS += -DQT_HAS_GTK
endif

include $(srcdir)/buildsystem/sources.am
include $(srcdir)/buildsystem/moc.am
if HAVE_WIN32

libqt_plugin_la_SOURCES += \
	maininterface/mainctx_win32.cpp \
	maininterface/mainctx_win32.hpp \
	maininterface/compositor_win7.cpp \
	maininterface/compositor_win7.hpp \
	style/windowsthemeprovider.cpp \
	maininterface/win32windoweffects_module.cpp \
	maininterface/win32windoweffects_module.hpp \
	util/csdmenu_win32.c \
	util/csdmenu_win32.h

nodist_libqt_plugin_la_SOURCES += maininterface/mainctx_win32.moc.cpp \
	maininterface/compositor_win7.moc.cpp

libqt_plugin_la_SOURCES += \
	maininterface/compositor_dcomp.cpp \
	maininterface/compositor_dcomp.hpp \
	maininterface/compositor_dcomp_error.hpp \
	maininterface/compositor_dcomp_acrylicsurface.hpp \
	maininterface/compositor_dcomp_acrylicsurface.cpp

nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_dcomp_acrylicsurface.moc.cpp \
	maininterface/compositor_dcomp.moc.cpp

endif

# X11 compositor

if HAVE_X
if HAVE_QT_XCB
if HAVE_XCB
if HAVE_XCB_DAMAGE
if HAVE_XCB_XFIXES

libqt_plugin_la_CXXFLAGS += -DQT_HAS_X11_COMPOSITOR \
	$(QT_X11_CFLAGS) $(XCB_RENDER_CFLAGS) $(XCB_COMPOSITE_CFLAGS) $(XCB_DAMAGE_CFLAGS) $(XCB_XFIXES_CFLAGS)

libqt_plugin_la_LIBADD += $(QT_X11_LIBS) $(XCB_RENDER_LIBS) $(XCB_COMPOSITE_LIBS) $(XCB_DAMAGE_LIBS) $(XCB_XFIXES_LIBS)

libqt_plugin_la_SOURCES += \
	maininterface/compositor_x11.cpp \
	maininterface/compositor_x11.hpp \
	maininterface/compositor_x11_renderclient.cpp \
	maininterface/compositor_x11_renderclient.hpp \
	maininterface/compositor_x11_renderwindow.cpp \
	maininterface/compositor_x11_renderwindow.hpp \
	maininterface/compositor_x11_uisurface.cpp \
	maininterface/compositor_x11_uisurface.hpp \
	maininterface/compositor_x11_utils.cpp \
	maininterface/compositor_x11_utils.hpp

nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_x11.moc.cpp \
	maininterface/compositor_x11_renderclient.moc.cpp \
	maininterface/compositor_x11_renderwindow.moc.cpp \
	maininterface/compositor_x11_uisurface.moc.cpp

#extra X11 features

libqt_x11_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(XCB_CFLAGS) $(XCB_RENDER_CFLAGS) $(XCB_COMPOSITE_CFLAGS) $(XCB_DAMAGE_CFLAGS) $(XCB_XFIXES_CFLAGS)
libqt_x11_plugin_la_LIBADD = $(XCB_LIBS) $(XCB_RENDER_LIBS) $(XCB_COMPOSITE_LIBS) $(XCB_DAMAGE_LIBS) $(XCB_XFIXES_LIBS)
libqt_x11_plugin_la_SOURCES = \
	maininterface/qt_x11_plugin.c \
	maininterface/compositor_x11_utils.hpp \
	maininterface/compositor_x11_utils.cpp \
	util/csdmenu_module.h \
	util/csdmenu_x11.cpp \
	util/csdmenu_x11.h

if ENABLE_QT
gui_PLUGINS += libqt_x11_plugin.la
endif

endif
endif
endif
endif
endif

# wayland compositor

if HAVE_WAYLAND
if HAVE_QT_GUI_PRIVATE

libqt_plugin_la_CPPFLAGS += -DQT_HAS_WAYLAND_COMPOSITOR

libqt_plugin_la_SOURCES += \
	maininterface/compositor_wayland.cpp \
	maininterface/compositor_wayland.hpp


nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_wayland.moc.cpp

libqt_wayland_plugin_la_CFLAGS = $(AM_CFLAGS) $(WAYLAND_CLIENT_CFLAGS)
libqt_wayland_plugin_la_LIBADD =  $(WAYLAND_CLIENT_LIBS) $(LIBM)
libqt_wayland_plugin_la_SOURCES = \
	maininterface/qt_wayland_plugin.c \
	maininterface/compositor_wayland_module.c \
	maininterface/compositor_wayland_module.h

#if WAYLAND_PROTOCOLS
#if WAYLAND_SCANNER
libqt_wayland_plugin_la_CFLAGS += -DQT_HAS_WAYLAND_PROTOCOLS -I$(builddir)/maininterface

libqt_wayland_plugin_la_SOURCES += \
	util/csdmenu_wayland.c \
	util/csdmenu_wayland.h \
	util/csdmenu_module.h

nodist_libqt_wayland_plugin_la_SOURCES = \
	maininterface/xdg-shell-client-protocol.h \
	maininterface/xdg-shell-protocol.c

if HAVE_QT65
libqt_wayland_plugin_la_CFLAGS += -DQT_HAS_WAYLAND_FRACTIONAL_SCALING
nodist_libqt_wayland_plugin_la_SOURCES += \
	maininterface/viewporter-client-protocol.h \
	maininterface/viewporter-protocol.c

maininterface/viewporter-client-protocol.h: \
		$(WAYLAND_PROTOCOLS)/stable/viewporter/viewporter.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) client-header $< $@

maininterface/viewporter-protocol.c: \
		$(WAYLAND_PROTOCOLS)/stable/viewporter/viewporter.xml \
		maininterface/viewporter-client-protocol.h
	$(AM_V_GEN)$(WAYLAND_SCANNER) private-code $< $@
endif

BUILT_SOURCES += $(nodist_libqt_wayland_plugin_la_SOURCES)

maininterface/xdg-shell-client-protocol.h: $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) client-header $< $@

maininterface/xdg-shell-protocol.c: $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) private-code $< $@

#endif
#endif

if ENABLE_QT
gui_PLUGINS += libqt_wayland_plugin.la
endif

endif
endif

if !HAVE_WIN32
if HAVE_KF6WINDOWSYSTEM

libqt_plugin_la_CPPFLAGS += -DQT_HAS_KWINDOWSYSTEM_PLUGIN

libqt_kwindowsystem_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(KF6WINDOWSYSTEM_CFLAGS)
libqt_kwindowsystem_plugin_la_LIBADD =  $(KF6WINDOWSYSTEM_LIBS) $(QT_LIBS)
libqt_kwindowsystem_plugin_la_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)
libqt_kwindowsystem_plugin_la_SOURCES = \
	maininterface/kwindowsystem_module.cpp

if ENABLE_QT
gui_PLUGINS += libqt_kwindowsystem_plugin.la
endif
endif
endif

# User interface compilation

uic_verbose = $(uic_verbose_$(V))
uic_verbose_ = $(uic_verbose__$(AM_DEFAULT_VERBOSITY))
uic_verbose_0 = @echo "  UIC     " $@;
uic_verbose__0 = $(uic_verbose_0)

MOC_CPPFLAGS = $(DEFS) \
	-I$(top_srcdir)/include -I$(top_builddir)/include -I$(top_builddir) \
	$(QT_MOC_INCLUDE_DIRS) \
	$(QT_CFLAGS) \
	$(libqt_plugin_la_CPPFLAGS)
if HAVE_DARWIN
MOC_CPPFLAGS += -DQ_OS_MAC
endif
if HAVE_WIN32
MOC_CPPFLAGS += -D_WIN32
endif

libqt_plugin_la_UI = \
	dialogs/extended/equalizer.ui \
	dialogs/extended/video_effects.ui \
	dialogs/fingerprint/fingerprintdialog.ui \
	dialogs/firstrun/firstrunwizard.ui \
	dialogs/help/about.ui \
	dialogs/help/update.ui \
	dialogs/messages/messages_panel.ui \
	dialogs/open/open.ui \
	dialogs/open/open_capture.ui \
	dialogs/open/open_disk.ui \
	dialogs/open/open_file.ui \
	dialogs/open/open_net.ui \
	dialogs/podcast/podcast_configuration.ui \
	dialogs/preferences/sprefs_audio.ui \
	dialogs/preferences/sprefs_input.ui \
	dialogs/preferences/sprefs_interface.ui \
	dialogs/preferences/sprefs_medialibrary.ui \
	dialogs/preferences/sprefs_subtitles.ui \
	dialogs/preferences/sprefs_video.ui \
	dialogs/sout/profiles.ui \
	dialogs/sout/sout.ui \
	dialogs/vlm/vlm.ui
EXTRA_DIST += $(libqt_plugin_la_UI)

ui_%.h: %.ui
	$(AM_V_at)$(MKDIR_P) "ui"
	$(AM_V_at)rm -f $@ $@.tmp
	$(AM_V_at)echo "#define Q_(a,b) QString::fromUtf8(_(a))" > $@.tmp
	$(uic_verbose)$(UIC) -tr "Q_" $< >> $@.tmp
	$(AM_V_at)sed -e 's/Q_(\"_(\\\"\(.*\)\\\")"/Q_("\1"/' $@.tmp >$@
	$(AM_V_at)rm -f $@.tmp

# Resources

include $(srcdir)/buildsystem/resources.am
include $(srcdir)/buildsystem/qml.am
include $(srcdir)/buildsystem/rules.am
