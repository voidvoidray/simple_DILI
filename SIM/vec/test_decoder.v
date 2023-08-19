// resets pushbutton

reset_pushbutton(); repeat (50) @(posedge usb_clk);
reset_pushbutton(); repeat (50) @(posedge usb_clk);
reset_pushbutton(); repeat (50) @(posedge usb_clk);
reset_pushbutton(); repeat (50) @(posedge usb_clk);
reset_pushbutton(); repeat (50) @(posedge usb_clk);




// resets

write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL, {8'h01}); repeat (5) @(posedge usb_clk);




// control

write_bytes(0, 1, `REG_CONTROL2, {8'h11}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h22}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h33}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h44}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h55}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h66}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h77}); repeat (5) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL2, {8'h00}); repeat (5) @(posedge usb_clk);




// datain

write_bytes(0, 8, `REG_DATAIN, {32'h12345678,32'h9ABCDEF0}); repeat (5) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'hDEADBEEF,32'hDEADCAFE}); repeat (5) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'hDEAD1234,32'h1234CAFE}); repeat (5) @(posedge usb_clk);
write_bytes(0, 8, `REG_DATAIN, {32'h5678BEEF,32'hDEAD5678}); repeat (5) @(posedge usb_clk);


write_bytes(0, 8, `REG_DATAIN, {32'h5678BEEF,32'hDEAD5678}); repeat (500) @(posedge usb_clk);


// start
write_bytes(0, 1, `REG_CONTROL2, {8'h22}); repeat (50) @(posedge usb_clk);                      // config

// data 1
write_bytes(0, 8, `REG_DATAIN, { 32'h31116c96,32'h1a71a6c0 }); repeat (50) @(posedge usb_clk);  // data input
write_bytes(0, 1, `REG_CONTROL3, {8'h01}); repeat (50) @(posedge usb_clk);                      // start

read_bytes(0, 12, `REG_SAMPLES0, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples0: %X", read_data );
read_bytes(0, 12, `REG_SAMPLES1, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples1: %X", read_data );
read_bytes(0, 12, `REG_SAMPLES2, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples2: %X", read_data );
read_bytes(0, 12, `REG_SAMPLES3, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples3: %X", read_data );
read_bytes(0, 12, `REG_SAMPLES4, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples4: %X", read_data );
read_bytes(0, 12, `REG_SAMPLES5, read_data); repeat (50) @(posedge usb_clk);                       // samples
$display ( "READ samples5: %X", read_data );

// data 2
write_bytes(0, 8, `REG_DATAIN, { 32'h426508d8,32'h21a8d92a }); repeat (50) @(posedge usb_clk);
write_bytes(0, 1, `REG_CONTROL3, {8'h01}); repeat (50) @(posedge usb_clk);                      // start

read_bytes(0, 12, `REG_SAMPLES0, read_data); repeat (50) @(posedge usb_clk);                       // samples
read_bytes(0, 12, `REG_SAMPLES1, read_data); repeat (50) @(posedge usb_clk);                       // samples
read_bytes(0, 12, `REG_SAMPLES2, read_data); repeat (50) @(posedge usb_clk);                       // samples
read_bytes(0, 12, `REG_SAMPLES3, read_data); repeat (50) @(posedge usb_clk);                       // samples
read_bytes(0, 12, `REG_SAMPLES4, read_data); repeat (50) @(posedge usb_clk);                       // samples
read_bytes(0, 12, `REG_SAMPLES5, read_data); repeat (50) @(posedge usb_clk);                       // samples


repeat (5000) @(posedge usb_clk);
