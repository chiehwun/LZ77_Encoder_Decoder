/* Author: rubato Wun
===== Synthesis Result =====
Total logic elements:               86 / 68,416 ( < 1 % )
    Total combinational functions:  56 / 68,416 ( < 1 % )
    Dedicated logic registers:      77 / 68,416 ( < 1 % )
Total registers:                    77
Total memory bits:                  0 / 1,152,000 ( 0 % )
Embedded Multiplier 9-bit elements: 0 / 300 ( 0 % )
===== Time Performance =====
img0: 61,620 ns
img1: 61,620 ns
img2: 61,620 ns
*/
module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);
input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output  			encode;
output  			finish;
output 	 	[7:0] 	char_nxt;

// Define Width
parameter Wsearch = 9;	// Search buffer    =>  9 chars
parameter Wchar   = 8;	// char  	        =>  8 bits

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$'

/********** Variables **********/
reg 		[Wchar-1:0]		srch_buf  [Wsearch-1:0];
reg 		[3:0]   		cnt, i;	// 0-(Wsearch-1): 4 bits

// Output
reg 		finish;
assign encode   = 0;
assign char_nxt = srch_buf[0];

// Decoder
always @(posedge clk) begin
    if(reset) begin
        cnt <= 0;   
        finish <= 0;
    end
    else begin
        for(i = 0; i < Wsearch-1; i = i + 4'd1)
            srch_buf[i + 1] <= srch_buf[i];	// Shift left
        if(cnt == code_len) begin
            cnt         <= 0;
            srch_buf[0] <= chardata;
        end
        else begin
            cnt         <= cnt + 4'd1;
            srch_buf[0] <= srch_buf[code_pos];
        end
        // output
        finish   <=  srch_buf[0] == EndSgn;
    end
end
endmodule