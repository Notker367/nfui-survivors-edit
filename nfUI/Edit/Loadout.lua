-- Skills and jewelry panels: an ally's under the target frame, the hero's under the skills, and the
-- class's skill pool. What the game's loadout API returns is shown; it does not list banished cards.
local E=nfUIEdit
local ALLY_SIZE,ALLY_GAP,ALLY_PER_ROW=19,2,9
local POOL_PICKS=6
-- The pools are as wide as the chat they stand over.
local POOL_PER_ROW=16
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
    local text=jewel.effect[E.IsRussian() and 1 or 2]
    return text~="" and text or nil
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
local function FillLoadout(holder,runId,owner,withSkills)
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=runId,ownerId=owner})
    if type(loadout)~="table" or type(loadout.sources)~="table" then return false end
    local count,x,y=0,0,0
    local function Place(entry)
        local source=entry.sourceKey and loadout.sources[entry.sourceKey]
        local path=source and type(source.icon)=="table" and source.icon.path
        if not path then return end
        if x>=ALLY_PER_ROW then x=0;y=y+1 end
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
        if x>=ALLY_PER_ROW then x=0;y=y+1 end
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
    if icon.pickedEdge then if picked then icon.pickedEdge.Show() else icon.pickedEdge.Hide() end end
    local marked=E.On("banishMarks") and E.IsBanished(key)
    if marked and not icon.cross then icon.cross=E.BanishCross(icon) end
    if icon.cross then if marked then icon.cross:Show() else icon.cross:Hide() end end
    icon:SetAlpha(marked and 0.6 or alpha)
end
local function Folded(holder,key)
    if not E.IsCollapsed(key) then return false end
    for _,icon in ipairs(holder.icons) do icon:Hide() end
    holder.frame:SetHeight(1)
    return true
end
-- The pools grow upward from the chat, as many rows as they have.
local function FitRows(holder,rows)
    holder.frame:SetHeight(math.max(1,rows*(ALLY_SIZE+ALLY_GAP)))
end
local function ShowPool(holder)
    if Folded(holder,"pool") then return true end
    local context=Context()
    if not context then return false end
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
    if type(loadout)~="table" then return false end
    -- The run's hero decides the class: the character's own class may be a different one.
    local hero=type(loadout.actors)=="table" and loadout.actors[loadout.ownerId or context.localOwnerId]
    local class=type(hero)=="table" and type(hero.classKey)=="string" and string.upper(hero.classKey)
    local pool=class and SKILL_POOL[class]
    if not pool then return false end
    local picked,total={},0
    for _,entry in ipairs(loadout.abilities or {}) do
        if entry.selected and type(entry.sourceKey)=="string" then
            local _,_,key=string.find(entry.sourceKey,"^ability:([%w_]+):")
            if key then picked[key]=true end
        end
    end
    for _,skill in ipairs(pool) do if picked[skill[1]] then total=total+1 end end
    local alpha=total>=POOL_PICKS and 0.35 or 0.8
    -- The picked skills on top, what can still come up below.
    local count,column,row=0,0,0
    local function Place(skill,isPicked)
        if column>=POOL_PER_ROW then column=0;row=row+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",column*(ALLY_SIZE+ALLY_GAP),-row*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture("Interface\\Icons\\"..skill[3]);icon.rankValue=nil;icon.effect=nil
        icon.label=E.IsRussian() and skill[2] or EnglishName(skill[1])
        icon.rank:SetText("")
        MarkBanish(icon,"spell:"..skill[1],isPicked and 1 or alpha,isPicked);icon:Show()
        column=column+1
    end
    for _,skill in ipairs(pool) do if picked[skill[1]] then Place(skill,true) end end
    if column>0 then column=0;row=row+1 end
    for _,skill in ipairs(pool) do if not picked[skill[1]] then Place(skill,false) end end
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    FitRows(holder,column>0 and row+1 or row)
    return count>0
end
-- Every ring, trinket and amulet that can still come up. Rings and trinkets dim once their slots are full; an
-- amulet can always replace the one worn. Dimmed icons can still be read.
local SLOTS={ring=2,trinket=2}
local KIND_ORDER={"ring","trinket","amulet"}
local function ShowJewelPool(holder)
    if Folded(holder,"jewelPool") then return true end
    local context=Context()
    if not context then return false end
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
    if type(loadout)~="table" then return false end
    local worn,held={},{}
    for _,entry in ipairs(loadout.runJewelry or {}) do
        if entry.localizationKey then worn[entry.localizationKey]=true end
        local kind=entry.category or "other"
        held[kind]=(held[kind] or 0)+1
    end
    local language=E.IsRussian() and 1 or 2
    local count,row,column=0,0,0
    local function Place(jewel,alpha,isPicked)
        if column>=POOL_PER_ROW then column=0;row=row+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",column*(ALLY_SIZE+ALLY_GAP),-row*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture("Interface\\Icons\\"..jewel.icon);icon.rankValue=nil
        icon.label=jewel.name[language]
        icon.effect=JewelEffect(jewel);icon.kindText=KindText(jewel.kind)
        icon.rank:SetText("")
        MarkBanish(icon,jewel.key,alpha,isPicked);icon:Show()
        column=column+1
    end
    -- What is worn on top, then each kind on its own rows.
    for _,jewel in ipairs(E.JEWELS) do if worn[jewel.key] then Place(jewel,1,true) end end
    if column>0 then column=0;row=row+1 end
    for _,kind in ipairs(KIND_ORDER) do
        local full=SLOTS[kind] and (held[kind] or 0)>=SLOTS[kind]
        for _,jewel in ipairs(E.JEWELS) do
            if jewel.kind==kind and not worn[jewel.key] then Place(jewel,full and 0.3 or 0.8,false) end
        end
        if column>0 then column=0;row=row+1 end
    end
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
    if isAlly and E.On("allyLoadout") then Refresh(allyHolder,ShowAlly) else E.Conceal(allyHolder.frame) end
    if E.On("skillPool") then Refresh(poolHolder,ShowPool) else E.Conceal(poolHolder.frame) end
    if E.On("jewelPool") then Refresh(jewelHolder,ShowJewelPool) else E.Conceal(jewelHolder.frame) end
    if E.On("ownLoadout") then wait=Refresh(ownHolder,ShowOwn) and 4 or 10 else E.Conceal(ownHolder.frame);wait=4 end
end)
