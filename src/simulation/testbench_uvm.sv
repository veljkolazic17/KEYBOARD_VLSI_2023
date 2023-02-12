`include "uvm_macros.svh"
import uvm_pkg::*;

// Sequence Item
class ps2_item extends uvm_sequence_item;


	rand bit [10:0]PS2_KBDAT;
	//rand bit rst_n;
	bit [15:0] code_vector;
	bit [1:0]ERR_CODE;

	constraint c1 { PS2_KBDAT[0] inside {1'b0}; }
	constraint c2 { PS2_KBDAT[10] inside {1'b1}; }
	constraint c3 { PS2_KBDAT[9] == !((PS2_KBDAT[1] + PS2_KBDAT[2] + PS2_KBDAT[3] + PS2_KBDAT[4] + PS2_KBDAT[5] + PS2_KBDAT[6] + PS2_KBDAT[7] + PS2_KBDAT[8])%2); }

	
	`uvm_object_utils_begin(ps2_item)
		`uvm_field_int(PS2_KBDAT, UVM_DEFAULT)
		//`uvm_field_int(rst_n, UVM_DEFAULT)
		`uvm_field_int(code_vector, UVM_DEFAULT)
		`uvm_field_int(ERR_CODE, UVM_DEFAULT)
	`uvm_object_utils_end
	
	function new(string name = "ps2_item");
		super.new(name);
	endfunction
	
	virtual function string my_print();
		return $sformatf(
			"PS2_KBDAT = %11b rst_n = %1b code_vector = %16b ERR_CODE = %2b",
			 PS2_KBDAT, 1, code_vector, ERR_CODE
		);
	endfunction

endclass

// Sequence
class generator extends uvm_sequence;

	`uvm_object_utils(generator)
	
	function new(string name = "generator");
		super.new(name);
	endfunction
	
	int num = 100;
	
	virtual task body();
		for (int i = 0; i < num; i++) begin
			ps2_item item = ps2_item::type_id::create("item");
			start_item(item);
			item.randomize();
			`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
			item.print();
			finish_item(item);
		end
	endtask
	
endclass

// Driver
class driver extends uvm_driver #(ps2_item);
	
	`uvm_component_utils(driver)
	
	function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			ps2_item item;
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)

			for(int i = 0; i<11;i = i + 1) begin
				vif.PS2_KBDAT <= item.PS2_KBDAT[i];
				//vif.rst_n <= item.rst_n;
				@(negedge vif.PS2_KBCLK);
				@(posedge vif.CLOCK);
			end			
			seq_item_port.item_done();
		end
	endtask
	
endclass

// Monitor

class monitor extends uvm_monitor;
	
	`uvm_component_utils(monitor)
	
	function new(string name = "monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	uvm_analysis_port #(ps2_item) mon_analysis_port;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Monitor", "No interface.")
		mon_analysis_port = new("mon_analysis_port", this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);	
		super.run_phase(phase);
		@(negedge vif.PS2_KBCLK);
		@(posedge vif.CLOCK);
		forever begin
			ps2_item item = ps2_item::type_id::create("item");
			for(int i = 0; i < 11; i = i + 1) begin
				@(negedge vif.PS2_KBCLK);
				@(posedge vif.CLOCK);

				item.PS2_KBDAT[i] = vif.PS2_KBDAT;
				item.code_vector = vif.code_vector;
				// item.rst_n = vif.rst_n;
				item.ERR_CODE = vif.ERR_CODE;
				
			end
			`uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_LOW)
			mon_analysis_port.write(item);
		end
	endtask
	
endclass

