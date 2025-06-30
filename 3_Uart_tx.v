//FSM:-IDLE → START → DATA[0→7] → STOP → IDLE

module uart_tx(
  input wire clk,
  input wire reset,
  input wire tx_start,// signal to start transmission
  input wire baud_tick,// 1-clock pulse at baud rate
  input wire[7:0] tx_data,// data to send
  input wire[1:0] parity_mode, //00:none, 01:even, 10:odd
  output reg tx,     // serial TX output
  output reg tx_busy // high while transmitting
);
  
  typedef enum logic [2:0] {idle,start,data,parity,stop} state_t;
 
  state_t state;
  reg [2:0] bit_idx; // bit index for data[7:0]
  reg [7:0] data_buf;//temorarily store the input data
  reg parity_bit; //to store parity bit that have to send over Tx line
  
  
  //function to calculate parity 
  function automatic parity_calc;
    input [7:0] data;
    input [1:0] mode;
    reg parity;
    begin
      parity=^data;//xor calculation
      case(mode)
        2'b01: parity_calc=parity;//even parity
        2'b10: parity_calc=~parity;//odd parity
        default: parity_calc=1'b0;//no parity
      endcase
    end
  endfunction
  
  //Transmit FSM
  always@(posedge clk or posedge reset) begin
    if(reset) begin
      state<=idle;
      tx<=1'b1;   //ideal state =high
      tx_busy<=1'b0;
      bit_idx<=3'd0;
      data_buf<=8'd0;
      parity_bit<=1'b0;
    end else if(baud_tick) begin
      
      case(state) 
        
        idle: begin
          tx<=1'b1;
          tx_busy<=1'b0;
          if(tx_start) begin
            data_buf<=tx_data; //temporarily store the input data
            parity_bit<=parity_calc(tx_data, parity_mode);
            tx_busy<=1'b1;// Now busy
            bit_idx<=3'd0;// Reset bit index
            state<=start;// Go to start bit
          end
        end
        
        start: begin
          tx<=1'b0; // Start bit is LOW
          state<=data;
        end
        
        data: begin
          tx<=data_buf[bit_idx]; // transmit data bit by bit
          if(bit_idx==3'd7) begin
            if(parity_mode==2'b00)
              state<=stop;// No parity, go to STOP
         	else
              state<=parity;// Else go to PARITY bit
          end else begin
            bit_idx<=bit_idx+1;// Move to next bit
          end
        end
          
        parity: begin
          tx<=parity_bit;
          state<=stop;
        end
        
        stop: begin
          tx<=1'b1; // stop bit =high
          state<=idle;
          tx_busy<=1'b0;
        end
      endcase
    end
  end
endmodule
  
  
  
  
      
      
      
      
      
      
      
      
      

