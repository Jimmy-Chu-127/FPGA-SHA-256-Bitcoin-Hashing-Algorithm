module bitcoin_hash (
 input logic clk, reset_n, start,
 input logic[15:0] message_addr, output_addr,
 output logic done, mem_clk, mem_we,
 output logic[15:0] mem_addr,
 output logic [31:0] mem_write_data,
 input logic [31:0] mem_read_data);

parameter num_nonces = 16;
parameter num_words  = 20;


enum logic [4:0] {IDLE, READ, PHASE1, PHASE2, PHASE3, WRITE} state;

logic [31:0] message[16][16];
logic [31:0] result[8][16];
logic        start1;
logic        done1;
logic        cycle;

logic [31:0] hout[num_nonces];
logic			 cur_we;
logic [15:0] offset;
logic [15:0] cur_addr;
logic [31:0] cur_write_data;

// SHA256 K constants
parameter int k[64] = '{
	32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
	32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
	32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
	32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
	32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
	32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
	32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
	32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};


// Memory stuff
assign mem_clk = clk;
assign mem_addr = cur_addr + offset;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;


// One round sha initializations 16 instance
genvar q;
generate
	for(q = 0; q < NUM_NONCES; q++) begin: generate_sha256_blocks
		sha256_block block(
			.clk(clk),
			.reset_n(reset_n),
			.start(),
			.message(message[q]),
			.result(result[q]),
			.done(done)
		);
endgenerate


// Student to add rest of the code here
// SHA256 FSM
always_ff@(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		cur_we <= 1'b0;
		state <= IDLE;
	end
	
	else begin
		case(state)
			// state for initialization
			IDLE: begin
				if(start) begin
					cycle <= 0;
					offset <= 0;
					cur_we <= 0;
					
					state <= READ;
				end
				else begin
					state <= IDLE;
				end
			end
			
			// state for reading in the variables
			READ: begin
				if(cycle == 0) begin
					for(i = 0; i < num_words; i++) begin
						message[ 0][i] <= mem_read_data;
						message[ 1][i] <= mem_read_data;
						message[ 2][i] <= mem_read_data;
						message[ 3][i] <= mem_read_data;
						message[ 4][i] <= mem_read_data;
						message[ 5][i] <= mem_read_data;
						message[ 6][i] <= mem_read_data;
						message[ 7][i] <= mem_read_data;
						message[ 8][i] <= mem_read_data;
						message[ 9][i] <= mem_read_data;
						message[10][i] <= mem_read_data;
						message[11][i] <= mem_read_data;
						message[12][i] <= mem_read_data;
						message[13][i] <= mem_read_data;
						message[14][i] <= mem_read_data;
						message[15][i] <= mem_read_date;
					end
				end
				else if(cycle == 1) begin
					for(i = 0; i < )
				end
				else begin
				
				end
			end
			
			// state for phase 1 processing
			PHASE1: begin
				
			
				cycle <= cycle + 1;
				state <= READ;
			end
			
			// state for phase 2 processing
			PHASE2: begin
				
			
				cycle <= cycle + 1;
				state <= READ;
			end
			
			// state for phase 3 processing
			PHASE3: begin
				
				state <= WRITE;
			end
			
			// state for writing the hash to memory
			WRITE: begin
			
				state <= IDLE;
			end
		endcase
	end
end
































// Generate done when SHA256 computation has finished and moved to IDLE
assign done = (state == IDLE);

endmodule