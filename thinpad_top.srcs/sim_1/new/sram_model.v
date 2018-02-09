//**************************************************************************//
//
//    File Name: AS7C34098A.v
//      Version:  1.0
//         Date:  2 April 2005
//        Model:  BUS Functional
//    Simulator:  Cadence verilog-Xl
//
//
//      Company:  Alliance Semiconductor pvt ltd.
//  Part Number:  AS7C34098A (256K x 16)
//
//  Description:  Alliance 4Mb Fast Asynchronous SRAM
//
//  Note: The model is Done for 10ns cycle time . To work with other cycle time, 
//  we have to change the timing parameters according to Data sheet.
//   
//**************************************************************************//

`timescale 1 ns/1 ps


module sram_model(Address, DataIO, OE_n, CE_n,WE_n, LB_n, UB_n);

`define tsim  20000

// Port Signal Definitions

input [19:0] Address;
inout [15:0] DataIO ;
input OE_n,CE_n,WE_n, LB_n, UB_n;

// Write Cycle Timing Parameters

time twc ;   // write cycle time
time tcw ;   // Chip enable to write end
time taw ;   // address setup to write end
time tas ;   // address setup time
time twp1 ;  // write pulse width(OE_n =1)
time twp2 ;  // write pulse width(OE_n =0)
time twr ;   // write recovery time
time tah ;   // address hold from end of write
time tdw ;   // data valid to write end
time tdh ;   // data hold time
time twz ;   // write enable to output in high-Z
time tow ;   // output active from write end
time tbw ;   // byte enable low to write end

time UB_n_start_time,LB_n_start_time;
time write_address1_time,write_data1_time,write_CE_n_start_time1,write_WE_n_start_time1; 
time write_CE_n_start_time,write_WE_n_start_time,write_address_time,write_data_time;
time temptaa, temptoe, read_address_add,read_address_oe ;


// Read Cycle Timing Parameters

time trc ;   // Read cycle time
time taa ;   // Address access time
time tace ;  // chip enable access time
time toe ;   // output enable access time
time toh ;   // output hold from address change
time tclz ;  // CE_n low to output in low-Z
time tchz ;  // CE_n high to output in High-Z
time tolz ;  // OE_n low to output in low-Z
time tohz ;  // OE_n high to output in High-Z
time tba ;   // LB_n/UB_n access time
time tblz ;  // LB_n/UB_n low to output in low-Z
time tbhz ;  // LB_n/UB_n high to output in High-Z
time tpu ;   // power up time
time tpd ;   // power down time

time read_address_time,read_CE_n_start_time,read_WE_n_start_time,read_OE_n_start_time;



// Internal Signal Definition
            // For Write access
reg   activate_cebar,activate_webar,activate_wecebar;
reg   initiate_write1,initiate_write2,initiate_write3;
reg   WE_dly;
reg   [19:0] Address_write1,Address_write2;
reg   [7:0] dummy_array0 [1048575:0];
reg   [15:8] dummy_array1 [1048575:0];
reg   [7:0] mem_array0 [1048575:0];
reg   [15:8] mem_array1 [1048575:0];
reg   [15:0] dataIO1;

            //For Read Access       
reg   [15:0] data_read;
reg   [19:0] Address_read1,Address_read2 ;
reg   initiate_read1,initiate_read2;



//Intializing values 

initial
   begin
            // write timings -- 10ns address access time
         twc = 10 ;
         tcw = 7 ;
         taw = 7 ;
   tas = 0 ;
   twp1 = 7 ;
   twp2 = 10 ;
   twr = 0 ;
   tah = 0 ;
   tdw = 5 ;
   tdh =0 ;
   twz = 5 ;
   tow = 3 ;
   tbw = 7 ;
        // Read timings -- 10ns address access time
   trc = 10 ;
   taa = 10 ;
   tace = 10 ;
   toe = 4 ;
   toh = 3 ;
   tclz = 3 ;
   tchz = 5 ;
   tolz = 0 ;
   tohz = 5 ;
   tba = 5 ;
   tblz = 0 ;
   tbhz = 5 ;
   tpu = 0 ;
   tpd = 10;
        // Internal Time signals  
    
    initiate_write1 = 1'b0;
    initiate_write2 = 1'b0;
    initiate_write3 = 1'b0;
    
    data_read = 16'hzz;
    initiate_read1 =1'b0;
    initiate_read2 =1'b0;
    read_address_time =0;
    
    read_address_add=0;
    read_address_oe=0;
    temptaa =  taa;
    temptoe =  toe;
    
    end
  
 
 
