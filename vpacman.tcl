#! /usr/bin/wish

#	 This is Vpacman - a Graphical front end for pacman and the AUR
#
#    Copyright (C) 2018 - 2019  Andrew Myers <andrew dot myers@wanadoo dot fr>
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

set error [catch {package require Thread}]
if {$error} {
	set threads false
} else {
	set threads true
}

# save any arguments passed to vpacman
set args $argv
# save the new version number
set version "1.3.3"

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
if {[string first "restart" $args] == -1} {
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
global browser buttons editor geometry geometry_view helpbg icon_dir installed_colour keep_log outdated_colour save_geometry show_menu show_buttonbar terminal terminal_string
# ..variables
global about_text after_id anchor args aur_all aur_files aur_messages aur_only aur_updates aur_versions backup_log bubble colours count_all count_installed count_outdated count_uninstalled dbpath dlprog files_upgrade filter filter_list find findfile find_message findtype fs_upgrade geometry_config group group_index help_text index installed_colour known_browsers known_editors known_terminals list_all list_groups list_installed list_local list_local_ids list_outdated list_repos list_show list_show_ids list_show_order list_uninstalled listfirst listlast listview_current listview_last_selected listview_selected listview_selected_in_order local_newer message one_time outdated_colour package_actions part_upgrade select selected_list selected_message start_time state su_cmd sync_time system_test threads times tverr_message tverr_text upgrade_time upgrades upgrades_count version win_configx win_configy win_mainx win_mainy

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
# make the temporary directory if it does not already exist
file mkdir /tmp/vpacman
set tmp_dir /tmp/vpacman

# set other variables

# about text
set about_text "

<centre><strong>vpacman.tcl</strong>

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
# do we show the warning messages in get_aur_updates or not
set aur_messages "true"
# if only aur packages are listed then set aur_only to true
set aur_only false
# these are the aur packages which could be updated
set aur_updates ""
# the versions found for the aur packages by the thread get_aur_versions
set aur_versions ""
# keep a backup copy of the pacman log
set backup_log "yes"
# default browser
set browser ""
# toolbar button size
set buttons "medium"
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
# the path to the pacman sync databases
set dbpath "/var/lib/pacman"
# the programme to use for downloads
set dlprog ""
# set debug mode
# launch vpacman with no arguments to direct debug to stdout, use 'debug' to direct debug to a file in the home directory
set debug false
set debug_out stdout
# if we started in debug mode
if {[string first "debug" $args] != -1} {
	set debug true
	# if we restarted then append the debug messages to the debug file
	# otherwise start a new debug file
	if {[string first "restart" $args] != -1} {
		# re-open the debug file
		set debug_out [open "$home/vpacman_debug.txt" a]
		puts $debug_out "Restart called"
	} else {
		# remove any existing debug file
		file delete ${home}/vpacman_debug.txt
		# and start a new one
		set debug_out [open "$home/vpacman_debug.txt" w]
		puts $debug_out "Debug called"
	}
}
puts $debug_out "Debug set to $debug\nDebug out is $debug_out"
# default editor
set editor ""
# is it ok to skip a files database upgrade - 0 no, 1 yes.
set files_upgrade 0
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
set geometry_config "487x243"
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
	Tools:	<lm3>Full System Upgrade > The only supported method of updating outdated packages. It may be wise to check the latest news before performing a full system upgrade.</lm3>
			<lm3>Install > Ask pacman to install or reinstall the selected packages. Partial upgrades are not supported. AUR packages can only be updated one at a time.</lm3>
			<lm3>Delete > Ask pacman to delete the selected packages.</lm3>
			<lm3>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been made then the elapsed time shows the time since Vpacman was started.</lm3>
			<lm3>Check Config Files > Display a list of any configuration file which need to be dealt with. See \"https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave\"</lm3>
			<lm3>Clean Package Cache > Delete any superfluous packages from the pacman cache to release disk space. The default is to keep at least the most recent three versions of each package. Cleaning can optionally be restricted to uninstalled packages. (Requires paccache)</lm3>
			<lm3>Clean Pacman Log > Reduce the size of the pacman log by deleting old entries to release disk space. The default is to keep at least the most recent three days. Cleaning will always keep the entries for today. Optionally keep a backup copy of the old log file.</lm3>
			<lm3>Install AUR/Local > Install an AUR package by name or a local package file.</lm3>
			<lm3>Update Cups > Run cups_genppdupdate if necessary and restart cups. Use if gutenprint has been updated.</lm3> 
			<lm3>Options > Change any of the configurable options for Vpacman. Allows for editing the configuration file manually, which could break Vpacman! In case of problems delete the configuration file \"~/.vpacman.config\" to return all the values to default.</lm3>
	View:	<lm3>Latest News > Read the last year of news from archlinux.org</lm3> 
			<lm3>Pacman Configuration > View the the pacman configuration file.</lm3> 
			<lm3>Recent Pacman Log > Read the last 5000 entries in the pacman log file.</lm3> 
			<lm3>Hide Menubar > Hide the menu bar. Can be shown again using the right click menu in the Packages Window - see below.</lm3> 
			<lm3>Hide/Show Toolbar > Hide or show the tool bar</lm3> 
	Help:	<lm3>Help > This help message.</lm3>
			<lm3>About > Information about this programme.</lm3>
			
<strong>Tool Bar:</strong>
	<lm2>Full System Update > The only supported method of updating outdated packages. It may be wise to check the latest news before performing a full system upgrade.</lm2>
	<lm2>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been made then the elapsed time shows the time since Vpacman was started.</lm2>
	<lm2>Install > Ask pacman to install or update the selected packages. AUR packages can only be updated one at a time.</lm2>
	<lm2>Delete > Ask pacman to delete the selected packages.</lm2>
	<lm2>Find > Enter any string to search for in the list of packages displayed. The search will be carried out over all the fields of the packages listed, including the description but excluding the repository name. Click on the label \"Find\" to change to a search the package names only, click again to search for the packages providing a specified file. Enter the full path to the file to search for, and press return to start the search. On the first search during any day, a prompt will ask if the file database should be updated if necessary. Click on the label again to return to the \"Find\" option.</lm2>
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
	
	<lm2>Left-Click on any line to select that line. Left-Click a second time to de-select the line. Shift-click to select a range of lines, Control-click to add to a selection.</lm2>
	<lm2>Right-Click to bring up a menu similar to the tools menu above. If the menu bar has been hidden then the last item on the list will offer to show the menu bar again.</lm2>
	<lm2>Left-Click on a heading to sort the package list by that heading. Left-Click a second time to sort the list in reverse order.</lm2>
	<lm2>To aid in navigating the list there is a scroll bar at the right edge of the window. Since some of the lists displayed can be rather long a Right-Click on the scroll bar at any point will align the list to that point. Right-Click on the top arrow will display the top of the list, Right-Click on the bottom arrow will display the end of the list.</lm2>

<strong>Details Window:</strong>
	<lm2>Shows the requested information, according to the tab activated, about the latest package selected in the Packages Window.</lm2>
	
	<lm2>Much of the information is sourced from the internet, and retrieval may be slow as a result. In these cases a \"Searching\" message is displayed, and if no result is found an \"Error\" message will be displayed in the appropriate field. In such case - try again.</lm2>"
# list of known browsers
set known_browsers [list chromium dillo epiphany falkon firefox opera qupzilla]
# list of known terminals
set known_terminals [list {gnome-terminal} {--title <title> -- <command>} {konsole} {--title <title> -e <command>} {lxterminal} {--title <title> -e <command>} {mate-terminal} {--title <title> -e <command>} {qterminal} {-title <title> -e <command>} {roxterm} {--title <title> -e <command>} {vte} {--name <title> --command <command>} {xfce4-terminal} {--title <title> -e <command>} {xterm} {-title <title> -e <command>}]
# list of known_editors
set known_editors [list emacs nano vi vim]
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
# the order that the list_show is sorted into in the form
set list_show_order "Package increasing"
# the list of packages which have not been installed in the form
# Repo Package Version Available Group(s) Descrition
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
# the list of all the currently selected items in listview in the order that they were selected in the form
# id
set local_newer 0
# the number of newer AUR/Local packages identified to be upgraded
set index 0
# message to be shown in the button bar near the top of the window
set message ""
# show message one_time
set one_time "true"
# list of updated packages which may require further actions
set package_actions [list "linux" "Linux was updated, consider rebooting" "gutenprint" "Gutenprint was installed or updated, consider running Tools > Update cups" "pacman-mirrorlist" "Pacman-mirrorlist was updated, consider running Tools > Check Config Files for advice on how to update the mirrorlist"]
# is it ok to run a partial upgrade- 0 no, 1 yes.
set part_upgrade 0
# have we agreed to select all the packages 
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
# the result of the last test system
set system_test "stable"
# default terminal
set terminal ""
# threads: is tcl threaded, true or false
# a list of times returned by get_sync_times - sync_time and update_time
set times ""
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
if { [exec id -u] eq 0 } {
	set su_cmd ""
# if not root then do we have sudo privileges without a password
} else {
	set error [catch {exec sudo -n true} result]
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
		set fid [open "| sudo -v -p \"\""]
		# close the channel
		set error [catch {close $fid} result]
		# what was the result?
		puts $debug_out "sudo -v was run with result $result"
		if {[string first "may not run sudo on" $result] == -1} {set su_cmd "sudo"}
		# otherwise just use the default
	}
}
puts $debug_out "Test complete - su command is $su_cmd"
# only certain commands will need elevated privileges. Since we are running all commands in a terminal session 
# we can ask for a password in that session if necessary
# so there really is no need to use a graphical su command.

puts $debug_out "Version $version: User is $env(USER) - Home is $home - Config file is $config_file - Programme Directory is $program_dir - Su command is set to $su_cmd"

# PROCEDURES

# proc all_clear
# 	Clear all of the items shown in the treeview widget
# proc all_select
# 	Select all of the items shown in the treeview widget
# proc aur_install
#	Install an AUR/Local package
# proc aur_upgrade
# 	Upgrade a given AUR package
## The following procedures create help messages invoked when the cursor hovers over a widget.
# proc balloon {target message {cx 0} {cy 0} } 
# proc balloon_set {target message}
# proc balloon_unset
##
# proc check_config_files
#	Check for any existing configurations files that have not been dealt with
# proc clean_cache
# 	Clean unnecessary files from the pacman cache
# proc cleanup_checkbuttons {aur} 
#	After a filter checkbutton is selected return the necessary variables to sane settings, 
#		set aur_only to the value requested. Reset the list checkbutton titles. 
# proc clock_format
# format a time according to the format requested
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
# proc get_aur_updates
#	Find local files which may need to be updated or may not be found amongst the AUR packages
# proc get_aur_version {package} 
#	Procedure to find the current available aur version and description. Relies on the correct aur version being shown in the aur data.
# proc get_aur_versions 
#	Procedure to find the current available aur version and description for all the list_local packages.
# proc get_configs
#	Read the configuration variables from the configuration file (
# proc get_dataview {current}
#	Get the information required, depending on the active tab in the dataview notebook. Since some of the details
#		can take a while to retrieve, show a searching message where necessary.
# proc get_file_mtime
# 	Get the  last modified time for a set of files
# proc get_sync_time
#	Get the last sync time, the list of repositories and check that the temporary database is up to date.
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
##
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
# proc read_config
#	Read the pacman configuration file and display it. 
# proc read_help
# 	Display the help text
# proc read_log
#	Find the pacman log file and display it. Warn if the log file is too big. 
# proc read_news
#	Try to downlaod and parse the arch news rss, and display it. If not possible then browse to the web page
# proc set_clock
#	Calculate the elapsed time since the last significant event, the e-time, which is set at the start of the programme, 
#		or the last sync event. Displays and updates the elapsed time at the foot of the window.
# proc set_images
#	Set up the images for use in the toolbar and other widgets
# proc set_message {type text}
#	Displays a message in the message area at the top of the window. The type influences whether the messge 
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
# proc test_configs
#	Test the current configuration options are sane, if not, reset to a default setting as necessary.
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
# proc trim_log
# 	clean the pacman log keeping the last keep_log days and, optionally, a backup of the current log
# proc update_cups
# 	if gutenprint is installed run cups-genppdupdate to update ppds - restart cups
# proc update_db
#   copies the pacman sync database into the temporary directory
# proc view_text
#	open a window and display some text in it
# proc view_text_codes
#   read through some text and replace a set of codes with a given tag

proc all_select {} {

global debug_out list_show_ids select tvselect
# select all the items in listview

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
	set tvselect ""
	puts $debug_out "all_select - set selection to $list_show_ids"
	.wp.wfone.listview selection add $list_show_ids
	# bind TreeviewSelect will update all the variables when the selection changes
	vwait tvselect
	return 0
}

proc all_clear {} {
	
global debug_out listview_selected part_upgrade select tvselect
# clear all the items selected in listview

	puts $debug_out "all_clear started"
	set select false
	set tvselect ""
	.wp.wfone.listview selection remove $listview_selected
	# bind TreeviewSelect will update all the variables when the selection changes
	vwait tvselect
	puts $debug_out "all_clear completed - partial upgrades set to no"
	set part_upgrade 0
}

proc aur_install {} {
	
global debug_out filename list_local package win_mainx win_mainy

# open a window to ask for a AUR package name to install or browse for a local package

	set filename ""
	set package ""
	
	toplevel .aurinstall
	
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {323 / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {170 / 2}]
	wm geometry .aurinstall 323x170+$left+$down
	wm iconphoto .aurinstall tools
	wm protocol .aurinstall WM_DELETE_WINDOW {
		# assume cancel clean_cache, see button .aurinstall.cancel
		.aurinstall.cancel invoke
	}
	wm resizable .aurinstall 0 0
	wm title .aurinstall "Install AUR/Local Package"
	wm transient .aurinstall .

# CONFIGURE CLEAN CACHE WINDOW

	label .aurinstall.package_label \
		-text "AUR Package Name"
	entry .aurinstall.package \
		-borderwidth 0 \
		-textvariable package 
		
	bind .aurinstall.package <Return> {.aurinstall.install invoke}
	
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
				 {{Packages}       {.pkg.tar.xz}        }
			}
			# and set a title for the window
			set title "Vpacman : Browse"
			# try to enlarge the window, this could cause a flicker in the window, but there is 
			# no other way to control the geometry of the tk_getOpenFile when it is created
			after 100 {exec wmctrl -r $title -e 0,-1,-1,600,350}
			# now browse for a file
			set filename [tk_getOpenFile -filetypes $types -title $title]
			if {$filename != ""} {
				set package [string range [file tail $filename] 0 [string first ".pkg.tar.xz" [file tail $filename]]-1] 
			} 
		} \
		-text "Browse" \
		-width 8

	frame .aurinstall.buttons

		button .aurinstall.install \
			-command {
				if {$filename != ""} {
					puts $debug_out "aur_install - install file $filename"
					grab release .aurinstall
					destroy .aurinstall
					puts $debug_out "aur_install - call aur_upgrade with file \"$filename\" and type \"install\""
					aur_upgrade $filename "install"
				} elseif {$package != ""} {
					puts $debug_out "aur_install - install package $package"
					grab release .aurinstall
					destroy .aurinstall
					puts $debug_out "aur_install - call aur_upgrade with package \"$package\" and type \"local\""
					aur_upgrade $package "aur"
				}
			} \
			-text "Install"
		button .aurinstall.cancel \
			-command {
				grab release .aurinstall
				destroy .aurinstall
			} \
			-text "Cancel"

	# Geometry management

	grid .aurinstall.package_label -in .aurinstall -row 2 -column 2 \
		-sticky w
	grid .aurinstall.package -in .aurinstall -row 2 -column 4 \
		-sticky e
	grid .aurinstall.browse_label -in .aurinstall -row 3 -column 2 \
		-columnspan 3 \
		-sticky we
	grid .aurinstall.browse -in .aurinstall -row 4 -column 2 \
		-columnspan 3 
	grid .aurinstall.buttons -in .aurinstall -row 5 -column 1 \
		-columnspan 5 \
		-sticky we
	grid .aurinstall.install -in .aurinstall.buttons -row 1 -column 1 \
		-sticky w
	grid .aurinstall.cancel -in .aurinstall.buttons -row 1 -column 2 \
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
	grid columnconfigure .aurinstall 5 -weight 0 -minsize 15 -pad 0
	
	grid rowconfigure .aurinstall.buttons 1 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.buttons 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .aurinstall.buttons 2 -weight 1 -minsize 0 -pad 0
	
	balloon_set .aurinstall.package_label "The name of an AUR package to install"
	balloon_set .aurinstall.package "The name of an AUR package to install"
	balloon_set .aurinstall.browse "Browse to a local file to install"
	balloon_set .aurinstall.install "Install the package now"
	balloon_set .aurinstall.cancel "Cancel - do not install any package"

	grab set .aurinstall
	focus .aurinstall.package
	
}

