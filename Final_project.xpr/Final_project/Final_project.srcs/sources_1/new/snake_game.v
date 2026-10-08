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


odule snake_game(
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

    localparam BKG_COLOR  = 12'h6A4;
    localparam SNK_COLOR  = 12'h660;
    localparam FOOD_COLOR = 12'hF00;
    localparam DEAD_COLOR = 12'hF80;   // snake turns orange on game over

    localparam GRID_W   = 10;
    localparam GRID_H   = 10;
    localparam CELL     = 48;          // 480 / 10
    localparam MAX_LEN  = 100;
    localparam PTR_W    = $clog2(MAX_LEN);   // $clog2, not $clog
    localparam START_X  = 2;
    localparam START_Y  = 5;
    localparam TICK_MAX = 20_000_000;  // 0.2 s per move at 100 MHz

    // ---------------- state ----------------
    reg [7:0] body_x [0:MAX_LEN-1];
    reg [7:0] body_y [0:MAX_LEN-1];
    reg [PTR_W-1:0] head_ptr, tail_ptr;
    reg [7:0] head_x, head_y;
    reg [7:0] food_x, food_y;
    reg       need_food;
    reg [1:0] dir, next_dir;            // 0=up 1=right 2=down 3=left
    reg       game_over;
    reg [GRID_W*GRID_H-1:0] occupied;

    // ---------------- move tick (clock ENABLE, not a derived clock) ----------------
    reg [24:0] tick_cnt = 0;
    reg tick = 0;
    always @(posedge clk) begin
        if (tick_cnt >= TICK_MAX-1) begin
            tick_cnt <= 0;
            tick <= 1'b1;
        end else begin
            tick_cnt <= tick_cnt + 1;
            tick <= 1'b0;
        end
    end

    // ---------------- free-running LFSR for food placement ----------------
    reg [15:0] lfsr = 16'hACE1;
    always @(posedge clk)
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

    wire [7:0] cand_x = lfsr[7:0]  % GRID_W;
    wire [7:0] cand_y = lfsr[15:8] % GRID_H;
    wire [6:0] cand_addr = cand_y * GRID_W + cand_x;

    // ---------------- next head position ----------------
    reg [7:0] nx, ny;                   // must be reg: assigned in always block
    always @(*) begin
        case (dir)
            2'd0: begin nx = head_x;     ny = head_y - 1; end
            2'd1: begin nx = head_x + 1; ny = head_y;     end
            2'd2: begin nx = head_x;     ny = head_y + 1; end
            default: begin nx = head_x - 1; ny = head_y;  end
        endcase
    end

    wire wall = (nx >= GRID_W) || (ny >= GRID_H);   // 0-1 wraps to 255, so this catches it
    wire [6:0] new_addr  = ny * GRID_W + nx;
    wire [6:0] tail_addr = body_y[tail_ptr] * GRID_W + body_x[tail_ptr];
    wire grow       = (nx == food_x) && (ny == food_y) && !need_food;
    wire tail_moves = !grow;
    wire self_collision = !wall && occupied[new_addr] &&
                          !(tail_moves && (new_addr == tail_addr));

    wire [PTR_W-1:0] next_head_ptr = (head_ptr == MAX_LEN-1) ? 0 : head_ptr + 1;
    wire [PTR_W-1:0] next_tail_ptr = (tail_ptr == MAX_LEN-1) ? 0 : tail_ptr + 1;

    // ---------------- buttons -> requested direction (no 180 turns) ----------------
    always @(posedge clk) begin
        if (reset) next_dir <= 2'd1;
        else if (btnU && dir != 2'd2) next_dir <= 2'd0;
        else if (btnR && dir != 2'd3) next_dir <= 2'd1;
        else if (btnD && dir != 2'd0) next_dir <= 2'd2;
        else if (btnL && dir != 2'd1) next_dir <= 2'd3;
    end

    // ---------------- game logic ----------------
    always @(posedge clk) begin
        if (reset) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            body_x[0] <= START_X;
            body_y[0] <= START_Y;
            head_x <= START_X;
            head_y <= START_Y;
            occupied <= 0;
            occupied[START_Y*GRID_W + START_X] <= 1'b1;
            dir <= 2'd1;
            game_over <= 1'b0;
            need_food <= 1'b1;
            food_x <= 0;
            food_y <= 0;
        end
        else begin
            // place food on a random EMPTY cell (retries every clock until it finds one)
            if (need_food && !occupied[cand_addr]) begin
                food_x <= cand_x;
                food_y <= cand_y;
                need_food <= 1'b0;
            end

            if (tick && !game_over) begin
                dir <= next_dir;

                if (wall || self_collision) begin
                    game_over <= 1'b1;
                end else begin
                    if (tail_moves) begin
                        occupied[tail_addr] <= 1'b0;
                        tail_ptr <= next_tail_ptr;
                    end
                    else begin
                        need_food <= 1'b1;   // ate it -> spawn another
                    end

                    body_x[next_head_ptr] <= nx;
                    body_y[next_head_ptr] <= ny;
                    occupied[new_addr] <= 1'b1;   // wins over the clear above if same cell
                    head_ptr <= next_head_ptr;
                    head_x <= nx;
                    head_y <= ny;
                end
            end
        end
    end

    // ---------------- drawing ----------------
    wire in_grid = (x < 480) && (y < 480);
    wire [3:0] cx = x / CELL;
    wire [3:0] cy = y / CELL;
    wire [6:0] idx = cy * GRID_W + cx;

    wire is_snake = in_grid && occupied[idx];
    wire is_food  = in_grid && !need_food && (cx == food_x) && (cy == food_y);
    wire [5:0] lx = x % CELL;
    wire [5:0] ly = y % CELL;
    wire is_line  = (lx == 0) || (ly == 0);

    always @(*) begin
        if (!in_grid)      color = 12'h000;
        else if (is_snake) color = game_over ? DEAD_COLOR : SNK_COLOR;
        else if (is_food)  color = FOOD_COLOR;
        else if (is_line)  color = SNK_COLOR;
        else               color = BKG_COLOR;
    end
endmodule
