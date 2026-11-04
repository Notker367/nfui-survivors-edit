-- Small, pooled damage labels share the localized parser with icon combat text.
local C,W=nfUIConfig,nfUIWidgets
local layer=CreateFrame("Frame","nfUIDamage",UIParent)
layer:SetAllPoints(UIParent);layer:SetFrameStrata("HIGH")
local pool={}
local events={"CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","CHAT_MSG_COMBAT_PET_HITS","CHAT_MSG_SPELL_PET_DAMAGE","CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE","COMBAT_TEXT_UPDATE"}
local incoming={DAMAGE=true,DAMAGE_CRIT=true,SPELL_DAMAGE=true}
local function Origin(name)
    if name then
        for _,entry in ipairs(nfUIPlatesRegistry or {}) do
            if entry.plate:IsVisible() and entry.stock.name:GetText()==name then
                local region=entry.bar
                local x,y=region:GetCenter()
                if x and y then local factor=C.RegionEffectiveScale(region)/UIParent:GetEffectiveScale();return x*factor,y*factor end
            end
        end
    end
    return UIParent:GetWidth()/2,UIParent:GetHeight()/2+(name and 30 or -15)
end
-- Local tweak: a small skill icon beside the number, from the hero's spellbook.
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
-- Local tweak: readable numbers: short format, repeat hits merged, and each target's numbers fanned out.
local function ShortAmount(value)
    value=tonumber(value) or 0
    if value>=1000000 then return string.format("%.1fm",value/1000000) end
    if value>=10000 then return string.format("%.0fk",value/1000) end
    if value>=1000 then return string.format("%.1fk",value/1000) end
    return string.format("%.0f",value)
end
local MERGE_TIME=0.3
local LANES={0,-34,34,-17,17}
local laneByTarget={}
local function Emit(amount,name,critical,periodic,spell)
    local key=(name or "self").."|"..(spell or "")
    local now=GetTime()
    for _,entry in ipairs(pool) do
        if entry.active and entry.key==key and now-entry.born<MERGE_TIME then
            entry.amount=(entry.amount or 0)+(tonumber(amount) or 0)
            entry.label:SetText((name and "" or "-")..ShortAmount(entry.amount))
            entry.born=now;entry.label:SetAlpha(1);entry.icon:SetAlpha(1)
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
    local x,y=Origin(name)
    state.active=true;state.settled=nil;state.born=GetTime();state.life=critical and 0.715 or 0.55
    local target=name or "self"
    local lane=math.mod((laneByTarget[target] or 0),table.getn(LANES))+1
    laneByTarget[target]=lane
    state.key=key;state.amount=tonumber(amount) or 0
    state.x=x+LANES[lane];state.y=y+math.mod(lane,3)*9;state.drift=LANES[lane]*0.25
    state.rise=(name and 1 or -1)*(critical and 80.6 or 62);state.critical=critical
    local color=not name and {1,0.22,0.22} or critical and {1,0.76,0.08} or periodic and {0.8,0.8,0.8} or {1,1,1}
    local label=state.label
    label:SetFont(W.font,critical and 18 or periodic and 11 or 12,"OUTLINE")
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
            local ease=t*(2-t)
            if state.critical and elapsed>=0.09 and not state.settled then state.label:SetFont(W.font,15,"OUTLINE");state.settled=true end
            state.label:ClearAllPoints();state.label:SetPoint("CENTER",UIParent,"BOTTOMLEFT",state.x+state.drift*ease,state.y+state.rise*ease)
            state.label:SetAlpha(math.min(1,(1-t)/0.34));state.icon:SetAlpha(math.min(1,(1-t)/0.34))
        end
    end end
end)
local reader=CreateFrame("Frame","nfUIQuickTextEvents",UIParent)
reader:SetScript("OnEvent",function()
    if event=="COMBAT_TEXT_UPDATE" then
        if incoming[arg1] and tonumber(arg2) then Emit(arg2,nil,arg1=="DAMAGE_CRIT") end
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
