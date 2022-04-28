onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /testfixture_encoder/allpass
add wave -noupdate -radix unsigned /testfixture_encoder/encode_err
add wave -noupdate -radix unsigned /testfixture_encoder/encode_cnt
add wave -noupdate -radix unsigned /testfixture_encoder/clk
add wave -noupdate -radix unsigned /testfixture_encoder/reset
add wave -noupdate -radix unsigned /testfixture_encoder/char_count
add wave -noupdate -radix unsigned /testfixture_encoder/gold_offset_str
add wave -noupdate -radix unsigned /testfixture_encoder/gold_match_len_str
add wave -noupdate -radix hexadecimal /testfixture_encoder/gold_char_nxt_str
add wave -noupdate -radix unsigned /testfixture_encoder/chardata
add wave -noupdate -radix unsigned /testfixture_encoder/valid
add wave -noupdate -radix unsigned /testfixture_encoder/encode
add wave -noupdate -radix unsigned /testfixture_encoder/finish
add wave -noupdate -radix unsigned /testfixture_encoder/offset
add wave -noupdate -radix unsigned /testfixture_encoder/match_len
add wave -noupdate -radix hexadecimal /testfixture_encoder/char_nxt
add wave -noupdate -radix unsigned /testfixture_encoder/gold_offset
add wave -noupdate -radix unsigned /testfixture_encoder/gold_match_len
add wave -noupdate -radix hexadecimal /testfixture_encoder/gold_char_nxt
add wave -noupdate -radix unsigned /testfixture_encoder/u_LZ77_Encoder/sl_ind
add wave -noupdate -radix unsigned /testfixture_encoder/u_LZ77_Encoder/i
add wave -noupdate -radix hexadecimal /testfixture_encoder/u_LZ77_Encoder/bundle_xor
add wave -noupdate -radix unsigned /testfixture_encoder/u_LZ77_Encoder/ans_offset
add wave -noupdate -radix unsigned /testfixture_encoder/u_LZ77_Encoder/ans_match_len
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~0_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~1_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~2_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~3_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~4_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~5_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~6_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~7_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~8_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~9_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~10_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml~11_combout }
add wave -noupdate -radix unsigned {/testfixture_encoder/u_LZ77_Encoder/\c_ml[2]~12_combout }
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48973046 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 364
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {55675020 ps} {56097400 ps}
