#! /bin/wish

#	 This is Vpacman - a programme to View and modify the pacman database
#
#    Copyright (C) 2018  Andrew Myers <andrew dot myers@fdservices dot co dot uk>
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

set args $argv

# Check for required programmes
set required "pacman wmctrl"
foreach programme $required {
	set result [catch {exec which $programme}]
	if {$result == 1} {
		tk_messageBox -default ok -detail "$programme is required by vpacman" -icon warning -message "Failed Dependency" -parent . -title "Error" -type ok
		puts $debug_out "Failed Dependency\n$programme is required by Vpacman"
		close $debug_out
		exit
	}
}

# Declarations
# .. directories
global home icon_dir program_dir tmp_dir
# .. configuration
global config_file 
# ..configurable
global browser buttons editor geometry_config helpbg helpfg installed_colour outdated_colour save_geometry terminal terminal_string
# ..variables
global about_text anchor aur_all aur_messages aur_only aur_updates aur_versions colours count_all count_installed count_outdated count_uninstalled dbpath dirs s_time flag_actions filter filter_list find findfile find_message findtype fs_upgrade geometry group help_text installed_colour known_browsers known_editors known_terminals list_all list_groups list_installed list_local list_outdated list_show list_show_ids list_show_order list_uninstalled listfirst listlast listview_current listview_last_selected listview_selected listview_selected_in_order index message outdated_colour package_actions pu_ans select_all selected_list selected_message state su_cmd tverr_message tverr_text tv_order geometry_view

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

## and what if the user wants to change the icons used?
## maybe make the icon path configurable, in which case the path below may not be ideal - could change it to /vpacman/default?
set icon_dir "/usr/share/pixmaps/vpacman"
file mkdir /tmp/vpacman
set tmp_dir /tmp/vpacman

# Intialise variables

# about text
set about_text "

<centre><strong>vpacman.tcl</strong>
	

View and modify the pacman database

This programme is free software. It is distributed under the terms of the GNU General Public Licence version 3 or any later version.

\"https://www.gnu.org/licenses/gpl.html\"

You may copy it, modify it, and/or redistribute it. 

This programme comes with NO WARRANTY whatsoever, under any circumstances.

vpacman should be installed in /usr/bin and /usr/share/vpacman</centre>"

# three variables use for the alternative treeview bindings
set anchor ""
set listlast ""
set listfirst ""
# do we want to include all the installed local packages in the aur_updates list
set aur_all false
# aur_updates - do we show the warning messages in get_aur_updates or not
set aur_messages "true"
# if only aur packages are listed then set aur_only to true
set aur_only false
# these are the aur packages which could be updated
set aur_updates ""
# the versions found for the aur packages by get_aur_updates
set aur_versions ""
# default browser
set browser ""
# list of all the known colours
set colours "{alice blue} {AliceBlue} {antique white} {AntiqueWhite} {AntiqueWhite1} {AntiqueWhite2} {AntiqueWhite3} {AntiqueWhite4} {aquamarine} {aquamarine1} {aquamarine2} {aquamarine3} {aquamarine4} {azure} {azure1} {azure2} {azure3} {azure4} {beige} {bisque} {bisque1} {bisque2} {bisque3} {bisque4} {black} {blanched almond} {BlanchedAlmond} {blue} {blue violet} {blue1} {blue2} {blue3} {blue4} {BlueViolet} {brown} {brown1} {brown2} {brown3} {brown4} {burlywood} {burlywood1} {burlywood2} {burlywood3} {burlywood4} {cadet blue} {CadetBlue} {CadetBlue1} {CadetBlue2} {CadetBlue3} {CadetBlue4} {chartreuse} {chartreuse1} {chartreuse2} {chartreuse3} {chartreuse4} {chocolate} {chocolate1} {chocolate2} {chocolate3} {chocolate4} {coral} {coral1} {coral2} {coral3} {coral4} {cornflower blue} {CornflowerBlue} {cornsilk} {cornsilk1} {cornsilk2} {cornsilk3} {cornsilk4} {cyan} {cyan1} {cyan2} {cyan3} {cyan4} {dark blue} {dark cyan} {dark goldenrod} {dark gray} {dark green} {dark grey} {dark khaki} {dark magenta} {dark olive green} {dark orange} {dark orchid} {dark red} {dark salmon} {dark sea green} {dark slate blue} {dark slate gray} {dark slate grey} {dark turquoise} {dark violet} {DarkBlue} {DarkCyan} {DarkGoldenrod} {DarkGoldenrod1} {DarkGoldenrod2} {DarkGoldenrod3} {DarkGoldenrod4} {DarkGray} {DarkGreen} {DarkGrey} {DarkKhaki} {DarkMagenta} {DarkOliveGreen} {DarkOliveGreen1} {DarkOliveGreen2} {DarkOliveGreen3} {DarkOliveGreen4} {DarkOrange} {DarkOrange1} {DarkOrange2} {DarkOrange3} {DarkOrange4} {DarkOrchid} {DarkOrchid1} {DarkOrchid2} {DarkOrchid3} {DarkOrchid4} {DarkRed} {DarkSalmon} {DarkSeaGreen} {DarkSeaGreen1} {DarkSeaGreen2} {DarkSeaGreen3} {DarkSeaGreen4} {DarkSlateBlue} {DarkSlateGray} {DarkSlateGray1} {DarkSlateGray2} {DarkSlateGray3} {DarkSlateGray4} {DarkSlateGrey} {DarkTurquoise} {DarkViolet} {deep pink} {deep sky blue} {DeepPink} {DeepPink1} {DeepPink2} {DeepPink3} {DeepPink4} {DeepSkyBlue} {DeepSkyBlue1} {DeepSkyBlue2} {DeepSkyBlue3} {DeepSkyBlue4} {dim gray} {dim grey} {DimGray} {DimGrey} {dodger blue} {DodgerBlue} {DodgerBlue1} {DodgerBlue2} {DodgerBlue3} {DodgerBlue4} {firebrick} {firebrick1} {firebrick2} {firebrick3} {firebrick4} {floral white} {FloralWhite} {forest green} {ForestGreen} {gainsboro} {ghost white} {GhostWhite} {gold} {gold1} {gold2} {gold3} {gold4} {goldenrod} {goldenrod1} {goldenrod2} {goldenrod3} {goldenrod4} {gray} {gray0} {gray1} {gray2} {gray3} {gray4} {gray5} {gray6} {gray7} {gray8} {gray9} {gray10} {gray11} {gray12} {gray13} {gray14} {gray15} {gray16} {gray17} {gray18} {gray19} {gray20} {gray21} {gray22} {gray23} {gray24} {gray25} {gray26} {gray27} {gray28} {gray29} {gray30} {gray31} {gray32} {gray33} {gray34} {gray35} {gray36} {gray37} {gray38} {gray39} {gray40} {gray41} {gray42} {gray43} {gray44} {gray45} {gray46} {gray47} {gray48} {gray49} {gray50} {gray51} {gray52} {gray53} {gray54} {gray55} {gray56} {gray57} {gray58} {gray59} {gray60} {gray61} {gray62} {gray63} {gray64} {gray65} {gray66} {gray67} {gray68} {gray69} {gray70} {gray71} {gray72} {gray73} {gray74} {gray75} {gray76} {gray77} {gray78} {gray79} {gray80} {gray81} {gray82} {gray83} {gray84} {gray85} {gray86} {gray87} {gray88} {gray89} {gray90} {gray91} {gray92} {gray93} {gray94} {gray95} {gray96} {gray97} {gray98} {gray99} {gray100} {green} {green yellow} {green1} {green2} {green3} {green4} {GreenYellow} {grey} {grey0} {grey1} {grey2} {grey3} {grey4} {grey5} {grey6} {grey7} {grey8} {grey9} {grey10} {grey11} {grey12} {grey13} {grey14} {grey15} {grey16} {grey17} {grey18} {grey19} {grey20} {grey21} {grey22} {grey23} {grey24} {grey25} {grey26} {grey27} {grey28} {grey29} {grey30} {grey31} {grey32} {grey33} {grey34} {grey35} {grey36} {grey37} {grey38} {grey39} {grey40} {grey41} {grey42} {grey43} {grey44} {grey45} {grey46} {grey47} {grey48} {grey49} {grey50} {grey51} {grey52} {grey53} {grey54} {grey55} {grey56} {grey57} {grey58} {grey59} {grey60} {grey61} {grey62} {grey63} {grey64} {grey65} {grey66} {grey67} {grey68} {grey69} {grey70} {grey71} {grey72} {grey73} {grey74} {grey75} {grey76} {grey77} {grey78} {grey79} {grey80} {grey81} {grey82} {grey83} {grey84} {grey85} {grey86} {grey87} {grey88} {grey89} {grey90} {grey91} {grey92} {grey93} {grey94} {grey95} {grey96} {grey97} {grey98} {grey99} {grey100} {honeydew} {honeydew1} {honeydew2} {honeydew3} {honeydew4} {hot pink} {HotPink} {HotPink1} {HotPink2} {HotPink3} {HotPink4} {indian red} {IndianRed} {IndianRed1} {IndianRed2} {IndianRed3} {IndianRed4} {ivory} {ivory1} {ivory2} {ivory3} {ivory4} {khaki} {khaki1} {khaki2} {khaki3} {khaki4} {lavender} {lavender blush} {LavenderBlush} {LavenderBlush1} {LavenderBlush2} {LavenderBlush3} {LavenderBlush4} {lawn green} {LawnGreen} {lemon chiffon} {LemonChiffon} {LemonChiffon1} {LemonChiffon2} {LemonChiffon3} {LemonChiffon4} {light blue} {light coral} {light cyan} {light goldenrod} {light goldenrod yellow} {light gray} {light green} {light grey} {light pink} {light salmon} {light sea green} {light sky blue} {light slate blue} {light slate gray} {light slate grey} {light steel blue} {light yellow} {LightBlue} {LightBlue1} {LightBlue2} {LightBlue3} {LightBlue4} {LightCoral} {LightCyan} {LightCyan1} {LightCyan2} {LightCyan3} {LightCyan4} {LightGoldenrod} {LightGoldenrod1} {LightGoldenrod2} {LightGoldenrod3} {LightGoldenrod4} {LightGoldenrodYellow} {LightGray} {LightGreen} {LightGrey} {LightPink} {LightPink1} {LightPink2} {LightPink3} {LightPink4} {LightSalmon} {LightSalmon1} {LightSalmon2} {LightSalmon3} {LightSalmon4} {LightSeaGreen} {LightSkyBlue} {LightSkyBlue1} {LightSkyBlue2} {LightSkyBlue3} {LightSkyBlue4} {LightSlateBlue} {LightSlateGray} {LightSlateGrey} {LightSteelBlue} {LightSteelBlue1} {LightSteelBlue2} {LightSteelBlue3} {LightSteelBlue4} {LightYellow} {LightYellow1} {LightYellow2} {LightYellow3} {LightYellow4} {lime green} {LimeGreen} {linen} {magenta} {magenta1} {magenta2} {magenta3} {magenta4} {maroon} {maroon1} {maroon2} {maroon3} {maroon4} {medium aquamarine} {medium blue} {medium orchid} {medium purple} {medium sea green} {medium slate blue} {medium spring green} {medium turquoise} {medium violet red} {MediumAquamarine} {MediumBlue} {MediumOrchid} {MediumOrchid1} {MediumOrchid2} {MediumOrchid3} {MediumOrchid4} {MediumPurple} {MediumPurple1} {MediumPurple2} {MediumPurple3} {MediumPurple4} {MediumSeaGreen} {MediumSlateBlue} {MediumSpringGreen} {MediumTurquoise} {MediumVioletRed} {midnight blue} {MidnightBlue} {mint cream} {MintCream} {misty rose} {MistyRose} {MistyRose1} {MistyRose2} {MistyRose3} {MistyRose4} {moccasin} {navajo white} {NavajoWhite} {NavajoWhite1} {NavajoWhite2} {NavajoWhite3} {NavajoWhite4} {navy} {navy blue} {NavyBlue} {old lace} {OldLace} {olive drab} {OliveDrab} {OliveDrab1} {OliveDrab2} {OliveDrab3} {OliveDrab4} {orange} {orange red} {orange1} {orange2} {orange3} {orange4} {OrangeRed} {OrangeRed1} {OrangeRed2} {OrangeRed3} {OrangeRed4} {orchid} {orchid1} {orchid2} {orchid3} {orchid4} {pale goldenrod} {pale green} {pale turquoise} {pale violet red} {PaleGoldenrod} {PaleGreen} {PaleGreen1} {PaleGreen2} {PaleGreen3} {PaleGreen4} {PaleTurquoise} {PaleTurquoise1} {PaleTurquoise2} {PaleTurquoise3} {PaleTurquoise4} {PaleVioletRed} {PaleVioletRed1} {PaleVioletRed2} {PaleVioletRed3} {PaleVioletRed4} {papaya whip} {PapayaWhip} {peach puff} {PeachPuff} {PeachPuff1} {PeachPuff2} {PeachPuff3} {PeachPuff4} {peru} {pink} {pink1} {pink2} {pink3} {pink4} {plum} {plum1} {plum2} {plum3} {plum4} {powder blue} {PowderBlue} {purple} {purple1} {purple2} {purple3} {purple4} {red} {red1} {red2} {red3} {red4} {rosy brown} {RosyBrown} {RosyBrown1} {RosyBrown2} {RosyBrown3} {RosyBrown4} {royal blue} {RoyalBlue} {RoyalBlue1} {RoyalBlue2} {RoyalBlue3} {RoyalBlue4} {saddle brown} {SaddleBrown} {salmon} {salmon1} {salmon2} {salmon3} {salmon4} {sandy brown} {SandyBrown} {sea green} {SeaGreen} {SeaGreen1} {SeaGreen2} {SeaGreen3} {SeaGreen4} {seashell} {seashell1} {seashell2} {seashell3} {seashell4} {sienna} {sienna1} {sienna2} {sienna3} {sienna4} {sky blue} {SkyBlue} {SkyBlue1} {SkyBlue2} {SkyBlue3} {SkyBlue4} {slate blue} {slate gray} {slate grey} {SlateBlue} {SlateBlue1} {SlateBlue2} {SlateBlue3} {SlateBlue4} {SlateGray} {SlateGray1} {SlateGray2} {SlateGray3} {SlateGray4} {SlateGrey} {snow} {snow1} {snow2} {snow3} {snow4} {spring green} {SpringGreen} {SpringGreen1} {SpringGreen2} {SpringGreen3} {SpringGreen4} {steel blue} {SteelBlue} {SteelBlue1} {SteelBlue2} {SteelBlue3} {SteelBlue4} {tan} {tan1} {tan2} {tan3} {tan4} {thistle} {thistle1} {thistle2} {thistle3} {thistle4} {tomato} {tomato1} {tomato2} {tomato3} {tomato4} {turquoise} {turquoise1} {turquoise2} {turquoise3} {turquoise4} {violet} {violet red} {VioletRed} {VioletRed1} {VioletRed2} {VioletRed3} {VioletRed4} {wheat} {wheat1} {wheat2} {wheat3} {wheat4} {white} {white smoke} {WhiteSmoke} {yellow} {yellow green} {yellow1} {yellow2} {yellow3} {yellow4} {YellowGreen}"
# set the location and name of the configuration file
set config_file "$home/.vpacman.config"
# various variables to hold the number of items found in the lists
set count_all 0
set count_installed 0
set count_outdated 0
set count_uninstalled 0
# the path to the pacman sync databases
set dbpath "/var/lib/pacman"
# set debug mode
# launch vpacman with no arguements to direct debug to stdout, use 'debug' to direct debug to a file in the home directory
set debug false
set debug_out stdout
if {[string first "debug" $args] != -1} {
	set debug true
	# remove any existing debug file
	file delete ${home}/vpacman_debug.txt
	# and start a new one
	set debug_out [open "$home/vpacman_debug.txt" w]
	puts $debug_out "Debug called ([clock seconds])"
}
puts $debug_out "Debug set to $debug\nDebug out is $debug_out"
# a list of all the directories and subdirectories found by the get_tree procedure in a given directory
set dirs ""
# default editor
set editor ""
# packages which may need further cation of updated
set flag_actions "gutenprint linux"
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
# the help text
set help_text "
This simple programme allows you to View the packages available in those pacman repositories which have been enabled in the pacman configuration file (/etc/pacman.conf) and to Install, Upgrade and Delete those packages. It also includes packages which have been installed from other sources - either from AUR or locally.

