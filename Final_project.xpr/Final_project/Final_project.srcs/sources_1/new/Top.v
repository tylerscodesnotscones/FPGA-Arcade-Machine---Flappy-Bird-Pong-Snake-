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
    input clk,          // 100 MHz
    input [11:0] sw,    // unused
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

    reg [2:0] state = 3'b000;
    wire video_on, p_tick;
    wire [9:0] x, y;
    wire [11:0] color, snake_color;

    // ---- synchronize + debounce ----
    wire L, R, U, D, C;
    debounce db_l(.clk(clk), .din(btnL), .dout(L));
    debounce db_r(.clk(clk), .din(btnR), .dout(R));
    debounce db_u(.clk(clk), .din(btnU), .dout(U));
    debounce db_d(.clk(clk), .din(btnD), .dout(D));
    debounce db_c(.clk(clk), .din(btnC), .dout(C));

    vga_controller vga_c(
        .clk_100MHz(clk),
        .reset(1'b0),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(p_tick),
        .x(x),
        .y(y)
    );

    selection_screen sel_s(
        .x(x), .y(y),
        .selector(state),
        .color(color)
    );

    wire playing_pong = (stable == 3'b100);

    pong pong_game (
        .state(state),
        .reset(reset),
        .clk(clk),
        .btnU(btnU),
        .btnD(btnD),
        .x(x),
        .y(y),
    );

    wire playing_snake = (state == 3'b011);

    snake_game game_one(
        .clk(clk),
        .reset(~playing_snake),  // game held in reset while in the menu
        .x(x), .y(y),
        .btnU(U), .btnD(D), .btnR(R), .btnL(L),
        .color(snake_color)
    );

    // ---- menu / state machine ----
    reg prevL = 0, prevR = 0, prevC = 0;
    wire pressL = L & ~prevL;
    wire pressR = R & ~prevR;
    wire pressC = C & ~prevC;

    always @(posedge clk) begin
        prevL <= L;
        prevR <= R;
        prevC <= C;

        case (state)
            3'b000: begin   // game one (snake) highlighted
                if (pressR)      state <= 3'b001;
                else if (pressL) state <= 3'b010;
                else if (pressC) state <= 3'b011;
            end
            3'b001: begin   // game two highlighted
                if (pressR)      state <= 3'b010;
                else if (pressL) state <= 3'b000;
            end
            3'b010: begin   // game three highlighted
                if (pressR)      state <= 3'b000;
                else if (pressL) state <= 3'b001;
            end
            3'b011: begin   // playing snake: center button returns to menu
                if (pressC) state <= 3'b000;
            end
            default: state <= 3'b000;
        endcase
    end

    assign led = state;

    // ---- pick what to draw ----
    reg [11:0] rgb_reg;
    always @(*) begin
        if (!video_on)          rgb_reg = 12'h000;
        else if (playing_snake) rgb_reg = snake_color;
        else if (playing_pong)  rgb_reg = 
        else                    rgb_reg = color; //selection_screen
    end
    assign rgb = rgb_reg;
endmodule


// 2-flop synchronizer + ~10 ms debounce. Output only changes after the
// input has been stable for 2^20 clocks (~10 ms at 100 MHz).
module debounce(
    input clk,
    input din,
    output reg dout = 1'b0
    );
    reg s0 = 0, s1 = 0;
    reg [19:0] cnt = 0;
    always @(posedge clk) begin
        s0 <= din;
        s1 <= s0;
        if (s1 == dout)
            cnt <= 0;
        else begin
            cnt <= cnt + 1;
            if (&cnt) dout <= s1;
        end
    end
endmodule