`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2026 11:34:33 AM
// Design Name: 
// Module Name: Top
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


module Top(
    input clk,          // 100 MHz FPGA clock
    input [11:0] sw,   // unused
    input btnL,
    input btnR,
    input btnC,
    input btnU,
    input btnD,
    output [2:0] led,
    output hsync,
    output vsync,
    output [11:0] rgb
    );
    
    wire video_on;
    wire p_tick;
    wire [9:0] x;
    wire [9:0] y;
    wire [11:0] color;
    wire [11:0] snake_color;
    
    vga_controller vga_c(
        .clk_100MHz(clk),
        .reset(btnC),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(p_tick),
        .x(x),
        .y(y)
    );
    
    selection_screen sel_s(
        .x(x),
        .y(y),
        .selector(state),
        .color(color)
    );
    
    snake_game game_one(
        .x(x),
        .y(y),
        .btnU(btnU),
        .btnD(btnD),
        .btnR(btnR),
        .btnL(btnL),
        .color(snake_color)
    );
    
    reg [2:0] state = 3'b000;
    reg prevBtnL, prevBtnR, prevBtnU, prevBtnD, prevBtnC = 1'b0;
    
    //State control code
    always @(posedge clk) begin
        case(state)
        
            //game one selected
            3'b000: begin
                if(btnR == 1'b1 && prevBtnR == 1'b0) begin
                    state <= 3'b001;
                end
                else if(btnC  == 1'b1 && prevBtnC == 1'b0)begin
                    state = 3'b011;
                end
                else if (btnL == 1'b1 && prevBtnL == 1'b0) begin
                    state <= 3'b010;
                end
            end
            
            //game two selected
            3'b001: begin
                if(btnR == 1'b1 && prevBtnR == 1'b0) begin
                    state <= 3'b010;
                end
                else if (btnL == 1'b1 && prevBtnL == 1'b0) begin
                    state <= 3'b000;
                end
            end
            
            //game three selected
            3'b010: begin
                if(btnR == 1'b1 && prevBtnR == 1'b0) begin
                    state <= 3'b000;
                end
                else if (btnL == 1'b1 && prevBtnL == 1'b0) begin
                    state <= 3'b001;
                end
            end
            
            //playing snake
            3'b011: begin
             if(btnC == 1'b1 && prevBtnC == 1'b0)
                state <= 3'b000;
            end
        endcase
        //DEBOUNCE CODE
        prevBtnL <= btnL;
        prevBtnR <= btnR;
        prevBtnU <= btnU;
        prevBtnD <= btnD;
        prevBtnC <= ~btnC;
    end
    assign led = state;
    
    reg [11:0] rgb_reg;
    //code for drawing game btnC
    always @(*) begin
        rgb_reg = 12'b0000_0000_0000;
        
        if (video_on) begin
            if(state == 3'b000 || state == 3'b001 || state == 3'b010) begin
                rgb_reg <= color;
            end
            if(state == 3'b011) begin //launch btnC
                rgb_reg <= snake-color;
            end
        end
    end
    
    assign rgb = rgb_reg;
endmodule
