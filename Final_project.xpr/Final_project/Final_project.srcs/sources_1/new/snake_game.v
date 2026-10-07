`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2026 03:39:14 PM
// Design Name: 
// Module Name: snake_game
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


module snake_game(
    input clk,
    input [9:0] x,
    input [9:0] y,
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    output reg [11:0] color
    );
    
    localparam BKG_COLOR = 12'b0110_1010_0100;
    localparam SNK_COLOR = 12'b0110_0110_0000;
    
    localparam GRID_W = 10;
    localparam GRID_H = 10;
    localparam screen_hight = 480;
    localparam CELL = screen_hight / GRID_H;
    localparam MAX_LEN = 100;
    localparam ADDR_W = $clog(GRID_W * GRID_H);
    localparam PTR_W = $clog(MAX_LEN);
    
    reg[7:0] body_x [0: MAX_LEN -1];
    reg[7:0] body_y [0: MAX_LEN -1];
    
    reg [PTR_W-1:0] head_ptr, tail_ptr;
    reg[15:0] length;
    reg [7:0] head_x, head_y;
    reg [7:0] food_x, food_y;
    reg need_food = 1'b1;
    
    reg [1:0] dir, next_dir ;
    reg game_over;
    
    reg [GRID_W*GRID_H-1:0] occupied;
    
    wire[7:0] nx, ny;
    
    wire [PTR_W-1:0] next_head_ptr = (head_ptr == MAX_LEN - 1) ? 0 : head_ptr + 1;
    wire [PTR_W-1:0] next_tail_ptr = (tail_ptr == MAX_LEN - 1) ? 0 : tail_ptr + 1;
    
    wire [ADDR_W-1:0] new_addr = ny * GRID_W + nx;
    wire [ADDR_W-1:0] tail_addr = body_y[tail_ptr] * GRID_W + body_x[tail_ptr];

    wire grow = (nx == food_x) && (ny == food_y);
    wire wall = (nx >= GRID_W) || (ny >= GRID_H);
    wire tail_moves = !grow;

    // Allow new head to enter the old tail cell only when the tail moves.
    wire self_collision = occupied[new_addr] && !(tail_moves && (new_addr == tail_addr));
    

    always @(*) begin
        case (dir)
            2'd0: begin nx = head_x; ny = head_y - 1; end
            2'd1: begin nx = head_x + 1; ny = head_y; end
            2'd2: begin nx = head_x; ny = head_y + 1; end
            2'd3: begin nx = head_x - 1; ny = head_y; end
        endcase
    end

    always @(posedge slow_clk) begin
        if (reset) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            length <= 1;

            body_x[0] <= 0;
            body_y[0] <= 0;
            head_x <= 0;
            head_y <= 0;

            occupied <= 0;
            occupied[START_Y*GRID_W + START_X] <= 1'b1;

            dir <= 2'd1;
            next_dir <= 2'd1;
            game_over <= 1'b0;

            // spawn inital food
            food_x = {$random} % 100;
            food_y = {$random} % 100;
        end
        else if (tick && !game_over) begin
            // Update direction, but block 180-degree turns.
            if (!((next_dir == 2'd0 && dir == 2'd2) ||
               (next_dir == 2'd2 && dir == 2'd0) ||
               (next_dir == 2'd1 && dir == 2'd3) ||
               (next_dir == 2'd3 && dir == 2'd1)))
                dir <= next_dir;

            if (wall || self_collision) begin
                game_over <= 1'b1;
            end
            else begin
                // Remove old tail if not growing.
                if (tail_moves) begin
                    occupied[tail_addr] <= 1'b0;
                    tail_ptr <= next_tail_ptr;
                end
                else begin
                    length <= length + 1;
                end

                // Insert new head.
                body_x[next_head_ptr] <= nx;
                body_y[next_head_ptr] <= ny;
                occupied[new_addr] <= 1'b1;
                head_ptr <= next_head_ptr;
                head_x <= nx;
                head_y <= ny;

                if (grow) begin
                    // spawn new food in an empty cell
                    food_x = {$random} % 100;
                    food_y = {$random} % 100;
                end
            end
        end
    end
    
    reg [19:0] slow_clk_reg;
    wire slow_clk;
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

    always @(posedge clk) begin
        //clock for snake movment
        if(slow_clk_reg == 20'b1111_1111_0000_0000_00)begin
            slow_clk = 1'b1;
            slow_clk_reg = 1'b0;
        end
        else
            slow_clk = 1'b0;
    end
    
    wire [7:0] cx = x / CELL;
    wire [7:0] cy = y / CELL;
    
    wire [6:0] idx = cy * GRID_W + cx;
    
    wire is_snake = occupied[idk];
    wire is_food = (cx == food_x) && (cy == food_y);
    
    wire [5:0] lx = x % CELL;
    wire [5:0] ly = y % CELL;
    wire is_line = (lx == 0) || (ly == 0);
    
    //screen 640x480
    always @(*) begin
        if(is_snake) color <= SNK_COLOR;
        else if(is_food) color <= 12'b1111_0000_0000;
        else if(is_line) color <= SNK_COLOR;
        else color <= BKG_COLOR;
    end
    
    
    
endmodule