//********* start Accessing  by CE_n low*******

  always@(negedge CE_n)
    begin
     activate_cebar <= 1'b0;
     activate_wecebar<=1'b0;
     write_CE_n_start_time <= $time;
     read_CE_n_start_time <=$time;
     end
 
 //****  Write Access *************
 
 //****** CE_n controlled ***********
  always@(posedge CE_n)
    begin
      if (($time - write_CE_n_start_time) >= tcw)
      begin
            if ( (WE_n == 1'b0) && ( ($time - write_WE_n_start_time) >=twp1) )
            begin
              Address_write2 <= Address_write1;
                    dummy_array0[Address_write1] <= dataIO1[7:0];  
                  dummy_array1[Address_write1] <= dataIO1[15:8] ;  
                    activate_cebar <= 1'b1;
            end
            else
               activate_cebar <= 1'b0;
      end            
      else
      begin
           activate_cebar <= 1'b0;
      end
    end
    
  
 //***** UB_n/LB_n change  *********
 
    always @(negedge UB_n)
       begin
         UB_n_start_time <= $time;
       end
   
    always @(negedge LB_n)
      begin
         LB_n_start_time <= $time;
       end    

//***** WE_n controlled  **********    
          
   always @(negedge WE_n)
     begin
      activate_webar <= 1'b0;
      activate_wecebar<=1'b0;
      write_WE_n_start_time <= $time;
      #twz WE_dly <= WE_n;
     end  
     
  always @(posedge WE_n  )
    begin
      WE_dly <= WE_n;
      read_WE_n_start_time <=$time;
      if (($time - write_WE_n_start_time) >=twp1)
      begin
            if ( (CE_n == 1'b0) && ( ($time - write_CE_n_start_time) >= tcw) )
            begin
          Address_write2 <= Address_write1;  
          dummy_array0[Address_write1] <= dataIO1[7:0]; 
                dummy_array1[Address_write1] <= dataIO1[15:8] ;
                activate_webar <= 1'b1;
            end 
            else 
                  activate_webar <= 1'b0;
      end       
      else
      begin
            activate_webar <= 1'b0;
      end 
   end       
 
 //******* WE_n & CE_n controlled ( If both comes to high at the same time)**********
 always @(CE_n && WE_n)
   begin
     if ( (CE_n ==1'b1) && (WE_n ==1'b1) )
     begin 
           if ( ( ($time - write_WE_n_start_time) >=twp1) && (($time-write_CE_n_start_time) >=tcw))
     begin
          Address_write2 <= Address_write1;  
          dummy_array0[Address_write1] <= dataIO1[7:0]; 
                dummy_array1[Address_write1] <= dataIO1[15:8] ;
                activate_webar <= 1'b1;
            end 
           else
               activate_wecebar <= 1'b0 ;    
           end 
     else
           activate_wecebar <=1'b0;
  end   
  

  
  always@(CE_n or WE_n or OE_n or Address or DataIO )
    begin
      if ((CE_n==1'b0) && (WE_n ==1'b0))
     begin
            Address_write1 <= Address;
                Address_write2 <= Address_write1;
              dataIO1  <= DataIO;  
        dummy_array0[Address_write1] <=  dataIO1[7:0] ;
              dummy_array1[Address_write1] <=  dataIO1[15:8] ;
          end
    end
 
 
 //********* DATAIO changes before write completion, then New write(2) initation **************
 
 always @(DataIO)
   begin
     write_data_time <= $time;
     write_data1_time <=write_data_time;
     write_WE_n_start_time1 <=$time;
     write_CE_n_start_time1 <=$time;
     if ( ($time - write_data_time) >= tdw)
     begin
         if ( (WE_n == 1'b0) && (CE_n == 1'b0))
         begin
             if ( ( ($time - write_CE_n_start_time) >=tcw) && ( ($time - write_WE_n_start_time) >=twp1) && (($time - write_address_time) >=twc) )
                initiate_write2 <= 1'b1;
             else
                initiate_write2 <= 1'b0;
         end
    end
end
 
 
 //******* Address changes before write completion, then New write(3) initation*************************
 
 
 always @(Address)
   begin
     write_address_time <= $time;
     write_address1_time <= write_address_time;
     write_WE_n_start_time1 <=$time;
     write_CE_n_start_time1 <=$time;
     if ( ($time - write_address_time) >= twc)
     begin
         if ( (WE_n == 1'b0) &&  (CE_n ==1'b0))
         begin
             if ( ( ($time - write_CE_n_start_time) >=tcw) && ( ($time - write_WE_n_start_time) >=twp1) && (($time - write_data_time) >=tdw) )
                initiate_write3 <= 1'b1;
             else
                initiate_write3 <= 1'b0;
         end
         else
            initiate_write3 <= 1'b0;
     end
     else
        initiate_write3 <= 1'b0;
end


//******* activate_cebar or activate_webar or ini_weceba goes high - initiate write access **************
 
always@(activate_cebar or activate_webar or activate_wecebar) 
  begin
     if ( (activate_cebar == 1'b1) || (activate_webar == 1'b1) || (activate_wecebar == 1'b1) ) 
     begin
         if ( ( ($time - write_data1_time) >= tdw) && ( ($time - write_address1_time) >= twc) )
            initiate_write1 <= 1'b1;
         else
            initiate_write1 <= 1'b0;
     end
     else
       initiate_write1 <= 1'b0;
end 
 


//***** Write completion (Writing into mem_arrayx[][]) ***********

always@( initiate_write1 )   
  begin
   if ( ( ($time - write_WE_n_start_time) >=twp1) && ( ($time - write_CE_n_start_time) >=tcw) )   
      begin
    if(UB_n == 1'b0 && (($time - UB_n_start_time) >= tbw))
    begin
                  mem_array1[Address_write2] <= dummy_array1[Address_write2];
        end
    if (LB_n == 1'b0 && (($time - LB_n_start_time) >= tbw))
    begin
      mem_array0[Address_write2] <= dummy_array0[Address_write2];
    end   
      end 
      initiate_write1 <=1'b0;
end

always @(initiate_write2 )  
begin
       if ( ( ($time - write_WE_n_start_time) >=twp1) && ( ($time - write_CE_n_start_time) >=tcw))
       begin
    if(UB_n == 1'b0 && (($time - UB_n_start_time) >= tbw))
    begin
                  mem_array1[Address_write2] <= dummy_array1[Address_write2];
        end
    if (LB_n == 1'b0 && (($time - LB_n_start_time) >= tbw))
    begin
      mem_array0[Address_write2] <= dummy_array0[Address_write2];
    end   
      end

    if ( (initiate_write2==1'b1)) 
       begin  
    initiate_write2 <=1'b0;
   end
end

always @(initiate_write3 )  
begin
       if ( ( ($time - write_WE_n_start_time) >=twp1) && ( ($time - write_CE_n_start_time) >=tcw))
       begin
    if(UB_n == 1'b0 && (($time - UB_n_start_time) >= tbw))
    begin
                  mem_array1[Address_write2] <= dummy_array1[Address_write2];
        end
    if (LB_n == 1'b0 && (($time - LB_n_start_time) >= tbw))
    begin
      mem_array0[Address_write2] <= dummy_array0[Address_write2];
    end   
      end
      
   if ( (initiate_write3==1'b1)) 
       begin  
    initiate_write3 <=1'b0;
   end
end

//****** Read Access  ********************

//******** Address transition initiates the Read access ********
 always@(Address)      // Address change exactly =trc 
   begin 
     read_address_time <=$time;
     Address_read1 <=Address;
     Address_read2 <=Address_read1;
     if ( ($time - read_address_time) == trc) 
     begin
         if ( (CE_n == 1'b0) && (WE_n == 1'b1) )
      initiate_read1 <= 1'b1;
         else
            initiate_read1 <= 1'b0;
     end  
     else
       initiate_read1 <= 1'b0;
end

//***** Address valid long time(>=trc)*************

always #1
  begin 
     if ( ($time - read_address_time) >= trc)
     begin
     
         if ( (CE_n == 1'b0) && (WE_n == 1'b1) )
         begin
             Address_read2 <=Address_read1;
       initiate_read2 <= 1'b1;
         end
         else
             initiate_read2 <= 1'b0;
     end
     else
       initiate_read2 <= 1'b0;
end

 //********** Register time when OE_n goes low ******

always @(negedge OE_n)
  begin
    read_OE_n_start_time <= $time;
    data_read <= 16'bz;
  end

//***** Data drive to data_read when $time >= taa & tace & trc (all are having same times) ******
 
always@(initiate_read1 or initiate_read2)
  begin
     if ( (initiate_read1 == 1'b1) || (initiate_read2 == 1'b1) )
     begin
         if ( (CE_n == 1'b0) && (WE_n ==1'b1))
         begin
             if ( ( ($time - read_WE_n_start_time) >=trc) && ( ($time -read_CE_n_start_time) >=tace) && ( ($time - read_OE_n_start_time) >=toe))
             begin
      if((LB_n == 1'b0) && (($time - LB_n_start_time) >= tba))              
      data_read[7:0] <= mem_array0[Address_read2];
      else
          data_read[7:0] <= 8'bzz;
      if((UB_n == 1'b0) && ( ($time - UB_n_start_time) >= tba)) 
                data_read[15:8] <= mem_array1[Address_read2];
          else
                  data_read[15:8] <= 8'bzz;
             end
         end
         else
             #toh data_read <=16'hzzzz;
      end
      initiate_read1 <=1'b0;
      initiate_read2 <=1'b0;
end
  


 //********** Driving DataIO during OE_n low *********
 
  wire [15:0] DataIO =  (!OE_n && WE_dly) ?  data_read[15:0] : 16'bz ;
 
 
 //******* simultion Finish by `tsim ***********
//initial # `tsim $finish;
 
    
  
  endmodule  
    
