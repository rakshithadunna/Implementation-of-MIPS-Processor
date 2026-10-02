`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.11.2025 17:57:20
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb();
reg clk1, clk2;
integer i;

// Instantiate DUT
MIPS_Wrapper dut (
    .clk1(clk1),
    .clk2(clk2)
);

// ------------------------------
// CLOCK GENERATION
// ------------------------------
initial begin
    clk1 = 0; clk2 = 0;
end

always #5  clk1 = ~clk1;   // 10 ns period
always #5  clk2 = ~clk2;   // 10 ns period (in-phase but still alternates pipeline)

// ------------------------------
// INITIAL SETUP
// ------------------------------
initial begin
    $dumpfile("mips_wrapper.vcd");
    $dumpvars(0, MIPS_Wrapper_tb);

    // Initialize memory to 0
    for(i=0; i<1024; i=i+1) begin
        dut.Mem[i] = 32'h0;
    end

    // Initialize register file
    for(i=0; i<32; i=i+1) begin
        dut.register[i] = 0;
    end

    // Set initial values
    dut.PC = 0;
    dut.halted = 0;
    dut.branch_taken = 0;

    // ------------------------------
    // LOAD A SAMPLE PROGRAM
    // ------------------------------
    // Format: Opcode (31:26), rs, rt, rd, imm

    // ADDI R1, R0, 5       ; R1 = 5
    dut.Mem[0] = {6'b001010, 5'd0, 5'd1, 16'd5}; 

    // ADDI R2, R0, 10      ; R2 = 10
    dut.Mem[1] = {6'b001010, 5'd0, 5'd2, 16'd10};

    // ADD  R3, R1, R2      ; R3 = R1 + R2 = 15
    dut.Mem[2] = {6'b000000, 5'd1, 5'd2, 5'd3, 11'd0};

    // SW   R3, 20(R0)      ; Mem[20] = R3 = 15
    dut.Mem[3] = {6'b001001, 5'd3, 5'd0, 16'd20};

    // LW   R4, 20(R0)      ; R4 = Mem[20] = 15
    dut.Mem[4] = {6'b001000, 5'd0, 5'd4, 16'd20};

    // BEQZ R4, +2          ; Skip next instr if R4==0 → false, R4=15
    dut.Mem[5] = {6'b001110, 5'd4, 5'd0, 16'd2};

    // ADDI R5, R0, 1       ; R5 = 1 (will execute)
    dut.Mem[6] = {6'b001010, 5'd0, 5'd5, 16'd1};

    // HLT
    dut.Mem[7] = {6'b111111, 26'd0};

    // ------------------------------
    // RUN SIMULATION
    // ------------------------------
    $display("Starting simulation...");
end

// ------------------------------
// MONITOR IMPORTANT SIGNALS
// ------------------------------
always @(posedge clk1) begin
    $display("CLK1: PC=%d IF_ID_IR=%h ID_EX_IR=%h EX_MEM_IR=%h MEM_WB_IR=%h halted=%b", 
             dut.PC, dut.IF_ID_IR, dut.ID_EX_IR, dut.EX_MEM_IR, dut.MEM_WB_IR, dut.halted);
end

// ------------------------------
// END SIMULATION WHEN HALTED
// ------------------------------
always @(posedge clk1) begin
    if(dut.halted == 1) begin
        $display("Program halted.");
        #20;
        $finish;
    end
end
endmodule
