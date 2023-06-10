module bitcoin_hash (
 input logic clk, reset_n, start,
 input logic[15:0] message_addr, output_addr,
 output logic done, mem_clk, mem_we,
 output logic[15:0] mem_addr,
 output logic [31:0] mem_write_data,
 input logic [31:0] mem_read_data);

parameter num_nonces = 16;

enum logic [4:0] {IDLE, READ, PHASE1, PHASE2, WRITE} state;
logic [31:0] hout[num_nonces];
logic [31:0] message[16];
logic [31:0] message_tail[16][4];
logic [31:0] result_phase1[8];
logic [31:0] result_phase2[16][8];

logic        cur_we;
logic [15:0] cur_addr;
logic [31:0] cur_write_data;
logic [7:0]  offset;

assign mem_clk = clk;
assign mem_addr = cur_addr + offset;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;

logic 		 rstn_phase1 = 1;
logic [15:0] rstn_phase2 = 16'hffff;
logic 		 start_phase1 = 0;
logic [15:0] start_phase2 = 0;
logic 		 done_phase1;
logic [15:0] done_phase2;

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

onephase_sha256 phase1(.clk, .reset_n(rstn_phase1), .start(start_phase1), .message, .result(result_phase1), .done(done_phase1));

genvar i;
generate
	for(i = 0; i < 16; i = i + 1) begin: phase2_loop
		twophase_sha256 phase2(.clk, .reset_n(rstn_phase2[i]), .start(start_phase2[i]), .inh(result_phase1), .outs(result_phase2[i]), .message(message_tail[i]), .done(done_phase2[i]));
	end : phase2_loop
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
			// Phase for initialization
			IDLE: begin
				if(start) begin
					cur_we <= 0;
					offset <= 0;
					cur_addr <= message_addr;
					state <= READ;
					rstn_phase1 <= 0;
					rstn_phase2 <= 0;
					for(int k = 0; k < 16; k++) begin
						message_tail[k][3] <= k; // nonce
					end
				end
			end
			
			READ: begin
				if (offset <= 16)
					message[offset-1] <= mem_read_data;
				else if(offset <= 19) begin // 4 cycles pipelineable 
					for(int k = 0; k < 16; k++) begin
						message_tail[k][offset-17] <= mem_read_data;
					end
				end
					
				if(offset == 19) begin
					rstn_phase1 <= 'b1;
					rstn_phase2 <= 16'hffff;
					start_phase1 <= 'b1;
					state <= PHASE1;
				end
				else begin
					state <= READ;
					offset <= offset + 1;
				end
			end
			
			PHASE1: begin
				if(done_phase1) begin
					start_phase2 <= 16'hffff;
					state <= PHASE2;
				end
				start_phase1 <= 0;
//				else state <= PHASE1;
			end
			
			PHASE2: begin
				if(&done_phase2) begin
					cur_addr <= output_addr - 1;
					offset <= 0;
					cur_we <= 1;
					state <= WRITE;
				end
				start_phase2 <= 0;
			end
			
			WRITE: begin
				if(offset < 16) begin
					cur_write_data <= result_phase2[offset][0];
					offset <= offset + 1;
					state <= WRITE;
				end
				else begin
					state <= IDLE;
					cur_we <= 0;
				end
			end
			
		endcase
	end
end

assign done = (state == IDLE);

endmodule