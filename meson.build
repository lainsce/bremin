project('io.github.lainsce.Bremin', 'vala', 'c',
    version: '0.1.0',
    default_options: ['warning_level=2'])

gnome = import('gnome')

add_project_arguments('-w', language: 'c')

# Dependencies
gtk_dep = dependency('gtk4')
glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')

add_project_arguments(
    '-w',
    language: 'c',
)

# Source files
sources = [
    'src/Application.vala',
    'src/Calendar.vala',
    'src/ReportView.vala',
    'src/SessionView.vala',
    'src/SetupView.vala',
    'src/StatsView.vala',
    'src/Utils.vala',
    'src/Window.vala'
]

# UI files
resources = gnome.compile_resources(
    'resources',
    'data/app.gresource.xml'
)

# Install the .desktop file
install_data(
  'data/app.desktop',
  install_dir: join_paths(get_option('datadir'), 'applications'),
  rename: 'io.github.lainsce.Bremin.desktop'
)

# Install the icon
install_data(
  'data/icon.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '128x128', 'apps'),
  rename: 'io.github.lainsce.Bremin.svg'
)

libm_dep = meson.get_compiler('c').find_library('m', required: false)
# Executable
executable('io.github.lainsce.Bremin',
    sources + resources,
    dependencies: [
      gtk_dep,
      glib_dep,
      gee_dep,
      libm_dep,
      dependency('libhelium-1')
    ],
    install: true
)

gnome.post_install(
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
