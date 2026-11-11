-- Rising numbers in slow columns: the damage the hero takes and the active healing beside it, above the health bar,
-- and the hero's hits above the target's. The totals come from the run's own data, so they do not depend on the
-- client's language; the hits on the target come from the combat log, matched by name.
local E=nfUIEdit
local LIFE,START=2.6,3
-- Hits this close together become one number, so a column stays readable.
local MERGE=0.8
local EXTRA_FONT,EXTRA_LIFE=10,1.4
local columns={}
-- Separate hits rise beside the total and leave sooner; a crowd shows only so many at once.
-- They stand well clear of the total, each on its own line.
local HIT_LIFE,HIT_MAX,HIT_SIDE,HIT_LINE=1.3,6,50,12
local hitPools={}
local function HitLabel(block,color)
    local key=tostring(block)..tostring(color)
    local pool=hitPools[key]
    if not pool then pool={block=block,color=color,turn=0,x=0};hitPools[key]=pool end
    for _,entry in ipairs(pool) do if not entry.age then return pool,entry end end
    if table.getn(pool)>=HIT_MAX then return pool,nil end
    local entry={label=block:CreateFontString(nil,"OVERLAY")}
    entry.label:SetTextColor(color[1],color[2],color[3]);entry.label:SetShadowColor(0,0,0,0.9);entry.label:SetShadowOffset(1,-1)
    table.insert(pool,entry)
    return pool,entry
end
-- A hit waits a moment before it shows beside its column: a lone hit equals the column's number and must not be shown
-- twice. Only when a second one comes do both appear.
local HIT_WAIT=0.25
local waiting={}
local PopHit
local function QueueHit(column,block,color,prefix,amount,side)
    if not E.On("separateHits") then return end
    table.insert(waiting,{column=column,block=block,color=color,prefix=prefix,amount=amount,side=side,age=0})
end
local function ReleaseHits(elapsed)
    for index=table.getn(waiting),1,-1 do
        local item=waiting[index]
        item.age=item.age+elapsed
        if item.age>=HIT_WAIT then
            table.remove(waiting,index)
            local newest=item.column.newest
            local shownAlone=newest and newest.age and math.abs(newest.amount-item.amount)<1
            if shownAlone then
                item.column.heldHit=item
            else
                local held=item.column.heldHit
                if held then
                    item.column.heldHit=nil
                    PopHit(held.block,held.color,held.prefix,held.amount,held.side)
                end
                PopHit(item.block,item.color,item.prefix,item.amount,item.side)
            end
        end
    end
end
function E.HitText(value) if E.On("fullHits") then return E.Full(value) end;return E.Short(value) end
function PopHit(block,color,prefix,amount,side)
    local pool,entry=HitLabel(block,color)
    if not entry then return end
    pool.turn=math.mod(pool.turn,3)+1
    entry.age=0;entry.x=side*HIT_SIDE;entry.y=START+(pool.turn-1)*HIT_LINE
    entry.label:SetFont(E.FONT,math.max(8,E.Size("risingFont",13)-3),"OUTLINE")
    entry.label:SetText(prefix..E.HitText(amount));entry.label:SetAlpha(1)
    entry.label:ClearAllPoints();entry.label:SetPoint("BOTTOM",block,"BOTTOM",entry.x,entry.y);entry.label:Show()
end

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
    entry.size=E.Size("risingFont",13)+EXTRA_FONT*weight;entry.settled=nil
    entry.label:SetFont(E.FONT,entry.size,"OUTLINE")
    entry.label:SetText(column.prefix..E.HitText(entry.amount))
