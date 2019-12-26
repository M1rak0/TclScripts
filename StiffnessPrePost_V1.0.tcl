# FILE NAME: StiffnessPrePost_V1.0.tcl
# DESCRIPTION: an automation tool for stiffness analysis including pre-process and post-process.
# INPUT: 
# OUTPUT: 
# AUTHOR:Ye Songkui & Lai Qibo @ XMKL
catch {namespace delete ::stiffness}
namespace eval ::stiffness {
    # begin local variables initializing
        set leftSide ""
        set rightSide ""
        set outputNodesLbl ""
        set suspConsLbl ""
        set bendNodesLbl ""
        set torsionNodesLbl ""
        set clrModelBtn ""
        set stiffnessMW ""
        set leftLoadLine ""
        set rightLoadLine ""
        set leftLoadLine ""
        set rightLoadLine ""
        set suspConsNodes ""
        set torsionResp ""
        set curvesPlot 0
        set genFlag 0
        set postFrm ""
        set importFrm ""
        set queryFrm ""
        set bendOutputLbl ""
        set bendOutputtail ""
        set torsionOutputLbl ""
        set torsionOutputtail ""
        set importBtn ""
        set queryBtn ""
        set plotBtn ""
        set bendOutputtxt ""
        set torsionOutputtxt ""
        set importEntry ""
    # end local variables initializing
}

# begin global variables initializing
    set bendStiffness 0.0
    set torsionStiffness 0.0
    set resultFilePath ""
# end global variables initializing

proc ::stiffness::mainWnd {args} {

    # begin variable quoting
        global   resultFilePath
        variable stiffnessMW
        variable bendStiffness
        variable torsionStiffness
        variable suspConsLbl
        variable bendNodesLbl
        variable outputNodesLbl
        variable torsionNodesLbl
        variable clrModelBtn
        variable postFrm 
        variable importFrm 
        variable queryFrm 
        variable bendOutputLbl 
        variable bendOutputtail 
        variable torsionOutputLbl 
        variable torsionOutputtail 
        variable importBtn 
        variable queryBtn 
        variable plotBtn 
        variable bendOutputtxt 
        variable torsionOutputtxt 
        variable importEntry 
    # end variable quoting

    # begin main window definition
        destroy .stiffnessMW
        set stiffnessMW [::hwtk::toplevel .stiffnessMW]

        wm title $stiffnessMW "整车刚度分析自动化工具V1.0"
        wm resizable $stiffnessMW 0 0
        catch {KeepOnTop $stiffnessMW}
    # end main window definition

    # begin widgets definition
        set parmFrm [::hwtk::frame $stiffnessMW.parmFrm]
            set preFrm [labelframe $parmFrm.preFrm -text "前处理" -font "times 10" -fg "blue" -relief "sunken"]
                set boundaryFrm [labelframe $preFrm.boundaryFrm -text "边界设置" -font "times 10" -fg "blue"]
                    set boundarySelFrm [::hwtk::frame $boundaryFrm.boundarySelFrm]
                        set suspConsLbl [label $boundarySelFrm.suspConsLbl -text "选择四轮约束点:" -font "times 10" -fg "red" -width 15]
                        set suspConsSel [button $boundarySelFrm.suspConsSel -text "选择节点" -font "times 10"\
                         -command {::stiffness::getSuspConsNodes} -width 13]
                        set suspConsClr [button $boundarySelFrm.suspConsClr -text "×" -font "times 10 bold"\
                         -command {::stiffness::rejectSelection suspConsLbl suspConsNodes} -width 2]
                        set bendNodesLbl [label $boundarySelFrm.bendNodesLbl -text "选择两侧加载点:" -font "times 10" -fg "red" -width 15]
                        set bendNodesSel [button $boundarySelFrm.bendNodesSel -text "选择节点" -font "times 10"\
                        -command {::stiffness::getBendingNodes} -width 13]
                        set bendNodesClr [button $boundarySelFrm.bendNodesClr -text "×" -font "times 10 bold"\
                         -command {::stiffness::rejectSelection bendNodesLbl leftLoadLine rightLoadLine} -width 2]
                set respFrm [labelframe $preFrm.respFrm -text "响应设置" -font "times 10" -fg "blue"]
                    set respBtnFrm [::hwtk::frame $respFrm.respBtnFrm]
                        set outputNodesLbl [label $respBtnFrm.outputNodesLbl -text "刚度曲线输出点:" -font "times 10" -fg "red" -width 15]
                        set outputNodesSel [button $respBtnFrm.outputNodesSel -text "选择节点" -font "times 10"\
                         -command {::stiffness::getBendingResp} -width 13]
                        set outputNodesClr [button $respBtnFrm.outputNodesClr -text "×" -font "times 10 bold"\
                         -command {::stiffness::rejectSelection outputNodesLbl leftSide rightSide} -width 2]
                        set torsionNodesLbl [label $respBtnFrm.torsionNodesLbl -text "扭转刚度响应点:" -font "times 10" -fg "red" -width 15]
                        set torsionNodesSel [button $respBtnFrm.torsionNodesSel -text "选择节点" -font "times 10"\
                         -command {::stiffness::getTorsionResp} -width 13]
                        set torsionNodesClr [button $respBtnFrm.torsionNodesClr -text "×" -font "times 10 bold"\
                         -command {::stiffness::rejectSelection torsionNodesLbl torsionResp} -width 2]
            set postFrm [labelframe $parmFrm.postFrm -text "后处理" -font "times 10" -fg "blue" -relief "sunken"]
                set importFrm [labelframe $postFrm.importFrm -text "导入模型" -font "times 10" -fg "blue"]
                    set importEntry [::hwtk::openfileentry $importFrm.importEntry -filetypes {{{OptiStruct Files} {"*.h3d"}} {{All Files} {"*.*"}}} -width 26 -textvariable resultFilePath -state readonly]
                set queryFrm [labelframe $postFrm.queryFrm -text "结果查询" -font "times 10" -fg "blue"]
                    set queryBtn [button $queryFrm.queryBtn -text "查询刚度数据" -font "times 10" -fg "blue"\
                     -command {::stiffness::resultQuery} -width 25]
                    set resOutputFrm [::hwtk::frame $queryFrm.resOutputFrm]
                        set bendOutputLbl [label $resOutputFrm.bendOutputLbl -text "弯曲刚度:" -font "times 10" -fg "blue" -justify left]
                        set bendOutputtxt [::hwtk::entry $resOutputFrm.bendOutputtxt -textvariable bendStiffness -justify right -width 8 -state readonly]
                        set bendOutputtail [label $resOutputFrm.bendOutputtail -text "N/mm." -font "times 10" -justify left]
                        set torsionOutputLbl [label $resOutputFrm.torsionOutputLbl -text "扭转刚度:" -font "times 10" -fg "blue" -justify left]
                        set torsionOutputtxt [::hwtk::entry $resOutputFrm.torsionOutputtxt -textvariable torsionStiffness -justify right -width 8 -state readonly]
                        set torsionOutputtail [label $resOutputFrm.torsionOutputtail -text "kN·m/rad." -font "times 10" -justify left]
                    set plotBtn [button $queryFrm.plotBtn -text "输出刚度曲线" -font "times 10" -fg "blue"\
                     -command {::stiffness::plot} -width 25]
        set funcFrm [::hwtk::frame $stiffnessMW.funcFrm]
            set clrModelBtn [button $funcFrm.clrModelBtn -text "清除所有边界条件" -font "times 10" -fg "red"\
             -command {::stiffness::modelInitialize} -width 20]
            set genModelBtn [button $funcFrm.genModelBtn -text "生成刚度分析模型" -font "times 10" -fg "black"\
             -command {::stiffness::genModel} -width 20]   
    # end widgets definition

    # begin main window layout
        grid $parmFrm -row 0 -column 0
            grid $preFrm -row 0 -column 0 -padx 2m -sticky ns
                grid $boundaryFrm -row 0 -column 0 -padx 1 -pady 2
                    grid $boundarySelFrm -row 0 -column 0 -padx 2
                        grid $suspConsLbl -row 0 -column 0
                        grid $suspConsSel -row 0 -column 1
                        grid $suspConsClr -row 0 -column 2 -pady 2
                        grid $bendNodesLbl -row 4 -column 0
                        grid $bendNodesSel -row 4 -column 1
                        grid $bendNodesClr -row 4 -column 2 -pady 2
                grid $respFrm -row 1 -column 0  -padx 1 -pady 1
                    grid $respBtnFrm -row 0 -column 0 -padx 2 -pady 1
                        grid $outputNodesLbl -row 0 -column 0
                        grid $outputNodesSel -row 0 -column 1
                        grid $outputNodesClr -row 0 -column 2
                        grid $torsionNodesLbl -row 1 -column 0
                        grid $torsionNodesSel -row 1 -column 1
                        grid $torsionNodesClr -row 1 -column 2 -pady 2
            grid $postFrm -row 0 -column 1 -padx 2m -sticky ns
                grid $importFrm -row 0 -padx 1 -sticky we
                    grid $importEntry -row 0 -column 0 -padx 1 -pady 1 -sticky we
                grid $queryFrm -row 1 -padx 1 
                    grid $queryBtn -row 0 -padx 1 -pady 1
                    grid $resOutputFrm -row 1 -padx 1 -pady 1
                        grid $bendOutputLbl -row 0 -column 0 
                        grid $bendOutputtxt -row 0 -column 1 -padx 4
                        grid $bendOutputtail -row 0 -column 2 -sticky e -pady 1
                        grid $torsionOutputLbl -row 1 -column 0 
                        grid $torsionOutputtxt -row 1 -column 1 -padx 4
                        grid $torsionOutputtail -row 1 -column 2 -sticky e -pady 1
                    grid $plotBtn -row 2 -padx 1 -pady 1
        grid $funcFrm -row 1 -column 0 -sticky we
            pack $genModelBtn -side right -padx 9 -pady 9
            pack $clrModelBtn -side right -pady 9
    # end main window layout
}

