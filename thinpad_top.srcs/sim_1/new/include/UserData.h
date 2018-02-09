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

// ************************************ 
//
// User Data definition file :
//
//      here are defined all parameters
//      that the user can change
//
// ************************************ 
  
//`define x128P30T // Select the device. Possible value are: x128P30B, x128P30T
`define x64P30T                 //                                        x64P30B, x64P30T  
 

//!`define organization "top"        // top or bottom
`define BLOCKPROTECT "on"         // if on the blocks are locked at power-up
`define TimingChecks "on"         // on for checking timing constraints
`define t_access      65          // Access Time 65 ns, 75 ns 
`define FILENAME_mem "flash_content.mem" // Memory File Name 




`ifdef  x128P30B 
`define organization "bottom"
`elsif  x128P30T
`define organization "top"        // top, bottom 
`elsif  x64P30B
`define organization "bottom"
`elsif  x64P30T
`define organization "top"
`else
`define organization "bottom"
`endif


