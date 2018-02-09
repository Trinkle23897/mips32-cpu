//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                                 28F640P30 / 
//      _/_/_/_/_/       _/_/_/           /                                           /  
//      _/_/_/_/_/_/     _/_/_/          /                                   128Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                       Single bit per Cell / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              

// ****************************************************
//
// Block Library :
//
//      define the architecture of the blocks and banks
//
// ****************************************************

  `include "def.h"
  `include "data.h"
  `include "UserData.h"



`ifdef x128P30B
  `define BLOCK_dim              131
`elsif x128P30T
   `define BLOCK_dim             131
`elsif x64P30B
   `define BLOCK_dim             67
`elsif x64P30T
   `define BLOCK_dim             67 
`endif 





//!  `define BLOCK_dim              131
  `define BLOCKDIM_range        0 : `BLOCK_dim - 1
  `define BLOCKADDR_dim         16 
  `define BLOCKADDR_range       `BLOCKADDR_dim - 1 : 0

// *********
//
//  Parameter Block & Main Block

//
// *********

  `define ParameterBlock_num      4
  `define ParameterBlock_size     16 // Size of Parameter Block (Kword)

  `ifdef x128P30B

  `define MainBlock_num           127

  `elsif x128P30T

  `define MainBlock_num           127

  `elsif x64P30B

  `define MainBlock_num           63

 `elsif x64P30T

  `define MainBlock_num           63

  `endif
  
  
  `define MainBlock_size          64 // Size of Main Block (Kword)



module BankLib;

integer BlockBoundaryStartAddr [`BLOCK_dim - 1 : 0];        // Block Boundary Start Address
integer BlockBoundaryEndAddr   [`BLOCK_dim - 1 : 0];        // Block Boundary End   Address
  
integer count;

initial
  begin

        begin: block_building
                for (count = 0; count <= `BLOCK_dim - 1; count = count + 1) 
                        BuildBlockBoundary(`organization, count, BlockBoundaryStartAddr[count], BlockBoundaryEndAddr[count]); 

        end

   end
    

// ******************************************************************
// 
// TASK BuildBlockBoundary: Build the Blocks Boundaries in two arrays
//
// ******************************************************************

  task BuildBlockBoundary;
        
        input   organize;
        input   n_block;
        output  StartAddr;
        output  EndAddr;

        reg [8*6:1]  organize;
        integer      n_block;
        integer      StartAddr;
        integer      EndAddr;

  begin
        
        if (organize == "top") begin 
  
                    if (n_block == 0) EndAddr = - 1;
               
                    if (n_block > `MainBlock_num  - 1 && n_block <= `MainBlock_num + `ParameterBlock_num - 1) // parameter block
                        begin
                             StartAddr = EndAddr + 1;
                            EndAddr   = StartAddr +  `ParameterBlock_size  * `Kword - 1;
    
                        end     
     
                    else   // Main block
                         begin
                             StartAddr = EndAddr + 1;   
                             EndAddr   = StartAddr + `MainBlock_size * `Kword - 1;
                         end

        end else  begin // organize = "bottom"
 
                    if (n_block == 0) EndAddr = - 1;   
              
                    if (n_block > `ParameterBlock_num - 1)     
                        begin
                          StartAddr = (`ParameterBlock_num * `ParameterBlock_size * `Kword ) + 
                                  (n_block - `ParameterBlock_num) * `MainBlock_size * `Kword;
                          EndAddr   = StartAddr +  `MainBlock_size * `Kword - 1;
                        end
//!
                    else  //   parameter block
                       begin
                           StartAddr = EndAddr + 1;   
                           EndAddr   = StartAddr + `ParameterBlock_size * `Kword - 1;
                       end

       end 

  end
  endtask      



  // *********************************************
  //        module work.MemoryModule:module (updated)
  // FUNCTION getBlock : return block from address
  //
  // *********************************************

  function [`INTEGER] getBlock;                     // BLOCK_dim in binary is 9 bit size 

  input   address;

  reg [`ADDRBUS_dim - 1 : 0] address;
  reg found;
  integer count;

  begin

     count = 0;
     found = 0;
     while ((count <= `BLOCK_dim) && (! found)) 
        begin

           if ((BlockBoundaryStartAddr[count] <= address) && (address <= BlockBoundaryEndAddr[count])) found= 1;
           else count = count + 1;

        end
      
     if (!found) $display("%t !Error in Block Library : specified block address is out of range",$time); 
     
     getBlock= count;
  
  end
  endfunction


  // ***************************
  //
  // FUNCTION getBlockAddress :
  //    return the block address
  //
  // ***************************

  function [`ADDRBUS_dim - 1 : 0] getBlockAddress;

  input block;

  integer block;

  begin

        getBlockAddress = BlockBoundaryStartAddr[block];        

  end
  endfunction


  // *********************************************
  //
  // FUNCTION isParameterBlock : 
  //    return true if the address 
  //    is in a parameter block
  //
  // *********************************************

  function isParameterBlock;                   

  input   address;
  

  reg [`ADDRBUS_dim - 1 : 0] address;
  reg prm;
  integer count;

  begin

        prm = `FALSE;
         if (`organization=="bottom") begin

                for (count = 0; count <= `ParameterBlock_num - 1; count = count + 1) begin: cycle

                if ((BlockBoundaryStartAddr[count] <= address) && (address <= BlockBoundaryEndAddr[count])) 
                                begin 
                                        prm= `TRUE;
                                        disable cycle;
                                 end  
                end                 
         end else begin 
               for (count = `BLOCK_dim - `ParameterBlock_num + 1; count <= `BLOCK_dim - 1; count = count + 1) begin: cycle1
 

                        if ((BlockBoundaryStartAddr[count] <= address) && (address <= BlockBoundaryEndAddr[count])) 
                                begin 
                                        prm= `TRUE;
                                        disable cycle1;
                                 end        
              end
         end
     
        isParameterBlock = prm; 
        
  end
  endfunction


  // *********************************************
  //
  // FUNCTION isMainBlock : 
  //    return true if the address is in a main block
  //
  // *********************************************

  function isMainBlock;                   

  input   address;

  reg [`ADDRBUS_dim - 1 : 0] address;
  reg main;
  integer count;

  begin

        main = `FALSE;

        if (`organization=="bottom") begin
                for (count = `BLOCK_dim - 1; count >= `BLOCK_dim - `ParameterBlock_num + 1; count = count - 1) begin: cycle2

                if ((BlockBoundaryStartAddr[count] <= address) && (address <= BlockBoundaryEndAddr[count])) 
                                begin 
                                        main = `TRUE;
                                        disable cycle2;
                                end   
                                
                end
         end else begin
               for (count = 0; count <= `MainBlock_num - 1; count = count + 1) begin: cycle3


                        if ((BlockBoundaryStartAddr[count] <= address) && (address <= BlockBoundaryEndAddr[count])) 
                                begin 
                                        main = `TRUE;
                                        disable cycle3;
                                end 
               end                  
         end
        isMainBlock = main;     
  end
  endfunction


endmodule
