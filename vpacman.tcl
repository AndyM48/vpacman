#!/bin/sh
# the next line restarts using wish \
exec wish "$0" -- "$@"

# we use this construct for two main reasons:
# 	 first, the location of the wish binary can be anywhere in your shell search path
#	 second, the "--" addition prevents wish from intercepting any arguments/options passed to it.
#		for example without the "--":
#			-h -help	would return wish help
#			-d -display	would open the wish window on the display indicated


#	 This is Vpacman - a Graphical front end for pacman and the AUR
#
#    Copyright (C) 2018 - 2022  Andrew Myers <andrew dot myers@wanadoo dot fr>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# set the version number
set version "1.4.7"

# save any arguments passed to vpacman
set args $argv

# run some tests on the arguments passed to vpacman.tcl

set debug ""
set usage_error false
set usage_help false
foreach item $args {
	# keep the "debug" option for backward compatability
	switch -- $item {
		-d	-
		--debug -
		debug {
			set debug "low"
		}
		-dd {
			set debug "medium"
		}
		-ddd {
			set debug "high"
		}
		-h -
		--help {
			set usage_help true
		}
		-dh -
		-hd {
			set debug "low"
			set usage_help true
		}
		-ddh -
		-hdd {
			set debug "medium"
			set usage_help true
		}
		-dddh -
		-hddd {
			set debug "high"
			set usage_help true
		}
		--restart {
		}
		default {
			set usage_help true
			set usage_error true
		}
	}
}

# set tk_messageBox defaults to a wider format
option add *Dialog.msg.wrapLength 12c
option add *Dialog.dtl.wrapLength 12c

# to reset the tk_messageBox to the default values use
#option clear

# do not throw an error if we ran vpacman.tcl from a terminal
# usage_help and usage_error have been set, so could be used later if necessary
set is_terminal [catch {exec tty -s} terminal_result]

if {$usage_help} {
	if {$is_terminal == 0} {
		if {$usage_help} {
			puts stdout "
Usage:

vpacman \[OPTIONS\]
Run vpacman - a Graphical front end for pacman and the AUR.

Options:

    -d --debug  run in debug mode. Output is saved to a file \"vpacman_debug.txt\" in the users home folder.
    -h --help   show this help. For extended help run vpacman and select Help > Help from the menu bar.
"
}
		if {$usage_error} {exit}
		puts stdout "Press <Enter> to run vpacman now: "
		fconfigure stdin -blocking 0; read stdin; fconfigure stdin -blocking 1
		exec /bin/stty raw -echo <@stdin
			set ans [read stdin 1]
		exec /bin/stty -raw echo <@stdin
		if {[scan $ans %c] != 10} {exit}
	} else {
		wm iconify .
		set detail "Options:\n\n   -d --debug  run in debug mode. Output is saved to a file\n\t\"vpacman_debug.txt\" in the users home folder.\n   -h --help     show this help. For extended help run vpacman\n\tand select Help > Help from the menu bar."
		set message "vpacman \[OPTIONS\]\n\nRun vpacman - a Graphical front end for pacman and the AUR."
		if {$usage_error} {
			tk_messageBox -default ok -detail $detail -message $message -parent . -title "Usage Error" -type ok
			exit
		} else {
			set ans [tk_messageBox -default ok -detail $detail -message $message -icon info -parent . -title "Usage" -type okcancel]
			if {$ans == "cancel"} {exit}
		}
	}
}

# now test the requirements to run vpacman.tcl
# check for threads

set error [catch {package require Thread}]
if {$error} {
	set threads false
} else {
	set threads true
}

# check for required programmes
set required "pacman wmctrl"
foreach programme $required {
	set result [catch {exec which $programme}]
	if {$result == 1} {
		tk_messageBox -default ok -detail "$programme is required by vpacman" -icon warning -message "Failed Dependency" -parent . -title "Error" -type ok
		exit
	}
}

# Use wmctrl to raise an already running application
# unless we have just restarted, in which case the previous window is in the process of being closed
if {[string first "--restart" $args] == -1} {
	set process [pid]
	set program [file tail $argv0]
	set list [split [exec ps -eo "pid cmd" | grep "$program"] \n]
	foreach i $list {
		if {[string first $process [string trim $i]] == 0} {continue}
		if {[string first grep $i] != -1} {continue}
		if {[string first "wish" $i] != -1 && [string first "$program" $i] != -1} {
			catch {exec wmctrl -F -a "Vpacman"}
			exit
		}
	}
}

# DECLARATIONS
# .. directories
global home program_dir tmp_dir
# .. configuration
global config_file 
# ..configurable
global backup_dir browser buttons editor geometry geometry_view helpbg helpfg icon_dir installed_colour keep_log outdated_colour save_geometry show_menu show_buttonbar terminal terminal_string
# ..variables
global about_text after_id anchor args aur_all aur_files aur_installs aur_list aur_messages aur_only aur_updates aur_versions backup_log bubble clock_id colours count_all count_installed count_outdated count_uninstalled dataview dbpath depends_searches diffprog dlprog filter filter_list find findfile find_message findtype fs_upgrade geometry_config group group_index help_text index installed_colour is_connected known_browsers known_diffprogs known_editors known_terminals list_all list_groups list_installed list_local list_local_ids list_outdated list_repos list_show list_show_ids list_show_order list_uninstalled listfirst listlast listview_current listview_last_selected listview_selected listview_selected_in_order local_newer message mirror_countries one_time outdated_colour package_actions pacman_files_upgrade part_upgrade pkgfile_upgrade repo_delete_msg select selected_list selected_message start_time state su_cmd sync_time system_data system_test thread threads times tv_index tv_select tverr_message tverr_text upgrade_time upgrades upgrades_count version win_configx win_configy win_mainx win_mainy

# VARIABLES

# Set directories
if {[file isdirectory /home/$env(USER)] == 1} {
	set home "/home/$env(USER)"
} else {
	set home $env(HOME)
}
set program_dir [file dirname [info script]]
if [string equal $program_dir "."] {
	set program_dir [pwd]
}

# the icons can be changed by copying the icon directory to a chosen location
# and then overwriting the icons with the preferred images of similar dimensions
# the location of the icon directory is preserved in the configuration file
set icon_dir "/usr/share/pixmaps/vpacman"

# we may need a temporary directory with more space than /tmp for aur_upgrades
# make the temporary directory if it does not already exist
# first check if the tmp directory exists before creating a new directory
if {[file isdirectory $home/.tmp/vpacman]} {
	set tmp_dir "$home/.tmp/vpacman"
} elseif {[file isdirectory $home/.tmp/vpacman]} {
	set tmp_dir "$home/.tmp/vpacman"
} else {
	# if there is a tmp directory in the users home dirctory use that
	if {[file isdirectory $home/tmp]} {
		file mkdir "$home/tmp/vpacman"
		set tmp_dir "$home/tmp/vpacman"
	} else {
	# if not then create a hidden tmp directory in the home directory and use that
		file mkdir "$home/.tmp/vpacman"
		set tmp_dir "$home/.tmp/vpacman"
	   }
}

# set other variables

# about text
set about_text "

<centre> <strong>vpacman.tcl</strong>

Version $version	

A graphical front end for pacman and the AUR

This programme is free software. It is distributed under the terms of the GNU General Public Licence version 3 or any later version.

\"https://www.gnu.org/licenses/gpl.html\"

You may copy it, modify it, and/or redistribute it. 

This programme comes with NO WARRANTY whatsoever, under any circumstances.

vpacman should be installed in /usr/bin and /usr/share/vpacman</centre>"

# set a dummy for the after id
set after_id ""
# anchor variable used for the alternative treeview bindings
set anchor ""
# do we want to include all the installed local packages in the aur_updates list
set aur_all false
# which files are owned by the local packages
set aur_files ""
# list any aur dependencies which need to be installed before an AUR/local package
set aur_installs ""
# list of packages available from the AUR
set aur_list ""
# do we show the warning messages in get_aur_updates or not
set aur_messages "true"
# if only aur packages are listed then set aur_only to true
set aur_only false
# these are the aur packages which could be updated
set aur_updates ""
# the versions found for the aur packages by the thread get_aur_versions
set aur_versions ""
# set the location of the backup file lists, the latest selected backup directory will be saved in the configuration file
set backup_dir $home
# keep a backup copy of the pacman log
set backup_log "yes"
# default browser
set browser ""
# toolbar button size
set buttons "medium"
# set an id for the clock update after delay
set clock_id 0
# list of all the known colours
set colours "{alice blue} {AliceBlue} {antique white} {AntiqueWhite} {AntiqueWhite1} {AntiqueWhite2} {AntiqueWhite3} {AntiqueWhite4} {aquamarine} {aquamarine1} {aquamarine2} {aquamarine3} {aquamarine4} {azure} {azure1} {azure2} {azure3} {azure4} {beige} {bisque} {bisque1} {bisque2} {bisque3} {bisque4} {black} {blanched almond} {BlanchedAlmond} {blue} {blue violet} {blue1} {blue2} {blue3} {blue4} {BlueViolet} {brown} {brown1} {brown2} {brown3} {brown4} {burlywood} {burlywood1} {burlywood2} {burlywood3} {burlywood4} {cadet blue} {CadetBlue} {CadetBlue1} {CadetBlue2} {CadetBlue3} {CadetBlue4} {chartreuse} {chartreuse1} {chartreuse2} {chartreuse3} {chartreuse4} {chocolate} {chocolate1} {chocolate2} {chocolate3} {chocolate4} {coral} {coral1} {coral2} {coral3} {coral4} {cornflower blue} {CornflowerBlue} {cornsilk} {cornsilk1} {cornsilk2} {cornsilk3} {cornsilk4} {cyan} {cyan1} {cyan2} {cyan3} {cyan4} {dark blue} {dark cyan} {dark goldenrod} {dark gray} {dark green} {dark grey} {dark khaki} {dark magenta} {dark olive green} {dark orange} {dark orchid} {dark red} {dark salmon} {dark sea green} {dark slate blue} {dark slate gray} {dark slate grey} {dark turquoise} {dark violet} {DarkBlue} {DarkCyan} {DarkGoldenrod} {DarkGoldenrod1} {DarkGoldenrod2} {DarkGoldenrod3} {DarkGoldenrod4} {DarkGray} {DarkGreen} {DarkGrey} {DarkKhaki} {DarkMagenta} {DarkOliveGreen} {DarkOliveGreen1} {DarkOliveGreen2} {DarkOliveGreen3} {DarkOliveGreen4} {DarkOrange} {DarkOrange1} {DarkOrange2} {DarkOrange3} {DarkOrange4} {DarkOrchid} {DarkOrchid1} {DarkOrchid2} {DarkOrchid3} {DarkOrchid4} {DarkRed} {DarkSalmon} {DarkSeaGreen} {DarkSeaGreen1} {DarkSeaGreen2} {DarkSeaGreen3} {DarkSeaGreen4} {DarkSlateBlue} {DarkSlateGray} {DarkSlateGray1} {DarkSlateGray2} {DarkSlateGray3} {DarkSlateGray4} {DarkSlateGrey} {DarkTurquoise} {DarkViolet} {deep pink} {deep sky blue} {DeepPink} {DeepPink1} {DeepPink2} {DeepPink3} {DeepPink4} {DeepSkyBlue} {DeepSkyBlue1} {DeepSkyBlue2} {DeepSkyBlue3} {DeepSkyBlue4} {dim gray} {dim grey} {DimGray} {DimGrey} {dodger blue} {DodgerBlue} {DodgerBlue1} {DodgerBlue2} {DodgerBlue3} {DodgerBlue4} {firebrick} {firebrick1} {firebrick2} {firebrick3} {firebrick4} {floral white} {FloralWhite} {forest green} {ForestGreen} {gainsboro} {ghost white} {GhostWhite} {gold} {gold1} {gold2} {gold3} {gold4} {goldenrod} {goldenrod1} {goldenrod2} {goldenrod3} {goldenrod4} {gray} {gray0} {gray1} {gray2} {gray3} {gray4} {gray5} {gray6} {gray7} {gray8} {gray9} {gray10} {gray11} {gray12} {gray13} {gray14} {gray15} {gray16} {gray17} {gray18} {gray19} {gray20} {gray21} {gray22} {gray23} {gray24} {gray25} {gray26} {gray27} {gray28} {gray29} {gray30} {gray31} {gray32} {gray33} {gray34} {gray35} {gray36} {gray37} {gray38} {gray39} {gray40} {gray41} {gray42} {gray43} {gray44} {gray45} {gray46} {gray47} {gray48} {gray49} {gray50} {gray51} {gray52} {gray53} {gray54} {gray55} {gray56} {gray57} {gray58} {gray59} {gray60} {gray61} {gray62} {gray63} {gray64} {gray65} {gray66} {gray67} {gray68} {gray69} {gray70} {gray71} {gray72} {gray73} {gray74} {gray75} {gray76} {gray77} {gray78} {gray79} {gray80} {gray81} {gray82} {gray83} {gray84} {gray85} {gray86} {gray87} {gray88} {gray89} {gray90} {gray91} {gray92} {gray93} {gray94} {gray95} {gray96} {gray97} {gray98} {gray99} {gray100} {green} {green yellow} {green1} {green2} {green3} {green4} {GreenYellow} {grey} {grey0} {grey1} {grey2} {grey3} {grey4} {grey5} {grey6} {grey7} {grey8} {grey9} {grey10} {grey11} {grey12} {grey13} {grey14} {grey15} {grey16} {grey17} {grey18} {grey19} {grey20} {grey21} {grey22} {grey23} {grey24} {grey25} {grey26} {grey27} {grey28} {grey29} {grey30} {grey31} {grey32} {grey33} {grey34} {grey35} {grey36} {grey37} {grey38} {grey39} {grey40} {grey41} {grey42} {grey43} {grey44} {grey45} {grey46} {grey47} {grey48} {grey49} {grey50} {grey51} {grey52} {grey53} {grey54} {grey55} {grey56} {grey57} {grey58} {grey59} {grey60} {grey61} {grey62} {grey63} {grey64} {grey65} {grey66} {grey67} {grey68} {grey69} {grey70} {grey71} {grey72} {grey73} {grey74} {grey75} {grey76} {grey77} {grey78} {grey79} {grey80} {grey81} {grey82} {grey83} {grey84} {grey85} {grey86} {grey87} {grey88} {grey89} {grey90} {grey91} {grey92} {grey93} {grey94} {grey95} {grey96} {grey97} {grey98} {grey99} {grey100} {honeydew} {honeydew1} {honeydew2} {honeydew3} {honeydew4} {hot pink} {HotPink} {HotPink1} {HotPink2} {HotPink3} {HotPink4} {indian red} {IndianRed} {IndianRed1} {IndianRed2} {IndianRed3} {IndianRed4} {ivory} {ivory1} {ivory2} {ivory3} {ivory4} {khaki} {khaki1} {khaki2} {khaki3} {khaki4} {lavender} {lavender blush} {LavenderBlush} {LavenderBlush1} {LavenderBlush2} {LavenderBlush3} {LavenderBlush4} {lawn green} {LawnGreen} {lemon chiffon} {LemonChiffon} {LemonChiffon1} {LemonChiffon2} {LemonChiffon3} {LemonChiffon4} {light blue} {light coral} {light cyan} {light goldenrod} {light goldenrod yellow} {light gray} {light green} {light grey} {light pink} {light salmon} {light sea green} {light sky blue} {light slate blue} {light slate gray} {light slate grey} {light steel blue} {light yellow} {LightBlue} {LightBlue1} {LightBlue2} {LightBlue3} {LightBlue4} {LightCoral} {LightCyan} {LightCyan1} {LightCyan2} {LightCyan3} {LightCyan4} {LightGoldenrod} {LightGoldenrod1} {LightGoldenrod2} {LightGoldenrod3} {LightGoldenrod4} {LightGoldenrodYellow} {LightGray} {LightGreen} {LightGrey} {LightPink} {LightPink1} {LightPink2} {LightPink3} {LightPink4} {LightSalmon} {LightSalmon1} {LightSalmon2} {LightSalmon3} {LightSalmon4} {LightSeaGreen} {LightSkyBlue} {LightSkyBlue1} {LightSkyBlue2} {LightSkyBlue3} {LightSkyBlue4} {LightSlateBlue} {LightSlateGray} {LightSlateGrey} {LightSteelBlue} {LightSteelBlue1} {LightSteelBlue2} {LightSteelBlue3} {LightSteelBlue4} {LightYellow} {LightYellow1} {LightYellow2} {LightYellow3} {LightYellow4} {lime green} {LimeGreen} {linen} {magenta} {magenta1} {magenta2} {magenta3} {magenta4} {maroon} {maroon1} {maroon2} {maroon3} {maroon4} {medium aquamarine} {medium blue} {medium orchid} {medium purple} {medium sea green} {medium slate blue} {medium spring green} {medium turquoise} {medium violet red} {MediumAquamarine} {MediumBlue} {MediumOrchid} {MediumOrchid1} {MediumOrchid2} {MediumOrchid3} {MediumOrchid4} {MediumPurple} {MediumPurple1} {MediumPurple2} {MediumPurple3} {MediumPurple4} {MediumSeaGreen} {MediumSlateBlue} {MediumSpringGreen} {MediumTurquoise} {MediumVioletRed} {midnight blue} {MidnightBlue} {mint cream} {MintCream} {misty rose} {MistyRose} {MistyRose1} {MistyRose2} {MistyRose3} {MistyRose4} {moccasin} {navajo white} {NavajoWhite} {NavajoWhite1} {NavajoWhite2} {NavajoWhite3} {NavajoWhite4} {navy} {navy blue} {NavyBlue} {old lace} {OldLace} {olive drab} {OliveDrab} {OliveDrab1} {OliveDrab2} {OliveDrab3} {OliveDrab4} {orange} {orange red} {orange1} {orange2} {orange3} {orange4} {OrangeRed} {OrangeRed1} {OrangeRed2} {OrangeRed3} {OrangeRed4} {orchid} {orchid1} {orchid2} {orchid3} {orchid4} {pale goldenrod} {pale green} {pale turquoise} {pale violet red} {PaleGoldenrod} {PaleGreen} {PaleGreen1} {PaleGreen2} {PaleGreen3} {PaleGreen4} {PaleTurquoise} {PaleTurquoise1} {PaleTurquoise2} {PaleTurquoise3} {PaleTurquoise4} {PaleVioletRed} {PaleVioletRed1} {PaleVioletRed2} {PaleVioletRed3} {PaleVioletRed4} {papaya whip} {PapayaWhip} {peach puff} {PeachPuff} {PeachPuff1} {PeachPuff2} {PeachPuff3} {PeachPuff4} {peru} {pink} {pink1} {pink2} {pink3} {pink4} {plum} {plum1} {plum2} {plum3} {plum4} {powder blue} {PowderBlue} {purple} {purple1} {purple2} {purple3} {purple4} {red} {red1} {red2} {red3} {red4} {rosy brown} {RosyBrown} {RosyBrown1} {RosyBrown2} {RosyBrown3} {RosyBrown4} {royal blue} {RoyalBlue} {RoyalBlue1} {RoyalBlue2} {RoyalBlue3} {RoyalBlue4} {saddle brown} {SaddleBrown} {salmon} {salmon1} {salmon2} {salmon3} {salmon4} {sandy brown} {SandyBrown} {sea green} {SeaGreen} {SeaGreen1} {SeaGreen2} {SeaGreen3} {SeaGreen4} {seashell} {seashell1} {seashell2} {seashell3} {seashell4} {sienna} {sienna1} {sienna2} {sienna3} {sienna4} {sky blue} {SkyBlue} {SkyBlue1} {SkyBlue2} {SkyBlue3} {SkyBlue4} {slate blue} {slate gray} {slate grey} {SlateBlue} {SlateBlue1} {SlateBlue2} {SlateBlue3} {SlateBlue4} {SlateGray} {SlateGray1} {SlateGray2} {SlateGray3} {SlateGray4} {SlateGrey} {snow} {snow1} {snow2} {snow3} {snow4} {spring green} {SpringGreen} {SpringGreen1} {SpringGreen2} {SpringGreen3} {SpringGreen4} {steel blue} {SteelBlue} {SteelBlue1} {SteelBlue2} {SteelBlue3} {SteelBlue4} {tan} {tan1} {tan2} {tan3} {tan4} {thistle} {thistle1} {thistle2} {thistle3} {thistle4} {tomato} {tomato1} {tomato2} {tomato3} {tomato4} {turquoise} {turquoise1} {turquoise2} {turquoise3} {turquoise4} {violet} {violet red} {VioletRed} {VioletRed1} {VioletRed2} {VioletRed3} {VioletRed4} {wheat} {wheat1} {wheat2} {wheat3} {wheat4} {white} {white smoke} {WhiteSmoke} {yellow} {yellow green} {yellow1} {yellow2} {yellow3} {yellow4} {YellowGreen}"
# set the location and name of the configuration file
set config_file "$home/.vpacman.config"
# various variables to hold the number of items found in the lists
set count_all 0
set count_installed 0
set count_outdated 0
set count_uninstalled 0
# array of balloon help variables
# bubble()
# the package name and dataview tab currently shown in the dataview window
set dataview ""
# the path to the pacman sync databases
set dbpath "/var/lib/pacman"
# set debug mode
# launch vpacman with no arguments to direct debug to stdout, use '-d' or --'debug' to direct debug to a file in the home directory, use -dd to increase the debug level
set debug_out(1) "stdout"
# throw away excess dubug messages
set debug_out(2) [open "/dev/null" w]
set debug_out(3) $debug_out(2)
# restart with the correct debug level
# if we started in debug mode
if {$debug != ""} {
	# if we restarted then append the debug messages to the debug file
	# otherwise start a new debug file
	if {[string first "--restart" $args] != -1} {
		# re-open the debug files
		if {$debug == "high"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" a]
			set debug_out(2) $debug_out(1)
			set debug_out(3) $debug_out(1)
		} elseif {$debug == "medium"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" a]
			set debug_out(2) $debug_out(1)
		} elseif {$debug == "low"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" a]
		}
		puts $debug_out(1) "Restart called with debug $debug"
	} else {
		# remove any existing debug file
		file delete ${home}/vpacman_debug.txt
		# and start a new one
		if {$debug == "high"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" w]
			set debug_out(2) $debug_out(1)
			set debug_out(3) $debug_out(1)
		} elseif {$debug == "medium"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" w]
			set debug_out(2) $debug_out(1)
		} elseif {$debug == "low"} {
			set debug_out(1) [open "$home/vpacman_debug.txt" w]
		}
	}
}
if {$debug != ""} {
	puts $debug_out(1) "Running vpacman with debug set to $debug and debug messages saved to $home/vpacman_debug.txt"
} else {
	puts $debug_out(1) "Running vpacman with debug set to low and debug messages sent to stdout"
}
# a list of all the packages which have been searched for their dependencies
set depends_searches ""
# the programme to use to compare files
set diffprog ""
# the programme to use for downloads
set dlprog ""
# default editor
set editor ""
# the filter selected in the checkboxes
set filter "all"
# the list to use to filter
set filter_list ""
# the search string selected in the find field
set find ""
# the search string selected in the find file field
set findfile ""
# the search type selected in the find field
set findtype "find"
# this is the message for the number of items found
set find_message ""
# are we in the process of a full system upgrade
set fs_upgrade false
# set the options window to a fixed size
set geometry_config "487x256"
# the group selected in the combobox
set group "All"
# the index number of the selected group in the group list box
set group_index 0
# the help text
set help_text "
This simple programme allows you to View the packages available in those pacman repositories which have been enabled in the pacman configuration file (/etc/pacman.conf) and to Install, Upgrade and Delete those packages. It also includes packages which have been installed from other sources - either from AUR or locally.

The only dependencies are Pacman, TCL, TK, a terminal and Wmctrl. Pacman is always used to install, update, delete and synchronize the pacman packages and database. Therefore the entries in the pacman configuration file will always be respected.

Note: Wmctrl relies on the window title set for the terminal. In order to use konsole the profile must be set to use the window title set by the shell.

Optional dependencies are a browser, an editor, Pacman-contrib, Pkgfile, Xwininfo.

<strong>Usage:</strong>

The main window consists of a menu bar, a toolbar, a set of filter and list options, a window showing a list of packages, and a window, below that, which shows details of a selected package.

<strong>Menu Bar:</strong>
	File:	<lm3>Quit</lm3>
	Edit:	<lm3>Select All > Select all the packages displayed.</lm3>
			<lm3>Clear All > De-select all the selected packages.</lm3>
	Tools:	<lm3>Full System Upgrade > The only supported method of updating outdated packages. It may be wise to check the latest news (View > Latest News) before performing a full system upgrade.</lm3>
			<lm3>Install > Ask pacman to install or reinstall the selected packages. Partial upgrades are not supported. Note that AUR packages (local) can only be updated one at a time through AUR/Local Updates.</lm3>
			<lm3>Delete > Ask pacman to delete the selected packages.</lm3>
			<lm3>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been made then the elapsed time shows the time since Vpacman was started.</lm3>
			<lm3>Check Config Files > Display a list of any configuration file which need to be dealt with (see \"https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave\"). If a Compare Files programme has been set in Options, then offers to update any configuration files found.</lm3>
			<lm3>Clean Package Cache > Delete any superfluous packages from the pacman cache to release disk space. The default is to keep at least the most recent three versions of each package. Cleaning can optionally be restricted to uninstalled packages. (Requires paccache)</lm3>
			<lm3>Clean Pacman Log > Reduce the size of the pacman log by deleting old entries to release disk space. The default is to keep at least the most recent twelve monthss. Cleaning will always keep the entries for today. Optionally keep a backup copy of the old log file.</lm3>
			<lm3>Install AUR/Local > Install an AUR package by name, or a local package file. Optionally browse for a local file to install. Use the \"Info\" button to search the list of AUR packages for packages that start with the package name and to view information about an AUR package. Use the \"Install\" button to install the package. Vpacman will attempt to recursively install any AUR dependencies, pacman will install any dependencies available from the repositories.</lm3>
			<lm3>Make Backup Lists > Save backup lists of the various packages installed, and a copy of the pacman configuration file, to a chosen directory.</lm3>
			<lm3>Update Cups > Run cups_genppdupdate if necessary and restart cups. Use if gutenprint has been updated.</lm3> 
			<lm3>Update Mirrorlist > Update the pacman mirrorlist optionally selecting servers for specific countries and excluding any servers where the current status is known to be \"Poor\" and/or \"Bad\".</lm3> 
			<lm3>Options > Change any of the configurable options for Vpacman. Allows for editing the configuration file manually, which could break Vpacman! In case of problems delete the configuration file \"~/.vpacman.config\" to return all the values to default.</lm3>
	View:	<lm3>Latest News > Read the last year of news from archlinux.org</lm3> 
			<lm3>Pacman Configuration > View the the pacman configuration file.</lm3> 
			<lm3>Recent Pacman Log > View the pacman log file.</lm3> 
			<lm3>Dependency Updates > View a report of the dependencies which will be updated in the next Full System Upgrade.</lm3> 
			<lm3>Hide Menubar > Hide the menu bar. Can be shown again using the right click menu in the Packages Window - see below.</lm3> 
			<lm3>Hide/Show Toolbar > Hide or show the tool bar</lm3> 
	Help:	<lm3>Help > This help message.</lm3>
			<lm3>About > Information about this programme.</lm3>
			
<strong>Tool Bar:</strong>
	<lm2>Full System Update > The only supported method of updating outdated packages. It may be wise to check the latest news before performing a full system upgrade.</lm2>
	<lm2>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been made then the elapsed time shows the time since Vpacman was started.</lm2>
	<lm2>Install > Ask pacman to install or update the selected packages. Note that AUR packages (local) can only be updated one at a time through AUR/Local Updates.</lm2>
	<lm2>Delete > Ask pacman to delete the selected packages.</lm2>
	<lm2>Find > Enter any string to search for in the list of packages displayed. The search will be carried out over all the fields of the packages listed, including the description but excluding the repository name. Click on the label \"Find\" to change to a search the package names only, click again to search for the packages providing a specified file. Enter the full name of the file to search for, and press return to start the search. On the first search during any day, if necessary, a prompt will ask if the file database should be updated. Click on the label again to return to the \"Find\" option.</lm2>
	<lm2>Options > Change any of the configurable options for Vpacman. Allows for editing the configuration file manually, which could break Vpacman! In case of any problems delete the configuration file \"$ rm ~/.vpacman.config\" to return all the values to sane defaults.</lm2>		

<strong>Filters:</strong>
	<lm2>All > Check to show all the available packages including the installed AUR or local packages.</lm2>
	<lm2>Group > Filter the selection to only show the packages included in the selected group.</lm2>
	<lm2>To aid in navigating the list there is a scroll bar at the right edge of the drop down window. Since the groups list displayed is rather long a Right-Click on the scroll bar at any point will align the list to that point. Right-Click on the top arrow will display the top of the list, Right-Click on the bottom arrow will display the end of the list.</lm2>
	<lm2>Installed > Check to show only those packages which have been installed. Includes installed AUR and local packages.</lm2>
	<lm2>Not Installed > Check to show only those packages which have not been installed.</lm2>
	<lm2>Updates Available > Check to show those packages where an update is available. Use Full System Upgrade as the preferred update method.</lm2>
	
	<lm2>Tip: If the filter shows unexpected results make sure that you have Groups set to \"All\" and that the Find entry is clear.</lm2>
	
<strong>List:</strong>
	<lm2>Orphans > Check to ask pacman to list any packages which are no longer required as a dependency of another package.</lm2>
	<lm2>Not Required > Check to ask pacman to list any packages not required by any other package.</lm2>
	<lm2>AUR/Local Updates > Check to list any AUR packages which may need updating. This relies heavily on correct package version data in the AUR database, so may not be wholly accurate.</lm2>
		<lm3>include all packages > Check to include all local packages in the AUR/Local Updates list.</lm3>
	
<strong>Packages Window:</strong>
	<lm2>Shows the result of the Filter or List selection. The results will also respect any Group selected and any Find entry.</lm2>
	
	<lm2>Tip: If the filter shows unexpected results make sure that you have Groups set to \"All\" and that the Find entry is clear.</lm2>
	
	<lm2>Left-Click on any line to select that line. Left-Click a second time to de-select the line. Shift-click to select a range of lines, Control-click to add to a selection. Note that AUR/Local Updates packages may only be selected one at a time.</lm2>
	<lm2>Right-Click to bring up a menu similar to the tools menu above. If there is a single package selected then an option will be available to Mark that package as Explicitly Installed, As a Dependancy or Ignored (or not). If the menu bar has been hidden then the last item on the list will offer to show the menu bar again.</lm2>
	<lm2>Left-Click on a heading to sort the package list by that heading. Left-Click a second time to sort the list in reverse order.</lm2>
	<lm2>To aid in navigating the list there is a scroll bar at the right edge of the window. Since some of the lists displayed can be rather long a Right-Click on the scroll bar at any point will align the list to that point. Right-Click on the top arrow will display the top of the list, Right-Click on the bottom arrow will display the end of the list.</lm2>

<strong>Details Window:</strong>
	<lm2>Shows the requested information, according to the tab activated, about the latest package selected in the Packages Window.</lm2>
	
	<lm2>Retrieval of some information may be slow, in which case a \"Searching\" message will be shown.</lm2>
	<lm2>If an error is returned then an appropriate message may be displayed.</lm2>"

# do we have an internet connection
set is_connected true
# list of known browsers
set known_browsers [list chromium dillo epiphany falkon firefox opera qupzilla]
# list of know compare programmes
set known_diffprogs "diffuse kompare kdiff3 meld  vimdiff"
# list of known_editors
set known_editors [list emacs nano vi vim]
# list of known terminals
set known_terminals [list {gnome-terminal} {--title <title> -- <command>} {konsole} {--title <title> -e <command>} {lxterminal} {--title <title> -e <command>} {mate-terminal} {--title <title> -e <command>} {qterminal} {--title <title> --execute <command>} {roxterm} {--title <title> -e <command>} {vte} {--name <title> --command <command>} {xfce4-terminal} {--title <title> -e <command>} {xterm} {-title <title> -e <command>}]
# the list of all the packages in the database, including locally installed packages in the form
# Repo Package Version Available Group(s) Description
set list_all ""
# the list of all the groups in the database in the form
# Group
set list_groups ""
# the list of all the installed packages, excluding locally installed packages in the form
# Repo Package Version Available Group(s) Description
set list_installed ""
# the list of locally installed packages in the form
# Repo(local) Package Version Available('-na-' while no known version available) Group('none') Description
set list_local ""
# the list of local packages with their list_all index and their list_show ids in the form
# name, list_all id, list_show index, treeview id
set list_local_ids ""
# the list ofpackages which can be updated
set list_outdated ""
# the list of repositories which have been included in the last sync
set list_repos ""
# the list of the packages on show in the treeview .wp.wfone.listview in the form
# Repo Package Version Available Group(s) Description
set list_show ""
# the same list but in the form
#id
set list_show_ids ""
# the order that the list_show is sorted into
set list_show_order "Package increasing"
# the list of packages which have not been installed in the form
# Repo Package Version Available Group(s) Description
set list_uninstalled ""
# the first item selected - used for the alternative treeview bindings
set listfirst ""
# the last item selected - used for the alternative treeview bindings
set listlast ""
# the last packages selected in listview, used to avoid continuously running the treeview selected binding, in the form
# id
set listview_last_selected ""
# the packages selected in listview, used to show the dataview information requested, in the form
# id
set listview_current ""
# the list of all the currently selected items in listview in the form
# id
set listview_selected ""
# the list of all the currently selected items in listview, in the order selected, in the form
# id
set listview_selected_in_order ""
# the number of newer AUR/Local packages identified to be upgraded
set local_newer 0
# an index
set index 0
# message to be shown in the button bar near the top of the window
set message ""
# a comma separated list of countries to use to compile a mirrorlist
set mirror_countries ""
# show message one_time
set one_time "true"
# list of updated packages which may require further actions
set package_actions [list "linux" "Linux was updated, consider rebooting" "gutenprint" "Gutenprint was installed or updated, consider running Tools > Update cups" ".pacnew" "A .pacnew file was installed, run Tools > Check Config Files to view and deal with the files" ".pacsave" "A .pacsave file was saved, run Tools > Check Config Files to view and deal with the files "]
# is it ok to skip a pacman files database upgrade - 0 no, 1 skip database upgrade, 2 skip database install.
set pacman_files_upgrade 0
# is it ok to skip a ppkgfile database upgrade - 0 no, 1 skip database upgrade, 2 skip database install.
set pkgfile_upgrade 0
# is it ok to run a partial upgrade- 0 no, 1 yes.
set part_upgrade 0
# have we agreed to select all the packages 
set repo_delete_msg true
# show a warning message if we have selected a mix of local and repository packages and therefore can only delete the repo packages
set select false
# variable to select one of the list options in the Filter frame
set selected_list 0
# this is the message for the number of items selected 
set selected_message ""
# show the menu bar yes or no
set show_menu "yes"
# show the toolbar yes or no
set show_buttonbar "yes"
# set start_time
set start_time [clock milliseconds]
# the state of any package(s) selected: install, delete or blank(none)
set state ""
# set the default su command
set su_cmd "su -c"
# the time of the last sync in clock seconds
set sync_time 0
# the system data (sync)
set system ""
# the result of the last test system
set system_test "stable"
# default terminal
set terminal ""
# is there a conflicting thread running
set thread ""
# threads: is tcl threaded, true or false
# a list of times returned by get_sync_times - sync_time and update_time
set times ""
# the first treeview item id displayed
set tv_index ""
# the result from the treeview selection binding
set tv_select ""
# the treeview message to display of any errors have been found
set tverr_message ""
# A list of any potential errors found in the treeview selection in the format Index Message
set tverr_text ""
# the time of the last full system update
set update_time ""
# a list of any packages selected which are set to upgrade
set upgrades ""
# the number of packages selected which are set to upgrade
set upgrades_count 0
# Various geometry settings for windows
set win_configx 0
set win_configy 0
set win_mainx 0
set win_mainy 0

# ELEVATED PRIVILEGES

# Check if we have been run as root or with root privileges
if {[exec id -u] eq 0 } {
	set su_cmd ""
# if not root then do we have sudo privileges without a password
} else {
	# remove any saved credentials
	exec sudo -k
	# and test if a passsword is required
	set error [catch {exec sudo -n true}]
	if {$error == 0} {
		set su_cmd "sudo -n"
		# the -n option is only needed to distinguish the su_cmd from the next one!
	} else {
		# or perhaps we can use sudo but still need a password
		# sudo -v will either ask for a password or return
		# immediately with a "may not run sudo" message.
		# so try it
		# if vpacman was run from a terminal the password request will still be on the screen!
		# so remove the prompt with -p ""
		set error [catch {exec sudo -S -v -p "" < /dev/null} error_message]
		# what was the result?
		# if the result includes the user name then it will be a "Sorry ..." result
		# otherwise it will include sudo: as in "sudo: no password...."
		# both will be error 1
		if {[string first "$env(USER)" $error_message] == -1} {set su_cmd "sudo"}
		# otherwise just use the default
	}
}
puts $debug_out(1) "Test complete - su command is $su_cmd ([expr [clock milliseconds] - $start_time])"
# only certain commands will need elevated privileges. Since we are running all commands in a terminal session 
# we can ask for a password in that session if necessary
# so there really is no need to use a graphical su command.

puts $debug_out(1) "Version $version: User is $env(USER) - Home is $home - Config file is $config_file - Programme Directory is $program_dir - Su command is set to $su_cmd"

# PROCEDURES

# proc all_clear
# 	Clear all of the items shown in the treeview widget
# proc all_select
# 	Select all of the items shown in the treeview widget
# proc aur_install
#	Install an AUR/Local package
# proc aur_install_depends
# 	Install each for the aur dependencies listed
# proc aur_upgrade
# 	Upgrade a given AUR package
## The following procedures create help messages invoked when the cursor hovers over a widget.
# proc balloon {target message {cx 0} {cy 0} } 
# proc balloon_set {target message}
# proc balloon_unset
##
# proc check_config_files
#	Check for any existing configurations files that have not been dealt with
# proc check_repo_files
#	Check that the database files exist for each repository in the pacman configuration file and return the list of repositories
# proc clean_cache
# 	Clean unnecessary files from the pacman cache
# proc cleanup_checkbuttons {aur} 
#	After a filter checkbutton is selected return the necessary variables to sane settings, 
#		set aur_only to the value requested. Reset the list checkbutton titles. 
# proc clock_format
# 	format a time according to the format requested
# proc configurable
# 	Set configurable variables to sane values
# proc configurable_default
# 	Initialize a configurable variable to the first item in the known variables list which is installed
# proc configure
#	Display a new window to allow the configurable variables to be changed. 
#		Also allows the configuration file to be edited using the selected editor.
# proc count_lists
#	Count the number of items in the lists found by the list_ procedures, inlcude list_licalcount in list_installed
# proc execute {type} 
#	Execute a command in the specified terminal depending on the type of action passed to the procedure (Install, Remove  or Sync)
# proc execute_command {action command wait}
#	Execute a command depending on the action required, and wait for a response if requested 
# proc execute_terminal_isclosed
#	Wait for the terminal to close
# proc execute_terminal_isopen
# 	Wait for  a terminal to open
# proc filter
#	Select the required programmes depending on the active filter checkbutton, the selected group and the search (find) entry 
# proc filter_checkbutton {button command title} 
#	Procedure to run after a list checkbutton has been activated. Set the required parameters dependant on the button 
#		and call list_special with the command specified. Finally reset the list checkbutton title to the specified title.
# proc find {find list type} 
#	Find all the items in the displayed list which contain the find string. For type all - Search all the fields,
#		including those not displayed, except for the Repo field, for type name - search the name field only.
# proc find_pacman_config
#	Find pacman configuration data
# proc get_aur_dependencies {package}
#	Find the dependencies required for a specified AUR package
# proc get_aur_info {package}
# 	Get various information about a named package. Returns the description, version, URL, the date last updated, the dependencies:
#		depends, checkdepends, makedepends, optdepends and any keywords.
# proc get_aur_list
#	Get a list of the names of the available aur packages
# proc get_aur_matches
#	Find any matches for a name n the aur list
# proc get_aur_name
#	Get the package name required from a list of matches
# proc get_aur_updates
#	Find local files which may need to be updated or may not be found amongst the AUR packages
# proc get_aur_versions 
#	Procedure to find the current available aur version and description for all the list_local packages.
# proc get_configs
#	Read the configuration variables from the configuration file (
# proc get_dataview {current}
#	Get the information required, depending on the active tab in the dataview notebook. Since some of the details
#		can take a while to retrieve, show a searching message where necessary.
# proc get_file_mtime
# 	Get the  last modified time for a set of files
# proc get_mirrorlist
#	Get the latest mirrorlist
# proc get_password
#	Get a password whenever needed.
# proc get_sync_time
#	Get the last sync time, the list of repositories and check that the temporary database is up to date.
# proc get_system_data
# 	Get the system data (sync)
# proc get_terminal
#	If no terminal is configured or found in the known_terminals list, try to get a valid terminal and terminal_string
# proc get_terminal_string {terminal}
#	get the terminal_string for a given terminal from the known_terminals list
# proc get_win_geometry
#	Get the geometry of the windows
# proc grid_remove_listgroups
# 	Remove the listgroups widget
# proc grid_set_listgroups
# 	Show the listgroups widget
## All list are in the format: Repo Package Version Available Group(s) Description
# proc list_all
# 	Make a list of all the available programmes in the database
# proc list_local
#	Make a list of the locally installed programmes including AUR programmes	
# proc list_groups
#	Make a list of all the available groups
# proc list_special {execute_string} 
#	Make a list based on a specific comamnd, the execute string. Run the command a create the list.
# proc list_show {list} 
# 	Display the list, passed to the procedure, in the treeview widget.
# proc make_backup_lists
# 	Make list of all the installed pacakges suitable for restoring after a reinstall
# proc mirrorlist_countries
#	Select the required countries from a list of countries included in the mirrorlist
# proc mirrorlist_filter
#	Filter and rank the given mirrorlist file, .pacnew or .backup, by the selected countries, the status of the mirrors and/or the number of servers required.
# proc mirrorlist_update
# 	Offer to update the mirrorlist, .pacnew if it exists otherwise .backup,  by the selecting countries, the mirror status and/or the number of servers required. 
# proc place_warning_icon
#	Place a warning icon in the .filetr_icons frame
# proc put_aur_files
#	called by thread aur_files to get the file lists for AUR/Local files for a file name search
# proc put_aur_versions
#	called by thread aur_versions to get the available versions and descriptions of AUR/Local files and update the lists and treeview
# proc put_configs
#	Write the configuration variables to the configuration file
# proc put_list_groups
#	called by thread list_groups to get the list of groups available
# proc read_about
#	Display the about text
# proc read_aur_info
#	Read the information from downloaded AUR package details
# proc read_config
#	Read the pacman configuration file and display it. 
# proc read_dependencies (params)
#	Check package upgrades available for changes in dependencies, and make a report if requested
# proc read_dependencies_extra 
#	Check for any extra packages required by added dependencies on an upgrade
# proc read_dependencies_provides 
#	Check for any dependencies that are provided by another package and which are required by added dependencies on an upgrade
# proc read_help
# 	Display the help text
# proc read_log
#	Find the pacman log file and display it.
# proc read_news
#	Try to downlaod and parse the arch news rss, and display it. If not possible then browse to the web page
# proc remove_warning_icon
#	Remove a warning icon and reposition any remaining icons
# proc set_clock
#	Calculate the elapsed time since the last significant event, the e-time, which is set at the start of the programme, 
#		or the last sync event. Displays and updates the elapsed time at the foot of the window.
# proc set_images
#	Set up the images for use in the toolbar and other widgets
# proc set_message {type text}
#	Displays a message in the message area at the top of the window. The type influences whether the message 
#		is appended to, resets or replaces a previous message
# proc set_wmdel_protocol {type} 
# 	Set the main window exit code, depending on the type, exit or noexit, requested
# proc sort_list 
#	Show the displayed list in the current order
# proc sort_list_toggle {heading} 
#	Toggle the order of whatever is shown in the treeview widget, in descending or ascending order, when a heading is clicked.
# proc start
#	On start up, or after a terminal command has been run to update all the base lists, all, installed, not installed and available updates.
# proc system_upgrade
#	Execute a full system upgrade
# proc test_aur_matches
#	Test a name against any matches found for various conditions
# proc test_configs
#	Test the current configuration options are sane, if not, reset to a default setting as necessary.
# proc test_files_data
#	Test the requested files databases exist and are up to date
# proc test_internet
#	Test, up to three times for an internet connection.
# proc test_resync
#	Test if a resync is required after a failed update or an external intervention
# proc test_system
#	called by thread test system to see if it appears to be in an unstable condition.
# proc test_versions {installed available}
#	test if the available version is newer or older than the installed version
# proc toggle_buttonbar
#	Toggle the menu entry to show or hide the buttonbar
# proc toggle_ignored
# 	Toggle an installed package as ignored/not ignored
# proc trim_log
# 	clean the pacman log keeping the last keep_log months and, optionally, a backup of the current log
# proc update_config_files {filelist} {
#	tools to update any config files found
# proc update_cups
# 	if gutenprint is installed run cups-genppdupdate to update ppds - restart cups
# proc update_db
#   copies the pacman sync database into the temporary directory
# proc view_text
#	open a window and display some text in it
# proc view_text_codes
#   read through some text and replace a set of codes with a given tag
# proc view_text_url
#	check for a selection before opening a URL in the browser

proc all_select {} {

global debug_out list_show list_show_ids select tv_select
# select all the items in listview

	puts $debug_out(1) "all_select called"

	if {[llength $list_show_ids] > 500 && $select == false} {
		set ans [tk_messageBox -default cancel -detail "" -icon warning -message "\nReally select [llength $list_show_ids] packages?" -parent . -title "Warning" -type okcancel]
		switch $ans {
			ok {set select true}
			cancel {
				set select false
				return 1
			}
		}
	}
	if {[llength $list_show] == 1 && [llength [.wp.wfone.listview selection]] == 1} {
		# one item is in the list and it is already selected
		puts $debug_out(2) "all_select - one item is already selected"
	} else {
		set tv_select ""
		puts $debug_out(2) "all_select - set selection to $list_show_ids"
		.wp.wfone.listview selection add $list_show_ids
		# bind TreeviewSelect will update all the variables when the selection changes
		vwait tv_select
	}
	puts $debug_out(1) "all_select completed"
	return 0
}

proc all_clear {} {
	
global debug_out listview_selected part_upgrade select tv_select
# clear all the items selected in listview

	puts $debug_out(1) "all_clear called"
	set select false
	set tv_select ""
	puts $debug_out(2) "all_clear - remove any treeview selection"
	catch {.wp.wfone.listview selection remove $listview_selected}
	# bind TreeviewSelect will update all the variables when the selection changes
	vwait tv_select
	puts $debug_out(2) "all_clear - treeview select completed"
	set part_upgrade 0
	puts $debug_out(1) "all_clear completed - partial upgrades set to no"
	return 0
}

proc aur_install {} {

global debug_out depends_searches home list_local win_mainx win_mainy

# open a window to ask for a AUR package name to install or browse for a local package
# if there are no other aur dependencies required, either to run, make or check, then install it
# otherwise pass control to aur_install_depends

	puts $debug_out(1) "aur_install called"
	
	set depends_searches ""
		
	toplevel .aurinstall
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {360 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {170 / 2}]
	wm geometry .aurinstall 360x175+$left+$down
	wm iconphoto .aurinstall tools
	wm protocol .aurinstall WM_DELETE_WINDOW {
		# assume cancel aur install, see button .aurinstall.cancel
		.aurinstall.cancel invoke
	}
	wm resizable .aurinstall 0 0
	wm title .aurinstall "Install AUR/Local Package"
	wm transient .aurinstall .

# CONFIGURE AUR INSTALL WINDOW

	label .aurinstall.packagename_label \
		-text "AUR Package Name"
	entry .aurinstall.packagename \
		-borderwidth 0 \
		-validate key \
		-validatecommand {
			if {"%S" == " "} {
				return 0
			}
			.aurinstall.package configure -text %P
			if {"%P" == "{}"} {
				.aurinstall.info configure -state disabled
			} else {
				.aurinstall.info configure -state normal
			}
			return 1
		}
		
	bind .aurinstall.packagename <Return> {.aurinstall.install invoke}
	
	label .aurinstall.filename
	.aurinstall.filename configure -text ""
	
	label .aurinstall.package
	.aurinstall.package configure -text ""
		
	button .aurinstall.info \
		-command {
			if {[.aurinstall.package cget -text] != ""} {
				set package [.aurinstall.package cget -text]
				# try to download an up-to-date packages list
				# the packages list is updated frequently so always get a new file if possible
				set result [get_aur_list]
				if {$result == 1} {
					puts $debug_out(2) "aur_install - cannot download new package list and there is no existing package available"
					set ans [tk_messageBox -default ok -detail "Could not download the AUR package list.\nNo previous AUR package list is available.\nCannot continue" -icon error -message "Failed to download AUR package list" -parent .aurinstall -title "Error" -type ok]
				} elseif {$result == 2} {
					puts $debug_out(2) "aur_install - cannot download new package list and do not use the package list available"
				} else {
					# now find matches in the list
					set matches [get_aur_matches $package]
					set result [test_aur_matches $package $matches]
					# now get the required package name from the list of matches found
					set aur_name [get_aur_name $package $matches]
					tkwait window .aurinstall.aurname
					puts $debug_out(2) "aur_install - returned aur_name: $aur_name"
					if {$aur_name == 3} {
						puts $debug_out(2) "aur_install - aur_name was cancelled"
						focus .aurinstall.packagename
					} else {
						.aurinstall.package configure -text $aur_name
						.aurinstall.filename configure -text ""
						.aurinstall.packagename delete 0 end
						.aurinstall.packagename insert 0 $aur_name
						.aurinstall.packagename icursor end
						focus .aurinstall.packagename
					}
					# now reset the grab on .aurinstall
					grab set .aurinstall
				}
			}
		} \
		-state disabled \
		-text "Info"
	
	label .aurinstall.browse_label \
		-text "or browse to a file to install"
	button .aurinstall.browse \
		-command {
			# the next code will call tk_getOpenFile 
			catch {tk_getOpenFile no file}
			# and arrange to hide the hidden files
			set ::tk::dialog::file::showHiddenVar 0
			# and display a button to show hidden files
			set ::tk::dialog::file::showHiddenBtn 1
			# now choose to display only the package files
			set types {
				 {{Packages}       {.pkg.tar.xz .pkg.tar.zst}        }
			}
			# and set a title for the window
			set title "Vpacman : Browse"
			# try to enlarge the window immediately after it opens
			after 100 {exec wmctrl -r $title -e 0,-1,-1,600,350}
			# now browse for a file
			set filename [tk_getOpenFile -filetypes $types -title $title]
			.aurinstall.filename configure -text $filename
			if {$filename != ""} {
				.aurinstall.package configure -text ""
				.aurinstall.packagename delete 0 end
				.aurinstall.packagename insert 0 [string range [file tail $filename] 0 [string first ".pkg." [file tail $filename]]-1] 
				.aurinstall.info configure -state disabled
			} 
		} \
		-text "Browse" \
		-width 8

	frame .aurinstall.buttons

		button .aurinstall.install \
			-command {
				if {[.aurinstall.filename cget -text] != ""} {
					set filename [.aurinstall.filename cget -text]
					puts $debug_out(1) "aur_install - install file \"$filename\""
					grab release .aurinstall
					destroy .aurinstall
					puts $debug_out(2) "aur_install - call aur_upgrade with file \"$filename\" and type \"install\""
					aur_upgrade $filename "install"
				} elseif {[.aurinstall.package cget -text] != ""} {
					# try to download an up-to-date packages list
					# the packages list is updated frequently so always get a new file if possible
					set result [get_aur_list]
					if {$result == 1} {
						puts $debug_out(2) "aur_install - cannot download new package list and there is no existing package available"
						set ans [tk_messageBox -default ok -detail "Could not download the AUR package list.\nNo previous AUR package list is available.\nCannot continue" -icon error -message "Failed to download AUR package list" -parent .aurinstall -title "Error" -type ok]
					} elseif {$result == 2} {
						puts $debug_out(2) "aur_install - cannot download new package list and do not use the package list available"
					} else {
						set package [.aurinstall.package cget -text]
						puts $debug_out(1) "aur_install - install package $package"
						# first get the dependencies for the named package
						puts $debug_out(2) "aur_install - call get_aur_dependencies for $package"
						set depends [get_aur_dependencies $package]
						if {$depends != "cancel"} {
							if {$depends == "none"} {
								puts $debug_out(2) "aur_install - get_aur_dependencies has already been called for $package"
								set aur_installs ""
							} else {
								# the following dependencies are required by $package
								puts $debug_out(2) "aur_install - get_aur_dependencies found:"
								puts $debug_out(2) "\tRequired: [lindex $depends 0]"
								puts $debug_out(2) "\tRepo installs needed: [lindex $depends 1]"
								puts $debug_out(2) "\tAUR installs needed: [lindex $depends 2]"
								puts $debug_out(2) "\tCheck Required: [lindex $depends 3]"
								puts $debug_out(2) "\tCheck Repo installs needed: [lindex $depends 4]"
								puts $debug_out(2) "\tCheck AUR installs needed: [lindex $depends 5]"
								puts $debug_out(2) "\tMake Required: [lindex $depends 6]"
								puts $debug_out(2) "\tMake Repo installs needed: [lindex $depends 7]"
								puts $debug_out(2) "\tMake AUR installs needed: [lindex $depends 8]"
								puts $debug_out(2) "aur_install - get_aur_dependencies returned package name [lindex $depends 9]"
								# set any aur dependencies to aur_installs
								set aur_installs [concat [lindex $depends 2] [lindex $depends 5] [lindex $depends 8]]
							}
							grab release .aurinstall
							destroy .aurinstall
	
							if {$aur_installs != ""} {
								# so there are some aur dependencies required. so pass the list back to aur_install_depends.
								puts $debug_out(2) "aur_install - install list is now set to $aur_installs"
								# first check that the AUR installs are correct, if the basename is different to the package name then use that instead
								set new_installs ""
								foreach item $aur_installs {
									puts $debug_out(3) "aur_install - test $item for against excludes list"
									# ignore certain listed dependencies				
									if {[lsearch -exact [list mime-types] $item] != -1} {
										puts $debug_out(3) "aur_install - \"$item\" is in ignored list"
										# so do not add item to the end of the list, just ignore it
										continue
									}
									puts $debug_out(3) "aur_install - test $item for basename"
									set result [get_aur_info $item]
									# if get_aur_info returns 1 then there is no internet
									if {$result == 1} {return 1}

									set basename [lindex $result 0]
									if {$basename == ""} {
										puts $debug_out(3) "aur_install - $item does not exist in AUR so pass it on to be queried in aur_install_depends"
										set basename $item
									} elseif {$basename != $item} {
										set ans [tk_messageBox -default ok -detail "The package $item is a dependency of $package, but $item is a part of $basename. Substituting $basename for $item in the list of dependencies" -icon info -message "The package \"$item\" is a part of \"$basename\"" -parent . -title "Dependency found" -type ok]
										puts $debug_out(3) "aur_install - basename of dependency $item is $basename"
									}
									# do not add duplicate items or the original package name
									if {[lsearch -exact $new_installs $basename] == -1 && $basename != $package} {
										puts $debug_out(3) "aur_install - add $basename to install list \"$new_installs\""
										lappend new_installs $basename
									}
									puts $debug_out(3) "aur_install - set revised installs list to $new_installs"
								} 
								set aur_installs $new_installs
								puts $debug_out(2) "aur_install - install list is reset to $aur_installs" 
								if {[llength $aur_installs] != 0 && $aur_installs != $package} {
									puts $debug_out(2) "aur_install - call aur_install_depends for package \"$package\" with \"$aur_installs\""
									aur_install_depends $package [concat $aur_installs $package]
									puts $debug_out(2) "aur_install - returned from aur_install_depends"
								} else {
									aur_upgrade $package "aur"
								}
									
							} else {
								puts $debug_out(2) "aur_install - call aur_upgrade with package \"$package\" and type \"aur\""
								aur_upgrade $package "aur"
							}
						}
					}
				}
			} \
			-text "Install" \
			-width 8

		button .aurinstall.download \
			-command {
				# get_aur_list will test the internet connection
				if {[.aurinstall.package cget -text] != ""} {
					# check that the package exists
					# try to download an up-to-date packages list
					# the packages list is updated frequently so always get a new file if possible
					set result [get_aur_list]
					if {$result == 1} {
						puts $debug_out(2) "aur_install - cannot download new package list and there is no existing package available"
						set ans [tk_messageBox -default ok -detail "Could not download the AUR package list.\nNo previous AUR package list is available.\nCannot continue" -icon error -message "Failed to download AUR package list" -parent .aurinstall -title "Error" -type ok]
					} elseif {$result == 2} {
						puts $debug_out(2) "aur_install - cannot download new package list and do not use the package list available"
					} else {
						set package [.aurinstall.package cget -text]
						puts $debug_out(1) "aur_install - download $package"
						set error [lsearch $aur_list $package]
						if {$error == -1} {
							puts $debug_out(3) "aur_install_depends - \"$package\" was not found in aur_list"
							# $item does not exist in the AUR
							tk_messageBox -default ok -detail "The package \"$package\" was not found in AUR" -icon error -message "Cannot download \"$package\"" -parent . -title "Download Error" -type ok
						} else {
							# test that the basename is the same as the package name
							set info [get_aur_info $package]
							set basename [lindex $info 0]
							if {$basename != $package} {
								puts $debug_out(2) "aur_install- $package has a basename of $basename"
								tk_messageBox -default ok -icon question -message "The package \"$package\" is a part of \"$basename\"" -parent . -title "Download $package" -type ok
								set package $basename
							}
							# find a download directory
							set dl_dir ""
							set xdg_dir ""
							if {[file exists "$home/.config/user-dirs.dirs"]} {
								set xdg_dir "not set"
								puts $debug_out(2) "aur_install - download directory set to XDG folder"
								set fid [open "$home/.config/user-dirs.dirs" r]
								set user_dirs [read $fid]
								close $fid
								set user_dirs [lsearch -inline -glob [split $user_dirs \n] "XDG_DOWNLOAD_DIR=*"]
								set dl_dir [string range $user_dirs [string first \" $user_dirs] end]
								if {[string first "HOME" $dl_dir] == 2} {set dl_dir $home/[string range $dl_dir 7 end-1]}
								puts $debug_out(2) "aur_install - XDG download directory is \"$dl_dir\""
							}
							if {$dl_dir == ""} {
								set dl_dir $home
							} else {
								set xdg_dir "set"
							}
							# download the file
							if {[file exists "$dl_dir/$package.tar.gz"]} {
								puts $debug_out(2) "aur_install - \"$dl_dir/$package.tar.gz\" exists - delete it"
								set error [catch {file delete "$dl_dir/$package.tar.gz"} result]
								if {$error != 0} {puts $debug_out(2) "aur_install - \tfailed with error $error  and result \"$result\""}
							}
							if {$dlprog == "curl"} {
								puts $debug_out(2) "aur_install - download file using \"curl -s -o \"$dl_dir/$package.tar.gz\" -L \"https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz\""
								set error [catch {exec curl -s -o "$dl_dir/$package.tar.gz" -L "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"} result]
								
							} else {
								puts $debug_out(2) "aur_install - download file using \"wget -P \"$dl_dir\" -Lq \"https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz\"\""
								exec wget -P "$dl_dir" -Lq "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
							}
							puts $debug_out(2) "aur_install - downloaded file with error $error and result \"$result\""
							# what were the results
							set detail ""
							if {$xdg_dir == ""} {
								set detail "Because no XDG user directories have been set\n"
							} elseif {$xdg_dir == "not set"} {
								set detail "Because no download directory has been set in the XDG user directories\n"
							}
							set detail [string trim [concat $detail "$package.tar.gz has been downloaded to \"$dl_dir\""]]
							set ans [tk_messageBox -default ok -detail $detail -icon info -message "The snapshot file for $package has been downloaded" -parent .aurinstall -title "Download complete" -type ok]
							destroy .aurinstall
						}
					}
				}
			} \
			-text "Download" \
			-width 8

		button .aurinstall.cancel \
			-command {
				grab release .aurinstall
				destroy .aurinstall
			} \
			-text "Cancel" \
			-width 8

	# Geometry management

	grid .aurinstall.packagename_label -in .aurinstall -row 2 -column 2 \
		-sticky w
	grid .aurinstall.packagename -in .aurinstall -row 2 -column 4 \
		-sticky e
	grid .aurinstall.info -in .aurinstall -row 2 -column 5 -padx 2
	grid .aurinstall.browse_label -in .aurinstall -row 3 -column 1 \
		-columnspan 5 \
		-sticky we
	grid .aurinstall.browse -in .aurinstall -row 4 -column 1 \
		-columnspan 5 \
		-sticky n
	grid .aurinstall.buttons -in .aurinstall -row 5 -column 1 \
		-columnspan 5 \
		-sticky we
		grid .aurinstall.install -in .aurinstall.buttons -row 1 -column 1 \
			-sticky w
		grid .aurinstall.download -in .aurinstall.buttons -row 1 -column 2 
		grid .aurinstall.cancel -in .aurinstall.buttons -row 1 -column 3 \
			-sticky e
			
	# Resize behavior management

	grid rowconfigure .aurinstall 1 -weight 0 -minsize 30 -pad 0
	grid rowconfigure .aurinstall 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall 3 -weight 1 -minsize 0 -pad 0
	grid rowconfigure .aurinstall 4 -weight 1 -minsize 0 -pad 0
	grid rowconfigure .aurinstall 5 -weight 0 -minsize 0 -pad 0

	grid columnconfigure .aurinstall 1 -weight 0 -minsize 15 -pad 0
	grid columnconfigure .aurinstall 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall 3 -weight 0 -minsize 5 -pad 0
	grid columnconfigure .aurinstall 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall 5 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall 5 -weight 0 -minsize 15 -pad 0
	
	grid rowconfigure .aurinstall.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.buttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.buttons 3 -weight 1 -minsize 0 -pad 0
	
	balloon_set .aurinstall.packagename_label "The name of an AUR package to install"
	balloon_set .aurinstall.packagename "The name of an AUR package to install"
	balloon_set .aurinstall.browse "Browse to a local file to install"
	balloon_set .aurinstall.info "Get more information about the package"
	balloon_set .aurinstall.install "Install the package now"
	balloon_set .aurinstall.download "Only download the package"
	balloon_set .aurinstall.cancel "Cancel - do not install any package"

	update
	grab set .aurinstall
	focus .aurinstall.packagename
	
}

proc aur_install_depends {package installs} {
	
global aur_list debug_out su_cmd tmp_dir
# install each of the aur dependencies listed

	puts $debug_out(1) "aur_install_depends called for package \"$package\" and installs \"$installs\""
	set index [lsearch $installs $package]
	set ans [tk_messageBox -default yes -detail "Do you want to try to install the AUR dependencies ([lrange $installs 0 $index-1]) before $package?" -icon question -message "There are dependencies from the AUR to install" -parent . -title "Install $package" -type yesno]
	if {$ans == "yes"} {
	# first pass, check that the aur packages exist
		set no_depends false
		puts $debug_out(2) "aur_install_depends - check the basenames of each item in \"$installs\""
		set error_list ""
		set new_installs ""
		foreach item $installs {
			puts $debug_out(3) "aur_install_depends - check basename of $item from $installs"
			# check the basenames of all the items up to, but not including, the package name
			if {$item == $package} {
				# now set the index to the position of the item in the installs list
				set index [lsearch -exact $installs $item]
				puts $debug_out(3) "aur_install_depends - set the index of package \"$package\" to $index"
				break
			}
			set error [lsearch $aur_list $item]
			if {$error == -1} {
				puts $debug_out(3) "aur_install_depends - \"$item\" was not found in aur_list"
				# $item does not exist in the AUR
				puts $debug_out(3) "aur_install_depends - check whether \"$item\" is already installed as 'provides'"
				# now find the name of the package(s) which provide the item
				set result [read_dependencies_provides $item]
				set provides [lindex $result 0]
				set installed [lindex $result 1]
				if {$installed != ""} {
					puts $debug_out(3) "aur_install_depends - an installed package already provides $item"
					continue
				} elseif {$provides == ""} {
					lappend error_list $item
					puts $debug_out(3) "aur_install_depends - cannot find what provides $item - error_list is now $error_list"
				} else {
					if {[llength $provides] == 1} {
						puts $debug_out(3) "aur_install_depends - $provides from sync will be installed and provides $item"
					} else {
						puts $debug_out(3) "aur_install_depends - one of \"$provides\" from sync will provide $item when installed"
					}
				}
					# either we found the item in a system package which will be installed automatically, or we did not and an error will be flagged
					continue
			} else {
				puts $debug_out(3) "aur_install_depends - \"$item\" exists in aur_list"
				# $item exists in aur_list

				# if the basename is different then replace item with basename in installs list
				puts $debug_out(3) "aur_install_depends - get the info for $item"
				set info [get_aur_info $item]
				if {$info == 1} {
					# no info for $item
					return 1
				}
				set basename [split [lindex $info 0] " "]
				if {$basename == ""} {set basename $item} else {set item $basename}
				puts $debug_out(3) "aur_install_depends - package set to $basename"
				# if for any reason the basename is the same as the package name then do not process it
				if {$basename == $package} {
					puts $debug_out(3) "aur_install_depends - this is the same package as the item to install, do not process it"
					continue
				}
			}
			
			
			puts $debug_out(3) "aur_install_depends - check for duplicates of \"$item\" in \"$new_installs\""
			set index [lsearch -exact $new_installs $item]
			if {$index != -1} {
				puts $debug_out(3) "aur_install_depends - \"$item\" already exists in \"$new_installs\""
				# so do not add item to the end of the list, use the existing, earlier, instance
			} else {
				# add item to the end of the new list
				lappend new_installs $item
			}
			puts $debug_out(3) "aur_install_depends - new_installs is now \"$new_installs\""
		}
		puts $debug_out(2) "aur_install_depends - new installs list is \"$new_installs\", the rest of the list is \"[lrange $installs $index end]\""
		# add back the rest of the install list
		set installs [concat $new_installs [lrange $installs $index end]]
		puts $debug_out(2) "aur_install_depends - test basenames complete and installs list is now \"$installs\""
		puts $debug_out(2) "\t and error list is \"$error_list\""
		if {$error_list != ""} {				
			puts $debug_out(2) "aur_install_depends - cannot install \"$error_list\""
			set ans [tk_messageBox -default no -detail "The following dependencies:   ${error_list}\n\n      could not be installed from here.\n\nDo you want to try to continue anyway? This may not succeed,\n\nHint: Check the list of dependencies for $package (Tools > Install AUR/Local > \"$package\" > Info) and check the AUR page (AUR:) for the package." -icon error -message "Unable to find dependencies in the AUR package list" -parent . -title "Cannot install $package dependencies" -type yesno]
			if {$ans == "yes"} {
				puts $debug_out(2) "aur_install_depends - answer to cannot install \"$error_list\" is yes"
				puts $debug_out(2) "aur_install_depends - remove \"$error_list\" from \"$installs\""
				# remove the error_list items and try to install the rest
				foreach item $error_list {
					set index [lsearch -exact $installs $item]
					set installs [lreplace $installs $index $index]
				}
				puts $debug_out(2) "aur_install_depends - install list is now \"$installs\""
				set no_depends true
			} else {
				return 1
			}
		}
		
	}
	# second pass, try to install them
	# $ans was set by the first question above and then reset by the second question
	if {$ans == "yes"} {
		puts $debug_out(2) "aur_install_depends - try to install dependencies \"$installs\""
		# now try to install them
		foreach item $installs {
			puts $debug_out(3) "aur_install_depends - try to install $item from $installs"
			if {$item == $installs} {
				puts $debug_out(3) "aur_install_depends - try to install $item"
				set error [aur_upgrade $item "aur"]
				puts $debug_out(3) "aur_install_depends - error was $error"	
				if {$error == 0 } {
					return 0
				} else {
					return 1
				}			
			} elseif {$no_depends} {
				puts $debug_out(3) "aur_install_depends - no_depends is true"
				set add_depends ""
				# reset no_depends for any futures passes
				set no_depends false
			} else {
				# are there any more dependencies?
				puts $debug_out(3) "aur_install_depends - call get_aur_dependencies for $item"
				set depends [get_aur_dependencies $item]
				if {$depends == "cancel"} {
					puts $debug_out(1) "aur_install_depends cancelled"
					return 1
				}
				if {$depends == "none"} {
					puts $debug_out(3) "aur_install_depends - there are no additional dependencies for $item"
					set add_depends ""
				} else {
					puts $debug_out(3) "aur_install_depends - get_aur_dependencies found:"
					puts $debug_out(3) "\tRequired: [lindex $depends 0]"
					puts $debug_out(3) "\tRepo installs needed: [lindex $depends 1]"
					puts $debug_out(3) "\tAUR installs needed: [lindex $depends 2]"
					puts $debug_out(3) "\tCheck Required: [lindex $depends 3]"
					puts $debug_out(3) "\tCheck Repo installs needed: [lindex $depends 4]"
					puts $debug_out(3) "\tCheck AUR installs needed: [lindex $depends 5]"
					puts $debug_out(3) "\tMake Required: [lindex $depends 6]"
					puts $debug_out(3) "\tMake Repo installs needed: [lindex $depends 7]"
					puts $debug_out(3) "\tMake AUR installs needed: [lindex $depends 8]"
					puts $debug_out(2) "aur_install_depends - get_aur_dependencies returned package name [lindex $depends 9]"
					set add_depends [concat [lindex $depends 2] [lindex $depends 5] [lindex $depends 8]]
				}
			}
			if {$add_depends != ""} {
				# there are additional dependencies
				# the dependencies need to be added to the front of the list of items to install, 
				# which will be just before the package that needs them, and then the procedure needs to be re-run
				set installs [concat $add_depends $installs]
				puts $debug_out(3) "aur_install_depends - found additional dependencies and reset installs to \"$installs\""
				break
			}
			puts $debug_out(3) "aur_install_depends - no more dependencies for $item, last package from $installs should be [lindex $installs end]"
			if {$item != [lindex $installs end]} {
				puts $debug_out(3) "aur_install_depends - run aur_upgrade to install dependency \"$item\" from \"$installs\""
				set error [aur_upgrade $item "aurdepends"]
				puts $debug_out(3) "aur_install_depends - error was $error"
			} else {
				puts $debug_out(3) "aur_install_depends - run aur_upgrade to install \"$item\" from \"$installs\""
				set error [aur_upgrade $item "aur"]
				puts $debug_out(3) "aur_install_depends - error was $error"
			}
			# remove item from install list
			set installs [lrange $installs 1 end]
			puts $debug_out(3) "aur_install_depends - installs reset to \"$installs\", package is \"$package\", last item to install is \"[lindex $installs end]\"" 
			# did aur_upgrade return an $error
			if {$error == 0} {
				# success
				puts $debug_out(3) "aur_install_depends - installed $item" 
			} elseif {$item != $package} {
				set ans [tk_messageBox -default ok -detail "Failed to install $item which is a dependency of $package.\n\nCannot continue to install $package." -icon error -message "Failed to install dependency $item." -parent . -title "Error" -type ok]
				puts $debug_out(3) "aur_install_depends - install $item failed - cannot continue" 
				set installs ""
				break
			} elseif {$item == $package} {
				set ans [tk_messageBox -default ok -detail "Failed to install $item which is a dependency of [lindex $installs end].\n\nCannot continue to install [lindex $installs end]." -icon error -message "Failed to install dependency $item." -parent . -title "Error" -type ok]
				puts $debug_out(3) "aur_install_depends - install $item failed - cannot continue" 
				set installs ""
				break
			} elseif {$item == [lindex $installs end]} {
				set ans [tk_messageBox -default ok -detail "Failed to install $item" -icon error -message "Failed to install $item." -parent . -title "Error" -type ok]
				puts $debug_out(3) "aur_install_depends - install $item failed - message reply is do not retry"
				set installs ""
				break
			}
		}
		puts $debug_out(2) "aur_install_depends - installs is now $installs"
		if {$installs != ""} {
			puts $debug_out(2) "aur_install_depends - there are more packages to install - call aur_install_depends with \"$item\" \"$installs\""
			# there are more packages to install so call aur_install_depends again
			aur_install_depends $item $installs
		}
	} else {
		puts $debug_out(1) "aur_install_depends cancelled"
		return 1
	}
	puts $debug_out(1) "aur_install_depends completed"
}

proc aur_upgrade {package type} {

global aur_versions aur_versions_TID debug debug_out dlprog editor geometry list_all list_local listview_last_selected listview_selected listview_selected_in_order program_dir save_geometry selected_list su_cmd terminal_string thread threads tmp_dir	
# download and install or upgrade a package from AUR/Local
# known types are: 
#	upgrade (upgrade a selected AUR/Local package), only existing AUR packages can be upgraded - called by invoking .buttonbar.install_button with aur_only
# 	install (install a local package from a filename), could apply to an install, upgrade or downgrade of any package - called by proc aur_install
#	aur (install, reinstall or upgrade an AUR package) - called by proc aur_install
#	aurdepends (install an AUR package asa dependency) - called by proc aur_install_depends

# if the package directory exists then it may have been the result of an aborted upgrade from before
# so we will leave the partial/completed upgrades until we close 
# otherwise we would need to force the upgrade, which would be messy and dangerous	

# this may not work if we are running as root

	puts $debug_out(1) "aur_upgrade called with type \"$type\" and package \"$package\""
	
	# check for a lock file
	if {[file exists "/var/lib/pacman/db.lck"]} {
		# silently copy the lock file to the clipboard
		clipboard append "/var/lib/pacman/db.lck"
		tk_messageBox -message "Unable to lock database" -detail "If you're sure a package manager is not already\nrunning, you can remove /var/lib/pacman/db.lck" -icon error -title "Sync - Update Failed" -type ok
		return 1
	}
	
	set found ""
	set available_version ""
	set current_version ""
	set install_version ""
	set asdepends ""
	set package_type "none"
	set vstate ""
	
	if {$type == "aurdepends"} {
		puts $debug_out(2) "aur_upgrade - type is aurdepends, install \"$package\" as a dependancy and reset type to aur"
		set asdepends " --asdeps"
		set type "aur"
	}
	
	if {$type == "install"} {
		# this is a local package to install so parse the filename and get the package name and the install version
		set filename $package
		set elements [split [file tail $package] "-"]
		set arch [lindex $elements end]
		set install_version [string map {\  -} [lrange $elements end-2 end-1]]
		set package [file rootname [string map {\  -} [lrange $elements 0 end-3]]]
		puts $debug_out(2) "aur_upgrade - install $package using $filename"
	}
	
	# does the package exist in list_local, if not does it exist in list_all
	set found [lsearch -nocase -index 1 -all -inline $list_local $package] 
	if {$found != ""} {
		puts $debug_out(2) "aur_upgrade - found $package in list_local"
		# this is an installed AUR/Local package
		set package_type "aur_local"
	} else {
		set found [lsearch -nocase -index 1 -all -inline $list_all $package]
		if {$found != ""} {
			puts $debug_out(2) "aur_upgrade - found $package in list_all"
			# this is a repository package
			set package_type "repo"
		}
	}
	# if the package exists then get its current version and available version
	if {$found != ""} {
		set found [split $found { }]
		set available_version [lindex $found 3]
		if {$type == "install" && $available_version == ""} {
			set available_version $install_version
		}
		set current_version [lindex $found 2]
		# note that the available version was set to "" originally
		if {$available_version != "\"\""} {
### temporarily remove any *
###			set available_version [string trimleft $available_version {*}]
###
			puts $debug_out(2) "aur_upgrade - $package has been installed"
			puts $debug_out(2) "aur_upgrade - The current version is $current_version, the version available is $available_version"
			# the package was found in one of the lists, then the package_type is either 'aur_only' or 'repo'
			# if the type is install then there will be an install_version available
			if {$type == "install"} {
				puts $debug_out(2) "aur_upgrade - The version to install is $install_version"
			}
			# types are install upgrade or aur
			# if the available version is the same as the current version then the package is already up to date (indate)
			# if the available version is greater than the current version, then the package could be upgraded (outdate)
			# if the type is install then if the install version is less than the current version then the package will be downgraded (downdate)
			if {$type == "install"} {
				set result [test_versions $current_version $install_version]
			} else {
				set result [test_versions $current_version $available_version]
			}
			puts $debug_out(2) "aur_upgrade - test_versions returned $result"
			switch $result {
				same {
					puts $debug_out(2) "\tand is up to date (indate) - ask if it should be reinstalled"
					set ans [tk_messageBox -default no -detail "Do you want to reinstall $package?" -icon question -message "The package \"$package\" is already up to date" -parent . -title "Reinstall $package" -type yesno]
					if {$ans == "no"} {
						puts $debug_out(2) "aur_upgrade - cancelled"
						return 1
					}
					set vstate "indate"
				}
				newer {
					puts $debug_out(2) "\tand is marked to upgrade (newer)"
					set vstate "outdate"
				}
				older {
					puts $debug_out(2) "\tand the installed version is already newer (downdate)"
					set vstate "downdate"
				}
			}
				
		} else {
			puts $debug_out(2) "aur_upgrade - $package has not been installed"
		}
	} else {
		puts $debug_out(2) "aur_upgrade - $package is not in the installed aur/local packages or in the repos"
	}
	
	puts $debug_out(2) "aur_upgrade - now check the package_type \"$package_type\""	
	switch $package_type {
		"none" {
			puts $debug_out(2) "aur_upgrade - $type called for $package which is not in list_local or in the repos"
			# could be installed if it is type "aur" and exists in AUR
			# or if it is a local package of type "install"
			# we can use get_aur_info to check that the package name exists in AUR
			# check if the package exists in AUR
			puts $debug_out(2) "aur_upgrade - call get_aur_info"
			set result [get_aur_info $package]
			if {$result == 1} {return 1}

			# if the package does not exist then get_aur_info will return a list of five blank items
			set basename [lindex $result 0]
			if {$basename == ""} {
				puts $debug_out(2) "aur_upgrade - $package not found in AUR"
				if {$type != "install"} {
					puts $debug_out(1) "aur_upgrade - $package is not type $type - return error"
					tk_messageBox -default ok -detail "The package \"$package\" was not found in AUR" -icon error -message "Cannot install \"$package\"" -parent . -title "Install Error" -type ok
					return 1
				}
				puts $debug_out(2) "aur_upgrade - $package is a local package to install"
			} elseif {$basename != $package} {
				puts $debug_out(2) "aur_upgrade - $package has a basename of $basename"
				set ans [tk_messageBox -default ok -detail "Do you want to install $basename?" -icon question -message "The package \"$package\" is a part of \"$basename\"" -parent . -title "Install $package (1)" -type okcancel]
				if {$ans == "cancel"} {return 1}
				set package $basename
			}
			puts $debug_out(2) "aur_upgrade - ok - install $package"
		}
		"aur_local" {
			puts $debug_out(2) "aur_upgrade - $type called for $package which is already installed in list_local"
			# type upgrade - will upgrade or reinstall which is fine (but can only apply to packages in AUR)
			# type aur - will do the same as upgrade (can only apply to packages in AUR)
			if {$type == "upgrade" || $type == "aur"} {
				# check if the package exists in AUR
				set result [get_aur_info $package]
				if {$result == 1} {return 1}

				# if the package does not exist then get_aur_info will return a list of five blank items
				set basename [lindex $result 0]
				if {$basename == ""} {
					puts $debug_out(1) "aur_upgrade - $package not found in AUR"
					set_message terminal "ERROR - the package \"$package\" was not found in AUR"
					after 5000 {set_message terminal ""}
					return 1
				}
				# now check if basename is not the same as the package name
				if {$basename != $package} {
					puts $debug_out(2) "aur_upgrade - $package has a basename of $basename"
					set ans [tk_messageBox -default ok -detail "Do you want to install $basename?" -icon question -message "The package \"$package\" is a part of \"$basename\"" -parent . -title "Install $package (2)" -type okcancel]
					if {$ans == "cancel"} {return 1}
					set package $basename
				}
				puts $debug_out(2) "aur_upgrade - $type called for $package which exists in AUR"
			}
			# type install - could be an upgrade, downgrade or re-install of the package filename
			puts $debug_out(2) "aur_upgrade - ok - install $package"
		}
		"repo" {
			puts $debug_out(2) "aur_upgrade - $type called for $package which is $vstate and is already available in the repos"
			# aur and upgrade types only apply to aur packages
			# it is not wise to install a repo package here because it might break the system
			# so we can only downdate a repo package at present
			if {$type == "install" && $vstate == "downdate"} {
				puts $debug_out(2) "aur_upgrade - ok - install $package"
			} elseif {$type == "install" && ($available_version != $install_version)} {
				puts $debug_out(2) "aur_upgrade - ok for minor update - install $package"
			} else {
				puts $debug_out(1) "aur_upgrade - cannot - install or upgrade $package here, it is in the repos"
				set ans [tk_messageBox -default ok -detail "\"$package\" cannot be installed or upgraded from here. Select All and Find the package in the list presented." -icon info -message "\"$package\" already exists in the repositories" -parent . -title "Install/Upgrade \"$package\"" -type ok]
				return 1
			}
		}
		
	}
	puts $debug_out(2) "aur_upgrade - passed tests, check state of package $package (type is $type, vstate is $vstate)"

	set detail "\"$package\" is already installed"

	switch $vstate {
		indate {
			# reinstalls have already been disallowed for package_types "repo"
			set detail [concat $detail " and is up to date."]
			set title "reinstall"
		}
		outdate {
			# upgrades have already been disallowed for package_types "repo", and for package_types "aur" which are not found in AUR
			set title "upgrade"
		}
		downdate {
			set title "downgrade"
		}
		default {
			# installs have already been disallowed for package_types "repo", and for package_types "aur" which are not found in AUR
			set detail ""
			set title "install"
		}
	}
	
	# if the type is not "upgrade" and this is a straight "install" then do not ask for confirmation, any false options have already been disallowed
	# or if this is a downgrade then do not ask for confirmation
	if {($type != "upgrade" && $title != "install" && $title != "reinstall" ) || $title == "downgrade"} {
		set tk_message "Do you want to $title \"$package\"?"
		if {$title == "downgrade"} {set detail [concat $detail " and is newer"]}
		set ans [tk_messageBox -default yes -detail $detail -icon info -message $tk_message -parent . -title "[string totitle $title] \"$package\"" -type yesno]
		 
		if {$ans == "no"} {
			return 1
		}
	}

	# Create a download directory in the tmp directory
	puts $debug_out(2) "aur_upgrade - make sure that $tmp_dir/aur_upgrades exists"
	file mkdir "$tmp_dir/aur_upgrades"
	
	if {$type != "install" && [file isdirectory "$tmp_dir/aur_upgrades/$package"] == 1} {
		# Unless this is install a filename then if the directory already exists, then the process has been run before.
		# This could be fine as long as the package was not built.
		puts $debug_out(2) "aur_upgrade - WARNING - $tmp_dir/aur_upgrades/$package already exists"
		# test for a pkg file, sort any files found and pick the last one 
		set filename [lindex [lsort [glob -nocomplain -directory $tmp_dir/aur_upgrades/$package *.pkg.*]] end]
		puts $debug_out(2) "aur_upgrade - glob returned $filename"
		if {$filename != ""} {
			# this will cause a failure with "==> ERROR: A package has already been built."
			puts $debug_out(2) "aur_upgrade - WARNING - $filename already exists"
			set ans [tk_messageBox -default yes -detail "Do you want to rebuild $package?\n\n         Answer Yes to rebuild the package.\n         Answer No to install the existing package." -icon warning -message "A package has already been built." -parent . -title "Warning" -type yesnocancel]
		 
			if {$ans == "yes"} {
				file delete "$filename"
			} elseif {$ans == "no"} {
				set type "install"
			} else {
				puts $debug_out(1) "aur_upgrade - user cancelled rebuild/reinstall package"
				return 1
			}
		}
	}
	
	set logfile [find_pacman_config logfile]
	set logfid [open $logfile r]
	seek $logfid +0 end
	puts $debug_out(2) "aur_upgrade - opened the pacman logfile ($logfile) and moved to the end of the file"

	# write a shell script to install or upgrade the package
	puts $debug_out(2) "aur_upgrade - Create a shell script to install or upgrade $package"
	# tidy up any leftover files (which should not exist)
	puts $debug_out(2) "\tdelete $tmp_dir/vpacman.sh"
	file delete "$tmp_dir/vpacman.sh"
	
	puts $debug_out(2) "\twrite new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	puts $fid "cd \"$tmp_dir/aur_upgrades\""
	if {$type != "install"} {
		# download the AUR file to install or upgrade
		puts $fid "echo \"\nDownload $package snapshot\n\""
		# the package snapshot presently has the extention .tar.gz		
		if {$dlprog == "curl"} {
			puts $fid "curl -L -O \"https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz\""
		} else {
			puts $fid "wget -Lq \"https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz\""
		}
		puts $fid "echo \"Unpack $package\n\""
		puts $fid "tar -xvf \"$package.tar.gz\""
		puts $fid "cd $tmp_dir/aur_upgrades/$package"
		puts $fid "echo -n \"\nDo you want to check the PKGBUILD file? \[Y/n\] \""
		puts $fid "read ans"
		puts $fid "case \"\$ans\" in"
	    puts $fid "\tN*|n*)  ;;"
	    if {$editor == ""} {
			puts $fid "\t*) cat PKGBUILD"
		} else {
			puts $fid "\t*) $editor PKGBUILD"
		}
		puts $fid "\techo -n \"\nContinue? \[Y/n] \""
		puts $fid "\tread ans"
		puts $fid "\tcase \"\$ans\" in"
		puts $fid "\t\tN*|n*) exit ;;"
		puts $fid "\t\t*);;"
	    puts $fid "\tesac"
	    puts $fid "esac"
	    if {$su_cmd != "su -c"} {
			puts $fid "echo -e \"\n$ makepkg -sci \n\""
			puts $fid "makepkg -sci $asdepends > /dev/tty 2>&1 | tee $tmp_dir/errors"
		} else {
			puts $fid "echo -e \"\n$ makepkg -c \n\""
			puts $fid "if makepkg -c ; then"
			puts $fid "\techo -e \"\nInstalling $package using pacman -U  \n\""
			puts $fid "\tsu -c \"pacman -U $asdepends $package\*.pkg.*\" > /dev/tty 2>&1 | tee $tmp_dir/errors"
			puts $fid "else"
			puts $fid "\techo -e \"\nCannot install dependencies now - install the missing dependencies and try again\n\""
			puts $fid "fi"
		}
			
	} else {
		puts $fid "echo -e \"\nInstalling $filename using pacman -U  \n\""
		if {$su_cmd != "su -c"} {
			puts $fid "$su_cmd pacman -U $filename > /dev/tty 2>&1 | tee $tmp_dir/errors"
		} else {
			puts $fid "su -c \"pacman -U $filename\" > /dev/tty 2>&1 | tee $tmp_dir/errors"
		}
	}
	if {$type == "upgrade"} {
		set action "Upgrade AUR Package"
		puts $fid "echo -ne \"\nUpgrade $package finished, press ENTER to close the terminal.\""
	} elseif {$type == "aur" || $type == "install"} {
		puts $fid "echo -ne \"\nInstall [string range [file tail $package] 0 [string first ".pkg." [file tail $package]]-1] finished, press ENTER to close the terminal.\""
		set action "Install Local Package"
	} elseif {$type == "reinstall"} {
		puts $fid "echo -ne \"\nReinstall $package finished, press ENTER to close the terminal.\""
		set action "Reinstall AUR Package"
	} else {
		
	}
	puts $fid "read ans"
	puts $fid "exit" 
	close $fid
	puts $debug_out(2) "aur_upgrade - change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out(2) "aur_upgrade - call set_message - type terminal, \"TERMINAL OPENED to run $action\""
	set_message terminal "TERMINAL OPENED to run $action"
	# stop the exit button working while the terminal is opened
	set_wmdel_protocol noexit
	update idletasks
	puts $debug_out(2) "aur_upgrade - execute $tmp_dir/vpacman.sh"
	eval [concat exec $execute_string &]
	# wait for the terminal to open
	execute_terminal_isopen $action
	puts $debug_out(2) "\taur_upgrade - command started in terminal"
	# place a grab on something unimportant to avoid random button presses on the window
	grab set .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> "catch {exec wmctrl -R \"$action\"}"
		update idletasks
	puts $debug_out(2) "aur_upgrade - set grab on .buttonbar.label_message"
	# wait for the terminal to close
	execute_terminal_isclosed $action "Vpacman"
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out(2) "aur_upgrade - Grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out(2) "aur_upgrade - Window manager delete window re-instated"
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	set_message terminal ""
	update
	
	# read the rest of the logfile
	# writing the logfile should be quick this time because there should only be a few lines
	set logtext [read $logfid]
	close $logfid
	puts $debug_out(2) "aur_upgrade - completed and logged these events:"
	puts $debug_out(2) "$logtext"
	if {$logtext == ""} {
		puts $debug_out(1) "aur_upgrade - nothing was logged so nothing happened - return error"
		return 1
	}

	# now work out what we did
	set count_upgrades 0
	set count_downgrades 0
	set count_installs 0
	set count_reinstalls 0
	foreach line [split $logtext \n] {
		if {[string first "\[ALPM\] upgraded" $line] != -1} {
			incr count_upgrades
		} elseif {[string first "\[ALPM\] downgraded" $line] != -1} {
			incr count_downgrades
		} elseif {[string first "\[ALPM\] installed" $line] != -1} {
			incr count_installs
		} elseif {[string first "\[ALPM\] reinstalled" $line] != -1} {
			incr count_reinstalls
		}
	}
	
	puts $debug_out(2) "aur_upgrade - Upgraded $count_upgrades, Downgraded $count_downgrades, Installed $count_installs, Reinstalled $count_reinstalls"	
	
	# and decide what is necessary to do 
	set restart false
	# aur_upgrade can only be called for one package, but others can be installed at the same time, so check that the called for
	# package has been installed (or reinstalled or upgraded or downgraded)
	switch $vstate {
		indate {
			if {$count_reinstalls >= 1 && [string first "reinstalled $package" $logtext] != -1} {
				puts $debug_out(2) "aur_upgrade - Reinstall succeeded"
				set result "success"
			} else {
				puts $debug_out(2) "aur_upgrade - Reinstall failed"
				set result "failed"
			}
		}
		outdate {
			if {$count_upgrades >= 1 && [string first "upgraded $package" $logtext] != -1} {
				puts $debug_out(2) "aur_upgrade - Upgrade succeeded"
				set result "success"
			} else {
				puts $debug_out(2) "aur_upgrade - Upgrade failed"
				set result "failed"
			}
		}
		downdate {
			if {$count_downgrades >= 1 && [string first "downgraded $package" $logtext] != -1} {
				puts $debug_out(2) "aur_upgrade - Downgrade succeeded"
				set result "success"
			} else {
				puts $debug_out(2) "aur_upgrade - Downgrade failed"
				set result "failed"
			}
		}
		default {
			if {$count_installs >= 1 && [string first "installed $package" $logtext] != -1} {
				puts $debug_out(2) "aur_upgrade - Install succeeded"
				set result "success"
			} else {
				puts $debug_out(2) "aur_upgrade - Install failed"
				set result "failed"
			}
		}
	}	

	# if something changed then set result to success
	if {[expr $count_upgrades + $count_downgrades + $count_installs] >= 1} {
		puts $debug_out(2) "aur_upgrade - Some changes were recorded"
		set result "success"
	}

	if {$result == "failed"} {
		puts $debug_out(2) "\tPackage was $vstate but the result was failed"
		# the local database will still be up to date
		# if we only did a reinstall then there is nothing to do
	} else {
		# the local database will need to be updated
		# delete the contents from  listview, proc start will run and bind TreeviewSelect
		# will update all the variables when the selection changes
		puts $debug_out(2) "\tPackage was not indate ($vstate) and result was success ($result) so delete listview contents"
		.wp.wfone.listview delete [.wp.wfone.listview children {}]
		update
		puts $debug_out(2) "\tSet restart true"
		# the counts and lists will need to be updated
		set restart true
	}
	# check that vpacman was not updated, if it was then restart it
	# it is not likely that it would be re-installed here (since it is running) but the upgrade may have been aborted
	if {$package == "vpacman" && $result == "success"} {
		set tk_message "updated"
		if {$vstate == "downdate"} {set message "downgraded"}
		tk_messageBox -default ok -detail "vpacman will now restart" -icon info -message "vpacman was $tk_message" -parent . -title "Further Action" -type ok
		if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]}
		puts $debug_out(2) "aur_upgrade - restart - save current configuration data"
		put_configs
		puts $debug_out(1) "aur_upgrade - restart called after vpacman update"
		if {$debug == "low"} {
			exec $program_dir/vpacman.tcl -d --restart &
		} elseif {$debug == "medium"} {
			exec $program_dir/vpacman.tcl -dd --restart &
		} elseif {$debug == "high"} {
			exec $program_dir/vpacman.tcl -ddd --restart &
		} else {
			exec $program_dir/vpacman.tcl --restart &
		}
		exit
	}
	# switch to aur_updates if required (do we want to include all local packages as well?)
	if {$package_type == "aur_local" || $package_type == "none"} {
		puts $debug_out(2) "aur_upgrade - $package is either AUR or local, so switch to AUR/Local if not already selected"
		set selected_list "aur_updates"
		set filter 0
	}
	# now update all the lists if we need to
	# if we did a local install using "pacman -U" then we do not know the result, so restart anyway
	if {$restart} { 
		puts $debug_out(2) "aur_upgrade - call start for type $type"
		# start will rewrite .wp.wfone.treeview and reset listview_selected
		# we need to remove the prior selection and the selection order
		set listview_last_selected ""
		set listview_selected_in_order ""
		# call start
		start
		if {$package_type == "aur_local" || $package_type == "none"} {
			puts $debug_out(2) "aur_upgrade - $package is AUR or local (or none), so do not call aur_versions_thread now, leave it to get_aur_versions when it is called by get_aur_updates"
			set aur_versions ""
			get_aur_updates
		} else { 
			puts $debug_out(2) "aur_upgrade - run threads called test_internet"
			if {$threads && [test_internet] == 0} {
				# now run the aur_versions thread to get the current aur_versions
				puts $debug_out(1) "aur_upgrade - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local"
				# this thread may conflict with get_aur_updates so mark it running
				set thread "running"
				thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
			}
		}
		filter
	} else {
		# otherwise just run filter
		puts $debug_out(2) "aur_upgrade - restart not required"
		filter
	}
	puts $debug_out(1) "aur_upgrade command - completed with result $result"
	if {$result == "failed"} {
		return 1
	}
	return 0
}

# SET UP BALLOON HELP
# Copyright (C) 1996-1997 Stewart Allen
# 
# This is part of vtcl source code
# Adapted for general purpose by 
# Daniel Roche <dan@lectra.com>
# version 1.1 ( Dec 02 1998 )

proc balloon {target message {cx 0} {cy 0} } {

global bubble helpbg helpfg

	if {$bubble(first) == 1 } {
		set bubble(first) 2
		if { $cx == 0 && $cy == 0 } {
			set x [expr [winfo rootx $target] + ([winfo width $target]/2)]
			set y [expr [winfo rooty $target] + [winfo height $target] + 4]
		} else {
			set x [expr $cx + 4]
			set y [expr $cy + 4]
		}
		# do not throw an error if the window has already been destroyed
		set error [catch {winfo screen $target} result]
		if {$error != 0} {return}
        toplevel .balloon -screen $result
        wm overrideredirect .balloon 1
        label .balloon.l \
			-bd 0 \
			-font "TkTextFont" \
            -text $message \
            -fg $helpfg \
            -bg $helpbg -padx 5 -pady 5 -anchor w
        pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${x}+${y}
        set bubble(set) 1
    }
}

proc balloon_set {target message} {

global bubble

	set bubble($target) $message
	bindtags $target "[bindtags $target] bubble"
}

proc balloon_unset {} {

global bubble

	after cancel $bubble(id)
	if {[winfo exists .balloon] == 1} {
		destroy .balloon
	}
	set bubble(set) 0
}

# bindings for balloon help

bind bubble <Enter> {
    set bubble(set) 0
    set bubble(first) 1
    # wait for a short time and show the balloon help message
	# do not throw an error if the window has been destroyed during the wait period
    catch {set bubble(id) [after 500 {balloon %W $bubble(%W) %X %Y}]}
}

bind bubble <Button> {
    set bubble(first) 0
    balloon_unset
}

bind bubble <Leave> {
    set bubble(first) 0
    balloon_unset
}

bind bubble <Motion> {
    if {$bubble(set) == 0} {
        after cancel $bubble(id)
        set bubble(id) [after 500 {balloon %W $bubble(%W) %X %Y}]
    }
}

# END OF BALLOON HELP

proc check_config_files {} {

global debug_out diffprog home su_cmd
# check /etc and /usr/bin /var/lib for any configuration files which need to be updated

	puts $debug_out(1) "check_config_files called"
	set config_files ""
	set file_list ""
	set files ""
	set lf ""
	set_message terminal "Checking for config files..." 
	update
	if {[catch {exec which find}] == 1} {
		tk_messageBox -default ok -detail "Consider installing the findutils package" -icon info -message "The find command is required." -parent . -title "Cannot Check Config Files" -type ok
		puts $debug_out(2) "check_config_files - findutils not installed - return1"
		return 1
	}
	set error [catch {exec find /etc /usr/bin /var/lib \( -name *.pacnew -o -name *.pacsave \) -print} files]
	puts $debug_out(2) "check_config_files - find command returned error $error and result $files"
	if {$files == "child process exited abnormal"} {set files ""}
	foreach file [split $files \n] {
		if {[string first "find:" $file] == -1} {
			set config_files [append config_files $lf $file]
			set file_list [lappend file_list $file]
			set lf "\n\t"
		}
	}
	set_message terminal ""
	if {$config_files == ""} {
		puts $debug_out(1) "check_config_files - no files found to update"	
		set_message terminal "No configuration files found to check"
		after 3000 {set_message terminal ""}
	} else {
		puts $debug_out(2) "check_config_files - found files to update: $config_files"	
		view_text "
	
	The following configuration files may need attention:
	
<lm1><code>	$config_files
</code></lm1>
	
	
	Check out:
	
	\"https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave\" 
	\"https://wiki.archlinux.org/index.php/mirrors\"
	\"https://wiki.archlinux.org/index.php/mirrors#List_by_speed\"
	
	for advice on how to deal with each file
	" "Found Configuration Files"
	
		tkwait window .view
		
		# see if pacman-mirrorlist has been upgraded
		if {[file exists /etc/pacman.d/mirrorlist.pacnew]} {
			puts $debug_out(2) "check_config_files - found pacnew mirrorlist"
			set ans [tk_messageBox -default yes -detail "Do you want to update pacman mirrorlist now?\n\nTo update the mirrorlist later run Tools > Update Mirrorlist" -icon info -message "A new pacman-mirrorlist has been downloaded" -parent . -title "Found Mirrorlist Config File" -type yesno]
			if {$ans == "yes"} {
				mirrorlist_update
				tkwait window .update_mirrors
			} 
		}
		set index [string first "/etc/pacman.d/mirrorlist.pacnew" $files]
		if {$index != -1} {
			puts $debug_out(2) "check_config_files - remove mirrorlist.pacnew from the list of config files"
			set file_list [string replace $file_list $index $index+31]
		}
		if {$diffprog != ""	} {	
			# if the diff programme is meld and the share folder is not writeable then meld will start, throw an error, and then fail to exit
			if {$diffprog == "meld"} {
				if {[file isdirectory $home/.local/share/meld]} {
					puts $debug_out(2) "check_config_files - meld directory exists"
					if {![file writable $home/.local/share/meld]} {
						puts $debug_out(2) "check_config_files - meld directory is not writeable"
						set ans [tk_messageBox -default ok -detail "The comparison programme is set to Meld, but the share folder \"$home/.local/share/meld\" is not writable.\nChoose another comparison programme or correct the share permissions." -icon error -message "Warning: Meld share directory is not writable!" -parent . -title "Meld Error" -type ok]
						return 1
					}
				}
			}
			set ans [tk_messageBox -default yes -detail "Would you like to try to deal with these configuration files now?" -icon info -message "Some saved configuration files were found." -parent . -title "Found Config Files" -type yesno]
			if {$ans == "yes"} {
				puts $debug_out(2) "check_config_files - now process the config file list"
				update_config_files [split $file_list]
			}	
		} else {
			puts $debug_out(2) "check_config_files - there is no diff programme selected return error"
			set ans [tk_messageBox -default ok -detail "If you would like to try to deal with these configuration files now then set a compare programme in Tools > Options" -icon info -message "No compare programme selected." -parent . -title "Found Config Files" -type ok]
			return 1
		}
	}
}

proc check_repo_files {dir tail} {
	
global dataview debug_out list_repos listview_current pacman_files_upgrade pkgfile_upgrade start_time su_cmd tmp_dir
# check whether the files for the repositories listed in the pacman configuration file exist in the directory
# if they do not, then update them, at the same time remove any files which are redundant.
# the file tails recognised are "db" or "files"

# Return 0 success, 1 failed, 2 updated, 3 cancelled

	puts $debug_out(1) "check_repo_files called for $tail extensions in $dir ([expr [clock milliseconds] - $start_time])"
	puts $debug_out(2) "\trepositories: $list_repos"
	# get the latest list of enabled repositories, pacman-conf does not check if the repository is correctly set up in the configuration file.
	# called by START and findfile
	
	set detail ""
	set error 0
	set message ""
	set missing ""
	puts $debug_out(2) "check_repo_files - get the file list for the \".$tail\" files"
	if {$dir == $tmp_dir} {
		set sync_dbs [glob -nocomplain "$dir/sync/*.$tail"]
	} else {
		set sync_dbs [glob -nocomplain "$dir/*.$tail"]
	}
	puts $debug_out(2) "\tfound $sync_dbs"
	# we could delete any files which are no longer valid
	# but then we might have to get a password for no apparent reason
	# or we could ask if we should delete them
	# but that risks continually asking the same question if the answer was no
	# for the moment just list the files no longer required in the debug output
	puts $debug_out(2) "check_repo_files - check that repo exists in $sync_dbs"
	foreach item $sync_dbs {
		set file [file tail [file rootname $item]]
		puts $debug_out(3) "check_repo_files - test for $file in $list_repos"
		if {[string first $file $list_repos] == -1} {
			puts $debug_out(3) "check_repo_files - delete $file - not in $list_repos"
			if {$dir == $tmp_dir} {
				puts $debug_out(1) "$dir/${file}.db and $dir/sync/${file}.files are no longer required and may be deleted"
			} else {
				puts $debug_out(1) "$dir/${file}.db and $dir/${file}.files are no longer required and may be deleted"
			}
		}
	}
	puts $debug_out(2) "check_repo_files - check for each repo in $sync_dbs"
	foreach repo $list_repos {
		puts $debug_out(3) "check_repo_files - test for $repo in $sync_dbs"
		# check that the database file exists
		if {[string first "${repo}.$tail" $sync_dbs] == -1} {
			puts $debug_out(3) "check_repo_files - $repo not found in $sync_dbs"
			lappend missing $repo
		}
	}
	if {$missing == ""} {
		puts $debug_out(2) "check_repo_files - no missing repos from \"$tail\" files"
	} else {
		puts $debug_out(2) "check_repo_files - missing repos are \"$missing\" from \"$tail\" files"
	}
	if {$tail == "db"} {
		if {[llength $missing] == 1} {
			set message "The database for $missing is missing."
		} elseif {[llength $missing] > 1} {
			set message "The databases for $missing are missing."
		}
		if {$message != ""} {
			puts $debug_out(2) "check_repo_files - there are missing db databases"
			tk_messageBox -default ok -detail "The missing temporary databases will be downloaded.\n\nConsider running a Full System Upgrade to avoid further errors." -icon error -message $message -parent . -title "Database Error" -type ok
			set error [execute sync]
			if {$error != 0} {
				puts $debug_out(2) "check_repo_files - db files update failed"
				tk_messageBox -default ok -detail "The missing temporary databases could not be downloaded.\n\nConsider running a Full System Upgrade to avoid further errors." -icon error -message "Download Failed" -parent . -title "Database Error" -type ok
				# this qualifies as a sync error so set the status warnings error flag
				place_warning_icon .filter_icons_warning
				return 1
			} else {
				puts $debug_out(2) "check_repo_files - db files update succeeded"
				return 2
			}
		} else {
			puts $debug_out(2) "check_repo_files - no missing db files"
			return 0
		}
	} elseif {$tail == "files" && $missing != ""} {
		set type "pacman"
		if {$dir == "/var/cache/pkgfile"} {set type "pkgfile"}
		puts $debug_out(2) "check_repo_files - there are missing $type files databases"
		set ans [tk_messageBox -default yes -detail "Download the missing $type databases now?" -icon error -message "There are missing files databases." -parent . -title "Files Database Error" -type yesnocancel]
		switch $ans {
			yes {
				puts $debug_out(2) "check_repo_files - download the missing databases"
				set action "Update Files Data"
				set wait true
				if {$type == "pkgfile"} {
					if {$su_cmd == "su -c"} {
						set command "$su_cmd \"pkgfile -u\""
					} else {
						set command "$su_cmd pkgfile -u"
					}					
				} else {
					if {$su_cmd == "su -c"} {
						set command "$su_cmd \"pacman -b $tmp_dir -Fy\""
					} else {
						set command "$su_cmd pacman -b $tmp_dir -Fy"
					}
				}
				execute_command $action $command $wait				
				if {$error != 0} {
					tk_messageBox -default ok -detail $detail -icon error -message "Files database download error" -parent . -title "Error" -type ok
					puts $debug_out(1) "check_repo_files - update files databases failed ([expr [clock milliseconds] - $start_time])"
					return 1
				}
				puts $debug_out(2) "check_repo_files - remove the warning icon"
				remove_warning_icon .filter_icons_filesync
				puts $debug_out(2) "check_repo_files - reset get_dataview"
				set dataview ""
				puts $debug_out(2) "check_repo_files - and get_dataview for $listview_current"
				get_dataview $listview_current
				puts $debug_out(1) "check_repo_files - update files databases completed ([expr [clock milliseconds] - $start_time])"
				return 2
			}
			no {
				place_warning_icon .filter_icons_filesync
				if {$type == "pacman"} {
					set pacman_files_upgrade [expr $pacman_files_upgrade + 2]
				} else {
					set pkgfile_upgrade [expr $pkgfile_upgrade + 2]
				}
				puts $debug_out(1) "check_repo_files - do not download the missing files databases (do not ask again)"
				return 1
			}
			cancel {
				puts $debug_out(1) "check_repo_files - cancel download of missing files databases"
				place_warning_icon .filter_icons_filesync
				return 3
			}
		}
	} else {
		puts $debug_out(1) "check_repo_files - no missing files databases"
		return 0
	}
}

proc clean_cache {} {

global debug_out password su_cmd win_mainx win_mainy
# clean the pacman cache keeping the last keep_versions package versions and, optionally, remove the uninstalled packages
	
	puts $debug_out(1) "clean-cache - called"
	if {[catch {exec which paccache}] == 1} {
		puts $debug_out(1) "clean-cache - failed, paccache is not installed"
		tk_messageBox -default ok -detail "Consider installing the pacman-contrib package" -icon info -message "Paccache is required to clean the package cache" -parent . -title "Cannot Clean Package Cache" -type ok
		return 1
	}

	toplevel .clean
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {288 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {120 / 2}]
	wm geometry .clean 288x120+$left+$down
	wm iconphoto .clean tools
	wm protocol .clean WM_DELETE_WINDOW {
		# assume cancel clean_cache, see button .clean.cancel
		.clean.cancel invoke
	}
	wm resizable .clean 0 0
	wm title .clean "Clean Pacman Cache"
	wm transient .clean .

# CONFIGURE CLEAN CACHE WINDOW

	label .clean.keep_label \
		-text "Number of package versions to keep"
	entry .clean.keep \
		-borderwidth 0 \
		-justify right \
		-validate key \
		-validatecommand {expr {"%P" == "0" || ([string is integer %P] && [string length %P] < 4 && [string first "0" %P] != 0)}} \
		-width 3
	.clean.keep insert 0 "3"
	# now set up a binding to remove any messages if .clean.keep value changes
	bind .clean.keep <KeyPress> {
		set_message terminal ""
	}
	label .clean.uninstalled_label \
		-text "Only target uninstalled packages"
	label .clean.yes_no \
		-anchor center \
		-background white \
		-justify center \
		-relief sunken \
		-width 3
	.clean.yes_no configure -text "no"
	# now set up a binding to toggle the value of the clean_yes_no label
	bind .clean.yes_no <ButtonRelease-1> {
		set_message terminal ""
		if {[string tolower [.clean.yes_no cget -text]] == "yes"} {
			.clean.yes_no configure -text "no"
		} else {
			.clean.yes_no configure -text "yes"
		}
	}
	
	frame .clean.buttons

		button .clean.continue \
			-command {
				set clean_uninstalled [.clean.yes_no cget -text]
				set keep_versions [.clean.keep get]
				puts $debug_out(2) "clean-cache - clean called with $keep_versions versions to keep and clean_uninstalled set to $clean_uninstalled"
				if {$keep_versions == "" || [string is integer $keep_versions] == 0} {
					# check that keep_versions is a numerical value
					puts $debug_out(2) "clean_cache - keep_versions is set to \"$keep_versions\" which is not a numerical value"
					tk_messageBox -default ok -detail "The versions to keep must be a numerical value.\nThe number of versions to keep has not been changed" -icon warning -message "Error in number of cached versions to keep" -parent . -title "Incorrect Option" -type ok 
					puts $debug_out(2) "clean_cache - reset the keep_versions value to 3"
					.clean.keep delete 0 end
					.clean.keep insert 0 "3"
				} else {
					set ans "ok"
					if {$keep_versions == 0} {
						# check that zero keep_versions is correct
						puts $debug_out(2) "clean_cache - keep_versions is set to \"$keep_versions\" is this correct"
						set ans [tk_messageBox -default cancel -detail "The versions to keep is set to zero. This will clear all packages from the package cache\nIs this correct?" -icon warning -message "Zero cached versions to keep" -parent . -title "Clear Package Cache" -type okcancel]
					}
					if {$ans == "cancel"} {
						puts $debug_out(2) "clean_cache - reset the keep_versions from zero value to 3"
						.clean.keep delete 0 end
						.clean.keep insert 0 "3"
					} else {
						if {$clean_uninstalled == "no"} {
							set args "-rk${keep_versions}"
						} else {
							set args "-ruk${keep_versions}"
						}
						puts $debug_out(2) "clean-cache - clean attempted with paccache $args"
						if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
							puts $debug_out(2) "clean_cache - called with no administrator priviledges so get a password"
							puts $debug_out(2) "clean_cache - write shell script"
							set fid [open $tmp_dir/vpacman.sh w]
							puts $fid "#!/bin/sh"
							puts $fid "password=\$1"
							if {$su_cmd == "su -c"} {
								puts $fid "echo \$password | $su_cmd \"paccache $args\" 2>$tmp_dir/errors"
							} else {
								puts $fid "echo \$password | $su_cmd -S -p \"\" paccache $args 2>$tmp_dir/errors"
							}
							puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
							close $fid
							exec chmod 0755 "$tmp_dir/vpacman.sh"
							puts $debug_out(2) "clean_cache - get a password"
							# get the password
							set password [get_password ".clean"]
							# password will be set to an error of 3 if the password procedure was cancelled
							if {$password != 3} {
								puts $debug_out(2) "clean_cache - run the script"
								set error [catch {eval [concat exec $tmp_dir/vpacman.sh $password]} result]
								# don't save the password
								unset password
								puts $debug_out(2) "clean_cache - ran vpacman.sh with error $error and result \"$result\""
							} else {
								unset password
								set error 1
								set result "Authentication failure"
								puts $debug_out(2) "clean_cache - get_password cancelled"
							}
							if {$error == 1} {
								if {[file exists $tmp_dir/errors]} {
									set fid [open $tmp_dir/errors r]
									set result [read $fid]
									close $fid
								}
								# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
								# the second error message will be displayed instead, whcih is not too bad. 								
								if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
									puts $debug_out(2) "get_terminal - Authentification failed"
									set_message terminal  "Authentication failed - clean cache cancelled. "
								} else {
									puts $debug_out(2) "clean_cache - clean cache failed"
									set_message terminal "Paccache returned an error cleaning cache"
								}
							}
							# and delete the shell script
							file delete $tmp_dir/vpacman.sh
						} else {
							set error [catch {eval [concat exec paccache $args]} result]
							if {$error != 0} {
								puts $debug_out(1) "clean_cache completed with Error $error and Result $result"
								set_message terminal "Paccache returned an error cleaning cache"
							}
						}
						if {$error == 0} {
							puts $debug_out(1) "clean_cache - completed with no errors and result $result"
							if {$result == "==> no candidate packages found for pruning"} {
								set_message terminal "No packages found for pruning"
							} else {
								set result [split $result \n]
								if {[llength $result] > 1} {set result [lindex $result [llength $result]-1]}
								set_message terminal "Cleaned cache [string range $result 14 end]"
							}
							# no errors, so delete the errors file
							file delete $tmp_dir/errors	
						}
						after 3000 {set_message terminal ""}
						grab release .clean
						destroy .clean
					}
				}
			} \
			-text "Continue" \
			-width 8
		button .clean.test \
			-command {
				puts $debug_out(1) "test clean_cache"
				set clean_uninstalled [.clean.yes_no cget -text]
				set keep_versions [.clean.keep get]
				if {$keep_versions == "" || [string is integer $keep_versions] == 0} {
					# check that keep_versions is a numerical value
					puts $debug_out(2) "clean_cache - test - keep_versions is set to \"$keep_versions\" which is not a numerical value"
					tk_messageBox -default ok -detail "The versions to keep must be a numerical value.\nThe number of versions to keep has not been changed" -icon warning -message "Error in number of cached versions to keep" -parent . -title "Incorrect Option" -type ok 
					puts $debug_out(2) "clean_cache - test - reset the keep_versions value to 3"
					.clean.keep delete 0 end
					.clean.keep insert 0 "3"
				} else {
					if {$clean_uninstalled == "no"} {
						set args "-dk${keep_versions}"
					} else {
						set args "-duk${keep_versions}"
					}
					puts $debug_out(2) "clean-cache - test clean attempted with paccache $args"
					set error [catch {eval [concat exec paccache $args]} result]
					puts $debug_out(2) "clean-cache - test clean ran with error $error and result $result"
					set_message terminal "Completed [string range $result 14 end]"
				}
			} \
			-text "Dry Run" \
			-width 8
			
		button .clean.cancel \
			-command {
				puts $debug_out(1) "clean_cache cancelled"
				set_message terminal ""
				grab release .clean
				destroy .clean
			} \
			-text "Cancel" \
			-width 8

	# Geometry management

	grid .clean.keep_label -in .clean -row 2 -column 2 \
		-sticky w
	grid .clean.keep -in .clean -row 2 -column 4 \
		-sticky e
	grid .clean.uninstalled_label -in .clean -row 3 -column 2 \
		-sticky w
	grid .clean.yes_no -in .clean -row 3 -column 4 \
		-sticky e
	grid .clean.buttons -in .clean -row 5 -column 1 \
		-columnspan 5 \
		-sticky we
		grid .clean.continue -in .clean.buttons -row 1 -column 1 \
			-sticky w
		grid .clean.test -in .clean.buttons -row 1 -column 2 
		grid .clean.cancel -in .clean.buttons -row 1 -column 3 \
			-sticky e
		
	# Resize behavior management

	grid rowconfigure .clean 1 -weight 0 -minsize 30 -pad 0
	grid rowconfigure .clean 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .clean 3 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .clean 4 -weight 0 -minsize 20 -pad 0
	grid rowconfigure .clean 5 -weight 0 -minsize 0 -pad 0

	grid columnconfigure .clean 1 -weight 0 -minsize 15 -pad 0
	grid columnconfigure .clean 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .clean 3 -weight 0 -minsize 5 -pad 0
	grid columnconfigure .clean 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .clean 5 -weight 0 -minsize 15 -pad 0
	
	grid rowconfigure .clean.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .clean.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .clean.buttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .clean.buttons 3 -weight 1 -minsize 0 -pad 0
	
	balloon_set .clean.keep_label "The number of versions of each package to keep"
	balloon_set .clean.keep "The number of versions of each package to keep"
	balloon_set .clean.uninstalled_label "Remove all versions of packages that have been uninstalled"
	balloon_set .clean.yes_no "Remove all versions of packages that have been uninstalled"
	balloon_set .clean.continue "Clean the package cache"
	balloon_set .clean.cancel "Cancel - do not clean the package cache"
	
	update
	grab set .clean
	
}

proc cleanup_checkbuttons {aur} {

global aur_only debug_out selected_list list_show_order

	puts $debug_out(1) "cleanup_checkbuttons called"

	set aur_only $aur
	puts $debug_out(1) "cleanup_checkbuttons - set selectmode to extended"
	.wp.wfone.listview configure -selectmode extended
	set selected_list 0
	grid_remove_listgroups
	.filter_list_orphans configure -text "Orphans"
	.filter_list_not_required configure -text "Not Required"
	if {$aur_only == false} {
		.menubar.edit entryconfigure 0 -state normal
		.listview_popup entryconfigure 3 -state normal
	}
	puts $debug_out(1) "cleanup_checkbuttons completed"
}

proc clock_format {time format} {

global debug_out start_time
# format a time according to the format called

	puts $debug_out(1) "clock_format called - ([expr [clock milliseconds] - $start_time])"

	switch $format {
		full {set result [clock format $time -format "%Ec"]}
		short_full {set result [clock format $time -format "[exec locale d_fmt] %R"]}
		date {set result [clock format $time -format "[string map {y Y} [exec locale d_fmt]]"]}
		short_date {set result [clock format $time -format "[exec locale d_fmt]"]}
		time {set result [clock format $time -format "%H:%M"]}
		default {set result [clock format $time -format "[exec locale d_fmt] %R"]}
	}
	puts $debug_out(1) "clock_format completed - ([expr [clock milliseconds] - $start_time])"
	return $result
}

proc configurable {} {
# Set configurable variables to sane values

global aur_all browser buttons debug_out diffprog editor geometry geometry_view helpbg helpfg icon_dir installed_colour keep_log known_browsers known_diffprogs known_editors known_terminals one_time outdated_colour save_geometry show_menu show_buttonbar start_time terminal terminal_string

	puts $debug_out(1) "configurable - set variables called - ([expr [clock milliseconds] - $start_time])"
	# initialize the browser variable to the first browser in the common browsers list which is installed
	set browser [configurable_default "browser" $known_browsers]
	if {$browser == 1} {set browser ""}
	# initialize the diffprog variable to the first compare programme in the common diffprogs list which is installed
	set diffprog [configurable_default "diffprog" $known_diffprogs]
	if {$diffprog == 1} {set diffprog ""}
	# initialize the editor variable to the first editor in the common editors list which is installed
	set editor [configurable_default "editor" $known_editors]
	if {$editor == 1} {set editor ""}
	# initialize the terminal variables to the first terminal in the known terminals which is installed
	set terminal [configurable_default "terminal" $known_terminals]
	if {$terminal == 1} {
		set terminal ""
		set terminal_string ""
	} else {
		set terminal_string [lindex $terminal 1]
		set terminal [lindex $terminal 0]
	}
	
	# do not show all aur/local packages
	set aur_all false
	# set the size of the icons used for the buttons
	set buttons medium
	# set the icon directory
	set icon_dir "/usr/share/pixmaps/vpacman"
	# set the number of months to keep when trimming the pacman log file
	set keep_log 12
	# set geometry to a sane size
	set geometry "1060x500+200+50"
	set geometry_view "750x350+225+55"
	# save the geometry - yes or no
	set save_geometry "no"
	# set colours to acceptable values
	set helpbg #EBE8E4	
	set helpfg #222222
	set installed_colour blue
	set outdated_colour red
	# set the show message one_time to false
	set one_time false
	# show the menu and/or toolbar - yes or no
	set show_menu "yes"
	set show_buttonbar "yes"
	puts $debug_out(1) "configurable - set variables completed - ([expr [clock milliseconds] - $start_time])"
}

proc configurable_default {variable list} {
# initialize a configurable variable to the first item in the known variables list which is installed
# terminal is a special case since it returns a list of two results
	
global debug_out
	
	puts $debug_out(1) "configurable_default - check default for $variable"
	if {$variable == "terminal"} {
		set terminal ""
		set terminal_string ""
		foreach {programme string} $list {
			set result [catch {exec which $programme}]
			if {$result == 0} {
				set terminal "$programme"
				set terminal_string "$programme $string"
				puts $debug_out(1) "configurable_default - terminal set to \"$terminal\" \"$terminal_string\""
				return [list $terminal $terminal_string]
			}
		}
		return 1
	} else {
		set default ""
		foreach programme $list {
			set result [catch {exec which $programme}]
			if {$result == 0} {
				set default "$programme"
				puts $debug_out(1) "configurable_default - $variable set to \"$default\""
				return $default
			}
		}
		
	}
	return 1
}

proc configure {} {

global backup_dir browser buttons config_file debug_out diffprog editor geometry geometry_config geometry_view icon_dir installed_colour keep_log known_terminals old_values outdated_colour save_geometry terminal terminal_string win_configx win_configy win_mainx win_mainy

	puts $debug_out(1) "configure called"
	
	toplevel .config
	
	get_win_geometry
	# calculate the position of the config window
	set left [expr $win_mainx + {[winfo width .] / 2} - {$win_configx / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {$win_configy / 2}]
	
	wm geometry .config $geometry_config+$left+$down
	wm iconphoto .config tools
	wm protocol .config WM_DELETE_WINDOW {
	# change the window geometry for the options window, but do not save it since the save button was not used to exit
		if {[string tolower $save_geometry] == "yes"} {set geometry_config "[winfo width .config]x[winfo height .config]"}
		# reload the previous configuration settings and release the grab, see button .config.cancel
		.config.cancel invoke
	}
	wm resizable .config 1 1
	wm title .config "Options"
	wm transient .config .

	# update the geometry (if necessary) for the main window
	if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]}
	# and save all the values in case we need to reverse them later
	set old_values ""
	lappend old_values $buttons $browser $diffprog $editor $geometry $geometry_config $save_geometry $terminal $terminal_string $installed_colour $outdated_colour $icon_dir $keep_log
	
	# get the possible terminal values
	set count 0
	set tlist1 ""
	set tlist2 ""
	while {$count < [llength $known_terminals]} {
		lappend tlist1 [lindex $known_terminals $count]
		incr count
		lappend tlist2 [lindex $known_terminals $count]
		incr count
	}
	puts $debug_out(2) "configure - Known terminals $tlist1"
	puts $debug_out(2) "configure - Known terminal strings $tlist2"
	puts $debug_out(2) "configure - Current terminal is $terminal - current terminal string is $terminal_string"

# CONFIGURE OPTIONS WINDOW

	label .config.browser_label \
		-text "Browser"
	entry .config.browser \
		-textvariable browser
	label .config.diffprog_label \
		-text "Compare Files"
	entry .config.diffprog \
		-textvariable diffprog
	label .config.editor_label \
		-text "Editor"
	entry .config.editor \
		-textvariable editor
	label .config.save_label \
		-text "Save Window Position"
	label .config.yes_no \
		-anchor w \
		-background white \
		-relief sunken \
		-textvariable save_geometry \
		-width 3
	# now set up a binding to toggle the value of the save_geometry variable
				bind .config.yes_no <ButtonRelease-1> {
		if {[string tolower $save_geometry] == "yes"} {
			set save_geometry "no"
		} else {
			set save_geometry "yes"
		}
	}
	label .config.terminal_label \
		-text "Terminal"
		
	# now set up a ttk::combobox to match the rest of the window
	# it would be better to pick a theme colour, but how?
	set background_colour "#FDFDFD"
	# set background_colour [ttk::style lookup TCombobox -background active]
	set foreground_colour [ttk::style lookup TCombobox -foreground active]
	puts $debug_out(2) "configure - Background colour for normal Combobox is $background_colour"
	puts $debug_out(2) "configure - Foreground colour for normal Combobox is $foreground_colour"
	# changes the readonly background of the value field
	ttk::style map TCombobox -fieldbackground "readonly $background_colour"
	# changes the background colour of the selected value
	ttk::style configure TCombobox -selectbackground #C3C3C3
	# changes the foreground colour of the selected value
	ttk::style configure TCombobox -selectforeground $foreground_colour	
	# FYI changes the background colour of the drop down arrow
	# ttk::style map TCombobox -background {readonly yellow}
	# the above is pretty close but the selected font remains bold. It may be better to write a new combobox (see list_groups)
		
	ttk::combobox .config.terminal \
		-state normal \
		-textvariable terminal \
		-values $tlist1 
	# and set up bindings for when the value of the combobox changes
	bind .config.terminal <Return> {
		# don't get the terminal string if it already exists
		if {[string first $terminal $terminal_string] == 0} {break}
		set terminal_string [get_terminal_string $terminal]
	}
	bind .config.terminal <FocusOut> {
		# don't get the terminal string if it already exists
		if {[string first $terminal $terminal_string] == 0} {break}
		set terminal_string [get_terminal_string $terminal]
	}
	bind .config.terminal <<ComboboxSelected>> {
		# don't get the terminal string if it already exists
		if {[string first $terminal $terminal_string] == 0} {break}
		set terminal_string [get_terminal_string $terminal]
	}
	label .config.terminal_string_label \
		-text "Terminal String"
	entry .config.terminal_string \
		-textvariable terminal_string	
	label .config.button_label \
		-text "Toolbar Size"
	label .config.buttons \
		-anchor w \
		-background white \
		-relief sunken \
		-textvariable buttons \
		-width 6
	# now set up a binding to toggle the value of the buttons variable
	bind .config.buttons <ButtonRelease-1> {
		if {[string tolower $buttons] == "medium"} {
			set buttons "small"
		} else {
			set buttons "medium"
		}
	}

	label .config.installed_label \
		-text "Installed colour"
	entry .config.installed_colour \
		-textvariable installed_colour
	label .config.outdated_label \
		-text "Updates colour"
	entry .config.outdated_colour \
		-textvariable outdated_colour
	button .config.edit_file \
		-command {
			# set up a command to edit the config file with the chosen editor
			set action "Edit Vpacman Options"
			set command "$editor $config_file"
			# set wait to false, otherwise a GUI editor window will drop back to the terminal
			set wait false
			execute_command $action $command $wait
			# no matter what the return code is but it may be the configuration file has been edited
			get_configs
		} \
		-text "Edit the Options File"
	button .config.reset \
		-command {
			# are you sure?
			set ans [tk_messageBox -default cancel -detail "Are you sure?" -icon warning -message "Reset all options to their default values" -parent .config -title "Warning" -type okcancel]
			if {$ans == "ok"} {
				configurable
				wm geometry . $geometry
				get_win_geometry
				set left [expr $win_mainx + {[winfo width .] / 2} - {$win_configx / 2}]
				set down [expr $win_mainy + {[winfo height .] / 2} - {$win_configy / 2}]
				wm geometry .config $geometry_config+$left+$down
			}
		} \
		-text "Reset"
	button .config.save \
		-command {
			#check the entries before saving:
			puts $debug_out(2) "configure - test results"
			set tests 0
			if {$browser != "" && [catch {exec which $browser}] == 1} {
				puts $debug_out(2) "configure - browser $browser is not installed"
				tk_messageBox -default ok -detail "\"$browser\" is not installed" -icon warning -message "Choose a different browser" -parent . -title "Incorrect Option" -type ok 
				focus .config.browser
				set tests 1
			}
			if {$diffprog != "" && [catch {exec which $diffprog}] == 1} {
				puts $debug_out(2) "configure - compare programme $diffprog is not installed"
				tk_messageBox -default ok -detail "\"$diffprog\" is not installed" -icon warning -message "Choose a different programme to compare files" -parent . -title "Incorrect Option" -type ok 
				focus .config.diffprog
				set tests 1
			}
			if {$editor != "" && [catch {exec which [lindex $editor 0]}] == 1} {
				puts $debug_out(2) "configure - editor $editor is not installed"
				tk_messageBox -default ok -detail "\"[lindex $editor 0]\" is not installed" -icon warning -message "Choose a different editor" -parent . -title "Incorrect Option" -type ok 
				focus .config.editor
				set tests 1
			}
			if {[catch {exec which $terminal}] == 1} {
				puts $debug_out(2) "configure - terminal \"$terminal\" is either blank or not installed"
				if {$terminal == ""} {set detail "No terminal is installed"} else {set detail "\"$terminal\" is not installed"}
				tk_messageBox -default ok -detail "$detail" -icon warning -message "Choose a different terminal" -parent . -title "Incorrect Option" -type ok 
				focus .config.terminal
				.config.terminal icursor 0
				set tests 1
			}
			if {$terminal != ""} {
				if {[string first "<title>" $terminal_string] == -1} {
					puts $debug_out(2) "configure - invalid terminal string (\<title\>)"
					tk_messageBox -default ok -detail "The terminal string must include provision for a window title. Use the string <title> to indicate its position in the string. Look at the examples of known terminal strings by selecting a terminal from the drop down list." -icon warning -message "\"$terminal_string\" has no title" -parent . -title "Incorrect Option" -type ok 
					focus .config.terminal_string
					set tests 1
				}
				if {[string first "<command>" $terminal_string] == -1} {
					puts $debug_out(2) "configure - invalid terminal string (\<command\>)"
					tk_messageBox -default ok -detail "The terminal string must include provision for a command to execute. Use the string <command> to indicate its position in the string. Look at the examples of known terminal strings by selecting a terminal from the drop down list."  -icon warning -message "\"$terminal_string\" has no command" -parent . -title "Incorrect Option" -type ok 
					focus .config.terminal_string
					set tests 1
				}
			}
			if {[lsearch $colours $installed_colour] == -1 && [regexp -indices ^#\[A-Fa-f0-9\]\{6\}$ $installed_colour] == 0} {
				puts $debug_out(2) "configure - invalid installed colour ($installed_colour)"
				tk_messageBox -default ok -detail "\"$installed_colour\" is not a recognised colour" -icon warning -message "Choose a different colour for the installed packages" -parent . -title "Incorrect Option" -type ok 
				focus .config.installed_colour
				set tests 1
			}
			if {[lsearch $colours $outdated_colour] == -1 && [regexp -indices ^#\[A-Fa-f0-9\]\{6\}$ $outdated_colour] == 0} {
				puts $debug_out(2) "configure - invalid outdated colour ($outdated_colour)"
				tk_messageBox -default ok -detail "\"$outdated_colour\" is not a recognised colour" -icon warning -message "Choose a different colour for the updates" -parent . -title "Incorrect Option" -type ok 
				focus .config.outdated_colour
				set tests 1
			}
			if {$icon_dir != [lindex $old_values 11]} {
				# reload the images for the button bar
				puts $debug_out(2) "configure - the icon location \"$icon_dir\" has changed, previous directory was \"[lindex $old_values 11]\""
				if {[set_images] != 0} {
					tk_messageBox -default ok -detail "\"$icon_dir\" does not exist or does not contain all the required icons\nThe icon directory has not been changed" -icon warning -message "Error in icon directory" -parent . -title "Incorrect Option" -type ok 
					# reset the icon_directory and the images
					puts $debug_out(1) "configure - reset the icon directory to \"[lindex $old_values 11]\" and reload the images"
					set icon_dir [lindex $old_values 11]
					set_images
				}
			}
			if {$keep_log == "" || ![string is integer $keep_log] || [string length $keep_log] > 3} {
				# check that keep_log is a numerical value and less than four characters long
				puts $debug_out(2) "configure - keep_log is set to $keep_log which is either not a numerical value or too long"
				tk_messageBox -default ok -detail "The months to keep must be a numerical value between 0 and 999.\nThe number of months to keep has not been changed" -icon warning -message "Error in months to keep the log" -parent . -title "Incorrect Option" -type ok 
				# reset keep_log
				puts $debug_out(2) "configure - reset the keep_log value to \"[lindex $old_values 12]\""
				set keep_log [lindex $old_values 12]
			}
			if {$buttons != [lindex $old_values 0]} {
				# reload the images for the button bar
				puts $debug_out(2) "configure - the button size has changed"
				set_images
			}
			if {$tests == 0} {
				puts $debug_out(2) "configure - All tests have passed so save configuration options"
				# now save the current geometry of the main window
				if {[string tolower $save_geometry] == "yes"} {set geometry_config "[winfo width .config]x[winfo height .config]"}
				put_configs
				.wp.wfone.listview tag configure installed -foreground $installed_colour
				.wp.wfone.listview tag configure outdated -foreground $outdated_colour
				filter
				puts $debug_out(1) "configure completed"
				grab release .config
				destroy .config
			}
		} \
		-text "Save"
	button .config.cancel \
		-command {
			set new_values ""
			lappend new_values $buttons $browser $editor $geometry $geometry_config $save_geometry $terminal $terminal_string $installed_colour $outdated_colour
			if {$old_values != $new_values} {
			# to cancel the updates we need to reset all the options to their old values
				set buttons [lindex $old_values 0]
				set browser [lindex $old_values 1] 
				set diffprog [lindex $old_values 2] 
				set editor [lindex $old_values 3]
				set geometry [lindex $old_values 4]
				set geometry_config [lindex $old_values 5]
				set save_geometry [lindex $old_values 6]
				set terminal [lindex $old_values 7]
				set terminal_string [lindex $old_values 8]
				set installed_colour [lindex $old_values 9]
				set outdated_colour [lindex $old_values 10]
			# reset the windows to their original sizes
				wm geometry . $geometry
				get_win_geometry
				set left [expr $win_mainx + {[winfo width .] / 2} - {$win_configx / 2}]
				set down [expr $win_mainy + {[winfo height .] / 2} - {$win_configy / 2}]
				wm geometry .config $geometry_config+$left+$down
			} 
			puts $debug_out(1) "configure cancelled"
			grab release .config
			destroy .config
		} \
		-text "Cancel"

	# Geometry management

	grid .config.browser_label -in .config -row 2 -column 1 \
		-sticky w
	grid .config.browser -in .config -row 2 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.diffprog_label -in .config -row 3 -column 1 \
		-sticky w
	grid .config.diffprog -in .config -row 3 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.editor_label -in .config -row 4 -column 1 \
		-sticky w
	grid .config.editor -in .config -row 4 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.save_label -in .config -row 5 -column 1 \
		-sticky w
	grid .config.yes_no -in .config -row 5 -column 2 \
		-sticky w
	grid .config.terminal_label -in .config -row 6 -column 1 \
		-sticky w
	grid .config.terminal -in .config -row 6 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.terminal_string_label -in .config -row 7 -column 1 \
		-sticky w
	grid .config.terminal_string -in .config -row 7 -column 2 \
		-columnspan 4 \
		-sticky we	
	grid .config.button_label -in .config -row 8 -column 1 \
		-sticky w
	grid .config.buttons -in .config -row 8 -column 2 \
		-columnspan 2 \
		-sticky w
	grid .config.installed_label -in .config -row 9 -column 1 \
		-sticky w
	grid .config.installed_colour -in .config -row 9 -column 2 \
		-sticky w
	grid .config.outdated_label -in .config -row 10 -column 1 \
		-sticky w
	grid .config.outdated_colour -in .config -row 10 -column 2 \
		-sticky w
	if {$editor != ""} {
		grid .config.edit_file -in .config -row 12 -column 1
	}
	grid .config.reset -in .config -row 12 -column 3
	grid .config.save -in .config -row 12 -column 4
	grid .config.cancel -in .config -row 12 -column 5
		
	# Resize behavior management

	grid rowconfigure .config 1 -weight 0 -minsize 20 -pad 0
	grid rowconfigure .config 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 3 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 5 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 6 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 7 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 8 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 9 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 10 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 11 -weight 0 -minsize 20 -pad 0
	grid rowconfigure .config 12 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 13 -weight 0 -minsize 10 -pad 0

	grid columnconfigure .config 1 -weight 0 -minsize 30 -pad 0
	grid columnconfigure .config 2 -weight 1 -minsize 30 -pad 0
	grid columnconfigure .config 3 -weight 0 -minsize 30 -pad 0
	grid columnconfigure .config 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .config 5 -weight 0 -minsize 0 -pad 0
	
	balloon_set .config.browser_label "Enter the name of an installed browser to use"
	balloon_set .config.browser "Enter the name of an installed browser to use"
	balloon_set .config.editor_label "Enter the string to call an installed editor to use\n(It may be necessary to disable server mode\nexample: mousepad -disable-server)"
	balloon_set .config.editor "Enter the string to call an installed editor to use\n(It may be necessary to disable server mode\nexample: mousepad -disable-server)"
	balloon_set .config.save_label "Should the window geometry be saved"
	balloon_set .config.yes_no "Should the window geometry be saved"
	balloon_set .config.terminal_label "Enter the name of an installed terminal to use\n(Can be selected from the drop down list)"
	balloon_set .config.terminal "Enter the name of an installed terminal to use\n(Can be selected from the drop down list)"
	balloon_set .config.terminal_string_label "The string to use to call a terminal session\n(Must include <title> to indicate the window title\nand <command> for the command to be run)"
	balloon_set .config.terminal_string "The string to use to call a terminal session\n(Must include <title> to indicate the window title\nand <command> for the command to be run)"
	balloon_set .config.button_label "Use medium or small buttons in the toolbar"
	balloon_set .config.buttons "Use medium or small buttons in the toolbar"
	balloon_set .config.installed_label "The colour used to indicate installed packages"
	balloon_set .config.installed_colour "The colour used to indicate installed packages"
	balloon_set .config.outdated_label "The colour used to indicate outdated packages"
	balloon_set .config.outdated_colour "The colour used to indicate outdated packages"
	balloon_set .config.edit_file "Directly edit the options file"
	balloon_set .config.reset "Reset all settings to default values"
	balloon_set .config.save "Save settings"
	balloon_set .config.cancel "Cancel without saving"

	update
	grab set .config
	
}

proc count_lists {} {

global count_all count_installed count_outdated count_uninstalled debug_out list_all list_installed list_local list_outdated list_uninstalled start_time
# returns the count of all the lists 	

	puts $debug_out(1) "count_lists called - ([expr [clock milliseconds] - $start_time])"
	set count_all 0
	set count_installed 0
	set count_outdated 0
	set count_uninstalled 0
	set count_all [llength $list_all]	
	set count_installed [expr [llength $list_installed]	 + [llength $list_local]]
	set count_outdated [llength $list_outdated]
	set count_uninstalled [llength $list_uninstalled]	
	puts $debug_out(2) "count_lists completed - All $count_all, Installed $count_installed, Outdated $count_outdated, Installed $count_installed"
	puts $debug_out(1) "count_lists completed - ([expr [clock milliseconds] - $start_time])"
}

proc execute {type} {

global aur_only aur_updates aur_versions aur_versions_TID clock_id dbpath debug_out dlprog filter groups listview_last_selected listview_selected listview_selected_in_order list_local list_show list_outdated package_actions part_upgrade selected_list su_cmd sync_time system_test terminal_string thread threads tmp_dir upgrades
# runs whatever we need to do in a terminal window

# known types are delete, install, sync and upgrade_all
# called from buttonbar, popup menu and menu options, and by system_upgrade

	puts $debug_out(1) "execute - called for $type - upgrades are \"$upgrades\""
	# reload listview_selected in case treeview select has not yet run
	set listview_selected [.wp.wfone.listview selection]
	# catch any errors in the install/delete settings	
	if {($type == "install" || $type == "delete") && $listview_selected == ""} {
		puts $debug_out(2) "execute - no packages selected return error"
		set ans [tk_messageBox -default ok -detail "No packages have been selected - cannot continue with $type." -icon warning -message "No packages selected." -parent . -title "Warning" -type ok]
		return 1
	}
	if {$type == "install" && $upgrades != ""} {
		set unstable_text ""
		set install_text "will be re-installed."
		if {$system_test == "unstable"} {
			set unstable_text "Warning: the system is unstable, "
			set install_text "may be upgraded. Continue at your own risk."
		}
		puts $debug_out(2) "execute - the system is $system_test, this looks like a partial upgrade"
		set ans [tk_messageBox -default no -detail "$unstable_text\"$upgrades\" $install_text\n\n         Answer Yes to continue.\n         Answer No to start a new selection.\n\nTo upgrade, select Full System Upgrade from the menus." -icon warning -message "Partial upgrades are not supported." -parent . -title "Warning" -type yesno]
		puts $debug_out(2) "execute install - answer to partial upgrade package warning message is $ans" 
		switch $ans {
			yes {
				# if the response is yes, then continue.
				puts $debug_out(2) "execute install - continue"
			}
			no {
				# if the response is no, then unselect everything and break out of the foreach loop.
				# remove anything shown in .wp.wftwo.dataview
				all_clear
				puts $debug_out(2) "execute install - do not continue, return error"
				return 1
			}	
		}
	}
	set count_selected [llength $listview_selected]
		
	# Install, Upgrade all and Sync will need an internet connection
	if {$type == "install" || $type == "upgrade_all" || $type == "sync"} {
		puts $debug_out(2) "execute - install/upgrade_all/sync called test_internet"
		if {[test_internet] != 0} {return 1}
	}
	
	# make a list of all the selected packages and check if any local packages are included in the list
	set list ""
	set aur false
	foreach item $listview_selected {
		lappend list [lrange [.wp.wfone.listview item $item -values] 1 1]
		if {[lrange [.wp.wfone.listview item $item -values] 0 0] == "local"} {
			puts $debug_out(2) "execute - the selected list includes a local package"
			set aur true
		}
	}
	
	set logfile [find_pacman_config logfile]
	set logfid [open $logfile r]
	seek $logfid +0 end
	puts $debug_out(2) "execute - opened the pacman logfile ($logfile) and moved to the end of the file"

	if {$type == "install"} {
		set action "Pacman Install/Upgrade packages"
		set command "$su_cmd pacman -S $list"
		if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -S $list\""}
	} elseif {$type == "upgrade_all"} {
		set upgrade_list ""
		foreach line $list_show {
			set element ""
			set name [lindex $line 1]
			set upgrade_list [concat $upgrade_list $name]
		}
		puts $debug_out(2) "execute - upgrade_all called for $upgrade_list"
		set action "Pacman Full System Upgrade"
		set command "$su_cmd pacman -Syu"
		if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -Syu\""}
	} elseif {$type == "delete"} {
		set action "Pacman Delete packages"
		set command "$su_cmd pacman -R $list"
		if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -R $list\""}
	} elseif {$type == "sync"} {
		set action "Pacman Synchronize database"
		set command "$su_cmd pacman -b $tmp_dir -Sy"
		if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Sy\""}
	} else {
		puts $debug_out(1) "execute - returned error for $type"
		return 1
	}

	# stop the clock if necessary	
	if {$type == "sync" || $type == "upgrade_all"} {
		puts $debug_out(2) "execute - cancel clock updates"
		after cancel $clock_id
		puts $debug_out(2) "execute - current after commands \"[after info]\""
	}
	
	puts $debug_out(2) "execute - call execute_command with $action $command true"
	execute_command "$action" "$command" "true"	
	# did we see any errors
	if {[file exists $tmp_dir/errors]} {
		set fid [open $tmp_dir/errors r]
		set errorinfo [read $fid]
		close $fid
		file delete $tmp_dir/errors
		puts $debug_out(2) "execute - read error file, the error file text was:\n$errorinfo"
		if {[string first "error 1" $errorinfo] != -1} {
			puts $debug_out(2) "execute - script aborted"
			return 1
		}
		# check the output found - only works if it is in English
		# check for lock files
		set lck_dir $dbpath
		if {$type == "sync"} {set lck_dir ${tmp_dir}/}
		if {[file exists ${lck_dir}db.lck]} {
			# silently copy the lock file to the clipboard
			clipboard append ${lck_dir}db.lck
			tk_messageBox -message "Unable to lock database" -detail "If you're sure a package manager is not already\nrunning, you can remove ${lck_dir}db.lck" -icon error -title "Sync - Update Failed" -type ok
			return 1
		# language - this error is restricted to English but we can ignore it at present.
		# the error was reported in the terminal, the message only shows one solution
		} elseif {[string first "error: target not found:" $errorinfo] != -1} {
			# cannot get "target not found" if the database is locked, so use if elseif to check if database is locked first
			tk_messageBox -message "Target not found" -detail "Run Full System Update to update the live database and then try again." -icon error -title "Install Failed" -type ok
		} 
	}
	# try and find out what happened by reading the new entries in the log file
	# it seems that the logfile takes a while to be written, so we may need to pause here to allow the writes to complete
	# we need a short delay to complete writing the logfile so ...
	if {$type == "install" || $type == "upgrade_all" || $type == "delete"} {after 500}
	set logtext [read $logfid]
	close $logfid
	puts $debug_out(2) "execute - completed and logged these events:"
	puts $debug_out(2) "$logtext"
	
	# now work out what we did
	set count_syncs 0
	set count_upgrades 0
	set list_upgrades ""
	set count_installs 0
	set count_reinstalls 0
	set count_deletes 0
	foreach line [split $logtext \n] {
		if {[string first "\[PACMAN\] synchronizing package lists" $line] != -1} {
			incr count_syncs
		} elseif {[string first "\[ALPM\] upgraded" $line] != -1} {
			# check which packages were upgraded
			if {$type == "upgrade_all"} {
				set from [expr [string first "\[ALPM\] upgraded" $line] + 16]
				set to [expr [string first " " $line $from] - 1]
				set list_upgrades [concat $list_upgrades [string range $line $from $to]]
			}
			incr count_upgrades
		} elseif {[string first "\[ALPM\] installed" $line] != -1} {
			incr count_installs
		} elseif {[string first "\[ALPM\] reinstalled" $line] != -1} {
			incr count_reinstalls
		} elseif {[string first "\[ALPM\] removed" $line] != -1} {
			incr count_deletes
		}
	}

	puts $debug_out(2) "execute - Synced $count_syncs, Upgraded $count_upgrades, Installed $count_installs, Reinstalled $count_reinstalls, Deleted $count_deletes"	
	
	if {[expr $count_syncs + $count_upgrades + $count_installs + $count_reinstalls + $count_deletes] != 0} {
		# something happened so ...
		# remove any saved selections.
		.wp.wfone.listview selection remove [.wp.wfone.listview selection]
		set listview_selected ""
		set listview_selected_in_order ""
		# now delete the contents from  listview, we do this now because otherwise we have to look at the wrong
		# contents until proc start or list_show completes
		.wp.wfone.listview delete [.wp.wfone.listview children {}]
		# and also delete the contents of dataview, it will be repopulated later
		puts $debug_out(2) "execute - remove contents of dataview"
		get_dataview ""
		update
	}

	# and decide what is necessary to do 
	set action_message ""
	set error 0
	set lf ""
	set restart false
	if {$type == "install"} {
		if {[expr $count_installs + $count_reinstalls + $count_upgrades] > 0} {
			# something was installed or upgraded
			if {[expr $count_installs + $count_reinstalls + $count_upgrades] >= $count_selected} {
				puts $debug_out(2) "\tInstall succeeded"
			} else {
				puts $debug_out(2) "\tInstall failed, $count_selected packages were selected but only [expr $count_installs + $count_reinstalls + $count_upgrades] were installed"
			}
			# the local database will still be up to date
			# if we only did a reinstall then there is nothing to do
			if {[expr $count_installs + $count_upgrades] != 0} {
				# the counts and lists will need to be updated
				set restart true
			}
			# we ran an install, not an upgrade_all; check if we really did one or more upgrades
			if {$count_upgrades != 0} {
				# looks like a partial upgrade which means we are out of sync
				set upgrade_text "packages were"
				if {$count_upgrades == 1} {set upgrade_text "package was"}
				set action_message "$count_upgrades $upgrade_text upgraded.\nPartial upgrades are not supported. Consider running Full System Upgrade from the menus."
				set lf "\n"
			}
		} else {
			set error 1
			puts $debug_out(2) "\tInstall failed, nothing was done"
			# nothing happened so there is nothing else to do
		}
	} elseif {$type == "upgrade_all"} {
		# get the last time that the real database was updated and show it
		# this does not mean that the update was successful since it may have failed after the sync time 
		puts $debug_out(2) "execute - found the following successful upgrades \"[lsort $list_upgrades]\""
		puts $debug_out(2) "execute - the upgrade list requested was $upgrade_list"
		# see if all the upgrades expected were upgraded
		set check_upgrade_list 0
		foreach item $upgrade_list {
			if {[lsearch $list_upgrades $item] != -1} {incr check_upgrade_list}
		}
		puts $debug_out(2) "execute - upgrade_all - $check_upgrade_list packages from [llength $upgrade_list] were upgraded."
		# were any packages omitted? (It could be that more packages were updated than expected)
		set omitted [expr [llength $upgrade_list] - $check_upgrade_list]
		puts $debug_out(2) "execute - upgrade_all - $omitted packages were omitted"
		# are there any packages ignored?
		# the ignored list from find_pacman_config is calculated from the pacman configuration file
		set ignored_packages [find_pacman_config all_ignored]
		set ignores [llength $ignored_packages]
		puts $debug_out(2) "execute - upgrade_all - $ignores are set to ignore in the pacman config file"
		# if the packages omitted are not simply the ignored packages, then check a bit further
		if {$ignores != $omitted} {
			puts $debug_out(2) "execute - upgrade_all - there are further possible errors in the upgrade."
			# we can check whether there are only ignored packages in the actual upgrade list
			# this eliminates any errors if additional, unexpected, packages were upgraded
			set ignores 0
			set outdated ""
			# pacman -Qu returns an error if there are no updates found
			set error [catch {exec pacman -Qqu} outdated]
			if {$error == 0} {
				# there are still outdated packages in the live database
				set outdated [split $outdated \n]
			}
			# lets see if the packages that are still out of date after the full system upgrade are simply the ignored packages
			foreach item $outdated {
				if {[string first $item $ignored_packages] != -1} {incr ignores}
			}
			puts $debug_out(2) "execute - upgrade_all - reset $ignores package updates ignored in the pacman config file"
		}
		# so if the number of packages ignored plus the items upgraded equals the number of packages expected then the upgrade completed as expected
		if {[expr $check_upgrade_list + $ignores] == [llength $upgrade_list]} {
			puts $debug_out(2) "execute - upgrade_all succeeded"
			# we must have done a sync so set the sync time and the update time
			set times [get_sync_time]
			set sync_time [lindex $times 0]
			set update_time [lindex $times 1]
			.filter_upgrade configure -text [clock_format $update_time short_full]
			# remove any warning label and show the change immediately
			remove_warning_icon .filter_icons_warning
			update
			# if packages were ignored then the system could be unstable
			if {$ignores != 0} {
				set action_message "Full System Upgrade succeeded but $ignores packages were ignored. The system may now be unstable."
			}
			# if no upgrades were needed then do not call restart
			if {[llength $upgrade_list] != 0} {
				# the counts and lists will need to be updated
				set restart true
			}
		} else {
			# if the upgrade_all failed then check the actual result
			set error 1
			puts $debug_out(2) "execute - upgrade_all failed"
			# if the sync database was updated then we are out of sync
			if {$count_syncs != 0} {
				set upgrade_text "packages were"
				if {$count_upgrades == 1} {set upgrade_text "package was"}
				set selected_text "upgrades were"
				if {$count_selected == 1} {set selected_text "upgrade was"}
				set action_message "$count_upgrades $upgrade_text upgraded, but $count_selected $selected_text selected. The system may now be unstable.\nConsider running a Full System Upgrade."
				set lf "\n"
				set restart true
				# set the warning label and show the change immediately
				place_warning_icon .filter_icons_warning
				update
			}
		}
	} elseif {$type == "delete"} {
		puts $debug_out(2) "execute - $type was called for $count_selected packages and $count_deletes were deleted"
		if {$count_deletes != 0} {
			# check that a configured programme was not deleted
			test_configs
			# the local database will still be up to date
			# the counts and lists will need to be updated
			set restart true
		}
		# were all, some or none of the deletes made
		if {$count_deletes == $count_selected} {
			puts $debug_out(2) "\tDeletes succeeded"
		} elseif {$count_deletes != 0} {
			set error 1
			puts $debug_out(2) "\tSome deletes failed"
		} else {
			set error 1
			puts $debug_out(2) "\tDeletes failed"
			# nothing happened so there is nothing to do
		}
	} elseif {$type == "sync"} {
		# temporary database sync - restart
		set restart true
		if {$count_syncs >= 1} {
			puts $debug_out(2) "\tSync succeeded"
			# set the sync time
			set sync_time [lindex [get_sync_time] 0]		 
		} else {
			set error 1
			puts $debug_out(2) "\tSync failed"
		}
	}
	# restart the clock if necessary,  but do not test for resync for the first run	
	if {$type == "sync" || $type == "upgrade_all"} {
		puts $debug_out(2) "execute - restart clock updates (no resync test)"
		set_clock false
	}
	# set any reminders about actions needed for certain packages
	if {$action_message != ""} {set lf "\n"}

	# count how many .pacnew files were created
	set pacnews [llength [regexp -all -inline ".pacnew" $logtext]]
	# if there is only one .pacnew and it is pacman-mirrorlist, then set pacnews 0
	if {$pacnews == 1 && [string first "\[ALPM\] upgraded pacman-mirrorlist" $logtext] != -1} {set pacnews 0}

	foreach {package action} $package_actions {
		if {[string first " upgraded $package " $logtext] != -1 || [string first " reinstalled $package " $logtext] != -1} {
			set action_message [append action_message $lf $action]
			set lf "\n"
		} elseif {($package == ".pacnew" && $pacnews != 0) || $package == ".pacsave"} {
			if {[string first "$package" $logtext] != -1} {
				set action_message [append action_message $lf $action]
				set lf "\n"
			}
		}
	}
	if {$action_message != ""} {
		tk_messageBox -default ok -detail "$action_message" -icon info -message "Further action may be required" -parent . -title "Further Action" -type ok
	} else {
		puts $debug_out(2) "execute - No package actions required"
	}
		
	# see if pacman-mirrorlist has been upgraded
	if {[string first "\[ALPM\] upgraded pacman-mirrorlist" $logtext] != -1} {
		set ans [tk_messageBox -default yes -detail "Do you want to update pacman mirrorlist now?\n\nTo update the mirrorlist later run Tools > Update Mirrorlist" -icon info -message "pacman-mirrorlist has been upgraded" -parent . -title "Update Mirrorlist" -type yesno]
		if {$ans == "yes"} {
			mirrorlist_update
			tkwait window .update_mirrors
		} 
	}

	update
	# if we have just run sync or update_all then we are already up to date, if not set_clock will call test_resync in 60 seconds
	# now update all the lists if we need to

	if {$restart} {
		puts $debug_out(2) "execute - called the start procedure"
		# call start
		start
		# do not run the thread if aur_only is true
		if {!$aur_only && $threads} {
			puts $debug_out(2) "execute - restart (threads) called test_internet"
			if {[test_internet] == 0} {
				# and run the aur_versions thread to get the current aur_versions
				# this thread may conflict with get_aur_updates so mark it running
				set thread "running"
				puts $debug_out(2) "execute - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local"
				thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
			}
		} else {
			puts $debug_out(2) "execute - cannot call aur_versions thread - threading not available - call get_aur_updates"
			set aur_versions ""
			get_aur_updates
		}
		puts $debug_out(2) "execute - completed the start procedure"
		
		# selected_list is the list selection. If it is 0 then just run filter
		if {$selected_list == 0} {
			# get_aur_updates left aur_local set to true
			set aur_only false
			puts $debug_out(2) "execute - now run the filter for \"all\""
			# if we needed to run get_aur_updates the filter will have been set to aur 
			set filter "all"
			filter
		} else {
			puts $debug_out(2) "execute - now run the filter_checkbutton for \"$selected_list\""
			# selected_list is not 0 so run the required filter(_checkbutton)
			switch $selected_list {
				"orphans" {
					filter_checkbutton ".filter_list_orphans" "pacman -b $tmp_dir -Qdtq" "Orphans"
				}
				"not_required" {
					filter_checkbutton ".filter_list_not_required" "pacman -b $tmp_dir -Qtq" "Not Required"
				}
				"aur_updates" {
					# are we running this twice?   will return if aur_versions is not blank
					get_aur_updates
				}
			}
		}
		puts $debug_out(2) "execute - completed the necessary filter procedure"
	} else {
	# otherwise just reset any message and run filter
		puts $debug_out(2) "execute - restart not required"
		set_message reset ""
		puts $debug_out(2) "execute - call filter"
		filter
	}
	if {$error != 0} {
		puts $debug_out(1) "execute - failed, return error"
		return 1
	}
	puts $debug_out(1) "execute - completed"
	return 0
}

proc execute_command {action command wait} {
	
global clock_id debug_out su_cmd terminal_string tmp_dir
# runs a specific command in a terminal window

	puts $debug_out(1) "execute_command - called for \"$action\", \"$command\" with wait set to $wait"
	# tidy up any leftover files (which should not exist)
	puts $debug_out(2) "execute_command - delete $tmp_dir/vpacman.sh if it exists"
	file delete "$tmp_dir/vpacman.sh"
	
	# now start the terminal session
	
	puts $debug_out(2) "execute_command - write new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	# trap any general error, interrupt or terminate and generate an error 1 code in the error file
	# add the error code to the end of the errors file
	puts $fid "trap 'echo \"\nerror 1\n\" >> $tmp_dir/errors; exit 1' 1 2 15"
	if {$su_cmd != ""} {
		puts $fid "echo -e \"$ [string map {\" \\"} $command] \n\""
	} else {
		puts $fid "echo -e \"# $ [string map {\" \\"} $command] \n\""
	}
	# now run the command - but send all the output to the terminal AND send any errors to the error file which can be analysed later if necessary
	# tee will overwrite any existing error file without the -a flag
	puts $fid "$command > /dev/tty 2>&1 | tee $tmp_dir/errors"
	if {$wait} {
		puts $fid "pid=\"$!\""
		puts $fid "wait \$pid"
		puts $fid "echo -ne \"\n[lrange $action 0 0] finished, press ENTER to close the terminal.\""
		puts $fid "read ans"
	}
	puts $fid "exit" 
	close $fid
	
	puts $debug_out(2) "execute_command - change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out(2) "execute_command - set_message called - type terminal, \"TERMINAL OPENED to run $action\""
	set_message terminal "TERMINAL OPENED to run $action"
	# stop the exit button working while the terminal is opened
	set_wmdel_protocol noexit
	update idletasks
	puts $debug_out(2) "execute_command - now run [concat exec $execute_string &]"
	eval [concat exec $execute_string &]
	# wait for the terminal to open
	execute_terminal_isopen $action
	puts $debug_out(2) "execute_command - command started in terminal"
	# place a grab on something unimportant to avoid random button presses on the window
	grab set .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> "catch {exec wmctrl -R \"$action\"}"
	update idletasks
	puts $debug_out(2) "execute_command - set grab on .buttonbar.label_message"
	# wait for the terminal to close
	execute_terminal_isclosed $action "Vpacman"
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out(2) "execute_command - grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out(2) "execute_command - window manager delete window re-instated"
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	puts $debug_out(2) "execute_command - wait for error file to be written and closed"
	set error 1
	while {$error == 1} {
		set error [catch {set fid [open $tmp_dir/errors r]} error_message]
		puts $debug_out(3) "execute_command - tried to open $tmp_dir/errors with error: $error - \"$error_message\""
		after 100
	}
	set errors [read $fid]
	close $fid
	puts $debug_out(2) "execute_command - errors recorded were:\n\"$errors\""
	set_message terminal ""
	update
	# check for 'error 1'
	if {[string first "error 1" $errors] != -1} {
		puts $debug_out(1) "execute_command - completed with error 1, return error"
		return 1
	}
	puts $debug_out(1) "execute_command - completed"
	return 0
}
	
proc execute_terminal_isclosed {action master} {
	
global debug_out
# OK, nothing seems to work in tcl to watch when the terminal window closes. We can use a runfile
# but that does not catch a graceless exit. So we are going to use wmctrl to see when the window closes
# but this means we have to know the title of the window so that we can track it!

	puts $debug_out(1) "execute_terminal_isclosed - called for window \"$action\""
	
	set count 0
	set mapstate "normal"
	set mapstate_count 0
	set window_count 0
	set window_list ""
	set xwininfo true
	
	# check once for xwininfo
	if {[catch {exec which xwininfo}] != 0} {
		puts $debug_out(2) "execute_terminal_isclosed - xwininfo is not installed, using \[wm state\]"
		set xwininfo false
	}
	while {true} {
		incr count
		# if xwininfo is installed then it will report faster than wm state so prefer it
		if {$xwininfo} {
			# check, during the loop, if the main window has been minimised.
			# if it is later maximised then redraw the window
			set error 1
			# run xwininfo until it does not return an error
			while {$error != 0} {set error [catch {exec xwininfo -name $master -stats} winstate]}
			set winstate [split $winstate \n]
			if {[lsearch $winstate "  Map State: IsViewable"] != -1} {set winstate "normal"}
		} else {
			set winstate [wm state .]
			if {$winstate == "iconic"} {set winstate "unmapped"}
		}
		if {$winstate == $mapstate} {
			# the windows state has not changed
			incr mapstate_count
		} else {
			puts $debug_out(2) "\tthe previous open message was repeated $mapstate_count times"
			set mapstate_count 0
			if {$winstate == "normal" && $mapstate == "unmapped"} {
				update
				set mapstate "normal"
			} else {
				set mapstate "unmapped"
			}
			set winstate $mapstate
		}
		set error 1
		set windows ""
		# get a list of open windows from wmctrl with no errors
		while {$error != 0} {set error [catch {exec wmctrl -l} windows]}
		if {$windows == $window_list} {
			incr window_count
		} else {
			if {$mapstate_count > 0} {
				puts $debug_out(2) "\tthe previous open message was repeated $mapstate_count times"
			}
			if {$window_count > 0} {
				puts $debug_out(2) "\tWindow list repeated $window_count time"
			}
			puts $debug_out(2) "Window List: \n$windows"
			set window_list $windows
			set window_count 1
			if {[string first "$action" $windows] == -1} {
				puts $debug_out(2) "execute_terminal_isclosed - terminal window \"$action\" closed - break after $count loops"
				break
			}
		}
		if {$mapstate_count == 0} {puts $debug_out(2) "execute_terminal_isclosed - terminal window \"$action\" is open, state is $mapstate"}
		update
		# and wait a few milliseconds - note: this was set to 250 which seemed to be too fast?
		after 500
				
	}
	# raise and focus the main window in case it has been covered or minimised
	catch {exec wmctrl -F -a $master}
	puts $debug_out(1) "execute_terminal_isclosed - loop has completed after $count loops"
	return 0
}

proc execute_terminal_isopen {action} {

global debug_out
# Make sure that the terminal window is open, it sometimes takes some time
	
	puts $debug_out(1) "execute_terminal_isopen - called for window \"$action\""
	set count 0
	while {true} {
		incr count
		set error 1
		set windows ""
		# get a list of open windows from wmctrl with no errors
		while {$error != 0} {set error [catch {exec wmctrl -l} windows]}
		puts $debug_out(2) "execute_terminal_isopen - window List: \n$windows"
		if {[string first "$action" $windows] != -1} {
			puts $debug_out(2) "execute_terminal_isopen - terminal window \"$action\" is open - break after $count loops"
			break
		}
		update
		# and wait a few milliseconds - note: this was set to 250 which seemed to be too fast
		after 500 
	}

	set error [catch {exec wmctrl -F -a "$action"} result]
	puts $debug_out(1) "execute_terminal_isopen - raised terminal window with  error $error and result \"$result\""

	puts $debug_out(1) "execute_terminal_isopen - loop has completed after $count loops"
	return 0
}

proc filter {} {
	
global aur_updates debug_out filter filter_list find findtype group list_all list_installed list_local list_outdated list_show list_special list_uninstalled listview_current tmp_dir
# procedure to run when we need to filter the output

	puts $debug_out(1) "filter called - filter is \"$filter\", group is \"$group\", find is \"$find\""

	# if the group setting is not applicable then reset it to All
	if {$filter == "orphans" || $filter == "aur"} {set group "All"}
	# if no filter is required then return
	if {$filter == 0 && $find == "" && $group == "All"} {return 0}
	# to filter by orphans fake the .fiter_list_orphans selection - does not keep any find
	if {$filter == "orphans" && $find == "" && $group == "All"} {filter_checkbutton ".filter_list_orphans" "pacman -b $tmp_dir -Qdtq" "Orphans"}
	set filter_list ""
	set list ""
	
	# if a filter is set then which overall list do we need to filter by
	switch $filter {
		"all" {
			set list $list_all
			puts $debug_out(2) "filter - list set to list_all"
		}
		"installed" {
			set list [lsort -dictionary -index 1 [concat $list_installed $list_local]]
			puts $debug_out(2) "filter - list set to list_installed"
		}
		"not_installed" {
			set list $list_uninstalled
			puts $debug_out(2) "filter - list set to list_uninstalled"
		}
		"orphans" {
			set list $list_special
			puts $debug_out(2) "filter - list set to list_special"
		}
		"outdated" {
			set list $list_outdated
			puts $debug_out(2) "filter - list set to list_outdated"
		}
		"not_required" {
			set list $list_special
			puts $debug_out(2) "filter - list set to list_special"
		}
		"aur" {
			set list $aur_updates
			puts $debug_out(2) "filter - list set to aur_updates"
		}
	}
	
	# now filter on any group selected unless we are in AUR which has no groups
	if {$group != "All" && $filter != "aur"} {
		puts $debug_out(2) "filter - now filter by group $group"
		foreach element $list {
			set groups [split [lrange $element 4 4] ","]
			foreach item $groups {
				if {$group == $item} {
					lappend filter_list $element
				}
			}
		}	
	} else {
		set filter_list $list
	}
	# finally filter on the find string
	if {$find != ""} {
		puts $debug_out(2) "filter - now find $find in filter_list"
		# find and show the results
		if {$findtype == "findname"} {
			find $find $filter_list name
		} else {
			find $find $filter_list all
		}
	} else {
		puts $debug_out(2) "filter - now show the [llength $filter_list] items in filter_list"
		# sort and show the list
		set filter_list [sort_list $filter_list]
		list_show $filter_list
	}
	puts $debug_out(1) "filter completed"

}

proc filter_checkbutton {button command title} {

global debug_out filter filter_list find find_message group list_show selected_list selected_message
# procedure to execute when a list checkbutton is selected

	puts $debug_out(1) "filter checkbutton called by $button with command $command  - the title is set to $title"

	set error 0
	set filter_list ""
	set group "All"
	# lose any existing find command, selected groups, and/or messages for the special filters
	set find ""
	.buttonbar.entry_find delete 0 end
	set_message terminal ""
	# reset the selectmode to the default
	.wp.wfone.listview configure -selectmode extended
	# and remove any existing listgroups
	grid_remove_listgroups
	
	# if the button was unchecked then reset the filter to all
	if {$selected_list == 0} {
		puts $debug_out(2) "filter checkbutton - selected_list is 0, set filter to \"All\" and call filter"
		set filter "all"
		filter
	} else {
		$button configure -text "Searching ...    "
		update
		puts $debug_out(2) "filter checkbutton called list special with $command"
		set result [list_special "$command"]
		puts $debug_out(2) "filter checkbutton - list_special returned with the result $result"
		if {$result == "error"} {
			# OK so it did not work, so reset everything to normal and return
			$button configure -text "$title"
			set selected_list 0
			set filter "all"
			puts $debug_out(1) "filter_checkbutton failed reset filter to all, return error"
			return 1
		} else {
			$button configure -text "$title ($result)"
			puts $debug_out(2) "filter checkbutton - set filter_list to list_show ([llength $list_show] packages)"
			set filter_list $list_show
			puts $debug_out(1) "filter_checkbutton completed"
			return 0
		}
	}
	puts $debug_out(1) "filter_checkbutton completed"
	return 0
}

proc find {find list type} {

global debug_out group list_all list_installed list_show_order list_uninstalled listview_current
# find all the items containing the find string
# this will search whatever is in the list and show the results in listview

	puts $debug_out(1) "find called"
	set list_found ""
	if {$type == "all"} {
		set pkg_string "package"
		foreach element $list {
		# search for the string in the chosen list, but excluding the first item in the list values
		# which is the Repo, may not be able to search all the fields for local files if they have not
		# been downloaded yet
			if {[string first [string tolower $find] [string tolower [lrange $element 1 end]]] != -1} {
				lappend list_found $element
			}
		}
		## 29ms for search all without repo
	} elseif {$type == "name"} {
		set pkg_string "package name"
		# only search the name field (element 1)
		set list_found [lsearch -nocase -index 1 -all -inline $list *${find}*]
		## 3 ms for search name only
	}
	if {[llength $list_found] == 0} {
		set_message find ""
	} elseif {[llength $list_found] == 1} {
		set_message find "Found \"$find\" in 1 ${pkg_string}"
	} else {
		set_message find "Found \"$find\" in [llength $list_found] ${pkg_string}s"
	}
	update
	# now sort the list and show it
	set list_found [sort_list $list_found]
	list_show $list_found
	puts $debug_out(1) "find completed"
}

proc find_pacman_config {data} {

global debug_out list_installed list_outdated start_time
# look up data in the pacman configuration file
		
	puts $debug_out(1) "find_pacman_config called for $data - ([expr [clock milliseconds] - $start_time])"
	switch $data {
		logfile {
			set logfile "/var/log/pacman.log"
			
			# check log file location in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "LogFile" $line] == 0} {
					set logfile [string trim [string range $line [string first "=" $line]+1 end]]
					break
				}
			}
			close $fid
			puts $debug_out(1) "find_pacman_config - returned $logfile - ([expr [clock milliseconds] - $start_time])"
			return $logfile
		}
		dbpath {
			set database "/var/lib/pacman/"
			
			# check database location in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "DBPath" $line] == 0} {
					set database [string trim [string range $line [string first "=" $line]+1 end]]
					break
				}
			}
			close $fid
			puts $debug_out(1) "find_pacman_config - returned $database - ([expr [clock milliseconds] - $start_time])"
			return $database
		}
		dlprog {
			set dlprog ""
			
			# find the last transfer programme defined in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "XferCommand" $line] == 0} {
					set dlprog [string trim [string range $line [string first "=" $line]+1 end]]
					set dlprog [string trim [file tail [string range $dlprog 0 [string first " " $dlprog]]]]
				}
			}
			close $fid
			puts $debug_out(1) "find_pacman_config - returned $dlprog - ([expr [clock milliseconds] - $start_time])"
			return $dlprog
		}
		downloads {
			set result false
			# find the last entry for ParallelDownloads defined in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "ParallelDownloads" $line] != -1} {
					puts $debug_out(1) "find_pacman_config - found ParallelDownloads in $line"
					# make sure that there are no blank spaces at the start of the line
					if {[string first "ParallelDownloads" [string trim $line]] == 0} {
						set result true
					}
				}
			}
			close $fid
			puts $debug_out(1) "find_pacman_config - returned ParallelDownloads $result - ([expr [clock milliseconds] - $start_time])"
			return $result
		}
		ignored -
		all_ignored {
			set ignored_list ""
			set ignored_updates ""
			set ignored_groups ""
			set ignored_groups_installed ""
			set ignored_groups_upgrades ""
			
			
			# find the ignored list and the ignored groups defined in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "IgnorePkg" $line] == 0} {
					set ignored_list [string trim [string range $line [string first "=" $line]+1 end]]
					foreach item $ignored_list {
						if {[lsearch -index 1 $list_outdated $item] != -1} {
							append ignored_updates " " $item
						}
					}
				}
				if {[string first "IgnoreGroup" $line] == 0} {
					set ignored_groups [string trim [string range $line [string first "=" $line]+1 end]]
				}
			}
			close $fid
			puts $debug_out(2) "find_pacman_config - found ignored packages \"$ignored_list\""
			puts $debug_out(2) "find_pacman_config - found ignored groups \"$ignored_groups\""

			if {$ignored_groups != ""} {
				# list all the ignored packages in each group
				foreach group $ignored_groups {
					puts $debug_out(3) "find_pacman_config - check installed packages from $group"
					foreach element $list_installed {
						set groups [split [lrange $element 4 4] ","]
						foreach item $groups {
							if {[string first $item $ignored_groups] != -1} {append ignored_list " " [lrange $element 1 1]}
						}
					}
					puts $debug_out(3) "find_pacman_config - check outdated packages from $group"
					foreach element $list_outdated {
						set groups [split [lrange $element 4 4] ","]
						foreach item $groups {
							if {[string first $item $ignored_groups] != -1} {append ignored_list " " [lrange $element 1 1]}
						}
					}
				}
			}

			puts $debug_out(2) "find_pacman_config - found ignored packages \"[string trim $ignored_list]\""
			puts $debug_out(2) "find_pacman_config - found ignored updates \"[string trim $ignored_updates]\""
			if {$data == "ignored"} {
				# we cannot be certain that the ignored updates is complete since, some packages updates could have been released sinc the last sync
				puts $debug_out(1) "find_pacman_config - returned assumed ignored updates \"$ignored_updates\" ([expr [clock milliseconds] - $start_time])"
				return [string trim $ignored_updates]
			} else {
				# this is the complete list of packages to be ignored, but some may not need to be updated
				puts $debug_out(1) "find_pacman_config - returned all ignored packages \"$ignored_list\" ([expr [clock milliseconds] - $start_time])"
				return [string trim $ignored_list]
			}
		}
	}
}

proc get_aur_dependencies {package} {
	
global debug_out depends_searches list_all list_installed list_local tmp_dir
# get the dependencies required for a specified AUR package
# returns a list of dependencies or "none" meaning that we have already sear ched for the dependencies for this package

	puts $debug_out(1) "get_aur_dependencies called for $package"
	puts $debug_out(2) "get_aur_dependencies - previous searches included $depends_searches"
	
	# have we already searched for this package?
	if {[lsearch $depends_searches $package] != -1} {return "none"}
	
	# this returns the dependencies for $package, but what if the basename is different?
	set basename ""
	while {$basename != $package} {
		puts $debug_out(3) "get_aur_dependencies - get the info for $package"
		set info [get_aur_info $package]
		if {$info == 1} {return 1}

		# add package to the list of previous searches
		lappend depends_searches $package
		set basename [split [lindex $info 0] " "]
		if {$basename == ""} {
			set ans [tk_messageBox -default ok -detail "The package \"$package\" was not found in AUR." -icon error -message "Cannot install $package" -parent . -title "Install $package" -type ok]
			puts $debug_out(2) "get_aur_dependencies - \"$package\" was not found in the AUR package list" 
			return "cancel"
		} elseif {$basename != $package} {
 			set ans [tk_messageBox -default ok -detail "Do you want to continue with $basename?\n\nHint: to install $package, first install $basename, but elect not to complete the installation. Then select Tools > Install AUR/Local and browse to $tmp_dir/aur_upgrades/$basename/$package* and install it. Be sure to install any dependencies first. Vpacman will clean up unwanted files when it is closed." -icon question -message "The package \"$package\" is a part of \"$basename\"" -parent . -title "Find the dependencies for $package" -type okcancel]
			if {$ans == "cancel"} {
				puts $debug_out(3) "get_aur_dependencies - do not install \"$package\" with the basename of \"$basename\""
				return "cancel"
			}
			set package $basename
			puts $debug_out(3) "get_aur_dependencies - package set to \"$basename\""
		}
	}
	# now make lists from the dependencies returned
	puts $debug_out(2) "get_aur_dependencies - found info: $info"
	set depends [split [lindex $info 5] " "]
	puts $debug_out(2) "get_aur_dependencies - found depends: $depends"
	set checkdepends [split [lindex $info 6] " "]
	puts $debug_out(2) "get_aur_dependencies - found checkdepends: $checkdepends"
	set makedepends [split [lindex $info 7] " "]
	puts $debug_out(2) "get_aur_dependencies - found make_depends: $makedepends"
	set optdepends [split [lindex $info 8] " "]
	puts $debug_out(2) "get_aur_dependencies - found opt_depends: $optdepends"
	
	set dependencies ""

	foreach list [list $depends $checkdepends $makedepends] {
		# fore each list, find the required dependencies, split between the aur dependencies and the repo dependencies
		set aur_depends ""
		set repo_depends ""
		set required ""
		puts $debug_out(3) "get_aur_dependencies - test dependencies from $list"
### each item could include the same package two or more times with different possible limits to the versions
### if all the one or more conditions fails then the item package name will be included plus the item name, in any order
### all will occur in the same list
### **SORT** the dependencies into alpha order to make sure that same name packages are shown together
### Need more examples in AUR to test this
		foreach item $list {
			set operator ""
			set real_name $item
			set repo ""
			set required_version ""
			set version ""
			puts $debug_out(3) "get_aur_dependencies - test $item from list"

			# see if there is a version specified
			# set the real_name of the package and the operator string to newer, older and/or same
			if {[string first "=" $item] != -1} {
				# could be "<=", ">=" or "="
				set required_version [string range $item [string first "=" $item]+1 end]
				set operator "same"
				set real_name [string range $item 0 [string first "=" $item]-1]
				if {[string first ">=" $item] != -1} {
					set operator "newer same"
					set real_name [string range $item 0 [string first ">=" $item]-1]
				} elseif {[string first "<=" $item] != -1} {
					set operator "older same"
					set real_name [string range $item 0 [string first "<=" $item]-1]
				}
			} elseif {[string first "<" $item] != -1} {
				set required_version [string range $item [string first "<" $item]+1 end]
				set operator "older"
				set real_name [string range $item 0 [string first "<" $item]-1]
			} elseif {[string first ">" $item] != -1} {
				set required_version [string range $item [string first ">" $item]+1 end]
				set operator "newer"
				set real_name [string range $item 0 [string first ">" $item]-1]
			} 
			# now see if the item is installed and if it is from the AUR or repos
			if {[lsearch -exact -index 1 [concat $list_installed $list_local] $real_name] != -1} {
				# the item has been installed
				set version [lindex [lsearch -exact -index 1 -inline $list_installed $real_name] 2]
				set repo [lindex [lsearch -exact -index 1 -inline $list_installed $real_name] 0]
				# is it the correct version
				if {$operator != ""} {
					set result [test_versions $required_version $version]
					if {[string first $result $operator] != -1} {
						# the version installed is one of the operator strings
						puts $debug_out(3) "get_aur_dependencies - add $item \[installed\] to required list"
						lappend required "$real_name \[installed\]"
						puts $debug_out(3) "\t$required"
					} else {
						# the version installed is not one of the operator strings
						puts $debug_out(3) "get_aur_dependencies - add $item to required list"
						lappend required $item
						puts $debug_out(3) "\t$required"
						if {$repo == "local"} {
							lappend aur_depends $item
						} else {
							lappend repo_depends $item 
						}
					}
				} else {
					puts $debug_out(3) "get_aur_dependencies - add $item \[installed\] to required list"
					lappend required "$real_name \[installed\]"
					puts $debug_out(3) "\t$required"
				}
			} else {
				# the item has not been installed
				# is the item available from repos?
				# list_all only includes packages installed from AUR which were already picked up
				# the rest will be repo packages
				if {[lsearch -exact -index 1 $list_all $real_name] != -1} {
					# get the version installed
					set version [lindex [lsearch -exact -index 1 -inline $list_installed $real_name] 2]
					# and check if it is ok
					if {$operator != ""} {
						set result [test_versions $required_version $version]
						if {[string first $result $operator] != -1} {
							# the version available is one of the operator strings
							puts $debug_out(3) "get_aur_dependencies - add $item which is $real_name to required list"
							lappend required "$real_name"
							puts $debug_out(3) "\t$required"
							lappend repo_depends "$real_name"
						} else {
							# the version available is not one of the operator strings
							puts $debug_out(3) "get_aur_dependencies - add $item to required list"
							lappend required $item
							puts $debug_out(3) "\t$required"
							lappend repo_depends $item 
						}
					} else {
						puts $debug_out(3) "get_aur_dependencies - add $item which is $real_name to required list"
						lappend required $real_name
						puts $debug_out(3) "\t$required"
						lappend repo_depends $real_name 
					}
				} else {
					# so the package is not included in list_all 
					# so it must be an AUR/Local package or maybe it does not exist?
					puts $debug_out(3) "get_aur_dependencies - add $item to required list"
					lappend required $item
					puts $debug_out(3) "\t$required"
					lappend aur_depends $real_name
				}
			}
		}
### now analyse the lists. If the same package name appears more than once, remove all but one occurrence.
### if the name appears more than once, but one includes a version number then remove the name only occurrencea
### if the name appears more than once with a version number then something is dreadfully wrong, just remove all but one of them
### or perhaps leave them all since it will fail anyway

### check the first item  if it contains > = < leave it, anyway save the package name
### get the next item, if it contains > = < leave it, anyway save the package name, but if it is the same package name on its own then delete it

		lappend dependencies $required $repo_depends $aur_depends
	}
	# dependencies now contains (required, repo_depends, aur_depends) for depends - (required, repo_depends, aur_depends) for check depends - (required, repo_depends, aur_depends) for make depends
	puts $debug_out(1) "get_aur_dependencies - completed and returned dependency list $dependencies and package name $package"
	lappend dependencies $package
	return $dependencies
}

proc get_aur_info {package} {
	
global debug_out dlprog
# use curl to get the information for a package from the RPC interface
# may be called if the aur_versions thread called from start did not run, or if the aur package is not installed
	
	puts $debug_out(1) "get_aur_info called for $package"
	if {$dlprog == ""} {
		puts $debug_out(1) "get_aur_info - No download programme installed - return Error"
		return 1
	}
	puts $debug_out(2) "get_aur_info - called test_internet"
	if {[test_internet] != 0} {return 1}
	set package [string map {+ %2B} $package] 
	if {$dlprog == "curl"} {
		set error [catch {eval [concat exec curl -Lfs "https://aur.archlinux.org/rpc?v=5&type=info&arg[]=$package"]} line]
	} else {
		set error [catch {eval [concat exec wget -LqO - "https://aur.archlinux.org/rpc?v=5&type=info&arg[]=$package"]} line]
	}
	if {$error != 0} {
		puts $debug_out(1) "get_aur_info could not get info for $package - error was $error : $line"
		return 1
	}
	set info [read_aur_info $line]
	puts $debug_out(2) "get_aur_info - read_aur_info returned: $info"

	puts $debug_out(1) "get_aur_info completed"
	
	return $info
}

proc get_aur_list {} {

global aur_list debug_out dlprog tmp_dir
# get the list of aur packages available
# download and unzip the package list takes less than a second on a slow internet connection 
# so do not ask to update the list, just try it
# returns 0 success - a list is available (may not be up to date),  1 failed - no list is available,  2 do not use the existing package list

	puts $debug_out(1) "get_aur_list called"
	
	set aur_list ""
	# delete any existing 'packages.gz' files
	file delete $tmp_dir/packages.gz

	set error 1
	puts $debug_out(2) "get_aur_list - called test_internet"
	if {[test_internet] == 0} {
		if {$dlprog == "curl"} {
			set error [catch {exec curl -s -o "$tmp_dir/packages.gz" "https://aur.archlinux.org/packages.gz"}]
		} elseif {$dlprog == "wget"} {
			set error [catch {exec wget -q -O "$tmp_dir/packages.gz" "https://aur.archlinux.org/packages.gz"}]
		}
		if {$error == 0} {
			# but any existing packages file from a previous download will still exist
			set error [catch {exec gunzip -f "$tmp_dir/packages.gz"} error_message]
			puts $debug_out(2) "get_aur_list - unzipped package.gz with error: $error - \"$error_message\""
		} else {
			set error 1
			puts $debug_out(2) "get_aur_list - failed to download package.gz"
		}
	}	
	# if the error is not 0 then either there was no internet or the download failed
	# see what packages file is available, if any
	if {$error != 0} {
		if {[file readable "$tmp_dir/packages"]} {
			set date [clock_format [file mtime "$tmp_dir/packages"] full_date]
			# failed to update aur package list
			puts $debug_out(2) "get_aur_list - failed to update package list"
			set ans [tk_messageBox -default yes -detail "Could not update the AUR package list.\nContinue using the package list dated $date?" -icon info -message "Failed to update AUR package list" -parent . -title "Information" -type yesno]
			if {$ans == "no"} {
				puts $debug_out(1) "get_aur_list - do not use existing package list, return 2"
				# return 2 from get_aur_list means that an aur_list is available but is not to be used
				return 2
			}
		} else {
			# failed to download aur package list
			puts $debug_out(1) "get_aur_list - failed to download package list, return 1"
			# return 1 from get_aur_list means that no aur_list is available
			return 1
		}
	}
	puts $debug_out(2) "get_aur_list - read packages"
	set fid [open $tmp_dir/packages r]
	set aur_list [read $fid]
	close $fid
	set aur_list [split $aur_list \n]
	# check that the first line is the comment and remove it
	if {[string first "#" [lindex $aur_list 0]] == 0} {set aur_list [lreplace $aur_list 0 0]}
	# check that the last line is not blank, if it is then remove it
	if {[lindex $aur_list end] == ""} {set aur_list [lreplace $aur_list end end]}
	# now sort the list
	set aur_list [lsort -dictionary $aur_list]
	puts $debug_out(1) "get_aur_list complete"
	# return 0 from get_aur_list means that an aur_list is available but may be, by choice, old
	return 0

}

proc get_aur_matches {name} {
	
global aur_list debug_out dlprog tmp_dir
# find any matches for $name in the aur list

	puts $debug_out(1) "get_aur_matches called"
	
	# check that the 'packages' file exists and is 'in date'

	# find any matches
	set matches [lsearch -all -inline -sorted -glob $aur_list "${name}*"]
	
	puts $debug_out(1) "get_aur_matches completed"
	return $matches
}

proc get_aur_name {name matches} {

global aur_list browser debug_out dlprog win_mainx win_mainy
# get the package name required from a list of matches
# returns package name or 3 cancelled

	puts $debug_out(1) "get_aur_name called for $name"
	
	toplevel .aurinstall.aurname
	
	get_win_geometry
	# calculate the position of the aurname window
	set left [expr $win_mainx + {[winfo width .] / 2} - {625 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {380 / 2}]
	wm geometry .aurinstall.aurname 625x380+$left+$down
	wm iconphoto .aurinstall.aurname tools
	wm resizable .aurinstall.aurname 0 0
	wm title .aurinstall.aurname "Select AUR Name"
	wm transient .aurinstall.aurname .aurinstall
	
# CONFIGURE AURNAME WINDOW

	label .aurinstall.aurname.title_label \
		-text "[llength $matches] AUR packages start with $name"
	listbox .aurinstall.aurname.list \
		-activestyle none \
		-listvariable matches \
		-selectmode browse \
		-yscrollcommand ".aurinstall.aurname.list_scroll set"
	# select the first item in the list
	.aurinstall.aurname.list selection set 0
	scrollbar .aurinstall.aurname.list_scroll \
		-command ".aurinstall.aurname.list yview"
	# set up a binding for .aurinstall.aurname_list
	bind .aurinstall.aurname.list <<ListboxSelect>> {
		set now_selected [.aurinstall.aurname.list curselection]
		# if this is the first access to the listbox then last_selected will not exist
		# so check for the error and correct it
		set error [info exists last_selected]
		# if last_selected does not exists then is was 0, the first item in the list
		if {$error == 0} {set last_selected 0}
		if {$now_selected != $last_selected} {
			.aurinstall.aurname.desc_entry configure -state normal
			.aurinstall.aurname.desc_entry delete 0.0 end
			.aurinstall.aurname.desc_entry configure -state disabled
			grid remove .aurinstall.aurname.desc_scroll
			.aurinstall.aurname.version_entry configure -text ""
			.aurinstall.aurname.url_entry configure -state normal
			.aurinstall.aurname.url_entry delete 0.0 end
			.aurinstall.aurname.url_entry configure -state disabled
			bind .aurinstall.aurname.url_entry <ButtonRelease-1> {}
			.aurinstall.aurname.aur_entry configure -state normal
			.aurinstall.aurname.aur_entry delete 0.0 end
			.aurinstall.aurname.aur_entry configure -state disabled
			bind .aurinstall.aurname.aur_entry <ButtonRelease-1> {}
			.aurinstall.aurname.depends_entry configure -state normal
			.aurinstall.aurname.depends_entry delete 0.0 end
			.aurinstall.aurname.depends_entry configure -state disabled
			grid remove .aurinstall.aurname.depends_scroll
			.aurinstall.aurname.updated_entry configure -text ""
		}
		# if now_selected is blank then reset it to the previously selected item
		set error [catch {
			if {$now_selected == ""} {.aurinstall.aurname.list selection set $last_selected}
		}]
		# if that was not possible then just select the first item in the list
		if {$error != 0} {
			.aurinstall.aurname.list selection set 0
		}
		# now reset the last selected item
		set last_selected  [.aurinstall.aurname.list curselection]
		.aurinstall.aurname.get_info invoke
	}
	frame .aurinstall.aurname.infobuttons
		button .aurinstall.aurname.get_info \
			-command {
				# get the info on the selected package
				set error [catch {.aurinstall.aurname.list get [.aurinstall.aurname.list curselection]} item]
				puts $debug_out(2) ".aurinstall.aurname.list get curselection returned error $error and item $item"
				if {$error == 0} {
					set info [get_aur_info $item]
					# get_aur_info will return 1 when there is no download programme or there is no internet
					if {$info != 1} {
						set basename [lindex $info 0]
						set version [lindex $info 1]
						set description [lindex $info 2]
						set url [lindex $info 3]
						set updated [lindex $info 4]
						set depends [lindex $info 5]
						set checkdepends [lindex $info 6]
						set makedepends [lindex $info 7]
						.aurinstall.aurname.desc_entry configure -state normal
						.aurinstall.aurname.desc_entry delete 0.0 end
						.aurinstall.aurname.desc_entry insert end $description		
						.aurinstall.aurname.desc_entry configure -state disabled
						# set up a scroll bar if necessary
						if {[.aurinstall.aurname.desc_entry count -displaylines 0.0 end] > 3} {
							grid .aurinstall.aurname.desc_scroll -in .aurinstall.aurname -row 3 -column 6 \
								-sticky ns
						}
						.aurinstall.aurname.version_entry configure -text $version
						.aurinstall.aurname.url_entry configure -state normal
						.aurinstall.aurname.url_entry delete 0.0 end
						.aurinstall.aurname.url_entry insert end $url
						.aurinstall.aurname.url_entry configure -state disabled
						# if there is a url then set up a binding for it
						if {$url != ""} {
							bind .aurinstall.aurname.url_entry <ButtonRelease-1> {exec $browser [.aurinstall.aurname.url_entry get 0.0 end] &}
						}
						.aurinstall.aurname.aur_entry configure -state normal
						.aurinstall.aurname.aur_entry delete 0.0 end
						.aurinstall.aurname.aur_entry insert end "https://aur.archlinux.org/packages/${item}/"
						.aurinstall.aurname.aur_entry configure -state disabled
						bind .aurinstall.aurname.aur_entry <ButtonRelease-1> {exec $browser "https://aur.archlinux.org/packages/$item" &}
						.aurinstall.aurname.depends_entry configure -state normal
						.aurinstall.aurname.depends_entry delete 0.0 end
						.aurinstall.aurname.depends_entry insert end $depends
						.aurinstall.aurname.depends_entry configure -state disabled
						# set up a scroll bar if necessary
						if {[.aurinstall.aurname.depends_entry count -displaylines 0.0 end] > 3} {
							grid .aurinstall.aurname.depends_scroll -in .aurinstall.aurname -row 8 -column 6 \
								-sticky ns
						}
						.aurinstall.aurname.updated_entry configure -text $updated
					} else {
						.aurinstall.aurname.desc_entry configure -state normal
						.aurinstall.aurname.desc_entry delete 0.0 end
						.aurinstall.aurname.desc_entry insert end "Could not get info for [.aurinstall.aurname.list get [.aurinstall.aurname.list curselection]]"	
						.aurinstall.aurname.desc_entry configure -state disabled
						grid remove .aurinstall.aurname.desc_scroll
						.aurinstall.aurname.version_entry configure -text ""
						.aurinstall.aurname.url_entry configure -state normal
						.aurinstall.aurname.url_entry delete 0.0 end
						.aurinstall.aurname.url_entry configure -state disabled
						.aurinstall.aurname.depends_entry configure -state normal
						.aurinstall.aurname.depends_entry delete 0.0 end
						.aurinstall.aurname.depends_entry configure -state disabled
						grid remove .aurinstall.aurname.depends_scroll
						.aurinstall.aurname.updated_entry configure -text ""
					}
				}
			} \
			-text "Get Info" \
			-width 13
		button .aurinstall.aurname.extend \
			-command {
				set title [.aurinstall.aurname.title_label cget -text]
				set name [string range $title [string last " " $title]+1 end]
				if {[.aurinstall.aurname.extend cget -text] == "Extend Search"} {
					# extend the search to all aur packages containing $name
					set matches [lsearch -all -inline $aur_list *$name*]
					.aurinstall.aurname.list selection clear 0 end
					.aurinstall.aurname.list selection set 0
					event generate .aurinstall.aurname.list <<ListboxSelect>>
					.aurinstall.aurname.title_label configure -text "[llength $matches] AUR packages include $name"
					.aurinstall.aurname.extend configure -text "Simple Search"
				} else {
					# change the search to all aur packages starting with $name
					set matches [lsearch -all -inline $aur_list $name*]
					.aurinstall.aurname.list selection clear 0 end
					.aurinstall.aurname.list selection set 0
					event generate .aurinstall.aurname.list <<ListboxSelect>>
					.aurinstall.aurname.title_label configure -text "[llength $matches] AUR packages start with $name"
					.aurinstall.aurname.extend configure -text "Extend Search"
				}
			} \
			-text "Extend Search" \
			-width 13
	label .aurinstall.aurname.desc_label \
		-text "Description :"
	text .aurinstall.aurname.desc_entry \
		-background [.aurinstall.aurname.desc_label cget -background] \
		-cursor left_ptr \
		-height 3 \
		-relief flat \
		-inactiveselectbackground {} \
		-state disabled \
		-wrap word \
		-yscrollcommand ".aurinstall.aurname.desc_scroll set"
	scrollbar .aurinstall.aurname.desc_scroll \
		-command ".aurinstall.aurname.desc_entry yview"		
	# do nothing for various events to avoid flickering
	bind .aurinstall.aurname.desc_entry <Enter> {break}
	bind .aurinstall.aurname.desc_entry <B1-Motion> {break}
	bind .aurinstall.aurname.desc_entry <Leave> {break}
	label .aurinstall.aurname.version_label \
		-text "Version :" 
	label .aurinstall.aurname.version_entry \
		-text ""
	label .aurinstall.aurname.url_label \
		-text "URL :"
	text .aurinstall.aurname.url_entry \
		-background [.aurinstall.aurname.desc_label cget -background] \
		-cursor left_ptr \
		-foreground blue \
		-height 3 \
		-relief flat \
		-state disabled \
		-wrap word	
	# do nothing for various events to avoid flickering
	bind .aurinstall.aurname.url_entry <Enter> {break}
	bind .aurinstall.aurname.url_entry <B1-Motion> {break}
	bind .aurinstall.aurname.url_entry <Leave> {break}
	label .aurinstall.aurname.aur_label \
		-text "AUR :"
	text .aurinstall.aurname.aur_entry \
		-background [.aurinstall.aurname.desc_label cget -background] \
		-cursor left_ptr \
		-foreground blue \
		-height 3 \
		-relief flat \
		-state disabled \
		-wrap word	
	# do nothing for various events to avoid flickering
	bind .aurinstall.aurname.aur_entry <Enter> {break}
	bind .aurinstall.aurname.aur_entry <B1-Motion> {break}
	bind .aurinstall.aurname.aur_entry <Leave> {break}
	label .aurinstall.aurname.depends_label \
		-text "Dependencies :" 
	text .aurinstall.aurname.depends_entry \
		-background [.aurinstall.aurname.desc_label cget -background] \
		-cursor left_ptr \
		-height 3 \
		-relief flat \
		-selectbackground [.aurinstall.aurname.desc_label cget -background] \
		-state disabled \
		-wrap word \
		-yscrollcommand ".aurinstall.aurname.depends_scroll set"
	scrollbar .aurinstall.aurname.depends_scroll \
		-command ".aurinstall.aurname.depends_entry yview"
	# do nothing for various events to avoid flickering
	bind .aurinstall.aurname.depends_entry <Enter> {break}
	bind .aurinstall.aurname.depends_entry <B1-Motion> {break}
	bind .aurinstall.aurname.depends_entry <Leave> {break}
	label .aurinstall.aurname.updated_label \
		-text "Last Updated :"
	label .aurinstall.aurname.updated_entry \
		-text ""
	frame .aurinstall.aurname.closebuttons
		button .aurinstall.aurname.select \
			-command {
				# return the selected aur package name
				set aur_name ""
				catch {set aur_name [.aurinstall.aurname.list get [.aurinstall.aurname.list curselection]]}
				grab release .aurinstall.aurname
				destroy .aurinstall.aurname
				puts $debug_out(1) "get_aur_name completed and returned \"$aur_name\""
				return $aur_name
			} \
			-text "Select" \
			-width 13
		button .aurinstall.aurname.cancel \
			-command {
				grab release .aurinstall.aurname
				set aur_name 3
				destroy .aurinstall.aurname
				puts $debug_out(1) "get_aur_name cancelled"
				return $aur_name
			} \
			-text "Cancel" \
			-width 13

	# Geometry management

	grid .aurinstall.aurname.title_label -in .aurinstall.aurname -row 1 -column 1 \
		-columnspan 6 \
		-pady 10 \
		-sticky we
	grid .aurinstall.aurname.list -in .aurinstall.aurname -row 2 -column 2 \
		-rowspan 11 \
		-sticky ns
	grid .aurinstall.aurname.list_scroll -in .aurinstall.aurname -row 2 -column 3 \
		-rowspan 11 \
		-sticky ns
	grid .aurinstall.aurname.infobuttons -in .aurinstall.aurname -row 2 -column 4 \
		-columnspan 3 \
		-sticky we
		grid .aurinstall.aurname.get_info -in .aurinstall.aurname.infobuttons -row 1 -column 1 \
			-sticky w
		grid .aurinstall.aurname.extend -in .aurinstall.aurname.infobuttons -row 1 -column 4 \
			-sticky e
	grid .aurinstall.aurname.desc_label -in .aurinstall.aurname -row 3 -column 4 \
		-sticky nw
	grid .aurinstall.aurname.desc_entry -in .aurinstall.aurname -row 3 -column 5 \
		-sticky nw
	grid .aurinstall.aurname.version_label -in .aurinstall.aurname -row 4 -column 4 \
		-sticky w
	grid .aurinstall.aurname.version_entry -in .aurinstall.aurname -row 4 -column 5 \
		-sticky w
	grid .aurinstall.aurname.url_label -in .aurinstall.aurname -row 6 -column 4 \
		-sticky nw
	grid .aurinstall.aurname.url_entry -in .aurinstall.aurname -row 6 -column 5 \
		-sticky nw
	grid .aurinstall.aurname.aur_label -in .aurinstall.aurname -row 7 -column 4 \
		-sticky nw
	grid .aurinstall.aurname.aur_entry -in .aurinstall.aurname -row 7 -column 5 \
		-sticky nw
	grid .aurinstall.aurname.depends_label -in .aurinstall.aurname -row 8 -column 4\
		-sticky nw
	grid .aurinstall.aurname.depends_entry -in .aurinstall.aurname -row 8 -column 5 \
		-sticky nw
	grid .aurinstall.aurname.updated_label -in .aurinstall.aurname -row 10 -column 4\
		-sticky w
	grid .aurinstall.aurname.updated_entry -in .aurinstall.aurname -row 10 -column 5 \
		-sticky w
	grid .aurinstall.aurname.closebuttons -in .aurinstall.aurname -row 12 -column 4 \
		-columnspan 3 \
		-sticky we
		grid .aurinstall.aurname.select -in .aurinstall.aurname.closebuttons -row 1 -column 1 \
			-stick w
		grid .aurinstall.aurname.cancel -in .aurinstall.aurname.closebuttons -row 1 -column 4 \
			-sticky e
			
	# Resize behavior management

	grid rowconfigure .aurinstall.aurname 1 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 3 -weight 2 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 5 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .aurinstall.aurname 6 -weight 1 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 7 -weight 1 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 8 -weight 2 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 9 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .aurinstall.aurname 10 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 11 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .aurinstall.aurname 12 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .aurinstall.aurname 13 -weight 0 -minsize 5 -pad 0

	grid columnconfigure .aurinstall.aurname 1 -weight 0 -minsize 10 -pad 0
	grid columnconfigure .aurinstall.aurname 2 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .aurinstall.aurname 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname 5 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname 6 -weight 0 -minsize 13 -pad 0
	grid columnconfigure .aurinstall.aurname 7 -weight 0 -minsize 7 -pad 0
	
	grid rowconfigure .aurinstall.aurname.infobuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.infobuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.infobuttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.infobuttons 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.infobuttons 4 -weight 0 -minsize 0 -pad 0
	
	grid rowconfigure .aurinstall.aurname.closebuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.closebuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.closebuttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.closebuttons 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.aurname.closebuttons 4 -weight 0 -minsize 0 -pad 0
	
	puts $debug_out(2) "get_aur_name - set grab on .aurinstall.aurname window"
	
	update
	grab set .aurinstall.aurname
	
	# if there is an exact match then get the info for it
	if {[lsearch -exact $matches $name] != -1} {
		# in this case the exact match will always be the first in the list
		.aurinstall.aurname.get_info invoke
	}
}

proc get_aur_updates {} {

global aur_all aur_messages aur_only aur_updates aur_versions debug_out filter filter_list find group list_local selected_list thread tmp_dir
# check for local packages which may need to be updated
	
	puts $debug_out(1) "get_aur_updates called"
	
	# If a conflicting thread is running then return
	if {$thread != ""} {
		puts $debug_out(1) "get_aur_updates called - but a conflicting thread is already $thread"
		return 1
	}

	set aur_only true
	set aur_updates ""
	set filter "aur"
	set filter_list ""
	set group "All"
	set messages ""
	
	if {$aur_versions == ""} {
		puts $debug_out(2) "get_aur_updates - aur_versions is blank"
		# aur_versions is blank so the thread to fetch it did not complete - get it now
		.filter_list_aur_updates configure -text "Searching ..."
		update
		puts $debug_out(2) "get_aur_updates - call get_aur_versions"
		# set aur_only false so that get_aur_versions completes
		set aur_only false
		set error [get_aur_versions]
		puts $debug_out(2) "get_aur_updates - configured text \"AUR/Local Updates\""
		.filter_list_aur_updates configure -text "AUR/Local Updates"
		update
	
		if {$error == 1} {
			# OK so it looks like there is no internet available, so just show what we've got
			if {$aur_all} {
				list_show $list_local
				.filter_list_aur_updates configure -text "AUR/Local Packages ([llength $list_local])"
			} else {
				list_show ""
				.filter_list_aur_updates configure -text "AUR/Local Updates (0)"
			}
			puts $debug_out(1) "get_aur_updates failed"
			return 1
		}
		
		puts $debug_out(2) "get_aur_updates - found [llength $aur_versions] aur_versions, now update lists and treeview - call put_aur_versions"
		put_aur_versions $aur_versions	
		# and reset aur_only
		set aur_only true
	} else {
		puts $debug_out(2) "get_aur_updates - aur_versions is already set to $aur_versions"
	}
	puts $debug_out(2) "get_aur_updates - aur_versions is available"
	# now just check for any errors and find the updates
	set find_string false
	puts $debug_out(2) "get_aur_updates - find the details of each list_local package"
	# check each package, is it a local install, is it newer or older, construct a message if necessary
	foreach line $list_local {
		set element ""
		set name [lindex $line 1]
		set version [lindex $line 2]
		set available [lindex $line 3]
		set index [lsearch $aur_versions $name]
		puts $debug_out(3) "get_aur_updates - check available versions for $name ($available), found at $index in aur_versions"
		# if this is a local file with no aur version
		if {$available == "-na-"} {
			set messages [append messages "Warning: $name was not found in the AUR packages\n"]
			if {$aur_all} {
				set element $line
			}
		} else {
			if {$aur_all} {
				set element $line
			} else {
				# has the version number changed
				if {$version != $available} {
					puts $debug_out(2) "get_aur_versions - the version for $name is different - call test_versions"
					set test [test_versions $version $available]
					if {$test == "newer"} {
						puts $debug_out(2) "\tthe current installed version is older"
						set element $line
					} elseif {$test == "older"} {
						puts $debug_out(2) "\tthe current installed version is newer"
					}
				}
			}
		}
		if {$element != ""} {
			lappend aur_updates $element
			if {[string first $find [lindex $element 1]] != -1} {set find_string true}
		}
	}
	# if there is a group selected or the find string is not in the selection of local packages then
	# lose any existing find command, selected groups, and/or messages for the special filters
	puts $debug_out(2) "get_aur_updates - Find String is $find_string | Group is $group"
	if {!$find_string || $group != "All"} {
		set find ""
		.buttonbar.entry_find delete 0 end
		set_message find ""
		grid_remove_listgroups
		puts $debug_out(2) "get_aur_updates - find set to blank"
	}
	# aur_updates should now be a clean list of all the updates including all the local packages if requested
	set filter_list $aur_updates
	if {$aur_all} {
		puts $debug_out(2) "get_aur_updates - configured text \"AUR/Local Packages ([llength $filter_list])\""
		.filter_list_aur_updates configure -text "AUR/Local Packages ([llength $filter_list])"
	} else {
		puts $debug_out(2) "get_aur_updates - configured text \"AUR/Local Updates ([llength $filter_list])\""
		.filter_list_aur_updates configure -text "AUR/Local Updates ([llength $filter_list])"
	}
	puts $debug_out(2) "aur_updates message\n\t$messages\naur_messages $aur_messages"
	if {$messages != "" && $aur_messages == "true"} {
		set ans [tk_messageBox -default yes -detail "Do you want to view the warning messages now?" -icon question -message "There are warning messages from the AUR/Local Updates." -parent . -title "Upgrade Warnings" -type yesno]
		# don't show the message again
		set aur_messages "false"
		switch $ans {
			no {}
			yes {view_text "$messages" "AUR/Local Updates Messages"}	
		}
	}
	.wp.wfone.listview configure -selectmode browse
	if {$find != ""} {
		puts $debug_out(2) "get_aur_updates - called find"
		find $find $aur_updates all
	} else {
		puts $debug_out(2) "get aur_updates - call list_show with [llength $aur_updates] aur_updates"
		list_show "$aur_updates"
	}
	puts $debug_out(1) "get_aur_updates completed"
}

proc get_aur_versions {} {

global aur_all aur_messages aur_only aur_updates aur_versions debug_out dlprog filter filter_list find group list_local selected_list start_time thread tmp_dir
# check for local packages which may need to be updated
	
	# If a conflicting thread is running then return
	if {$thread != ""} {
		puts $debug_out(1) "get_aur_versions called - but a conflicting thread is already $thread"
		return 1
	}

	puts $debug_out(1) "get_aur_versions called - ([expr [clock milliseconds] - $start_time])"
	# if aur_only is true then this was the last procedure run
	puts $debug_out(2) "get_aur_versions - aur_only is $aur_only"
	# avoid looking up all the updates a second time if aur_only is already true
	if {$aur_only == "false"} {
		puts $debug_out(2) "get_aur_versions - find aur_versions ([expr [clock milliseconds] - $start_time])"
		# test for internet
		puts $debug_out(2) "get_aur_versions - called test_internet"
		set error [test_internet]
		if {$error != 0 || $dlprog == ""} {
			puts $debug_out(2) "get_aur_versions - test_internet returned $error, download programme set to \"$dlprog\", return error"
			return 1
		}
		set list ""
		set aur_versions ""
		puts $debug_out(2) "get_aur_versions started ([expr [clock milliseconds] - $start_time])"
		foreach item $list_local {
			# make up a list of all the local packages in the format &arg[]=package&arg[]=package etc.
			set list [append list "\&arg\[\]=[lindex $item 1]"]
		}
		# now find all the information on these packages
		set fid [open "$tmp_dir/get_aur_versions.sh" w]
		puts $fid "#!/bin/bash"
		if {$dlprog == "curl"} {
			puts $fid "curl -LfGs \"https://aur.archlinux.org/rpc?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\" 2>&1"
		} else {
			puts $fid "wget -LqO - \"https://aur.archlinux.org/rpc?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\" 2>&1"
		}
		puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
		close $fid
		exec chmod 0755 "$tmp_dir/get_aur_versions.sh"

		puts $debug_out(2) "get_aur_versions - now run $tmp_dir/get_aur_versions.sh"
		set error [catch {exec "$tmp_dir/get_aur_versions.sh"} error_message]
		if {$error != 0} {
			puts $debug_out(1) "get_aur_versions - error getting version info ([expr [clock milliseconds] - $start_time])"
			tk_messageBox -default ok -detail "Try again later" -icon error -message "Unable to get version information for AUR/Local packages." -parent . -title "Error getting AUR versions" -type ok
			return 1
		}
		file delete "$tmp_dir/get_aur_versions.sh"
		# check if the file has been written and read the results into a variable 
		set error 1
		while {$error == 1} {
			set error [catch {set fid [open $tmp_dir/vpacman_aur_result r]} error_message]
			puts $debug_out(3) "get_aur_versions - tried to open $tmp_dir/vpacman_aur_result with error $error and result \"$error_message\""
			after 100
		}
		gets $fid result
		close $fid
		puts $debug_out(2) "get_aur_versions - found result ([expr [clock milliseconds] - $start_time])"
		# and delete the temporary file
		file delete $tmp_dir/vpacman_aur_result
		# split the result on each "\},\{"
		set result [regsub -all "\},\{" $result "\n"]
		set result [split $result "\n"]
		puts $debug_out(3) "get_aur_versions - result is \"$result\""
		# and analyse each line
		foreach line $result {
			set index [string first "\"Name\":" $line]
			if {$index == -1} {
				set name ""
			} else {
				set position [expr $index + 8]
				set name [string trim [string range $line $position [expr [string first \, $line $position] - 1]] \"]
			}
			set index [string first "\"Version\":" $line]
			if {$index == -1} {
				set version ""
			} else {
				set position [expr $index + 11]
				set version [string trim [string range $line $position [expr [string first \, $line $position] - 1]] \"]
			}
			set index [string first "\"Description\":" $line]
			if {$index == -1 } {
				set description ""
			} else {
				set position [expr $index + 15]
				set description [string range $line $position [expr [string first \, $line $position] - 1]]
				set description [string map {"\\" ""} $description]
				set description [string trim $description \"]
			}
			set index [string first "\"URL\":" $line]
			if {$index == -1} {
				set url ""
			} else {
				set position [expr $index + 6]
				set url [string range $line $position [expr [string first \, $line $position] - 1]]
				regsub -all {\\} $url {} url
				set url [string trim $url \"]
			}
			set index [string first "\"LastModified\":" $line]
			if {$index == -1} {
				set updated ""
			} else {
				set position [expr $index + 15]
				set updated [string range $line $position [expr [string first \, $line $position] - 1]]
				set updated [clock format $updated -format "[exec locale d_fmt] %R"]
			}
			set index [string first "\"Depends\":" $line]
			if {$index == -1} {
				set depends ""
			} else {
				set position [expr $index + 11]
				set depends [string range $line $position [expr [string first \] $line $position] - 1]]
				set depends [string map {"\"" "" "," " "} $depends]
			}
			set index [string first "\"MakeDepends\":" $line]
			if {$index == -1} {
				set makedepends ""
			} else {
				set position [expr $index + 15]
				set makedepends [string range $line $position [expr [string first \] $line $position] - 1]]
				set makedepends [string map {"\"" "" "," " "} $depends]
			}
			set index [string first "\"Keywords\";" $line]
			if {$index == -1} {
				set keywords ""
			} else {
				set position [expr $index + 12]
				set keywords [string range $line $position [expr [string first \] $line $position] - 1]]
				set keywords [string map {"\"" "" "," " "} $keywords]
			}
			puts $debug_out(3) "get_aur_versions - parsed result and found \"$name $version $description\""
			lappend aur_versions [list $name $version $description]
		}
		puts $debug_out(1) "get_aur_versions found AUR package version details - ([expr [clock milliseconds] - $start_time])"	
	}
	return 0
}

proc get_configs {} {

global aur_all backup_dir browser buttons config_file debug_out diffprog editor geometry geometry_config geometry_view helpbg helpfg icon_dir installed_colour keep_log mirror_countries one_time outdated_colour part_upgrade save_geometry show_menu show_buttonbar start_time terminal terminal_string
# get the configuration previously saved

	puts $debug_out(1) "get_configs called - ([expr [clock milliseconds] - $start_time])"
	if [file exists "$config_file"] {
	set fid [open "$config_file" r ]
	while {[eof $fid] == 0} {
		gets $fid config_option
		if {$config_option == ""} {continue}
		if {[string index $config_option 0] == "#"} {continue} 
		set var [string trim [string map {\{ \  \} \  } [lrange $config_option 1 end]]]
		switch -- [lindex $config_option 0] {
			aur_all {set aur_all $var}
			backup_dir {set backup_dir $var}
			browser {set browser $var}
			buttons {set buttons $var}
			config_file {set config_file $var}
			diffprog {set diffprog $var}
			editor {set editor $var}
			geometry {set geometry $var}
			geometry_config {set geometry_config $var}
			geometry_view {set geometry_view $var}
			help_background {set helpbg $var}
			help_foreground {set helpfg $var}
			icon_directory {set icon_dir $var}
			installed_colour {set installed_colour $var}
			keep_log {set keep_log $var}
			mirror_countries {set mirror_countries $var}
			one_time {set one_time $var}
			outdated_colour {set outdated_colour $var}
			save_geometry {set save_geometry $var}
			show_menu {set show_menu $var}
			show_buttonbar {set show_buttonbar $var}
			terminal {set terminal $var}
			terminal_string {set terminal_string $var}
		}
	}
	close $fid
	}
	puts $debug_out(1) "get_configs completed - ([expr [clock milliseconds] - $start_time])"
}

proc get_dataview {current} {

global aur_only browser dataview debug_out pacman_files_upgrade pkgfile_upgrade start_time tmp_dir
# get the data from the database to show in the notebook page selected in .wp.wftwo.dataview
# current is the item id of the latest selected row

	puts $debug_out(1) "get_dataview - called for \"$current\" - ([expr [clock milliseconds] - $start_time])"

	set error 0
	set item ""
	set result ""
	# list_show could have blanked the dataview window already
	# so do not blank yet, we may not need to refresh the dataview window
	if {$current != ""} {
		set result [catch {.wp.wfone.listview item $current -values} item]
		if {$result == 1} {
			puts $debug_out(1) "\titem has disappeared, return error 1 - ([expr [clock milliseconds] - $start_time])"
			# so blank anything in the dataview window
			[.wp.wftwo.dataview select] delete 1.0 end
			return 1
		}
		puts $debug_out(1) "\titem selected $item"

		set repo [lrange $item 0 0]
		set package [lrange $item 1 1]
		set version [lrange $item 2 2]
		set available [lrange $item 3 3]
		set groups [lrange $item 4 4]
		set description [lrange $item 5 5]
		if {$dataview == "${package} [.wp.wftwo.dataview select]"} {
			puts $debug_out(1) "get_dataview - dataview has not changed from \"$dataview\", return 0 - ([expr [clock milliseconds] - $start_time])"
			return 0
		} else {
			set dataview "${package} [.wp.wftwo.dataview select]"
			[.wp.wftwo.dataview select] delete 1.0 end
			puts $debug_out(2) "get_dataview - dataview has changed to \"$dataview\""
		}
		puts $debug_out(2) "get_dataview - switch to [.wp.wftwo.dataview select]"
		switch [.wp.wftwo.dataview select] {
			.wp.wftwo.dataview.info {
				puts $debug_out(2) "get_dataview - selected info"
				grid remove .wp.wftwo.ydataview_moreinfo_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_info_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				.wp.wftwo.dataview.info insert 1.0 "Repository      : $repo\n"
				#  if we know of a browser, and this is a local package then use the package name to make a URL and insert tags accordingly
				if {$repo == "local" && $browser != ""} {
					# click on the link to view it in the selected browser
					.wp.wftwo.dataview.info tag bind get_aur <ButtonRelease-1> "exec $browser https://aur.archlinux.org/packages/$package &"
					# add the normal text to the text box
					.wp.wftwo.dataview.info insert end "Name            : " 
					# add the package name to the text box and use the pre-defined tags to alter how it looks
					.wp.wftwo.dataview.info insert end "$package\n" "url_tag get_aur url_cursor_in url_cursor_out" 
				} else {
					.wp.wftwo.dataview.info insert end "Name            : $package\n"
				}
				puts $debug_out(2) "\tinstalled is $version Available is $available"
				if {$available == "{}"} {
					.wp.wftwo.dataview.info insert end "Installed       : no\n"
					.wp.wftwo.dataview.info insert end "Available       : $version\n"
				} elseif {$available == "-na-"} {
					# either this was not in the AUR or the aur_versions thread did not run
					puts $debug_out(2) "\tavailable was $available"
					.wp.wftwo.dataview.info insert end "Installed       : $version\n"
					.wp.wftwo.dataview.info insert end "Available       : Searching ...\n"
					# update now to show the message while we find the (supposed) version available
					update
					# since this is an AUR package or another local install
					# we can use an RPC to get the latest version number and the description
					set result [get_aur_info $package]
					set version [lindex $result 1]
					puts $debug_out(2) "get_dataview - info - get aur version returned $version"
					if {$version == ""} {
						set version "not found in AUR"
					} else {
						set description [string map {\\ ""} [lindex $result 1]]
					}
					.wp.wftwo.dataview.info delete [expr [.wp.wftwo.dataview.info count -lines 0.0 end] -1].18 end
					.wp.wftwo.dataview.info insert end "$version \n"
					puts $debug_out(2) "get_dataview - info - version available is $version and description $description"
				} else {
					.wp.wftwo.dataview.info insert end "Installed       : $version\n"
					.wp.wftwo.dataview.info insert end "Available       : $available\n"
				}
				.wp.wftwo.dataview.info insert end "Member of       : $groups\n"
				# we may have a description already, either in the $info string or from get aur version above
				# but what do we do if we do not have a description yet?
				if {[string trim $description "{}"] == "DESCRIPTION"} {
					# it seems that we could not get the description from the AUR RPC call above
					.wp.wftwo.dataview.info insert end "Description     : Searching ...\n"
					update
					# lets try the long winded method
					set error [catch {exec pacman -b $tmp_dir -Qi $package} result]
					if {$error == 1} {
						set description "not found in AUR"
					} else {
						set description [string range [lindex [split $result \n] 2] 18 end]
					}
					.wp.wftwo.dataview.info delete [expr [.wp.wftwo.dataview.info count -lines 0.0 end] -1].18 end
					.wp.wftwo.dataview.info insert end "$description"
				} else {
					.wp.wftwo.dataview.info insert end "Description     : [string trim $description "{}"]"
				}
			}
			.wp.wftwo.dataview.moreinfo {
				puts $debug_out(2) "get_dataview - get moreinfo ([expr [clock milliseconds] - $start_time])"
				grid remove .wp.wftwo.ydataview_info_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_moreinfo_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				.wp.wftwo.dataview.moreinfo insert 1.0 "Searching ..."
				update
				set depends 0
				if {$available != "{}"} {
					# the package is installed
					if {$version != $available} {
						set depends [read_dependencies [list $package $version $available]]
					}
					# try to get the extended info from the local database if the package is installed
					puts $debug_out(2) "get_dataview - try local database ([expr [clock milliseconds] - $start_time])"
					set error [catch {exec pacman -b $tmp_dir -Qi $package} result]
					set result [split $result \n]
					# add in a line for the repository
					set result [linsert $result 0 "Repository      : $repo"]
				} else {
					# try to get the info from the main database
					puts $debug_out(2) "get_dataview - try sync database ([expr [clock milliseconds] - $start_time])"
					set error [catch {exec pacman -b $tmp_dir -Sii $package} result]
					set result [split $result \n]
				}
				# work out the spacing for each line from the second row, since we may have inserted the first row
				set index [string first ":" [lindex $result 1]]
				.wp.wftwo.dataview.moreinfo delete 1.0 end
				if {$error == 0} {
					set count 0
					foreach row $result {
						incr count
						# if this is row 1 then change the wording to Repository : ....
						if {$count == 1} {
							.wp.wftwo.dataview.moreinfo insert end "Repository[string repeat { } [expr $index - 10]]: $repo\n" 
							#  if we know of a browser, and this is a local package then use the package name to make a URL and insert tags accordingly
						} elseif {$repo == "local" && $browser != "" && $count == 2} {
							# click on the link to view it in the selected browser
							.wp.wftwo.dataview.moreinfo tag bind get_aur <ButtonRelease-1> "puts $debug_out(2) \"GET AUR URL\"; exec $browser https://aur.archlinux.org/packages/[string range $row [expr $index + 2] end] &"
							# add the normal text to the text box
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 0 [expr $index + 1]]" 
							# add the package name to the text box and use the pre-defined tags to alter how it looks
							.wp.wftwo.dataview.moreinfo insert end "[string range $row [expr $index + 2] end]\n" "url_tag get_aur url_cursor_in url_cursor_out" 
						#  if we know of a browser then find URL and insert tags accordingly
						} elseif {$browser != "" && [string first "URL" $row] == 0} {
							# click on the link to view it in the selected browser
							.wp.wftwo.dataview.moreinfo tag bind get_url <ButtonRelease-1> "puts $debug_out(2) \"GET URL - exec $browser [string range $row 18 end]\"; exec $browser [string range $row 18 end] &"
							# add the normal text to the text box
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 0 17]" 
							# add the URL to the text box and use the pre-defined tags to alter how it looks
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 18 end]\n" "url_tag get_url url_cursor_in url_cursor_out" 
						} else {
							if {[string first "Version" $row] == 0} {
								if {$available == "{}"} {
									.wp.wftwo.dataview.moreinfo insert end "Installed[string repeat { } [expr $index -9]]: no\n"
									.wp.wftwo.dataview.moreinfo insert end "Available[string repeat { } [expr $index -9]]: $version\n"
								} elseif {$available == "-na-"} {
									# so the thread lookup did not work, so get the available version now
									puts $debug_out(2) "get_dataview - moreinfo - available was -na-"
									.wp.wftwo.dataview.moreinfo insert end "Installed[string repeat { } [expr $index -9]]: $version\n"
									.wp.wftwo.dataview.moreinfo insert end "Available[string repeat { } [expr $index -9]]: Searching ...\n"
									update
									# since this is an AUR package or another local install
									# we can use an RPC to get the latest version number
									set result [get_aur_info $package]
									set version [lindex $result 1]
									if {$version == ""} {set version "not found in AUR"}
									# the following deletes the last newline character, which it is not supposed to do
									.wp.wftwo.dataview.moreinfo delete [expr [.wp.wftwo.dataview.moreinfo count -lines 0.0 end] -1].0 end
									# so we put it back here. This may be a bug in tk so check new releases.
									.wp.wftwo.dataview.moreinfo insert end "\nAvailable[string repeat { } [expr $index -9]]: $version\n"
									puts $debug_out(2) "get_dataview - moreinfo - version available is $version"
								} else {
									.wp.wftwo.dataview.moreinfo insert end "Installed[string repeat { } [expr $index -9]]: $version\n"
									.wp.wftwo.dataview.moreinfo insert end "Available[string repeat { } [expr $index -9]]: $available\n"
								}
							} elseif {[string first "Depends On" $row] == 0 && $depends != 0} {
								.wp.wftwo.dataview.moreinfo insert end "Depends On *[string repeat { } [expr $index -12]]: $depends\n"
							} else {
								.wp.wftwo.dataview.moreinfo insert end "$row\n"
							}
						}
					}
				} else {
					.wp.wftwo.dataview.moreinfo insert end "Could not get any information for $package"
				}
			}
			.wp.wftwo.dataview.files {
				grid remove .wp.wftwo.ydataview_info_scroll
				grid remove .wp.wftwo.ydataview_moreinfo_scroll
				grid .wp.wftwo.ydataview_files_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				.wp.wftwo.dataview.files insert 1.0 "Searching ..."
				update	
				# first try to get the file list from the local database
				# only works if the package is installed
				set error 1
				puts $debug_out(2) "get_dataview - files available is \"$available\"" 
				if {$available != "{}"} {
					puts $debug_out(2) "get_dataview - files - try to get files from the local database"
					set error [catch {exec pacman -b $tmp_dir -Qlq $package} result]
					set result [split $result \n]
					puts $debug_out(2) "get_dataview - files - pacman -Qlq $package returned $error: $result"
				}
				if {$error != 0} {
					# pacman could not get the file list from the local database
					# if pkgfile is installed then try that next
					if {[catch {exec which pkgfile}] == 0} {
						puts $debug_out(2) "get_dataview - files - try pkgfile"
						# if we have not been told to avoid updates
						if {![expr $pkgfile_upgrade & 2]} {
							puts $debug_out(2) "get_dataview - files - check if there is a files database available"
							# if the database file does not exist then try check_repo_files
							if {![file exists /var/cache/pkgfile/$repo.files]} {
								puts $debug_out(2) "get_dataview - files - there is no files database available run check_repo_files"
								# looks like the files database is missing, try to update the databases
								set error [check_repo_files /var/cache/pkgfile files]
								puts $debug_out(2) "get_dataview - files - check_repo_files (pkgfile) returned $error"
							} else {
								puts $debug_out(2) "get_dataview - files - there is a files database available check if it is in date"
								# now check if the database is up to date
								set mtime [file mtime "/var/cache/pkgfile/$repo.files"]
								if {[expr [clock seconds] > [clock add $mtime 1 day]]} {
									puts $debug_out(2) "get_dataview - files - the files database is not in date run test_files_data"
									# database is more than one day old, ask to update if not already refused
									if {![expr $pkgfile_upgrade & 1]} { 
										set error [test_files_data pkgfile]
										puts $debug_out(2) "get_dataview - -files -test_files_data (pkgfile) returned $error"
									}
								}
							}
						}
						if {[file exists $tmp_dir/sync/$repo.files]} {
							puts $debug_out(2) "get_dataview - files - there is a files database available so try it"
							# continue with the existing databases
							set error [catch {exec pkgfile -lq $package} result]
							set result [split $result \n]
							puts $debug_out(2) "get_dataview - files - pkgfile $package returned $error: $result"
							set detail ""
						} else {
							puts $debug_out(2) "get_dataview - files - the files database is missing"
							set error 1
							set result 0
							set detail " The database file is missing.\n\nClick on the folder icon to update the files data.\n"
						}
					}
					# if that failed, or pkgfile is not installed or missing databases, see if we can use pacman .files data
					if {$error != 0} {
						# pkgfile could not be used so try pacman files
						puts $debug_out(2) "get_dataview - files are not available from pkgfile, or from local pacman data, error is $error"
						# if we have not been told to avoid updates
						if {![expr $pacman_files_upgrade & 2]} {
							puts $debug_out(2) "get_dataview - files - check if there is a pacman files database available"
							# if the database file does not exist then try check_repo_fles
							if {![file exists $tmp_dir/sync/$repo.files]} {
								puts $debug_out(2) "get_dataview - files - there is no files database available run check_repo_files"
								# looks like the files database is missing, try to update the databases
								set error [check_repo_files $tmp_dir files]
								puts $debug_out(2) "get_dataview - files - check_repo_files (pacman) returned $error"
							} else {
								puts $debug_out(2) "get_dataview - files - there is a files database ($repo) available check if it is in date"
								# now check if the database is up to date
								set mtime [file mtime "$tmp_dir/sync/$repo.files"]
								if {[expr [clock seconds] > [clock add $mtime 1 day]]} {
									puts $debug_out(2) "get_dataview - files - the files database is not in date run test_files_data"
									# database is more than one day old, ask to update if not already refused
									if {![expr $pacman_files_upgrade & 1]} { 
										set error [test_files_data pacman]
										puts $debug_out(2) "get_dataview - files - test_files_data (pacman) returned $error"
									}
								}
							}
						}
						if {[file exists $tmp_dir/sync/$repo.files]} {
							puts $debug_out(2) "get_dataview - files - there is a files database available so try it"
							# continue with the existing databases
							set error [catch {exec pacman -b $tmp_dir -Flq $package} result]
							set result [split $result \n]
							puts $debug_out(2) "get_dataview - files - pacman -b $tmp_dir -Flq $package returned $error: $result"
							set detail ""
						} else {
							puts $debug_out(2) "get_dataview - files - the files database is missing"
							set error 1
							set result 0
							set detail " The database file is missing.\n\nClick on the folder icon to update the files data.\n"
						}
					}
				}
				# now show the results
				.wp.wftwo.dataview.files delete 1.0 end
				# check whether there was an error or, if the user cancelled the error message, the files for the package were not found.
				if {$error == 0} {
					puts $debug_out(2) "get_dataview - files no errors found"
					foreach row $result {
						.wp.wftwo.dataview.files insert end $row\n
					}
				} elseif {$error == 1 && $result != "0"} {
					puts $debug_out(2) "get_dataview - files found a file list with errors ($error) and removed the warnings"
					# result will be a file list followed by a warning
					foreach row $result {
						if {[string first "error:" $row] == 0} {break}
						if {[string first "warning:" $row] == 0} {break}
						.wp.wftwo.dataview.files insert end $row\n
					}
				} else {
					puts $debug_out(2) "get_dataview - files did not find a file list"
					.wp.wftwo.dataview.files insert end "Could not get the file list for $package.$detail\n"
				}
			}
			.wp.wftwo.dataview.check {
				grid remove .wp.wftwo.ydataview_info_scroll
				grid remove .wp.wftwo.ydataview_moreinfo_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				.wp.wftwo.dataview.check insert 1.0 "Checking ..."
				update
				set error [catch {exec pacman -b $tmp_dir -Qk $package} result]
				.wp.wftwo.dataview.check delete 1.0 end
				if {[string first "error:" $result] == -1} {
					set result [split $result \n]
					foreach row $result {
						.wp.wftwo.dataview.check insert end $row\n
					}
				} else {
					.wp.wftwo.dataview.check insert end "Could not check $package, it is not installed"
				}
			}
		}
	} else {
		set dataview ""
		[.wp.wftwo.dataview select] delete 1.0 end
	}
	puts $debug_out(1) "get_dataview - completed and returned 0 - ([expr [clock milliseconds] - $start_time])"
	return 0
}

proc get_file_mtime {dir ext} {

global debug_out
# find the latest modified time for a series of files with a given extention in the given directory	

	puts $debug_out(1) "get_file_mtime - called for *.$ext files in $dir"
	set last 0
	set files [glob -nocomplain $dir/*.$ext]
	foreach file $files {
		set time [file mtime $file]
		if {$last < $time} {set last $time}
	}
	puts $debug_out(1) "get_file_mtime completed"
	return $last
}

proc get_mirrorlist {} {
	
global debug_out dlprog tmp_dir
# get the latest mirrorlist

	puts $debug_out(1) "get_mirrorlist called"
	
	# backup any existing list just in case the download fails
	if {[file exists "$tmp_dir/mirrorlist.latest"]} {
		file rename -force "$tmp_dir/mirrorlist.latest" "$tmp_dir/mirrorlist.backup"
	}

	set error 1
	puts $debug_out(2) "get_mirrorlist - called test_internet"
	if {[test_internet] == 0} {
		if {$dlprog == "curl"} {
			set error [catch {exec curl -o "$tmp_dir/mirrorlist.latest" "https://archlinux.org/mirrorlist/all/"}]
		} elseif {$dlprog == "wget"} {
			set error [catch {exec wget -q -O "$tmp_dir/mirrorlist.latest" "https://archlinux.org/mirrorlist/all/"}]
		}
		if {$error != 0} {
			puts $debug_out(2) "get_mirrorlist - failed to download mirrorlist"
		}
	}
	# if the error is not 0 then either there was no internet or the download failed
	# see what mirrorlist file is available, if any
	if {[file exists "$tmp_dir/mirrorlist.latest"]} {
		return 0
	} elseif {[file exists "$tmp_dir/mirrorlist.backup"]} {
		# use the previous "latest" file, the update time will be shown in the Update Mirrorlist process
		file rename -force "$tmp_dir/mirrorlist.backup" "$tmp_dir/mirrorlist.latest"
	} else {
		return 1
	}
	
}

proc get_password {master} {
	
global debug_out env pw_entry su_cmd win_mainx win_mainy
# env is a system variable
# returns a password or 3 if cancelled

	puts $debug_out(1) "get_password called"
	
	set window true
	set prompt "\[su\] Password: "
	set width 250
	if {$su_cmd == "sudo"} {
		set prompt "\[sudo\] password for $env(USER): "
		set width 325
	}
	toplevel .password
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {$width / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {80 / 2}]
	wm geometry .password ${width}x80+$left+$down
	wm iconphoto .password tools
	wm protocol .password WM_DELETE_WINDOW {.password.cancel invoke}
	wm resizable .password 0 0
	wm title .password "A password is required"
	wm transient .password $master

	# CONFIGURE PASSWORD WINDOW
	label .password.password_label 
	.password.password_label configure -text $prompt
	entry .password.entry \
		-borderwidth 0 \
		-show * \
		-width 15
	bind .password.entry <Return> {
		catch {.password.select invoke}
	}
	frame .password.buttons
		button .password.select \
			-command {
				set pw_entry [.password.entry get]
				destroy .password
			} \
			-text "OK" \
			-width 6
		button .password.cancel \
			-command {
				set pw_entry 3
				destroy .password
			} \
			-text "Cancel" \
			-width 6
	grid .password.password_label -in .password -row 2 -column 2 \
		-sticky w
	grid .password.entry -in .password -row 2 -column 3 \
		-sticky e
	grid .password.buttons -in .password -row 4 -column 1 \
		-columnspan 4 \
		-sticky we
		grid .password.select -in .password.buttons -row 1 -column 2 \
			-sticky w
		grid .password.cancel -in .password.buttons -row 1 -column 3 \
			-sticky e
	
	grid rowconfigure .password 1 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .password 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .password 3 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .password 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .password 5 -weight 0 -minsize 10 -pad 0
				
	grid columnconfigure .password 1 -weight 0 -minsize 10 -pad 0
	grid columnconfigure .password 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .password 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .password 4 -weight 0 -minsize 10 -pad 0
		
	grid rowconfigure .password.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .password.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .password.buttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .password.buttons 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .password.buttons 4 -weight 1 -minsize 0 -pad 0
	
	focus .password
	
	update
	grab set .password
	focus .password.entry
	
	tkwait window .password
	puts "Password Window Closed ($pw_entry)"
	return $pw_entry
}

proc get_sync_time {} {
	
global dbpath debug_out start_time tmp_dir
# check last modified times for the pacman database 
# check last modified times for the temporary database 
# check that the temporary sync database exists and is the same or newer than the pacman database

	puts $debug_out(1) "get_sync_time called - ([expr [clock milliseconds] - $start_time])"
	set sync_mtime 0
	set sync_dbs [glob -nocomplain "$dbpath/sync/*.db"]
	# get the last sync time from the sync directory timestamp
	set sync_mtime [file mtime "$dbpath/sync"]
	# check if the tmp database copy is older than the sync database, and update or create it as necessary
	if {[file isdirectory $tmp_dir/sync]} {
		# update_db will update the copy of the sync directory if necessary
		if {$sync_mtime > [file mtime $tmp_dir/sync]} {update_db}
	} else {
		# temp sync directory does not exists, so create it
		update_db
	}
	# now return the tmp directory sync time
	puts $debug_out(1) "get_sync_time completed - ([expr [clock milliseconds] - $start_time])"
	return [list [file mtime $tmp_dir/sync] $sync_mtime]
}

proc get_system_data {data} {

global debug_out system tmp_dir
# if thread_get_system_data has returned the system value then set the system variable here,
# if not then check that the system variable was already set, if not, either the thread did not finish or it never ran
# so initialize it now

	puts $debug_out(1) "get_system_data called"
	if {$data != ""} {
		puts $debug_out(1) "get_system_data - system data found"
		set system [split $data \n]
	}
	
	if {$system == ""} {
		puts $debug_out(1) "get_system_data - system data not found"
		set_message "terminal" "Fetching system data"
		update
		set system [split [eval [concat exec pacman -b $tmp_dir -Si]] \n]
		set_message "terminal" ""
		update
	}
	puts $debug_out(1) "get_system_data completed"
}

proc get_terminal {} {

global debug_out start_time su_cmd terminal terminal_string tmp_dir
# no terminal is configured or found in the known_terminals list, try to get a valid terminal and terminal_string
	
	puts $debug_out(1) "get_terminal called"
	
	set detail ""
	set error 1
	
	set ans [tk_messageBox -default yes -detail "Do you want to install xterm now?\t(recommended)\n\nIf not then go to Tools > Options and enter a terminal and a valid terminal string." -icon warning -message "Vpacman requires a known terminal to function." -parent . -title "No known terminal found" -type yesno]

	if {$ans == "yes"} {
		puts $debug_out(2) "get_terminal - called test_internet"
		if {[test_internet] == 0} {
			# try to install xterm
			puts $debug_out(2) "get_terminal - try to install xterm terminal ([expr [clock milliseconds] - $start_time])"
			if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
				puts $debug_out(2) "get_terminal - write shell script"
				set fid [open $tmp_dir/vpacman.sh w]
				puts $fid "#!/bin/sh"
				puts $fid "password=\$1"
				if {$su_cmd == "su -c"} {
					puts $fid "echo \$password | $su_cmd \"pacman --noconfirm -S xterm\" > $tmp_dir/errors 2>&1"
				} else {
					puts $fid "echo \$password | $su_cmd -S -p \"\" pacman --noconfirm -S xterm > $tmp_dir/errors 2>&1"
				}
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				close $fid
				exec chmod 0755 "$tmp_dir/vpacman.sh"
				puts $debug_out(2) "get_terminal - get a password"
				# get the password
				set password [get_password "."]
				# password will be set to an error of 3 if the password procedure was cancelled
				if {$password != 3} {
					puts $debug_out(2) "get_terminal - run the script"
					set error [catch {eval [concat exec $tmp_dir/vpacman.sh $password]} result]
					# don't save the password
					unset password
					puts $debug_out(2) "get_terminal - ran vpacman.sh with error $error and result \"$result\""
				} else {
					unset password
					set error 1
					set result "Authentication failure"
					puts $debug_out(2) "get_terminal - get_password cancelled"
				}
				if {$error == 1} {
					# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
					# the second error message will be displayed instead, which is not too bad.
					if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
						puts $debug_out(2) "get_terminal - Authentification failed"
						set detail "Authentication failed - install terminal cancelled. "
					} else {
						puts $debug_out(2) "get_terminal- install xterm failed"
						set detail "Could not install xterm - install terminal cancelled. "
					}
					tk_messageBox -default ok -detail "$detail" -icon warning -message "Could not install xterm." -parent . -title "Install terminal failed" -type ok
				}
				file delete $tmp_dir/vpacman.sh
				file delete $tmp_dir/errors
			} else {
				set error [catch {eval [concat exec $su_cmd pacman --noconfirm -S xterm]} error_message]
			}
		}
		# we could check for an error or simply check that xterm has been installed
		if {[catch {exec which xterm}] == 1} {
			puts $debug_out(2) "get_terminal - install xterm failed error: $error - \"$error_message\""
		} else {
			puts $debug_out(2) "get_terminal - installed xterm"
			set terminal "xterm"
			set terminal_string "xterm -title <title> -e <command>"
			# installed xterm so update the lists
			set_message terminal "Xterm has been installed"
			update
			puts $debug_out(2) "get_terminal - now call start"
			# call start
			start
			filter
		}		
	}
	# either the answer was no, or there was an error installing xterm
	if {$terminal == ""} {
		puts $debug_out(2) "get_terminal - failed to install xterm so call configure to manually select a terminal"
		set terminal_string ""
		configure 
		# wait for the configure window to close
		tkwait window .config
		if {$terminal == ""} {
			puts $debug_out(1) "get_terminal - failed, cannot continue, exit now"
			tk_messageBox -default ok -detail "$detail\nVpacman will exit now" -icon warning -message "Vpacman requires a known terminal to function." -parent . -title "No known terminal entered" -type ok
			exit
		}
	}
	puts $debug_out(1) "get_terminal completed"
	return 0
}

proc get_terminal_string {terminal} {

global debug_out known_terminals	
# get the terminal_string for terminal from the known_terminals string
	
	puts $debug_out(1) "get_terminal_string called for $terminal"
	if {[lsearch $known_terminals $terminal] == -1} {
		set terminal_string "$terminal --title <title> --command <command>"
		puts $debug_out(2) "get_terminal_string - terminal $terminal is unknown, string is set to default $terminal_string"
		
		tk_messageBox -default ok -detail "The terminal \"$terminal\" is unknown.\n  - \"$terminal\" must be installed.\n  - The terminal string is used to call a terminal session and must include <title> to indicate the window title and <command> for the command to be run.\n\nNow edit and correct the terminal string as necessary." -icon info -message "The Terminal String has been set to default" -parent . -title "New Terminal" -type ok
		
		focus .config.terminal_string
		.config.terminal_string icursor 0
	} else {
		foreach {name string} $known_terminals {
			if {$name == $terminal} {
				set terminal_string "$name $string"
				break
			}
		}
		focus .config.terminal_string
		puts $debug_out(2) "get_terminal_string - terminal is $terminal - string is $terminal_string"
	}	
	.config.terminal selection clear
	.config.terminal_string selection clear
	puts $debug_out(1) "get_terminal_string completed and returned $terminal_string"
	return $terminal_string
}

proc get_win_geometry {} {
	
global debug_out geometry geometry_config win_configx win_configy win_mainx win_mainy
# calculate various window geometry variables from the current geometry settings excluding borders

	puts $debug_out(1) "get_win_geometry called"
	# calculate the position of the main window
	set win_mainx [string range $geometry [string first "+" $geometry]+1 [string last "+" $geometry]-1]
	set win_mainy [string range $geometry [string last "+" $geometry]+1 end]
	# calculate the size of the config window
	set win_configx [string range $geometry_config 0 [string first "x" $geometry_config]-1]
	set win_configy [string range $geometry_config [string first "x" $geometry_config]+1 end]
	puts $debug_out(1) "get_win_geometry completed"
}

proc grid_remove_listgroups {} {
	
global debug_out start_time
	
	puts $debug_out(1) "grid_remove_listgroups called - ([expr [clock milliseconds] - $start_time])"
	grid remove .listgroups
	grid remove .scroll_selectgroup
	.group_button configure -command {grid_set_listgroups; .listgroups selection clear 0 end}
	bind .listgroups <Motion> {}
	bind .listgroups <<ListboxSelect>>  {}
	bind .menubar <ButtonRelease-1> {}
	foreach child [winfo children .buttonbar] {
		bind $child <ButtonRelease-1> {}
	}
	bind .filters <ButtonRelease-1> {}
	bind .wp.wfone.listview <ButtonRelease-1> {}
	bind .wp.wftwo.dataview <ButtonRelease-1> {}
	puts $debug_out(1) "grid_remove_listgroups completed - ([expr [clock milliseconds] - $start_time])"
}
	
proc grid_set_listgroups {} {

global debug_out group group_index list_groups
# create the listgroups widget and its bindings
	
	puts $debug_out(1) "grid_set_listgroups called"
	grid .listgroups
	grid .scroll_selectgroup
	set group_index [lsearch -exact $list_groups $group]
	puts $debug_out(2) "grid_set_listgroups - Found $group at $group_index"
	if {$group_index == -1} {set group_index 0}
	.listgroups yview $group_index
	# go too fast and this will fail - just ignore the error
	catch {.listgroups itemconfigure $group_index -background #c6c6c6}
	.group_button configure -command {grid_remove_listgroups}
	
	bind .listgroups <Motion> {
		.listgroups itemconfigure $group_index -background white
		.listgroups itemconfigure @%x,%y -background #c6c6c6
		set group_index [.listgroups index @%x,%y]
	}
	bind .listgroups <Down> {
		.listgroups itemconfigure $group_index -background white
		if {$group_index != [expr [llength $list_groups] - 1]} {set group_index [expr $group_index + 1]}
		.listgroups itemconfigure $group_index -background #c6c6c6
	}
	bind .listgroups <Up> {
		.listgroups itemconfigure $group_index -background white
		if {$group_index != 0} {set group_index [expr $group_index - 1]}
		.listgroups itemconfigure $group_index -background #c6c6c6
	}
	bind .listgroups <space> {
		set group [.listgroups get $group_index]
		filter
		grid_remove_listgroups
		focus .group_entry
	}
	bind .listgroups <<ListboxSelect>>  {
		# .listgroups curselection should not be blank, but check anyway
		if {[.listgroups curselection] != ""} {
			set group [.listgroups get [.listgroups curselection]]
			filter
			grid_remove_listgroups
		}
	}
	bind .menubar <ButtonRelease-1> {
		grid_remove_listgroups
	}
	foreach child [winfo children .buttonbar] {
		bind $child <ButtonRelease-1> {
			grid_remove_listgroups
		}
	}
	bind .filters <ButtonRelease-1> {
		grid_remove_listgroups
	}
	bind .wp.wfone.listview <ButtonRelease-1> {
		grid_remove_listgroups
	}
	bind .wp.wftwo.dataview <ButtonRelease-1> {
		grid_remove_listgroups
	}
	puts $debug_out(1) "grid_set_listgroups completed"
}

# THE LIST PROCEDURES CALCULATE ALL OF THE LISTS OF PACKAGES THAT WE WILL NEED FOR THE FUTURE
# INCLUDING THE LIST OF PACKAGES CURRENTLY SHOWN IN THE LISTVIEW WINDOW AND ANY SPECIAL LIST OPTIONS

proc list_all {} {

global debug_out list_all list_local list_local_ids list_installed list_outdated list_uninstalled list_show_order start_time tmp_dir
# get a list of all available packages in package order as:
# Repo Package Version Available Group(s) Description

	puts $debug_out(1) "list_all called ([expr [clock milliseconds] - $start_time])"
	
	set list_all ""
	set list_installed ""
	set list_outdated ""
	set list_uninstalled ""
	# we could get the full system data here to use later, with pacman -Si, but this takes half the time!
	set details [split [exec pacman -b $tmp_dir -Ss] \n]
	foreach {element description} $details {
		# find the group(s) that the package belongs to
		set group [string map {\  \,} [string range $element [string first "(" $element] [string first ")" $element]]]
		if {$group == ""} {set group "-none-"}
		# if the item has been installed then set the third and fourth field to the current version
		set index [string first "\[" $element]
		if {$index != -1} {
			# this item has been installed
			set installed [lrange $element 1 1]
			set installed_index [string first ":" $element $index]
			if {$installed_index != -1} {
				# so a new version is available
				set installed [string range $element [expr $installed_index + 2] [string first "\]" $element]-1]
			}
			set item "[string map {\/ \ } [lrange $element 0 0]] $installed [lrange $element 1 1] [string trim $group "()"] \{[string trim $description]\}"
			lappend list_installed $item
			if {$installed != [lrange $element 1 1]} {
				# is available newer than installed?
				# if installed does not equal the available version then it may be newer!!!
				if {[test_versions $installed [lrange $element 1 1]] == "newer"} {
					lappend list_outdated $item
				}
			}
		} else {
			# otherwise leave the fourth field blank
			set item "[string map {\/ \ } [lrange $element 0 0]] [lrange $element 1 1] \"\" [string trim $group "()"] \{[string trim $description]\}"
			lappend list_uninstalled $item
		}	
		lappend list_all $item
	}
	# join the local package list to the packages installed from the database and sort them into the required order
	set list_all [concat $list_all $list_local]
	set list_all [sort_list $list_all]
	# find the index of each local package and record it in list_local_ids
	set index ""
	set list_local_ids ""
	foreach element $list_local {
		set index [lsearch $list_all $element]
		set list_local_ids [lappend list_local_ids [list [lindex $element 1] $index]]
	}
	puts $debug_out(1) "list_all completed ([expr [clock milliseconds] - $start_time])"
}

proc list_groups {} {
	
global debug_out list_groups start_time tmp_dir
# get a list of all available groups

	puts $debug_out(1) "list_groups called ([expr [clock milliseconds] - $start_time])"
	set list_groups "All\n[exec pacman -b $tmp_dir -Sg | sort -d]"
	puts $debug_out(1) "list_groups completed ([expr [clock milliseconds] - $start_time])"
}

proc list_local {} {

global debug_out list_local start_time tmp_dir
# get a list of locally installed packages
# returns local_list as Repo Package Version Available(na) Group(s) Description
	
	puts $debug_out(1) "list_local called ([expr [clock milliseconds] - $start_time])"
	
	set list_local ""
	# get the list in the form Package Version
	set error [catch {exec pacman -b $tmp_dir -Qm} local]
	if {$error != 0} {
		puts $debug_out(1) "list_local - executed Pacman -Qm with error $error and result $local"
		# why is this check here? because pacman suggests a -Sy when new repositories are detected, which is not recommended!
		if {[string first "use \'-Sy\' to download" $local] != -1} {
			tk_messageBox -default ok -detail "The temporary sync database will need to be updated.\n\nConsider running a full system upgrade to avoid further errors." -icon info -message "There are new repositories detected." -parent . -title "Update Sync Database" -type ok
			execute "sync"
		}
		set local ""
	}
	set local [split $local \n]
	# now add the remaining fields, plus a placeholder for the available version and the description, for the item and add it to list_local

	# looking up the descriptions for 32 local items takes an extra 0.7 seconds in the start up time
	# we could consider using the aur_versions thread
	# the problem with this would be if there is no internet available, in which case the description
	# which is available in the local database, would not be searched in any find procedure
	foreach {element} $local {
		set item "local [lrange $element 0 0] [lrange $element 1 1] -na- -none- DESCRIPTION"
		lappend list_local $item
	}
	puts $debug_out(1) "list_local completed ([expr [clock milliseconds] - $start_time])"
}

proc list_special {execute_string} {

global debug_out filter list_all list_local list_special start_time tmp_dir
# get a list of requested packages
# returns list as Repo Package Version Available(na) Group(s) Description

	puts $debug_out(1) "list_special - called to execute $execute_string ([expr [clock milliseconds] - $start_time])"
	set list_special ""
	set paclist ""
	set tmp_list ""

	# now execute the command
	# some of these commands return an error if there are no results so we need to catch those errors
	set error [catch {eval [concat exec $execute_string]} paclist]
	puts $debug_out(2) "list_special - ran $execute_string with error $error ([expr [clock milliseconds] - $start_time])"
	if {[llength $paclist] > 1} {set paclist [split $paclist \n]}

	# and handle the error:
	# for the pacman -Qtq and pacman -Qdtq the error normally means that the command returned nothing
	if {$error != 0} {
		if {$execute_string == "pacman -b $tmp_dir -Qtq"} {
			set paclist ""
		} elseif {$execute_string == "pacman -b $tmp_dir -Qdtq"} {
			if {$paclist == "{child process exited abnormally}"} {
				set paclist ""
			} else {
				set_message terminal "Pacman find orphan packages (-Qdtq) returned an error - please try again"
				return "error"
			}
		}
	}
	# paclist should now be a clean list of all the packages found by the command.
	# now find the details of the package and make a list to show them
	puts $debug_out(2) "list special - for each element find its details ([expr [clock milliseconds] - $start_time])"

	# tried three different methods to find 
	# to find the details the regex method takes 0.05 seconds
	# we need to quote any odd characters or regex will not compile
	#foreach element $paclist {
	#	set element [string map {+ \\\+ - \\\-} $element]
	#	set values [lindex $list_all [lsearch -regex $list_all "^\[a-zA-Z\]+\\y $element \\y *"]]
	#	lappend list $values
	#}
	# while the eq method takes 0.27 seconds
	#foreach values $list_all {
	#    foreach element $paclist {
	#        if {[lindex [split $values] 1] eq $element} {
	#            lappend list $values
	#			break
	#        }
	#    }
	#}
	# the third method is the quickest so far
	set tmp_list ""
	foreach element $list_all {
		lappend tmp_list [lindex [split $element] 1]
	}
	puts $debug_out(2) "list special created a list of packages ([expr [clock milliseconds] - $start_time])"
	puts $debug_out(2) "\tnow get the details for each of the packages found"
	foreach element $paclist {
		set values [lindex $list_all [lsearch $tmp_list $element]]
		lappend list_special $values
	}
	puts $debug_out(2) "list special completed - now call list_show"
	list_show [lsort -dictionary -index 1 $list_special]
	puts $debug_out(1) "list special completed ([expr [clock milliseconds] - $start_time])"
	return [llength $list_special]
}

proc list_show {list} {

global debug_out list_local_ids list_show list_show_ids listview_selected_in_order part_upgrade start_time tv_index tv_select
# Show the list of packages in the .wp.wfone.listview window maintaining any selected items if possible
# Repo Package Version Available Group(s) Description

	puts $debug_out(1) "list_show - called ([expr [clock milliseconds] - $start_time])"

	# first save the names of the packages selected in the selected order
	set listview_selected_names ""
	foreach item $listview_selected_in_order {
		lappend listview_selected_names [lrange [.wp.wfone.listview item $item -values] 1 1]
	}
	# now delete the contents from  listview
	.wp.wfone.listview delete [.wp.wfone.listview children {}]
	# and show the new list in listview
	set list_show ""
	set list_show_ids ""
	set listview_selected_in_order ""
	# save only the first two items (name and list_all index) in list_local_ids
	set tmp_list ""
	foreach line $list_local_ids {set tmp_list [lappend tmp_list [lrange $line 0 1]]}
	set list_local_ids $tmp_list
	# save done
	set new_listview_selected ""
	set tv_index ""
	puts $debug_out(2) "list_show - show all the [llength $list] elements ([expr [clock milliseconds] - $start_time])"
	foreach element $list {
		lappend list_show $element
		set id [.wp.wfone.listview insert {} end -values $element]
		if {$tv_index == ""} {set tv_index $id}
		lappend list_show_ids $id
		if {[lrange $element 0 0] == "local"} {
			# add the index of the list_show to list_local_ids
			# find the line number of the element in list_local_ids
			set lineno [lsearch -index 0 $list_local_ids [lindex $element 1]]
			# find the index in list_show
			set index [lsearch $list_show $element]
			# now add the list_show index and the id of the treeview_list to list_local_ids
			set list_local_ids [lreplace $list_local_ids $lineno $lineno [linsert [lindex $list_local_ids $lineno] end $index $id]]
		}
		# if the item has been installed then tag it with the installed tag if a new version is available then tag it as outdated
		if {[lrange $element 3 3] != "{}"} {
			if {[lrange $element 2 2] == [lrange $element 3 3] || [lrange $element 3 3] == "-na-"} {
				# installed version equals available version or available version is unknown so...
				.wp.wfone.listview tag add installed $id
			} elseif {[lrange $element 0 0] == "local"} {
				# now test for the local special case
				# there are no special tests for an "r" in the versions
				# if the two versions are not the same
				if {[lrange $element 2 2] != [lrange $element 3 3]} {
					set test [test_versions [lrange $element 2 2] [lrange $element 3 3]]
					if {$test == "newer"} {
						.wp.wfone.listview tag add outdated $id
### temporarily add an asterix to the new version number
###.wp.wfone.listview item $id -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
###
					} elseif {$test == "older"} {
						# the available versions seems to be older, but just mark it as installed for now
						.wp.wfone.listview tag add installed $id
					}
				} else {
					.wp.wfone.listview tag add installed $id
				}
			} else {
### temporarily add an asterix to the new version number
###.wp.wfone.listview item $id -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
###
				.wp.wfone.listview tag add outdated $id
			}
		}
		# if the item was previously selected then select it again
		# this selection will call bind again, so we will need to completely rewrite listview_selected_in_order
		# and save the id of the item, if it is in the new list, in the same order
		# so new_listview_selected will include all the items proviously selected from this list
		set index [lsearch $listview_selected_names [lrange $element 1 1]]
		if {$index != -1} {
			lappend new_listview_selected "$index $id"
		}
	}
	puts $debug_out(2) "list_show - show all the elements completed for [llength $list] packages (new listview selected is [llength $new_listview_selected] long) ([expr [clock milliseconds] - $start_time])"
	if {$new_listview_selected != ""} {
		set new_listview_selected [lsort -index 0 $new_listview_selected]
		# now add each of the selected items to the listview in the correct order
		# bind TreeviewSelect will update all the variables, and the mark entry on the popup menu, when the selection changes
		set tv_select ""
		foreach {item} $new_listview_selected {
			.wp.wfone.listview selection add [lindex $item 1]
		}
		vwait tv_select
		puts $debug_out(2) "list_show - Treeview Select has completed ([expr [clock milliseconds] - $start_time])"
	} else {
		puts $debug_out(2) "list_show - there are no selections from [llength $list] packages, set blank message and dataview"
		# we have just shown a new list and nothing is selected, so reset the menu entries
		set_message selected ""
		get_dataview ""
		puts $debug_out(2) "list_show - reset buttons and remove 'Mark' from popup menu"
		.buttonbar.install_button configure -state disabled
		.buttonbar.delete_button configure -state disabled
		.menubar.edit entryconfigure 0 -state normal
		.menubar.edit entryconfigure 1 -state disabled
		.menubar.tools entryconfigure 1 -state disabled
		.menubar.tools entryconfigure 2 -state disabled
		.listview_popup entryconfigure 1 -state disabled
		.listview_popup entryconfigure 2 -state disabled
		.listview_popup entryconfigure 3 -state normal
		.listview_popup entryconfigure 4 -state disabled
		# and unpost the mark entry on the popup menu if it exists
		catch {.listview_popup delete "Mark"}
		if {[llength $list] == 0} {
			# and nothing is listed
			puts $debug_out(2) "list_show - there is nothing listed"
			.menubar.edit entryconfigure 0 -state disabled
			.listview_popup entryconfigure 3 -state disabled
		}
		puts $debug_out(2) "list_show - partial upgrades set to no"
		set part_upgrade 0
	}
	puts $debug_out(2) "list_show - listview_selected_in_order is \"$listview_selected_in_order\""
	if {[llength $listview_selected_in_order] != 0} {
		puts $debug_out(1) "\tmove to last selected item"
		.wp.wfone.listview see [lindex $listview_selected_in_order end]
	} else {
		puts $debug_out(2) "\tmove to first item"
		.wp.wfone.listview xview moveto 0
		.wp.wfone.listview yview moveto 0
	}
	puts $debug_out(1) "list_show - finished ([expr [clock milliseconds] - $start_time])"
	return 0
}

proc make_backup_lists {} {
	
global backup_dir debug_out
# make lists of all the installed packages
# returns 0 success, 1 failed, 3 cancelled
	
	puts $debug_out(1) "make_backup_lists called"
	# the next code will call tk_getOpenFile 
	catch {tk_getOpenFile no file}
	# and arrange to hide the hidden files
	set ::tk::dialog::file::showHiddenVar 0
	# and display a button to show hidden files
	set ::tk::dialog::file::showHiddenBtn 1
	# and set a title for the window
	set title "Select a directory for the backup lists"
	# try to enlarge the window immediately after it opens
	after 100 {exec wmctrl -r "Select a directory for the backup lists" -e 0,-1,-1,600,350}
	# now get a directory to hold the files
	set dir [tk_chooseDirectory -initialdir $backup_dir -title $title]
	# if no directory has been chosen then return
	if {$dir eq ""} {
		puts $debug_out(1) "make_backup_lists cancelled from select directory"
		return 3
	# if a directory has been specified make sure that it exists
	} elseif {![file isdirectory $dir]} {
		file mkdir $dir
	}
	# mow make the backup lists
	set_message terminal "Writing backup lists to $dir"
	update
	set backup_dir $dir
	set date [clock format [clock seconds] -format "_%Y%m%d"]
	set error [catch {
		# there are three lists to save	
		# list all the files explicitly installed, no foreign packages
		exec pacman -Qqen > $backup_dir/pacman_explicit$date.txt
		# list files installed as dependencies
		exec pacman -Qqd > $backup_dir/pacman_depends$date.txt
		# list all the foreign packages
		exec pacman -Qqem > $backup_dir/aur_local$date.txt
		# copy the pacman configureation file
		file copy -force /etc/pacman.conf $backup_dir/pacman$date.conf
	} error_message]
	puts $debug_out(2) "Lists completed with error: $error - \"error_message\""
	if {$error != 0} {
		puts $debug_out(1) "make_backup_lists failed with error: $error - \"$error_message\""
		tk_messageBox -default ok -detail "$error_message" -icon error -message "Failed to make the backup lists." -parent . -title "Error." -type ok 
		return 1
	} else {
		set text "
Make Backup Lists completed successfully and saved the backup lists and a copy of the pacman configuration file to $backup_dir. 

The following lists were created:

<lm1>	A list of all explicitly installed packages \"pacman_explicit$date.txt\" which can be used to reinstall the packages in the event of a reinstallation or installation of a new system.

	A list of all packages installed as dependencies of other packages \"pacman_depends$date.txt\".
	
	A list of all AUR and locally installed packages \"aur_local$date.txt\" which can be used to reinstall, individually, the AUR or locally installed packages.</lm1>
	
These three lists contain the names of all of the packages, known to pacman, which are installed on the system.

Consider copying the backup files to a remote location.

To reinstall the pacman packages execute <code>pacman -S --needed < $backup_dir/pacman_explicit$date.txt</code>."

		view_text $text "Make Backup Lists - Success"
	}
	set_message reset ""
	update
	puts $debug_out(1) "make_backup_lists completed"
	return 0
}

proc mirrorlist_countries {source} {
	
global debug_out mirror_countries win_mainx win_mainy
# return a list of countries selected from a given list
	
	puts $debug_out(1) "mirrorlist_countries called with \"$source\""
	
	toplevel .update_mirrors.countries
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {850 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {320 / 2}]
	wm geometry .update_mirrors.countries 850x320+$left+$down
	wm iconphoto .update_mirrors.countries tools
	wm protocol .update_mirrors.countries WM_DELETE_WINDOW {
		# assume cancel select, see button .update_mirrors.countries.cancel
		.update_mirrors.countries.cancel invoke
	}
	wm resizable .update_mirrors.countries 0 0
	wm title .update_mirrors.countries "Select Country Mirrors"
	wm transient .update_mirrors.countries .update_mirrors

# CONFIGURE SELECT COUNTRIES WINDOW

	set fid [open $source r]
	set mirrorlist [read $fid]
	close $fid
	# now get the country list
	set country ""
	set all_countries ""
	foreach line [split $mirrorlist "\n"] {
		if {[string trim $line] == "##" || [string trim $line] == ""} {continue}
		if {[string first "Arch Linux repository mirrorlist" $line] != -1} {continue}
		if {[string first "Generated on" $line] != -1} {continue}
		if {[string first "##" $line] != -1} {
			set country [string trim [string range $line 2 end]]
			lappend all_countries $country
		}
	}
	set country ""
	puts $debug_out(2) "mirrorlist_countries - there are [llength $all_countries] countries"
	puts $debug_out(2) "mirrorlist_countries - arrange them over five columns"
	set columns 5
	
	# create the necessary columns and grid them into columns two etc.
	
	set count 1
	while {$count <= $columns} {
		listbox .update_mirrors.countries.list${count} \
			-exportselection false \
			-height 14 \
			-selectbackground blue \
			-selectforeground white \
			-selectmode multiple \
			-width 20
		grid .update_mirrors.countries.list${count} -in .update_mirrors.countries -row 2 -column [expr $count + 1] \
			-sticky w
		balloon_set .update_mirrors.countries.list${count} "Select all of the coutries to be included in the mirrorlist."
		incr count
	}
	
	# create the rest of the widgets
	
	frame .update_mirrors.countries.buttons

		button .update_mirrors.countries.select \
			-command {
				puts $debug_out(2) "mirrorlist_countries - select called"
				set countries ""
				set separator ""
				set count 1
				while {$count <= 5} {
					set selection [.update_mirrors.countries.list${count} curselection]
					foreach item $selection {
						set name [.update_mirrors.countries.list${count} get $item]
						set countries "${countries}${separator}${name}"
						set separator ", "
					}
					incr count
				}
				set mirror_countries $countries
				grab release .update_mirrors.countries
				destroy .update_mirrors.countries
				puts $debug_out(1) "mirrorlist_countries - return $mirror_countries"
				return $mirror_countries
			} \
			-text "Select"
		button .update_mirrors.countries.cancel \
			-command {
				puts $debug_out(1) "mirrorlist_countries - cancelled"
				grab release .update_mirrors.countries
				destroy .update_mirrors.countries
			} \
			-text "Cancel"
	
	# and grid them
		
	grid .update_mirrors.countries.buttons -in .update_mirrors.countries -row 4 -column 3 \
		-columnspan 3 \
		-sticky we
	grid .update_mirrors.countries.select -in .update_mirrors.countries.buttons -row 1 -column 1 \
		-sticky w
	grid .update_mirrors.countries.cancel -in .update_mirrors.countries.buttons -row 1 -column 2 \
		-sticky e

	# Resize behavior management

	grid rowconfigure .update_mirrors.countries 1 -weight 0 -minsize 30 -pad 0
	grid rowconfigure .update_mirrors.countries 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors.countries 3 -weight 0 -minsize 20 -pad 0
	grid rowconfigure .update_mirrors.countries 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors.countries 5 -weight 0 -minsize 20 -pad 0

	grid columnconfigure .update_mirrors.countries 1 -weight 0 -minsize 15 -pad 0
	grid columnconfigure .update_mirrors.countries 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries 3 -weight 0 -minsize 5 -pad 0
	grid columnconfigure .update_mirrors.countries 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries 5 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries 6 -weight 0 -minsize 15 -pad 0

	grid rowconfigure .update_mirrors.countries.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries.buttons 2 -weight 1 -minsize 0 -pad 0

	
	
	# calculate the number of lines for each listbox
	set lines [expr int(([llength $all_countries] / ${columns}.0) + 0.9)]
	# now populate the listboxes
	foreach item [split $mirror_countries ","] {lappend countries [string trim $item]}
	set count 1
	puts $debug_out(2) "mirrorlist_countries - populate the columns with the [llength $all_countries] countries"
	puts $debug_out(2) "mirrorlist_countries - and select any countries in \"$mirror_countries\""

	# make a proper list from mirror_countries
	regsub -all {, } $mirror_countries {/} select_countries
	set select_countries [split $select_countries /]

	while {$count <= $columns} {
		foreach country [lrange $all_countries [expr ($count - 1) * $lines] [expr ($count * $lines) - 1]] {
			.update_mirrors.countries.list${count} insert end $country
			if {[lsearch $select_countries $country] != -1} {.update_mirrors.countries.list${count} selection set end end}
		}
		# next column
		incr count
	}
	
	balloon_set .update_mirrors.countries.select "Update the country list selection"
	balloon_set .update_mirrors.countries.cancel "Cancel - do not change the country list"
	
	update
	grab set .update_mirrors.countries
}	

proc mirrorlist_filter {source poor bad number} {

global debug_out mirror_countries su_cmd tmp_dir
# called by mirrorlist_update to filter the mirrorlist by mirror_countries
# also exclude poor and bad servers if requested
# limit the final mirrorlist to the number of servers specified
# source is either /etc/pacman.d/mirrorlist.pacnew or /etc/pacman.d/mirrorlist.backup

	puts $debug_out(1) "mirrorlist_filter called for $source $poor $bad $number"

	# and take a new backup copy of the latest source file -force overwrites any existing file, which should not exist.
	puts $debug_out(2) "mirrorlist_filter - copy $source to $tmp_dir/mirrorlist.backup"
	file copy -force "$source" "$tmp_dir/mirrorlist.backup"

	# now filter the mirrorlist.backup file to include only the country mirrors required
	foreach item [split $mirror_countries ","] {lappend countries [string trim $item]}
	.update_mirrors.exclude_label configure -foreground blue -relief raised -text "Filtering the mirrors by country...."
	update
	puts $debug_out(2) "mirrorlist_filter - writing new pacman mirror list to $tmp_dir/mirrorlist.tmp"
	set fid1 [open "$tmp_dir/mirrorlist.backup" r]
	set fid2 [open "$tmp_dir/mirrorlist.countries" w]
	set count 0
	gets $fid1 line
	while {[eof $fid1] == 0} {
		# check for a country which is named in countries
		# if countries is blank then just unhash all the servers
		if {[string range $line 0 1] == "##"} { 
			if {$countries == "" || [string first [string trim [string range $line 2 end]] $countries] != -1} {
				puts $fid2 $line
				# now copy over the servers for that country
				gets $fid1 line
				while {[string range $line 0 1] != "##"} {
					if {[string range $line 0 0] == "#"} {
						set line [string range $line 1 end]
					}
					puts $debug_out(3) "mirrorlist_filter - found server $line"
					puts $fid2 $line
					incr count
					gets $fid1 line
				}
			}
		}
		gets $fid1 line
	}
	close $fid1
	close $fid2
	# check that at least some servers were found
	puts $debug_out(2) "mirrorlist_filter - $count servers servers selected for countries"
	if {$count == 0} {
		tk_messageBox -default ok -detail "No servers were found for the parameters specified." -icon info -message "The mirrorlist update aborted" -parent . -title "No mirrors found." -type ok
		# leave the backup file just in case
		file delete "$tmp_dir/mirrorlist.countries"
		return 1
	}

	# check for $poor and or $bad
	if {$poor == 1 || $bad == 1} {
	# hash out any poor or bad servers as requested
	
		if {[test_internet] != 0} {return 1}
	
		.update_mirrors.exclude_label configure -foreground blue -relief raised -text "Filtering the mirrors by status...."
		update
		set mirror_status [eval [concat exec curl -Lfs "https://archlinux.org/mirrors/status/json/"]]
		
		# first get the last_check time
		set position [expr [string first "last_check" $mirror_status] + 14]
		set last_check [string range $mirror_status $position [string first \" $mirror_status $position]-1]
		if {[string first "." $last_check] != -1} {
			# drop the fractions of a second
			set last_check "[string range $last_check 0 [string first "." $last_check]-1]Z"
		}
		set last_check [clock scan $last_check -format "%Y-%m-%dT%H:%M:%SZ"]
		
		# now split the result on each "\}, \{" and keep it as a list
		set mirror_status [split [string trim [regsub -all "\}, \{" $mirror_status "\n"] {\{\}}] "\n"]
		# list the items that we want to read for each site
		set items [list "url" "last_sync" "completion_pct" "delay" "duration_avg" "duration_stddev" "country"]
		# get the mirror status
		set status ""
		foreach line $mirror_status {
			set results ""
			foreach element $items {  
				set index [string first "\"$element\": " $line]
				if {$index == -1} {
					set results [lappend results ""]
				} else {
					set position [expr $index + [string length $element] + 4]
					set result [string trim [string range $line $position [expr [string first \, $line $position] - 1]] \"]
					if {$element == "last_sync"} {
						if {$result == "null"} {
							set result "null"
						} else {
							set result [expr ($last_check - [clock scan $result -format "%Y-%m-%dT%H:%M:%SZ"]) / 3600.0]
						}
					}
					set results [lappend results $result]
				}
			}
			# the rating here is set according to the best results suggested at https://archlinux.org/mirrors/status/
			set rating "status_good"
			# if the checks did not complete or the delay was more that 1 hour then the mirror may not be ideal
			if {[lindex $results 2] != 1 || [lindex $results 1] > 1} {set rating "status_poor"}
			# if the checks did not start or the delay was blank
			if {[lindex $results 2] == 0 || [lindex $results 1] == "" || [lindex $results 1] == "null"} {set rating "status_bad"}
			set results [lappend results $rating]
			set status [lappend mirror_status $results]
		}
	
		set fid1 [open "$tmp_dir/mirrorlist.countries" r]
		set fid2 [open "$tmp_dir/mirrorlist.tmp" w]
		set count 0
		gets $fid1 line
		while {[eof $fid1] == 0} {
			# check for the status of any server found
			if {$line == "" || [string range $line 0 1] == "##"} {
				puts $fid2 $line
			} else {
				set server [string range $line 9 end-14]
				puts $debug_out(3) "mirrorlist_filter - find the server $server in the status list"
				set index [lsearch $status "${server} *"]
				if {$index == -1} {
					set $server_status "status_bad"
				} else {
					set server_string [lindex $status $index]
					set server_status [lindex $server_string end]
				}
				puts $debug_out(3) "\tServer status is $server_status"
				if {$server_status == "status_poor" && $poor == 1} {
					puts $fid2 "\# Status Poor - $line"
				} elseif {$server_status == "status_bad" && $bad == 1} {
					puts $fid2 "\# Status Bad - $line"
				} else {
					puts $fid2 $line
					incr count
				}
			}
			gets $fid1 line
		}
		close $fid1
		close $fid2
		puts $debug_out(2) "$count servers selected by status"
		if {$count == 0} {
			
			
		}
	} else {
		# do not rank by status so just copy over the temporary file
		file copy -force "$tmp_dir/mirrorlist.countries" "$tmp_dir/mirrorlist.tmp"
	}
	
	# now rank the mirrorlist
	.update_mirrors.exclude_label configure -foreground blue -relief raised -text "Ranking the mirrors - this may take some time"
	update
	
	puts $debug_out(2) "mirrorlist_filter - rank the temporary mirrorlist"
	exec rankmirrors -n $number "$tmp_dir/mirrorlist.tmp" > "$tmp_dir/mirrorlist"
	puts $debug_out(2) "mirrorlist_filter - rank mirrorlist completed"
	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		# make a script to run
		set fid [open $tmp_dir/vpacman.sh w]
		puts $fid "#!/bin/sh"
		puts $fid "password=\$1"
		# copy over the mirrorlist and the backup file
		if {$su_cmd == "su -c"} {
			puts $fid "echo \$password | $su_cmd \"cp -f $tmp_dir/mirrorlist /etc/pacman.d\" > $tmp_dir/errors 2>&1"
			if {$source == "/etc/pacman.d/mirrorlist.pacnew"} {
				# move the .pacnew file to the backup file
				puts $fid "echo \$password | $su_cmd \"mv -f $source /etc/pacman.d/mirrorlist.backup\" >> $tmp_dir/errors 2>&1"
			}
		} else {
			puts $fid "echo \$password | $su_cmd -S -p \"\" cp -f $tmp_dir/mirrorlist /etc/pacman.d > $tmp_dir/errors 2>&1"
			if {$source == "/etc/pacman.d/mirrorlist.pacnew"} {
				# move the .pacnew file to the backup file
				puts $fid "echo \$password | $su_cmd -S -p \"\" mv -f $source /etc/pacman.d/mirrorlist.backup >> $tmp_dir/errors 2>&1"
			}
		}
		close $fid
		# and run it
		exec chmod 0755 "$tmp_dir/vpacman.sh"
		# get the password
		grab release .update_mirrors
		set password [get_password ".update_mirrors"]
		# password will be set to an error of 3 if the password procedure was cancelled
		if {$password != 3} {
			set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
			# don't save the password
			unset password
			puts $debug_out(2) "mirrorlist_filter - ran vpacman.sh with error $error and result \"$result\""
		} else {
			unset password
			set error 1
			set result "Authentication failure"
			puts $debug_out(2) "mirrorlist_filter - get_password cancelled"
		}
		if {$error == 1} {
			# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
			# the second error message will be displayed instead, which is not too bad.
			if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
				puts $debug_out(1) "mirrorlist_filter - Authentification failed, return 1"
				set detail "Authentification failed - rank mirrors cancelled. "
			} else {
				puts $debug_out(1) "mirrorlist_filter - rank mirrors failed, return 1"
				set detail "Could not rank the mirror list - rank mirrors cancelled. "
			}
			tk_messageBox -default ok -detail "$detail" -icon error -message "Update Mirrorlist Failed." -parent .update_mirrors -title "Error" -type ok
			# remove the temporary files
			file delete "$tmp_dir/mirrorlist.backup"
			file delete "$tmp_dir/mirrorlist.countries" 
			file delete "$tmp_dir/mirrorlist.tmp" 
			file delete "$tmp_dir/mirrorlist" 
			return 1
		}
		# no errors so
		file delete $tmp_dir/vpacman.sh
		file delete $tmp_dir/errors
	} else {
		# copy over the mirrorlist
		exec sudo cp -f "$tmp_dir/mirrorlist" "/etc/pacman.d"
		if {$source == "/etc/pacman.d/mirrorlist.pacnew"} {
			# move the .pacnew file to the backup file
			exec sudo mv -f "/etc/pacman.d/mirrorlist.pacnew" "/etc/pacman.d/mirrorlist.backup"
		}
	}
	# count the number of servers that were ranked
	set fid [open "$tmp_dir/mirrorlist"  r]
	set mirrorlist [split [read $fid] \n]
	close $fid
	set count_servers 0
	foreach line $mirrorlist {
		if {[string first "Server = " $line] == 0} {
			incr count_servers}
	}

	# remove the temporary files
	file delete "$tmp_dir/mirrorlist.backup"
	file delete "$tmp_dir/mirrorlist.countries" 
	file delete "$tmp_dir/mirrorlist.tmp" 
	file delete "$tmp_dir/mirrorlist" 
	
	tk_messageBox -default ok -detail "$count_servers mirror servers have been ranked and saved to a new mirrorlist" -icon info -message "The pacman mirrorlist has been updated." -parent . -title "Update Mirrorlist Complete" -type ok

	puts $debug_out(1) "mirrorlist_filter completed"
	return 0
}

proc mirrorlist_update {} {
	
global debug_out mirror_countries tmp_dir win_mainx win_mainy
# update and rank the mirrorlist
# valid sources are /etc/pacman.d/mirrorlist.pacnew /etc/pacman.d/mirrorlist.backup 0r a downloaded update
# requires rankmirrors

	puts $debug_out(1) "mirrorlist_update called"
	if {[catch {exec which rankmirrors}] == 1} {
		tk_messageBox -default ok -detail "Consider installing the pacman-contrib package" -icon info -message "Rankmirrors is required to update the mirrorlist" -parent . -title "Cannot Update Mirrorlist" -type ok
		return 1
	}
	if {[file exists /etc/pacman.d/mirrorlist.pacnew]} {
		set source /etc/pacman.d/mirrorlist.pacnew
	# if no pacnew file exists then try to download the latest mirrorlist to the tmp directory and use that
	} elseif {[get_mirrorlist] == 0} {
		set source $tmp_dir/mirrorlist.latest
	# if that does not work then use a backup file 
	} elseif {[file exists /etc/pacman.d/mirrorlist.backup]} {
		set source /etc/pacman.d/mirrorlist.backup
	} else {
		# if the only file is mirrorlist then offer to back it up and then rank it
		tk_messageBox -default ok -detail "Update mirrorlist will use the file \"mirrorlist.pacnew\" or \"mirrorlist.backup\" in /etc to create a new, updated, pacman mirrorlist." -icon error -message "No pacman mirrorlist source file exists." -parent . -title "Error" -type ok
		puts $debug_out(1) "mirrorlist_update - no backup or pacnew file to update, return error"
		return 1
	}
	puts $debug_out(1) "mirrorlist_update - using mirrorlist $source" 
	set fid [open $source r]
	while {![eof $fid]} {
		gets $fid line
		if {[string first "## Generated on " $line] != -1} {break}
	}
	close $fid
	puts $debug_out(2) "mirrotlist_update - generated on [string range $line 16 end]"
	set generated [clock format [clock scan [string range $line 16 end] -format %Y-%m-%d] -format "[exec locale d_fmt]"]
	
	puts $debug_out(2) "mirrorlist_update -using $source updated $generated"
		
	toplevel .update_mirrors
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {356/ 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {240 / 2}]
	wm geometry .update_mirrors +$left+$down
	wm iconphoto .update_mirrors tools
	wm protocol .update_mirrors WM_DELETE_WINDOW {
		# assume cancel select, see button .update_mirrors.cancel
		.update_mirrors.cancel invoke

	}
	wm resizable .update_mirrors 0 0
	wm title .update_mirrors "Update/Rank Mirror List"
	wm transient .update_mirrors .

# CONFIGURE RANK MIRRORS WINDOW

	label .update_mirrors.source_file
	.update_mirrors.source_file configure -text "$source"	
		
	label .update_mirrors.source_label
	.update_mirrors.source_label configure -text "Source : ${source} (${generated})"

	label .update_mirrors.countries_label \
		-text "Select servers only from the following countries "
	
	entry .update_mirrors.countries_entry \
		-textvariable mirror_countries
	
	
	frame .update_mirrors.countries_button_frame
	
		button .update_mirrors.countries_button \
			-command {
				# update mirror_countries
				mirrorlist_countries [.update_mirrors.source_file cget -text]
				tkwait window .update_mirrors.countries
			} \
			-text "Select"
	
	label .update_mirrors.exclude_label \
		-text "Exclude mirrors with the following current status" \
		-width 36
		
	frame .update_mirrors.checkbuttons
	
		label .update_mirrors.status_poor_label \
			-text "Poor"
		
		checkbutton .update_mirrors.status_poor 
		.update_mirrors.status_poor select
		
		# if poor is selected then bad must be selected as well
		bind .update_mirrors.status_poor <ButtonRelease-1> {
			if {$status_poor == 1} {.update_mirrors.status_bad select}
		}
		
		label .update_mirrors.status_bad_label \
			-text "Bad" 
		
		checkbutton .update_mirrors.status_bad 
		.update_mirrors.status_bad select
		
		# if bad is deselected then poor must be deselected as well
		bind .update_mirrors.status_bad <ButtonRelease-1> {
			if {$status_bad == 0} {.update_mirrors.status_poor deselect}
		}
		
	label .update_mirrors.limit_label \
		-text "Restrict the mirrors to "
	
	entry .update_mirrors.limit_entry \
		-justify right \
		-validate key \
		-validatecommand {expr {"%P" == "0" || ([string is integer %P] && [string length %P] < 3 && [string first "0" %P] != 0)}} \
		-width 2
	.update_mirrors.limit_entry insert 0 0
		
	label .update_mirrors.limit_servers \
		-text "servers"

	frame .update_mirrors.buttons

		button .update_mirrors.select\
			-command {
				# get the source file 
				set source [.update_mirrors.source_file cget -text]
				# select the country mirrors
				# make sure that the number of mirrors is not blank
				if {[.update_mirrors.limit_entry get] == ""} {.update_mirrors.limit_entry insert 0 0}
				update
				# now filter and rank the source file
				mirrorlist_filter $source $status_poor $status_bad [.update_mirrors.limit_entry get]
				puts $debug_out(2) "mirrorlist_update - save the selections (put_configs)"
				put_configs
				puts $debug_out(1) "mirrorlist_update - complete"
				grab release .update_mirrors
				destroy .update_mirrors
			} \
			-text "Update"
		button .update_mirrors.cancel \
			-command {
				puts $debug_out(1) "mirrorlist_update - cancelled"
				grab release .update_mirrors
				destroy .update_mirrors
			} \
			-text "Cancel"
	
	# and grid them
	
	grid .update_mirrors.source_label -in .update_mirrors -row 2 -column 2 \
		-columnspan 4 \
		-sticky w
	grid .update_mirrors.countries_label -in .update_mirrors -row 4 -column 2 \
		-columnspan 4 \
		-sticky w
	grid .update_mirrors.countries_entry -in .update_mirrors -row 4 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .update_mirrors.countries_button_frame -in .update_mirrors -row 6 -column 2 \
		-columnspan 4 
		grid .update_mirrors.countries_button -in .update_mirrors.countries_button_frame -row 1 -column 2
	
	grid .update_mirrors.exclude_label -in .update_mirrors -row 8 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .update_mirrors.checkbuttons -in .update_mirrors -row 10 -column 2 \
		-columnspan 4
		grid .update_mirrors.status_poor_label -in .update_mirrors.checkbuttons -row 1 -column 2
		grid .update_mirrors.status_poor -in .update_mirrors.checkbuttons -row 1 -column 3
		grid .update_mirrors.status_bad_label -in .update_mirrors.checkbuttons -row 1 -column 4
		grid .update_mirrors.status_bad -in .update_mirrors.checkbuttons -row 1 -column 5
	grid .update_mirrors.limit_label -in .update_mirrors -row 12 -column 2 \
		-sticky w
	grid .update_mirrors.limit_entry -in .update_mirrors -row 12 -column 3
	grid .update_mirrors.limit_servers -in .update_mirrors -row 12 -column 4
	grid .update_mirrors.buttons -in .update_mirrors -row 14 -column 2 \
		-columnspan 4 \
		-sticky we
		grid .update_mirrors.select -in .update_mirrors.buttons -row 1 -column 1 \
			-sticky w
		grid .update_mirrors.cancel -in .update_mirrors.buttons -row 1 -column 2 \
			-sticky e

	# Resize behavior management

	grid rowconfigure .update_mirrors 1 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 3 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 5 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 6 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 7 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 8 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 9 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 10 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 11 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 12 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_mirrors 13 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_mirrors 14 -weight 0 -minsize 0 -pad 0
	

	grid columnconfigure .update_mirrors 1 -weight 0 -minsize 15 -pad 0
	grid columnconfigure .update_mirrors 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors 5 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors 6 -weight 0 -minsize 15 -pad 0
	
	grid rowconfigure .update_mirrors.countries_button_frame 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries_button_frame 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries_button_frame 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.countries_button_frame 3 -weight 1 -minsize 0 -pad 0

	grid rowconfigure .update_mirrors.checkbuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 5 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.checkbuttons 6 -weight 0 -minsize 0 -pad 0
	
	grid rowconfigure .update_mirrors.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_mirrors.buttons 2 -weight 1 -minsize 0 -pad 0

	balloon_set .update_mirrors.countries_label "Only select servers for these countries. (Comma separated list)"
	balloon_set .update_mirrors.countries_entry "Only select servers for these countries. (Comma separated list)"
	balloon_set .update_mirrors.countries_button "Select the countries from a list"
	balloon_set .update_mirrors.status_poor_label "Do not include servers know to be status poor"
	balloon_set .update_mirrors.status_poor "Do not include servers know to be status poor"
	balloon_set .update_mirrors.status_bad_label "Do not include servers know to be status bad"
	balloon_set .update_mirrors.status_bad "Do not include servers know to be status bad"
	balloon_set .update_mirrors.limit_label "Limit the number of servers in the mirrorlist"
	balloon_set .update_mirrors.limit_entry "Limit the number of servers in the mirrorlist"
	balloon_set .update_mirrors.limit_servers "Limit the number of servers in the mirrorlist"
	balloon_set .update_mirrors.select "Cancel - do not update the mirrorlist"
	balloon_set .update_mirrors.select "Update and rank the mirrorlist"
	
	update
	grab set .update_mirrors
}

proc place_warning_icon {icon} {
	
global debug_out
# place a warning icon on the .filter_icons frame
# allow for four icons
	
	puts $debug_out(1) "place_warning_icon - called for $icon"
	# which icons are already visible, unfortunately gridded is in alphabetical order
	set gridded [grid slaves .filter_icons]
	set count [llength [split $gridded]]
	puts $debug_out(2) "place_warning_icon - $count icons are gridded"
	# if the icon is shown already then return
	if {[string first $icon $gridded] != -1} {return 0} 
	puts $debug_out(2) "place_warning_icon - $icon is not shown so grid it at $count"
	# then place it in the next available position
	# columns 2 to 3, rows 2 to 3
	# gridding the first item is easy because no space will be reserved for column 3 and row 3 so it will be placed in the middle of the frame
	# similarly gridding the second item will mean that the two icons will be side by side and centred vertically since row 3 takes no space
	# grid the third item spanned across columns 2 and 3 in row 3
	# grid any fourth item in column 3 row 3 and rearrange the third icon in column 2
	# get the icon which is configured in row 3 in case we need it later
	set row3icon ""
	foreach item $gridded {
		if {[string first "-row 3" [grid info $item]] != -1} {set row3icon $item}
	}
	switch $count {
		0 {grid $icon -in .filter_icons -row 2 -column 2 -padx 10 -sticky ""}
		1 {grid $icon -in .filter_icons -row 2 -column 3 -padx 10 -sticky w}
		2 {grid $icon -in .filter_icons -row 3 -column 2 -padx 10 -columnspan 2 -sticky ""}
		3 {grid configure $row3icon -columnspan 1 -sticky e
		   grid $icon -in .filter_icons -row 3 -column 3 -padx 10 -sticky w}
	}
	update idletasks
	puts $debug_out(1) "place_warning_icon - completed"
	return 0
}

proc put_aur_files {files} {
	
global aur_files debug_out start_time

	puts $debug_out(1) "put_aur_files - called by thread aur_files ([expr [clock milliseconds] - $start_time])"
	set aur_files $files
	puts $debug_out(1) "put_aur_files - completed ([expr [clock milliseconds] - $start_time])"

}

proc put_aur_versions {versions} {
	
global aur_all aur_versions debug_out filter filter_list find group list_all list_local list_local_ids list_show local_newer selected_list start_time thread tmp_dir
# put the version and description found for a local package into list_all list_show list_local and treeview
# this procedure is called by a thread
	
	puts $debug_out(1) "put_aur_versions - called, thread is \"$thread\" ([expr [clock milliseconds] - $start_time])"
	# and what if the thread was running but failed?	
	if {$versions == "failed"} {
		puts $debug_out(1) "put_aur_versions - aur_versions thread exited with failed state - call get_aur_versions"
		set thread ""
		set aur_versions ""
		get_aur_versions
	} else {
		set aur_versions $versions
	}
	puts $debug_out(3) "put_aur_versions - aur_versions set to $aur_versions"
	# reset the number of local files that need to be updated
	set local_newer 0
	# read each of the local packages and compare them to the information in aur_versions
	# if the local package does not exist in aur_versions then leave it unchanged
	# test for no local packages
	if {[llength $list_local] != 0} {
		foreach line $list_local {
				set name [lindex $line 1]
				set element ""
				if {[lsearch -index 0 $aur_versions $name] != -1} {
					set version [lindex $line 2]
					set index [lsearch -index 0 $aur_versions $name]
					set item [lindex $aur_versions $index]
					set available [lindex $item 1]
					set description [lindex $item 2]
				} else {
					set version [lindex $line 2]
					set available [lindex $line 3]
					set description [lindex $line 5]
				}
				# try to get the description from the local database
				if {$description == "DESCRIPTION"} {
					puts $debug_out(3) "put_aur_versions - find description for ${name}-${version} from local database"
					set filename [glob $tmp_dir/local/${name}-${version}]
					set fid [open $filename/desc r]
					while {[eof $fid] == 0} {
						gets $fid header
						if {$header == "%DESC%"} {
							gets $fid description
							break
						}
					}
					close $fid
					puts $debug_out(3) "put_aur_versions - description for $name set to \"$description\""
				}	
				set is_update false
				lappend element "local" "$name" "$version" "$available" "[lindex $line 4]" "$description"
				# rewrite list_local into aur_updates
				if {$element != ""} {lappend aur_updates $element}
				# now insert the available version and the description into the lists
				# find the index of the package in list_local_ids 
				set index [lsearch -index 0 $list_local_ids $name]
				# put the new element line into list_all (first index)
				set list_all_index [lindex [lindex $list_local_ids $index] 1]
				set list_all [lreplace $list_all $list_all_index $list_all_index $element]
				# check if this is an update and calculate the number of updates available. If it is an update insert the correct tags as necessary.
				if {[lrange $element 2 2] != [lrange $element 3 3]} {
					puts $debug_out(3) "put_aur_versions - call test_versions for $name"
					set test [test_versions [lrange $element 2 2] [lrange $element 3 3]]
					puts $debug_out(3) "put_aur_versions - test_versions returned $test"
					if {$test == "newer"} {
						set is_update true
						puts $debug_out(3) "put_aur_versions - this is an update"
						incr local_newer
					}
				}
				# if there are four items in the list_local_ids then the element is included in list_show and the treeview
				if {[llength [lindex $list_local_ids $index]] == 4} {
					# put the new element line into list_show (second index)
					set list_show_index [lindex [lindex $list_local_ids $index] 2]
					set list_show [lreplace $list_show $list_show_index $list_show_index $element]
					# put $available into treeview at the fourth position (third index)
					# $description is not shown in the treeview
					set treeview_index [lindex [lindex $list_local_ids $index] 3]
					set element [lreplace [.wp.wfone.listview item $treeview_index -values] 3 3 $available]
					# now check if this would be an update and add the tags if necessary
					# remove any existing tags
					.wp.wfone.listview tag remove outdated $treeview_index
					.wp.wfone.listview tag remove installed $treeview_index
					# and add any new tags required
					if {$is_update} {
### temporarily add an asterix to the new version number
###.wp.wfone.listview item $treeview_index -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
###
						.wp.wfone.listview tag add outdated $treeview_index
					} else {
						.wp.wfone.listview tag add installed $treeview_index
					}	
					.wp.wfone.listview item $treeview_index -values $element
				}
			}
			set list_local $aur_updates
			# list_local should now be a clean list of all the local packages
			puts $debug_out(2) "put_aur_versions - filter is \"$filter\", group is \"$group\", find is \"$find\""
			# if filter_list is still set to list_all at this point then update it
			if {$filter == "all" && $group == "All" && $find == ""} {
				set filter_list $list_all
				puts $debug_out(2) "put_aur_versions - filter_list set to list_all"
			}
	}
	# now show the number of packages against AUR/Local Updates
	if {$aur_all == true} {
		puts $debug_out(2) "put_aur_versions - configured text \"AUR/Local Packages ([llength $list_local])\""
		.filter_list_aur_updates configure -text "AUR/Local Packages ([llength $list_local])"
	} else {
		puts $debug_out(2) "put_aur_versions - configured text to local_newer \"AUR/Local Updates ($local_newer)\""
		.filter_list_aur_updates configure -text "AUR/Local Updates ($local_newer)"
	}
	puts $debug_out(2) "put_aur_versions - unset thread"
	set thread ""
	puts $debug_out(1) "put_aur_versions - completed ([expr [clock milliseconds] - $start_time])"
}

proc put_configs {} {

global aur_all backup_dir browser buttons config_file debug_out diffprog editor geometry geometry_config geometry_view helpbg helpfg icon_dir installed_colour keep_log mirror_countries one_time outdated_colour save_geometry show_menu show_buttonbar terminal terminal_string
# save the configuration data

	puts $debug_out(1) "put_configs called"
	
	set fid [open "$config_file" w ]

	puts $fid "# Configuration options for the tcl Vpacman programme GUI for pacman."
	puts $fid "# Valid format is "
	puts $fid "# 	variable option_list"
	puts $fid "# This file will be overwritten when the vpacman programme exits"
	puts $fid "#"
	puts $fid "# If you change any of these settings by hand then the programme may not run correctly."
	puts $fid "# Delete the file $config_file to re-initialize sane options"
	puts $fid ""
	if {$aur_all != true} {set aur_all false} 
	puts $fid "aur_all $aur_all"
	puts $fid "backup_dir $backup_dir"
	puts $fid "browser $browser"
	puts $fid "buttons $buttons"
	puts $fid "config_file $config_file"
	puts $fid "diffprog $diffprog"
	puts $fid "editor $editor"
	puts $fid "geometry $geometry"
	puts $fid "geometry_config $geometry_config"
	puts $fid "geometry_view $geometry_view"
	puts $fid "help_background $helpbg"
	puts $fid "help_foreground $helpfg"
	puts $fid "icon_directory $icon_dir"
	puts $fid "installed_colour $installed_colour"
	puts $fid "keep_log $keep_log"
	puts $fid "mirror_countries $mirror_countries"
	puts $fid "one_time $one_time"
	puts $fid "outdated_colour $outdated_colour"
	if {$save_geometry != "yes"} {set $save_geometry "no"}
	puts $fid "save_geometry $save_geometry"
	if {$show_menu != "no"} {set $show_menu "yes"}
	puts $fid "show_menu $show_menu"
	if {$show_buttonbar != "no"} {set $show_buttonbar "yes"}
	puts $fid "show_buttonbar $show_buttonbar"
	puts $fid "terminal $terminal" 
	puts $fid "terminal_string $terminal_string" 
	close $fid 
	
	puts $debug_out(1) "put_configs completed"
}

proc put_list_groups {groups} {
	
global debug_out list_groups list_groups_TID start_time

	puts $debug_out(1) "put_list_groups called by thread list_groups ([expr [clock milliseconds] - $start_time])"
	set list_groups $groups
	# we can stop this thread running since we do not need it again
	thread::release $list_groups_TID
	if {[thread::exists $list_groups_TID] == 0} {
		puts $debug_out(2) "put_list_groups stopped the list groups thread"
	}
	puts $debug_out(1) "put_list_groups completed ([expr [clock milliseconds] - $start_time])"
}

proc read_aur_info {line} {
	
global debug_out
# read the information from downloaded AUR package details

	puts $debug_out(1) "read_aur_info called"
	set index [string first "\"Name\":" $line]
	if {$index == -1} {
		set name ""
	} else {
		set position [expr $index + 8]
		set name [string trim [string range $line $position [expr [string first \" $line $position] - 1]] \"]
	}
	set index [string first "\"PackageBase\":" $line]
	if {$index == -1} {
		set basename ""
	} else {
		set position [expr $index + 15]
		set basename [string trim [string range $line $position [expr [string first \" $line $position] - 1]] \"]
	}
	set index [string first "\"Version\":" $line]
	if {$index == -1} {
		set version ""
	} else {
		set position [expr $index + 11]
		set version [string trim [string range $line $position [expr [string first \" $line $position] - 1]] \"]
	}
	set index [string first "\"Description\":" $line]
	if {$index == -1 } {
		set description ""
	} else {
		set position [expr $index + 15]
		set description [string range $line $position [expr [string first \" $line $position] - 1]]
	}
	set index [string first "\"URL\":" $line]
	if {$index == -1} {
		set url ""
	} else {
		set position [expr $index + 6]
		set url [string range $line $position [expr [string first \, $line $position] - 1]]
		regsub -all {\\} $url {} url
		set url [string trim $url \"]
	}
	set index [string first "\"LastModified\":" $line]
	if {$index == -1} {
		set updated ""
	} else {
		set position [expr $index + 15]
		set updated [string range $line $position [expr [string first \, $line $position] - 1]]
		set updated [clock_format $updated short_full]
	}
	set index [string first "\"Depends\":" $line]
	if {$index == -1} {
		set depends ""
	} else {
		set position [expr $index + 11]
		set depends [string range $line $position [expr [string first \] $line $position] - 1]]
		set depends [string map {"\"" "" "," " "} $depends]
	}
	set index [string first "\"CheckDepends\":" $line]
	if {$index == -1} {
		set checkdepends ""
	} else {
		set position [expr $index + 16]
		set checkdepends [string range $line $position [expr [string first \] $line $position] - 1]]
		set checkdepends [string map {"\"" "" "," " "} $depends]
	}
	set index [string first "\"MakeDepends\":" $line]
	if {$index == -1} {
		set makedepends ""
	} else {
		set position [expr $index + 15]
		set makedepends [string range $line $position [expr [string first \] $line $position] - 1]]
		set makedepends [string map {"\"" "" "," " "} $makedepends]
	}
	set index [string first "\"OptDepends\":" $line]
	if {$index == -1} {
		set optdepends ""
	} else {
		set position [expr $index + 14]
		set optdepends [string range $line $position [expr [string first \] $line $position] - 1]]
		set optdepends [string map {"\"" "" "," " "} $optdepends]
	}
	set index [string first "\"Keywords\";" $line]
	if {$index == -1} {
		set keywords ""
	} else {
		set position [expr $index + 12]
		set keywords [string range $line $position [expr [string first \] $line $position] - 1]]
		set keywords [string map {"\"" "" "," " "} $keywords]
	}
	set index [string first "\"URLPath\":" $line]
	if {$index == -1} {
		set snapshot ""
	} else {
		set position [expr $index + 10]
		set snapshot [string range $line $position [expr [string first \, $line $position] - 1]]
		regsub -all {\\} $snapshot {} snapshot
		set snapshot [string trim $snapshot \"]
	}
	set index [string first "\"OutOfDate\":" $line]
	if {$index == -1} {
		set outofdate ""
	} else {
		set position [expr $index + 12]
		set outofdate [string range $line $position [expr [string first \, $line $position] - 1]]
		if {$outofdate != "null"} {set outofdate [clock_format $outofdate short_full]}
	}

	puts $debug_out(2) "read_aur_info - found BaseName: $basename, Version: $version, Description: $description, URL: $url, Updated: $updated, Depends: $depends, CheckDepends: $checkdepends, MakeDepends: $makedepends, OptDepends: $optdepends, Keywords: $keywords, Snapshot: $snapshot, OutOfDate: $outofdate"
	
	puts $debug_out(1) "read_aur_info completed"
	
	return [list "$basename" "$version" "$description" "$url" "$updated" "$depends" "$checkdepends" "$makedepends" "$optdepends" "$keywords" "$snapshot"]
}

proc read_config {}  {
	
global debug_out
# read the pacman configuration file 

	puts $debug_out(1) "read_config called"
	
	# read /etc/pacman.conf
	set config_text ""
	set config_text [exec cat "/etc/pacman.conf"]
	view_text $config_text "Pacman Configuration"
	puts $debug_out(1) "read_config completed"
}

proc read_dependencies {params} {

global count_outdated debug_out list_installed list_outdated start_time system tmp_dir
# test the dependencies of the installed package and the available package and list any changes

    if {"$params" != "report"} {
		set package [lindex $params 0]
		set version [lindex $params 1]
		set available [lindex $params 2]
		puts $debug_out(1) "read_dependencies called for $package - version is $version, available is $available - ([expr [clock milliseconds] - $start_time])"
	
		# check that we have not installed a newer version than in the official repos
		if {[test_versions $version $available] == "newer"} {
			puts $debug_out(2) "read_dependencies - available version of $package is newer"
			set error [catch {exec pacman -b $tmp_dir -Qi $package} result]
			set result [split $result \n]
			set value [expr [string first ":" [lindex $result 0]] + 2]
			set old_deps [string range [lsearch -inline -glob $result "Depends On*"] $value end]
			if {$old_deps == "None"} {set old_deps ""}
			puts $debug_out(2) "read_dependencies - old dependencies are \"$old_deps\""
			# if the package is a local install then use get_aur_info
			set error [catch {exec pacman -b $tmp_dir -Si $package} result]
			set new_deps [string range [lsearch -inline -glob [split $result \n] "Depends On*"] $value end]
			if {$new_deps == "None"} {set new_deps ""}
			if {$error == 1} {
				puts $debug_out(2) "read_dependencies - pacman -Si returned an error try get_aur_info"
				set info [get_aur_info $package]
				set new_deps [lindex $info 5 ]
			}
			puts $debug_out(2) "read_dependencies - new dependencies are \"$new_deps\""
			# first run a simple test
			if {[lsort $old_deps] == [lsort $new_deps]} {
				puts $debug_out(2) "read_dependencies - no changes"
				puts $debug_out(1) "read_dependencies for $package completed - ([expr [clock milliseconds] - $start_time])"
				return 0
			} else {
			# then run an item by item test
				puts $debug_out(2) "read_dependencies - dependencies are not the same - ([expr [clock milliseconds] - $start_time])"
				# now find the changes
				set compare 0
				set new_list ""
				set old_count 0
				set new_count 0
				while {true} {
					set old_dep [lindex $old_deps $old_count]
					set new_dep [lindex $new_deps $new_count]
					if {"$old_dep" == "" && "$new_dep" == ""} {break}
					puts -nonewline $debug_out(3) "read_dependencies - Compare $old_dep to $new_dep -"
					if {$old_dep == $new_dep} {
						puts $debug_out(3) " they are the same"
						set new_list [concat $new_list $new_dep]
						incr old_count
						incr new_count
					} else {
						set compare 1
						puts $debug_out(3) " they are not the same"
						if {"$old_dep" == ""} {
							puts $debug_out(3) "read_dependencies - $new_dep is new"
							set new_list [concat $new_list "+$new_dep"]
							incr new_count
						} elseif {"$new_dep" == ""} {
							puts $debug_out(3) "read_dependencies - $old_dep is no longer needed"
							set new_list [concat $new_list "-$old_dep"]
							incr old_count
						} else {
							if {[lsearch $old_deps $new_dep] == -1} {
								puts $debug_out(3) "read_dependencies - $new_dep is new"
								set new_list [concat $new_list "+$new_dep"]
								incr new_count
							} else {
								puts $debug_out(3) "read_dependencies - $new_dep is still needed"
								set new_list [concat $new_list "$new_dep"]
								incr new_count
							}
							if {[lsearch $new_deps $old_dep] == -1} {
								puts $debug_out(3) "read_dependencies - $old_dep is no longer needed"
								set new_list [concat $new_list "-$old_dep"]
								incr old_count
							} else {
								incr old_count
							}
						}
					}
				}
				puts $debug_out(1) "read_dependencies for $package completed - ([expr [clock milliseconds] - $start_time])"
				if {$compare == 0} {return 0}
				return $new_list
			}
		}
		return 0
	} else {
		puts $debug_out(1) "read_dependencies called to report updated dependencies - ([expr [clock milliseconds] - $start_time])"
		
		if {[llength $list_outdated] == 0} {
			puts $debug_out(1) "read_dependencies - no updates available - return 1"
			set_message "terminal" "No updates available"
			after 5000 {set_message reset ""}
			return 1
		}
			
		# make a list of all the update packages
		puts $debug_out(2) "read_dependencies - get list of updates available"
		set packages ""
		foreach item $list_outdated {
			lappend packages [lrange $item 1 1]
		}
		set packages [lsort $packages]
		
		# now get the details from the local and system databases
		puts $debug_out(2) "read_dependencies - get list of local packages"
		set local [split [eval [concat exec pacman -b $tmp_dir -Qi $packages]] \n]
		if {$system == ""} {
			puts $debug_out(2) "read_dependencies - refresh system variable"
			get_system_data ""
		}
		
		puts $debug_out(2) "read_dependencies - start dependency report"
		
		set test_results "\n<strong>DEPENDENCY CHANGES FOR THE $count_outdated PACKAGES LISTED AS \"UPDATES AVAILABLE\":</strong>\n\n"
		
		set count 0
		set current 0
		set total [llength $list_outdated]
		# can we assume that value will be the same for local and system reports
		set value [expr [string first ":" [lindex $system 0]] + 2]
		# set value [expr [string first ":" [lindex $local 0]] + 2]
		puts $debug_out(2) "read_dependencies - value set to $value"
	
		foreach package $packages {
			puts $debug_out(3) "read_dependencies for $package - ([expr [clock milliseconds] - $start_time])"
	
			# display a helpful message	
			incr current
			set_message "terminal" "Compiling report of dependency changes for $current/$total upgrades"
			update
						
			set index [lsearch -glob $local "Name* $package"]
			set old_deps [string range [lsearch -inline -glob -start $index $local "Depends On*"] $value end]
			if {$old_deps == "None"} {set old_deps ""}
			puts $debug_out(3) "read_dependencies - Old dependencies are $old_deps"
			set index [lsearch -glob $system "Name* $package"]
			set new_deps [string range [lsearch -inline -glob -start $index $system "Depends On*"] $value end]
			if {$new_deps == "None"} {set new_deps ""}
			puts $debug_out(3) "read_dependencies - New dependencies are $new_deps"
			# check if the dependencies have not changed
			if {[lsort $old_deps] == [lsort $new_deps]} {
			puts $debug_out(3) "read_dependencies - Dependencies have not changed"
				continue
			}
			puts $debug_out(3) "read_dependencies - Dependencies have changed"
			incr count
			append test_results "\nDependency updates for $package\n\n"
			set added ""
			set removed ""
			set required ""
			foreach dep $old_deps {
				if {[lsearch $new_deps $dep] == -1} {
					puts $debug_out(3) "read_dependencies - $dep is no longer needed"
					set removed [concat $removed $dep]
				}
			}
			if {[llength $removed] > 0} {
				append test_results "\tRemoves: $removed\n"
			}

			foreach dep $new_deps {
				if {[lsearch $old_deps $dep] == -1} {
					puts $debug_out(3) "read_dependencies - $package needs new dependencies $dep"
					set added [concat $added $dep]
					#check for version upgrades
					if {[string first "=" $dep] != -1} {
						if {[string first [string range $added 0 [string first "=" $dep]] $removed] != -1} {
							puts $debug_out(3) "read_dependencies - This is a version upgrade"
							continue
						}
					}
					if {[lsearch -index 1 $list_installed $dep] != -1} {
						puts $debug_out(3) "read_dependencies - $dep is already installed"
						set added [concat $added (installed)]
					} elseif {[lindex [read_dependencies_provides $dep] 1] != ""} {
						puts $debug_out(3) "read_dependencies - $dep is already provided by an installed package"
						set added [concat $added (installed)]
					} else {
						puts $debug_out(3) "read_dependencies - $dep is not installed, find any extra dependencies for $dep"
						set tests $dep
						while true {
							# now get all the additional dependencies to install for $tests
							puts $debug_out(3) "read_dependencies - test is now $tests"
							puts $debug_out(3) "read_dependencies - call read_dependencies_extra for [lindex $tests 0]"
							set more_deps [read_dependencies_extra [lindex $tests 0]]
							puts $debug_out(3) "read dependencies - extra returned more_deps - \"$more_deps\" for [lindex $tests 0], set tests to \"[concat [lrange $tests 1 end] $more_deps]\""
							# read_dependencies_extra returns more_deps which are only packages which are not installed
							if {$more_deps != ""} {
								set required [concat $required  "| [lindex $tests 0]: $more_deps"]
								puts $debug_out(3) "read_dependencies - \"$more_deps\" is required by \"[lindex $tests 0]\""
							}
							set tests [concat [lrange $tests 1 end] $more_deps]
							if {$tests == ""} {
								puts $debug_out(3) "read dependencies - tests (and more_deps) are blank, so break"
								break
							}
							puts $debug_out(3) "read_dependencies - there are more tests - \"$tests\""
						}
					}
				}
			}
			if {[llength $added] > 0} {
				append test_results "\tAdds   : $added\n"
			}
			if {[llength $required] > 0} {
				# remove any surrounding | from $required and then split required into a proper list
				set required [split [string trim $required "|"] "|"]
				# each item is a dependency followed by a list of required dependencies
				# strip off any surrounding blank spaces
				foreach req $required {
					append test_results "\tRequired by [string trim $req " "]\n"
				}
			}
		}
		if {$count == 0} {append test_results "\n\nNo dependency changes in the package updates available"}
		# now display the report
		set_message "terminal" ""
		puts $debug_out(1) "read_dependencies for all updates completed - ([expr [clock milliseconds] - $start_time])"
		puts $debug_out(1) "read_dependencies - view results"
		view_text $test_results "Dependency Updates"
		return 0			
	}	
}

proc read_dependencies_extra {package} {
	
global debug_out list_installed start_time system
# find any additional dependencies needed for a given package which are not already installed

	puts $debug_out(3) "read_dependencies_extra called for $package"
	set added ""
	set index ""
	set value [expr [string first ":" [lindex $system 0]] + 2]
	
	set index [lsearch -glob $system "Name* $package"]
	puts $debug_out(3) "read_dependencies_extra - $package found in system at $index"
	# ok so if we cannot find the dependency in the system packages, so we could search the files database for it,
	# but we may not have an up to date files database, so try to replicate it here.
	if {$index == -1} {
		puts $debug_out(3) "read_dependencies_extra - search for $package in Provides"
		set result [read_dependencies_provides $package]
		set provides [lindex $result 0]
		set installed [lindex $result 1]
		puts $debug_out(3) "read_dependencies_extra - $package found in uninstalled \"$provides\" and installed \"$installed\""
		# package names returned by Provides have already been found in system
		# if there are installed packages which provide $package then we don't need to look any further
		# If there is more than one package, they will all be either installed or not
		if {$installed != ""} {
			puts $debug_out(3) "read_dependencies_extra - $package found in installed packages \"$installed\""
		} elseif {$provides != ""} {
			puts $debug_out(3) "read_dependencies_extra - $package found in uninstalled packages \"$provides\""
			set added [concat $added "$provides"]
		} else {
			puts $debug_out(3) "read_dependencies_extra - $package was not found in system or provides - give up"
		}
	} else {
		# now check if there are any further dependencies
		puts $debug_out(3) "read_dependencies_extra - $package found in system at $index"
		set new_deps [string range [lsearch -inline -glob -start $index $system "Depends On*"] $value end]
		if {$new_deps == "None"} {set new_deps ""}
		puts $debug_out(3) "read_dependencies_extra - $package depends on \"$new_deps\""
		foreach dep $new_deps {
			set index [lsearch -glob $system "Name* $dep"]
			if {$index != -1} {
				puts $debug_out(3) "read_dependencies_extra - $dep found in system at $index"
				if {[lsearch -index 1 $list_installed $dep] != -1} {
					puts $debug_out(3) "read_dependencies_extra - $dep is already installed"
				} else {
					puts $debug_out(3) "read_dependencies_extra - $dep is not installed"
					set added [concat $added "$dep"]
				}
			} else {
				puts $debug_out(3) "read_dependencies_extra - $dep was not found in system, search in read_dependencies_provides"
				set result [read_dependencies_provides $dep]
				set provides [lindex $result 0]
				set installed [lindex $result 1]
				puts $debug_out(3) "read_dependencies_extra - provides returned \"$provides\" provides $dep and installed packages \"$installed\" which provide $dep"
				if {$installed != ""} {
					puts $debug_out(3) "read_dependencies_extra - $dep is provided by installed package(s)"
				} elseif {$provides != ""} {
					puts $debug_out(3) "read_dependencies_extra - \"$provides\" is not installed"
					set added [concat $added "$provides"]
				} else {
					puts $debug_out(3) "read_dependencies_extra - $dep was not found in system or provides - give up"
				}
			}
		}
	}
	puts $debug_out(3) "read_dependencies_extra completed and returned $added - ([expr [clock milliseconds] - $start_time])"
 	return $added
}

proc read_dependencies_provides {package} {
	
global debug_out list_installed start_time system
# Check for any dependencies that are provided by another package and which are required by added dependencies on an upgrade

	puts $debug_out(3) "read_dependencies_provides called for $package - ([expr [clock milliseconds] - $start_time])"
	set installed ""
	set provides "" 
	set value [expr [string first ":" [lindex $system 0]] + 2]
	
	# if we reverse the system data here then we may have to do it more than once, each time that provides is called
	# we could do it in read_dependencies but then it might not be needed.
	# lrevers system takes around 7 milliseconds, so we can accept the trade-off
	set rsystem [lreverse $system]
	set r_index [lsearch -all -glob $rsystem "Provides* $package*"]
	puts $debug_out(3) "read_dependencies_extra - $package found in rsystem at $r_index"
	if {$r_index == -1} {
		puts $debug_out(3) "read_dependencies_extra - $package found in provides - return blank"
		return ""
	}
	# now find the package name(s) that provide it
	foreach i $r_index {
		set name [string range [lsearch -inline -glob -start $i $rsystem "Name*"] $value end]
		puts $debug_out(3) "read_dependencies_extra - found $name in rsystem"
		set s_index [lsearch -inline -glob $system $name]
		puts $debug_out(3) "read_dependencies_extra - found $name in system at $s_index"
		if {[lsearch -index 1 $list_installed $name] == -1} {
			puts $debug_out(3) "read_dependencies_extra - $name is not installed"
			set provides [concat $provides "$name"]
		} else {
			# if any of the packages are already installed then return them
			puts $debug_out(3) "read_dependencies_extra - $name is already installed"
			set installed [concat $installed "$name"]
		}
	}
	puts $debug_out(3) "read_dependencies_provides completed and returned uninstalled \"$provides\" and installed \"$installed\" packages- ([expr [clock milliseconds] - $start_time])"
	return [list $provides $installed]
}

proc read_log {} {
	
global debug_out
# read through the pacman log file and display it. Check the size and warn if it is too big

	puts $debug_out(1) "read_log called"

	set log_text ""
	set logfile [find_pacman_config logfile]
	puts $debug_out(2) "read_log - Logfile is $logfile"
	
	if {[file exists $logfile]} {
		set log_text [exec cat $logfile]
		# using log_text, reverse the order of the lines
		set tmp_log_text [lreverse [split $log_text \n]]
		set log_text ""
		foreach item $tmp_log_text {set log_text [append log_text $item "\n"]}
		# and view them in reverse order
		view_text $log_text "Pacman Log"
	} else {
		tk_messageBox -default ok -detail "" -icon error -message "The pacman log file ($logfile) is missing." -parent . -title "Error" -type ok
		puts $debug_out(1) "read_log failed - logfile is missing"
		return 1	
	}
	puts $debug_out(1) "read_log completed"
	return 0		
}

proc read_news {} {
	
global browser debug_out dlprog home
# use the download programme to get the latest news from the arch rss feed
	
	puts $debug_out(1) "read_news called"
	puts $debug_out(2) "read_news - called test_internet"
	if {[test_internet] != 0} {return 1}
	puts $debug_out(2) "read_news - download arch rss"
	if {$dlprog == "curl"} {
		set error [catch {eval [concat exec curl -s https://archlinux.org/feeds/news/]} rss_news]
	} elseif {$dlprog == "wget"} {
		set error [catch {eval [concat exec wget -qO - https://archlinux.org/feeds/news/]} rss_news]
	} else {
		set error 1
	}
	if {$error != 0} {return 1}
	set rss_news [split $rss_news "<>"]
	puts $debug_out(2) "\tdone"
	puts $debug_out(2) $rss_news
	set count 0
	set element ""
	set news_list ""
	while {$element != "item"} {
		set element [lindex $rss_news $count]
		incr count
	}
	# there is some duplication in the following code, but we need different results depending on the element found
	while {$count <= [llength $rss_news]} {
		set element [lindex $rss_news $count]
		switch $element {
			item {
				set title ""
				set link ""
				set pubDate ""
				set description ""
				}
			title {
				incr count
				set element [string trim [lindex $rss_news $count]]
				# substitute various named characters
				regsub -all {&gt;} $element {>} element
				regsub -all {&lt;} $element {<} element
				regsub -all {&amp;amp;} $element {&} element
				regsub -all {&amp;gt;} $element {>} element
				regsub -all {&amp;lt;} $element {<} element
				regsub -all {&quot;} $element {"} element
				regsub -all {&apos;} $element {'} element
				set title $element
				}
			link {
				incr count
				set link \"[lindex $rss_news $count]\"
				}
			pubDate {
				incr count
				set pubDate [lindex $rss_news $count]
				# only continue for, up to, one year of the news reports
				set date [clock scan $pubDate -format "%a, %d %b %G %H:%M:%S %z"]
				if {$date > [clock add [clock seconds] 1 year]} {break}
				# remove any unwanted characters from the date string
				set pubDate [string range [string trim [string map { \{ \  \} \  } $pubDate]] 0 end-15]
				}
			description {
				incr count
				set element [lindex $rss_news $count]
				# substitute various named characters
				regsub -all {&gt;} $element {>} element
				regsub -all {&lt;} $element {<} element				
				regsub -all {&amp;amp;} $element {\&} element
				regsub -all {&amp;gt;} $element {>} element
				regsub -all {&amp;lt;} $element {<} element
				regsub -all {&quot;} $element {"} element
				regsub -all {&apos;} $element {'} element
		 		# remove any linebreaks which are not part of a <pre> statement
				set new_element ""
				set from 0
				set to [expr [string first "<pre>" $element] - 1]
				if {$to < 0} {set to "end"}
				while {$to != -1} {
					set sub_element [string map {\n \ } [string range $element $from $to]]
					append new_element $sub_element
					# unless we are at the end
					if {$to == "end"} {break}
					# add in the <pre> statement as is
					set from $to
					set to [expr [string first "</pre>" $element $from] + 6]
					set sub_element "[string range $element $from $to]"
					append new_element $sub_element 
					# next while
					# set from to the end of the </pre> statement
					set from $to
					set to [expr [string first "<pre>" $element $from] - 1]
					if {$to < 0} {set to "end"}
				}
				set element $new_element
				# remove other line breaks, which are normally not required, unless they are not at the end of a line
				set element [string map {<br>\n \n <br/>\n \n <br\ />\n \n} $element]
				set element [string map {<br> \n <br/> \n <br\ /> \n} $element]
				# remove paragraph tags and replace them with carriage returns
				set element [string map {<p> \n} $element]
				set element [string map {</p> \n} $element]
				#remove hyperlinks
				regsub -all {<a href=.*?>} $element {} element
				# remove bullet list
				regsub -all {<li>} $element { } element	
				# remove numbered list			
				regsub -all {<ul>} $element { } element
				# remove end of tag markers
				regsub -all {</a>} $element {} element
				regsub -all {</li>} $element { } element
				regsub -all {</ul>} $element { } element
				# remove multiple spaces
				regsub -all {\u20{2,}} $element {  } element
				set description $element
				}
			/item {
				set news_list $news_list<strong>$pubDate\t\t$title</strong>\n\n$link\n$description\n\n
				}
			default {}
		}
		incr count
	}
	puts $debug_out(2) "read_news rss parsed"
	puts $debug_out(2) "\t$news_list"
	view_text $news_list "Latest News"
	puts $debug_out(1) "read_news rss completed"
}

proc remove_warning_icon {icon} {
	
global debug_out
# remove a warning icon from the .filter_icons frame
# there are up to four icons
	
	puts $debug_out(1) "remove_warning_icon - called for $icon"
	# which icons are already visible, unfortunately gridded is in alphabetical order
	set gridded [grid slaves .filter_icons]
	puts $debug_out(2) "remove_warning_icon - $gridded icons are gridded"
	# if the icon is not shown then return
	if {[string first $icon $gridded] == -1} {return 0} 
	# remove the icon and reposition any others as necessary
	grid remove $icon
	# are there any other icons gridded
	if {$icon == $gridded} {return 0}
	# now get the order of the remaining icons
	set icon1 ""
	set icon2 ""
	set icon3 ""
	set icon4 ""
	set count 0
	foreach item $gridded {
		if {$item == $icon} {continue}
		incr count
		set info [split [grid info $item]]
		set position "[lindex $info 3],[lindex $info 5]"
		# there can only be four icons and we just deleted one so
		# get the order of the remaining three icons based on the column,row position
		switch $position {
			"2,2" {set icon1 $item}
			"3,2" {set icon2 $item}
			"2,3" {set icon3 $item}
			"3,3" {set icon4 $item}
		}
	}
	# reset gridded to the new icon list in order
	set gridded [list $icon1 $icon2 $icon3 $icon4]
	# now reposition the remaining icons
	set count 0
	foreach item $gridded {
		if {$item == ""} {continue}
		incr count
		switch $count {
			1 {grid configure $item -column 2 -row 2 -sticky ""}
			2 {grid configure $item -column 3 -row 2 -sticky w}
			3 {grid configure $item -column 2 -row 3 -columnspan 2 -sticky ""}
		}
	}
	puts $debug_out(1) "remove_warning_icon - completed"
	return 0
}

proc set_clock {test} {
	
global clock_id debug_out start_time sync_time
# work out the elapsed time since the last sync
# calculate the minutes rounded up

	puts $debug_out(1) "set_clock called - ([expr [clock milliseconds] - $start_time])"

	# test for a resync and update if requested
	if {$test} {test_resync}
	
	set e_time [expr [clock seconds] - $sync_time]
	# now convert the number of elapsed seconds into a string dd:hh:mm
	set days [expr int($e_time / 60 / 60 / 24)]
	set hours [expr int($e_time / 60 / 60) - ($days * 24)] 
	set mins [expr round(($e_time / 60.0) - ($hours * 60) - ($days * 60 * 24))]
	# set the next update to the next full minute 
	set delay [expr (60 - ($e_time - [expr int($e_time / 60) * 60])) * 1000]
	# show at least 1 minute
	if {[expr $days + $hours + $mins] == 0} {set mins 1}
	if {[string length $days] == 1} {set days "0$days"}
	puts $debug_out(3) "set_clock - update set to ${days}:[string range "0${hours}" end-1 end]:[string range "0${mins}" end-1 end]"
	.filter_clock configure -text "${days}:[string range "0${hours}" end-1 end]:[string range "0${mins}" end-1 end]"
	if {[string trimleft $days 0] > 7} {
		.filter_clock configure -foreground red
		balloon_set .filter_clock "Run Tools > Sync to update the sync data"
	} else {
		.filter_clock configure -foreground black
		balloon_set .filter_clock "The elapsed time since the last sync (d:h:m)"
	}		
	update

	# wait, up to, a minute
	set clock_id [after $delay {
		# update the time since last sync
		set_clock true
	}]
	
	puts $debug_out(1) "set_clock completed - ([expr [clock milliseconds] - $start_time])"
}

proc set_images {} {
	
global buttons debug_out icon_dir start_time
# Create images

	puts $debug_out(1) "set_images called - ([expr [clock milliseconds] - $start_time])"
	set error [catch {
		# Toolbar	
		image create photo delete -file "$icon_dir/$buttons/edit-delete.png"
		image create photo install -file "$icon_dir/$buttons/dialog-ok-apply.png"
		image create photo reload -file "$icon_dir/$buttons/edit-redo.png"
		image create photo tools -file "$icon_dir/$buttons/configure.png"
		image create photo upgrade -file "$icon_dir/$buttons/system-software-update.png"
		# Message Box
		image create photo filesync -file "$icon_dir/medium/folder-sync.png"
		image create photo hint -file "$icon_dir/medium/help-hint.png"
		image create photo disconnected -file "$icon_dir/medium/network-offline.png"
		image create photo warning -file "$icon_dir/medium/dialog-warning.png"
		# Fixed size
		image create photo clear -file "$icon_dir/tiny/edit-clear-locationbar-rtl.png"
		image create photo down_arrow -file "$icon_dir/tiny/pan-down-symbolic.symbolic.png"
		image create photo pacman -file "$icon_dir/small/ark.png"
		image create photo up_arrow -file "$icon_dir/tiny/pan-up-symbolic.symbolic.png"
		image create photo view -file "$icon_dir/small/view-list-text.png"
		}]

	puts $debug_out(1) "set_images completed and returned $error - ([expr [clock milliseconds] - $start_time])"

	return $error
}

proc set_message {type text} {

global debug_out find_message message selected_message
# print a message consisting of any saved message plus any new text:
	
	puts $debug_out(1) "set_message called - type $type, text \"$text\"\n\tFind Message \"$find_message\", Selected Message \"$selected_message\""
	# when a new item is selected then print the text and save it in the selected message variable
	if {$type == "selected"} {
		set selected_message $text
		set message "$find_message $text"
	} elseif {$type == "find"} {
	# when any items are found using the find procedure, print the text followed by the any saved selected message
	# save the text in the find message variable
		set find_message $text
		set message "$text $selected_message"
	} elseif {$type == "reset"} {
		set message "$find_message $selected_message"
	} else {
	# for other types of message (e.g.terminal) just print the text
		set message "$text"
	}
	puts $debug_out(1) "set_message completed - message \"$message\"\n\tFind Message \"$find_message\", Selected Message \"$selected_message\""
	
}

proc set_wmdel_protocol {type} {
	
global debug_out start_time
# set the main window exit code, depending on the type requested

	puts $debug_out(1) "set_wm_protocal called - ([expr [clock milliseconds] - $start_time])"
	if {$type == "noexit"} {
		wm protocol . WM_DELETE_WINDOW {
			puts $debug_out(2) "Don't click on exit while a Terminal is open!"
		}
	} else { 
		wm protocol . WM_DELETE_WINDOW {
			if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]}
			put_configs
			# delete all the unecessary folders created
			file delete -force $tmp_dir/config_files
			# delete the aur_upgrades directory and all of its contents
			# any aur packages with incomplete downloads or upgrades will have to be restarted
			# file delete can fail here so use rm instead
			exec rm -rf $tmp_dir/aur_upgrades
			exit
		}
	}
	puts $debug_out(1) "set_wm_protocal completed - ([expr [clock milliseconds] - $start_time])"
}

proc sort_list {list} {
	
global debug_out list_show_order start_time
# show the displayed list in the current order

	puts $debug_out(1) "sort_list called for $list_show_order and [llength $list] packages ([expr [clock milliseconds] - $start_time])"
	set heading [lindex $list_show_order 0]
	set order [lindex $list_show_order 1]
	set index [lsearch "Repo Package Version Available" $heading]
	puts $debug_out(2) "sort_list index for $heading is $index"
	set list [lsort -index $index -$order $list]
	puts $debug_out(1) "sort_list completed ([expr [clock milliseconds] - $start_time])"
	return $list
}

proc sort_list_toggle {heading} {
	
global debug_out list_show list_show_order
# toggle the order of the list according to the heading selected
# the values are Repo Package Available Installed Group(s) Description
# the headings are Package Version Available Repo

	puts $debug_out(1) "sort_list_toggle called for $heading - current order is $list_show_order"
	.wp.wfone.listview heading Package -image ""
	.wp.wfone.listview heading Version -image ""
	.wp.wfone.listview heading Available -image ""
	.wp.wfone.listview heading Repo -image ""
	
	if {$list_show_order == "$heading increasing"} {
		set list_show_order "$heading decreasing"
		.wp.wfone.listview heading $heading -image up_arrow
	} else {
		set list_show_order "$heading increasing"
		.wp.wfone.listview heading $heading -image down_arrow
	}
	puts $debug_out(2) "sort_list_toggle - call sort_list"
	set list_show [sort_list $list_show]
	puts $debug_out(1) "sort_list_toggle completed"
	return $list_show
}

proc start {} {
	
global aur_files_TID count_all count_installed count_uninstalled count_outdated debug_out list_all list_local get_system_data_TID select start_time system test_system_TID threads tmp_dir
# this is the process to start the programme from scratch or after an update is called	

	puts $debug_out(1) "start - called, call list_local ([expr [clock milliseconds] - $start_time])"
	set select false
	set system ""
	
	list_local
	puts $debug_out(2) "start - list_local done, call list_all ([expr [clock milliseconds] - $start_time])"
	list_all
	puts $debug_out(2) "start - list_all done, call count_lists ([expr [clock milliseconds] - $start_time])"
	count_lists
	puts $debug_out(2) "start - count_lists done, show counts ([expr [clock milliseconds] - $start_time])"
	
	.filter_installed configure -text "Installed ($count_installed)"
	.filter_all configure -text "All ($count_all)"
	.filter_not_installed configure -text "Not Installed ($count_uninstalled)"
	.filter_updates configure -text "Updates Available ($count_outdated)"
	if {$threads} {
		puts $debug_out(2) "start - Call threads to find the files of local packages, get the system data and test the system ([expr [clock milliseconds] - $start_time])"
		puts $debug_out(2) "start - Call aur_files thread with main_TID, list_local and ttmp_dir"
		thread::send -async $aur_files_TID [list thread_get_aur_files [thread::id] $list_local $tmp_dir]
		puts $debug_out(2) "start - Call get_system_data thread with main_TID and tmp_dir"
		thread::send -async $get_system_data_TID [list thread_get_system_data [thread::id] $tmp_dir]
		puts $debug_out(2) "start - Call test_system thread with main_TID"
		thread::send -async $test_system_TID [list thread_test_system [thread::id]]
	}
	puts $debug_out(1) "start - completed ([expr [clock milliseconds] - $start_time])"
}

proc system_upgrade {} {

global aur_versions_TID debug_out dlprog filter find fs_upgrade list_local sync_time threads tmp_dir tv_select
# run a full system upgrade

	puts $debug_out(1) "system_upgrade called"
	if {[test_internet] != 0} {return 1}
	set fs_upgrade true
	update idletasks
	cleanup_checkbuttons false
	set find ""
	.buttonbar.entry_find delete 0 end
	set filter "outdated"
	filter
	puts $debug_out(2) "system_upgrade - select all"
	all_select
	# we changed the selection
	# TreeviewSelect now updates the selection and sets a new message
	# select everything in the outdated list
	puts $debug_out(2) "system_upgrade - all selected"
	set return [execute "upgrade_all"]
	if {$return == 1} {
		all_clear
		set fs_upgrade false
		return 1
	}
	set fs_upgrade false
	filter
	puts $debug_out(1) "system_upgrade - completed"
}

proc test_aur_matches {name matches} {
	
global debug_out
# test aur matches for various conditions

	puts $debug_out(1) "test_aur_matches called"
	# if the list of matches is greater than 50 then set a warning message
	set ans "ok"
	if {[llength $matches] > 50} {
		set ans [tk_messageBox -default cancel -detail "[llength $matches] AUR packages match $name. Show all [llength $matches]?" -icon warning -message "\nFound [llength $matches] packages?" -parent . -title "Warning" -type okcancel]
	}
	if {$ans == "cancel"} {return ""}
	puts $debug_out(1) "test_aur_matches completed"
	return $matches
}

proc test_configs {} {
	
global browser debug_out diffprog editor known_browsers known_diffprogs known_editors known_terminals one_time start_time terminal terminal_string
# Test for sane configuration options

	puts $debug_out(1) "test_configs - called ([expr [clock milliseconds] - $start_time])"
	set_message terminal ""
	puts $debug_out(2) "test_configs - test browser \"$browser\""
	if {$browser != "" && [catch {exec which $browser}] == 1} {
		puts $debug_out(2) "test_configs - browser is not installed"
		tk_messageBox -default ok -detail "\"$browser\" is configured but is not installed" -icon warning -message "The browser will be reset" -parent . -title "Incorrect Option" -type ok 
		set browser [configurable_default browser $known_browsers]
	}
	puts $debug_out(2) "test_configs - test diff_prog \"$diffprog\""
	if {$diffprog != "" && [catch {exec which $diffprog}] == 1} {
		puts $debug_out(2) "test_configs - diffprog is not installed"
		tk_messageBox -default ok -detail "\"$diffprog\" is configured but is not installed" -icon warning -message "The compare programme will be reset" -parent . -title "Incorrect Option" -type ok 
		set diffprog [configurable_default browser $known_diffprogs]
	}
	puts $debug_out(2) "test_configs - test editor \"$editor\""
	if {$editor != "" && [catch {exec which [lindex $editor 0]}] == 1} {
		puts $debug_out(2) "test_configs - editor is not installed"
		tk_messageBox -default ok -detail "\"[lindex $editor 0]\" is configured but is not installed" -icon warning -message "The editor will be reset" -parent . -title "Incorrect Option" -type ok 
		set editor [configurable_default editor $known_editors]
	}
	puts $debug_out(2) "test_configs - test terminal \"$terminal\""
	if {$terminal != "" && [catch {exec which $terminal}] == 1} {
		puts $debug_out(2) "test_configs - terminal is not installed"
		tk_messageBox -default ok -detail "\"$terminal\" is configured but is not installed" -icon warning -message "The terminal will be reset" -parent . -title "Incorrect Option" -type ok 
		set result [configurable_default terminal $known_terminals]
		set terminal [lindex $result 0]
		set terminal_string [lindex $result 1]
	} 
	# the terminal must exist
	if {$terminal == ""} {
		puts $debug_out(2) "test_configs - no terminal specified"
		set_message terminal "Error: A terminal is required"
		get_terminal
	}
	if {$terminal == "konsole" && $one_time == "true"} {
		tk_messageBox -default ok -detail "Wmctl relies on the window title set for the terminal. In order to use konsole the profile must be set to use the window title set by the shell.\nSet Tab title format to \"%w\"" -icon warning -message "The terminal emulator \"$terminal\" has been selected" -parent . -title "Changed terminal emulator" -type ok
		set one_time "false"
	}
	puts $debug_out(1) "test_configs - completed ([expr [clock milliseconds] - $start_time])"
}

proc test_files_data {type} {
	
global debug_out filter_list find findtype list_repos pacman_files_upgrade pkgfile_upgrade su_cmd tmp_dir
# test that the files databases for $type are up to date. Offer to update them if required.
# known types are pkgfile and pacman

# return codes: 0 success, 1 failed, 2 updated, 3 cancelled

	puts $debug_out(1) "test_files_data called for $type"
	
	set error 0
	set latest 0
	
	if {$type == "pkgfile"} {
		set title "pkgfile"
		set dir "/var/cache/pkgfile"
	} else {
		set title "pacman files"
		# saving the files databases in the dbpath directory will mean that they will not be in sync with the sync databases
		# so save the files databases in the home tmp directory
		set dir "$tmp_dir/sync"
	}
	
	puts $debug_out(2) "test_files_data - title set to $title, directory to check is $dir"
	
	foreach item $list_repos {
		puts $debug_out(3) "test_files_data - test for $item in $dir"
		if {[file exists $dir/$item.files] == 0} {
			puts $debug_out(3) "\tdoes not exist"
			continue
		}
		if {[file mtime $dir/$item.files] > $latest} {
			set latest [file mtime $dir/$item.files]
			puts $debug_out(3) "\tlatest set to $latest"

		}
	}
	puts $debug_out(2) "test_files_data - $type - databases last updated at [clock_format $latest full]"
	# is the latest date more than 24 hours old
	if {[expr [clock seconds] > [clock add $latest 1 day]]} {
		set message "were last updated on \n[clock_format $latest full]."
		if {$latest == 0} {set message "must be initialized."}
		set ans [tk_messageBox -default yes -detail "Do you want to update the $type file databases now?" -icon question -message "The $type file databases $message" -parent . -title "Update $title databases?" -type yesnocancel]
		switch $ans {
			yes {
				puts $debug_out(2) "test_files_data - $type - try to update databases"
				# we do this in a terminal to show the progress
				if {$type == "pkgfile"} {
					set action "Update pkgfile databases"
					set command "$su_cmd pkgfile -u"
					if {$su_cmd == "su -c"} {set command "$su_cmd \"pkgfile -u\""}
				} else {
					set action "Update pacman file databases"
					set command "$su_cmd pacman -b $tmp_dir -Fy"
					if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Fy\""}
				}
				set wait true
				set error [execute_command $action $command $wait]
				puts $debug_out(1) "test_files_data - ran execute_command with result $error"
				if {$error != 0} {
					puts $debug_out(1) "test_files_data - $type - update failed"
					place_warning_icon .filter_icons_filesync
					return 1
				}
				remove_warning_icon .filter_icons_filesync
				# if the find type is "findfile" run it
				if {$findtype == "findfile" && $find != ""} {
					puts $debug_out(2) "test_files_data - call find file"
					find $find $filter_list all
				}
				puts $debug_out(1) "test_files_data - completed"
				return 2
			}
			no {
				update
				if {$type == "pacman"} {
					set pacman_files_upgrade [expr $pacman_files_upgrade + 1]
				} else {
					set pkgfile_upgrade [expr $pkgfile_upgrade + 1]
				}
				place_warning_icon .filter_icons_filesync
				puts $debug_out(1) "test_files_data - completed with outdated files (do not ask again)"
				return 1
			}
			cancel {
				update
				place_warning_icon .filter_icons_filesync
				puts $debug_out(1) "test_files_data - update cancelled"
				return 3
			}
		}	
	} else {
		# databases are up to date
		puts $debug_out(1) "test_files_data - completed files are up to date"
		return 0
	}
}

proc test_internet {} {
	
global debug_out is_connected start_time
# try three times to find an internet connection using three different sites in case one does not reply

	puts $debug_out(1) "test_internet called - ([expr [clock milliseconds] - $start_time])"
	set count 0
	set try(0) "google.com"
	set try(1) "yahoo.com"
	set try(2) "bing.com"
	while {$count < 3} {
		# bypass the ping dns lookup in case it takes too long
		# uses IPv4 which should work for everyone
		set error [catch {exec timeout 3 getent ahostsv4 $try($count)} result]
		puts $debug_out(2) "test_internet - ran gentent with error $error and result \"$result\""
		# if we have a result
		if {$error == 0} {
			set ip  [string range  $result 0 [string first " " $result]]
			set error [catch {eval [concat exec timeout 3 ping -c 1 $ip]} result]
			puts $debug_out(2) "test_internet - $count returned $error $result"
			if {$error == 0} {
				set is_connected true
				remove_warning_icon .filter_icons_disconnected
				puts $debug_out(1) "test_internet completed - ([expr [clock milliseconds] - $start_time])"
				return 0
			}
		}
		incr count
		after 100
	}
	# if we reach this point and $is_connected was true then write an error message, if $is_connected is already false then just carry on
	if {$is_connected} {
		set ans [tk_messageBox -default ok -detail "" -icon warning -message "No Internet - Please check your internet connection and try again" -parent . -title "Warning" -type ok]
	}
	set is_connected false
	place_warning_icon .filter_icons_disconnected
	puts $debug_out(1) "test_internet failed - ([expr [clock milliseconds] - $start_time])"
	return 1
}

proc test_resync {} {

global aur_versions_TID debug_out dlprog list_local thread threads sync_time tmp_dir
# test if a resync is required after a failed update or an external intervention

	puts $debug_out(1) "test_resync called - sync_time is $sync_time"
	# save the last recorded time that the temporary sync database was updated
	set prev_tmpsync_time $sync_time
	# now get the latest time that the temporary sync database was updated
	set latest_tmpsync_time [file mtime "$tmp_dir/sync"]
	# now update the temporary sync database if necessary and record the update time
	# 	get_sync_time checks that the temporary sync database exists and is the same or newer than the pacman database
	# get_sync_time returns the update time of the tmp database and the update time of the real database
	set sync_time [lindex [get_sync_time] 0]
	# get_sync_time may have changed the value of latest_tmpsync_time
	# see if an update occurred to the sync database because it will have changed the temporary sync database time.
	if {$latest_tmpsync_time != $sync_time} {
		puts $debug_out(2) "test_resync - external pacman sync detected"
		# the pacman database has been updated, is the system stable?
		test_system ""
	}
	# now we can see if an update occurred to the temporary sync database because the mtime will have changed from the previously recorded tmpsync time.
	if {$sync_time != $prev_tmpsync_time} {
		puts $debug_out(2) "test_resync - external temporary sync detected"
		# was anything updated?
		set last_update_time [get_file_mtime $tmp_dir/sync db]
		puts $debug_out(2) "test_resync - an external temporary database was last updated [clock_format $last_update_time "short_full"], the last time a sync was recorded by vpacman was [clock_format $prev_tmpsync_time "short_full"]"
		# if the last time that a db file was updated is later than the previous tmpsync time then one of the db files was updated
		# this could be because there was an external system update (failed or not) or an external sync of the temporary databases.
		if {$last_update_time > $prev_tmpsync_time} {
			puts $debug_out(2) "test_resync - external temporary sync update detected"
			# the temporary sync database has been updated, the lists may not be up to date so restart 
			# set a warning message if the vpacman window is displayed ...
			if {"[focus]" == ""} {
				puts $debug_out(2) "test_resync - vpacman does not have the focus so call start without confirmation"
			} else {
				puts $debug_out(2) "test_resync - vpacman has the focus so ask to continue"
				tk_messageBox -default ok -detail "This may be due to a failed system update or the action of an external programme.\nThe data will now be reloaded" -icon warning -message "The temporary database is out of sync." -parent . -title "Out of Sync" -type ok
			}
			# ... otherwise just start
			# call start
			start
			if {$threads} {
				puts $debug_out(2) "test_resync - restart (threads) called test_internet"
				if {[test_internet] == 0} {
					# and run the aur_versions thread to get the current aur_versions
					# this thread may conflict with get_aur_updates so mark it running
					set thread "running"
					puts $debug_out(2) "test_resync - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local"
					thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
				} else {
					puts $debug_out(2) "test_resync - cannot call aur versions thread - threading not available"
					# so set aur_versions to "" so that get_aur_updates will get the versions when it runs next
					set aur_versions ""
				}
			}
			filter
		}
	}
	puts $debug_out(1) "test_resync - completed"
}

proc test_system {result} {
	
global debug_out start_time system_test
# if the sync database shows updates available then the system is out of sync and therefore unstable 
	
	puts $debug_out(1) "test_system - called to update status ([expr [clock milliseconds] - $start_time])"
	
	if {$result == ""} {
		# looks like we are being asked to update the system status
		set error [catch {exec pacman -Qu}]
		if {$error == 0} {
			set result "unstable"
		} else {
			set result "stable"
		}
	} else {
		puts $debug_out(2) "test_system -called by test system thread"
	}
	if {$result == "unstable"} {
		place_warning_icon .filter_icons_warning
	} else {
		remove_warning_icon .filter_icons_warning
	}
	set system_test $result
	puts $debug_out(1) "test_system complete - the system is $result ([expr [clock milliseconds] - $start_time])"
	return "$result"
}

proc test_versions {installed available} {
	
global debug_out start_time
# test if the available version is newer or older than the installed version
# test_versions is called when the versions in list_all or list_show are not the same.
# pacman -b $tmp_dir -Qu should produce the same result, but would need to be run at start which could add to the startup time.
# test_versions is also called for AUR/local packages and to check AUR/Local dependancies

	puts $debug_out(1) "test_versions called for installed $installed and available $available  ([expr [clock milliseconds] - $start_time])"

	if {$available == "-na-"} {
		# there is no available version
		puts $debug_out(2) "test_versions - there is no new available version so return same or older"
		return "same"
	}


	set installed [split $installed "-"]
	set available [split $available "-"]
	set old_build [lindex $installed 1]
	set new_build [lindex $available 1]
	set installed [lindex $installed 0]
	set available [lindex $available 0]
	
	set old_epoch 0
	set index [string first ":" $installed]
	if {$index != -1} {
		set old_epoch [string range $installed 0 $index-1]
		set installed [string range $installed $index+1 end]
	}
	set new_epoch 0
	set index [string first ":" $available]
	if {$index != -1} {
		set new_epoch [string range $available 0 $index-1]
		set available [string range $available $index+1 end]
	}
	
	puts $debug_out(2) "test_versions - test installed $old_epoch : $installed - $old_build and available $new_epoch : $available - $new_build"
	
	if {$new_epoch > $old_epoch} {
		return "newer"
	} elseif {$new_epoch < $old_epoch} {
		return "older"
	}
	set old_version [split $installed "+."]
	set new_version [split $available "+."]
	if {[string first "rc" $old_version] != -1 && [string first "rc" $new_version] == -1} {
		# the installed version was a release candidate and new version is not
		puts $debug_out(2) "test_versions - was a release candidate - this is an update"
		return "newer"
	}
	
	# what is the length of the longer list
	set length [llength $old_version]
	if {[llength $old_version] < [llength $new_version]} {
		set length [llength $new_version]
	}	
	
	puts $debug_out(2) "test_versions - compare new version \"$new_version\" to old version \"$old_version\""
	set count 0
	while {$count < $length} {
		puts $debug_out(3) "test_versions - comparing \"$old_version\" to \"$new_version\", $length items, $count item: [lindex $new_version $count] and [lindex $old_version $count]"
		# if the first item is blank and the second item is not then the second version is an extended version
		if {[lindex $new_version $count] != "" && [lindex $old_version $count] == ""} {
			puts $debug_out(3) "test_versions - version number is extended, available is newer"
			return "newer"
		}
		# if both versions are integer numbers test them
		if {[string is integer [lindex $new_version $count]] && [string is integer [lindex $old_version $count]]} {
			if {[lindex $new_version $count] > [lindex $old_version $count]} {
				puts $debug_out(1) "test_versions - numeric compare indicates available is newer"
				return "newer"
			} elseif {[lindex $new_version $count] < [lindex $old_version $count]} {
				puts $debug_out(1) "test_versions - numeric compare indicates available is older"
				return "older"
			}
		# next check if strings can be compared
		} elseif {[string length [lindex $new_version $count]] == [string length [lindex $old_version $count]] || ([string is alpha [lindex $new_version $count]] && [string is alpha [lindex $old_version $count]])} {
			puts $debug_out(3) "test_versions - compare \[string compare [lindex $new_version $count] [lindex $old_version $count]\] "
			set result [string compare [lindex $new_version $count] [lindex $old_version $count]]
			puts $debug_out(3) "test_versions - compare returned $result"
			if {$result == 1} {
				puts $debug_out(1) "test_versions - compare strings indicates that available is newer"
				return "newer"
			} elseif {$result == -1} {
				puts $debug_out(1) "test_versions - compare strings indicates that available is older"
				return "older"
			}
		# otherwise compare two alphanumeric strings of unequal length
		} else {
			set string1 [lindex $new_version $count]
			set string2 [lindex $old_version $count]
			puts $debug_out(3) "test_versions - complex compare $string1 with $string2"
			if {$string1 == ""} {
				puts $debug_out(3) "test_versions - complex compare string1 is blank, installed version is newer"
				return "older"
			} elseif {$string2 == ""} {
				puts $debug_out(3) "test_versions - complex compare string2 is blank, available version is newer"
				return "newer"
			}
			set index1 0
			set index2 0
			
			while true {
				set failindex1 0
				set failindex2 0
				# does each string start with an alpha sub string
				set result [string is alpha -failindex failindex1 "$string1"]
				puts $debug_out(3) "test_versions - complex compare new part is \"$string1\" alpha? Result is $result, Fail index is $failindex1"
				# what type is string1 
				if {$result == 1} {
					puts $debug_out(3) "test_versions - complex compare \"$string1\" is alpha"
				} elseif {$failindex1 != 0} {
					puts $debug_out(3) "test_versions - complex compare \"$string1\" is alphanumeric"
				} else {
					puts $debug_out(3) "test_versions - complex compare \"$string1\" starts with a number"
					set result [string is integer -failindex failindex1 \"$string1\"]
					if {$result == 1} {
						puts $debug_out(3) "test_versions - complex compare \"$string1\" is numeric"
						set failindex1 0
					}
				}
				# what type is string2
				set result [string is alpha -failindex failindex2 "$string2"]
				puts $debug_out(3) "test_versions - complex compare old part is \"$string2\" alpha? Results is $result, Fail index is $failindex2"
				# is string1 alpha
				if {$result == 1} {
					puts $debug_out(3) "test_versions - complex compare \"$string2\" is alpha"
				} elseif {$failindex2 != 0} {
					puts $debug_out(3) "test_versions - complex compare \"$string2\" is alphanumeric"
				} else {
					puts $debug_out(3) "test_versions - complex compare \"$string2\" starts with a number"
					set result [string is integer -failindex failindex2 \"$string2\"]
					if {$result == 1} {
						puts $debug_out(3) "test_versions - complex compare \"$string2\" is numeric"
						set failindex2 0
					}
				}

				if {$failindex1 == 0} {
					puts $debug_out(3) "test_versions - complex compare set sub_string1 to \"$string1\""
					set sub_string1 $string1
				} else {
					puts $debug_out(3) "test_versions - complex compare set sub_string1 to \"[string range $string1 $index1 $failindex1-1]\""
					set sub_string1 [string range $string1 $index1 $failindex1-1]
				}
				if {$failindex2 == 0} {
					puts $debug_out(3) "test_versions - complex compare set sub_string2 to \"$string2\""
					set sub_string2 $string2
				} else {
					puts $debug_out(3) "test_versions - complex compare set sub_string2 to \"[string range $string2 $index2 $failindex2-1]\""
					set sub_string2 [string range $string2 $index2 $failindex2-1]
				}
				puts $debug_out(3) "test_versions - complex compare sub_strings \"$sub_string1\" with \"$sub_string2\""
				if {[string is integer $sub_string1] == 1 && [string is alpha $sub_string2] == 1} {
					puts $debug_out(1) "test_versions - complex compare \"$sub_string1\" is newer (is integer)"
					return "newer"
				} elseif {[string is alpha $sub_string1] == 1 && [string is integer $sub_string2] == 1} {
					puts $debug_out(1) "test_versions - complex compare \"$sub_string1\" is older (is alpha not integer)"
					return "older"
				} elseif {[string is integer $sub_string1] == 1 && [string is integer $sub_string2] == 1} {
					puts $debug_out(3) "test_versions - complex compare sub_strings are both integers"
					if {$sub_string1 > $sub_string2} {
						puts $debug_out(1) "test_versions - complex compare values indicates that available is newer"
						return "newer"
					} elseif {$sub_string1 < $sub_string2} {
						puts $debug_out(1) "test_versions - complex compare values indicates that available is older"
						return "older"
					}
				} else {
					set result [string compare $sub_string1 $sub_string2]
					puts $debug_out(3) "test_versions - complex compare strings \"$sub_string1\" with \"$sub_string2\" returned $result"
					if {$result == 1} {
						puts $debug_out(1) "test_versions - complex compare strings indicates that available is newer"
						return "newer"
					} elseif {$result == -1} {
						puts $debug_out(1) "test_versions - complex compare strings indicates that available is older"
						return "older"
					}
				}
				puts $debug_out(3) "test_versions - complex compare indicates the strings are the same"
				set string1 [string range $string1 [string length $sub_string1] end]
				set string2 [string range $string2 [string length $sub_string2] end]
				set index1 $failindex1 
				set index2 $failindex2
				puts $debug_out(3) "test_versions - complex compare now test \"$string1\" with \"$string2\""
			}
		}
		incr count
	}
	if {$new_build > $old_build} {
		puts $debug_out(2) "test_versions - build version indicates that available is newer"
		return "newer"
	} elseif {$new_build < $old_build} {
		puts $debug_out(2) "test_versions - build version indicates that available is older"
		return "older"
	}
	puts $debug_out(1) "test_versions completed - versions are the same"
	return "same"	
}

proc toggle_buttonbar {} {

global debug_out show_buttonbar	
# toggle the buttonbar on or off

	puts $debug_out(1) "toggle_buttonbar called"
	if {[.menubar.view entrycget 6 -label] == "Hide Toolbar"} {
		.menubar.view entryconfigure 6 -command {
			grid .buttonbar -in . -row 2 -column 1 -columnspan 3 -sticky ew
			set show_buttonbar "yes"
			toggle_buttonbar
		} -label "Show Toolbar" -state normal -underline 5
	} else {
		.menubar.view entryconfigure 6 -command {
			grid remove .buttonbar 
			set show_buttonbar "no"
			toggle_buttonbar
		} -label "Hide Toolbar" -state normal -underline 5
	}
	puts $debug_out(1) "toggle_buttonbar completed"
}

proc toggle_ignored {name} {
	
global debug_out su_cmd tmp_dir win_mainx win_mainy
# check and amend the list of ignored packages

	puts $debug_out(1) "toggle_ignored called"
	set detail ""
	set ignored_list [find_pacman_config all_ignored]
	puts $debug_out(2) "toggle_ignored - ignored list is \"$ignored_list\""
	set index [lsearch -exact $ignored_list $name] 
	if {$index != -1} {
		puts $debug_out(2) "toggle_ignored $name exists in ignored_list"
		set msg_text "was found in the list, $name will be deleted from"
		set ignored_list [lreplace $ignored_list $index $index]
	} else {
		puts $debug_out(2) "toggle_ignored $name does not exist in ignored_list"
		set msg_text "was not found in the list, $name will be added to"
		lappend ignored_list $name
	}
	set ignored_list [lsort -dictionary $ignored_list]
	set ans [tk_messageBox -default no -detail "$name $msg_text the list of ignored packages.\n\n         Answer Yes to update the list\n         Answer No to cancel\n\nA backup copy of the pacman configuration file (/etc/pacman.conf) will be saved at /etc/pacman.conf.bak" -icon info -message "Update the Ignored Packages list in the pacman configuration file?" -parent . -title "Information" -type yesno]
	if {$ans == "yes"} {
		# replace the ignored list in /etc/pacman.conf
		set fid1 [open "/etc/pacman.conf" r]
		set fid2 [open "$tmp_dir/pacman.conf" w]
		# locate the options section
		while {[eof $fid1] == 0} {
			gets $fid1 line
			puts $fid2 $line
			if {[string first "\[options\]" $line] != -1} {
				break
			}
		}
		# now continue until another secction is found 		
		while {[eof $fid1] == 0} {
			gets $fid1 line
			# if we find a new section before the IgnorePkg line then insert the line and finish off
			if {[string first "# REPOSITORIES" $line] == 0 || [string first "\[" $line] == 0} {
				puts $fid2 "IgnorePkg = $ignored_list"
				puts $fid2 $line
				break
			# if we find the IgnorePkg line then replace it and finish off
			} elseif {[string first "IgnorePkg" $line] == 0 || [string first "#IgnorePkg" $line] == 0} {
				puts $fid2 "IgnorePkg = $ignored_list"
				break
			} else {
				puts $fid2 $line
			}
		}
		# and write the rest of the file
		gets $fid1 line
		while {[eof $fid1] == 0} {
			puts $fid2 $line
			gets $fid1 line
		}
		close $fid1
		close $fid2
		# now copy the pacman.conf file back to /etc
		if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
			set fid [open $tmp_dir/vpacman.sh w]
			puts $fid "#!/bin/sh"
			puts $fid "password=\$1"
			if {$su_cmd == "su -c"} {
				puts $fid "echo \$password | $su_cmd \"cp -p /etc/pacman.conf /etc/pacman.conf.bak\" > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				puts $fid "echo \$password | $su_cmd \"cp $tmp_dir/pacman.conf /etc/pacman.conf\" > /dev/null 2>&1"
				puts $fid "if \[ $? -ne 0 \]; then exit 2; fi"
			} else {
				puts $fid "echo \$password | $su_cmd -S -p \"\" cp -p /etc/pacman.conf /etc/pacman.conf.bak > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				puts $fid "echo \$password | $su_cmd -S -p \"\" cp $tmp_dir/pacman.conf /etc/pacman.conf > /dev/null 2>&1"
				puts $fid "if \[ $? -ne 0 \]; then exit 2; fi"
			}
			close $fid
			exec chmod 0755 "$tmp_dir/vpacman.sh"
			# get the password
			set password [get_password "."]
			# password will be set to an error of 3 if the password procedure was cancelled
			if {$password != 3} {
				puts $debug_out(2) "toggle_ignored - now run the shell script"
				set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
				# don't save the password
				unset password
				puts $debug_out(2) "toggle_ignored - vpacman.sh ran with error $error and result $result"
			} else {
				unset password
				set error 1
				set result "Authentication failure"
				puts $debug_out(2) "toggle_ignored - get_password cancelled"
			}
		 	if {$error == 1} {
				# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
				# the second error message will be displayed instead, which is not too bad.
				if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
					puts $debug_out(2) "toggle_ignored - Authentification failed"
					set detail "Authentification failed - Toggle ignored cancelled"
				} else {
					puts $debug_out(2) "toggle_ignored- Backup log file failed"
					set detail "Could not backup log file - Toggle ignored cancelled"
				}
			} elseif {$error == 2} {
				puts $debug_out(2) "toggle_ignored - Copy new config file failed"
				set detail "Could not write new config file - Toggle ignored failed"
			}
		} else {
			puts $debug_out(2) "toggle_ignored - copy pacman.conf file to backup"
			set error [catch {eval [concat exec $su_cmd cp -p /etc/pacman.conf /etc/pacman.conf.bak]} error_message]
			if {$error != 0} {
				puts $debug_out(2) "toggle_ignored - backup config file failed with error: $error - \"$error_message\""
				set detail "Could not backup config file - Toggle ignored cancelled"
			} else {
				set error [catch {eval [concat exec $su_cmd cp $tmp_dir/pacman.conf /etc/pacman.conf]} error_message]
				if {$error != 0} {
					puts $debug_out(2) "toggle_ignored - copy new config file failed with error: $error - \"$error_message\""
					set detail "Could not write new config file - Toggle ignored failed"
				} 
			}	
		}
		file delete $tmp_dir/vpacman.sh
		file delete $tmp_dir/pacman.conf
		if {$detail != ""} {
			tk_messageBox -default ok -detail "$detail" -icon error -message "Failed to complete updating the ignored package list." -parent . -title "Error" -type ok	
		} else {
			if {[string first "added" $msg_text] != -1} {
				# $name has been added to the ignored list
				set_message terminal "$name will be ignored"
			} else {
				set_message terminal "$name will no longer be ignored"
			}
			after 3000 {set_message reset ""}
		}
		puts $debug_out(1) "toggle_ignored - completed"
		return 0
	} else {
		puts $debug_out(1) "toggle_ignored - cancelled update of ignored list"
		return 1
	}
}

proc trim_log {} {

global backup_dir backup_log debug_out keep_log su_cmd win_mainx win_mainy
# trim the pacman log keeping the last keep_log months and, optionally, a backup of the last file
	
	puts $debug_out(1) "trim_log called"
	
	set logfile [find_pacman_config logfile]
	
	# calculate the size of the logfile in gigabytes to two decimal places
	# use GiB binary calculation
	set logsize [expr [expr [file size $logfile] / 1024000] / 100.0]
	puts $debug_out(2) "trim_log - Logfile is [file size $logfile] ${logsize} GB"
	set result [lindex [split [exec df -h $logfile] "\n"] 1]
	set detail "The log file is ${logsize} GB, and is on the partition mounted on [lindex $result 5].\nThe Total Space on [lindex $result 5] is [lindex $result 1] and the Available Space is [lindex $result 3] or [expr 100 - [string trim [lindex $result 4] "%"]]%"
	
	
	set ans [tk_messageBox -default cancel -detail "${detail}\n\nRemoving pacman.log entries will result in loss of the pacman installation history. As a result, for example, it will no longer be possible to restore the local database from the log file history.\n\nYou must take a copy of the backup lists before continuing. \n\nContinue at your own risk." -icon warning -message "Removing pacman.log entries is not recommended." -parent . -title "Warning" -type okcancel]	
	if {$ans == "cancel"} {
		set_message terminal "Clean log cancelled"
		after 3000 {set_message terminal ""}
		return 1
	}

	# now create updated backup package files
	set ans [tk_messageBox -default ok -detail "You must take a copy of the backup lists before continuing. " -icon info -message "Save the backup lists." -parent . -title "Information" -type okcancel]
	if {$ans == "cancel"} {
		set_message terminal "Clean log cancelled"
		after 3000 {set_message terminal ""}
		return 1
	}
	
	set result [make_backup_lists]
	if {$result != 0} {
		if {$result == 1} {
			set_message terminal "Clean log failed"
		} else {
			# result must be 3, cancelled
			set_message terminal "Clean log cancelled"
		}		
		after 3000 {set_message terminal ""}
		return 1
	} else {
		# wait for the view window to close
		tkwait window .view
	}	
	
	toplevel .trim

	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {240 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {120 / 2}]
	wm geometry .trim 240x120+$left+$down
	wm iconphoto .trim tools
	wm protocol .trim WM_DELETE_WINDOW {
		# assume cancel trim, see button .trim.cancel
		.trim.cancel invoke
	}
	wm resizable .trim 0 0
	wm title .trim "Clean Pacman Log"
	wm transient .trim .

# CONFIGURE TRIM WINDOW

	label .trim.keep_label \
		-text "Number of months to keep"
	entry .trim.keep \
		-borderwidth 0 \
		-justify right \
		-textvariable keep_log \
		-validate key \
		-validatecommand {expr {"%P" == "0" || ([string is integer %P] && [string length %P] < 4 && [string first "0" %P] != 0)}} \
		-width 3
		
	# remember the old value of keep_log in case we cancel
	label .trim.keep_bak
	.trim.keep_bak configure -text $keep_log
		
	label .trim.save_label \
		-text "Save a backup of the old log"
	label .trim.yes_no \
		-anchor center \
		-background white \
		-justify center \
		-relief sunken \
		-textvariable backup_log \
		-width 3
	# now set up a binding to toggle the value of the save_backup variable
	bind .trim.yes_no <ButtonRelease-1> {
		if {[string tolower $backup_log] == "yes"} {
			set backup_log "no"
		} else {
			set backup_log "yes"
		}
	}
	frame .trim.buttons
		button .trim.continue \
			-command {
				if {$keep_log == "" || [string is integer $keep_log] == 0 || [string length $keep_log] > 3} {
					# check that keep_log is a numerical value and less than four characters long
					puts $debug_out(2) "trim_log - keep_log is set to $keep_log which is either not a numerical value or too long"
					tk_messageBox -default ok -detail "The months to keep must be a numerical value between 0 and 999.\nThe number of months to keep has not been changed" -icon warning -message "Error in months to keep the log" -parent . -title "Incorrect Option" -type ok 
					# reset keep_log
					set keep_log [.trim.keep_bak cget -text]
					puts $debug_out(2) "trim_log - reset the keep_log value to \"$keep_log\""
				} else {
					set logfile [find_pacman_config logfile]
					if {[file exists $logfile]} {
						puts $debug_out(2) "trim_log - All tests have passed so trim the log"
						set keep_date [clock format [clock add [clock seconds] -$keep_log months] -format {%Y-%m-%d}]
						puts $debug_out(2) "trim_log - keep $keep_log months, from $keep_date"
						# read the log into a tmp file keeping lines dated on or after $keep_date
						# don't keep the lines until we decide to
						set keep false
						set fid [open $logfile r]
						set fid1 [open $tmp_dir/pacman.log.tmp w]
						gets $fid line
						while {![eof $fid]} { 
							# if the line starts with a date string that is greater than of equal to the keep date, start keeping the lines
							# any information or memo lines will now be kept as well as the date lines
							if {$keep} {
								puts $fid1 $line
							} elseif {[string first "\[" $line] == 0 && "[string range $line 1 10]" >= "$keep_date"} {
								set keep true
								puts $fid1 $line
							}
							gets $fid line
						}
						close $fid
						close $fid1
				 		# now we have the new log file
						# so copy the log to a backup file if requested
						# and if there are no errors then overwrite the log with the tmp file
						set error 0
						# if su_cmd is su -c or sudo then we need a password
						if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
						 	set fid [open $tmp_dir/vpacman.sh w]
							puts $fid "#!/bin/sh"
							puts $fid "password=\$1"
							if {$backup_log == yes} {
								puts $debug_out(2) "trim_log - Copy log file to backup"
								if {$su_cmd == "su -c"} {
									puts $fid "echo \$password | $su_cmd \"cp $logfile $backup_dir/[file tail $logfile].bak\" > $tmp_dir/errors 2>&1"
									puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
									puts $fid "echo \$password | $su_cmd \"cp $tmp_dir/pacman.log.tmp $logfile\" > $tmp_dir/errors 2>&1"
									puts $fid "if \[ $? -ne 0 \]; then exit 2; fi"
								} else {
									puts $fid "echo \$password | $su_cmd -S -p \"\" cp $logfile $backup_dir/[file tail $logfile].bak > $tmp_dir/errors 2>&1"
									puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
									puts $fid "echo \$password | $su_cmd -S -p \"\" cp $tmp_dir/pacman.log.tmp $logfile > $tmp_dir/errors 2>&1"
									puts $fid "if \[ $? -ne 0 \]; then exit 2; fi"
								}
								
						 	}
							close $fid
							exec chmod 0755 "$tmp_dir/vpacman.sh"
							# get the password
							grab release .trim
							set password [get_password ".trim"]
							# password will be set to an error of 3 if the password procedure was cancelled
							if {$password != 3} {
								puts $debug_out(2) "trim_log - now run the shell script"
								set error [catch {eval [concat exec "$tmp_dir/vpacman.sh" $password]} result]
								# don't save the password
								unset password
								puts $debug_out(2) "trim_log - vpacman.sh ran with error $error and result $result"
							} else {
								unset password
								set error 1
								set result "Authentication failure"
								puts $debug_out(2) "trim_log - get_password cancelled"
							}
						 	if {$error == 1} {
								# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
								# the second error message will be displayed instead, which is not too bad.
								if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
									puts $debug_out(2) "trim_log - Authentification failed"
									set_message terminal "Authentification failed - Clean Pacman Log cancelled"
								} else {
									puts $debug_out(2) "trim_log - Backup log file failed"
									set_message terminal "Could not backup log file - Clean Pacman Log cancelled"
								}
							} elseif {$error == 2} {
								puts $debug_out(2) "trim_log - Copy new log file failed"
								set_message terminal "Could not write new log file - Clean Pacman Log failed"
							}
						} else {
							if {$backup_log == yes} {
								puts $debug_out(2) "trim_log - Copy log file to backup"
								set error [catch {eval [concat exec $su_cmd cp $logfile $backup_dir/[file tail $logfile].bak]} error_message]
								if {$error != 0} {
									puts $debug_out(2) "trim_log - Backup log file failed with error: $error - \"$error_message\""
									set_message terminal "Could not backup log file - Clean Pacman Log cancelled"
								}
							}
							if {$error == 0} {
								set error [catch {eval [concat exec $su_cmd cp $tmp_dir/pacman.log.tmp $logfile]} error_message]
								if {$error != 0} {
									puts $debug_out(2) "trim_log - Copy new log file failed with error: $error - \"$error_message\""
									set_message terminal "Could not write new log file - Clean Pacman Log failed"
								} 
							}
						}
						file delete $tmp_dir/pacman.log.tmp
						file delete $tmp_dir/vpacman.sh
						file delete $tmp_dir/errors
					} else {
						tk_messageBox -default ok -detail "" -icon error -message "The pacman log file ($logfile) is missing." -parent . -title "Error" -type ok
					}
					if {$error == 0} {
						set_message terminal "Clean Pacman Log completed"
						after 3000 {set_message terminal ""}
					} else {
						# the message was set above, since it is an
						# error report, leave it on screen for a little longer
						after 5000 {set_message terminal ""}
					}
					puts $debug_out(1) "trim_log completed"
					grab release .trim
					destroy .trim
				}
			} \
			-text "Continue"
		button .trim.cancel \
			-command {
				set keep_log [.trim.keep_bak cget -text]
				puts $debug_out(1) "read_log cancelled"
				grab release .trim
				destroy .trim
			} \
			-text "Cancel"

	# Geometry management

	grid .trim.keep_label -in .trim -row 2 -column 2 \
		-sticky w
	grid .trim.keep -in .trim -row 2 -column 4 \
		-sticky e
	grid .trim.save_label -in .trim -row 3 -column 2 \
		-sticky w
	grid .trim.yes_no -in .trim -row 3 -column 4 \
		-sticky e
	grid .trim.buttons -in .trim -row 6 -column 1 \
		-columnspan 5 \
		-sticky we
		grid .trim.continue -in .trim.buttons -row 1 -column 1 \
			-sticky sw
		grid .trim.cancel -in .trim.buttons -row 1 -column 2 \
			-sticky se
		
	# Resize behavior management

	grid rowconfigure .trim 1 -weight 0 -minsize 30 -pad 0
	grid rowconfigure .trim 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .trim 3 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .trim 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .trim 5 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .trim 6 -weight 0 -minsize 50 -pad 0
	
	grid columnconfigure .trim 1 -weight 0 -minsize 15 -pad 0
	grid columnconfigure .trim 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .trim 3 -weight 0 -minsize 5 -pad 0
	grid columnconfigure .trim 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .trim 5 -weight 0 -minsize 15 -pad 0
	
	grid rowconfigure .trim.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .trim.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .trim.buttons 2 -weight 1 -minsize 0 -pad 0

	balloon_set .trim.keep_label "The number of months of history to keep\nToday is always saved"
	balloon_set .trim.keep "The number of months of history to keep\nToday is always saved"
	balloon_set .trim.save_label "Save a backup of the pacman log at $backup_dir/pacman.log.bak"
	balloon_set .trim.yes_no "Save a backup of the pacman log at $backup_dir/pacman.log.bak"
	balloon_set .trim.continue "Clean the pacman log"
	balloon_set .trim.cancel "Cancel - do not clean the log"

	update
	grab set .trim
}

proc update_config_files {filelist} {

global editor debug_out diffprog su_cmd tmp_dir win_mainx win_mainy
# tools to update any config files found

	puts $debug_out(1) "update_config_files called for $filelist"
	
	# save the permissions and the ownership of each of the files
	# and save the list of any destination files
	set source_files ""
	set destination ""
	set destination_files ""
	set detail ""
	
	# make sure that any temporary directory from before was deleted
	file delete -force $tmp_dir/config_files
	# and make a temporary directory to record the changes requested
	file mkdir $tmp_dir/config_files
	
	foreach file $filelist {
		lappend source_files $file [file attributes $file -permissions] [file attributes $file -owner] [file attributes $file -group]
		set path [file dirname $file]
		puts $debug_out(2) "update_config_files - path is $path"
		puts $debug_out(2) "update_config_files - file mkdir $tmp_dir/config_files/$path"
		file mkdir $tmp_dir/config_files/$path
		set destination [file rootname $file]
		if {[file exists $destination]} {
			lappend destination_files $destination [file attributes $destination -permissions] [file attributes $destination -owner] [file attributes $destination -group]
		} else {
			lappend destination_files "-none-" "-none-" "-none-" "-none-" 
		}
	}
	puts $debug_out(2) "update_config_files - source files: $source_files"
	puts $debug_out(2) "update_config_files - destination files: $destination_files"

	# the user will need rw permissions on all the files to compare, copy, edit or move them so
	# make a working copy of all the source and destination files in the temporary directory
	set index 0
	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		set fid [open $tmp_dir/vpacman.sh w]
		puts $fid "#!/bin/sh"
		puts $fid "password=\$1"
		foreach {file permissions owner group} $source_files {
			if {$su_cmd == "su -c"} {
				puts $debug_out(2) "update_config_files - copy source file $file $tmp_dir/config_files/$destination"
				puts $fid "echo \$password | $su_cmd \"cp -p $file $tmp_dir/config_files/$file\" > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				puts $fid "echo \$password | $su_cmd \"chmod 0666 $tmp_dir/config_files/$file\" > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				set destination [lindex $destination_files $index]
				if {$destination != "-none-"} {
					puts $debug_out(2) "update_config_files - copy $destination $tmp_dir/config_files/$destination"
					puts $fid "echo \$password | $su_cmd \"cp -p $destination $tmp_dir/config_files/$destination\" > /dev/null 2>&1"
					puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
					puts $fid "echo \$password | $su_cmd \"chmod 0666 $tmp_dir/config_files/$destination\" > /dev/null 2>&1"
					puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				}
			} else {
				puts $debug_out(2) "update_config_files - copy source file $file $tmp_dir/config_files/$destination"
				puts $fid "echo \$password | $su_cmd -S -p \"\" cp -p $file $tmp_dir/config_files/$file > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				puts $fid "echo \$password | $su_cmd -S -p \"\" chmod 0666 $tmp_dir/config_files/$file > /dev/null 2>&1"
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				set destination [lindex $destination_files $index]
				if {$destination != "-none-"} {
					puts $debug_out(2) "update_config_files - copy destination file $destination $tmp_dir/config_files/$destination"
					puts $fid "echo \$password | $su_cmd -S -p \"\" cp -p $destination $tmp_dir/config_files/$destination > /dev/null 2>&1"
					puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
					puts $fid "echo \$password | $su_cmd -S -p \"\" chmod 0666 $tmp_dir/config_files/$destination > /dev/null 2>&1"
					puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				}
			
			}
			incr index +4
		}
		close $fid
		exec chmod 0755 "$tmp_dir/vpacman.sh"
		# get the password
		grab release .
		set password [get_password "."]
		# password will be set to an error of 3 if the password procedure was cancelled
		if {$password != 3} {
			puts $debug_out(2) "update_config_files - now run the shell script"
			set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
			# don't save the password
			unset password
			puts $debug_out(2) "update_config_files - vpacman.sh ran with error $error and result \"$result\""
		} else {
			unset password
			set error 1
			set result "Authentication failure"
			puts $debug_out(2) "update_config_files - get_password cancelled"
		}
	 	if {$error != 0} {
			# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
			# the second error message will be displayed instead, which is not too bad.
			if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
				puts $debug_out(2) "update_config_files - Authentification failed"
				set detail "Authentification failed."
			} else {
				puts $debug_out(2) "update_config_files - copy config files failed with error 1"
				set detail "Could not make a working copy of the config files."
			}
		}
		# now tidy up
		file delete "$tmp_dir/vpacman.sh"
	} else {
		foreach {file permissions owner group} $source_files {
			puts $debug_out(2) "update_config_files - cp $file $tmp_dir/config_files/$file"
			set error [catch {eval [concat exec $su_cmd cp $file $tmp_dir/config_files/$file]} error_message]
			puts $debug_out(2) "\tcp $file error: $error - \"$error_message\""
			# if the file was not copied then this will be an error as well
			set error [catch {eval [concat exec $su_cmd chmod 0666 $tmp_dir/config_files/$file]} error_message]
			puts $debug_out(2) "\tchmod $tmp_dir/config_files/$file error: $error - \"$error_message\""
			set destination [lindex $destination_files $index]
			# if the source file was not copied correctly then do not copy the destination file
			if {$error == 0 && $destination != "-none-"} {
				puts $debug_out(2) "update_config_files - cp $destination $tmp_dir/config_files/$destination"
				set error [catch {eval [concat exec $su_cmd cp $destination $tmp_dir/config_files/$destination]} error_message]
				puts $debug_out(2) "\tcp $destination error: $error - \"$error_message\""
				set error [catch {eval [concat exec $su_cmd chmod 0666 $tmp_dir/config_files/$destination]} error_message]
				puts $debug_out(2) "\tchmod $tmp_dir/config_files/$destination error: $error - \"$error_message\""
			}
			# if we have an error here then something failed so
			if {$error != 0} {
				set detail "Could not make a working copy of the config files."
				break
			}
			incr index +4
		}
	}
	if {$error != 0} {
		puts $debug_out(2) "update_config_files - cancelled - $detail"
		tk_messageBox -default ok -detail "$detail" -icon error -message "Update config files cancelled" -parent . -title "Error" -type ok	
		return 1
	}
	# save a list of files to delete
	set delete_files ""
	
	toplevel .update_configs
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {760 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {300 / 2}]
	wm geometry .update_configs 760x300+$left+$down
	wm iconphoto .update_configs tools
	wm protocol .update_configs WM_DELETE_WINDOW {
		# assume cancel update, see button .update_configs.cancel
		.update_configs.cancel invoke
	}
	wm resizable .update_configs 0 0
	wm title .update_configs "Edit Pacman Configuration File Updates"
	wm transient .update_configs .

# CONFIGURE UPDATE CONFIG FILES WINDOW

	label .update_configs.filelist
	.update_configs.filelist configure -text "$filelist"
	
	label .update_configs.source_files
	.update_configs.source_files configure -text "$source_files"
	
	label .update_configs.destination_files
	.update_configs.destination_files configure -text "$destination_files"
	
	label .update_configs.next_file
	.update_configs.next_file configure -text "0"
	
	label .update_configs.delete_files
	.update_configs.delete_files configure -text "$delete_files"

	frame .update_configs.files

		label .update_configs.source_label \
			-foreground blue

		label .update_configs.destination_label \
			-foreground blue
	
	set next_file 1	
	label .update_configs.nextfiles \
		-anchor w
	.update_configs.nextfiles configure -text "Next files: [lrange $filelist $next_file end]"
	
	set count 1
	while {$count < 6} {	
		listbox .update_configs.list$count \
			-height 1 \
			-selectbackground blue \
			-selectforeground white \
			-selectmode single
		
		incr count
	}

	frame .update_configs.action_buttons
	
		button .update_configs.continue \
			-command {
				# have we created the correct tmp directories in $tmp_dir/config_files
				set next [expr [.update_configs.next_file cget -text] - 1]
				set source [lindex [.update_configs.filelist cget -text] $next]
				set source_name [file tail $source]
				set destination [file rootname $source]
				set destination_name [file tail $destination]
				set backup "$destination.backup"
				
				# now do the requested action
				set action [.update_configs.continue cget -text]
				switch $action {
					Compare {
						# compare and modify source and destination
						exec $diffprog "$tmp_dir/config_files/$source" "$tmp_dir/config_files/$destination" 
						# we can do this more than once
					}
					Copy {
						# Copy $source to $destination and remove $source
						# copy over the source to the destination, overwrite any $destination
						file copy -force "$tmp_dir/config_files/$source" "$tmp_dir/config_files/$destination"
						puts $debug_out(2) "update_config_files - copied $source to $destination"
						# and delete/mark to delete the $source file
						file delete "$tmp_dir/config_files/$source"
						set delete_files [.update_configs.delete_files cget -text]
						lappend delete_files "$source"
						.update_configs.delete_files configure -text $delete_files
						puts $debug_out(2) "update_config_files - copy $source to $destination - files to delete are $delete_files"
						# no more possible actions for this source file
						.update_configs.list1 configure -state disabled
						.update_configs.list2 configure -state disabled
						.update_configs.list3 configure -state disabled
						.update_configs.list4 configure -state disabled
						.update_configs.list5 configure -state disabled
						if {[llength [.update_configs.filelist cget -text]] == [.update_configs.next_file cget -text]} {
							.update_configs.continue configure -state disabled
						}
					}
					Edit {
						# Edit $source
						puts $debug_out(2) "update_config_files - edit $source"
						# set up a command to edit the source file with the chosen editor
						set action "Edit $source"
						set command "$editor $tmp_dir/config_files/$source"
						# set wait to false, otherwise a GUI editor window will drop back to the terminal
						set wait false
						execute_command $action $command $wait
						# we can do this more than once
					}
					Move {
						# Move $source  $backup
						puts $debug_out(2) "update_config_files - move $source to $backup"
						file rename "$tmp_dir/config_files/$source" "$tmp_dir/config_files/$backup"
						# now delete the original $source file
						puts $debug_out(2) "update_config_files - move $source - remove $tmp_dir/config_files/$source"
						file delete "$tmp_dir/config_files/$source"
						puts $debug_out(2) "update_config_files - move $source - add $source to the list of files to delete"
						set delete_files [.update_configs.delete_files cget -text]
						lappend delete_files "$source"
						.update_configs.delete_files configure -text $delete_files
						puts $debug_out(2) "update_config_files - move $source - files to delete are $delete_files"
						# no more possible actions for this source file
						.update_configs.list1 configure -state disabled
						.update_configs.list2 configure -state disabled
						.update_configs.list3 configure -state disabled
						.update_configs.list4 configure -state disabled
						.update_configs.list5 configure -state disabled
						.update_configs.continue configure -state disabled
						if {[llength [.update_configs.filelist cget -text]] == [.update_configs.next_file cget -text]} {
							.update_configs.continue configure -state disabled
							.update_configs.message configure -text "All the Config Files have now been processed. Select Commit to save all the changes, select Cancel to abort." 
						}
						puts $debug_out(2) "update_config_files - move $source completed"
					}
					Remove {
						# Remove $source
						# remove the temporary source file (if it exists) and mark it to delete
						puts $debug_out(2) "update_config_files - remove $source"
						file delete "$tmp_dir/config_files/$source"
						set delete_files [.update_configs.delete_files cget -text]
						lappend delete_files "$source"
						.update_configs.delete_files configure -text $delete_files
						puts $debug_out(2) "update_config_files - remove $source - files to delete are $delete_files"
						# no more possible actions for this source file
						.update_configs.list1 configure -state disabled
						.update_configs.list2 configure -state disabled
						.update_configs.list3 configure -state disabled
						.update_configs.list4 configure -state disabled
						.update_configs.list5 configure -state disabled
						.update_configs.continue configure -state disabled
						if {[llength [.update_configs.filelist cget -text]] == [.update_configs.next_file cget -text]} {
							.update_configs.continue configure -state disabled
							.update_configs.message configure -text "All the Config Files have now been processed. Select Commit to save all the changes, select Cancel to abort." 
						}
					}
				}
			} \
			-text "Select" \
			-width 10
		
		# set up bindings to change the button text
		bind .update_configs.list1 <<ListboxSelect>> {
			if {[.update_configs.list1 curselection] != ""} {
				.update_configs.continue configure -text "Compare"
				.update_configs.message configure -text "Select the required option and press the Action button (Compare). Next File will move to the next file in the list." 
			}
		}
		bind .update_configs.list2 <<ListboxSelect>> {
			if {[.update_configs.list2 curselection] != ""} {
				.update_configs.continue configure -text "Copy"
				.update_configs.message configure -text "Select the required option and press the Action button (Copy). Next File will move to the next file in the list." 
			}
		}
		bind .update_configs.list3 <<ListboxSelect>> {
			if {[.update_configs.list3 curselection] != ""} {
				.update_configs.continue configure -text "Edit"
				.update_configs.message configure -text "Select the required option and press the Action button (Edit). Next File will move to the next file in the list." 
			}
		}
		bind .update_configs.list4 <<ListboxSelect>> {
			if {[.update_configs.list4 curselection] != ""} {
				.update_configs.continue configure -text "Move"
				.update_configs.message configure -text "Select the required option and press the Action button (Move). Next File will move to the next file in the list." 
			}
		}
		bind .update_configs.list5 <<ListboxSelect>> {
			if {[.update_configs.list5 curselection] != ""} {
				.update_configs.continue configure -text "Remove"
				.update_configs.message configure -text "Select the required option and press the Action button (Remove). Next File will move to the next file in the list." 
	
			}
		}
		
		button .update_configs.next \
			-command {
				# read the next file number to deal with
				puts $debug_out(2) "update_config_files - get next file"
				set next_file [.update_configs.next_file cget -text]
				# now check it
				set source [lindex [.update_configs.filelist cget -text] $next_file]
				set source_name [file tail $source]
				set path [file dirname $source]
				set destination [file rootname $source]
				set destination_name [file tail $destination]
			
				puts $debug_out(2) "update_config_files - next file is $source_name from $path, the original file was $destination"
			
				# populate the source and destination labels
				.update_configs.source_label configure -text "Source: $source"
				.update_configs.destination_label configure -text "Destination: $destination"
				
				# populate the listbox
				set count 1
				while {$count < 6} {
					.update_configs.list$count configure -state normal
					.update_configs.list$count delete 0 end
					incr count
				}
				.update_configs.list1 insert end "Check differences between $source and $destination"
				.update_configs.list2 insert end "Copy $source to $destination and remove $source"
				.update_configs.list3 insert end "Edit $source"
				.update_configs.list4 insert end "Move $source  $destination.backup"
				.update_configs.list5 insert end "Remove $source"
				
				# select the default listbox
				.update_configs.list1 selection set 0 end
				.update_configs.continue configure -text "Compare"
				
				# now set the state of each listbox
				if {$editor == ""} {
					puts $debug_out(2) "update_config_files - no editor defined so disable edit"
					.update_configs.list3 configure -state disabled
				}
				if {![file exists $destination]} {
					puts $debug_out(2) "update_config_files - $destination does not exist"
					.update_configs.destination_label configure -text "Destination:"
					# if there is no destination file then just offer to remove the source file or move it to a backup file so that we do not ask again
					.update_configs.list1 configure -state disabled
					.update_configs.list2 configure -state disabled
					.update_configs.list3 configure -state disabled
					# select the default list
					.update_configs.list4 selection set 0 end
					# update to post the selection message and then overwrite it
					update
					.update_configs.continue configure -text "Move"
					.update_configs.message configure -text "There is no destination file. Select the required option, Move or Remove, and press the Action button (Move)."
				} elseif {[catch {exec cmp $source $destination}] == 0} {
					puts $debug_out(2) "update_config_files - $source and $destination are identical"
					# then compare the source with the destination. If they are identical then just offer to remove the source file
					.update_configs.list1 configure -state disabled
					.update_configs.list2 configure -state disabled
					.update_configs.list3 configure -state disabled
					.update_configs.list4 configure -state disabled
					# select the default list
					.update_configs.list5 selection set 0 end
					# update to post the selection message and then overwrite it
					update
					.update_configs.continue configure -text "Remove"
					.update_configs.message configure -text "Files are identical. Press the Action button (Remove) to remove the source file." 
				}	
				# update the file lists
				if {[llength [.update_configs.filelist cget -text]] == [expr $next_file + 1]} {
					.update_configs.next configure -state disabled
					.update_configs.nextfiles configure -text "Next files:"
				} else {
					.update_configs.nextfiles configure -text "Next files: [lrange [.update_configs.filelist cget -text] $next_file+1 end]"
				}
				.update_configs.continue configure -state normal
				incr next_file
				.update_configs.next_file configure -text $next_file
			} \
			-text "Next File" \
			-width 10
			
	label .update_configs.message \
		-foreground blue
	.update_configs.message configure -text "Select the required option and press the Action button (Compare). Next File will move to the next file in the list." 
			
	frame .update_configs.buttons \
		-borderwidth 2 \
		-relief sunken
	
		button .update_configs.commit \
			-command {
				# commit all the changes made
				puts $debug_out(2) "update_config_files - commit the changes"
				# restore the permissions for the source and the destination files
				
				# get a list of all the files to be restored
				set file_restore_permissions ""
				set file_restore_permissions [glob -nocomplain -types {f} -directory $tmp_dir/config_files *]
				puts $debug_out(2) "update_config_file - files in $tmp_dir/config_files - \"$file_restore_permissions\""
				set sub_directories [glob -nocomplain -types {d} -directory $tmp_dir/config_files *]
				puts $debug_out(2) "update_config_file - directories in $tmp_dir/config_files - \"$sub_directories\""
				while true {
					if {[llength $sub_directories] != 0} {
						foreach dir $sub_directories {
							puts $debug_out(3) "update_config_file - \"[glob -nocomplain -types {f} -directory $dir *]\""
							set file_restore_permissions [concat $file_restore_permissions [glob -nocomplain -types {f} -directory $dir *]]
						}
						foreach dir $sub_directories {
							set next_sub_directories [glob -nocomplain -types {d} -directory $dir *]
							puts $debug_out(3) "update_config_file - directories in $dir - \"[glob -nocomplain -types {d} -directory $dir *]\""
						}
						set sub_directories $next_sub_directories
					} else {
						break
					}
				}
				puts $debug_out(2) "update_config_file - $file_restore_permissions"
				
				# get the permission saved for all of the source and destination files
				set source_files [.update_configs.source_files cget -text]
				puts $debug_out(2) "update_config_file - $source_files"
				set destination_files [.update_configs.destination_files cget -text]
				puts $debug_out(2) "update_config_file - $destination_files"
				
				# now restore the permissions
				puts $debug_out(2) "update_config_file - config file path length is [string length $tmp_dir/config_files]"
				set set_permissions ""
				foreach file $file_restore_permissions {
					set search_string [string range $file [string length "$tmp_dir/config_files"] end]
					puts $debug_out(3) "update_config_file - set permissions for $file - search for $search_string"

					if {[string range $search_string end-6 end] == ".backup"} {
						puts $debug_out(3) "update_config_file - search string ends in .backup"
						set search_string [string range $search_string 0 end-7]
					}
					puts $debug_out(3) "update_config_file - search string is $search_string"
					set index [lsearch $source_files $search_string]
					if {$index != -1} {
						puts $debug_out(3) "update_config_file - set permissions for $file to [lindex $source_files [expr $index + 1]] owner [lindex $source_files [expr $index + 2]]:[lindex $source_files [expr $index + 3]]"
						set set_permissions [concat $set_permissions $file [lindex $source_files [expr $index + 1]] [lindex $source_files [expr $index + 2]]:[lindex $source_files [expr $index + 3]]]
					} else {
						set index [lsearch $destination_files $search_string]
						if {$index != -1} {
							puts $debug_out(3) "update_config_file - set permissions for $file to [lindex $destination_files [expr $index + 1]], set owner [lindex $destination_files [expr $index + 2]]:[lindex $destination_files [expr $index + 3]]"
							set set_permissions [concat $set_permissions $file [lindex $source_files [expr $index + 1]] [lindex $source_files [expr $index + 2]]:[lindex $source_files [expr $index + 3]]]
						}
					}
				}
				puts $debug_out(2) "update_config_file - set permissions for \"$set_permissions\""
				
				# get a list of the files to delete
				set delete_files [.update_configs.delete_files cget -text]
				
				# now copy the new config files back to their source
				set files ""
				set dir ""
				if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
					set fid [open $tmp_dir/vpacman.sh w]
					puts $fid "#!/bin/sh"
					puts $fid "password=\$1"
					# find the directories in the current directory
					foreach {file permissions owner} $set_permissions {
						set path [string range $file [string length "$tmp_dir/config_files"] end]
						puts $debug_out(2) "update_config_files - chmod $file and copy $file to $path"
						if {$su_cmd == "su -c"} {
							# only copy the file back if it has changed
							puts $fid "echo \$password | $su_cmd \"cmp $file $path\" > /dev/null 2>&1"
							puts $fid "if \[ \$? -ne 0 \]; then"
							puts $fid "\techo \$password | $su_cmd \"chmod $permissions $file\" > /dev/null 2>&1"
							puts $fid "\tif \[ \$? -ne 0 \]; then exit 1; fi"
							puts $fid "\techo \$password | $su_cmd \"cp -p $file $path\" > /dev/null 2>&1"
							puts $fid "\tif \[ \$? -ne 0 \]; then exit 1; fi"
							puts $fid "fi"
						} else {
							# only copy the file back if it has changed
							puts $fid "echo \$password | $su_cmd -S -p \"\" cmp $file $path > /dev/null 2>&1"
							puts $fid "if \[ \$? -ne 0 \]; then"
							puts $fid "\techo \$password | $su_cmd -S -p \"\" chmod $permissions $file > /dev/null 2>&1"
							puts $fid "\tif \[ \$? -ne 0 \]; then exit 1; fi"
							puts $fid "\techo \$password | $su_cmd -S -p \"\" cp -p $file $path > /dev/null 2>&1"
							puts $fid "\tif \[ \$? -ne 0 \]; then exit 1; fi"
							puts $fid "fi"
						}
					}
					if {[llength $delete_files] != 0} {
						puts $debug_out(2) "update_config_files - delete $delete_files"
						if {$su_cmd == "su -c"} {
							puts $fid "echo \$password | $su_cmd \"rm $delete_files\" > /dev/null 2>&1"
							puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
						} else {
							puts $fid "echo \$password | $su_cmd -S -p \"\" rm $delete_files > /dev/null 2>&1"
							puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
						}
					} else {
						puts $debug_out(2) "update_config_files - no files to delete"
					}
					close $fid
					exec chmod 0755 "$tmp_dir/vpacman.sh"
					# get the password
					set password [get_password ".update_configs"]
					# password will be set to an error of 3 if the password procedure was cancelled
					if {$password != 3} {
						puts $debug_out(2) "update_config_files - now run the shell script"
						set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
						# don't save the password
						unset password
						puts $debug_out(2) "update_config_files - vpacman.sh ran with error $error and result \"$result\""
					} else {
						unset password
						set error 1
						set result "Authentication failure"
						puts $debug_out(2) "update_config_files - get_password cancelled"
					}
				 	if {$error != 0} {
						# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
						# the second error message will be displayed instead, which is not too bad.
						if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
							puts $debug_out(2) "update_config_files - Authentification failed"
							set detail "Authentification failed -commit config files changes cancelled"
						} else {
							puts $debug_out(2) "update_config_files - commit config file changes failed"
							set detail "Could not commit config file changes - update config files cancelled"
						}
					}

 					file delete $tmp_dir/vpacman.sh
				} else {
					foreach {file permissions owner} $set_permissions {
						set path [string range $file [string length "$tmp_dir/config_files"] end]
						# only copy the file back if it has been changed
						set error [catch {eval [concat exec $su_cmd cmp $file $path]}]
						if {$error == 1} {
							puts $debug_out(2) "update_config_files - chmod $file and copy $file to $path"
							set error [catch {eval [concat exec $su_cmd chmod $permissions $file]}]
							if {$error == 0} {
								set error [catch {eval [concat exec $su_cmd cp -p $file $path]}]
							}
							if {$error != 0} {
								set detail "Could not commit config file changes - update config files cancelled"
								break
							}
						} else {
							puts $debug_out(2) "update_config_files - $path has not changed"
						}
					}
					# if the folder copy did not complete then do not remove any files
					puts $debug_out(2) "update_config_files - now remove any files if error ($error) is 0 and the number of files to delete ([llength $delete_files]) is not zero"
					if {$error == 0 && [llength $delete_files] != 0} {
						set error [catch {eval [concat exec $su_cmd rm $delete_files]}]
						if {$error != 0} {
							puts $debug_out(2) "update_config_files - commit config file changes failed"
							set detail "Could not remove $delete_files\n\nCommit config files failed"
						} 
					} else {
						if {[llength $delete_files] == 0} {puts $debug_out(2) "update_config_files - no files to remove"}
					}
				}
				if {$error != 0} {
					puts $debug_out(2) "update_config_files - commit config file changes failed"
					puts $debug_out(2) "update_config_files - $detail"
					tk_messageBox -default ok -detail "$detail" -icon error -message "Could not commit config file changes" -parent .update_configs -title "Error" -type ok
				} 
				puts $debug_out(2) "update_config_files - commit terminated - invoke .update_configs.cancel"
				.update_configs.cancel invoke
			} \
			-text "Commit" \
			-width 10
			
		button .update_configs.cancel \
			-command {
				puts $debug_out(1) "update_configs - cancel invoked"
				file delete -force $tmp_dir/config_files
				grab release .update_configs
				destroy .update_configs
			} \
			-text "Cancel" \
			-width 10
	
	# and grid them
		
	grid .update_configs.files -in .update_configs -row 2 -column 1 \
		-columnspan 7 \
		-sticky we
		grid .update_configs.source_label -in .update_configs.files -row 1 -column 2 \
			-sticky w
		grid .update_configs.destination_label -in .update_configs.files -row 1 -column 4 \
			-sticky w
	grid .update_configs.nextfiles -in .update_configs -row 4 -column 2 \
		-columnspan 5 \
		-sticky w
	grid .update_configs.list1 -in .update_configs -row 6 -column 2 \
		-columnspan 5 \
		-sticky we
	grid .update_configs.list2 -in .update_configs -row 7 -column 2 \
		-columnspan 5 \
		-sticky we
	grid .update_configs.list3 -in .update_configs -row 8 -column 2 \
		-columnspan 5 \
		-sticky we
	grid .update_configs.list4 -in .update_configs -row 9 -column 2 \
		-columnspan 5 \
		-sticky we
	grid .update_configs.list5 -in .update_configs -row 10 -column 2 \
		-columnspan 5 \
		-sticky we
	grid .update_configs.action_buttons -in .update_configs -row 11 -column 2 \
		-columnspan 5 \
		-sticky we
		grid .update_configs.continue -in .update_configs.action_buttons -row 1 -column 2 \
			-sticky w
		grid .update_configs.next -in .update_configs.action_buttons -row 1 -column 3 \
			-sticky e
	grid .update_configs.message -in .update_configs -row 12 -column 2\
		-columnspan 5 \
		-sticky we
	grid .update_configs.buttons -in .update_configs -row 13 -column 2 \
		-columnspan 5 \
		-sticky we
		grid .update_configs.commit -in .update_configs.buttons -row 1 -column 2 \
			-sticky w
		grid .update_configs.cancel -in .update_configs.buttons -row 1 -column 3 \
			-sticky e
			
	# Resize behavior management
	
	grid rowconfigure .update_configs.files 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_configs.files 1 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .update_configs.files 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.files 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.files 4 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.files 5 -weight 0 -minsize 20 -pad 0

	grid rowconfigure .update_configs 1 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_configs 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 3 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_configs 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 5 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_configs 6 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 7 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 8 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 9 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 10 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .update_configs 11 -weight 0 -minsize 0 -pad 30
	grid rowconfigure .update_configs 12 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .update_configs 13 -weight 0 -minsize 0 -pad 30


	grid columnconfigure .update_configs 1 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .update_configs 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs 4 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs 5 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs 6 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs 7 -weight 0 -minsize 20 -pad 0
		
	grid rowconfigure .update_configs.action_buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_configs.action_buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.action_buttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.action_buttons 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.action_buttons 4 -weight 1 -minsize 0 -pad 0

	grid rowconfigure .update_configs.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .update_configs.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.buttons 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.buttons 3 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .update_configs.buttons 4 -weight 1 -minsize 0 -pad 0
	
	.update_configs.next invoke
	
	grab set .update_configs
}

proc update_cups {} {

global debug_out home su_cmd tmp_dir
# if we have gutenprint installed then run cups-genppdupdate
# run systemctl daemons-reload and then restart cups.

	puts $debug_out(1) "update_cups called"
	
	set message ""
	
	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		set fid [open $tmp_dir/vpacman.sh w]
		puts $fid "#!/bin/sh"
		puts $fid "password=\$1"
		set cups_gen_return [catch {exec which cups-genppdupdate}]
		if {$cups_gen_return != 1} {
			puts $debug_out(2) "update_cups added cups-genppdupdate to the commands to run"
			puts $fid "cups-genppdupdate > $tmp_dir/errors 2>&1"
			puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
		}
		if {$su_cmd == "su -c"} {
			puts $fid "echo \$password | $su_cmd \"systemctl daemon-reload\" >> $tmp_dir/errors 2>&1"
			puts $fid "if \[ \$? -ne 0 \]; then exit 2; fi"
			puts $fid "echo \$password | $su_cmd \"systemctl restart cups.service\" >> $tmp_dir/errors 2>&1"
			puts $fid "if \[ \$? -ne 0 \]; then exit 3; fi"
		} else {
			puts $fid "echo \$password | $su_cmd -S -p \"\" systemctl daemon-reload >> $tmp_dir/errors 2>&1"
			puts $fid "if \[ \$? -ne 0 \]; then exit 2; fi"
			puts $fid "echo \$password | $su_cmd -S -p \"\" systemctl restart cups.service >> $tmp_dir/errors 2>&1"
			puts $fid "if \[ \$? -ne 0 \]; then exit 3; fi"
		}
		close $fid
		exec chmod 0755 "$tmp_dir/vpacman.sh"
		# get the password
		set password [get_password "."]
		# password will be set to an error of 3 if the password procedure was cancelled
		if {$password != 3} {
			set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
			# don't save the password
			unset password
			puts $debug_out(2) "update_cups - ran vpacman.sh with error $error and result \"$result\""
		} else {
			unset password
			puts $debug_out(2) "update_cups - get_password cancelled"
			file delete $tmp_dir/vpacman.sh
			file delete $tmp_dir/errors
			return 1
		}
		if {$error != 0} {
			# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
			# the second error message will be displayed instead, which is not too bad.
			if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
				puts $debug_out(1) "update_cups - Authentification failed"
				set error_message "Authentification failed - update_cups cancelled"
			} else {
				puts $debug_out(1) "update_cups- update_cups failed"
				set error_message "Could not update cups - Update cups cancelled"
			}
			tk_messageBox -default ok -detail "$error_message" -icon error -message "Error while restarting cups" -parent . -title "Update Cups" -type ok  
			file delete $tmp_dir/vpacman.sh
			file delete $tmp_dir/errors
			return 1
		}
		# we do not need a password for this, but nor do we want to run it if the password authentification failed
		set cups_gen_return [catch {exec which cups-genppdupdate}]
		if {$cups_gen_return != 1} {
			puts $debug_out(2) "update_cups - run cups-genppdupdate"
			set error [catch {eval [concat exec cups-genppdupdate]} result]
			set message "${result}. "
			puts $debug_out(2) "update_cups - message set to $message"
		} 
		# now check for recorded errors
		set fid [open $tmp_dir/errors r]
		set result [read $fid]
		close $fid
		puts $debug_out(2) "update_cups - completed with the following result:\n\t$result"
	} else {
		# OK, we can do this without a password
		set cups_gen_return [catch {exec which cups-genppdupdate}]
		if {$cups_gen_return != 1} {
			puts $debug_out(2) "update_cups - run cups-genppdupdate"
			set error [catch {eval [concat exec cups-genppdupdate]} result]
			set message "${result}. "
			puts $debug_out(2) "update_cups - message set to $message"
		}
		puts $debug_out(2) "update_cups - reloading daemons"
		catch {exec $su_cmd systemctl daemon-reload}
		puts $debug_out(2) "update_cups - restart cups"
		set error [catch {eval [concat exec $su_cmd systemctl restart cups.service]} error_message]
		if {$error != 0} {
			puts $debug_out(1) "update_cups - error while restarting cups: $error_message"
			tk_messageBox -default ok -detail "$error_message" -icon error -message "Error while restarting cups" -parent . -title "Update Cups" -type ok  
			file delete $tmp_dir/vpacman.sh
			file delete $tmp_dir/errors
			return 1
		}
	}
	file delete $tmp_dir/vpacman.sh
	file delete $tmp_dir/errors
	tk_messageBox -default ok -detail $message -icon info -message "Restarted cups" -parent . -title "Update Cups" -type ok
	puts $debug_out(1) "update_cups completed"	

	return 0
}

proc update_db {} {

global dbpath debug_out start_time tmp_dir
# make sure that we are using an up to date copy of the sync databases

	puts $debug_out(1) "update_db called ([expr [clock milliseconds] - $start_time])"
    # make the directory if it does not exist already
    file mkdir "$tmp_dir/sync"
	set sync_dbs [glob -nocomplain "$dbpath/sync/*.db"]
	foreach item $sync_dbs {
		file copy -force $item $tmp_dir/sync
	}
	puts $debug_out(1) "update_db completed ([expr [clock milliseconds] - $start_time])"
}

proc view_text {text title} {

global browser debug_out save_geometry geometry_view
# open a window and display some text in it
	
	puts $debug_out(1) "view_text called"

	catch {destroy .view}
	
	toplevel .view
	
	wm iconphoto .view  view
	wm geometry .view $geometry_view
	wm protocol .view WM_DELETE_WINDOW {
		.view.close_button invoke
	}
	wm title .view $title
	wm transient .view .
	
		text .view.listbox \
			-background white \
			-tabs "[expr {4 * [font measure TkTextFont 0]}] left" \
			-tabstyle wordprocessor \
			-wrap word \
			-yscrollcommand ".view.listbox_scroll set"
	
		scrollbar .view.listbox_scroll \
			-command ".view.listbox yview"
			
		# now extend the bindings for the scrollbar	
		bind .view.listbox_scroll <ButtonRelease-3> {
			set scroll_element [.view.listbox_scroll identify %x %y]
			if {$scroll_element == "arrow1"} {
				.view.listbox yview moveto 0
			} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
				.view.listbox  yview moveto [.view.listbox_scroll fraction %x %y]
			} elseif {$scroll_element == "arrow2"} {
				.view.listbox  yview moveto 1
			}
		}
		
		balloon_set .view.listbox_scroll "Use right click to jump"
		
		button .view.close_button \
			-command {
				puts $debug_out(1) "view_text closed"
				if {[string tolower $save_geometry] == "yes"} {set geometry_view [wm geometry .view]; put_configs}
				grab release .view
				destroy .view
			} \
			-relief raised \
			-text "Close" \
			-width 7
			
			
		# Geometry management
	
		grid .view.listbox -in .view -row 1 -column 1  \
			-sticky nesw
		grid .view.listbox_scroll -in .view -row 1 -column 2  \
			-sticky ns
		grid .view.close_button -in .view -row 2 -column 1 \
			-columnspan 2 
	
	# Resize behavior management
	
		grid rowconfigure .view 1 -weight 1 -minsize 0 -pad 0
		grid rowconfigure .view 2 -weight 0 -minsize 20 -pad 0
		grid columnconfigure .view 1 -weight 1 -minsize 0 -pad 0
		grid columnconfigure .view 2 -weight 0 -minsize 20 -pad 0
	
	# use the dataview_popup menu for the .view window	
	
	# and set up a binding for it
		bind .view.listbox <ButtonRelease-3> {
			puts $debug_out(2) "view_text button 3 pressed"
			if {[.view.listbox tag ranges sel] != ""} {
				tk_popup .dataview_popup %X %Y 0
			}
		}
	
		
	# Set up some tags for the text field '.view.listbox'
	# make the URL blue, do not show any selection
		.view.listbox tag configure url_tag -foreground blue -selectforeground blue
	# set the cursor to a left pointer when hovering over the text
		.view.listbox tag bind url_cursor_in <Enter> ".view.listbox configure -cursor left_ptr"
	# set the cursor to the default when leaving the text
		.view.listbox tag bind url_cursor_out <Leave> ".view.listbox configure -cursor [.view.listbox cget -cursor]"
	# set the text background colour
		.view.listbox tag configure background_tag -background "#F6FAA0" -font "TkFixedFont" -selectbackground #c3c3c3
	# set the text to bold
		.view.listbox tag configure bold_tag -font "TkHeadingFont" -selectbackground #c3c3c3
	# set the text to centred
		.view.listbox tag configure centred_tag -justify center -selectbackground #c3c3c3	
	# set the text to fixed width
		.view.listbox tag configure fixed_tag -font "TkFixedFont" -selectbackground #c3c3c3
	# set the one indent value
		.view.listbox tag configure indent1_tag -lmargin2 "[expr {4 * [font measure TkTextFont 0]}]" 
	# set the two indent value
		.view.listbox tag configure indent2_tag -lmargin2 "[expr {8 * [font measure TkTextFont 0]}]" 
	# set the three indent value
		.view.listbox tag configure indent3_tag -lmargin2 "[expr {12 * [font measure TkTextFont 0]}]" 
		
	.view.listbox insert 0.0 $text
	# replace any code strings with their tags
	puts $debug_out(2) "view_text - call view_text_codes for text with centre"
	view_text_codes $text "<centre>" "</centre>" centred_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with pre"
	view_text_codes $text "<pre>" "</pre>" fixed_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with strong"
	view_text_codes $text "<strong>" "</strong>" bold_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with lm1"
	view_text_codes $text "<lm1>" "</lm1>" indent1_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with lm2"
	view_text_codes $text "<lm2>" "</lm2>" indent2_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with lm3"
	view_text_codes $text "<lm3>" "</lm3>" indent3_tag
	puts $debug_out(2) "view_text - call view_text_codes for text with code"
	view_text_codes $text "<code>" "</code>" background_tag

	# find any http? links and tag them if there is a browser available
	
	if {$browser != ""} {
		set count 0
		set from 0
		set start 0
		set start_index 0.0
		while {true} {
			set from [string first "\"http" $text $start]
			if {$from == -1} {break}
			# next while start the string search from the end of the last string found
			set start $from+1
			# find the end of the text string (carefully enclosed in quotes)
			set text_url [string range $text $from [string first "\"" $text $start]]
			# find the start index of that particular text string
			set index [.view.listbox search -forward $text_url $start_index]
			# and the end index of that string, but also the position from which to start the next seach
			set start_index $index+[string length $text_url]chars
			# set up a bind tag for the text found
			#.view.listbox tag bind get_url($count) <ButtonRelease-1> "exec $browser $text_url &"
			.view.listbox tag bind get_url($count) <ButtonRelease-1> "view_text_url $text_url"
			
			puts $debug_out(2) "view_text - found http at $index : $text_url : get_url($count) set to exec $browser $text_url &"
			# now replace the text with the text plus all of its tags
			puts $debug_out(2) "view_text - replace text $text_url at $index to $start_index with the text plus tags"
			.view.listbox tag add url_tag $index $start_index 
			.view.listbox tag add get_url($count) $index $start_index
			.view.listbox tag add url_cursor_in $index $start_index
			.view.listbox tag add url_cursor_out $index $start_index
			incr count
			
		}
	}
	
	.view.listbox configure -state disabled
	puts $debug_out(1) "view_text completed"
	
	update
	grab set .view
}
	
proc view_text_codes {text start_code end_code tag} {
	
global debug_out
# read through some text and replace a set of codes with a given tag
	
	puts $debug_out(1) "view_text_codes called"
	
	set start_count [string length $start_code]
	set end_count [string length $end_code]
	
	puts $debug_out(2) "view_text_codes called with text $start_code $end_code $start_count $end_count $tag"
	
	set count 0
	set from 0
	set start 0
	set start_index 0.0
	set end_index 0.0
	set to 0
	
	# read through the text and replace any start/end codes with the tag
	while {true} {
		# set from to the start of the code string
		puts $debug_out(3) "view_text_codes - search for ${start_code} in text with result [string first $start_code $text $start]"
		set from [string first ${start_code} $text $start]
		# no code string? exit the while loop
		if {$from == -1} {break}
		# find the end of the text string
		puts $debug_out(3) "view_text_codes - search for ${end_code} in text with result [string first $end_code $text $start]"
		set to [expr [string first ${end_code} $text $start] + $start_count]
		# start the next string search from the end of the last string found
		set start $to+1
		# and store the string
		set text_code [string range $text $from $to]
		puts $debug_out(3) "view_text_codes - found start code at $from to $to: $text_code"
		set text_string [string range $text_code $start_count end-$end_count]
		puts $debug_out(3) "view_text_codes - found text $text_string"
		# locate the same string in the view.listbox
		# find the start index of that particular text string, the first character of the code string
		set start_index [.view.listbox search -forward $text_code $start_index]
		# and the end index of that string, the last character of the end code string
		set end_index $start_index+[string length $text_code]indices
		# now remove the code tags and the string
		.view.listbox delete $start_index $end_index 
		# and replace it with the tags and the text string
		.view.listbox insert $start_index $text_string $tag
		# and set the next start index position
		set start_index $end_index
	}
	puts $debug_out(1) "view_text_codes completed"
}

proc view_text_url {url} {
	
global browser debug_out
# check for a selection before opening a URL in the browser

	puts $debug_out(1) "view_text_url - called for $url"
	
	if {[.view.listbox tag ranges sel] != ""} {
		puts $debug_out(1) "view_text_url - there is a selection, do nothing"
		return 1
	} else {
		puts $debug_out(1) "view_text_url - there is no selection, open $url"
		exec $browser $url &
	}
}

# MAIN 

puts $debug_out(1) "Main reached - ([expr [clock milliseconds] - $start_time])"

# set configurable variables to sane values
configurable
puts $debug_out(1) "Pre configuration file: browser set to \"$browser\", editor set to \"$editor\", terminal set to \"$terminal\" ([expr [clock milliseconds] - $start_time])"
# get the configuration previously saved
get_configs
# set up the images
set_images
# set the window manager default exit protocol
set_wmdel_protocol exit
# remove any errors saved from previous runs
file delete "$tmp_dir/errors"
# make sure that the required link exists for the local database
file delete -force $tmp_dir/local
set dbpath [find_pacman_config dbpath]
puts $debug_out(1) "Database directory is $dbpath"
puts $debug_out(1) "Link local directory in $tmp_dir/local"
file link $tmp_dir/local $dbpath/local
# check last modified times for each pacman database 
# and get a list of repos at the same time
# check that the temporary sync database exists
set times [get_sync_time]
set sync_time [lindex $times 0]
set update_time [lindex $times 1]
puts $debug_out(1) "Post configuration file: browser set to \"$browser\", editor set to \"$editor\", terminal set to \"$terminal\" ([expr [clock milliseconds] - $start_time])"

# WINDOW

# Set up screen

puts $debug_out(1) "Start Window set up - ([expr [clock milliseconds] - $start_time])"
wm title . "Vpacman"
wm iconphoto . -default pacman
wm geometry . $geometry

# set up main window

menu .menubar \
	-relief flat
	. configure -menu .menubar
	menu .menubar.file -tearoff 0
		.menubar add cascade -menu .menubar.file -label File -underline 0
		.menubar.file add command \
			-command {
				if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]}
				puts $debug_out(1) "wm exit - save current configuration data"
				put_configs
				# delete the aur_upgrades directory and all of its contents
				# any aur packages with incomplete downloads or upgrades will have to be restarted
				puts $debug_out(1) "wm exit - delete $tmp_dir/aur_upgrades and its contents"
				file delete -force "$tmp_dir/aur_upgrades"
				exit \
			} \
			-label Quit \
			-underline 0
	menu .menubar.edit -tearoff 0
		.menubar add cascade -menu .menubar.edit -label Edit -underline 0
			.menubar.edit add command -command {all_select} -label "Select All" -state normal -underline 0
			.menubar.edit add command -command {all_clear} -label "Clear All" -state disabled -underline 0
	menu .menubar.tools -tearoff 0
		.menubar add cascade -menu .menubar.tools -label Tools -underline 0
			.menubar.tools add command -command {system_upgrade} -label "Full System Upgrade" -state normal -underline 0
			.menubar.tools add command -command {
				if {$aur_only} {
					puts $debug_out(1) ".menubar.tools  call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
					aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] "upgrade"
				} else {
					execute install
				}
			} -label Install -state disabled -underline 0
			.menubar.tools add command -command {execute delete} -label Delete -state disabled	-underline 0
			.menubar.tools add command -command {execute sync} -label Sync -state normal -underline 0
			.menubar.tools add separator
			.menubar.tools add command -command {check_config_files} -label "Check Config Files" -state normal -underline 6
			.menubar.tools add command -command {clean_cache} -label "Clean Package Cache" -state normal -underline 6
			.menubar.tools add command -command {trim_log} -label "Clean Pacman Log" -state normal -underline 13
			.menubar.tools add command -command {aur_install} -label "Install AUR/Local" -state normal -underline 8
			.menubar.tools add command -command {make_backup_lists} -label "Make Backup Lists" -state normal -underline 5
			.menubar.tools add command -command {update_cups} -label "Update Cups" -state normal -underline 0
			.menubar.tools add command -command {mirrorlist_update} -label "Update Mirrorlist" -state normal -underline 7
			.menubar.tools add separator
			.menubar.tools add command -command {configure} -label Options -state normal -underline 0
	menu .menubar.view -tearoff 0
		.menubar add cascade -menu .menubar.view -label View -underline 0
		.menubar.view add command -command {read_news} -label "Latest News" -state normal -underline 7
		.menubar.view add command -command {read_config} -label "Pacman Configuration" -state normal -underline 7
		.menubar.view add command -command {read_log} -label "Pacman Log" -state normal -underline 7
		.menubar.view add command -command {read_dependencies report} -label "Dependency Updates" -state normal -underline 1
		.menubar.view add separator
		.menubar.view add command -command {
			. configure -menu ""
			# this command will add two entries to the end of the popup menu
			# when the menu entry is selected
			.listview_popup add separator
			.listview_popup add command -label "Show Menubar" -command {
				. configure -menu .menubar
				set show_menu "yes"
				# when the command is executed, remove the last two lines, whatever they may be
				.listview_popup delete end	
				.listview_popup delete end
			} -state normal
			set show_menu "no"
		} -label "Hide Menubar" -state normal -underline 5
		.menubar.view add command -command {grid remove .buttonbar; toggle_buttonbar; set show_buttonbar "no"} -label "Hide Toolbar" -state normal -underline 5
	menu .menubar.help -tearoff 0
		.menubar add cascade -menu .menubar.help -label Help -underline 0
			.menubar.help add command -command {view_text $help_text "Help"} -label "Help" -state normal -underline 0
			.menubar.help add command -command {view_text $about_text "About"} -label "About" -state normal -underline 0

frame .buttonbar 

	button .buttonbar.upgrade_button \
		-command {system_upgrade} \
		-image upgrade \
		-relief flat

	button .buttonbar.reload_button \
		-command {execute sync} \
		-image reload \
		-relief flat

	button .buttonbar.install_button \
		-command {
			if {$aur_only} {
				puts $debug_out(1) ".buttonbar.install_button call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
				aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] "upgrade"
			} else {
				execute install
			}
		}\
		-image install \
		-relief flat \
		-state disabled

	button .buttonbar.delete_button \
		-command {execute delete} \
		-image delete \
		-relief flat \
		-state disabled	

	label .buttonbar.label_message \
		-anchor center \
		-takefocus 0 \
		-textvariable message

	label .buttonbar.label_find \
		-anchor e \
		-foreground Blue \
		-highlightthickness 1 \
		-takefocus 1 \
		-text "Find " \
		-width 10

	bind .buttonbar.label_find <Enter> {
		.buttonbar.label_find configure -background [.buttonbar.upgrade_button cget -activebackground]
	}
	bind .buttonbar.label_find <Leave> {
		.buttonbar.label_find configure -background [.buttonbar.upgrade_button cget -background]
	}

# bindings to change the type of find command displayed
	
	bind .buttonbar.label_find <Key-space> {event generate .buttonbar.label_find <ButtonPress-1>}
	bind .buttonbar.label_find <ButtonPress-1> {
		if {$findtype == "find"} {
			puts $debug_out(1) "Find label clicked - Find is \"$find\""
			# moving from find to findname
			set findtype "findname"
			puts $debug_out(2) "ButtonRelease on .buttonbar.label_find turned find validate on"
			.buttonbar.entry_find configure -validate key
			# keep the entry in the find field
			# if find is not blank then we have to rerun filter to get the "find" packages by name only
			if {$find != ""} {filter}
			puts $debug_out(2) "Find type is $findtype (Find is $find)"
			.buttonbar.label_find configure -text "Find Name "
			puts $debug_out(2) "Find text set to Find Name"
			balloon_set .buttonbar.entry_find "Find a package name in the list displayed"
		} elseif {$findtype == "findname"} {
			puts $debug_out(1) "Find Name label clicked - Find is \"$find\""
			set findtype "findfile"
			# moving from findname to findfile
			puts $debug_out(2) "ButtonRelease on .buttonbar.label_find turned find validate on"
			.buttonbar.entry_find configure -validate key
			# keep the entry from the find field
			set findfile $find
			# do not rerun filter until return is pressed
			puts $debug_out(2) "Find type is $findtype"
			.buttonbar.label_find configure -text "Find File "
			puts $debug_out(2) "Find text set to Find File"
			update
			.buttonbar.clear_find_button configure -command {
				puts $debug_out(1) ".buttonbar.clear_find_button removed findfile entry"
				set findfile ""
				set_message find ""
				filter
			}
			# and change the entry widget from entry_find to entry_findfile
			balloon_set .buttonbar.entry_findfile "Find the package which owns a file" 
			grid remove .buttonbar.entry_find
			grid .buttonbar.entry_findfile -in .buttonbar -row 1 -column 9 \
				-sticky we
		} elseif {$findtype == "findfile"} {
			puts $debug_out(1) "Find File label clicked"
			# moving from findfile to find
			set findtype "find"
			puts $debug_out(2) "Find type is $findtype"
			.buttonbar.label_find configure -text "Find "
			# clear the find variable
			set find ""
			set_message find ""
			update
			# reset the treeview
			filter
			# and reset the message
			set_message reset ""
			# now update all the widgets and help
			.buttonbar.clear_find_button configure -command {
				puts $debug_out(2) ".buttonbar.clear_find_button removed find entry"
				.buttonbar.entry_find delete 0 end
				# .buttonbar.entry_find -validatecommand will update everything
			}
			# and change the entry widget from entry_findfile to entry_find
			balloon_set .buttonbar.entry_find "Find some data in the list displayed\n(excluding the Repository name)"
			grid remove .buttonbar.entry_findfile
			grid .buttonbar.entry_find -in .buttonbar -row 1 -column 9 \
				-sticky we
		}
	}

# Alternate labels and entries to find some data in any field in the current list

	entry .buttonbar.entry_find \
		-foreground Blue \
		-takefocus 1 \
		-textvariable find \
		-validate key \
		-validatecommand {
			# Backspace plus repeat key crashes the programme if the string is 2 characters or more
			# so we need to update idletasks
			update idletasks
			puts $debug_out(1) ".buttonbar.entry_find - find string is %P"
			after 500 {
				if {[string length %P] == 0} {
					set_message find ""
					# sort and show the list
					set filter_list [sort_list $filter_list]
					list_show $filter_list
				} elseif {[string length %P] > 2} {
					if {$findtype == "findname"} {
						find %P $filter_list name
					} else {
						find %P $filter_list all
					}
				}
			}
			# any error in the find script will turn off the validate command
			# so we try to reinstate it here
			after idle {.buttonbar.entry_find configure -validate key}
			return 1
		} \
		-width 25
		
	# Do not allow Shift Left and Shift Right to create a selection
	# if there are any problems reported then we may have to change the bindings for other keys
	# Shift-Home, Shift-End, Shift-Button-1
	bind .buttonbar.entry_find <Shift-Left> {
		.buttonbar.entry_find icursor [expr [.buttonbar.entry_find index insert] - 1]
		break
	}

	bind .buttonbar.entry_find <Shift-Right> {
		.buttonbar.entry_find icursor [expr [.buttonbar.entry_find index insert] + 1]
		break
	}
	
	# set up a popup menu for find
	option add *tearOff 0
	set entry_find_popup [menu .buttonbar.entry_find_popup -cursor left_ptr]
	$entry_find_popup add command -label "Copy" -command {
		clipboard append [selection get]
		selection clear -displayof .buttonbar.entry_find
	} 
	$entry_find_popup add command -label "Paste" -command {
		catch {.buttonbar.entry_find delete sel.first sel.last}
		update idletasks
		.buttonbar.entry_find insert insert [clipboard get]
	}
	
	# and set up the binding for it
	bind .buttonbar.entry_find <ButtonRelease-3> {
		if {![.buttonbar.entry_find selection present]} {
			$entry_find_popup entryconfigure 0 -state disabled
		} else {
			$entry_find_popup entryconfigure 0 -state normal
		}
		tk_popup $entry_find_popup %X %Y 0
	}

	# remove any selection before pasting from the clipboard with Shift-Insert
	bind .buttonbar.entry_find <Shift-Insert> {
		catch {.buttonbar.entry_find delete sel.first sel.last}
		update idletasks
		.buttonbar.entry_find insert insert [clipboard get]
		break
	}

	# run the find if return has been pressed, to find strings of less than 3 characters and reset the validate key
	bind .buttonbar.entry_find <Return> {
		puts $debug_out(1) "Return Key ran find $find"
		if {[string length $find] > 0} {
			if {$findtype == "findname"} {
				find $find $filter_list name
			} else {
				find $find $filter_list all
			}
		}
		puts $debug_out(1) "Return Key turned find validate on"
		.buttonbar.entry_find configure -validate key
	}

	# sometimes clicking buttons in the find data area stops the validate key working, so the last thing 
	# to do after a button is released is to reset it
	bind .buttonbar.entry_find <ButtonRelease> {+
		.buttonbar.entry_find configure -validate key
	}

# Alternate labels and entries to find a file instead of finding data in the current list
	entry .buttonbar.entry_findfile \
		-foreground Blue \
		-takefocus 1 \
		-textvariable findfile \
		-width 25

	label .pkgfile_upgrade \
		-textvariable pkgfile_upgrade 
	
	label .pacman_files_upgrade \
		-textvariable pacman_files_upgrade
	# Do not allow Shift Left and Shift Right to create a selection
	# if there are any problems reported then we may have to change the bindings for other keys
	# Shift-Home, Shift-End, Shift-Button-1
	bind .buttonbar.entry_findfile <Shift-Left> {
		.buttonbar.entry_findfile icursor [expr [.buttonbar.entry_findfile index insert] - 1]
		break
	}

	bind .buttonbar.entry_findfile <Shift-Right> {
		.buttonbar.entry_findfile icursor [expr [.buttonbar.entry_findfile index insert] + 1]
		break
	}
	
	# set up a popup menu for findfile
	option add *tearOff 0
	set entry_findfile_popup [menu .buttonbar.entry_findfile_popup -cursor left_ptr]
	$entry_findfile_popup add command -label "Copy" -command {
		clipboard append [selection get]
		selection clear -displayof .buttonbar.entry_findfile
	} 
	$entry_findfile_popup add command -label "Paste" -command {
		catch {.buttonbar.entry_findfile delete sel.first sel.last}
		update idletasks
		.buttonbar.entry_findfile insert insert [clipboard get]
	}
	
	# and set up the binding for it
	bind .buttonbar.entry_findfile <ButtonRelease-3> {
		if {![.buttonbar.entry_findfile selection present]} {
			$entry_findfile_popup entryconfigure 0 -state disabled
		} else {
			$entry_findfile_popup entryconfigure 0 -state normal
		}
		tk_popup $entry_findfile_popup %X %Y 0
	}
	
	# remove any selection before pasting from the clipboard with Shift-Insert
	bind .buttonbar.entry_findfile <Shift-Insert> {
		catch {.buttonbar.entry_findfile delete sel.first sel.last}
		update idletasks
		.buttonbar.entry_findfile insert insert [clipboard get]
		break
	}
	
	bind .buttonbar.entry_findfile <Return> {
		puts $debug_out(1) "Return key ran findfile \"$findfile\""
		if {$findfile != ""} {
			# reset the filter and group to all
			set error 0
			set filter "all"
			set group "All"
			# and reconfigure the group list
			.listgroups itemconfigure $group_index -background white
			set group_index 0
			cleanup_checkbuttons false
			# clear the dataview pane
			get_dataview ""
			
			puts $debug_out(2) "Return key - set up command to find \"$findfile\""
			# set up a command to find the requested file in the database
			set command ""
			
			# use pkgfile if it is installed
			if {[catch {exec which pkgfile}] == 0} {
				puts $debug_out(2) "findfile - try pkgfile"
				# check for complete files databases
				# if we have not been told to avoid updates
				set pkgfile_upgrade [.pkgfile_upgrade cget -text]
				if {![expr $pkgfile_upgrade & 2]} {
					set error [check_repo_files /var/cache/pkgfile files]
					puts $debug_out(2) "findfile - check_repo_files (pkgfile) returned $error"
					# 0 = success, 1 = error, 2 = upgraded, 3 = cancelled
					if {$error == 3} {return 1}
				}
				# do not check whether the databases are in date if they have just been upgraded
				if {$error != 2} {
					puts $debug_out(2) "findfile - check whether the (pkgfile) databases are up to date"
					# check for whether the files databases are up to date
					# if the check was already refused then do not check again
					if {![expr $pkgfile_upgrade & 1]} {
						set error [test_files_data pkgfile]
						puts $debug_out(2) "findfile - test_files_data (pkgfile) returned $error"
					}
					# check the error from test_files_data
					# try anyway if we chose not to update the files databases
					# 0 success, 1 failed, 2 updated, 3 cancelled
					if {$error == 3} {return 1}
				}
				# continue with the existing databases	
				set command "pkgfile $findfile"
				puts $debug_out(2) "findfiles - command set to \"pkgfile $findfile\""
			}
			puts $debug_out(2) "Return key - tried pkgfile, command set to \"$command\""
			if {$command == ""} {
				puts $debug_out(2) "findfile - cannot use pkgfile, try pacman files"
				# pkgfile is not installed or no pkgfile databases are available, so try pacman	files
				# check for complete files databases
				# if we have not been told to avoid updates
				puts $debug_out(2) "findfile - pacman_files_upgrade set to $pacman_files_upgrade"
				set pacman_files_upgrade [.pacman_files_upgrade cget -text]

				if {![expr $pacman_files_upgrade & 2]} {
					set error [check_repo_files $tmp_dir files]
					puts $debug_out(2) "findfile - check_repo_files (pacman) returned $error"
					# 0 = success, 1 = error, 2 = upgraded, 3 = cancelled
					if {$error == 3} {return 1}
				}
				# do not check whether the databases are in date if they have just been upgraded
				if {$error != 2} {
					# check for whether the files database are up to date
					# if the check was already refused then do not check again
					if {![expr $pacman_files_upgrade & 1]} {
						set error [test_files_data pacman]
						puts $debug_out(2) "findfile - test_files_data (pacman) returned $error"
					}
					# check the error from test_files_data
					# 0 success, 1 failed, 2 updated, 3 cancelled
					if {$error == 3} {return 1}
				}
				# continue with the existing databases
				set command "pacman -b $tmp_dir -Fq $findfile"
			}
			# OK, so we know the command to execute, so do it
			puts $debug_out(2) "findfile - find command set to \"$command\""
			set_message terminal "Searching for packages containing $findfile ...."
			update
			set list ""
			set pkglist ""
			set warning_list ""
			if {$command != ""} {
				set error [catch {eval [concat exec $command]} list]
				puts $debug_out(2) ".buttonbar.entry_findfile - command ran with error $error and list\n$list"
			}
			# and also search the local files list
			set index [lsearch -all -glob $aur_files "*$findfile *"]
			if {$index != ""} {
				puts $debug_out(2) ".buttonbar.entry_findfile - the local files contain \"$findfile\" at $index"
				foreach item $index {
					set element [lindex [split [lindex $aur_files $item] " "] 0]
					puts $debug_out(3) ".buttonbar.entry_findfile - found $element at index $item"
					append list "\n" "local/$element"
					puts $debug_out(3) ".buttonbar.entry_findfile - list is now\n$list"
				}
				# pkgfile returns 0 whether or not any files are found
				# pacman returns 1 if no files are found
				set list [concat $list [lindex [split [lindex $aur_files $index] " "] 0]]
				if {$error == 1} {
					# since there is a local find file result reset error to 0
					set error 0
				}
			} else {
				puts $debug_out(2) ".buttonbar.entry_findfile - no local files contain \"$findfile\""
			}
			set_message terminal ""
			puts $debug_out(3) ".buttonbar.entry_findfile - list is now\n$list"
			if {$list != ""} {
				set list [split $list "\n"]
				puts $debug_out(2) ".buttonbar.entry_findfile - findfile list is $list"
				foreach item $list {
					if {[string first "warning:" $item] == 0} {
						puts $debug_out(2) ".buttonbar.entry_findfile - there are warnings in the list"
						lappend warning_list "W[string range $item 1 [string first {(} $item]-1]"
						continue
					}
					if {[string first "error:" $item] == 0} {continue}
					puts $debug_out(2) ".buttonbar.entry_findfile - Item is $item"
					puts $debug_out(2) ".buttonbar.entry_findfile - [string last "/" $item]"
					set item [string range $item [string last "/" $item]+1 end]
					puts $debug_out(2) ".buttonbar.entry_findfile - Item is now $item"
					foreach element $list_all {
					# search for the string in package names in the chosen list
						if {$item == [lrange $element 1 1]} {
							lappend pkglist $element
						}
					}
				}
				list_show $pkglist
			}
			if {[llength $pkglist] == 0} {
				# now delete the contents from  listview
				.wp.wfone.listview delete [.wp.wfone.listview children {}]
				set_message terminal "No packages found containing \"$findfile\""
			} elseif {[llength $pkglist] > 1} {
				set_message terminal "[llength $pkglist] packages provide \"$findfile\""
			} else {
				set_message terminal "[llength $pkglist] package provides \"$findfile\""
			}
			if {[llength $warning_list]  != 0} {
				.wp.wftwo.dataview select .wp.wftwo.dataview.info
				update
				.wp.wftwo.dataview.info insert end "\n"
				foreach element $warning_list {	
					.wp.wftwo.dataview.info insert end "${element}\n"
				}
				.wp.wftwo.dataview.info insert end "Click on the folder icon to update the files data.\n"			
			}
			if {$command == ""} {
				.wp.wftwo.dataview select .wp.wftwo.dataview.info
				update
				.wp.wftwo.dataview.info insert end "\n"			
				.wp.wftwo.dataview.info insert end "Unable to search repositories for $findfile\n"
			}		
		}
		puts $debug_out(1) ".buttonbar.entry_findfile completed"
	}
	
	button .buttonbar.clear_find_button \
		-command {
			puts $debug_out(1) ".buttonbar.clear_find_button removed find entry"
			.buttonbar.entry_find delete 0 end
			# .buttonbar.entry_find -validatecommand will update everything
		} \
		-image clear \
		-relief flat

	button .buttonbar.configure_button \
		-command {configure} \
		-image tools \
		-relief flat

# set up display area

frame .filters

	label .filter_label \
		-text "Filters:" 
		
	checkbutton .filter_all \
		-command {
			update idletasks
			cleanup_checkbuttons false
			if {$filter == 0} {
				set filter "all"
			} else {
				filter
			}
		} \
		-onvalue "all" \
		-text "All" \
		-variable filter
		
	label .group_label \
		-text "  Group"
	
	entry .group_entry \
		-readonlybackground white \
		-relief sunken \
		-selectbackground white \
		-selectborderwidth 0 \
		-state readonly \
		-textvariable group 

	bind .group_entry <Key-space> {
		.group_button invoke 
		focus .listgroups
	}

		
	button .group_button \
		-command {
			update idletasks
			set selected_list 0
			grid .listgroups
			grid .scroll_selectgroup
		} \
		-image down_arrow
		
	bind .group_button <Key-space> {focus .listgroups}
				
	checkbutton .filter_installed \
		-command {
			update idletasks
			cleanup_checkbuttons false
			if {$filter == 0} {
				set filter "installed"
			} else {
				filter
			}
		} \
		-onvalue "installed" \
		-text "Installed" \
		-variable filter
		
	checkbutton .filter_not_installed \
		-command {
			update idletasks
			cleanup_checkbuttons false
			if {$filter == 0} {
				set filter "not_installed"
			} else {
				filter
			}
		} \
		-onvalue "not_installed" \
		-text "Not Installed" \
		-variable filter
		
	checkbutton .filter_updates \
		-command {
			update idletasks
			cleanup_checkbuttons false
			.menubar.tools entryconfigure 6 -state normal
			if {$filter == 0} {
				set filter "outdated"
			} else {
				filter
			}
		} \
		-onvalue "outdated" \
		-text "Updates Available" \
		-variable filter

	label .filter_list_label \
		-text "List:" 
		
	checkbutton .filter_list_orphans \
		-command {
			update idletasks
			set aur_only false
			set filter "orphans"
			filter_checkbutton ".filter_list_orphans" "pacman -b $tmp_dir -Qdtq" "Orphans"
		} \
		-onvalue "orphans" \
		-text "Orphans" \
		-variable selected_list
		
	checkbutton .filter_list_not_required \
		-command {
			update idletasks
			set aur_only false
			set filter "not_required"
			filter_checkbutton ".filter_list_not_required" "pacman -b $tmp_dir -Qtq" "Not Required"
		} \
		-onvalue "not_required" \
		-text "Not Required" \
		-variable selected_list
		
	checkbutton .filter_list_aur_updates \
		-command {
			puts $debug_out(3) ".filter_list_aur_updates - called with thread \"$thread\""
			# do not execute until the thread has completed
			if {$thread != ""} {
				puts $debug_out(3) ".filter_list_aur_updates - aur_versions thread is $thread"
				tkwait variable thread
			}
			update idletasks
			if {$selected_list == 0} {
				set filter "all"
				cleanup_checkbuttons false
				puts $debug_out(3) ".filter_list_aur_updates - call filter"
				filter
			} else {
				puts $debug_out(3) ".filter_list_aur_updates - call get_aur_updates"
				get_aur_updates
			}			
		} \
		-onvalue "aur_updates" \
		-variable selected_list
	if {$aur_all == true} {
		.filter_list_aur_updates configure -text "AUR/Local Packages"
	} else {
		.filter_list_aur_updates configure -text "AUR/Local Updates"
	}		
		
	checkbutton .filter_list_aur_updates_all \
		-command {
			update idletasks
			puts $debug_out(1) ".filter_list_aur_updates_all - aur_all set to $aur_all"
			if {$aur_all} {
				puts $debug_out(2) ".filter_list_aur_updates_all - configured text \"AUR/Local Packages ([llength $list_local])\""
				.filter_list_aur_updates configure -text "AUR/Local Packages ([llength $list_local])"
				balloon_set .filter_list_aur_updates "List all AUR/Local packages which have been installed"
			} else {
				puts $debug_out(2) ".filter_list_aur_updates_all - configured text to local_newer \"AUR/Local Updates ($local_newer)\""
				.filter_list_aur_updates configure -text "AUR/Local Updates ($local_newer)"
				balloon_set .filter_list_aur_updates "List only local packages which may need to be updated"
			}
			if {$selected_list == "aur_updates"} {
				puts $debug_out(3) ".filter_list_aur_updates_all - call get_aur_updates"
				get_aur_updates
			}
		} \
		-offvalue false \
		-onvalue true \
		-text "include all local packages" \
		-variable aur_all
	bind .filter_list_aur_updates_all <Tab> {
		focus .wp.wfone.listview
		.wp.wfone configure -highlightcolor black
		.wp.wfone.listview tag add focussed $tv_index
	}
	
	frame .filter_icons \
		-takefocus 0
		
		label .filter_icons_warning \
			-image warning \
			-takefocus 0
		
		bind .filter_icons_warning <ButtonRelease-1> {
			system_upgrade
		}
		
		label .filter_icons_disconnected \
			-image disconnected \
			-takefocus 0
		
		bind .filter_icons_disconnected <ButtonRelease-1> {
			# set is_connected true so that we get the full tk_messageBox
			set is_connected true
			test_internet
		}
				
		label .filter_icons_filesync \
			-image filesync \
			-takefocus 0
			
		bind .filter_icons_filesync <ButtonRelease-1> {
			if {[catch {exec which pkgfile}] == 0} {
				# do the database files exist
				set error [check_repo_files /var/cache/pkgfile files]
				# are they up to date
				if {$error == 3} {
					set pkgfile_updates 0
				} elseif {$error == 0} {
					set error [test_files_data pkgfile]
					set pkgfile_updates 0
				}
			} else {
				# do the database files exist
				set error [check_repo_files $tmp_dir files]
				# are they up to date
				if {$error == 3} {
					set pacman_files_upgrade 0
				} elseif {$error == 0} {
					set error [test_files_data pacman]
					set pacman_files_upgrade 0
				}
			}
		}

	label .filter_clock_label \
		-takefocus 0 \
		-text "Time since last sync"
		
	label .filter_clock \
		-takefocus 0 \
		-text ""
		
	label .filter_upgrade_label \
		-takefocus 0 \
		-text "Last system upgrade"
		
	label .filter_upgrade \
		-takefocus 0 \
		-text ""
	
# define these widgets last in the filter set so that they cover the other items when they are shown	

	listbox .listgroups \
		-listvariable list_groups \
		-selectmode single \
		-takefocus 1 \
		-yscrollcommand ".scroll_selectgroup set"

	scrollbar .scroll_selectgroup \
		-command {.listgroups yview} \
		-takefocus 1

	bind .listgroups <Key-space> {+
		focus .group_entry
		grid_remove_listgroups
	}
	# reorder the Tab selections
	bind .listgroups <Tab> {
		focus .filter_installed
		grid_remove_listgroups
		break
	}
	bind .group_entry <<PrevWindow>> {
		grid_remove_listgroups
		update idletasks
		focus .filter_all
		break
	}
	bind .listgroups <<PrevWindow>> {
		grid_remove_listgroups
		update idletasks
		focus .filter_all
		break
	}

	# now extend the bindings for the scrollbar	
	bind .scroll_selectgroup <ButtonRelease-3> {
			set scroll_element [.scroll_selectgroup identify %x %y]
			if {$scroll_element == "arrow1"} {
				.listgroups yview moveto 0
			} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
				.listgroups yview moveto [.scroll_selectgroup fraction %x %y]
			} elseif {$scroll_element == "arrow2"} {
				.listgroups yview moveto 1
			}
		}
		
# set up a paned window called windowpane or wp to hold listview and dataview
panedwindow .wp -orient vertical

# set up a window frame for the treeview in the windowpane wp called windowframe one or wfone
frame .wp.wfone \
	-borderwidth 1 \
	-highlightthickness 1 \
	-takefocus 0

# Treeview

	ttk::treeview .wp.wfone.listview \
		-columns "Repo Package Version Available" \
		-displaycolumns "Package Version Available Repo" \
		-selectmode extended \
		-show headings \
		-takefocus 0 \
		-xscrollcommand ".wp.wfone.xlistview_scroll set" \
		-yscrollcommand ".wp.wfone.ylistview_scroll set"
	
		.wp.wfone.listview heading Package -text "Package" \
			-anchor center \
			-command {
				set list_show [sort_list_toggle {Package}]
				list_show $list_show
			}
		.wp.wfone.listview heading Package \
			-image down_arrow
		.wp.wfone.listview heading Version \
			-text "Version" \
			-anchor center \
			-command {
				set list_show [sort_list_toggle {Version}]
				list_show $list_show
			}
		.wp.wfone.listview heading Available \
			-text "Available" \
			-anchor center \
			-command {
				set list_show [sort_list_toggle {Available}]
				list_show $list_show
			}
		.wp.wfone.listview heading Repo \
			-text "Repo" \
			-anchor center \
			-command {
				set list_show [sort_list_toggle {Repo}]
				list_show $list_show
			}
		.wp.wfone.listview column Package \
			-minwidth 150 \
			-stretch 1
		.wp.wfone.listview column Version \
			-stretch 0 \
			-width 150
		.wp.wfone.listview column Available \
			-stretch 0 \
			-width 150
		.wp.wfone.listview column Repo \
			-stretch 0 \
			-width 150
		.wp.wfone.listview tag configure focussed -background #c6c6c6
		.wp.wfone.listview tag configure installed -foreground $installed_colour
		.wp.wfone.listview tag configure outdated -foreground $outdated_colour

		scrollbar .wp.wfone.xlistview_scroll \
			-command ".wp.wfone.listview xview" \
			-cursor {} \
			-orient horizontal \
			-takefocus 0
			
		# now extend the bindings for the scrollbar
		bind .wp.wfone.xlistview_scroll <ButtonRelease-3> {
			set scroll_element [.wp.wfone.xlistview_scroll identify %x %y]
			if {$scroll_element == "arrow1"} {
				.wp.wfone.listview xview moveto 0
			} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
				.wp.wfone.listview xview moveto [.wp.wfone.xlistview_scroll fraction %x %y]
			} elseif {$scroll_element == "arrow2"} {
				.wp.wfone.listview xview moveto 1
			}
		}

		scrollbar .wp.wfone.ylistview_scroll \
			-command ".wp.wfone.listview yview" \
			-cursor {} \
			-takefocus 0
		
		# now extend the bindings for the scrollbar	
		bind .wp.wfone.ylistview_scroll <ButtonRelease-3> {
			set scroll_element [.wp.wfone.ylistview_scroll identify %x %y]
			if {$scroll_element == "arrow1"} {
				.wp.wfone.listview yview moveto 0
			} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
				.wp.wfone.listview yview moveto [.wp.wfone.ylistview_scroll fraction %x %y]
			} elseif {$scroll_element == "arrow2"} {
				.wp.wfone.listview yview moveto 1
			}
		}
		
# change the bindings for the treeview because some of the shift button bindings give some odd results
# and to allow for keyboard traversal 

		bind .wp.wfone.listview <Tab> {focus .buttonbar.upgrade_button; break}
		bind .wp.wfone.listview <<PrevWindow>> {focus .filter_list_aur_updates_all}
		bind .wp.wfone.listview <Down> {
			# remove the tag from the current item
			.wp.wfone.listview tag remove focussed $tv_index
			# check that there is a next item
			if {[.wp.wfone.listview next $tv_index] != ""} {
				# if there is then check that the next item is not selected as well
				# and check that this is not the anchor
				# if all this is true deselect the item and select the next one
				if {[lsearch [.wp.wfone.listview selection] $tv_index] != -1 && [lsearch [.wp.wfone.listview selection] [.wp.wfone.listview next $tv_index]] != -1 && $tv_index != $anchor} {
					.wp.wfone.listview selection remove $tv_index
					set listlast $tv_index
				}
				set tv_index [.wp.wfone.listview next $tv_index]
			}
			.wp.wfone.listview tag add focussed $tv_index
			.wp.wfone.listview see $tv_index
			break
		}
		bind .wp.wfone.listview <Up> {
			# remove the tag from the current item
			.wp.wfone.listview tag remove focussed $tv_index
			# check that there is a previous item
			if {[.wp.wfone.listview prev $tv_index] != ""} {
				# if there is then check that the previous item is not selected as well
				# and check that this is not the anchor
				# if all this is true deselect the item and select the previous one
				if {[lsearch [.wp.wfone.listview selection] $tv_index] != -1 && [lsearch [.wp.wfone.listview selection] [.wp.wfone.listview prev $tv_index]] != -1 && $tv_index != $anchor} {
					.wp.wfone.listview selection remove $tv_index
					set listlast $tv_index
				}
				set tv_index [.wp.wfone.listview prev $tv_index]
 			} 
			.wp.wfone.listview tag add focussed $tv_index 
			.wp.wfone.listview see $tv_index
			break
		}
		bind .wp.wfone.listview <Key-space> {
			# toggle will set the selected/unselected state
			.wp.wfone.listview selection toggle $tv_index
		}
		bind .wp.wfone.listview <Shift-space> {
			set listlast $tv_index
			#set tv_index $listlast
			if {$anchor == ""} {set anchor $listlast}
			puts $debug_out(1) "Shift Space clicked on TreeView: Anchor is $anchor First was $listfirst Last is $listlast"
			if {$aur_only == true} {
				puts $debug_out(1) "\taur_only is true"
				set listfirst $listlast
				.wp.wfone.listview selection set $listfirst
				break
			}
			.wp.wfone.listview selection set $anchor
			set item $anchor
			while {$listlast < $item} {
				set item [.wp.wfone.listview prev $item]
				.wp.wfone.listview selection add $item
			}
			set item $anchor
			set count [expr abs (0x[string trim $listlast {I}] - 0x[string trim $item {I}] + 1)]
			# check if we are being over ambitious
			if {$count > 500} {
				puts $debug_out(1) "Shift Button in Treeview - there are $count selected"
				set ans [tk_messageBox -default cancel -detail "" -icon warning -message "\nReally select $count packages?" -parent . -title "Warning" -type okcancel]
				switch $ans {
					ok {set select true}
					cancel {
						set select false
						# now break out of the bind script and do nothing
						break
					}
				}
			}
			while {$listlast > $item} {
				set item [.wp.wfone.listview next $item]
				.wp.wfone.listview selection add $item
			}
			set listfirst $listlast
			break
		}
		bind .wp.wfone.listview <Shift-ButtonPress-1> {
			# remove any highlight border
			.wp.wfone configure -highlightcolor #d9d9d9

			set listlast [.wp.wfone.listview identify item %x %y]
			set tv_index $listlast
			if {$anchor == ""} {set anchor $listlast}
			puts $debug_out(1) "Shift Button clicked on TreeView: Anchor is $anchor First was $listfirst Last is $listlast"
			if {$aur_only == true} {
				puts $debug_out(1) "\taur_only is true"
				set listfirst $listlast
				.wp.wfone.listview selection set $listfirst
				break
			}
			.wp.wfone.listview selection set $anchor
			set item $anchor
			while {$listlast < $item} {
				set item [.wp.wfone.listview prev $item]
				.wp.wfone.listview selection add $item
			}
			set item $anchor
			set count [expr abs (0x[string trim $listlast {I}] - 0x[string trim $item {I}] + 1)]
			# check if we are being over ambitious
			if {$count > 500} {
				puts $debug_out(1) "Shift Button in Treeview - there are $count selected"
				set ans [tk_messageBox -default cancel -detail "" -icon warning -message "\nReally select $count packages?" -parent . -title "Warning" -type okcancel]
				switch $ans {
					ok {set select true}
					cancel {
						set select false
						# now break out of the bind script and do nothing
						break
					}
				}
			}
			while {$listlast > $item} {
				set item [.wp.wfone.listview next $item]
				.wp.wfone.listview selection add $item
			}
			set listfirst $listlast
			break
		}
		bind .wp.wfone.listview <Control-ButtonPress-1> {
			# remove any highlight border
			.wp.wfone configure -highlightcolor #d9d9d9
			# find which item was clicked on last
			set listlast [.wp.wfone.listview identify item %x %y]
			set tv_index $listlast
			# if this item was selected already, then de-select it
			if {[lsearch [.wp.wfone.listview selection] $listlast] != -1} {
				puts $debug_out(1) "Control Button clicked on TreeView - remove Last $listlast, Anchor is $anchor"
				.wp.wfone.listview selection remove $listlast
				break
			}
			# if this is an aur list then only select one item
			if {$aur_only == true} {
				puts $debug_out(1) "Control Button clicked on TreeView but aur_only is true"
				set listfirst $listlast
				.wp.wfone.listview selection set $listfirst
				break
			}
			# if this is the first item selected then set it as the anchor point
			if {$listfirst == ""} {
				puts $debug_out(1) "Control Button clicked on TreeView: Anchor is $anchor Last is $listlast"
				set anchor $listlast
			} else {
				puts $debug_out(1) "Control Button clicked on TreeView: Anchor is $anchor Last is $listlast First is $listfirst"
			}
			# finish off - add the new item to the selection list and save it as first
			.wp.wfone.listview selection add $listlast
			set listfirst $listlast
			break
		}
		bind .wp.wfone.listview <Control-space> {
			# find which item was clicked on last
			set listlast $tv_index
			# if this item was selected already, then de-select it
			if {[lsearch [.wp.wfone.listview selection] $listlast] != -1} {
				puts $debug_out(1) "Control Space clicked on TreeView - remove Last $listlast, Anchor is $anchor"
				.wp.wfone.listview selection remove $listlast
				break
			}
			# if this is an aur list then only select one item
			if {$aur_only == true} {
				puts $debug_out(1) "Control Space clicked on TreeView but aur_only is true"
				set listfirst $listlast
				.wp.wfone.listview selection set $listfirst
				break
			}
			# if this is the first item selected then set it as the anchor point
			if {$listfirst == ""} {
				puts $debug_out(1) "Control Space clicked on TreeView: Anchor is $anchor Last is $listlast"
				set anchor $listlast
			} else {
				puts $debug_out(1) "Control Space clicked on TreeView: Anchor is $anchor Last is $listlast First is $listfirst"
			}
			# finish off - add the new item to the selection list and save it as first
			.wp.wfone.listview selection add $listlast
			set listfirst $listlast
			break
		}
		bind .wp.wfone.listview <ButtonPress-1> {
			# remove any highlight border
			.wp.wfone configure -highlightcolor #d9d9d9		
			if {[.wp.wfone.listview identify region %x %y] == "heading" || [.wp.wfone.listview identify region %x %y] == "separator"} {
				puts $debug_out(1) "Button clicked on Treeview: column [string trim [.wp.wfone.listview identify column %x %y] \#] [.wp.wfone.listview identify region %x %y]"
			} else {	
				set listlast [.wp.wfone.listview identify item %x %y]
				set tv_index $listlast
				set anchor $listlast
				set listfirst ""
				puts $debug_out(1) "Button clicked on TreeView: Anchor is $anchor Last is $listlast"
				.wp.wfone.listview selection set $listlast
			}
			# now run the standard binding for treeview
		}
		bind .wp.wfone.listview <<TreeviewSelect>> {	
			# the selection has changed! What is the new selection?
			set listview_selected [.wp.wfone.listview selection]
			set state ""
			
			# check whether list_show was called and reset the selection list
			if {$listview_selected_in_order == ""} {
				puts $debug_out(2) "TreeviewSelect - listview_selected_in_order is blank so reset listview_last_selected"
				set listview_last_selected ""
			}

			puts $debug_out(1) "TreeviewSelect - there is a new selection: $listview_selected\n\tthe previous selection was $listview_last_selected"

			# check if anchor still exists, if not then set the anchor to the first item selected, or blank if nothing is selected
			if {[lsearch $listview_selected $anchor] == -1} {set anchor [lindex $listview_selected 0]}
			# first get rid of any obvious anomolies
			# if nothing has really changed then break out of the script
			# TreeviewSelect is triggered by a change in the selection, so it can appear to be triggered more than once.
			# for example when one item is deselected because another has been selected
			# so we get rid duplicate calls as soon as possible.
			# if we selected the same item a second time then we presume that we wanted to clear that selection
			# we need this because we haven't handled all the possibilities in the button bindings
			if {[llength $listview_selected] == 1 && $listview_selected == $listview_selected_in_order} {
				puts $debug_out(1) "Treeview selection $listview_selected has been selected twice so remove it"
				.wp.wfone.listview selection remove $listview_selected
				# reset the repo_delete_msg flag
				set repo_delete_msg true
				# and unpost the mark entry on the popup menu if it exists
				catch {.listview_popup delete "Mark"}
				# bind TreeviewSelect will update all the variables when the selection changes
				# now break out of the bind script
				set tv_select "break"
				break
			}
			if {$listview_selected == $listview_last_selected} {
				puts $debug_out(1) "TreeviewSelect - selection has not changed so break out of the script"
				# just check that we are not in AUR/Local, if we are then we cannot Select All, even if nothing is selected
				# this is necessary because we may have an AUR/Local item selected and have just checked AUR/Local
				if {$aur_only == true} {
					.menubar.edit entryconfigure 0 -state disabled
					.listview_popup entryconfigure 3 -state disabled
				}
				# now break out of the bind script
				set tv_select "break"
				break
			}
			# rather than checking if the mark entry already exists and then deciding whether to leave it or delete it
			# just unpost the mark entry on the popup menu if it exists
			catch {.listview_popup delete "Mark"}
			# and insert the mark entry in the popup menu if only one item is selected and it has been installed
			if {[llength $listview_selected] == 1 && [lrange [.wp.wfone.listview item $listview_selected -values] 3 3] != "{}"} {
				.listview_popup insert 5 cascade -label "Mark" -menu .listview_popup.mark
			}
			# so the selection has changed so reset the upgrades list
			set upgrades ""
			set upgrades_count 0
			# if the selection changed but nothing is selected now
			if {$listview_selected == ""} {
				puts $debug_out(1) "TreeviewSelect - there is nothing selected so break out of the script"
				# if anything was selcted before then clear the dtaview window - nothing is selected now
				if {$listview_last_selected != ""} {get_dataview ""}
				set listview_current ""
				set listview_last_selected ""
				set listview_selected_in_order ""
				set_message selected ""
				set repo_delete_msg true
				set state ""
				puts $debug_out(2) "TreeviewSelect - set the nothing selected menus states" 
				.buttonbar.install_button configure -state disabled
				.buttonbar.delete_button configure -state disabled
				.listview_popup entryconfigure 1 -state disabled
				.listview_popup entryconfigure 2 -state disabled
				.menubar.tools entryconfigure 1 -state disabled
				.menubar.tools entryconfigure 2 -state disabled
				.menubar.edit entryconfigure 0 -state normal
				.menubar.edit entryconfigure 1 -state disabled
				.listview_popup entryconfigure 3 -state normal
				.listview_popup entryconfigure 4 -state disabled
				if {[llength $list_show] == 0 || $aur_only == true} {
					# there is nothing in the list or we are in AUR/Local so we cannot Select All
					.menubar.edit entryconfigure 0 -state disabled
					.listview_popup entryconfigure 3 -state disabled
				} 
				# now break out of the bind script
				set tv_select "break"
				break
			}
			set listview_last_selected $listview_selected
			# update now to show the selection before analyzing it.
			update
			# find whether we need to install or delete the packages selected
			set listview_values ""
			# if there is nothing in the list then disable everything
			# we need this because the selection changed so the options may have changed as well
			if {[llength $list_show] == 0} {
				puts $debug_out(2) "there is nothing in the treeview list!"
				.buttonbar.install_button configure -state disabled
				.buttonbar.delete_button configure -state disabled
				.listview_popup entryconfigure 0 -state disabled
				.listview_popup entryconfigure 1 -state disabled
				.menubar.tools entryconfigure 1 -state disabled
				.menubar.tools entryconfigure 2 -state disabled
				# there is nothing in the list so we cannot Select All or Clear All
				.menubar.edit entryconfigure 0 -state disabled
				.menubar.edit entryconfigure 1 -state disabled
				.listview_popup entryconfigure 3 -state disabled
				.listview_popup entryconfigure 4 -state disabled
				# break out of the bind script
				set tv_select "break"
				break
			# if only one item is selected and it is in the aur updates list 
			# which is a given because only one item can be selected in the aur updates list
			# then it can be only be updated, re-installed or deleted
			# we need this here to avoid the other checks in the foreach loop below
			} elseif {$aur_only == true && [llength $listview_selected] == 1} {
				puts $debug_out(2) "TreeviewSelect - one item selected and AUR only is true"
				set state "update, re-install or delete"
				.buttonbar.install_button configure -state normal
				.buttonbar.delete_button configure -state normal
				.menubar.tools entryconfigure 1 -state normal
				.menubar.tools entryconfigure 2 -state normal
				.listview_popup entryconfigure 1 -state normal
				.listview_popup entryconfigure 2 -state normal
				# there is an AUR/Local item selected so we can Clear All but not Select All
				.menubar.edit entryconfigure 0 -state disabled
				.menubar.edit entryconfigure 1 -state normal
				.listview_popup entryconfigure 3 -state disabled
				.listview_popup entryconfigure 4 -state normal
			# then there is something selected so for each item selected
			# see whether we should offer to install, re-install or delete it
			} else {
				set tv_upgrades 0
				set tverr_text ""
				puts $debug_out(2) "TreeviewSelect - running tests foreach item in $listview_selected"
				set count 0
# start foreach loop
				foreach item $listview_selected {
					incr count
					puts $debug_out(3) "\t$item is $count loop"
					set listview_values [.wp.wfone.listview item $item -values]
					puts $debug_out(3) "TreeviewSelect - test next $item [lrange $listview_values 1 1]"
# if the item has not been installed
					if { [lrange $listview_values 3 3] == "{}"} {
						# if the item has not been installed then we should install it
						# not delete it
						# local packages cannot be installed here, but will show something, version or "-na-", in the fourth field!
						puts $debug_out(3) "\t$item has not been installed"
						if {$tverr_text == ""} {
							set tverr_text [list $item "[lrange $listview_values 1 1] can only be installed"]
						} else {
							set tverr_text [lappend tverr_text $item "[lrange $listview_values 1 1] can only be installed"]
						}
						puts $debug_out(3) "\t$tverr_text"
						if {$state == "" || $state == "install"} {
							set state "install"
							puts $debug_out(3) "\tset state to install"
						} elseif {$state == "install or re-install"} {
							puts $debug_out(3) "\tstate is already install or re-install"
						} elseif {$state == "re-install or delete"} {
						# unless one of the previous selected packages was local, in which case this would be an error
							puts $debug_out(3) "\tset state to install or re-install"
							set state "install or re-install"
						} else {
						# so state must be "delete" which is an error
							puts $debug_out(3) "\tset state to error"
							set state "error"
						}						
						# so this item is installed look at the next item
# if the item is outdated and is not a local package
					} elseif {[lrange $listview_values 3 3] != [lrange $listview_values 2 2] && [lrange $listview_values 0 0] != "local"} {
						if {$fs_upgrade == false} {
							puts $debug_out(3) "TreeviewSelect - FS_Upgrade is $fs_upgrade"
							puts $debug_out(3) "TreeviewSelect - [lindex $listview_values 1] upgrade from [lrange $listview_values 2 2] to [lrange $listview_values 3 3]"
							incr tv_upgrades
							# if we have not elected to do partial upgrades and
							# if the Treeview upgrade count equals the count of outdated packages or
							# we are in the outdated packages filter and the selected packages equals the count of outdated packages
							if {$tv_upgrades == $count_outdated || ($filter == "outdated" && [llength $listview_selected] == $count_outdated)} {
								# fs_upgrade is false, but we now have selected all the outdated packages, and no others
								# so check again if we want to do a Full System Upgrade"
								# but only ask for the last item in the list and we have not already set partial upgrade to yes (2)
								set tv_upgrades $count_outdated
								if {$item == [lindex $listview_selected end] && $part_upgrade == 0} {
									set tmp_text "The packages selected will be reinstalled."
									if {[llength $listview_selected] == 1} {set tmp_text "\"[lrange $listview_values 1 1]\" will be reinstalled."}
									if {$system_test == "unstable"} {set tmp_text [concat [string map {reinstalled ugraded} $tmp_text] "Continue at your own risk."]}
									set ans [tk_messageBox -default yes -detail "Answer Yes to run a Full System Upgrade (recommended)\nAnswer No to continue. $tmp_text" -icon warning -message "All the upgrades are selected" -parent . -title "Warning" -type yesno]
									puts $debug_out(3) "TreeviewSelect - answer to partial upgrade all packages warning message is $ans" 
									switch $ans {
										"yes" {
											puts $debug_out(3) "\tPartial Upgrades set to no, Full System Upgrade set to true"
											set part_upgrade 0
											set fs_upgrade true
											# run a full system upgrade and kill this bind script
											system_upgrade
											# now break out of the loop and complete the bind script
											set tv_select "break"
											break
										}
										"no" {
											puts $debug_out(3) "\tPartial Upgrades set to yes - 1"
											set part_upgrade 1
										}
									}
								}
							}
						}
						# this could be a partial upgrade, so if Partial Upgrades is no (0) and Full System Upgrade is false
						# and we have not selected all the upgrades						
						if {$part_upgrade == 0 && $fs_upgrade == false && $tv_upgrades != $count_outdated} {
							# TreeviewSelect will check all the packages selected each time the selection changes so
							# add the item selected to the upgrade list
							if {[lsearch $upgrades [lrange $listview_values 1 1]] == -1} {
								incr upgrades_count
								if {$upgrades_count < 15} {
									set upgrades [lappend upgrades [lrange $listview_values 1 1]]
									puts $debug_out(3) "TreeviewSelect - added [lrange $listview_values 1 1] to upgrade list ($upgrades)"
								} elseif {$upgrades_count == 15} {
									set upgrades [lappend upgrades  etc ...]
									puts $debug_out(3) "TreeviewSelect - added \" etc ...\" to upgrade list ($upgrades)"
								}
								puts $debug_out(3) "TreeviewSelect - $upgrades_count upgrades selected."
							}
							
						}
						puts $debug_out(3) "\t$item has been installed and is not a local package"
						# if any previous items were set to install it can only be re-installed
						if {$state == "install" || $state == "install or re-install"} {
							# then there must be an "install only" item selected previously"
							puts $debug_out(3) "\tset state to install or re-install"
							set state "install or re-install"
						} elseif {$state == "delete"} {
							puts $debug_out(3) "\tset state to delete"
						} else {
							puts $debug_out(3) "\tset state to re-install or delete"
							set state "re-install or delete"
						}
# if the item is a local package then it can only be deleted unless we are in AUR/Local Updates
					} elseif {[lrange $listview_values 0 0] == "local"} {
						puts $debug_out(3) "\t$item is local and aur_only is $aur_only"
						# if it is a local package, we can only delete it here
						if {$aur_only == false} {
							if {($state == "install" || $state == "install or re-install") && $repo_delete_msg == true} {
								puts $debug_out(3) "$item is local and state is set to $state"
								set ans [tk_messageBox -default yes -detail "Answer Yes to continue without selecting \"[lindex $listview_values 1]\"\nAnswer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and cannot be  re-installed from here." -parent . -title "Warning" -type yesno]
								puts $debug_out(3) "Answer to install local package warning message is $ans" 
								switch $ans {
									no {
										puts $debug_out(3) "\tLocal Upgrades set to true."
										set repo_delete_msg true
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# break out of the loop and complete the bind script
										# bind TreeviewSelect will update all the variables when the selection changes
										set tv_select "break"
										break
									}
									yes {
										puts $debug_out(3) "\tLocal Upgrades set to false."
										set repo_delete_msg false
										# if the response is Continue (1), then deselect item and continue with the next item in the foreach loop.
										.wp.wfone.listview selection remove $item
										# bind TreeviewSelect will update all the variables when the selection changes
										# so break out of the loop and complete the bind script
										set tv_select "break"
										break
									}	
								}
							} elseif {$state == "delete"} {
								puts $debug_out(3) "$item is local and state is delete"
								# bind TreeviewSelect will update all the variables when the selection changes
							} elseif {[string first "delete" $state] != -1 && $repo_delete_msg == true} {
								puts $debug_out(3) "$item is local and state ($state) includes delete"
								set ans [tk_messageBox -default yes -detail "Do you want to continue selecting packages to delete, answer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and can only be deleted from here." -parent . -title "Warning" -type yesno]
								puts $debug_out(3) "\tanswer to delete local package warning message is $ans" 
								switch $ans {
									no {
										puts $debug_out(3) "\tLocal Upgrades set to true."
										set repo_delete_msg true
										# if the response is Abort (no), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# bind TreeviewSelect will update all the variables when the selection changes
										set tv_select "break"
										break
									}
									yes {
										puts $debug_out(3) "\tLocal Upgrades set to false."
										set repo_delete_msg false
										# if the response is Continue (yes), then set delete and continue with the next item in the foreach loop.
										set state "delete"
										puts $debug_out(3) "\tset to delete"
									}	
								}
							} elseif {$state == "error"} {
								puts $debug_out(3) "\tpreviously set to error"
							} else {
								set state "delete"
								puts $debug_out(3) "\tset to delete"
							}
							if {$tverr_text == ""} {
								set tverr_text [list $item "[lrange $listview_values 1 1] is a local package and can only be deleted "]
							} else {
								set tverr_text [lappend tverr_text $item "[lrange $listview_values 1 1] is a local package and can only be deleted "]
							}
							puts $debug_out(3) "\t$tverr_text"
						} else {
							# so aur_only is true
							set state "update, re-install or delete"
							puts $debug_out(3) "\tset to re-install or delete"
						}
# so the item is installed, is not outdated and is not a local package
					} else {
						if {$state == "" || $state == "re-install or delete"} {
							puts $debug_out(3) "\tset state to re-install or delete"
							set state "re-install or delete"
						} elseif {$state == "install" || $state == "install or re-install"} {
							puts $debug_out(3) "\tset state to install or re-install"
							set state "install or re-install"
						} else {
							puts $debug_out(3) "\t$item can only be re-installed or deleted"
							# if the existing state includes delete then select that, otherwise it is an error
							if {[string first "delete" $state] == -1} {
								set state "error"
							} else {
								# only show this message once in each new selection
								if {$repo_delete_msg} {
									set values [.wp.wfone.listview item [lindex $listview_selected_in_order end] -values]
									tk_messageBox -default ok -detail "To Install or Reinstall any repository packages selected, deselect all the local packages." -icon warning -message "A local package is selected so repository packages (including [lindex $listview_values 1])  can only be deleted." -parent . -title "Warning" -type ok
									set repo_delete_msg false
								}
								set state "delete"
							}
						}
					}
				}
# end foreach loop
# now check for any errors in the new selection
				puts $debug_out(2) "TreeviewSelect - sort all items completed - check for errors"
				set tverr_message ""
				if {$state == "error"} {
					set index ""
					set message ""
					foreach {index message} $tverr_text {
						set tverr_message "$tverr_message \n$message"
					}
					puts $debug_out(2) "TreeviewSelect -there are potential errors in the selected list"	
					if {[string first "deleted" $tverr_text] != -1} {puts $debug_out(1) "deleted found in error text"}
					if {[string first "installed" $tverr_text] != -1} {puts $debug_out(1) "installed found in error text"}
					set ans [tk_messageBox -default ok -detail "$tverr_message" -icon warning -message "Errors were found in the Selection" -parent . -title "Error" -type ok]
					puts $debug_out(2) "\tanswer to local package warning message is $ans" 
					all_clear
				}
				puts $debug_out(2) "TreeviewSelect - something is selected so set the correct menus states" 
				# set the correct menu states
				.buttonbar.install_button configure -state disabled
				.buttonbar.delete_button configure -state disabled
				.menubar.tools entryconfigure 1 -state disabled
				.menubar.tools entryconfigure 2 -state disabled
				.listview_popup entryconfigure 1 -state disabled
				.listview_popup entryconfigure 2 -state disabled
				# there is something selected and we are not in AUR/Local so allow Select All and Clear All
				.menubar.edit entryconfigure 0 -state normal
				.menubar.edit entryconfigure 1 -state normal
				.listview_popup entryconfigure 3 -state normal
				.listview_popup entryconfigure 4 -state normal
				if {$state != "error"} {
					if {[string first "install" $state] != -1} {
						# enable the install entries
						.buttonbar.install_button configure -state normal
						.menubar.tools entryconfigure 1 -state normal
						.listview_popup entryconfigure 1 -state normal
					}
					if {[string first "delete" $state] != -1} {
						# enable the delete entries
						.buttonbar.delete_button configure -state normal
						.menubar.tools entryconfigure 2 -state normal
						.listview_popup entryconfigure 2 -state normal
					}
				}
			}
			# everything has been checked so finish the set up
			if {$listview_selected != ""} {
				# now lets work out the last selected item to pass to get_dataview
				# add any newly selected items to listview_selected_in_order
				foreach item $listview_selected {
					# if the item from listview_selected does not exist in listview_selected_in_order then add it at the end of listview_selected_in_order
					if {[string first $item $listview_selected_in_order] == -1} {
						lappend listview_selected_in_order $item
					}
				}
				# remove any deselected items from listview_selected_in_order
				set temp_list ""
				foreach item $listview_selected_in_order {
					# if the item from listview_selected_in_order exists in listview_selected then add it to a temporary list
					if {[string first $item $listview_selected] != -1} {
						lappend temp_list $item
					}
				}
				# now reset listview_selected_in_order to the temporary list constructed
				set listview_selected_in_order $temp_list
				puts $debug_out(2) "TreeviewSelect - selection in order is now $listview_selected_in_order"
			}
			# set the message text
			if {[llength $listview_selected] == 0} {
				puts $debug_out(2) "TreeviewSelect - set_message selected blanked"
				set_message selected ""
			} elseif {[llength $listview_selected] > 1} {
				set_message selected "[llength $listview_selected] items selected to $state"
			} else {
				set_message selected "[llength $listview_selected] item selected to $state"
			}
			# if more than one item was selected in the last selection then choose the last one
			set listview_current [lindex $listview_selected_in_order end]
			# now update whatever the tag is in the dataview window
			puts $debug_out(2) "TreeviewSelect - selection changed - call dataview with $listview_current"
			get_dataview $listview_current
			puts $debug_out(2) "TreeviewSelect - updated dataview"
			# change a variable to allow for a vwait command if necessary
			set tv_select "done"
			puts $debug_out(1) "TreeviewSelect - completed - tv_select is now $tv_select\n\tlistview_selected_in_order is $listview_selected_in_order "
		}	

# set up a popup menu for listview
	option add *tearOff 0
	menu .listview_popup -cursor left_ptr
	.listview_popup add command -label "Full System Upgrade" -command {system_upgrade} -state normal
	.listview_popup add command -label "Install" -command {
		if {$aur_only} {
			puts $debug_out(1) ".buttonbar.install_button call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
			aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] "upgrade"
		} else {
			execute install
		}
	} -state disabled
	.listview_popup add command -label "Delete" -command {execute delete} -state disabled
	.listview_popup add command -label "Select All" -command {all_select} -state normal
	.listview_popup add command -label "Clear All" -command {all_clear} -state disabled
# and a cacade menu for a mark entry, but do not insert the mark entry until it is needed
	menu .listview_popup.mark
		.listview_popup.mark add command -label "Explicitly installed" -command {
			set package [lrange [.wp.wfone.listview item  [.wp.wfone.listview selection] -values] 1 1] 
			puts $debug_out(1) "mark --asexplicit called for $package"
			if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
				set fid [open $tmp_dir/vpacman.sh w]
				puts $fid "#!/bin/sh"
				puts $fid "password=\$1"
				if {$su_cmd == "su -c"} {
					puts $fid "echo \$password | $su_cmd \"pacman -D --asexplicit $package\" > /dev/null 2>&1"
				} else {
					puts $fid "echo \$password | $su_cmd -S -p \"\" pacman -D --asexplicit $package > /dev/null 2>&1"
				}
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				close $fid
				exec chmod 0755 "$tmp_dir/vpacman.sh"
				# get the password
				set password [get_password "."]
				# password will be set to an error of 3 if the password procedure was cancelled
				if {$password != 3} {
					set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
					# don't save the password
					unset password
				} else {
					unset password
					set error 1
					set result "Authentication failure"
					puts $debug_out(1) "mark explicitally installed - get_password cancelled"
				}
				if {$error == 1} {
					# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
					# the second error message will be displayed instead, which is not too bad.
					if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
						puts $debug_out(1) "mark explicitally installed - Authentification failed"
						set_message terminal "Authentification failed - mark $package as explicitly installed cancelled"
					} else {
						puts $debug_out(1) "mark explicitly installed - failed"
						set_message terminal "Could not mark package as explicitly installed"
					}
				} else {
					set_message terminal "Marked $package as explicitly installed"
				}
				
			} else {
				puts $debug_out(1) "mark --asexplicit ran \"exec $su_cmd pacman -D --asexplicit $package\""
				set error [catch {eval [concat exec $su_cmd pacman -D --asexplicit $package]} error_message]
				puts $debug_out(1) "mark --asexplicit called with error: $error - \"$error_message\""
				if {$error != 0} {
					set_message terminal "Pacman returned an error marking $package as explicitly installed"
				} else {
					set_message terminal "Marked $package as explicitly installed"
				}
			}
			file delete $tmp_dir/vpacman.sh
			# set the dataview variable blank so that the datview procedure updates the current page
			set dataview ""
			# and update dataview
			get_dataview [.wp.wfone.listview selection]
			after 3000 {set_message reset ""}
		}
		.listview_popup.mark add command -label "Installed as a dependancy" -command {
			set package [lrange [.wp.wfone.listview item  [.wp.wfone.listview selection] -values] 1 1] 
			puts $debug_out(1) "mark --asdeps called for $package"
			if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
				set fid [open $tmp_dir/vpacman.sh w]
				puts $fid "#!/bin/sh"
				puts $fid "password=\$1"
				if {$su_cmd == "su -c"} {
					puts $fid "echo \$password | $su_cmd \"pacman -D --asdeps $package\" > /dev/null 2>&1"
				} else {
					puts $fid "echo \$password | $su_cmd -S -p \"\" pacman -D --asdeps $package > /dev/null 2>&1"
				}
				puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
				close $fid
				exec chmod 0755 "$tmp_dir/vpacman.sh"
				# get the password
				set password [get_password "."]
				# password will be set to an error of 3 if the password procedure was cancelled
				if {$password != 3} {
					set error [catch {eval [concat exec "$tmp_dir/vpacman.sh $password"]} result]
					# don't save the password
					unset password
				} else {
					unset password
					set error 1
					set result "Authentication failure"
					puts $debug_out(1) "mark explicitally installed - get_password cancelled"
				}
				if {$error == 1} {
					# language - Authentication failure/Sorry, try again. occur only in English, or on Password cancelled (above)
					# the second error message will be displayed instead, which is not too bad.
					if {[string first "Authentication failure" $result] != -1 || [string first "Sorry, try again." $result] != -1} {
						puts $debug_out(1) "mark as dependancy - Authentification failed"
						set_message terminal "Authentification failed - mark $package as a dependency cancelled"
					} else {
						puts $debug_out(1) "mark as dependency - failed"
						set_message terminal "Could not mark package as a dependency"
					}
				} else {
					set_message terminal "Marked $package as a dependency"
				}
			} else {
				puts $debug_out(1) "mark --asdeps ran \"exec $su_cmd pacman -D --asdeps $package\""
				set error [catch {eval [concat exec $su_cmd pacman -D --asdeps $package]} error_message]
				puts $debug_out(1) "mark --asdeps called with error: $error - \"$error_message\""
				if {$error != 0} {
					set_message terminal "Pacman returned an error marking $package as a dependancy"
				} else {
					set_message terminal "Marked $package as a dependency"
				}
			}
			file delete $tmp_dir/vpacman.sh
			# set the dataview variable blank so that the datview procedure updates the current page
			set dataview ""
			# and update dataview
			get_dataview [.wp.wfone.listview selection]
			after 3000 {set_message reset ""}
		}
		.listview_popup.mark add command -label "Ignored \[toggle\]" -command {toggle_ignored [lrange [.wp.wfone.listview item  [.wp.wfone.listview selection] -values] 1 1]}
				
# set up a binding to open the popup menu at the cursor position
	bind .wp.wfone.listview <ButtonRelease-3> {
		puts $debug_out(1) "Button 3 pressed on listview at %X %Y ([.wp.wfone.listview identify region %x %y] [.wp.wfone.listview identify column %x %y])"
		# remove any highlight border
		.wp.wfone configure -highlightcolor #d9d9d9
		# do not pop up the menu if we clicked on the heading row
		if {[.wp.wfone.listview identify region %x %y] != "heading" && [.wp.wfone.listview identify region %x %y] != "separator"} {
			tk_popup .listview_popup %X %Y 0
		}
		break
	}
# set button-3 on the popup menu to re-open it at the new position
	bind .listview_popup <ButtonRelease-3> {
		puts $debug_out(1) "Button 3 pressed on listview_popup at %X %Y"
		# the default height of a ttk_treeview row is 20
		# so the boundings of the treeview window, excluding the headings row, are
		set tv_left [winfo rootx .wp.wfone.listview]
		set tv_top [expr [winfo rooty .wp.wfone.listview] + 20]
		set tv_right [expr [winfo rootx .wp.wfone.listview] + [winfo width .wp.wfone.listview]]
		set tv_bottom [expr [winfo rooty .wp.wfone.listview] + [winfo height .wp.wfone.listview]]
		# so if we clicked in the data part of the treeview window
		if {(%X > $tv_left && %X < $tv_right) && (%Y > $tv_top && %Y < $tv_bottom)} {
			tk_popup .listview_popup %X %Y 0
		}
		break
	}
	
# set up a window frame for the dataview in the windowpane wp called windowframe two or wftwo

frame .wp.wftwo \
	-takefocus 0

# Notebook

# Insert a ttk::notebook with tab widths set to 10 and centred
ttk::style configure TNotebook.Tab -width 10
ttk::style configure TNotebook.Tab -anchor center 
	
ttk::notebook .wp.wftwo.dataview \
	-takefocus 1
	
	.wp.wftwo.dataview add [text .wp.wftwo.dataview.info -font TkFixedFont -relief flat -wrap word -yscrollcommand ".wp.wftwo.ydataview_info_scroll set"] \
		-state normal \
		-sticky nswe \
		-text "Info"

	.wp.wftwo.dataview add [text .wp.wftwo.dataview.moreinfo -font TkFixedFont -relief flat -wrap word  -yscrollcommand ".wp.wftwo.ydataview_moreinfo_scroll set"] \
		-state normal \
		-sticky nswe \
		-text "More Info"

	.wp.wftwo.dataview add [text .wp.wftwo.dataview.files -font TkFixedFont -relief flat -yscrollcommand ".wp.wftwo.ydataview_files_scroll set"] \
		-state normal \
		-sticky nswe \
		-text "Files" 
		
	.wp.wftwo.dataview add [text .wp.wftwo.dataview.check -font TkFixedFont -relief flat ] \
		-state normal \
		-sticky nswe \
		-text "Check" 
	
	# set up some scroll bars
	
	scrollbar .wp.wftwo.ydataview_info_scroll \
			-command ".wp.wftwo.dataview.info yview" \
			-cursor {} \
			-takefocus 0
	
	# now extend the bindings for the scrollbar	
	bind .wp.wftwo.ydataview_info_scroll <ButtonRelease-3> {
		set scroll_element [.wp.wftwo.ydataview_info_scroll identify %x %y]
		if {$scroll_element == "arrow1"} {
			.wp.wftwo.dataview.info yview moveto 0
		} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
			.wp.wftwo.dataview.info yview moveto [.wp.wftwo.ydataview_info_scroll fraction %x %y]
		} elseif {$scroll_element == "arrow2"} {
			.wp.wftwo.dataview.info yview moveto 1
		}
	}
			
	scrollbar .wp.wftwo.ydataview_moreinfo_scroll \
			-command ".wp.wftwo.dataview.moreinfo yview" \
			-cursor {} \
			-takefocus 0
			
	# now extend the bindings for the scrollbar	
	bind .wp.wftwo.ydataview_moreinfo_scroll <ButtonRelease-3> {
		set scroll_element [.wp.wftwo.ydataview_moreinfo_scroll identify %x %y]
		if {$scroll_element == "arrow1"} {
			.wp.wftwo.dataview.moreinfo yview moveto 0
		} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
			.wp.wftwo.dataview.moreinfo yview moveto [.wp.wftwo.ydataview_moreinfo_scroll fraction %x %y]
		} elseif {$scroll_element == "arrow2"} {
			.wp.wftwo.dataview.moreinfo yview moveto 1
		}
	}
		
	scrollbar .wp.wftwo.ydataview_files_scroll \
			-command ".wp.wftwo.dataview.files yview" \
			-cursor {} \
			-takefocus 0
			
	# now extend the bindings for the scrollbar	
	bind .wp.wftwo.ydataview_files_scroll <ButtonRelease-3> {
		set scroll_element [.wp.wftwo.ydataview_files_scroll identify %x %y]
		if {$scroll_element == "arrow1"} {
			.wp.wftwo.dataview.files yview moveto 0
		} elseif {$scroll_element == "trough1" || $scroll_element == "trough2"} {
			.wp.wftwo.dataview.files yview moveto [.wp.wftwo.ydataview_files_scroll fraction %x %y]
		} elseif {$scroll_element == "arrow2"} {
			.wp.wftwo.dataview.files yview moveto 1
		}
	}

	# some simple bindings for wp.wftwo.dataview
	# don't allow dataview to keep the focus
	bind .wp.wftwo.dataview <FocusIn> {
		focus .wp.wfone.listview
	}
	# get the new contents for dataview when the tab changes	
	bind .wp.wftwo.dataview <<NotebookTabChanged>> {
		puts $debug_out(1) "Dataview tab changed - call get_dataview ([expr [clock milliseconds] - $start_time])"
		get_dataview $listview_current
	}
	
# set up a popup menu for dataview
	option add *tearOff 0
	set dataview_popup [menu .dataview_popup -cursor left_ptr]
	$dataview_popup add command -label "Copy" -command {
		clipboard clear
		clipboard append [selection get]
		selection clear -displayof $window
	}
# and set up a binding for it
	foreach window ".wp.wftwo.dataview.info .wp.wftwo.dataview.moreinfo .wp.wftwo.dataview.files .wp.wftwo.dataview.check" {
		bind $window <ButtonRelease-3> {
			set window %W
			if {[$window tag ranges sel] != ""} {
				tk_popup .dataview_popup %X %Y 0
			}
		}
	}
# Set up some tags for the text field '.wp.wftwo.dataview.info'
# make the URL blue
.wp.wftwo.dataview.info tag configure url_tag -foreground blue 
# set the cursor to a left pointer when hovering over the text
.wp.wftwo.dataview.info tag bind url_cursor_in <Enter> ".wp.wftwo.dataview.info configure -cursor left_ptr"
# set the cursor to the default when leaving the text
.wp.wftwo.dataview.info tag bind url_cursor_out <Leave> ".wp.wftwo.dataview.info configure -cursor [.wp.wftwo.dataview.info cget -cursor]"
	
# Set up some tags for the text field '.wp.wftwo.dataview.moreinfo'
# make the URL blue
.wp.wftwo.dataview.moreinfo tag configure url_tag -foreground blue 
# set the cursor to a left pointer when hovering over the text
.wp.wftwo.dataview.moreinfo tag bind url_cursor_in <Enter> ".wp.wftwo.dataview.moreinfo configure -cursor left_ptr"
# set the cursor to the default when leaving the text
.wp.wftwo.dataview.moreinfo tag bind url_cursor_out <Leave> ".wp.wftwo.dataview.moreinfo configure -cursor [.wp.wftwo.dataview.moreinfo cget -cursor]"	


# add the two elements, listview and dataview to the windowpane wp
	.wp add .wp.wfone
	.wp add .wp.wftwo
	
# Geometry management
	
	grid .buttonbar -in . -row 2 -column 1 \
		-columnspan 3 \
		-sticky ew
		grid .buttonbar.upgrade_button -in .buttonbar -row 1 -column 1 \
			-sticky w
		grid .buttonbar.reload_button -in .buttonbar -row 1 -column 2 \
			-sticky w
		grid .buttonbar.install_button -in .buttonbar -row 1 -column 3 \
			-sticky w
		grid .buttonbar.delete_button -in .buttonbar -row 1 -column 4 \
			-sticky w
		grid .buttonbar.label_message -in .buttonbar -row 1 -column 5 \
			-columnspan 3 \
			-sticky we
		grid .buttonbar.label_find -in .buttonbar -row 1 -column 8 \
			-sticky e
		grid .buttonbar.entry_find -in .buttonbar -row 1 -column 9 \
			-sticky we
		grid .buttonbar.clear_find_button -in .buttonbar -row 1 -column 10 \
			-sticky e
		grid .buttonbar.configure_button -in .buttonbar -row 1 -column 11 \
			-sticky e

	grid .filters -in . -row 3 -column 1 \
		-columnspan 1 \
		-rowspan 3 \
		-sticky nswe
		grid .filter_label -in .filters -row 2 -column 1 \
			-columnspan 5 \
			-sticky w
		grid .filter_all -in .filters -row 3 -column 2 \
			-columnspan 4 \
			-sticky w
		grid .group_label -in .filters -row 4 -column 2 \
			-sticky w
		grid .group_entry -in .filters -row 4 -column 3 \
			-columnspan 2 \
			-sticky we
		grid .group_button -in .filters -row 4 -column 5
		grid .listgroups -in .filters -row 5 -column 3 \
			-columnspan 2 \
			-rowspan 7 \
			-sticky nesw
		grid .scroll_selectgroup -in .filters -row 5 -column 5 \
			-rowspan 7 \
			-sticky ns
		# and remove the listgroups box and its scroll bar until needed, also set up the associated bindings
		grid_remove_listgroups

		grid .filter_installed -in .filters -row 6 -column 2 \
			-columnspan 4 \
			-sticky w
		grid .filter_not_installed -in .filters -row 7 -column 2 \
			-columnspan 4 \
			-sticky w	
		grid .filter_updates -in .filters -row 8 -column 2 \
			-columnspan 4 \
			-sticky w	
		grid .filter_list_label -in .filters -row 9 -column 1 \
			-columnspan 5 \
			-sticky w
		grid .filter_list_orphans -in .filters -row 10 -column 2 \
			-columnspan 4 \
			-sticky w
		grid .filter_list_not_required -in .filters -row 11 -column 2 \
			-columnspan 4 \
			-sticky w
		grid .filter_list_aur_updates -in .filters -row 12 -column 2 \
			-columnspan 4 \
			-sticky w
		grid .filter_list_aur_updates_all -in .filters -row 13 -column 3 \
			-columnspan 3 \
			-sticky w
		# grid the filter_icons frame
		grid .filter_icons -in .filters -row 14 -column 2 \
			-columnspan 4 \
			-sticky nswe
			# grid a warning
			grid .filter_icons_warning -in .filter_icons -row 2 -column 2 \
				-padx 10
			# and remove it until needed
			grid remove .filter_icons_warning
			# grid disconnected
			grid .filter_icons_disconnected -in .filter_icons -row 2 -column 3 \
				-padx 10
			# and remove it until needed
			grid remove .filter_icons_disconnected
			# grid filesync
			grid .filter_icons_filesync -in .filter_icons -row 3 -column 2 \
				-padx 10
			# and remove it until needed
			grid remove .filter_icons_filesync
		grid .filter_clock_label -in .filters -row 15 -column 1 \
			-columnspan 3 \
			-sticky w
		grid .filter_clock -in .filters -row 15 -column 4 \
			-columnspan 2 \
			-sticky e
		grid .filter_upgrade_label -in .filters -row 16 -column 1 \
			-columnspan 3 \
			-sticky w
		grid .filter_upgrade -in .filters -row 16 -column 4 \
			-columnspan 2 \
			-sticky e
	grid .wp.wfone.listview -in .wp.wfone -row 1 -column 1 \
		-sticky nsew
	grid .wp.wfone.xlistview_scroll -in .wp.wfone -row 2 -column 1 \
		-sticky ew
	grid .wp.wfone.ylistview_scroll -in .wp.wfone -row 1 -column 2 \
		-sticky ns
	grid .wp.wftwo.dataview -in .wp.wftwo -row 1 -column 1 \
		-sticky nsew
	grid .wp -in . -row 3 -column 2 \
		-columnspan 2\
		-rowspan 2 \
		-sticky nsew

# Resize behavior management

	grid rowconfigure . 1 -weight 0 -minsize 0 -pad 0
	grid rowconfigure . 2 -weight 0 -minsize 0 -pad 0
	grid rowconfigure . 3 -weight 1 -minsize 0 -pad 0
	grid rowconfigure . 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure . 5 -weight 1 -minsize 0 -pad 0
	grid columnconfigure . 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure . 2 -weight 1 -minsize 0 -pad 0
	grid columnconfigure . 3 -weight 0 -minsize 20 -pad 0

	grid rowconfigure .menubar 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 5 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 6 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 7 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 8 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 9 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .menubar 10 -weight 0 -minsize 0 -pad 0
	
	grid rowconfigure .buttonbar 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 1 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 2 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 3 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 4 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 5 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 6 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 7 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 8 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 9 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 10 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 11 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 12 -weight 0 -minsize 20 -pad 0

	grid rowconfigure .filters 1 -weight 0 -minsize 10 -pad 10
	grid rowconfigure .filters 2 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 3 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 4 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .filters 5 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 6 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 7 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 8 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 9 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 10 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 11 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 12 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 13 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .filters 14 -weight 1 -minsize 10 -pad 0
	grid rowconfigure .filters 15 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .filters 16 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .filters 17 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filters 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filters 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filters 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filters 4 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filters 5 -weight 0 -minsize 5 -pad 0
	
	grid rowconfigure .filter_icons 1 -weight 1 -minsize 0 -pad 0 
	grid rowconfigure .filter_icons 2 -weight 0 -minsize 0 -pad 0 
	grid rowconfigure .filter_icons 3 -weight 1 -minsize 0 -pad 0 
	grid columnconfigure .filter_icons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .filter_icons 2 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filter_icons 3 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .filter_icons 4 -weight 1 -minsize 0 -pad 0
	
	grid rowconfigure .wp.wfone 1 -weight 1 -minsize 0 -pad 0 
	grid rowconfigure .wp.wfone 2 -weight 0 -minsize 10 -pad 0
	grid columnconfigure .wp.wfone 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .wp.wfone 2 -weight 0 -minsize 10 -pad 0
	
	grid rowconfigure .wp.wftwo 1 -weight 1 -minsize 0 -pad 0 
	grid rowconfigure .wp.wftwo 2 -weight 0 -minsize 10 -pad 0
	grid columnconfigure .wp.wftwo 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .wp.wftwo 2 -weight 0 -minsize 10 -pad 0
	
# the menu bar is mapped, but remove it if we did not ask for it
if {$show_menu == "no"} {
	. configure -menu ""
	# add two entries at the end of the popup menu
	.listview_popup add separator
	.listview_popup add command -label "Show Menu" -command {
		. configure -menu .menubar
		set show_menu "yes"
		# now remove the last two lines, whatever they may be
		.listview_popup delete end	
		.listview_popup delete end	
	} -state normal
}
# the button bar is mapped, but remove it if we did not ask for it
if {$show_buttonbar == "no"} {
	grid remove .buttonbar
	.menubar.view entryconfigure 6 -command {
			grid .buttonbar -in . -row 2 -column 1 -columnspan 3 -sticky ew
			set show_buttonbar "yes"
			toggle_buttonbar
	} -label "Show Toolbar" -state normal -underline 5
}

# Control Keys

# set some bindings on the main window for Control-Keys
bind . <Control-a> {all_select}
bind . <Control-A> {event generate . <Control-a>}
bind . <Control-a> {all_select}
bind . <Key-Escape> {all_clear}
bind . <Control-t> {
	# have we got Shift-Control-t or Control-t?
	if {%s & 2} {
		# looks like Caps Lock is on
		event generate . <Control-T>
		break
	}
	set tab_index [.wp.wftwo.dataview index current]
	# move to the next tab - there are only four tabs (0 - 3)
	incr tab_index
	if {$tab_index > 3} {set tab_index 0}
	.wp.wftwo.dataview select $tab_index
}
bind . <Control-T> {
	# have we got Shift-Control-t or Control-t?
	if {%s & 2} {
		# looks like Caps Lock is on
		event generate . <Control-t>
		break
	}
	set tab_index [.wp.wftwo.dataview index current]
	# move to the previous tab - there are only four tabs (0 - 3)
	incr tab_index -1
	if {$tab_index < 0} {set tab_index 3}
	.wp.wftwo.dataview select $tab_index
}

# set balloon help

balloon_set .buttonbar.upgrade_button "Perform a Full System Upgrade"
balloon_set .buttonbar.reload_button "Synchronize the database" 
balloon_set .buttonbar.install_button "Install or Re-install the selected items" 
balloon_set .buttonbar.delete_button "Delete the selected items" 
balloon_set .buttonbar.label_find "Click here to change the type of search" 
balloon_set .buttonbar.entry_find "Find some data in the list displayed\n(excluding the Repository name)" 
balloon_set .buttonbar.clear_find_button "Clear the find data" 
balloon_set .buttonbar.configure_button "Options" 
balloon_set .filter_all "Show all packages for the selected Group"
balloon_set .filter_icons_disconnected "Vpacman did not detect an internet connection.\nClick her to check again."
balloon_set .filter_icons_warning "Vpacman has detected a possible sync error.\nConsider running a Full System Upgrade."
balloon_set .filter_icons_filesync "One or more files databases are out of date.\nClick here to update them."
balloon_set .group_entry "Only show packages in the selected Group"
balloon_set .group_label "Only show packages in the selected Group"
balloon_set .filter_upgrade "The time of the last Full System Upgrade"
balloon_set .filter_upgrade_label "The time of the last Full System Upgrade"
balloon_set .filter_clock "The elapsed time since the last sync (d:h:m)"
balloon_set .filter_clock_label "The elapsed time since the last sync (d:h:m)"
balloon_set .filter_installed "Only show installed packages for the selected Group"
balloon_set .filter_not_installed "Only show packages which are not installed for the selected Group"
balloon_set .filter_updates "Only show packages which have not been updated for the selected Group"
balloon_set .filter_list_orphans "List any unused packages (Orphans)"
balloon_set .filter_list_not_required "List only packages which are not required by any installed package"
if {!$aur_all} {
	balloon_set .filter_list_aur_updates "List only local packages which may need to be updated"
} else {
	balloon_set .filter_list_aur_updates "List all AUR/Local packages which have been installed"
}
balloon_set .filter_list_aur_updates_all "Include all local packages in the AUR/Local list"
balloon_set .scroll_selectgroup "Use right click to jump"
balloon_set .wp.wfone.ylistview_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_files_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_info_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_moreinfo_scroll "Use right click to jump"

puts $debug_out(1) "WINDOWS - completed Window bindings and help set up -([expr [clock milliseconds] - $start_time])"

# THREADS

if {$threads} {
	
puts $debug_out(1) "THREADS - start threads set up -([expr [clock milliseconds] - $start_time])"

	# aur_files
	#	use pacman to get the file list of the AUR/Local packages for a file name search
	# aur_versions
	#	use the download programme to get the available versions of the AUR/Local packages
	
	# create a thread to lookup the files for AUR/local packages
	# this thread will keep running so that it can be used whenever start is called
	
	set aur_files_TID [thread::create {
	
		proc thread_get_aur_files {main_TID list_local tmp_dir} {
			set aur_files ""
			foreach element $list_local {
				# make up a list of all the local packages in the format "package file file file..."
				# and save them in aur_files
				set item [lindex $element 1]
				set aur_files [lappend aur_files [concat "$item" [split [exec pacman -b $tmp_dir -Qlq $item] \n]]]
			}
			eval [subst {thread::send -async $main_TID {::put_aur_files [list $aur_files]}}]
	    }
	    thread::wait
	}] 
	
	# create a thread to lookup the new AUR/local versions
	# this thread will keep running so that it can be used again where start is called and a delayed result is possible
	
	set aur_versions_TID [thread::create {
	
		proc thread_get_aur_versions {main_TID dlprog tmp_dir list_local} {

			set aur_versions ""
			set list ""
			set result ""
	
			foreach item $list_local {
				# make up a list of all the local packages in the format &arg[]=package&arg[]=package etc.
				set list [append list "\&arg\[\]=[lindex $item 1]"]
			}
			# now find all the information on these packages
			set fid [open "$tmp_dir/thread_aur_versions.sh" w]
			puts $fid "#!/bin/bash"
			if {$dlprog == "curl"} {
				puts $fid "curl -LfGs \"https://aur.archlinux.org/rpc?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\""
			} else {
				puts $fid "wget -LqO - \"https://aur.archlinux.org/rpc?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\""
			}	
			close $fid
			exec chmod 0755 "$tmp_dir/thread_aur_versions.sh"
			set error [catch {exec "$tmp_dir/thread_aur_versions.sh"}]

			file delete "$tmp_dir/thread_aur_versions.sh"
			
			if {$error == 0} {
				# read the results into a variable 
				set fid [open $tmp_dir/vpacman_aur_result r]
				gets $fid result
				close $fid
				# and delete the temporary file
				file delete $tmp_dir/vpacman_aur_result
				# split the result on each "\},\{"
				set result [regsub -all "\},\{" $result "\n"]
				set result [split $result "\n"]
				# and analyse each line
				foreach line $result {
					set index [string first "\"Name\":" $line]
					if {$index == -1} {
						set name ""
					} else {
						set position [expr $index + 8]
						set name [string trim [string range $line $position [expr [string first \" $line $position] - 1]] \"]
					}
					set index [string first "\"Version\":" $line]
					if {$index == -1} {
						set version ""
					} else {
						set position [expr $index + 11]
						set version [string trim [string range $line $position [expr [string first \" $line $position] - 1]] \"]
					}
					set index [string first "\"Description\":" $line]
					if {$index == -1 } {
						set description ""
					} else {
						set position [expr $index + 15]
						set description [string range $line $position [expr [string first \" $line $position] - 1]]
						set description [string map {"\\" ""} $description]
						set description [string trim $description \"]
					}
					set index [string first "\"URL\":" $line]
					if {$index == -1} {
						set url ""
					} else {
						set position [expr $index + 6]
						set url [string range $line $position [expr [string first \, $line $position] - 1]]
						regsub -all {\\} $url {} url
						set url [string trim $url \"]
					}
					set index [string first "\"LastModified\":" $line]
					if {$index == -1} {
						set updated ""
					} else {
						set position [expr $index + 15]
						set updated [string range $line $position [expr [string first \, $line $position] - 1]]
						set updated [clock format $updated -format "[exec locale d_fmt] %R"]
					}
					set index [string first "\"Depends\":" $line]
					if {$index == -1} {
						set depends ""
					} else {
						set position [expr $index + 11]
						set depends [string range $line $position [expr [string first \] $line $position] - 1]]
						set depends [string map {"\"" "" "," " "} $depends]
					}
					set index [string first "\"MakeDepends\":" $line]
					if {$index == -1} {
						set makedepends ""
					} else {
						set position [expr $index + 15]
						set makedepends [string range $line $position [expr [string first \] $line $position] - 1]]
						set makedepends [string map {"\"" "" "," " "} $depends]
					}
					set index [string first "\"Keywords\";" $line]
					if {$index == -1} {
						set keywords ""
					} else {
						set position [expr $index + 12]
						set keywords [string range $line $position [expr [string first \] $line $position] - 1]]
						set keywords [string map {"\"" "" "," " "} $keywords]
					}
					lappend aur_versions [list $name $version $description]
				}
				# aur_versions should now be a clean list of all the updates including all the local packages if requested
				eval [subst {thread::send -async $main_TID {::put_aur_versions [list $aur_versions]}}]
			} else {
				# aur_versions will be empty since this shell script threw an error
				# aur_versions will have to be updated by get_aur_updates
				eval [subst {thread::send -async $main_TID {::put_aur_versions "failed"}}]
			}
	    }
	    thread::wait
	}] 
	
	# create a thread to list the groups available
	# this thread will stop running after it has executed since it will not be needed again
	
	set list_groups_TID [thread::create {
	
		proc thread_list_groups {main_TID tmp_dir} {
			set list_groups "All\n[exec pacman -b $tmp_dir -Sg | sort -d]"
			eval [subst {thread::send -async $main_TID {::put_list_groups [list $list_groups]}}]
	    }
	    thread::wait
	}] 

	# create a thread to get the system data (sync)
	# this thread will keep running so that it can be used whenever it is needed
	
	set get_system_data_TID [thread::create {
	
		proc thread_get_system_data {main_TID tmp_dir} {
			set error [catch {exec pacman -b $tmp_dir -Si} result] 	
			eval [subst {thread::send -async $main_TID {::get_system_data [list $result]}}]
	    }
	    thread::wait
	}] 
	
	# create a thread to test the system state
	# this thread will keep running so that it can be used whenever it is needed
	
	set test_system_TID [thread::create {
	
		proc thread_test_system {main_TID} {
			set error [catch {exec pacman -Qu}] 
			set result "stable"
			if {$error == 0} {
				set result "unstable"
			}	
			eval [subst {thread::send -async $main_TID {::test_system [list $result]}}]
	    }
	    thread::wait
	}] 
	
puts $debug_out(1) "THREADS - completed threads set up -([expr [clock milliseconds] - $start_time])"

}

# START
# note: vpacman takes approx 200 milliseconds to compile to bytecode and start execution
set_clock false
.filter_upgrade configure -text [clock_format $update_time short_full]
# draw the screen now to make it appear as if it is loading faster and then run start to get the full list of packages
puts $debug_out(1) "START - window display - show first window, now update screen ([expr [clock milliseconds] - $start_time])"
# this update takes around 300 ms
# so the trade off is 600 ms to show a blank window and then 1200ms the populated window
# or around 1500ms to show a populated window

# just in case the window was iconified by the -h argument
wm deiconify .

# just in case the treeview widget is clicked on before it is populated
# set the treeview selected background to unselected
ttk::style map Treeview -background {selected #FFFFFF}

# save the list of repos for later
set list_repos [split [exec pacman-conf -l] \n]
# thread_get_aur_files, called from start, will fail if the databases are not present
check_repo_files $tmp_dir/sync db

# call start
start
# we do not need to run the filter/sort procedure here
# an update now would show the list counts in the window before showing the package list
list_show $list_all
# so we have an updated list - set filter_list to the new list
set filter_list $list_all

# just in case the treeview widget was clicked on before it was populated
# goto the first record
.wp.wfone.listview xview moveto 0
.wp.wfone.listview yview moveto 0
# clear any selections
all_clear
# reset the treeview selected background colour
ttk::style map Treeview -background {selected #4a6984}

if {$su_cmd == ""} {
	tk_messageBox -default ok -detail "Some commands cannot be run as root. Consider restarting as a standard user" -icon warning -message "Running vpacman as root is not recommended." -parent . -title "Warning" -type ok
}
if {!$threads} {
	tk_messageBox -default ok -detail "Some functions will be restricted e.g.:\n  files searches will exclude AUR packages.\n  AUR version lookup will be delayed.\n\nConsider installing a threaded version of tcl." -icon warning -message "Running tcl without threading." -parent . -title "tcl not threaded" -type ok
}

puts $debug_out(1) "START - window display complete - grab released ([expr [clock milliseconds] - $start_time])"
# select the download programme to use
# first check for a preference set in pacman.conf, otherwise prefer curl if it is installed
set dlprog [find_pacman_config dlprog]
if {$dlprog == "" || [catch {exec which $dlprog}] == 1} {
	if {[catch {exec which curl}] == 0} {
		set dlprog "curl"
	} elseif {[catch {exec which wget}] == 0} {
		set dlprog "wget"
	}
}
# this is pretty much impossible but check anyway
if {$dlprog == ""} {
	tk_messageBox -default ok -detail "No download programme found" -icon warning -message "Pacman cannot function without an installed download programme (curl or wget)." -parent . -title "Warning" -type ok
}
puts $debug_out(1) "START - download programme set to $dlprog ([expr [clock milliseconds] - $start_time])"
puts $debug_out(1) "START - threads is $threads ([expr [clock milliseconds] - $start_time])"
if {$threads} {
	puts $debug_out(1) "START (threads) called test_internet"
	if {[test_internet] == 0} {
		# if the internet is up then run the aur_versions thread to get the current aur_versions
		# this thread may conflict with get_aur_updates so mark it running and set an appropriate label
		set thread "running"
		if {$aur_all} {
			puts $debug_out(2) "START (threads) - configured text \"AUR/Local Packages (..)\""
			.filter_list_aur_updates configure -text "AUR/Local Packages (..)"
		} else {
			puts $debug_out(2) "START (threads) - configured text \"AUR/Local Updates (..)\""
			.filter_list_aur_updates configure -text "AUR/Local Updates (..)"
		}
		puts $debug_out(1) "START - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
		thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
	}
	# and the list_groups thread to find all of the groups available
	puts $debug_out(1) "START - call list_groups thread with main_TID and tmp_dir ([expr [clock milliseconds] - $start_time])"
	thread::send -async $list_groups_TID [list thread_list_groups [thread::id] $tmp_dir]
} else {
	puts $debug_out(1) "START - cannot run versions thread - threads not enabled"
	list_groups
}
# test the current configuration options
test_configs
puts $debug_out(1) "START - completed -([expr [clock milliseconds] - $start_time])"
