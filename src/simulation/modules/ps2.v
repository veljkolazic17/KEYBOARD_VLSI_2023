module ps2(
		   input CLOCK,
		   input PS2_KBCLK,
           input PS2_KBDAT,
           output [15:0]code_vector,
           input rst_n,
			  output[1:0] ERR_CODE
		);
		
		
		reg data_bit;
		
		localparam NOT_ACTIVE = 0;
		localparam READING = 1;
		localparam END_READ = 2;
		
		reg [1:0]STATE_reg = 0;
		reg [1:0]STATE_next = 0;
		
		integer COUNTER_reg = 0;
		integer COUNTER_next = 0;
		
		reg [7:0] code_vector_buffer_reg = 0;
		reg [7:0] code_vector_buffer_next = 0;
		
		reg [15:0] code_vector_reg = 0;
		reg [15:0] code_vector_next = 0;
		
		reg [1:0] err_code_reg = 0;
		reg [1:0] err_code_next = 0;		
		
		integer parity_counter_reg = 0;
		integer parity_counter_next = 0;
		
		
		assign code_vector = code_vector_reg;
		assign ERR_CODE = err_code_reg;
		
		
		
		always @(posedge CLOCK, negedge rst_n) begin
            if(!rst_n) begin
                STATE_reg <= 0;
                code_vector_buffer_reg <= 0;
                COUNTER_reg <= 0;
                code_vector_reg <= 0;
					 err_code_reg <= 0;
					 parity_counter_reg <= 0;
            end

            else begin
                STATE_reg <= STATE_next;
                code_vector_buffer_reg <= code_vector_buffer_next;
                COUNTER_reg <= COUNTER_next;
                code_vector_reg <= code_vector_next;
					 err_code_reg <= err_code_next;
					 parity_counter_reg <= parity_counter_next;
            end
		end
		
		always @(negedge PS2_KBCLK) begin
			data_bit = PS2_KBDAT;
			
			
			STATE_next = STATE_reg;
			code_vector_buffer_next =  code_vector_buffer_reg;
			COUNTER_next = COUNTER_reg;
			code_vector_next = code_vector_reg;
			err_code_next = err_code_reg;
			parity_counter_next = parity_counter_reg;
			
			case (STATE_next) 
				NOT_ACTIVE: begin
					if(data_bit == 0) begin
						STATE_next = READING;
						COUNTER_next = 0;
						err_code_next = 0;
					end					
				end
				READING: begin
					code_vector_buffer_next[COUNTER_next] = data_bit;
					
					if(data_bit == 1) begin
						parity_counter_next = parity_counter_next + 1;
					end 
					
					
					COUNTER_next = COUNTER_next + 1;
					if(COUNTER_next == 8) begin
						COUNTER_next = 0;
						STATE_next = END_READ;
					end
				end
			
				END_READ: begin
					if(COUNTER_next == 0) begin
						if(data_bit == 1'b1 && parity_counter_next % 2 == 1 || data_bit == 1'b0 && parity_counter_next % 2 == 0) begin
							// COUNTER_next = 0;
							// parity_counter_next = 0;
							// code_vector_next = 0;
							// code_vector_buffer_next = 0;
							
							err_code_next = 2'b01;
						end
					end
					
					if(COUNTER_next == 1) begin
						if(data_bit == 0) begin
							code_vector_next = 0;
							code_vector_buffer_next = 0;
							err_code_next = err_code_next | 2'b10;
						end
						else begin
							if(err_code_next != 2'b01) begin
								if(code_vector_next[7:0] == code_vector_buffer_next || (
								code_vector_next[7:0] != 8'hE0 && code_vector_next[7:0] != 8'hF0 && code_vector_next[15:8] == 8'h00
								)) begin
									code_vector_next = {{8{1'b0}}, code_vector_buffer_next};
								end		
								else if(	(code_vector_next[15:8] == 8'hF0 || code_vector_next[15:8] == 8'hE0) &&
											(code_vector_next[7:0] != 8'hF0 && code_vector_next[7:0] != 8'hE0)
								) begin 
									code_vector_next = 0;
									code_vector_next = code_vector_next | code_vector_buffer_next;
								end
								else begin
									code_vector_next = code_vector_next << 8;
									code_vector_next = code_vector_next | code_vector_buffer_next;
								end	
							end	
							else begin
								code_vector_next = 0;
								code_vector_buffer_next = 0;
							end
						end
						COUNTER_next = -1;
						parity_counter_next = 0;
						STATE_next = NOT_ACTIVE;
					end
					
					COUNTER_next = COUNTER_next + 1;
				
				end	
			endcase
		
		
		end
    
    
		

        
endmodule