# Sequelize

Remind future me:
```
 .
├──  application.vala
├──  gtk -> blue print, will compile to .ui files (2)
│  ├──  box.blp
│  ├──  help-overlay.ui
│  └──  window.blp
├── 謹 hellowolrd.gresource.xml <- List the ui files in this file (3)
├──  main.vala
├──  meson.build <- List the blue prints in this files to make the compiler running. (1)
├──  ui <- Create a class (.vala file) to load template in this file (4) 
└──  window.vala

```