end
local function Pop(column,amount,texture)
    local newest=column.newest
    if newest and newest.age and newest.age<MERGE then
        newest.amount=newest.amount+amount
        Dress(column,newest)
    else
        column.heldHit=nil
        newest=Free(column);column.newest=newest
        newest.age=0;newest.amount=amount
        Dress(column,newest)
        newest.label:SetAlpha(1);newest.label:ClearAllPoints()
        newest.anchorX=column.fromBar and column.fromBar() or nil
        newest.label:SetPoint("BOTTOM",column.block,"BOTTOM",newest.anchorX or column.x,START);newest.label:Show()
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
-- Where the hero's health ends now, as an offset from the middle of the rising block: the number comes out of the
-- piece of health just lost. Nil when the frames cannot be measured.
taken.fromBar=function()
    local widget=getglobal("nfUIPlayer")
    local bar=widget and widget.health
    if not bar or not bar:GetLeft() or not E.blocks.rising:GetCenter() then return nil end
    local most=UnitHealthMax("player") or 0
    local share=most>0 and (UnitHealth("player") or 0)/most or 0
    local barScale,blockScale=bar:GetEffectiveScale(),E.blocks.rising:GetEffectiveScale()
    local x=(bar:GetLeft()+bar:GetWidth()*math.max(0,math.min(1,share)))*barScale
    local center=E.blocks.rising:GetCenter()*blockScale
    return (x-center)/blockScale
end
local healed=Column(E.blocks.rising,E.COLORS.green,"+",58,ByHealth)
local dealt=Column(E.blocks.targetRising,E.COLORS.enemy,"-",0,ByRecent)

-- Called for each hit of the hero's that the combat log names.
function E.TargetHit(amount,name,texture)
    if not E.On("targetRising") or not name or name~=UnitName("target") then return end
    local value=tonumber(amount)
    if value and value>0 then
        Pop(dealt,value,texture)
        QueueHit(dealt,E.blocks.targetRising,E.COLORS.enemy,"-",value,1)
    end
end

-- Called for each hit on the hero that the game reports.
-- The hits the hero took in the last ten seconds, for the damage panel's biggest hit.
local recentHits={}
function E.BiggestRecentHit()
    local now,biggest=GetTime(),0
    for index=table.getn(recentHits),1,-1 do
        local hit=recentHits[index]
        if now-hit.at>10 then table.remove(recentHits,index) elseif hit.amount>biggest then biggest=hit.amount end
    end
    return biggest
end
-- The hits on the hero are not shown one by one beside their total: one number per moment, coming out of the bar.
function E.HeroHit(amount)
    local value=tonumber(amount)
    if value and value>0 then table.insert(recentHits,{at=GetTime(),amount=value}) end
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
    ReleaseHits(elapsed)
    for _,pool in pairs(hitPools) do
        for _,entry in ipairs(pool) do
            if entry.age then
                entry.age=entry.age+elapsed
                if entry.age>=HIT_LIFE then
                    entry.age=nil;entry.label:Hide()
                else
                    local part=entry.age/HIT_LIFE
                    entry.label:SetPoint("BOTTOM",pool.block,"BOTTOM",entry.x,entry.y+10*part)
                    local fade=part<0.4 and 1 or (1-part)/0.6
                    entry.label:SetAlpha(fade*fade)
                end
            end
        end
    end
    for _,column in ipairs(columns) do
        for _,entry in ipairs(column.pool) do
            if entry.age then
                entry.age=entry.age+elapsed
                if entry.age>=entry.life then
                    entry.age=nil;entry.label:Hide();entry.icon:Hide()
                else
                    local part=entry.age/entry.life
                    -- One speed for all, so that a newer number never catches an older one.
                    entry.label:SetPoint("BOTTOM",column.block,"BOTTOM",entry.anchorX or column.x,START+E.Size("risingHeight",64)*entry.age/LIFE)
                    -- A short pop as it appears: larger for a moment, then its own size.
                    if entry.age<0.18 then entry.label:SetFont(E.FONT,math.floor(entry.size*(1.5-entry.age/0.18*0.5)+0.5),"OUTLINE")
                    elseif not entry.settled then entry.label:SetFont(E.FONT,entry.size,"OUTLINE");entry.settled=true end
                    -- Solid at first, then it dissolves ever more gently.
                    local fade=part<0.35 and 1 or (1-part)/0.65
                    entry.label:SetAlpha(fade*fade);entry.icon:SetAlpha(fade*fade)
                end
            end
        end
    end
end)
