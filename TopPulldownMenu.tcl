####################################################################################
# FILE NAME : topPulldownMenu.tcl
# PURPOSE : Scan all tcl/tk scripts in HW_CONFIG_PATH and add them 
#           to a top pulldown menu named ""
# USAGE : Add "source [full path]/topPulldownMenu.tcl" in the "hmcustom.tcl" file 
# INPUT : NONE
# OUTPUT : NONE
# AUTHOR : LAI QIBO@XMKL
####################################################################################

namespace eval ::topPulldownMenu {

    package require hwat
    variable scriptPath [file dirname [info script]]
    set count 1

    proc menuFuncRegister { procName } {
        
        set after_userprofile_procs [hm_framework getregisteredprocs after_userprofile]
        if {[lsearch $after_userprofile_procs $procName] == -1} {
            hm_framework registerproc $procName after_userprofile
        }
        
    }

    if {[hm_info -appinfo VERSION] > 8.0 && [info procs [namespace current]::menuFuncRegisterAction] == ""} {
        hm_setpanelproc :[namespace current]::menuFuncRegisterAction
    }
    proc menuFuncRegisterAction {} {

        foreach name_proc [hm_framework getregisteredprocs after_userprofile] {
            if {$name_proc == "::hm::notebooktab::panedwindow::PAVisible"} {
                set name_proc [concat $name_proc " up"]
            } 
            eval $name_proc
        }

    }   
}

proc ::topPulldownMenu::loadHmtclScript {hmFileName} {

    *readfile $hmFileName

}

proc ::topPulldownMenu::addMenuItem {args} {

    variable scriptPath
    set mainTopMenu [hm_framework getpulldowns]
    catch {$mainTopMenu delete "KL_NVH"}
    destroy $mainTopMenu.customMenu
    menu $mainTopMenu.customMenu -tearoff 0
    $mainTopMenu insert "Help" cascade -label "KL_NVH" -menu $mainTopMenu.customMenu
        ::topPulldownMenu::scanFolders $scriptPath $mainTopMenu.customMenu
    menu $mainTopMenu.customMenu.pres -tearoff 0
    
}

proc ::topPulldownMenu::formatName {nameString} {

    set nameString [file rootname $nameString]
    set newString ""
    set i 0
    foreach char [split $nameString ""] {
        if {[string is upper $char] && $i} {
            set char " $char"
        }
        append newString $char
        incr i
    }
    return $newString

}

proc ::topPulldownMenu::scanFolders {folder customMenu} {

	if { [catch {set folders [glob -directory $folder -type d *]} fid] } {
	# No further sub folders found - just continue on
	} else {
	# found some folders, go search them as well
		foreach subFolder $folders {
			set menu_foldername [string tolower [string map {" " ""} [string map {. ""} [file tail $subFolder]]]]
			set foldername [file tail $subFolder]
			$customMenu add cascade -label "$foldername" -underline 0 -menu [menu $customMenu.$menu_foldername -title "$foldername"]
			::topPulldownMenu::scanFolders $subFolder $customMenu.$menu_foldername
		}
	}
    
    # TCL FILES
	if { [catch {set tclFiles [glob -tails -directory $folder *.tcl]} fid] } {
	} else {
		foreach tclScript $tclFiles  {
			if {$tclScript != "hmcustom.tcl" && $tclScript != "TopPulldownMenu.tcl"} {
				$customMenu add command -label [::topPulldownMenu::formatName $tclScript] -command "source \"$folder/$tclScript\"" -underline 0
			}
		}
	}
    	
    # TBC　FILES
	if { [catch {set tbcFiles [glob -tails -directory $folder *.tbc]} fid] } {
	} else {
		foreach tbcScript $tbcFiles  {
			$customMenu add command -label [::topPulldownMenu::formatName $tbcScript] -command "source \"$folder/$tbcScript\"" -underline 0
		}
	}	

}

::topPulldownMenu::menuFuncRegister ::topPulldownMenu::addMenuItem
