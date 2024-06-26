// Simplied sha256 for one block operation
module onephase_sha256 #(parameter integer NUM_OF_WORDs = 16)(
	input  logic clk, reset_n, start,
	input  logic [31:0] message[16],
	output logic [31:0] result[8],
	output logic done);

// K constant for sha
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

// FSM state variables
enum logic [2:0] {IDLE, READ, BLOCK, PRECOMP, COMPUTE, WRITE, DONE} state;

// Local variables
logic [31:0] w[16];
logic [31:0] wt;
logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
logic [31:0] a, b, c, d, e, f, g, h;
logic [ 7:0] i, j;
logic [15:0] offset;
logic [ 7:0] num_blocks, block_idx;
logic [ 7:0] tstep;
assign tstep = (i - 1);

// function for right rotation (multiple use by other functions)
function logic [31:0] rightrotate(	input logic [31:0] x,
												input logic [ 7:0] r);
	rightrotate = (x >> r) | (x << (32 - r));
endfunction


// function for word expansion
function logic [31:0] wtnew;
	logic [31:0] s0, s1;
	
	s0 = rightrotate(w[1],7) ^ rightrotate(w[1],18) ^ (w[1]>>3);
	s1 = rightrotate(w[14],17) ^ rightrotate(w[14],19) ^ (w[14]>>10);
	wtnew = w[0] + s0 + w[9] + s1;
endfunction

// SHA256 Hash round
function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w,
											input logic [ 7:0] t);
	// internal signals
	logic [31:0] s1, s0, ch, maj, t1, t2;
	begin
		s1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
		ch = (e & f) ^ ((~e) & g);
		t1 = h + s1 + ch + k[t] + w;
		s0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
		maj = (a & b) ^ (a & c) ^ (b & c);
		t2 = s0+maj;
		sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
	end
endfunction


// SHA256 FSM (non-blocking statements)
always_ff @(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		state <= IDLE;
	end
	else begin
		case(state)
			// initial state to initiate varibles
			IDLE: begin
				if(start) begin
					h0 <= 32'h6a09e667;
					h1 <= 32'hbb67ae85;
					h2 <= 32'h3c6ef372;
					h3 <= 32'ha54ff53a;
					h4 <= 32'h510e527f;
					h5 <= 32'h9b05688c;
					h6 <= 32'h1f83d9ab;
					h7 <= 32'h5be0cd19;
					
					offset <= 0;
					i <= 0; j <= 0;
					
					state <= READ;
				end
			end
			
			// state to read in message, values in message already read by bitcoin hashing
			READ: begin
				state <= BLOCK;
			end
			
			// state to get values into w[t], values in message already read by bitcoin hashing
			BLOCK: begin
				for(int t = 0; t < 16; t = t + 1) begin
					w[t] <= message[t];
					
					{a, b, c, d, e, f, g, h} <= {h0, h1, h2, h3, h4, h5, h6, h7};
					state <= PRECOMP;
				end
			end
			
			// pre computation state
			PRECOMP: begin
				wt <= w[0];
				i <= 1;
				state <= COMPUTE;
			end
			
			// state to compute one block hash computation and move to write state
			COMPUTE: begin
				// 64 processing rounds steps for one 512 bits block
				if(i < 65) begin
					if(i < 16) begin
						wt <= w[i];
					end
					else begin
						wt <= wtnew();
						for(int n = 0; n < 15; n++) begin
							w[n] <= w[n + 1];
						end
						w[15] <= wtnew();
					end
					{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, wt, tstep);
					i <= i + 1;
				end
				
				else begin
					h0 <= h0 + a;
					h1 <= h1 + b;
					h2 <= h2 + c;
					h3 <= h3 + d;
					h4 <= h4 + e;
					h5 <= h5 + f;
					h6 <= h6 + g;
					h7 <= h7 + h;
					
					i <= 0;
					state <= WRITE;
				end
			end
			
			// state to write the computed hash value to output result
			WRITE: begin
				result[0] <= h0;
				result[1] <= h1;
				result[2] <= h2;
				result[3] <= h3;
				result[4] <= h4;
				result[5] <= h5;
				result[6] <= h6;
				result[7] <= h7;
				
				state <= DONE;
			end
			
			DONE: begin
				state <= DONE;
			end
		endcase
	end
end

// Generate done when SHA256 hash computation is finished and moved to IDLE state
assign done = (state == DONE);

endmodule