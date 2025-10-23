--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

addon.author            =  'Espe (spkywt)';
addon.name              =  'hxinv';
addon.desc              =  'FFXI Inventory Manager.';
addon.version           =  '0.1.0';

-- Ashita Libs
require 'common'
local ffi               =  require('ffi');
local d3d               =  require('d3d8');
local imgui             =  require('imgui');
local settings          =  require('settings');
local d3d8dev           =  d3d.get_device();

-- Addon Custom Files
require 'constants'
require 'helpers'
require 'packets'
local item_sort         = require('item_sort')

-- Addon Settings
local config;
local defaults                         =  require('defaults');
local itemTextures                     =  T{};
local itemTexturesPtr                  =  T{};
local BMWidth_Gil                      =  0;
local BMWidth_Storage                  =  0;
local popupItem                        =  {-1, -1, 0, 0};
local ZONE_FLAGS_POINTER               =  {};
local ZONE_FLAGS_OFFSET                =  {};
local ContainersInverted               =  T{};
local player                           =  AshitaCore:GetMemoryManager():GetPlayer();
local inventory                        =  AshitaCore:GetMemoryManager():GetInventory();


----------------------------------------------------------------------------------------------------
-- Get Textures for Images
----------------------------------------------------------------------------------------------------
local GetItemById = function(itemId)
    return AshitaCore:GetResourceManager():GetItemById(itemId);
end

local GetItemTexture = function(item)
   if not itemTextures:containskey(item.Id) then
      local texturePointer = ffi.new('IDirect3DTexture8*[1]');

      local hr = ffi.C.D3DXCreateTextureFromFileInMemory(d3d8dev, item.Bitmap, item.ImageSize, texturePointer);
      if hr ~= 0 then return nil; end

      itemTextures[item.Id] = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePointer[0]));
   end
   
   return tonumber(ffi.cast("uintptr_t", itemTextures[item.Id]));
end

function LoadTextureFromFile(textureName)
   local textures = T{};
   local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
   local res = ffi.C.D3DXCreateTextureFromFileA(d3d8dev, string.format('%s/images/%s.png', addon.path, textureName), texture_ptr);
   if (res ~= ffi.C.S_OK) then
      return nil, nil;
   end;
   local raw = ffi.cast('IDirect3DTexture8*', texture_ptr[0]);
   textures.image = d3d.gc_safe_release(raw);
   
	return tonumber(ffi.cast("uintptr_t", raw)), textures.image;
end

----------------------------------------------------------------------------------------------------
-- Create Textures from Images
----------------------------------------------------------------------------------------------------
local imgGilIcon, texGilIcon = LoadTextureFromFile('65535');
local imgInvIcon, texInvIcon = LoadTextureFromFile('sack');
local imgLckIcon, texLckIcon = LoadTextureFromFile('locked');
local imgDrpIcon, texDrpIcon = LoadTextureFromFile('x');

----------------------------------------------------------------------------------------------------
-- func: isMogHouse
-- desc: Return container names with proper spacing.
----------------------------------------------------------------------------------------------------
local function isMogHouse()
   local zoneflagspointer = ashita.memory.read_uint32(ZONE_FLAGS_POINTER);
   local zoneflags = ashita.memory.read_uint32(zoneflagspointer + ZONE_FLAGS_OFFSET);
   if (bit.band(zoneflags, 0x100) == 0x100) then
      return true;
   else return false;
   end
end

----------------------------------------------------------------------------------------------------
-- func: GetContainerName
-- desc: Return container names with proper spacing.
----------------------------------------------------------------------------------------------------
function GetContainerName(cID)
   return Containers[cID] or '';
end

----------------------------------------------------------------------------------------------------
-- func: GetContainerSize
-- desc: Return count of items in container as well as table of item types.
----------------------------------------------------------------------------------------------------
local function GetContainerSize(cID)
   local pRace = GetPlayerEntity().Race;
   local size = 0;
   local types = {};
   
   for i = 0, inventory:GetContainerCountMax(cID), 1 do
      local item = inventory:GetContainerItem(cID, i);
      if (item.Id ~= 0 and item.Id ~= 65535) then
         local ires = AshitaCore:GetResourceManager():GetItemById(item.Id);
         if ires then
            if (not types[ires.Type]) then
               types[(ires.Type == 3 and pRace == 7) and 7 or ires.Type] = true;
            end
         end
      end
   end
   return inventory:GetContainerCount(cID), types;
