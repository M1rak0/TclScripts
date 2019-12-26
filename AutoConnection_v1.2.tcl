# Coding UTF-8
# FILE NAME: AutoConnection_v1.2.tcl
# DESCRIPTION:
# INPUT: 
# OUTPUT: 
# AUTHOR:Lai Qibo

# Changelog - 20191202 v1.2 -- 一周年纪念典藏版
# 1:新增视图保存和恢复功能，在进行任何操作之后都会将视图恢复到操作前的状态，再也不会把已经隐藏的网格显示出来了
# 2:修改了1D单元检查和自动处理的逻辑，大幅提升了运行速度 （新的处理逻辑：将所有无法通过1D检查的单元按组分别合并为一个新的1D单元）
# 3:批量塞焊模块由于速度太慢，打入冷宫（默认隐藏）
# 4:精简代码（为什么功能越来越牛B代码却越来越少）
# 5:修复了每次使用完毕之后残留空system collector的BUG

# Changelog - 20190911 v1.1
# 1:修复了在粗画网格模型中进行连接后自动显示粗画网格的BUG
# 2:速度优化

# Changelog - 20181202 v1.0
# 1:初版发布

# global variables initializing
    set weldTol 10
    set weldLength 100
    set weldGap 300
    set maxDia 100

    set currentComp 0
    set selfComp 1
    set singleWithWasher 0
    set multipleWithWasher 0
    set rgdChkAllElems 0


catch {namespace delete ::rgdlnkCnt}
namespace eval ::rgdlnkCnt {
    set rgdChkPrgsbar ""
    set mainWindow ""
    set seamNodesSel ""
    set seamCompsSel ""
    set singleNodesSel ""
    set singleCompsSel ""
    set multiComps1Sel ""
    set multiComps2Sel ""
    set rgdChkElemSel ""
    set seamPath ""
    set seamCompSet ""
    set singleNodes ""
    set singleComps ""
    set multipleComps1 ""
    set multipleComps2 ""
    set elemsToChk ""
}

