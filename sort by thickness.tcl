*clearmarkall 1
*clearmarkall 2
*createmark comps 1 all
set compset [hm_getmark comps 1]

foreach comp $compset {
	set compname [hm_getvalue comps id=$comp dataname=name]
	set flag [string last _t $compname]
	set length [string length $compname]
	set thick [string range $compname [expr $flag+1] $length]
	catch {*createentity comps name=comps_28part3_$thick}
	*currentcollector components "comps_28part3_$thick"
	
	*clearmark elems 1
	*createmark elems 1 "by comps" $comp
	*movemark elems 1 "comps_28part3_$thick"
}
*clearmarkall 1
*clearmarkall 2