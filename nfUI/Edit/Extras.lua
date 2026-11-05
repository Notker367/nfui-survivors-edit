-- Smaller features: how much the interface shows, boss warnings, guardians and caches on the minimap, the
-- colour-blind palette, and the export of past runs.
local E,C=nfUIEdit,nfUIConfig

-- How much is shown: default, detailed (adds hero stats and the DPS graph) or hidden (no info panels).
local MODES={"default","detailed","hidden"}
local MODE_NAMES={default={"обычный","default"},detailed={"подробный","detailed"},hidden={"скрытый","hidden"}}
function E.ModeName()
    local names=MODE_NAMES[E.Mode()] or MODE_NAMES.default
    return names[E.IsRussian() and 1 or 2]
end
function E.CycleMode()
    local now=E.Mode()
    local nextMode=MODES[1]
    for index,mode in ipairs(MODES) do
        if mode==now then nextMode=MODES[math.mod(index,table.getn(MODES))+1] end
    end
    nfUIDB.uiMode=nextMode
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("nfUI: "..E.Text("режим: ","mode: ")..E.ModeName()) end
    if E.RefreshPools then E.RefreshPools() end
    if C.Refresh then C.Refresh() end
end
BINDING_HEADER_NFUI="nfUI"
BINDING_NAME_NFUI_MODE="Cycle interface detail"

-- A warning in the middle of the screen.
local banner=CreateFrame("Frame","nfUIAlert",UIParent)
banner:SetWidth(700);banner:SetHeight(40);banner:SetPoint("CENTER",UIParent,"CENTER",0,190);banner:SetFrameStrata("HIGH");banner:Hide()
banner.text=banner:CreateFontString(nil,"OVERLAY");banner.text:SetFont(E.FONT,24,"OUTLINE");banner.text:SetAllPoints(banner)
banner:SetScript("OnUpdate",function()
    this.age=(this.age or 0)+(arg1 or 0)
    if this.age>=3.5 then this:Hide() elseif this.age>2 then this:SetAlpha((3.5-this.age)/1.5) end
end)
function E.Alert(text)
    banner.age=0;banner:SetAlpha(1)
    banner.text:SetTextColor(E.COLORS.yellow[1],E.COLORS.yellow[2],E.COLORS.yellow[3]);banner.text:SetText(text);banner:Show()
    if PlaySound then pcall(PlaySound,"RaidWarning") end
end

-- Guardians and caches on the minimap, at the classic game's scale for each zoom level.
local RADIUS={[0]=233.33,[1]=200,[2]=166.67,[3]=133.33,[4]=100,[5]=66.67}
local pins={}
local function Pin(index)
    local pin=pins[index]
    if pin then return pin end
    pin=CreateFrame("Frame",nil,Minimap);pin:SetWidth(9);pin:SetHeight(9);pin:SetFrameLevel(Minimap:GetFrameLevel()+5)
    pin.dot=pin:CreateTexture(nil,"OVERLAY");pin.dot:SetTexture(E.FLAT);pin.dot:SetAllPoints(pin)
    E.Ring(pin);pin:EnableMouse(true)
    pin:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(this.label or "",1,1,1);GameTooltip:Show()
    end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
    pins[index]=pin
    return pin
end
local function Place(index,x,y,px,py,radius,half,color,label)
    local north,east=x-px,py-y
    local dx,dy=east/radius*half,north/radius*half
    local gap=math.sqrt(dx*dx+dy*dy)
    local limit=half-6
    local pin=Pin(index)
    -- Beyond the map's edge a pin stays on the edge, fainter, pointing the way.
    if gap>limit then dx=dx/gap*limit;dy=dy/gap*limit;pin:SetAlpha(0.55) else pin:SetAlpha(1) end
    pin:ClearAllPoints();pin:SetPoint("CENTER",Minimap,"CENTER",dx,dy)
    pin.dot:SetVertexColor(color[1],color[2],color[3]);pin.label=label;pin:Show()
end
E.Every(0.2,function()
    local count=0
    local run=AZS_RUN
    local px,py=type(run)=="table" and tonumber(run.px),type(run)=="table" and tonumber(run.py)
    if px and py and E.On("mapPins") and Minimap:IsVisible() then
        local radius=RADIUS[Minimap.GetZoom and Minimap:GetZoom() or 0] or 233.33
        local half=Minimap:GetWidth()/2
        for _,lair in ipairs(type(AZS_LAIRS)=="table" and AZS_LAIRS or {}) do
            if tonumber(lair.x) and tonumber(lair.y) and lair.state~="empty" then
                count=count+1
                local color=lair.state=="asleep" and E.COLORS.sapphire or E.COLORS.peach
                Place(count,lair.x,lair.y,px,py,radius,half,color,lair.name)
            end
        end
        for _,chest in ipairs(type(AZS_CHESTS)=="table" and AZS_CHESTS or {}) do
            if tonumber(chest.x) and tonumber(chest.y) then
                count=count+1
                Place(count,chest.x,chest.y,px,py,radius,half,E.COLORS.yellow,E.Text("Сундук","Cache"))
            end
        end
    end
    for index=count+1,table.getn(pins) do pins[index]:Hide() end
end)

-- A palette without the red and green pair, from Okabe and Ito's colour-blind safe set. It changes the shared
-- colour tables, so what reads them follows at once and the rest after a /reload.
local SAFE={enemy={0.84,0.37,0},red={0.84,0.37,0},green={0.34,0.71,0.91},peach={0.9,0.62,0},sapphire={0,0.62,0.45},yellow={0.94,0.89,0.26},mauve={0.8,0.47,0.65}}
local original={}
for name,color in pairs(E.COLORS) do original[name]={color[1],color[2],color[3]} end
local shown=false
E.Every(1,function()
    local wanted=type(nfUIDB)=="table" and type(nfUIDB.edit)=="table" and nfUIDB.edit.colorblind==true
    if wanted==shown then return end
    shown=wanted
    for name,target in pairs(E.COLORS) do
        local source=wanted and SAFE[name] or original[name]
        if source then target[1],target[2],target[3]=source[1],source[2],source[3] end
    end
    if C.Apply then C.Apply() end
end)

-- Past runs as plain text, to copy out of the game.
function E.ExportText()
    local lines={"class;zone;seconds;level;damage;dps;top skills"}
    for _,run in ipairs(type(nfUIDB.runHistory)=="table" and nfUIDB.runHistory or {}) do
        if (run.t or 0)>=1 then
            local skills=""
            for _,skill in ipairs(run.skills or {}) do skills=skills..skill.name.." "..math.floor(skill.dmg).." " end
            table.insert(lines,table.concat({tostring(run.class),tostring(run.zone),math.floor(run.t),tostring(run.level),math.floor(run.dealt or 0),math.floor((run.dealt or 0)/run.t),skills},";"))
        end
    end
    return table.concat(lines," | ")
end