The only dependencies are Pacman, TCL, TK, a terminal and Wmctrl. Pacman is always used to install, update, delete and synchronize the pacman packages and database. Therefore the entries in the pacman configuration file will always be respected.

Note: Wmctl relies on the window title set for the terminal. In order to use konsole the profile must be set to use the window title set by the shell.

Optional dependencies are Curl, a browser, an editor, Xwininfo, Pkgfile

<strong>Usage:</strong>

The main window consists of a menu bar, a toolbar, a set of filter and list options, a window showing a list of packages, and a window, below that, which shows details of a selected package.

<strong>Menu Bar:</strong>
	File:	<lm3>Quit</lm3>
	Edit:	<lm3>Select All > Select all the packages displayed.</lm3>
			<lm3>Clear All > De-select all the selected packages.</lm3>
	Tools:	<lm3>Full System Upgrade > The only supported method of updating outdated packages. It may be wise to check the latest news before performing a full system update.</lm3>
			<lm3>Install > Ask pacman to install or update the selected packages. Partial upgrades are not supported. AUR packages can only be updated one at a time.</lm3>
			<lm3>Delete > Ask pacman to delete the selected packages.</lm3>
			<lm3>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been amde then the elapsed time shows the time since Vpacman was started.</lm3>
			<lm3>Check Config Files > Display a list of any configuration file which need to be dealt with. See \"https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave\"</lm3>
			<lm3>Clean Pacman Cache > Delete any superfluous packages from the pacman cache to release disk space. This will keep at least the most recent three versions of each package.</lm3>
			<lm3>Update Cups > Run cups_genppdupdate if necessary and restart cups. Use if gutenprint has been updated.</lm3> 
			<lm3>Options > Change any of the configurable options for Vpacman. Allows for editing the configuration file manually, which could break Vpacman! In case of problems delete the configuration file \"~/.vpacman.config\" to return all the values to default.</lm3>
	Help:	<lm3>Help > This help message.</lm3>
			<lm3>About > Information about this programme.</lm3>
			
<strong>Tool Bar:</strong>
	<lm2>Sync > Ask pacman to synchronize the pacman database. The elapsed time since the last synchronization is shown at the foot of the filter and list options. If no recent synchronization has been made then the elapsed time shows the time since Vpacman was started.</lm2>
	<lm2>Install > Ask pacman to install or update the selected packages. AUR packages can only be updated one at a time.</lm2>
	<lm2>Delete > Ask pacman to delete the selected packages.</lm2>
	<lm2>Find > Enter any string to search for in the list of packages displayed. The search will be carried out over all the fields of the packages listed, including the description but excluding the repository name. Click on the label \"Find\" to change to a search for the packages providing a specified file. Enter the full path to the file to search for, and press return to start the search. On the first search during any day, the file database will be updated automatically. Click on the label again to return to the \"Find\" option.</lm2>
	<lm2>Options > Change any of the configurable options for Vpacman. Allows for editing the configuration file manually, which could break Vpacman! In case of any problems delete the configuration file \"$ rm ~/.vpacman.config\" to return all the values to sane defaults.</lm2>		

<strong>Filters:</strong>
	<lm2>All > Check to show all the available packages including the installed AUR or local packages.</lm2>
	<lm2>Group > Filter the selection to only show the packages included in the selected group.</lm2>
	<lm2>To aid in navigating the list there is a scroll bar at the right edge of the drop down window. Since the groups list displayed is rather long a Right-Click on the scroll bar at any point will align the list to that point. Right-Click on the top arrow will display the top of the list, Right-Click on the bottom arrow will display the end of the list.</lm2>
	<lm2>Installed > Check to show only those packages which have been installed. Includes installed AUR and local packages.</lm2>
	<lm2>Not Installed > Check to show only those packages which have not been installed.</lm2>
	<lm2>Updates Available > Check to show those packages where an update is available. Use Full System Update as the preferred update method.</lm2>
	
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
	<lm2>Right-Click to bring up a menu similar to the tools menu above.</lm2>
	<lm2>Left-Click on a heading to sort the package list by that heading. Left-Click a second time to sort the list in reverse order.</lm2>
	<lm2>To aid in navigating the list there is a scroll bar at the right edge of the window. Since some of the lists displayed can be rather long a Right-Click on the scroll bar at any point will align the list to that point. Right-Click on the top arrow will display the top of the list, Right-Click on the bottom arrow will display the end of the list.</lm2>

<strong>Details Window:</strong>
	<lm2>Shows the requested information, according to the tab activated, about the latest package selected in the Packages Window.</lm2>
	
	<lm2>Much of the information is sourced from the internet, and retrieval may be slow as a result. In these cases a \"Searching\" message is displayed, and if no result is found an \"Error\" message will be displayed in the appropriate field. In such case - try again.</lm2>"
# list of known browsers
set known_browsers [list chromium dillo epiphany falkon firefox opera qupzilla]
# list of known terminals
set known_terminals [list {gnome-terminal} {--title <title> -- <command>} {konsole} {--title <title> -e <command>} {lxterminal} {--title <title> -e <command>} {mate-terminal} {--title <title> -e <command>} {roxterm} {--title <title> -e <command>} {vte} {--name <title> --command <command>} {vte-2.91} {--name <title> --command <command>} {xfce4-terminal} {--title <title> -e <command>} {xterm} {-title <title> -e <command>}]
# list of known_editors
set known_editors [list vi vim emacs nano]

# the list of all the packages in the database, including locally installed packages in the form
# Repo Package Version Available Group(s) Descrition
set list_all ""
# the list of all the groups in the database in the form
# Group
set list_groups ""
# the list of all the installed packages, including locally installed packages in the form
# Repo Package Version Available Group(s) Descrition
set list_installed ""
# the list of locally installed packages in the form
# Repo(local) Package Version Available(-na-) Group(s) Descrition
set list_local ""
# the list ofpackages which can be updated
set list_outdated ""
# the list of the packages on show in the treeview .wp.wfone.listview in the form
# Repo Package Version Available Group(s) Description
set list_show ""
# the same list but in the form
#id
set list_show_ids ""
# the order that the list_show is sorted into in the form
# Repo Package Version Available Group(s) Descrition
set list_show_order ""
# the list of packages which have not been installed in the form
# Repo Package Version Available Group(s) Descrition
set list_uninstalled ""
# the last packages selected in listview, used to avoid continuously running the treeview selected binding, in the form
# id
set listview_last_selected ""
# the packages selected in listview, used to show the dataview information requested, in the form
# id
set listview_current ""
# the list of all the currently selected items in listview in the form
# id
set listview_selected ""
# the list of all the currently selected items in listview in the order that they were selected in the form
# id
set listview_selected_in_order ""
set index 0
# message to be shown in the button bar near the top of the window
set message ""
# list of updated packages which may require further actions
set package_actions [list "linux" "Linux was updated, consider rebooting" "gutenprint" "Gutenprint was installed or updated, consider running Tools > Update cups" "pacman-mirrorlist" "Pacman-mirrorlist was updated, consider running Tools > Check Config Files for advice on how to update the mirrorlist"]
set pu_ans ""
# the time of the last sync in clock seconds
set s_time 0
# select_all is true if everything was selected from the drop down menu in listbox or from the menu bar
set select_all false
# variable to select one of the list options in the Filter frame
set selected_list 0
# this is the message for the number od items selected 
set selected_message ""
# the state of any package(s) selected: install, delete or blank(none)
set state ""
# set the default su command
set su_cmd "su -c"
# default terminal
set terminal ""
# the treeview message to display of any errors have been found
set tverr_message ""
# A list of any potential errors found in the treeview selection in the format Index Message
set tverr_text ""
# this is that order the treeview appears in, stated as column_number(a)scending/(d)escending. It will start with Column 1 Ascending
set tv_order "1a"

# Set configurable variables
proc configurable {} {

global browser buttons debug_out editor geometry geometry_view helpfg helpbg installed_colour known_browsers known_editors known_terminals outdated_colour save_geometry terminal terminal_string

	puts $debug_out "Set configurable variables"
	# initialize the browser variable to the first browser in the common browsers list which is installed
	configurable_default "browser" $known_browsers
	# initialize the editor variable to the first editor in the common editors list which is installed
	configurable_default "editor" $known_editors
	# initialize the terminal variables to the first terminal in the known terminals which is installed
	configurable_default "terminal" $known_terminals 
	# set the size of the icons used for the buttons
	set buttons medium
	# set geometry to a sane size
	set geometry "1060x500+200+50"
	set geometry_view "750x350+225+55"
	set save_geometry "no"
	# set colours to acceptable values
	set helpbg #EBE8E4	
	set helpfg #FFFFFF
	set installed_colour blue
	set outdated_colour red
}

proc configurable_default {variable list} {
	
global browser debug_out editor terminal terminal_string
	
	puts $debug_out "configurable_default - check default for $variable"
	if {$variable == "terminal"} {
		foreach {programme string} $list {
			set result [catch {exec which $programme}]
			if {$result == 0} {
				set terminal "$programme"
				set terminal_string "$programme $string"
				break
			}
		}	
		return 0
	}
	foreach programme $list {
		set result [catch {exec which $programme}]
		if {$result == 0} {
			switch $variable {
				browser {set browser "$programme"}
				editor {set editor "$programme"}
			}
		}
	}
	return 0
}

configurable

puts $debug_out "Pre configuration file: browser set to $browser, editor set to $editor, terminal set to $terminal"

# Check if we have been run as root or with root privileges
if { [exec id -u] eq 0 } {
	puts $debug_out "Vpacman is running with root priveleges"
	set su_cmd ""
# if not root then do we have sudo privileges without a password
} else {
	set error [catch {exec echo "" | sudo -S -v} result]
	puts $debug_out "sudo -S -v returned error $error and result: $result"
	if {$error == 0} {
		# the -n option is only needed to distinguish the su_cmd from the next one!
		puts $debug_out "Vpacman: user can run sudo without a password"
		set su_cmd "sudo -n"
	} elseif {[string first "may not run sudo" $result] == -1} {
		# so we can use sudo but still need a password
		puts $debug_out "Vpacman: user can run sudo with a password"
		set su_cmd "sudo"
	}
}

# OK just use the default

puts $debug_out "User is $env(USER) - Home is $home -Config file is $config_file - Programme Directory is $program_dir - Su command is set to $su_cmd"

# Use wmctrl to raise an already running application
set process [pid]
set program [file tail $argv0]
set list [split [exec ps -eo "pid cmd" | grep "$program"] \n]
foreach i $list {
	if {[string first $process [string trim $i]] == 0} {continue}
	if {[string first grep $i] != -1} {continue}
	if {[string first "wish" $i] != -1 && [string first "$program" $i] != -1} {
		catch {exec wmctrl -F -a "View and Modify Pacman Database"}
		exit
	}
}


# GET CONFIGURATION OPTIONS

proc .get_configs {} {

global aur_all browser buttons config_file editor geometry geometry_config geometry_view helpbg helpfg installed_colour outdated_colour save_geometry terminal terminal_string

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
			help_foreground {set helpfg $var}
			installed_colour {set installed_colour $var}
			outdated_colour {set outdated_colour $var}
			save_geometry {set save_geometry $var}
			terminal {set terminal $var}
			terminal_string {set terminal_string $var}
		}
	}
	close $fid
	}
}

# SAVE CONFIGURATION OPTIONS

proc .put_configs {} {

global aur_all browser buttons config_file editor geometry geometry_config geometry_view helpbg helpfg installed_colour outdated_colour save_geometry terminal terminal_string

	set fid [open "$config_file" w ]

	puts $fid "# Configuration options for the tcl vpacman programme to view and manipulate the pacman database."
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
	puts $fid "help_foreground $helpfg"
	puts $fid "installed_colour $installed_colour"
	puts $fid "outdated_colour $outdated_colour"
	if {$save_geometry != "yes"} {set $save_geometry "no"}
	puts $fid "save_geometry $save_geometry"
	puts $fid "terminal $terminal" 
	puts $fid "terminal_string $terminal_string" 
	close $fid 
}

.get_configs

# Create images

# Toolbar	
	image create photo tools -file "$icon_dir/$buttons/configure.png"
	image create photo delete -file "$icon_dir/$buttons/edit-delete.png"
	image create photo install -file "$icon_dir/$buttons/dialog-ok-apply.png"
	image create photo reload -file "$icon_dir/$buttons/edit-redo.png"
# Message Box
	image create photo hint -file "$icon_dir/medium/help-hint.png"
	image create photo warning -file "$icon_dir/medium/dialog-warning.png"
	
# Fixed size
	image create photo clear -file "$icon_dir/tiny/edit-clear-locationbar-rtl.png"
	image create photo down_arrow -file "$icon_dir/tiny/pan-down-symbolic.symbolic.png"
	image create photo pacman -file "$icon_dir/small/ark.png"
	image create photo view -file "$icon_dir/small/view-list-text.png"
	
# Set up screen

wm title . "View and Modify Pacman Database"
wm iconphoto . -default pacman
wm geometry . $geometry

