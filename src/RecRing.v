/*
 * Copyright (c) 2026 Andrew Noonan
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_ReconfigRing_AKNoonan (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  ReconRingOscCore CORE1(ui_in[0],clk,rst_n,uo_out[0],uo_out[1],uo_out[2],uo_out[3],uo_out[4]);
  wire DIVL, DIVH, DIVBeat;
  CLKDIV LOWloopDiv(rst_n, uo_out[1], DIVL);
  CLKDIV HIGHloopDiv(rst_n, uo_out[2], DIVH);
  AND2 BEATLOWSPEED(DIVL,DIVH,DIVBeat);
  assign uo_out[5] = DIVL;
  assign uo_out[6] = DIVH;
  assign uo_out[7] = DIVBeat;

  // List all unused inputs to prevent warnings
    logic _unused_ena;
    logic _unused_ioin;
    logic _unused_inp;
    assign _unused_ena = &{1'b0, ena};
    assign _unused_ioin = &{8'b0, uio_in[7:0]};
    assign _unused_inp = &{7'b0, ui_in[7:1]};

    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    

endmodule

//Clock Divider
module CLKDIV(
  input wire RST, //reset active low
  input wire ClkIN, //clock input
  output reg ClkOUT //clock output
);

reg [15:0] CNT;
    always @(posedge ClkIN or negedge RST) 
begin
 if(RST==1'b0)
  CNT <= 16'b0; 
 else 
  CNT <= CNT + 16'd1;
  if(CNT == 16'd4096)
   CNT <= 0; 
  ClkOUT <= ~ClkOUT;
end 
endmodule 

//ReconRing with break N=12 stages 
//positive edge clocked
//negetive edge REST
//reset status is 00 ... 10x00's ... 00 000 or dont cross loops for speed and dont pull from bypass loop for all 12 stages
//                          dont break Low Loop dont break High Loop dont break Bypass Loop
//each crossover flip flop cascades to the next creating a bitstream of SBSBSBSBS of speed and bypass across the loop
module ReconRingOscCore(
input wire D, //bitstrem in
input wire CLK, //bitstream clock
input wire RST, //reset active lop
output reg Q, //bitstream out
output PhaseA, //loop output
output PhaseB, //loop output
output BypassOut,//bypass output
output BeatAB //loop beat frequency
);

wire Stage1L, Stage1Ln, Stage1H, Stage1B, Stage1Q;
ConfigCrossover Stage1(D,CLK,RST,Stage1Q,Stage12Ln,Stage12H,Stage12B,Stage1L,Stage1H,Stage1B);
assign Stage1Ln = ~Stage1L;

assign PhaseA = Stage1L;
assign PhaseB = Stage1H;
assign BypassOut = Stage1B;
AND2 ANDBreakL(Stage1L,Stage1H,BeatAB);

wire Stage2L, Stage2Ln, Stage2H, Stage2B, Stage2Q;
ConfigCrossover Stage2(Stage1Q,CLK,RST,Stage2Q,Stage1Ln,Stage1H,Stage1B,Stage2L,Stage2H,Stage2B);
assign Stage2Ln = ~Stage2L;

wire Stage3L, Stage3Ln, Stage3H, Stage3B, Stage3Q;
ConfigCrossover Stage3(Stage2Q,CLK,RST,Stage3Q,Stage2Ln,Stage2H,Stage2B,Stage3L,Stage3H,Stage3B);
assign Stage3Ln = ~Stage3L;

wire Stage4L, Stage4Ln, Stage4H, Stage4B, Stage4Q;
ConfigCrossover Stage4(Stage3Q,CLK,RST,Stage4Q,Stage3Ln,Stage3H,Stage3B,Stage4L,Stage4H,Stage4B);
assign Stage4Ln = ~Stage4L;

wire Stage5L, Stage5Ln, Stage5H, Stage5B, Stage5Q;
ConfigCrossover Stage5(Stage4Q,CLK,RST,Stage5Q,Stage4Ln,Stage4H,Stage4B,Stage5L,Stage5H,Stage5B);
assign Stage5Ln = ~Stage5L;

wire Stage6L, Stage6Ln, Stage6H, Stage6B, Stage6Q;
ConfigCrossover Stage6(Stage5Q,CLK,RST,Stage6Q,Stage5Ln,Stage5H,Stage5B,Stage6L,Stage6H,Stage6B);
assign Stage6Ln = ~Stage6L;

wire Stage7L, Stage7Ln, Stage7H, Stage7B, Stage7Q;
ConfigCrossover Stage7(Stage6Q,CLK,RST,Stage7Q,Stage6Ln,Stage6H,Stage6B,Stage7L,Stage7H,Stage7B);
assign Stage7Ln = ~Stage7L;

wire Stage8L, Stage8Ln, Stage8H, Stage8B, Stage8Q;
ConfigCrossover Stage8(Stage7Q,CLK,RST,Stage8Q,Stage7Ln,Stage7H,Stage7B,Stage8L,Stage8H,Stage8B);
assign Stage8Ln = ~Stage8L;

wire Stage9L, Stage9Ln, Stage9H, Stage9B, Stage9Q;
ConfigCrossover Stage9(Stage8Q,CLK,RST,Stage9Q,Stage8Ln,Stage8H,Stage8B,Stage9L,Stage9H,Stage9B);
assign Stage9Ln = ~Stage9L;

wire Stage10L, Stage10Ln, Stage10H, Stage10B, Stage10Q;
ConfigCrossover Stage10(Stage9Q,CLK,RST,Stage10Q,Stage9Ln,Stage9H,Stage9B,Stage10L,Stage10H,Stage10B);
assign Stage10Ln = ~Stage10L;

wire Stage11L, Stage11Ln, Stage11H, Stage11B, Stage11Q;
ConfigCrossover Stage11(Stage10Q,CLK,RST,Stage11Q,Stage10Ln,Stage10H,Stage10B,Stage11L,Stage11H,Stage11B);
assign Stage11Ln = ~Stage11L;

wire Stage12L, Stage12Ln, Stage12H, Stage12B, Stage12Q;
BreakConfigCrossover Stage12(Stage11Q,CLK,RST,Stage12Q,Stage11Ln,Stage11H,Stage11B,Stage12L,Stage12H,Stage12B);
assign Stage12Ln = ~Stage12L;

assign Q = Stage12Q;

endmodule 

//3by3 crossover with clocked flip flops AND breakability
//positive edge clocked
//negetive edge REST
//reset status is 00 000 or dont cross loops for speed and dont pull from bypass loop
//                          dont break Low Loop dont break High Loop dont break Bypass Loop
//each crossover flip flop cascades to the next creating a bitstream of SBSBSBSBS of speed and bypass across the loop
module BreakConfigCrossover(
  input wire D, //bitstream in
  input wire CLK, //bitstream clock
  input wire RST, //reset active low
  output reg Q, //bitstream data out
  input wire LoopL_in, //low speed loop input
  input wire LoopH_in, //high speed loop input
  input wire LoopBy_in, //bypass loop input
  output wire LoopL_out, //low speed loop output
  output wire LoopH_out, //High speed loop output
  output wire LoopBy_out //bupass loop output 
);

wire speed, speedn, bypass, bypassn, BreakSlow, BreakSlown, BreakFast, BreakFastn, BreakBy, BreakByn;
DFF speedcfg(D,CLK,RST,speed,speedn);
DFF bypasscfg(speed,CLK,RST,bypass,bypassn);
DFF BreakS(bypass,CLK,RST,BreakSlow,BreakSlown);
DFF BreakF(BreakSlow,CLK,RST,BreakFast,BreakFastn);
DFF BreakB(BreakFast,CLK,RST,BreakBy,BreakByn);
assign Q = BreakBy;

wire LoopL_out_break, LoopH_out_break, LoopBy_out_break;
    Crossover3x3 crossoverunit(LoopL_in, LoopH_in, LoopBy_in, LoopL_out_break, LoopH_out_break, LoopBy_out_break, speed, speedn, bypass, bypassn);
AND2 ANDBreakL(LoopL_out_break,BreakSlown,LoopL_out);
AND2 ANDBreakH(LoopH_out_break,BreakFastn,LoopH_out);
AND2 ANDBreakB(LoopBy_out_break,BreakByn,LoopBy_out);

endmodule 

//3by3 crossover with clocked flip flops 
//positive edge clocked
//negetive edge REST
//reset status is 00 or dont cross loops for speed and dont pull from bypass loop
//each crossover flip flop cascades to the next creating a bitstream of SBSBSBSBS of speed and bypass across the loop
module ConfigCrossover(
  input wire D, //bitstream in
  input wire CLK, //bitstream clock
  input wire RST, //reset active low
  output reg Q, //bitstream data out
  input wire LoopL_in, //low speed loop input
  input wire LoopH_in, //high speed loop input
  input wire LoopBy_in, //bypass loop input
    /* verilator lint_off UNOPTFLAT */
  output wire LoopL_out, //low speed loop output
  output wire LoopH_out, //High speed loop output
  output wire LoopBy_out //bupass loop output 
    /* verilator lint_on UNOPTFLAT */
);

