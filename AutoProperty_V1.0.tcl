#######################################################################
# FILE NAME :            AutoProperty_V1.0.tcl
# PURPOSE : create and assign properties/materials for components selected
#           automatically.
# USAGE :   Select components after the process start, then it will run
#           automatically.
# INPUT :   NONE.
# OUTPUT :  NONE.
# AYTHOR :  Lai Qibo @ XMKL
#######################################################################
namespace eval ::autoProp {
    set errList ""
    set defaultMat "NONE"
    set profile ""
    set table ""
}

proc ::autoProp::pickComps {args} {
    *clearmarkall 1
    *createmarkpanel comps 1 "请选择需要自动设置材料属性的组件"
    set compSet [hm_getmark comps 1]
    *clearmarkall 1
    if {[llength $compSet] > 0} {
        return $compSet
    } else {
        return "nullComps"
    }
}

proc ::autoProp::chooseList {args} {
    return [list "NONE" "Q235" "Q345" "20\#" "Q700"]
}
proc ::autoProp::getProfile {args} {
    variable defaultMat
    set profile [lindex [hm_framework getuserprofile] 0]
    if {[string match -nocase $profile "LsDyna"]} {
        set defaultMat [::hwtk::inputdialog -title "默认材料设置" -text "请选择默认材料:" \
         -inputtype combobox -initialvalue "NONE" -valuelistcommand ::autoProp::chooseList -x [expr [winfo rootx .]+700] -y [expr [winfo rooty .]+250]]
        return $profile
    } elseif {[string match -nocase $profile "OptiStruct"]} {
        return $profile
    } else {
        return "unsupportedProfile"
    }
}

proc ::autoProp::getCompParms {comp} {
    # {id elemtype thickness material rigid}
    foreach i [list id elemtype thickness material rigid] {
        set $i "null"
    }
    set compName [hm_getvalue comps id=$comp dataname=name]
    set elemTypes [hm_elemlist type $compName]
    set shell 0
    set solid 0
    set linear 0
    if {[Null elemTypes]} {
        set elemtype "null"
    } else {
        foreach config $elemTypes {
            if {$config < 103} {
                set linear 1
            } elseif {$config > 200} {
                set solid 1
            } else {
                set shell 1
            }
        }
    }
    set sum [expr $shell + $solid + $linear]
    if {$sum == 1} {
        if {$shell == 1} {
            set elemtype "shell"
        } elseif {$solid == 1} {
            set elemtype "solid"
        } else {
            set elemtype "1D"
        }

    } elseif {$sum == 0} {
        set elemtype "null"
    } else {
        set elemtype "toomany"
    }
    set i [lindex [lsort -decreasing [list [string first "t" $compName] [string first "T" $compName]]] 0]
    if {$i == -1} {
        set thickness "nothickness"
    } else {
        set tmp [::autoProp::getFloat [string range $compName $i end]]
        if {[catch {set thickness [format "%.1f" [lindex [split $tmp "-_tTQ\#"] 1]]}]} {
            set thickness "nothickness"
        }
    }
    set material "null"
    foreach mat [list Q235 q235 Q345 q345 Q700 q700 20\# \#20] {
        if {[string first $mat $compName] > -1} {
            set material $mat
        }
    }
    set parmTable [list $comp $elemtype $thickness $material $rigid]
    return $parmTable
}

proc ::autoProp::getFloat {string} {
    set str ""
    append str [lindex [split $string "."] 0] "." [lindex [split $string "."] 1]
    return $str
}

proc ::autoProp::adderrmsg {id msg} {
    variable errList
    set i [lsearch $errList $id]
    if {$i == -1} {
        lappend errList $id $msg
    } else {
        set j [expr $i + 1]
        set msgn [lindex $errList $j]
        append msgn "  " $msg
        set errList [lreplace $errList $j $j $msgn]
    }
}

