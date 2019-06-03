// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// APB Read-Write Registers
// This module exposes a number of 32-bit registers (provided on the `reg_i` input) writable on an
// APB interface.  It responds to accesses that are out of range with a slave error.
module apb_rw_regs #(
  parameter int unsigned N_REGS = 0
) (
  // APB Interface
  input  logic        pclk_i,
  input  logic        preset_ni,
  input  logic [31:0] paddr_i,
  input  logic  [2:0] pprot_i,
  input  logic        psel_i,
  input  logic        penable_i,
  input  logic        pwrite_i,
  input  logic [31:0] pwdata_i,
  input  logic  [3:0] pstrb_i,
  output logic        pready_o,
  output logic [31:0] prdata_o,
  output logic        pslverr_o,

  // Register Interface
  input  logic [N_REGS-1:0][31:0] init_i,
  output logic [N_REGS-1:0][31:0] q_o
);

  logic [N_REGS-1:0][31:0] reg_d, reg_q;

  always_comb begin
    reg_d     = reg_q;
    prdata_o  = 'x;
    pslverr_o = 1'b0;
    if (psel_i) begin
      automatic logic [29:0] word_addr = paddr_i >> 2;
      if (word_addr >= N_REGS) begin
        // Error response to accesses that are out of range
        pslverr_o = 1'b1;
      end else begin
        if (pwrite_i) begin
          for (int i = 0; i < 4; i++) begin
            if (pstrb_i[i]) begin
              reg_d[word_addr][i*8 +: 8] = pwdata_i[i*8 +: 8];
            end
          end
        end else begin
          prdata_o = reg_q[word_addr];
        end
      end
    end
  end
  assign pready_o = psel_i & penable_i;

  assign q_o = reg_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q <= init_i;
    end else begin
      reg_q <= reg_d;
    end
  end

// Validate parameters.
// pragma translate_off
`ifndef VERILATOR
  initial begin: p_assertions
    assert (N_REGS >= 1) else $fatal(1, "The number of registers must be at least 1!");
  end
`endif
// pragma translate_on

endmodule
