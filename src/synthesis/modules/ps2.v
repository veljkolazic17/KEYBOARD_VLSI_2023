module ps2(input PS2_KBCLK,
           input PS2_KBDAT,
           output [15:0]code_vector);
    
    
    integer counter_reg        = -1, counter_next        = -1;
    integer parity_counter_reg = 0, parity_counter_next = 0;
    reg [15:0] code_vector_reg = 0;
    reg [15:0] code_vector_next = 0;
    
    assign code_vector = code_vector_reg;
    reg data_bit;
    
    localparam START       = 0;
    localparam STOP        = 1;
    localparam ODD_PARITY  = 1;
    localparam SECOND_BYTE = 8;

    reg start_bit_reg = 0, start_bit_next = 0;

    reg [15:0] code_vector_buffer_reg = 0, code_vector_buffer_next = 0;
    
    always @(negedge PS2_KBCLK) begin
         counter_reg        <= counter_next;
        code_vector_reg    <= code_vector_next;
        data_bit           <= PS2_KBDAT;
        parity_counter_reg <= parity_counter_next;
        code_vector_buffer_reg <= code_vector_buffer_next;
        start_bit_reg <= start_bit_next;
        
    end

    always @(*) begin
        counter_next        = counter_reg;
        code_vector_next    = code_vector_reg;
        parity_counter_next = parity_counter_reg;
        code_vector_buffer_next = code_vector_buffer_reg;
        start_bit_next = start_bit_reg;


        if (counter_next == 0) begin 
            if (data_bit != START) begin
                //error handling
                counter_next        = -1;
                parity_counter_next = 0;
                code_vector_buffer_next = 0;
                start_bit_next = 0;
            end
            else begin
                start_bit_next = 1;
            end
        end
        if (counter_next > 0  && counter_next < 9) begin
            code_vector_buffer_next[counter_next - 1] = data_bit;
            if (data_bit == 1'b1) begin
                parity_counter_next = parity_counter_next + 1;
            end
        end
        if (counter_next == 9) begin
            if ((data_bit == ODD_PARITY && parity_counter_next % 2 == 1) || (data_bit != ODD_PARITY && parity_counter_next % 2 == 0)) begin
            //error handling
            end
        end
        if (counter_next == 10) begin
            if (data_bit != STOP) begin
                //error handling
            end
            else begin
                 if(start_bit_next == 1) begin
                     code_vector_next = code_vector_next << SECOND_BYTE;
                     code_vector_next = code_vector_buffer_next | code_vector_next;
                 end
            end
            start_bit_next = 0;
            counter_next        = -1;
            parity_counter_next = 0;
            code_vector_buffer_next = 0;
        end
        counter_next = counter_next + 1;

    end
        
endmodule
