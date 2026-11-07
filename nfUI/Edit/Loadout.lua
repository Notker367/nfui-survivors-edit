-- Skills and jewelry panels: an ally's under the target frame, the hero's under the skills, and the
-- class's skill pool. What the game's loadout API returns is shown; it does not list banished cards.
local E=nfUIEdit
local ALLY_SIZE,ALLY_GAP,ALLY_PER_ROW=19,2,9
local POOL_PICKS=6
-- The pools are as wide as the chat they stand over.
local POOL_PER_ROW=16
-- Enough for all the amulets on one row, about as wide as the chat.
local JEWEL_PER_ROW=17
-- Each class's skill pool: { key, Russian name, icon }, from the game's own tables.
local SKILL_POOL={
    DRUID={{"wrath","Гнев","Ability_ThunderClap"},{"moonfire","Лунный огонь","Spell_Nature_StarFall"},{"starfire","Звездный огонь","Spell_Arcane_StarFire"},{"hurricane","Гроза","Spell_Nature_Cyclone"},{"insect_swarm","Рой насекомых","Spell_Nature_InsectSwarm"},{"entangling_roots","Гнев деревьев","Spell_Nature_StrangleVines"},{"rejuvenation","Омоложение","Spell_Nature_Rejuvenation"},{"regrowth","Восстановление","Spell_Nature_ResistNature"},{"thorns","Шипы","Spell_Nature_Thorns"},{"swipe","Размах","INV_Misc_MonsterClaw_03"},{"faerie_fire","Волшебный огонь","Spell_Nature_FaerieFire"},{"shred","Полоснуть","Spell_Shadow_VampiricAura"}},
    HUNTER={{"auto_shot","Автоматическая стрельба","Ability_Whirlwind"},{"arcane_shot","Чародейский выстрел","Ability_ImpalingBolt"},{"multi_shot","Залп","Ability_UpgradeMoonGlaive"},{"serpent_sting","Укус змеи","Ability_Hunter_Quickshot"},{"volley","Град стрел","Ability_Marksmanship"},{"kill_command","Команда «Взять!»","Ability_Hunter_BeastCall"},{"concussive_shot","Контузящий выстрел","Spell_Frost_Stun"},{"aimed_shot","Прицельный выстрел","INV_Spear_07"},{"immolation_trap","Обжигающая ловушка","Spell_Fire_FlameShock"},{"frost_trap","Ледяная ловушка","Spell_Frost_FreezingBreath"},{"hunters_mark","Метка охотника","Ability_Hunter_SniperShot"}},
    MAGE={{"fireball","Огненный шар","Spell_Fire_FlameBolt"},{"frostbolt","Ледяная стрела","Spell_Frost_FrostBolt02"},{"arcane_missiles","Чародейские стрелы","Spell_Nature_StarFall"},{"frost_nova","Кольцо льда","Spell_Frost_FrostNova"},{"arcane_explosion","Чародейский взрыв","Spell_Nature_WispSplode"},{"blizzard","Снежная буря","Spell_Frost_IceStorm"},{"flamestrike","Огненный столб","Spell_Fire_SelfDestruct"},{"fire_blast","Огненный взрыв","Spell_Fire_Fireball"},{"cone_of_cold","Конус холода","Spell_Frost_Glacier"},{"blast_wave","Взрывная волна","Spell_Holy_Excorcism_02"},{"pyroblast","Огненная глыба","Spell_Fire_Fireball02"},{"ice_barrier","Ледяная преграда","Spell_Ice_Lament"},{"polymorph","Превращение","Spell_Nature_Polymorph"}},
    PALADIN={{"consecration","Освящение","Spell_Holy_InnerFire"},{"exorcism","Экзорцизм","Spell_Holy_Excorcism_02"},{"hammer_of_wrath","Молот гнева","Ability_ThunderClap"},{"holy_shock","Шок небес","Spell_Holy_SearingLight"},{"holy_wrath","Гнев небес","Spell_Holy_Excorcism"},{"judgement","Правосудие","Spell_Holy_RighteousFury"},{"hammer_of_justice","Молот правосудия","Spell_Holy_SealOfMight"},{"holy_light","Свет небес","Spell_Holy_HolyBolt"},{"divine_shield","Божественный щит","Spell_Holy_DivineIntervention"},{"holy_shield","Щит небес","Spell_Holy_BlessingOfProtection"},{"redemption","Искупление","Spell_Holy_Resurrection"}},
    PRIEST={{"smite","Кара","Spell_Holy_HolySmite"},{"sw_pain","Слово Тьмы: Боль","Spell_Shadow_ShadowWordPain"},{"mind_blast","Взрыв разума","Spell_Shadow_UnholyFrenzy"},{"holy_nova","Кольцо света","Spell_Holy_HolyNova"},{"pw_shield","Слово силы: Щит","Spell_Holy_PowerWordShield"},{"renew","Обновление","Spell_Holy_Renew"},{"holy_fire","Священный огонь","Spell_Holy_SearingLight"},{"mind_flay","Пытка разума","Spell_Shadow_SiphonMana"},{"psychic_scream","Ментальный крик","Spell_Shadow_PsychicScream"},{"devouring_plague","Всепожирающая чума","Spell_Shadow_BlackPlague"}},
    ROGUE={{"sinister_strike","Коварный удар","Spell_Shadow_RitualOfSacrifice"},{"eviscerate","Потрошение","Ability_Rogue_Eviscerate"},{"blade_flurry","Шквал клинков","Ability_Warrior_PunishingBlow"},{"rupture","Рваная рана","Ability_Rogue_Rupture"},{"kidney_shot","Удар по почкам","Ability_Rogue_KidneyShot"},{"gouge","Парализующий удар","Ability_Gouge"},{"ghostly_strike","Призрачный удар","Spell_Shadow_Curse"},{"adrenaline_rush","Выброс адреналина","Spell_Shadow_ShadowWordDominate"},{"backstab","Удар в спину","Ability_BackStab"},{"slice_and_dice","Мясорубка","Ability_Rogue_SliceDice"},{"seal_fate","Печать судьбы","Spell_Shadow_ChillTouch"}},
    SHAMAN={{"lightning_bolt","Молния","Spell_Nature_Lightning"},{"chain_lightning","Цепная молния","Spell_Nature_ChainLightning"},{"earth_shock","Земной шок","Spell_Nature_EarthShock"},{"flame_shock","Огненный шок","Spell_Fire_FlameShock"},{"frost_shock","Ледяной шок","Spell_Frost_FrostShock"},{"lightning_shield","Щит молний","Spell_Nature_LightningShield"},{"magma_totem","Тотем магмы","Spell_Fire_SelfDestruct"},{"searing_totem","Опаляющий тотем","Spell_Fire_SearingTotem"},{"fire_nova","Кольцо огня","Spell_Fire_SealOfFire"},{"healing_wave","Волна исцеления","Spell_Nature_MagicImmunity"},{"stormstrike","Удар бури","Ability_Shaman_Stormstrike"}},
    WARLOCK={{"shadow_bolt","Стрела Тьмы","Spell_Shadow_ShadowBolt"},{"corruption","Порча","Spell_Shadow_AbominationExplosion"},{"immolate","Жертвенный огонь","Spell_Fire_Immolation"},{"curse_of_agony","Проклятие агонии","Spell_Shadow_CurseOfSargeras"},{"rain_of_fire","Огненный ливень","Spell_Shadow_RainOfFire"},{"hellfire","Адское пламя","Spell_Fire_Incinerate"},{"death_coil","Лик смерти","Spell_Shadow_DeathCoil"},{"searing_pain","Жгучая боль","Spell_Fire_SoulBurn"},{"drain_life","Похищение жизни","Spell_Shadow_LifeDrain02"},{"fear","Страх","Spell_Shadow_Possession"},{"soul_fire","Ожог души","Spell_Fire_Fireball02"},{"demonic_empowerment","Демоническое усиление","Spell_Nature_RemoveCurse"}},
    WARRIOR={{"cleave","Рассекающий удар","Ability_Warrior_Cleave"},{"whirlwind","Вихрь","Ability_Whirlwind"},{"thunder_clap","Удар грома","Spell_Nature_ThunderClap"},{"mortal_strike","Смертельный удар","Ability_Warrior_SavageBlow"},{"execute","Казнь","INV_Sword_48"},{"demo_shout","Деморализующий крик","Ability_Warrior_WarCry"},{"battle_shout","Боевой крик","Ability_Warrior_BattleShout"},{"bloodthirst","Жажда крови","Spell_Nature_BloodLust"},{"rend","Кровопускание","Ability_Gouge"},{"shield_slam","Мощный удар щитом","INV_Shield_05"},{"bloodrage","Кровавая ярость","Ability_Racial_BloodRage"}},
}

