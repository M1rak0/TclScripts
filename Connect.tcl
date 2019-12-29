
# 销毁重名的命名空间，防止出错
catch {namespace delete ::connect}

namespace eval ::connect { }

# 内容选取模块，可重复调用
proc ::connect::pickEntity {entityName} {
    *createmarkpanel $entityName 1
    return [hm_getmark $entityName 1]
}

# 主程序
proc ::connect::main {elemSet compSet} {
    *clearmarkall 1
    *clearmarkall 2
    if {![llength $elemSet] || ![llength $compSet]} {
        return
    }
    # 保存当前视图
    eval *createmark elems 1 "displayed"
    set currentDisplayed [hm_getmark elems 1]
    *unmaskall2
    eval *createmark elems 1 $elemSet
    *maskentitymark elems 1 0
    *maskreverse elems
    # 将网格分组，所有相连的网格为一组
    set groups ""
    foreach elem $elemSet {
        *clearmarkall 1
        *clearmarkall 2
        eval *createmark elems 1 $elem
        *appendmark elems 1 "by attached"
        set group [lsort -decreasing [hm_getmark elems 1]]
        # 组内元素去重
        if {[lsearch $groups $group] == -1} {
            lappend groups $group
        }
    }

    # 提取目标component内所有网格的中心，建立临时节点，并将中心节点的编号与网格编号对应
    eval *createmark elems 1 "by comps" $compSet
    set tmpNodes ""
    foreach elem [hm_getmark elems 1] {
        *createnode [hm_getvalue elems id=$elem dataname=centerx] [hm_getvalue elems id=$elem dataname=centery] [hm_getvalue elems id=$elem dataname=centerz]
        *createmark nodes 1 -1
        set nid [hm_getmark nodes 1]
        append tmpNodes " " $nid
        set center$nid $elem
    }

    set rigidsCreated ""
    foreach group $groups {
        set nodeList1 ""
        set nodeList2 ""
        # 分别对各组内的每个单元搜索距离它最近的单元，然后以组为单位建立连接
        foreach elem $group {
            *clearmarkall 1
            *clearmarkall 2
            append nodeList1 " " [hm_getvalue elems id=$elem dataname=nodes]
            eval *createmark nodes 1 all
            eval *createmark nodes 2 $tmpNodes
            *markdifference nodes 1 nodes 2
            # 以各网格中心点间的距离作为搜索依据
            set nid [hm_getclosestnode [hm_getvalue elems id=$elem dataname=centerx] [hm_getvalue elems id=$elem dataname=centery] [hm_getvalue elems id=$elem dataname=centerz] 0 1]
            set closestElem [set center$nid]
            append nodeList2 " " [hm_getvalue elems id=$closestElem dataname=nodes]
        }
        *clearmarkall 1
        *clearmarkall 2
        if {![hm_entityinfo exist comps "rigidlink"]} {
            *createentity comps name="rigidlink" color=5
        }
        *currentcollector comps "rigidlink"
        eval *createmark nodes 1 $nodeList1
        *rigidlinkinodecalandcreate 1 0 0 123456
        *createmark elems 2 -1
        *createmark nodes 2 -1
        eval *createmark nodes 1 $nodeList2
        *rigidlinkinodecalandcreate 1 0 0 123456
        *appendmark elems 2 -1
        *appendmark nodes 2 -1
        *rigidlinkinodecalandcreate 2 0 0 123456
        *appendmark elems 2 -1
        append rigidsCreated " " [hm_getmark elems 2]
        *clearmarkall 1
        *clearmarkall 2
    }

    # 恢复操作前的视图，清除临时节点
    *unmaskall2
    eval *createmark elems 1 $currentDisplayed
    eval *appendmark elems 1 $rigidsCreated
    *maskentitymark elems 1 0
    *maskreverse elems
    *nodecleartempmark
    *clearmarkall 1
    *clearmarkall 2
}

# 主窗口
proc ::connect::mainWindow {args} {
    set mw [::hwtk::dialog .mw -title "傻逼才用这种东西"]
    $mw hide ok
    $mw hide cancel
    $mw buttonconfigure apply -command {::connect::main $::connect::elemSet $::connect::compSet}
    $mw post
    set recess [$mw recess]
    set frame [::hwtk::frame $recess.frame]
    set pickElemBtn [::hwtk::button $frame.btn1 -text "Pick Elems" -width 25 -command {set ::connect::elemSet [::connect::pickEntity elems]}]
    set pickCompBtn [::hwtk::button $frame.btn2 -text "Pick Comps" -width 25 -command {set ::connect::compSet [::connect::pickEntity comps]}]
    
    # Layout
        pack $frame -side top -pady 8 -padx 2
        grid $pickElemBtn -col 0 -row 0 -pady 2
        grid $pickCompBtn -col 0 -row 1
    #
    
}

::connect::mainWindow