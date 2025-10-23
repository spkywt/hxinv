--[[
  item_sort.lua
  ---------------------
  Custom sort function for Ashita v4 (FFXI item lists)

  Current Logic Summary:
   • Sort Priority by Type:
      1. Type 8  = Crystal
      2. Type 7  = Usable Item
      3. Type 3  = Fish
      4. Type 4  = Weapon
      5. Type 5  = Armor
      6. All other types follow in ascending numeric order.

   • Within each group:
      - Types 8, 7, 3:
         → Sort by name (A–Z)
         → Then by count (lowest to highest)
      - Types 4, 5:
         → Sort by slots (lowest numeric value first)
         → Then by name (A–Z)
      - Everything else:
         → Sort by type (ascending)
         → Then by name (A–Z)

   • Tie-break:
      → If all fields match, compare by ID or Index to ensure a stable, deterministic order.

  Notes:
   - To reverse order (e.g., highest count first), flip the comparison signs inside that section.
   - Case-sensitive sorting by default; wrap `a.name` / `b.name` with `string.lower()` for case-insensitive behavior.
   - Nil slots are treated as very large (`math.huge`) so they appear last within type 4/5 groups.
]]

local M = {}

local function type_rank(t)
   if t == 8 then return 1
   elseif t == 7 then return 2
   elseif t == 3 then return 3
   elseif t == 4 then return 4
   elseif t == 5 then return 5
   elseif t ~= nil then return 100 + t
   else return 999
   end
end

function M.sort_items(items)
   table.sort(items, function(a, b)
      local ra, rb = type_rank(a.type), type_rank(b.type)
      if ra ~= rb then
         return ra < rb
      end

      if a.type == 8 or a.type == 7 or a.type == 3 then
         if a.name ~= b.name then
            return (a.name or "") < (b.name or "")
         end
         if (a.count or 0) ~= (b.count or 0) then
            return (a.count or 0) < (b.count or 0)
         end
         return (a.id or a.index or 0) < (b.id or b.index or 0)
      end

      if a.type == 4 or a.type == 5 then
         if (a.slots or math.huge) ~= (b.slots or math.huge) then
            return (a.slots or math.huge) < (b.slots or math.huge)
         end
         if a.name ~= b.name then
            return (a.name or "") < (b.name or "")
         end
         return (a.id or a.index or 0) < (b.id or b.index or 0)
      end

      if (a.type or math.huge) ~= (b.type or math.huge) then
         return (a.type or math.huge) < (b.type or math.huge)
      end
      if a.name ~= b.name then
         return (a.name or "") < (b.name or "")
      end
      return (a.id or a.index or 0) < (b.id or b.index or 0)
   end)
   return items
end

return M