end

----------------------------------------------------------------------------------------------------
-- func: UpdateContainerInfo
-- desc: Update config table with current container info.
----------------------------------------------------------------------------------------------------
local ContainerInfo = {};
local function SetContainerInfo()
   if (table.getn(ContainerInfo) == 0) then
      for i = 1, table.getn(config.containerOrder), 1 do
         local cID = config.containerOrder[i];
         ContainerInfo[cID] = {};
         ContainerInfo[cID].name = GetContainerName(cID);
         if (inventory:GetContainerCountMax(cID) == 0) then
            ContainerInfo[cID].max = 0;
         else
            ContainerInfo[cID].max = inventory:GetContainerCountMax(cID);
         end
         local types = {};
         ContainerInfo[cID].size, types = GetContainerSize(cID);
         ContainerInfo[cID].types = {};
         for k,v in pairs(ItemType) do 
         if (types[v]) then ContainerInfo[cID].types[k] = v; end end
         ContainerInfo.Gil = inventory:GetContainerItem(0,0).Count;
      end
   else
      for i = 1, table.getn(config.containerOrder), 1 do
         local cID = config.containerOrder[i];
         if (inventory:GetContainerCountMax(cID) ~= 0) then
            ContainerInfo[cID].max = inventory:GetContainerCountMax(cID);
         end
         local types = {};
         ContainerInfo[cID].size, types = GetContainerSize(cID);
         ContainerInfo[cID].types = {};
         for k,v in pairs(ItemType) do if (types[v]) then ContainerInfo[cID].types[k] = v; end end
         ContainerInfo.Gil = inventory:GetContainerItem(0,0).Count;
      end
   end
end

----------------------------------------------------------------------------------------------------
-- func: StorageCurrentAndMax
-- desc: Return formatted string of used and max storage for a container.
----------------------------------------------------------------------------------------------------
local function StorageCurrentAndMax(cID)
   if (ContainerInfo[cID].max == 0) then
      return '--/--';
   else
      return string.format("%5s", ContainerInfo[cID].size .. '/' .. ContainerInfo[cID].max);
   end
end

