-- Rising numbers in slow columns: the damage the hero takes and the active healing beside it, above the health bar,
-- and the hero's hits above the target's. The totals come from the run's own data, so they do not depend on the
-- client's language; the hits on the target come from the combat log, matched by name.
local E=nfUIEdit
local LIFE,START=2.6,3
-- Hits this close together become one number, so a column stays readable.
local MERGE=0.8
local EXTRA_FONT,EXTRA_LIFE=10,1.4
local columns={}

local function Column(block,color,prefix,x,weigh)
    local column={block=block,color=color,prefix=prefix,x=x,weigh=weigh,pool={}}
    table.insert(columns,column)
    return column
end
local function Free(column)
    for _,entry in ipairs(column.pool) do
        if not entry.age then return entry end
    end
    local entry={label=column.block:CreateFontString(nil,"OVERLAY"),icon=column.block:CreateTexture(nil,"OVERLAY")}
    entry.label:SetTextColor(column.color[1],column.color[2],column.color[3])
    entry.label:SetShadowColor(0,0,0,0.9);entry.label:SetShadowOffset(1,-1)
    entry.icon:SetWidth(16);entry.icon:SetHeight(16);entry.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    entry.icon:SetPoint("RIGHT",entry.label,"LEFT",-2,0);entry.icon:Hide()
    table.insert(column.pool,entry)
    return entry
end
local function Dress(column,entry)
    local weight=math.max(0,math.min(1,column.weigh(entry.amount)))
    entry.life=LIFE+EXTRA_LIFE*weight
    entry.label:SetFont(E.FONT,E.Size("risingFont",13)+EXTRA_FONT*weight,"OUTLINE")
    entry.label:SetText(column.prefix..E.Short(entry.amount))
end
local function Pop(column,amount,texture)
    local newest=column.newest
    if newest and newest.age and newest.age<MERGE then
        newest.amount=newest.amount+amount
        Dress(column,newest)
    else
        newest=Free(column);column.newest=newest
        newest.age=0;newest.amount=amount
        Dress(column,newest)
        newest.label:SetAlpha(1);newest.label:ClearAllPoints()
        newest.label:SetPoint("BOTTOM",column.block,"BOTTOM",column.x,START);newest.label:Show()
    end
    if texture then
        newest.icon:SetTexture(texture);newest.icon:SetAlpha(1);newest.icon:Show()
    elseif newest.age==0 then newest.icon:Hide() end
end

-- A quarter of the hero's health is the most a number can weigh.
local function ByHealth(amount)
    local most=UnitHealthMax("player") or 0
    return most>0 and math.sqrt(amount/(most*0.25)) or 0
end
-- On the target, against the strongest recent hit.
local peak=0
local function ByRecent(amount)
    peak=math.max(amount,peak*0.995)
    return peak>0 and math.sqrt(amount/peak) or 0
end
local taken=Column(E.blocks.rising,E.COLORS.enemy,"-",0,ByHealth)
local healed=Column(E.blocks.rising,E.COLORS.green,"+",48,ByHealth)
local dealt=Column(E.blocks.targetRising,{1,1,1},"",0,ByRecent)

-- Called for each hit of the hero's that the combat log names.
function E.TargetHit(amount,name,texture)
    if not E.On("targetRising") or not name or name~=UnitName("target") then return end
    local value=tonumber(amount)
    if value and value>0 then Pop(dealt,value,texture) end
end

-- Regeneration is passive, and has its own number at the end of the health bar.
local PASSIVE={Regeneration=true,["Восполнение"]=true,["Регенерация"]=true}
local function ActiveHealing()
    local total=0
    for _,line in ipairs(type(AZS_HEALING)=="table" and AZS_HEALING or {}) do
        if type(line)=="table" and not PASSIVE[line.name] then total=total+(tonumber(line.dmg) or 0) end
    end
    return total
end
local lastTaken,lastHealed,lastRun
local ticker=CreateFrame("Frame","nfUIEditRising")
ticker:SetScript("OnUpdate",function()
    local elapsed=arg1 or 0
    local run=type(AZS_ZONE)=="table" and AZS_ZONE.run
    if run~=lastRun then lastRun=run;lastTaken=nil;lastHealed=nil end
    local totalTaken=type(AZS_RUN)=="table" and tonumber(AZS_RUN.taken)
    if totalTaken then
        if lastTaken and totalTaken-lastTaken>=1 and E.On("risingDamage") then Pop(taken,totalTaken-lastTaken) end
        lastTaken=totalTaken
    end
    if type(AZS_HEALING)=="table" then
        local totalHealed=ActiveHealing()
        if lastHealed and totalHealed-lastHealed>=1 and E.On("risingHeal") then Pop(healed,totalHealed-lastHealed) end
        lastHealed=totalHealed
    end
    for _,column in ipairs(columns) do
        for _,entry in ipairs(column.pool) do
            if entry.age then
                entry.age=entry.age+elapsed
                if entry.age>=entry.life then
                    entry.age=nil;entry.label:Hide();entry.icon:Hide()
                else
                    local part=entry.age/entry.life
                    entry.label:SetPoint("BOTTOM",column.block,"BOTTOM",column.x,START+E.Size("risingHeight",42)*part)
                    -- Solid at first, then it dissolves ever more gently.
                    local fade=part<0.35 and 1 or (1-part)/0.65
                    entry.label:SetAlpha(fade*fade);entry.icon:SetAlpha(fade*fade)
                end
            end
        end
    end
end)
