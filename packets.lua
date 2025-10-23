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

----------------------------------------------------------------------------------------------------
-- func: sendEquipItem
-- desc: Add packet to equip or remove item.
----------------------------------------------------------------------------------------------------
function sendEquipItem(itemIndex, slotmask, containerId, equipped)
	equipped = equipped or false;
	local slot = nil;
	for k,v in pairs(EquipmentSlotMask) do
		if (slotmask == 3) then slot = 'Main'; break; end
		if (slotmask == v) then	slot = k;      break; end
	end
	if (slot == 'Ears') then
		if equipped then
			if     (inventory:GetEquippedItem(11).ItemIndex == itemIndex) then slot = 'Ear1';
			elseif (inventory:GetEquippedItem(12).ItemIndex == itemIndex) then slot = 'Ear2';
			end
		else
			if     (inventory:GetEquippedItem(11).ItemIndex == 0) then slot = 'Ear1';
			elseif (inventory:GetEquippedItem(12).ItemIndex == 0) then slot = 'Ear2';
			else echo('You must remove an earring before equipping one.'); return false;
			end
		end
	end
	if (slot == 'Rings') then
		if equipped then
			if     (inventory:GetEquippedItem(13).ItemIndex == itemIndex) then slot = 'Ring1';
			elseif (inventory:GetEquippedItem(14).ItemIndex == itemIndex) then slot = 'Ring2';
			end
		else
			if     (inventory:GetEquippedItem(13).ItemIndex == 0) then slot = 'Ring1';
			elseif (inventory:GetEquippedItem(14).ItemIndex == 0) then slot = 'Ring2';
			else echo('You must remove a ring before equipping one.'); return false;
			end
		end
	end
	
	if equipped then itemIndex = 0; end
	
	local packet = struct.pack('bbbbbbbb',
        0x50, 0x04, 0x00, 0x00,
        itemIndex,
		EquipmentSlots[slot],
        containerId,
        0x00
    );
    AshitaCore:GetPacketManager():AddOutgoingPacket(0x050, packet:totable());
end

----------------------------------------------------------------------------------------------------
-- func: dropItem
-- desc: Add packet move item between bags.
----------------------------------------------------------------------------------------------------
function dropItem(itemIndex, itemCount, containerId)
	local packet = struct.pack('bbbbbbbbbbbb',
        0x28, 0x06, 0x00, 0x00,
        itemCount, 0x00, 0x00, 0x00,
		containerId, itemIndex, 0x00, 0x00
    );
    AshitaCore:GetPacketManager():AddOutgoingPacket(0x028, packet:totable());
end

----------------------------------------------------------------------------------------------------
-- func: moveItem
-- desc: Add packet move item between bags.
----------------------------------------------------------------------------------------------------
function moveItem(itemIndex, itemCount, cSourceId, cTargetId)
	local packet = struct.pack('bbbbbbbbbbbb',
        0x29, 0x06, 0x00, 0x00,
        itemCount, 0x00, 0x00, 0x00,
		cSourceId, cTargetId, itemIndex, 0x52
    );
    AshitaCore:GetPacketManager():AddOutgoingPacket(0x029, packet:totable());
end

----------------------------------------------------------------------------------------------------
-- func: sortContainer
-- desc: Sort container.
----------------------------------------------------------------------------------------------------
function sortContainer(cID)
	local packet = struct.pack('bbbbbbbb',
      0x3A, 0x04, 0x00, 0x00,
      cID, 0x00, 0x00, 0x00
   );
   AshitaCore:GetPacketManager():AddOutgoingPacket(0x03A, packet:totable());
end

--[[
-- Drop Item
fields.outgoing[0x028] = L{
    {ctype='unsigned int',      label='Count'},                                 -- 04
    {ctype='unsigned char',     label='Bag',                fn=bag},            -- 08
    {ctype='unsigned char',     label='Inventory Index',    fn=invp+{0x08}},    -- 09
    {ctype='unsigned short',    label='_junk1'},                                -- 0A
}

-- Move Item
fields.outgoing[0x029] = L{
    {ctype='unsigned int',      label='Count'},                                 -- 04
    {ctype='unsigned char',     label='Bag',                fn=bag},            -- 08
    {ctype='unsigned char',     label='Target Bag',         fn=bag},            -- 09
    {ctype='unsigned char',     label='Current Index',      fn=invp+{0x08}},    -- 0A
    {ctype='unsigned char',     label='Target Index'},                          -- 0B  This byte is 0x52 when moving items between bags. It takes other values when manually sorting.
}
]]--