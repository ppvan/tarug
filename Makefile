# Directories
FLATPAK_DIR := .flatpak
BUILD_DIR := build
REPO_DIR := $(FLATPAK_DIR)/repo
STATE_DIR := $(FLATPAK_DIR)/flatpak-builder
BUNDLE_DIR := $(FLATPAK_DIR)/finalized-repo

# Application info
APP_ID := io.github.ppvan.tarug
MANIFEST := pkgs/flatpak/$(APP_ID).yml
SDK := org.gnome.Sdk
PLATFORM := org.gnome.Platform
VERSION := 47

# Common builder flags
BUILDER_FLAGS := --ccache \
				--force-clean \
				--disable-updates \
				--state-dir=$(STATE_DIR) \
				--stop-at=tarug


# Run flatpak app without install, a lot of hack since flatpak not realy support this (wtf?)
# Reference: https://github.com/flatpak/flatpak/issues/408
RUNNER_FLAGS := --with-appdir \
				--allow=devel \
				--env=AT_SPI_BUS_ADDRESS=unix:path=/run/flatpak/at-spi-bus \
				--env=DESKTOP_SESSION=$(DESKTOP_SESSION) \
				--env=LANG=$(LANG) \
				--env=WAYLAND_DISPLAY=$(WAYLAND_DISPLAY) \
				--env=XDG_CURRENT_DESKTOP=$(XDG_CURRENT_DESKTOP) \
				--env=XDG_SESSION_DESKTOP=$(XDG_SESSION_DESKTOP) \
				--env=XDG_SESSION_TYPE=$(XDG_SESSION_TYPE) \
				--bind-mount=/run/host/fonts=/usr/share/fonts \
				--bind-mount=/run/host/fonts-cache=/var/cache/fontconfig \
				--bind-mount=/run/host/user-fonts-cache=$(HOME)/.cache/fontconfig \
				--bind-mount=/run/host/font-dirs.xml=$(HOME)/.cache/font-dirs.xml \
				--bind-mount=/run/flatpak/at-spi-bus=/run/user/1000/at-spi/bus \
				--filesystem=$(HOME)/.local/share/fonts:ro \
				--filesystem=$(HOME)/.cache/fontconfig:ro \
				--share=network \
				--share=ipc \
				--socket=fallback-x11 \
				--socket=wayland \
				--talk-name="org.freedesktop.portal.*" \
				--talk-name=org.a11y.Bus \
				--device=dri

init:
	flatpak build-init $(REPO_DIR) $(APP_ID) $(SDK) $(PLATFORM) $(VERSION)

download:
	flatpak-builder \
	$(BUILDER_FLAGS) \
	--download-only \
	$(REPO_DIR) \
	$(MANIFEST)

build-deps: download
	flatpak-builder \
	$(BUILDER_FLAGS) \
	--disable-download \
	--build-only \
	--keep-build-dirs \
	$(REPO_DIR) \
	$(MANIFEST)

configure: build-deps
	flatpak build \
	--share=network \
	--filesystem=$(PWD) \
	--filesystem=$(PWD)/$(REPO_DIR) \
	--filesystem=$(PWD)/$(BUILD_DIR) \
	$(REPO_DIR) \
	meson setup $(BUILD_DIR)

build: configure
	flatpak build \
	--share=network \
	--filesystem=$(PWD) \
	--filesystem=$(PWD)/$(REPO_DIR) \
	--filesystem=$(PWD)/$(BUILD_DIR) \
	$(REPO_DIR) \
	ninja -C $(BUILD_DIR)

install: build
	flatpak build \
	--share=network \
	--filesystem=$(PWD) \
	--filesystem=$(PWD)/$(REPO_DIR) \
	--filesystem=$(PWD)/$(BUILD_DIR) \
	$(REPO_DIR) \
	ninja -C $(BUILD_DIR) install

run: install
	flatpak build \
	$(RUNNER_FLAGS) \
	$(REPO_DIR) tarug

bundle: build
	cp -r $(REPO_DIR) $(BUNDLE_DIR)
	flatpak build-export $(FLATPAK_DIR)/ostree-repo $(BUNDLE_DIR)
	flatpak build-bundle $(FLATPAK_DIR)/ostree-repo $(APP_ID).flatpak $(APP_ID)

lsp:
	flatpak build $(RUNNER_FLAGS) $(REPO_DIR) /usr/lib/sdk/vala/bin/vala-language-server

meson:
	flatpak build $(RUNNER_FLAGS) $(REPO_DIR) /usr/bin/meson

test:
	flatpak build $(RUNNER_FLAGS) $(REPO_DIR) /usr/bin/meson test -C $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(REPO_DIR)