//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase
  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Task:
  // Implement a module that detects the "110011" input sequence
  //
  // Hint: See Lecture 3 for details

  // States
  enum logic[2:0]
  {
     IDLE = 3'b000,
     S1   = 3'b001,
     S2   = 3'b010,
     S3   = 3'b011,
     S4   = 3'b100,
     S5   = 3'b101,
     S6   = 3'b110
  }
  state, new_state;

  // state  when0  when1
  // IDLE   stay   S1
  // S1     IDLE   S2
  // S2     S3     stay
  // S3     S4     S1
  // S4     IDLE   S5
  // S5     IDLE   S6
  // S6     S3     S2

  // State transition logic
  always_comb
  begin
    new_state = state;

    case (state)
      IDLE: if (  a) new_state = S1;   // First  "1" -> we are in
      S1:   if (  a) new_state = S2;   // Second "1" -> ok, look for zeroes
            else     new_state = IDLE; //            "0" -> start over
      S2:   if (~ a) new_state = S3;   // Third  "0" -> ok, need the second one
      S3:   if (~ a) new_state = S4;   // Fourth "0" -> ok, look for ones
            else     new_state = S1;   //            "1" -> start from "First 1"
      S4:   if (  a) new_state = S5;   // Fifth  "1" -> ok, almost there
            else     new_state = IDLE; //            "0" -> start over
      S5:   if (  a) new_state = S6;   // Sixth  "1" -> detected
            else     new_state = IDLE; //            "0" -> start over
      S6:   if (  a) new_state = S2;   //        "1" -> restart from S2
            else     new_state = S3;   //            "0" -> restart from S3
    endcase
  end

  // Output logic (depends only on the current state)
  assign detected = (state == S6);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  logic clk;

  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

  logic rst;

  initial
  begin
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  end

  logic a, det4bit, det6bit;
  detect_4_bit_sequence_using_fsm det4b (.detected (det4bit),  .*);
  detect_6_bit_sequence_using_fsm det6b (.detected (det6bit), .*);

  localparam n = 24;

  // The sequence of input values
  localparam [0 : n - 1] seq_a       = 24'b0011_0101_1001_1001_1010_1000;

  // The sequence of expected output values
  localparam [0 : n - 1] seq_det4bit = 24'b0000_0001_0000_0000_0000_1010;
  localparam [0 : n - 1] seq_det6bit = 24'b0000_0000_0000_0100_0100_0000;

  initial
  begin
    `ifdef __ICARUS__
        // Uncomment the following lines
        // to generate a VCD file and analyze it using GTKwave

        // $dumpfile ("dump_03_01.vcd");
        // $dumpvars;
    `endif

    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a [i];

      @ (posedge clk);

      $display ("%b %b (%b) %b (%b)",
        a,
        det4bit, seq_det4bit[i],
        det6bit, seq_det6bit[i]);

      if (   det4bit !== seq_det4bit[i]
          || det6bit !== seq_det6bit[i])
      begin
        $display ("%s FAIL - see log above", `__FILE__);
        $finish;
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
