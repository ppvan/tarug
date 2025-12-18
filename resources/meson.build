# UI files in gtk/ directory
ui_files = files(
  'gtk/connection-listitem.ui',
  'gtk/connection-row.ui',
  'gtk/connection-view.ui',
  'gtk/datacell.ui',
  'gtk/help-overlay.ui',
  'gtk/preferences-window.ui',
  'gtk/query-editor.ui',
  'gtk/query-listitem.ui',
  'gtk/query-results.ui',
  'gtk/schema-view.ui',
  'gtk/style-switcher.ui',
  'gtk/table-cols.ui',
  'gtk/table-data-view.ui',
  'gtk/table-fk.ui',
  'gtk/table-graph.ui',
  'gtk/table-index.ui',
  'gtk/table-listitem.ui',
  'gtk/table-row.ui',
  'gtk/table-structure-view.ui',
  'gtk/view-data-view.ui',
  'gtk/view-listitem.ui',
  'gtk/view-structure-view.ui',
  'gtk/window.ui',
  'gtk/backup-dialog.ui',
  'gtk/restore-dialog.ui',
  'gtk/edit-row.ui',
  'gtk/where-entry.ui'
)

# Icon files in gtk/icons/ directory
icon_files = files(
  'gtk/icons/plus-large-symbolic.svg',
  'gtk/icons/minus-large-symbolic.svg',
  'gtk/icons/library-symbolic.svg',
  'gtk/icons/object-rows-symbolic.svg',
  'gtk/icons/terminal-symbolic.svg',
  'gtk/icons/loupe-large-symbolic.svg',
  'gtk/icons/refresh-large-symbolic.svg',
  'gtk/icons/table-symbolic.svg',
  'gtk/icons/columns-symbolic.svg',
  'gtk/icons/step-out-symbolic.svg',
  'gtk/icons/arrow-into-box-symbolic.svg',
  'gtk/icons/category-search-symbolic.svg',
  'gtk/icons/left-large-symbolic.svg',
  'gtk/icons/right-large-symbolic.svg',
  'gtk/icons/text-sql-symbolic.svg',
  'gtk/icons/webview-filler-symbolic.svg',
  'gtk/icons/settings-symbolic.svg',
  'gtk/icons/test-pass-symbolic.svg',
  'gtk/icons/history-undo-symbolic.svg',
  'gtk/icons/check-plain-symbolic.svg',
  'gtk/icons/export-symbolic.svg',
  'gtk/icons/filemanager-app-symbolic.svg',
  'gtk/icons/application-certificate-symbolic.svg',
  'gtk/icons/copy-symbolic.svg'
)

# Generate XML entries for gresource file
fs = import('fs')

ui_entries = []
foreach f : ui_files
  ui_entries += '<file preprocess="xml-stripblanks">gtk/@0@</file>'.format(fs.name(f))
endforeach

icon_entries = []
foreach f : icon_files
  icon_name = fs.name(f)
  icon_entries += '<file preprocess="xml-stripblanks" alias="@0@">gtk/icons/@1@</file>'.format(icon_name, icon_name)
endforeach

# Configure gresource XML
resource_data = configuration_data()
resource_data.set('PREFIX', app_resource_prefix)
resource_data.set('UI_FILES', '\n    '.join(ui_entries))
resource_data.set('ICON_FILES', '\n    '.join(icon_entries))

tarug_resources_xml = configure_file(
  input: 'tarug.gresource.xml.in',
  output: 'tarug.gresource.xml',
  configuration: resource_data,
)

# Compile resources
tarug_resources = gnome.compile_resources(
  'tarug_resources',
  tarug_resources_xml,
  source_dir: meson.current_source_dir(),
  c_name: 'tarug_resources',
  dependencies: [ui_files, icon_files],
  build_by_default: true
)