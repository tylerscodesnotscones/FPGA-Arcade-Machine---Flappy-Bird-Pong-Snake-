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
    input reset,
    input [9:0] x,
    input [9:0] y,
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    output reg [11:0] color
);

    localparam [11:0] BKG_COLOR  = 12'h6A4;
    localparam [11:0] SNK_COLOR  = 12'h660;
    localparam [11:0] FOOD_COLOR = 12'hF00;
    localparam [11:0] DEAD_COLOR = 12'hF80;

    localparam GRID_W  = 10;
    localparam CELL    = 48;
    localparam MAX_LEN = 100;
    localparam PTR_W   = 7;
    localparam TICK_MAX = 15_000_000;

    // Direction: 0=up, 1=right, 2=down, 3=left
    reg [1:0] dir, next_dir;

    reg [7:0] body_x [0:99];
    reg [7:0] body_y [0:99];
    reg [6:0] head_ptr, tail_ptr;

    reg [7:0] head_x, head_y;
    reg [7:0] food_x, food_y;

    reg [99:0] occupied;
    reg need_food, game_over;

    reg [30:0] tick_cnt;
    reg tick;

    reg [15:0] lfsr;

    wire [7:0] cand_x = lfsr[7:0] % 10;
    wire [7:0] cand_y = lfsr[15:8] % 10;
    wire [6:0] cand_addr = cand_y * 10 + cand_x;

    wire [7:0] nx = (next_dir == 2'd1) ? head_x + 1 : (next_dir == 2'd3) ? head_x - 1 : head_x;

    wire [7:0] ny = (next_dir == 2'd0) ? head_y - 1 : (next_dir == 2'd2) ? head_y + 1 : head_y;

    wire wall = (nx >= 10) || (ny >= 10);

    wire [6:0] new_addr = ny * 10 + nx;
    wire [6:0] tail_addr =
        body_y[tail_ptr] * 10 + body_x[tail_ptr];

    wire grow =
        !need_food &&
        nx == food_x &&
        ny == food_y;

    wire self_collision =
        !wall &&
        occupied[new_addr] &&
        !(new_addr == tail_addr && !grow);

    // Clock / game tick

    always @(posedge clk) begin
        if (reset) begin
            tick_cnt <= 0;
            tick <= 0;
        end
        else if (tick_cnt == TICK_MAX-1) begin
            tick_cnt <= 0;
            tick <= 1;
        end
        else begin
            tick_cnt <= tick_cnt + 1;
            tick <= 0;
        end
    end

    // Random number generator

    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr[14:0],
                     lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    // Direction control

    always @(posedge clk) begin
        if (reset) begin
            dir <= 2'd1;
            next_dir <= 2'd1;
        end
        else begin

            // Store requested direction immediately.
            // Don't allow 180 degree turns.
            if (btnU && dir != 2'd2)
                next_dir <= 2'd0;
            else if (btnR && dir != 2'd3)
                next_dir <= 2'd1;
            else if (btnD && dir != 2'd0)
                next_dir <= 2'd2;
            else if (btnL && dir != 2'd1)
                next_dir <= 2'd3;

            // Apply direction on next movement.
            if (tick)
                dir <= next_dir;
        end
    end


    // Snake
    always @(posedge clk) begin
        if (reset) begin
            head_ptr <= 0;
            tail_ptr <= 0;

            head_x <= 2;
            head_y <= 5;

            body_x[0] <= 2;
            body_y[0] <= 5;

            occupied <= 0;
            occupied[52] <= 1;

            food_x <= 0;
            food_y <= 0;

            need_food <= 1;
            game_over <= 0;
        end
        else begin

            // Create food
            if (need_food && !occupied[cand_addr]) begin
                food_x <= cand_x;
                food_y <= cand_y;
                need_food <= 0;
            end

            if (tick && !game_over) begin

                if (wall || self_collision) begin
                    game_over <= 1;
                end
                else begin

                    // Remove tail
                    if (!grow) begin
                        occupied[tail_addr] <= 0;

                        if (tail_ptr == 99)
                            tail_ptr <= 0;
                        else
                            tail_ptr <= tail_ptr + 1;
                    end
                    else begin
                        need_food <= 1;
                    end

                    // Add head
                    if (head_ptr == 99)
                        head_ptr <= 0;
                    else
                        head_ptr <= head_ptr + 1;

                    body_x[(head_ptr == 99) ? 0 : head_ptr + 1] <= nx;
                    body_y[(head_ptr == 99) ? 0 : head_ptr + 1] <= ny;

                    occupied[new_addr] <= 1;

                    head_x <= nx;
                    head_y <= ny;
                end
            end
        end
    end

    // VGA

    wire in_grid = (x < 480) && (y < 480);

    wire [3:0] cx = x / 48;
    wire [3:0] cy = y / 48;

    wire [6:0] idx = cy * 10 + cx;

    wire is_snake =
        in_grid &&
        (idx < 100) &&
        occupied[idx];

    wire is_food =
        in_grid &&
        !need_food &&
        cx == food_x &&
        cy == food_y;

    wire is_line =
        (x % 48 == 0) ||
        (y % 48 == 0);

    always @(*) begin
        if (!in_grid)
            color = 12'h000;
        else if (is_snake)
            color = game_over ? DEAD_COLOR : SNK_COLOR;
        else if (is_food)
            color = FOOD_COLOR;
        else if (is_line)
            color = SNK_COLOR;
        else
            color = BKG_COLOR;
    end

endmodule