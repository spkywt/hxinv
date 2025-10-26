require('common')

-- Constants
Containers = T{ [0] = 'Inventory', [1] = 'Mog Safe', [2] = 'Storage', [3] = 'Temporary', [4] = 'Locker', [5] = 'Satchel', [6] = 'Sack', [7] = 'Case', [8] = 'Wardrobe', [9] = 'Mog Safe 2', [10] = 'Wardrobe 2', [11] = 'Wardrobe 3', [12] = 'Wardrobe 4', [13] = 'Wardrobe 5', [14] = 'Wardrobe 6', [15] = 'Wardrobe 7', [16] = 'Wardrobe 8' };

ItemType = T{ None = 0, Item = 1, QuestItem = 2, Fish = 3, Weapon = 4, Armor = 5, Linkshell = 6, UsableItem = 7, Crystal = 8, Currency = 9, Furnishing = 10, Plant = 11, Flowerpot = 12, PuppetItem = 13, Mannequin = 14, Book = 15, RacingForm = 16, BettingSlip = 17, SoulPlate = 18, Reflector = 19, Logs = 20, LotteryTicket = 21, TabulaM = 22, TabulaR = 23, Voucher = 24, Rune = 25, Evolith = 26, StorageSlip = 27, Type1 = 28, Unknown0000 = 29, Instinct = 30 };

ItemFlags = T{ Wallhanging = 0x0001, Unknown = 0x0002, Mystery_Box = 0x0004, Mog_Garden = 0x0008, Mail2account = 0x0010, Inscribable = 0x0020, Noauction = 0x0040, Scroll = 0x0080, Linkshell = 0x0100, Canuse = 0x0200, Cantradenpc = 0x0400, Canequip = 0x0800, Nosale = 0x1000, Nodelivery = 0x2000, Ex = 0x4000, Rare = 0x8000 };

SkillTypes = T{ None=0, Hand_To_Hand=1, Dagger=2, Sword=3, Great_Sword=4, Axe=5, Great_Axe=6, Scythe=7, Polearm=8, Katana=9, Great_Katana=10, Club=11, Staff=12, Automaton_Melee=22, Automaton_Ranged=23, Automaton_Magic=24, Archery=25, Marksmanship=26, Throwing=27, Guard=28, Evasion=29, Shield=30, Parry=31, Divine_Magic=32, Healing_Magic=33, Enhancing_Magic=34, Enfeebling_Magic=35, Elemental_Magic=36, Dark_Magic=37, Summoning_Magic=38, Ninjutsu=39, Singing=40, String_Instrument=41, Wind_Instrument=42, Blue_Magic=43, Geomancy=44, Handbell=45, ["Fishing Tackle"]=48, Woodworking=49, Smithing=50, Goldsmithing=51, Clothcraft=52, Leathercraft=53, Bonecraft=54, Alchemy=55, Cooking=56, Synergy=57, Rid=58, Dig=59 };

RaceMask = T{ All = 0, HUME_M = 2, HUME_F = 4, ELVAAN_M = 8, ELVAAN_F = 16, TARU_M = 32, TARU_F = 64, MITHRA = 128, GALKA = 256 };

EquipmentSlots = T{ Main = 3, Sub = 2, Range = 4, Ammo = 8, Head = 16, Body = 32, Hands = 64, Legs = 128, Feet = 256, Neck = 512, Waist = 1024, Ear1 = 2056, Ear2 = 4096, Ring1 = 8192, Ring2 = 16384, Back = 32768 };

EquipmentSlotMask = T{ Main = 0, Sub = 2, Ranged = 4, Ammo = 8, Head = 16, Body = 32, Hands = 64, Legs = 128, Feet = 256, Neck = 512, Waist = 1024, Ear1 = 2056, Ear2 = 4096, Ring1 = 8192, Ring2 = 16384, Back = 32768 };

JobMask = T{ NONE = 0x00000000, WAR = 0x00000002, MNK = 0x00000004, WHM = 0x00000008, BLM = 0x00000010, RDM = 0x00000020, THF = 0x00000040, PLD = 0x00000080, DRK = 0x00000100, BST = 0x00000200, BRD = 0x00000400, RNG = 0x00000800,  SAM = 0x00001000, NIN = 0x00002000, DRG = 0x00004000, SMN = 0x00008000, BLU = 0x00010000, COR = 0x00020000, PUP = 0x00040000, DNC = 0x00080000, SCH = 0x00100000, GEO = 0x00200000, RUN = 0x00400000, MON = 0x00800000 };

return {
 Containers = Containers, 
 ItemType = ItemType, 
 ItemFlags = ItemFlags, 
 SkillTypes = SkillTypes,
 RaceMask = RaceMask,
 EquipmentSlotMask = EquipmentSlotMask,
 JobMask = JobMask
}