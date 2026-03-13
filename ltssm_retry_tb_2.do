onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ltssm_top_2/DUT/clk
add wave -noupdate /ltssm_top_2/DUT/reset
add wave -noupdate {/ltssm_top_2/DUT/pipe_rx_data[0]}
add wave -noupdate {/ltssm_top_2/DUT/pipe_tx_data[0]}
add wave -noupdate /ltssm_top_2/DUT/d_to
add wave -noupdate /ltssm_top_2/DUT/pa_to
add wave -noupdate /ltssm_top_2/DUT/pc_to
add wave -noupdate /ltssm_top_2/DUT/c_to
add wave -noupdate /ltssm_top_2/DUT/state
add wave -noupdate /ltssm_top_2/DUT/next_state
add wave -noupdate -radix ascii /ltssm_top_2/DUT/state_ascii
add wave -noupdate -radix unsigned {/ltssm_top_2/DUT/ts1_sent_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top_2/DUT/ts2_sent_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top_2/DUT/ts1_rcvd_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top_2/DUT/ts2_rcvd_cnt[0]}
add wave -noupdate /ltssm_top_2/DUT/rcv_5_ts1
add wave -noupdate /ltssm_top_2/DUT/rcv_8_ts1
add wave -noupdate /ltssm_top_2/DUT/rcv_8_ts2
add wave -noupdate /ltssm_top_2/DUT/sent_12_ts1
add wave -noupdate /ltssm_top_2/DUT/sent_16_ts2
add wave -noupdate -expand -group {tb side os count} -radix unsigned {/ltssm_top_2/ts1_send_cnt[0]}
add wave -noupdate -expand -group {tb side os count} -radix unsigned {/ltssm_top_2/ts2_send_cnt[0]}
add wave -noupdate -expand -group {tb side os count} -radix unsigned {/ltssm_top_2/ts1_rcv_cnt[0]}
add wave -noupdate -expand -group {tb side os count} -radix unsigned {/ltssm_top_2/ts2_rcv_cnt[0]}
add wave -noupdate -expand -group {tb side os count} -radix ascii /ltssm_top_2/state_ascii_tb
add wave -noupdate -expand -group {tb side os count} -radix unsigned /ltssm_top_2/flag_detect
add wave -noupdate -expand -group {tb side os count} -radix unsigned /ltssm_top_2/flag_pol_active_send
add wave -noupdate -expand -group {tb side os count} -radix unsigned /ltssm_top_2/flag_pol_active_receive
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {56750 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {1868354 ps} {2049034 ps}
