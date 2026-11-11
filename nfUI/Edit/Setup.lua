-- First start: one window with the two choices that matter most, how much the interface shows and where things
-- stand. Everything else keeps its default and stays a click away on the minimap gear. Shown once to new players;
-- `/nfui setup` opens it again.
local E,C=nfUIEdit,nfUIConfig
local WIDTH,HEIGHT=560,330
local frame=CreateFrame("Frame","nfUISetup",UIParent)
frame:SetWidth(WIDTH);frame:SetHeight(HEIGHT);frame:SetFrameStrata("FULLSCREEN_DIALOG");frame:EnableMouse(true);frame:Hide()
-- Below the middle of the screen, where the game writes "move to begin" over everything.
frame:SetPoint("TOP",UIParent,"CENTER",0,-40)
table.insert(UISpecialFrames,"nfUISetup")
local fill=frame:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT);fill:SetAllPoints(frame)
fill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.97)
E.Polish(frame)
local function Font(parent,size,color,justify)
    local text=parent:CreateFontString(nil,"OVERLAY");text:SetFont(E.FONT,size,"OUTLINE");text:SetJustifyH(justify or "LEFT")
    text:SetTextColor(color[1],color[2],color[3])
    return text
end
local title=Font(frame,15,E.COLORS.mauve);title:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-12)
local intro=Font(frame,11,{0.8,0.8,0.85});intro:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-36);intro:SetWidth(WIDTH-28);intro:SetHeight(30);intro:SetJustifyV("TOP")

-- A row of choices: each a button with a name and a line under it.
local function Choices(top,heading,list,current,pick)
    local head=Font(frame,12,{1,0.82,0.5});head:SetPoint("TOPLEFT",frame,"TOPLEFT",14,top)
    local buttons={}
    local width=(WIDTH-28-(table.getn(list)-1)*8)/table.getn(list)
    for index,choice in ipairs(list) do
        local button=CreateFrame("Button",nil,frame);button:SetWidth(width);button:SetHeight(62)
        button:SetPoint("TOPLEFT",frame,"TOPLEFT",14+(index-1)*(width+8),top-20)
        button.back=button:CreateTexture(nil,"BACKGROUND");button.back:SetTexture(E.FLAT);button.back:SetAllPoints(button)
        button.name=Font(button,12,E.COLORS.text,"CENTER");button.name:SetPoint("TOP",button,"TOP",0,-8)
        button.line=Font(button,10,{0.75,0.75,0.8},"CENTER");button.line:SetPoint("TOP",button.name,"BOTTOM",0,-4)
        button.line:SetWidth(width-10);button.line:SetHeight(28);button.line:SetJustifyV("TOP")
        button.choice=choice
        button:SetScript("OnClick",function() pick(this.choice[1]);frame.Refresh() end)
        buttons[index]=button
    end
    return {head=head,heading=heading,buttons=buttons,current=current}
