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

-- Guardians and caches on the minimap, at the classic game's scale for each zoom level, with the game's own art:
-- a skull for a guardian, a crate for a cache. The hero's arrow is drawn by the game beneath anything an addon adds, so
-- the middle of the map stays clear: a pin that close steps out to the zone's edge and fades.
local RADIUS={[0]=233.33,[1]=200,[2]=166.67,[3]=133.33,[4]=100,[5]=66.67}
local SKULL,CRATE="Interface\\TargetingFrame\\UI-TargetingFrame-Skull","Interface\\Icons\\INV_Crate_01"
local CLEAR_ZONE=14
local pins={}
local function Pin(index)
    local pin=pins[index]
    if pin then return pin end
    pin=CreateFrame("Frame",nil,Minimap);pin:SetFrameLevel(Minimap:GetFrameLevel()+5)
    pin.back=pin:CreateTexture(nil,"BACKGROUND");pin.back:SetTexture(E.FLAT);pin.back:SetVertexColor(0,0,0,0.65)
    pin.back:SetPoint("TOPLEFT",pin,"TOPLEFT",-1,1);pin.back:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",1,-1)
    pin.art=pin:CreateTexture(nil,"ARTWORK");pin.art:SetAllPoints(pin)
    pin:EnableMouse(true)
    pin:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(this.label or "",1,1,1);GameTooltip:Show()
    end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
    pins[index]=pin
    return pin
end
local function Place(index,x,y,px,py,radius,half,texture,color,label,size)
    local north,east=x-px,py-y
    local dx,dy=east/radius*half,north/radius*half
    local gap=math.sqrt(dx*dx+dy*dy)
    local limit=half-size/2-1
    local pin=Pin(index)
    local alpha=1
    -- Beyond the map's edge a pin stays on the edge, fainter, pointing the way.
    if gap>limit then dx=dx/gap*limit;dy=dy/gap*limit;alpha=0.6
    elseif gap<CLEAR_ZONE then
        if gap<0.5 then dx,dy,gap=0,1,1 end
        dx=dx/gap*CLEAR_ZONE;dy=dy/gap*CLEAR_ZONE;alpha=0.55
    end
    pin:SetWidth(size);pin:SetHeight(size);pin:SetAlpha(alpha)
    pin:ClearAllPoints();pin:SetPoint("CENTER",Minimap,"CENTER",dx,dy)
    if pin.texture~=texture then
        pin.texture=texture;pin.art:SetTexture(texture)
        if texture==CRATE then pin.art:SetTexCoord(0.07,0.93,0.07,0.93) else pin.art:SetTexCoord(0,1,0,1) end
    end
    pin.art:SetVertexColor(color[1],color[2],color[3]);pin.label=label;pin:Show()
end
local WHITE={1,1,1}
E.Every(0.2,function()
    local count=0
    local run=AZS_RUN
    local px,py=type(run)=="table" and tonumber(run.px),type(run)=="table" and tonumber(run.py)
    if px and py and E.On("mapPins") and Minimap:IsVisible() then
        local radius=RADIUS[Minimap.GetZoom and Minimap:GetZoom() or 0] or 233.33
        local half=Minimap:GetWidth()/2
        local size=E.Size("mapPinSize",14)
        for _,chest in ipairs(type(AZS_CHESTS)=="table" and AZS_CHESTS or {}) do
            if tonumber(chest.x) and tonumber(chest.y) then
                count=count+1
                Place(count,chest.x,chest.y,px,py,radius,half,CRATE,WHITE,E.Text("Сундук","Cache"),size)
            end
        end
        for _,lair in ipairs(type(AZS_LAIRS)=="table" and AZS_LAIRS or {}) do
            -- The lair the game points at already has its red flag on the map.
            if tonumber(lair.x) and tonumber(lair.y) and lair.state~="empty" and lair.flag~=1 then
                count=count+1
                -- A sleeping guardian is pale; an awake one burns.
                local color=lair.state=="asleep" and E.COLORS.sapphire or E.COLORS.peach
                Place(count,lair.x,lair.y,px,py,radius,half,SKULL,color,lair.name,size)
            end
        end
    end
    for index=count+1,table.getn(pins) do pins[index]:Hide() end
end)