proc ::rgdlnkCnt::mainWindow {args} {

    global weldTol
    global weldLength
    global weldGap
    global maxDia
    global currentComp
    global selfComp
    global singleWithWasher
    global multipleWithWasher
    global rgdChkAllElems    

    variable rgdChkPrgsbar
    variable mainWindow
    variable seamNodesSel
    variable seamCompsSel
    variable singleNodesSel
    variable singleCompsSel
    variable multiComps1Sel
    variable multiComps2Sel
    variable rgdChkElemSel

    variable seamPath
    variable seamCompSet
    variable singleNodes
    variable singleComps
    variable multipleComps1
    variable multipleComps2
    variable elemsToChk



    # main window create
    destroy .rgdlnkMW
    set mainWindow [::hwtk::toplevel .rgdlnkMW]
    wm title $mainWindow "自动连接工具V1.1"
    # wm geometry $mainWindow  735x142
    wm resizable $mainWindow 0 0
    KeepOnTop $mainWindow

    # wigets create
    set parmFrame [labelframe $mainWindow.parmFrame -relief sunken -text "参数设置" -font "times 10" -fg blue]
        set tolLabel  [label $parmFrame.tolLabel -text "焊接容差:" -font "times 10" -fg blue -width 10 -justify left]
        set tolEntry [::hwtk::entry $parmFrame.tolEntry -help "被焊接部件间允许的最大距离\n若设为0则不考虑距离" -justify right -textvariable weldTol -inputtype unsignedinteger -width 6]
        set lengthLabel [label $parmFrame.lengthLabel -text "焊缝长度:" -font "times 10" -fg blue -width 10 -justify left]
        set lengthEntry [::hwtk::entry $parmFrame.lengthEntry -help "单条焊缝的长度" -justify right -textvariable weldLength -inputtype unsignedinteger -width 6]
        set gapLabel [label $parmFrame.gapLabel -text "焊缝间距:" -font "times 10" -fg blue -width 10 -justify left]
        set gapEntry [::hwtk::entry $parmFrame.gapEntry -help "每两条焊缝间的距离\n若设置为0则连续焊" -justify right -textvariable weldGap -inputtype unsignedinteger -width 6]
        set diamLabel [label $parmFrame.diamLabel -text "最大半径:" -font "times 10" -fg blue -width 10 -justify left]
        set diamEntry [::hwtk::entry $parmFrame.diamEntry -help "自动检测小于此半径的孔\n设为0则检测所有孔" -justify right -textvariable maxDia -inputtype unsignedinteger -width 6]
        set cbLabel [label $parmFrame.cbLabel -text "置于当前:" -font "times 10" -fg blue -width 10 -justify left]
        set currentcb [::hwtk::checkbutton $parmFrame.currentcb -help "勾选则将在当前component中创建1D单元" -variable currentComp -onvalue 1 -offvalue 0]

    set seamFrame [labelframe $mainWindow.seamFrame -relief sunken -text "断续焊接" -font "times 10" -fg blue]
        set seamSelectFrame [frame $seamFrame.seamSelectFrame]
            set seamNodesSel [button $seamSelectFrame.seamNodesSel -text "选择节点" -font "times 10" -command {::rgdlnkCnt::seamPickPath seamNodesSel} -width 14]
            set seamNodesClr [button $seamSelectFrame.seamNodesClr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject seamPath} -width 2]
            set seamCompsSel [button $seamSelectFrame.seamCompsSel -text "选择部件" -font "times 10" -command {::rgdlnkCnt::pickComps seamCompsSel seamCompSet "请选择需要焊接的部件"} -width 14]
            set seamCompsClr [button $seamSelectFrame.seamCompsClr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject seamCompSet} -width 2]
            set selfLabel [label $seamSelectFrame.selfLabel -text "包含自身:" -font "times 10" -fg blue -width 10 -justify left]
            set selfcb [::hwtk::checkbutton $seamSelectFrame.selfcb -help "勾选则可以对同component内的网格进行焊接" -variable selfComp -onvalue 1 -offvalue 0]
        set seamCreate [button $seamFrame.seamCreate -text "创建连接" -font "times 10" -command {::rgdlnkCnt::createSeam} -width 17]
            
    set singleSpiderFrame [labelframe $mainWindow.singleSpiderFrame -relief sunken -text "手动塞焊" -font "times 10" -fg blue]
        set singleSpiderSelectFrame [frame $singleSpiderFrame.singleSpiderSelectFrame]
            set singleNodesSel [button $singleSpiderSelectFrame.singleNodesSel -text "选择节点" -font "times 10" -command {::rgdlnkCnt::pickNodes singleNodesSel singleNodes "请在所有需要塞焊的孔边缘各选择一个节点"} -width 14]
            set singleNodesClr [button $singleSpiderSelectFrame.singleNodesClr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject singleNodes} -width 2]
            set singleCompsSel [button $singleSpiderSelectFrame.singleCompsSel -text "选择部件" -font "times 10" -command {::rgdlnkCnt::pickComps singleCompsSel singleComps "请选择需要焊接的部件"} -width 14]
            set singleCompsClr [button $singleSpiderSelectFrame.singleCompsClr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject singleComps} -width 2]
            set singleWasherLabel [label $singleSpiderSelectFrame.singleWasherLabel -text "双层连接:" -font "times 10" -fg blue -width 10 -justify left]
            set singleWashercb [::hwtk::checkbutton $singleSpiderSelectFrame.singleWashercb -help "勾选则在塞焊时包含washer" -variable singleWithWasher -onvalue 1 -offvalue 0]
        set singleCreate [button $singleSpiderFrame.singleCreate -text "创建连接" -font "times 10" -command {::rgdlnkCnt::createSingle} -width 17]
        
    set multiSpiderFrame [labelframe $mainWindow.multiSpiderFrame -relief sunken -text "自动塞焊" -font "times 10" -fg blue]
        set multiSpiderSelectFrame [frame $multiSpiderFrame.multiSpiderSelectFrame]
            set multiComps1Sel [button $multiSpiderSelectFrame.multiComps1Sel -text "选择部件" -font "times 10" -command {::rgdlnkCnt::pickComps multiComps1Sel multipleComps1 "请选择需要焊接的部件"} -width 14]
            set multiComps1Clr [button $multiSpiderSelectFrame.multiComps1Clr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject multipleComps1} -width 2]
            set multiComps2Sel [button $multiSpiderSelectFrame.multiComps2Sel -text "选择部件" -font "times 10" -command {::rgdlnkCnt::pickComps multiComps2Sel multipleComps2 "请选择需要焊接的部件"} -width 14]
            set multiComps2Clr [button $multiSpiderSelectFrame.multiComps2Clr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject multipleComps2} -width 2]
            set multiWasherLabel [label $multiSpiderSelectFrame.multiWasherLabel -text "双层连接:" -font "times 10" -fg blue -width 10 -justify left]
            set multiWashercb [::hwtk::checkbutton $multiSpiderSelectFrame.multiWashercb -help "勾选则在塞焊时包含washer" -variable multipleWithWasher -onvalue 1 -offvalue 0]
        set multiCreate [button $multiSpiderFrame.multiCreate -text "创建连接" -font "times 10" -command {::rgdlnkCnt::createMultiple} -width 17]

    set rigidCheckFrame [labelframe $mainWindow.rigidCheckFrame -relief sunken -text "连接检查" -font "times 10" -fg blue]
        set rgdChkSelFrm [frame $rigidCheckFrame.rgdChkSelFrm]
            set rgdChkElemSel [button $rgdChkSelFrm.rgdChkElemSel -text "选择单元" -font "times 10" -command {::rgdlnkCnt::pickElems rgdChkElemSel elemsToChk "请选择需要检查的单元"} -width 14]
            set rgdChkElemClr [button $rgdChkSelFrm.rgdChkElemClr -text "×" -font "times 10 bold" -command {::rgdlnkCnt::reject elemsToChk} -width 2]
            # 界面实在放不满了，这是用来掩饰尴尬的并没有什么用的空白按钮
            set rgdChkCompsSel [button $rgdChkSelFrm.rgdChkCompsSel -text " " -font "times 10" -relief flat -state disabled -width 14]
            set rgdChkCompsClr [button $rgdChkSelFrm.rgdChkCompsClr -text " " -font "times 10 bold" -relief flat -state disabled -width 2]
            # *****************************************************
            set rgdChkAllLabel [label $rgdChkSelFrm.rgdChkAllLabel -text "所有单元:" -font "times 10" -fg blue -width 10 -justify left]
            set rgdChkAllcb [::hwtk::checkbutton $rgdChkSelFrm.rgdChkAllcb -help "勾选则自动检查整个模型" -variable rgdChkAllElems -onvalue 1 -offvalue 0]
        # 这是原本用来掩饰尴尬的并没有什么用的永远没有进度的进度条
        # set rgdChkPrgsbar [::hwtk::progressbar $rigidCheckFrame.rgdChkPrgsbar -mode determinate -length 125]
        # **************************************************
        set rgdChkBtn [button $rigidCheckFrame.rgdChkBtn -text "检查连接" -font "times 10" -command {::rgdlnkCnt::elemsChk} -width 17]
              
    # window layput
        grid $parmFrame -row 0 -column 0 -padx 10 -pady 6
            grid $tolLabel -row 0 -column 0 -padx 2 
            grid $tolEntry -row 0 -column 1 -padx 2 
            grid $lengthLabel -row 1 -column 0 -pady 2
            grid $lengthEntry -row 1 -column 1 -pady 2
            grid $gapLabel -row 2 -column 0 
            grid $gapEntry -row 2 -column 1
            grid $diamLabel -row 3 -column 0 -pady 2
            grid $diamEntry -row 3 -column 1 -pady 2
            grid $cbLabel -row 4 -column 0
            grid $currentcb -row 4 -column 1    -pady 2
        grid $seamFrame -row 0 -column 1 -padx 0 -pady 6
            pack $seamSelectFrame -padx 2  
                grid $seamNodesSel -row 0 -column 0 
                grid $seamNodesClr -row 0 -column 1 
                grid $seamCompsSel -row 1 -column 0 -pady 5
                grid $seamCompsClr -row 1 -column 1 -pady 5
                grid $selfLabel -row 2 -column 0 
                grid $selfcb -row 2 -column 1 
            pack $seamCreate -pady 2
        grid $singleSpiderFrame -row 0 -column 2 -padx 10 -pady 6
            pack $singleSpiderSelectFrame -padx 2 
                grid $singleNodesSel -row 0 -column 0 
                grid $singleNodesClr -row 0 -column 1
                grid $singleCompsSel -row 1 -column 0 -pady 5
                grid $singleCompsClr -row 1 -column 1 -pady 5
                grid $singleWasherLabel -row 2 -column 0
                grid $singleWashercb -row 2 -column 1
            pack $singleCreate -pady 2
        # **********************************冷宫********************************** #
            # grid $multiSpiderFrame -row 0 -column 3 -pady 6
            #     pack $multiSpiderSelectFrame -padx 2 
            #         grid $multiComps1Sel -row 0 -column 0 
            #         grid $multiComps1Clr -row 0 -column 1
            #         grid $multiComps2Sel -row 1 -column 0 -pady 5
            #         grid $multiComps2Clr -row 1 -column 1 -pady 5
            #         grid $multiWasherLabel -row 2 -column 0
            #         grid $multiWashercb -row 2 -column 1
            #     pack $multiCreate -pady 2
        # ************************************************************************ #
        grid $rigidCheckFrame -row 0 -column 4 -padx 10 -pady 6
            pack $rgdChkSelFrm -padx 2
                grid $rgdChkElemSel -row 0 -column 0 
                grid $rgdChkElemClr -row 0 -column 1
                grid $rgdChkCompsSel -row 1 -column 0 -pady 4
                grid $rgdChkCompsClr -row 1 -column 1 -pady 4
                grid $rgdChkAllLabel -row 2 -column 0 
                grid $rgdChkAllcb -row 2 -column 1 
            # pack $rgdChkPrgsbar -pady 2
            pack $rgdChkBtn -pady 2
    # end window layout
}

