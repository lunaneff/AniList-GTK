anilist_gtk_sources = [
  'AnilistGtkApp.vala',
  'MainWindow.vala',
  'LoginWindow.vala',
  'AnilistClient.vala',
  'MediaListWidget.vala',
  'MediaListEntryWidget.vala',
]

anilist_gtk_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.2.1'),
  dependency('libadwaita-1', version: '>= 1.0.0-alpha.2'),
  dependency('libsecret-1', version: '>= 0.20.4'),
  dependency('json-glib-1.0', version: '>= 1.6.2'),
  dependency('libsoup-2.4', version: '>= 2.72.0'),
  dependency('gee-0.8', version: '>= 0.20.4'),
]

gnome = import('gnome')

anilist_gtk_sources += gnome.compile_resources('anilist_gtk-resources',
  '../data/resources/anilist_gtk.gresource.xml',
  c_name: 'anilist_gtk',
  source_dir: '../data/resources'
)

executable('anilist-gtk', anilist_gtk_sources,
  vala_args: '--target-glib=2.50',  dependencies: anilist_gtk_deps,
  install: true,
)
