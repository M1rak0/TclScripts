namespace eval ::equivalentWave {

}

set oringinDataPath "请选择文件"
set xValue1 0
set xValue2 0

proc ::equivalentWave::mainWindow {args} {

    global oringinDataPath
    global xValue1
    global xValue2

    catch {destroy .eqMW}
    set eqMW [::hwtk::dialog .eqMW -x [expr [winfo rootx .] + 120] -y [expr [winfo rooty .] + 120]]

    $eqMW hide cancel
    $eqMW hide ok
    $eqMW buttonconfigure apply -command {::equivalentWave::generation} -text "Generate"

    wm title $eqMW "等效双线性波生成工具"
    wm resizable $eqMW 0 0

    set eqrecess [$eqMW recess]
        set importFrame [::hwtk::frame $eqrecess.importFrame]
            set importLabel [::hwtk::label $importFrame.import:label -text "导入数据:" -width 10]
            set importEntry [::hwtk::openfileentry $importFrame.importEntry -filetypes {{{Microsoft Excel 逗号分隔值文件} {"*.csv"}} {{All Files} {"*.*"}}} -width 20 -textvariable oringinDataPath -state readonly]
        set parmFrame [::hwtk::frame $eqrecess.parmFrame]
            set parmLabel1 [::hwtk::label $parmFrame.parmLabel1 -text "第一顶点横坐标:" -width 15]
            set parmLabel2 [::hwtk::label $parmFrame.parmLabel2 -text "第二顶点横坐标:" -width 15]
            set parmEntry1 [::hwtk::entry $parmFrame.parmEntry1 -textvariable xValue1 -justify right -width 18 -inputtype double]
            set parmEntry2 [::hwtk::entry $parmFrame.parmEntry2 -textvariable xValue2 -justify right -width 18 -inputtype double]

        grid $importFrame -pady 5 -ipady 2 -ipadx 2
            grid $importLabel -row 0 -column 0
            grid $importEntry -row 0 -column 1
        grid $parmFrame -ipady 2 -ipadx 2 
            grid $parmLabel1 -row 0 -column 0
            grid $parmLabel2 -row 1 -column 0 -pady 5
            grid $parmEntry1 -row 0 -column 1
            grid $parmEntry2 -row 1 -column 1 -pady 5
    $eqMW post
    focus $eqMW
}

proc ::equivalentWave::generation {args} {

    global oringinDataPath
    global xValue1
    global xValue2

    if {[catch {file tail $oringinDataPath}]} {
        tk_messageBox -title "错误" -icon error -message "请选择正确的数据文件"
        return 0
    }
    if {[expr $xValue2 - $xValue1] <= 0 || [expr $xValue1 * $xValue2] <= 0 || $xValue1 <= 0 || $xValue2 <= 0} {
        tk_messageBox -title "错误" -icon error -message "顶点横坐标必须为正数且不相等"
        return 0
    }
    set curveFile [open $oringinDataPath r]
    set t1 $xValue1
    set t2 $xValue2
    set vPrev -1
    set vTotal 0
    set i 0
    while {![eof $curveFile]} {
        set pointCord$i [string map {"," " "} [gets $curveFile]]
        if {[set pointCord$i] eq ""} {
            continue
        }
        if {[catch {expr int([lindex [set pointCord$i] 0])}]} {
            continue
        }
        if {[catch {expr int([lindex [set pointCord$i] 1])}]} {
            continue
        }
        if {$i > 1} {
            set j [expr $i - 1]
            set vDiv [expr 0.5 * ([lindex [set pointCord$i] 0] - [lindex [set pointCord$j] 0]) * ([lindex [set pointCord$i] 1] + [lindex [set pointCord$j] 1])]
            set vTotal [expr $vTotal + $vDiv]
        }
        
        if {[lindex [set pointCord$i] 0] == $t1} {
            set v1 $vTotal
        }
        if {[lindex [set pointCord$i] 0] == $t2} {
            set v2 [expr $vTotal - $v1]
            break
        }
        incr i
    }
    close $curveFile
    set accl1 [expr 2 * $v1 / $t1]
    set accl2 [expr 2 * $v2 / ($t2 - $t1) - $accl1]
    set resultFile [open [file dir $oringinDataPath]/EBW-[file tail $oringinDataPath] w]
    puts $resultFile "0.0,0.0"
    puts $resultFile "$t1,$accl1"
    puts $resultFile "$t2,$accl2"
    puts $resultFile "[expr $t2 * 1.1],0.0"
    close $resultFile
}

::equivalentWave::mainWindow