proc ::rgdlnkCnt::reject {args} {
    foreach arg $args {
        variable $arg
        set $arg ""
    }
}

proc ::rgdlnkCnt::seamPickPath {path} {
    variable seamPath
    variable mainWindow
    variable $path
    set widgetPath [set $path]

    $widgetPath configure -state disable
    wm iconify $mainWindow
    focus .

    *clearmarkall 1
    *createlistbypathpanel nodes 1 "请选择定位节点"
    set seamPath [hm_getlist nodes 1]
    *clearmarkall 1
    wm deiconify $mainWindow
    $widgetPath configure -state active
    return $seamPath
}

proc ::rgdlnkCnt::createSeam {args} {
    global weldTol
    global weldLength
    global weldGap
    global currentComp
    global selfComp
    set weldlength $weldLength
    set weldgap $weldGap
    if {$weldLength < 5 || $weldLength == ""} {set weldlength 5}
    if {$weldGap == 0 || $weldGap == ""} {set weldgap 0}
    
    set currentDisplayed [::rgdlnkCnt::viewClip]
    set elemsCreated ""

    variable seamPath
    variable seamCompSet
    if {[Null seamPath]} {
        tk_messageBox -title "错误" -message "未选择任何节点!"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    set nodesOnFace ""
    if {[Null seamCompSet] && $selfComp == 0} {
        tk_messageBox -title "错误" -message "未选择任何部件!"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    } elseif {$selfComp == 1} {
        *clearmarkall 1
        *clearmarkall 2
        eval *createmark nodes 1 $seamPath
        *findmark nodes 1 1 1 elements 0 2
        *appendmark nodes 1 "by face"
        set nodesOnFace [hm_getmark nodes 1]
        set nodesComps ""
        foreach elem [hm_getmark elems 2] {
            set elemComp [hm_getvalue elems id=$elem dataname=component]
            if {[lsearch $nodesComps $elemComp] == -1} {
                lappend nodesComps $elemComp
            }
        }
        *clearmarkall 1
        *clearmarkall 2
        append seamCompSet " " $nodesComps
    }
    if {$currentComp == 0} {
        if {![hm_entityinfo exist comp "rigids_autogenerate" -byname]} {
            *createentity comps name="rigids_autogenerate" color=3
        }
        *currentcollector comps "rigids_autogenerate"
    }
    if {[expr $weldlength / 10] <= [llength $seamPath]} {
        set totalLength 0
        foreach node $seamPath {
            # divide the node path selected with a length unit (weldlength+weldgap), caculate each node's relative position on the unit.
            # the threshold is the ratio of length and unit. if the relative position of a node is smaller than threshold, it will be picked.
            if {[lsearch $seamPath $node] > 0} {
                set prev [lindex $seamPath [expr $index - 1]]
                set nnDist [lindex [hm_getdistance nodes $node $prev 0] 0]
            } else {
                set nnDist 0
            }
            set totalLength [expr $totalLength + $nnDist]
            set absPosition [expr 1.0*$totalLength / ($weldlength + $weldgap)]
            set relativePosition [format "%.10f" 0.[lindex [split $absPosition "."] 1]]
            set threshold [format "%.10f" [expr $weldlength.0 / ($weldlength + $weldgap)]]
            if {$relativePosition <= $threshold} {
                lappend weldNodes $node
            }
        }
    } else {
        set weldNodes $seamPath
    }
    if {$weldTol == 0 || $weldTol == ""} {
        set tolorance 99999
    } else {
        set tolorance $weldTol
    }
    set targetNodes ""
    foreach node $weldNodes {
        *clearmarkall 1
        *clearmarkall 2
        eval *createmark elems 1 "by comps" $seamCompSet
        eval *createmark nodes 1 $nodesOnFace
        set targetNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 1 1]
        if {[lindex [hm_getdistance nodes $node $targetNode 0] 0] <= $tolorance} {
            if {[lindex $targetNodes end] == $targetNode} {
                eval *createmark elems 2 -1
                *deletemark elems 2
                eval *createmark nodes 2 [list $prevNode $node $targetNode]
                *rigidlinkinodecalandcreate 2 0 0 123456
                lappend targetNodes $targetNode
            } else {
                eval *createmark nodes 2 [list $node $targetNode]
                *rigidlinkinodecalandcreate 2 0 0 123456
                lappend targetNodes $targetNode
            }
            *createmark elems 2 -1
            lappend elemsCreated [hm_getmark elems 2]
        }
        set prevNode $node
    }
    eval *createmark nodes 1 $weldNodes
    *duplicatemark nodes 1
    *clearmarkall 1
    *clearmarkall 2
    set seamPath ""
    set seamCompSet ""
    ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
}