proc set_wmdel_protocol {type} {
	
# set the main window exit code, depending on the type requested

	if {$type == "noexit"} {
		wm protocol . WM_DELETE_WINDOW {
		puts $debug_out "Don't click on exit while a Terminal is open!"
		}
	} else { 
		wm protocol . WM_DELETE_WINDOW {
		if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]; .put_configs}
		# delete the aur_upgrades directory and all of its contents
		# any aur packages with incomplete downloads or upgrades will have to be restarted
		set error [catch {file delete -force "$tmp_dir/aur_upgrades"} result]
		close $debug_out
		exit
		}
	}
}
set_wmdel_protocol exit

# set up main window

menu .menubar \
	-relief flat
	. configure -menu .menubar
	menu .menubar.file -tearoff 0
		.menubar add cascade -menu .menubar.file -label File -underline 0
		.menubar.file add command \
			-command {
				if {[string tolower $save_geometry] == "yes"} {set geometry [wm geometry .]; .put_configs} 
				# delete the aur_upgrades directory and all of its contents
				# any aur packages with incomplete downloads or upgrades will have to be restarted
				puts $debug_out "wm exit - delete $tmp_dir/aur_upgrades and its contents"
				file delete "$tmp_dir/aur_upgrades"
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
			.menubar.tools add command -command {execute install} -label Install -state disabled -underline 0
			.menubar.tools add command -command {execute delete} -label Delete -state disabled	-underline 0
			.menubar.tools add command -command {execute sync} -label Sync -state normal -underline 0
			.menubar.tools add separator
			.menubar.tools add command -command {check_config_files} -label "Check Config Files" -state normal -underline 6
			.menubar.tools add command -command {clean_cache} -label "Clean Package Cache" -state normal -underline 6
			.menubar.tools add command -command {update_cups} -label "Update Cups" -state normal -underline 0
			.menubar.tools add separator
			.menubar.tools add command -command {configure} -label Options -state normal -underline 0
	menu .menubar.view -tearoff 0
		.menubar add cascade -menu .menubar.view -label View -underline 0
		.menubar.view add command -command {read_news} -label "Latest News" -state normal -underline 0
		.menubar.view add command -command {read_config} -label "Pacman Configuration" -state normal -underline 7
		.menubar.view add command -command {read_log view} -label "Pacman Log" -state normal -underline 0
	menu .menubar.help -tearoff 0
		.menubar add cascade -menu .menubar.help -label Help -underline 0
			.menubar.help add command -command {view_text $help_text "Help"} -label "Help" -state normal -underline 0
			.menubar.help add command -command {view_text $about_text "About"} -label "About" -state normal -underline 0

frame .buttonbar 

	button .buttonbar.reload_button \
		-command {execute sync} \
		-image reload \
		-relief flat

	button .buttonbar.install_button \
		-command {execute install}\
		-image install \
		-relief flat \
		-state disabled

	button .buttonbar.delete_button \
		-command {execute delete}\
		-image delete \
		-relief flat \
		-state disabled	
	
	button .buttonbar.configure_button \
		-command {configure} \
		-image tools \
		-relief flat
	
	label .buttonbar.label_message \
		-justify center \
		-textvariable message
		
	label .buttonbar.label_find \
		-foreground Blue \
		-justify left \
		-text Find 

	entry .buttonbar.entry_find \
		-foreground Blue \
		-takefocus 0 \
		-validate key \
		-validatecommand {
			## !!THERE ARE STILL PROBLEMS WITH THIS!!
			# Backspace plus repeat key crashes the programme if the string is 2 characters or more
			# so we need to update idletasks
			update idletasks
			puts $debug_out "Find string is %P"
			set find %P
			if {[string length %P] == 0} {
				set_message find ""
				list_show $filter_list
			} elseif {[string length %P] > 2} {
				find %P $filter_list
			}
			# any error in the find script will turn off the validate command
			# so we try to reinstate it here 
			after idle {
				puts $debug_out "after idle turned find validate on"
				.buttonbar.entry_find configure -validate key
			}
			return 1
		} \
		-width 25
	
	bind .buttonbar.entry_find <Return> {
		# run the find if return has been pressed, to find strings of less than 3 characters and reset the validate key
		puts $debug_out "Return Key ran find $find"
		if {[string length $find] > 0} {find $find $filter_list}
		puts $debug_out "Return Key turned find validate on"
		.buttonbar.entry_find configure -validate key
	}

## perhaps this is the first thing to do on a button release?
	# sometimes clicking buttons in the find data area stops the validate key working, so the last thing 
	# to do after a button is released is to reset it
	bind .buttonbar.entry_find <ButtonRelease> {+
		#puts $debug_out "ButtonRelease ran find $find"
		#if {[string length $find] > 3} {find $find $filter_list}
		puts $debug_out "ButtonRelease turned find validate on"
		.buttonbar.entry_find configure -validate key
	}
	
	button .buttonbar.clear_find_button \
		-command {
			puts $debug_out ".buttonbar.clear removed find entry"
			.buttonbar.entry_find delete 0 end
			# .buttonbar.entry_find -validatecommand will update everything
		} \
		-image clear \
		-relief flat

# Alternate labels and entries to find a file instead of finding data in the current list

	label .buttonbar.label_findfile \
		-foreground Blue \
		-justify left \
		-text "Find File"

	entry .buttonbar.entry_findfile \
		-foreground Blue \
		-takefocus 0 \
		-textvariable findfile \
		-width 25
		
	button .buttonbar.clear_findfile_button \
		-command {
			set findfile ""
			set_message find ""
			filter
		} \
		-image clear \
		-relief flat

	bind .buttonbar.entry_findfile <Return> {
		if {$findfile != ""} {
			set filter all
			# set up a command to find the requested file in the database
			
			# is pkgfile installed
			if {[catch {exec which pkgfile}] != 0} {
			# no - then use pacman	
				# offer to update the file database if it is more than 1 day old
				# we can work out the last update time from the temp databases
				# if the files databases do not exist then create them
				set pacman_database [get_file_mtime $tmp_dir/sync files]
				if {$pacman_database == 0} {
## do we need a message in here?
					set ans "yes"
				} else {
					if {[expr [clock seconds] > [clock add $pacman_database 1 day]]} {
						set ans [tk_messageBox -default yes -detail "Do you want to update the pacman files database now?" -icon question -message "The pacman files database was last updated at  [clock_format $pkgfile_database full]." -parent . -title "Update database?" -type yesno]
					}
					switch $ans {
						no {}
						yes {
							set action "Update pacman file database"
							set command "$su_cmd pacman -b $tmp_dir -Fy"
							if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Fy\""}
							set wait false
							execute_command $action $command $wait
					}
					set command "$su_cmd pacman -b $tmp_dir -Foq $findfile"
					if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Foq $findfile\""}
					}
				}
			} else {
			# pkgfile is installed , so use that
				# ask to update the file database if it is more than 1 day old
				# pkgfile stores its data in /var/cache/pkgfile
				# we can work out the last update time from the directory then use that
				# first check if the directory exists and is not empty
				if {[file isdirectory /var/cache/pkgfile] == 0 || [llength [glob -nocomplain "/var/cache/pkgfile/*"]] == 0} {
## do we need a message in here?
					set ans "yes"
				} else {
					set pkgfile_database [file mtime /var/cache/pkgfile]
					if {[expr [clock seconds] > [clock add $pkgfile_database 1 day]]} {
						set ans [tk_messageBox -default yes -detail "Do you want to update the pkgfile database now?" -icon question -message "The pkgfile database was last updated at [clock_format $pkgfile_database full]." -parent . -title "Update database?" -type yesno]
					}
					switch $ans {
						no {}
						yes {
							set action "Update pkgfile database"
							set command "$su_cmd pkgfile -u"
							if {$su_cmd == "su -c"} {set command "$su_cmd \"pkgfile -u\""}
							set wait false
							execute_command $action $command $wait
						}	
					}
				}
				set command "$su_cmd pkgfile $findfile"
				if {$su_cmd == "su -c"} {set command "$su_cmd \"pkgfile $findfile\""}
			}
			# OK, so we know the command to execute, so do it
			set list ""
			set pkglist ""
			set error [catch {eval [concat exec $command]} list]
			if {$error == 0} {
				set list [split $list "\n"]
				puts $debug_out "Findfile list is $list"
				foreach item $list {
					puts $debug_out "Item is $item"
					puts $debug_out "[string last "/" $item]"
					set item [string range $item [string last "/" $item]+1 end]
					puts $debug_out "Item is now $item"
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
				set_message selected "No packages found containing $findfile"
			} elseif {[llength $pkglist] > 1} {
				set_message selected "[llength $pkglist] packages provide $findfile"
			} else {
				set_message selected "[llength $pkglist] packages provides $findfile"
			}
			if {[string first "pacman" $command] == 0} {
				.wp.wftwo.dataview select .wp.wftwo.dataview.info
				update
				.wp.wftwo.dataview.info insert end "\n"			
				.wp.wftwo.dataview.info insert end "Consider installing pkgfile"
			}

		}
	}
	
