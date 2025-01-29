

blueprint_compiler = find_program('blueprint-compiler')

# CURRENT_SOURCE_DIR relative to BUILDDIR blueprints_output_dir = meson.current_build_dir()
# This is a hack to make sure below target was run. For some reason you can't use example from blueprint docs.

tarug_resources_dir = meson.current_build_dir()

mark_ups = [
    'gtk/connection-listitem.blp',
    'gtk/connection-row.blp',
    'gtk/connection-view.blp',
    'gtk/datacell.blp',
    'gtk/help-overlay.blp',
    'gtk/preferences-window.blp',
    'gtk/query-editor.blp',
    'gtk/query-listitem.blp',
    'gtk/query-results.blp',
    'gtk/schema-view.blp',
    'gtk/style-switcher.blp',
    'gtk/table-cols.blp',
    'gtk/table-data-view.blp',
    'gtk/table-fk.blp',
    'gtk/table-graph.blp',
    'gtk/table-index.blp',
    'gtk/table-listitem.blp',
    'gtk/table-row.blp',
    'gtk/table-structure-view.blp',
    'gtk/view-data-view.blp',
    'gtk/view-listitem.blp',
    'gtk/view-structure-view.blp',
    'gtk/window.blp',
    'gtk/backup-dialog.blp',
    'gtk/restore-dialog.blp',
    'gtk/edit-row.blp',
    'gtk/where-entry.blp'
]

icons = [
    'plus-large-symbolic.svg',
    'minus-large-symbolic.svg',
    'library-symbolic.svg',
    'object-rows-symbolic.svg',
    'terminal-symbolic.svg',
    'loupe-large-symbolic.svg',
    'refresh-large-symbolic.svg',
    'table-symbolic.svg',
    'columns-symbolic.svg',
    'step-out-symbolic.svg',
    'arrow-into-box-symbolic.svg',
    'category-search-symbolic.svg',
    'left-large-symbolic.svg',
    'right-large-symbolic.svg',
    'text-sql-symbolic.svg',
    'webview-filler-symbolic.svg',
    'settings-symbolic.svg',
    'test-pass-symbolic.svg',
    'history-undo-symbolic.svg',
    'check-plain-symbolic.svg',
    'export-symbolic.svg',
    'filemanager-app-symbolic.svg',
    'application-certificate-symbolic.svg',
    'copy-symbolic.svg'
]


blueprints = custom_target(
    'blueprints',
    input: files(mark_ups),
    build_by_default: true,
    build_always_stale: true,
    #   This does not run if you use an dot (.)
    output: '.',
    command: [
        blueprint_compiler,
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)

ui_files = ''
foreach mark_up : mark_ups
    filename = mark_up.replace('.blp', '.ui')
    ui_files += f'<file preprocess="xml-stripblanks">@filename@</file>'
endforeach

icon_files = ''
foreach icon : icons
    icon_files += f'<file preprocess="xml-stripblanks" alias="@icon@">gtk/icons/@icon@</file>'
endforeach

resource_data = configuration_data()
resource_data.set('PREFIX', app_resource_prefix)
resource_data.set('UI_FILES', ui_files)
resource_data.set('ICON_FILES', icon_files)


tarug_resources_xml = configure_file(
    input: 'tarug.gresource.xml.in',
    output: 'tarug.gresource.xml',
    configuration: resource_data,
)


tarug_resources = gnome.compile_resources(
    'tarug_resources',
    tarug_resources_xml,
    c_name: 'tarug_resources',
    dependencies: [blueprints],
    build_by_default: true
)

