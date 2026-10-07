`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2026 11:56:59 AM
// Design Name: 
// Module Name: selection_screen
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


module selection_screen(
    input [9:0] x,
    input [9:0] y,
    input [2:0] selector,
    output reg [11:0] color
    );
    
    localparam width_of_selection = 100;
    localparam height_of_selection = 100;
    localparam bkg_clr = 12'b0010_0010_0010;
    localparam item_clr = 12'b1000_1000_1000;
    localparam highlight_clr = 12'b0100_0100_0100; 
    localparam center_x = 320;
    localparam  center_y = 240;
    
    function draw_box;
        input [9:0] x, y;
        input [9:0] centerX, centerY, width, height;
        if((x > centerX - width/2) &&
           (x < centerX + width/2) &&
           (y > centerY - height/2) &&
           (y < centerY + height/2)) begin
                draw_box = 1'b1;
        end
        else
            draw_box = 1'b0;
    endfunction
    reg [9:0] pos = 9'b0;
    always @(*) begin
    
        //highlight box
        case(selector)
            3'b000: pos <= -200;
            3'b001: pos <= 0;
            3'b010: pos <= 200;
        endcase
        
        //three boxes for selection
        if(draw_box(x, y, center_x + 200, center_y, width_of_selection, height_of_selection) == 1'b1) begin
            color = item_clr;
        end
        else if(draw_box(x, y, center_x, center_y, width_of_selection, height_of_selection) == 1'b1) begin
            color = item_clr;
        end
        else if(draw_box(x, y, center_x - 200, center_y, width_of_selection, height_of_selection) == 1'b1) begin
            color = item_clr;
        end
        else if(draw_box(x,y, center_x + pos, center_y, width_of_selection + 50, height_of_selection + 50) == 1'b1) begin
            color = highlight_clr;
        end
        else begin
            color = bkg_clr;
        end
    end
        
    
endmodule
