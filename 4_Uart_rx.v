module uart_rx(
  input wire clk,
  input wire reset,
  input wire rx,
  input wire sample_tick,
  input wire[1:0] parity_mode,
  output reg[7:0] rx_data,
  output reg rx_done,
  output reg parity_error
);
  
    // FSM States
  typedef enum logic[2:0] {idle,start,data,parity, stop} state_t;
  
  state_t state;// Current state of receiver FSM
  reg [3:0] sample_count;// Count sample_tick (0 to 15 for oversampling)
  reg [2:0] bit_idx;// Index of current data bit being received
  reg [7:0] data_buf;// Buffer to collect received bits
  reg rx_parity; // Parity bit received
  
  function automatic logic expected_parity;
    input[7:0] data;
    input[1:0] mode;
    reg parity;
    begin
      parity=^data;
      case(mode)
        2'b01:expected_parity=parity; //even
        2'b10:expected_parity=~parity; //odd
        default: expected_parity=1'b0; //none
      endcase
    end
  endfunction
  
  
  always @(posedge clk or posedge reset) begin
    
    if(reset) begin
      state<=idle;
      sample_count<=0;
      bit_idx<=0;
      rx_done<=0;
      parity_error<=0;
      data_buf<=8'd0;
      rx_data<=8'd0;
      rx_parity<=1'b0;
    end else if(sample_tick) begin
      rx_done<=0; // Clear done flag on every sample_tick unless set
      
      case(state)
        
        idle:begin
          if(rx==0) begin // Detect start bit (LOW)
            state<=start;
            sample_count<=0;
          end
        end
        
        start: begin
          sample_count<=sample_count+1;
          if(sample_count==4'd7) begin // Sample at midpoint (8th tick)
            if(rx==0) begin // Confirm it's still LOW (valid start)
              state<=data;
              sample_count<=0;
              bit_idx<=0;
            end else begin
              state<=idle; // False start detected
            end
          end
        end
        
        data:begin
          sample_count<=sample_count+1;
          if(sample_count==4'd15) begin // Sample each data bit on last tick
            sample_count<=0;
            data_buf[bit_idx]<=rx; // Capture bit from rx line
            if(bit_idx==3'd7) begin 
              if(parity_mode==2'b00) 
                state<=stop;    // No parity → go to STOP
              else 
                state<=parity;// Parity enabled → go to PARITY state
            end else begin
              bit_idx<=bit_idx+1; // Next bit
            end
          end
        end
        
        parity:begin
          sample_count<=sample_count+1;
          if(sample_count==4'd15) begin
            rx_parity<=rx;// Capture the parity bit
            state<=stop;
            sample_count<=0;
          end
        end
        
        stop:begin
          sample_count<=sample_count+1;
          if(sample_count==4'd15) begin
            rx_data<=data_buf; // Output received data
            rx_done<=1; // One-cycle pulse to indicate done
            
          //check parity if enable
            if(parity_mode!=2'b00)
              parity_error<=(rx_parity!=expected_parity(data_buf,parity_mode));
            else
              parity_error<=0;
            state<=idle;
            sample_count<=0;
          end
        end
      endcase
    end
  end
endmodule
        
        



