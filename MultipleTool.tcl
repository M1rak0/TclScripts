# FILE NAME : multipletool.tcl
# DESCRIPTION :
# USAGE :
# INPUT :
# OUTPUT : NONE
# AUTHOR :

set entityType Elemens
set multipleTimes 0
set multipleDistance 0

namespace eval ::multipleTool {

    variable entitySet {}
    variable direction 0
    variable invalidDir 1
    variable nullEntitySet 1

}

proc ::multipleTool::mainWindow {args} {

    global entityType
    global multipleTimes
    global multipleDistance

    set entityList {Elements Nodes Surfaces Solids Lines Parts Connectors}

    destroy .mainWindow
    set mainWindow [::hwtk::toplevel .mainWindow]

    wm title $mainWindow "Multiple Tool"
    wm geometry $mainWindow 250x182
    wm resizable $mainWindow 0 0

    set parmFrame [::hwtk::labelframe $mainWindow.parmFrame -text "Parameters"]
    set typeLabel [::hwtk::label $parmFrame.typeLabel -text "Entity Type: " -width 15]
    set typeBox [::hwtk::combobox $parmFrame.typeBox -textvariable entityType -state readonly -values $entityList -width 12]
    set timesLabel [::hwtk::label $parmFrame.timesLabel -text "Multiple Times: "  -width 15]
    set timesEntry [::hwtk::entry $parmFrame.timesEntry -textvariable multipleTimes -justify right -inputtype integer -width 15]
    set distanceLabel [::hwtk::label $parmFrame.distanceLabel -text "Distance: "  -width 15]
    set distanceEntry [::hwtk::entry $parmFrame.distanceEntry -textvariable multipleDistance -justify right -inputtype string -width 15]

    pack $parmFrame
    grid $typeLabel -row 0 -column 0
    grid $typeBox -row 0 -column 1
    grid $timesLabel -row 1 -column 0
    grid $timesEntry -row 1 -column 1
    grid $distanceLabel -row 2 -column 0
    grid $distanceEntry -row 2 -column 1

    set entityFrame [::hwtk::labelframe $mainWindow.entitylFrame -text "Entity Selection"]
    set entityLabel [::hwtk::label $entityFrame.entitylLabel -text "Entities: " -justify right -width 15]
    set entityButton [::hwtk::button $entityFrame.entityButton -text "Select Entitys"\
     -command {::multipleTool::entitySelection $entityType} -width 15]

    pack $entityFrame 
    grid $entityLabel -row 0 -column 0
    grid $entityButton -row 0 -column 1

    set directionFrame [::hwtk::labelframe $mainWindow.directionFrame -text "Direction"]
    set directionLabel [::hwtk::label $directionFrame.directionLabel -text "Select a direction: " -width 15]
    set directionButton [::hwtk::button $directionFrame.directionButton -text "Select Vector"\
     -command {::multipleTool::directionSelection} -width 15]
    
    pack $directionFrame
    grid $directionLabel -row 0 -column 0
    grid $directionButton -row 0 -column 1

    set funcFrame [::hwtk::frame $mainWindow.funcFrame]
    set nullFrame [::hwtk::frame $mainWindow.funcFrame.nullFrame -width 15]
    set actionButton [::hwtk::button $funcFrame.actionButton -text "Apply"\
     -command {::multipleTool::multipleAction} -width 10]
    set cancelButton [::hwtk::button $funcFrame.cancelButton -text "Cancel"\
     -command {destroy .mainWindow} -width 10]

    pack $funcFrame
    grid $cancelButton -row 0 -column 0
    grid $nullFrame -row 0 -column 1
    grid $actionButton -row 0 -column 2

}

proc ::multipleTool::entitySelection {entityType} {

    variable entitySet
    variable nullEntitySet

    *createmarkpanel $entityType 2 "please select the $entityType to multiply"
    set entitySet [hm_getmark $entityType 2]
    *clearmark $entityType 2

    if {![llength $entitySet]} {
        set nullEntitySet 1
    } else {
        set nullEntitySet 0
    }
    focus .mainWindow

}

proc ::multipleTool::directionSelection {args} {

    variable direction
    variable invalidDir

    set direction [hm_getdirectionpanel "please select a direction."]

    if {[llength [lindex $direction 0]] != 3} {
        set invalidDir 1
    } else {
        set invalidDir 0
    }
    focus .mainWindow

}

proc ::multipleTool::multipleAction {args} {

    global entityType
    global multipleTimes
    global multipleDistance

    variable direction
    variable invalidDir 
    variable entitySet
    variable nullEntitySet

    if {$invalidDir} {
        case [tk_messageBox -type retrycancel -icon warning -title "Invalid Direction" -message "Invalid direction selected!" -detail "Please re-select" ] {
            retry {focus .mainWindow}
            cancel {}
            default {}
        }
    } elseif {$nullEntitySet} {
        case [tk_messageBox -type retrycancel -icon warning -title "No Entities Selected" -message "No entities selected!" -detail "Please re-select" ] {
            retry {focus .mainWindow}
            cancel {}
            default {}
        }
    } else {
        set times [llength [set distList [string map {"." " "} [string map {"_" " "} [string map {"," " "} $multipleDistance]]]]]
        # multiple with different distances
        if {$multipleTimes == 0} {
            *clearmarkall 1
            *clearmarkall 2
            hm_createmark $entityType 2 $entitySet
            for {set i 0} {$i < $times} {incr i} {
                *createvector 2 [lindex $direction 0 0] [lindex $direction 0 1] [lindex $direction 0 2]
                *duplicatemark $entityType 2
                *translatemark $entityType 2 2 [lindex $distList $i]
            }
            *clearmarkall 1
            *clearmarkall 2
        # multiple with multipleTimes*multipleDistance
        } elseif {$multipleTimes > 0 && $times == 1} {
            *clearmarkall 1
            *clearmarkall 2
            hm_createmark $entityType 2 $entitySet
            for {set i 0} {$i < $multipleTimes} {incr i} {
                *createvector 2 [lindex $direction 0 0] [lindex $direction 0 1] [lindex $direction 0 2]
                *duplicatemark $entityType 2
                *translatemark $entityType 2 2 $multipleDistance
            }
            *clearmarkall 1
            *clearmarkall 2
        } elseif {$multipleTimes > 0 && $times > 1} {
            *clearmarkall 1
            *clearmarkall 2
            hm_createmark $entityType 2 $entitySet
            for {set i 0} {$i < $multipleTimes} {incr i} {
                *createvector 2 [lindex $direction 0 0] [lindex $direction 0 1] [lindex $direction 0 2]
                *duplicatemark $entityType 2
                *translatemark $entityType 2 2 [lindex $distList 0]
            }
            *clearmarkall 1
            *clearmarkall 2
        }
    }
    focus .mainWindow
}

::multipleTool::mainWindow 
    focus .mainWindow