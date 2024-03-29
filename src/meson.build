conf_data = configuration_data({
  'version': meson.project_version(),
  'build_type': get_option('build_type').to_upper()
})
build_config = configure_file(input: 'BuildConfig.vala.in',
                           output: 'BuildConfig.vala',
                           configuration: conf_data)

anilist_gtk_sources = [
  'AnilistGtkApp.vala',
  'MainWindow.vala',
  'LoginWindow.vala',
  'PreferencesWindow.vala',
  'AnilistClient.vala',
  'MediaListEntryWidget.vala',
  build_config
]

# We can't use the shorthand syntax for subprojects for libadwaita because of https://github.com/mesonbuild/meson/issues/1923
# Workaround code is based on https://gitlab.gnome.org/GNOME/gnome-clocks/-/blob/master/meson.build#L24-42
libadwaita_dep = dependency('libadwaita-1', version: '>= 1.0.0-alpha.2', required: false)
if not libadwaita_dep.found()
  libadwaita_proj = subproject(
    'libadwaita',
    default_options: [
      'examples=false',
      'tests=false',
    ]
  )
  libadwaita_dep = declare_dependency(
    dependencies: [
      libadwaita_proj.get_variable('libadwaita_dep'),
      libadwaita_proj.get_variable('libadwaita_vapi'),
    ]
  )
endif

anilist_gtk_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.2.1'),
  libadwaita_dep,
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

executable('ch.laurinneff.AniList-GTK', anilist_gtk_sources,
  vala_args: '--target-glib=2.50',  dependencies: anilist_gtk_deps,
  install: true,
)
