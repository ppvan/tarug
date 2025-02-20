
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

```
make build run
```

> If you got error something like: `org.gnome.Sdk/*unspecified*/47 not installed`. Install required runtime and sdk.
    ```sh
    flatpak install flathub org.gnome.Platform//47 org.gnome.Sdk//47 org.freedesktop.Sdk.Extension.vala//24.08
    ```

Try edit `resources/gtk/connection-view.blp:200` label from "Connect with Tarug" to "Hello world". Build the project again to see the change

## Project structure

To be update.