end
local MODES={
    {"hidden","Минимум","Minimal","Только бой: здоровье, скилы, враги.","Just the fight: health, skills, enemies."},
    {"default","Обычный","Default","Плюс боссы, стражи, история, пулы.","Adds bosses, guardians, history, pools."},
    {"detailed","Подробный","Detailed","Всё: статы героя, график DPS. Для разбора билдов.","Everything: hero stats, DPS graph. For build testing."},
}
local LAYOUTS={
    {"classic","Классика","Classic","Рамки слева сверху, панель внизу, как в старом WoW.","Frames top left, bar at the bottom, as in the old WoW."},
    {"mine","Как есть","As it is","Оставить раскладку этого аддона.","Keep this addon's layout."},
}
local modeRow=Choices(-76,{"Сколько показывать","How much to show"},MODES,function() return E.Mode() end,function(mode)
    nfUIDB.uiMode=mode
    if E.RefreshPools then E.RefreshPools() end
    if C.Refresh then C.Refresh() end
end)
local layoutRow=Choices(-176,{"Раскладка","Layout"},LAYOUTS,function() return nfUIDB.layoutPreset=="classic" and "classic" or "mine" end,function(layout)
    if layout=="classic" and nfUIDB.layoutPreset~="classic" and E.ApplyLayout then E.ApplyLayout("classic")
    elseif layout=="mine" and nfUIDB.layoutPreset=="classic" and E.ApplyLayout then E.ApplyLayout("mine") end
end)
local foot=Font(frame,10,{0.7,0.7,0.75});foot:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",14,14);foot:SetWidth(WIDTH-160);foot:SetHeight(28);foot:SetJustifyV("TOP")
local done=CreateFrame("Button",nil,frame);done:SetWidth(120);done:SetHeight(26);done:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-14,12)
done.back=done:CreateTexture(nil,"BACKGROUND");done.back:SetTexture(E.FLAT);done.back:SetAllPoints(done)
done.back:SetVertexColor(E.COLORS.mauve[1]*0.6,E.COLORS.mauve[2]*0.6,E.COLORS.mauve[3]*0.6,1)
done.label=Font(done,12,E.COLORS.text,"CENTER");done.label:SetPoint("CENTER",done,"CENTER",0,0)
done:SetScript("OnClick",function() nfUIDB.setupDone=true;frame:Hide() end)

function frame.Refresh()
    title:SetText(E.Text("nfUI Survivors Edit: настройка за минуту","nfUI Survivors Edit: a one-minute setup"))
    intro:SetText(E.Text("Выберите, сколько интерфейса видеть и где ему стоять. Всё остальное уже настроено и меняется потом на шестерёнке у миникарты.",
        "Choose how much of the interface to see and where it stands. The rest is set already and changes later on the gear by the minimap."))
    for _,row in ipairs({modeRow,layoutRow}) do
        row.head:SetText(E.Text(row.heading[1],row.heading[2]))
        local now=row.current()
        for _,button in ipairs(row.buttons) do
            local on=button.choice[1]==now
            local c=on and E.COLORS.mauve or E.COLORS.surface
            button.back:SetVertexColor(c[1]*(on and 0.55 or 1),c[2]*(on and 0.55 or 1),c[3]*(on and 0.55 or 1),1)
            button.name:SetText(E.Text(button.choice[2],button.choice[3]))
            button.line:SetText(E.Text(button.choice[4],button.choice[5]))
        end
    end
    foot:SetText(E.Text("Шестерёнка у карты: быстрое меню. Меч рядом: анализ забегов. Снова открыть это окно: /nfui setup",
        "Gear by the map: quick menu. Sword beside it: run analysis. Open this window again: /nfui setup"))
    done.label:SetText(E.Text("Готово","Done"))
end
function E.ShowSetup() frame.Refresh();frame:Show() end

-- Once, a few seconds into the world, for a new player only: one who has played with this addon before has made
-- these choices already.
-- Who is new is decided as soon as the saved settings are in (this client loads them after the addon's files),
-- before the run history can write this run down.
local newPlayer
local watcher=CreateFrame("Frame")
local function Decide()
    if newPlayer~=nil or type(nfUIDB)~="table" then return end
    local played=type(nfUIDB.runHistory)=="table" and nfUIDB.runHistory[1]
    newPlayer=not (nfUIDB.setupDone or played or nfUIDB.uiMode or nfUIDB.layoutPreset)
    if not newPlayer then nfUIDB.setupDone=true end
end
watcher:RegisterEvent("VARIABLES_LOADED")
watcher:SetScript("OnEvent",Decide)
local age=0
watcher:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<4 then return end
    Decide()
    this:SetScript("OnUpdate",nil)
    if newPlayer then E.ShowSetup() end
end)

local command=SlashCmdList["NFUI"]
SlashCmdList["NFUI"]=function(message)
    if string.lower(message or "")=="setup" then E.ShowSetup();return end
    if command then command(message) end
end