# pre-process
proc ::stiffness::modelInitialize {args} {
    variable stiffnessMW
    variable clrModelBtn
    *clearmarkall 1
    *createmark loadcols 1 "all"
    *createmark loadsteps 1 "all"
    if {[llength [hm_getmark loadcols 1]] || [llength [hm_getmark loadsteps 1]]} {
        if {[tk_messageBox -icon warning -message "是否删除模型原有的所有工况信息?" -parent $stiffnessMW -title "确认" -type yesno] eq "yes"} {
            $clrModelBtn configure -fg "red"
            catch {*deletemark loadcols 1}
            catch {*deletemark loadsteps 1}
            *clearmarkall 1
            tk_messageBox -message "模型初始化成功！" -title "提示" -parent $stiffnessMW
            $clrModelBtn configure -fg "blue"
        }
    } else {
        tk_messageBox -message "模型无需初始化！" -title "提示" -parent $stiffnessMW
        $clrModelBtn configure -fg "blue"
    }
    focus $stiffnessMW
}

proc ::stiffness::rejectSelection {labelName args} {
    variable $labelName
    set labelPath [set $labelName]
    $labelPath configure -fg "red"
    foreach arg $args {
        catch {
            variable $arg
            unset $arg
        }
    }
    *clearmarkall 1
    *clearmarkall 2
}

proc ::stiffness::getBendingResp {args} {

    variable stiffnessMW
    variable outputNodesLbl
    variable leftSide
    variable rightSide
    set flag 1

    wm iconify $stiffnessMW
    focus .
    $outputNodesLbl configure -fg "red"
    *clearmarkall 1
    *createlistbypathpanel nodes 1 "请在车架左侧选择刚度曲线输出点."
    set leftSide [hm_getlist nodes 1]
    set flag [expr $flag * [llength $leftSide]]
    *clearmarkall 1
    *createlistbypathpanel nodes 1 "请在车架右侧选择刚度曲线输出点."
    set rightSide [hm_getlist nodes 1]
    set flag [expr $flag * [llength $rightSide]]
    *clearmarkall 1


    *createmark nodes 1 30000001-32000000
    catch {*renumbersolverid nodes 1 40000001 1 0 0 0 0 0}
    if {$flag == 0} {
        tk_messageBox -message "未正确选择刚度曲线输出点, 请重新操作." -title "提示" -parent $stiffnessMW
    } else {
        if {[hm_getvalue nodes id=[lindex $leftSide 0] dataname=globaly] > [hm_getvalue nodes id=[lindex $rightSide 0] dataname=globaly]} {
            set tmp $leftSide
            set leftSide $rightSide
            set rightSide $tmp 
            unset tmp
        }
        *clearmarkall 1
        *createmark sets 1 "LeftSide" "RightSide"
        catch {*deletemark sets 1}
        hm_createmark nodes 1 $leftSide
        *renumbersolverid nodes 1 30000001 1 0 0 0 0 0
        *entitysetcreate "LeftSide" nodes 1
        *clearmarkall 1
        hm_createmark nodes 1 $rightSide
        *renumbersolverid nodes 1 31000001 1 0 0 0 0 0
        *entitysetcreate "RightSide" nodes 1
        *clearmarkall 1
        $outputNodesLbl configure -fg "blue"
    }
    wm deiconify $stiffnessMW
    focus $stiffnessMW
}