proc ::autoProp::createMaterial {profile parms} {
    variable defaultMat
    variable errList
    switch $profile {
        OptiStruct {
            if {[hm_getvalue comps id=[lindex $parms 0] dataname=property.material] > 0} {
                return [hm_getvalue comps id=[lindex $parms 0] dataname=property.material]
            }
            set matName ""
            if {[lindex $parms 3] eq "null"} {
                set matTail "NONAME"
            } else {
                set matTail [lindex $parms 3]
            }
            append matName "MAT1_" "$matTail"
            if {![hm_entityinfo exist mats $matName -byname]} {
                *createentity mats cardimage=MAT1 name=$matName
                *setvalue mats name=$matName STATUS=1 1=210000
                *setvalue mats name=$matName STATUS=1 3=0.3
                *setvalue mats name=$matName STATUS=1 4=7.85e-009
                set clr [lindex [list 5 6 4 3 3] [lsearch [list Q700 Q345 Q235 20\# \#20] $matTail]]
                if {$clr == ""} {set clr 9}
                *setvalue mats name=$matName color=$clr
            }
        }
        LsDyna     {
            if {[hm_getvalue comps id=[lindex $parms 0] dataname=material] > 0} {
                return [hm_getvalue comps id=[lindex $parms 0] dataname=material]
            }
            set matName ""
            if {[lindex $parms 3] eq "null" && $defaultMat eq "NONE"} {
                ::autoProp::adderrmsg [lindex $parms 0] "未设置材料信息"
                return 0
            } elseif {[lindex $parms 3] eq "null" && $defaultMat != "NONE"} {
                set matTail $defaultMat
            } else {
                set matTail [lindex $parms 3]
            }
            append matName "MATL24_" "$matTail"
            if {[string match -nocase $matTail "Q700"]} {
                set curveName1 "Q700_0.01"
                if {![hm_entityinfo exist curve $curveName1 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName1"
                    *xyplotcurvemodify "$curveName1" "title" "$curveName1" 0 1
                    set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                    *curvedeletepoint $crv1ID 1
                    *attributeupdatedouble curves $crv1ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv1ID 514 9 0 0 0
                    *attributeupdateint curves $crv1ID 4421 9 2 0 0
                    *attributeupdateint curves $crv1ID 5827 9 2 0 1
                    *attributeupdateint curves $crv1ID 3016 9 2 0 0
                    *attributeupdateint curves $crv1ID 5068 9 2 0 1
                    *attributeupdateint curves $crv1ID 90 9 2 0 0
                    *attributeupdateint curves $crv1ID 510 9 0 0 0
                    *attributeupdateint curves $crv1ID 515 9 0 0 0
                    set curveValue {
                        0.0,759.6574
                        0.01,767.81424
                        0.02,774.83855
                        0.03,789.343
                        0.04,813.04474
                        0.05,831.37722
                        0.06,847.76627
                        0.07,862.18085
                        0.08,874.1725
                        0.09,885.98269
                        0.1,897.34183
                        0.11,907.97633
                        0.12,916.18286
                        0.14,932.63227
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv1ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv1ID color=5
                }
                set curveName2 "Q700_1"
                if {![hm_entityinfo exist curve $curveName2 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName2"
                    *xyplotcurvemodify "$curveName2" "title" "$curveName2" 0 1
                    set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                    *curvedeletepoint $crv2ID 1
                    *attributeupdatedouble curves $crv2ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv2ID 514 9 0 0 0
                    *attributeupdateint curves $crv2ID 4421 9 2 0 0
                    *attributeupdateint curves $crv2ID 5827 9 2 0 1
                    *attributeupdateint curves $crv2ID 3016 9 2 0 0
                    *attributeupdateint curves $crv2ID 5068 9 2 0 1
                    *attributeupdateint curves $crv2ID 90 9 2 0 0
                    *attributeupdateint curves $crv2ID 510 9 0 0 0
                    *attributeupdateint curves $crv2ID 515 9 0 0 0
                    set curveValue {
                        0.0,815.22746
                        0.01,824.12476
                        0.02,835.23666
                        0.03,847.1745
                        0.04,867.6782
                        0.05,888.79052
                        0.06,906.4735
                        0.07,922.99228
                        0.08,937.30573
                        0.09,950.71655
                        0.1,963.73568
                        0.11,973.73032
                        0.12,981.34457
                        0.14,992.90794
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv2ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv2ID color=5
                }
                set curveName3 "Q700_10"
                if {![hm_entityinfo exist curve $curveName3 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName3"
                    *xyplotcurvemodify "$curveName3" "title" "$curveName3" 0 1
                    set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                    *curvedeletepoint $crv3ID 1
                    *attributeupdatedouble curves $crv3ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv3ID 514 9 0 0 0
                    *attributeupdateint curves $crv3ID 4421 9 2 0 0
                    *attributeupdateint curves $crv3ID 5827 9 2 0 1
                    *attributeupdateint curves $crv3ID 3016 9 2 0 0
                    *attributeupdateint curves $crv3ID 5068 9 2 0 1
                    *attributeupdateint curves $crv3ID 90 9 2 0 0
                    *attributeupdateint curves $crv3ID 510 9 0 0 0
                    *attributeupdateint curves $crv3ID 515 9 0 0 0
                    set curveValue {
                        0.0,846.01938
                        0.01,856.3177
                        0.02,868.05263
                        0.03,884.63474
                        0.04,904.07078
                        0.05,922.3638
                        0.06,938.48895
                        0.07,952.95674
                        0.08,967.51326
                        0.09,981.71473
                        0.1,993.65483
                        0.11,1002.73081
                        0.12,1010.26532
                        0.14,1022.72089
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv3ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv3ID color=5
                }
                set curveName4 "Q700_200"
                if {![hm_entityinfo exist curve $curveName4 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName4"
                    *xyplotcurvemodify "$curveName4" "title" "$curveName4" 0 1
                    set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                    *curvedeletepoint $crv4ID 1
                    *attributeupdatedouble curves $crv4ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv4ID 514 9 0 0 0
                    *attributeupdateint curves $crv4ID 4421 9 2 0 0
                    *attributeupdateint curves $crv4ID 5827 9 2 0 1
                    *attributeupdateint curves $crv4ID 3016 9 2 0 0
                    *attributeupdateint curves $crv4ID 5068 9 2 0 1
                    *attributeupdateint curves $crv4ID 90 9 2 0 0
                    *attributeupdateint curves $crv4ID 510 9 0 0 0
                    *attributeupdateint curves $crv4ID 515 9 0 0 0
                    set curveValue {
                        0.0,884.56894
                        0.01,897.31696
                        0.02,911.42265
                        0.03,929.87726
                        0.04,948.74014
                        0.05,966.54574
                        0.06,981.98141
                        0.07,995.84643
                        0.08,1008.1477
                        0.09,1017.85997
                        0.1,1026.51449
                        0.11,1035.35796
                        0.12,1044.38817
                        0.14,1057.61724
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv4ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv4ID color=5
                }
                set curveName5 "Q700_500"
                if {![hm_entityinfo exist curve $curveName5 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName5"
                    *xyplotcurvemodify "$curveName5" "title" "$curveName5" 0 1
                    set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                    *curvedeletepoint $crv5ID 1
                    *attributeupdatedouble curves $crv5ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv5ID 514 9 0 0 0
                    *attributeupdateint curves $crv5ID 4421 9 2 0 0
                    *attributeupdateint curves $crv5ID 5827 9 2 0 1
                    *attributeupdateint curves $crv5ID 3016 9 2 0 0
                    *attributeupdateint curves $crv5ID 5068 9 2 0 1
                    *attributeupdateint curves $crv5ID 90 9 2 0 0
                    *attributeupdateint curves $crv5ID 510 9 0 0 0
                    *attributeupdateint curves $crv5ID 515 9 0 0 0
                    set curveValue {
                        0.0,916.31564
                        0.01,930.62364
                        0.02,943.68246
                        0.03,960.13727
                        0.04,976.93604
                        0.05,992.9273
                        0.06,1008.73019
                        0.07,1024.64599
                        0.08,1038.68938
                        0.09,1050.50375
                        0.1,1061.26347
                        0.11,1070.99806
                        0.12,1078.9937
                        0.14,1091.93734
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv5ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv5ID color=5
                }
                set matTabelName "TABLE_Q700"
                set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                if {![hm_entityinfo exist curve $matTabelName -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$matTabelName"
                    set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                    *attributeupdateint curves $matTabelID 3016 9 2 0 1
                    *attributeupdateint curves $matTabelID 4421 9 2 0 0
                    *attributeupdateint curves $matTabelID 5827 9 2 0 1
                    *attributeupdateint curves $matTabelID 90 9 2 0 0
                    *attributeupdatedouble curves $matTabelID 511 9 0 0 1
                    *attributeupdatedouble curves $matTabelID 513 9 0 0 0
                    *attributeupdateint curves $matTabelID 2246 9 1 0 5
                    *createdoublearray 5 0.01 1 10 200 500
                    *attributeupdatedoublearray curves $matTabelID 3017 9 2 0 1 5
                    *createarray 5 $crv1ID $crv2ID $crv3ID $crv4ID $crv5ID
                    *attributeupdateentityidarray curves $matTabelID 4420 9 2 0 curves 1 5
                    *setvalue curves id=$matTabelID color=5
                }
                set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                if {![hm_entityinfo exist mats $matName -byname]} {
                    *createentity mats cardimage=MATL24 name=$matName
                    *setvalue mats name=$matName STATUS=1 118=7.9e-009
                    *setvalue mats name=$matName STATUS=1 119=210000
                    *setvalue mats name=$matName STATUS=1 120=0.3
                    *setvalue mats name=$matName STATUS=1 152=759
                    *setvalue mats name=$matName STATUS=1 45={curves $matTabelID}
                    *setvalue mats name=$matName color=5
                }
            } elseif {[string match -nocase $matTail "Q345"]} {
                set curveName1 "Q345_0.01"
                if {![hm_entityinfo exist curve $curveName1 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName1"
                    *xyplotcurvemodify "$curveName1" "title" "$curveName1" 0 1
                    set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                    *curvedeletepoint $crv1ID 1
                    *attributeupdatedouble curves $crv1ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv1ID 514 9 0 0 0
                    *attributeupdateint curves $crv1ID 4421 9 2 0 0
                    *attributeupdateint curves $crv1ID 5827 9 2 0 1
                    *attributeupdateint curves $crv1ID 3016 9 2 0 0
                    *attributeupdateint curves $crv1ID 5068 9 2 0 1
                    *attributeupdateint curves $crv1ID 90 9 2 0 0
                    *attributeupdateint curves $crv1ID 510 9 0 0 0
                    *attributeupdateint curves $crv1ID 515 9 0 0 0
                    set curveValue {
                        0.0,379.435
                        0.005,382.319976
                        0.01,384.374624
                        0.015,388.439456
                        0.02,406.839088
                        0.025,419.57084
                        0.03,431.055368
                        0.035,441.2694
                        0.04,450.3572
                        0.045,458.400448
                        0.05,465.583248
                        0.055,471.96164
                        0.06,477.615448
                        0.065,482.714512
                        0.07,487.368424
                        0.075,491.523536
                        0.08,495.3804
                        0.085,498.86564
                        0.09,502.094592
                        0.095,505.063792
                        0.1,507.795376
                        0.105,510.426456
                        0.11,512.831928
                        0.115,515.10456
                        0.12,517.200168
                        0.125,519.188496
                        0.13,521.18308
                        0.135,522.942792
                        0.14,524.65204
                        0.145,526.240136
                        0.15,527.697664
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv1ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv1ID STATUS=1 512=0.8
                    *setvalue curves id=$crv1ID color=6
                }
                set curveName2 "Q345_1"
                if {![hm_entityinfo exist curve $curveName2 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName2"
                    *xyplotcurvemodify "$curveName2" "title" "$curveName2" 0 1
                    set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                    *curvedeletepoint $crv2ID 1
                    *attributeupdatedouble curves $crv2ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv2ID 514 9 0 0 0
                    *attributeupdateint curves $crv2ID 4421 9 2 0 0
                    *attributeupdateint curves $crv2ID 5827 9 2 0 1
                    *attributeupdateint curves $crv2ID 3016 9 2 0 0
                    *attributeupdateint curves $crv2ID 5068 9 2 0 1
                    *attributeupdateint curves $crv2ID 90 9 2 0 0
                    *attributeupdateint curves $crv2ID 510 9 0 0 0
                    *attributeupdateint curves $crv2ID 515 9 0 0 0
                    set curveValue {
                        0.0,415.164552
                        0.005,420.413592
                        0.01,424.553328
                        0.015,428.08388
                        0.02,431.91824
                        0.025,436.039864
                        0.03,445.71376
                        0.035,454.280336
                        0.04,464.479224
                        0.045,473.704208
                        0.05,481.778392
                        0.055,488.65936
                        0.06,495.644616
                        0.065,501.490552
                        0.07,506.81732
                        0.075,511.92248
                        0.08,516.639104
                        0.085,521.119968
                        0.09,524.781288
                        0.095,528.2974
                        0.1,531.686296
                        0.105,534.552816
                        0.11,537.1384
                        0.115,539.420224
                        0.12,541.23804
                        0.125,543.465456
                        0.13,545.360408
                        0.135,546.97832
                        0.14,548.644784
                        0.145,550.040704
                        0.15,551.17564
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv2ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv2ID STATUS=1 512=0.8
                    *setvalue curves id=$crv2ID color=6
                }
                set curveName3 "Q345_10"
                if {![hm_entityinfo exist curve $curveName3 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName3"
                    *xyplotcurvemodify "$curveName3" "title" "$curveName3" 0 1
                    set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                    *curvedeletepoint $crv3ID 1
                    *attributeupdatedouble curves $crv3ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv3ID 514 9 0 0 0
                    *attributeupdateint curves $crv3ID 4421 9 2 0 0
                    *attributeupdateint curves $crv3ID 5827 9 2 0 1
                    *attributeupdateint curves $crv3ID 3016 9 2 0 0
                    *attributeupdateint curves $crv3ID 5068 9 2 0 1
                    *attributeupdateint curves $crv3ID 90 9 2 0 0
                    *attributeupdateint curves $crv3ID 510 9 0 0 0
                    *attributeupdateint curves $crv3ID 515 9 0 0 0
                    set curveValue {
                        0.0,425.675968
                        0.005,430.18792
                        0.01,435.17944
                        0.015,440.670632
                        0.02,446.639456
                        0.025,453.109904
                        0.03,460.056032
                        0.035,468.480528
                        0.04,477.324808
                        0.045,486.034352
                        0.05,493.95756
                        0.055,500.498088
                        0.06,506.333288
                        0.065,511.581512
                        0.07,516.394752
                        0.075,521.0046
                        0.08,525.566824
                        0.085,529.89116
                        0.09,534.014744
                        0.095,538.05408
                        0.1,541.952696
                        0.105,545.689896
                        0.11,549.24132
                        0.115,552.318944
                        0.12,554.694344
                        0.125,556.146568
                        0.13,556.954528
                        0.135,557.762488
                        0.14,558.570448
                        0.145,559.378408
                        0.15,560.186368
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv3ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv3ID STATUS=1 512=0.8
                    *setvalue curves id=$crv3ID color=6
                }
                set curveName4 "Q345_200"
                if {![hm_entityinfo exist curve $curveName4 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName4"
                    *xyplotcurvemodify "$curveName4" "title" "$curveName4" 0 1
                    set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                    *curvedeletepoint $crv4ID 1
                    *attributeupdatedouble curves $crv4ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv4ID 514 9 0 0 0
                    *attributeupdateint curves $crv4ID 4421 9 2 0 0
                    *attributeupdateint curves $crv4ID 5827 9 2 0 1
                    *attributeupdateint curves $crv4ID 3016 9 2 0 0
                    *attributeupdateint curves $crv4ID 5068 9 2 0 1
                    *attributeupdateint curves $crv4ID 90 9 2 0 0
                    *attributeupdateint curves $crv4ID 510 9 0 0 0
                    *attributeupdateint curves $crv4ID 515 9 0 0 0
                    set curveValue {
                        0.0,436.507664
                        0.005,442.281336
                        0.01,448.271792
                        0.015,454.476752
                        0.02,460.896968
                        0.025,467.532456
                        0.03,474.383216
                        0.035,481.449224
                        0.04,489.14892
                        0.045,497.094296
                        0.05,505.067016
                        0.055,512.872888
                        0.06,520.332936
                        0.065,527.2918
                        0.07,533.593272
                        0.075,539.293392
                        0.08,544.582632
                        0.085,549.595152
                        0.09,554.471864
                        0.095,559.118176
                        0.1,563.554328
                        0.105,567.883896
                        0.11,572.29736
                        0.115,576.625424
                        0.12,580.732712
                        0.125,584.299072
                        0.13,587.579568
                        0.135,590.595256
                        0.14,593.34616
                        0.145,595.832272
                        0.15,598.053592
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv4ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv4ID STATUS=1 512=0.8
                    *setvalue curves id=$crv4ID color=6
                }
                set curveName5 "Q345_500"
                if {![hm_entityinfo exist curve $curveName5 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName5"
                    *xyplotcurvemodify "$curveName5" "title" "$curveName5" 0 1
                    set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                    *curvedeletepoint $crv5ID 1
                    *attributeupdatedouble curves $crv5ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv5ID 514 9 0 0 0
                    *attributeupdateint curves $crv5ID 4421 9 2 0 0
                    *attributeupdateint curves $crv5ID 5827 9 2 0 1
                    *attributeupdateint curves $crv5ID 3016 9 2 0 0
                    *attributeupdateint curves $crv5ID 5068 9 2 0 1
                    *attributeupdateint curves $crv5ID 90 9 2 0 0
                    *attributeupdateint curves $crv5ID 510 9 0 0 0
                    *attributeupdateint curves $crv5ID 515 9 0 0 0
                    set curveValue {
                        0.0,451.71596
                        0.005,457.816104
                        0.01,464.085296
                        0.015,470.510616
                        0.02,477.117696
                        0.025,483.90684
                        0.03,491.113104
                        0.035,498.375896
                        0.04,505.606088
                        0.045,513.16292
                        0.05,521.022464
                        0.055,528.855456
                        0.06,536.259912
                        0.065,543.03804
                        0.07,549.082904
                        0.075,554.743512
                        0.08,560.499072
                        0.085,566.346312
                        0.09,572.324456
                        0.095,578.036816
                        0.1,583.186368
                        0.105,587.737936
                        0.11,592.003472
                        0.115,595.985784
                        0.12,599.780576
                        0.125,603.440336
                        0.13,606.612152
                        0.135,609.29116
                        0.14,611.39944
                        0.145,613.074376
                        0.15,614.562032
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv5ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv5ID STATUS=1 512=0.8
                    *setvalue curves id=$crv5ID color=6
                }
                set matTabelName "TABLE_Q345"
                set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                if {![hm_entityinfo exist curve $matTabelName -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$matTabelName"
                    set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                    *attributeupdateint curves $matTabelID 3016 9 2 0 1
                    *attributeupdateint curves $matTabelID 4421 9 2 0 0
                    *attributeupdateint curves $matTabelID 5827 9 2 0 1
                    *attributeupdateint curves $matTabelID 90 9 2 0 0
                    *attributeupdatedouble curves $matTabelID 511 9 0 0 1
                    *attributeupdatedouble curves $matTabelID 513 9 0 0 0
                    *attributeupdateint curves $matTabelID 2246 9 1 0 5
                    *createdoublearray 5 0.01 1 10 200 500
                    *attributeupdatedoublearray curves $matTabelID 3017 9 2 0 1 5
                    *createarray 5 $crv1ID $crv2ID $crv3ID $crv4ID $crv5ID
                    *attributeupdateentityidarray curves $matTabelID 4420 9 2 0 curves 1 5
                    *setvalue curves id=$matTabelID color=6
                }
                set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                if {![hm_entityinfo exist mats $matName -byname]} {
                    *createentity mats cardimage=MATL24 name=$matName
                    *setvalue mats name=$matName STATUS=1 118=7.9e-009
                    *setvalue mats name=$matName STATUS=1 119=210000
                    *setvalue mats name=$matName STATUS=1 120=0.3
                    *setvalue mats name=$matName STATUS=1 152=380
                    *setvalue mats name=$matName STATUS=1 45={curves $matTabelID}
                    *setvalue mats name=$matName color=6
                }
            } elseif {[string match -nocase $matTail "Q235"]} {
                set curveName1 "Q235_0.01"
                if {![hm_entityinfo exist curve $curveName1 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName1"
                    *xyplotcurvemodify "$curveName1" "title" "$curveName1" 0 1
                    set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                    *curvedeletepoint $crv1ID 1
                    *attributeupdatedouble curves $crv1ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv1ID 514 9 0 0 0
                    *attributeupdateint curves $crv1ID 4421 9 2 0 0
                    *attributeupdateint curves $crv1ID 5827 9 2 0 1
                    *attributeupdateint curves $crv1ID 3016 9 2 0 0
                    *attributeupdateint curves $crv1ID 5068 9 2 0 1
                    *attributeupdateint curves $crv1ID 90 9 2 0 0
                    *attributeupdateint curves $crv1ID 510 9 0 0 0
                    *attributeupdateint curves $crv1ID 515 9 0 0 0
                    set curveValue {
                        0.0,357.35046
                        0.01,380.34069
                        0.02,399.7042
                        0.03,416.23117
                        0.04,428.64969
                        0.05,437.53322
                        0.06,444.21131
                        0.07,449.59016
                        0.08,454.06455
                        0.09,458.03279
                        0.1,461.89955
                        0.11,465.81577
                        0.12,469.90818
                        0.13,473.89385
                        0.14,477.6543
                        0.15,481.25324
                        0.16,484.6828
                        0.17,487.94023
                        0.18,490.92249
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv1ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv1ID color=4
                }
                set curveName2 "Q235_1"
                if {![hm_entityinfo exist curve $curveName2 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName2"
                    *xyplotcurvemodify "$curveName2" "title" "$curveName2" 0 1
                    set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                    *curvedeletepoint $crv2ID 1
                    *attributeupdatedouble curves $crv2ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv2ID 514 9 0 0 0
                    *attributeupdateint curves $crv2ID 4421 9 2 0 0
                    *attributeupdateint curves $crv2ID 5827 9 2 0 1
                    *attributeupdateint curves $crv2ID 3016 9 2 0 0
                    *attributeupdateint curves $crv2ID 5068 9 2 0 1
                    *attributeupdateint curves $crv2ID 90 9 2 0 0
                    *attributeupdateint curves $crv2ID 510 9 0 0 0
                    *attributeupdateint curves $crv2ID 515 9 0 0 0
                    set curveValue {
                        0.0,431.7818
                        0.01,463.1608
                        0.02,486.0408
                        0.03,500.28049
                        0.04,509.91314
                        0.05,518.26416
                        0.06,525.72788
                        0.07,532.16533
                        0.08,538.39733
                        0.09,544.56628
                        0.1,550.635
                        0.11,556.6564
                        0.12,562.079
                        0.13,566.4523
                        0.14,570.38455
                        0.15,574.41867
                        0.16,578.66789
                        0.17,583.03393
                        0.18,587.39997
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv2ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv2ID color=4
                }
                set curveName3 "Q235_10"
                if {![hm_entityinfo exist curve $curveName3 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName3"
                    *xyplotcurvemodify "$curveName3" "title" "$curveName3" 0 1
                    set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                    *curvedeletepoint $crv3ID 1
                    *attributeupdatedouble curves $crv3ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv3ID 514 9 0 0 0
                    *attributeupdateint curves $crv3ID 4421 9 2 0 0
                    *attributeupdateint curves $crv3ID 5827 9 2 0 1
                    *attributeupdateint curves $crv3ID 3016 9 2 0 0
                    *attributeupdateint curves $crv3ID 5068 9 2 0 1
                    *attributeupdateint curves $crv3ID 90 9 2 0 0
                    *attributeupdateint curves $crv3ID 510 9 0 0 0
                    *attributeupdateint curves $crv3ID 515 9 0 0 0
                    set curveValue {
                        0.0,481.69756
                        0.01,514.21395
                        0.02,532.60605
                        0.03,548.41614
                        0.04,560.54937
                        0.05,571.23823
                        0.06,581.33061
                        0.07,590.50669
                        0.08,598.67814
                        0.09,606.02577
                        0.1,612.39903
                        0.11,618.2757
                        0.12,623.66352
                        0.13,628.55717
                        0.14,633.27774
                        0.15,638.11241
                        0.16,643.19833
                        0.17,648.54686
                        0.18,653.43694
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv3ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv3ID color=4
                }
                set curveName4 "Q235_200"
                if {![hm_entityinfo exist curve $curveName4 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName4"
                    *xyplotcurvemodify "$curveName4" "title" "$curveName4" 0 1
                    set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                    *curvedeletepoint $crv4ID 1
                    *attributeupdatedouble curves $crv4ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv4ID 514 9 0 0 0
                    *attributeupdateint curves $crv4ID 4421 9 2 0 0
                    *attributeupdateint curves $crv4ID 5827 9 2 0 1
                    *attributeupdateint curves $crv4ID 3016 9 2 0 0
                    *attributeupdateint curves $crv4ID 5068 9 2 0 1
                    *attributeupdateint curves $crv4ID 90 9 2 0 0
                    *attributeupdateint curves $crv4ID 510 9 0 0 0
                    *attributeupdateint curves $crv4ID 515 9 0 0 0
                    set curveValue {
                        0.0,562.19461
                        0.01,582.91721
                        0.02,598.8758
                        0.03,613.53069
                        0.04,626.17891
                        0.05,637.13655
                        0.06,646.58741
                        0.07,654.40831
                        0.08,661.21562
                        0.09,667.07023
                        0.1,672.44326
                        0.11,677.57439
                        0.12,682.5548
                        0.14,692.96789
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv4ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv4ID color=4
                }
                set curveName5 "Q235_500"
                if {![hm_entityinfo exist curve $curveName5 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName5"
                    *xyplotcurvemodify "$curveName5" "title" "$curveName5" 0 1
                    set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                    *curvedeletepoint $crv5ID 1
                    *attributeupdatedouble curves $crv5ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv5ID 514 9 0 0 0
                    *attributeupdateint curves $crv5ID 4421 9 2 0 0
                    *attributeupdateint curves $crv5ID 5827 9 2 0 1
                    *attributeupdateint curves $crv5ID 3016 9 2 0 0
                    *attributeupdateint curves $crv5ID 5068 9 2 0 1
                    *attributeupdateint curves $crv5ID 90 9 2 0 0
                    *attributeupdateint curves $crv5ID 510 9 0 0 0
                    *attributeupdateint curves $crv5ID 515 9 0 0 0
                    set curveValue {
                        0.0,615.26959
                        0.01,636.95286
                        0.02,653.30452
                        0.03,667.70606
                        0.04,679.17567
                        0.05,688.66575
                        0.06,696.86588
                        0.07,703.98262
                        0.08,710.72218
                        0.09,716.77769
                        0.1,722.32909
                        0.11,727.67603
                        0.12,732.6698
                        0.14,741.25
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv5ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv5ID color=4
                }
                set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                set matTabelName "TABLE_Q235"
                if {![hm_entityinfo exist curve $matTabelName -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$matTabelName"
                    set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                    *attributeupdateint curves $matTabelID 3016 9 2 0 1
                    *attributeupdateint curves $matTabelID 4421 9 2 0 0
                    *attributeupdateint curves $matTabelID 5827 9 2 0 1
                    *attributeupdateint curves $matTabelID 90 9 2 0 0
                    *attributeupdatedouble curves $matTabelID 511 9 0 0 1
                    *attributeupdatedouble curves $matTabelID 513 9 0 0 0
                    *attributeupdateint curves $matTabelID 2246 9 1 0 5
                    *createdoublearray 5 0.01 1 10 200 500
                    *attributeupdatedoublearray curves $matTabelID 3017 9 2 0 1 5
                    *createarray 5 $crv1ID $crv2ID $crv3ID $crv4ID $crv5ID
                    *attributeupdateentityidarray curves $matTabelID 4420 9 2 0 curves 1 5
                    *setvalue curves id=$matTabelID color=4
                }
                set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                if {![hm_entityinfo exist mats $matName -byname]} {
                    *createentity mats cardimage=MATL24 name=$matName
                    *setvalue mats name=$matName STATUS=1 118=7.9e-009
                    *setvalue mats name=$matName STATUS=1 119=210000
                    *setvalue mats name=$matName STATUS=1 120=0.3
                    *setvalue mats name=$matName STATUS=1 152=380
                    *setvalue mats name=$matName STATUS=1 45={curves $matTabelID}
                    *setvalue mats name=$matName color=4
                }
            } elseif {[string match -nocase $matTail "20\#"]} {
                set curveName1 "20\#_0.01"
                if {![hm_entityinfo exist curve $curveName1 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName1"
                    *xyplotcurvemodify "$curveName1" "title" "$curveName1" 0 1
                    set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                    *curvedeletepoint $crv1ID 1
                    *attributeupdatedouble curves $crv1ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv1ID 514 9 0 0 0
                    *attributeupdateint curves $crv1ID 4421 9 2 0 0
                    *attributeupdateint curves $crv1ID 5827 9 2 0 1
                    *attributeupdateint curves $crv1ID 3016 9 2 0 0
                    *attributeupdateint curves $crv1ID 5068 9 2 0 1
                    *attributeupdateint curves $crv1ID 90 9 2 0 0
                    *attributeupdateint curves $crv1ID 510 9 0 0 0
                    *attributeupdateint curves $crv1ID 515 9 0 0 0
                    set curveValue {
                        0.0,357.35046
                        0.01,380.34069
                        0.02,399.7042
                        0.03,416.23117
                        0.04,428.64969
                        0.05,437.53322
                        0.06,444.21131
                        0.07,449.59016
                        0.08,454.06455
                        0.09,458.03279
                        0.1,461.89955
                        0.11,465.81577
                        0.12,469.90818
                        0.13,473.89385
                        0.14,477.6543
                        0.15,481.25324
                        0.16,484.6828
                        0.17,487.94023
                        0.18,490.92249
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv1ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv1ID color=4
                }
                set curveName2 "20\#_1"
                if {![hm_entityinfo exist curve $curveName2 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName2"
                    *xyplotcurvemodify "$curveName2" "title" "$curveName2" 0 1
                    set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                    *curvedeletepoint $crv2ID 1
                    *attributeupdatedouble curves $crv2ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv2ID 514 9 0 0 0
                    *attributeupdateint curves $crv2ID 4421 9 2 0 0
                    *attributeupdateint curves $crv2ID 5827 9 2 0 1
                    *attributeupdateint curves $crv2ID 3016 9 2 0 0
                    *attributeupdateint curves $crv2ID 5068 9 2 0 1
                    *attributeupdateint curves $crv2ID 90 9 2 0 0
                    *attributeupdateint curves $crv2ID 510 9 0 0 0
                    *attributeupdateint curves $crv2ID 515 9 0 0 0
                    set curveValue {
                        0.0,431.7818
                        0.01,463.1608
                        0.02,486.0408
                        0.03,500.28049
                        0.04,509.91314
                        0.05,518.26416
                        0.06,525.72788
                        0.07,532.16533
                        0.08,538.39733
                        0.09,544.56628
                        0.1,550.635
                        0.11,556.6564
                        0.12,562.079
                        0.13,566.4523
                        0.14,570.38455
                        0.15,574.41867
                        0.16,578.66789
                        0.17,583.03393
                        0.18,587.39997
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv2ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv2ID color=4
                }
                set curveName3 "20\#_10"
                if {![hm_entityinfo exist curve $curveName3 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName3"
                    *xyplotcurvemodify "$curveName3" "title" "$curveName3" 0 1
                    set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                    *curvedeletepoint $crv3ID 1
                    *attributeupdatedouble curves $crv3ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv3ID 514 9 0 0 0
                    *attributeupdateint curves $crv3ID 4421 9 2 0 0
                    *attributeupdateint curves $crv3ID 5827 9 2 0 1
                    *attributeupdateint curves $crv3ID 3016 9 2 0 0
                    *attributeupdateint curves $crv3ID 5068 9 2 0 1
                    *attributeupdateint curves $crv3ID 90 9 2 0 0
                    *attributeupdateint curves $crv3ID 510 9 0 0 0
                    *attributeupdateint curves $crv3ID 515 9 0 0 0
                    set curveValue {
                        0.0,481.69756
                        0.01,514.21395
                        0.02,532.60605
                        0.03,548.41614
                        0.04,560.54937
                        0.05,571.23823
                        0.06,581.33061
                        0.07,590.50669
                        0.08,598.67814
                        0.09,606.02577
                        0.1,612.39903
                        0.11,618.2757
                        0.12,623.66352
                        0.13,628.55717
                        0.14,633.27774
                        0.15,638.11241
                        0.16,643.19833
                        0.17,648.54686
                        0.18,653.43694
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv3ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv3ID color=4
                }
                set curveName4 "20\#_200"
                if {![hm_entityinfo exist curve $curveName4 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName4"
                    *xyplotcurvemodify "$curveName4" "title" "$curveName4" 0 1
                    set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                    *curvedeletepoint $crv4ID 1
                    *attributeupdatedouble curves $crv4ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv4ID 514 9 0 0 0
                    *attributeupdateint curves $crv4ID 4421 9 2 0 0
                    *attributeupdateint curves $crv4ID 5827 9 2 0 1
                    *attributeupdateint curves $crv4ID 3016 9 2 0 0
                    *attributeupdateint curves $crv4ID 5068 9 2 0 1
                    *attributeupdateint curves $crv4ID 90 9 2 0 0
                    *attributeupdateint curves $crv4ID 510 9 0 0 0
                    *attributeupdateint curves $crv4ID 515 9 0 0 0
                    set curveValue {
                        0.0,562.19461
                        0.01,582.91721
                        0.02,598.8758
                        0.03,613.53069
                        0.04,626.17891
                        0.05,637.13655
                        0.06,646.58741
                        0.07,654.40831
                        0.08,661.21562
                        0.09,667.07023
                        0.1,672.44326
                        0.11,677.57439
                        0.12,682.5548
                        0.14,692.96789
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv4ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv4ID color=4
                }
                set curveName5 "20\#_500"
                if {![hm_entityinfo exist curve $curveName5 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName5"
                    *xyplotcurvemodify "$curveName5" "title" "$curveName5" 0 1
                    set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                    *curvedeletepoint $crv5ID 1
                    *attributeupdatedouble curves $crv5ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv5ID 514 9 0 0 0
                    *attributeupdateint curves $crv5ID 4421 9 2 0 0
                    *attributeupdateint curves $crv5ID 5827 9 2 0 1
                    *attributeupdateint curves $crv5ID 3016 9 2 0 0
                    *attributeupdateint curves $crv5ID 5068 9 2 0 1
                    *attributeupdateint curves $crv5ID 90 9 2 0 0
                    *attributeupdateint curves $crv5ID 510 9 0 0 0
                    *attributeupdateint curves $crv5ID 515 9 0 0 0
                    set curveValue {
                        0.0,615.26959
                        0.01,636.95286
                        0.02,653.30452
                        0.03,667.70606
                        0.04,679.17567
                        0.05,688.66575
                        0.06,696.86588
                        0.07,703.98262
                        0.08,710.72218
                        0.09,716.77769
                        0.1,722.32909
                        0.11,727.67603
                        0.12,732.6698
                        0.14,741.25
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv5ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv5ID color=4
                }
                set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                set matTabelName "TABLE_20\#"
                if {![hm_entityinfo exist curve $matTabelName -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$matTabelName"
                    set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                    *attributeupdateint curves $matTabelID 3016 9 2 0 1
                    *attributeupdateint curves $matTabelID 4421 9 2 0 0
                    *attributeupdateint curves $matTabelID 5827 9 2 0 1
                    *attributeupdateint curves $matTabelID 90 9 2 0 0
                    *attributeupdatedouble curves $matTabelID 511 9 0 0 1
                    *attributeupdatedouble curves $matTabelID 513 9 0 0 0
                    *attributeupdateint curves $matTabelID 2246 9 1 0 5
                    *createdoublearray 5 0.01 1 10 200 500
                    *attributeupdatedoublearray curves $matTabelID 3017 9 2 0 1 5
                    *createarray 5 $crv1ID $crv2ID $crv3ID $crv4ID $crv5ID
                    *attributeupdateentityidarray curves $matTabelID 4420 9 2 0 curves 1 5
                    *setvalue curves id=$matTabelID color=4
                }
                set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                if {![hm_entityinfo exist mats $matName -byname]} {
                    *createentity mats cardimage=MATL24 name=$matName
                    *setvalue mats name=$matName STATUS=1 118=7.9e-009
                    *setvalue mats name=$matName STATUS=1 119=210000
                    *setvalue mats name=$matName STATUS=1 120=0.3
                    *setvalue mats name=$matName STATUS=1 152=380
                    *setvalue mats name=$matName STATUS=1 45={curves $matTabelID}
                    *setvalue mats name=$matName color=4
                }
            } elseif {[string match -nocase $matTail "\#20"]} {
                set curveName1 "20\#_0.01"
                if {![hm_entityinfo exist curve $curveName1 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName1"
                    *xyplotcurvemodify "$curveName1" "title" "$curveName1" 0 1
                    set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                    *curvedeletepoint $crv1ID 1
                    *attributeupdatedouble curves $crv1ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv1ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv1ID 514 9 0 0 0
                    *attributeupdateint curves $crv1ID 4421 9 2 0 0
                    *attributeupdateint curves $crv1ID 5827 9 2 0 1
                    *attributeupdateint curves $crv1ID 3016 9 2 0 0
                    *attributeupdateint curves $crv1ID 5068 9 2 0 1
                    *attributeupdateint curves $crv1ID 90 9 2 0 0
                    *attributeupdateint curves $crv1ID 510 9 0 0 0
                    *attributeupdateint curves $crv1ID 515 9 0 0 0
                    set curveValue {
                        0.0,357.35046
                        0.01,380.34069
                        0.02,399.7042
                        0.03,416.23117
                        0.04,428.64969
                        0.05,437.53322
                        0.06,444.21131
                        0.07,449.59016
                        0.08,454.06455
                        0.09,458.03279
                        0.1,461.89955
                        0.11,465.81577
                        0.12,469.90818
                        0.13,473.89385
                        0.14,477.6543
                        0.15,481.25324
                        0.16,484.6828
                        0.17,487.94023
                        0.18,490.92249
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv1ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv1ID color=4
                }
                set curveName2 "20\#_1"
                if {![hm_entityinfo exist curve $curveName2 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName2"
                    *xyplotcurvemodify "$curveName2" "title" "$curveName2" 0 1
                    set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                    *curvedeletepoint $crv2ID 1
                    *attributeupdatedouble curves $crv2ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv2ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv2ID 514 9 0 0 0
                    *attributeupdateint curves $crv2ID 4421 9 2 0 0
                    *attributeupdateint curves $crv2ID 5827 9 2 0 1
                    *attributeupdateint curves $crv2ID 3016 9 2 0 0
                    *attributeupdateint curves $crv2ID 5068 9 2 0 1
                    *attributeupdateint curves $crv2ID 90 9 2 0 0
                    *attributeupdateint curves $crv2ID 510 9 0 0 0
                    *attributeupdateint curves $crv2ID 515 9 0 0 0
                    set curveValue {
                        0.0,431.7818
                        0.01,463.1608
                        0.02,486.0408
                        0.03,500.28049
                        0.04,509.91314
                        0.05,518.26416
                        0.06,525.72788
                        0.07,532.16533
                        0.08,538.39733
                        0.09,544.56628
                        0.1,550.635
                        0.11,556.6564
                        0.12,562.079
                        0.13,566.4523
                        0.14,570.38455
                        0.15,574.41867
                        0.16,578.66789
                        0.17,583.03393
                        0.18,587.39997
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv2ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv2ID color=4
                }
                set curveName3 "20\#_10"
                if {![hm_entityinfo exist curve $curveName3 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName3"
                    *xyplotcurvemodify "$curveName3" "title" "$curveName3" 0 1
                    set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                    *curvedeletepoint $crv3ID 1
                    *attributeupdatedouble curves $crv3ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv3ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv3ID 514 9 0 0 0
                    *attributeupdateint curves $crv3ID 4421 9 2 0 0
                    *attributeupdateint curves $crv3ID 5827 9 2 0 1
                    *attributeupdateint curves $crv3ID 3016 9 2 0 0
                    *attributeupdateint curves $crv3ID 5068 9 2 0 1
                    *attributeupdateint curves $crv3ID 90 9 2 0 0
                    *attributeupdateint curves $crv3ID 510 9 0 0 0
                    *attributeupdateint curves $crv3ID 515 9 0 0 0
                    set curveValue {
                        0.0,481.69756
                        0.01,514.21395
                        0.02,532.60605
                        0.03,548.41614
                        0.04,560.54937
                        0.05,571.23823
                        0.06,581.33061
                        0.07,590.50669
                        0.08,598.67814
                        0.09,606.02577
                        0.1,612.39903
                        0.11,618.2757
                        0.12,623.66352
                        0.13,628.55717
                        0.14,633.27774
                        0.15,638.11241
                        0.16,643.19833
                        0.17,648.54686
                        0.18,653.43694
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv3ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv3ID color=4
                }
                set curveName4 "20\#_200"
                if {![hm_entityinfo exist curve $curveName4 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName4"
                    *xyplotcurvemodify "$curveName4" "title" "$curveName4" 0 1
                    set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                    *curvedeletepoint $crv4ID 1
                    *attributeupdatedouble curves $crv4ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv4ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv4ID 514 9 0 0 0
                    *attributeupdateint curves $crv4ID 4421 9 2 0 0
                    *attributeupdateint curves $crv4ID 5827 9 2 0 1
                    *attributeupdateint curves $crv4ID 3016 9 2 0 0
                    *attributeupdateint curves $crv4ID 5068 9 2 0 1
                    *attributeupdateint curves $crv4ID 90 9 2 0 0
                    *attributeupdateint curves $crv4ID 510 9 0 0 0
                    *attributeupdateint curves $crv4ID 515 9 0 0 0
                    set curveValue {
                        0.0,562.19461
                        0.01,582.91721
                        0.02,598.8758
                        0.03,613.53069
                        0.04,626.17891
                        0.05,637.13655
                        0.06,646.58741
                        0.07,654.40831
                        0.08,661.21562
                        0.09,667.07023
                        0.1,672.44326
                        0.11,677.57439
                        0.12,682.5548
                        0.14,692.96789
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv4ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv4ID color=4
                }
                set curveName5 "20\#_500"
                if {![hm_entityinfo exist curve $curveName5 -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$curveName5"
                    *xyplotcurvemodify "$curveName5" "title" "$curveName5" 0 1
                    set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                    *curvedeletepoint $crv5ID 1
                    *attributeupdatedouble curves $crv5ID 511 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 512 9 0 0 1
                    *attributeupdatedouble curves $crv5ID 513 9 0 0 0
                    *attributeupdatedouble curves $crv5ID 514 9 0 0 0
                    *attributeupdateint curves $crv5ID 4421 9 2 0 0
                    *attributeupdateint curves $crv5ID 5827 9 2 0 1
                    *attributeupdateint curves $crv5ID 3016 9 2 0 0
                    *attributeupdateint curves $crv5ID 5068 9 2 0 1
                    *attributeupdateint curves $crv5ID 90 9 2 0 0
                    *attributeupdateint curves $crv5ID 510 9 0 0 0
                    *attributeupdateint curves $crv5ID 515 9 0 0 0
                    set curveValue {
                        0.0,615.26959
                        0.01,636.95286
                        0.02,653.30452
                        0.03,667.70606
                        0.04,679.17567
                        0.05,688.66575
                        0.06,696.86588
                        0.07,703.98262
                        0.08,710.72218
                        0.09,716.77769
                        0.1,722.32909
                        0.11,727.67603
                        0.12,732.6698
                        0.14,741.25
                    }
                    for {set i 0} {$i < [llength $curveValue]} {incr i} {
                        set curveX [lindex [split [lindex $curveValue $i] ","] 0]
                        set curveY [lindex [split [lindex $curveValue $i] ","] 1]
                        *curveaddpoint $crv5ID $i $curveX $curveY
                    }
                    *setvalue curves id=$crv5ID color=4
                }
                set crv1ID [hm_getvalue curves name=$curveName1 dataname=id]
                set crv2ID [hm_getvalue curves name=$curveName2 dataname=id]
                set crv3ID [hm_getvalue curves name=$curveName3 dataname=id]
                set crv4ID [hm_getvalue curves name=$curveName4 dataname=id]
                set crv5ID [hm_getvalue curves name=$curveName5 dataname=id]
                set matTabelName "TABLE_20\#"
                if {![hm_entityinfo exist curve $matTabelName -byname]} {
                    *xyplotcreatecurve "{0}" "" "" "" 1 "{0}" "" "" "" 1
                    *renamecollector curves "curve1" "$matTabelName"
                    set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                    *attributeupdateint curves $matTabelID 3016 9 2 0 1
                    *attributeupdateint curves $matTabelID 4421 9 2 0 0
                    *attributeupdateint curves $matTabelID 5827 9 2 0 1
                    *attributeupdateint curves $matTabelID 90 9 2 0 0
                    *attributeupdatedouble curves $matTabelID 511 9 0 0 1
                    *attributeupdatedouble curves $matTabelID 513 9 0 0 0
                    *attributeupdateint curves $matTabelID 2246 9 1 0 5
                    *createdoublearray 5 0.01 1 10 200 500
                    *attributeupdatedoublearray curves $matTabelID 3017 9 2 0 1 5
                    *createarray 5 $crv1ID $crv2ID $crv3ID $crv4ID $crv5ID
                    *attributeupdateentityidarray curves $matTabelID 4420 9 2 0 curves 1 5
                    *setvalue curves id=$matTabelID color=4
                }
                set matTabelID [hm_getvalue curves name=$matTabelName dataname=id]
                if {![hm_entityinfo exist mats $matName -byname]} {
                    *createentity mats cardimage=MATL24 name=$matName
                    *setvalue mats name=$matName STATUS=1 118=7.9e-009
                    *setvalue mats name=$matName STATUS=1 119=210000
                    *setvalue mats name=$matName STATUS=1 120=0.3
                    *setvalue mats name=$matName STATUS=1 152=380
                    *setvalue mats name=$matName STATUS=1 45={curves $matTabelID}
                    *setvalue mats name=$matName color=4
                }
            }
        }
        default {return 0}
    }
    return [hm_getvalue mats name=$matName dataname=id]
}

proc ::autoProp::createProperty {profile parms} {
    variable errList
    switch $profile {
        OptiStruct {
            if {[hm_getvalue comps id=[lindex $parms 0] dataname=property] > 0} {
                return [hm_getvalue comps id=[lindex $parms 0] dataname=property]
            }
            set propName ""
            if {[lindex $parms 3] eq "null"} {
                set propTail "NONAME"
            } else {
                set propTail [lindex $parms 3]
            }
            if {[lindex $parms 1] eq "shell" && [lindex $parms 2] != "nothickness"} {
                set prefix "PSHELL"
                append propName $prefix "_t" [lindex $parms 2] "_" $propTail
            } elseif {[lindex $parms 1] eq "solid"} {
                set prefix "PSOLID"
                append propName $prefix "_" $propTail
            } else {
                ::autoProp::adderrmsg [lindex $parms 0] "未设置厚度信息"
                return 0
            }
            if {![hm_entityinfo exist prop $propName -byname]} {
                *createentity props cardimage=$prefix name=$propName
                if {$prefix eq "PSHELL"} {
                    *setvalue props name=$propName STATUS=1 95=[lindex $parms 2]
                }
            }
        }
        LsDyna     {
            if {[hm_getvalue comps id=[lindex $parms 0] dataname=property] > 0} {
                return [hm_getvalue comps id=[lindex $parms 0] dataname=property]
            }
            set propName ""
            if {[lindex $parms 1] eq "shell" && [lindex $parms 2] != "nothickness"} {
                set prefix "SectShll"
                append propName $prefix "_t" [lindex $parms 2]
            } elseif {[lindex $parms 1] eq "solid"} {
                set prefix "SectSld"
                append propName $prefix "_CompID." [lindex $parms 0]
            } elseif {[lindex $parms 1] eq "shell" && [lindex $parms 2] eq "nothickness"} {
                ::autoProp::adderrmsg [lindex $parms 0] "未设置厚度信息"
                return 0
            }
            if {![hm_entityinfo exist prop $propName -byname]} {
                *createentity props cardimage=$prefix name=$propName
                if {$prefix == "SectShll"} {
                    *setvalue props name=$propName STATUS=1 399=16
                    *setvalue props name=$propName STATUS=1 427=5
                    *setvalue props name=$propName STATUS=1 431=[lindex $parms 2]
                } else {
                    *setvalue props name=$propName STATUS=1 399=5
                }
            }
        }
        default {return 0}
    }
    return [hm_getvalue props name=$propName dataname=id]
}

proc ::autoProp::assign {profile comp MID PID} {
    if {[expr $MID + $PID] == 0} {
        return
    }
    switch $profile {
        LsDyna {
            *setvalue comps id=$comp cardimage="Part"
            if {$PID} {*setvalue comps id=$comp propertyid={props $PID}}
            if {$MID} {*setvalue comps id=$comp materialid={mats $MID}}
        }
        OptiStruct {
            if {[expr $MID*$PID]} {
                if {[hm_getvalue props id=$PID dataname=material] == 0} {
                    *setvalue props id=$PID materialid={mats $MID}
                }
                if {[hm_getvalue comps id=$comp dataname=property] == 0} {
                    *setvalue comps id=$comp propertyid={props $PID}
                }
            }
        }
    }
}

proc ::autoProp::listProps {args} {
    *clearmarkall 1
    *createmark props 1 "all"
    set propLst ""
    foreach id [hm_getmark props 1] {
        lappend propLst [hm_getvalue props id=$id dataname=name]
    }
    return $propLst
}

proc ::autoProp::listMats {args} {
    *clearmarkall 1    
    *createmark mats 1 "all"
    set matLst ""
    foreach id [hm_getmark mats 1] {
        lappend matLst [hm_getvalue mats id=$id dataname=name]
    }
    return $matLst
}

proc ::autoProp::getMat {id} {
    variable profile
    if {$profile eq "LsDyna"} {
        return [hm_getvalue comps id=$id dataname=material.name]
    } else {
        return [hm_getvalue comps id=$id dataname=property.material.name]
    }
}

proc ::autoProp::applyProp {args} {
    variable table
    variable profile

    set rowLst [$table rowlist]
    foreach row $rowLst {
        set id [$table cellget $row,id]
        set name [$table cellget $row,name]
        catch {set prop [hm_getvalue props name=[$table cellget $row,prop] dataname=id]}
        catch {set mat [hm_getvalue mats name=[$table cellget $row,mat] dataname=id]}
        if {$profile eq "LsDyna"} {
            catch {*setvalue comps id=$id name=$name}
            catch {*setvalue comps id=$id property=$prop}
            catch {*setvalue comps id=$id material=$mat}
        } else {
            catch {*setvalue comps id=$id name=$name}
            if {![Null prop]} {
                catch {*setvalue props id=$prop material=$mat}
                catch {*setvalue comps id=$id property=$prop}
            }
        }
        catch {
            unset id
            unset name
            unset prop
            unset mat
        }
        if {[$table cellget $row,prop] != "" && [$table cellget $row,mat] != ""} {
            $table rowconfigure $row -background "lightgreen"
            $table cellset $row,msg ""
        }
    }
    tk_messageBox -title "提示" -message "模型信息已更新!"
}

proc ::autoProp::displayMsg {args} {
    variable table
    variable profile
    variable errList

    destroy .errDialog
    set mw [::hwtk::dialog .errDialog -title "信息" -transient .]
    set recess [$mw recess]
    $mw hide cancel
    $mw buttonconfigure ok -text "Apply" -command {::autoProp::applyProp}
    $mw buttonconfigure apply -text "Close" -command {destroy .errDialog}
    $mw post
    wm geometry $mw 800x300
    wm resizable $mw 0 0

    set table [::hwtk::table $recess.table ]
        $table columncreate id -text "ID" -justify center -width 30 -editable 0 -width 100
        $table columncreate name -text "名称" -justify center -width 180
        $table columncreate prop -text "属性" -justify center -type combobox -valuelistcommand "::autoProp::listProps" -width 150
        $table columncreate mat -text "材料" -justify center -type combobox -valuelistcommand "::autoProp::listMats" -width 150
        $table columncreate msg -text "错误信息" -justify center -editable 0

    pack $table -fill both -expand true -side top

    for {set i 0} {$i < [llength $errList]} {incr i 2} {
        set values [list id [lindex $errList $i] name [hm_getvalue comps id=[lindex $errList $i] dataname=name] prop [hm_getvalue comps id=[lindex $errList $i] dataname=property.name] mat [::autoProp::getMat [lindex $errList $i]] msg [lindex $errList [expr $i + 1]]]
        $table rowinsert end row$i -values $values 
    }

    if {$profile eq "OptiStruct"} {
        $table columnconfigure mat -editable 0
    }

}

proc ::autoProp::main {args} {
    variable errList
    variable profile
    set profile [::autoProp::getProfile]
    if {$profile eq "unsupportedProfile"} {
        tk_messageBox -title "提示" -message "当前程序版本仅支持LsDyna和OptiStruct环境 !"
        return
    }
    set compSet [::autoProp::pickComps]
    if {$compSet eq "nullComps"} {
        return
    } else {
        foreach comp $compSet {
            set compParms [::autoProp::getCompParms $comp]
            if {[lindex $compParms 1] == "null"} {
                ::autoProp::adderrmsg [lindex $compParms 0] "未找到任何网格"
            } elseif {[lindex $compParms 1] == "toomany"} {
                ::autoProp::adderrmsg [lindex $compParms 0] "含有多类型网格"
            } elseif {[lindex $compParms 1] == "1D"} {
                ::autoProp::adderrmsg [lindex $compParms 0] "不支持1D单元"
            } else {
                set MID [::autoProp::createMaterial $profile $compParms]
                set PID [::autoProp::createProperty $profile $compParms]
                ::autoProp::assign $profile $comp $MID $PID
            }
        }
    }
    if {[llength $errList] > 0} {
        ::autoProp::displayMsg
    } else {
        tk_messageBox -title "提示" -message "所有操作已完成!"
    }
}
::autoProp::main
