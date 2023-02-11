module ps2(
		   input CLOCK,
		   input PS2_KBCLK,
           input PS2_KBDAT,
           output [15:0]code_vector,
           input rst_n
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
		
		assign code_vector = code_vector_reg;
		
		
		always @(posedge CLOCK, negedge rst_n) begin
            if(!rst_n) begin
                STATE_reg <= 0;
                code_vector_buffer_reg <= 0;
                COUNTER_reg <= 0;
                code_vector_reg <= 0;
            end

            else begin
                STATE_reg <= STATE_next;
                code_vector_buffer_reg <= code_vector_buffer_next;
                COUNTER_reg <= COUNTER_next;
                code_vector_reg <= code_vector_next;
            end
		end
		




		always @(negedge PS2_KBCLK) begin
			data_bit = PS2_KBDAT;
			
			
			STATE_next = STATE_reg;
			code_vector_buffer_next =  code_vector_buffer_reg;
			COUNTER_next = COUNTER_reg;
			code_vector_next = code_vector_reg;
			
			case (STATE_next) 
				NOT_ACTIVE: begin
					if(data_bit == 0) begin
						STATE_next = READING;
						COUNTER_next = 0;
					end
				end
				READING: begin
					code_vector_buffer_next[COUNTER_next] = data_bit;
					COUNTER_next = COUNTER_next + 1;
					if(COUNTER_next == 8) begin
						COUNTER_next = 0;
						STATE_next = END_READ;
					end
				end
			
				END_READ: begin
					if(COUNTER_next == 0) begin
						//parity handling
					end
					
					if(COUNTER_next == 1) begin
						if(data_bit == 0) begin
							
						end
						else begin					
							code_vector_next = code_vector_next << 8;
							code_vector_next = code_vector_next | code_vector_buffer_next;
							
						end
						COUNTER_next = -1;
						STATE_next = NOT_ACTIVE;
					end
					
					COUNTER_next = COUNTER_next + 1;
				
				end
						
			
			endcase
		
		
		end
    
    
		

        
endmodule