-- The settings, a click away from the minimap: left click for the settings, right click for moving panels.
local gear=CreateFrame("Button","nfUIMapSettings",Minimap)
gear:SetWidth(14);gear:SetHeight(14);gear:SetFrameLevel(Minimap:GetFrameLevel()+8);gear:SetPoint("TOPLEFT",Minimap,"TOPLEFT",4,-4)
gear:RegisterForClicks("LeftButtonUp","RightButtonUp")
gear.back=gear:CreateTexture(nil,"BACKGROUND");gear.back:SetTexture(E.FLAT);gear.back:SetVertexColor(0,0,0,0.7);gear.back:SetPoint("TOPLEFT",gear,"TOPLEFT",-1,1);gear.back:SetPoint("BOTTOMRIGHT",gear,"BOTTOMRIGHT",1,-1)
gear.art=gear:CreateTexture(nil,"ARTWORK");gear.art:SetAllPoints(gear);gear.art:SetTexture("Interface\\Icons\\Trade_Engineering");gear.art:SetTexCoord(0.07,0.93,0.07,0.93)
gear:SetScript("OnClick",function()
    if arg1=="RightButton" then C.ToggleMovers()
    elseif IsShiftKeyDown() or not E.ToggleQuickMenu then SlashCmdList["NFUI"]("")
    else E.ToggleQuickMenu(this) end
end)
gear:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText("nfUI",0.8,0.65,0.97)
    GameTooltip:AddLine(E.Text("Клик: быстрое меню","Click: quick menu"),1,1,1)
    GameTooltip:AddLine(E.Text("Shift+клик: все настройки","Shift+click: all settings"),1,1,1)
    GameTooltip:AddLine(E.Text("Правая кнопка: двигать панели","Right click: move panels"),1,1,1);GameTooltip:Show()
end)
gear:SetScript("OnLeave",function() GameTooltip:Hide() end)
-- Faint until the mouse is over the minimap, so that it does not catch the eye in a fight.
local gearAge=0
gear:SetScript("OnUpdate",function()
    gearAge=gearAge+(arg1 or 0);if gearAge<0.05 then return end;gearAge=0
    local menu=getglobal("nfUIQuickMenu")
    local near=(MouseIsOver and (MouseIsOver(Minimap) or MouseIsOver(this))) or (menu and menu:IsShown())
    this:SetAlpha(near and 1 or 0.3)
end)
-- Beside it, a sword: the run analysis, one click away.
local sword=CreateFrame("Button","nfUIMapRuns",Minimap)
sword:SetWidth(14);sword:SetHeight(14);sword:SetFrameLevel(Minimap:GetFrameLevel()+8);sword:SetPoint("LEFT",gear,"RIGHT",4,0)
sword.back=sword:CreateTexture(nil,"BACKGROUND");sword.back:SetTexture(E.FLAT);sword.back:SetVertexColor(0,0,0,0.7);sword.back:SetPoint("TOPLEFT",sword,"TOPLEFT",-1,1);sword.back:SetPoint("BOTTOMRIGHT",sword,"BOTTOMRIGHT",1,-1)
sword.art=sword:CreateTexture(nil,"ARTWORK");sword.art:SetAllPoints(sword);sword.art:SetTexture("Interface\\Icons\\INV_Sword_04");sword.art:SetTexCoord(0.07,0.93,0.07,0.93)
sword:SetScript("OnClick",function() if E.ToggleRunReport then E.ToggleRunReport() end end)
sword:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text("Анализ забегов","Run analysis"),0.8,0.65,0.97)
    GameTooltip:AddLine(E.Text("Забеги класса: DPS, прибавки, билды","The class's runs: DPS, picks, builds"),1,1,1);GameTooltip:Show()