proc aur_upgrade {package type} {

global aur_versions_TID debug debug_out dlprog editor geometry list_all list_local listview_last_selected listview_selected listview_selected_in_order program_dir save_geometry selected_list start_time su_cmd terminal_string threads tmp_dir	
# download and install or upgrade a package from AUR/Local
# known types are: 
#	upgrade (upgrade a selected AUR/Local package), only existing AUR packages can be upgraded - called by invoking .buttonbar.install_button with aur_only
# 	install (install a local package from a filename), could apply to an install, upgrade or downgrade of any package - called by proc aur_install
#	aur (install, reinstall or upgrade an AUR package) - called by proc aur_install

# if the package directory exists then it may have been the result of an aborted upgrade from before
# so we will leave the partial/completed upgrades until we close 
# otherwise we would need to force the upgrade, which would be messy and dangerous	

# this may not work if we are running as root

	puts $debug_out "aur_upgrade called with type \"$type\" and package \"$package\""
	
	set found ""
	set available_version ""
	set current_version ""
	set install_version ""
	set package_type "none"
	set vstate "install"
	
	if {$type == "install"} {
		# this is a local package to install so parse the filename and get the package name and the install version
		set filename $package
		set elements [split [file tail $package] "-"]
		set arch [lindex $elements end]
		set install_version [string map {\  -} [lrange $elements end-2 end-1]]
		set package [file rootname [string map {\  -} [lrange $elements 0 end-3]]]
		puts $debug_out "aur_upgrade - install $package using $filename"
	}
	
	# does the package exist in list_local, if not does it exist in list_all
	set found [lsearch -nocase -index 1 -all -inline $list_local $package] 
	if {$found != ""} {
		puts $debug_out "aur_upgrade - found $package in list_local"
		# this is an AUR/Local package
		set package_type "aur_local"
	} else {
		set found [lsearch -nocase -index 1 -all -inline $list_all $package]
		if {$found != ""} {
			puts $debug_out "aur_upgrade - found $package in list_all"
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
			set available_version [string trimleft $available_version {*}]
###
			puts $debug_out "aur_upgrade - $package has been installed"
			puts $debug_out "aur_upgrade - The current version is $current_version, the version available is $available_version and the version to install is $install_version"
			# the package was found in one of the lists, then the package_type is either 'aur_only' or 'repo'
			# if the type is install then there will be an install_version available
			
			# types are install upgrade or aur
			# if the available version is the same as the current version then the package is already up to date (indate)
			# if the available version is greater than the current version, then the package could be upgraded (outdate)
			# if the type is install then if the install version is less than the current version then the package will be downgraded (downdate)
			if {$type == "install"} {
				set result [test_versions $current_version $install_version]
			} else {
				set result [test_versions $current_version $available_version]
			}
			puts $debug_out "aur_upgrade - test_version returned $result"
			switch $result {
				same {
					puts $debug_out "\tand is up to date"
					set vstate "indate"
				}
				newer {
					puts $debug_out "\tand is marked to upgrade"
					set vstate "outdate"
				}
				older {
					puts $debug_out "\tand the installed version is already newer"
					set vstate "downdate"
				}
			}
				
		} else {
			puts $debug_out "aur_upgrade - $package has not been installed"
		}
	} else {
		puts $debug_out "aur_upgrade - $package is not in the installed aur/local packages or in the repos"
	}
	
	puts $debug_out "aur_upgrade - now check the package_type \"$package_type\""	
	switch $package_type {
		"none" {
			puts $debug_out "aur_upgrade - $type called for $package which is not in list_local or in the repos"
			# could be installed if it is type "aur" and exists in AUR
			# or if it is a local package of type "install"
			# we can use get_aur_version to check that the package name exists in AUR
			# check if the package exists in AUR
			set result [get_aur_version $package]
			set version [lindex $result 0]
			set description [lindex $result 1]
			if {$version == "" && $description == ""} {
				puts $debug_out "aur_upgrade - $package not found in AUR"
				if {$type != "install"} {
					puts $debug_out "aur_upgrade - $package is not type $install - return error"
					set_message terminal "ERROR - the package \"$package\" was not found in AUR"
					after 5000 {set_message terminal ""}
					return 1
				}
				puts $debug_out "aur_upgrade - $package is a local package to install"
			}
			puts $debug_out "aur_upgrade - ok - install $package"
		}
		"aur_local" {
			puts $debug_out "aur_upgrade - $type called for $package which is already installed in list_local"
			# type upgrade - will upgrade or reinstall which is fine (but can only apply to packages in AUR)
			# type aur - will do the same as upgrade (can only apply to packages in AUR)
			if {$type == "upgrade" || $type == "aur"} {
				# check if the package exists in AUR
				set result [get_aur_version $package]
				set version [lindex $result 0]
				set description [lindex $result 1]
				if {$version == "" && $description == ""} {
					puts $debug_out "aur_upgrade - $package not found in AUR"
					set_message terminal "ERROR - the package \"$package\" was not found in AUR"
					after 5000 {set_message terminal ""}
					return 1
				}
				puts $debug_out "aur_upgrade - $type called for $package which exists in AUR"
			}
			# type install - could be an upgrade, downgrade or re-install of the package filename
			puts $debug_out "aur_upgrade - ok - install $package"
		}
		"repo" {
			puts $debug_out "aur_upgrade - $type called for $package which is $vstate and is already available in the repos"
			# aur and upgrade types only apply to aur packages
			# it is not wise to install a repo package here because it might break the system
			# so we can only downdate a repo package at present
			if {$type == "install" && $vstate == "downdate"} {
				puts $debug_out "aur_upgrade - ok - install $package"
			} elseif {$type == "install" && ($available_version != $install_version)} {
				puts $debug_out "aur_upgrade - ok for minor update - install $package"
			} else {
				puts $debug_out "aur_upgrade - cannot - install or upgrade $package here, it is in the repos"
				set ans [tk_messageBox -default ok -detail "\"$package\" cannot be installed or upgraded from here. Select All and Find the package in the list presented." -icon info -message "\"$package\" already exists in the repositories" -parent . -title "Install/Upgrade \"$package\"" -type ok]
				return 1
			}
		}
		
	}
	puts $debug_out "aur_upgrade - passed tests, check state of package $package (type is $type, vstate is $vstate)"

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
	
	# do not ask for confirmation if the type is "upgrade" or this is a straight "install" where any false options have already been disallowed
	if {($type != "upgrade" && $title != "install") || $title == "downgrade"} {
		set tk_message "Do you want to $title \"$package\"?"
		if {$title == "downgrade"} {set detail [concat $detail " and is newer"]}
		set ans [tk_messageBox -default yes -detail $detail -icon info -message $tk_message -parent . -title "[string totitle $title] \"$package\"" -type yesno]
		 
		if {$ans == "no"} {
			return 1
		}
	}

	# Create a download directory in the tmp directory
	puts $debug_out "aur_upgrade - make sure that $tmp_dir/aur_upgrades exists"
	file mkdir "$tmp_dir/aur_upgrades"
	
	if {$type != "install" && [file isdirectory "$tmp_dir/aur_upgrades/$package"] == 1} {
		# Unless this is install a filename then if the directory already exists, then the process has been run before.
		# This could be fine as long as the package was not built.
		puts $debug_out "aur_upgrade - WARNING - $tmp_dir/aur_upgrades/$package already exists"
		# test for a pkg file, sort any files found and pick the last one 
		set filename [lindex [lsort [glob -nocomplain -directory $tmp_dir/aur_upgrades/$package *.pkg.tar.xz]] end]
		puts $debug_out "aur_upgrade - glob returned $filename"
		if {$filename != ""} {
			# this will cause a failure with "==> ERROR: A package has already been built."
			puts $debug_out "aur_upgrade - WARNING - $filename already exists"
			set ans [tk_messageBox -default yes -detail "Do you want to rebuild the package?\n   Answer Yes to continue\n   Answer No to reinstall $package" -icon warning -message "A package has already been built." -parent . -title "Warning" -type yesnocancel]
		 
			if {$ans == "yes"} {
				file delete "$filename"
			} elseif {$ans == "no"} {
				set type "install"
			} else {
				return 1
			}
		}
	}
	
	set logfile [find_pacman_config logfile]
	set logfid [open $logfile r]
	seek $logfid +0 end
	puts $debug_out "aur_upgrade - opened the pacman logfile ($logfile) and moved to the end of the file"

	# write a shell script to install or upgrade the package
	puts $debug_out "aur_upgrade - Create a shell script to install or upgrade $package"
	# tidy up any leftover files (which should not exist)
	puts $debug_out "\tdelete $tmp_dir/vpacman.sh"
	file delete "$tmp_dir/vpacman.sh"
	
	puts $debug_out "\twrite new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	puts $fid "cd \"$tmp_dir/aur_upgrades\""
	if {$type != "install"} {
		# download the AUR file to install or upgrade
		puts $fid "echo \"\nDownload $package snapshot\n\""
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
			puts $fid "makepkg -sci"
		} else {
			puts $fid "echo -e \"\n$ makepkg -sc \n\""
			puts $fid "if makepkg -sc ; then"
			puts $fid "\techo -e \"\nInstalling $package using pacman -U  \n\""
			puts $fid "\tsu -c \"pacman -U $package\*.pkg.tar.xz\""
			puts $fid "fi"
		}
	} else {
		puts $fid "echo -e \"\nInstalling $filename using pacman -U  \n\""
		if {$su_cmd != "su -c"} {
			puts $fid "$su_cmd pacman -U $filename"
		} else {
			puts $fid "su -c \"pacman -U $filename\""
		}
	}
	if {$type == "upgrade"} {
		set action "Upgrade AUR Package"
		puts $fid "echo -ne \"\nUpgrade $package finished, press ENTER to close the terminal.\""
	} elseif {$type == "aur" || $type == "install"} {
		puts $fid "echo -ne \"\nInstall [string range [file tail $package] 0 [string first ".pkg.tar.xz" [file tail $package]]-1] finished, press ENTER to close the terminal.\""
		set action "Install Local Package"
	} elseif {$type == "reinstall"} {
		puts $fid "echo -ne \"\nReinstall $package finished, press ENTER to close the terminal.\""
		set action "Reinstall AUR Package"
	} else {
		
	}
	puts $fid "read ans"
	puts $fid "exit" 
	close $fid
	puts $debug_out "aur_upgrade - change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out "aur_upgrade - call set_message - type terminal, \"TERMINAL OPENED to run $action\""
	set_message terminal "TERMINAL OPENED to run $action"
	# stop the exit button working while the terminal is opened
	set_wmdel_protocol noexit
	update idletasks
	puts $debug_out "aur_upgrade - execute $tmp_dir/vpacman.sh"
	eval [concat exec $execute_string &]
	# wait for the terminal to open
	execute_terminal_isopen $action
	puts $debug_out "\taur_upgrade - command started in terminal"
	# place a grab on something unimportant to avoid random button presses on the window
	grab set .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> "catch {exec wmctrl -R \"$action\"}"
		update idletasks
	puts $debug_out "aur_upgrade - set grab on .buttonbar.label_message"
	# wait for the terminal to close
	execute_terminal_isclosed $action "Vpacman"
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out "aur_upgrade - Grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out "aur_upgrade - Window manager delete window re-instated"
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	set_message terminal ""
	update
	
	# read the rest of the logfile
	# writing the logfile should be quick this time because there should only be a few lines
	set logtext [read $logfid]
	close $logfid
	puts $debug_out "aur_upgrade - completed and logged these events ([expr [clock milliseconds] - $start_time]):"
	puts $debug_out "$logtext"
	if {$logtext == ""} {
		puts $debug_out "aur_upgrade - nothing was logged so nothing happened - return"
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
	
	puts $debug_out "aur_upgrade - Upgraded $count_upgrades, Downgraded $count_downgrades, Installed $count_installs, Reinstalled $count_reinstalls"	
	
	# and decide what is necessary to do 
	set restart false
	switch $vstate {
		indate {
			if {$count_reinstalls == 1} {
				puts $debug_out "aur_upgrade - Reinstall succeeded"
				set result "success"
			} else {
				puts $debug_out "aur_upgrade - Reinstall failed"
				set result "failed"
			}
		}
		outdate {
			if {$count_upgrades == 1} {
				puts $debug_out "aur_upgrade - Upgrade succeeded"
				set result "success"
			} else {
				puts $debug_out "aur_upgrade - Upgrade failed"
				set result "failed"
			}
		}
		downdate {
			if {$count_downgrades == 1} {
				puts $debug_out "aur_upgrade - Downgrade succeeded"
				set result "success"
			} else {
				puts $debug_out "aur_upgrade - Downgrade failed"
				set result "failed"
			}
		}
		default {
			if {$count_installs == 1} {
				puts $debug_out "aur_upgrade - Install succeeded"
				set result "success"
			} else {
				puts $debug_out "aur_upgrade - Install failed"
				set result "failed"
			}
		}
		
	}	

	if {$vstate == "indate" || $result == "failed"} {
		puts $debug_out "\tPackage was indate ($vstate) or the result was failed ($result)"
		# the local database will still be up to date
		# if we only did a reinstall then there is nothing to do
	} else {
		# the local database will need to be updated
		# delete the contents from  listview, proc start will run and bind TreeviewSelect
		# will update all the variables when the selection changes
		puts $debug_out "\tPackage was not indate ($vstate) and result was success ($result) so delete listview contents"
		.wp.wfone.listview delete [.wp.wfone.listview children {}]
		update
		puts $debug_out "\tSet restart true"
		# the counts and lists will need to be updated
		set restart true
	}
	# check that vpacman was not updated, if it was then restart it
	# it is not likely that it would be re-installed here (since it is running) but the upgrade may have been aborted
	if {$package == "vpacman" && $result == "success"} {
		set tk_message "updated"
		if {$vstate == "downdate"} {set message "downgraded"}
		tk_messageBox -default ok -detail "vpacman will now restart" -icon info -message "vpacman was $tk_message" -parent . -title "Further Action" -type ok
		if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]; put_configs}
		puts $debug_out "aur_upgrade - restart called after vpacman update"
		close $debug_out
		if {$debug} {
			exec $program_dir/vpacman.tcl debug restart &
		} else {
			exec $program_dir/vpacman.tcl restart &
		}
		exit
	}
	# switch to aur_updates if required (do we want to include all local packages as well?)
	if {$package_type == "aur_local" || $package_type == "none"} {
		puts $debug_out "aur_upgrade - $package is either AUR or local, so switch to AUR/Local if not already selected"
		set selected_list "aur_updates"
		set filter 0
	}
	# now update all the lists if we need to
	# if we did a local install using "pacman -U" then we do not know the result, so restart anyway
	if {$restart} { 
		puts $debug_out "aur_upgrade - call start for type $type"
		# start will rewrite .wp.wfone.treeview and reset listview_selected
		# we need to remove the prior selection and the selection order
		set listview_last_selected ""
		set listview_selected_in_order ""
		# call start
		start
		if {$package_type == "aur_local" || $package_type == "none"} {
			puts $debug_out "aur_upgrade - $package is aur_local or none, so do not call aur_versions_thread now, leave it to get_aur_versions when it is called by get_aur_updates"
			set aur_versions ""
			get_aur_updates
		} else { 
			if {$threads && [test_internet] == 0} {
				# now run the aur_versions thread to get the current aur_versions
				puts $debug_out "Call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
				thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
			}
		}
		filter
	} else {
		# otherwise just run filter
		puts $debug_out "aur_upgrade - restart not required"
		filter
	}
	puts $debug_out "aur_upgrade command - completed ([expr [clock milliseconds] - $start_time])"
}

# SET UP BALLOON HELP
# Copyright (C) 1996-1997 Stewart Allen
# 
# This is part of vtcl source code
# Adapted for general purpose by 
# Daniel Roche <dan@lectra.com>
# version 1.1 ( Dec 02 1998 )

proc balloon {target message {cx 0} {cy 0} } {

global bubble helpbg

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
            -bg $helpbg -padx 2 -pady 0 -anchor w
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

global debug_out start_time su_cmd
# check /etc and /usr/bin for any configuration files which need to be updated

	puts $debug_out "check_config_files - called ([expr [clock milliseconds] - $start_time])"
	set config_files ""
	set files ""
	set lf ""
	set_message terminal "Checking for config files..." 
	update
	if {[catch {exec which find}] == 1} {
		tk_messageBox -default ok -detail "Consider installing the findutils package" -icon info -message "The find command is required." -parent . -title "Cannot Check Config Files" -type ok
		return 1
	}
	set error [catch {exec find /etc /usr/bin \( -name *.pacnew -o -name *.pacsave \) -print} files]
	foreach file [split $files \n] {
		if {[string first "Permission denied" $file] == -1} {
			set config_files [append config_files $lf $file]
			set lf "\n\t"
		}
	}
	set_message terminal ""
	if {$config_files == ""} {
		puts $debug_out "check_config_files - no files found to update ([expr [clock milliseconds] - $start_time])"	
		set_message terminal "No configuration files found to check"
		after 3000 {set_message terminal ""}
	} else {
		puts $debug_out "check_config_files - found files to update: $config_files ([expr [clock milliseconds] - $start_time])"	
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
	}
}

proc clean_cache {} {
	
global clean_uninstalled debug_out keep_versions su_cmd win_mainx win_mainy
# clean the pacman cache keeping the last keep_versions package versions and, optionally, remove the uninstalled packages
	
	puts $debug_out "clean-cache - called"
	if {[catch {exec which paccache}] == 1} {
		puts $debug_out "clean-cache - failed, paccache is not installed"
		tk_messageBox -default ok -detail "Consider installing the pacman-contrib package" -icon info -message "Paccache is required to clean the package cache" -parent . -title "Cannot Clean Package Cache" -type ok
		return 1
	}

	set clean_uninstalled "no"
	set keep_versions 3
	
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
		-textvariable keep_versions \
		-validate key \
		-validatecommand {expr {[string is integer %P] && [string length %P] < 4}} \
		-width 3
	label .clean.uninstalled_label \
		-text "Only target uninstalled packages"
	label .clean.yes_no \
		-anchor center \
		-background white \
		-justify center \
		-relief sunken \
		-textvariable clean_uninstalled \
		-width 3
	# now set up a binding to toggle the value of the clean_uninstalled variable
	bind .clean.yes_no <ButtonRelease-1> {
		if {[string tolower $clean_uninstalled] == "yes"} {
			set clean_uninstalled "no"
		} else {
			set clean_uninstalled "yes"
		}
	}
	
	frame .clean.buttons

		button .clean.continue \
			-command {
				puts $debug_out "clean-cache - clean called with $keep_versions versionsto keep and clean_uninstalled set to $clean_uninstalled"
				if {$keep_versions == "" || [string is integer $keep_versions] == 0} {
					# check that keep_versions is a numerical value
					puts $debug_out "clean_cache - keep_versions is set to \"$keep_versions\" which is not a numerical value"
					tk_messageBox -default ok -detail "The versions to keep must be a numerical value.\nThe number of versions to keep has not been changed" -icon warning -message "Error in number of cached versions to keep" -parent . -title "Incorrect Option" -type ok 
					puts $debug_out "clean_cache - reset the keep_versions value to 3"
					set keep_versions 3
				} else {
					set ans "ok"
					if {$keep_versions == 0 && $clean_uninstalled == "no"} {
						# check that zero keep_versions is correct
						puts $debug_out "clean_cache - keep_versions is set to \"$keep_versions\" is this correct"
						set ans [tk_messageBox -default cancel -detail "The versions to keep is set to zero. This will clear all packages from the package cache\nIs this correct?" -icon warning -message "Zero cached versions to keep" -parent . -title "Clear Package Cashe" -type okcancel]
					}
					if {$ans == "cancel"} {
						puts $debug_out "clean_cache - reset the keep_versions from zero value to 3"
						set keep_versions 3
					} else {
						if {$clean_uninstalled == "no"} {
							set args "-rk${keep_versions}"
						} else {
							set args "-ruk${keep_versions}"
						}
						puts $debug_out "clean-cache - clean attempted with paccache $args"
						if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
							# looks like we need to run this command in a terminal
							puts $debug_out "clean_cache ran paccache in a terminal"
							set action "Clean package cache"
							if {$su_cmd == "su -c"} {
								set command "$su_cmd \"paccache $args\""
							} else {
								set command "$su_cmd paccache $args"
							}
							set wait true
							execute_command $action $command $wait	
						} else {
							set error [catch {eval [concat exec $su_cmd paccache $args]} result]
							puts $debug_out "clean_cache called with Error $error and Result $result"
							if {$error != 0} {
								set_message terminal "Paccache returned an error cleaning cache"
							} else {
								if {$result == "==> no candidate packages found for pruning"} {
									set_message terminal "No packages found for pruning"
								} else {
									set result [split $result \n]
									if {[llength $result] > 1} {set result [lindex $result [llength $result]-1]}
									set_message terminal "Cleaned cache [string range $result 14 end]"
								}
							}
						}
						after 3000 {set_message terminal ""}
						grab release .clean
						destroy .clean
					}
				}
			} \
			-text "Continue"
		button .clean.cancel \
			-command {
				set keep_log 3
				grab release .clean
				destroy .clean
			} \
			-text "Cancel"

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
	grid .clean.cancel -in .clean.buttons -row 1 -column 2 \
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
	
	balloon_set .clean.keep_label "The number of versions of each package to keep"
	balloon_set .clean.keep "The number of versions of each package to keep"
	balloon_set .clean.uninstalled_label "Remove all versions of packages that have been uninstalled"
	balloon_set .clean.yes_no "Remove all versions of packages that have been uninstalled"
	balloon_set .clean.continue "Clean the package cache"
	balloon_set .clean.cancel "Cancel - do not clean the package cache"

	grab set .clean
	
}

proc cleanup_checkbuttons {aur} {

global aur_only selected_list list_show_order

	set aur_only $aur
	.wp.wfone.listview configure -selectmode extended
	set selected_list 0
	grid_remove_listgroups
	.filter_list_orphans configure -text "Orphans"
	.filter_list_not_required configure -text "Not Required"
	if {$aur_only == false} {
		.menubar.edit entryconfigure 0 -state normal
		.listview_popup entryconfigure 3 -state normal
	}
}

proc clock_format {time format} {

global debug_out
# format a time according to the format called

	switch $format {
		full {set result [clock format $time -format "%Ec"]}
		short_full {set result [clock format $time -format "[exec locale d_fmt] %R"]}
		date {set result [clock format $time -format "[string map {y Y} [exec locale d_fmt]]"]}
		short_date {set result [clock format $time -format "[exec locale d_fmt]"]}
		time {set result [clock format $time -format "%H:%M"]}
		default {set result [clock format $time -format "[exec locale d_fmt] %R"]}
	}
	return $result
}

proc configurable {} {
# Set configurable variables to sane values

global aur_all browser buttons debug_out editor geometry geometry_view helpbg icon_dir installed_colour keep_log known_browsers known_editors known_terminals one_time outdated_colour save_geometry show_menu show_buttonbar terminal terminal_string

	puts $debug_out "Set configurable variables"
	# initialize the browser variable to the first browser in the common browsers list which is installed
	configurable_default "browser" $known_browsers
	# initialize the editor variable to the first editor in the common editors list which is installed
	configurable_default "editor" $known_editors
	# initialize the terminal variables to the first terminal in the known terminals which is installed
	configurable_default "terminal" $known_terminals 
	
	# do not show all aur/local packages
	set aur_all false
	# set the size of the icons used for the buttons
	set buttons medium
	# set the icon directory
	set icon_dir "/usr/share/pixmaps/vpacman"
	# set the number of days to keep when trimming the pacman log file
	set keep_log 31
	# set geometry to a sane size
	set geometry "1060x500+200+50"
	set geometry_view "750x350+225+55"
	# save the geometry - yes or no
	set save_geometry "no"
	# set colours to acceptable values
	set helpbg #EBE8E4	
	set installed_colour blue
	set outdated_colour red
	# set the number of days to keep in the log file
	set keep_log 31
	# set the show message one_time to false
	set one_time false
	# show the menu and/or toolbar - yes or no
	set show_menu "yes"
	set show_buttonbar "yes"
}

proc configurable_default {variable list} {
# initialize a configurable variable to the first item in the known variables list which is installed
	
global browser debug_out editor terminal terminal_string
	
	puts $debug_out "configurable_default - check default for $variable"
	if {$variable == "terminal"} {
		set terminal ""
		set terminal_string ""
		foreach {programme string} $list {
			set result [catch {exec which $programme}]
			if {$result == 0} {
				set terminal "$programme"
				set terminal_string "$programme $string"
				break
			}
		}
		puts $debug_out "configurable_default - terminal set to \"$terminal\""
	} else {
		if {$variable == "browser"} {
			set browser ""
		} else {
			set editor ""
		}
		foreach programme $list {
			set result [catch {exec which $programme}]
			if {$result == 0} {
				switch $variable {
					browser {set browser "$programme"}
					editor {set editor "$programme"}
				}
				break
			}
		}
		if {$variable == "browser"} {
			puts $debug_out "configurable_default - browser set to \"$browser\""
		} else {
			puts $debug_out "configurable_default - editor set to \"$editor\""
		}
	}
	return 0
}

