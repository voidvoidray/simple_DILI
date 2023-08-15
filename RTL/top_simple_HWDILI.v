`timescale 1ns / 1ps
`default_nettype none 

module top_simple_HWDILI #(
    parameter pBYTECNT_SIZE         = 7,
    parameter pADDR_WIDTH           = 21,
    parameter pPT_WIDTH             = 128,
    parameter pCT_WIDTH             = 128,
    parameter pKEY_WIDTH            = 128,
    parameter pSEC_LEVEL_WIDTH      = 3,
    parameter pENCODE_MODE_WIDTH    = 3,
    parameter pOUTPUT_W             = 4,
    parameter pCOEFF_W              = 23,
    parameter pW                    = 64
)(
    // USB Interface
    input wire                          usb_clk,        // Clock
`ifdef SS2_WRAPPER
    output wire                         usb_clk_buf,    // if needed by parent module
`endif
    inout wire [7:0]                    usb_data,       // Data for write/read
    input wire [pADDR_WIDTH-1:0]        usb_addr,       // Address
    input wire                          usb_rdn,        // !RD, low when addr valid for read
    input wire                          usb_wrn,        // !WR, low when data+addr valid for write
    input wire                          usb_cen,        // !CE, active low chip enable
    input wire                          usb_trigger,    // High when trigger requested

    // Buttons/LEDs on Board
    input wire                          j16_sel,        // DIP switch J16
    input wire                          k16_sel,        // DIP switch K16
    input wire                          k15_sel,        // DIP switch K15
    input wire                          l14_sel,        // DIP Switch L14
    input wire                          pushbutton,     // Pushbutton SW4, connected to R1, used here as reset
    output wire                         led1,           // red LED
    output wire                         led2,           // green LED
    output wire                         led3,           // blue LED

    // PLL
    input wire                          pll_clk1,       //PLL Clock Channel #1
    //input wire                        pll_clk2,       //PLL Clock Channel #2 (unused in this example)

    // 20-Pin Connector Stuff
    output wire                         tio_trigger,
    output wire                         tio_clkout,
    input  wire                         tio_clkin

    // Block Interface to Crypto Core
`ifdef USE_BLOCK_INTERFACE
   ,output wire                         crypto_clk,
    output wire                         crypto_rst,
    output wire [pPT_WIDTH-1:0]         crypto_textout,
    output wire [pKEY_WIDTH-1:0]        crypto_keyout,
    input  wire [pCT_WIDTH-1:0]         crypto_cipherin,
    output wire                         crypto_start,
    input wire                          crypto_ready,
    input wire                          crypto_done,
    input wire                          crypto_busy,
    input wire                          crypto_idle
`endif
    );

