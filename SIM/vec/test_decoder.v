// resets pushbutton

reset_pushbutton(); repeat (500) @(posedge usb_clk);
reset_pushbutton(); repeat (500) @(posedge usb_clk);
reset_pushbutton(); repeat (500) @(posedge usb_clk);
reset_pushbutton(); repeat (500) @(posedge usb_clk);
reset_pushbutton(); repeat (500) @(posedge usb_clk);




// resets

write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (50) @(posedge usb_clk);




// control

write_bytes(0, 1, `REG_CONTROL2, {8'h11}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h22}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h33}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h44}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h55}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h66}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h77}); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h00}); repeat (50) @(posedge usb_clk);




// datain

write_bytes(0, 8, `REG_DATAIN, {32'h12345678,32'h9ABCDEF0}); repeat (50) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'hDEADBEEF,32'hDEADCAFE}); repeat (50) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'hDEAD1234,32'h1234CAFE}); repeat (50) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'h5678BEEF,32'hDEAD5678}); repeat (50) @(posedge usb_clk);




// start
write_bytes(0, 1, `REG_CONTROL3, {8'h01}); repeat (1) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'h12345678,32'h9ABCDEF0}); repeat (1) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'hDEADBEEF,32'hDEADCAFE}); repeat (1) @(posedge usb_clk);


repeat (5000) @(posedge usb_clk);
