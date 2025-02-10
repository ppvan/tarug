# Source code
tarug_sources = files(
    'models/Connection.vala',
    'models/Query.vala',
    'models/Relation.vala',
    'models/Schema.vala',
    'models/Table.vala',
    'repositories/ConnectionRepository.vala',
    'repositories/QueryRepository.vala',
    'repositories/SchemaRepository.vala',
    'services/BackupService.vala',
    'services/Container.vala',
    'services/ExportService.vala',
    'services/MigrationService.vala',
    'services/NavigationService.vala',
    'services/ResourceManager.vala',
    'services/SQLCompletionService.vala',
    'services/TableColumnCompletionService.vala',
    'services/SQLService.vala',
    'services/SchemaService.vala',
    'services/StorageService.vala',
    'utils/Event.vala',
    'utils/ObservableList.vala',
    'utils/ValueConverter.vala',
    'utils/errors.vala',
    'utils/logging.vala',
    'utils/types.vala',
    'viewmodels/BaseViewModel.vala',
    'viewmodels/ConnectionViewModel.vala',
    'viewmodels/DataViewModel.vala',
    'viewmodels/QueryHistoryViewModel.vala',
    'viewmodels/QueryViewModel.vala',
    'viewmodels/SchemaViewModel.vala',
    'viewmodels/TableDataViewModel.vala',
    'viewmodels/TableViewModel.vala',
    'viewmodels/ViewDataViewModel.vala',
    'viewmodels/ViewStructureViewModel.vala',
    'viewmodels/ViewViewModel.vala',

)

ui_sources = files(
    'ui/PreferencesWindow.vala',
    'ui/Window.vala',
    'ui/editor/QueryEditor.vala',
    'ui/schema/QueryResult.vala',
    'ui/schema/TableDataView.vala',
    'ui/schema/TableStructureView.vala',
    'ui/schema/ViewDataView.vala',
    'ui/schema/ViewStructureView.vala',
    'ui/views/ConnectionView.vala',
    'ui/views/SchemaView.vala',
    'ui/widgets/WhereEntry.vala',
    'ui/widgets/BackupDialog.vala',
    'ui/widgets/EditRowDialog.vala',
    'ui/widgets/DataCell.vala',
    'ui/widgets/RestoreDialog.vala',
    'ui/widgets/Shape.vala',
    'ui/widgets/StyleSwitcher.vala',
    'ui/widgets/TableColumnInfo.vala',
    'ui/widgets/TableGraph.vala',
    'ui/widgets/TableIndexInfo.vala',
    'ui/widgets/TableRow.vala',
    'utils/helpers.vala',
)

# Create config data, this will create a config.h file, then be bind to Config class.

vapi_dir = join_paths(meson.current_source_dir(), 'vapi')
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

cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required: false)

tarug_deps = [
    # assume exists typical gtk system
    dependency('glib-2.0', version: '>=2.80'),
    dependency('gtk4', version: '>=4.10'),
    dependency('libadwaita-1', version: '>= 1.5'),
    dependency('json-glib-1.0', version: '>= 1.6'),
    dependency('gee-0.8'),
    dependency('gtksourceview-5', version: '>= 5.0'),
    dependency('libpq', version: '>= 15.3'),
    math_dep,
    dependency('sqlite3'),
    dependency('pgquery-vala'),
    cc.find_library('csv', has_headers: ['csv.h'], required: true),
    valac.find_library('config', dirs: vapi_dir),
]

add_project_arguments(
    [
        '--target-glib=2.80',
        '--vapidir', vapi_dir,
        '--gresourcesdir', tarug_resources_dir,
        '--enable-deprecated',
        '--pkg', 'csv'
    ],
    language: 'vala',
)


add_project_arguments(
    '-include', 'config.h',
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c',
)

add_project_arguments(
    [
        '-Wno-pointer-sign',
        '-Wno-deprecated-declarations',
        '-Wno-format',
        '-Wno-unused',
        '-Wno-address',
        '-Wno-switch',
        '-Wno-incompatible-pointer-types',
        '-Wno-discarded-qualifiers'
    ],
    language: 'c',
)

tarug_sources_main = tarug_sources + ui_sources + files('application.vala')

executable(
    app_name,
    [tarug_resources, tarug_sources_main],
    dependencies: tarug_deps,
    vala_args: [
        '--gresourcesdir=' + tarug_resources_dir,
    ],
    install: true,
)


tarug_sources_test = tarug_sources + files('cmd.vala')
test(
    'foo',
   executable(
    'tarug_test',
    [tarug_resources, tarug_sources_test],
    dependencies: tarug_deps,
    vala_args: [
        '--gresourcesdir=' + tarug_resources_dir,
    ]
   ),
   protocol: 'tap',
)
