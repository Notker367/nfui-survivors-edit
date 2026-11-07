-- The skill bar: locked, slightly see-through, each skill's rank and DPS under its icon.
local E=nfUIEdit
local BAR_ALPHA=0.9
E.Every(0.5,function()
    LOCK_ACTIONBAR="1"
    local xp=getglobal("MainMenuExpBar")
    if xp then xp:SetAlpha(BAR_ALPHA);E.Polish(xp) end
    for _,id in ipairs(E.BUTTONS) do
        for _,prefix in ipairs({"ActionButton","BonusActionButton"}) do
            local button=getglobal(prefix..id)
            if button then button:SetAlpha(BAR_ALPHA);E.Ring(button) end
        end
    end
end)

local scan
local function ReadAction(action)
    if not scan then
        local ok,tip=pcall(CreateFrame,"GameTooltip","nfUIRankScan",UIParent,"GameTooltipTemplate")
        if not ok or not tip then return nil end
        scan=tip;tip:SetAlpha(0)
    end
    scan:SetOwner(UIParent,"ANCHOR_NONE");scan:ClearLines();scan:SetAction(action)
    local right=getglobal("nfUIRankScanTextRight1")
    local left=getglobal("nfUIRankScanTextLeft1")
    local rankText=right and right:GetText()
    local spell=left and left:GetText()
    scan:Hide()
    local number
    if rankText then _,_,number=string.find(rankText,"(%d+)") end
    return number,spell
end
local function Label(button,anchor,relative,gap,r,g,b)
    local label=button:CreateFontString(nil,"OVERLAY")
    label:SetFont(E.FONT,9,"OUTLINE");label:SetPoint("TOP",anchor,relative,0,gap);label:SetTextColor(r,g,b)
    return label
end
E.Every(2,function()
    if not ActionButton_GetPagedID then return end
    local rates={}
    if AZS_GetMeter then
        local ok,lines=pcall(AZS_GetMeter)
        if ok and type(lines)=="table" then
            for _,line in ipairs(lines) do
                if type(line)=="table" and line.name and type(line.dps)=="number" then rates[line.name]=line.dps end
            end
        end
    end
    local mark=E.Text("\208\160","R")
    local on=E.On("skillStats")
    local font=E.Size("skillStatsFont",9)
    for _,prefix in ipairs({"ActionButton","BonusActionButton"}) do
        for _,id in ipairs(E.BUTTONS) do
            local button=getglobal(prefix..id)
            if button and button:IsVisible() then
                button.nfuiRank=button.nfuiRank or Label(button,button,"BOTTOM",-2,1,0.82,0.3)
                button.nfuiDps=button.nfuiDps or Label(button,button.nfuiRank,"BOTTOM",-1,0.75,0.9,1)
                if button.nfuiFont~=font then
                    button.nfuiFont=font
                    button.nfuiRank:SetFont(E.FONT,font,"OUTLINE");button.nfuiDps:SetFont(E.FONT,font,"OUTLINE")
                end
                local ok,action=pcall(ActionButton_GetPagedID,button)
                local number,spell
                if on and ok and action and HasAction(action) then number,spell=ReadAction(action) end
                button.nfuiRank:SetText(number and (mark..number) or "")
                local rate=spell and rates[spell]
                button.nfuiDps:SetText(rate and E.Short(rate) or "")
            end
        end
    end
end)

-- Hovering a skill adds what the meter knows about it.
local function MeterLine(spell)
    if not spell or not AZS_GetMeter then return nil end
    local ok,lines=pcall(AZS_GetMeter)
    if not ok or type(lines)~="table" then return nil end
    for _,line in ipairs(lines) do
        if type(line)=="table" and line.name==spell and type(line.dps)=="number" then return line end
    end
end
local setAction=GameTooltip.SetAction
if setAction then
    GameTooltip.SetAction=function(self,action)
        local result=setAction(self,action)
        if E.On("skillStats") then
            local first=getglobal("GameTooltipTextLeft1")
            local line=MeterLine(first and first:GetText())
            if line then
                self:AddLine(" ")
                self:AddDoubleLine(E.Text("Урон в секунду","Damage per second"),E.Short(line.dps).." DPS",1,0.82,0,1,1,1)
                if type(line.share)=="number" then self:AddDoubleLine(E.Text("Доля урона","Damage share"),string.format("%.0f%%",line.share*100),1,0.82,0,1,1,1) end
                if type(line.dmg)=="number" then self:AddDoubleLine(E.Text("Урон за забег","Damage this run"),E.Short(line.dmg),1,0.82,0,1,1,1) end
                self:Show()
            end
        end
        return result
    end
end
