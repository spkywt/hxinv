require('common')

local defaults = T{
   Window_Flags            =  bit.bor(ImGuiWindowFlags_NoDecoration);
   Window_Flags_Menu       =  bit.bor(ImGuiWindowFlags_NoTitleBar,
                                      ImGuiWindowFlags_NoResize,
                                      ImGuiWindowFlags_NoFocusOnAppearing,
                                      ImGuiWindowFlags_NoMove,
                                      ImGuiWindowFlags_NoBringToFrontOnFocus,
                                      ImGuiWindowFlags_NoScrollbar,
                                      ImGuiWindowFlags_NoScrollWithMouse,
                                      ImGuiWindowFlags_NoSavedSettings);
   options                 =  T{
      showGil              =  true;
      showInv              =  true;
   };
   unlockedItems           = T{};
   -- Container display order, must add show and filter "variable" entry for each container
   containerOrder          =  {0, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 1, 9, 2, 4, 3};
   windows                 =  {
      showMenu             =  true,
      showMenu_Gil         =  true,
      showMenu_Inv         =  true,
      showContainer0       =  { false },
      showContainer5       =  { false },
      showContainer6       =  { false },
      showContainer8       =  { false },
      showContainer10      =  { false },
      showContainer11      =  { false },
      showContainer12      =  { false },
      showContainer13      =  { false },
      showContainer14      =  { false },
      showContainer15      =  { false },
      showContainer16      =  { false },
      showContainer1       =  { false },
      showContainer9       =  { false },
      showContainer2       =  { false },
      showContainer4       =  { false },
      showContainer7       =  { false },
      showContainer3       =  { false },
      filterContainer0     =  { 0 },
      filterContainer5     =  { 0 },
      filterContainer6     =  { 0 },
      filterContainer8     =  { 0 },
      filterContainer10    =  { 0 },
      filterContainer11    =  { 0 },
      filterContainer12    =  { 0 },
      filterContainer13    =  { 0 },
      filterContainer14    =  { 0 },
      filterContainer15    =  { 0 },
      filterContainer16    =  { 0 },
      filterContainer1     =  { 0 },
      filterContainer9     =  { 0 },
      filterContainer2     =  { 0 },
      filterContainer4     =  { 0 },
      filterContainer7     =  { 0 },
      filterContainer3     =  { 0 }
   }
};

return defaults;