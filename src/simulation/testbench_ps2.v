module testbench_ps2;
    
reg dut_clk;
reg dut_rst_n;
reg dut_kb_data;
reg dut_kb_clk;
wire [15:0] dut_buffer_out;
wire dut_error;


ps2 dut(
    dut_kb_clk,
    dut_kb_data,
    dut_buffer_out
);

initial begin
    dut_clk = 1'b0;
    dut_rst_n = 1'b0;
    dut_kb_clk = 1'b1;



    dut_kb_data = 1'b0;
    #100 dut_kb_data = 1'b1;

    #160 dut_kb_data = 1'b0;
    #60 dut_kb_data = 1'b1;
    #60 dut_kb_data = 1'b0;
    #80 dut_kb_data = 1'b1;
    #100
    $finish;

end

always begin
    #1 dut_clk = ~dut_clk;
end

always begin
    #10 dut_kb_clk = ~dut_kb_clk;
end

always @(negedge dut_kb_clk) begin
    $strobe(
            "time = %0d, dut_kb_clk = %0d, dut_kb_data = %h, dut_buffer_out = %h",
            $time,
            dut_kb_clk,
            dut_kb_data,
            dut_buffer_out
        );
end

endmodule