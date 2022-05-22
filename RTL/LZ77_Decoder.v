/* Author: rubato Wun
===== Synthesis Result =====
Total logic elements:               83 / 68,416 ( < 1 % )
    Total combinational functions:  52 / 68,416 ( < 1 % )
    Dedicated logic registers:      76 / 68,416 ( < 1 % )
Total registers:                    76
Total memory bits:                  0 / 1,152,000 ( 0 % )
Embedded Multiplier 9-bit elements: 0 / 300 ( 0 % )
===== Functional Simulation =====
status: pass
61,620 ns
===== Gate-level Simulation =====
status: pass
===== Scoring =====
Scoring = Total logic elements + total memory bit + 9*embedded multiplier 9-bit element
Scoring = 83
*/
module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);
input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output   			encode;
output reg			finish;
output reg	[7:0] 	char_nxt;

assign encode = 0;

parameter Wsearch = 9;	// Search buffer	=>  9 chars
parameter Wchar   = 8;	// char  			=>  8 bits
parameter [Wchar-1:0]	EndSgn = 8'h24; // Dollar sign: '$' 

reg 		[Wchar-1:0]		srch_buf  [Wsearch-1:0];
reg 		[2:0]   		cnt;	// 0-7: 2 bits
integer i;

// Datapath: Decoder
always @(posedge clk or posedge reset) begin
	// CONTROL SIGNAL & OUTPUT should be triggered at the posedge !!!
	// so that the golden pattern will be checked 
	// while the OUTPUT update at the posedge.
	if (reset) begin
		for (i=0; i < Wsearch; i = i + 32'd1)
			srch_buf[i] <= 0;
		cnt <= 0;
		finish   <= 0;
		char_nxt <= 0;
	end
	else begin
		// Shift left
		for(i=0; i < Wsearch-1; i = i + 32'd1)
			srch_buf[i + 1] <= srch_buf[i];
		cnt         <= cnt == code_len ? 3'd0 : cnt + 3'd1;
		srch_buf[0] <= cnt == code_len ? chardata : srch_buf[code_pos];
		char_nxt    <= cnt == code_len ? chardata : srch_buf[code_pos];
		finish      <= char_nxt == EndSgn ? 1'b1 : 1'b0;
	end
end
endmodule