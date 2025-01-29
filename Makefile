# This is just a file for me to type command faster, not the build file.

SHELL := /bin/bash
VALA_FILES := $(shell find $(SRC_DIR) -name '*.vala')
PROJECT_NAME := tarug

debug:
	rm -rf build/resources/gtk
	meson configure -Dbuildtype=debug build
	ninja -C build/ && G_MESSAGES_DEBUG=Tarug ./build/src/tarug

release:
	meson configure -Dbuildtype=release build
	ninja -C build/ && G_MESSAGES_DEBUG=Tarug ./build/src/tarug

format:
	@echo "Formatting Vala files..."
	uncrustify -l VALA -c uncrustify.cfg --replace --no-backup $(VALA_FILES)

clean:
	rm -rf build/resources

test:
	ninja -C build/ && ./build/test/tarug-test

flatpak:
	flatpak-builder --install-deps-from=flathub build-aux/ pkgs/flatpak/io.github.ppvan.tarug.yml --force-clean
	flatpak build-export export build-aux
	flatpak build-bundle export ./build-aux/io.github.ppvan.tarug.flatpak io.github.ppvan.tarug --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo

run:
	G_MESSAGES_DEBUG=Tarug ./build/src/tarug