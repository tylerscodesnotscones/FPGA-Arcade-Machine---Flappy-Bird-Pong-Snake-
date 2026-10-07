`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2026 02:34:19 PM
// Design Name: 
// Module Name: pong
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


module pong(
    input [9:0] x, y,
    input video_on, clk,
    input btnU, btnD,
    input [2:0] state,
    output reg [11:0] rgb
    );

    //state logic
    localparam pong_state = 3'b100;
    
    wire active = (state == pong_state);
    
    reg active_reg;
    
    always @(posedge clk) begin
        active_reg <= active;
    end
    
    wire active_state = active && !active_reg;
    



    //middle is 319,320 for x, 239, 240 for y
    localparam screen_width = 640;
    localparam screen_height = 480;
    localparam center_x = 320;
    localparam center_y = 240;
    
    //paddle dimensions 
    localparam paddle_width = 8;
    localparam paddle_height = 48;
    localparam paddle_offset = 30; //from screen edge
    
    // paddle boundaries for player (right)
    localparam player_x_min = screen_width - paddle_offset - paddle_width;
    localparam player_x_max = screen_width - paddle_offset;
    
    // paddle boundaries for computer (left)
    localparam comp_x_min = paddle_offset;
    localparam comp_x_max = paddle_offset + paddle_width;
    
    // boundaries for center line
    localparam line_x_min = 318;
    localparam line_x_max = 321;
    
    // ball param
    localparam ball_size = 8;
    
    //colors
    localparam white = 12'hFFF;
    localparam black = 12'h000;
    
    // registers for ball position & signed speed/direction
    reg [9:0] ball_x = 10'd316;
    reg [9:0] ball_y = 10'd236;
    reg signed [9:0] ball_dx = 10'sd2;
    reg signed [9:0] ball_dy = 10'sd0;
    
    // computer paddle pos register
    reg [9:0] comp_y;
    reg [9:0] player_y;
    
    // frame clock @60fps
    localparam target_count = 21'b110010110111001101011;
    
    reg [20:0] counter = 21'd0; 
    reg frame_tick = 1'b0;  
    
    always @(posedge clk) begin
        if (counter >= target_count) begin
            counter <= 21'd0;
            frame_tick <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            frame_tick <= 1'b0;
        end
    end
    
    // center coords for balls & paddles
    wire [9:0] ball_center_y = ball_y + (ball_size / 2);
    wire [9:0] comp_center_y = comp_y + (paddle_height / 2);
    
    // offset calcs for rebounding relative to the top of each paddle
    wire [9:0] comp_hit_offset = (ball_center_y >= comp_y) ? (ball_center_y - comp_y) : 10'd0;
    wire [9:0] player_hit_offset = (ball_center_y >= player_y) ? (ball_center_y - player_y) : 10'd0;
    
    // player paddle movement
    always @(posedge clk) begin
        if (active_state) begin
            player_y <= 10'd216; // center player paddle
        end
        else if (active && frame_tick) begin
            if (btnU && (player_y > 0)) begin
                player_y <= player_y - 10'd2; // up
            end
            else if (btnD && (player_y + paddle_height < screen_height)) begin
                player_y <= player_y + 10'd2; // down
            end
        end
    end
    
    // comp tracking
    always @(posedge clk) begin
        if (active_state) begin
           comp_y <= 10'd216; // center comp paddle
        end
        else if (active && frame_tick) begin
            // ball = below paddle center, paddle move down
            if ((ball_center_y > comp_center_y + 2) && (comp_y + paddle_height < screen_height)) begin
                comp_y <= comp_y + 10'd1;
            end
            // ball = above paddle center, paddle move up
            else if ((ball_center_y < comp_center_y - 2) && (comp_y > 0)) begin
                comp_y <= comp_y - 10'd1;
            end
        end
    end
        
    // ball movement and bounce/collision logic
    
    always @(posedge clk) begin
        if(active_state) begin
            ball_x <= 10'd316;
            ball_y <= 10'd236;
            ball_dx <= 10'sd2;
            ball_dy <= 10'sd0;
        end
        else if (active && frame_tick) begin
                //computer paddle collision (left)
                if ((ball_dx < 0) && (ball_x <= comp_x_max) && (ball_x + ball_size >= comp_x_min) && (ball_y + ball_size >= comp_y) && (ball_y <= comp_y + paddle_height)) begin
                    ball_dx <= 10'sd2; // ball goes right instead of left
                    
                    // zone-based ball direction override for computer paddle
                    if (comp_hit_offset < 10)
                        ball_dy <= -10'sd2;
                    else if (comp_hit_offset < 20)
                        ball_dy <= -10'sd1;
                    else if (comp_hit_offset <28)
                        ball_dy <= 10'sd0;
                    else if (comp_hit_offset <38)
                        ball_dy <= 10'sd1;
                    else
                        ball_dy <= 10'sd2;
                end
                
                // player paddle collision (right)
                else if ((ball_dx > 0) && (ball_x + ball_size >= player_x_min) && (ball_x <= player_x_max) && (ball_y + ball_size >= player_y) && (ball_y <= player_y + paddle_height)) begin
                    ball_dx <= -10'sd2; // ball goes left instead of right
                    
                    //zone-based ball direction override for player paddle
                    if (player_hit_offset < 10)
                        ball_dy <= -10'sd2;
                    else if (player_hit_offset < 20)
                        ball_dy <= -10'sd1;
                    else if (player_hit_offset <28)
                        ball_dy <= 10'sd0;
                    else if (player_hit_offset <38)
                        ball_dy <= 10'sd1;
                    else
                        ball_dy <= 10'sd2;
                end
                
                // top and bottom wall bounces
                else if (ball_y <= 0) begin
                    ball_dy <= -ball_dy;
                    ball_y <= 10'd1;
                end
                else if (ball_y + ball_size >= screen_height) begin
                    ball_dy <= -ball_dy;
                    ball_y <= screen_height - ball_size - 1;
                end
                
                // out of bounds (scoring) + reset
                else if ((ball_x <= 0) || (ball_x + ball_size >= screen_width)) begin
                    ball_x <= 10'd316;
                    ball_y <= 10'd236;
                    ball_dx <= -ball_dx; // send the ball towards the scorer
                    ball_dy <= 10'sd0;
                end
                
                // position update
                ball_x <= ball_x + ball_dx;
                ball_y <= ball_y + ball_dy;
            end
    end
    
    
    // display
    always @(*) begin
        if (!active || video_on == 0) begin
            rgb = black;
        end
        // player paddle
        else if ((x >= player_x_min) && (x < player_x_max) && (y >= player_y) && (y < player_y + paddle_height)) begin
            rgb = white;
        end
        // comp paddle
        else if ((x >= comp_x_min) && (x < comp_x_max) && (y >= comp_y) && (y < comp_y + paddle_height)) begin
            rgb = white;
        end
        //ball
        else if ((x >= ball_x) && (x < ball_x + ball_size) && (y >= ball_y) && (y < ball_y + ball_size)) begin
            rgb = white;
        end
        // dashed line divider
        else if ((x >= line_x_min) && (x < line_x_max) && ((y % 8) < 4)) begin
            rgb = white;
        end
        else begin
            rgb = black;
        end
    end
    
endmodule

/*



//pong instantiation for top.v
pong pong_game (
    .state(state),
    .reset(reset),
    .clk(clk),
    .video_on(video_on),
    .btnU(btnU),
    .btnD(btnD),
    .x(x),
    .y(y),
);




*/