`ifndef SS2_WRAPPER
    wire usb_clk_buf;
`endif

    wire [pKEY_WIDTH-1:0] crypt_key;
    wire [pPT_WIDTH-1:0] crypt_textout;
    wire [pCT_WIDTH-1:0] crypt_cipherin;
    wire crypt_init;
    wire crypt_ready;
    wire crypt_start;
    wire crypt_done;
    wire crypt_busy;

    wire [7:0] usb_dout;
    wire isout;
    wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0] reg_address;
    wire [pBYTECNT_SIZE-1:0] reg_bytecnt;
    wire reg_addrvalid;
    wire [7:0] write_data;
    wire [7:0] read_data;
    wire reg_read;
    wire reg_write;
    wire [4:0] clk_settings;
    wire crypt_clk;    

    wire resetn = pushbutton;
    wire reset = !resetn;

    // USB CLK Heartbeat
    reg [24:0] usb_timer_heartbeat;
    always @(posedge usb_clk_buf) usb_timer_heartbeat <= usb_timer_heartbeat +  25'd1;
    assign led1 = usb_timer_heartbeat[24];

    // CRYPT CLK Heartbeat
    reg [22:0] crypt_clk_heartbeat;
    always @(posedge crypt_clk) crypt_clk_heartbeat <= crypt_clk_heartbeat +  23'd1;
    assign led2 = crypt_clk_heartbeat[22];



    wire VALID_TO_DUT;
    wire READY_FROM_DUT;
    wire VALID_FROM_DUT;               
    wire READY_TO_DUT;

    cw305_usb_reg_fe #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE),
       .pADDR_WIDTH             (pADDR_WIDTH)
    ) U_usb_reg_fe (
       .rst                     (reset),
       .usb_clk                 (usb_clk_buf), 
       .usb_din                 (usb_data), 
       .usb_dout                (usb_dout), 
       .usb_rdn                 (usb_rdn), 
       .usb_wrn                 (usb_wrn),
       .usb_cen                 (usb_cen),
       .usb_alen                (1'b0),                 // unused
       .usb_addr                (usb_addr),
       .usb_isout               (isout), 
       .reg_address             (reg_address), 
       .reg_bytecnt             (reg_bytecnt), 
       .reg_datao               (write_data), 
       .reg_datai               (read_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write), 
       .reg_addrvalid           (reg_addrvalid)
    );

    wire                            dut_RESET;
    wire [pSEC_LEVEL_WIDTH-1:0]     w_sec_lvl;
    wire [pENCODE_MODE_WIDTH-1:0]   w_encode_modei;
    wire [pW-1:0]                   w_di;
    wire [pOUTPUT_W*pCOEFF_W-1:0]   w_samples;

    cw305_hostif #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE),
       .pADDR_WIDTH             (pADDR_WIDTH),
       .pPT_WIDTH               (pPT_WIDTH),
       .pCT_WIDTH               (pCT_WIDTH),
       .pKEY_WIDTH              (pKEY_WIDTH)
    ) uHOSTIF (
       .reset_i                 (reset),
       .crypto_clk              (crypt_clk),
       .usb_clk                 (usb_clk_buf), 
       .reg_address             (reg_address[pADDR_WIDTH-pBYTECNT_SIZE-1:0]), 
       .reg_bytecnt             (reg_bytecnt), 
       .read_data               (read_data), 
       .write_data              (write_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write), 
       .reg_addrvalid           (reg_addrvalid),

       .exttrigger_in           (usb_trigger),

       .I_textout               (128'b0),               // unused
       .I_cipherout             (crypt_cipherin),
       .I_ready                 (crypt_ready),
       .I_done                  (crypt_done),
       .I_busy                  (crypt_busy),

       .O_clksettings           (clk_settings),
       .O_user_led              (led3),
       .O_key                   (crypt_key),
       .O_textin                (crypt_textout),
       .O_cipherin              (),                     // unused
       .O_start                 (crypt_start),

       .oRESET                  (dut_RESET       ),
       .o_sec_lvl               ( w_sec_lvl      ),
       .o_encode_modei          ( w_encode_modei ),
       .o_di                    ( w_di           ),        
       .i_samples               ( w_samples      ),
       .VALID_TO_DUT            ( VALID_TO_DUT   ),
       .READY_FROM_DUT          ( READY_FROM_DUT ),
       .VALID_FROM_DUT          ( VALID_FROM_DUT ),
       .READY_TO_DUT            ( READY_TO_DUT   )
    );

    assign usb_data = isout? usb_dout : 8'bZ;


    clocks U_clocks (
       .usb_clk                 (usb_clk),
       .usb_clk_buf             (usb_clk_buf),
       .I_j16_sel               (j16_sel),
       .I_k16_sel               (k16_sel),
       .I_clock_reg             (clk_settings),
       .I_cw_clkin              (tio_clkin),
       .I_pll_clk1              (pll_clk1),
       .O_cw_clkout             (tio_clkout),
       .O_cryptoclk             (crypt_clk)
    );



  // Block interface is used by the IP Catalog. If you are using block-based
  // design define USE_BLOCK_INTERFACE.
`ifdef USE_BLOCK_INTERFACE
    assign crypto_clk = crypt_clk;
    assign crypto_rst = crypt_init;
    assign crypto_keyout = crypt_key;
    assign crypto_textout = crypt_textout;
    assign crypt_cipherin = crypto_cipherin;
    assign crypto_start = crypt_start;
    assign crypt_ready = crypto_ready;
    assign crypt_done = crypto_done;
    assign crypt_busy = crypto_busy;
    assign tio_trigger = ~crypto_idle;
`endif

  // START CRYPTO MODULE CONNECTIONS
  // The following can have your crypto module inserted.
  // This is an example of the Google Vault AES module.
  // You can use the ILA to view waveforms if needed, which
  // requires an external USB-JTAG adapter (such as Xilinx Platform
  // Cable USB).

decoder #(
    .OUTPUT_W (  4 ),
    .COEFF_W  ( 23 ),
    .W        ( 64 )
) uDUT (
    .rst            ( dut_RESET      ),
    .clk            ( crypt_clk      ),
    .sec_lvl        ( w_sec_lvl      ), // [2:0]
    .encode_modei   ( w_encode_modei ), // [2:0]
    .valid_i        ( VALID_TO_DUT   ),
    .ready_i        ( READY_FROM_DUT ),
    .di             ( w_di           ), // [W-1:0]
    .samples        ( w_samples      ), // [OUTPUT_W*COEFF_W-1:0]
    .valid_o        ( VALID_FROM_DUT ),
    .ready_o        ( READY_TO_DUT   ) 
);


endmodule

`default_nettype wire

