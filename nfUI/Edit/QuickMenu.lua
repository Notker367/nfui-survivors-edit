-- The quick menu, a click on the minimap's gear: how much the interface shows and the switches players reach
-- for most. Everything else stays in the full settings.
local E,C=nfUIEdit,nfUIConfig
local MODES={{"hidden","Скрытый","Hidden"},{"default","Обычный","Default"},{"detailed","Подробный","Detailed"}}
-- { switch, Russian, English, only in the detailed mode, "db" when the switch lives in the profile itself }
local GROUPS={
    {"Панели","Panels",{
        {"dpsMeter","DPS-метр","DPS meter"},{"compass","Компас","Compass",nil,"db"},
        {"targetOfTarget","Цель цели","Target of target"},{"partyLoadout","Снаряжение группы","Party loadouts"}}},
    {"Панели справа","Right panels",{
        {"bossSchedule","Боссы","Bosses"},{"lairPanel","Стражи","Guardians"},{"takenPanel","Кто бьёт героя","Damage taken"},
        {"historyPanel","История забегов","Run history"},{"heroStats","Статы героя","Hero stats",true},{"dpsGraph","График DPS","DPS graph",true}}},
    {"Пулы","Pools",{
        {"skillPool","Пул скилов","Skill pool"},{"jewelPool","Пул бижутерии","Jewelry pool"},{"legendRow","Легендарки на скилы","Skill legendaries"}}},
    {"Цифры","Numbers",{
        {"risingDamage","Урон над здоровьем","Damage above health"},{"targetRising","Урон по цели","Hits on the target"},
        {"skillRate","Уд/с и макс в метре","Hits/s and max in meter"},{"skillStats","Ранг и DPS под скилами","Rank and DPS under skills"}}},
    {"Враги","Enemies",{
        {"farPlates","Полоски дальних врагов","Far enemy bars"},{"petBars","Полоски питомцев (тонкие)","Pet bars (thin)"},{"metres","Метры до врагов","Metres to enemies"},{"bossAlert","Предупреждение о боссе","Boss warning"}}},
}
local ROW,WIDTH=16,190
local menu=CreateFrame("Frame","nfUIQuickMenu",UIParent)
menu:SetWidth(WIDTH);menu:SetFrameStrata("DIALOG");menu:EnableMouse(true);menu:Hide()
table.insert(UISpecialFrames,"nfUIQuickMenu")
local fill=menu:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT);fill:SetAllPoints(menu)
fill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.95)
E.Polish(menu)
local function Font(parent,size,color)
    local text=parent:CreateFontString(nil,"OVERLAY");text:SetFont(E.FONT,size,"OUTLINE");text:SetJustifyH("LEFT")
    text:SetTextColor(color[1],color[2],color[3])
    return text
end
local title=Font(menu,12,E.COLORS.mauve);title:SetPoint("TOPLEFT",menu,"TOPLEFT",8,-7);title:SetText("nfUI")
local y=-26
-- How much is shown, as three buttons.
local modeButtons={}
local function SetMode(mode)
    nfUIDB.uiMode=mode
    if E.RefreshPools then E.RefreshPools() end
    if C.Refresh then C.Refresh() end
    menu.Refresh()
