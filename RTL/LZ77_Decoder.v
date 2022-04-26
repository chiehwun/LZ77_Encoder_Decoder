module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);
input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output  			encode;
output  			finish;
output 	 	[7:0] 	char_nxt;

assign encode = 0;

// Define Width
parameter Wsearch = 9;	// Search buffer    =>  9 chars
parameter Wchar   = 8;	// char  	        =>  8 bits
parameter Wstate  = 2;	// state 0-3        =>  3 bits

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$'

// Define State & Constrol Signal
parameter 	[Wstate-1:0] 	Dec_S0 = 0;
parameter 	[Wstate-1:0] 	Dec_S  = 1;
parameter 	[Wstate-1:0] 	Fin_S  = 2;

/********** Variables **********/
reg 		[Wstate-1:0] 	cur_S, nxt_S, ctrl_sig;
reg 		[Wchar-1:0] 	char_nxt;
reg 		[Wchar-1:0]		srch_buf  [Wsearch-1:0];
reg 		[3:0]   		cnt, i;	// 0-(Wsearch-1): 4 bits

// Output register
reg 			finish;

// Next State Logic
always @(*) begin
    case (cur_S)
        Dec_S0:  nxt_S 	= Dec_S;
        Dec_S: 	 nxt_S 	= (chardata == EndSgn && cnt == code_len)? Fin_S : Dec_S;
        Fin_S: 	 nxt_S 	= Fin_S;
        default: nxt_S 	= Dec_S0;
    endcase
end

// State Register
always @(posedge clk) begin
    cur_S <= reset ? Dec_S0 : nxt_S;
end

// Output Logic
always @(*) begin
    case (cur_S)
        Dec_S0: 	ctrl_sig = Dec_S0;
        Dec_S: 		ctrl_sig = Dec_S;
        Fin_S: 		ctrl_sig = Fin_S;
        default: 	ctrl_sig = Dec_S0;
    endcase
end

// Datapath: Decoder
always @(posedge clk) begin
    // CONTROL SIGNAL & OUTPUT should be triggered at the posedge !!!
    // so that the golden pattern will be checked
    // while the OUTPUT update at the posedge.
    case(ctrl_sig)
        Dec_S0: begin
            srch_buf[0] <= chardata;
            cnt <= 0;
            // output
            char_nxt <= chardata;
            finish   <= 0;
        end
        Dec_S: begin
            for(i = 0; i < Wsearch-1; i = i + 4'd1)
                srch_buf[i + 1] <= srch_buf[i];	// Shift left
                if(cnt == code_len) begin
                    cnt <= 0;
                    srch_buf[0] <= chardata;
                end
                else begin
                    cnt <= cnt + 4'd1;
                    srch_buf[0] <= srch_buf[code_pos];
                end
                // output
                char_nxt <= cnt == code_len? chardata : srch_buf[code_pos];
                finish   <= 0;
        end
        Fin_S: begin
            // output
            char_nxt <= 8'h00;
            finish   <= 1;
        end
        default: begin
            // output
            char_nxt <= 8'h00;
            finish   <= 1;
        end
    endcase
end
endmodule