proc ::rgdlnkCnt::createSingle {args} {
    global weldTol
    global maxDia
    global currentComp
    global singleWithWasher
    if {$maxDia == 0 || $maxDia == ""} {set maxdia 99999} else {set maxdia $maxDia}

    set currentDisplayed [::rgdlnkCnt::viewClip]
    set elemsCreated ""
    variable singleNodes
    variable singleComps

    if {[Null singleNodes]} {
        tk_messageBox -title "错误" -message "未选择任何节点"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    } elseif {[Null singleComps]} {
        tk_messageBox -title "错误" -message "未选择任何部件"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    
    if {$weldTol == 0 || $weldTol == ""} {
        set tolorance 99999
    } else {
        set tolorance $weldTol
    }
    *clearmarkall 1
    set searchNodes ""
    set singleCompSet ""
    foreach id $singleComps {
        lappend singleCompSet [hm_getvalue comps id=$id dataname=name]
    }
    eval *createmark nodes 2 $singleNodes
    *appendmark nodes 2 "by face"
    eval *createmark elems 1 "by comps" $singleCompSet
    foreach node $singleNodes {
        set targetNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 1 2]
        eval *createmark nodes 1 $targetNode
        *findmark nodes 1 1 1 elements 0 2
        set elemNodes [hm_getvalue elems id=[lindex [hm_getmark elems 2] 0] dataname=nodes]
        set systNodes [lreplace $elemNodes [lsearch $elemNodes $targetNode] [lsearch $elemNodes $targetNode]]
        *systemcreate3nodes 0 $targetNode "x-axis" [lindex $systNodes 0] "xy-plane" [lindex $systNodes 1]
        set nsDist [lindex [hm_getdistance nodes $node $targetNode 1] 3]
        if {$nsDist <= $tolorance} {
            lappend searchNodes $node
        }
        *createmark systs 1 -1
        *deletemark systs 1
        *createmark systemcols 1 -1
        *deletemark systemcols 1
    }
    if {[Null searchNodes]} {
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    set searchComps ""
    foreach node $searchNodes {
        *createmark nodes 1 $node
        *findmark nodes 1 1 1 elements 0 2
        foreach elem [hm_getmark elems 2] {
            set elemComp [hm_getvalue elems id=$elem dataname=component.name]
            if {[lsearch $searchComps $elemComp] == -1} {
                append searchComps " " $elemComp
            }
        }
    }
    if {[Null searchComps]} {
        tk_messageBox -title "错误" -message "无法确定搜索范围, 请选择正确的点!"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    eval *createmark comps 1 $searchComps
    set holeInfo [hm_ce_gethmholes 1 $maxdia 0 1 0 1]
    if {$currentComp == 0} {
        if {![hm_entityinfo exist comp "spiders_autogenerate" -byname]} {
            *createentity comps name=RigidLink color=3
        }
        *currentcollector comps "spiders_autogenerate"
    }
    foreach group $holeInfo {
        foreach hole $group {
            set center [lindex $hole 0]
            set innerNodes [lindex $hole 1]
            set outterNodes [lindex $hole 2]
            set flg 0
            foreach node $searchNodes {
                if {[lsearch $innerNodes $node] > -1 || [lsearch $outterNodes $node] > -1} {
                    set flg 1
                }
            }
            if {$flg == 0} {
                continue
            } 
            *createnode [lindex $center 0] [lindex $center 1] [lindex $center 2]
            *createmark nodes 1 -1
            set tempNode [hm_getmark nodes 1]
            set holeNodes $innerNodes
            if {$singleWithWasher == 1} {
                append holeNodes " " $outterNodes
            }
            set singleTargetNodes $holeNodes
            eval *createmark nodes 2 $holeNodes
            *appendmark nodes 2 "by face"
            eval *createmark elems 2 "by comps" $singleCompSet
            foreach node $holeNodes {
                set tmpNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 2 2]
                if {[lsearch $singleTargetNodes $tmpNode] > -1} {
                    set dist1 [lindex [hm_getdistance nodes $node $tmpNode 0] 0]
                    eval *createmark nodes 1 $singleTargetNodes
                    set tmpNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 2 1]
                    set dist2 [lindex [hm_getdistance nodes $node $tmpNode 0] 0]
                    if {$dist2 <= [expr 1.3*$dist1]} {
                        lappend singleTargetNodes $tmpNode
                    }
                } else {
                    lappend singleTargetNodes $tmpNode
                }
            }
            if {[llength $singleTargetNodes] > [llength $holeNodes]} {
                eval *createmark nodes 2 $singleTargetNodes
                *rigidlinkinodecalandcreate 2 0 0 123456
                *createmark elems 2 -1
                lappend elemsCreated [hm_getmark elems 2]
            }
            *createmark nodes 1 $tempNode
            *nodemarkcleartempmark 1
            
        }
    }
    set singleNodes ""
    set singleComps ""
    set searchComps ""
    *clearmarkall 1
    *clearmarkall 2
    ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
}

