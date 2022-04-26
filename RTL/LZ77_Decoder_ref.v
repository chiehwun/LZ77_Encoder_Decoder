module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);

input     clk;
input     reset;
input   [3:0]  code_pos;
input   [2:0]  code_len;
input   [7:0]  chardata;
output     encode;
output     finish;
output    [7:0]  char_nxt;

reg         [3:0]   currentstate, nextstate;
reg         [3:0]   control_signal;
reg                 finish, encode, no_sig;
reg         [7:0]   search_buffer [8:0];
reg         [3:0]   idx, i;
reg         [7:0]   char_nxt;
parameter   [3:0]   IDLE = 4'd0, first_decoding = 4'd1, decode = 4'd2;


initial begin
 finish <= 0;
 encode <= 0;
end

//state register
always@(posedge clk)
 if(!reset)
  currentstate <= nextstate;
 else
  currentstate <= IDLE;

always@(reset)
 if(!reset)
  currentstate = first_decoding;


//next state logic
always@(*)
 begin
  case(currentstate)
  first_decoding:
   begin
    nextstate = decode;
   end
  decode:
   begin
    nextstate = decode;
   end
  default:
   begin
    no_sig = 1;
   end

  endcase
 end

//output logic
always@(currentstate)
 begin
  case(currentstate)
  first_decoding:
   begin
    control_signal = 4'd1;
   end
  decode:
   begin
    control_signal = 4'd2;
   end

  default:
   begin
    control_signal = 4'd0;
   end
  endcase
  
 end

//解碼部分
always@(posedge clk)
 begin
  case(control_signal)
  2'd1:   //first decoding
   begin
    char_nxt <= chardata;
    search_buffer[0] <= chardata;
    idx <= 0;
   end
  2'd2:   //decode search_buffer 
   begin
    for(i = 0; i <= 7; i = i + 1)
     search_buffer[i + 1] <= search_buffer[i];
    if(code_len <= 0)
     begin
      char_nxt <= chardata;
      search_buffer[0] <= chardata;
     end
    else
     begin
      if(idx < code_len)
       begin
        char_nxt <= search_buffer[code_pos];
        search_buffer[0] <= search_buffer[code_pos];
        idx <= idx + 1;
       end
      else
       begin
        char_nxt <= chardata;
        search_buffer[0] <= chardata;
        idx <= 0;
       end    
     end
    if(search_buffer[0] == 8'h24)
     finish <= 1;
   end
  default:
   begin
    no_sig <= 1;
   end
  endcase

 end

endmodule