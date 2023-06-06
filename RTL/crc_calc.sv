
//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//-----------------------------------------------------------------------------
// CRC module for data[7:0] ,   crc[7:0]=1+x^4+x^5+x^8;
//-----------------------------------------------------------------------------
module crc_calc(
  input [7:0] data_in,
  input crc_en,
  output [7:0] crc_out,
  input clear,
  input rst,
  input clk);

  reg [7:0] lfsr_q,lfsr_c;

  assign crc_out = lfsr_q;

  always @(*) begin
    lfsr_c[0] = lfsr_q[0] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[6] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    lfsr_c[1] = lfsr_q[1] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[7] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7];
    lfsr_c[2] = lfsr_q[2] ^ lfsr_q[5] ^ lfsr_q[6] ^ data_in[2] ^ data_in[5] ^ data_in[6];
    lfsr_c[3] = lfsr_q[3] ^ lfsr_q[6] ^ lfsr_q[7] ^ data_in[3] ^ data_in[6] ^ data_in[7];
    lfsr_c[4] = lfsr_q[0] ^ lfsr_q[3] ^ lfsr_q[6] ^ lfsr_q[7] ^ data_in[0] ^ data_in[3] ^ data_in[6] ^ data_in[7];
    lfsr_c[5] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[3] ^ lfsr_q[6] ^ lfsr_q[7] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[6] ^ data_in[7];
    lfsr_c[6] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[4] ^ lfsr_q[7] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[7];
    lfsr_c[7] = lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[5] ^ data_in[2] ^ data_in[3] ^ data_in[5];  
  end // always

  always @(posedge clk, negedge rst) begin
    if(!rst) lfsr_q <= 8'hFF;
    else begin
      if(clear) lfsr_q <= 8'hFF;
      else lfsr_q <= crc_en ? lfsr_c : lfsr_q;
    end
  end // always

endmodule // crc