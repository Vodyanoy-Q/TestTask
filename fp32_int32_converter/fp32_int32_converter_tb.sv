module top;
    logic        clk_i;
    logic        rst_i;
    logic        is_fp32_i;
    logic [31:0] a_i;
    logic [31:0] result_o;
    logic        nv_o;

    fp32_int32_converter u_fp32_int32_converter(
        .clk_i     ( clk_i     ),
        .rst_i     ( rst_i     ),
        .is_fp32_i ( is_fp32_i ),
        .a_i       ( a_i       ),
        .result_o  ( result_o  ),
        .nv_o      ( nv_o      )
    );
    //----------------------------------------
    initial begin
        $dumpfile("fp32_int32_converter_dump.vcd");
        $dumpvars;
    end
    //----------------------------------------
    initial begin
        clk_i = 0;
        forever
            #500 clk_i = ~ clk_i;
    end
    //----------------------------------------
    integer f_in;
    integer f_res;
    integer f_exp;
    integer f_log;
    integer val;
    integer NUMBER_OF_TESTS;

    initial begin
        f_in = $fopen("test_data.txt", "r");
        if (f_in == 0) begin
            $display("ERROR: can not open input file.");
            $finish;
        end

        f_res = $fopen("test_result.txt", "w");
        if (f_res == 0) begin
            $display("ERROR: can not open output file.");
            $fclose(f_in);
            $finish;
        end

        f_exp = $fopen("test_expected.txt", "r");
        if (f_exp == 0) begin
            $display("ERROR: can not open file with expected outputs.");
            $fclose(f_in);
            $fclose(f_res);
            $finish;
        end

        f_log = $fopen("logs.txt", "w");
        if (f_log == 0) begin
            $display("ERROR: can not open file with expected outputs.");
            $fclose(f_in);
            $fclose(f_res);
            $fclose(f_exp);
            $finish;
        end

        NUMBER_OF_TESTS = 565;
    end
    //----------------------------------------
    logic   is_fp32_i_ff;
    integer exp_format;
    integer exp_nv;
    integer exp_data;
    integer error_count;
    integer error_flag;

    initial begin
        error_count = 0;
        rst_i = 1;
        #2000
        rst_i = 0;
        #1000

        for (int i = 0; i < NUMBER_OF_TESTS; i++) begin
            @(posedge clk_i)
            error_flag = 0;
            is_fp32_i_ff <= is_fp32_i;

            if ( $fscanf(f_in, "%d %h" , is_fp32_i, a_i) != 2) begin
                $display("WARNING: Can not read data from input file in test %0d", i);
                $fdisplay(f_log, "WARNING: Can not read data from input file in test %0d", i);
            end

            if ( i > 0 ) begin
                #1 $fdisplay(f_res, "%0d %0d %h", is_fp32_i_ff, nv_o, result_o);

                if ( $fscanf(f_exp, "%b %b %h" , exp_format, exp_nv, exp_data) != 3) begin
                    $display("WARNING: Can not read data from expected data file in test %0d", i);
                    $fdisplay(f_log, "WARNING: Can not read data from expected data file in test %0d", i);
                end
                
                if ( is_fp32_i_ff != exp_format || nv_o != exp_nv || result_o != exp_data ) begin
                    error_count = error_count + 1;
                    error_flag  = 1;
                    $display("Incorrect result in test %0d", i);
                    $fdisplay(f_log, "Incorrect result in test %0d", i);
                end
            end
        end
        @(posedge clk_i)
        #1 $fdisplay(f_res, "%d %d %h", is_fp32_i_ff, nv_o, result_o);
        #5000

        $display("============================================================");
        $display("END OF TESTS");
        if ( error_count == 0 )
            $display("ALL TESTS PASSED");
        else begin
            $display("%0d tests PASSED", NUMBER_OF_TESTS - error_count);
            $display("%0d errors", error_count);
        end
        $display("============================================================");

        $fdisplay(f_log, "============================================================");
        $fdisplay(f_log, "END OF TESTS");
        if ( error_count == 0 )
            $fdisplay(f_log, "ALL TESTS PASSED");
        else begin
            $fdisplay(f_log, "%0d tests PASSED", NUMBER_OF_TESTS - error_count);
            $fdisplay(f_log, "%0d errors", error_count);
        end
        $fdisplay(f_log, "============================================================");

        $fclose(f_in);
        $fclose(f_res);
        $fclose(f_exp);
        $fclose(f_log);
        
        $finish;
    end


endmodule