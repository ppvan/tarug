
## Setup guide
> This guide support VScode only, it's may work with GNOME builder but I'm not sure.

### 1. Install dependencies and build tool.

```sh
# Install gtk4, vala, meson and postgresql (provide libpq) 

yay -S gtk4 \
vala \
meson \
postgresql \
flatpak-builder
flatpak
```

### 2. Setup test database

Follow the postgres setup guide in [this gist](https://gist.github.com/NickMcSweeney/3444ce99209ee9bd9393ae6ab48599d8)

I often use the dvdrental sample db when develop and test tarug.


### 3. Build Tarug

- Install Flatpak Intergration for VScode [extension](https://github.com/bilelmoussaoui/flatpak-vscode)
- Open VScode commmand prompt (Ctr+Shift+P/Cmd+Shift+P) type: "Flatpak: Select or change manifest", make sure it's io.github.ppvan.tarug
- Open the prompt again and type "Flatpak: Build and Run"
- Start patching!!


### 4. Trouble shooting

If you got error something like: `org.gnome.Sdk/*unspecified*/47 not installed`. Install required runtime and sdk.

```sh
flatpak install flathub org.gnome.Platform//47 org.gnome.Sdk//47 org.freedesktop.Sdk.Extension.vala//24.08
```

If you do not see syntax hightlight or meson error, check your local .vscode setting:: `.vscode/settings.json`. It should be update by the flatpak extension to something like:

```json
{
    "mesonbuild.configureOnOpen": false,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/.hg/store/**": true,
        ".flatpak/**": true,
        "_build/**": true
    },
    "mesonbuild.mesonPath": "${workspaceFolder}/.flatpak/meson.sh",
    "vala.languageServerPath": "${workspaceFolder}/.flatpak/vala-language-server.sh",
    "mesonbuild.buildFolder": "_build",
    "C_Cpp.default.compileCommands": "/home/ppvan/Documents/code/github/tarug/_build/compile_commands.json",
    "C_Cpp.default.configurationProvider": "mesonbuild.mesonbuild"
}
```


## Project structure

To be update.