`default_nettype none
`timescale 1ns / 1ps
`include "cw305_defines.v"

module cw305_hostif #(
   parameter pADDR_WIDTH            = 21,
   parameter pBYTECNT_SIZE          = 7,
   parameter pDONE_EDGE_SENSITIVE   = 1,
   parameter pPT_WIDTH              = 128,
   parameter pCT_WIDTH              = 128,
   parameter pKEY_WIDTH             = 128,
   parameter pCRYPT_TYPE            = 2,
   parameter pCRYPT_REV             = 4,
   parameter pIDENTIFY              = 8'h2e,
   parameter pSEC_LEVEL_WIDTH       = 3,
   parameter pENCODE_MODE_WIDTH     = 3,
   parameter pOUTPUT_W              = 4,
   parameter pCOEFF_W               = 23,
   parameter pW                     = 64
)(

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire                                  crypto_clk,
   input  wire                                  reset_i,
   input  wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0]  reg_address,     // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output reg  [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write,       // Write flag. When high on rising edge valid data is
                                                                 // present on write_data
   input  wire                                  reg_addrvalid,   // Address valid flag

// from top:
   input  wire                                  exttrigger_in,

// register inputs:
   input  wire [pPT_WIDTH-1:0]                  I_textout,
   input  wire [pCT_WIDTH-1:0]                  I_cipherout,
   input  wire                                  I_ready,  /* Crypto core ready. Tie to '1' if not used. */
   input  wire                                  I_done,   /* Crypto done. Can be high for one crypto_clk cycle or longer. */
   input  wire                                  I_busy,   /* Crypto busy. */

// register outputs:
   output reg   [4:0]                           O_clksettings,
   output reg                                   O_user_led,
   output wire  [pKEY_WIDTH-1:0]                O_key,
   output wire  [pPT_WIDTH-1:0]                 O_textin,
   output wire  [pCT_WIDTH-1:0]                 O_cipherin,
   output wire                                  O_start,   /* High for one crypto_clk cycle, indicates text ready. */
   output reg   [pSEC_LEVEL_WIDTH-1:0]          o_sec_lvl,
   output reg   [pENCODE_MODE_WIDTH-1:0]        o_encode_modei,
   output wire                                  oRESET,
   output reg   [pW-1:0]                        o_di,
   input  wire  [pOUTPUT_W*pCOEFF_W-1:0]        i_samples,
   output wire                                  VALID_TO_DUT,
   input  wire                                  READY_FROM_DUT,
   input  wire                                  VALID_FROM_DUT,
   output wire                                  READY_TO_DUT
);

   reg  [7:0]                   reg_read_data;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherin;
   reg  [pKEY_WIDTH-1:0]        reg_crypt_key;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textin;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textout;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherout;
   reg                          reg_crypt_go_pulse;
   wire                         reg_crypt_go_pulse_crypt;


   reg                          busy_usb;
   reg                          done_r;
   wire                         done_pulse;
   wire                         crypt_go_pulse;
   reg                          go_r;
   reg                          go;
   wire [31:0]                  buildtime;

   reg                          dut_reset;
   reg                          start;

   (* ASYNC_REG = "TRUE" *) reg  [pKEY_WIDTH-1:0] reg_crypt_key_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textin_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [pCT_WIDTH-1:0] reg_crypt_cipherout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [1:0] go_pipe;
   (* ASYNC_REG = "TRUE" *) reg  [1:0] busy_pipe;


   always @(posedge crypto_clk) begin
       done_r <= I_done & pDONE_EDGE_SENSITIVE;
   end
   assign done_pulse = I_done & ~done_r;

   always @(posedge crypto_clk) begin
       if (done_pulse) begin
           reg_crypt_cipherout <= I_cipherout;
           reg_crypt_textout   <= I_textout;
       end
       reg_crypt_key_crypt <= reg_crypt_key;
       reg_crypt_textin_crypt <= reg_crypt_textin;
   end

   always @(posedge usb_clk) begin
       reg_crypt_cipherout_usb <= reg_crypt_cipherout;
       reg_crypt_textout_usb   <= reg_crypt_textout;
   end

   assign O_textin = reg_crypt_textin_crypt;
   assign O_key = reg_crypt_key_crypt;
   assign O_start = crypt_go_pulse || reg_crypt_go_pulse_crypt;

   assign   oRESET  =   dut_reset;
//------------------------------------------------------------------------------




//------------------------------------------------------------------------------
// read logic:
//------------------------------------------------------------------------------

always @(*) begin
    if (reg_addrvalid && reg_read) begin
        case (reg_address)
            `REG_CLKSETTINGS:           reg_read_data = O_clksettings;
            `REG_USER_LED:              reg_read_data = O_user_led;
            `REG_CRYPT_TYPE:            reg_read_data = pCRYPT_TYPE;
            `REG_CRYPT_REV:             reg_read_data = pCRYPT_REV;
            `REG_IDENTIFY:              reg_read_data = pIDENTIFY;
            `REG_CRYPT_GO:              reg_read_data = busy_usb;
            `REG_CRYPT_KEY:             reg_read_data = reg_crypt_key[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTIN:          reg_read_data = reg_crypt_textin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHERIN:        reg_read_data = reg_crypt_cipherin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTOUT:         reg_read_data = reg_crypt_textout_usb[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHEROUT:       reg_read_data = reg_crypt_cipherout_usb[reg_bytecnt*8 +: 8];
            `REG_BUILDTIME:             reg_read_data = buildtime[reg_bytecnt*8 +: 8];
            default:                    reg_read_data = 0;
        endcase
    end
    else begin
        reg_read_data = 0;
    end
end

// Register output read data to ease timing. If you need read data one clock
// cycle earlier, simply remove this stage:
always @(posedge usb_clk)
    read_data <= reg_read_data;
//------------------------------------------------------------------------------




//------------------------------------------------------------------------------
// write logic (USB clock domain):
//------------------------------------------------------------------------------
always @(posedge usb_clk) begin
    if (reset_i) begin
        O_clksettings <= 0;
    end
    else begin
       if (reg_addrvalid && reg_write) begin
          case (reg_address)
             `REG_CLKSETTINGS:        O_clksettings <= write_data;
          endcase
       end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        O_user_led <= 0;
    end
    else begin
       if (reg_addrvalid && reg_write) begin
          case (reg_address)
             `REG_USER_LED:           O_user_led <= write_data;
          endcase
       end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        reg_crypt_go_pulse <= 1'b0;
    end
    else begin
        // REG_CRYPT_GO register is special: writing it creates a pulse. Reading it gives you the "busy" status.
        if ( (reg_addrvalid && reg_write && (reg_address == `REG_CRYPT_GO)) ) begin
            reg_crypt_go_pulse <= 1'b1;
        end
        else begin
            reg_crypt_go_pulse <= 1'b0;
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        reg_crypt_textin    =   'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_CRYPT_TEXTIN:       reg_crypt_textin[reg_bytecnt*8 +: 8] <= write_data;
            endcase
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        reg_crypt_cipherin  =   'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_CRYPT_CIPHERIN:     reg_crypt_cipherin[reg_bytecnt*8 +: 8] <= write_data;
            endcase
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        reg_crypt_key       =   'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_CRYPT_KEY:          reg_crypt_key[reg_bytecnt*8 +: 8] <= write_data;
            endcase
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        dut_reset  <= 1'h0;
    end
    else begin
        if (dut_reset == 1'b1) begin
            dut_reset  <= 1'b0;
        end
        else begin
            if (reg_addrvalid && reg_write) begin
                case (reg_address)
                    `REG_CONTROL:   dut_reset  <= write_data[0];
                endcase
            end
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        o_sec_lvl  <= 3'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_CONTROL2:   o_sec_lvl  <= write_data[0 +: 3];
            endcase
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        o_encode_modei  <= 3'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_CONTROL2:   o_encode_modei  <= write_data[4 +: 3];
            endcase
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        start  <= 1'h0;
    end
    else begin
        if (start == 1'b1) begin
            start  <= 1'b0;
        end
        else begin
            if (reg_addrvalid && reg_write) begin
                case (reg_address)
                    `REG_CONTROL3:   start  <= write_data[0];
                endcase
            end
        end
    end
end

always @(posedge usb_clk) begin
    if (reset_i) begin
        o_di  <= 'h0;
    end
    else begin
        if (reg_addrvalid && reg_write) begin
            case (reg_address)
                `REG_DATAIN:   o_di[reg_bytecnt*8 +: 8] <= write_data;
            endcase
        end
    end
end

reg datvalid;
always @(posedge usb_clk) begin
    if (reset_i) begin
        datvalid <= 1'b0;
    end
//    else if (READY_FROM_DUT == 1'b1) begin
//        datvalid <= 1'b0;
//    end
    else if (start == 1'b1) begin
        datvalid <= 1'b1;
    end
//    else if (datvalid == 1'b1) begin
//        datvalid <= 1'b0;
//    end
end

assign  VALID_TO_DUT    = datvalid;

assign  READY_TO_DUT    = 1'b1;

reg  [pOUTPUT_W*pCOEFF_W-1:0]        samples;
always @(posedge usb_clk) begin
    if (reset_i) begin
        samples <= 'h0;
    end
    else if (VALID_FROM_DUT == 1'b1) begin
        samples <= 1'b0;
    end
end

reg dat_recv_ack;
always @(posedge usb_clk) begin
    if (reset_i) begin
        dat_recv_ack <= 1'b0;
    end
    else if (READY_FROM_DUT == 1'b1) begin
        dat_recv_ack <= 1'b0;
    end
end



always @(posedge crypto_clk) begin
   {go_r, go, go_pipe} <= {go, go_pipe, exttrigger_in};
end
assign crypt_go_pulse = go & !go_r;

cdc_pulse U_go_pulse (
    .reset_i       (reset_i),
    .src_clk       (usb_clk),
    .src_pulse     (reg_crypt_go_pulse),
    .dst_clk       (crypto_clk),
    .dst_pulse     (reg_crypt_go_pulse_crypt)
);

always @(posedge usb_clk)
   {busy_usb, busy_pipe} <= {busy_pipe, I_busy};


`ifdef ILA_REG
    ila_0 U_reg_ila (
 .clk            (usb_clk),                      // input wire clk
 .probe0         (reg_address[7:0]),             // input wire [7:0]  probe0  
 .probe1         (reg_bytecnt),                  // input wire [6:0]  probe1 
 .probe2         (read_data),                    // input wire [7:0]  probe2 
 .probe3         (write_data),                   // input wire [7:0]  probe3 
 .probe4         (reg_read),                     // input wire [0:0]  probe4 
 .probe5         (reg_write),                    // input wire [0:0]  probe5 
 .probe6         (reg_addrvalid),                // input wire [0:0]  probe6 
 .probe7         (reg_read_data),                // input wire [7:0]  probe7 
 .probe8         (exttrigger_in),                // input wire [0:0]  probe8 
 .probe9         (1'b0),                         // input wire [0:0]  probe9
 .probe10        (reg_crypt_go_pulse)            // input wire [0:0]  probe10
    );
`endif

`ifdef ILA_CRYPTO
    ila_1 U_reg_aes (
 .clk            (crypto_clk),                   // input wire clk
 .probe0         (O_start),                      // input wire [0:0]  probe0  
 .probe1         (I_done),                       // input wire [0:0]  probe1 
 .probe2         (I_cipherout[7:0]),             // input wire [7:0]  probe2 
 .probe3         (O_textin[7:0]),                // input wire [7:0]  probe3 
 .probe4         (done_pulse)                    // input wire [0:0]  probe4 
    );
`endif

`ifndef __ICARUS__
   USR_ACCESSE2 U_buildtime (
      .CFGCLK(),
      .DATA(buildtime),
      .DATAVALID()
   );
`else
   assign buildtime = 0;
`endif


endmodule

`default_nettype wire