proc ::rgdlnkCnt::createMultiple {args} {
    global currentComp
    global multipleWithWasher
    global maxDia
    global weldTol
    if {$maxDia == 0 || $maxDia == ""} {set maxdia 99999} else {set maxdia $maxDia}

    variable multipleComps1
    variable multipleComps2

    set currentDisplayed [::rgdlnkCnt::viewClip]
    set elemsCreated ""
    if {[Null multipleComps1]} {
        tk_messageBox -title "错误" -message "未选择任何部件"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    } elseif {[Null multipleComps2]} {
        tk_messageBox -title "错误" -message "未选择任何部件"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    if {$currentComp == 0} {
        if {![hm_entityinfo exist comp "spiders_autogenerate" -byname]} {
            *createentity comps name=RigidLink color=3
        }
        *currentcollector comps "spiders_autogenerate"
    }
    if {$weldTol == 0 || $weldTol == ""} {
        set tolorance 99999
    } else {
        set tolorance $weldTol
    }
    *clearmarkall 1
    *clearmarkall 2
    set multipleCompSet1 ""
    set multipleCompSet2 ""
    foreach id $multipleComps1 {
        lappend multipleCompSet1 [hm_getvalue comps id=$id dataname=name]
    }
    foreach id $multipleComps2 {
        lappend multipleCompSet2 [hm_getvalue comps id=$id dataname=name]
    }
    eval *createmark comps 1 $multipleCompSet1
    set holeInfo [hm_ce_gethmholes 1 $maxdia 0 1 0 1]
    foreach group $holeInfo {
        foreach hole $group {
            if {[llength $hole] <= 1} {
                continue
            }
            set center [lindex $hole 0]
            set innerNodes [lindex $hole 1]
            set outterNodes [lindex $hole 2]
            set holeNodes $innerNodes
            *createnode [lindex $center 0] [lindex $center 1] [lindex $center 2]
            *createmark nodes 1 -1
            set tempNode [hm_getmark nodes 1]
            if {$multipleWithWasher == 1} {
                append holeNodes " " $outterNodes
            }
            eval *createmark elems 1 "by comps" $multipleCompSet2
            eval *createmark nodes 1 $holeNodes
            *appendmark nodes 1 "by face"
            set targetNode [hm_getclosestnode [lindex $center 0] [lindex $center 1] [lindex $center 2] 1 1]
            *clearmarkall 1
            eval *createmark nodes 1 $targetNode
            *findmark nodes 1 1 1 elements 0 2
            set elemNodes [hm_getvalue elems id=[lindex [hm_getmark elems 2] 0] dataname=nodes]
            set systNodes [lreplace $elemNodes [lsearch $elemNodes $targetNode] [lsearch $elemNodes $targetNode]]
            *systemcreate3nodes 0 $targetNode "x-axis" [lindex $systNodes 0] "xy-plane" [lindex $systNodes 1]
            *createnode [lindex $center 0] [lindex $center 1] [lindex $center 2]
            *createmark nodes 1 -1
            set ssDist [lindex [hm_getdistance nodes [hm_getmark nodes 1] $targetNode 1] 3]
            *createmark nodes 1 -1
            *nodemarkcleartempmark 1
            *createmark systs 1 -1
            *deletemark systs 1
            *createmark systemcols 1 -1
            *deletemark systemcols 1
            if {$ssDist > $tolorance} {
                continue
            }
            set multipleTargetNodes $holeNodes
            eval *createmark nodes 1 $holeNodes
            *appendmark nodes 1 "by face"
            eval *createmark elems 1 "by comps" $multipleCompSet2
            foreach node $holeNodes {
                set tmpNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 1 1]
                if {[lsearch $multipleTargetNodes $tmpNode] > -1} {
                    set dist1 [lindex [hm_getdistance nodes $node $tmpNode 0] 0]
                    eval *createmark nodes 2 $multipleTargetNodes
                    set tmpNode [hm_getclosestnode [lindex [hm_nodevalue $node] 0 0] [lindex [hm_nodevalue $node] 0 1] [lindex [hm_nodevalue $node] 0 2] 1 2]
                    set dist2 [lindex [hm_getdistance nodes $node $tmpNode 0] 0]
                    if {$dist2 <= [expr 1.3*$dist1]} {
                        lappend multipleTargetNodes $tmpNode
                    }
                } else {
                    lappend multipleTargetNodes $tmpNode
                }
            }
            if {[llength $multipleTargetNodes] > [llength $holeNodes]} {
                *clearmarkall 2
                eval *createmark nodes 2 $multipleTargetNodes
                *rigidlinkinodecalandcreate 2 0 0 123456
                *createmark elems 2 -1
                lappend elemsCreated [hm_getmark elems 2]
            }
            *createmark nodes 1 $tempNode
            *nodemarkcleartempmark 1
        }
    }
    set multipleComps1 ""
    set multipleComps2 ""
    *clearmarkall 1
    *clearmarkall 2
    ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
}