proc ::stiffness::getTorsionResp {args} {
    variable stiffnessMW
    variable torsionResp
    variable torsionNodesLbl

    $torsionNodesLbl configure -fg "red"
    *clearmarkall 1
    *createmark nodes 1 32000001-32000004
    catch {*renumbersolverid nodes 1 40000001 1 0 0 0 0 0}
    *clearmarkall 1
    set torsionResp [list ]
    set pickedNodes [::stiffness::pickNodes "请选择四个扭转刚度响应点."]
    foreach node $pickedNodes {
        if {[hm_getvalue nodes id=$node dataname=globalx] < 2000 && [hm_getvalue nodes id=$node dataname=globaly] < 0} {
            set flrespNode $node
        } elseif {[hm_getvalue nodes id=$node dataname=globalx] < 2000 && [hm_getvalue nodes id=$node dataname=globaly] > 0} {
            set frrespNode $node
        } elseif {[hm_getvalue nodes id=$node dataname=globalx] > 2000 && [hm_getvalue nodes id=$node dataname=globaly] < 0} {
            set rlrespNode $node
        } else {
            set rrrespNode $node
        }
    }
    catch {set torsionResp [list $flrespNode $frrespNode $rlrespNode $rrrespNode]}
    hm_createmark nodes 1 $torsionResp
    *createmark sets 1 "TorsionResponseNodes"
    catch {*deletemark sets 1}
    *entitysetcreate "TorsionResponseNodes" nodes 1
    if {[llength $torsionResp] != 4} {
        tk_messageBox -title "错误" -icon error -message "响应点选取错误, 必须选取四个扭转刚度响应点." -parent $stiffnessMW
        set torsionResp [list ]
        $torsionNodesLbl configure -fg "red"
    } else {
        *clearmarkall 1
        hm_createmark nodes 1 [lindex $torsionResp 0]
        *renumbersolverid nodes 1 32000001 1 0 0 0 0 0
        hm_createmark nodes 1 [lindex $torsionResp 1]
        *renumbersolverid nodes 1 32000002 1 0 0 0 0 0
        hm_createmark nodes 1 [lindex $torsionResp 2]
        *renumbersolverid nodes 1 32000003 1 0 0 0 0 0
        hm_createmark nodes 1 [lindex $torsionResp 3]
        *renumbersolverid nodes 1 32000004 1 0 0 0 0 0
        $torsionNodesLbl configure -fg "blue"
    }
}

proc ::stiffness::pickNodes {msg} {
    variable stiffnessMW 
    wm iconify $stiffnessMW
    focus .
    *clearmarkall 1
    *createmarkpanel nodes 1 "$msg"
    set nodesList [hm_getmark nodes 1]
    *clearmarkall 1
    wm deiconify $stiffnessMW
    return $nodesList
}

proc ::stiffness::chooseList {args} {
    return [list "1000" "2000"]
}

proc ::stiffness::getBendingNodes {args} {
    variable stiffnessMW
    variable leftLoadLine
    variable rightLoadLine
    variable bendNodesLbl
    variable leftLoadLine
    variable rightLoadLine

    $bendNodesLbl configure -fg "red"
    set loadLength [::hwtk::inputdialog -title "参数设置" -text "请选择加载长度:" \
     -inputtype combobox -initialvalue "1000" -valuelistcommand ::stiffness::chooseList -x [expr [winfo rootx $stiffnessMW]+550] -y [winfo rooty $stiffnessMW]]
    if {$loadLength eq ""} {
        $bendNodesLbl configure -fg "red"
        focus $stiffnessMW
        return
    } elseif {$loadLength <= 1000} {
        set halfLoadLength 500
    } else {
        set halfLoadLength 1000
    }
    set msg "请在车架左右两侧各选择一个节点."
    set loadNodes [::stiffness::pickNodes $msg]
    if {[llength $loadNodes] != 2} {
        tk_messageBox -icon error -title "错误" -message "加载点选择错误, 请在车架左右两侧各选择一个节点 !" -parent $stiffnessMW
        $bendNodesLbl configure -fg "red"
        focus $stiffnessMW
        return
    } else {
        # assigning the node on the left to variable "left", the node on the right to variable "right".
        if {[lindex [hm_nodevalue [lindex $loadNodes 0]] 0 1] > [lindex [hm_nodevalue [lindex $loadNodes 1]] 0 1]} {
            set leftBase [lindex $loadNodes 1]
            set rightBase [lindex $loadNodes 0]
        } elseif {[lindex [hm_nodevalue [lindex $loadNodes 0]] 0 1] < [lindex [hm_nodevalue [lindex $loadNodes 1]] 0 1]} {
            set leftBase [lindex $loadNodes 0]
            set rightBase [lindex $loadNodes 1]
        } else {
            tk_messageBox -title "错误" -icon "error" -message "加载点选择错误, 请在车架左右两侧各选择一个节点 !" -parent $stiffnessMW
            $bendNodesLbl configure -fg "red"
            focus $stiffnessMW
            return
        }
    }

    *clearmarkall 1
    set extendMethod "by face"
    hm_createmark nodes 1 [list $leftBase $rightBase]
    *findmark nodes 1 1 1 elements 0 2
    foreach elem [hm_getmark elems 2] {
        if {[hm_getvalue elems id=$elem dataname=config] == 60} {
            set extendMethod "displayed"
        }
    }
    unset elem
    
    *clearmarkall 1
    hm_createmark nodes 1 $leftBase
    *appendmark nodes 1 "by face"
    *appendmark nodes 1 "by face"
    set leftFace [hm_getmark nodes 1]
    *clearmarkall 1
    hm_createmark nodes 1 $rightBase
    *appendmark nodes 1 "by face"
    *appendmark nodes 1 "by face"
    set rightFace [hm_getmark nodes 1]
    *clearmarkall 1
    
    set leftLoadLine [list ]
    set rigidNodes [list ]
    foreach node $leftFace {
        # if a node in the base face has a distance that smaller than 3 in y&z direction,
        # and in the loading range, it will be picked.
        if {[expr abs([lindex [hm_getdistance nodes $node $leftBase 0] 2])] < 3 &&\
            [expr abs([lindex [hm_getdistance nodes $node $leftBase 0] 3])] < 3 &&\
            [expr abs([lindex [hm_getdistance nodes $node $leftBase 0] 0])] <= $halfLoadLength} {
            lappend leftLoadLine $node
        }
    }
    # reject nodes those connected to any rigid elements
    hm_createmark nodes 1 $leftLoadLine
    *findmark nodes 1 1 1 elements 0 2
    foreach elem [hm_getmark elems 2] {
        if {[hm_getvalue elems id=$elem dataname=config] == 5 || [hm_getvalue elems id=$elem dataname=config] == 55} {
            append rigidNodes [hm_getvalue elems id=$elem dataname=nodes] " "
        }
    }
    set rightLoadLine [list ]
    foreach node $rightFace {
        if {[expr abs([lindex [hm_getdistance nodes $node $rightBase 0] 2])] < 3 &&\
            [expr abs([lindex [hm_getdistance nodes $node $rightBase 0] 3])] < 3 &&\
            [expr abs([lindex [hm_getdistance nodes $node $rightBase 0] 0])] <= $halfLoadLength} {
            lappend rightLoadLine $node
        }
    }
    hm_createmark nodes 1 $rightLoadLine
    *findmark nodes 1 1 1 elements 0 2
    foreach elem [hm_getmark elems 2] {
        if {[hm_getvalue elems id=$elem dataname=config] == 5 || [hm_getvalue elems id=$elem dataname=config] == 55} {
            append rigidNodes [hm_getvalue elems id=$elem dataname=nodes] " "
        }
    }
    foreach node $rigidNodes {
        set leftLoadLine [lreplace $leftLoadLine [lsearch $leftLoadLine $node] [lsearch $leftLoadLine $node]]
        set rightLoadLine [lreplace $rightLoadLine [lsearch $rightLoadLine $node] [lsearch $rightLoadLine $node]]
    }
    $bendNodesLbl configure -fg "blue"
    focus $stiffnessMW
}