proc configure {} {

global browser buttons config_file debug_out editor geometry geometry_config geometry_view icon_dir installed_colour keep_log known_terminals old_values outdated_colour terminal terminal_string save_geometry win_configx win_configy win_mainx win_mainy

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
	lappend old_values $buttons $browser $editor $geometry $geometry_config $save_geometry $terminal $terminal_string $installed_colour $outdated_colour $icon_dir $keep_log
	set new_terminal $terminal
	
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
	puts $debug_out "configure - Known terminals $tlist1"
	puts $debug_out "configure - Known terminal strings $tlist2"
	puts $debug_out "configure - Current terminal is $terminal - new terminal is $new_terminal"

# CONFIGURE OPTIONS WINDOW

	label .config.browser_label \
		-text "Browser"
	entry .config.browser \
		-textvariable browser
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
	puts $debug_out "configure - Background colour for normal Combobox is $background_colour"
	puts $debug_out "configure - Foreground colour for normal Combobox is $foreground_colour"
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
		set terminal_string [get_terminal_string $terminal]
	}
	bind .config.terminal <FocusOut> {
		set terminal_string [get_terminal_string $terminal]
	}
	bind .config.terminal <<ComboboxSelected>> {
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
			# may be the configuration file has been edited
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
			set tests 0
			if {$browser != "" && [catch {exec which $browser}] == 1} {
				tk_messageBox -default ok -detail "\"$browser\" is not installed" -icon warning -message "Choose a different browser" -parent . -title "Incorrect Option" -type ok 
				focus .config.browser
				set tests 1
			}
			if {$editor != "" && [catch {exec which [lindex $editor 0]}] == 1} {
				tk_messageBox -default ok -detail "\"[lindex $editor 0]\" is not installed" -icon warning -message "Choose a different editor" -parent . -title "Incorrect Option" -type ok 
				focus .config.editor
				set tests 1
			}
			if {[catch {exec which $terminal}] == 1} {
				if {$terminal == ""} {set detail "No terminal is installed"} else {set detail "\"$terminal\" is not installed"}
				tk_messageBox -default ok -detail "$detail" -icon warning -message "Choose a different terminal" -parent . -title "Incorrect Option" -type ok 
				focus .config.terminal
				set tests 1
			}
			if {$terminal != ""} {
				if {[string first "<title>" $terminal_string] == -1} {
					tk_messageBox -default ok -detail "The terminal string must include provision for a window title. Use the string <title> to indicate its position in the string. Look at the examples of known terminal strings by selecting a terminal from the drop down list." -icon warning -message "\"$terminal_string\" has no title" -parent . -title "Incorrect Option" -type ok 
					focus .config.terminal_string
					set tests 1
				}
				if {[string first "<command>" $terminal_string] == -1} {
					tk_messageBox -default ok -detail "The terminal string must include provision for a command to execute. Use the string <command> to indicate its position in the string. Look at the examples of known terminal strings by selecting a terminal from the drop down list."  -icon warning -message "\"$terminal_string\" has no command" -parent . -title "Incorrect Option" -type ok 
					focus .config.terminal_string
					set tests 1
				}
			}
			if {[lsearch $colours $installed_colour] == -1 && [regexp -indices ^#\[A-Fa-f0-9\]\{6\}$ $installed_colour] == 0} {
				tk_messageBox -default ok -detail "\"$installed_colour\" is not a recognised colour" -icon warning -message "Choose a different colour for the installed packages" -parent . -title "Incorrect Option" -type ok 
				focus .config.installed_colour
				set tests 1
			}
			if {[lsearch $colours $outdated_colour] == -1 && [regexp -indices ^#\[A-Fa-f0-9\]\{6\}$ $outdated_colour] == 0} {
				tk_messageBox -default ok -detail "\"$outdated_colour\" is not a recognised colour" -icon warning -message "Choose a different colour for the updates" -parent . -title "Incorrect Option" -type ok 
				focus .config.outdated_colour
				set tests 1
			}
			if {$icon_dir != [lindex $old_values 10]} {
				# reload the images for the button bar
				puts $debug_out "configure - the icon location \"$icon_dir\" has changed, previous directory was \"[lindex $old_values 10]\""
				if {[set_images] != 0} {
					tk_messageBox -default ok -detail "\"$icon_dir\" does not exist or does not contain all the required icons\nThe icon directory has not been changed" -icon warning -message "Error in icon directory" -parent . -title "Incorrect Option" -type ok 
					# reset the icon_directory and the images
					puts $debug_out "configure - reset the icon directory to \"[lindex $old_values 10]\" and reload the images"
					set icon_dir [lindex $old_values 10]
					set_images
				}
			}
			if {$keep_log == "" || ![string is integer $keep_log] || [string length $keep_log] > 3} {
				# check that keep_log is a numerical value and less than four characters long
				puts $debug_out "configure - keep_log is set to $keep_log which is either not a numerical value or too long"
				tk_messageBox -default ok -detail "The days to keep must be a numerical value between 0 and 999.\nThe number of days to keep has not been changed" -icon warning -message "Error in days to keep the log" -parent . -title "Incorrect Option" -type ok 
				# reset keep_log
				puts $debug_out "configure - reset the keep_log value to \"[lindex $old_values 11]\""
				set keep_log [lindex $old_values 11]
			}
			if {$buttons != [lindex $old_values 1]} {
				# reload the images for the button bar
				puts $debug_out "configure - the button size has changed"
				set_images
			}
			if {$tests == 0} {
				puts $debug_out "configure - All tests have passed so save configuration options"
				# now save the current geometry of the main window
				if {[string tolower $save_geometry] == "yes"} {set geometry_config "[winfo width .config]x[winfo height .config]"}
				put_configs
				.wp.wfone.listview tag configure installed -foreground $installed_colour
				.wp.wfone.listview tag configure outdated -foreground $outdated_colour
				filter
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
				set editor [lindex $old_values 2]
				set geometry [lindex $old_values 3]
				set geometry_config [lindex $old_values 4]
				set save_geometry [lindex $old_values 5]
				set terminal [lindex $old_values 6]
				set terminal_string [lindex $old_values 7]
				set installed_colour [lindex $old_values 8]
				set outdated_colour [lindex $old_values 9]
			# reset the windows to their original sizes
				wm geometry . $geometry
				get_win_geometry
				set left [expr $win_mainx + {[winfo width .] / 2} - {$win_configx / 2}]
				set down [expr $win_mainy + {[winfo height .] / 2} - {$win_configy / 2}]
				wm geometry .config $geometry_config+$left+$down
			} 
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
	grid .config.editor_label -in .config -row 3 -column 1 \
		-sticky w
	grid .config.editor -in .config -row 3 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.save_label -in .config -row 4 -column 1 \
		-sticky w
	grid .config.yes_no -in .config -row 4 -column 2 \
		-sticky w
	grid .config.terminal_label -in .config -row 5 -column 1 \
		-sticky w
	grid .config.terminal -in .config -row 5 -column 2 \
		-columnspan 4 \
		-sticky we
	grid .config.terminal_string_label -in .config -row 6 -column 1 \
		-sticky w
	grid .config.terminal_string -in .config -row 6 -column 2 \
		-columnspan 4 \
		-sticky we	
	grid .config.button_label -in .config -row 7 -column 1 \
		-sticky w
	grid .config.buttons -in .config -row 7 -column 2 \
		-columnspan 2 \
		-sticky w
	grid .config.installed_label -in .config -row 8 -column 1 \
		-sticky w
	grid .config.installed_colour -in .config -row 8 -column 2 \
		-sticky w
	grid .config.outdated_label -in .config -row 9 -column 1 \
		-sticky w
	grid .config.outdated_colour -in .config -row 9 -column 2 \
		-sticky w
	if {$editor != ""} {
		grid .config.edit_file -in .config -row 11 -column 1
	}
	grid .config.reset -in .config -row 11 -column 3
	grid .config.save -in .config -row 11 -column 4
	grid .config.cancel -in .config -row 11 -column 5
		
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
	grid rowconfigure .config 10 -weight 0 -minsize 20 -pad 0
	grid rowconfigure .config 11 -weight 0 -minsize 0 -pad 0
	grid rowconfigure .config 12 -weight 0 -minsize 10 -pad 0

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

	grab set .config
	
}

proc count_lists {} {

global count_all count_installed count_outdated count_uninstalled debug_out list_all list_installed list_local list_outdated list_uninstalled
# returns the count of all the lists 	

	puts $debug_out "count_lists called"
	set count_all 0
	set count_installed 0
	set count_outdated 0
	set count_uninstalled 0
	set count_all [llength $list_all]	
	set count_installed [expr [llength $list_installed]	 + [llength $list_local]]
	set count_outdated [llength $list_outdated]
	set count_uninstalled [llength $list_uninstalled]	
	puts $debug_out "count_lists - All $count_all, Installed $count_installed, Outdated $count_outdated, Installed $count_installed"
}

proc execute {type} {

global aur_only aur_updates aur_versions_TID dbpath debug_out dlprog filter groups listview_last_selected listview_selected listview_selected_in_order list_local list_show list_outdated package_actions part_upgrade sync_time selected_list start_time su_cmd system_test terminal_string threads tmp_dir upgrades
# runs whatever we need to do in a terminal window

	puts $debug_out "execute - called for $type - upgrades are \"$upgrades\""
	# reload listview_selected in case treeview select has not yet run
	set listview_selected [.wp.wfone.listview selection]
### add warning to catch any erros in the install/delete settings	
	if {($type == "install" || $type == "delete") && $listview_selected == ""} {
		set ans [tk_messageBox -default ok -detail "No packages have been selected - cannot continue with $type." -icon warning -message "No packages selected." -parent . -title "Warning" -type ok]
		return 1
	}
###
	if {$type == "install" && $upgrades != ""} {
		set unstable_text ""
		set install_text "will be re-installed."
		if {$system_test == "unstable"} {
			set unstable_text "Warning: the system is unstable, "
			set install_text "may be upgraded. Continue at your own risk."
		}
		set ans [tk_messageBox -default no -detail "$unstable_text\"$upgrades\" $install_text\n\nAnswer Yes to continue.\nAnswer No to start a new selection.\n\nTo upgrade, select Full System Upgrade from the menus." -icon warning -message "Partial upgrades are not supported." -parent . -title "Warning" -type yesno]
		puts $debug_out "execute install - answer to partial upgrade package warning message is $ans" 
		switch $ans {
			yes {
				# if the response is yes, then continue.
			}
			no {
				# if the response is no, then unselect everything and break out of the foreach loop.
				# remove anything shown in .wp.wftwo.dataview
				all_clear
				return 1
			}	
		}
	}
	set count_selected [llength $listview_selected]
		
	# Install, Upgrade all and Sync will need an internet connection
	if {$type == "install" || $type == "upgrade_all" || $type == "sync"} {
		if {[test_internet] != 0} {return 1}
	}
	
	set list ""

	foreach item $listview_selected {
		lappend list [lrange [.wp.wfone.listview item $item -values] 1 1]
	}
	
	set logfile [find_pacman_config logfile]
	set logfid [open $logfile r]
	seek $logfid +0 end
	puts $debug_out "execute - opened the pacman logfile ($logfile) and moved to the end of the file"

	if {$type == "install"} {
		# test if the version available, pacman -Ss, is not the version requested. If so abort with get a full system upgrade
		set version [lrange [.wp.wfone.listview item $item -values] 2 2]
		puts $debug_out "execute (install) - can $version be installed?"
		set info [split [exec pacman -Si [lrange [.wp.wfone.listview item $item -values] 1 1]] "\n"]
		puts $debug_out "execute (install) - $info"
		set available [lsearch -inline -regex $info "Version         : *"]
		if {[string first $version $available] == -1} {
			puts $debug_out "execute (install) - Version $version is not available ($available)"
			set ans [tk_messageBox -default ok -detail "The sync'ed database shows \"$available\" but $version is available. to instal $version select Full System Upgrade from the menus and then try again." -icon warning -message "Full System Upgrade needed." -parent . -title "Warning" -type ok]
			return 1
		}
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
		puts $debug_out "execute - upgrade_all called for $upgrade_list"
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
		return 1
	}
	
	puts $debug_out "execute - $action $command true"
	execute_command "$action" "$command" "true"	
	# did we see any errors
	if {[file exists $tmp_dir/errors]} {
		set fid [open $tmp_dir/errors r]
		set errorinfo [read $fid]
		close $fid
		file delete $tmp_dir/errors
		puts $debug_out "execute - read error file, the error file text was:\n$errorinfo"
		# check the output found
		# if the string "Packages (" exists then the next part shows the number of updates available
		# if the string "ignoring package upgrade" exists then there are packages ignored
		if {[string first "unable to lock database" $errorinfo] != -1} {
			set lck_dir $dbpath
			if {$type == "sync"} {set lck_dir $tmp_dir}
			tk_messageBox -message "Unable to lock database" -detail "If you're sure a package manager is not already\nrunning, you can remove ${lck_dir}db.lck" -icon error -title "Sync - Update Failed" -type ok
		} elseif {[string first "error: target not found:" $errorinfo] != -1} {
			# cannot get "target not found" if the database is locked, so use if elseif tp check if database is locked first
			tk_messageBox -message "Target not found" -detail "Run Full System Update to update the live database and then try again." -icon error -title "Install Failed" -type ok
		} else {
			if {$type == "upgrade_all"} {
				set errorinfo [split $errorinfo \n]
				set ignores 0
				set replaces 0
				foreach line $errorinfo {
					if {[string first "ignoring package upgrade" $line] != -1} {
						incr ignores
					} elseif {[string first "Replace " $line] != -1} {
						incr replaces
					}
				}
				puts $debug_out "execute - upgrade_all found $ignores ignores and $replaces replaces in error file"
			}
		}	
	}
	# try and find out what happened by reading the new entries in the log file
	# it seems that the logfile takes a while to be written, so we may need to pause here to allow the writes to complete
	# we need a short delay to complete writing the logfile so ...
	if {$type == "install" || $type == "upgrade_all" || $type == "delete"} {after 500}
	set logtext [read $logfid]
	close $logfid
	puts $debug_out "execute - completed and logged these events ([expr [clock milliseconds] - $start_time]):"
	puts $debug_out "$logtext"
	
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
	
	puts $debug_out "execute - Synced $count_syncs, Upgraded $count_upgrades, Installed $count_installs, Reinstalled $count_reinstalls, Deleted $count_deletes"	
	
	# something happened so ...
	if {[expr $count_syncs + $count_upgrades + $count_installs + $count_reinstalls + $count_deletes] != 0} {
		# remove any saved selections.
		.wp.wfone.listview selection remove [.wp.wfone.listview selection]
		set listview_selected ""
		set listview_selected_in_order ""
		# now delete the contents from  listview, we do this now because otherwise we have to look at the wrong
		# contents until proc start or list_show completes
		.wp.wfone.listview delete [.wp.wfone.listview children {}]
		# and also delete the contents of dataview, it will be repopulated later
		puts $debug_out "execute - remove contents of dataview"
		get_dataview ""
		update
	}

	# and decide what is necessary to do 
	set action_message ""
	set lf ""
	set restart false
	if {$type == "install"} {
		if {[expr $count_installs + $count_reinstalls + $count_upgrades] > 0} {
			# something was installed or upgraded
			if {[expr $count_installs + $count_reinstalls + $count_upgrades] >= $count_selected} {
				puts $debug_out "\tInstall succeeded"
			} else {
				puts $debug_out "\tInstall failed, $count_selected packages were selected but only [expr $count_installs + $count_reinstalls + $count_upgrades] were installed"
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
			puts $debug_out "\tInstall failed, nothing was done"
			# nothing happened so there is nothing else to do
		}
	} elseif {$type == "upgrade_all"} {
		# get the last time that the real database was updated and show it
		# this does not mean that the update was successful since it may have failed after the sync time 
		puts $debug_out "execute - found the following successful upgrades \"[lsort $list_upgrades]\""
		puts $debug_out "execute - the upgrade list requested was $upgrade_list"
		set check_upgrade_list 0
		foreach item $upgrade_list {
			if {[lsearch $list_upgrades $item] != -1} {incr check_upgrade_list}
		}
		puts $debug_out "execute - upgrade_all - $check_upgrade_list packages from [llength $upgrade_list] were upgraded, $ignores packages were ignored."
		if {[expr $check_upgrade_list + $ignores] == [llength $upgrade_list]} {
			puts $debug_out "execute - upgrade_all succeeded"
			# remove any warning label and show the change immediately
			grid remove .filter_warning
			update
			if {$ignores != 0} {
				set action_message "Full System Upgrade succeeded but $ignores packages were ignored. The system may now be unstable."
			}
			# the counts and lists will need to be updated
			set restart true
		} else {
			puts $debug_out "execute - upgrade_all failed"
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
				grid .filter_warning
				update
			}
		}
	} elseif {$type == "delete"} {
		if {$count_deletes != 0} {
			# check that a configured programme was not deleted
			test_configs
			# the local database will still be up to date
			# the counts and lists will need to be updated
			set restart true
		}
		if {$count_deletes == $count_selected} {
			puts $debug_out "\tDeletes succeeded"
		} elseif {$count_deletes != 0} {
			puts $debug_out "\tSome deletes failed"
		} else {
			puts $debug_out "\tDeletes failed"
			# nothing happened so there is nothing to do
		}
	} elseif {$type == "sync"} {
		# temporary database sync - restart
		if {$count_syncs >= 1} {
			puts $debug_out "\tSync succeeded"
			# stop the clock
			after 60000 {}
			# set the sync time
			set sync_time [lindex [get_sync_time] 0]
			# and the clock, but do not run test_resync
			set_clock false
			set restart true
		} else {
			puts $debug_out "\tSync failed"
		}
	}
	
	# set any reminders about actions needed for certain packages
	if {$action_message != ""} {set lf "\n"}
	foreach {package action} $package_actions {
		if {[string first " upgraded $package " $logtext] != -1 || [string first " reinstalled $package " $logtext] != -1} {
			set action_message [append action_message $lf $action]
			set lf "\n"
		}
	}
	if {$action_message != ""} {
		tk_messageBox -default ok -detail "$action_message" -icon info -message "Further action may be required" -parent . -title "Further Action" -type ok
	} else {
		puts $debug_out "execute - No package actions required"
	}
	update
	# test  and update if a resync is required
	test_resync
	# now update all the lists if we need to
	if {$restart} {
		puts $debug_out "execute - called the start procedure ([expr [clock milliseconds] - $start_time])"
		# call start
		start
		if {$threads && [test_internet] == 0} {
			# and run the aur_versions thread to get the current aur_versions
			puts $debug_out "execute - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
			thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
		} else {
			puts $debug_out "execute - cannot call aur_versions thread - threading not available"
		}
		
		puts $debug_out "execute - completed the start procedure ([expr [clock milliseconds] - $start_time])"
		
		# selected_list is the list selection. If it is 0 then just run filter
		if {$selected_list == 0} {
			filter
		} else {
			# selected_list is not 0 so run the required filter(_checkbutton)
			switch $selected_list {
				"orphans" {
					filter_checkbutton ".filter_list_orphans" "pacman -b $tmp_dir -Qdtq" "Orphans"
				}
				"not_required" {
					filter_checkbutton ".filter_list_not_required" "pacman -b $tmp_dir -Qtq" "Not Required"
				}
				"aur_updates" {
					get_aur_updates
				}
			}
		}
		puts $debug_out "execute - completed the necessary filter procedure ([expr [clock milliseconds] - $start_time])"
	} else {
	# otherwise just reset any message and run filter
		puts $debug_out "execute - restart not required"
		set_message reset ""
		puts $debug_out "execute - call filter"
		filter
	}
	puts $debug_out "execute - completed"
}

proc execute_command {action command wait} {
	
global debug_out su_cmd terminal_string tmp_dir
# runs a specific command in a terminal window

	puts $debug_out "execute_command - called for \"$action\", \"$command\" with wait set to $wait"
	# tidy up any leftover files (which should not exist)
	puts $debug_out "execute_command - delete $tmp_dir/vpacman.sh"
	file delete "$tmp_dir/vpacman.sh"
	
	# now start the terminal session
	
	puts $debug_out "execute_command - write new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	if {$su_cmd != ""} {
		puts $fid "echo -e \"$ [string map {\" \\"} $command] \n\""
	} else {
		puts $fid "echo -e \"# $ [string map {\" \\"} $command] \n\""
	}
	# now run the command - but send all the output to the terminal AND send any errors to the error file which can be analysed later if necessary
	# tee will overwrite any existing error file without the -a flag
	puts $fid "$command 2>&1 >/dev/tty | tee $tmp_dir/errors"
	if {$wait} {
		puts $fid "pid=\"$!\""
		puts $fid "wait \$pid"
		puts $fid "echo -ne \"\n[lrange $action 0 0] finished, press ENTER to close the terminal.\""
		puts $fid "read ans"
	}
	puts $fid "exit" 
	close $fid
	
	puts $debug_out "execute_command - change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out "execute_command - set_message called - type terminal, \"TERMINAL OPENED to run $action\""
	set_message terminal "TERMINAL OPENED to run $action"
	# stop the exit button working while the terminal is opened
	set_wmdel_protocol noexit
	update idletasks
	puts $debug_out "execute_command - now execute $tmp_dir/vpacman.sh"
	eval [concat exec $execute_string &]
	# wait for the terminal to open
	execute_terminal_isopen $action
	puts $debug_out "execute_command - command started in terminal"
	# place a grab on something unimportant to avoid random button presses on the window
	grab set .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> "catch {exec wmctrl -R \"$action\"}"
		update idletasks
	puts $debug_out "execute_command - set grab on .buttonbar.label_message"
	# wait for the terminal to close
	execute_terminal_isclosed $action "Vpacman"
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out "execute_command - Grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out "execute_command - Window manager delete window re-instated"
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	set_message terminal ""
	update
	puts $debug_out "execute_command - completed"
}
	
