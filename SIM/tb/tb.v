`timescale 1ns / 1ns
`default_nettype none 

`include "cw305_defines.v"

module tb();

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter pADDR_WIDTH       = 21;
parameter pBYTECNT_SIZE     = 7;
parameter pUSB_CLOCK_PERIOD = 10;
parameter pPLL_CLOCK_PERIOD = 6;
parameter pSEED             = 1;
parameter pTIMEOUT          = 30000;
parameter pVERBOSE          = 0;
parameter pDUMP             = 0;
//------------------------------------------------------------------------------




//------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------

// data I/O for DUT
wire    [            7:0]   usb_data;
reg     [            7:0]   usb_wdata;
reg     [pADDR_WIDTH-1:0]   usb_addr;
reg                         usb_rdn;
reg                         usb_wrn;
reg                         usb_cen;
reg                         usb_trigger;

reg                         pushbutton; // reset button

reg                         j16_sel;
reg                         k16_sel;
reg                         k15_sel;
reg                         l14_sel;
wire                        tio_clkin;
wire                        trig_out;

wire                        led1;
wire                        led2;
wire                        led3;

wire                        tio_trigger;
wire                        tio_clkout;


reg     [           31:0]   write_data;

reg     [          127:0]   read_data;          // data read
reg     [          127:0]   expected_cipher = 128'h8a278bf8fa2812bc39e52c76205af377;

integer                     cycle;
integer                     total_time;
integer                     seed;
integer                     errors;
integer                     warnings;
integer                     i;
//------------------------------------------------------------------------------




//------------------------------------------------------------------------------
// Reset and Clock
//------------------------------------------------------------------------------
reg                         usb_clk_enable;
reg                         usb_clk;
reg                         pll_clk1;
wire                        clk; // shorthand for testbench

initial begin
    usb_clk_enable  =   1'b1;
    usb_clk         =   1'b0;
    pll_clk1        =   1'b0;
end

always #(pUSB_CLOCK_PERIOD/2) usb_clk = !usb_clk;
always #(pPLL_CLOCK_PERIOD/2) pll_clk1 = !pll_clk1;

assign          clk = pll_clk1;     // shorthand for testbench

// maintain a cycle counter
always @(posedge clk) begin
   if (pushbutton == 0)
      cycle <= 0;
   else
      cycle <= cycle + 1;
end
//------------------------------------------------------------------------------




//------------------------------------------------------------------------------
// Timeout Condition
//------------------------------------------------------------------------------
initial begin
   #(pUSB_CLOCK_PERIOD*pTIMEOUT);
      errors = errors + 1;
   $display("ERROR: global timeout");
   $display("SIMULATION FAILED (%0d errors).", errors);
   $finish;
end
//------------------------------------------------------------------------------


   reg read_select;

   assign usb_data = read_select? 8'bz : usb_wdata;
   assign tio_clkin = pll_clk1;

   always @(*) begin
      if (usb_wrn == 1'b0)
         read_select = 1'b0;
      else if (usb_rdn == 1'b0)
         read_select = 1'b1;
   end



   wire #1 usb_rdn_out = usb_rdn;
   wire #1 usb_wrn_out = usb_wrn;
   wire #1 usb_cen_out = usb_cen;
   wire #1 usb_trigger_out = usb_trigger;

   wire trigger; // TODO: use it?

   top_simple_HWDILI #(
      .pBYTECNT_SIZE            (pBYTECNT_SIZE),
      .pADDR_WIDTH              (pADDR_WIDTH)
   ) U_dut (
      .usb_clk                  (usb_clk & usb_clk_enable),
      .usb_data                 (usb_data),
      .usb_addr                 (usb_addr),
      .usb_rdn                  (usb_rdn_out),
      .usb_wrn                  (usb_wrn_out),
      .usb_cen                  (usb_cen_out),
      .usb_trigger              (usb_trigger_out),
      .j16_sel                  (j16_sel),
      .k16_sel                  (k16_sel),
      .k15_sel                  (k15_sel),
      .l14_sel                  (l14_sel),
      .pushbutton               (pushbutton),
      .led1                     (led1),
      .led2                     (led2),
      .led3                     (led3),
      .pll_clk1                 (pll_clk1),
      .tio_trigger              (trigger),
      .tio_clkout               (),             // unused
      .tio_clkin                (tio_clkin)
   );

//------------------------------------------------------------------------------
// Stimulus
//------------------------------------------------------------------------------
initial begin
    usb_wdata       = 'h0;
    usb_addr        = 'h0;
    usb_rdn         = 'h1;
    usb_wrn         = 'h1;
    usb_cen         = 'h1;
    usb_trigger     = 'h0;
end

initial begin
    j16_sel = 1'b0;
    k16_sel = 1'b0;
    k15_sel = 1'b0;
    l14_sel = 1'b0;
end

// Vectors
initial begin
    //`include "../vec/test_basic.v"
    //`include "../vec/test_simple.v"
    `include "../vec/test_decoder.v"
end
//------------------------------------------------------------------------------



`include "tb_cw305_reg_tasks.v"




endmodule

`default_nettype wire