# bindings to change the type of find command displayed
# tried using ButtonRelease-1 but it did not work and I don't know why?

	bind .buttonbar.label_find <ButtonRelease> {
		puts $debug_out "Find label clicked"
			set findtype "findfile"
			set findfile $find
			set find ""
			.buttonbar.entry_find delete 0 end
			puts $debug_out "ButtonRelease on .buttonbar.label_find turned find validate on"
			.buttonbar.entry_find configure -validate key
			filter
			set_message find ""
		puts $debug_out "Find type is $findtype"
			grid remove .buttonbar.label_find
			grid remove .buttonbar.entry_find
			grid remove .buttonbar.clear_find_button
			grid .buttonbar.label_findfile -in .buttonbar -row 1 -column 7 \
				-sticky e
			grid .buttonbar.entry_findfile -in .buttonbar -row 1 -column 8 \
				-sticky we
			grid .buttonbar.clear_findfile_button -in .buttonbar -row 1 -column 9 \
				-sticky e
	}

	bind .buttonbar.label_findfile <ButtonRelease> {
		puts $debug_out "Find File label clicked"
			set findtype "find"
			set_message find ""
			filter
		puts $debug_out "Find type is $findtype"
			grid remove .buttonbar.label_findfile
			grid remove .buttonbar.entry_findfile
			grid remove .buttonbar.clear_findfile_button
			grid .buttonbar.label_find -in .buttonbar -row 1 -column 7 \
				-sticky e
			grid .buttonbar.entry_find -in .buttonbar -row 1 -column 8 \
				-sticky we
			grid .buttonbar.clear_find_button -in .buttonbar -row 1 -column 9 \
				-sticky e	
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
			filter_checkbutton ".filter_list_orphans" "pacman -b $tmp_dir -Qdtq" "Orphans"
		} \
		-onvalue "orphans" \
		-text "Orphans" \
		-variable selected_list
		
	checkbutton .filter_list_not_required \
		-command {
			update idletasks
			set aur_only false
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
			if {$selected_list == "aur_updates"} {
				get_aur_updates
			}
		} \
		-offvalue false \
		-onvalue true \
		-text "include all local packages" \
		-variable aur_all
			
	label .filter_clock_label \
		-text "Time since last sync"
		
	label .filter_clock \
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
	
		.wp.wfone.listview heading Package -text "Package" -anchor center -command {sort_list_show {Package}}
		.wp.wfone.listview heading Version -text "Version" -anchor center -command {sort_list_show {Version}}
		.wp.wfone.listview heading Available -text "Available" -anchor center -command {sort_list_show {Available}}
		.wp.wfone.listview heading Repo -text "Repo" -anchor center -command {sort_list_show {Repo}}
		.wp.wfone.listview column Package -stretch 1 
		.wp.wfone.listview column Version -stretch 0 -width 150
		.wp.wfone.listview column Available -stretch 0 -width 150
		.wp.wfone.listview column Repo -stretch 0 -width 150
		.wp.wfone.listview tag configure selected -foreground [ttk::style lookup Treeview -foreground selected] -background [ttk::style lookup Treeview -background selected]
		.wp.wfone.listview tag configure installed -foreground $installed_colour
		.wp.wfone.listview tag configure outdated -foreground $outdated_colour

		scrollbar .wp.wfone.xlistview_scroll \
			-command ".wp.wfone.listview xview" \
			-cursor {} \
			-orient horizontal \
			-takefocus 0

		scrollbar .wp.wfone.ylistview_scroll \
			-command ".wp.wfone.listview yview" \
			-cursor {} \
			-takefocus 0
			
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
				puts $debug_out "Control Button clicked on TreeView: Anchor is $anchor Item is $listlast"
				set anchor $listlast
			} else {
				puts $debug_out "Control Button clicked on TreeView: Anchor is $anchor Item is $listlast Previous is $listfirst"
			}
			# finish off - add the new item to the selection list and save it as first
			.wp.wfone.listview selection add $listlast
			set listfirst $listlast
			break
		}	
		bind .wp.wfone.listview <ButtonPress-1> {
			if {[.wp.wfone.listview identify region %x %y] == "heading"} {
				puts $debug_out "you clicked on column [string trim [.wp.wfone.listview identify column %x %y] \#] heading"
				# set these up as temporary variables
				set item ""
				set newlist ""
				# Columns 1 is item 1 in the list, 2 = 2, 3 = 3, 4 = 0, 
				set item [string trim [.wp.wfone.listview identify column %x %y] \#] 
				if {$item == 4} {set item 0}
				switch $item {
					0	{if {$tv_order == "4a"} {set tv_order "4d"} else {set tv_order "4a"}}
					1	{if {$tv_order == "1a"} {set tv_order "1d"} else {set tv_order "1a"}}
					2	{if {$tv_order == "2a"} {set tv_order "2d"} else {set tv_order "2a"}}
					3	{if {$tv_order == "3a"} {set tv_order "3d"} else {set tv_order "3a"}}
				}
				puts $debug_out "Sort list by item $item, column order is set to $tv_order"
				if {[string first "a" $tv_order] == -1} {
					set newlist [lsort -dictionary -decreasing -index $item $list_show]
				} else {
					set newlist [lsort -dictionary -index $item $list_show]
				}
				list_show $newlist
				# unset the temporary variables
				set item ""
				set newlist ""
			} else {	
				set listlast [.wp.wfone.listview identify item %x %y]
				set anchor $listlast
				set listfirst ""
				puts $debug_out "Button clicked on TreeView: Anchor is $anchor Item is $listlast"
				.wp.wfone.listview selection set $listlast
			}
			break
		}
	
		bind .wp.wfone.listview <<TreeviewSelect>> {	
			# the selection has changed! What is the new selection?
			set listview_selected [.wp.wfone.listview selection]
			puts $debug_out "TreeviewSelect - there is a new selection: $listview_selected\n\tthe previous selection was $listview_last_selected"
			
			# check if anchor still exists
			if {[lsearch $listview_selected $anchor] == -1} {set anchor [lindex $listview_selected 0]}
			# first get rid of any obvious anomolies
			# for example the selection changed but nothing is selected now
			if {$listview_selected == ""} {
				puts $debug_out "TreeviewSelect - there is nothing selected so break out of the script"
				if {$listview_last_selected != ""} {get_dataview ""}
				set listview_current ""
				set listview_last_selected ""
				set listview_selected_in_order ""
				set_message selected ""
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
				break
			}
			# if we selected the same item a second time then we presume that we wanted to clear that selection
			# we need this because we haven't handled all the possibilities in the button bindings
			if {[llength $listview_selected] == 1 && $listview_selected == $listview_selected_in_order && $select_all == false} {
				.wp.wfone.listview selection remove $listview_selected
				# bind TreeviewSelect will update all the variables when the selection changes
				set listview_selected ""
			}
			# if nothing has really changed then break out of the script
			if {$listview_selected == $listview_last_selected} {
				puts $debug_out "Treeview selection has not changed so break out of the script"
				# just check that we are not in AUR/Local, if we are then we cannot Select All, even if nothing is selected_list
				# this is necessary because we may have an AUR/Local item selected and have just checked AUR/Local
				if {$aur_only == true} {
					.menubar.edit entryconfigure 0 -state disabled
					.listview_popup entryconfigure 3 -state disabled
				}
				set tvselect "done"
				break
			}
			set listview_last_selected $listview_selected
			set select_all false
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
				break
			# if only one item is selected and it is in the aur updates list 
			# which is a given because only one item can be selected in the aur updates list
			# then it can be only be updated, re-installed or deleted
			# we need this here to avoid the other checks in the foreach loop below
			} elseif {$aur_only == true && [llength $listview_selected] == 1} {
				puts $debug_out "TreeviewSelect - something selected but AUR only"
				set state "re-install or delete"
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
				set tverr_text ""
				puts $debug_out "TreeviewSelect - running tests foreach item in $listview_selected"
				set count 0
				foreach item $listview_selected {
# start foreach loop
					incr count
					puts $debug_out "\t$item is $count loop"
					set listview_values [.wp.wfone.listview item $item -values]
					puts $debug_out "TreeviewSelect - test next $item [lrange $listview_values 1 1]"
# if the item has not been installed
					if { [lrange $listview_values 3 3] == "{}"} {
						# if the item has not been installed then we should install it
						# not delete it
						# local packages cannot be installed here, but will show "-na-" in the fourth field!
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
# if the item has already been installed and is not a local package
					} elseif {[lrange $listview_values 3 3] != "{}" && [lrange $listview_values 0 0] != "local"} {
						if {[lrange $listview_values 2 2] != [lrange $listview_values 3 3] && $fs_upgrade == false} {
							puts $debug_out "TreeviewSelect - FS_Upgrade is $fs_upgrade"
							puts $debug_out "TreeviewSelect - [lindex $listview_values 1] upgrade from [lrange $listview_values 2 2] to [lrange $listview_values 3 3]"
							if {$pu_ans != "yes"} {
								set pu_ans [tk_messageBox -default no -detail "Do you want to continue, at your own risk, including [lindex $listview_values 1], answer No to start a new selection, then, to upgrade, select Full System Upgrade from the menus" -icon warning -message "Partial upgrades are not supported." -parent . -title "Warning" -type yesno]
								puts $debug_out "Answer to partial upgrade package warning message is $pu_ans" 
								switch $pu_ans {
									no {
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# bind TreeviewSelect will update all the variables when the selection changes
										break
									}
									yes {
										# if the response is Continue (1), then continue with the rest of the analysis.
									}	
								}
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
								set ans [tk_messageBox -default yes -detail "Do you want to continue without selecting [lindex $listview_values 1], answer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and cannot be installed or re-installed from here." -parent . -title "Warning" -type yesno]
								puts $debug_out "Answer to local package warning message is $ans" 
								switch $ans {
									no {
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# bind TreeviewSelect will update all the variables when the selection changes
										break
									}
									yes {
										# if the response is Continue (1), then deselect item and continue with the next item in the foreach loop.
										.wp.wfone.listview selection remove $item
										# bind TreeviewSelect will update all the variables when the selection changes
										break
									}	
								}
							} elseif {$state == "delete"} {
								puts $debug_out "$item is local and state is delete"
								# bind TreeviewSelect will update all the variables when the selection changes
								break
							} elseif {[string first "delete" $state] != -1} {
								puts $debug_out "$item is local and state includes delete"
								set ans [tk_messageBox -default yes -detail "Do you want to continue selecting packages to delete, answer No to start a new selection" -icon warning -message "[lindex $listview_values 1] is a local package and canonly be deleted from here." -parent . -title "Warning" -type yesno]
								puts $debug_out "Answer to local package warning message is $ans" 
								switch $ans {
									no {
										# if the response is Abort (0), then unselect everything and break out of the foreach loop.
										# remove anything shown in .wp.wftwo.dataview
										all_clear
										# bind TreeviewSelect will update all the variables when the selection changes
										break
									}
									yes {
										# if the response is Continue (1), then set delete and continue with the next item in the foreach loop.
										set state "delete"
										puts $debug_out "\tset to delete"
										# bind TreeviewSelect will update all the variables when the selection changes
										break
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
							set state "re-install or delete"
							puts $debug_out "\tset to re-install or delete"
						}
					}
				}
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
			# set the message text
			if {[llength $listview_selected] == 0} {
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
			puts $debug_out "TreeviewSelect - tvselect is now $tvselect"
		}

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
		
# set up a popup menu for listview
	option add *tearOff 0
	menu .listview_popup -cursor left_ptr
	.listview_popup add command -label "Full System Upgrade" -command {system_upgrade} -state normal
	.listview_popup add command -label "Install" -command {execute install} -state disabled
	.listview_popup add command -label "Delete" -command {execute delete} -state disabled
	.listview_popup add command -label "Select All" -command {all_select} -state normal
	.listview_popup add command -label "Clear All" -command {all_clear} -state disabled
# and set up a binding for it
	bind .wp.wfone.listview <ButtonRelease-3> {
		puts $debug_out "Right-Click on listview"
		tk_popup .listview_popup %X %Y 0
	}
# set button-3 on the popup menu to do nothing
	bind .listview_popup <ButtonRelease-3> {
		puts $debug_out "Button 3 pressed in popup menu"
		wm withdraw .listview_popup
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
			
	scrollbar .wp.wftwo.ydataview_moreinfo_scroll \
			-command ".wp.wftwo.dataview.moreinfo yview" \
			-cursor {} \
			-takefocus 0
			
	scrollbar .wp.wftwo.ydataview_files_scroll \
			-command ".wp.wftwo.dataview.files yview" \
			-cursor {} \
			-takefocus 0

	# some simple bindings for wp.wftwo.dataview
	# don't allow dataview to keep the focus
	bind .wp.wftwo.dataview <FocusIn> {
		focus .wp.wfone.listview
	}
	# get the new contents for dataview when the tab changes	
	bind .wp.wftwo.dataview <<NotebookTabChanged>> {
		puts $debug_out "Dataview tab changed - call get_dataview"
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

# two simple procedures to hide and show the listgroups widget as required

proc grid_listgroups {} {

global debug_out group list_groups
	
	grid .listgroups
	grid .scroll_selectgroup
	set index [lsearch -exact $list_groups $group]
	puts $debug_out "grid_listgroups - Found $group at $index"
	if {$index == -1} {set index 0}
	.listgroups yview $index
	.listgroups itemconfigure $index -background #c6c6c6
	.group_button configure -command {remove_listgroups}
	bind .listgroups <Motion> {
		.listgroups itemconfigure $index -background white
		.listgroups itemconfigure @%x,%y -background #c6c6c6
		set index [.listgroups index @%x,%y]
	}
	bind .listgroups <<ListboxSelect>>  {
		set group [.listgroups get [.listgroups curselection]]
		filter
		remove_listgroups
	}
	bind .menubar <ButtonRelease-1> {
		remove_listgroups
	}
	foreach child [winfo children .buttonbar] {
		bind $child <ButtonRelease-1> {
			remove_listgroups
		}
	}
	bind .filters <ButtonRelease-1> {
		remove_listgroups
	}
	bind .wp.wfone.listview <ButtonRelease-1> {
		remove_listgroups
	}
	bind .wp.wftwo.dataview <ButtonRelease-1> {
		remove_listgroups
	}
}

proc remove_listgroups {} {
	
global debug_out
	
	grid remove .listgroups
	grid remove .scroll_selectgroup
	.group_button configure -command {grid_listgroups; .listgroups selection clear 0 end}
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

# add the two elements, listview and dataview to the windowpane wp
	.wp add .wp.wfone
	.wp add .wp.wftwo
	
# Geometry management
	
	grid .buttonbar -in . -row 2 -column 1\
		-columnspan 3 \
		-sticky ew
		grid .buttonbar.reload_button -in .buttonbar -row 1 -column 1 \
			-sticky w
		grid .buttonbar.install_button -in .buttonbar -row 1 -column 2 \
			-sticky w
		grid .buttonbar.delete_button -in .buttonbar -row 1 -column 3 \
			-sticky w
		grid .buttonbar.label_message -in .buttonbar -row 1 -column 4 \
			-columnspan 3 \
			-sticky we
		grid .buttonbar.label_find -in .buttonbar -row 1 -column 7 \
			-sticky e
		grid .buttonbar.entry_find -in .buttonbar -row 1 -column 8 \
			-sticky we
		grid .buttonbar.clear_find_button -in .buttonbar -row 1 -column 9 \
			-sticky e
		grid .buttonbar.configure_button -in .buttonbar -row 1 -column 10 \
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
		grid .filter_clock_label -in .filters -row 16 -column 1 \
			-columnspan 3 \
			-sticky w
		grid .filter_clock -in .filters -row 16 -column 4 \
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
	grid columnconfigure .buttonbar 4 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 5 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 6 -weight 2 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 7 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 8 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 9 -weight 0 -minsize 0 -pad 0
	grid columnconfigure .buttonbar 10 -weight 0 -minsize 20 -pad 0
	grid columnconfigure .buttonbar 11 -weight 0 -minsize 20 -pad 0

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
	grid rowconfigure .filters 14 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 15 -weight 1 -minsize 0 -pad 10
	grid rowconfigure .filters 16 -weight 0 -minsize 0 -pad 10
	grid rowconfigure .filters 17 -weight 0 -minsize 0 -pad 10
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

	
# remove the listgroups list box and set up the associated bindings
remove_listgroups

# PROCEDURES

## Two procedures to load and save the configurable options
# proc .get_configs
#	Read the configuration variables from the configuration file (
# proc .put_configs
#	Write the configuration variables to the configuration file
## Procedure to set and reset the main window delete protocol
# proc set_wmdel_protocol {type} 
# 	Set the main window exit code, depending on the type, exit or noexit, requested
## Two simple procedures to hide and show the listgroups widget as required
# 	proc grid_listgroups
# 	proc remove_listgroups
# proc count_lists
#	Count the number of items in the lists found by the list_ procedures
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
## The following procedures create help messages invoked when the curosr hovers over a widget.
# proc set_balloon {target message}
# proc kill_balloon
# proc balloon {target message {cx 0} {cy 0} } 
## Select or Clear all of the items shown in the treeview widget
# proc all_select
# proc all_clear
##
# proc aur_upgrade
# 	Upgrade a given AUR package
# proc check_config_files
#	Check for any existing configurations files that have not been dealt with
# proc clean_cache
# 	Clean unnecessary files from the pacman cache
# proc cleanup_checkbuttons {aur} 
#	After a filter checkbutton is selected return the necessary variables to sane settings, 
#		set aur_only to the value requested. Reset the list checkbutton titles. 
# proc configure
#	Display a new window to allow the configurable variables to be changed. 
#		Also allows the configuration file to be edited using the selected editor.
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
# proc find {find list} 
#	Find all the items in the displayed list which contain the find string. Search all the fields,
#		including those not displayed, except for the Repo field.
# proc find_pacman_config
#	Find pacman configuration data
# proc get_aur_updates
#	Find local files which may need to be updated or may not be found amongst the AUR packages
# proc get_aur_version {package} 
#	Procedure to find the current available aur version. Relies on the correct aur version being shown in the aur data.
# proc get_dataview {current}
#	Get the information required, depending on the active tab in the dataview notebook. Since some of the details
#		can take a while to retrieve, show a searching message where necessary.
# proc get_file_mtime
# 	Get the  last modigied time for a set of files
# proc get_tree {rootdir}
# 	Get all the directories and subdirectories in a given directory
# proc flush_kb
#	Attempts to flush the keyboard buffer after a long procedure in case the user has been randomly stabbing at the keyboard.
# proc read_about
#	Display the about text
# proc read_config
#	Read the pacman configuration file and display it. 
# proc read_help
# 	Display the help text
# proc read_log {action}
#	Find the pacman log file and read it. Get the last sync time and, if action is view, then display the log. 
# proc read_news
#	Try to downlaod and parse the arch news rss, and display it. If not possible then browse to the web page
# proc set_message {type text}
#	Displays a message in the message area at the top of the window. The type influences whether the messge 
#		is appended to, or replaces a previous message
# proc sort_list_show {heading} 
#	This procedure sorts whatever is shown in the treeview widget, in descending or ascending order, when a heading is clicked.
# proc start
#	On start up, or after a terminal command has been run to update all the base lists, all, installed, not installed and available updates.
# proc start_clock
#	Calculate the elapsed time since the last significant event, the e-time, which is set at the start of the programme, 
#		or the last sync event. Displays and updates the elapsed time at the foot of the window.
# proc system_upgrade
#	Execute a full system upgrade
# proc test_configs
#	Test the current configuration options are sane, if not, reset to a default setting as necessary.
# proc test_internet
#	Test, up to three times for an internet connection.
# proc update_cups
# 	if gutenprint is installed run cups-genppdupdate to update ppds - restart cups
# proc update_db
#   copies the pacman sync database into the temporary directory
# proc view_text
#	open a window and display some text in it
# proc view_text_codes
#   read through some text and replace a set of codes with a given tag

proc count_lists {} {

global count_all count_installed count_outdated count_uninstalled debug_out list_all list_installed list_outdated list_uninstalled
# returns the count of all the lists 	

set count_all 0
set count_installed 0
set count_outdated 0
set count_uninstalled 0
set count_all [llength $list_all]	
set count_installed [llength $list_installed]	
set count_outdated [llength $list_outdated]
set count_uninstalled [llength $list_uninstalled]	
}

# THESE PROCEDURES CALCULATE ALL OF THE LISTS OF PACKAGES THAT WE WILL NEED FOR THE FUTURE
# INCLUDING THE LIST OF PACKAGES SHOWN IN THE LISTVIEW WINDOW AND THE SPECIAL LIST OPTIONS

proc list_all {} {

global debug_out list_all list_local list_installed list_outdated list_uninstalled list_show_order tmp_dir
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
# join the local package list to the packages installed from the database and sort them into package increasing order
set list_show_order "Package increasing"
set list_installed [lsort -dictionary -index 1 [concat $list_installed $list_local]]
# join the local package list to the database packages and sort them into package increasing order
set list_all [lsort -dictionary -index 1 [concat $list_all $list_local]]
}

proc list_local {} {

global debug_out list_local tmp_dir
# get a list of locally installed packages
# local, details, element, description - are temporary local variables
# returns local_list as Repo Package Version Available(na) Group(s) Description

	set list_local ""
	set error [catch {exec pacman -b $tmp_dir -Qm} local]
	if {$error != 0} {
		puts $debug_out "List local executed Pacman -Qm with error $error and result $local"
	}
	set local [split $local \n]
	# now add a placeholder for the description for the item and add it to list_local
	foreach {element} $local {
		# it is _WAY_ too slow to get the versions available for the local packages at this point
		#puts $debug_out "Get aur version started [clock milliseconds]"
		#set version [get_aur_version [lrange $element 0 0]]
		#puts $debug_out "Get aur version completed ($version) [clock milliseconds]"
		set item "local [lrange $element 0 0] [lrange $element 1 1] -na- -none- DESCRIPTION"
		lappend list_local $item
	}
}

proc list_groups {} {
	
global debug_out list_groups tmp_dir
# get a list of all available groups

	puts $debug_out "list_groups called ([clock seconds])"
	set list_groups "All\n[exec pacman -b $tmp_dir -Sg | sort -d]"
}

proc list_special {execute_string} {

global debug_out filter list_all list_local selected_list all tmp_dir
# get a list of requested packages
# element, item, list, paclist, tmp_list, values - are temporary local variables
# returns list as Repo Package Version Available(na) Group(s) Description

	puts $debug_out "list_special - called to execute $execute_string ([clock seconds])"
	set list ""
	set paclist ""
	set tmp_list ""

	# now execute the command
	# some of these commands return an error if there are no results so we need to catch those errors
	set error [catch {eval [concat exec $execute_string]} paclist]
	puts $debug_out "list_special - ran $execute_string with error $error ([clock seconds])"
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
				return 1
			}
		}
	}
	# paclist should now be a clean list of all the packages found by the command.
	# now find the details of the package and make a list to show them
	puts $debug_out "list special - for each element find its details ([clock seconds])"

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
	puts $debug_out "list special created a list of packages ([clock seconds])"
	puts $debug_out "\tnow get the details for each of the packages found"
	foreach element $paclist {
		set values [lindex $list_all [lsearch $tmp_list $element]]
		lappend list $values
	}
	puts $debug_out "list special finished - now call list_show ([clock seconds])"
	list_show [lsort -dictionary -index 1 $list]
	return 0
}

proc list_show {list} {

global debug_out list_all list_local list_show list_show_ids listview_current listview_selected_in_order message 
# Show the list of packages in the .wp.wfone.listview window maintaining any selected items if possible
# Repo Package Version Available Group(s) Description

	puts $debug_out "list_show - called ([clock seconds])"

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
	set new_listview_selected_in_order ""
	puts $debug_out "list_show - show all the elements ([clock seconds])"
	foreach element $list {
		lappend list_show $element
		set id [.wp.wfone.listview insert {} end -values $element]
		lappend list_show_ids $id
		# if the item has been installed then tag it with the installed tag if a new version is available then tag it as outdated
		if {[lrange $element 3 3] != "{}"} {
			if {[lrange $element 2 2] == [lrange $element 3 3] || [lrange $element 3 3] == "-na-"} {
				# installed version equals available version or available version is unknown so...
				.wp.wfone.listview tag add installed $id
			} elseif {[lrange $element 0 0] == "local"} {
				# now test for athe local special case
				if {[string trim [lrange $element 2 2] "r"] < [string trim [lrange $element 3 3] "r"]} {
					# this is a local package and the installed version is less than the available version so...
					.wp.wfone.listview tag add outdated $id
				} else {
					.wp.wfone.listview tag add installed $id
				}
			} else {
				.wp.wfone.listview tag add outdated $id
			}
		}
		# if the item was previously selected then select it again
		# this selection will call bind again, so we will need to completely rewrite listview_selected_in_order
		# and save the id of the item if it is in the new list in the same order
		set index [lsearch $listview_selected_names [lrange $element 1 1]]
		if {$index != -1} {
			if {$index == 0} {
				set new_listview_selected_in_order $id
			} else {
				set new_listview_selected_in_order [linsert $new_listview_selected_in_order $index $id]
			}	
		}
	}
##	vwait tvselect
	puts $debug_out "list_show - show all the elements completed ([clock seconds])"
	.wp.wfone.listview selection add $new_listview_selected_in_order
	update
	set listview_selected_in_order $new_listview_selected_in_order
	puts $debug_out "list_show - listview_selected_in_order is $listview_selected_in_order"
	if {[llength $listview_selected_in_order] != 0} {
## this can cause an error, but I don't know why yet
##		puts $debug_out "list_show - last item selected is [lindex $listview_selected_in_order end]"
##		puts $debug_out "list_show - call get_dataview with last selected item"
##		get_dataview [lindex $listview_selected_in_order end]
##		.wp.wfone.listview selection add $listview_selected_in_order
		.wp.wfone.listview see [lindex $listview_selected_in_order end]
	} else {
		.wp.wfone.listview xview moveto 0
		.wp.wfone.listview yview moveto 0
	}
##	update
	puts $debug_out "list_show - finished ([clock seconds])"
	return 0
}

# GENERAL PROCEDURES

# SET UP BALLOON HELP
# Copyright (C) 1996-1997 Stewart Allen
# 
# This is part of vtcl source code
# Adapted for general purpose by 
# Daniel Roche <dan@lectra.com>
# version 1.1 ( Dec 02 1998 )

proc set_balloon {target message} {

global Bulle

	set Bulle($target) $message
	bindtags $target "[bindtags $target] Bulle"
}

proc kill_balloon {} {

global Bulle

	after cancel $Bulle(id)
	if {[winfo exists .balloon] == 1} {
		destroy .balloon
	}
	set Bulle(set) 0
}

proc balloon {target message {cx 0} {cy 0} } {

global Bulle helpbg

	if {$Bulle(first) == 1 } {
		set Bulle(first) 2
		if { $cx == 0 && $cy == 0 } {
			set x [expr [winfo rootx $target] + ([winfo width $target]/2)]
			set y [expr [winfo rooty $target] + [winfo height $target] + 4]
		} else {
			set x [expr $cx + 4]
			set y [expr $cy + 4]
		}
        toplevel .balloon -screen [winfo screen $target]
        wm overrideredirect .balloon 1
        label .balloon.l \
			-bd 0 \
			-font "TkTextFont" \
            -text $message \
            -bg $helpbg -padx 2 -pady 0 -anchor w
        pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${x}+${y}
        set Bulle(set) 1
    }
}

# bindings for balloon help

bind Bulle <Enter> {
    set Bulle(set) 0
    set Bulle(first) 1
    # wait for a short time and show the balloon help message
## and what if the window has been destroyed during the wait period?
    catch {set Bulle(id) [after 500 {balloon %W $Bulle(%W) %X %Y}]}
}

bind Bulle <Button> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Leave> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Motion> {
    if {$Bulle(set) == 0} {
        after cancel $Bulle(id)
        set Bulle(id) [after 500 {balloon %W $Bulle(%W) %X %Y}]
    }
}

# set balloon help

set_balloon .buttonbar.reload_button "Synchronize the database" 
set_balloon .buttonbar.install_button "Install, Re-install or Upgrade the selected items" 
set_balloon .buttonbar.delete_button "Delete the selected items" 
set_balloon .buttonbar.label_find "Click here to change the type of search" 
set_balloon .buttonbar.entry_find "Find some data in the list presently shown\n(excludes the Repository name)" 
set_balloon .buttonbar.label_findfile "Click here to change the type of search" 
set_balloon .buttonbar.entry_findfile "Find the package which owns a file\n(enter the full path to the file name)" 
set_balloon .buttonbar.clear_find_button "Clear the find data" 
set_balloon .buttonbar.configure_button "Options" 
set_balloon .filter_all "Show all packages for the selected Group"
set_balloon .group_entry "Only show packages in the selected Group"
set_balloon .group_label "Only show packages in the selected Group"
set_balloon .filter_clock "The elapsed time since the last sync (d:h:m)"
set_balloon .filter_clock_label "The elapsed time since the last sync (d:h:m)"
set_balloon .filter_installed "Only show installed packages for the selected Group"
set_balloon .filter_not_installed "Only show packages which are not installed for the selected Group"
set_balloon .filter_updates "Only show packages which have not been updated for the selected Group"
set_balloon .filter_list_orphans "List any unused packages (Orphans)"
set_balloon .filter_list_not_required "List only packages which are not required by any installed package"
set_balloon .filter_list_aur_updates "List only local packages which may need to be updated"
set_balloon .filter_list_aur_updates_all "Include all local packages in the AUR/Local Updates list"
set_balloon .scroll_selectgroup "Use right click to jump"
set_balloon .wp.wfone.ylistview_scroll "Use right click to jump"

# END OF BALLOON HELP

proc all_select {} {

global debug_out filter group list_show_ids select_all
# select all the items in listview

	if {[llength $list_show_ids] > 500} {
		set ans [tk_messageBox -default cancel -detail "" -icon warning -message "\nReally select [llength $list_show_ids] packages?" -parent . -title "Warning" -type okcancel]
		switch $ans {
			ok {continue}
			cancel {return 1}
		}
	}
	set select_all true
	.wp.wfone.listview selection add $list_show_ids
	# bind TreeviewSelect will update all the variables when the selection changes
	return 0
}

proc all_clear {} {
	
global debug_out listview_selected
# clear all the items selected in listview

	puts $debug_out "All clear started"
	.wp.wfone.listview selection remove $listview_selected
	# bind TreeviewSelect will update all the variables when the selection changess
}

proc aur_upgrade {package} {

global debug_out editor su_cmd terminal_string tmp_dir	
# download and install a package from AUR

# if the package directory exists then it may have been the result of an aborted upgrade from before
# so we will leave the partial/completed upgrades until we close 
# otherwise we would need to force the upgrade, which would be messy and dangerous	

	puts $debug_out "aur_upgrade called for $package"
	if {[catch {exec which curl}] != 0} {
		puts $debug_out "aur_upgrade - Curl not installed - return Error"
		return 1
	}
	# Create a download directory in the tmp directory
	file mkdir "$tmp_dir/aur_upgrades"
	
	# write a shell script to install the package
	puts $debug_out "aur_upgrade - Create a shell script to install $package"
	# tidy up any leftover files (which should not exist)
	puts $debug_out "\tdelete $tmp_dir/vpacman.sh"
	file delete "$tmp_dir/vpacman.sh"
	
	# now start the terminal session
	
	puts $debug_out "\twrite new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	puts $fid "cd \"$tmp_dir/aur_upgrades\""
	puts $fid "echo \"\nDownload $package snapshot\n\""
	puts $fid "curl -L -O \"https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz\""
	puts $fid "echo \"Unpack $package\n\""
	puts $fid "tar -xvf \"$package.tar.gz\""
	puts $fid "cd $tmp_dir/aur_upgrades/$package"
	puts $fid "echo -n \"\nDo you want to check the PKGBUILD file? \[Y/n\] \""
	puts $fid "read ans"
	puts $fid "case \"\$ans\" in"
    puts $fid "\tN*|n*)  ;;"
    if {[string trim $editor] == ""} {
		puts $fid "\t*) more PKGBUILD"
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
    puts $fid "function CheckIt () {"
	puts $fid "\techo \"\nSorry - an error occurred\""
	puts $fid "\techo \"\nPossibly missing dependancies.\""
	puts $fid "\techo \"If so then install all the missing dependancies and try again.\""
	puts $fid "\techo -ne \"\nInstall $package failed, press ENTER to close the terminal.\""
	puts $fid "\tread ans"
	puts $fid "\texit 1"
	puts $fid "}"
	puts $fid "echo -e \"\n$ makepkg -sci\n\""
	if {$su_cmd == "su -c"} {
		puts $fid "makepkg -c"
		puts $fid "if \[ $? -ne 0 \]"
		puts $fid "then"
		puts $fid "\tCheckIt"
		puts $fid "fi"
		puts $fid "echo -e \"\nA password is required to install $package\n\""
	} else {
		puts $fid "makepkg -sc"
		puts $fid "if \[ $? -ne 0 \]"
		puts $fid "then"
		puts $fid "\tCheckIt"
		puts $fid "fi"
	}
    if {$su_cmd == "su -c"} {
		puts $fid "$su_cmd \"pacman -U *.pkg.tar.xz\""
	} else {
		puts $fid "$su_cmd pacman -U *.pkg.tar.xz"
	}
	puts $fid "echo -ne \"\nInstall $package finished, press ENTER to close the terminal.\""
	puts $fid "read ans"
	puts $fid "exit 0" 
	close $fid
	puts $debug_out "Change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
#close $debug_out; exit

	set action "Upgrade AUR Package"	
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out "aur_upgrade - set message to TERMINAL OPENED to run $action"
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
	execute_terminal_isclosed $action
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out "aur_upgrade - Grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out "aur_upgrade - Window manager delete window re-instated"
	# flush the keyboard buffer in case somone was randomly clicking on the window
	flush_kb
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	set_message terminal ""
	update idletasks
	
	# now update all the lists. We need to do this because we did not work out the results of the script executed. 
	# It is possible that nothing changed.
	start
	# re-activate the sync button
	.buttonbar.reload_button configure -state normal
	# and reload the AUR updates
	get_aur_updates
	puts $debug_out "aur_upgrade command - completed ([clock seconds])"
}

proc check_config_files {} {

global debug_out

	# find any .pacnew and .pacsave files in /etc
	# find all the readable directories in /etc
	set dirs ""
	set dirs [get_tree "/etc"]
	# now find all the .pacnew and/or .pacsave files in those directories
	set list ""
	puts $debug_out "check_config_files found [llength $dirs] directories"
	foreach node $dirs {
		set files ""
		set files [glob -nocomplain -directory $node -types {f} -- *.pac*]
		if {$files != ""} {if {$list == ""} {set list $files} else {append list " " $files}}
	}

	if {$list == ""} {
		puts $debug_out "check_config no files found to update"	
		set_message terminal "No configuration files found to check"
		after 3000 {set_message terminal ""}
	} else {
		puts $debug_out "check_config found files to update: $list"	
		view_text "
	
	The following configuration files may need attention:
	
<lm1><code>	$list
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
	
global debug_out su_cmd

	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		# looks like we need to run this command in a terminal
		puts $debug_out "clean_cache ran paccache in a terminal"
		set action "Clean package cache"
		if {$su_cmd == "su -c"} {
			set command "$su_cmd \"paccache -rk3\""
		} else {
			set command "$su_cmd paccache -rk3"
		}
		set wait true
		execute_command $action $command $wait	
		set_message terminal "Paccache completed cleaning cache"
	} else {
		set error [catch {eval [concat exec $su_cmd paccache -rk3]} result]
		puts $debug_out "clean_cache called with Error $error and Result $result"
		if {$error != 0} {
			set_message terminal "Paccache returned an error cleaning cache"
			return 1
		} else {
			if {$result == "==> no candidate packages found for pruning"} {
				set_message terminal "No packages found for pruning"
			} else {
				set result [split $result \n]
				if {[llength $result] > 1} {set result [lindex $result [llength $result]-1]}
				set_message terminal "Cleaned cache [string range $result 14 end]"
				return 0
			}
		}
	}
	after 3000 {set_message terminal ""}
}
	
proc cleanup_checkbuttons {aur} {

global aur_only selected_list tv_order

	set aur_only $aur
	.wp.wfone.listview configure -selectmode extended
	set selected_list 0
	set tv_order "1a"
	remove_listgroups
	.filter_list_orphans configure -text "Orphans"
	.filter_list_not_required configure -text "Not Required"
	.filter_list_aur_updates configure -text "AUR/Local Updates"
	if {$aur_only == false} {
		.menubar.edit entryconfigure 0 -state normal
		.listview_popup entryconfigure 3 -state normal
	}
}

proc clock_format {time format} {

global debug_out

	switch $format {
		full {set format [clock format $time -format "%d/%m/%Y %H:%M"]}
		date {set format [clock format $time -format "%d/%m/%Y"]}
		time {set format [clock format $time -format "%H:%M"]}
	}

	return $format
}

# CONFIGURE

proc configure {} {

global browser buttons config_file debug_out editor geometry geometry_config geometry_view icon_dir installed_colour known_terminals old_values outdated_colour  terminal terminal_string save_geometry 

	toplevel .config

	set left [expr {[winfo width .] / 2} + [winfo rootx .] - 285]
	set down [expr [expr [winfo rooty .] -26] + 25]
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
	lappend old_values $buttons $browser $editor $geometry $geometry_config $save_geometry $terminal $terminal_string $installed_colour $outdated_colour
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
	puts $debug_out "Known terminals $tlist1"
	puts $debug_out "Known terminal strings $tlist2"
	puts $debug_out "Current terminal is $terminal - new terminal is $new_terminal"

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
	puts $debug_out "Background colour for normal Combobox is $background_colour"
	puts $debug_out "Foreground colour for normal Combobox is $foreground_colour"
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
		if {[lsearch $known_terminals $terminal] == -1} {
			set terminal_string "$terminal --title <title> --command <command>"
			puts $debug_out "configure - Terminal is $terminal - not a known terminal - String is $terminal_string"
		}
	}
	bind .config.terminal <<ComboboxSelected>> {
		puts $debug_out "configure - the terminal selection has changed. Terminal is $terminal Index is [.config.terminal current] ([expr [.config.terminal current] * 2 + 1]) String is [lindex $known_terminals [expr [.config.terminal current] * 2 + 1]]"
		set terminal_string "$terminal [lindex $known_terminals [expr [.config.terminal current] * 2 + 1]]"
		focus .config.terminal_string
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
			set wait false
			execute_command $action $command $wait
			# may be the configuration file has been edited
			.get_configs
		} \
		-text "Edit the Options File"
	button .config.reset \
		-command {
			# are you sure?
			set ans [tk_messageBox -default cancel -detail "Are you sure?" -icon warning -message "Reset all options to their default values" -parent .config -title "Warning" -type okcancel]
			if {$ans == "ok"} {
				configurable
				wm geometry . $geometry
				set left [expr {[winfo width .] / 2} + [winfo rootx .] - 285]
				set down [expr [expr [winfo rooty .] -26] + 25]
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
			if {$editor != "" && [catch {exec which $editor}] == 1} {
				tk_messageBox -default ok -detail "\"$editor\" is not installed" -icon warning -message "Choose a different editor" -parent . -title "Incorrect Option" -type ok 
				focus .config.editor
				set tests 1
			}
			if {[catch {exec which $terminal}] == 1} {
				tk_messageBox -default ok -detail "\"$terminal\" is not installed" -icon warning -message "Choose a different terminal" -parent . -title "Incorrect Option" -type ok 
				focus .config.terminal
				set tests 1
			}
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
			if {$buttons != [lindex $old_values 1]} {
				# reload the images for the button bar
				puts $debug_out "configure - the button size has changed"
				image create photo tools -file "$icon_dir/$buttons/configure.png"
				image create photo delete -file "$icon_dir/$buttons/edit-delete.png"
				image create photo install -file "$icon_dir/$buttons/dialog-ok-apply.png"
				image create photo reload -file "$icon_dir/$buttons/edit-redo.png"
			}
			if {$tests == 0} {
				puts $debug_out "configure - All tests have passed so save configuration options"
				# now save the current geometry of the main window
				if {[string tolower $save_geometry] == "yes"} {set geometry_config "[winfo width .config]x[winfo height .config]"}
				.put_configs
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
				set left [expr {[winfo width .] / 2} + [winfo rootx .] - 285]
				set down [expr [expr [winfo rooty .] -26] + 25]
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
	
	set_balloon .config.reset "Reset all settings to default values"
	set_balloon .config.save "Save settings"
	set_balloon .config.cancel "Cancel without saving"
	set_balloon .config.edit_file "Directly edit the options file"

	grab set .config
}

proc execute {type} {
	
global aur_only aur_updates debug_out s_time filter flag_actions listview_selected listview_selected_in_order list_outdated filter groups message  package_actions selected_list su_cmd terminal_string tmp_dir
# local variable are action command execute_string list mapstate type
# runs whatever we need to do in a terminal window

	puts $debug_out "execute - called for $type"

	# Install, Upgrade all and Sync will need an internet connection
	if {$type == "install" || $type == "upgrade_all" || $type == "sync"} {
		if {[test_internet] != 0} {return 1}
	}
	
	set list ""
	
	# disable the buttons, menu and popup entries, they will all be reset on the next treeview selection
	# except for the sync button which is disable to stop random clicking on it while the
	# terminal window is open. We will re-activate it at the end of this procedure.
	.buttonbar.reload_button configure -state disabled
	.buttonbar.install_button configure -state disabled
	.buttonbar.delete_button configure -state disabled
	.menubar.tools entryconfigure 1 -state disabled
	.menubar.tools entryconfigure 2 -state disabled
	.listview_popup entryconfigure 1 -state disabled
	.listview_popup entryconfigure 2 -state disabled
			
	foreach item $listview_selected {
		catch {lappend list [lrange [.wp.wfone.listview item $item -values] 1 1]}
	}
	
	set logfile [find_pacman_config logfile]
	set logfid [open $logfile r]
	seek $logfid +0 end
	puts $debug_out "execute - opened the pacman logfile ($logfile) and moved to the end of the file"
	
	if {$type == "install"} {
		if {$aur_only == true} {
			# pass execution to aur_upgrade with the package to update and stop executing this procedure
			aur_upgrade $list
			return 0
		} else {
			set action "Pacman Install/Upgrade packages"
			set command "$su_cmd pacman -S $list"
			if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -S $list\""}
		}
	} elseif {$type == "upgrade_all"} {
			set action "Pacman Full System Upgrade"
			set command "$su_cmd pacman -Syu"
			if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -Syu\""}
	} elseif {$type == "delete"} {
		set action "Pacman Delete packages"
		set command "$su_cmd pacman -R $list"
		if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -R $list\""}
	} elseif {$type == "sync"} {
		set action "Pacman Synchronize database"
		if {[catch {exec which fakeroot}] == 0} {
			set command "fakeroot pacman -b $tmp_dir -Sy"
		} else {
			set command "$su_cmd pacman -b $tmp_dir -Sy"
			if {$su_cmd == "su -c"} {set command "$su_cmd \"pacman -b $tmp_dir -Sy\""}
		}
		set s_time [clock seconds]
		start_clock
	} else {
		return 1
	}
	
	puts $debug_out "execute $action $command true"
	execute_command "$action" "$command" "true"	
	
	# remove any saved selections (since we won't know whether or not the install/delete/sync actually did anything.
	.wp.wfone.listview selection remove [.wp.wfone.listview selection]
	set listview_selected ""
	set listview_selected_in_order ""
	# now delete the contents from  listview, we do this now because otherwise we have to look at the wrong
	# contents until proc start completes
	.wp.wfone.listview delete [.wp.wfone.listview children {}]
	# and also delete the contents of dataview, it will be repopulated later
	puts $debug_out "execute - remove contents of dataview"
	get_dataview ""

	# try and find out what happened by reading the new entries in the log file
	# it seems that the logfile takes a while to be written, so we may need to pause here to allow the writes to complete
	# but at the moment we only use the added text for an install or upgrade, so we do not need to wait in any other cases.
## not sure how long it will take to complete the logfile so ...
## try 1000 - works OK
## now try 500	
	if {$type == "install" || $type == "upgrade_all"} {after 500}
	update
	set logtext [read $logfid]
	close $logfid
	puts $debug_out "execute - completed and logged these events ([clock seconds]):"
	puts $debug_out "$logtext"
	
	# update the temporary sync database if necessary
## but best work out if we actually did an upgrade
	if {$type == "upgrade_all"} {update_db}
	# set any reminders about actions needed for certain packages
	set action_message ""
	set lf ""
	foreach {package action} $package_actions {
		if {[string first " upgraded $package " $logtext] != -1} {
			set action_message [append action_message $lf $action]
			set lf "\n"
		}
	}
	if {$action_message != ""} {
		tk_messageBox -default ok -detail "$action_message" -icon info -message "Further action may be required" -parent . -title "Further Action" -type ok
	} else {
		puts $debug_out "execute - No package actions required"
	}
	# now update all the lists. We need to do this because we did not work out the results of the script executed. 
	# It is possible that nothing changed.
	start
	puts $debug_out "execute - completed the start procedure ([clock seconds])"
	
	# if all the outdated packages were updated successfully then set the filter back to all
	# the number of outdated packages will be shown as zero in any case
##	if {$filter == "outdated" && [llength $list_outdated] == 0} {
##		set filter "all"
##	}
	
	# selected_list is the list selection. If it is not 0 then run the required filter(_checkbutton)
	if {$selected_list != 0} {
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
	# re-activate the sync button
	.buttonbar.reload_button configure -state normal
	puts $debug_out "execute - completed"
}

proc execute_command {action command wait} {
	
global debug_out message su_cmd terminal_string tmp_dir
# runs a specific command in a terminal window
	
	puts $debug_out "execute_command - called for $action $command with wait set to $wait"
	# tidy up any leftover files (which should not exist)
	puts $debug_out "execute_command - delete $tmp_dir/vpacman.sh"
	file delete "$tmp_dir/vpacman.sh"
	
	# now start the terminal session
	
	puts $debug_out "execute_command - write new file $tmp_dir/vpacman.sh"
	set fid [open "$tmp_dir/vpacman.sh" w]
	puts $fid "#!/bin/sh"
	if {$su_cmd != ""} {
		puts $fid "echo -e \"$ $command \n\""
	} else {
		puts $fid "echo -e \"# $command \n\""
	}
	puts $fid "$command"
	if {$wait} {
		puts $fid "echo -ne \"\n[lrange $action 0 0] finished, press ENTER to close the terminal.\""
		puts $fid "read ans"
	}
	puts $fid "exit" 
	close $fid
	
	puts $debug_out "execute_command - change mode to 0755 - $tmp_dir/vpacman.sh"
	exec chmod 0755 "$tmp_dir/vpacman.sh"
	
	set execute_string [string map {<title> "$action" <command> "$tmp_dir/vpacman.sh"} $terminal_string]
	puts $debug_out "execute_command - set message to TERMINAL OPENED to run $action"
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
	puts $debug_out "execute - set grab on .buttonbar.label_message"
	# wait for the terminal to close
	execute_terminal_isclosed $action
	# release the grab
	grab release .buttonbar.label_message
	bind .buttonbar.label_message <ButtonRelease> {}
	puts $debug_out "execute - Grab released from .buttonbar.label_message"
	# re-instate the exit button now that the terminal is closed
	set_wmdel_protocol exit
	puts $debug_out "execute - Window manager delete window re-instated"
	# flush the keyboard buffer in case somone was randomly clicking on the window
	flush_kb
	# now tidy up
	file delete "$tmp_dir/vpacman.sh"
	set_message terminal ""
	update idletasks
	
	puts $debug_out "execute_command - completed"
	
}
	
proc execute_terminal_isclosed {action} {
	
global debug_out
# OK, nothing seems to work in tcl to watch when the terminal window closes. We can use a runfile
# but that does not catch a graceless exit. So we are going to use wmctrl to see when the window closes
# but this means we have to know the title of the window so that we can track it!

	set mapstate "normal"
	set count 0
	while {true} {
		incr count
		# if xwininfo is installed then
		if {[catch {exec which xwininfo}] == 0} {
			# check, during the loop, if the main window has been minimised.
			# if it is later maximised then redraw the window
			set error 1
			# run xwininfo until it does not return an error
			while {$error != 0} {set error [catch {exec xwininfo -name "View and Modify Pacman Database" -stats} state]}
			set state [split $state \n]
			if {[lsearch $state "  Map State: IsViewable"] != -1} {
				if {$mapstate == "unmapped"} {
					flush_kb
					update
					set mapstate "normal"
				}
			} else {
				set mapstate "unmapped"
			}
			puts $debug_out "execute_terminal_isclosed - Vpacman window is $mapstate"
		} else {
			puts $debug_out "execute_terminal_isclosed - xwininfo is not installed"
		}
		puts $debug_out "$ wmctl -l - [clock format [clock seconds] -format {%H:%M:%S}]"
		set error 1
		set windows ""
		# get a list of open windows from wmctrl with no errors
		while {$error != 0} {set error [catch {exec wmctrl -l} windows]}
		puts $debug_out "Window List: \n$windows"
		if {[string first "$action" $windows] == -1} {
			puts $debug_out "execute_terminal_isclosed - terminal window \"$action\" closed - break after $count loops"
			break
		}
		puts $debug_out "execute_terminal_isclosed - terminal window \"$action\" is open (loop $count)- continue"
		# update the contents and get rid of any random keystokes, just in case
		flush_kb
		flush $debug_out
		update
		# and wait a few milliseconds ## was set to 250 which seemed to be too fast?
		after 500
				
	}
	puts $debug_out "execute_terminal_isclosed - loop has completed after $count loops ([clock seconds])"	
	return 0
}

proc execute_terminal_isopen {action} {

global debug_out
# Make sure that the terminal window is open, it sometimes takes some time
	
	puts $debug_out "execute_terminal_isopen - wait for the Terminal window to open"
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
		# and wait a few milliseconds ## was set to 250 which seemed to be too fast
		after 500 
	}
	puts $debug_out "execute_terminal_isopen - loop has completed after $count loops ([clock seconds])"
	return 0
}

proc filter {} {
	
global aur_updates debug_out filter filter_list find group list_all list_installed list_outdated list_uninstalled listview_current
# procedure to run when we need to filter the output
# element and list are local variables

	puts $debug_out "filter proc called - filter is \"$filter\", group is \"$group\", find is \"$find\""

	if {$filter == "" && $find == "" && $group == "All"} {return 0}

	set filter_list ""
	set list ""
	
	# if a filter is set then which overall list do we need to filter by
	switch $filter {
		"all" {
			set list $list_all
			puts $debug_out "filter - list set to list_all"
		}
		"installed" {
			set list $list_installed
			puts $debug_out "filter - list set to list_installed"
		}
		"not_installed" {
			set list $list_uninstalled
			puts $debug_out "filter - list set to list_uninstalled"
		}
		"outdated" {
			set list $list_outdated
			puts $debug_out "filter - list set to list_outdated"
		}
		"aur" {
			set list $aur_updates
			puts $debug_out "filter - list set to aur_updates"
		}
	}
	
	# now filter on any group selected
	puts $debug_out "filter - now filter by group"
	if {$group != "All"} {
		puts $debug_out "filter - group is $group"
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
	puts $debug_out "filter - now find $find in filter_list"
	if {$find != ""} {
		# find and show the results
		find $find $filter_list
	} else {
		# show the list
		list_show [lsort -dictionary -index 1 $filter_list]
	}

}

proc filter_checkbutton {button command title} {

global debug_out filter filter_list find group list_show selected_list
# procedure to execute when a list checkbutton is selected

	puts $debug_out "filter checkbutton called by $button with command $command  - the title is set to $title ([clock seconds])"

	set error 0
	set filter "none"
	set filter_list ""
	set group "All"
	# lose any existing find command, selected groups, and/or messages for the special filters
	set find ""
	.buttonbar.entry_find delete 0 end
	set_message find ""
	remove_listgroups
	
	# if the button was unchecked then reset the filter to all
	if {$selected_list == 0} {
		set filter "all"
		filter
	} else {
		$button configure -text "Searching ...    "
		update
		puts $debug_out "filter checkbutton called list special with $command ([clock seconds])"
		set result [list_special "$command"]
		puts $debug_out "filter checkbutton - list_special returned with the result $result ([clock seconds])"
		if {$result == 1} {
		# OK so it did not work, so reset everything to normal and return
			$button configure -text "$title"
			set selected_list 0
			set filter "all"
			return 1
		} else {
			.wp.wfone.listview configure -selectmode browse
			puts $debug_out "filter_checkbutton set wp.wfone.listview to selectmode browse"
			$button configure -text "$title ([llength $list_show])"
			set filter_list $list_show
			return 0
		}
	}
	return 0
}

proc find {find list} {

global debug_out group list_all list_installed list_uninstalled listview_current message
# find all the items containing the find string
# this will search whatever is in the list and show the results in listview

	puts $debug_out "find - called to find $find in list"
	set list_found ""
	foreach element $list {
	# search for the string in the chosen list, but excluding the first item in the list values
	# which is the Repo
		if {[string first $find [lrange $element 1 end]] != -1} {
			lappend list_found $element
		}
	}
	set_message find "Found [llength $list_found] packages"
	update idletasks
	# show the new list found, which replaces list_show with that list
	list_show $list_found
	}
	
proc find_pacman_config {data} {
		
	switch $data {
		logfile {
			set logfile "/var/log/pacman.log"
			
			# check log file location in /etc/pacman.config
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
			
			# check database location in /etc/pacman.config
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
	}
}

proc get_aur_updates {} {

global aur_all aur_messages aur_only aur_updates aur_versions debug_out filter filter_list find group list_local selected_list tmp_dir
# check for local packages which may need to be updated

	puts $debug_out "get_aur_updates - called ([clock seconds])"
	# if aur_only is true then this was the last procedure run
	puts $debug_out "get_aur_updates - aur_only is $aur_only"
	set aur_updates ""
	set filter "aur"
	set filter_list ""
	set group "All"
	set messages ""
	# avoid looking up all the updates a second time if aur_only is already true
	if {$aur_only == "false"} {
		puts $debug_out "get_aur_updates - find aur_versions ([clock seconds])"
		# lose any existing find command, selected groups, and/or messages for the special filters
		set find ""
		.buttonbar.entry_find delete 0 end
		set_message find ""
		puts $debug_out "get_aur_updates - find set to blank"
		remove_listgroups
		# test for internet
		.filter_list_aur_updates configure -text "Test for Internet ..."
		update
		set error [test_internet]
		if {$error != 0} {
			# OK so there is no internet available, so reset everything to normal and return
			.filter_list_aur_updates configure -text "AUR/Local Updates"
			set selected_list 0
			set filter "all"
			return 1
		}
		set aur_only true
		set list ""
		set aur_versions ""
		puts $debug_out "get_aur_updates started ([clock seconds])"
		foreach item $list_local {
			# make up a list of all the local packages in the format &arg[]=package&arg[]=package etc.
			set list [append list "\&arg\[\]=[lindex $item 1]"]
		}
		# now find all the information on these packages
## this is a fudge until I find out how to do this in tcl alone
set fid [open "$tmp_dir/get_aur_updates.sh" w]
puts $fid "#!/bin/bash"
puts $fid "curl -LfGs \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > \"$tmp_dir/vpacman_aur_result\""
close $fid
exec chmod 0755 "$tmp_dir/get_aur_updates.sh"

.filter_list_aur_updates configure -text "Searching ..."
exec "$tmp_dir/get_aur_updates.sh"
file delete "$tmp_dir/get_aur_updates.sh"
#	these did not work:
#	set result [eval [concat exec curl -Lfs \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" > $tmp_dir/vpacman_aur_result]]
#	set result [eval [concat exec curl -Lfs \"https://aur.archlinux.org//rpc/?v=5&type=info$list\" 2>@1]]
##

		.filter_list_aur_updates configure -text "AUR/Local Updates"
		puts $debug_out "get_aur_updates - found result ([clock seconds])"
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
		puts $debug_out "get_aur_updates found AUR package version details ([clock seconds])"
		#puts $debug_out "$aur_versions"
	}
	puts $debug_out "get_aur_updates - found aur_versions, now check against list_local"
	# now read each of the local packages and compare them to the information in aur_versions
	foreach line $list_local {
		set element ""
		set name [lindex $line 1]
		set version [lindex $line 2]
		set index [lsearch $aur_versions $name]
		if {$index == -1} {
			set messages [append messages "Warning: $name was not found in the AUR packages\n"]
			if {$aur_all} {
				lappend element "local" "$name" "$version" "[lindex $line 3]" "[lindex $line 4]" "[lindex $line 5]"
			}
		} else {
			if {$aur_all} {
				lappend element "local" "$name" "$version" "[lindex $aur_versions $index+1]" "[lindex $line 4]" "[lindex $aur_versions $index+2]"
			} else {
				# check if the new version is greater that the current version
				if {[string trim "$version" "r"] < [string trim [lindex $aur_versions $index+1] "r"]} {
					lappend element "local" "$name" "$version" "[lindex $aur_versions $index+1]" "[lindex $line 4]" "[lindex $aur_versions $index+2]"
				}					
			}
		}
		if {$element != ""} {lappend aur_updates $element}
	}
	# aur_updates should now be a clean list of all the updates including all the local packages if requested
	set filter_list $aur_updates
	.filter_list_aur_updates configure -text "AUR/Local Updates ([llength $filter_list])"
	if {$messages != "" && $aur_messages == "true"} {
		set ans [tk_messageBox -default yes -detail "Do you want to view the warning messages now?" -icon question -message "There are warning messages from the AUR/Local Updates." -parent . -title "Upgrade Warnings" -type yesno]
		switch $ans {
			no {set aur_messages "false"}
			yes {
				view_text "$messages" "AUR/Local Updates Messages"
			}	
		}
	}
	.wp.wfone.listview configure -selectmode browse
	if {$find != ""} {
		puts $debug_out "get_aur_updates - called find"
		find $find $aur_updates
	} else {
		list_show "$aur_updates"
	}
}

proc get_aur_version {package} {
	
global debug_out
# user curl to get the Version number and description for a package from the RPC interface
# we don't actually use the description yet"

	if {[catch {exec which curl}] != 0} {
		puts $debug_out "get_aur_version - Curl not installed - return Error"
		return [list "Error" "Error"]
	}
	if {[test_internet] != 0} {return [list "Error" "Error"]}
	puts $debug_out "get_aur_version called for $package ([clock seconds])"
	set result [eval [concat exec curl -Lfs "https://aur.archlinux.org//rpc/?v=5&type=info&arg[]=$package"]]
	# puts $debug_out "\t$result"
	set position [expr [string first "Version" $result] + 10]
	set version [string range $result $position [expr [string first \" $result $position] - 1]]
	set position [expr [string first "Description" $result] + 14]
	set description [string range $result $position [expr [string first \" $result $position] - 1]]
	puts $debug_out "get_aur_version returns ([clock seconds]) - Version is $version - Description is $description"
	return [list $version $description]
}

proc get_dataview {current} {

global aur_only browser debug_out tmp_dir
# get the data from the database to show in the notebook page selected in .wp.wftwo.dataview
# current is the item id of the latest selected row

	puts $debug_out "get_dataview - called for $current"
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
		#store the package name on listview_current for use below
		set listview_current [lrange $item 1 1]
		switch [.wp.wftwo.dataview select] {
			.wp.wftwo.dataview.info {
				grid remove .wp.wftwo.ydataview_moreinfo_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_info_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				# If this is a local package it will take up to half a second to get the available versions
				# so we need to implement a note to say why we are waiting
				set info [.wp.wfone.listview item $current -values]
				.wp.wftwo.dataview.info insert 1.0 "Repository      : [lrange $info 0 0]\n"
				#  if we know of a browser, and this is a local package then use the package name to make a URL and insert tags accordingly
				if {$aur_only == true && $browser != ""} {
					# click on the link to view it in the selected browser
					.wp.wftwo.dataview.info tag bind get_aur <ButtonRelease-1> "exec $browser https://aur.archlinux.org/packages/[lrange $info 1 1] &"
					# add the normal text to the text box
					.wp.wftwo.dataview.info insert end "Name            : " 
					# add the package name to the text box and use the pre-defined tags to alter how it looks
					.wp.wftwo.dataview.info insert end "[lrange $info 1 1]\n" "url_tag get_aur url_cursor_in url_cursor_out" 
				} else {
					.wp.wftwo.dataview.info insert end "Name            : [lrange $info 1 1]\n"
				}
				puts $debug_out "\tinstalled is [lrange $info 2 2] Available is [lrange $info 3 3]"
				if {[lrange $info 3 3] == "{}"} {
					.wp.wftwo.dataview.info insert end "Installed       : no\n"
					.wp.wftwo.dataview.info insert end "Available       : [lrange $info 2 2]\n"
				} elseif {[lrange $info 3 3] == "-na-"} {
					puts $debug_out "\tavailable was -na-"
					.wp.wftwo.dataview.info insert end "Installed       : [lrange $info 2 2]\n"
					.wp.wftwo.dataview.info insert end "Available       : Searching ...\n"
##					update
					# since this is an AUR package or another local install
					# we can use an RPC to get the latest version number and the description
					set result [get_aur_version [lrange $info 1 1]]
					set version [lindex $result 0]
					set description [lindex $result 1]
					set description [string map {\\ ""} $description]
					puts $debug_out "get_dataview - info - get aur version returned $version"
					if {$version == ""} {set version "not found in AUR"}
					.wp.wftwo.dataview.info delete [expr [.wp.wftwo.dataview.info count -lines 0.0 end] -1].18 end
					.wp.wftwo.dataview.info insert end "$version \n"
					puts $debug_out "Version available is $version"
				} else {
					.wp.wftwo.dataview.info insert end "Installed       : [lrange $info 2 2]\n"
					.wp.wftwo.dataview.info insert end "Available       : [lrange $info 3 3]\n"
				}
				.wp.wftwo.dataview.info insert end "Member of       : [lrange $info 4 4]\n"
				if {[string trim [lrange $info 5 5] "{}"] == "DESCRIPTION"} {
					# if we could not get the description from the AUR RPC call above
					if {$description == ""} {
						.wp.wftwo.dataview.info insert end "Description     : Searching ...\n"
						update
						set error [catch {exec pacman -b $tmp_dir -Qi $listview_current} result]
						if {$error == 1} {
							set description "not found in AUR"
						} else {
							set description [string range [lindex [split $result \n] 2] 18 end]
						}
						.wp.wftwo.dataview.info delete [expr [.wp.wftwo.dataview.info count -lines 0.0 end] -1].18 end
						.wp.wftwo.dataview.info insert end "$description"
					} else {
						.wp.wftwo.dataview.info insert end "Description     : $description"
					}
				} else {
					.wp.wftwo.dataview.info insert end "Description     : [string trim [lrange $info 5 5] "{}"]"
				}
			}
			.wp.wftwo.dataview.moreinfo {
				grid remove .wp.wftwo.ydataview_info_scroll
				grid remove .wp.wftwo.ydataview_files_scroll
				grid .wp.wftwo.ydataview_moreinfo_scroll -in .wp.wftwo -row 1 -column 2 \
					-sticky ns
				.wp.wftwo.dataview.moreinfo insert 1.0 "Searching ..."
				update
				set info [.wp.wfone.listview item $current -values]
				# try to get the info from the main database
				set error [catch {split [exec pacman -b $tmp_dir -Sii $listview_current] \n} result]
				if {$error != 0} {
					# if that did not work then try the local database
					set error [catch {split [exec pacman -b $tmp_dir -Qi $listview_current] \n} result]
					set result [linsert $result 0 "Repository      : local"]
				}
				# and if it is installed then save the first line of the data, the repository,
				# and then get the rest from the local database
				if {[lrange $info 3 3] != "{}"} {
					# $result holds the info from the main database until it is overwritten
					set repository "[lindex $result 0]"
					set error [catch {split [exec pacman -b $tmp_dir -Qi $listview_current] \n} result]
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
								if {[lrange $info 3 3] == "{}"} {
									.wp.wftwo.dataview.moreinfo insert end "Installed       : no\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : [lrange $info 2 2]\n"
								} elseif {[lrange $info 3 3] == "-na-"} {
									puts $debug_out "Available was -na-"
									.wp.wftwo.dataview.moreinfo insert end "Installed       : [lrange $info 2 2]\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : Searching ...\n"
									update
									# since this is an AUR package or another local install
									# we can use an RPC to get the latest version number
									set result [get_aur_version [lrange $info 1 1]]
									set version [lindex $result 0]
									if {$version == ""} {set version "not found in AUR"}
									.wp.wftwo.dataview.moreinfo delete [expr [.wp.wftwo.dataview.moreinfo count -lines 0.0 end] -1].18 end
									.wp.wftwo.dataview.moreinfo insert end "$version \n"
									puts $debug_out "Version available is $version"
								} else {
									.wp.wftwo.dataview.moreinfo insert end "Installed       : [lrange $info 2 2]\n"
									.wp.wftwo.dataview.moreinfo insert end "Available       : [lrange $info 3 3]\n"
								}
							} else {
								.wp.wftwo.dataview.moreinfo insert end "$row\n"
							}
						}
					}
				} else {
					.wp.wftwo.dataview.moreinfo insert end "Could not get any information for $listview_current"
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
				set error [catch {split [exec pacman -b $tmp_dir -Qlq $listview_current] \n} result]
				if {$error != 0} {
					# if that did not work then try using pkgfile to get the file list from the main database
					# if this does not work then pkgfile may not be installed
					set error [catch {split [exec pkgfile -lq $listview_current] \n} result]
				}
				.wp.wftwo.dataview.files delete 1.0 end
				if {$error == 0} {
					foreach row $result {
						.wp.wftwo.dataview.files insert end $row\n
					}
				} else {
					.wp.wftwo.dataview.files insert end "Could not get the file list for $listview_current\n"
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
				set error [catch {exec pacman -b $tmp_dir -Qk $listview_current} result]
				.wp.wftwo.dataview.check delete 1.0 end
				if {[string first "error:" $result] == -1} {
					set result [split $result \n]
					foreach row $result {
						.wp.wftwo.dataview.check insert end $row\n
					}
				} else {
					.wp.wftwo.dataview.check insert end "Could not check $listview_current, it is not installed"
				}
			}
		}
	} else {
		[.wp.wftwo.dataview select] delete 1.0 end
	}
	puts $debug_out "get_dataview - completed and returned 0"
	return 0
}

proc get_file_mtime {dir ext} {

global debug_out
# find the latest modified time for a series of files with a given extention in the given directory	

	set last 0
	set files [glob -nocomplain $dir/*.$ext]
	foreach file $files {
		set time [file mtime $file]
		if {$last < $time} {set last $time}
	}
}

proc get_tree {rootdir} {

global debug_out dirs
# recursively list the directory tree under any given root, giving the full path name of all descendants
# lifted straight from http://wiki.tcl.tk/1474 - thanks Bob

	set currentnodes [glob -nocomplain -directory $rootdir -types {d r} -- *]
	if {[llength $currentnodes] <= 0} {
    # Base case: the current dir is a leaf so save it
		lappend dirs $rootdir
		#puts $debug_out "get_tree found $dirs"
		return $dirs
	} else {
	# save the current node 
		lappend dirs $rootdir
	# and recurse over all directories at this level
		foreach node $currentnodes {
			get_tree $node
		}
	}
	return $dirs
}

proc flush_kb {} {
	
	# No waiting for input
	fconfigure stdin -blocking 0
	# Drain the data by not saving it anywhere
	read stdin
	# Flip back into blocking mode (if necessary)
	fconfigure stdin -blocking 1
}

proc read_config {}  {
	
global debug_out  
# read the pacman configuration file 

	puts $debug_out "read_config called ([clock seconds])"
	
	# read /etc/pacman.config
	set config_text ""
	set config_text [exec cat "/etc/pacman.conf"]
	puts $debug_out "read_config complete ([clock seconds])"
	
	view_text $config_text "Pacman Configuration"
}

proc read_log {action}  {
	
global debug_out 
# read through the pacman log file and find, if possible, when the last sync happened

	puts $debug_out "read_log called ([clock seconds])"
	
	set sync_time "na"
	set log_text ""
	set logfile [find_pacman_config logfile]
	
	puts $debug_out "read_log - Logfile is $logfile"
	# read the last 200 lines of the logfile
	set log_text [exec tail -200 $logfile]
	# find the last time the sync database was updated
	# the update may be the copy sync database or the pacman sync database
	# if the latter then it should have been via a full system update
## but we may need to check that an external operation did the update
	if {$action == "synctime"} {
		set tmp_log_text [split $log_text \n]
		set count 0
		foreach line $tmp_log_text {
			if {[string first "synchronizing package lists" $line] != -1} {			
				set sync_time [clock scan [string range $line 1 16] -format "%Y-%m-%d %H:%M" ]
			}
		}
		puts $debug_out "read_log - last update was $sync_time"
		if {$sync_time != "na"} {
			set s_time $sync_time
			start_clock
		}
		puts $debug_out "read_log - synctime complete ([clock seconds])"
		return s_time
	}
	if {$action == "view"} {
		view_text $log_text "Pacman Log"
	}
}

proc read_news {} {
	
global browser debug_out home
# user curl to get the latest news from the arch rss feed

	if {[catch {exec which curl}] != 0} {
		puts $debug_out "read_news - Curl not installed - try web"
		if {$browser == ""} {return 1}
		if {[test_internet] != 0} {return 1}
		exec $browser "https://www.archlinux.org/" &
		return 0
	} else {
		if {[test_internet] != 0} {return 1}
		puts $debug_out "read_news - download arch rss ([clock seconds])"
		set error [catch {eval [concat exec curl -s https://www.archlinux.org/feeds/news/]} rss_news]
		if {$error != 0} {return 1}
		set rss_news [split $rss_news "<>"]
		puts $debug_out "\tdone ([clock seconds])"
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
		puts $debug_out "read_news rss parsed  ([clock seconds])"
		view_text $news_list "Latest News"
	}
}

proc set_message {type text} {
	
global debug_out find_message message selected_message
# print a message consisting of any saved message plus any new text:
	
	# when a new item is selected then print the text and save it in the selected message variable
	if {$type == "selected"} {
		set selected_message $text
		set message "$find_message $text"
	} elseif {$type == "find"} {
	# when any items are found using the find procedure, print the text followed by the any saved selected message
	# save the text in the find message variable
		set find_message $text
		set message "$text $selected_message"
	} elseif {$type == "terminal"} {
	# for other types of message just print the text
		set message "$text"
	}
	
}

proc sort_list_show {heading} {
	
global debug_out list_installed list_show list_show_order
# sort the list according to the heading selected
# the values are Repo Package Available Installed Group(s) Description
# the headings are Package Version Available Repo

	set index 0
	set list ""
	
	switch $heading {
		"Package" {set index 1; set list $list_show}
		"Version" {set index 2; set list $list_show}
		"Available" {set index 3; set list $list_installed}
		"Repo" {set index 0; set list $list_show}
	}
	if {$list_show_order == "$heading increasing"} {
		set list [lsort -index $index -decreasing $list]
		set list_show_order "$heading decreasing"
	} else {
		set list [lsort -index $index -increasing $list]
		set list_show_order "$heading increasing"
	}
	list_show $list
}

proc start {} {
	
global count_all count_installed count_uninstalled count_outdated debug_out list_all
# this is the process to start the programme from scratch
# or after an update is called	

	list_local
	puts $debug_out "list_local ([clock seconds])"
	# draw the screen now to make it appear as if it is loading faster and get the full list of packages
	update
	list_all
	puts $debug_out "list_all ([clock seconds])"
	count_lists
	puts $debug_out "count_lists ([clock seconds])"
	
	.filter_installed configure -text "Installed ($count_installed)"
	.filter_all configure -text "All ($count_all)"
	.filter_not_installed configure -text "Not Installed ($count_uninstalled)"
	.filter_updates configure -text "Updates Available ($count_outdated)"
	
	update
	filter
	list_groups
}

proc start_clock {} {
	
global debug_out s_time
# work out the elapsed time since the required event (start or last sync)

	set e_time [expr [clock seconds] - $s_time]
	set days [expr int($e_time / 60 / 60 / 24)]
	if {[string length $days] == 1} {set days "0$days"}
	set hours [expr int($e_time / 60 / 60) - ($days * 24)] 
	set mins [expr int(($e_time / 60) - ($hours * 60) - ($days * 60 * 24))]
#	# if the elapsed time includes days
#	if {$days != 0} {
#		.filter_clock configure -text "${days} d ${hours} h"
#	# if the elapsed time is less one day but includes hours
#	} elseif {$hours != 0} {
#		.filter_clock configure -text "${hours} h ${mins} min" 
#	} else {
#		.filter_clock configure -text "${mins} min"
#	}
	.filter_clock configure -text "${days}:[string range "0${hours}" end-1 end]:[string range "0${mins}" end-1 end] "
	update
	# wait a minute
	after 60000 start_clock
}

proc system_upgrade {} {

global debug_out filter find fs_upgrade s_time tvselect

	set fs_upgrade true
	update idletasks
	cleanup_checkbuttons false
	set find ""
	.buttonbar.entry_find delete 0 end
	set filter "outdated"
	filter
	puts $debug_out "system_upgrade - clear tvselect"
	set tvselect ""
	all_select
	# we changed the selection
	# TreeviewSelect now updates the selection and sets a new message
	# select everything in the outdated list
	# wait for TreeviewSelect to complete
	vwait tvselect
	puts $debug_out "system_upgrade - all selected"
	set return [execute "upgrade_all"]
	if {$return == 1} {
		all_clear
		set fs_upgrade false
		return 1
	}
	set fs_upgrade false
	set s_time [clock seconds]
	start_clock
	start
}

proc test_configs {} {
	
global browser editor known_browsers known_editors known_terminals terminal 
# Test for sane configuration options

	set tests 0
	if {$browser != "" && [catch {exec which $browser}] == 1} {
		tk_messageBox -default ok -detail "\"$browser\" is configured but is not installed" -icon warning -message "The browser has been reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default browser $known_browsers
	}
	if {$editor != "" && [catch {exec which $editor}] == 1} {
		tk_messageBox -default ok -detail "\"$editor\" is configured but is not installed" -icon warning -message "The editor has been reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default editor $known_editors
	}
	if {[catch {exec which $terminal}] == 1} {
		tk_messageBox -default ok -detail "\"$terminal\" is configured but is not installed" -icon warning -message "The terminal has been reset" -parent . -title "Incorrect Option" -type ok 
		configurable_default terminal $known_terminals
	}
}

proc test_internet {} {
	
global debug_out
# try three times to find an internet connection

	set count 0
	while {$count < 3} {
		set error [catch {eval [concat exec timeout 1 ping -c 1 www.google.com]} result]
		puts $debug_out "test_internet - $count returned $error"
		if {$error == 0} {return 0}
		incr count
		after 100
	}
	set ans [tk_messageBox -default ok -detail "" -icon warning -message "No Internet - Please check your internet connection and try again" -parent . -title "Warning" -type ok]
	return "Error"
}

proc update_cups {} {
	
global debug_out home message su_cmd
# if we have gutenprint installed the run cups-genppdupdate
# restart cups. If necessary run systemctl daemons-reload first.

	if {$su_cmd == "su -c" || $su_cmd == "sudo"} {
		# looks like we will have to do this in a terminal
		set return [catch {exec which cups-genppdupdate}]
		if {$return != 1} {
			puts $debug_out "update_cups ran cups-genppdupdate in a terminal"
			set action "Update cups ppds"
			if {$su_cmd == "su -c"} {
				set command "$su_cmd \"cups-genppdupdate\""
			} else {
				set command "$su_cmd cups-genppdupdate"
			}
			set wait false
			execute_command $action $command $wait
		}
		puts $debug_out "update_cups ran systemctl daemon-reload in a terminal"
		set action "Reload daemons"
		if {$su_cmd == "su -c"} {
			set command "$su_cmd \"systemctl daemon-reload\""
		} else {
			set command "$su_cmd systemctl daemon-reload"
		}
		set wait false
		execute_command $action $command $wait
		
		puts $debug_out "update_cups ran systemctl restart org.cups.cupsd in a terminal"
		set action "Restart CUPS"
		if {$su_cmd == "su -c"} {
			set command "$su_cmd \"systemctl restart org.cups.cupsd\""
		} else {
			set command "$su_cmd systemctl restart org.cups.cupsd"
		}
		set wait false
		execute_command $action $command $wait
		set_message terminal "Restarted cups"
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

global dbpath debug_out tmp_dir
# make sure that we are using an up to date copy of the sync databases

	puts $debug_out "update_db started ([clock milliseconds] ms)"
	puts $debug_out "Make a copy of the sync directory in $tmp_dir/sync"
	file delete -force $tmp_dir/sync
	file copy -force $dbpath/sync $tmp_dir
	puts $debug_out "update_db completed ([clock milliseconds] ms)"
}

proc view_text {text title} {

global browser debug_out save_geometry geometry_view
# open a window and display some text in it

	catch {destroy .view}
	
	toplevel .view
	
	wm iconphoto .view  view
	wm geometry .view $geometry_view
	wm protocol .view WM_DELETE_WINDOW {
		if {[string tolower $save_geometry] == "yes"} {set geometry_view [wm geometry .view]; .put_configs}
		destroy .view
	}
	wm title .view $title
	
		text .view.listbox \
			-background white \
			-selectforeground red \
			-tabs "[expr {4 * [font measure TkTextFont 0]}] left" \
			-tabstyle wordprocessor \
			-wrap word \
			-yscrollcommand ".view.scrollbar1 set"
	
		scrollbar .view.scrollbar1 \
			-command ".view.listbox yview"
	
		button .view.close_button \
			-command {
				if {[string tolower $save_geometry] == "yes"} {set geometry_view [wm geometry .view]; .put_configs}
				destroy .view
			} \
			-relief raised \
			-text "Close" \
			-width 7
			
			
		# Geometry management
	
		grid .view.listbox -in .view -row 1 -column 1  \
			-sticky nesw
		grid .view.scrollbar1 -in .view -row 1 -column 2  \
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

# main
# OK lets do it

# make sure that the required link exists for the local database
file delete -force $tmp_dir/local
set dbpath [find_pacman_config dbpath]
puts $debug_out "Database directory is $dbpath"
puts $debug_out "Link local directory in $tmp_dir/local"
file link $tmp_dir/local $dbpath/local

# check last modified times for the pacman database and its copy
puts $debug_out "Pacman database was last modified at [file mtime $dbpath/sync]"
if {[file isdirectory $tmp_dir/sync]} {
	puts $debug_out "Copy database was last modified at [file mtime $tmp_dir/sync]"
	# update_db will create the copy of the sync directory if necessary and copy the contents from the pacman DBPath
	if {[file mtime $dbpath/sync] > [file mtime $tmp_dir/sync]} {update_db}
} else {
	# temp sync directory does not exists, so create it
	update_db
}
# test the current configuration options
test_configs
puts $debug_out "Post configuration file: browser set to $browser, editor set to $editor, terminal set to $terminal"

# set the elapsed time base time and start the clock
set s_time [file mtime $tmp_dir/sync]
start_clock

start
