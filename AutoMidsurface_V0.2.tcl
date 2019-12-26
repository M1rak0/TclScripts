#######################################################################
# FILE NAME :            AutoMidsurface_V0.2.tcl
# PURPOSE : Extract midsurface for each solid selected, assign solids
#           & midsurfaces into components by thickness, and assign 
#           components into assemblies automatically. If any errors
#           occured in the process, a message will be sent and the error
#           solids will be stored in a component, so that they can be 
#           processed manually.
# USAGE :   Select components after the process start, then it will run
#           automatically.
# INPUT :   NONE.
# OUTPUT :  NONE.
# AYTHOR :  Lai Qibo @ XMKL
#######################################################################
namespace eval ::autoMidsurf {
    variable thicknessTolerance 0.2
}

proc ::autoMidsurf::initialize {} {
    *clearmarkall 1
    *createmark comps 1 "Middle Surface" "FailMidSurface"
    catch {*deletemark comps 1}
    catch {*collectorcreateonly components  "Middle Surface" "" 20}
    catch {*collectorcreateonly components  "FailMidSurface" "" 20}
    *clearmarkall 1
    *createmark comps 1 "Middle Surface"
    *renumbersolverid components 1 100000 1 0 0 0 0
    *clearmarkall 1
    *createmark comps 1 "FailMidSurface"
    *renumbersolverid components 1 200000 1 0 0 0 0
    *clearmarkall 1
    *currentcollector comps "Middle Surface"
}

proc ::autoMidsurf::select {} {
    *clearmarkall 1
    *createmarkpanel comps 1 "Select the components to extract middle surface."
    set compSet [hm_getmark comps 1]
    hm_createmark solids 1 "by comps" $compSet
    set solidSet [hm_getmark solids 1]
    *clearmarkall 1
    if {[llength $solidSet]} {
        return $solidSet
    } else {
        return "err_NullSolidSet"
    }
}

proc ::autoMidsurf::midSurfExtract {solidSet} {
    set meshCode 1
    if {$solidSet eq "err_NullSolidSet"} {
        return "err_NullSolidSet"
    } else {
        foreach solid $solidSet {
            *currentcollector comps "Middle Surface"
            *clearmarkall 1
            hm_createmark solids 2 $solid
            if {[catch {*midsurface_extract_10 solids 2 3 0 1 1 0 0 20 0 0 10 0 10 -2 undefined 0 0 1}]} {
                *movemark solids 2 "FailMidSurface"
            }
            hm_createmark surfs 1 "by comps" 100000
            set midSurfSet [hm_getmark surfs 1]
            if {[llength $midSurfSet]} {
                set areaOfSurfs 0
                foreach surf $midSurfSet {
                    set areaOfSurfs [expr $areaOfSurfs + [hm_getareaofsurface surfs $surf]]
                }
                if {$areaOfSurfs < 300} {
                    *deletemark surfs 1
                    *movemark solids 2 "FailMidSurface"
                } else {
                    set meshCode [::autoMidsurf::surfMesh $surf]
                    if {$meshCode == 1} {
                        ::autoMidsurf::autoSort $solid $midSurfSet
                    } else {
                        break
                    }                
                }
                if {$meshCode == 0} {
                    catch {*collectorcreateonly comps "solids_err" "" 20}
                    *movemark solids 2 "solids_err"
                    continue
                }
            }
        }
    }
}

proc ::autoMidsurf::formatName {solid} {
    set solidCompName "solids_"
    set surfsCompName "comps_"
    set compName [hm_getvalue solids id=$solid dataname=collector.name]
    if {![lsearch $compName "solids_"] || ![lsearch $compName "comps_"]} {
        set nameBody [lindex [split $compName "_"] 1]
    } else {
        set nameBody [lindex [split [split $compName "_"] "-"] 0 0 0]
    }
    append solidCompName $nameBody
    append surfsCompName $nameBody
    return [list $solidCompName $surfsCompName]
}

proc ::autoMidsurf::surfMesh {surf} {
    *clearmarkall 1
    hm_createmark surfs 1 $surf
    *interactivemeshsurf 1 20 2 2 2 1 1
    *set_meshfaceparams 0 2 2 0 0 1 0.5 1 1
    set code [*automesh 0 2 2]
    *storemeshtodatabase 1
    *ameshclearsurface
    *clearmarkall 1
    return $code
}

