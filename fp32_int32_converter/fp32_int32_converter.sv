module fp32_int32_converter (
    input        clk_i,
    input        rst_i,
    input        is_fp32_i,
    input [31:0] a_i,

    output [31:0] result_o,
    output        nv_o
);
    localparam EXP_OVERFLOW = 8'd158;
    localparam EXP_BIAS     = 8'd127;

    logic [31:0] result_reg;
    logic        nv_reg;

    logic [31:0] data;
    logic [31:0] abs_data;
    logic [31:0] comb_result;
    logic        comb_nv;

    logic [$clog2(32):0] msb_pos;

    //comb_part
    always_comb begin
        comb_result = '0;
        comb_nv     = '0;
        msb_pos     = '0;

        // Converter from fp32 to int32 
        if ( is_fp32_i )
            //============== Handler for specific cases ==============
            // NaN/Inf and overflow detector: exp = 255 or exp > 158 for overflow
            if ( a_i[30:23] > EXP_OVERFLOW )
                comb_nv = 1'b1;

            // Min int32 detector
            // If exp == 158 only one number can be valid after converting. 
            // Other numbers after converting will be overflow.
            else if ( a_i[30:23] == EXP_OVERFLOW )
                if ( a_i == 32'hCF000000 ) 
                    comb_result[31] = 1'b1;
                else
                    comb_nv = 1'b1;

            // Subnormal and small numbers detector 
            else if ( a_i[30:23] < EXP_BIAS)
                comb_result = '0;

            //============== Converter from fp32 to int32 ==============
            else begin
                msb_pos = a_i[30:23] - EXP_BIAS;
                abs_data = { 1'b1, a_i[22:0], 8'b0000_0000 };
                abs_data = abs_data >> (31 - msb_pos);

                // Sign handler
                if ( a_i[31] == 1'b1 )
                    comb_result = (~ abs_data) + 32'b1;
                else
                    comb_result = abs_data;
            end

        // Converter from int32 to fp32 part
        else begin
            // Abs of num calculating
            if ( a_i[31] == 1) begin
                abs_data        = (~ a_i) + 32'b1;
                comb_result[31] = 1'b1;
            end
            else
                abs_data = a_i;            

            data = abs_data;

            // need to find msb pos
            if ( data[31:16] ) begin msb_pos = msb_pos + 6'd16; data = data >> 16; end 
            if ( data[15:8]  ) begin msb_pos = msb_pos + 6'd8;  data = data >> 8;  end   
            if ( data[7:4]   ) begin msb_pos = msb_pos + 6'd4;  data = data >> 4;  end   
            if ( data[3:2]   ) begin msb_pos = msb_pos + 6'd2;  data = data >> 2;  end 
            if ( data[1]     ) begin msb_pos = msb_pos + 6'd1;                     end   

            // Exp calculating
            comb_result[30:23] = ( abs_data == 0 ) ? 8'b0 : msb_pos + EXP_BIAS;

            // Mantissa calculating
            abs_data          = abs_data  << ( 31 - msb_pos );
            comb_result[22:0] = abs_data[30:8];
        end
    end

    //reg part
    always_ff @(posedge clk_i or posedge rst_i )
        if ( rst_i ) begin
            nv_reg     <= '0;
            result_reg <= '0;
        end
        else begin
            result_reg <= comb_result;
            nv_reg     <= comb_nv;
        end

    assign result_o = result_reg;
    assign nv_o     = nv_reg;
endmodule      