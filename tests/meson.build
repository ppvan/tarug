gnome = import('gnome')

conf = configuration_data()

conf.set_quoted('APP_ID', app_id)
conf.set_quoted('APP_NAME', 'Tarug')
conf.set_quoted('G_LOG_DOMAIN', 'Tarug')
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted(
    'DATADIR',
    join_paths(get_option('prefix'), get_option('datadir')),
)
conf.set_quoted(
    'GNOMELOCALEDIR',
    join_paths(get_option('prefix'), get_option('localedir')),
)
configure_file(output: 'config.h', configuration: conf)


tests = [
    'sql_connect',
]

foreach name : tests
    test(
        name,
    executable(
        name + '_test',
        [tarug_resources, tarug_sources, 'test_runtime.vala', name + '_test.vala'],
        dependencies: tarug_deps,
        vala_args: [
            '--gresourcesdir=' + tarug_resources_dir,
        ]
    ),
    protocol: 'tap',
    env: ['G_TEST_SRCDIR=' + meson.current_source_dir()]
    )
endforeach