----------------------------------------------------------------------------------------------------
-- func: ShowItemToolTip
-- desc: Shows a tooltip with ImGui.
----------------------------------------------------------------------------------------------------
local function ShowItemToolTip(item, r, g, b, a)
   if (r == nil or g == nil or b == nil or a == nil) then
      r = 1;   g = 1;   b = 1;   a = 1;
   end
   
   if (imgui.IsItemHovered()) then
      imgui.SetNextWindowContentSize({350, 0});
      imgui.BeginTooltip();
         local image_size = 64;
         imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, {2, 2});
         imgui.BeginChild('item-tt-icon', {image_size + 4, image_size + 4}, true);
            imgui.Image(itemTexturesPtr[item.id], {image_size, image_size});
         imgui.EndChild();
         imgui.PopStyleVar();
         imgui.SameLine();
         imgui.BeginGroup();
            -- Item Name
            --imgui.Text(item.type);
            imgui.TextColored({r, g, b, a}, item.name);
            if (bit.band(item.flags2, ItemFlags.Rare) ~= 0) then
               imgui.SameLine(imgui.GetWindowWidth() - 140);
               imgui.TextColored({1.0, 1.0, 0.57, 1.0}, '(R)');
            end
            if (bit.band(item.flags2, ItemFlags.Ex) ~= 0) then
               imgui.SameLine(imgui.GetWindowWidth() - 115);
               imgui.TextColored({0.55, 1.0, 0.58, 1.0}, '(E)');
            end
            imgui.Separator();
            
            --imgui.Text('Index: ' .. item.index);
            --imgui.Text('Flags: ' .. item.flags);
            --imgui.Text('Flags: ' .. item.flags2);
            --imgui.Text('Price: ' .. item.price);
            --imgui.Text('ResId: ' .. item.resid);
            --imgui.Text('Targs: ' .. item.targs);
            --imgui.Text('Extra: ' .. table.getn(item.extra));
            --for k,v in pairs (item.extra) do imgui.Text(k .. ' :: ' .. v); end
            
            -- Skill Type & Race
            if (item.skill > 0) then
               for k,v in pairs(SkillTypes) do
                  if (item.skill == v) then imgui.Text('(' .. k .. ')'); end
               end
            elseif (item.slots > 0) then
               for k,v in pairs(EquipmentSlotMask) do
                  if (item.slots == v) then imgui.Text('[' .. k .. ']'); end
               end
            end
            if (item.races == 0x01FE) then
               imgui.SameLine();
               imgui.Text('All Races');
            elseif (item.races == 0) then else
               if (bit.band(item.races, RaceMask.All) ~= item.races) then end
               for k,v in pairs(RaceMask) do
                  if (bit.bor(item.races, v) == item.races and v > 0) then
                     imgui.SameLine();
                     imgui.Text(k);
                  end
               end
            end
            
            -- Description
            if (item.desc[1]) then imgui.Text(item.desc[1]); end
            --ashita.misc.set_clipboard(item.desc[0]);
               --dark = ï&
            
            -- Level & Jobs
            if (item.skill ~= 48) then -- ignore fishing tackle
               if (item.level > 0) then
                  imgui.Text('Lv.' .. item.level .. ' ');
               end
               if (item.jobs == 0x007FFFFE) then
                  imgui.SameLine(0,0);
                  imgui.Text('All Jobs');
               elseif (item.jobs > 0) then
                  local jobCount = 0;
                  local jobPerRow = 7;
                  
                  local OrderedJobs = {};
                  for k,v in pairs(JobMask) do
                      if (v > 0) then
                          table.insert(OrderedJobs, { name = k, mask = v });
                      end
                  end
                  table.sort(OrderedJobs, function(a,b) return a.mask < b.mask end);
                  
                  for _,job in ipairs(OrderedJobs) do
                     if (bit.band(item.jobs, job.mask) ~= 0) then
                        if (jobCount > 0) then
                           imgui.SameLine(0,0);
                           imgui.Text('/');
                        end
                        if (jobCount == 0 or jobCount % jobPerRow ~= 0) then
                           imgui.SameLine(0,0);
                        end
                        imgui.Text(job.name);
                        if (jobPerRow == 7 and jobCount > 7) then jobPerRow = 8; end
                        jobCount = jobCount + 1;
                     end
                  end
               end
            end
            
         imgui.EndGroup();
      imgui.EndTooltip();
   end
end