end
for index,mode in ipairs(MODES) do
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth((WIDTH-16-4)/3)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",8+(index-1)*((WIDTH-16-4)/3+2),y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.mode=mode
    button:SetScript("OnClick",function() SetMode(this.mode[1]) end)
    button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text("Сколько показывать","How much to show"),1,1,1)
        GameTooltip:AddLine(E.Text("Скрытый: без инфо-панелей. Подробный: ещё статы героя и график DPS.","Hidden: no info panels. Detailed: adds hero stats and the DPS graph."),0.8,0.8,0.85,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    modeButtons[index]=button
end
y=y-24
-- Where everything stands: as in the old game, or the player's own.
local LAYOUTS={{"classic","Классика","Classic"},{"mine","Моя","Mine"}}
local layoutButtons={}
for index,layout in ipairs(LAYOUTS) do
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth((WIDTH-16-2)/2)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",8+(index-1)*((WIDTH-16-2)/2+2),y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.layout=layout
    button:SetScript("OnClick",function()
        if E.ApplyLayout then E.ApplyLayout(this.layout[1]) end
        menu.Refresh()
    end)
    button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text("Раскладка","Layout"),1,1,1)
        GameTooltip:AddLine(E.Text("Классика: ваша рамка и цель слева сверху, бафы у миникарты, панель внизу по центру, как в старом WoW.","Classic: your frame and the target in the top left, buffs by the minimap, the bar at the bottom centre, as in the old WoW."),0.8,0.8,0.85,true)
        GameTooltip:AddLine(E.Text("Моя: вернуть раскладку, что была до Классики.","Mine: back to the layout from before Classic."),0.8,0.8,0.85,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    layoutButtons[index]=button
end
y=y-24
local checks={}
local function Check(item)
    local check=CreateFrame("Button",nil,menu);check:SetHeight(ROW);check:SetWidth(WIDTH-16)
    check:SetPoint("TOPLEFT",menu,"TOPLEFT",8,y)
    check.box=check:CreateTexture(nil,"ARTWORK");check.box:SetTexture(E.FLAT);check.box:SetWidth(10);check.box:SetHeight(10)
    check.box:SetPoint("LEFT",check,"LEFT",2,0)
    check.edge=check:CreateTexture(nil,"BORDER");check.edge:SetTexture(E.FLAT);check.edge:SetWidth(12);check.edge:SetHeight(12)
    check.edge:SetPoint("CENTER",check.box,"CENTER",0,0);check.edge:SetVertexColor(0.45,0.45,0.55,1)
    check.label=Font(check,10,E.COLORS.text);check.label:SetPoint("LEFT",check.box,"RIGHT",6,0);check.label:SetWidth(WIDTH-40);check.label:SetHeight(ROW)
    check.item=item
    check:SetScript("OnClick",function()
        if type(nfUIDB.edit)~="table" then nfUIDB.edit={} end
        local key=this.item[1]
        if this.item[5]=="db" then nfUIDB[key]=nfUIDB[key]==false
        else nfUIDB.edit[key]=(nfUIDB.edit[key]==false) and true or false end
        if E.RefreshPools then E.RefreshPools() end
        if C.Refresh then C.Refresh() end
        menu.Refresh()
    end)
    table.insert(checks,check)
    y=y-ROW
end
for _,group in ipairs(GROUPS) do
    local head=Font(menu,10,E.COLORS.yellow);head:SetPoint("TOPLEFT",menu,"TOPLEFT",8,y-2);head.group=group
    menu[group[2]]=head
    y=y-15
    for _,item in ipairs(group[3]) do Check(item) end
    y=y-4
end
-- The way to everything else.
local function Link(textRu,textEn,action,x)
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth((WIDTH-16-2)/2)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",x,y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.back:SetVertexColor(E.COLORS.surface[1],E.COLORS.surface[2],E.COLORS.surface[3],1)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.ru=textRu;button.en=textEn
    button:SetScript("OnClick",function() menu:Hide();action() end)
    return button
end
local links={
    Link("Все настройки","All settings",function() SlashCmdList["NFUI"]("") end,8),
    Link("Двигать панели","Move panels",function() C.ToggleMovers() end,8+(WIDTH-16-2)/2+2),
}
y=y-24
menu:SetHeight(-y)
function menu.Refresh()
    local now=E.Mode()
    for _,button in ipairs(modeButtons) do
        local on=button.mode[1]==now
        local c=on and E.COLORS.mauve or E.COLORS.surface
        button.back:SetVertexColor(c[1]*(on and 0.6 or 1),c[2]*(on and 0.6 or 1),c[3]*(on and 0.6 or 1),1)
        button.label:SetText(E.Text(button.mode[2],button.mode[3]))
    end
    local classic=nfUIDB.layoutPreset=="classic"
    for _,button in ipairs(layoutButtons) do
        local on=(button.layout[1]=="classic")==classic
        local c=on and E.COLORS.mauve or E.COLORS.surface
        button.back:SetVertexColor(c[1]*(on and 0.6 or 1),c[2]*(on and 0.6 or 1),c[3]*(on and 0.6 or 1),1)
        button.label:SetText(E.Text(button.layout[2],button.layout[3]))
        -- Nothing to return to before Classic was ever chosen.
        local idle=button.layout[1]=="mine" and not classic and type(nfUIDB.savedLayout)~="table"
        local t=idle and {0.55,0.55,0.6} or E.COLORS.text
        button.label:SetTextColor(t[1],t[2],t[3])
    end
    for _,group in ipairs(GROUPS) do menu[group[2]]:SetText(E.Text(group[1],group[2])) end
    for _,check in ipairs(checks) do
        local key=check.item[1]
        local on
        if check.item[5]=="db" then on=nfUIDB[key]~=false
        else on=not (type(nfUIDB.edit)=="table" and nfUIDB.edit[key]==false) end
        local c=on and E.COLORS.green or E.COLORS.surface
        check.box:SetVertexColor(c[1],c[2],c[3],1)
        local text=E.Text(check.item[2],check.item[3])
        -- A switch that the current mode overrides says so, instead of seeming broken.
        if check.item[4] and now~="detailed" then text=text.." |cff8a8a96("..E.Text("подробный","detailed")..")|r"
        elseif now=="hidden" and on and not E.On(key) then text=text.." |cff8a8a96("..E.Text("скрыто","hidden")..")|r" end
        check.label:SetText(text)
        local t=on and E.COLORS.text or {0.55,0.55,0.6}
        check.label:SetTextColor(t[1],t[2],t[3])
    end
    for _,link in ipairs(links) do link.label:SetText(E.Text(link.ru,link.en)) end
end
function E.ToggleQuickMenu(anchor)
    if menu:IsShown() then menu:Hide();return end
    menu:ClearAllPoints()
    if anchor then menu:SetPoint("TOPRIGHT",anchor,"BOTTOMLEFT",-4,-4) else menu:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    -- Kept on screen.
    menu.Refresh();menu:Show()
    local bottom=menu:GetBottom()
    if bottom and bottom<0 then menu:ClearAllPoints();menu:SetPoint("BOTTOMRIGHT",anchor or UIParent,"BOTTOMLEFT",-4,0) end
end
