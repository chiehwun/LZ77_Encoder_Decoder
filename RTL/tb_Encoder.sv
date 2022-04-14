`timescale 1ns/10ps
`define CYCLE      30.0  
`define End_CYCLE  100000

`define PAT        "./img0/testdata_encoder.dat"
// `define PAT        "./img1/testdata_encoder.dat"
// `define PAT        "./img2/testdata_encoder.dat"


module testfixture_encoder();


integer linedata;
integer char_count;
string data;
string strdata;
string gold_offset_str;
string gold_match_len_str;
string gold_char_nxt_str;

// ====================================================================
// I/O Pins                                                          //
// ====================================================================
reg clk = 0;
reg reset = 0;
reg [7:0] chardata;
wire valid;
wire encode;
wire finish;
wire [3:0] offset;
wire [2:0] match_len;
wire [7:0] char_nxt;

LZ77_Encoder u_LZ77_Encoder ( .clk(clk),
                            .reset(reset),
                            .chardata(chardata),
                            .valid(valid),
                            .encode(encode),
                            .finish(finish),
                            .offset(offset),
                            .match_len(match_len),
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
integer encode_cnt;
integer encode_err;

reg [3:0] gold_offset;
reg [2:0] gold_match_len;
reg [7:0] gold_char_nxt;
reg [7:0] gold_char_nxt_fin;
reg       encode_reg;
reg       wait_valid;
reg [3:0] get_offset;
reg [2:0] get_match_len;
reg [7:0] get_char_nxt;

integer allpass=1;
always@(negedge clk)
begin

    if(reset) begin
        wait_valid=0;
        encode_err = 0;
    end
    else
    begin

        if(wait_valid && valid && !finish)
        begin

            if(encode_reg) // Check encoding answer
            begin
                wait_valid = 0;
                get_offset = offset;
                get_match_len = match_len;
                get_char_nxt = char_nxt;

                encode_cnt = encode_cnt + 1;

                if (encode==1)
                begin
                    if ((get_offset === gold_offset) && (get_match_len === gold_match_len) && ((get_char_nxt === gold_char_nxt) || (gold_char_nxt_fin==8'h24 && get_char_nxt==8'h24))) begin
                        if(gold_char_nxt_fin == 8'h24 && get_char_nxt==8'h24) begin
                            $display("cycle %5h, expect(%h,%h,%c) , get(%h,%h,%c) >> Pass",cycle,gold_offset,gold_match_len,gold_char_nxt_fin,get_offset,get_match_len,get_char_nxt);
                        end
                        else begin
                            $display("cycle %5h, expect(%h,%h,%h) , get(%h,%h,%h) >> Pass",cycle,gold_offset,gold_match_len,gold_char_nxt[3:0],get_offset,get_match_len,get_char_nxt[3:0]);
                        end
                    end
                    else
                    begin
                        allpass = 0;
                        encode_err = encode_err+1;
                        if(gold_char_nxt_fin == 8'h24 && get_char_nxt!=8'h24) begin
                            $display("cycle %5h, expect(%h,%h,%c) , get(%h,%h,%h) >> Fail",cycle,gold_offset,gold_match_len,gold_char_nxt_fin,get_offset,get_match_len,get_char_nxt[3:0]); 
                        end
                        else if(gold_char_nxt_fin != 8'h24 && get_char_nxt==8'h24) begin
                            $display("cycle %5h, expect(%h,%h,%h) , get(%h,%h,%c) >> Fail",cycle,gold_offset,gold_match_len,gold_char_nxt[3:0],get_offset,get_match_len,get_char_nxt); 
                        end
                        else begin
                            $display("cycle %5h, expect(%h,%h,%h) , get(%h,%h,%h) >> Fail",cycle,gold_offset,gold_match_len,gold_char_nxt[3:0],get_offset,get_match_len,get_char_nxt[3:0]); 
                        end
                    end
                end
                else begin
                    allpass = 0;
                    encode_err = encode_err+1;
                    $display("cycle %5h, expect encoding, but encode signal is not high >> Fail",cycle);
                end
            end
        end

    end

end


// ====================================================================
// Read input string                                                 //
// ====================================================================
always @(negedge clk ) begin
    if (reset) begin
        encode_reg = 1;
    end 
    else begin

        if (!wait_valid)
        begin

            if (strindex < strdata.len() - 1)
            begin
                strindex = strindex + 1;
                if(strindex==strdata.len()-1) begin
                    chardata = strdata.getc(strindex);
                end
                else begin
                    chardata = strdata.substr(strindex, strindex).atohex();
                end
            end 
            else
            begin
                if (!$feof(linedata))
                begin

                    if (!finish)
                    begin
                        char_count = $fgets(data, linedata);
                    end
                    else
                    begin
                        char_count = 0;
                    end

                    if (char_count !== 0)
                    begin
                        if(data.substr(0,6) == "images:")
                        begin
                            strindex = 0;
                            encode_cnt = 0;
                            strdata = data.substr(7,data.len() - 2);
                            $display("== Encoding Image : \"%s\"\n", strdata);
                            chardata = strdata.substr(strindex, strindex).atohex();
                            $display("== Encoding start ==",);
                        end 
                        else if (data.substr(0,6) == "encode:")
                        begin
                            wait_valid = 1;
                            encode_reg = 1;
                            chardata = 8'h24; // String ending character
                            gold_offset = data.substr(7,7).atoi();
                            gold_match_len = data.substr(9,9).atoi();
                            gold_char_nxt = data.substr(11, 11).atohex();
                            gold_char_nxt_fin = data.getc(11);
                        end
                    end

                end
                else
                begin
                    if(finish) begin
                        if(allpass == 1) begin
                            $display("-----------------------------------------------");
                            // $display("-- Simulation finish, ALL PASS  --");
                            if(encode_err == 0) begin
                                $display("--------- Encoding finished, ALL PASS ---------"); 
                            end
                            $display("-----------------------------------------------");
                        end
                        else begin
                            $display("-----------------------------------------------");
                            $display("-- Simulation finish");
                            
                            if(encode_err != 0) begin
                                $display("----- Encoding failed, There are %d errors", encode_err); 
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
end

endmodule

