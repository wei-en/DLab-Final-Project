`timescale 1ns / 1ps
//last modified: 2019/12/26 Kk
//////////////////////////////////////////////////////////////////////////////////

module move_uart(
    input wire clk,
    input wire reset_n,
    //uart input
    input  uart_rx,
    output uart_tx,  
    //uart output
    output wire U, 
    output wire L, 
    output wire R
    // for debugging
    //output [3:0] usr_led
    );

reg jump;
reg left; 
reg right;
//ouput logic
assign U = jump;
assign L = left;
assign R = right;
// localparam [2:0] S_MAIN_INIT = 0, S_MAIN_FIRST_PROMPT = 1, S_MAIN_FIRST_READ_NUM = 2,
//                  S_MAIN_SECOND_PROMPT = 3, S_MAIN_SECOND_READ_NUM = 4, S_MAIN_REPLY = 5;
localparam [2:0] S_MAIN_INIT = 0, S_MAIN_FIRST_PROMPT = 1, S_MAIN_FIRST_READ_NUM = 2;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz

localparam PROMPT_FIRST_STR  = 0;  // starting index of the prompt message
localparam PROMPT_FIRST_LEN  = 19; // length of the prompt message
// localparam PROMPT_SECOND_STR = 35; // starting index of the prompt message
// localparam PROMPT_SECOND_LEN = 36; // length of the prompt message
// localparam REPLY_STR         = PROMPT_FIRST_LEN + PROMPT_SECOND_LEN; // starting index of the hello message
// localparam REPLY_LEN         = 39; // length of the hello message

localparam MEM_SIZE = PROMPT_FIRST_LEN;

// declare system variables
wire enter_pressed;
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];

reg  [0:PROMPT_FIRST_LEN*8-1] msg1 = { "\015\012START THE GAME! ", 8'h00 }; //8 bit per character
// reg  [0:PROMPT_SECOND_LEN*8-1] msg2 = { "\015\012Enter the second decimal number: ", 8'h00 };
// reg  [0:REPLY_LEN*8-1] msg3 = { "\015\012The interger quotient is: 0x00000.\015\012", 8'h00 };
// reg  [2:0]  key_cnt;  // The key strokes counter, i.e., how many digits
// reg  [16:0] dec_fir_reg; // The key-in number register, stores the first number in decimal
// reg  [16:0] dec_sec_reg; // stores the second number in decimal

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
reg  [7:0] prev_rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire moving_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;
// wire finish_division;

// reg [16:0] quo = 0; //for long division 
// reg [16:0] rem = 0; //for long division

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//

reg [23:0] led_counter_jump;
reg [23:0] led_counter_left;
reg [23:0] led_counter_right;
reg [23:0] led_counter_rcv;

// assign usr_led[0] = |led_counter_jump; //|: OR
// assign usr_led[1] = |led_counter_left;
// assign usr_led[2] = |led_counter_right;
// assign usr_led[3] = |led_counter_rcv;
/*
assign usr_led[0] = jump; //|: OR
assign usr_led[1] = left; //|: OR
assign usr_led[2] = right; //|: OR
assign usr_led[3] = received; //|: OR
*/
// assign usr_led[1] = |led_counter_left;
// assign usr_led[2] = |led_counter_right;
// assign usr_led[3] = |led_counter_rcv;

// always @(posedge clk) begin
//   if (~reset_n) begin
//     led_counter_jump <= 0;
//   end
//   else if (jump) begin
//     led_counter_jump <= 23'h2DC6C0;
//   end
//   else led_counter_jump <= (led_counter_jump > 0) ? led_counter_jump - 1 : 0;
// end

// always @(posedge clk) begin
//   if (~reset_n) begin
//     led_counter_left <= 0;
//   end
//   else if (left) begin
//     led_counter_left <= 23'h2DC6C0;
//   end
//   else led_counter_left <= (led_counter_left > 0) ? led_counter_left - 1 : 0;
// end

// always @(posedge clk) begin
//   if (~reset_n) begin
//     led_counter_right <= 0;
//   end
//   else if (right) begin
//     led_counter_right <= 23'h2DC6C0;
//   end
//   else led_counter_right <=(led_counter_right > 0) ? led_counter_right - 1 : 0;
// end

// always @(posedge clk) begin
//   if (~reset_n) begin
//     led_counter_rcv <= 0;
//   end
//   else if (received) begin
//     led_counter_rcv <= 23'h2DC6C0;
//   end
//   else led_counter_rcv <=(led_counter_rcv > 0) ? led_counter_rcv - 1 : 0;
// end

// ------------------------------------------------------------------------
// A for left, W for jump,, D for right
// ascii for A(a)--65(97) ; W(w)--87(119) ; D(d)--68(100)
// convert to hex--41(61)         57(77)          44(64)
reg [26:0] jump_counter; // at least move for 0.3s (300_0000 clk cycle)
reg [26:0] left_counter; // at least move for 0.3s (300_0000 clk cycle)
reg [26:0] right_counter; // at least move for 0.3s (300_0000 clk cycle)

always @(posedge clk) begin
  if (~reset_n) begin
  // if (~reset_n) begin
    jump_counter <= 0;
    left_counter <= 0;
    right_counter <= 0;
  end
  else if (~received) begin
    jump_counter <= jump_counter>0 ? jump_counter -1 : 0;
    left_counter <= left_counter>0 ? left_counter -1 : 0;
    right_counter <= right_counter>0 ? right_counter -1 : 0;    
  end
  else if ((rx_byte == 8'h57) || (rx_byte == 8'h77)) begin
    //jump_counter <= 27'h4F5_E100;   //2FA_F0F0
    jump_counter <= 27'h335_E100;
  end
  else if ((rx_byte == 8'h41) || (rx_byte == 8'h61)) begin
    //left_counter <= 27'h4F5_E100;
    left_counter <= 27'h2FA_F0F0;
  end
  else if ((rx_byte == 8'h44) || (rx_byte == 8'h64)) begin
    //right_counter <= 27'h4F5_E100;
    right_counter <= 27'h2FA_F0F0;
  end
end

// always @(posedge clk) begin
//   if (~reset_n) begin
//   // if (~reset_n) begin
//     jump_counter <= 0;
//   end
//   else if (~received) begin
//     jump_counter <= jump_counter -1;   
//   end
//   else if ((rx_byte == 8'h57) || (rx_byte == 8'h77)) begin
//     jump_counter <= 23'h989680;
//   end
// end

// always @(posedge clk) begin
//   if (~reset_n) begin
//   // if (~reset_n) begin
//     left_counter <= 0;
//   end
//   else if (~received) begin
//     left_counter <= left_counter -1;   
//   end
//   else if ((rx_byte == 8'h57) || (rx_byte == 8'h77)) begin
//     left_counter <= 23'h989680;
//   end
// end

// always @(posedge clk) begin
//   if (~reset_n) begin
//   // if (~reset_n) begin
//     right_counter <= 0;
//   end
//   else if (~received) begin
//     right_counter <= right_counter -1;   
//   end
//   else if ((rx_byte == 8'h57) || (rx_byte == 8'h77)) begin
//     right_counter <= 23'h989680;
//   end
// end

always @(posedge clk) begin
  if (~reset_n) begin
    jump <= 0;
    left <= 0;
    right <= 0;
  end  
  else begin
    if (jump_counter > 0) jump <= 1;
    else jump <= 0;
    if (left_counter > 0) left <= 1;
    else left <= 0;
    if (right_counter > 0) right <= 1;
    else right <= 0;
  end
end
// ------------------------------------------------------------------------

integer idx;
always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < PROMPT_FIRST_LEN; idx = idx + 1) data[idx] = msg1[idx*8 +: 8];
  end
end

// Combinational I/O logics of the top-level system
// assign enter_pressed = (rx_temp == 8'h0D); // don't use rx_byte here!
// ------------------------------------------------------------------------
// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
// always @(posedge clk) begin
//   rx_temp <= (received)? rx_byte : 8'h0;
// end
// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
	    if (init_counter < INIT_DELAY) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_FIRST_PROMPT;
    S_MAIN_FIRST_PROMPT: // Print the prompt message.
      if (print_done) P_next = S_MAIN_FIRST_READ_NUM;
      else P_next = S_MAIN_FIRST_PROMPT;
    S_MAIN_FIRST_READ_NUM: // wait for <Enter> key.
      P_next = S_MAIN_FIRST_READ_NUM;
    // S_MAIN_REPLY: // Print the hello message.
    //   if (print_done) P_next = S_MAIN_INIT;
    //   else P_next = S_MAIN_REPLY;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_FIRST_PROMPT && P_next == S_MAIN_FIRST_PROMPT);
                  // (P == S_MAIN_SECOND_READ_NUM && P_next == S_MAIN_REPLY);
assign print_done = (tx_byte == 8'h0);

// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                  (P == S_MAIN_FIRST_READ_NUM && received) ||
                  // (P == S_MAIN_SECOND_READ_NUM && received) ||
                   print_enable);

assign moving_key = left || jump || right;
assign echo_key = moving_key ? rx_byte : 0;
// assign echo_key = (moving_key || rx_byte == 8'h0D)? rx_byte : 0;
assign tx_byte  = (P == S_MAIN_FIRST_READ_NUM && received) ? echo_key : data[send_counter];
// evrey time we type in a letter (hit the keyboard), print out what we typed on the screen
// or if we finish typing, then we expect either a new prompt sentence or the fianl result 

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= PROMPT_FIRST_STR;
    // S_MAIN_FIRST_READ_NUM: send_counter <= PROMPT_SECOND_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR); //send_counter increment by 1 every clock
  endcase
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// UART input logic
// End of the UART input logic
// ------------------------------------------------------------------------
endmodule