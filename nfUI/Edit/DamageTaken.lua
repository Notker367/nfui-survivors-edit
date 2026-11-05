-- The damage the hero takes: one slow column of numbers that rise from the health bar and dissolve.
-- Read from the run's own damage total, so it does not depend on the client's language.
local E=nfUIEdit
local LIFE,START=2.6,3
-- The bigger the hit, the larger the number and the longer it stays: a quarter of the hero's health is the most.
local BIG_SHARE,EXTRA_FONT,EXTRA_LIFE=0.25,10,1.4
-- Hits this close together become one number, so the column stays readable.
local MERGE=0.8
local pool={}
local last,newest

local function Free(block)
    for _,entry in ipairs(pool) do
        if not entry.age then return entry end
    end
    local entry={label=block:CreateFontString(nil,"OVERLAY")}
    entry.label:SetTextColor(E.COLORS.enemy[1],E.COLORS.enemy[2],E.COLORS.enemy[3])
    entry.label:SetShadowColor(0,0,0,0.9);entry.label:SetShadowOffset(1,-1)
    table.insert(pool,entry)
    return entry
end

local function Emphasize(entry)
    local most=UnitHealthMax("player") or 0
    local weight=most>0 and math.min(1,math.sqrt(entry.amount/(most*BIG_SHARE))) or 0
    entry.life=LIFE+EXTRA_LIFE*weight
    entry.label:SetFont(E.FONT,E.Size("risingFont",13)+EXTRA_FONT*weight,"OUTLINE")
end

local function Pop(block,amount)
    if newest and newest.age and newest.age<MERGE then
        newest.amount=newest.amount+amount
        Emphasize(newest)
        newest.label:SetText("-"..E.Short(newest.amount))
        return
    end
    local entry=Free(block)
    entry.age=0;entry.amount=amount;newest=entry
    Emphasize(entry)
    entry.label:SetText("-"..E.Short(amount));entry.label:SetAlpha(1)
    entry.label:ClearAllPoints();entry.label:SetPoint("BOTTOM",block,"BOTTOM",0,START)
    entry.label:Show()
end

local ticker=CreateFrame("Frame","nfUIEditRising")
ticker:SetScript("OnUpdate",function()
    local elapsed=arg1 or 0
    local block=E.blocks.rising
    local taken=type(AZS_RUN)=="table" and tonumber(AZS_RUN.taken)
    if taken then
        -- A smaller total means a new run; the first reading only sets the baseline.
        if last and taken-last>=1 and E.On("risingDamage") then Pop(block,taken-last) end
        last=taken
    end
    for _,entry in ipairs(pool) do
        if entry.age then
            entry.age=entry.age+elapsed
            if entry.age>=entry.life then
                entry.age=nil;entry.label:Hide()
            else
                local part=entry.age/entry.life
                entry.label:SetPoint("BOTTOM",block,"BOTTOM",0,START+E.Size("risingHeight",42)*part)
                -- Solid at first, then it dissolves ever more gently.
                local fade=part<0.35 and 1 or (1-part)/0.65
                entry.label:SetAlpha(fade*fade)
            end
        end
    end
end)