proc execute_terminal_isclosed {action master} {
	
global debug_out start_time
# OK, nothing seems to work in tcl to watch when the terminal window closes. We can use a runfile
# but that does not catch a graceless exit. So we are going to use wmctrl to see when the window closes
# but this means we have to know the title of the window so that we can track it!

	puts $debug_out "execute_terminal_isclosed - called for window \"$action\""
	
	set count 0
	set mapstate "normal"
	set mapstate_count 0
	set window_count 0
	set window_list ""
	set xwininfo true
	
	# check once for xwininfo
	if {[catch {exec which xwininfo}] != 0} {
		puts $debug_out "execute_terminal_isclosed - xwininfo is not installed, using \[wm state\]"
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
			puts $debug_out "\tthe previous open message was repeated $mapstate_count times"
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
				puts $debug_out "\tthe previous open message was repeated $mapstate_count times"
			}
			if {$window_count > 0} {
				puts $debug_out "\tWindow list repeated $window_count time"
			}
			puts $debug_out "Window List: \n$windows"
			set window_list $windows
			set window_count 1
			if {[string first "$action" $windows] == -1} {
				puts $debug_out "execute_terminal_isclosed - terminal window \"$action\" closed - break after $count loops"
				break
			}
		}
		if {$mapstate_count == 0} {puts $debug_out "execute_terminal_isclosed - terminal window \"$action\" is open, state is $mapstate"}
		update
		# and wait a few milliseconds - note: this was set to 250 which seemed to be too fast?
		after 500
				
	}
	puts $debug_out "execute_terminal_isclosed - loop has completed after $count loops ([expr [clock milliseconds] - $start_time])"
	# raise and focus the main window in case it has been covered or minimised
	catch {exec wmctrl -F -a $master}
	return 0
}

proc execute_terminal_isopen {action} {

global debug_out start_time
# Make sure that the terminal window is open, it sometimes takes some time
	
	puts $debug_out "execute_terminal_isopen - called for window \"$action\""
	set count 0
	while {true} {
		incr count
		set error 1
		set windows ""
		# get a list of open windows from wmctrl with no errors
		while {$error != 0} {set error [catch {exec wmctrl -l} windows]}
		puts $debug_out "execute_terminal_isopen - window List: \n$windows"
		if {[string first "$action" $windows] != -1} {
			puts $debug_out "execute_terminal_isopen - terminal window \"$action\" is open - break after $count loops"
			break
		}
		update
		# and wait a few milliseconds - note: this was set to 250 which seemed to be too fast
		after 500 
	}
	puts $debug_out "execute_terminal_isopen - loop has completed after $count loops ([expr [clock milliseconds] - $start_time])"
	return 0
}

proc filter {} {
	
global aur_updates debug_out filter filter_list find findtype group list_all list_installed list_local list_outdated list_show list_special list_uninstalled listview_current
# procedure to run when we need to filter the output

	puts $debug_out "filter called - filter is \"$filter\", group is \"$group\", find is \"$find\""

	# if the group setting is not applicable then reset it to All
	if {$filter == "orphans" || $filter == "aur"} {set group "All"}
	# if no filter is required then return
	if {($filter == 0 || $filter == "orphans") && $find == "" && $group == "All"} {return 0}

	set filter_list ""
	set list ""
	
	# if a filter is set then which overall list do we need to filter by
	switch $filter {
		"all" {
			set list $list_all
			puts $debug_out "filter - list set to list_all"
		}
		"installed" {
			set list [lsort -dictionary -index 1 [concat $list_installed $list_local]]
			puts $debug_out "filter - list set to list_installed"
		}
		"not_installed" {
			set list $list_uninstalled
			puts $debug_out "filter - list set to list_uninstalled"
		}
		"orphans" {
			set list $list_special
			puts $debug_out "filter - list set to list_special"
		}
		"outdated" {
			set list $list_outdated
			puts $debug_out "filter - list set to list_outdated"
		}
		"not_required" {
			set list $list_special
			puts $debug_out "filter - list set to list_special"
		}
		"aur" {
			set list $aur_updates
			puts $debug_out "filter - list set to aur_updates"
		}
	}
	
	# now filter on any group selected unless we are in AUR which has no groups
	if {$group != "All" && $filter != "aur"} {
		puts $debug_out "filter - now filter by group $group"
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
		puts $debug_out "filter - now find $find in filter_list"
		# find and show the results
		if {$findtype == "findname"} {
			find $find $filter_list name
		} else {
			find $find $filter_list all
		}
	} else {
		puts $debug_out "filter - now show the [llength $filter_list] items in filter_list"
		# sort and show the list
		set filter_list [sort_list $filter_list]
		list_show $filter_list
	}

}

proc filter_checkbutton {button command title} {

global debug_out filter filter_list find find_message group list_show selected_list selected_message start_time
# procedure to execute when a list checkbutton is selected

	puts $debug_out "filter checkbutton called by $button with command $command  - the title is set to $title ([expr [clock milliseconds] - $start_time])"

	set error 0
	set filter_list ""
	set group "All"
	# lose any existing find command, selected groups, and/or messages for the special filters
	set find ""
	.buttonbar.entry_find delete 0 end
	set_message terminal ""
	grid_remove_listgroups
	
	# if the button was unchecked then reset the filter to all
	if {$selected_list == 0} {
		puts $debug_out "filter checkbutton - selected_list is 0, set filter to \"All\" and call filter"
		set filter "all"
		filter
	} else {
		$button configure -text "Searching ...    "
		update
		puts $debug_out "filter checkbutton called list special with $command ([expr [clock milliseconds] - $start_time])"
		set result [list_special "$command"]
		puts $debug_out "filter checkbutton - list_special returned with the result $result ([expr [clock milliseconds] - $start_time])"
		if {$result == "error"} {
		# OK so it did not work, so reset everything to normal and return
			$button configure -text "$title"
			set selected_list 0
			set filter "all"
			return 1
		} else {
			.wp.wfone.listview configure -selectmode browse
			puts $debug_out "filter_checkbutton set wp.wfone.listview to selectmode browse"
			$button configure -text "$title ($result)"
			set filter_list $list_show
			return 0
		}
	}
	return 0
}

proc find {find list type} {

global debug_out group list_all list_installed list_show_order list_uninstalled listview_current start_time
# find all the items containing the find string
# this will search whatever is in the list and show the results in listview

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
}

proc find_pacman_config {data} {

global debug_out start_time
# look up data in the pacman configuration file
		
	switch $data {
		logfile {
			set logfile "/var/log/pacman.log"
			
			# check log file location in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "LogFile" $line] == 0} {
					set logfile [trim [string range $line [string first "=" $line]+1 end]]
					break
				}
			}
			close $fid
			return $logfile
		}
		dbpath {
			set database "/var/lib/pacman/"
			
			# check database location in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "DBPath" $line] == 0} {
					set database [trim [string range $line [string first "=" $line]+1 end]]
					break
				}
			}
			close $fid
			return $database
		}
		dlprog {
			set dlprog ""
			
			# find the last transfer programme defined in /etc/pacman.conf
			set fid [open "/etc/pacman.conf" r]
			while {[eof $fid] == 0} {
				gets $fid line
				if {[string first "XferCommand" $line] == 0} {
					set dlprog [trim [string range $line [string first "=" $line]+1 end]]
				}
			}
			close $fid
			return $dlprog
		}
	}
}