proc ::stiffness::getSuspConsNodes {args} {
    variable stiffnessMW
    variable suspConsLbl
    variable suspConsNodes

    $suspConsLbl configure -fg "red"
    set suspConsNodes [list ]
    set pickedNodes [::stiffness::pickNodes "请分别在四轮处各选择一个约束点."]
    foreach node $pickedNodes {
        if {[hm_getvalue nodes id=$node dataname=globalx] < 2000 && [hm_getvalue nodes id=$node dataname=globaly] < 0} {
            set flSuspNode $node
        } elseif {[hm_getvalue nodes id=$node dataname=globalx] < 2000 && [hm_getvalue nodes id=$node dataname=globaly] > 0} {
            set frSuspNode $node
        } elseif {[hm_getvalue nodes id=$node dataname=globalx] > 2000 && [hm_getvalue nodes id=$node dataname=globaly] < 0} {
            set rlSuspNode $node
        } else {
            set rrSuspNode $node
        }
    }
    catch {set suspConsNodes [list $flSuspNode $frSuspNode $rlSuspNode $rrSuspNode]}
    if {[llength $suspConsNodes] != 4} {
        tk_messageBox -title "错误" -icon error -message "约束点选取错误, 请分别在四轮处各选择一个约束点." -parent $stiffnessMW
        set suspConsNodes [list ]
        $suspConsLbl configure -fg "red"
    } else {
        *clearmarkall 1 
        hm_createmark nodes 1 $suspConsNodes
        *duplicatemark nodes 1
        $suspConsLbl configure -fg "blue"
        *clearmarkall 1
    }
    focus $stiffnessMW
}

proc ::stiffness::createBendingSPC {args} {
    variable suspConsNodes

    catch {*collectorcreate loadcols "Bending_SPC" "" 5}
    *currentcollector loadcols "Bending_SPC"

    # FL
	hm_createmark nodes 1  [lindex $suspConsNodes 0]
	*loadcreateonentity nodes 1 3 1 -999999 0 0 -999999 -999999 -999999
    # FR
	hm_createmark nodes 1  [lindex $suspConsNodes 1]
	*loadcreateonentity nodes 1 3 1 -999999 -999999 0 -999999 -999999 -999999
    # RL
    hm_createmark nodes 1  [lindex $suspConsNodes 2]
	*loadcreateonentity nodes 1 3 1 0 0 0 -999999 -999999 -999999
    # RR
	hm_createmark nodes 1  [lindex $suspConsNodes 3]
	*loadcreateonentity nodes 1 3 1 0 -999999 0 -999999 -999999 -999999
}

proc ::stiffness::createBendingLoad {args} {
    variable leftLoadLine
    variable rightLoadLine

    catch {*collectorcreate loadcols "Bending_load" "" 5}
    *currentcollector loadcols "Bending_load"
    
    foreach loadline [list $leftLoadLine $rightLoadLine] {
        *clearmarkall 1      
        hm_createmark nodes 1 $loadline
        set loadMag [format "%.4f" [expr -1000.0/[llength $loadline]]]
        *loadcreateonentity_curve nodes 1 1 1 0 0 $loadMag 0 0 $loadMag 0 0 0 0 0
        *clearmarkall 1      
    }
}

proc ::stiffness::createBendingLoadStep {args} {
    catch {*createentity loadsteps name="Bending"}
    *setvalue loadsteps name="Bending" STATUS=2 OS_TYPE=0
    *setvalue loadsteps name="Bending" 4709=1 STATUS=1
    *setvalue loadsteps name="Bending" STATUS=2 4059=1
    *setvalue loadsteps name="Bending" STATUS=2 4060=STATIC
    *setvalue loadsteps name="Bending" 707=0 STATUS=0
    *setvalue loadsteps name="Bending" STATUS=2 3240=1
    *setvalue loadsteps name="Bending" STATUS=2 289=0
    *setvalue loadsteps name="Bending" STATUS=2 288=0
    *setvalue loadsteps name="Bending" STATUS=2 4347=0
    *setvalue loadsteps name="Bending" STATUS=2 4034=0
    *setvalue loadsteps name="Bending" STATUS=2 4037=0
    *setvalue loadsteps name="Bending" STATUS=2 9891=0
    *setvalue loadsteps name="Bending" STATUS=2 10701=0
    *setvalue loadsteps name="Bending" STATUS=2 8142=0
    *setvalue loadsteps name="Bending" STATUS=2 4722=0
    *setvalue loadsteps name="Bending" STATUS=2 3391=0
    *setvalue loadsteps name="Bending" STATUS=2 3396=0
    *setvalue loadsteps name="Bending" STATUS=2 7408=0
    *setvalue loadsteps name="Bending" STATUS=2 8897=0
    *setvalue loadsteps name="Bending" STATUS=2 4152=0
    *setvalue loadsteps name="Bending" STATUS=2 4973=0
    *setvalue loadsteps name="Bending" STATUS=2 351=0
    *setvalue loadsteps name="Bending" STATUS=2 3292=0
    *setvalue loadsteps name="Bending" STATUS=2 OS_SPCID={loadcols [hm_getvalue loadcols name="Bending_SPC" dataname=id]}
    *setvalue loadsteps name="Bending" STATUS=2 4143=1
    *setvalue loadsteps name="Bending" 4144=1 STATUS=1
    *setvalue loadsteps name="Bending" 4145={Loadcols [hm_getvalue loadcols name="Bending_SPC" dataname=id]} STATUS=1
    *setvalue loadsteps name="Bending" STATUS=2 OS_LOADID={loadcols [hm_getvalue loadcols name="Bending_load" dataname=id]}
    *setvalue loadsteps name="Bending" STATUS=2 4143=1
    *setvalue loadsteps name="Bending" 4146=1 STATUS=1
    *setvalue loadsteps name="Bending" 4147={Loadcols [hm_getvalue loadcols name="Bending_load" dataname=id]} STATUS=1
    *setvalue loadsteps name="Bending" 7763=0 STATUS=0
    *setvalue loadsteps name="Bending" 7740={Loadcols 0} STATUS=0
}

