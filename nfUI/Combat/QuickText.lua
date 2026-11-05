-- Small, pooled damage labels share the localized parser with icon combat text.
local C,W=nfUIConfig,nfUIWidgets
local layer=CreateFrame("Frame","nfUIDamage",UIParent)
layer:SetAllPoints(UIParent);layer:SetFrameStrata("HIGH")
local pool={}
local events={"CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","CHAT_MSG_COMBAT_PET_HITS","CHAT_MSG_SPELL_PET_DAMAGE","CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE","COMBAT_TEXT_UPDATE"}
local incoming={DAMAGE=true,DAMAGE_CRIT=true,SPELL_DAMAGE=true}
local originTurn=0
local function Origin(name)
    if name then
        -- Enemies of one name take turns, so their numbers do not all land on the first plate.
        local plates={}
        for _,entry in ipairs(nfUIPlatesRegistry or {}) do
            if entry.plate:IsVisible() and entry.stock.name:GetText()==name then table.insert(plates,entry) end
        end
        local total=table.getn(plates)
        if total>0 then
            originTurn=originTurn+1
            local region=plates[math.mod(originTurn,total)+1].bar
            local x,y=region:GetCenter()
            if x and y then local factor=C.RegionEffectiveScale(region)/UIParent:GetEffectiveScale();return x*factor,y*factor,true end
        end
        -- No plate: the enemy's own place on screen, from the game's anchors.
        local x,y=nfUIEdit.EnemySpot(name)
        if x then return x,y,true end
    end
    return UIParent:GetWidth()/2,UIParent:GetHeight()/2+(name and 30 or -15),false
end
-- A small skill icon beside the number, from the hero's spellbook.
local spellIcons
local function SpellIcon(spell)
    if not spell or spell=="" then return nil end
    if not spellIcons then
        spellIcons={}
        local index=1
        while true do
            local known=GetSpellName(index,"spell")
            if not known then break end
            spellIcons[known]=GetSpellTexture(index,"spell")
            index=index+1
        end
    end
    return spellIcons[spell]
end
-- Readable numbers: short format, repeat hits merged, and each target's numbers fanned out.
local function ShortAmount(value)
    value=tonumber(value) or 0
    if value>=1000000 then return string.format("%.1fm",value/1000000) end
    if value>=10000 then return string.format("%.0fk",value/1000) end
    if value>=1000 then return string.format("%.1fk",value/1000) end
    return string.format("%.0f",value)
end
-- Calm on purpose: hits merge for longer, the numbers stay close together and move slowly.
local MERGE_TIME=0.5
local LANES={0,-18,18}
local LANE_COUNT=6
-- The bigger the hit compared with recent ones, the larger the number and the longer it stays.
local peak=0
local function Weight(value)
    peak=math.max(value,peak*0.995)
    return peak>0 and math.sqrt(value/peak) or 0
end
local function Emphasize(state,periodic)
    local weight=Weight(state.amount or 0)
    state.life=(state.critical and 1.3 or 1.0)+1.0*weight
    state.label:SetFont(W.font,(periodic and 10 or 11)+(state.critical and 2 or 0)+8*weight,"OUTLINE")
