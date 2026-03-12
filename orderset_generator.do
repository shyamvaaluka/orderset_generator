onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ltssm_top/DUT/clk
add wave -noupdate /ltssm_top/DUT/reset
add wave -noupdate /ltssm_top/DUT/pipe_rx_data
add wave -noupdate /ltssm_top/DUT/pipe_tx_data
add wave -noupdate /ltssm_top/DUT/d_to
add wave -noupdate /ltssm_top/DUT/pa_to
add wave -noupdate /ltssm_top/DUT/pc_to
add wave -noupdate /ltssm_top/DUT/c_to
add wave -noupdate /ltssm_top/DUT/state
add wave -noupdate /ltssm_top/DUT/next_state
add wave -noupdate -radix ascii /ltssm_top/DUT/state_ascii
add wave -noupdate /ltssm_top/DUT/rcv_5_ts1
add wave -noupdate /ltssm_top/DUT/rcv_8_ts1
add wave -noupdate /ltssm_top/DUT/rcv_8_ts2
add wave -noupdate -radix unsigned {/ltssm_top/DUT/ts1_sent_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top/DUT/ts2_sent_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top/DUT/ts1_rcvd_cnt[0]}
add wave -noupdate -radix unsigned {/ltssm_top/DUT/ts2_rcvd_cnt[0]}
add wave -noupdate /ltssm_top/DUT/sent_12_ts1
add wave -noupdate /ltssm_top/DUT/sent_16_ts2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1595000 ps} 0}
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
WaveRestoreZoom {1233516 ps} {1956236 ps}