proc ::stiffness::createTorsionBoundary {args} {
    variable suspConsNodes

    # create MPC
    catch {*collectorcreate loadcols "Torsion_MPC" "" 3}
    *currentcollector loadcols "Torsion_MPC"
    set flConsNode [lindex $suspConsNodes 0]
    set frConsNode [lindex $suspConsNodes 1]
    set mpcLength [lindex [hm_getdistance nodes $flConsNode $frConsNode 0] 2]
    *clearmarkall 1
    hm_createmark nodes 1 $flConsNode
    *createarray 1  4
    *createdoublearray 6  1 1 1 1 1 1
    *equationcreate 1 1 1 1 6 $frConsNode 3 1 0
    *clearmarkall 1

    # create SPC
    catch {*collectorcreate loadcols "Torsion_SPC" "" 3}
    *currentcollector loadcols "Torsion_SPC"
    hm_createmark nodes 1 [lindex $suspConsNodes 2]
    *loadcreateonentity nodes 1 3 1 0 0 0 -999999 -999999 -999999
    *clearmarkall 1
    hm_createmark nodes 1 [lindex $suspConsNodes 3]
    *loadcreateonentity nodes 1 3 1 0 -999999 0 -999999 -999999 -999999
    *clearmarkall 1

    # create force
    catch {*collectorcreate loadcols "Torsion_Force" "" 3}
    *currentcollector loadcols "Torsion_Force"
    set torsionForce [format "%.4f" [expr 2000000*2.0/$mpcLength]]
    *createmark nodes 2 $frConsNode
	*loadcreateonentity_curve nodes 2 1 1 0 0 $torsionForce 0 0 $torsionForce 0 0 0 0 0
}

proc ::stiffness::createTorsionLoadStep {args} {
    catch {*createentity loadsteps name="Torsion"}
    *setvalue loadsteps name="Torsion" STATUS=2 OS_TYPE=0
    *setvalue loadsteps name="Torsion" 4709=1 STATUS=1
    *setvalue loadsteps name="Torsion" STATUS=2 4059=1
    *setvalue loadsteps name="Torsion" STATUS=2 4060=STATIC
    *setvalue loadsteps name="Torsion" 707=0 STATUS=0
    *setvalue loadsteps name="Torsion" STATUS=2 3240=1
    *setvalue loadsteps name="Torsion" STATUS=2 289=0
    *setvalue loadsteps name="Torsion" STATUS=2 288=0
    *setvalue loadsteps name="Torsion" STATUS=2 4347=0
    *setvalue loadsteps name="Torsion" STATUS=2 4034=0
    *setvalue loadsteps name="Torsion" STATUS=2 4037=0
    *setvalue loadsteps name="Torsion" STATUS=2 9891=0
    *setvalue loadsteps name="Torsion" STATUS=2 10701=0
    *setvalue loadsteps name="Torsion" STATUS=2 8142=0
    *setvalue loadsteps name="Torsion" STATUS=2 4722=0
    *setvalue loadsteps name="Torsion" STATUS=2 3391=0
    *setvalue loadsteps name="Torsion" STATUS=2 3396=0
    *setvalue loadsteps name="Torsion" STATUS=2 7408=0
    *setvalue loadsteps name="Torsion" STATUS=2 8897=0
    *setvalue loadsteps name="Torsion" STATUS=2 4152=0
    *setvalue loadsteps name="Torsion" STATUS=2 4973=0
    *setvalue loadsteps name="Torsion" STATUS=2 351=0
    *setvalue loadsteps name="Torsion" STATUS=2 3292=0
    *setvalue loadsteps name="Torsion" STATUS=2 OS_SPCID={loadcols [hm_getvalue loadcols name="Torsion_SPC" dataname=id]}
    *setvalue loadsteps name="Torsion" STATUS=2 4143=1
    *setvalue loadsteps name="Torsion" 4144=1 STATUS=1
    *setvalue loadsteps name="Torsion" 4145={Loadcols [hm_getvalue loadcols name="Torsion_SPC" dataname=id]} STATUS=1
    *setvalue loadsteps name="Torsion" STATUS=2 OS_MPCID={loadcols [hm_getvalue loadcols name="Torsion_MPC" dataname=id]}
    *setvalue loadsteps name="Torsion" STATUS=2 4143=1
    *setvalue loadsteps name="Torsion" 4148=1 STATUS=1
    *setvalue loadsteps name="Torsion" 4149={Loadcols [hm_getvalue loadcols name="Torsion_MPC" dataname=id]} STATUS=1
    *setvalue loadsteps name="Torsion" STATUS=2 OS_LOADID={loadcols [hm_getvalue loadcols name="Torsion_Force" dataname=id]}
    *setvalue loadsteps name="Torsion" STATUS=2 4143=1
    *setvalue loadsteps name="Torsion" 4146=1 STATUS=1
    *setvalue loadsteps name="Torsion" 4147={Loadcols [hm_getvalue loadcols name="Torsion_Force" dataname=id]} STATUS=1
    *setvalue loadsteps name="Torsion" 7763=0 STATUS=0
    *setvalue loadsteps name="Torsion" 7740={Loadcols 0} STATUS=0
}

proc ::stiffness::feExport {args} {
    global resultFilePath
    variable stiffnessMW

    set exportPath [tk_getSaveFile -filetypes "{{OptiStruct files} {*.fem *.parm}} {{All Files} {*.*}}" -title "请选择有限元模型保存路径"]
    if {$exportPath == ""} {
        tk_messageBox -title "错误" -icon "error" -message "所选路径不正确, 无法自动导出, 请手动导出计算文件 !" -parent $stiffnessMW
        return
    } elseif {[file extension $exportPath] == ""} {
        append exportPath ".fem"
    } elseif {[file extension $exportPath] != ".fem" && [file extension $exportPath] != ".parm"} {
        tk_messageBox -title "错误" -icon "error" -message "文件扩展名必须为\".fem\"或者\".parm\" !" -parent $stiffnessMW
        return
    }
    *retainmarkselections 0
    *createstringarray 3 "HM_NODEELEMS_SET_COMPRESS_SKIP " "EXPORT_SYSTEM_LONGFORMAT " "HMBOMCOMMENTS_XML"
    set tmpDir [hm_info -appinfo ALTAIR_HOME]/templates/feoutput/optistruct/optistruct
    # append tmpDir "/templates/feoutput/optistruct/optistruct"
    hm_answernext yes
    *feoutputwithdata "$tmpDir" "$exportPath" 0 0 2 1 3
    set resultFilePath "[lindex [split $exportPath "."] 0].h3d"
    focus $stiffnessMW
}

proc ::stiffness::genModel {args} {
    variable stiffnessMW
    variable outputNodesLbl
    variable suspConsLbl
    variable bendNodesLbl
    variable torsionNodesLbl
    variable genFlag

    set genLock 0
    puts $genFlag
    foreach labelPath [list $outputNodesLbl $suspConsLbl $bendNodesLbl $torsionNodesLbl] {
        if {[$labelPath cget -fg] eq "red"} {
            set genLock 1
        }
    }
    if {$genLock == 1} {
        tk_messageBox -title "提示" -message "请先完成前处理设置 ！" -parent $stiffnessMW
        focus $stiffnessMW
        return
    } elseif {$genFlag == 0} {
        *nodecleartempmark 
        ::stiffness::createBendingSPC
        ::stiffness::createBendingLoad
        ::stiffness::createBendingLoadStep
        ::stiffness::createTorsionBoundary
        ::stiffness::createTorsionLoadStep
        if {[tk_messageBox -title "提示" -message "模型设置成功 ！是否需要直接生成计算文件 ?" -parent $stiffnessMW -type yesno] eq yes} {
            ::stiffness::feExport
        }
        focus $stiffnessMW
        set genFlag 1
    } elseif {$genFlag == 1} {
        tk_messageBox -title "提示" -message "请勿重复设置 ！" -parent $stiffnessMW
        focus $stiffnessMW
    }
}

