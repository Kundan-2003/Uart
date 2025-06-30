module baud_gen #(parameter clk_freq=50000000, //50MHZ
                  baud_rate=9600)
  
  (
    input wire clk,
    input wire reset,
    output reg sample_tick
  );
  
  localparam integer baud_16x_div=clk_freq/(baud_rate*16); 
  // clk_freq= our clock freq; baud_rate=that both tx and rx agree to work on; 16->for oversampling that tx will use(and take the middle sampled value) 
  
//  CLOCK_FREQ = 50_000_000
// BAUD_RATE  = 9600
// BAUD_16X_DIV = 50_000_000 / (9600 × 16)
//               = 50_000_000 / 153600
//               ≈ 326 clock cycles
// Matlab:
// 326 clock cycles mein ek sample_tick pulse dena hai.
  
  
  reg[$clog2(baud_16x_div)-1:0] count;
  
  always @(posedge clk or posedge reset)
    if(reset) begin
      count<=0;
      sample_tick<=0;
    end else begin
      if(count==baud_16x_div-1) begin
        count<=0;
        sample_tick<=1;
      end else begin
       count<=count+1;
        sample_tick<=0;
      end
    end
  end
endmodule
       







