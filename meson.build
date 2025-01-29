project(
    'io.github.ppvan.tarug',
    ['c', 'vala'],
    version: '0.2.0',
    meson_version: '>= 1.2.0',
    default_options: [
        'warning_level=1',
        'werror=false',
    ],
)

app_id = meson.project_name()
app_resource_prefix = meson.project_name().replace('.', '/')
app_name = meson.project_name().split('.')[-1]

i18n = import('i18n')
gnome = import('gnome')
valac = meson.get_compiler('vala')

subdir('data')
subdir('resources')
subdir('src')
subdir('po')

# Using gnome module to do some task after the app is installed, like compile schema (settings data)
# Update icon cache.
gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
)
