-- Auto-generated Stormwind coordinate fixes for Project Epoch
-- Converts all Classic Stormwind NPCs to their WotLK coordinates
-- Generated on 08/25/2025 14:43:21

---@class QuestieEpochStormwindFixes
local QuestieEpochStormwindFixes = QuestieLoader:CreateModule("QuestieEpochStormwindFixes")
-------------------------
--Import modules.
-------------------------
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
local npcKeys = QuestieDB.npcKeys

function QuestieEpochStormwindFixes:Load()
    return {
        -- NPC ID 277: Roberto Pupellyverbos
        [277] = {
            [npcKeys.spawns] = {[1519]={{60.03,76.86}}},
        },
        -- NPC ID 279: Morgan Pestle
        [279] = {
            [npcKeys.spawns] = {[1519]={{63.16,74.4}}},
        },
        -- NPC ID 297: Caretaker Folsom
        [297] = {
            [npcKeys.spawns] = {[1519]={{42.56,72.36}}},
        },
        -- NPC ID 332: Master Mathias Shaw
        [332] = {
            [npcKeys.spawns] = {[1519]={{78.31,70.74}}},
        },
        -- NPC ID 338: Mazen Mac\
        [338] = {
            [npcKeys.spawns] = {[1519]={{51.8,74.23}}},
        },
        -- NPC ID 340: Kendor Kabonka
        [340] = {
            [npcKeys.spawns] = {[1519]={{77.47,52.69}}},
        },
        -- NPC ID 352: Dungar Longdrink
        [352] = {
            [npcKeys.spawns] = {[1519]={{70.95,72.51}}},
        },
        -- NPC ID 376: High Priestess Laurena
        [376] = {
            [npcKeys.spawns] = {[1519]={{49.53,44.6}}},
        },
        -- NPC ID 461: Demisette Cloyce
        [461] = {
            [npcKeys.spawns] = {[1519]={{39.24,84.96}}},
        },
        -- NPC ID 466: General Marcus Jonathan
        [466] = {
            [npcKeys.spawns] = {[1519]={{69.17,82.72}}},
        },
        -- NPC ID 482: Elling Trias
        [482] = {
            [npcKeys.spawns] = {[1519]={{66.03,74.1}}},
        },
        -- NPC ID 483: Elaine Trias
        [483] = {
            [npcKeys.spawns] = {[1519]={{66.56,73.37}}},
        },
        -- NPC ID 656: Wilder Thistlenettle
        [656] = {
            [npcKeys.spawns] = {[1519]={{70.31,40.82}}},
        },
        -- NPC ID 914: Ander Germaine
        [914] = {
            [npcKeys.spawns] = {[1519]={{80.19,61.26}}},
        },
        -- NPC ID 918: Osborne the Night Man
        [918] = {
            [npcKeys.spawns] = {[1519]={{77.43,65.31}}},
        },
        -- NPC ID 928: Lord Grayson Shadowbreaker
        [928] = {
            [npcKeys.spawns] = {[1519]={{48.43,50.22}}},
        },
        -- NPC ID 957: Dane Lindgren
        [957] = {
            [npcKeys.spawns] = {[1519]={{64.12,37.02}}},
        },
        -- NPC ID 1141: Angus Stern
        [1141] = {
            [npcKeys.spawns] = {[1519]={{51.78,93.61}}},
        },
        -- NPC ID 1212: Bishop Farthing
        [1212] = {
            [npcKeys.spawns] = {[1519]={{49.93,45.99}}},
        },
        -- NPC ID 1257: Keldric Boucher
        [1257] = {
            [npcKeys.spawns] = {[1519]={{62.8,75.04}}},
        },
        -- NPC ID 1275: Kyra Boucher
        [1275] = {
            [npcKeys.spawns] = {[1519]={{63.11,74.94}}},
        },
        -- NPC ID 1284: Archbishop Benedictus
        [1284] = {
            [npcKeys.spawns] = {[1519]={{50.31,45.48}}},
        },
        -- NPC ID 1285: Thurman Mullby
        [1285] = {
            [npcKeys.spawns] = {[1519]={{64.84,72.17}}},
        },
        -- NPC ID 1286: Edna Mullby
        [1286] = {
            [npcKeys.spawns] = {[1519]={{64.73,71.26}}},
        },
        -- NPC ID 1287: Marda Weller
        [1287] = {
            [npcKeys.spawns] = {[1519]={{64.07,68.36}}},
        },
        -- NPC ID 1289: Gunther Weller
        [1289] = {
            [npcKeys.spawns] = {[1519]={{64.21,68.6}}},
        },
        -- NPC ID 1291: Carla Granger
        [1291] = {
            [npcKeys.spawns] = {[1519]={{62.02,67.79}}},
        },
        -- NPC ID 1292: Maris Granger
        [1292] = {
            [npcKeys.spawns] = {[1519]={{72.14,62.21}}},
        },
        -- NPC ID 1294: Aldric Moore
        [1294] = {
            [npcKeys.spawns] = {[1519]={{61.91,67.18}}},
        },
        -- NPC ID 1295: Lara Moore
        [1295] = {
            [npcKeys.spawns] = {[1519]={{61.97,67.47}}},
        },
        -- NPC ID 1297: Lina Stover
        [1297] = {
            [npcKeys.spawns] = {[1519]={{58.72,68.72}}},
        },
        -- NPC ID 1298: Frederick Stover
        [1298] = {
            [npcKeys.spawns] = {[1519]={{58.35,69.03}}},
        },
        -- NPC ID 1299: Lisbeth Schneider
        [1299] = {
            [npcKeys.spawns] = {[1519]={{58.3,67.15}}},
        },
        -- NPC ID 1300: Lawrence Schneider
        [1300] = {
            [npcKeys.spawns] = {[1519]={{53.48,81.47}}},
        },
        -- NPC ID 1301: Julia Gallina
        [1301] = {
            [npcKeys.spawns] = {[1519]={{59.93,77.7}}},
        },
        -- NPC ID 1302: Bernard Gump
        [1302] = {
            [npcKeys.spawns] = {[1519]={{69.24,71.84}}},
        },
        -- NPC ID 1303: Felicia Gump
        [1303] = {
            [npcKeys.spawns] = {[1519]={{69.35,71.33}}},
        },
        -- NPC ID 1304: Darian Singh
        [1304] = {
            [npcKeys.spawns] = {[1519]={{42.44,76.94}}},
        },
        -- NPC ID 1305: Jarel Moor
        [1305] = {
            [npcKeys.spawns] = {[1519]={{41.97,82.72}}},
        },
        -- NPC ID 1307: Charys Yserian
        [1307] = {
            [npcKeys.spawns] = {[1519]={{44.58,86.26}}},
        },
        -- NPC ID 1308: Owen Vaughn
        [1308] = {
            [npcKeys.spawns] = {[1519]={{47.42,82.46}}},
        },
        -- NPC ID 1309: Wynne Larson
        [1309] = {
            [npcKeys.spawns] = {[1519]={{51.84,83.51}}},
        },
        -- NPC ID 1310: Evan Larson
        [1310] = {
            [npcKeys.spawns] = {[1519]={{52.66,83.68}}},
        },
        -- NPC ID 1311: Joachim Brenlow
        [1311] = {
            [npcKeys.spawns] = {[1519]={{51.45,94.1}}},
        },
        -- NPC ID 1312: Ardwyn Cailen
        [1312] = {
            [npcKeys.spawns] = {[1519]={{52.86,74.82}}},
        },
        -- NPC ID 1313: Maria Lumere
        [1313] = {
            [npcKeys.spawns] = {[1519]={{55.89,85.63}}},
        },
        -- NPC ID 1314: Duncan Cullen
        [1314] = {
            [npcKeys.spawns] = {[1519]={{53.18,82.04}}},
        },
        -- NPC ID 1315: Allan Hafgan
        [1315] = {
            [npcKeys.spawns] = {[1519]={{53.01,74.9}}},
        },
        -- NPC ID 1316: Adair Gilroy
        [1316] = {
            [npcKeys.spawns] = {[1519]={{51.83,75.08}}},
        },
        -- NPC ID 1317: Lucan Cordell
        [1317] = {
            [npcKeys.spawns] = {[1519]={{52.9,74.46}}},
        },
        -- NPC ID 1318: Jessara Cordell
        [1318] = {
            [npcKeys.spawns] = {[1519]={{52.8,74.26}}},
        },
        -- NPC ID 1319: Bryan Cross
        [1319] = {
            [npcKeys.spawns] = {[1519]={{69.19,57.64}}},
        },
        -- NPC ID 1320: Seoman Griffith
        [1320] = {
            [npcKeys.spawns] = {[1519]={{71.86,61.98}}},
        },
        -- NPC ID 1321: Alyssa Griffith
        [1321] = {
            [npcKeys.spawns] = {[1519]={{71.69,62.21}}},
        },
        -- NPC ID 1323: Osric Strang
        [1323] = {
            [npcKeys.spawns] = {[1519]={{77.17,60.99}}},
        },
        -- NPC ID 1324: Heinrich Stone
        [1324] = {
            [npcKeys.spawns] = {[1519]={{77.22,57.36}}},
        },
        -- NPC ID 1325: Jasper Fel
        [1325] = {
            [npcKeys.spawns] = {[1519]={{80.27,70.08}}},
        },
        -- NPC ID 1326: Sloan McCoy
        [1326] = {
            [npcKeys.spawns] = {[1519]={{78.63,70.86}}},
        },
        -- NPC ID 1327: Reese Langston
        [1327] = {
            [npcKeys.spawns] = {[1519]={{77.04,52.7}}},
        },
        -- NPC ID 1328: Elly Langston
        [1328] = {
            [npcKeys.spawns] = {[1519]={{76.48,54.3}}},
        },
        -- NPC ID 1333: Gerik Koen
        [1333] = {
            [npcKeys.spawns] = {[1519]={{73.01,57.45}}},
        },
        -- NPC ID 1339: Mayda Thane
        [1339] = {
            [npcKeys.spawns] = {[1519]={{71.69,58.19}}},
        },
        -- NPC ID 1341: Wilhelm Strang
        [1341] = {
            [npcKeys.spawns] = {[1519]={{77.51,61.3}}},
        },
        -- NPC ID 1346: Georgio Bolero
        [1346] = {
            [npcKeys.spawns] = {[1519]={{53.08,81.35}}},
        },
        -- NPC ID 1347: Alexandra Bolero
        [1347] = {
            [npcKeys.spawns] = {[1519]={{53.14,81.76}}},
        },
        -- NPC ID 1348: Gregory Ardus
        [1348] = {
            [npcKeys.spawns] = {[1519]={{48.13,55.11}}},
        },
        -- NPC ID 1349: Agustus Moulaine
        [1349] = {
            [npcKeys.spawns] = {[1519]={{53.51,57.56}}},
        },
        -- NPC ID 1350: Theresa Moulaine
        [1350] = {
            [npcKeys.spawns] = {[1519]={{53.21,57.93}}},
        },
        -- NPC ID 1351: Brother Cassius
        [1351] = {
            [npcKeys.spawns] = {[1519]={{53.33,45.3}}},
        },
        -- NPC ID 1366: Adam
        [1366] = {
            [npcKeys.spawns] = {[1519]={{68.34,64.87}}},
        },
        -- NPC ID 1367: Billy
        [1367] = {
            [npcKeys.spawns] = {[1519]={{68.38,64.76}}},
        },
        -- NPC ID 1368: Justin
        [1368] = {
            [npcKeys.spawns] = {[1519]={{62.45,50.79}}},
        },
        -- NPC ID 1370: Brandon
        [1370] = {
            [npcKeys.spawns] = {[1519]={{62.45,50.79}}},
        },
        -- NPC ID 1371: Roman
        [1371] = {
            [npcKeys.spawns] = {[1519]={{62.45,50.79}}},
        },
        -- NPC ID 1395: Ol\
        [1395] = {
            [npcKeys.spawns] = {[1519]={{73.59,60.09}}},
        },
        -- NPC ID 1402: Topper McNabb
        [1402] = {
            [npcKeys.spawns] = {[1519]={{60.3,69.01}}},
        },
        -- NPC ID 1405: Morris Lawry
        [1405] = {
            [npcKeys.spawns] = {[1519]={{53.05,61.97}}},
        },
        -- NPC ID 1413: Janey Anship
        [1413] = {
            [npcKeys.spawns] = {[1519]={{49.72,86.04}}},
        },
        -- NPC ID 1414: Lisan Pierce
        [1414] = {
            [npcKeys.spawns] = {[1519]={{49.77,85.79}}},
        },
        -- NPC ID 1415: Suzanne
        [1415] = {
            [npcKeys.spawns] = {[1519]={{49.88,86.06}}},
        },
        -- NPC ID 1416: Grimand Elmore
        [1416] = {
            [npcKeys.spawns] = {[1519]={{59.72,33.77}}},
        },
        -- NPC ID 1419: Fizzles
        [1419] = {
            [npcKeys.spawns] = {[1519]={{44.65,86.19}}},
        },
        -- NPC ID 1423: Stormwind Guard
        [1423] = {
            [npcKeys.spawns] = {[1519]={{74.57,93.02}}},
        },
        -- NPC ID 1427: Harlan Bagley
        [1427] = {
            [npcKeys.spawns] = {[1519]={{62.32,67.95}}},
        },
        -- NPC ID 1428: Rema Schneider
        [1428] = {
            [npcKeys.spawns] = {[1519]={{58.1,67.49}}},
        },
        -- NPC ID 1429: Thurman Schneider
        [1429] = {
            [npcKeys.spawns] = {[1519]={{52.59,83.4}}},
        },
        -- NPC ID 1431: Suzetta Gallina
        [1431] = {
            [npcKeys.spawns] = {[1519]={{60.28,76.75}}},
        },
        -- NPC ID 1432: Renato Gallina
        [1432] = {
            [npcKeys.spawns] = {[1519]={{63.77,73.59}}},
        },
        -- NPC ID 1435: Zardeth of the Black Claw
        [1435] = {
            [npcKeys.spawns] = {[1519]={{40.14,85.31}}},
        },
        -- NPC ID 1439: Lord Baurles K. Wishock
        [1439] = {
            [npcKeys.spawns] = {[1519]={{77.88,48.95}}},
        },
        -- NPC ID 1440: Milton Sheaf
        [1440] = {
            [npcKeys.spawns] = {[1519]={{77.07,30.21}}},
        },
        -- NPC ID 1444: Brother Kristoff
        [1444] = {
            [npcKeys.spawns] = {[1519]={{55.04,54.16}}},
        },
        -- NPC ID 1472: Morgg Stormshot
        [1472] = {
            [npcKeys.spawns] = {[1519]={{65.61,40.88}}},
        },
        -- NPC ID 1478: Aedis Brom
        [1478] = {
            [npcKeys.spawns] = {[1519]={{76.81,52.67}}},
        },
        -- NPC ID 1646: Baros Alexston
        [1646] = {
            [npcKeys.spawns] = {[1519]={{57.74,47.86}}},
        },
        -- NPC ID 1719: Warden Thelwater
        [1719] = {
            [npcKeys.spawns] = {[1519]={{51.49,69.39}}},
        },
        -- NPC ID 1721: Nikova Raskol
        [1721] = {
            [npcKeys.spawns] = {[1519]={{73.26,55.51}}},
        },
        -- NPC ID 1733: Zggi
        [1733] = {
            [npcKeys.spawns] = {[1519]={{40.21,85.31}}},
        },
        -- NPC ID 1747: Anduin Wrynn
        [1747] = {
            [npcKeys.spawns] = {[1519]={{79.92,38.31}}},
        },
        -- NPC ID 1750: Grand Admiral Jes-Tereth
        [1750] = {
            [npcKeys.spawns] = {[1519]={{82.94,34.37}}},
        },
        -- NPC ID 1751: Mithras Ironhill
        [1751] = {
            [npcKeys.spawns] = {[1519]={{83.23,35.06}}},
        },
        -- NPC ID 1752: Caledra Dawnbreeze
        [1752] = {
            [npcKeys.spawns] = {[1519]={{78.03,46.43}}},
        },
        -- NPC ID 1754: Lord Gregor Lescovar
        [1754] = {
            [npcKeys.spawns] = {[1519]={{76.44,29.1}}},
        },
        -- NPC ID 2198: Crier Goodman
        [2198] = {
            [npcKeys.spawns] = {[1519]={{56.39,74.09}}},
        },
        -- NPC ID 2285: Count Remington Ridgewell
        [2285] = {
            [npcKeys.spawns] = {[1519]={{76.94,47.83}}},
        },
        -- NPC ID 2327: Shaina Fuller
        [2327] = {
            [npcKeys.spawns] = {[1519]={{53.0,44.67}}},
        },
        -- NPC ID 2330: Karlee Chaddis
        [2330] = {
            [npcKeys.spawns] = {[1519]={{56.46,74.28}}},
        },
        -- NPC ID 2331: Paige Chaddis
        [2331] = {
            [npcKeys.spawns] = {[1519]={{56.55,74.27}}},
        },
        -- NPC ID 2439: Major Samuelson
        [2439] = {
            [npcKeys.spawns] = {[1519]={{75.82,36.72}}},
        },
        -- NPC ID 2455: Olivia Burnside
        [2455] = {
            [npcKeys.spawns] = {[1519]={{64.29,80.75}}},
        },
        -- NPC ID 2456: Newton Burnside
        [2456] = {
            [npcKeys.spawns] = {[1519]={{63.87,81.1}}},
        },
        -- NPC ID 2457: John Burnside
        [2457] = {
            [npcKeys.spawns] = {[1519]={{63.45,81.45}}},
        },
        -- NPC ID 2485: Larimaine Purdue
        [2485] = {
            [npcKeys.spawns] = {[1519]={{50.38,85.99}}},
        },
        -- NPC ID 2504: Donyal Tovald
        [2504] = {
            [npcKeys.spawns] = {[1519]={{75.05,30.12}}},
        },
        -- NPC ID 2532: Donna
        [2532] = {
            [npcKeys.spawns] = {[1519]={{67.42,64.27}}},
        },
        -- NPC ID 2533: William
        [2533] = {
            [npcKeys.spawns] = {[1519]={{67.51,64.16}}},
        },
        -- NPC ID 2708: Archmage Malin
        [2708] = {
            [npcKeys.spawns] = {[1519]={{50.51,87.47}}},
        },
        -- NPC ID 2795: Lenny "Fingers" McCoy
        [2795] = {
            [npcKeys.spawns] = {[1519]={{72.79,58.91}}},
        },
        -- NPC ID 2879: Karrina Mekenda
        [2879] = {
            [npcKeys.spawns] = {[1519]={{67.32,36.81}}},
        },
        -- NPC ID 3504: Gil
        [3504] = {
            [npcKeys.spawns] = {[1519]={{56.52,74.16}}},
        },
        -- NPC ID 3505: Pat
        [3505] = {
            [npcKeys.spawns] = {[1519]={{60.77,72.75}}},
        },
        -- NPC ID 3507: Andi
        [3507] = {
            [npcKeys.spawns] = {[1519]={{60.78,72.92}}},
        },
        -- NPC ID 3508: Mikey
        [3508] = {
            [npcKeys.spawns] = {[1519]={{60.58,73.03}}},
        },
        -- NPC ID 3509: Geoff
        [3509] = {
            [npcKeys.spawns] = {[1519]={{60.8,72.84}}},
        },
        -- NPC ID 3510: Twain
        [3510] = {
            [npcKeys.spawns] = {[1519]={{60.73,72.99}}},
        },
        -- NPC ID 3511: Steven
        [3511] = {
            [npcKeys.spawns] = {[1519]={{60.65,73.01}}},
        },
        -- NPC ID 3512: Jimmy
        [3512] = {
            [npcKeys.spawns] = {[1519]={{60.51,73.02}}},
        },
        -- NPC ID 3513: Miss Danna
        [3513] = {
            [npcKeys.spawns] = {[1519]={{60.58,72.75}}},
        },
        -- NPC ID 3626: Jenn Langston
        [3626] = {
            [npcKeys.spawns] = {[1519]={{71.79,56.17}}},
        },
        -- NPC ID 3627: Erich Lohan
        [3627] = {
            [npcKeys.spawns] = {[1519]={{47.98,89.17}}},
        },
        -- NPC ID 3628: Steven Lohan
        [3628] = {
            [npcKeys.spawns] = {[1519]={{51.74,93.94}}},
        },
        -- NPC ID 3629: David Langston
        [3629] = {
            [npcKeys.spawns] = {[1519]={{77.28,53.09}}},
        },
        -- NPC ID 4078: Collin Mauren
        [4078] = {
            [npcKeys.spawns] = {[1519]={{53.02,86.64}}},
        },
        -- NPC ID 4959: Jorgen
        [4959] = {
            [npcKeys.spawns] = {[1519]={{76.29,85.12}}},
        },
        -- NPC ID 4960: Bishop DeLavey
        [4960] = {
            [npcKeys.spawns] = {[1519]={{80.26,44.13}}},
        },
        -- NPC ID 4961: Dashel Stonefist
        [4961] = {
            [npcKeys.spawns] = {[1519]={{74.27,59.17}}},
        },
        -- NPC ID 4974: Aldwin Laughlin
        [4974] = {
            [npcKeys.spawns] = {[1519]={{63.8,76.78}}},
        },
        -- NPC ID 4981: Ben Trias
        [4981] = {
            [npcKeys.spawns] = {[1519]={{66.36,73.51}}},
        },
        -- NPC ID 4982: Thomas
        [4982] = {
            [npcKeys.spawns] = {[1519]={{49.64,44.47}}},
        },
        -- NPC ID 4984: Argos Nightwhisper
        [4984] = {
            [npcKeys.spawns] = {[1519]={{36.23,67.61}}},
        },
        -- NPC ID 5042: Nurse Lillian
        [5042] = {
            [npcKeys.spawns] = {[1519]={{52.26,65.97}}},
        },
        -- NPC ID 5081: Connor Rivers
        [5081] = {
            [npcKeys.spawns] = {[1519]={{51.12,95.52}}},
        },
        -- NPC ID 5193: Rebecca Laughlin
        [5193] = {
            [npcKeys.spawns] = {[1519]={{63.98,77.5}}},
        },
        -- NPC ID 5384: Brohann Caskbelly
        [5384] = {
            [npcKeys.spawns] = {[1519]={{69.45,40.42}}},
        },
        -- NPC ID 5386: Acolyte Dellis
        [5386] = {
            [npcKeys.spawns] = {[1519]={{51.4,73.81}}},
        },
        -- NPC ID 5413: Furen Longbeard
        [5413] = {
            [npcKeys.spawns] = {[1519]={{64.62,37.22}}},
        },
        -- NPC ID 5479: Wu Shen
        [5479] = {
            [npcKeys.spawns] = {[1519]={{80.56,59.87}}},
        },
        -- NPC ID 5480: Ilsa Corbin
        [5480] = {
            [npcKeys.spawns] = {[1519]={{80.41,59.8}}},
        },
        -- NPC ID 5482: Stephen Ryback
        [5482] = {
            [npcKeys.spawns] = {[1519]={{78.17,53.1}}},
        },
        -- NPC ID 5483: Erika Tate
        [5483] = {
            [npcKeys.spawns] = {[1519]={{78.53,52.88}}},
        },
        -- NPC ID 5484: Brother Benjamin
        [5484] = {
            [npcKeys.spawns] = {[1519]={{52.27,47.64}}},
        },
        -- NPC ID 5489: Brother Joshua
        [5489] = {
            [npcKeys.spawns] = {[1519]={{49.5,45.21}}},
        },
        -- NPC ID 5491: Arthur the Faithful
        [5491] = {
            [npcKeys.spawns] = {[1519]={{49.6,49.84}}},
        },
        -- NPC ID 5492: Katherine the Pure
        [5492] = {
            [npcKeys.spawns] = {[1519]={{48.48,49.08}}},
        },
        -- NPC ID 5493: Arnold Leland
        [5493] = {
            [npcKeys.spawns] = {[1519]={{54.99,69.65}}},
        },
        -- NPC ID 5494: Catherine Leland
        [5494] = {
            [npcKeys.spawns] = {[1519]={{55.09,69.76}}},
        },
        -- NPC ID 5495: Ursula Deline
        [5495] = {
            [npcKeys.spawns] = {[1519]={{39.89,84.19}}},
        },
        -- NPC ID 5496: Sandahl
        [5496] = {
            [npcKeys.spawns] = {[1519]={{39.66,85.74}}},
        },
        -- NPC ID 5497: Jennea Cannon
        [5497] = {
            [npcKeys.spawns] = {[1519]={{49.56,85.8}}},
        },
        -- NPC ID 5498: Elsharin
        [5498] = {
            [npcKeys.spawns] = {[1519]={{48.2,87.22}}},
        },
        -- NPC ID 5499: Lilyssia Nightbreeze
        [5499] = {
            [npcKeys.spawns] = {[1519]={{55.66,86.09}}},
        },
        -- NPC ID 5500: Tel\
        [5500] = {
            [npcKeys.spawns] = {[1519]={{55.47,85.65}}},
        },
        -- NPC ID 5502: Shylamiir
        [5502] = {
            [npcKeys.spawns] = {[1519]={{31.51,62.6}}},
        },
        -- NPC ID 5503: Eldraeith
        [5503] = {
            [npcKeys.spawns] = {[1519]={{55.78,85.29}}},
        },
        -- NPC ID 5504: Sheldras Moontree
        [5504] = {
            [npcKeys.spawns] = {[1519]={{35.85,67.35}}},
        },
        -- NPC ID 5505: Theridran
        [5505] = {
            [npcKeys.spawns] = {[1519]={{36.12,64.42}}},
        },
        -- NPC ID 5506: Maldryn
        [5506] = {
            [npcKeys.spawns] = {[1519]={{34.44,65.19}}},
        },
        -- NPC ID 5509: Kathrum Axehand
        [5509] = {
            [npcKeys.spawns] = {[1519]={{59.3,33.82}}},
        },
        -- NPC ID 5510: Thulman Flintcrag
        [5510] = {
            [npcKeys.spawns] = {[1519]={{61.95,36.56}}},
        },
        -- NPC ID 5511: Therum Deepforge
        [5511] = {
            [npcKeys.spawns] = {[1519]={{63.65,37.01}}},
        },
        -- NPC ID 5512: Kaita Deepforge
        [5512] = {
            [npcKeys.spawns] = {[1519]={{63.26,37.74}}},
        },
        -- NPC ID 5513: Gelman Stonehand
        [5513] = {
            [npcKeys.spawns] = {[1519]={{59.25,37.83}}},
        },
        -- NPC ID 5514: Brooke Stonebraid
        [5514] = {
            [npcKeys.spawns] = {[1519]={{59.15,37.48}}},
        },
        -- NPC ID 5515: Einris Brightspear
        [5515] = {
            [npcKeys.spawns] = {[1519]={{67.35,36.25}}},
        },
        -- NPC ID 5516: Ulfir Ironbeard
        [5516] = {
            [npcKeys.spawns] = {[1519]={{67.59,35.78}}},
        },
        -- NPC ID 5517: Thorfin Stoneshield
        [5517] = {
            [npcKeys.spawns] = {[1519]={{68.0,36.0}}},
        },
        -- NPC ID 5518: Lilliam Sparkspindle
        [5518] = {
            [npcKeys.spawns] = {[1519]={{62.09,30.32}}},
        },
        -- NPC ID 5519: Billibub Cogspinner
        [5519] = {
            [npcKeys.spawns] = {[1519]={{62.42,29.91}}},
        },
        -- NPC ID 5520: Spackle Thornberry
        [5520] = {
            [npcKeys.spawns] = {[1519]={{39.54,84.53}}},
        },
        -- NPC ID 5564: Simon Tanner
        [5564] = {
            [npcKeys.spawns] = {[1519]={{71.68,63.0}}},
        },
        -- NPC ID 5565: Jillian Tanner
        [5565] = {
            [npcKeys.spawns] = {[1519]={{71.57,62.77}}},
        },
        -- NPC ID 5566: Tannysa
        [5566] = {
            [npcKeys.spawns] = {[1519]={{54.29,84.1}}},
        },
        -- NPC ID 5567: Sellandus
        [5567] = {
            [npcKeys.spawns] = {[1519]={{52.17,83.14}}},
        },
        -- NPC ID 5694: High Sorcerer Andromath
        [5694] = {
            [npcKeys.spawns] = {[1519]={{48.71,87.62}}},
        },
        -- NPC ID 6089: Harry Burlguard
        [6089] = {
            [npcKeys.spawns] = {[1519]={{77.13,53.26}}},
        },
        -- NPC ID 6090: Bartleby
        [6090] = {
            [npcKeys.spawns] = {[1519]={{76.77,52.54}}},
        },
        -- NPC ID 6122: Gakin the Darkbinder
        [6122] = {
            [npcKeys.spawns] = {[1519]={{39.22,85.22}}},
        },
        -- NPC ID 6171: Duthorian Rall
        [6171] = {
            [npcKeys.spawns] = {[1519]={{50.48,47.5}}},
        },
        -- NPC ID 6173: Gazin Tenorm
        [6173] = {
            [npcKeys.spawns] = {[1519]={{49.53,44.98}}},
        },
        -- NPC ID 6174: Stephanie Turner
        [6174] = {
            [npcKeys.spawns] = {[1519]={{63.84,72.21}}},
        },
        -- NPC ID 6267: Acolyte Porena
        [6267] = {
            [npcKeys.spawns] = {[1519]={{39.1,83.47}}},
        },
        -- NPC ID 6579: Shoni the Shilent
        [6579] = {
            [npcKeys.spawns] = {[1519]={{62.63,34.12}}},
        },
        -- NPC ID 6740: Innkeeper Allison
        [6740] = {
            [npcKeys.spawns] = {[1519]={{60.39,75.28}}},
        },
        -- NPC ID 6946: Renzik "The Shiv"
        [6946] = {
            [npcKeys.spawns] = {[1519]={{78.3,71.14}}},
        },
        -- NPC ID 7207: Doc Mixilpixil
        [7207] = {
            [npcKeys.spawns] = {[1519]={{80.05,69.9}}},
        },
        -- NPC ID 7208: Noarm
        [7208] = {
            [npcKeys.spawns] = {[1519]={{79.75,69.78}}},
        },
        -- NPC ID 7232: Borgus Steelhand
        [7232] = {
            [npcKeys.spawns] = {[1519]={{59.4,34.26}}},
        },
        -- NPC ID 7295: Shailiea
        [7295] = {
            [npcKeys.spawns] = {[1519]={{43.19,65.7}}},
        },
        -- NPC ID 7386: White Kitten
        [7386] = {
            [npcKeys.spawns] = {[1519]={{46.24,55.09}}},
        },
        -- NPC ID 7410: Thelman Slatefist
        [7410] = {
            [npcKeys.spawns] = {[1519]={{82.09,34.87}}},
        },
        -- NPC ID 7766: Tyrion
        [7766] = {
            [npcKeys.spawns] = {[1519]={{73.22,35.58}}},
        },
        -- NPC ID 7798: Hank the Hammer
        [7798] = {
            [npcKeys.spawns] = {[1519]={{62.85,36.81}}},
        },
        -- NPC ID 7917: Brother Sarno
        [7917] = {
            [npcKeys.spawns] = {[1519]={{51.05,48.39}}},
        },
        -- NPC ID 8383: Master Wood
        [8383] = {
            [npcKeys.spawns] = {[1519]={{80.93,61.32}}},
        },
        -- NPC ID 8666: Lil Timmy
        [8666] = {
            [npcKeys.spawns] = {[1519]={{46.27,55.14}}},
        },
        -- NPC ID 8670: Auctioneer Chilton
        [8670] = {
            [npcKeys.spawns] = {[1519]={{60.85,71.52}}},
        },
        -- NPC ID 8719: Auctioneer Fitch
        [8719] = {
            [npcKeys.spawns] = {[1519]={{61.18,71.28}}},
        },
        -- NPC ID 8856: Tyrion\
        [8856] = {
            [npcKeys.spawns] = {[1519]={{73.15,35.6}}},
        },
        -- NPC ID 9584: Jalane Ayrole
        [9584] = {
            [npcKeys.spawns] = {[1519]={{40.35,84.62}}},
        },
        -- NPC ID 9977: Sylista
        [9977] = {
            [npcKeys.spawns] = {[1519]={{42.57,64.07}}},
        },
        -- NPC ID 10782: Royal Factor Bathrilor
        [10782] = {
            [npcKeys.spawns] = {[1519]={{57.18,48.07}}},
        },
        -- NPC ID 11026: Sprite Jumpsprocket
        [11026] = {
            [npcKeys.spawns] = {[1519]={{61.89,30.57}}},
        },
        -- NPC ID 11068: Betty Quin
        [11068] = {
            [npcKeys.spawns] = {[1519]={{53.03,73.73}}},
        },
        -- NPC ID 11069: Jenova Stoneshield
        [11069] = {
            [npcKeys.spawns] = {[1519]={{67.24,37.72}}},
        },
        -- NPC ID 11096: Randal Worth
        [11096] = {
            [npcKeys.spawns] = {[1519]={{72.14,62.85}}},
        },
        -- NPC ID 11397: Nara Meideros
        [11397] = {
            [npcKeys.spawns] = {[1519]={{35.68,63.21}}},
        },
        -- NPC ID 11827: Kimberly Grant
        [11827] = {
            [npcKeys.spawns] = {[1519]={{37.79,64.8}}},
        },
        -- NPC ID 11828: Kelly Grant
        [11828] = {
            [npcKeys.spawns] = {[1519]={{37.82,64.85}}},
        },
        -- NPC ID 11867: Woo Ping
        [11867] = {
            [npcKeys.spawns] = {[1519]={{63.88,69.09}}},
        },
        -- NPC ID 11916: Imelda
        [11916] = {
            [npcKeys.spawns] = {[1519]={{33.71,62.6}}},
        },
        -- NPC ID 12336: Brother Crowley
        [12336] = {
            [npcKeys.spawns] = {[1519]={{52.63,43.18}}},
        },
        -- NPC ID 12480: Melris Malagan
        [12480] = {
            [npcKeys.spawns] = {[1519]={{62.88,71.48}}},
        },
        -- NPC ID 12481: Justine Demalier
        [12481] = {
            [npcKeys.spawns] = {[1519]={{62.79,71.56}}},
        },
        -- NPC ID 13283: Lord Tony Romano
        [13283] = {
            [npcKeys.spawns] = {[1519]={{80.28,68.58}}},
        },
        -- NPC ID 13435: Khole Jinglepocket
        [13435] = {
            [npcKeys.spawns] = {[1519]={{62.24,70.29}}},
        },
        -- NPC ID 13436: Guchie Jinglepocket
        [13436] = {
            [npcKeys.spawns] = {[1519]={{62.6,70.03}}},
        },
        -- NPC ID 14394: Major Mattingly
        [14394] = {
            [npcKeys.spawns] = {[1519]={{67.16,85.51}}},
        },
        -- NPC ID 14423: Officer Jaxon
        [14423] = {
            [npcKeys.spawns] = {[1519]={{67.75,72.31}}},
        },
        -- NPC ID 14438: Officer Pomeroy
        [14438] = {
            [npcKeys.spawns] = {[1519]={{42.5,65.34}}},
        },
        -- NPC ID 14439: Officer Brady
        [14439] = {
            [npcKeys.spawns] = {[1519]={{68.88,52.11}}},
        },
        -- NPC ID 14450: Orphan Matron Nightingale
        [14450] = {
            [npcKeys.spawns] = {[1519]={{56.32,53.99}}},
        },
        -- NPC ID 14481: Emmithue Smails
        [14481] = {
            [npcKeys.spawns] = {[1519]={{61.26,74.99}}},
        },
        -- NPC ID 14497: Shellene
        [14497] = {
            [npcKeys.spawns] = {[1519]={{57.02,52.49}}},
        },
        -- NPC ID 14721: Field Marshal Afrasiabi
        [14721] = {
            [npcKeys.spawns] = {[1519]={{71.46,80.45}}},
        },
        -- NPC ID 14722: Clavicus Knavingham
        [14722] = {
            [npcKeys.spawns] = {[1519]={{53.93,81.69}}},
        },
        -- NPC ID 14981: Elfarran
        [14981] = {
            [npcKeys.spawns] = {[1519]={{83.61,34.31}}},
        },
        -- NPC ID 15008: Lady Hoteshem
        [15008] = {
            [npcKeys.spawns] = {[1519]={{83.48,34.05}}},
        },
        -- NPC ID 15310: Jesper
        [15310] = {
            [npcKeys.spawns] = {[1519]={{56.59,51.81}}},
        },
        -- NPC ID 15351: Alliance Brigadier General
        [15351] = {
            [npcKeys.spawns] = {[1519]={{83.47,33.66}}},
        },
        -- NPC ID 15562: Elder Hammershout
        [15562] = {
            [npcKeys.spawns] = {[1519]={{36.27,66.14}}},
        },
        -- NPC ID 15659: Auctioneer Jaxon
        [15659] = {
            [npcKeys.spawns] = {[1519]={{61.16,70.68}}},
        },
        -- NPC ID 15708: Master Sergeant Maclure
        [15708] = {
            [npcKeys.spawns] = {[1519]={{61.52,70.61}}},
        },
        -- NPC ID 15732: Wonderform Operator
        [15732] = {
            [npcKeys.spawns] = {[1519]={{67.87,71.43}}},
        },
        -- NPC ID 15766: Officer Maloof
        [15766] = {
            [npcKeys.spawns] = {[1519]={{62.42,74.53}}},
        },
        -- NPC ID 15893: Lunar Firework Credit Marker
        [15893] = {
            [npcKeys.spawns] = {[1519]={{37.34,64.93}}},
        },
        -- NPC ID 15894: Lunar Cluster Credit Marker
        [15894] = {
            [npcKeys.spawns] = {[1519]={{37.33,64.92}}},
        },
        -- NPC ID 15895: Lunar Festival Harbinger
        [15895] = {
            [npcKeys.spawns] = {[1519]={{37.65,65.63}}},
        },
        -- NPC ID 15897: Large Spotlight
        [15897] = {
            [npcKeys.spawns] = {[1519]={{37.33,64.98}}},
        },
        -- NPC ID 15898: Lunar Festival Vendor
        [15898] = {
            [npcKeys.spawns] = {[1519]={{37.3,64.04}}},
        },
        -- NPC ID 16075: Kwee Q. Peddlefeet
        [16075] = {
            [npcKeys.spawns] = {[1519]={{80.17,37.6}}},
        },
        -- NPC ID 16241: Argent Recruiter
        [16241] = {
            [npcKeys.spawns] = {[1519]={{62.17,72.26}}},
        },
        -- NPC ID 16285: Argent Emissary
        [16285] = {
            [npcKeys.spawns] = {[1519]={{62.28,72.09}}},
        },
        -- NPC ID 16395: Argent Dawn Paladin
        [16395] = {
            [npcKeys.spawns] = {[1519]={{62.15,72.41}}},
        },
        -- NPC ID 16433: Argent Dawn Crusader
        [16433] = {
            [npcKeys.spawns] = {[1519]={{62.15,72.41}}},
        },
        -- NPC ID 16434: Argent Dawn Champion
        [16434] = {
            [npcKeys.spawns] = {[1519]={{62.15,72.41}}},
        },
        -- NPC ID 16478: Lieutenant Orrin
        [16478] = {
            [npcKeys.spawns] = {[1519]={{69.04,82.83}}},
        },
        -- NPC ID 16817: Festival Loremaster
        [16817] = {
            [npcKeys.spawns] = {[1519]={{49.53,72.27}}},
        },
        -- NPC ID 16995: Mouth of Kel\
        [16995] = {
            [npcKeys.spawns] = {[1519]={{66.32,82.87}}},
        },
        -- NPC ID 17804: Squire Rowe
        [17804] = {
            [npcKeys.spawns] = {[1519]={{74.17,90.34}}},
        },
        
        -- Special WotLK Addition (Alliance Shaman Trainer)
        [20407] = {
            [npcKeys.spawns] = {[1519]={{67.52,89.42}}},
        }, -- Farseer Umbrua (Shaman Trainer)
    }
end