----------------------------------------------------------------------------------------------------
-- func: ShowItemMenu
-- desc: Display context menu when right clicking on inventory item.
----------------------------------------------------------------------------------------------------
local function ShowItemMenu(cID, item)
   if (popupItem[1] == cID and popupItem[2] == item.index) then
      imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, {7, 7});
      imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, {7, 7});
      imgui.PushStyleColor(ImGuiCol_PopupBg, {0.15, 0.15, 0.15, 1});
      imgui.PushStyleColor(ImGuiCol_Border, {0.25, 0.25, 0.25, 1});
      imgui.SetNextWindowPos({popupItem[3], popupItem[4]});
      if (imgui.BeginPopup('ItemMenu')) then
         local atleastone = false;
         local wearable = false;
         if (item.type == 4 or item.type == 5) then wearable = true; end
         
         imgui.TextColored({1.0, 1.0, 0.57, 1.0}, item.name);
         imgui.Separator();
         if (imgui.BeginMenu('MoveItem', item.flags ~= 5)) then
            if (ContainerInfo[0].size == ContainerInfo[0].max and cID ~= 0) then
               imgui.MenuItem('Must have 1 space in inventory.',  nil, false, false);
            else
               for i = 1, table.getn(config.containerOrder), 1 do
                  local cli = config.containerOrder[i];
                  local notSame = cli ~= cID;
                  local notTemp = cli ~= 3;
                  local notFull = ContainerInfo[cli].size < ContainerInfo[cli].max;
                  local mhCheck = isMogHouse() or (not isMogHouse() and
                                  cli ~= 1 and cli ~= 9 and cli ~= 2 and cli ~= 4);
                  local wdCheck = ((item.type == 4 or item.type == 5) and
                                  (cli >= 8 and cli ~= 9 and cli <= 16)) or
                                  (cli <= 9 and cli ~= 8);
                  if (notSame and notTemp and notFull and mhCheck and wdCheck) then
                     if (imgui.MenuItem(ContainerInfo[cli].name,  nil, false, true)) then
                        if (cID == 0 or cli == 0) then
                           moveItem(item.index, item.count, cID, cli);
                        else
                           moveItem(item.index, item.count, cID, 0);
                           local getNewIndex = 0;
                           for i = 0, ContainerInfo[0].max, 1 do
                              local gi = inventory:GetContainerItem(0, i);
                              if (item.id == gi.Id and item.count == gi.Count) then
                                 getNewIndex = gi.Index;
                              end
                           end
                           moveItem(getNewIndex, item.count, 0, cli);
                        end
                     end
                     atleastone = true;
                  end
               end
               if not atleastone then
                  imgui.MenuItem('No Valid Options',  nil, false, false)
               end
            end
            imgui.EndMenu();
         end
         --[[
         local tradable = true;
         if (item.flags == 5) then tradable = false; end
         --if (bit.bor(item.flags2, ItemFlags.Exclusive) == item.flags2) then tradable = false; end
         if (imgui.MenuItem('Trade', nil, false, tradable)) then
            AshitaCore:GetChatManager():QueueCommand(string.format('/item "%s" <t>', item.name), 1); end
         ]]--
         if (config.unlockedItems[item.id]) then
            if (imgui.MenuItem('Disable Drop', nil, false, true)) then
               config.unlockedItems[item.id] = nil;
               settings.save();
            end
         else
            if (imgui.MenuItem('Enable Drop', nil, false, item.flags ~= 5)) then
               config.unlockedItems[item.id] = true;
               settings.save();
            end
         end
         imgui.EndPopup();
      else
         popupItem = {-1, -1};
      end
      imgui.PopStyleColor(2);
      imgui.PopStyleVar();
      imgui.PopStyleVar();
   end
   
   if imgui.IsWindowHovered(
           bit.bor(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem,
                   ImGuiHoveredFlags_AllowWhenBlockedByPopup))
      and imgui.IsMouseClicked(ImGuiMouseButton_Right) then
      imgui.SetWindowFocus();
   end
   local mhCheck2 = isMogHouse() or (not isMogHouse() and cID ~= 1 and cID ~= 9 and cID ~= 2 and cID ~= 4);
   if (imgui.IsItemClicked(1) and mhCheck2) then
      popupItem = {cID, item.index};
      imgui.OpenPopup('ItemMenu');
      popupItem[3], popupItem[4] = imgui.GetMousePos();
   end
end

----------------------------------------------------------------------------------------------------
-- func: ContainerButton
-- desc: Create button for containers.
----------------------------------------------------------------------------------------------------
local function ContainerButton(cID, cLabel, cVar)
   if (inventory:GetContainerCountMax(cID) > 0) then
      if (ContainerInfo[cID].size == 0) then
      else
         if (cID ~= 0) then
            imgui.SameLine();
            imgui.TextColored({1, 1, 1, 0.25},'::');
         end
         imgui.SameLine();
         imgui.PushStyleColor(ImGuiCol_Button, {0, 0, 0, 0});
         imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.0, 0.6, 0.9, 0.6});
         imgui.PushStyleColor(ImGuiCol_ButtonActive, {1.0, 1.0, 1.0, 0.3});
         if (ContainerInfo[cID].size / ContainerInfo[cID].max == 1) then
            imgui.PushStyleColor(ImGuiCol_Text, {1, 0, 0, 1});
         elseif (ContainerInfo[cID].size / ContainerInfo[cID].max >= 0.8) then
            imgui.PushStyleColor(ImGuiCol_Text, {1, 1, 0, 1});
         else
            imgui.PushStyleColor(ImGuiCol_Text, {1, 1, 1, 1});
         end
         if (imgui.SmallButton(string.format('%-12s', cLabel) .. StorageCurrentAndMax(cID))) then
            config.windows[cVar][1] = not config.windows[cVar][1];
         end
         imgui.PopStyleColor(4);
      end
   end
