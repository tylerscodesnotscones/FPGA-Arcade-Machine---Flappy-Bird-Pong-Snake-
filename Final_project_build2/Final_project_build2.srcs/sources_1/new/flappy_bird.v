`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 02:14:07 AM
// Design Name: 
// Module Name: flappy_bird
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


module flappy_bird(
    input clk,
    input reset,
    input [9:0] x,
    input [9:0] y,
    input btnFlap,
    output reg [11:0] color
);
 
    // ---------------- colors (12-bit, {R,G,B} like snake_game) ----------------
    localparam [11:0] SKY_COLOR    = 12'h6CF;
    localparam [11:0] PIPE_COLOR   = 12'h2B2;
    localparam [11:0] PIPE_EDGE    = 12'h060;
    localparam [11:0] GROUND_COLOR = 12'h970;
    localparam [11:0] GRASS_COLOR  = 12'h6C2;
    localparam [11:0] BIRD_COLOR   = 12'hFD0;
    localparam [11:0] WING_COLOR   = 12'hDA0;
    localparam [11:0] BEAK_COLOR   = 12'hF80;
    localparam [11:0] DEAD_COLOR   = 12'hF55;
    localparam [11:0] SCORE_COLOR  = 12'hFFF;
 
    // ---------------- tuning knobs ----------------
    localparam BIRD_X     = 160;     // bird's fixed column
    localparam BIRD_S     = 20;      // bird is 20x20 pixels
    localparam GROUND_Y   = 440;     // top of the ground strip
    localparam NUM_PIPES  = 3;
    localparam PIPE_W     = 60;
    localparam GAP        = 120;     // vertical opening between pipes
    localparam SPACING    = 240;     // distance between pipes (NUM*SPACING must be > 640+PIPE_W)
    localparam SPEED      = 2;       // pixels per frame pipes scroll left
    localparam GAP_MIN    = 60;      // lowest allowed top-of-gap
    localparam GAP_RANGE  = 200;     // gap top is GAP_MIN .. GAP_MIN+GAP_RANGE-1
    localparam FLAP_V     = 5;       // upward speed on flap (pixels/frame)
    localparam MAX_V      = 6;       // terminal falling speed
    localparam FRAME_MAX  = 1_666_667; // 100 MHz / 60 fps
 
    localparam [1:0] S_WAIT = 2'd0, S_PLAY = 2'd1, S_DEAD = 2'd2;
 
    // ---------------- state ----------------
    reg [1:0] state;
    reg signed [11:0] bird_y;
    reg signed [7:0]  vel;
    reg grav_cnt;                    // gravity applies every 2nd frame
    reg [5:0] score;
 
        reg signed [11:0] pipe_x   [0:NUM_PIPES-1];
    reg signed [11:0] pipe_gap [0:NUM_PIPES-1];   // y of top of the opening
    reg [NUM_PIPES-1:0] passed;
 
    reg prev_flap, flap_req;
    wire flap = btnFlap & ~prev_flap;             // one-clock pulse on press
 
    // free-running random number generator (same taps as snake_game)
    reg [15:0] lfsr = 16'hACE1;
    always @(posedge clk)
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
 
    // ~60 Hz frame tick (counter sizes itself from FRAME_MAX)
    reg [$clog2(FRAME_MAX)-1:0] frame_cnt = 0;
    reg frame_tick = 1'b0;
    always @(posedge clk) begin
        if (frame_cnt == FRAME_MAX-1) begin
            frame_cnt  <= 0;
            frame_tick <= 1'b1;
        end else begin
            frame_cnt  <= frame_cnt + 1'b1;
            frame_tick <= 1'b0;
        end
    end
 
    // collision
    reg hit;
    integer k;
    always @(*) begin
        hit = 1'b0;
        if (bird_y < 0 || bird_y + BIRD_S >= GROUND_Y)
            hit = 1'b1;
        for (k = 0; k < NUM_PIPES; k = k + 1) begin
            if ((BIRD_X + BIRD_S > pipe_x[k]) && (BIRD_X < pipe_x[k] + PIPE_W) &&
                ((bird_y < pipe_gap[k]) || (bird_y + BIRD_S > pipe_gap[k] + GAP)))
                hit = 1'b1;
        end
    end
 
    //game logic
    integer i;
    always @(posedge clk) begin
        prev_flap <= btnFlap;
 
        if (reset || (state == S_DEAD && flap)) begin
            state     <= S_WAIT;
            bird_y    <= 12'sd220;
            vel       <= 8'sd0;
            grav_cnt  <= 1'b0;
            score     <= 6'd0;
            flap_req  <= 1'b0;
            passed    <= {NUM_PIPES{1'b0}};
            for (i = 0; i < NUM_PIPES; i = i + 1) begin
                pipe_x[i]   <= 640 + i*SPACING;
                pipe_gap[i] <= 100 + i*40;
            end
        end
        else begin
            if (flap) flap_req <= 1'b1;   // remember a press until the next frame
 
            if (state == S_WAIT) begin
                if (flap) begin
                    state    <= S_PLAY;
                    flap_req <= 1'b0;
                    vel      <= -FLAP_V;
                end
            end
            else if (state == S_PLAY && frame_tick) begin
                flap_req <= flap;         // consume the stored press
 
                if (hit) begin
                    state <= S_DEAD;
                end
                else begin
                    // ---- bird ----
                    if (flap_req) begin
                        vel      <= -FLAP_V;
                        grav_cnt <= 1'b0;
                        bird_y   <= bird_y - FLAP_V;
                    end
                    else begin
                        bird_y <= bird_y + vel;
                        grav_cnt <= ~grav_cnt;
                        if (grav_cnt && vel < MAX_V)
                            vel <= vel + 1'b1;
                    end
 
                    // ---- pipes ----
                    for (i = 0; i < NUM_PIPES; i = i + 1) begin
                        pipe_x[i] <= pipe_x[i] - SPEED;
 
                        if (!passed[i] && (pipe_x[i] + PIPE_W < BIRD_X)) begin
                            passed[i] <= 1'b1;
                            score     <= score + 1'b1;
                        end
 
                        // off the left edge -> recycle to the far right, new random gap
                        if (pipe_x[i] + PIPE_W <= 0) begin
                            pipe_x[i]   <= pipe_x[i] + NUM_PIPES*SPACING - SPEED;
                            pipe_gap[i] <= GAP_MIN + (lfsr[7:0] % GAP_RANGE);
                                passed[i]   <= 1'b0;
                        end
                    end
                end
            end
        end
    end
 
    // VGA drawing
    reg [11:0] color_next;
    wire signed [11:0] xs = $signed({2'b00, x});
    wire signed [11:0] ys = $signed({2'b00, y});
 
    // bird
    wire signed [11:0] bx = xs - BIRD_X;
    wire signed [11:0] by = ys - bird_y;
    wire in_bird = (bx >= 0) && (bx < BIRD_S) && (by >= 0) && (by < BIRD_S);
    wire is_eye   = (bx >= 11) && (bx < 16) && (by >= 3) && (by < 8);
    wire is_pupil = (bx >= 13) && (bx < 16) && (by >= 4) && (by < 7);
    wire is_beak  = (bx >= 16) && (by >= 9) && (by < 13);
    wire is_wing  = (bx >= 2)  && (bx < 9)  && (by >= 10) && (by < 15);
 
    // pipes
    reg in_pipe, in_pipe_edge;
    integer j;
    always @(*) begin
        in_pipe      = 1'b0;
        in_pipe_edge = 1'b0;
        for (j = 0; j < NUM_PIPES; j = j + 1) begin
            if ((xs >= pipe_x[j]) && (xs < pipe_x[j] + PIPE_W) &&
                ((ys < pipe_gap[j]) || (ys >= pipe_gap[j] + GAP)) &&
                (y < GROUND_Y)) begin
                in_pipe = 1'b1;
                if ((xs < pipe_x[j] + 3) || (xs >= pipe_x[j] + PIPE_W - 3))
                    in_pipe_edge = 1'b1;
            end
        end
    end
 
    // score squares: one per point, top-left (16 px pitch, 12 px wide, bit slices only)
    wire [9:0] sx   = x - 10'd8;
    wire [5:0] sidx = sx[9:4];
    wire is_score = (x >= 8) && (y >= 8) && (y < 20) &&
                    (sx[3:0] < 4'd12) && (sidx < score);
 
    always @(*) begin
        if (is_score)
            color_next = SCORE_COLOR;
        else if (y >= GROUND_Y)
            color_next = (y < GROUND_Y + 6) ? GRASS_COLOR : GROUND_COLOR;
        else if (in_bird) begin
            if (is_pupil)                 color_next = 12'h000;
            else if (is_eye)              color_next = 12'hFFF;
            else if (is_beak)             color_next = BEAK_COLOR;
            else if (is_wing)             color_next = WING_COLOR;
            else                          color_next = (state == S_DEAD) ? DEAD_COLOR : BIRD_COLOR;
        end
        else if (in_pipe)
            color_next = in_pipe_edge ? PIPE_EDGE : PIPE_COLOR;
        else
            color_next = SKY_COLOR;
    end
 
    // register the pixel color: short, clean path from the flops to the VGA pins
    always @(posedge clk)
        color <= color_next;
 
endmodule