proc ::rgdlnkCnt::elemsChk {args} {
    global rgdChkAllElems
    variable elemsToChk

    set currentDisplayed [::rgdlnkCnt::viewClip]
    set elemsCreated ""

    set chkElemLst ""
    if {$rgdChkAllElems == 1} {
        *createmark elems 1 "by config" 5
        *appendmark elems 1 "by config" 55
        set chkElemLst [hm_getmark elems 1]
    } else {
        foreach elem $elemsToChk {
            set cfg [hm_getvalue elems id=$elem dataname=config]
            if {$cfg == 5 || $cfg == 55} {
                lappend chkElemLst $elem
            }
        }
    }
    if {[Null chkElemLst]} {
        tk_messageBox -title "错误" -message "未选择任何单元!"
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    set elemsToSolve ""
    *clearmarkall 1
    *clearmarkall 2
    eval *createmark elems 1 $chkElemLst
    *elementtestdependancy elements 1 2
    set errElems [hm_getmark elems 2]
    *appendmark elems 2 "reverse"
    *maskentitymark elems 2
    *clearmarkall 1
    *clearmarkall 2
    foreach elem $errElems {
        eval *createmark elems 1 $elem
        *appendmark elems 1 "by attached"
        set group [lsort -decreasing [hm_getmark elems 1]]
        if {[lsearch $elemsToSolve $group] == -1} {
            lappend elemsToSolve $group
        }
    }
    if {[Null elemsToSolve]} {
        tk_messageBox -title "提示" -message "检查完毕!"
        *clearmarkall 1
        *clearmarkall 2
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    } elseif {[tk_messageBox -title "提示" -message "检测到部分单元存在连接错误,是否自动处理?" -type yesno] eq no} {
        *clearmarkall 1
        eval *createmark elems 1 $elemsToSolve
        if {[catch {*entitysetcreate "Failed_rigids" elems 1}]} {
            *appendmark elems 1 "by sets" "Failed_rigids"
            *createmark sets 1 "Failed_rigids"
            catch {*deletemark sets 1}
            *entitysetcreate "Failed_rigids" elems 1
        }
        tk_messageBox -title "提示" -message "已将错误单元保存在SET\"Failed_rigids\"中, 可自行处理。"
        *clearmarkall 1
        ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
        return
    }
    foreach group $elemsToSolve {
        *clearmarkall 1
        *clearmarkall 2
        set nset ""
        foreach elem $group {
            if {[hm_getvalue elems id=$elem dataname=config] == 55 && [hm_getvalue elems id=$elem dataname=nodecount] > 2} {
                append nset " " [hm_getvalue elems id=$elem dataname=dependentnodes]
            } else {
                append nset " " [hm_getvalue elems id=$elem dataname=nodes]
            }
        }
        eval *createmark nodes 1 $nset
        if {![hm_entityinfo exist "rigids_autocorrect" -byname]} {
            *createentity comps name="rigids_autocorrect" color=5
        }
        *currentcollector comps "rigids_autocorrect"
        *rigidlinkinodecalandcreate 1 0 0 123456
        *createmark elems 1 -1
        lappend elemsCreated [hm_getmark elems 1]
        eval *createmark elems 2 $group
        *deletemark elems 2
    }
    set elemsToChk ""
    *clearmarkall 1
    *clearmarkall 2
    ::rgdlnkCnt::viewRetrive $currentDisplayed $elemsCreated
}

proc ::rgdlnkCnt::pickElems {path var msg} {
    variable mainWindow
    variable $path
    set widgetPath [set $path]
    variable $var

    $widgetPath configure -state disable
    wm iconify $mainWindow
    focus .

    *clearmarkall 1
    *createmarkpanel elems 1 "$msg"
    set elemList [hm_getmark elems 1]
    *clearmarkall 1
    wm deiconify $mainWindow
    set $var $elemList
    $widgetPath configure -state active
    return $elemList
}

proc ::rgdlnkCnt::pickNodes {path var msg} {
    variable mainWindow
    variable $path
    set widgetPath [set $path]
    variable $var

    $widgetPath configure -state disable
    wm iconify $mainWindow
    focus .

    *clearmarkall 1
    *createmarkpanel nodes 1 "$msg"
    set nodesList [hm_getmark nodes 1]
    *clearmarkall 1
    wm deiconify $mainWindow
    set $var $nodesList
    $widgetPath configure -state active
    return $nodesList
}

proc ::rgdlnkCnt::pickComps {path var msg} {
    variable mainWindow
    variable $var
    variable $path
    set widgetPath [set $path]

    $widgetPath configure -state disable
    wm iconify $mainWindow
    focus .
    
    *clearmarkall 1
    *createmarkpanel comps 1 "$msg"
    set $var [hm_getmark comps 1]
    *clearmarkall 1
    wm deiconify $mainWindow
    $widgetPath configure -state active
    return [set $var]
}

proc ::rgdlnkCnt::viewClip {args} {
    
    *createmark elems 1 "displayed"
    return [hm_getmark elems 1]

}

proc ::rgdlnkCnt::viewRetrive {originalElems newElems} {

    *unmaskall2
    *clearmarkall 1
    *clearmarkall 2
    eval *createmark elems 1 $originalElems
    eval *appendmark elems 1 $newElems
    *appendmark elems 1 "reverse"
    *maskentitymark elems 1
    *clearmarkall 1
    *clearmarkall 2

}

::rgdlnkCnt::mainWindow;focus .rgdlnkMW