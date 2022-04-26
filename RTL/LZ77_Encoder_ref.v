/* Author: Liu
img0: 507,330 ns
img1: 491,670 ns
img2: 273,690 ns
*/
module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);
input     clk;
input     reset;
input   [7:0]  chardata;
output     valid;
output     encode;
output     finish;
output   [3:0]  offset;
output   [2:0]  match_len;
output    [7:0]  char_nxt;

wire encode;

reg [2:0] Next_state, Current_state;
reg [7:0] input_data [1023:0];
reg [7:0] input_data_1 [1023:0];

reg [12:0] n;
reg [11:0] n1;
reg [11:0] n2;

reg input_done;

reg valid;
// reg compute_done;
reg finish;
reg [2:0] control_out;

reg [3:0] offset, offset_buffer;
reg [2:0] match_len, match_len_buffer, match_len_buffer_1;
reg [7:0] char_nxt;

/*========search==========*/
reg [7:0] search_buffer [16:0];
reg [3:0] search_count;
/*========================*/
parameter input_state = 3'd0;
parameter state_1     = 3'd1;
parameter state_2     = 3'd2;
parameter state_3     = 3'd3;
parameter state_4     = 3'd4;
parameter state_5     = 3'd5;
parameter idle_state  = 3'd6;

integer i;

assign encode = 1;

// Controller path
// State register
always @(posedge clk) begin
    Current_state <= Next_state;
end

// Next state logic
always @(*) begin
    if (reset)
        Next_state = input_state;
    else begin
        case (Current_state)
            input_state: begin
                if (n == 2049) begin
                    Next_state = state_1;
                end
                else Next_state = input_state;
            end
            // Round1
            state_1: begin
                Next_state = state_2;
            end
            state_2: begin
                if (search_count == 8) begin
                    Next_state = state_3;
                end
                else Next_state = state_2;
            end
        // Round2~end
        state_3: begin
            Next_state = state_4;
        end
        state_4: begin
            Next_state = state_5;
        end
        state_5: begin
            if (match_len_buffer == 0) begin
                Next_state = state_1;
            end
            else if (finish) Next_state = idle_state;
            else Next_state             = state_5;
        end
        idle_state: begin
            Next_state = idle_state;
        end
        default: Next_state = Current_state;
        endcase
    end
    
end

// Output logic
always @(Current_state) begin
    case (Current_state)
        input_state:    control_out = 3'd0;
        state_1:        control_out = 3'd1;
        state_2:        control_out = 3'd2;
        state_3:        control_out = 3'd3;
        state_4:        control_out = 3'd4;
        state_5:        control_out = 3'd5;
        idle_state:     control_out = 3'd6;
    endcase
end

// input_state:
always @(posedge clk) begin
    case (control_out)
        3'd0: begin
            if (reset) begin
                input_done <= 0;
                n          <= 0;
                n1         <= 0;
                n2         <= 0;
                // output initial
                offset    <= 0;
                match_len <= 0;
                char_nxt  <= 0;
                finish    <= 0;
                valid     <= 0;
                for (i = 0; i < 8; i = i + 1)
                    search_buffer[i] <= 8'h24;
            end
            else begin
                if (n < 9)
                    search_buffer[n + 8] <= chardata;
                else begin
                    if (n1 < 1024) begin
                        input_data[n1] <= chardata;
                        n1             <= n1 + 1;
                    end
                    else begin
                        if (n < 2049) begin
                            input_data_1[n2] <= chardata;
                            n2               <= n2 + 1;
                        end
                        else begin
                            // input_done <= 1;
                            valid         <= 1;
                            offset        <= 0;
                            match_len     <= 0;
                            char_nxt      <= search_buffer[8];
                        end
                    end
                end
                n <= n + 1;
            end
        end
        3'd1: begin
            valid            <= 0;
            match_len_buffer <= 0;
            offset_buffer    <= 0;
            search_count     <= 0;
        end
        3'd2: begin
            if (search_count == 8) begin
                search_count <= 0;
            end
            else search_count <= search_count + 1;
            if (match_len_buffer < match_len_buffer_1) begin
                match_len_buffer <= match_len_buffer_1;
                offset_buffer    <= 8 - search_count;
            end
            else match_len_buffer <= match_len_buffer;
        end
        3'd3: begin
            //output state
            valid     <= 1;
            offset    <= offset_buffer;
            match_len <= match_len_buffer;
            char_nxt  <= search_buffer[9 + match_len_buffer];
        end
        3'd4: begin
            // wait state
            valid <= 0;
            if (search_buffer[9 + match_len_buffer] == 8'h24) begin
                finish <= 1;
            end
        end
        3'd5: begin
            if (match_len_buffer == 0)
                match_len_buffer <= 0;
            else match_len_buffer <= match_len_buffer - 1;
            for (i = 0; i < = 15 ; i = i + 1)
                search_buffer[i] <= search_buffer[i + 1];
            search_buffer[16] <= input_data[0];
            for (i = 0; i < = 1022 ; i = i + 1)
                input_data[i] <= input_data[i + 1];
            input_data[1023] <= input_data_1[0];
            for (i = 0; i < = 1022 ; i = i + 1)
                input_data_1[i] <= input_data_1[i + 1];
        end
        3'd6: begin
            finish <= 1;
        end
        // default:
    endcase
    
    
end

always @(*) begin
    if (reset)
        match_len_buffer_1 = 3'd0;
    else begin
        casex({search_buffer[search_count], search_buffer[search_count + 1], search_buffer[search_count + 2], search_buffer[search_count + 3], search_buffer[search_count + 4], search_buffer[search_count + 5], search_buffer[search_count + 6]}
        ^ {search_buffer[9], search_buffer[10], search_buffer[11], search_buffer[12], search_buffer[13], search_buffer[14], search_buffer[15]})
        56'h00000000000000: match_len_buffer_1 = 7;
        56'h000000000000xx: match_len_buffer_1 = 6;
        56'h0000000000xxxx: match_len_buffer_1 = 5;
        56'h00000000xxxxxx: match_len_buffer_1 = 4;
        56'h000000xxxxxxxx: match_len_buffer_1 = 3;
        56'h0000xxxxxxxxxx: match_len_buffer_1 = 2;
        56'h00xxxxxxxxxxxx: match_len_buffer_1 = 1;
        56'hxxxxxxxxxxxxxx: match_len_buffer_1 = 0;
        default: match_len_buffer_1            = 0;
        endcase
    end
end
endmodule
