anilist_gtk_sources = [
  'AnilistGtkApp.vala',
  'MainWindow.vala',
]

anilist_gtk_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.2.1'),
  dependency('libadwaita-1', version: '>= 1.0.0-alpha.2'),
]

gnome = import('gnome')

anilist_gtk_sources += gnome.compile_resources('anilist_gtk-resources',
  'anilist_gtk.gresource.xml',
  c_name: 'anilist_gtk'
)

executable('anilist-gtk', anilist_gtk_sources,
  vala_args: '--target-glib=2.50',  dependencies: anilist_gtk_deps,
  install: true,
)