// Agent
class agent extends uvm_agent;
	
	`uvm_component_utils(agent)
	
	function new(string name = "agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	driver d0;
	monitor m0;
	uvm_sequencer #(ps2_item) s0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		d0 = driver::type_id::create("d0", this);
		m0 = monitor::type_id::create("m0", this);
		s0 = uvm_sequencer#(ps2_item)::type_id::create("s0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		d0.seq_item_port.connect(s0.seq_item_export);
	endfunction
	
endclass

// Scoreboard
class scoreboard extends uvm_scoreboard;
	
	`uvm_component_utils(scoreboard)
	
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	uvm_analysis_imp #(ps2_item, scoreboard) mon_analysis_imp;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_analysis_imp = new("mon_analysis_imp", this);
	endfunction
	
	reg data_bit;
	
	localparam NOT_ACTIVE = 0;
	localparam READING = 1;
	localparam END_READ = 2;
	
	reg [1:0]STATE_next = 0;
	integer COUNTER_next = 0;
	reg [7:0] code_vector_buffer_next = 0;
	reg [15:0] code_vector_next = 0;
	reg [1:0] err_code_next = 0;		
	integer parity_counter_next = 0;
	
	virtual function write(ps2_item item);
	
		if (code_vector_next == item.code_vector)
			`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		else
			`uvm_error("Scoreboard", $sformatf("FAIL! expected = %16b, got = %16b", code_vector_next, item.code_vector))


		// LOGIKA
		for(int i = 0 ;i<11; i = i + 1) begin
			data_bit = item.PS2_KBDAT[i];

			
			case (STATE_next) 
				NOT_ACTIVE: begin
					if(data_bit == 0) begin
						STATE_next = READING;
						COUNTER_next = 0;
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
							STATE_next = NOT_ACTIVE;
							COUNTER_next = 0;
							parity_counter_next = 0;
							code_vector_next = 0;
							code_vector_buffer_next = 0;
							
							err_code_next = 2'b01;
						end
					end
					
					if(COUNTER_next == 1) begin
						if(data_bit == 0) begin
							code_vector_next = 0;
							code_vector_buffer_next = 0;
							err_code_next = 2'b10;
						end
						else begin
							
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
						COUNTER_next = -1;
						parity_counter_next = 0;
						STATE_next = NOT_ACTIVE;
					end
					
					COUNTER_next = COUNTER_next + 1;
				
				end	
			endcase
		end

		
		
	endfunction
	
endclass

// Environment
class env extends uvm_env;
	
	`uvm_component_utils(env)
	
	function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	agent a0;
	scoreboard sb0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a0 = agent::type_id::create("a0", this);
		sb0 = scoreboard::type_id::create("sb0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
	endfunction
	
endclass

// Test
class test extends uvm_test;

	`uvm_component_utils(test)
	
	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;

	env e0;
	generator g0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Test", "No interface.")
		e0 = env::type_id::create("e0", this);
		g0 = generator::type_id::create("g0");
	endfunction
	
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		vif.rst_n <= 0;
		#20 vif.rst_n <= 1;
		
		g0.start(e0.a0.s0);
		phase.drop_objection(this);
	endtask

endclass

// Interface
interface ps2_if (
	input bit CLOCK,
	input bit PS2_KBCLK
);


	logic PS2_KBDAT;
	logic rst_n;
	logic [15:0] code_vector;
	logic [1:0]ERR_CODE;

endinterface

// Testbench
module testbench_uvm;

	reg CLOCK;
	reg PS2_KBCLK;
	
	ps2_if dut_if (
		.CLOCK(CLOCK),
		.PS2_KBCLK(PS2_KBCLK)
	);
	
	ps2 dut (
		.CLOCK(CLOCK),
		.PS2_KBCLK(PS2_KBCLK),
		.PS2_KBDAT(dut_if.PS2_KBDAT),
		.code_vector(dut_if.code_vector),
		.rst_n(dut_if.rst_n),
		.ERR_CODE(dut_if.ERR_CODE)
	);

	initial begin
		CLOCK = 0;
		PS2_KBCLK = 0;
	end

	always begin
		#1 CLOCK = ~CLOCK;
	end

	always begin
		#10 PS2_KBCLK = ~PS2_KBCLK;
	end

	initial begin
		uvm_config_db#(virtual ps2_if)::set(null, "*", "ps2_vif", dut_if);
		run_test("test");
	end

endmodule
