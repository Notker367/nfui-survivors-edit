-- The quick menu, a click on the minimap's gear: how much the interface shows and the switches players reach
-- for most. Everything else stays in the full settings.
local E,C=nfUIEdit,nfUIConfig
local MODES={{"hidden","Минимум","Minimal"},{"default","Обычный","Default"},{"detailed","Подробный","Detailed"}}
-- { switch, Russian, English, { what it does, in Russian and English }, "db" when it lives in the profile itself,
--   "cvar" for the game's own option, shown on when that option is off }
local GROUPS={
    {"Опасность","Danger",{
        {"dangerLine","Порог ваншота","One-shot line",{"Красная черта на ХП: ниже неё следующий такой удар убьёт.","A red line on health: below it the next hit like that kills."}},
        {"bossAlert","Предупреждение о боссе","Boss warning",{"Звук и надпись за 10 секунд до босса.","A sound and a line 10 seconds before a boss."}},
        {"metres","Метры до врагов","Metres to enemies",{"Расстояние рядом с полоской врага.","The distance beside an enemy's bar."}}}},
    {"Билд","Build",{
        {"skillPool","Пул скилов","Skill pool",{"Слева: что взято и что ещё может выпасть.","On the left: what you have and what can still drop."}},
        {"jewelPool","Пул бижутерии","Jewelry pool",{"Кольца, талисманы, амулеты и легендарки ваших скилов.","Rings, trinkets, amulets and your skills' legendaries."}}}},
    {"Забег","Run",{
        {"bossSchedule","Боссы","Bosses",{"Справа: отсчёт до каждого босса.","On the right: a countdown to each boss."}},
        {"lairPanel","Стражи","Guardians",{"Справа: когда проснётся каждый страж.","On the right: when each guardian wakes."}},
        {"historyPanel","Ты против лучшего","You against your best",{"DPS сейчас против лучшего забега в ту же секунду.","DPS now against your best run at the same second."}},
        {"deathSummary","Карточка смерти","Death card",{"После смерти: что убило и кнопка разбора.","After a death: what killed you and a review button."}}}},
    {"Графика","Graphics",{
        {"noSpellEffects","Эффекты заклинаний","Spell effects",{"Вспышки и следы заклинаний. Без них проще видеть врагов.","Flashes and trails of spells. Without them enemies are easier to see."},"cvar"}}},
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
local title=Font(menu,12,E.COLORS.mauve);title:SetPoint("TOPLEFT",menu,"TOPLEFT",8,-7);title:SetText(E.NAME)
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
        GameTooltip:AddLine(E.Text("Минимум: только бой. Обычный: плюс боссы, стражи, пулы. Подробный: ещё статы героя и график DPS.","Minimal: the fight only. Default: adds bosses, guardians, pools. Detailed: adds hero stats and the DPS graph."),0.8,0.8,0.85,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    modeButtons[index]=button
end
y=y-24
-- Where everything stands: as in the old game, or the player's own.
local LAYOUTS={{"classic","Классический","Classic"},{"mine","Современный","Modern"}}
local layoutButtons={}
for index,layout in ipairs(LAYOUTS) do
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth((WIDTH-16-2)/2)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",8+(index-1)*((WIDTH-16-2)/2+2),y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.layout=layout
    button:SetScript("OnClick",function()
        -- Modern while Modern is on would put back the panels the player has moved: nothing to do then.
        local classic=nfUIDB.layoutPreset=="classic"
        if E.ApplyLayout and ((this.layout[1]=="classic")~=classic) then E.ApplyLayout(this.layout[1]) end
        menu.Refresh()
    end)
    button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text("Раскладка","Layout"),1,1,1)
        GameTooltip:AddLine(E.Text("Классический: крупные рамки героя и цели слева сверху, кнопки внизу по центру, как в старом WoW.","Classic: large hero and target frames in the top left, buttons at the bottom centre, as in the old WoW."),0.8,0.8,0.85,true)
        GameTooltip:AddLine(E.Text("Современный: всё компактно под героем. Вернёт вашу раскладку, если вы её меняли.","Modern: everything compact under the hero. Brings back your own layout if you changed it."),0.8,0.8,0.85,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    layoutButtons[index]=button
end
y=y-24
-- Text size, three buttons.
local sizeButtons={}
local sizeHead=Font(menu,10,E.COLORS.yellow);sizeHead:SetPoint("TOPLEFT",menu,"TOPLEFT",8,y-4)
for index,size in ipairs(E.TEXT_SIZES or {}) do
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth((WIDTH-16-58-4)/3)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",8+58+(index-1)*((WIDTH-16-58-4)/3+2),y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.size=size
    button:SetScript("OnClick",function() E.SetTextSize(this.size[1]);menu.Refresh() end)
    button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text("Размер текста: ","Text size: ")..E.Text(this.size[3],this.size[4]),1,1,1)
        GameTooltip:AddLine(E.Text("Все шрифты аддона и боковые панели вместе.","All the addon's fonts and side panels together."),0.8,0.8,0.85,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    sizeButtons[index]=button
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
        if this.item[5]=="cvar" then SetCVar(key,GetCVar(key)=="1" and "0" or "1")
        elseif this.item[5]=="db" then nfUIDB[key]=nfUIDB[key]==false
        else E.SetSwitch(key,not E.On(key)) end
        if E.RefreshPools then E.RefreshPools() end
        if C.Refresh then C.Refresh() end
        menu.Refresh()
    end)
    check:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(E.Text(this.item[2],this.item[3]),1,1,1)
        GameTooltip:AddLine(E.Text(this.item[4][1],this.item[4][2]),0.8,0.8,0.85,true)
        if this.item[5]~="cvar" and this.item[5]~="db" and E.SwitchChanged(this.item[1]) then
            GameTooltip:AddLine(E.Text("Изменено вами. Вернуть как в режиме: «Сбросить раздел» в настройках.","Changed by you. Back to the mode's choice: Reset section in the settings."),0.55,0.55,0.6,true)
        end
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave",function() GameTooltip:Hide() end)
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
local function Link(textRu,textEn,action,x,wide)
    local button=CreateFrame("Button",nil,menu);button:SetHeight(18);button:SetWidth(wide and (WIDTH-16) or (WIDTH-16-2)/2)
    button:SetPoint("TOPLEFT",menu,"TOPLEFT",x,y)
    button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
    button.back:SetVertexColor(E.COLORS.surface[1],E.COLORS.surface[2],E.COLORS.surface[3],1)
    button.label=Font(button,10,E.COLORS.text);button.label:SetPoint("CENTER",button,"CENTER",0,0);button.label:SetJustifyH("CENTER")
    button.ru=textRu;button.en=textEn
    button:SetScript("OnClick",function() menu:Hide();action() end)
    return button
end
-- The runs of each class, with picks and builds, in a window of their own.
local reportLink=Link("Анализ забегов","Run analysis",function() if E.ToggleRunReport then E.ToggleRunReport() end end,8,true)
y=y-22
local links={
    reportLink,
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
        button.label:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
    end
    sizeHead:SetText(E.Text("Текст","Text"))
    for _,button in ipairs(sizeButtons) do
        local on=button.size[1]==E.TextSize()
        local c=on and E.COLORS.mauve or E.COLORS.surface
        button.back:SetVertexColor(c[1]*(on and 0.6 or 1),c[2]*(on and 0.6 or 1),c[3]*(on and 0.6 or 1),1)
        -- Short marks: three words do not fit the menu's width.
        button.label:SetText(button.size[1]=="small" and "A-" or (button.size[1]=="large" and "A+" or "A"))
    end
    for _,group in ipairs(GROUPS) do menu[group[2]]:SetText(E.Text(group[1],group[2])) end
    for _,check in ipairs(checks) do
        local key=check.item[1]
        local on
        -- The game's option is "no spell effects": the box shows the effects, so it is on when that option is off.
        if check.item[5]=="cvar" then on=GetCVar(key)~="1"
        elseif check.item[5]=="db" then on=nfUIDB[key]~=false
        else on=E.On(key) end
        local c=on and E.COLORS.green or E.COLORS.surface
        check.box:SetVertexColor(c[1],c[2],c[3],1)
        local text=E.Text(check.item[2],check.item[3])
        -- A switch set by hand over the mode says so.
        if check.item[5]~="cvar" and check.item[5]~="db" and E.SwitchChanged(key) then text=text.." |cff8a8a96*|r" end
        check.label:SetText(text)
        local t=on and E.COLORS.text or {0.55,0.55,0.6}
        check.label:SetTextColor(t[1],t[2],t[3])
    end
    for _,link in ipairs(links) do link.label:SetText(E.Text(link.ru,link.en)) end
end
function E.ToggleQuickMenu(anchor)
    if menu:IsShown() then menu:Hide();return end
    menu:ClearAllPoints()
    if anchor then menu:SetPoint("TOPRIGHT",anchor,"BOTTOMLEFT",-4,-30) else menu:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    -- Kept on screen.
    menu.Refresh();menu:Show()
    local bottom=menu:GetBottom()
    if bottom and bottom<0 then menu:ClearAllPoints();menu:SetPoint("BOTTOMRIGHT",anchor or UIParent,"BOTTOMLEFT",-4,0) end
end