# post-precess
proc ::stiffness::importResult {FilePath} {
    variable stiffnessMW
    hwi OpenStack
        if {$FilePath == "" || ![string match -nocase [file extension $FilePath] ".h3d"]} {
            hwi CloseStack
            tk_messageBox -icon error -title "错误" -message "请选择正确的结果文件 ！" -parent $stiffnessMW
            focus $stiffnessMW
            return
        }
        set t [clock milliseconds]
        hwi GetSessionHandle sess$t$t
        sess$t$t GetProjectHandle proj$t$t    
        proj$t$t GetPageHandle page$t [proj$t$t GetActivePage]
        page$t SetLayout 3
        page$t SetActiveWindow 1
        page$t GetWindowHandle win1$t 1
        page$t GetWindowHandle win2$t 2
        page$t GetWindowHandle win3$t 3
        win1$t SetClientType "Animation"
        catch {win2$t SetClientType "Plot"}
        catch {win3$t SetClientType "Plot"}
        win1$t GetClientHandle anim$t
        anim$t Clear
        set modelID [anim$t AddModel $FilePath]
        anim$t GetModelHandle mod$t $modelID
        mod$t  SetResult [file root $FilePath].h3d
        mod$t  GetResultCtrlHandle r$t
        r$t SetCurrentSubcase 0
        anim$t Draw
    hwi CloseStack
}

proc ::stiffness::getBendingStiffness {args} {
    global resultFilePath
    global bendStiffness 

    set resultFileDir [file dirname $resultFilePath]

    hwi OpenStack
        set t [clock milliseconds]
        hwi GetSessionHandle sess$t$t
        sess$t$t GetProjectHandle proj$t$t
        proj$t$t GetPageHandle page$t [proj$t$t GetActivePage]
        page$t GetWindowHandle win$t [page$t GetActiveWindow]
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        model$t GetResultCtrlHandle result$t
        result$t SetCurrentSubcase 1
        result$t GetContourCtrlHandle contour$t
        contour$t SetDataType "Displacement"
        contour$t SetDataComponent z
        contour$t SetEnableState true
        client$t Draw
    hwi CloseStack

    # write "Bending_Left.txt"
    set bendingLeftFileChanel [open "$resultFileDir/Bending_Left.txt" w]
    hwi OpenStack 
        set t [clock milliseconds]
        hwi GetSessionHandle sess$t$t
        sess$t$t GetProjectHandle proj$t$t
        set pageindex [proj$t$t GetActivePage]
        proj$t$t GetPageHandle page$t $pageindex
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "NodeBL"
        set$t Add "id 30000001-31000000"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        iter$t First
        set disp(id) {}
        while {[iter$t Valid]== "true"} {
            set resp111 [iter$t GetDataList]
                if {[lsearch -exact $disp(id) [lindex $resp111 0]]<0} {
                    lappend disp(id) [lindex $resp111 0]
                    lappend disp(xcoord) [lindex [lindex $resp111 1] 0]		
                    lappend disp([lindex [lindex $resp111 1] 0]) [lindex $resp111 2]
                    lappend bendlt(z) [lindex $resp111 2]
                    lappend bendlt([lindex $resp111 2]) [lindex $resp111 0]
                }
            iter$t Next
        }
        foreach i [lsort -real -increasing $disp(xcoord)] {
            puts -nonewline $bendingLeftFileChanel "$i\t"
            puts -nonewline $bendingLeftFileChanel " "
            puts $bendingLeftFileChanel $disp($i)
        }
        set minlz [lindex [lsort -real -increasing $bendlt(z)] 0]
        set minlid [lindex $bendlt($minlz) 0]
        catch {unset disp}
        catch {unset bendlt}
        close $bendingLeftFileChanel
    hwi CloseStack

    # write "Bending_Right.txt"
    set bendingRightFileChanel [open "$resultFileDir/Bending_Right.txt" w] 
    hwi OpenStack 
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "NodeBR"
        set$t Add "id 31000001-32000000"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        iter$t First
        set disp(id) {}
        while {[iter$t Valid]== "true"} {
            set resp111 [iter$t GetDataList]
                if {[lsearch -exact $disp(id) [lindex $resp111 0]]<0} {
                    lappend disp(id) [lindex $resp111 0]
                    lappend disp(xcoord) [lindex [lindex $resp111 1] 0]		
                    lappend disp([lindex [lindex $resp111 1] 0]) [lindex $resp111 2]
                    lappend bendrt(z) [lindex $resp111 2]
                    lappend bendrt([lindex $resp111 2]) [lindex $resp111 0]		
                }
            iter$t Next
        }
        foreach i [lsort -real -increasing $disp(xcoord)] {
            puts -nonewline $bendingRightFileChanel "$i\t"
            puts -nonewline $bendingRightFileChanel " "
            puts $bendingRightFileChanel $disp($i)
        }
        set minrz [lindex [lsort -real -increasing $bendrt(z)] 0]
        set minrid [lindex $bendrt($minrz) 0]
        catch {unset disp}
        catch {unset bendlt}
        close $bendingRightFileChanel
    hwi CloseStack

    # calculate bending stiffness
    set bendStiffness [format "%.1f" [expr 2000/(abs($minlz) + abs($minrz))*2]]
}