end

----------------------------------------------------------------------------------------------------
-- func: ShowBottomBar
-- desc: Shows storage summary window.
----------------------------------------------------------------------------------------------------
local function showMenu()
   local xChest = 0;
   local xGil = 0;
                     
   -- Initialize the window draw.
   imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, {0, 2});
   imgui.PushStyleColor(ImGuiCol_WindowBg, {0.15, 0.15, 0.15, 0.85});
   imgui.SetNextWindowSize({imgui.GetIO().DisplaySize.x, 20}, ImGuiSetCond_Always);
   imgui.SetNextWindowPos({0, imgui.GetIO().DisplaySize.y - 17});
   if (imgui.Begin('BottomBar', config.windows.showMenu, config.Window_Flags_Menu)) then
      -- Spacing
      if (BMWidth_Gil ~= 0 and BMWidth_Storage ~= 0) then
         imgui.SameLine((imgui.GetWindowWidth() - BMWidth_Storage) / 2);
      elseif (BMWidth_Gil ~= 0 or BMWidth_Storage ~= 0) then
         imgui.SameLine((imgui.GetWindowWidth() - BMWidth_Storage - BMWidth_Gil) / 2);
      end
      -- Gil
      if (config.windows.showMenu_Gil) then
         xGil = imgui.GetCursorPosX();
         imgui.Text('     ');
         imgui.SameLine();
         imgui.Text(comma_value(ContainerInfo.Gil) ..  '    ');
         imgui.SameLine();
         if (BMWidth_Gil == 0) then BMWidth_Gil, _ = imgui.GetCursorScreenPos(); end
      end
      -- Storage
      if (config.windows.showMenu_Inv) then
         xChest = imgui.GetCursorPosX();
         imgui.Text('    ');
         imgui.PushStyleColor(ImGuiCol_Button, {1, 1, 1, 0.4});
         imgui.PushStyleColor(ImGuiCol_Border, {1, 1, 1, 0});
         for i = 1, table.getn(config.containerOrder), 1 do
            local cid = config.containerOrder[i];
            ContainerButton(cid, GetContainerName(cid),  'showContainer' .. cid);
         end
         imgui.PopStyleColor(2);
         imgui.SameLine();
         if (BMWidth_Storage == 0) then BMWidth_Storage, _ = imgui.GetCursorScreenPos(); end
      end
    end
   imgui.End();
   imgui.PopStyleColor(1);
   imgui.PopStyleVar();
   
   local Window_Flags = bit.bor(ImGuiWindowFlags_NoTitleBar,
                                ImGuiWindowFlags_NoResize,
                                ImGuiWindowFlags_NoMove,
                                ImGuiWindowFlags_NoScrollbar,
                                ImGuiWindowFlags_NoScrollWithMouse,
                                ImGuiWindowFlags_NoSavedSettings,
                                ImGuiWindowFlags_NoBackground);
   imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0);
   if (config.windows.showMenu_Inv) then
      if (BMWidth_Storage ~= 0) then
         imgui.SetNextWindowSize({60, 60}, ImGuiSetCond_Always);
         imgui.SetNextWindowPos({xChest - 2, imgui.GetIO().DisplaySize.y - 30});
         if (imgui.Begin('imgInvIcon', config.windows['showMenu_Inv'], Window_Flags)) then
            imgui.Image(imgInvIcon, {32, 32});
         end
         imgui.End();
      end
   end
   if (config.windows.showMenu_Gil) then
      if (BMWidth_Gil ~= 0) then
         imgui.SetNextWindowSize({60, 60}, ImGuiSetCond_Always);
         imgui.SetNextWindowPos({xGil - 2, imgui.GetIO().DisplaySize.y - 28});
         if (imgui.Begin('imgGilIcon', config.windows['showMenu_Gil'], Window_Flags)) then
            imgui.Image(imgGilIcon, {32, 32});
         end
         imgui.End();
      end
   end
   imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: ShowContainer
