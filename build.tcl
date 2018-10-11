update_compile_order -fileset sources_1

# If IP cores are used
if { [llength [get_ips]] != 0} {
    upgrade_ip [get_ips]

    foreach ip [get_ips] {
        create_ip_run [get_ips $ip]
    }

    set ip_runs [get_runs -filter {SRCSET != sources_1 && IS_SYNTHESIS && NEEDS_REFRESH}]
    
    if { [llength $ip_runs] != 0} {
        launch_runs -quiet -jobs 2 {*}$ip_runs
        
        foreach r $ip_runs {
            wait_on_run $r
        }
    }

}

reset_run impl_1
reset_run synth_1
launch_runs -jobs 2 impl_1 -to_step write_bitstream
wait_on_run impl_1

exit