`timescale 1ns/10ps
`define CYCLE      30.0  
`define End_CYCLE  100000

`define PAT        "./img0/testdata_decoder.dat"
// `define PAT        "./img1/testdata_decoder.dat"
// `define PAT        "./img2/testdata_decoder.dat"


module testfixture_decoder();


integer linedata;
integer char_count;
string data;
string strdata;


// ====================================================================
// I/O Pins                                                          //
// ====================================================================
reg clk = 0;
reg reset = 0;
reg [3:0] code_pos;
reg [2:0] code_len;
reg [7:0] chardata;
wire encode;
wire finish;
wire [7:0] char_nxt;

LZ77_Decoder u_LZ77_Decoder ( .clk(clk),
                            .reset(reset),
                            .code_pos(code_pos),
                            .code_len(code_len),
                            .chardata(chardata),
                            .encode(encode),
                            .finish(finish),
                            .char_nxt(char_nxt)
                           );


// ====================================================================
// Initialize                                                        //
// ====================================================================
always begin #(`CYCLE/2) clk = ~clk; end

initial
begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk); #1; reset = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk); #1;   reset = 1'b0;
end

initial
begin
    linedata = $fopen(`PAT,"r");
    if(linedata == 0)
    begin
        $display ("pattern handle null");
        $finish;
    end
end


// ====================================================================
// Handle end-cycle exceeding situation                              //
// ====================================================================
reg [22:0] cycle=0;

always@(posedge clk)
begin
    cycle=cycle+1;
    if (cycle > `End_CYCLE)
    begin
        $display("--------------------------------------------------");
        $display("---------- Time Exceed, Simulation STOP ----------");
        $display("--------------------------------------------------");
        $fclose(linedata);
        $finish;
    end
end


// ====================================================================
// Check if answers correct                                          //
// ====================================================================

integer strindex;
integer decode_num;
integer decode_cnt;

integer decode_err;

reg [7:0] gold_char_nxt;
reg [7:0] gold_char_nxt_fin;
reg wait_valid;
reg [7:0] get_char_nxt;

integer allpass=1;
always@(negedge clk)
begin

    if(reset) begin
        wait_valid=0;
        decode_err = 0;
    end
    else
    begin
        if(wait_valid && !finish)
        begin
            decode_num = decode_num + 1;
            if(decode_num == strdata.len())
                wait_valid = 0;

            get_char_nxt = char_nxt;
            if(!(gold_char_nxt_fin==8'h24 && code_pos==0 && code_len==0) && !finish) begin
                if (!encode)
                begin
                    if(get_char_nxt !== gold_char_nxt)
                    begin
                        allpass = 0;
                        decode_err = decode_err+1;
                        $display("cycle %5h, failed to decode %s, expect %h, get %h >> Fail",cycle,strdata,gold_char_nxt[3:0],get_char_nxt[3:0]);
                    end
                    else begin
                        $display("cycle %5h, expect %h, get %h >> Pass",cycle,gold_char_nxt[3:0],get_char_nxt[3:0]); 
                    end
                end
                else begin
                    allpass = 0;
                    decode_err = decode_err+1;
                    $display("cycle %5h, expect decoding, but encode signal not low >> Fail",cycle);
                end
                
                strindex = strindex + 1;
                gold_char_nxt = strdata.substr(strindex, strindex).atohex();
            end
            else begin
                wait_valid = 0;
            end
        end
        else if(wait_valid && finish)begin
            if(gold_char_nxt_fin==8'h24 && code_pos==0 && code_len==0) begin
                wait_valid = 0;
            end
        end
    end

end


// ====================================================================
// Read input string                                                 //
// ====================================================================
always @(negedge clk ) begin
    if (reset) begin
        char_count = 0;
    end 
    else begin
        if (!wait_valid)
        begin
            if (!$feof(linedata))
            begin
                if (!finish)
                begin
                    char_count = $fgets(data, linedata);
                end
                else
                begin
                    char_count = $fgets(data, linedata);
                    char_count = 0;
                end

                if (char_count !== 0)
                begin
                    if (data.substr(0,6) == "decode:")
                    begin
                        wait_valid = 1;
                        strindex = 0;
                        decode_num = 0;
                        strdata = data.substr(13,data.len() - 2);
                        gold_char_nxt = strdata.substr(strindex, strindex).atohex();

                        code_pos = data.substr(7,7).atoi();
                        code_len = data.substr(9,9).atoi();
                        gold_char_nxt_fin = data.getc(11);
                        chardata = data.substr(11, 11).atohex();

                        decode_cnt = decode_cnt + 1;

                        if(gold_char_nxt_fin==8'h24) begin
                            chardata = gold_char_nxt_fin;
                        end

                        if(!(gold_char_nxt_fin==8'h24 && code_pos==0 && code_len==0)) begin
                            // chardata = gold_char_nxt_fin;
                            $display("  == Decoding string \"%s\"", strdata);
                        end
                    end

                end

            end
            else
            begin
                if(finish) begin
                    if(allpass == 1) begin
                        $display("-----------------------------------------------");
                        // $display("-- Simulation finish, ALL PASS  --");
                        if(decode_err == 0) begin
                            $display("--------- Decoding finished, ALL PASS ---------"); 
                        end
                        $display("-----------------------------------------------");
                    end
                    else begin
                        $display("-----------------------------------------------");
                        $display("-- Simulation finish");
                        
                        if(decode_err != 0) begin
                            $display("----- Decoding failed, There are %d errors", decode_err); 
                        end
                        $display("-----------------------------------------------");
                    end
                    $fclose(linedata);
                    $finish;
                end
            end
        end

    end
end

endmodule