-- desc: Shows container contents window.
----------------------------------------------------------------------------------------------------
local function ShowContainer(cID, itemTypes)
   local cID = cID or 0;
   local Window_Flags = bit.bor(ImGuiWindowFlags_NoResize,
                                ImGuiWindowFlags_NoCollapse,
                                ImGuiWindowFlags_AlwaysUseWindowPadding,
                                ImGuiWindowFlags_AlwaysVerticalScrollbar);
   
   local pRace = GetPlayerEntity().Race;
   local myItemTypes   =   {};
   for k,v in pairs(ItemType) do
      if (ContainerInfo[cID].types[k]) then
         table.insert(myItemTypes, {k, v});
      end
   end
   table.sort(myItemTypes, function (a, b) return a[1] < b[1] end);
   
   local current_index = config.windows['filterContainer' .. cID] or { 0 };
   local filters = 'Show All\0';
   for i = 1, #myItemTypes do
      filters = filters .. myItemTypes[i][1] .. '\0';
   end;
   filters = filters .. '\0';
   
   -- Initialize the window draw.  
   imgui.SetNextWindowSize({250, 320}, ImGuiSetCond_Always);
   imgui.PushStyleColor(ImGuiCol_WindowBg, {0.1, 0.1, 0.1, 0.5});
   --imgui.GetStyle().DisplayWindowPadding = imgui.ImVec2(260, 330);
   local title = string.format("%-25s", GetContainerName(cID)) .. string.format("%6s", '[' .. ContainerInfo[cID].size .. '/' .. ContainerInfo[cID].max) .. ']###' .. ContainerInfo[cID].name;
   if (config.windows['showContainer' .. cID][1] and 
      imgui.Begin(title, config.windows['showContainer' .. cID], Window_Flags)) then
      --bool Combo(const char* label, int* current_item, const char* items_separated_by_zeros, int height_in_items = -1);
      imgui.PushItemWidth(imgui.GetWindowWidth() - 84);
      if (imgui.Combo('###FilterContainer' .. cID, current_index, filters, #filters)) then
         config.windows['filterContainer' .. cID] = current_index;
         settings.save();
      end
      imgui.PopItemWidth();
      imgui.SameLine();
      if (imgui.Button(' Sort ')) then
         --sortContainer(cID);
         echo('Sort feature disabled until future version.');
      end
      local items = {};
      for i = 0, ContainerInfo[cID].max, 1 do
         local item = inventory:GetContainerItem(cID, i);
         if (item.Id ~= 0 and item.Id ~= 65535) then
            local foo = {};
            local gibi = AshitaCore:GetResourceManager():GetItemById(item.Id);
            foo.id      = item.Id;
            foo.index   = item.Index;
            foo.name    = gibi.Name[1];
            foo.count   = item.Count;
            --foo.extra   = item.Extra;
            foo.flags   = item.Flags;
            --foo.price   = item.Price;
            foo.flags2  = gibi.Flags;
            foo.resid   = gibi.ResourceId;
            foo.slots   = gibi.Slots;
            foo.type    = (gibi.Type == 3 and pRace == 7) and 7 or gibi.Type;
            foo.desc    = gibi.Description;
            foo.races   = gibi.Races;
            foo.level   = gibi.Level;
            foo.jobs    = gibi.Jobs;
            foo.skill   = gibi.Skill;
            foo.stack   = gibi.StackSize;
            foo.targs   = gibi.Targets;
            table.insert(items, foo);
         end
      end
      item_sort.sort_items(items);
      
      local filterID = config.windows['filterContainer' .. cID][1];
      for i = 1, table.getn(items) do
         if (filterID == 0 or myItemTypes[filterID][2] == items[i].type) then
            imgui.BeginGroup();
            if (not itemTextures:containskey(items[i].id)) then
               local ires = GetItemById(items[i].id);
               itemTexturesPtr[items[i].id] = GetItemTexture(ires);
            end
            local image_size = 13;
            imgui.BeginChild('item-icon##' .. cID .. ':' .. items[i].index, {image_size, image_size}, false);
               if (itemTextures[items[i].id]) then
                  imgui.Image(itemTexturesPtr[items[i].id], {image_size, image_size});
               else
                  imgui.Dummy({image_size, image_size});
               end
            imgui.EndChild();
            imgui.SameLine();
            local strout = items[i].name
            if (items[i].stack > 1) then
               imgui.Text(string.format("%2d", items[i].count));
               imgui.SameLine();
            else
               imgui.Text('  ');
               imgui.SameLine();
            end
            if (items[i].type == 7) then
               imgui.TextColored({1.0, 1.0, 0.57, 1.0}, strout);
               ShowItemToolTip(items[i], 1.0, 1.0, 0.57, 1.0);
               if (cID ~= 1 and cID ~= 9) then
                  imgui.SameLine(imgui.GetWindowWidth() - 55);
                  imgui.PushStyleColor(ImGuiCol_Button, {0.8, 0.8, 0.4, 0.3});
                  imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.8, 0.8, 0.4, 0.5});
                  if (imgui.SmallButton('Use##' .. items[i].index)) then
                     if (items[i].targs == 1) then
                        AshitaCore:GetChatManager():QueueCommand(-1, string.format('/item "%s" <me>', strout));
                     elseif (items[i].targs > 1 and
                             AshitaCore:GetMemoryManager():GetTarget():GetTargetName() ~= '') then
                        AshitaCore:GetChatManager():QueueCommand(-1, string.format('/item "%s" <t>', strout));
                     end
                  end
                  imgui.PopStyleColor(2);
               else
                  imgui.SameLine(imgui.GetWindowWidth() - 10);
                  imgui.Text(' ');
               end
            elseif (items[i].type == 4 or items[i].type == 5) then
               local jobCanUse = bit.bor(items[i].jobs, math.pow(2, player:GetMainJob())) == items[i].jobs;
               local lvlCanUse = player:GetMainJobLevel() >= items[i].level;
               if (items[i].flags == 5) then
                  imgui.TextColored({0.55, 1.0, 0.58, 1.0}, strout);
                  ShowItemToolTip(items[i], 0.55, 1.0, 0.58, 1.0);
                  if (cID ~= 1 and cID ~= 9 and jobCanUse and lvlCanUse) then
                     imgui.SameLine(imgui.GetWindowWidth() - 55);
                     if (imgui.SmallButton('Rem##' .. items[i].index)) then
                        sendEquipItem(items[i].index, items[i].slots, cID, true);
                     end
                  else
                     imgui.SameLine(imgui.GetWindowWidth() - 10);
                     imgui.Text(' ');
                  end
               else
                  imgui.Text(strout);
                  ShowItemToolTip(items[i]);
                  
                  if (cID ~= 1 and cID ~= 9 and jobCanUse and lvlCanUse) then
                     imgui.SameLine(imgui.GetWindowWidth() - 55);
                     imgui.PushStyleColor(ImGuiCol_Button, {0.55, 1.0, 0.58, 0.33});
                     imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.55, 1.0, 0.58, 0.66});
                     if (imgui.SmallButton('Eqp##' .. items[i].index)) then
                        sendEquipItem(items[i].index, items[i].slots, cID);
                     end
                     imgui.PopStyleColor(2);
                  elseif (cID ~= 1 and cID ~= 9) then
                     imgui.SameLine(imgui.GetWindowWidth() - 55);
                     imgui.PushStyleColor(ImGuiCol_Button, {0.4, 0.4, 0.4, 0.5});
                     imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.4, 0.4, 0.4, 0.5});
                     imgui.PushStyleColor(ImGuiCol_ButtonActive, {0.4, 0.4, 0.4, 0.5});
                     imgui.PushStyleColor(ImGuiCol_Text, {0.7, 0.7, 0.7, 1});
                     imgui.SmallButton('Eqp##' .. items[i].index);
                     imgui.PopStyleColor(4);
                  else
                     imgui.SameLine(imgui.GetWindowWidth() - 10);
                     imgui.Text(' ');
                  end
               end
            else
               if (cID ~= 1 and cID ~= 9) then
                  imgui.Text(strout);
                  ShowItemToolTip(items[i]);
                  imgui.SameLine(imgui.GetWindowWidth() - 10);
                  imgui.Text(' ');
               else
                  imgui.Text(strout);
                  ShowItemToolTip(items[i]);
                  imgui.SameLine(imgui.GetWindowWidth() - 10);
                  imgui.Text(' ');
               end
            end
            if (cID ~= 1 and cID ~= 9) then
               if (config.unlockedItems[items[i].id]) then
                  imgui.SameLine(imgui.GetWindowWidth() - 78);
                  imgui.PushStyleColor(ImGuiCol_Button, {1, 0.3, 0.2, 0});
                  imgui.PushStyleColor(ImGuiCol_ButtonHovered, {1, 0.3, 0.2, 0.25});
                  imgui.PushID('Drop' .. items[i].index .. ':' .. cID);
                  if (imgui.ImageButton(imgDrpIcon, {13, 13}, {0, 0}, {1, 1}, 0)) then
                     dropItem(items[i].index, items[i].count, cID);
                  end
                  imgui.PopID();
                  imgui.PopStyleColor(2);
                  imgui.EndGroup();
                  ShowItemMenu(cID, items[i]);
                  imgui.Separator();
               else 
                  imgui.EndGroup();
                  ShowItemMenu(cID, items[i]);
                  if (imgui.IsItemHovered()) then
                     imgui.SameLine(imgui.GetWindowWidth() - 70);
                     imgui.Image(imgLckIcon, {13, 13}, {0, 0}, {1, 1}, 0);
                  else
                     
                  end
                  imgui.Separator();
               end
            else
               imgui.EndGroup();
               ShowItemMenu(cID, items[i]);
               imgui.Separator();
            end
         end
      end
   end
   imgui.PopStyleColor(1);
   imgui.End();
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
   -- Merge settings and defaults
   config = settings.load(defaults);
   settings.register('settings', 'on_switch', function(newSettings)
      config = newSettings
   end)
   
   ContainersInverted = table_invert(config.containerOrder);
   
   -- Set Pointers (MogHouse)
   local pointer = ashita.memory.find('FFXiMain.dll', 0, '8B8C24040100008B90????????0BD18990????????8B15????????8B82', 0x00, 0x00);
    if (pointer == 0) then
        error('Failed to find required pointer. (2)');
        return;
    end
    local offset = ashita.memory.read_uint32(pointer + 0x09);
    if (offset == 0) then
        error('Failed to read required offset. (2)');
        return;
    end
    ZONE_FLAGS_OFFSET = offset;
    pointer = ashita.memory.read_uint32(pointer + 0x17);
    if (pointer == 0) then
        error('Failed to read required pointer. (2)');
        return;
    end
    ZONE_FLAGS_POINTER = pointer;
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()
   settings.save();
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.events.register('packet_in', 'packet_in_cb', function(e)
   local id = e.id;
   local size = e.size;
   local packet = e.data;
   
   local player = GetPlayerEntity();
   if (player == nil or ContainerInfo.Gil == nil) then
      return;
   end
   
   if (id == 0x01D or id == 0x01E or id == 0x01F or id == 0x020) then
      ashita.tasks.once(0.1, function()
         SetContainerInfo();
      end);
   end
   
   return false;
end);

----------------------------------------------------------------------------------------------------
-- func: d3d_reset
-- desc: Reload tetures if the device resets.
----------------------------------------------------------------------------------------------------
ashita.events.register('d3d_reset', 'reset_cb', function()
   imgGilIcon, texGilIcon = LoadTextureFromFile('65535');
   imgInvIcon, texInvIcon = LoadTextureFromFile('sack');
   imgLckIcon, texLckIcon = LoadTextureFromFile('locked');
   imgDrpIcon, texDrpIcon = LoadTextureFromFile('x');
   
   for id, tex in pairs(itemTextures) do
      if tex then tex:Release(); end
      itemTextures[id] = nil;
   end
   itemTextures = T{};
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.events.register('d3d_present', 'present_cb', function ()
   -- Prevent Render
   local player = GetPlayerEntity();
   if (player == nil) then return; end
   
   if (ContainerInfo.Gil == nil) then
      SetContainerInfo();
      return;
   end
   
   if (inventory:GetContainerCountMax(0) ~= 0) then
      showMenu();
      
      for i = 1, table.getn(config.containerOrder), 1 do
         if(config.windows['showContainer' .. config.containerOrder[i]][1]) then
            ShowContainer(config.containerOrder[i]);
         end
      end
   end
end);