end
local laneByTarget={}
local CROWD=14
local function Emit(amount,name,critical,periodic,spell)
    if name then nfUIEdit.TargetHit(amount,name,SpellIcon(spell)) end
    local now=GetTime()
    local x,y,placed=Origin(name)
    -- Hits on enemies that cannot be placed all become one number, instead of a pile in the middle of the screen.
    local key=(placed or not name) and ((name or "self").."|"..(spell or "")) or "unplaced"
    if key=="unplaced" then spell=nil end
    -- In a crowd the small numbers give way, so the big ones can be read.
    local active=0
    for _,entry in ipairs(pool) do if entry.active then active=active+1 end end
    if active>=CROWD and not critical and (tonumber(amount) or 0)<peak*0.35 then return end
    for _,entry in ipairs(pool) do
        if entry.active and entry.key==key and now-entry.born<MERGE_TIME then
            entry.amount=(entry.amount or 0)+(tonumber(amount) or 0)
            entry.label:SetText((name and "" or "-")..ShortAmount(entry.amount))
            Emphasize(entry,periodic)
            return
        end
    end
    local state
    for _,entry in ipairs(pool) do if not entry.active then state=entry;break end end
    if not state then
        if table.getn(pool)>=24 then return end
        state={label=layer:CreateFontString(nil,"OVERLAY")};table.insert(pool,state)
        state.icon=layer:CreateTexture(nil,"OVERLAY");state.icon:SetTexCoord(0.07,0.93,0.07,0.93)
        state.icon:SetWidth(14);state.icon:SetHeight(14);state.icon:SetPoint("RIGHT",state.label,"LEFT",-2,0);state.icon:Hide()
    end
    state.active=true;state.settled=nil;state.born=GetTime();state.life=critical and 1.5 or 1.2
    local target=name or "self"
    local lane=math.mod((laneByTarget[target] or 0),LANE_COUNT)+1
    laneByTarget[target]=lane
    state.key=key;state.amount=tonumber(amount) or 0
    state.x=x+LANES[math.mod(lane-1,3)+1];state.y=y+math.floor((lane-1)/3)*14;state.drift=0
    state.rise=(name and 1 or -1)*28;state.critical=critical
    local color=not name and {1,0.22,0.22} or critical and {1,0.76,0.08} or periodic and {0.8,0.8,0.8} or {1,1,1}
    local label=state.label
    Emphasize(state,periodic)
    label:SetText((name and "" or "-")..ShortAmount(amount))
    label:SetTextColor(unpack(color));label:SetAlpha(1);label:Show()
    local texture=name and SpellIcon(spell)
    if texture then state.icon:SetTexture(texture);state.icon:SetAlpha(1);state.icon:Show() else state.icon:Hide() end
end
layer:SetScript("OnUpdate",function()
    local now=GetTime()
    for _,state in ipairs(pool) do if state.active then
        local elapsed=now-state.born;local t=elapsed/state.life
        if t>=1 then state.active=false;state.label:Hide();state.icon:Hide()
        else
            local ease=t
            state.label:ClearAllPoints();state.label:SetPoint("CENTER",UIParent,"BOTTOMLEFT",state.x+state.drift*ease,state.y+state.rise*ease)
            local fade=math.min(1,(1-t)/0.6);state.label:SetAlpha(fade*fade);state.icon:SetAlpha(fade*fade)
        end
    end end
end)
local reader=CreateFrame("Frame","nfUIQuickTextEvents",UIParent)
reader:SetScript("OnEvent",function()
    if event=="COMBAT_TEXT_UPDATE" then
        -- The hero's own damage has its slow column above the health bar; this is for when that is off.
        if incoming[arg1] and tonumber(arg2) and not nfUIEdit.On("risingDamage") then Emit(arg2,nil,arg1=="DAMAGE_CRIT") end
    else
        local parser=nfUIModules.tools.ParseNameplateCombatEvent
        local hit=parser and parser(event,arg1 or "")
        if hit and hit.kind=="damage" and hit.targetName and hit.targetName~="" then Emit(hit.amount,hit.targetName,hit.critical,hit.damageType=="periodic",hit.spell) end
    end
end)
function C.ApplyQuickText()
    local db=C.Settings();local on=db.damageText and db.damageMode~="default" and db.damageMode~="off"
    for _,name in ipairs(events) do
        if on and (db.damageMode=="quick" or name=="COMBAT_TEXT_UPDATE") then reader:RegisterEvent(name) else reader:UnregisterEvent(name) end
    end
    SetCVar("CombatDamage",db.damageMode=="default" and "1" or "0")
    for name in pairs(incoming) do if COMBAT_TEXT_TYPE_INFO and COMBAT_TEXT_TYPE_INFO[name] then COMBAT_TEXT_TYPE_INFO[name].show=not on and 1 or nil end end
    if not on then for _,state in ipairs(pool) do state.active=false;state.label:Hide();state.icon:Hide() end end
end
local loader=CreateFrame("Frame",nil,UIParent)
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("SPELLS_CHANGED")
loader:SetScript("OnEvent",function()
    if event=="SPELLS_CHANGED" then spellIcons=nil
    elseif arg1=="Blizzard_CombatText" then C.ApplyQuickText() end
end)
