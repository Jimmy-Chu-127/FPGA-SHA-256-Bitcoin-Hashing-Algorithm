module bitcoin_hash (
 input logic clk, reset_n, start,
 input logic[15:0] message_addr, output_addr,
 output logic done, mem_clk, mem_we,
 output logic[15:0] mem_addr,
 output logic [31:0] mem_write_data,
 input logic [31:0] mem_read_data);

parameter num_nonces = 16;
parameter num_words  = 20;
logic [63:0] message_size = 640;


enum logic [4:0] {IDLE, READ, PREP1, PREP2, PREP3, PHASE1, PHASE2, PHASE3, WRITE, DONE} state;

logic [31:0] message1[32];                          // Double check for pack unpacked array
logic [31:0] message2[16][16];
logic [31:0] result[16][8];

logic        start1;
logic			 done1;
logic			 round2;

logic        done;
logic        i, j;

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
			.start(start1),
			.message(message2[q]),
			.hash_val(result[q]),
			.round2(round2),
			.result(result[q]),
			.done(done1)
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
					cur_addr <= message_addr;
					cur_we <= 0;
					
					state <= READ;
				end
				else begin
					state <= IDLE;
				end
			end
			
			// state for reading in the variables
			// the nonce will be changed in prep states
			READ: begin
				if(offset < num_words-1) begin
					message[offset-1] <= mem_read_data;
				end
				else if(offset == 20) begin
					message[offset-1] <= 32'h80000000;
				end
				else if(offset == 31) begin
					message[offset-1] <= message_size;
					state  <= PREP1;
					offset <= 0;
				end
				else begin
					message[offset-1] <= 32'h00000000;
				end
				offset <= offset + 1;
			end
			
			// state for preping the data for phase 1
			PREP1: begin
				for(i = 0; i < 16; i++) begin
					for(j = 0; j < 16; j++) begin
						message2[i][j] <= message1[j];
					end
				end
				state <= PHASE1;
			end
			
			// state for preping the data for phase 2
			PREP2: begin
				for(i = 0; i < 16; i++) begin
					for(j = 0; j < 3; j++) begin
						message2[i][j] <= message1[j+16];
					end
				end
				
				message2[ 0][3] <= 32'd0;
				message2[ 1][3] <= 32'd1;
				message2[ 2][3] <= 32'd2;
				message2[ 3][3] <= 32'd3;
				message2[ 4][3] <= 32'd4;
				message2[ 5][3] <= 32'd5;
				message2[ 6][3] <= 32'd6;
				message2[ 7][3] <= 32'd7;
				message2[ 8][3] <= 32'd8;
				message2[ 9][3] <= 32'd9;
				message2[10][3] <= 32'd10;
				message2[11][3] <= 32'd11;
				message2[12][3] <= 32'd12;
				message2[13][3] <= 32'd13;
				message2[14][3] <= 32'd14;
				message2[15][3] <= 32'd15;
				
				for(i = 0; i < 16; i++) begin
					for(j = 4; j < 16; j++) begin
						message2[i][j] <= message1[j+16];
					end
				end
				
				state  <= PHASE2;
				round2 <= 1;
			end
			
			// state for preping the data for phase 3
			PREP3: begin
			
			end
			
			// state for phase 1 processing
			PHASE1: begin
				start1 <= 1; 
			
				if(done1) begin
					state  <= PREP2;
					start1 <= 0;
					
					
				end
				else begin
					state  <= PHASE1;
				end
			end
			
			// state for phase 2 processing
			PHASE2: begin
				start1 <= 1;
				
				if(done1) begin
					state  <= PREP3;
					start1 <= 0;
				end
				else begin
					state  < PHASE2;
				end
			end
			
			// state for phase 3 processing
			PHASE3: begin
				
				state <= WRITE;
			end
			
			// state for writing the hash to memory
			WRITE: begin
			
				state <= DONE;
			end
			
			// state to show the sha is done with operations
			DONE: begin
				state <= IDLE;
			end
		endcase
	end
end
































// Generate done when SHA256 computation has finished and moved to IDLE
assign done = (state == IDLE);

endmodule