proc ::stiffness::getTorsionStiffness {args} {
    global resultFilePath
    global torsionStiffness

    hwi OpenStack
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t
        sess$t$t GetProjectHandle proj$t$t
        proj$t$t GetPageHandle page$t [proj$t$t GetActivePage]
        page$t GetWindowHandle win$t [page$t GetActiveWindow]
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        model$t GetResultCtrlHandle result$t
        result$t SetCurrentSubcase 2
        result$t GetContourCtrlHandle contour$t
        contour$t SetDataType "Displacement"
        contour$t SetDataComponent z
        contour$t SetEnableState true
        client$t Draw
    hwi CloseStack 

    set resp1 ""
    set resp2 ""
    set resp3 ""
    set resp4 ""
    hwi OpenStack 
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "Node5"
        set$t Add "id 32000001"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        set resp1 [iter$t GetDataList]
        set d_xCoord2 [lindex $resp1 2]
    hwi CloseStack

    hwi OpenStack 
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "Node6"
        set$t Add "id 32000002"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        set resp2 [iter$t GetDataList]
        set d_yCoord2 [lindex $resp2 2]
    hwi CloseStack

    hwi OpenStack 
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "Node7"
        set$t Add "id 32000003"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        set resp3 [iter$t GetDataList]
    hwi CloseStack

    hwi OpenStack 
    set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "Node8"
        set$t Add "id 32000004"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        set resp4 [iter$t GetDataList]
    hwi CloseStack

    # write "Torsion_Left.txt"
    set resultFileDir [file dirname $resultFilePath]
    set torsionLeftFileChanel [open "$resultFileDir/Torsion_Left.txt" w] 
    hwi OpenStack 
    set t [clock milliseconds] 
    hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "NodeTL"
        set$t Add "id 30000001-31000000"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        iter$t First
        set disp(id) {}
        while {[iter$t Valid]== "true"} {
            set resp111 [iter$t GetDataList]
                if {[lsearch -exact $disp(id) [lindex $resp111 0]]<0} {
                    lappend disp(id) [lindex $resp111 0]
                    lappend disp(xcoord) [lindex [lindex $resp111 1] 0]		
                    lappend disp([lindex [lindex $resp111 1] 0]) [lindex $resp111 2]				
                }
            iter$t Next
        }
        foreach i [lsort -real -increasing $disp(xcoord)] {
            puts -nonewline $torsionLeftFileChanel "$i\t"
            puts -nonewline $torsionLeftFileChanel " "
            puts $torsionLeftFileChanel $disp($i)
        }
        unset disp
        close $torsionLeftFileChanel
    hwi CloseStack

    # write "Torsion_Right.txt"
    set torsionRightFileChanel [open "$resultFileDir/Torsion_Right.txt" w] 
    hwi OpenStack 
        set t [clock milliseconds] 
        hwi GetSessionHandle sess$t$t 
        sess$t$t GetProjectHandle proj$t$t 
        set pageindex [proj$t$t GetActivePage] 
        proj$t$t GetPageHandle page$t $pageindex 
        page$t GetWindowHandle win$t [page$t GetActiveWindow] 
        win$t GetClientHandle client$t
        client$t GetModelHandle model$t [client$t GetActiveModel]
        set id [model$t AddSelectionSet node]
        model$t GetSelectionSetHandle set$t $id
        set$t SetLabel "NodeTR"
        set$t Add "id 31000001-32000000"
        model$t GetQueryCtrlHandle query$t
        query$t SetQuery "node.id node.coords contour.value"
        query$t SetSelectionSet [set$t GetID]
        query$t GetIteratorHandle iter$t
        iter$t First
        set disp(id) {}
        while {[iter$t Valid]== "true"} {
            set resp111 [iter$t GetDataList]
                if {[lsearch -exact $disp(id) [lindex $resp111 0]]<0} {
                    lappend disp(id) [lindex $resp111 0]
                    lappend disp(xcoord) [lindex [lindex $resp111 1] 0]		
                    lappend disp([lindex [lindex $resp111 1] 0]) [lindex $resp111 2]				
                }
            iter$t Next
        }
        foreach i [lsort -real -increasing $disp(xcoord)] {
            puts -nonewline $torsionRightFileChanel "$i\t"
            puts -nonewline $torsionRightFileChanel " "
            puts $torsionRightFileChanel $disp($i)
        }
        unset disp
        close $torsionRightFileChanel
    hwi CloseStack

    # calculate torsion stiffness
    set s1 [lindex $resp1 2]
    set s2 [lindex $resp2 2]
    set s3 [lindex $resp3 2]
    set s4 [lindex $resp4 2]
    set s12 [expr abs($s1-$s2)]
    set s34 [expr abs($s3-$s4)]
    set y1 [lindex [lindex $resp1 1] 1]
    set y2 [lindex [lindex $resp2 1] 1]
    set y3 [lindex [lindex $resp3 1] 1]
    set y4 [lindex [lindex $resp4 1] 1]
    set l1 [expr abs($y1-$y2)]
    set l2 [expr abs($y3-$y4)]
    set angle1 [expr $s12/$l1]
    set angle2 [expr $s34/$l2]
    set angle [expr $angle1-$angle2]
    set M 2000 
    set torsion [expr $M/$angle/1000]
    set torsionStiffness [format "%.1f" $torsion]
}

proc ::stiffness::resultQuery {args} {
    global resultFilePath
    variable stiffnessMW

    ::stiffness::importResult $resultFilePath
    ::stiffness::getBendingStiffness
    ::stiffness::getTorsionStiffness
    focus $stiffnessMW
}

proc ::stiffness::createBendingCurves {args} {
    global resultFilePath
    variable stiffnessMW
    variable curvesPlot

    set t [clock milliseconds]
    hwi ReleaseAllHandles
    hwi OpenStack
        hwi GetSessionHandle sess$t
        sess$t GetProjectHandle proj$t
        for {set i 0} {$i < 2} {incr i} {
            if {$i == 0} {
                set responseFile [file dirname $resultFilePath]/Bending_Left.txt
                if {[file exist $responseFile] == 0} {
                    tk_messageBox -icon "error" -message "未找到弯曲刚度数据文件, 请先点击查询按钮 !" -title "错误" -parent $stiffnessMW
                    focus $stiffnessMW
                    return "noDataFile"
                }
                sess$t GetDataFileHandle datafile_$i$t $responseFile
            } else {
                set responseFile [file dirname $resultFilePath]/Bending_Right.txt
                if {[file exist $responseFile] == 0} {
                    tk_messageBox -icon "error" -message "未找到弯曲刚度数据文件, 请先点击查询按钮 !" -title "错误" -parent $stiffnessMW
                    focus $stiffnessMW
                    return "noDataFile"
                }
                sess$t GetDataFileHandle datafile_$i$t $responseFile
            }
            if {$i == 0} {
                proj$t SetActivePage [expr $i + 2]
            }
            proj$t GetPageHandle page_$i$t [proj$t GetActivePage]
            page_$i$t GetWindowHandle wind_$i$t 2
            page_$i$t SetTitle "Stiffness"
            page_$i$t SetTitleDisplayed true
            wind_$i$t SetClientType "Plot"
            wind_$i$t GetClientHandle plt_$i$t
            set types [datafile_$i$t GetDataTypeList]
            set xtype [lindex $types 1]
            set ytype [lindex $types 0]
            set reqs [datafile_$i$t GetRequestList $ytype]
            set reqitem [lindex $reqs 0]
            set components [datafile_$i$t GetComponentList $ytype]
            set component1 [lindex $components 1]
            plt_$i$t GetHeaderHandle header$t
            header$t SetVisibility true
            header$t SetText "Bending"
            header$t ReleaseHandle
            set curvName ""
            plt_$i$t AddCurve
            set ncurve [plt_$i$t GetNumberOfCurves]
            plt_$i$t GetCurveHandle curv_$i$t $ncurve
            if {$i < 1} {
                curv_$i$t SetName "Bending_Left"
            } else {
                curv_$i$t SetName "Bending_Right"
            }
            plt_$i$t GetHorizontalAxisHandle xaxis_$i$t 1
            plt_$i$t GetVerticalAxisHandle yaxis_$i$t 1
            curv_$i$t GetVectorHandle vectorx_$i$t x
            curv_$i$t GetVectorHandle vectory_$i$t y
            xaxis_$i$t SetVisibility true
            xaxis_$i$t SetAutoFit true
            set xlabel "X Axis ( MM )"
            xaxis_$i$t SetLabel $xlabel
            yaxis_$i$t SetVisibility true
            set ylabel "Y Axis"
            yaxis_$i$t SetLabel "Displacement (mm)"
            yaxis_$i$t SetAutoFit true
            plt_$i$t Recalculate
	        plt_$i$t Autoscale
		    plt_$i$t Draw
            vectorx_$i$t SetType "file"
            vectorx_$i$t SetFilename $responseFile
            vectorx_$i$t SetDataType $xtype
            set xv [vectorx_$i$t GetValuesList]
            vectory_$i$t SetType "file"
            vectory_$i$t SetFilename $responseFile
            vectory_$i$t SetDataType $ytype
            vectory_$i$t SetRequest $reqitem
            vectory_$i$t SetComponent $component1
            curv_$i$t SetVisibility true
            xaxis_$i$t SetAutoFit true
            yaxis_$i$t SetAutoFit true
            xaxis_$i$t ReleaseHandle
            yaxis_$i$t ReleaseHandle
            wind_$i$t GetViewControlHandle viewctrl$i
            viewctrl$i Fit
            plt_$i$t Recalculate
            plt_$i$t Draw
            hwi ReleaseAllHandles 
        }
    hwi CloseStack
    set curvesPlot 1
}