local ownerByName={}
local function AllyOwnerId(name,context)
    if ownerByName[name] then return ownerByName[name] end
    local snapshot=AZS_GetMeterSnapshot({apiVersion=1,runId=context.runId,metric="damage",scope="party",period="run",groupBy="owner",windowSeconds=0})
    if type(snapshot)~="table" or type(snapshot.actors)~="table" then return nil end
    for id,actor in pairs(snapshot.actors) do
        if type(actor)=="table" and actor.kind=="hero" and actor.name then ownerByName[actor.name]=id end
    end
    return ownerByName[name]
end
-- What the game's own tables say about each piece of jewelry, and the rule of its slot for those they do not describe.
local JewelByKey={}
for _,jewel in ipairs(E.JEWELS) do JewelByKey[jewel.key]=jewel end
local function JewelEffect(jewel)
    return E.Pick(jewel.effect)
end
local function KindText(kind)
    if kind=="ring" then return E.Text("Кольцо: до двух на героя","Ring: two at most") end
    if kind=="trinket" then return E.Text("Талисман: до двух на героя","Trinket: two at most") end
    return E.Text("Амулет: один на героя, новый заменяет надетый","Amulet: one at a time, a new one replaces the one worn")
end
local function LoadoutIcon(holder,index)
    local icon=holder.icons[index]
    if icon then return icon end
    icon=CreateFrame("Frame",nil,holder.frame);icon:SetWidth(ALLY_SIZE);icon:SetHeight(ALLY_SIZE)
    icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints(icon);icon.texture:SetTexCoord(0.08,0.92,0.08,0.92)
    E.Ring(icon)
    icon.rank=icon:CreateFontString(nil,"OVERLAY");icon.rank:SetFont(E.FONT,9,"OUTLINE")
    icon.rank:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",1,-1);icon.rank:SetTextColor(1,0.82,0.3)
    icon:EnableMouse(true)
    icon:SetScript("OnEnter",function()
        if not this.label then return end
        GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(this.label,1,1,1)
        if this.rankValue then GameTooltip:AddLine(E.Text("\208\160\208\176\208\189\208\179 ","Rank ")..this.rankValue,1,0.82,0) end
        if this.effect then GameTooltip:AddLine(this.effect,0.75,0.9,1,true) end
        if this.kindText then GameTooltip:AddLine(this.kindText,0.6,0.6,0.65,true) end
        if this.banishKey and E.On("banishMarks") then GameTooltip:AddLine(E.Text("Клик: отметить как изгнанное","Click: mark as banished"),0.7,0.7,0.7) end
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
    icon:SetScript("OnMouseUp",function()
        if this.banishKey and E.On("banishMarks") then E.ToggleBanish(this.banishKey,this.texture:GetTexture(),this.label) end
    end)
    holder.icons[index]=icon
    return icon
end
local JEWEL_CELLS={
    {"amulet",1,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck","Пусто: амулет","Empty: amulet"},
    {"ring",2,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger","Пусто: кольцо","Empty: ring"},
    {"trinket",2,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket","Пусто: талисман","Empty: trinket"},
}
-- The game names only a few skill legendaries in data an addon can read. Each one a hero of the party wears is
-- remembered with its skill, so the row of legendaries fills in as they turn up.
local STATIC_LEGEND={}
for _,jewel in ipairs(E.LEGENDARY or {}) do STATIC_LEGEND[jewel.spell]=true end
-- Every class's legendary amulets in the Codex's order, one for each spell (Armory > Codex, game build 1127).
-- The game names an amulet only once a run has offered it, so until then the row shows its spell.
local CODEX={
    WARRIOR={"cleave","whirlwind","thunder_clap","mortal_strike","execute","demoralizing_shout","battle_shout","bloodthirst","rend","shield_slam","bloodrage"},
    PALADIN={"consecration","exorcism","hammer_of_wrath","holy_shock","holy_wrath","judgement","hammer_of_justice","holy_light","divine_shield","holy_shield","redemption"},
    HUNTER={"auto_shot","arcane_shot","multi_shot","serpent_sting","volley","kill_command","concussive_shot","aimed_shot","immolation_trap","frost_trap","hunters_mark"},
    ROGUE={"sinister_strike","eviscerate","blade_flurry","rupture","kidney_shot","gouge","ghostly_strike","adrenaline_rush","backstab","slice_and_dice","seal_fate"},
    PRIEST={"smite","sw_pain","mind_blast","holy_nova","pw_shield","renew","holy_fire","mind_flay","psychic_scream","devouring_plague","lightwell"},
    SHAMAN={"lightning_bolt","chain_lightning","earth_shock","flame_shock","frost_shock","magma_totem","searing_totem","fire_nova","stormstrike","rockbiter"},
    MAGE={"fireball","frostbolt","arcane_missiles","frost_nova","arcane_explosion","blizzard","flamestrike","fire_blast","cone_of_cold","blast_wave","pyroblast","ice_barrier","polymorph"},
    WARLOCK={"shadow_bolt","corruption","immolate","curse_of_agony","rain_of_fire","hellfire","death_coil","searing_pain","drain_life","fear","soul_fire","demonic_empowerment"},
    DRUID={"wrath","moonfire","starfire","hurricane","insect_swarm","entangling_roots","rejuvenation","regrowth","thorns","swipe","faerie_fire","shred"},
}
local CODEX_ORDER,LISTED={},{}
for _,jewel in ipairs(E.LEGENDARY or {}) do LISTED[jewel.class..":"..jewel.spell]=true end
for class,spells in pairs(CODEX) do
    for order,spell in ipairs(spells) do
        CODEX_ORDER[spell]=order
        if not LISTED[class..":"..spell] then
            LISTED[class..":"..spell]=true
            table.insert(E.LEGENDARY,{class=class,spell=spell,key="legendary."..spell,placeholder=true})
        end
    end
end
-- Spells missing from the skill pools below.
local EXTRA_ICONS={lightwell="Spell_Holy_SummonLightwell",rockbiter="Spell_Nature_RockBiter"}
local function Learn(loadout,class)
    if type(loadout)~="table" or type(loadout.sources)~="table" or type(nfUIDB)~="table" then return end
    for _,entry in ipairs(loadout.runJewelry or {}) do
        local key=entry.sourceKey
        local _,_,spell=string.find(type(key)=="string" and key or "","legendary[:%.]([%a_]+)")
        local source=key and loadout.sources[key]
        if spell and not STATIC_LEGEND[spell] and type(source)=="table" then
            if type(nfUIDB.legendLearned)~="table" then nfUIDB.legendLearned={} end
            local path=type(source.icon)=="table" and source.icon.path
            local known=nfUIDB.legendLearned[spell] or {}
            known.name=source.name or known.name;known.icon=path or known.icon;known.class=class or known.class
            nfUIDB.legendLearned[spell]=known
        end
    end
end
local function ActorClass(loadout,owner)
    local actor=type(loadout.actors)=="table" and loadout.actors[owner or loadout.ownerId]
    return type(actor)=="table" and type(actor.classKey)=="string" and string.upper(actor.classKey) or nil
end
local function FillLoadout(holder,runId,owner,withSkills)
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=runId,ownerId=owner})
    if type(loadout)~="table" or type(loadout.sources)~="table" then return false end
    pcall(Learn,loadout,ActorClass(loadout,owner))
    local count,x,y=0,0,0
    local function Place(entry)
        local source=entry.sourceKey and loadout.sources[entry.sourceKey]
        local path=source and type(source.icon)=="table" and source.icon.path
        if not path then return end
        if x>=(holder.perRow or ALLY_PER_ROW) then x=0;y=y+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",x*(ALLY_SIZE+ALLY_GAP),-y*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture(path);icon.label=source.name;icon.rankValue=source.rank
        local known=source.localizationKey and JewelByKey[source.localizationKey]
        icon.effect=known and JewelEffect(known) or nil
        icon.kindText=known and KindText(known.kind) or nil
        icon.rank:SetText(source.rank or "");icon:SetAlpha(1);icon:Show()
        x=x+1
    end
    if withSkills then
        for _,entry in ipairs(loadout.abilities or {}) do
            if entry.learned and entry.selected and not entry.passive then Place(entry) end
        end
        if x>0 then x=0;y=y+1 end
    end
    -- Only what matters in a run: gear with its own effects, and the run's jewelry. Starter gear is left out.
    for _,entry in ipairs(loadout.equipment or {}) do
        if entry.occupied and type(entry.effectSourceKeys)=="table" and table.getn(entry.effectSourceKeys)>0 then Place(entry) end
    end
    -- Local tweak: jewelry in fixed cells, with empty cells for what is not picked yet.
    local function PlaceEmpty(texture,label)
        if x>=(holder.perRow or ALLY_PER_ROW) then x=0;y=y+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",x*(ALLY_SIZE+ALLY_GAP),-y*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture(texture);icon.label=label;icon.rankValue=nil;icon.effect=nil
        icon.rank:SetText("");icon:SetAlpha(0.45);icon:Show()
        x=x+1
    end
    local byCategory={}
    for _,entry in ipairs(loadout.runJewelry or {}) do
        local kind=entry.category or "other"
        byCategory[kind]=byCategory[kind] or {}
        table.insert(byCategory[kind],entry)
    end
    for _,cell in ipairs(JEWEL_CELLS) do
        local list=byCategory[cell[1]] or {}
        for index=1,math.max(cell[2],table.getn(list)) do
            if list[index] then Place(list[index]) else PlaceEmpty(cell[3],E.Text(cell[4],cell[5])) end
        end
    end
    for _,entry in ipairs(byCategory.other or {}) do Place(entry) end
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    return count>0
end
local function Context()
    local context=AZS_GetMeterContext()
    if type(context)=="table" and context.runId then return context end
    return nil
end
local function ShowAlly(holder)
    local context=Context()
    if not context then return false end
    local owner=AllyOwnerId(UnitName("target"),context)
    if not owner then return false end
    return FillLoadout(holder,context.runId,owner,true)
end
local function ShowOwn(holder)
    local context=Context()
    if not context or not context.localOwnerId then return false end
    return FillLoadout(holder,context.runId,context.localOwnerId,false)
end
-- An English label for clients not in Russian: "frost_nova" reads "Frost Nova".
local function EnglishName(key)
    return (string.gsub(string.gsub(key,"_"," "),"(%a)([%w]*)",function(first,rest) return string.upper(first)..rest end))
end
-- The skills still in the pool. They stay up once the six are picked, fainter.
-- A pool's icon can be clicked to mark it as banished; a marked one is crossed out.
local function MarkBanish(icon,key,alpha,picked)
    icon.banishKey=key
    -- What is already picked has a green edge.
    if picked and not icon.pickedEdge then icon.pickedEdge=E.Edge(icon,E.COLORS.green[1],E.COLORS.green[2],E.COLORS.green[3],1) end
    if icon.pickedEdge then
        if picked then icon.pickedEdge.SetSize(E.Size("pickedEdgeSize",2));icon.pickedEdge.Show() else icon.pickedEdge.Hide() end
    end
    local marked=E.On("banishMarks") and E.IsBanished(key)
    if marked and not icon.cross then icon.cross=E.BanishCross(icon) end
    if icon.cross then if marked then icon.cross:Show() else icon.cross:Hide() end end
    icon:SetAlpha(marked and 0.6 or alpha)
end
-- The class is checked against what was really picked: the game's word, then the run's, and in the end whichever
-- class's pool holds the most of the picked skills.
function E.CheckClass(class,picked)
    if not class and type(AZS_ZONE)=="table" and type(AZS_ZONE.class)=="string" then class=string.upper(AZS_ZONE.class) end
    local function Holds(name)
        local held=0
        for _,skill in ipairs(SKILL_POOL[name] or {}) do if picked[skill[1]] then held=held+1 end end
        return held
    end
    local total=0
    for _ in pairs(picked) do total=total+1 end
    if class and SKILL_POOL[class] and Holds(class)*2>=total then return class end
    local best,bestHeld=class,0
    for name in pairs(SKILL_POOL) do
        local held=Holds(name)
        if held>bestHeld then best,bestHeld=name,held end
    end
    return best
end
-- The pools grow upward from the chat, as many rows as they have.
local function FitRows(holder,rows)
    holder.frame:SetHeight(math.max(1,rows*(ALLY_SIZE+ALLY_GAP)))
end
local function ShowPool(holder)
    local foldedPool=E.IsCollapsed("pool")
    local context=Context()
    if not context then return false end
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
    if type(loadout)~="table" then return false end
    -- The run's hero decides the class: the character's own class may be a different one.
    local hero=type(loadout.actors)=="table" and loadout.actors[loadout.ownerId or context.localOwnerId]
    local class=type(hero)=="table" and type(hero.classKey)=="string" and string.upper(hero.classKey)
    local picked,total={},0
    for _,entry in ipairs(loadout.abilities or {}) do
        if entry.selected and type(entry.sourceKey)=="string" then
            local _,_,key=string.find(entry.sourceKey,"^ability:([%w_]+):")
            if key then picked[key]=true end
        end
    end
    class=E.CheckClass(class,picked)
    local pool=class and SKILL_POOL[class]
    if not pool then return false end
    for _,skill in ipairs(pool) do if picked[skill[1]] then total=total+1 end end
    local alpha=total>=POOL_PICKS and 0.35 or 0.8
    -- What is picked on its own row, what can still come up below.
    local count,column,row=0,0,0
    local function Place(skill,isPicked)
        if column>=POOL_PER_ROW then column=0;row=row+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",column*(ALLY_SIZE+ALLY_GAP),-row*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture("Interface\\Icons\\"..skill[3]);icon.rankValue=nil
        -- Only in the client's own language: another language's text would break the page.
        local described=E.SKILL_TEXT[skill[1]]
        icon.effect=described and described[GetCVar("azsLanguage")] or nil
        icon.label=E.Pick(E.SKILL_NAMES[skill[1]]) or (E.IsRussian() and skill[2]) or EnglishName(skill[1])
        icon.rank:SetText("")
        MarkBanish(icon,"spell:"..skill[1],isPicked and 1 or alpha,isPicked);icon:Show()
        column=column+1
    end
    for _,skill in ipairs(pool) do if picked[skill[1]] then Place(skill,true) end end
    if column>0 then column=0;row=row+1 end
    -- Folded, only what is picked remains.
    if not foldedPool then
        for _,skill in ipairs(pool) do if not picked[skill[1]] then Place(skill,false) end end
    end
    local usedRows=column>0 and row+1 or row
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    FitRows(holder,usedRows)
    return count>0
end
-- The jewelry, compact: a row for each kind, and in every row the same order of effects, so that like stands near
-- like: damage first, then survival, then utility. What is worn keeps its place, with a green edge. Rings and trinkets
-- dim once both slots are full; an amulet can always replace the one worn. Dimmed icons can still be read.
local SLOTS={ring=2,trinket=2}
local KIND_ORDER={"ring","trinket","amulet"}
local COLUMN_ORDER={"dmg","crit","critdmg","cd","echo","area","dot","hp","dr","regen","leech","killheal","lives","speed","pickup","xp","gold","luck","buff","special"}
local function ShowJewelPool(holder)
    local foldedPool=E.IsCollapsed("jewelPool")
    local context=Context()
    if not context then return false end
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
    if type(loadout)~="table" then return false end
    local worn,held={},{}
    for _,entry in ipairs(loadout.runJewelry or {}) do
        -- The name lives on the entry's source; the source key holds it too, such as "jewel:accuria:r2".
        local source=entry.sourceKey and type(loadout.sources)=="table" and loadout.sources[entry.sourceKey]
        local key=entry.localizationKey or (type(source)=="table" and source.localizationKey)
        if not key and type(entry.sourceKey)=="string" then
            local _,_,group,name=string.find(entry.sourceKey,"(%a+):([%w_]+)")
            if group=="run" then _,_,group,name=string.find(entry.sourceKey,"run:(%a+):([%w_]+)") end
            if group and name then key=group.."."..name end
        end
        if key then worn[key]=true end
        local kind=entry.category or "other"
        held[kind]=(held[kind] or 0)+1
    end
    local count,row=0,0
    -- The legendary amulets of the hero's class, first. They come up once the hero knows their spell.
    local hero=type(loadout.actors)=="table" and loadout.actors[loadout.ownerId or context.localOwnerId]
    local class=type(hero)=="table" and type(hero.classKey)=="string" and string.upper(hero.classKey)
    local known={}
    for _,entry in ipairs(loadout.abilities or {}) do
        if entry.selected and type(entry.sourceKey)=="string" then
            local _,_,key=string.find(entry.sourceKey,"^ability:([%w_]+):")
            if key then known[key]=true end
        end
    end
    class=E.CheckClass(class,known)
    pcall(Learn,loadout,class)
    local legendaryColumn=0
    local showLegend=E.On("legendRow")
    local skillNames,skillIcons={},{}
    for _,skill in ipairs(SKILL_POOL[class or ""] or {}) do
        skillNames[skill[1]]=E.IsRussian() and skill[2] or EnglishName(skill[1]);skillIcons[skill[1]]=skill[3]
    end
    -- A legendary comes up only once its spell is picked: those first and bright, the rest after them and pale.
    local legends={}
    for _,jewel in ipairs(E.LEGENDARY or {}) do
        if showLegend and jewel.class==class and not foldedPool then table.insert(legends,jewel) end
    end
    table.sort(legends,function(a,b)
        local ka,kb=known[a.spell] and 1 or 0,known[b.spell] and 1 or 0
        if ka~=kb then return ka>kb end
        return (CODEX_ORDER[a.spell] or 99)<(CODEX_ORDER[b.spell] or 99)
    end)
    local learnedAll=type(nfUIDB.legendLearned)=="table" and nfUIDB.legendLearned or {}
    for _,jewel in ipairs(legends) do
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",legendaryColumn*(ALLY_SIZE+ALLY_GAP),0)
        icon.rankValue=nil;icon.kindText=KindText("amulet");icon.rank:SetText("")
        local spellName=skillNames[jewel.spell] or EnglishName(jewel.spell) or jewel.spell
        local learned=type(learnedAll[jewel.spell])=="table" and learnedAll[jewel.spell] or nil
        if jewel.placeholder then
            icon.texture:SetTexture((learned and learned.icon) or ("Interface\\Icons\\"..(skillIcons[jewel.spell] or EXTRA_ICONS[jewel.spell] or "INV_Jewelry_Necklace_01")))
            icon.label=(learned and learned.name) or E.Text("Легендарный амулет","Legendary amulet")
            icon.effect=E.Text("Переделывает скил «","Remakes ")..spellName..E.Text("»","")
        else
            icon.texture:SetTexture("Interface\\Icons\\"..jewel.icon)
            icon.label=E.Pick(jewel.name);icon.effect=E.Pick(jewel.effect) or (E.Text("Переделывает скил «","Remakes ")..spellName..E.Text("»",""))
        end
        if known[jewel.spell] then icon.effect=icon.effect.."\n|cff7fd67f"..E.Text("Может выпасть: скил взят","Can drop: the spell is picked").."|r"
        else icon.effect=icon.effect.."\n|cff8a8a96"..E.Text("Выпадет, только если взять «","Drops only once you pick ")..spellName..E.Text("»","").."|r" end
        MarkBanish(icon,jewel.key,known[jewel.spell] and 1 or 0.35,worn[jewel.key] and true or false);icon:Show()
        legendaryColumn=legendaryColumn+1
    end
    -- And those learned in play that the Codex list does not hold.
    for spell,jewel in pairs(showLegend and not foldedPool and learnedAll or {}) do
        if type(jewel)=="table" and jewel.class==class and jewel.icon and not LISTED[(class or "")..":"..spell] then
            count=count+1
            local icon=LoadoutIcon(holder,count)
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",legendaryColumn*(ALLY_SIZE+ALLY_GAP),0)
            icon.texture:SetTexture(jewel.icon);icon.rankValue=nil
            icon.label=jewel.name or spell
            icon.effect=E.Text("Легендарный амулет · скилл «","Legendary amulet · skill ")..(skillNames[spell] or spell)..E.Text("»","")
            icon.kindText=KindText("amulet");icon.rank:SetText("")
            MarkBanish(icon,"legendary."..spell,known[spell] and 1 or 0.35,worn["legendary."..spell] and true or false);icon:Show()
            legendaryColumn=legendaryColumn+1
        end
    end
    if legendaryColumn>0 then row=1 end
    -- Folded, only what is worn remains, on one row.
    local foldedColumn=0
    for _,kind in ipairs(KIND_ORDER) do
        local full=SLOTS[kind] and (held[kind] or 0)>=SLOTS[kind]
        local column=foldedPool and foldedColumn or 0
        for _,effect in ipairs(COLUMN_ORDER) do
            for _,jewel in ipairs(E.JEWELS) do
                if jewel.kind==kind and jewel.col==effect and (not foldedPool or worn[jewel.key]) then
                    if column>=JEWEL_PER_ROW then column=0;row=row+1 end
                    count=count+1
                    local icon=LoadoutIcon(holder,count)
                    icon:ClearAllPoints()
                    icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",column*(ALLY_SIZE+ALLY_GAP),-row*(ALLY_SIZE+ALLY_GAP))
                    icon.texture:SetTexture("Interface\\Icons\\"..jewel.icon);icon.rankValue=nil
                    icon.label=E.Pick(jewel.name)
                    icon.effect=JewelEffect(jewel);icon.kindText=KindText(jewel.kind)
                    icon.rank:SetText("")
                    local isWorn=worn[jewel.key] and true or false
                    MarkBanish(icon,jewel.key,isWorn and 1 or (full and 0.3 or 0.8),isWorn);icon:Show()
                    column=column+1
                end
            end
        end
        if foldedPool then foldedColumn=column elseif column>0 then row=row+1 end
    end
    if foldedPool and foldedColumn>0 then row=1 end
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    FitRows(holder,row)
    return count>0
end
local function NewHolder(frame)
    return {frame=frame,icons={}}
end
local function Refresh(holder,show)
    local ok,shown=pcall(show,holder)
    if ok and shown then holder.frame:Show() else E.Conceal(holder.frame) end
    return ok and shown
end

local allyHolder,ownHolder,poolHolder,jewelHolder
-- Each ally's skills and jewelry, always in view, under their frame at the left wall of the screen.
local partyHolders={}
local function PartyHolder(index)
    local holder=partyHolders[index]
    if holder then return holder end
    local bar=getglobal("PartyMemberFrame"..index.."ManaBar")
    if not bar then return nil end
    local frame=CreateFrame("Frame","nfUIPartyLoadout"..index,UIParent)
    frame:SetWidth(240);frame:SetHeight(19);frame:SetPoint("TOPLEFT",bar,"BOTTOMLEFT",-1,-3);frame:Hide()
    holder={frame=frame,icons={},perRow=13}
    partyHolders[index]=holder
    return holder
end
local function UpdateParty()
    for index=1,4 do
        local unit="party"..index
        local holder=PartyHolder(index)
        if holder then
            if E.On("partyLoadout") and UnitExists(unit) then
                local bar=getglobal("PartyMemberFrame"..index.."ManaBar")
                holder.frame:SetScale(0.8*bar:GetEffectiveScale()/UIParent:GetEffectiveScale())
                Refresh(holder,function(one)
                    local context=Context()
                    if not context then return false end
                    local owner=AllyOwnerId(UnitName(unit),context)
                    if not owner then return false end
                    return FillLoadout(one,context.runId,owner,true)
                end)
            else holder.frame:Hide() end
        end
    end
end
-- These calls ask the game for a lot, and a refused one sends a request to the server, so they
-- wait for a run in progress and back off while the game is not ready.
local RUN_PHASES={playing=true,choosing=true,paused=true}
local age,wait=0,5
local driver=CreateFrame("Frame","nfUIAllyLoadout")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:SetScript("OnEvent",function() age=wait;ownerByName={} end)
driver:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<wait then return end;age=0
    if not RUN_PHASES[AZS_GetPhase and AZS_GetPhase() or ""] then wait=3;return end
    local C=nfUIConfig
    if not E.totFrame or not C or not C.row then return end
    if not allyHolder then
        allyHolder=NewHolder(E.blocks.ally)
        ownHolder=NewHolder(E.blocks.own)
        poolHolder=NewHolder(E.blocks.pool)
        jewelHolder=NewHolder(E.blocks.jewelPool)
        E.Collapsible(E.blocks.pool,"pool",E.Text("Пул скилов","Skill pool"),function() E.RefreshPools() end,true)
        E.Collapsible(E.blocks.jewelPool,"jewelPool",E.Text("Пул бижутерии","Jewelry pool"),function() E.RefreshPools() end,true)
        function E.RefreshPools()
            if E.On("skillPool") then Refresh(poolHolder,ShowPool) end
            if E.On("jewelPool") then Refresh(jewelHolder,ShowJewelPool) end
        end
    end
    local isAlly=UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target","player") and not UnitCanAttack("player","target")
    UpdateParty()
    if isAlly and E.On("allyLoadout") then Refresh(allyHolder,ShowAlly) else E.Conceal(allyHolder.frame) end
    if E.On("skillPool") then Refresh(poolHolder,ShowPool) else E.Conceal(poolHolder.frame) end
    if E.On("jewelPool") then Refresh(jewelHolder,ShowJewelPool) else E.Conceal(jewelHolder.frame) end
    if E.On("ownLoadout") then wait=Refresh(ownHolder,ShowOwn) and 4 or 10 else E.Conceal(ownHolder.frame);wait=4 end
end)
