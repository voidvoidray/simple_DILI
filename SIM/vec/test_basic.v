
      seed = pSEED;
      errors = 0;
      warnings = 0;
      $display("Running with seed=%0d", seed);
//      $random(seed);
      if (pDUMP) begin
         $dumpfile("results/tb.fst");
         $dumpvars(0, tb);
      end
      usb_clk = 1'b1;
      usb_clk_enable = 1'b1;
      pll_clk1 = 1'b1;

      usb_wdata = 0;
      usb_addr = 0;
      usb_rdn = 1;
      usb_wrn = 1;
      usb_cen = 1;
      usb_trigger = 0;

      j16_sel = 0;
      k16_sel = 0;
      k15_sel = 0;
      l14_sel = 0;
      pll_clk1 = 0;

      // pushbotton reset
      //pushbutton = 1;
      //#(pUSB_CLOCK_PERIOD*2) pushbutton = 0;
      //#(pUSB_CLOCK_PERIOD*2) pushbutton = 1;
      //#(pUSB_CLOCK_PERIOD*10);
      reset_pushbutton();

      write_bytes(0, 16, `REG_CRYPT_TEXTIN, {32'h12345678, 32'habcdef01, 32'h87654321, 32'hdeadbeef});
      repeat (500) @(posedge usb_clk);
      write_bytes(0, 16, `REG_CRYPT_KEY, {32'habcdef01, 32'h12345678, 32'hdeadbeef, 32'h87654321});

      $display("Encrypting via register...");
      write_byte(0, `REG_CRYPT_GO, 0, 1);
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(0, 16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors = errors + 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end


      $display("Encrypting via usb_trigger (USB clock disabled)...");
      write_bytes(0, 1, `REG_CRYPT_TEXTIN, 8'h01);
      expected_cipher = 128'h0efee0bff4cf170752994fb45bd45934;
      usb_clk_enable = 1'b0;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (10) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (30) @(posedge pll_clk1);
      usb_clk_enable = 1'b1;
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(0, 16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors = errors + 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end


      $display("Encrypting via usb_trigger (USB clock enabled)...");
      write_bytes(0, 1, `REG_CRYPT_TEXTIN, 8'h02);
      expected_cipher = 128'h8623e205b50bede46f795d1aad15faae;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (10) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (30) @(posedge pll_clk1);
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(0, 16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors = errors + 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end

      $display("Encrypting via usb_trigger (USB clock disabled, returns mid-encryption)...");
      write_bytes(0, 1, `REG_CRYPT_TEXTIN, 8'h03);
      expected_cipher = 128'h46be87df4d18bfe6d0d1d3b20b6bf382;
      usb_clk_enable = 1'b0;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (2) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (2) @(posedge pll_clk1);
      usb_clk_enable = 1'b1;
      repeat (1) @(posedge usb_clk);
      wait_done();
      read_bytes(0, 16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors = errors + 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end



      $display("done!");
      #(pUSB_CLOCK_PERIOD*10);
      if (errors)
         $display("SIMULATION FAILED (%0d errors, %0d warnings).", errors, warnings);
      else
         $display("Simulation passed (%0d warnings).", warnings);
      $finish;