proc ::stiffness::createTorsionCurves {args} {
    global resultFilePath
    variable stiffnessMW
    variable curvesPlot

    hwi OpenStack
        set tt [clock milliseconds]
        hwi GetSessionHandle sess$tt 
        sess$tt  GetProjectHandle proj$tt
        for {set i 2} {$i<4} {incr i} {
            set t [clock milliseconds]
            if {$i==2} {
                set responseFile [file dirname $resultFilePath]/Torsion_Left.txt
                if {[file exist $responseFile] == 0} {
                    tk_messageBox -icon "error" -message "未找到扭转刚度数据文件, 请先点击查询按钮 !" -title "错误" -parent $stiffnessMW
                    focus $stiffnessMW
                    return "noDataFile"
                }
                sess$tt GetDataFileHandle datafile_$i$t $responseFile
            } else {
                set responseFile [file dirname $resultFilePath]/Torsion_Right.txt
                if {[file exist $responseFile] == 0} {
                    tk_messageBox -icon "error" -message "未找到扭转刚度数据文件, 请先点击查询按钮 !" -title "错误" -parent $stiffnessMW
                    focus $stiffnessMW
                    return "noDataFile"
                }
                sess$tt GetDataFileHandle datafile_$i$t $responseFile
            }
            if {$i==2} {
                proj$tt SetActivePage [expr {$i+1}]
            }
            proj$tt GetPageHandle page$t [proj$tt GetActivePage]
            page$t GetWindowHandle win$t 3
            page$t SetTitle "Stiffness"
            page$t SetTitleDisplayed true
            win$t SetClientType "Plot"
            win$t GetClientHandle plot$t
            set types [datafile_$i$t GetDataTypeList]
            set xtype [lindex $types 1]
            set ytype [lindex $types 0]
            set reqs [datafile_$i$t GetRequestList $ytype]
            set reqitem [lindex $reqs 0]
            set components [datafile_$i$t GetComponentList $ytype]
            set component1 [lindex $components 1]
            plot$t GetHeaderHandle header$t
            header$t SetVisibility true
            header$t SetText "Torsion"
            header$t ReleaseHandle
            set curvName ""	
            plot$t AddCurve
            set ncurve [plot$t GetNumberOfCurves]
            plot$t GetCurveHandle curv_$t $ncurve
            if {$i<3} {
                curv_$t SetName "Torsion_Left"
            } else {
                curv_$t SetName "Torsion_Right"
            }
            plot$t GetHorizontalAxisHandle xaxis_$t 1
            plot$t GetVerticalAxisHandle yaxis_$t 1
            curv_$t GetVectorHandle vectorx_$t x
            curv_$t GetVectorHandle vectory_$t y
            xaxis_$t SetVisibility true
            xaxis_$t SetAutoFit true
            set xlabel "X Axis ( MM )"
            xaxis_$t SetLabel $xlabel
            yaxis_$t SetVisibility true
            set ylabel "Y Axis"
            yaxis_$t SetLabel "Displacement (mm)"
            yaxis_$t SetAutoFit true
            plot$t Recalculate
            plot$t Autoscale
            plot$t Draw
            vectorx_$t SetType "file"
            vectorx_$t SetFilename $responseFile
            vectorx_$t SetDataType $xtype
            set xv [vectorx_$t GetValuesList]
            vectory_$t SetType "file"
            vectory_$t SetFilename $responseFile
            vectory_$t SetDataType $ytype
            vectory_$t SetRequest $reqitem
            vectory_$t SetComponent $component1
            curv_$t SetVisibility true
            xaxis_$t SetAutoFit true
            yaxis_$t SetAutoFit true
            xaxis_$t ReleaseHandle
            yaxis_$t ReleaseHandle
            win$t GetViewControlHandle viewctrl$t
            viewctrl$t Fit
            plot$t Recalculate
            plot$t Draw
            hwi ReleaseAllHandles
        }
    hwi CloseStack
    hwi OpenStack
        set t [clock milliseconds]
        hwi GetSessionHandle sess$t
        sess$t GetProjectHandle proj$t
        proj$t GetPageHandle page$t [proj$t GetActivePage]
        page$t GetWindowHandle win$t 3
        win$t GetViewControlHandle viewctrl$t
        viewctrl$t Fit
        win$t GetClientHandle plot$t
        plot$t Draw
    hwi CloseStack
    set curvesPlot 1
}

proc ::stiffness::plot {args} {
    variable stiffnessMW
    variable curvesPlot
        
    if {$curvesPlot == 0} {
        if {[::stiffness::createBendingCurves] != "noDataFile"} {
            ::stiffness::createTorsionCurves
        }
        focus .
    } else {
        tk_messageBox -title "提示" -message "刚度曲线已输出, 无需重复点击, 请在HyperWorks窗口内查看 !" -parent $stiffnessMW
    }
}

proc ::stiffness::envCheck {args} {
    variable stiffnessMW
    if {[catch {hwi OpenStack}]} {
        foreach label [list postFrm importFrm queryFrm bendOutputLbl bendOutputtail torsionOutputLbl torsionOutputtail] {
            variable $label 
            set labelPath [set $label]
            $labelPath configure -fg "gray"
        }
        foreach button  [list queryBtn plotBtn bendOutputtxt torsionOutputtxt importEntry] {
            variable $button
            set buttonPath [set $button]
            $buttonPath configure -state "disabled"
        }
        tk_messageBox -title "提示" -message "推荐使用HpyerWorks Desktop进行刚度分析, 当前软件环境只支持前处理部分, 后处理操作请切换至HpyerWorks Desktop ." -parent $stiffnessMW
    }
    if {[hm_framework getuserprofile] != "OptiStruct {}"} {
        if {[tk_messageBox -title "提示" -message "当前工作环境不是OptiStruct, 程序无法正常工作, 是否自动切换?" -parent $stiffnessMW -type yesno] eq "yes"} {
            hm_framework loaduserprofile OptiStruct {}
        }
    }
    focus $stiffnessMW
}

::stiffness::mainWnd
::stiffness::envCheck
