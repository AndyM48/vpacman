# vpacman
A graphical front end for pacman and the AUR - built with Tcl/Tk

This simple programme allows you to View the packages available in those pacman repositories which have been enabled in the pacman configuration file (/etc/pacman.conf) and to Install, Upgrade and Delete those packages. It also includes packages which have been installed from other sources - either from AUR or locally.

## Requirements
The only dependencies are pacman, tcl, tk, a terminal and wmctrl. Pacman is always used to install, update, delete and synchronize the pacman packages and database. Therefore the entries in the pacman configuration file will always be respected.

Note: Wmctrl relies on the window title set for the terminal. In order to use konsole the profile must be set to use the window title set by the shell.

## Optional Dependencies
A browser, an editor, pacman-contrib (for paccache to clean the package cache), pkgfile for faster retrieval of package files, xwininfo for fine control of terminal windows.

## Features

- View available packages
- View installed packages
- View packages not installed
- View packages with updates available
- Install and delete packages
- Synchronize with the Pacman database
- View AUR and local packages
- View AUR packages with updates availabe
- Install AUR packages by name
- Update and delete AUR packages
- Install local package files
- Delete local packages
- View detailed information and file lists for packages
- Check installation of packages
- Check for updated configuration files
- Clean Pacman package cache
- Read Arch news
- ... and more