wire speed, speedn, bypass, bypassn;
DFF speedcfg(D,CLK,RST,speed,speedn);
DFF bypasscfg(speed,CLK,RST,bypass,bypassn);
assign Q = bypass;
    Crossover3x3 crossoverunit(LoopL_in, LoopH_in, LoopBy_in, LoopL_out, LoopH_out, LoopBy_out, speed, speedn, bypass, bypassn);

endmodule 

//3by3 Crossover
//LoopH High Frequency loop 
//LoopL Low Frequency loop (Contains NOT gates for ring oscillator making loop slower)
//BYPASS LOW
// Freq HIGH LoopL input maps to LoopL out
//           LoopH input maps to LoopH out
//           LoopL input maps to Bypass out used by next stage if this stages LoopH out is damaged 
// Freq LOW LoopH input maps to LoopL out
//          LoopL input maps to LoopH out
//          LoopH input maps to Bypass out used by next stage if this stages LoopL out is damaged 
//Bypass High - used to route around broken output gagtes and restore loop
//  Freq HIGH Bypass input maps to LoopL out
//            LoopH input maps to LoopH out
//  Freq LOW LoopL input maps to LoopL out
//           Bypass input maps to LoopH out 
module Crossover3x3(
  input wire LoopL_IN, //low loop in
  input wire LoopH_IN, //high loop in
  input wire LoopBypass_IN, //bypass loop in
  output wire LoopL_OUT, //low loop out
  output wire LoopH_OUT, //high loop out
  output wire LoopBypass_OUT, //bypass loop out 
  input wire Freq, 
  input wire Freqn, //frequency input
  input wire Bypass, 
  input wire Bypassn //bypass Input
);
  
  wire LoLiBl, LoHiBl, LoBiBh, LoLiBh;//Low Loop Out, singal In, Bypass State High/Low
  AND3 LLBn(LoopL_IN,     Freq,  Bypassn, LoLiBl);
  AND3 LHBn(LoopH_IN,     Freqn, Bypassn, LoHiBl);
  AND3 LBB(LoopBypass_IN, Freq,  Bypass,  LoBiBh);
  AND3 LLB(LoopL_IN,      Freqn, Bypass,  LoLiBh);
  
  OR4 Lout(LoLiBl,LoHiBl,LoBiBh,LoLiBh,LoopH_OUT); //outputs the low speed loop signal
  
  
  wire HoLiBl, HoHiBl, HoHiBh, HoBiBh;//High Loop Out, singal In, Bypass State High/Low 
  AND3 HLBn(LoopL_IN,     Freqn, Bypassn, HoLiBl);
  AND3 HHBn(LoopH_IN,     Freq,  Bypassn, HoHiBl);
  AND3 HHB(LoopH_IN,      Freq,  Bypass,  HoHiBh);
  AND3 HBB(LoopBypass_IN, Freqn, Bypass,  HoBiBh);
  
  OR4 Hout(HoLiBl,HoHiBl,HoHiBh,HoBiBh,LoopL_OUT);//outputs the high speed loop signal
  
  
  wire BoLi, BoHi;//Bypass Loop Out, singal In
  AND2 BL(LoopL_IN, Freq,  BoLi);
  AND2 BH(LoopH_IN, Freqn, BoHi);
  
  OR2 Bout(BoLi,BoHi,LoopBypass_OUT); //outputs the bypass loop signal
  
endmodule 

//D Flip Flop
module DFF(
  input wire D, //data in
  input wire CLK, //clock rising edge
  input wire RST, //reset active low
  output reg Q, //data out
  output reg Qn //inverted data out
);
always @(posedge CLK or negedge RST) 
begin
    if(RST==1'b0) begin
  Q <= 1'b0; 
  Qn <= 1'b1; 
    end
 else begin
  Q <= D; 
  Qn <= ~D;
 end
end 
endmodule 

//3 Input AND
module AND3(
  input wire A, 
  input wire B, 
  input wire C, //Logic Input
  output wire Y //Output 
);

  assign Y = (A) & (B) & (C);
 
endmodule 

//2 Input AND
module AND2(
  input wire A, 
  input wire B, //Logic Input
  output wire Y //Output 
);

  assign Y = (A) & (B);
 
endmodule 

//4 Input OR
module OR4(
  input wire A, 
  input wire B, 
  input wire C, 
  input wire D, //Logic Input
  output wire Y //Output 
);

  assign Y = (A) | (B) | (C) | (D);
 
endmodule 

//2 Input OR
module OR2(
  input wire A, 
  input wire B, //Logic Input
  output wire Y //Output 
); 

  assign Y = (A) | (B);
 
endmodule 
