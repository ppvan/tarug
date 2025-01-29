<!--
    2023 ppvan phuclaplace@gmail.com
-->
<h1 align="center">
<img
    src="data/icons/hicolor/scalable/apps/io.github.ppvan.tarug.svg" alt="tarug"
    width="128"
    height="128"/><br/>
    Tarug
</h1>

<p align="center">
<a href="https://stopthemingmy.app">
    <img width="200" src="https://stopthemingmy.app/badge.svg"/>
</a>
</p>

<p align="center">
<a href="https://flathub.org/apps/io.github.ppvan.tarug">
    <img width="200" src="https://flathub.org/assets/badges/flathub-badge-en.png" alt="Download on Flathub">
</a>
</p>

<p align="center">
    <img alt="Screenshot" src="screenshots/screenshot.png"/>
</p>


Small tool for quick sql query, specialized in PostgresSQL.

> **This project is not a part of or affiliated with PostgreSQL.**

# Features
- Load and save connections.
- Import and Export connections info
- List schema info, tables, views.
- View table columns info, indexes, foreign keys
- View table data, sort by column
- Write query
- Query History
- Hightlight current query
- Export query data

# Installation

## Flatpak
> **Recommended**

<a href="https://flathub.org/apps/io.github.ppvan.tarug">Click here</a> to install app from Flathub.

## Build from source

### Via GNOME Builder
PSequel can be built with GNOME Builder >= 3.38. Clone this repo and click run button.

> (Warning: required to rebuild postgres, will take a little bit of time)


# Contributions
Contributions are welcome.

# Credits

- [Psequel](https://psequel.com/) - MacOS postgresql client. This project is inspired by Psequel.
- [libpg_query](https://github.com/pganalyze/libpg_query) - PostgresSQL parser
- [libcsv](https://github.com/rgamble/libcsv) - Robust C csv library