end)
sword:SetScript("OnLeave",function() GameTooltip:Hide() end)
local swordAge=0
sword:SetScript("OnUpdate",function()
    swordAge=swordAge+(arg1 or 0);if swordAge<0.05 then return end;swordAge=0
    local report=getglobal("nfUIRunReport")
    local near=(MouseIsOver and (MouseIsOver(Minimap) or MouseIsOver(this))) or (report and report:IsShown())
    this:SetAlpha(near and 1 or 0.3)
end)
E.Every(1,function()
    if E.On("mapSettings") then gear:Show() else gear:Hide() end
    if E.On("mapSettings") and E.On("runsButton") then sword:Show() else sword:Hide() end
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
    local lines={"class;zone;heroic/difficulty;seconds;level;damage;dps;top skills"}
    for _,run in ipairs(type(nfUIDB.runHistory)=="table" and nfUIDB.runHistory or {}) do
        if (run.t or 0)>=1 then
            local skills=""
            for _,skill in ipairs(run.skills or {}) do skills=skills..skill.name.." "..math.floor(skill.dmg).." " end
            table.insert(lines,table.concat({tostring(run.class),tostring(run.zone),tostring(run.mode),math.floor(run.t),tostring(run.level),math.floor(run.dealt or 0),math.floor((run.dealt or 0)/run.t),skills},";"))
        end
    end
    return table.concat(lines," | ")
end

-- Raid marks set by themselves, without two copies of the addon taking one mark from each other.
-- Each hero gets a mark of their own from the party's names in alphabetical order, the same on every client, and
-- marks only themselves. An ally who is down gets the skull from everyone; once up, they take their own mark back.
-- A mark someone set by hand is left alone for the rest of the run, and a client the game does not let mark stops trying.
local HERO_MARKS={1,2,3,5,4} -- star, circle, diamond, triangle, moon
local SKULL=8
local marked,lastSet,manual,refusedUntil={},{},{},0
local function Mark(unit,index)
    if not SetRaidTarget or not UnitExists(unit) or GetTime()<refusedUntil then return end
    local now=GetRaidTargetIndex and GetRaidTargetIndex(unit) or 0
    if now==index then return end
    -- Someone else changed one's own mark after this addon set it: theirs wins. Allies' marks are their own clients' to set.
    if unit=="player" and lastSet[unit] and now~=lastSet[unit] and now~=0 and now~=SKULL then manual[unit]=true end
    if manual[unit] then return end
    -- Setting the same mark again would take it off, so 0 only when one is there.
    if index==0 and now==0 then lastSet[unit]=nil;return end
    pcall(SetRaidTarget,unit,index);lastSet[unit]=index
    -- The game may keep marks to the party's leader: if nothing changed, wait a while before the next try.
    if (GetRaidTargetIndex and GetRaidTargetIndex(unit) or 0)~=index then refusedUntil=GetTime()+30 end
end
local function IsDown(unit)
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then return true end
    local name=UnitName(unit)
    for _,down in ipairs(type(AZS_DOWNED)=="table" and AZS_DOWNED or {}) do
        if type(down)=="table" and down.name==name and down.state=="down" then return true end
    end
    return false
end
local function OwnMark()
    local names={UnitName("player") or ""}
    for index=1,4 do local name=UnitExists("party"..index) and UnitName("party"..index);if name then table.insert(names,name) end end
    table.sort(names)
    local me=UnitName("player")
    for index,name in ipairs(names) do if name==me then return HERO_MARKS[index] or 0 end end
    return 0
end
local markTime=0
E.Every(0.5,function()
    -- A new run, its clock back at the start, has no hand-set marks to respect.
    local time=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0
    if time<markTime then manual={};lastSet={} end
    markTime=time
    if not E.On("autoMarks") then
        for unit in pairs(marked) do Mark(unit,0);marked[unit]=nil end
        return
    end
    local party=UnitExists("party1")
    -- One's own mark, unless down: then the others' skull stays.
    if party and not IsDown("player") then Mark("player",OwnMark());marked.player=true
    elseif not party and marked.player then Mark("player",0);marked.player=nil end
    for index=1,4 do
        local unit="party"..index
        if UnitExists(unit) and IsDown(unit) then Mark(unit,SKULL);marked[unit]=true
        elseif marked[unit] then
            -- Up again: the skull goes, unless their own client has already put their mark back.
            if UnitExists(unit) and GetRaidTargetIndex and GetRaidTargetIndex(unit)==SKULL then Mark(unit,0) end
            marked[unit]=nil
        end
    end
end)

-- A right click on a portrait: the game's own menu for that unit, and locking the frame in place.
local portraitMenu
local function PortraitMenu(frame,unit)
    if not portraitMenu then
        portraitMenu=CreateFrame("Frame","nfUIPortraitMenu",UIParent)
        portraitMenu:SetWidth(180);portraitMenu:SetHeight(92);portraitMenu:SetFrameStrata("FULLSCREEN_DIALOG");portraitMenu:EnableMouse(true)
        portraitMenu:SetBackdrop({bgFile=E.FLAT});portraitMenu:SetBackdropColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.97)
        portraitMenu.buttons={}
        for index=1,3 do
            local button=CreateFrame("Button","nfUIPortraitMenuButton"..index,portraitMenu,"UIPanelButtonTemplate")
            button:SetWidth(168);button:SetHeight(24);button:SetPoint("TOPLEFT",portraitMenu,"TOPLEFT",6,-6-(index-1)*28)
            portraitMenu.buttons[index]=button
        end
        portraitMenu.buttons[3]:SetText(E.L("Cancel"));portraitMenu.buttons[3]:SetScript("OnClick",function() portraitMenu:Hide() end)
        table.insert(UISpecialFrames,"nfUIPortraitMenu")
    end
    local menu=portraitMenu
    local key=unit=="player" and "player" or "target"
    menu.buttons[1]:SetText(E.Text("Меню","Menu"))
    menu.buttons[1]:SetScript("OnClick",function()
        menu:Hide()
        local dropdown=getglobal(unit=="player" and "PlayerFrameDropDown" or "TargetFrameDropDown")
        if dropdown and ToggleDropDownMenu then pcall(ToggleDropDownMenu,1,nil,dropdown,"cursor") end
    end)
    menu.buttons[2]:SetText(E.L(C.IsMoverLocked and C.IsMoverLocked(key) and "Unlock" or "Lock"))
    menu.buttons[2]:SetScript("OnClick",function()
        if C.ToggleMoverLock then C.ToggleMoverLock(key) end
        menu:Hide()
    end)
    local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
    menu:ClearAllPoints();menu:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale);menu:Show()
end
-- Only the portraits take the mouse: the bars stay click-through, so the camera never sticks on them.
for _,frame in ipairs({C.player,C.target}) do
    local owner=frame
    local catcher=CreateFrame("Button",nil,owner.portrait)
    catcher:SetAllPoints(owner.portrait);catcher:SetFrameLevel(owner.portrait:GetFrameLevel()+5)
    catcher:RegisterForClicks("LeftButtonUp","RightButtonUp")
    catcher:SetScript("OnClick",function()
        if arg1=="RightButton" then PortraitMenu(owner,owner.unit) elseif owner.unit=="target" then return else TargetUnit(owner.unit) end
    end)
end
