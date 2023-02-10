module testbench;
    reg clk, data_in;
    wire [15:0] data_out;
    ps2 ps2Instance(clk, data_in, data_out);

    initial begin
        clk = 1'b1;
        #5;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        // ------------------------------------------------------
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        // ----------------------------------------------------------
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        // -------------------------------------------------------------
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b1;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b0;
        #10;
        data_in = 1'b1;
        #1000;
        $finish;
    end

    always @(data_out) begin
        $display("Val : %16.b", data_out);
    end

    always #5 begin
        clk = ~clk;
    end

endmodule