proc get_aur_updates {} {

global aur_all aur_messages aur_only aur_updates aur_versions debug_out filter filter_list find group list_local selected_list start_time tmp_dir
# check for local packages which may need to be updated
	
	puts $debug_out "get_aur_updates - called ([expr [clock milliseconds] - $start_time])"

	set aur_only true
	set aur_updates ""
	set filter "aur"
	set filter_list ""
	set group "All"
	set messages ""
	
	if {$aur_versions == ""} {
		puts $debug_out "get_aur_updates - aur_versions is blank"
		# aur_versions is blank so the thread to fetch it did not complete - get it now
		.filter_list_aur_updates configure -text "Searching ....."
		update
		puts $debug_out "get_aur_updates - call get_aur_versions"
		# set aur_only false so that get_aur_versions completes
		set aur_only false
		set error [get_aur_versions]
		puts $debug_out "get_aur_updates - configured text \"AUR/Local Updates\""
		.filter_list_aur_updates configure -text "AUR/Local Updates"
		update
	
		if {$error == 1} {
			# OK so it looks like there is no internet available, so reset everything to normal and return
			set selected_list 0
			set filter "all"
			return 1
		}
		
		puts $debug_out "get_aur_updates - found [llength $aur_versions] aur_versions, now update lists and treeview - call put_aur_versions"
		put_aur_versions $aur_versions	
		# and reset aur_only
		set aur_only true
	}
	puts $debug_out "get_aur_updates - aur_versions is available"
	# now just check for any errors and find the updates
	set find_string false
	puts $debug_out "get_aur_updates - find the details of each list_local package"
	# check each package, is it a local install, is it newer or older, construct a message if necessary
	foreach line $list_local {
		set element ""
		set name [lindex $line 1]
		set version [lindex $line 2]
		set available [lindex $line 3]
		set index [lsearch $aur_versions $name]
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
					puts $debug_out "get_aur_versions - the version for $name is different - call test_versions"
					set test [test_versions $version $available]
					if {$test == "newer"} {
						puts $debug_out "\tthe current installed version is older"
						set element $line
					} elseif {$test == "older"} {
						puts $debug_out "\tthe current installed version is newer"
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
	puts $debug_out "get_aur_updates - Find String is $find_string | Group is $group"
	if {!$find_string || $group != "All"} {
		set find ""
		.buttonbar.entry_find delete 0 end
		set_message find ""
		grid_remove_listgroups
		puts $debug_out "get_aur_updates - find set to blank"
	}
	# aur_updates should now be a clean list of all the updates including all the local packages if requested
	set filter_list $aur_updates
	puts $debug_out "get_aur_updates - configured text \"AUR/Local Updates ([llength $filter_list])\""
	.filter_list_aur_updates configure -text "AUR/Local Updates ([llength $filter_list])"
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
		puts $debug_out "get_aur_updates - called find"
		find $find $aur_updates all
	} else {
		puts $debug_out "get aur_updates - call list_show with [llength $aur_updates] aur_updates"
		list_show "$aur_updates"
	}
	puts $debug_out "get_aur_updates - completed ([expr [clock milliseconds] - $start_time])"
}

proc get_aur_version {package} {
	
global debug_out dlprog start_time
# user curl to get the Version number and description for a package from the RPC interface
# we don't actually use the description yet
# only called if the aur_versions thread called from start did not run

	if {$dlprog == ""} {
		puts $debug_out "get_aur_version - No download programme installed - return Error"
		return 1
	}
	if {[test_internet] != 0} {return [list "Error" "Error"]}
	puts $debug_out "get_aur_version called for $package ([expr [clock milliseconds] - $start_time])"
	if {$dlprog == "curl"} {
		set result [eval [concat exec curl -Lfs "https://aur.archlinux.org//rpc/?v=5&type=info&arg[]=$package"]]
	} else {
		set result [eval [concat exec wget -LqO - "https://aur.archlinux.org//rpc/?v=5&type=info&arg[]=$package"]]
	}
	set position [expr [string first "Version" $result] + 10]
	set version [string range $result $position [expr [string first \" $result $position] - 1]]
	set position [expr [string first "Description" $result] + 14]
	set description [string range $result $position [expr [string first \" $result $position] - 1]]
	puts $debug_out "get_aur_version complete - Version is $version - Description is $description ([expr [clock milliseconds] - $start_time])"
	return [list $version $description]
}

proc get_aur_versions {} {

global aur_all aur_messages aur_only aur_updates aur_versions debug_out dlprog filter filter_list find group list_local selected_list start_time tmp_dir
# check for local packages which may need to be updated

	puts $debug_out "get_aur_versions - called ([expr [clock milliseconds] - $start_time])"
	# if aur_only is true then this was the last procedure run
	puts $debug_out "get_aur_versions - aur_only is $aur_only"
	# avoid looking up all the updates a second time if aur_only is already true
	if {$aur_only == "false"} {
		puts $debug_out "get_aur_versions - find aur_versions ([expr [clock milliseconds] - $start_time])"
		# test for internet
		set error [test_internet]
		if {$error != 0} {return 1}
		if {$dlprog == ""} {return 1}
		set list ""
		set aur_versions ""
		puts $debug_out "get_aur_versions started ([expr [clock milliseconds] - $start_time])"
		foreach item $list_local {
			# make up a list of all the local packages in the format &arg[]=package&arg[]=package etc.
			set list [append list "\&arg\[\]=[lindex $item 1]"]
		}
		# now find all the information on these packages
		set fid [open "$tmp_dir/get_aur_versions.sh" w]
		puts $fid "#!/bin/bash"
		if {$dlprog == "curl"} {
			puts $fid "curl -LfGs \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\""
		} else {
			puts $fid "wget -LqO - \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\""
		}
		close $fid
		exec chmod 0755 "$tmp_dir/get_aur_versions.sh"
		exec "$tmp_dir/get_aur_versions.sh"
		file delete "$tmp_dir/get_aur_versions.sh"
		puts $debug_out "get_aur_versions - found result ([expr [clock milliseconds] - $start_time])"
		# read the results into a variable 
		set fid [open $tmp_dir/vpacman_aur_result]
		gets $fid result
		close $fid
		# and delete the temporary file
		file delete $tmp_dir/vpacman_aur_result
	
		set result [split [string map {\[ ( \] )} $result] "\},\{"]
		# and analyse them
		foreach line $result {
			# get the name, version available and description of each package in turn, and save it
			if {[string first "Name" $line] == 1} {lappend aur_versions [string range $line 8 end-1]}
			if {[string first "Version" $line] == 1} {lappend aur_versions [string range $line 11 end-1]}
			if {[string first "Description" $line] == 1} {lappend aur_versions [string range $line 15 end-1]}
		}
		puts $debug_out "get_aur_versions found AUR package version details ([expr [clock milliseconds] - $start_time])"
	}
}

proc get_configs {} {

global aur_all browser buttons config_file editor geometry geometry_config geometry_view helpbg icon_dir installed_colour keep_log one_time outdated_colour  part_upgrade save_geometry show_menu show_buttonbar terminal terminal_string
# get the configuration previously saved

	if [file exists "$config_file"] {
	set fid [open "$config_file" r ]
	while {[eof $fid] == 0} {
		gets $fid config_option
		if {$config_option == ""} {continue}
		if {[string index $config_option 0] == "#"} {continue} 
		set var [string trim [string map {\{ \  \} \  } [lrange $config_option 1 end]]]
		switch -- [lindex $config_option 0] {
			aur_all {set aur_all $var}
			browser {set browser $var}
			buttons {set buttons $var}
			config_file {set config_file $var}
			editor {set editor $var}
			geometry {set geometry $var}
			geometry_config {set geometry_config $var}
			geometry_view {set geometry_view $var}
			help_background {set helpbg $var}
			icon_directory {set icon_dir $var}
			installed_colour {set installed_colour $var}
			keep_log {set keep_log $var}
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
}

proc get_dataview {current} {

global aur_only browser debug_out start_time tmp_dir
# get the data from the database to show in the notebook page selected in .wp.wftwo.dataview
# current is the item id of the latest selected row

	puts $debug_out "get_dataview - called for \"$current\" ([expr [clock milliseconds] - $start_time])"
	set error 0
	set item ""
	set result ""
	[.wp.wftwo.dataview select] delete 1.0 end
	if {$current != ""} {
		set result [catch {.wp.wfone.listview item $current -values} item]
		if {$result == 1} {
			puts $debug_out "\titem has disappeared, return an error"
			return 1
		}
		puts $debug_out "\titem selected $item"

		set repo [lrange $item 0 0]
		set package [lrange $item 1 1]
		set version [lrange $item 2 2]
		set available [lrange $item 3 3]
		set groups [lrange $item 4 4]
		set description [lrange $item 5 5]
		switch [.wp.wftwo.dataview select] {
			.wp.wftwo.dataview.info {
				grid remove .wp.wftwo.ydataview_moreinfo_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_info_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				# If this is a local package it will take up to half a second to get the available versions
				# so we need to implement a note to say why we are waiting
				.wp.wftwo.dataview.info insert 1.0 "Repository      : $repo\n"
				#  if we know of a browser, and this is a local package then use the package name to make a URL and insert tags accordingly
				if {$aur_only == true && $browser != ""} {
					# click on the link to view it in the selected browser
					.wp.wftwo.dataview.info tag bind get_aur <ButtonRelease-1> "exec $browser https://aur.archlinux.org/packages/$package &"
					# add the normal text to the text box
					.wp.wftwo.dataview.info insert end "Name            : " 
					# add the package name to the text box and use the pre-defined tags to alter how it looks
					.wp.wftwo.dataview.info insert end "$package\n" "url_tag get_aur url_cursor_in url_cursor_out" 
				} else {
					.wp.wftwo.dataview.info insert end "Name            : $package\n"
				}
				puts $debug_out "\tinstalled is $version Available is $available"
				if {$available == "{}"} {
					.wp.wftwo.dataview.info insert end "Installed       : no\n"
					.wp.wftwo.dataview.info insert end "Available       : $version\n"
				} elseif {$available == "-na-"} {
					# either this was not in the AUR or the aur_versions thread did not run
					puts $debug_out "\tavailable was $available"
					.wp.wftwo.dataview.info insert end "Installed       : $version\n"
					.wp.wftwo.dataview.info insert end "Available       : Searching ...\n"
					# update now to show the message while we find the (supposed) version available
					update
					# since this is an AUR package or another local install
					# we can use an RPC to get the latest version number and the description
					set result [get_aur_version $package]
					set version [lindex $result 0]
					puts $debug_out "get_dataview - info - get aur version returned $version"
					if {$version == ""} {
						set version "not found in AUR"
					} else {
						set description [string map {\\ ""} [lindex $result 1]]
					}
					.wp.wftwo.dataview.info delete [expr [.wp.wftwo.dataview.info count -lines 0.0 end] -1].18 end
					.wp.wftwo.dataview.info insert end "$version \n"
					puts $debug_out "Version available is $version and description $description"
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
				puts $debug_out "get_dataview - get moreinfo ([expr [clock milliseconds] - $start_time])"
				grid remove .wp.wftwo.ydataview_info_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_moreinfo_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				.wp.wftwo.dataview.moreinfo insert 1.0 "Searching ..."
				update
				# try to get the info from the main database
				puts $debug_out "get_dataview - try sync database ([expr [clock milliseconds] - $start_time])"
				set error [catch {split [exec pacman -b $tmp_dir -Sii $package] \n} result]
				if {$error != 0} {
					# if that did not work then try the local database
					puts $debug_out "get_dataview - main database failed try local database ([expr [clock milliseconds] - $start_time])"
					set error [catch {split [exec pacman -b $tmp_dir -Qi $package] \n} result]
					set result [linsert $result 0 "Repository      : local"]
				}
				puts $debug_out "get_dataview - found moreinfo ([expr [clock milliseconds] - $start_time])"
				# and if it is installed then save the first line of the data, the repository,
				# and then get the rest from the local database
				if {$available != "{}"} {
					# $result holds the info from the main database until it is overwritten
					set repository "[lindex $result 0]"
					set error [catch {split [exec pacman -b $tmp_dir -Qi $package] \n} result]
					set result [linsert $result 0 "$repository"]
				}
				.wp.wftwo.dataview.moreinfo delete 1.0 end
				if {$error == 0} {
					foreach row $result {
						#  if we know of a browser, and this is a local package then use the package name to make a URL and insert tags accordingly
						if {$aur_only == true && $browser != "" && [string first "Name" $row] == 0} {
							# click on the link to view it in the selected browser
							.wp.wftwo.dataview.moreinfo tag bind get_aur <ButtonRelease-1> "puts $debug_out \"GET AUR URL\"; exec $browser https://aur.archlinux.org/packages/[string range $row 18 end] &"
							# add the normal text to the text box
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 0 17]" 
							# add the package name to the text box and use the pre-defined tags to alter how it looks
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 18 end]\n" "url_tag get_aur url_cursor_in url_cursor_out" 
						#  if we know of a browser then find URL and insert tags accordingly
						} elseif {$browser != "" && [string first "URL" $row] == 0} {
							# click on the link to view it in the selected browser
							.wp.wftwo.dataview.moreinfo tag bind get_url <ButtonRelease-1> "puts $debug_out \"GET URL - exec $browser [string range $row 18 end]\"; exec $browser [string range $row 18 end] &"
							# add the normal text to the text box
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 0 17]" 
							# add the URL to the text box and use the pre-defined tags to alter how it looks
							.wp.wftwo.dataview.moreinfo insert end "[string range $row 18 end]\n" "url_tag get_url url_cursor_in url_cursor_out" 
						} else {
							# All this section is repeated from above and should probably be in a procedure
							if {[string first "Version" $row] == 0} {
								if {$available == "{}"} {
									.wp.wftwo.dataview.moreinfo insert end "Installed       : no\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : $version\n"
								} elseif {$available == "-na-"} {
									# so the thread lookup did not work, so get the available version now
									puts $debug_out "Available was -na-"
									.wp.wftwo.dataview.moreinfo insert end "Installed       : $version\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : Searching ...\n"
									update
									# since this is an AUR package or another local install
									# we can use an RPC to get the latest version number
									set result [get_aur_version $package]
									set version [lindex $result 0]
									if {$version == ""} {set version "not found in AUR"}
									.wp.wftwo.dataview.moreinfo delete [expr [.wp.wftwo.dataview.moreinfo count -lines 0.0 end] -1].18 end
									.wp.wftwo.dataview.moreinfo insert end "$version \n"
									puts $debug_out "Version available is $version"
								} else {
									.wp.wftwo.dataview.moreinfo insert end "Installed       : $version\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : $available\n"
								}
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
				# try to get the file list from the local database
				set error [catch {split [exec pacman -b $tmp_dir -Qlq $package] \n} result]
				if {$error != 0} {
					# if that did not work then try using pkgfile to get the file list from the main database
					# if this does not work then pkgfile may not be installed
					set error [catch {split [exec pkgfile -lq $package] \n} result]
				}
				.wp.wftwo.dataview.files delete 1.0 end
				if {$error == 0} {
					foreach row $result {
						.wp.wftwo.dataview.files insert end $row\n
					}
				} else {
					.wp.wftwo.dataview.files insert end "Could not get the file list for $package\n"
					# Check for pkgfile - useful for listing files belonging to a package
					if {[catch {exec which pkgfile}] != 0} {	
						.wp.wftwo.dataview.files insert end "\n"			
						.wp.wftwo.dataview.files insert end "Install pkgfile and try again"
					}
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
		[.wp.wftwo.dataview select] delete 1.0 end
	}
	puts $debug_out "get_dataview - completed and returned 0 ([expr [clock milliseconds] - $start_time])"
	return 0
}

proc get_file_mtime {dir ext} {

global debug_out
# find the latest modified time for a series of files with a given extention in the given directory	

	puts $debug_out "get_file_mtime - called for *.$ext files in $dir"
	set last 0
	set files [glob -nocomplain $dir/*.$ext]
	foreach file $files {
		set time [file mtime $file]
		if {$last < $time} {set last $time}
	}
	return $last
}

proc get_sync_time {} {
	
global dbpath debug_out start_time tmp_dir
# check last modified times for the pacman database 
# check last modified times for the temporary database 
# check that the temporary sync database exists and is the same or newer than the pacman database

	puts $debug_out "get_sync_time called"
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
	return [list [file mtime $tmp_dir/sync] $sync_mtime]
}

proc get_terminal {} {

global debug_out start_time su_cmd terminal terminal_string
# no terminal is configured or found in the known_terminals list, try to get a valid terminal and terminal_string
	
	set ans [tk_messageBox -default yes -detail "Do you want to install xterm now?\n\t(recommended)\nIf not then go to Tools > Options and enter a terminal and a valid terminal string." -icon warning -message "Vpacman requires a known terminal to function." -parent . -title "No known terminal found" -type yesno]

	if {$ans == "yes"} {
		if {[test_internet] == 0} {
			# try to install xterm
			puts $debug_out "get_terminal - try to install xterm terminal ([expr [clock milliseconds] - $start_time])"
			set error 1
			if {$su_cmd == "sudo -n"} {
				set error [catch {eval [concat exec $su_cmd pacman --noconfirm -S xterm]} result]
			} elseif {[catch {exec which pkexec}] == 0} {
				set error [catch {eval [concat exec pkexec pacman --noconfirm -S xterm]} result]
			}
			# not sure why the above returns 1 even when the install is successful so check for xterm instead
			if {[catch {exec which xterm}] == 1} {
				puts $debug_out "get_terminal - install xterm failed error $error and result $result"
			} else {
				puts $debug_out "get_terminal - installed xterm"
				set terminal "xterm"
				set terminal_string "xterm -title <title> -e <command>"
				# installed xterm so update the lists
				puts $debug_out "get_terminal - now call start"
				start
				filter
			}	
		}	
	}
	# either the answer was no, or there was an error installing xterm
	if {$terminal == ""} {
		set terminal_string ""
		configure 
		# wait for the configure window to close
		tkwait window .config
		if {$terminal == ""} {
			tk_messageBox -default ok -detail "Vpacman will exit now" -icon warning -message "Vpacman requires a known terminal to function." -parent . -title "No known terminal entered" -type ok
			exit
		}
	}

}

proc get_terminal_string {terminal} {

global debug_out known_terminals	
# get the terminal_string for terminal from the known_terminals string
	
	puts $debug_out "get_terminal_string called for $terminal"
	if {[lsearch $known_terminals $terminal] != -1} {
		set terminal_string "$terminal --title <title> --command <command>"
		puts $debug_out "get_terminal_string - terminal is $terminal, String is $terminal_string"
	} else {
		set terminal_string "$terminal "
		focus .config.terminal_string
		.config.terminal_string icursor end
		puts $debug_out "get_terminal_string - terminal is $terminal - not a known terminal"
	}	
	.config.terminal selection clear
	.config.terminal_string selection clear
	puts $debug_out "get_terminal_string completed and returned $terminal_string"
	return $terminal_string
}

proc get_win_geometry {} {
	
global geometry geometry_config win_configx win_configy win_mainx win_mainy
# calculate various window geometry variables from the current geometry settings excluding borders

	# calculate the position of the main window
	set win_mainx [string range $geometry [string first "+" $geometry]+1 [string last "+" $geometry]-1]
	set win_mainy [string range $geometry [string last "+" $geometry]+1 end]
	# calculate the size of the config window
	set win_configx [string range $geometry_config 0 [string first "x" $geometry_config]-1]
	set win_configy [string range $geometry_config [string first "x" $geometry_config]+1 end]
}

proc grid_remove_listgroups {} {
	
global debug_out
	
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
}
	
proc grid_set_listgroups {} {

global debug_out group group_index list_groups
	
	grid .listgroups
	grid .scroll_selectgroup
	set group_index [lsearch -exact $list_groups $group]
	puts $debug_out "grid_set_listgroups - Found $group at $group_index"
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
	bind .listgroups <<ListboxSelect>>  {
		set group [.listgroups get [.listgroups curselection]]
		filter
		grid_remove_listgroups
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
}

# THE LIST PROCEDURES CALCULATE ALL OF THE LISTS OF PACKAGES THAT WE WILL NEED FOR THE FUTURE
# INCLUDING THE LIST OF PACKAGES CURRENTLY SHOWN IN THE LISTVIEW WINDOW AND ANY SPECIAL LIST OPTIONS

proc list_all {} {

global debug_out list_all list_local list_local_ids list_installed list_outdated list_uninstalled list_show_order tmp_dir
# get a list of all available packages in package order as:
# Repo Package Version Available Group(s) Description

	set list_all ""
	set list_installed ""
	set list_outdated ""
	set list_uninstalled ""
	
	set details [split [exec pacman -b $tmp_dir -Ss] \n]
	foreach {element description} $details {
		# find the group(s) that the package belongs to
		set group [string map {\  \,} [string range $element [string first "(" $element] [string first ")" $element]]]
		if {$group == ""} {set group "-none-"}
		# if the item has been installed then set the third and fourth field to the current version
		if {[string first "\[installed\]" $element] != -1 } {
			set item "[string map {\/ \ } [lrange $element 0 0]] [lrange $element 1 1] [lrange $element 1 1] [string trim $group "()"] \{[string trim $description]\}"
			lappend list_installed $item 
		# else if the item has been installed and there is a new version available then set the third field to the installed version and set the fourth field to the current version
		} elseif {[string first "\[installed:" $element ] != -1 } {
			set available [string range $element [string first "\[installed:" $element]+12 [string first \] $element [string first "\[installed:" $element]+12]-1]
			set item "[string map {\/ \ } [lrange $element 0 0]] $available [lrange $element 1 1] [string trim $group "()"] \{[string trim $description]\}"
			lappend list_installed $item
			if {$available != [lrange $element 1 1]} {
				lappend list_outdated $item
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
}

proc list_groups {} {
	
global debug_out list_groups start_time tmp_dir
# get a list of all available groups

	puts $debug_out "list_groups called ([expr [clock milliseconds] - $start_time])"
	set list_groups "All\n[exec pacman -b $tmp_dir -Sg | sort -d]"
	puts $debug_out "list_groups completed ([expr [clock milliseconds] - $start_time])"
}

proc list_local {} {

global debug_out list_local start_time tmp_dir
# get a list of locally installed packages
# returns local_list as Repo Package Version Available(na) Group(s) Description

	set list_local ""
	# get the list in the form Package Version
	set error [catch {exec pacman -b $tmp_dir -Qm} local]
	if {$error != 0} {
		puts $debug_out "list_local - executed Pacman -Qm with error $error and result $local"
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

}

proc list_special {execute_string} {

global debug_out filter list_all list_local list_special start_time tmp_dir
# get a list of requested packages
# returns list as Repo Package Version Available(na) Group(s) Description

	puts $debug_out "list_special - called to execute $execute_string ([expr [clock milliseconds] - $start_time])"
	set list_special ""
	set paclist ""
	set tmp_list ""

	# now execute the command
	# some of these commands return an error if there are no results so we need to catch those errors
	set error [catch {eval [concat exec $execute_string]} paclist]
	puts $debug_out "list_special - ran $execute_string with error $error ([expr [clock milliseconds] - $start_time])"
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
	puts $debug_out "list special - for each element find its details ([expr [clock milliseconds] - $start_time])"

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
	puts $debug_out "list special created a list of packages ([expr [clock milliseconds] - $start_time])"
	puts $debug_out "\tnow get the details for each of the packages found"
	foreach element $paclist {
		set values [lindex $list_all [lsearch $tmp_list $element]]
		lappend list_special $values
	}
	puts $debug_out "list special finished - now call list_show ([expr [clock milliseconds] - $start_time])"
	list_show [lsort -dictionary -index 1 $list_special]
	return [llength $list_special]
}

proc list_show {list} {

global debug_out list_local_ids list_show list_show_ids listview_selected_in_order part_upgrade start_time tvselect
# Show the list of packages in the .wp.wfone.listview window maintaining any selected items if possible
# Repo Package Version Available Group(s) Description

	puts $debug_out "list_show - called ([expr [clock milliseconds] - $start_time])"

	# first save the names of the packages selected in the selected order
	set listview_selected_names ""
	foreach item $listview_selected_in_order {
		lappend listview_selected_names [lrange [.wp.wfone.listview item $item -values] 1 1]
	}
	# now delete the contents from  listview
	.wp.wfone.listview delete [.wp.wfone.listview children {}]
	# and also delete the contents of dataview, it will be repopulated below
	puts $debug_out "list_show - remove contents of dataview"
	get_dataview ""

	# now show the new list in listview
	set list_show ""
	set list_show_ids ""
	set listview_selected_in_order ""
	# save only the first two items (name and list_all index) in list_local_ids
	set tmp_list ""
	foreach line $list_local_ids {set tmp_list [lappend tmp_list [lrange $line 0 1]]}
	set list_local_ids $tmp_list
	# save done
	set new_listview_selected ""
	puts $debug_out "list_show - show all the [llength $list] elements ([expr [clock milliseconds] - $start_time])"
	foreach element $list {
		lappend list_show $element
		set id [.wp.wfone.listview insert {} end -values $element]
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
.wp.wfone.listview item $id -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
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
.wp.wfone.listview item $id -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
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
	puts $debug_out "list_show - show all the elements completed ([expr [clock milliseconds] - $start_time])"
	if {$new_listview_selected != ""} {
		set new_listview_selected [lsort -index 0 $new_listview_selected]
		# now add each of the selected items to the listview in the correct order
		# bind TreeviewSelect will update all the variables when the selection changes
		set tvselect ""
		foreach {item} $new_listview_selected {
			.wp.wfone.listview selection add [lindex $item 1]
		}
		vwait tvselect
		puts $debug_out "list_show - Treeview Select has completed ([expr [clock milliseconds] - $start_time])"
	} else {
		puts $debug_out "list_show - there are no selections"
		# we have just shown a new list and nothing is selected, so reset the menu entries
		set_message selected ""
		.menubar.edit entryconfigure 0 -state normal
		.menubar.edit entryconfigure 1 -state disabled
		.menubar.tools entryconfigure 1 -state disabled
		.menubar.tools entryconfigure 2 -state disabled
		.listview_popup entryconfigure 1 -state disabled
		.listview_popup entryconfigure 2 -state disabled
		.listview_popup entryconfigure 3 -state normal
		.listview_popup entryconfigure 4 -state disabled
		if {[llength $list] == 0} {
			# and nothing is listed
			puts $debug_out "list_show - there is nothing listed"
			.menubar.edit entryconfigure 0 -state disabled
			.listview_popup entryconfigure 3 -state disabled
		}
		puts $debug_out "\tPartial Upgrades set to no"
		set part_upgrade 0
	}
	update
	puts $debug_out "list_show - listview_selected_in_order is \"$listview_selected_in_order\""
	if {[llength $listview_selected_in_order] != 0} {
		puts $debug_out "\tmove to last selected item"
		.wp.wfone.listview see [lindex $listview_selected_in_order end]
	} else {
		puts $debug_out "\tmove to first item"
		.wp.wfone.listview xview moveto 0
		.wp.wfone.listview yview moveto 0
	}
	puts $debug_out "list_show - finished ([expr [clock milliseconds] - $start_time])"
	return 0
}

proc put_aur_files {files} {
	
global aur_files debug_out start_time

	puts $debug_out "put_aur_files - called by thread aur_files ([expr [clock milliseconds] - $start_time])"
	set aur_files $files
	puts $debug_out "put_aur_files - completed ([expr [clock milliseconds] - $start_time])"

}

proc put_aur_versions {versions} {
	
global aur_all aur_versions debug_out filter filter_list find group list_all list_local list_local_ids list_show local_newer selected_list start_time tmp_dir
# put the version and description found for a local package into list_all list_show list_local and treeview
# this procedure is called by a thread
	
	set aur_versions $versions

	puts $debug_out "put_aur_versions - called ([expr [clock milliseconds] - $start_time])"
	# reset the number of local files that need to be updated
	set local_newer 0
	# read each of the local packages and compare them to the information in aur_versions
	# if the local package does not exist in aur_versions then leave it unchanged
	foreach line $list_local {
		set name [lindex $line 1]
		set element ""
		if {[lsearch $aur_versions $name] != -1} {
			set version [lindex $line 2]
			set index [lsearch $aur_versions $name]
			set available [lindex $aur_versions $index+1]
			set description [lindex $aur_versions $index+2]
		} else {
			set version [lindex $line 2]
			set available [lindex $line 3]
			set description [lindex $line 5]
		}
		# try to get the description from the local database
		if {$description == "DESCRIPTION"} {
			puts $debug_out "put_aur_versions - find description for $name from local database ([expr [clock milliseconds] - $start_time])"
			# this can take a long time when first run - replace with a straight look up from the file
			#set error [catch {split [exec pacman -b $tmp_dir -Qi $name] \n} result]
			#if {$error == 0} {set description [string range [lindex $result 2] 18 end]}
			set filename [glob $tmp_dir/local/$name*]
			set fid [open $filename/desc r]
			while {[eof $fid] == 0} {
				gets $fid header
				if {$header == "%DESC%"} {
					gets $fid description
					break
				}
			}
			close $fid
			puts $debug_out "put_aur_versions - description for $name set to \"$description\" ([expr [clock milliseconds] - $start_time])"
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
			puts $debug_out "put_aur_versions - call test_versions for $name ([expr [clock milliseconds] - $start_time])"
			set test [test_versions [lrange $element 2 2] [lrange $element 3 3]]
			puts $debug_out "put_aur_versions - test_versions returned $test ([expr [clock milliseconds] - $start_time])"
			if {$test == "newer"} {
				set is_update true
				puts $debug_out "put_aur_versions - this is an update ([expr [clock milliseconds] - $start_time])"
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
.wp.wfone.listview item $treeview_index -values [lreplace $element 3 3 "*[lrange $element 3 3]"]
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
	puts $debug_out "put_aur_versions - filter is \"$filter\", group is \"$group\", find is \"$find\" ([expr [clock milliseconds] - $start_time])"
	# if filter_list is still set to list_all at this point then update it
	if {$filter == "all" && $group == "All" && $find == ""} {
		set filter_list $list_all
		puts $debug_out "put_aur_versions - filter_list set to list_all ([expr [clock milliseconds] - $start_time])"
	}
	# now show the number of packages against AUR/Local Updates
	if {$aur_all == true} {
		puts $debug_out "put_aur_versions - configured text \"AUR/Local Updates ([llength $list_local])\" ([expr [clock milliseconds] - $start_time])"
		.filter_list_aur_updates configure -text "AUR/Local Updates ([llength $list_local])"
	} else {
		puts $debug_out "put_aur_versions - configured text to local_newer \"AUR/Local Updates ($local_newer)\" ([expr [clock milliseconds] - $start_time])"
		.filter_list_aur_updates configure -text "AUR/Local Updates ($local_newer)"
	}
	puts $debug_out "put_aur_versions - completed ([expr [clock milliseconds] - $start_time])"
}

proc put_configs {} {

global aur_all browser buttons config_file editor geometry geometry_config geometry_view helpbg icon_dir installed_colour keep_log one_time outdated_colour save_geometry show_menu show_buttonbar terminal terminal_string
# save the configuration data

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
	puts $fid "browser $browser"
	puts $fid "buttons $buttons"
	puts $fid "config_file $config_file"
	puts $fid "editor $editor"
	puts $fid "geometry $geometry"
	puts $fid "geometry_config $geometry_config"
	puts $fid "geometry_view $geometry_view"
	puts $fid "help_background $helpbg"
	puts $fid "icon_directory $icon_dir"
	puts $fid "installed_colour $installed_colour"
	puts $fid "keep_log $keep_log"
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
}

proc put_list_groups {groups} {
	
global debug_out list_groups list_groups_TID start_time

	puts $debug_out "put_list_groups called by thread list_groups ([expr [clock milliseconds] - $start_time])"
	set list_groups $groups
	# we can stop this thread running since we do not need it again
	thread::release $list_groups_TID
	if {[thread::exists $list_groups_TID] == 0} {
		puts $debug_out "put_list_groups stopped the list groups thread"
	}
	puts $debug_out "put_list_groups completed ([expr [clock milliseconds] - $start_time])"
}

proc read_config {}  {
	
global debug_out  start_time
# read the pacman configuration file 

	puts $debug_out "read_config called ([expr [clock milliseconds] - $start_time])"
	
	# read /etc/pacman.conf
	set config_text ""
	set config_text [exec cat "/etc/pacman.conf"]
	puts $debug_out "read_config complete ([expr [clock milliseconds] - $start_time])"
	
	view_text $config_text "Pacman Configuration"
}

proc read_log {} {
	
global debug_out start_time
# read through the pacman log file and display it. Check the size and warn if it is too big

	puts $debug_out "read_log called ([expr [clock milliseconds] - $start_time])"

	set log_text ""
	set logfile [find_pacman_config logfile]
	puts $debug_out "read_log - Logfile is $logfile"
	
	if {[file exists $logfile]} {
		# calculate the size of the logfile in megabytes to two decimal places
		# use MB = SI version and not MiB = binary calculation
		set logsize [expr [expr [file size $logfile] / 10000] / 100.0]
		puts $debug_out "read_log - Logfile is ${logsize} MB"
		# read the last 5000 lines of the logfile
		set log_text [exec tail -5000 $logfile]
		# what size is too big - set to 1 MB	
		if {$logsize > 1} {
				set_message terminal "WARNING: the Pacman log ($logfile) is $logsize MB"
		}
		# using log_text, reverse the order of the lines
		set tmp_log_text [lreverse [split $log_text \n]]
		set log_text ""
		foreach item $tmp_log_text {set log_text [append log_text $item "\n"]}
		# and view them in reverse order
		view_text $log_text "Recent Pacman Log"
	} else {
		tk_messageBox -default ok -detail "" -icon error -message "The pacman log file ($logfile) is missing." -parent . -title "Error" -type ok
	}		
}

proc read_news {} {
	
global browser debug_out dlprog home start_time
# use the download programme to get the latest news from the arch rss feed

	if {[test_internet] != 0} {return 1}
	puts $debug_out "read_news - download arch rss ([expr [clock milliseconds] - $start_time])"
	if {$dlprog == "curl"} {
		set error [catch {eval [concat exec curl -s https://www.archlinux.org/feeds/news/]} rss_news]
	} elseif {$dlprog == "wget"} {
		set error [catch {eval [concat exec wget -qO - https://www.archlinux.org/feeds/news/]} rss_news]
	} else {
		set error 1
	}
	if {$error != 0} {return 1}
	set rss_news [split $rss_news "<>"]
	puts $debug_out "\tdone ([expr [clock milliseconds] - $start_time])"
	puts $debug_out $rss_news
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
				regsub -all {&amp;gt;} $element {>} element
				regsub -all {&amp;lt;} $element {<} element
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
				# remove any stray newline characters
				regsub -all {\u0A} $element { } element
				# substitute various named characters
				regsub -all {&gt;} $element {>} element
				regsub -all {&lt;} $element {<} element
				regsub -all {&amp;gt;} $element {>} element
				regsub -all {&amp;lt;} $element {<} element
				# remove paragraph tags and replace them with carriage returns
				set element [string map {<p> \n} $element]
				set element [string map {</p> \n} $element]
				#remove hyperlinks
				regsub -all {<a href=.*?>} $element {} element
				# first attempt to deal with the pre tags, at least add a newline
				set element [string map {<pre> \n<pre>} $element]
				set element [string map {</pre> \n</pre>} $element]
				# remove other tags
				regsub -all {<li>} $element { } element
				#regsub -all {<pre>} $element {} element					
				regsub -all {<ul>} $element { } element
				# remove end of tag markers
				regsub -all {</a>} $element {} element
				regsub -all {</li>} $element { } element
				#regsub -all {</pre>} $element { } element
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
	puts $debug_out "read_news rss parsed  ([expr [clock milliseconds] - $start_time])"
	view_text $news_list "Latest News"
}

proc set_clock {test} {
	
global debug_out start_time sync_time
# work out the elapsed time since the last sync
# calculate the minutes rounded up

	puts $debug_out "set_clock - called ([expr [clock milliseconds] - $start_time])"
	# test for a resync and update if requested
	if {$test} {test_resync}

	set e_time [expr [clock seconds] - $sync_time]
	# now convert the number of elapsed seconds into a string dd:hh:mm
	set days [expr int($e_time / 60 / 60 / 24)]
	if {[string length $days] == 1} {set days "0$days"}
	set hours [expr int($e_time / 60 / 60) - ($days * 24)] 
	set mins [expr round((($e_time / 60.0) +0.5) - ($hours * 60) - ($days * 60 * 24))]
	.filter_clock configure -text "${days}:[string range "0${hours}" end-1 end]:[string range "0${mins}" end-1 end]"
	puts $debug_out "set_clock - completed ([expr [clock milliseconds] - $start_time])"
	
	# wait a minute
	after 60000 {
		# update the time since last sync
		set_clock true
	}
}

proc set_images {} {
	
global buttons debug_out icon_dir
# Create images

	set error [catch {
		# Toolbar	
		image create photo delete -file "$icon_dir/$buttons/edit-delete.png"
		image create photo install -file "$icon_dir/$buttons/dialog-ok-apply.png"
		image create photo reload -file "$icon_dir/$buttons/edit-redo.png"
		image create photo tools -file "$icon_dir/$buttons/configure.png"
		image create photo upgrade -file "$icon_dir/$buttons/system-software-update.png"
		# Message Box
		image create photo hint -file "$icon_dir/medium/help-hint.png"
		image create photo warning -file "$icon_dir/medium/dialog-warning.png"
		# Fixed size
		image create photo clear -file "$icon_dir/tiny/edit-clear-locationbar-rtl.png"
		image create photo down_arrow -file "$icon_dir/tiny/pan-down-symbolic.symbolic.png"
		image create photo pacman -file "$icon_dir/small/ark.png"
		image create photo up_arrow -file "$icon_dir/tiny/pan-up-symbolic.symbolic.png"
		image create photo view -file "$icon_dir/small/view-list-text.png"
		}]

	puts $debug_out "set_images returned $error"

	return $error
}

proc set_message {type text} {

global debug_out find_message message selected_message
# print a message consisting of any saved message plus any new text:
	
	puts $debug_out "set_message called - Type $type, Text \"$text\"\n\tFind Message \"$find_message\", Selected Message \"$selected_message\""
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
	} elseif {$type == "terminal"} {
	# for other types of message just print the text
		set message "$text"
	}
	puts $debug_out "set_message done - Find Message \"$find_message\", Selected Message \"$selected_message\"\n\tMessage \"$message\""
	
}

proc set_wmdel_protocol {type} {
	
# set the main window exit code, depending on the type requested

	if {$type == "noexit"} {
		wm protocol . WM_DELETE_WINDOW {
			puts $debug_out "Don't click on exit while a Terminal is open!"
		}
	} else { 
		wm protocol . WM_DELETE_WINDOW {
			if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]}
			put_configs
			# delete the aur_upgrades directory and all of its contents
			# any aur packages with incomplete downloads or upgrades will have to be restarted
			set error [catch {file delete -force "$tmp_dir/aur_upgrades"} result]
			close $debug_out
			exit
		}
	}
}

proc sort_list {list} {
	
global debug_out list_show_order start_time
# show the displayed list in the current order

	set heading [lindex $list_show_order 0]
	set order [lindex $list_show_order 1]
	puts $debug_out "sort_list called for $list_show_order ([expr [clock milliseconds] - $start_time])"
	set index [lsearch "Repo Package Version Available" $heading]
	puts $debug_out "sort_list index for $heading is $index"
	set list [lsort -index $index -$order $list]
	puts $debug_out "sort_list completed ([expr [clock milliseconds] - $start_time])"
	return $list
}

proc sort_list_toggle {heading} {
	
global debug_out list_show list_show_order
# toggle the order of the list according to the heading selected
# the values are Repo Package Available Installed Group(s) Description
# the headings are Package Version Available Repo

	puts $debug_out "sort_list_toggle called for $heading - current order is $list_show_order"
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
	puts $debug_out "sort_list_toggle completed - order is $list_show_order - call sort_list"
	set list_show [sort_list $list_show]
	return $list_show
}

proc start {} {
	
global aur_files_TID aur_versions_TID aur_versions count_all count_installed count_uninstalled count_outdated debug_out list_all list_local select start_time test_system_TID threads tmp_dir
# this is the process to start the programme from scratch
# or after an update is called	

	set aur_versions ""
	puts $debug_out "start - called, call list_local ([expr [clock milliseconds] - $start_time])"
	set select false
	list_local
	puts $debug_out "start - list_local done, call list_all ([expr [clock milliseconds] - $start_time])"
	list_all
	puts $debug_out "start - list_all done, call count_lists ([expr [clock milliseconds] - $start_time])"
	count_lists
	puts $debug_out "start - count_lists done, show counts ([expr [clock milliseconds] - $start_time])"
	
	.filter_installed configure -text "Installed ($count_installed)"
	.filter_all configure -text "All ($count_all)"
	.filter_not_installed configure -text "Not Installed ($count_uninstalled)"
	.filter_updates configure -text "Updates Available ($count_outdated)"
	if {$threads} {
		puts $debug_out "start - Call threads to find the files of local packages and test the system ([expr [clock milliseconds] - $start_time])"
		puts $debug_out "start - Call aur_files thread with main_TID and list_local"
		thread::send -async $aur_files_TID [list thread_get_aur_files [thread::id] $list_local]
		puts $debug_out "start - Call test_system thread with main_TID"
		thread::send -async $test_system_TID [list thread_test_system [thread::id]]
	}
	puts $debug_out "start - completed ([expr [clock milliseconds] - $start_time])"
}

proc system_upgrade {} {

global aur_versions_TID debug_out dlprog filter find fs_upgrade list_local start_time sync_time threads tmp_dir tvselect
# run a full system upgrade

	puts $debug_out "system_upgrade called"
	set fs_upgrade true
	update idletasks
	cleanup_checkbuttons false
	set find ""
	.buttonbar.entry_find delete 0 end
	set filter "outdated"
	filter
	puts $debug_out "system_upgrade - select all"
	all_select
	# we changed the selection
	# TreeviewSelect now updates the selection and sets a new message
	# select everything in the outdated list
	puts $debug_out "system_upgrade - all selected"
	set return [execute "upgrade_all"]
	if {$return == 1} {
		all_clear
		set fs_upgrade false
		return 1
	}
	set fs_upgrade false
	# call start
	start
	if {$threads && [test_internet] == 0} {
		# and run the aur_versions thread to get the current aur_versions
		puts $debug_out "system_upgrade - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
		thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
	} else {
		puts $debug_out "system_upgrade - cannot call aur versions thread - threading not available"
	}
	filter
}

proc test_configs {} {
	
global browser debug_out editor known_browsers known_editors known_terminals one_time start_time terminal 
# Test for sane configuration options

	puts $debug_out "test_configs - called ([expr [clock milliseconds] - $start_time])"
	set_message terminal ""
	puts $debug_out "test_configs - test browser \"$browser\""
	if {$browser != "" && [catch {exec which $browser}] == 1} {
		tk_messageBox -default ok -detail "\"$browser\" is configured but is not installed" -icon warning -message "The browser will be reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default browser $known_browsers
	}
	puts $debug_out "test_configs - test editor \"$editor\""
	if {$editor != "" && [catch {exec which [lindex $editor 0]}] == 1} {
		tk_messageBox -default ok -detail "\"[lindex $editor 0]\" is configured but is not installed" -icon warning -message "The editor will be reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default editor $known_editors
	}
	puts $debug_out "test_configs - test terminal \"$terminal\""
	if {$terminal != "" && [catch {exec which $terminal}] == 1} {
		tk_messageBox -default ok -detail "\"$terminal\" is configured but is not installed" -icon warning -message "The terminal will be reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default terminal $known_terminals
	} 
	# the terminal must exist
	if {$terminal == ""} {
		set_message terminal "Error: A terminal is required"
		get_terminal
	}
	if {$terminal == "konsole" && $one_time == "true"} {
		tk_messageBox -default ok -detail "Wmctl relies on the window title set for the terminal. In order to use konsole the profile must be set to use the window title set by the shell.\nSet Tab title format to \"%w\"" -icon warning -message "The terminal emulator \"$terminal\" has been selected" -parent . -title "Changed terminal emulator" -type ok
		set one_time "false"
	}
	puts $debug_out "test_configs - completed ([expr [clock milliseconds] - $start_time])"
}

proc test_internet {} {
	
global debug_out
# try three times to find an internet connection using three different sites in case one does not reply

	set count 0
	set try(0) "www.google.com"
	set try(1) "www.yahoo.com"
	set try(2) "www.bing.com"
	while {$count < 3} {
		set error [catch {eval [concat exec timeout 1 ping -c 1 $try($count)]} result]
		puts $debug_out "test_internet - $count returned $error $result"
		if {$error == 0} {return 0}
		incr count
		after 100
	}
	set ans [tk_messageBox -default ok -detail "" -icon warning -message "No Internet - Please check your internet connection and try again" -parent . -title "Warning" -type ok]
	return "Error"
}

proc test_resync {} {

global aur_versions_TID debug_out dlprog list_local threads start_time sync_time tmp_dir
# test if a resync is required after a failed update or an external intervention

	puts $debug_out "test_resync - called ([expr [clock milliseconds] - $start_time])"
	# save the last recorded time that the temporary sync database was updated
	set prev_tmpsync_time $sync_time
	# now get the latest time that the temporary sync database was updated
	set latest_tmpsync_time [file mtime "$tmp_dir/sync"]
	# now update the temporary sync database if necessary and record the update time
	# get_sync_time checks that the temporary sync database exists and is the same or newer than the pacman database
	set sync_time [lindex [get_sync_time] 0]
	# so we can see if an update occurred to the sync database because it will have changed the temporary sync database time.
	if {$latest_tmpsync_time != [file mtime "$tmp_dir/sync"]} {
		puts $debug_out "test_resync - external pacman sync detected"
		# the pacman database has been updated, is the system stable?
		test_system ""
	}
	# now we can see if an update occurred to the temporary sync database because the mtime will have changed from the previously recorded tmpsync time.
	if {$latest_tmpsync_time != $prev_tmpsync_time} {
		puts $debug_out "test_resync - external temporary sync detected"
		# was anything updated?
		set last_update_time [get_file_mtime $tmp_dir/sync db]
		puts $debug_out "test_resync - an external temporary database was last updated [clock_format $last_update_time "short_full"], the last time a sync was recorded by vpacman was [clock_format $prev_tmpsync_time "short_full"]"
		# if the last time that a db file was updated is later than the previous tmpsync time then one of the db files was updated
		# this could be because there was an external system update (failed or not) or an external sync of the temporary databases.
		if {$last_update_time > $prev_tmpsync_time} {
			puts $debug_out "test_resync - external temporary sync update detected"
			# the temporary sync database has been updated, the lists may not be up to date so restart 
			# set a warning message if the vpacman window is displayed ...
			if {"[focus]" == ""} {
				puts $debug_out "test_resync - vpacman does not have the focus so call start without confirmation"
			} else {
				puts $debug_out "test_resync - vpacman has the focus so ask to continue"
				tk_messageBox -default ok -detail "This may be due to a failed system update or the action of an external programme.\nThe data will now be reloaded" -icon warning -message "The temporary database is out of sync." -parent . -title "Out of Sync" -type ok
			}
			# ... otherwise just start
			# call start
			start
			if {$threads && [test_internet] == 0} {
				# and run the aur_versions thread to get the current aur_versions
				puts $debug_out "test_resync - call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
				thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
			} else {
				puts $debug_out "test_resync - cannot call aur versions thread - threading not available"
			}
			filter
		}
	}
	puts $debug_out "test_resync - completed ([expr [clock milliseconds] - $start_time])"
}

proc test_system {result} {
	
global debug_out start_time system_test
# if the sync database shows updates available then the system is out of sync and therefore unstable 
	
	if {$result == ""} {
		# looks like we are being asked to update the system status
		puts $debug_out "test_system -called to update status ([expr [clock milliseconds] - $start_time])"
		set error [catch {exec pacman -Qu} result]
		if {$error == 0} {
			set result "unstable"
		} else {
			set result "stable"
		}
	} else {
		puts $debug_out "test_system -called by test system thread ([expr [clock milliseconds] - $start_time])"
	}
	if {$result == "unstable"} {
		grid .filter_warning
	}
	puts $debug_out "\tThe system is $result ([expr [clock milliseconds] - $start_time])"
	set system_test $result
	return "$result"
}

proc test_versions {installed available} {
	
global debug_out start_time
# test if the available version is newer or older the installed version

	puts $debug_out "test_versions called for installed $installed and available $available  ([expr [clock milliseconds] - $start_time])"
	set old_version [split [string trim $installed "r"] ".-"]
	set new_version [split [string trim $available "r"] ".-"]
	set count 0
	while {$count <= [llength $old_version]} {
		if {[lindex $new_version $count] > [lindex $old_version $count]} {
			puts $debug_out "test_versions - this is an update"
			return "newer"
		} elseif {[lindex $new_version $count] < [lindex $old_version $count]} {
			# if the major element has decreased then it is older
			return "older"
		} else {
			incr count
		}
	}
	return "same"	
}

proc toggle_buttonbar {} {

global show_buttonbar	
# toggle the buttonbar on or off

	if {[.menubar.view entrycget 5 -label] == "Hide Toolbar"} {
		.menubar.view entryconfigure 5 -command {
			grid .buttonbar -in . -row 2 -column 1 -columnspan 3 -sticky ew
			set show_buttonbar "yes"
			toggle_buttonbar
		} -label "Show Toolbar" -state normal -underline 5
	} else {
		.menubar.view entryconfigure 5 -command {
			grid remove .buttonbar 
			set show_buttonbar "no"
			toggle_buttonbar
		} -label "Hide Toolbar" -state normal -underline 5
	}
}

proc trim_log {} {
	
global backup_log debug_out keep_log old_log_values su_cmd win_mainx win_mainy password
# trim the pacman log keeping the last keep_log days and, optionally, a backup of the last file
	
	# remember the old value of keep_log in case we cancel
	set old_log_values $keep_log
	puts $debug_out "trim_log - Old value of keep_log is $old_log_values"
	toplevel .trim
	
	set x 240
	set y 120
	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		set x 335
		set y 145
	} 
	get_win_geometry
	set left [expr $win_mainx + {[winfo width .] / 2} - {$x / 2}]
	set down [expr $win_mainy + {[winfo height .] / 2} - {$y / 2}]
	wm geometry .trim ${x}x${y}+$left+$down
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
		-text "Number of days to keep"
	entry .trim.keep \
		-borderwidth 0 \
		-justify right \
		-textvariable keep_log \
		-validate key \
		-validatecommand {expr {%P == 0 || ([string is integer %P] && [string length %P] < 4 && [string first "0" %P] != 0)}} \
		-width 3
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
	label .trim.password_text \
		-text "A password is required"
	label .trim.password_label \
		-text "  Password: "
	entry .trim.password \
		-borderwidth 0 \
		-show * \
		-textvariable password \
		-width 15
	frame .trim.buttons

		button .trim.continue \
			-command {
				if {$keep_log == "" || [string is integer $keep_log] == 0 || [string length $keep_log] > 3} {
					# check that keep_log is a numerical value and less than four characters long
					puts $debug_out "trim_log - keep_log is set to $keep_log which is either not a numerical value or too long"
					tk_messageBox -default ok -detail "The days to keep must be a numerical value between 0 and 999.\nThe number of days to keep has not been changed" -icon warning -message "Error in days to keep the log" -parent . -title "Incorrect Option" -type ok 
					# reset keep_log
					puts $debug_out "trim_log - reset the keep_log value to \"$old_log_values\""
					set keep_log $old_log_values
				} else {
					set logfile [find_pacman_config logfile]
					if {[file exists $logfile]} {
						puts $debug_out "trim_log - All tests have passed so trim the log"
						set keep_date [clock format [clock add [clock seconds] -$keep_log day] -format {%Y-%m-%d}]
						puts $debug_out "trim_log - keep $keep_log days, from $keep_date"
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
					# if su_cmd is su -c or sudo then run the script in a terminal
						if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
						 	set fid [open $tmp_dir/trim_log.sh w]
							puts $fid "#!/bin/sh"
							if {$backup_log == yes} {
								puts $debug_out "trim_log - Copy log file to backup"
								puts $fid "echo $password | su -c \"cp $logfile ${logfile}.bak\" 2>&1 >/dev/null"
								puts $fid "if \[ \$? -ne 0 \]; then exit 1; fi"
						 	}
							puts $fid "echo $password | su -c \"cp $tmp_dir/pacman.log.tmp $logfile\" 2>&1 >/dev/null"
							puts $fid "if \[ $? -ne 0 \]; then exit 2; fi"
							puts $fid "rm $tmp_dir/pacman.log.tmp"
							puts $fid "if \[ \$? -ne 0 \]; then exit 3; fi"
							close $fid
							exec chmod 0755 "$tmp_dir/trim_log.sh"
							puts $debug_out "trim_log - now run the shell script"
							set error [catch {eval [concat exec "$tmp_dir/trim_log.sh"]} result]
							puts $debug_out "trim_log - trim_log.sh ran with error $error and result $result"
						 	if {$error == 1} {
								if {[string first "Authentication failure" $result] != -1} {
									puts $debug_out "trim_log - Authentification failed"
									set_message terminal "Authentification failed - Clean Pacman Log cancelled"
								} else {
									puts $debug_out "trim_log - Backup log file failed"
									set_message terminal "Could not backup log file - Clean Pacman Log cancelled"
								}
							} elseif {$error == 2} {
								puts $debug_out "trim_log - Copy new log file failed"
								set_message terminal "Could not write new log file - Clean Pacman Log failed"
							} elseif {$error == 3} {
								puts $debug_out "trim_log - Remove temporary log file failed"
								set_message terminal "Clean Pacman Log complete but failed to delete temporary log file"
							}
							file delete "$tmp_dir/trim_log.sh"
						} else {
							if {$backup_log == yes} {
								puts $debug_out "trim_log - Copy log file to backup"
								set error [catch {eval [concat exec $su_cmd cp $logfile ${logfile}.bak]} result]
								if {$error != 0} {
									puts $debug_out "trim_log - Backup log file failed with error $error and result $result"
									set_message terminal "Could not backup log file - Clean Pacman Log cancelled"
								}
							}
							if {$error == 0} {
								set error [catch {eval [concat exec $su_cmd cp $tmp_dir/pacman.log.tmp $logfile]} result]
								if {$error != 0} {
									puts $debug_out "trim_log - Copy new log file failed"
									set_message terminal "Could not write new log file - Clean Pacman Log failed"
								} 
							}
							file delete $tmp_dir/pacman.log.tmp
						}
					} else {
						tk_messageBox -default ok -detail "" -icon error -message "The pacman log file ($logfile) is missing." -parent . -title "Error" -type ok
					}
					if {$error == 0} {
						set_message terminal "Clean Pacman Log completed"
						after 3000 {set_message terminal ""}
					} else {
						# error report, leave it on screen for a little longer
						after 5000 {set_message terminal ""}
					}
					puts $debug_out "trim_log - completed"
					grab release .trim
					destroy .trim
				}
			} \
			-text "Continue"
		button .trim.cancel \
			-command {
				set keep_log $old_log_values
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
	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		grid .trim.password_text -in .trim -row 4 -column 2 \
			-columnspan 3 \
			-sticky w
		grid .trim.password_label -in .trim -row 5 -column 2 \
			-sticky w
		grid .trim.password -in .trim -row 5 -column 4 \
			-sticky e
	}
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
	
	balloon_set .trim.keep_label "The number of days of history to keep\nToday is always saved"
	balloon_set .trim.keep "The number of days of history to keep\nToday is always saved"
	balloon_set .trim.save_label "Save a backup of the pacman log at /var/log/pacman.log.bak"
	balloon_set .trim.yes_no "Save a backup of the pacman log at /var/log/pacman.log.bak"
	balloon_set .trim.continue "Clean the pacman log"
	balloon_set .trim.cancel "Cancel - do not clean the log"

	grab set .trim
}

proc update_cups {} {

global debug_out home message su_cmd
# if we have gutenprint installed then run cups-genppdupdate
# run systemctl daemons-reload and then restart cups.

	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		# looks like we will have to do this in a terminal
		set command ""
		set message ""
		set return [catch {exec which cups-genppdupdate}]
		if {$return != 1} {
			puts $debug_out "update_cups added cups-genppdupdate to the command to run"
			set command [string trim [concat $command cups-genppdupdate]]
		}
		puts $debug_out "update_cups added systemctl daemon-reload and systemctl restart org.cups.cupsd to the command to run"
		set command [string trimleft [append command ";" " systemctl daemon-reload; systemctl restart org.cups.cupsd"] { ;}]
		set action "Restart CUPS"
		if {$su_cmd == "su -c"} {
			set command "su -c \"$command\""
			puts $debug_out "***  $command"
		} else {
			set command "sudo sh -c \"$command\""
		}
		set wait true
		execute_command $action $command $wait
	} else {
		# OK, we can do this without opening a terminal
		set return [catch {exec which cups-genppdupdate}]
		if {$return != 1} {
			puts $debug_out "update_cups ran cups-genppdupdate"
			catch {exec $su_cmd cups-genppdupdate}
		}
	
		puts $debug_out "update_cups reloading daemons"
		catch {exec $su_cmd systemctl daemon-reload}
		set return [catch {eval [concat exec $su_cmd systemctl restart org.cups.cupsd]} result]
		if {$return != 0} {
			puts $debug_out "update_cups error while restarting cups: $result"
			set_message terminal "Error while restarting cups"
			return 1
		}
		set_message terminal "Restarted cups"
		puts $debug_out "update_cups restarted cups"	
	}
	
	after 3000 {set_message terminal ""}
	return 0
}

proc update_db {} {

global dbpath debug_out start_time tmp_dir
# make sure that we are using an up to date copy of the sync databases

	puts $debug_out "update_db started ([expr [clock milliseconds] - $start_time])"
	# delete any existinc sync file
    if {[file isfile "$tmp_dir/sync"] == 1} {file delete "$tmp_dir/sync"}
    # make the directory if it does not exist already
    file mkdir "$tmp_dir/sync"
	set sync_dbs [glob -nocomplain "$dbpath/sync/*.db"]
	foreach item $sync_dbs {
		file copy -force $item $tmp_dir/sync
	}
	puts $debug_out "update_db completed ([expr [clock milliseconds] - $start_time])"
}

proc view_text {text title} {

global browser debug_out save_geometry geometry_view
# open a window and display some text in it

	catch {destroy .view}
	
	toplevel .view
	
	wm iconphoto .view  view
	wm geometry .view $geometry_view
	wm protocol .view WM_DELETE_WINDOW {
		.view.close_button invoke
	}
	wm title .view $title
	
		text .view.listbox \
			-background white \
			-selectforeground red \
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
				if {[string tolower $save_geometry] == "yes"} {set geometry_view [wm geometry .view]; put_configs}
				after 5000 {set_message terminal ""}
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
			puts $debug_out "View-text button 3 pressed"
			if {[.view.listbox tag ranges sel] != ""} {
				tk_popup .dataview_popup %X %Y 0
			}
		}
	
		
	# Set up some tags for the text field '.view.listbox'
	# make the URL blue
		.view.listbox tag configure url_tag -foreground blue 
	# set the cursor to a left pointer when hovering over the text
		.view.listbox tag bind url_cursor_in <Enter> ".view.listbox configure -cursor left_ptr"
	# set the cursor to the default when leaving the text
		.view.listbox tag bind url_cursor_out <Leave> ".view.listbox configure -cursor [.view.listbox cget -cursor]"
	# set the text background colour
		.view.listbox tag configure background_tag -background "#F6FAA0"
	# set the text to bold
		.view.listbox tag configure bold_tag -font "TkHeadingFont" 
	# set the text to centred
		.view.listbox tag configure centred_tag -justify center 	
	# set the text to fixed width
		.view.listbox tag configure fixed_tag -font "TkFixedFont"
	# set the one indent value
		.view.listbox tag configure indent1_tag -lmargin2 "[expr {4 * [font measure TkTextFont 0]}]" 
	# set the two indent value
		.view.listbox tag configure indent2_tag -lmargin2 "[expr {8 * [font measure TkTextFont 0]}]" 
	# set the three indent value
		.view.listbox tag configure indent3_tag -lmargin2 "[expr {12 * [font measure TkTextFont 0]}]" 
		
	.view.listbox insert 0.0 $text
	
	# replace any code strings with their tags
	
	view_text_codes $text "<centre>" "</centre>" centred_tag
	view_text_codes $text "<pre>" "</pre>" fixed_tag
	view_text_codes $text "<strong>" "</strong>" bold_tag
	view_text_codes $text "<lm1>" "</lm1>" indent1_tag
	view_text_codes $text "<lm2>" "</lm2>" indent2_tag
	view_text_codes $text "<lm3>" "</lm3>" indent3_tag
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
			.view.listbox tag bind get_url($count) <ButtonRelease-1> "exec $browser $text_url &"
			puts $debug_out "view_text found http at $index : $text_url : get_url($count) set to exec $browser $text_url &"
			# now replace the text with the text plus all of its tags
			puts $debug_out "view_text replace text $text_url at $index to $start_index with the text plus tags"
			.view.listbox tag add url_tag $index $start_index 
			.view.listbox tag add get_url($count) $index $start_index
			.view.listbox tag add url_cursor_in $index $start_index
			.view.listbox tag add url_cursor_out $index $start_index
			incr count
			
		}
	}
	
	.view.listbox configure -state disabled
	
}
	
proc view_text_codes {text start_code end_code tag} {
	
global debug_out
# read through some text and replace a set of codes with a given tag
	
	set start_count [string length $start_code]
	set end_count [string length $end_code]
	
	puts $debug_out "view_text_codes called with text $start_code $end_code $start_count $end_count $tag"
	
	set count 0
	set from 0
	set start 0
	set start_index 0.0
	set end_index 0.0
	set to 0
	
	while {true} {
		# set from to the start of the code string
		puts $debug_out "Search for ${start_code} in text [string first $start_code $text $start]"
		set from [string first ${start_code} $text $start]
		# no code string? exit the while loop
		if {$from == -1} {break}
		# find the end of the text string
		puts $debug_out "Search for ${end_code} in text [string first $end_code $text $start]"
		set to [expr [string first ${end_code} $text $start] + $start_count]
		# start the next string search from the end of the last string found
		set start $to+1
		# and store the string
		set text_code [string range $text $from $to]
		puts $debug_out "view_text_codes found start code at $from  to $to: $text_code"
		
		# locate the same string in the view.listbox
		# find the start index of that particular text string, the first character of the code string
		set start_index [.view.listbox search -forward $text_code $start_index]
		# and the end index of that string, the last character of the end code string
		set end_index $start_index+[string length $text_code]indices
		# now remove the code tags
		puts $debug_out "Start Index is $start_index End Index is $end_index"
		.view.listbox delete $start_index $start_index+${start_count}indices $end_index-${end_count}indices $end_index 
		# now add the tags to the text found
		set all_count [expr $start_count + $end_count]
		.view.listbox tag add $tag $start_index $end_index-${all_count}indices
		# and set the next start index position
		set start_index $end_index
	}

}

# MAIN 

puts $debug_out "Main reached - ([expr [clock milliseconds] - $start_time])"

# set configurable variables to sane values
configurable
puts $debug_out "Pre configuration file: browser set to \"$browser\", editor set to \"$editor\", terminal set to \"$terminal\" ([expr [clock milliseconds] - $start_time])"
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
puts $debug_out "Database directory is $dbpath"
puts $debug_out "Link local directory in $tmp_dir/local"
file link $tmp_dir/local $dbpath/local
# check last modified times for each pacman database 
# and get a list of repos at the same time
# check that the temporary sync database exists
set times [get_sync_time]
set sync_time [lindex $times 0]
set update_time [lindex $times 1]
puts $debug_out "Post configuration file: browser set to \"$browser\", editor set to \"$editor\", terminal set to \"$terminal\" ([expr [clock milliseconds] - $start_time])"

# WINDOW

# Set up screen

puts $debug_out "Start Window set up - ([expr [clock milliseconds] - $start_time])"
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
				if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]; put_configs} 
				# delete the aur_upgrades directory and all of its contents
				# any aur packages with incomplete downloads or upgrades will have to be restarted
				puts $debug_out "wm exit - delete $tmp_dir/aur_upgrades and its contents"
				file delete -force "$tmp_dir/aur_upgrades"
				close $debug_out
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
					puts $debug_out ".menubar.tools  call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
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
			.menubar.tools add command -command {aur_install} -label "Install AUR/Local" -state normal -underline 12
			.menubar.tools add command -command {update_cups} -label "Update Cups" -state normal -underline 0
			.menubar.tools add separator
			.menubar.tools add command -command {configure} -label Options -state normal -underline 0
	menu .menubar.view -tearoff 0
		.menubar add cascade -menu .menubar.view -label View -underline 0
		.menubar.view add command -command {read_news} -label "Latest News" -state normal -underline 0
		.menubar.view add command -command {read_config} -label "Pacman Configuration" -state normal -underline 7
		.menubar.view add command -command {read_log} -label "Recent Pacman Log" -state normal -underline 0
		.menubar.view add separator
		.menubar.view add command -command {
			. configure -menu ""
			.listview_popup add separator
			.listview_popup add command -label "Show Menu" -command {
				. configure -menu .menubar
				set show_menu "yes"
				.listview_popup delete 5 6		
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
				puts $debug_out ".buttonbar.install_button call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
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
	
	button .buttonbar.configure_button \
		-command {configure} \
		-image tools \
		-relief flat
	
	label .buttonbar.label_message \
		-anchor center \
		-textvariable message
		
	label .buttonbar.label_find \
		-anchor e \
		-foreground Blue \
		-text "Find " \
		-width 10

	button .buttonbar.clear_find_button \
		-command {
			puts $debug_out ".buttonbar.clear_find_button removed find entry"
			.buttonbar.entry_find delete 0 end
			# .buttonbar.entry_find -validatecommand will update everything
		} \
		-image clear \
		-relief flat


# bindings to change the type of find command displayed

	bind .buttonbar.label_find <ButtonRelease> {
		if {$findtype == "find"} {
			puts $debug_out "Find label clicked - Find is $find"
			set findtype "findname"
			# keep the entry in the find field
			puts $debug_out "ButtonRelease on .buttonbar.label_find turned find validate on"
			.buttonbar.entry_find configure -validate key
			if {$find != ""} {filter}
			puts $debug_out "Find type is $findtype (Find is $find)"
			.buttonbar.label_find configure -text "Find Name "
			puts $debug_out "Find text set to Find Name"
			balloon_set .buttonbar.entry_find "Find a package name in the list displayed"
			focus .buttonbar.entry_find
		} elseif {$findtype == "findname"} {
			puts $debug_out "Find Name label clicked"
			set findtype "findfile"
			# keep the entry from the find field
			set findfile $find
			# but forget it for the find/find name field
			set find ""
			.buttonbar.entry_find delete 0 end
			filter
			puts $debug_out "ButtonRelease on .buttonbar.label_find turned find validate on"
			.buttonbar.entry_find configure -validate key
			set_message find ""
			puts $debug_out "Find type is $findtype (Find File)"
			.buttonbar.label_find configure -text "Find File "
			puts $debug_out "Find text set to Find File"
			update
			.buttonbar.clear_find_button configure -command {
				puts $debug_out ".buttonbar.clear_find_button removed findfile entry"
				set findfile ""
				set_message find ""
				filter
			}
			balloon_set .buttonbar.entry_findfile "Find the package which owns a file\n(enter the full path to the file name)" 
			grid remove .buttonbar.entry_find
			grid .buttonbar.entry_findfile -in .buttonbar -row 1 -column 9 \
				-sticky we
			focus .buttonbar.entry_findfile
		} elseif {$findtype == "findfile"} {
			puts $debug_out "Find File label clicked"
			set findtype "find"
			set_message find ""
			filter
			puts $debug_out "Find type is $findtype"
			.buttonbar.label_find configure -text "Find "
			.buttonbar.clear_find_button configure -command {
				puts $debug_out ".buttonbar.clear_find_button removed find entry"
				.buttonbar.entry_find delete 0 end
				# .buttonbar.entry_find -validatecommand will update everything
			}
			balloon_set .buttonbar.entry_find "Find some data in the list displayed\n(excluding the Repository name)"
			grid remove .buttonbar.entry_findfile
			grid .buttonbar.entry_find -in .buttonbar -row 1 -column 9 \
				-sticky we
			focus .buttonbar.entry_find
		}
	}

# Alternate labels and entries to find some data in any field in the current list
		
	entry .buttonbar.entry_find \
		-foreground Blue \
		-takefocus 0 \
		-textvariable find \
		-validate key \
		-validatecommand {
			# Backspace plus repeat key crashes the programme if the string is 2 characters or more
			# so we need to update idletasks
			update idletasks
			puts $debug_out ".buttonbar.entry_find - find string is %P"
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
	
	# remove any selection before pasting from the clipboard with Shift-Insert
	bind .buttonbar.entry_find <Shift-Insert> {
		catch {.buttonbar.entry_find delete sel.first sel.last}
		update idletasks
		.buttonbar.entry_find insert insert [clipboard get]
	}

	# run the find if return has been pressed, to find strings of less than 3 characters and reset the validate key
	bind .buttonbar.entry_find <Return> {
		puts $debug_out "Return Key ran find $find"
		if {[string length $find] > 0} {
			if {$findtype == "findname"} {
				find $find $filter_list name
			} else {
				find $find $filter_list all
			}
		}
		puts $debug_out "Return Key turned find validate on"
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
		-takefocus 0 \
		-textvariable findfile \
		-width 25

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

	bind .buttonbar.entry_findfile <Return> {
		if {$findfile != ""} {		
			# reset the filter and group to all
			set filter "all"
			set group "All"
			# and reconfigure the group list
			.listgroups itemconfigure $group_index -background white
			set group_index 0
			cleanup_checkbuttons false
			
			# set up a command to find the requested file in the database
			# is pkgfile installed
			if {[catch {exec which pkgfile}] != 0} {
			# no - then use pacman	
				# offer to update the file database if it is more than 1 day old
				# we can work out the last update time from the temp databases
				# if all the repo files databases do not exist then create them
				set pacman_database 0
				foreach item $list_repos {
					if {[file exists $tmp_dir/sync/$item.files] == 0} {
						set pacman_database 0
						break
					}
					if {[file mtime $tmp_dir/sync/$item.files] > $pacman_database} {set pacman_database [file mtime $tmp_dir/sync/$item.files]}
				}
				puts $debug_out ".buttonbar.entry_findfile - Pacman databases last updated at [clock_format $pkgfile_database full]"
				set ans "no"
				if {$pacman_database == 0 || $pacman_database == ""} {
					tk_messageBox -default ok -detail "The pacman files databases must be updated now" -icon question -message "One or all of the  pacman files databases is missing." -parent . -title "Install databases" -type ok
					set ans "yes"
				} else {
					if {[expr [clock seconds] > [clock add $pacman_database 1 day]] && $files_upgrade == 0} {
						set ans [tk_messageBox -default yes -detail "Do you want to update the pacman file databases now?" -icon question -message "The pacman file databases were last updated at  [clock_format $pacman_database full]." -parent . -title "Update databases?" -type yesno]
					}
				}
				switch $ans {
					no {set files_upgrade 1}
					yes {
						set action "Update pacman file database"
						set command "$su_cmd pacman -b $tmp_dir -Fy"
						if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Fy\""}
						set wait false
						execute_command $action $command $wait
					}
				}
				set command "pacman -b $tmp_dir -Foq $findfile"
			} else {
			# pkgfile is installed , so use that
				# ask to update the file database if it is more than 1 day old
				# pkgfile stores its data in /var/cache/pkgfile
				# we can work out the last update time from the directory then use that
				# first check if the directory exists and is not empty
				set ans "no"
				if {[file isdirectory /var/cache/pkgfile] == 0 || [llength [glob -nocomplain "/var/cache/pkgfile/*"]] == 0} {
					tk_messageBox -default ok -detail "The pkgfile database must be installed now" -icon question -message "The pkgfile database has not been installed." -parent . -title "Install database" -type ok
					set ans "yes"
				} else {
					set pkgfile_database [file mtime /var/cache/pkgfile]
					puts $debug_out "button_entry_findfile - Pkgfile databases last updated at [clock_format $pkgfile_database full]"
					if {[expr [clock seconds] > [clock add $pkgfile_database 1 day]] && $files_upgrade == 0} {
						set ans [tk_messageBox -default yes -detail "Do you want to update the pkgfile database now?\nPkgfile ships with a systemd service and timer for automatically synchronizing the pkgfile database. To activate automatic updates enable pkgfile-update.timer." -icon question -message "The pkgfile database was last updated at [clock_format $pkgfile_database full]." -parent . -title "Update database?" -type yesno]
					}
				}
				switch $ans {
					no {set files_upgrade 1}
					yes {
						set action "Update pkgfile database"
						set command "$su_cmd pkgfile -u"
						if {$su_cmd == "su -c"} {set command "$su_cmd \"pkgfile -u\""}
						set wait false
						execute_command $action $command $wait
					}	
				}
				set command "pkgfile $findfile"
			}
			# OK, so we know the command to execute, so do it
			set list ""
			set pkglist ""
			set error [catch {eval [concat exec $command]} list]
			# now search the local files list
			set index [lsearch -all -glob $aur_files "*$findfile *"]
			if {$index != ""} {
				puts $debug_out ".buttonbar.entry_findfile - $index local files contain \"$findfile\""
				# pkgfile returns 0 whether or not any files are found
				# pacman returns 1 if no files are found
				if {$error == 0} {
					set list [concat $list [lindex [split [lindex $aur_files $index] " "] 0]]
				} else { 
					set list [lindex [split [lindex $aur_files $index] " "] 0]
					# since there is a local find file result reset error to 0
					set error 0
				}
			} else {
				puts $debug_out ".buttonbar.entry_findfile - no local files contain \"$findfile\""
			}
			if {$error == 0} {
				set list [split $list "\n"]
				puts $debug_out ".buttonbar.entry_findfile - Findfile list is $list"
				foreach item $list {
					puts $debug_out ".buttonbar.entry_findfile - Item is $item"
					puts $debug_out ".buttonbar.entry_findfile - [string last "/" $item]"
					set item [string range $item [string last "/" $item]+1 end]
					puts $debug_out ".buttonbar.entry_findfile - Item is now $item"
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
				set_message terminal "No packages found containing \"$findfile\""
			} elseif {[llength $pkglist] > 1} {
				set_message terminal "[llength $pkglist] packages provide \"$findfile\""
			} else {
				set_message terminal "[llength $pkglist] package provides \"$findfile\""
			}
			if {[string first "pacman" $command] == 0} {
				.wp.wftwo.dataview select .wp.wftwo.dataview.info
				update
				.wp.wftwo.dataview.info insert end "\n"			
				.wp.wftwo.dataview.info insert end "Consider installing pkgfile"
			}

		}
	}

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
		
	button .group_button \
		-command {
			update idletasks
			set selected_list 0
			grid .listgroups
			grid .scroll_selectgroup
		} \
		-image down_arrow
				
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
			update idletasks
			if {$selected_list == 0} {
				set filter "all"
				cleanup_checkbuttons false
				filter
			} else {
				get_aur_updates
			}			
		} \
		-onvalue "aur_updates" \
		-text "AUR/Local Updates" \
		-variable selected_list
		
	checkbutton .filter_list_aur_updates_all \
		-command {
			update idletasks
			puts $debug_out "aur_all set to $aur_all"
			if {$aur_all} {
				puts $debug_out ".filter_list_aur_updates - configured text \"AUR/Local Updates ([llength $list_local])\""
				.filter_list_aur_updates configure -text "AUR/Local Updates ([llength $list_local])"
			} else {
				puts $debug_out ".filter_list_aur_updates - configured text to local_newer \"AUR/Local Updates ($local_newer)\""
				.filter_list_aur_updates configure -text "AUR/Local Updates ($local_newer)"
			}
			if {$selected_list == "aur_updates"} {
				get_aur_updates
			}
		} \
		-offvalue false \
		-onvalue true \
		-text "include all local packages" \
		-variable aur_all
		
	label .filter_warning \
		-image warning
				
	label .filter_clock_label \
		-text "Time since last sync"
		
	label .filter_clock \
		-text ""
		
	label .filter_upgrade_label \
		-text "Last system upgrade"
		
	label .filter_upgrade \
		-text ""
	
# define these widgets last in the filter set so that they cover the other items when they are shown	

	listbox .listgroups \
		-listvariable list_groups \
		-selectmode single \
		-takefocus 0 \
		-yscrollcommand ".scroll_selectgroup set"

	scrollbar .scroll_selectgroup \
		-command ".listgroups yview" \
		-takefocus 0
	
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
frame .wp.wfone

	ttk::treeview .wp.wfone.listview \
		-columns "Repo Package Version Available" \
		-displaycolumns "Package Version Available Repo" \
		-selectmode extended \
		-show headings \
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
		.wp.wfone.listview tag configure selected -foreground [ttk::style lookup Treeview -foreground selected] -background [ttk::style lookup Treeview -background selected]
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
	
		bind .wp.wfone.listview <Shift-ButtonPress-1> {
			set listlast [.wp.wfone.listview identify item %x %y]
			if {$anchor == ""} {set anchor $listlast}
			puts $debug_out "Shift Button clicked on TreeView: Anchor is $anchor First was $listfirst Last is $listlast"
			if {$aur_only == true} {
				puts $debug_out "\taur_only is true"
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
				puts $debug_out "Shift Button in Treeview - there are $count selected"
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
			# find which item was clicked on last
			set listlast [.wp.wfone.listview identify item %x %y]
			# if this item was selected already, then de-select it
			if {[lsearch [.wp.wfone.listview selection] $listlast] != -1} {
				puts $debug_out "Control Button clicked on TreeView - remove Last $listlast, Anchor is $anchor"
				.wp.wfone.listview selection remove $listlast
				break
			}
			# if this is an aur list then only select one item
			if {$aur_only == true} {
				puts $debug_out "Control Button clicked on TreeView but aur_only is true"
				set listfirst $listlast
				.wp.wfone.listview selection set $listfirst
				break
			}
			# if this is the first item selected then set it as the anchor point
			if {$listfirst == ""} {
				puts $debug_out "Control Button clicked on TreeView: Anchor is $anchor Last is $listlast"
				set anchor $listlast
			} else {
				puts $debug_out "Control Button clicked on TreeView: Anchor is $anchor Last is $listlast First is $listfirst"
			}
			# finish off - add the new item to the selection list and save it as first
			.wp.wfone.listview selection add $listlast
			set listfirst $listlast
			break
		}	
		bind .wp.wfone.listview <ButtonPress-1> {
			if {[.wp.wfone.listview identify region %x %y] == "heading" || [.wp.wfone.listview identify region %x %y] == "separator"} {
				puts $debug_out "Button clicked on Treeview: column [string trim [.wp.wfone.listview identify column %x %y] \#] [.wp.wfone.listview identify region %x %y]"
			} else {	
				set listlast [.wp.wfone.listview identify item %x %y]
				set anchor $listlast
				set listfirst ""
				puts $debug_out "Button clicked on TreeView: Anchor is $anchor Last is $listlast"
				.wp.wfone.listview selection set $listlast
			}
			# now run the standard binding for treeview
			# this seems to mean that TreeviewSelect can be called twice for the same selection
		}
	
		bind .wp.wfone.listview <<TreeviewSelect>> {	
			# the selection has changed! What is the new selection?
			set listview_selected [.wp.wfone.listview selection]

			puts $debug_out "TreeviewSelect - there is a new selection: $listview_selected\n\tthe previous selection was $listview_last_selected"
			
			# check if anchor still exists, if not then set the anchor to the first item selected, or blank if nothing is selected
			if {[lsearch $listview_selected $anchor] == -1} {set anchor [lindex $listview_selected 0]}
			# first get rid of any obvious anomolies
			# if nothing has really changed then break out of the script
			# it seems that TreeviewSelect is not actually triggered by a change in the selection, but by the other bindings
			# since we changed the other bindings it can be triggered twice, so get rid of the second one as soon as possible.
			# if we selected the same item a second time then we presume that we wanted to clear that selection
			# we need this because we haven't handled all the possibilities in the button bindings
			if {[llength $listview_selected] == 1 && $listview_selected == $listview_selected_in_order} {
				puts $debug_out "Treeview selection $listview_selected has been selected twice so remove it"
				.wp.wfone.listview selection remove $listview_selected
				# bind TreeviewSelect will update all the variables when the selection changes
				# now break out of the bind script
				set tvselect "break"
				break
			}
			if {$listview_selected == $listview_last_selected} {
				puts $debug_out "Treeview selection has not changed so break out of the script"
				# just check that we are not in AUR/Local, if we are then we cannot Select All, even if nothing is selected
				# this is necessary because we may have an AUR/Local item selected and have just checked AUR/Local
				if {$aur_only == true} {
					.menubar.edit entryconfigure 0 -state disabled
					.listview_popup entryconfigure 3 -state disabled
				}
				# now break out of the bind script
				set tvselect "break"
				break
			}
			# so the selection has changed so reset the upgrades list
			set upgrades ""
			set upgrades_count 0
			# if the selection changed but nothing is selected now
			if {$listview_selected == ""} {
				puts $debug_out "TreeviewSelect - there is nothing selected so break out of the script"
				if {$listview_last_selected != ""} {get_dataview ""}
				set listview_current ""
				set listview_last_selected ""
				set listview_selected_in_order ""
				set_message selected ""
				puts $debug_out "TreeviewSelect - set the nothing selected menus states" 
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
				set tvselect "break"
				break
			}
			set listview_last_selected $listview_selected
			# update now to show the selection before analyzing it.
			update
			# find whether we need to install or delete the packages selected
			set listview_values ""
			set state ""
			# if there is nothing in the list then disable everything
			# we need this because the selection changed so the options may have changed as well
			if {[llength $list_show] == 0} {
				puts $debug_out "there is nothing in the treeview list!"
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
				# break out of the loop and complete the bind script
				set tvselect "break"
				break
			# if only one item is selected and it is in the aur updates list 
			# which is a given because only one item can be selected in the aur updates list
			# then it can be only be updated, re-installed or deleted
			# we need this here to avoid the other checks in the foreach loop below
			} elseif {$aur_only == true && [llength $listview_selected] == 1} {
				puts $debug_out "TreeviewSelect - something selected and AUR only is true"
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
				puts $debug_out "TreeviewSelect - running tests foreach item in $listview_selected"
				set count 0
# start foreach loop
				foreach item $listview_selected {
					incr count
					puts $debug_out "\t$item is $count loop"
					set listview_values [.wp.wfone.listview item $item -values]
					puts $debug_out "TreeviewSelect - test next $item [lrange $listview_values 1 1]"
# if the item has not been installed
					if { [lrange $listview_values 3 3] == "{}"} {
						# if the item has not been installed then we should install it
						# not delete it
						# local packages cannot be installed here, but will show something, version or "-na-", in the fourth field!
						puts $debug_out "\t$item has not been installed"
						if {$tverr_text == ""} {
							set tverr_text [list $item "[lrange $listview_values 1 1] can only be installed"]
						} else {
							set tverr_text [lappend tverr_text $item "[lrange $listview_values 1 1] can only be installed"]
						}
						puts $debug_out "\t$tverr_text"
						if {$state == "" || $state == "install"} {
							set state "install"
							puts $debug_out "\tset state to install"
						} elseif {$state == "install or re-install"} {
							puts $debug_out "\tstate is already install or re-install"
						} elseif {$state == "re-install or delete"} {
						# unless one of the previous selected packages was local, in which case this would be an error
							puts $debug_out "\tset state to install or re-install"
							set state "install or re-install"
						} else {
						# so state must be "delete" which is an error
							puts $debug_out "\tset state to error"
							set state "error"
						}						
						# so this item is installed look at the next item
# if the item is outdated and is not a local package
					} elseif {[lrange $listview_values 3 3] != [lrange $listview_values 2 2] && [lrange $listview_values 0 0] != "local"} {
						if {$fs_upgrade == false} {
							puts $debug_out "TreeviewSelect - FS_Upgrade is $fs_upgrade"
							puts $debug_out "TreeviewSelect - [lindex $listview_values 1] upgrade from [lrange $listview_values 2 2] to [lrange $listview_values 3 3]"
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
									puts $debug_out "TreeviewSelect - answer to partial upgrade all packages warning message is $ans" 
									switch $ans {
										"yes" {
											puts $debug_out "\tPartial Upgrades set to no, Full System Upgrade set to true"
											set part_upgrade 0
											set fs_upgrade true
											# run a full system upgrade and kill this bind script
											system_upgrade
											# now break out of the loop and complete the bind script
											set tvselect "break"
											break
										}
										"no" {
											puts $debug_out "\tPartial Upgrades set to yes - 1"
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
									puts $debug_out "TreeviewSelect - added [lrange $listview_values 1 1] to upgrade list ($upgrades)"
								} elseif {$upgrades_count == 15} {
									set upgrades [lappend upgrades  etc ...]
									puts $debug_out "TreeviewSelect - added \" etc ...\" to upgrade list ($upgrades)"
								}
								puts $debug_out "TreeviewSelect - $upgrades_count upgrades selected."
							}
							
						}
						puts $debug_out "\t$item has been installed and is not a local package"
						# if any previous items were set to install it can only be re-installed
						if {$state == "install" || $state == "install or re-install"} {
							# then there must be an "install only" item selected previously"
							puts $debug_out "\tset state to install or re-install"
							set state "install or re-install"
						} elseif {$state == "delete"} {
							puts $debug_out "\tset state to delete"
						} else {
							puts $debug_out "\tset state to re-install or delete"
							set state "re-install or delete"
						}
# if the item is a local package then it can only be deleted unless we are in AUR/Local Updates
					} elseif {[lrange $listview_values 0 0] == "local"} {
						puts $debug_out "\t$item is local and aur_only is $aur_only"
						# if it is a local package, we can only delete it here
						if {$aur_only == false} {
							if {$state == "install" || $state == "install or re-install"} {
								puts $debug_out "$item is local and state is set to $state"
								set ans [tk_messageBox -default yes -detail "Answer Yes to continue without selecting \"[lindex $listview_values 1]\"\nAnswer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and cannot be  re-installed from here." -parent . -title "Warning" -type yesno]
								puts $debug_out "Answer to install local package warning message is $ans" 
								switch $ans {
									no {
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# break out of the loop and complete the bind script
										# bind TreeviewSelect will update all the variables when the selection changes
										set tvselect "break"
										break
									}
									yes {
										# if the response is Continue (1), then deselect item and continue with the next item in the foreach loop.
										.wp.wfone.listview selection remove $item
										# bind TreeviewSelect will update all the variables when the selection changes
										# so break out of the loop and complete the bind script
										set tvselect "break"
										break
									}	
								}
							} elseif {$state == "delete"} {
								puts $debug_out "$item is local and state is delete"
								# bind TreeviewSelect will update all the variables when the selection changes
							} elseif {[string first "delete" $state] != -1} {
								puts $debug_out "$item is local and state includes delete"
								set ans [tk_messageBox -default yes -detail "Do you want to continue selecting packages to delete, answer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and can only be deleted from here." -parent . -title "Warning" -type yesno]
								puts $debug_out "\tanswer to delete local package warning message is $ans" 
								switch $ans {
									no {
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# bind TreeviewSelect will update all the variables when the selection changes
										set tvselect "break"
										break
									}
									yes {
										# if the response is Continue (1), then set delete and continue with the next item in the foreach loop.
										set state "delete"
										puts $debug_out "\tset to delete"
									}	
								}
							} elseif {$state == "error"} {
								puts $debug_out "\tpreviously set to error"
							} else {
								set state "delete"
								puts $debug_out "\tset to delete"
							}
							if {$tverr_text == ""} {
								set tverr_text [list $item "[lrange $listview_values 1 1] is a local package and can only be deleted"]
							} else {
								set tverr_text [lappend tverr_text $item "[lrange $listview_values 1 1] is a local package and can only be deleted"]
							}
							puts $debug_out "\t$tverr_text"
						} else {
							# so aur_only is true
							set state "update, re-install or delete"
							puts $debug_out "\tset to re-install or delete"
						}
# so the item is installed, is not outdated and is not a local package
					} else {
						if {$state == "" || $state == "re-install or delete"} {
							puts $debug_out "\tset state to re-install or delete"
							set state "re-install or delete"
						} elseif {$state == "install" || $state == "install or re-install"} {
							puts $debug_out "\tset state to install or re-install"
							set state "install or re-install"
						} else {
							puts $debug_out "\t$item can only be re-installed or deleted"
							# if the existing state includes delete then select that, otherwise it is an error
							if {[string first "delete" $state] == -1} {
								set state "error"
							} else {
								tk_messageBox -default ok -detail "To Install or Reinstall [lindex $listview_values 1] deselect all the selected local packages." -icon warning -message "A local package is selected so [lindex $listview_values 1] can only be deleted." -parent . -title "Warning" -type ok
								set state "delete"
							}
						}
					}
				}
# end foreach loop
# now check for any errors in the new selection
				puts $debug_out "TreeviewSelect - sort all items completed - check for errors"
				set tverr_message ""
				if {$state == "error"} {
					set index ""
					set message ""
					foreach {index message} $tverr_text {
						set tverr_message "$tverr_message \n$message"
					}
					puts $debug_out "TreeviewSelect -there are potential errors in the selected list"	
					if {[string first "deleted" $tverr_text] != -1} {puts $debug_out "deleted found in error text"}
					if {[string first "installed" $tverr_text] != -1} {puts $debug_out "installed found in error text"}
					set ans [tk_messageBox -default ok -detail "" -icon warning -message $tverr_message -parent . -title "Errors were found in the Selection" -type ok]
					puts $debug_out "\tanswer to local package warning message is $ans" 
					all_clear
				}
			}
# everthing has been checked so finish the set up
			if {$listview_selected != ""} {
				puts $debug_out "TreeviewSelect - something is selected so set the correct menus states" 
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
					# now lets work out the last selected item to pass to get_dataview
					# add any newly selected items to listview_selected_in_order
					foreach item $listview_selected {
						# if the item from listview_selected does not exist in listview_selected_in_order then add it at the end of listview_selected_in_order
						if {[string first $item $listview_selected_in_order] == -1} {
							lappend listview_selected_in_order $item
						}
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
				puts $debug_out "TreeviewSelect - selection in order is now $listview_selected_in_order"
			}
			# set the message text
			if {[llength $listview_selected] == 0} {
				puts $debug_out "TreeviewSelect - set_message selected blanked"
				set_message selected ""
			} elseif {[llength $listview_selected] > 1} {
				set_message selected "[llength $listview_selected] items selected to $state"
			} else {
				set_message selected "[llength $listview_selected] item selected to $state"
			}
			# if more than one item was selected in the last selection then choose the last one
			set listview_current [lindex $listview_selected_in_order end]
			# now update whatever the tag is in the dataview window
			puts $debug_out "TreeviewSelect - selection changed - call dataview with $listview_current"
			get_dataview $listview_current
			puts $debug_out "TreeviewSelect - updated dataview"
			# change a variable to allow for a vwait command if necessary
			set tvselect "done"
			puts $debug_out "TreeviewSelect - tvselect is now $tvselect\n\tlistview_selected_in_order is $listview_selected_in_order "
		}	

# set up a popup menu for listview
	option add *tearOff 0
	menu .listview_popup -cursor left_ptr
	.listview_popup add command -label "Full System Upgrade" -command {system_upgrade} -state normal
	.listview_popup add command -label "Install" -command {
		if {$aur_only} {
			puts $debug_out ".buttonbar.install_button call aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] \"upgrade\""
			aur_upgrade [lrange [.wp.wfone.listview item [.wp.wfone.listview selection] -values] 1 1] "upgrade"
		} else {
			execute install
		}
	} -state disabled
	.listview_popup add command -label "Delete" -command {execute delete} -state disabled
	.listview_popup add command -label "Select All" -command {all_select} -state normal
	.listview_popup add command -label "Clear All" -command {all_clear} -state disabled
# and set up a binding to open it at the cursor position
	bind .wp.wfone.listview <ButtonRelease-3> {
		puts $debug_out "Button 3 pressed on listview at %X %Y ([.wp.wfone.listview identify region %x %y] [.wp.wfone.listview identify column %x %y])"
		# do not pop up the menu if we clicked on the heading row
		if {[.wp.wfone.listview identify region %x %y] != "heading" && [.wp.wfone.listview identify region %x %y] != "separator"} {
			tk_popup .listview_popup %X %Y 0
		}
		break
	}
# set button-3 on the popup menu to re-open it at the new position
	bind .listview_popup <ButtonRelease-3> {
		puts $debug_out "Button 3 pressed on listview_popup at %X %Y"
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
frame .wp.wftwo
	
# Insert a ttk::notebook with tab widths set to 10 and centred

ttk::style configure TNotebook.Tab -width 10
ttk::style configure TNotebook.Tab -anchor center 	
ttk::notebook .wp.wftwo.dataview \
	
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
		puts $debug_out "Dataview tab changed - call get_dataview ([expr [clock milliseconds] - $start_time])"
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
		# grid a warning
		grid .filter_warning -in .filters -row 14 -column 3 \
			-sticky nswe
		# and remove it until needed
		grid remove .filter_warning
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
	
	grid columnconfigure .wp.wfone 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .wp.wfone 2 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .wp.wfone 1 -weight 1 -minsize 0 -pad 0 
	grid rowconfigure .wp.wfone 2 -weight 0 -minsize 10 -pad 0
	
	grid columnconfigure .wp.wftwo 1 -weight 1 -minsize 0 -pad 0
	grid columnconfigure .wp.wftwo 2 -weight 0 -minsize 10 -pad 0
	grid rowconfigure .wp.wftwo 1 -weight 1 -minsize 0 -pad 0 
	grid rowconfigure .wp.wftwo 2 -weight 0 -minsize 10 -pad 0

# the menu bar is mapped, but remove it if we did not ask for it
if {$show_menu == "no"} {
	. configure -menu ""
	.listview_popup add separator
	.listview_popup add command -label "Show Menu" -command {
		. configure -menu .menubar
		set show_menu "yes"
		.listview_popup delete 5 6	
	} -state normal
}
# the button bar is mapped, but remove it if we did not ask for it
if {$show_buttonbar == "no"} {
	grid remove .buttonbar
	.menubar.view entryconfigure 5 -command {
			grid .buttonbar -in . -row 2 -column 1 -columnspan 3 -sticky ew
			set show_buttonbar "yes"
			toggle_buttonbar
	} -label "Show Toolbar" -state normal -underline 5
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
balloon_set .filter_warning "Vpacman has detected a possible sync error\nConsider running a Full System Upgrade"
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
balloon_set .filter_list_aur_updates "List only local packages which may need to be updated"
balloon_set .filter_list_aur_updates_all "Include all local packages in the AUR/Local Updates list"
balloon_set .scroll_selectgroup "Use right click to jump"
balloon_set .wp.wfone.ylistview_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_files_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_info_scroll "Use right click to jump"
balloon_set .wp.wftwo.ydataview_moreinfo_scroll "Use right click to jump"

puts $debug_out "Completed Window bindings and help set up -([expr [clock milliseconds] - $start_time])"

# THREADS

if {$threads} {
	
puts $debug_out "Start Threads set up -([expr [clock milliseconds] - $start_time])"

	# aur_files
	#	use pacman to get the file list of the AUR/Local packages for a file name search
	# aur_versions
	#	use the download programme to get the available versions of the AUR/Local packages
	
	# create a thread to lookup the files for AUR/local packages
	# this thread will keep running so that it can be used whenever start is called
	
	set aur_files_TID [thread::create {
	
		proc thread_get_aur_files {main_TID list_local} {
			set aur_files ""
			foreach element $list_local {
				# make up a list of all the local packages in the format "package file file file..."
				# and save them in aur_files
				set item [lindex $element 1]
				set aur_files [lappend aur_files [concat "$item" [split [exec pacman -Qlq $item] \n]]]
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
				puts $fid "curl -LfGs \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > \"$tmp_dir/thread_aur_result\""
			} else {
				puts $fid "wget -LqO - \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > \"$tmp_dir/thread_aur_result\""
			}	
			close $fid
			exec chmod 0755 "$tmp_dir/thread_aur_versions.sh"
			exec "$tmp_dir/thread_aur_versions.sh"
			file delete "$tmp_dir/thread_aur_versions.sh"
			
			# read the results into a variable 
			set fid [open $tmp_dir/thread_aur_result]
			gets $fid result
			close $fid
			# and delete the temporary file
			file delete $tmp_dir/thread_aur_result
			# change square brackets to normal brackets
			set result [string map {\[ ( \] )} $result]
			# split the file on each "\},\{"
			set result [regsub -all "\},\{" $result "\n"]
			set result [split $result "\n"]
			foreach line $result {
				# get the name, version available and description of each package in turn, and save it
				set index [string first "Name\":\"" $line] 
					lappend aur_versions [string range $line $index+7 [string first {","} $line $index]-1] 
				set index [string first "Version\":\"" $line] 
					lappend aur_versions [string range $line $index+10 [string first {","} $line $index]-1] 
				set index [string first "Description\":\"" $line] 
					lappend aur_versions [string range $line $index+14 [string first {","} $line $index]-1] 
			}
			# aur_updates should now be a clean list of all the updates including all the local packages if requested
			eval [subst {thread::send -async $main_TID {::put_aur_versions [list $aur_versions]}}]
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
	
puts $debug_out "Completed Threads set up -([expr [clock milliseconds] - $start_time])"

}

# START
set_clock false
.filter_upgrade configure -text [clock_format $update_time short_full]
# draw the screen now to make it appear as if it is loading faster and then run start to get the full list of packages
# note: vpacman takes approx 200 milliseconds to compile to bytecode and start execution
puts $debug_out "Window display - first display show, now update screen ([expr [clock milliseconds] - $start_time])"
update idletasks
# but do not interact with the window
# place a grab on something unimportant to avoid random button presses on the window
puts $debug_out "Grab set ([expr [clock milliseconds] - $start_time])"
grab set .buttonbar.label_message
# call start
start
# we do not need to run the filter/sort procedure here
# an update now would show the list counts in the window before showing the package list
list_show $list_all
# so we have an updated list - set filter_list to the new list
set filter_list $list_all
if {$su_cmd == ""} {
	tk_messageBox -default ok -detail "Some commands cannot be run as root. Consider restarting as a standard user" -icon warning -message "Running vpacman as root is not recommended." -parent . -title "Warning" -type ok
}
if {!$threads} {
	tk_messageBox -default ok -detail "Some functions will be restricted e.g.:\n  files searches will exclude AUR packages.\n  AUR version lookup will be delayed.\n\nConsider installing a threaded version of tcl." -icon warning -message "Running tcl without threading." -parent . -title "tcl not threaded" -type ok
}
# release the grab
grab release .buttonbar.label_message
puts $debug_out "Window display - complete - grab released ([expr [clock milliseconds] - $start_time])"
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
puts $debug_out "Download programme set to $dlprog ([expr [clock milliseconds] - $start_time])"
if {$threads} {
	if {[test_internet] == 0} {
		# if the internet is up then run the aur_versions thread to get the current aur_versions
		puts $debug_out "Call aur_versions thread with main_TID, dlprog, tmp_dir and list_local ([expr [clock milliseconds] - $start_time])"
		thread::send -async $aur_versions_TID [list thread_get_aur_versions [thread::id] $dlprog $tmp_dir $list_local]
	}
	# and the list_groups thread to find all of the groups available
	puts $debug_out "Call list_groups thread with main_TID and tmp_dir ([expr [clock milliseconds] - $start_time])"
	thread::send -async $list_groups_TID [list thread_list_groups [thread::id] $tmp_dir]
} else {
	list_groups
	puts $debug_out "Cannot run versions thread - threads not enabled"
}
# test the current configuration options
test_configs