proc ::autoMidsurf::autoSort {solid surfSet} {
    variable thicknessTolerance
    variable meshCode

    set nameList [::autoMidsurf::formatName $solid]
    set solidCompName [lindex $nameList 0]
    set surfsCompName [lindex $nameList 1]
    append solidCompName "_t"
    append surfsCompName "_t"

    # get thickness
    hm_createmark elems 1 "by comps" 100000
    set infoList [hm_getsurfacethicknessvalues elems 1 0]
    set totalThickness 0
    foreach elemInfo $infoList {
        set singleElemThickness [lindex $elemInfo 2]
        set totalThickness [expr $totalThickness + $singleElemThickness]
    }
    set averageThickness [expr $totalThickness*1.0 / [llength $infoList]]
    *deletemark elems 1
    if {$averageThickness >= 20 || $averageThickness <= 0.5} {
        hm_createmark solids 1 $solid
        *movemark solids 1 "FailMidSurface"
        hm_createmark elems 1 "by comps" 100000
        catch {*deletemark elems 1}
        hm_createmark surfs 1 "by comps" 100000
        catch {*deletemark surfs 1}
        *clearmarkall 1
    }

    # round thickness
    set compThickness [::autoMidsurf::roundThickness $averageThickness]

    append solidCompName "$compThickness"
    append surfsCompName "$compThickness"

    # set color of component
    switch $compThickness {
        1.0 {set compColor 13}
        1.5 {set compColor 3}
        2.0 {set compColor 4}
        2.5 {set compColor 28}
        3.0 {set compColor 6}
        3.5 {set compColor 62}
        4.0 {set compColor 29}
        4.5 {set compColor 22}
        5.0 {set compColor 7}
        5.5 {set compColor 8}
        6.0 {set compColor 53}
        6.5 {set compColor 60}
        7.0 {set compColor 50}
        7.5 {set compColor 15}
        8.0 {set compColor 40}
        # 8.5 {set compColor 17}
        # 9.0 {set compColor 18}
        # 9.5 {set compColor 19}
        10.0 {set compColor 20}
        # 10.5 {set compColor 21}
        # 11.0 {set compColor 22}
        # 11.5 {set compColor 23}
        12.0 {set compColor 24}
        # 12.5 {set compColor 25}
        # 13.0 {set compColor 26}
        # 13.5 {set compColor 27}
        # 14.0 {set compColor 28}
        # 14.5 {set compColor 29}
        # 15.0 {set compColor 30}
        default {set compColor 64}
    }
    # assign solids and surfaces
    catch {*collectorcreateonly comps "$solidCompName" "" $compColor}
    catch {*collectorcreateonly comps "$surfsCompName" "" $compColor}
    hm_createmark solids 1 $solid 
    if {[catch {*movemark solids 1 $solidCompName}]} {
        catch {*movemark solids 1 "FailMidSurface"}
    }
    hm_createmark surfs 1 $surfSet
    if {[catch {*movemark surfs 1 $surfsCompName}]} {
        catch {*deletemark surfs 1}
    }
    *clearmarkall 1
}

proc ::autoMidsurf::roundThickness {thickness} {
    variable thicknessTolerance
    set initialThickness [expr 2.0*($thickness + $thicknessTolerance)]
    set intThickness [expr int($initialThickness)]
    set roundedThickness [expr 0.5*$intThickness]
    return $roundedThickness
}

proc ::autoMidsurf::assignComps {} {
    # assign components
    *createmark comps 1 all
    set allComps [hm_getmark comps 1]
    *clearmarkall 1
    foreach component $allComps {
        # create empty assemblies with valid names (if not exist).
        set componentName [hm_getvalue comps id=$component dataname=name]
        set nameString [split $componentName "_"]
        set assemNameBody [lindex $nameString 1]
        if {[lindex $nameString 0] eq "comps"} {
            set assemNamePrefix "assem_"
            set assemName [append assemNamePrefix $assemNameBody]
            if {[hm_entityinfo exist assem $assemName] == 0} {
                *clearmarkall 1
                *assemblymodifyhierarchy "$assemName" 1 3
            }
        } elseif {[lindex $nameString 0] eq "solids"} {
            set assemNamePrefix "solids_"
            set assemName [append assemNamePrefix $assemNameBody]
            if {[hm_entityinfo exist assem $assemName] == 0} {
                *clearmarkall 1
                *assemblymodifyhierarchy "$assemName" 1 3
            }
        }
    }
    
    foreach compsToMove $allComps {
        # move components to valid assemblies.
        set movedCompName [hm_getvalue comps id=$compsToMove dataname=name]
        set splitName [split $movedCompName "_"]
        set asmBody [lindex $splitName 1]
        if {[lindex $splitName 0] eq "comps"} {
            set asmPrefix "assem_"
            set targetAsmName [append asmPrefix $asmBody]
            set targetAsmID [hm_getvalue assems name=$targetAsmName dataname=id]
            *createmark comps 1 $compsToMove
            *assemblyaddmark $targetAsmID comps 1
            *clearmarkall 1
        } elseif {[lindex $splitName 0] eq "solids"} {
            set asmPrefix "solids_"
            set targetAsmName [append asmPrefix $asmBody]
            set targetAsmID [hm_getvalue assems name=$targetAsmName dataname=id]
            *createmark comps 1 $compsToMove
            *assemblyaddmark $targetAsmID comps 1
            *clearmarkall 1
        }
    }
}

proc ::autoMidsurf::main {} {
    ::autoMidsurf::initialize;
    set returncode [::autoMidsurf::midSurfExtract [::autoMidsurf::select]]
    ::autoMidsurf::assignComps
    *clearmarkall 1
    *createmark solids 1 "by comps" "solids_err"
    set errSolids [hm_getmark solids 1]

    if {$returncode eq "err_NullSolidSet"} {
        tk_messageBox -message "No solids selected, nothing done." -title "Warning" -icon warning 
    } elseif {[llength $errSolids]} {
        tk_messageBox -message "Some solids failed to extract middle sueface, do it manually." -title "Message"         
    } else {
        tk_messageBox -message "DONE!" -title "Information"
    }
}
::autoMidsurf::main