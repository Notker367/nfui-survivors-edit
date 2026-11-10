-- What killed the hero: the last seconds before a death, or before going down in co-op, in one panel.
-- The game reports damage by kind of source, not by enemy, so the kinds are shown, and the bars over the enemies
-- tell who stood near. The panel stays until it is clicked or a new run starts; `/nfui death` shows it again.
local E=nfUIEdit
local WINDOW,KEEP,STEP=5,8,0.25
local WIDTH,ROW=300,14
local KIND_NAMES={elite={"элитка","elite"},guardian={"страж","guardian"},boss={"босс","boss"}}

local snapshots,hits={},{}
-- Each hit on the hero, kept a few seconds, for the biggest and the last ones.
local heroHit=E.HeroHit
E.HeroHit=function(amount)
    local value=tonumber(amount)
    if value and value>0 then table.insert(hits,{at=GetTime(),amount=value}) end
    if heroHit then return heroHit(amount) end
end

local function ActiveHealing()
    local total=0
    for _,line in ipairs(type(AZS_HEALING)=="table" and AZS_HEALING or {}) do
        if type(line)=="table" and line.name~="Regeneration" and line.name~="Восполнение" and line.name~="Регенерация" then
            total=total+(tonumber(line.dmg) or 0)
        end
    end
    return total
end
local function Near()
    local count,named=0,{}
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.plate and overlay.plate:IsVisible() and overlay.nearHero and not overlay.petThin then
            count=count+1
            local kind=overlay.kind
            local name=overlay.stock and overlay.stock.name and overlay.stock.name:GetText()
            if KIND_NAMES[kind] and name then table.insert(named,{kind=kind,name=name}) end
        end
    end
    return count,named
end
local function Snapshot()
    local taken={}
    for _,line in ipairs(type(AZS_TAKEN)=="table" and AZS_TAKEN or {}) do
        if type(line)=="table" and line.source and tonumber(line.dmg) then taken[tostring(line.source)]=tonumber(line.dmg) end
    end
    local count,named=Near()
    return {at=GetTime(),hp=UnitHealth("player") or 0,hpMax=UnitHealthMax("player") or 0,taken=taken,healed=ActiveHealing(),
        runTime=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0,near=count,named=named}
end
local function Trim(now)
    while snapshots[1] and now-snapshots[1].at>KEEP do table.remove(snapshots,1) end
    while hits[1] and now-hits[1].at>KEEP do table.remove(hits,1) end
end
-- The snapshot from about this many seconds ago.
local function Ago(seconds,now)
    local found=snapshots[1]
    for _,snap in ipairs(snapshots) do if now-snap.at>=seconds then found=snap end end
    return found
end

local function Summarize()
    local now=GetTime()
    local last=snapshots[table.getn(snapshots)]
    if not last then return nil end
    local first=Ago(WINDOW,now)
    local second=Ago(1,now)
    local sources,total={},0
    for source,amount in pairs(last.taken) do
        local delta=amount-((first and first.taken[source]) or 0)
        if delta>=1 then total=total+delta;table.insert(sources,{source=source,dmg=delta,final=amount-((second and second.taken[source]) or 0)}) end
    end
    table.sort(sources,function(a,b) return a.dmg>b.dmg end)
    -- What landed in the last second.
    local killer
    for _,line in ipairs(sources) do if line.final>=1 and (not killer or line.final>killer.final) then killer=line end end
    local span=math.max(1,last.at-(first and first.at or last.at))
    local biggest,lastHit=0,nil
    for _,hit in ipairs(hits) do
        if now-hit.at<=WINDOW then
            if hit.amount>biggest then biggest=hit.amount end
            lastHit=hit
        end
    end
    -- From half health down to nothing.
    local fall
    local maxHp=last.hpMax
    for index=table.getn(snapshots),1,-1 do
        local snap=snapshots[index]
        if maxHp>0 and snap.hp>=maxHp*0.5 then fall=last.at-snap.at;break end
    end
    return {runTime=last.runTime,level=UnitLevel("player"),sources=sources,total=total,perSecond=total/span,span=span,
        healed=math.max(0,last.healed-(first and first.healed or last.healed)),killer=killer and killer.source,
        lastHit=lastHit and lastHit.amount,biggest=biggest,fall=fall,near=last.near,named=last.named}
end

-- The panel.
local frame=CreateFrame("Button","nfUIDeathSummary",UIParent)
frame:SetWidth(WIDTH);frame:SetFrameStrata("DIALOG");frame:EnableMouse(true);frame:Hide()
frame:SetPoint("TOP",UIParent,"TOP",0,-110)
frame:RegisterForClicks("LeftButtonUp","RightButtonUp")
frame:SetScript("OnClick",function() this:Hide() end)
local fill=frame:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT);fill:SetAllPoints(frame)
fill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.92)
E.Polish(frame)
local function Text(size,color,justify)
    local text=frame:CreateFontString(nil,"OVERLAY");text:SetFont(E.FONT,size,"OUTLINE");text:SetJustifyH(justify or "LEFT")
    text:SetTextColor(color[1],color[2],color[3])
    return text
end
local title=Text(13,E.COLORS.red);title:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-7)
local close=Text(10,{0.55,0.55,0.6},"RIGHT");close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-8,-9)
local lines={}
for index=1,4 do
    local line=Text(10,E.COLORS.text);line:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-26-(index-1)*ROW);line:SetWidth(WIDTH-16);line:SetHeight(ROW)
    lines[index]=line
end
local rows={}
for index=1,5 do
    local row={}
    local y=-26-4*ROW-6-(index-1)*ROW
    row.bar=frame:CreateTexture(nil,"BORDER");row.bar:SetTexture(E.FLAT);row.bar:SetHeight(ROW-2)
    row.bar:SetPoint("TOPLEFT",frame,"TOPLEFT",6,y+1);row.bar:SetVertexColor(E.COLORS.red[1],E.COLORS.red[2],E.COLORS.red[3],0.35)
    row.left=Text(10,E.COLORS.text);row.left:SetPoint("TOPLEFT",frame,"TOPLEFT",10,y)
    row.right=Text(10,E.COLORS.text,"RIGHT");row.right:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10,y)
    rows[index]=row
end
local near=Text(10,{0.75,0.75,0.8});near:SetWidth(WIDTH-16);near:SetHeight(ROW*2)

local function SourceName(source)
    local name=E.TAKEN_SOURCES and E.TAKEN_SOURCES[source]
    return name and E.Text(name[1],name[2]) or tostring(source)
end
local function Clock(seconds)
    seconds=math.max(0,math.floor((seconds or 0)+0.5))
    return string.format("%d:%02d",math.floor(seconds/60),math.mod(seconds,60))
end
function E.ShowDeathSummary(summary)
    summary=summary or (type(nfUIDB)=="table" and nfUIDB.lastDeath)
    if type(summary)~="table" then
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("nfUI: "..E.Text("смертей в этой сессии ещё не было","no death recorded yet")) end
        return
    end
    title:SetText(E.Text("Смерть","Death").."  "..Clock(summary.runTime)..(summary.level and (E.Text("  · ур. ","  · lvl ")..summary.level) or ""))
    close:SetText(E.Text("клик: закрыть","click to close"))
    lines[1]:SetText(E.Text("Добило: ","Finished by: ").."|cffff7070"..(summary.killer and SourceName(summary.killer) or "?").."|r"
        ..(summary.lastHit and (E.Text(", последний удар ",", last hit ")..E.Short(summary.lastHit)) or ""))
    lines[2]:SetText(string.format(E.Text("За %d сек: %s урона (%s/с), лечение +%s","In %d sec: %s damage (%s/s), healing +%s"),
        math.floor(summary.span+0.5),E.Short(summary.total),E.Short(summary.perSecond),E.Short(summary.healed or 0)))
    lines[3]:SetText(summary.fall and string.format(E.Text("Здоровье с 50%% до нуля за %.1f сек","Health from 50%% to nothing in %.1f sec"),summary.fall)
        or E.Text("Здоровье ниже половины всё окно","Health below half the whole time"))
    lines[4]:SetText(summary.biggest and summary.biggest>0 and (E.Text("Самый большой удар: ","Biggest hit: ")..E.Short(summary.biggest)) or "")
    local shown=0
    for index,row in ipairs(rows) do
        local line=summary.sources and summary.sources[index]
        if line then
            shown=index
            row.left:SetText(SourceName(line.source))
            row.right:SetText(E.Short(line.dmg).."  |cff8a8a96"..string.format("%.0f%%",100*line.dmg/math.max(1,summary.total)).."|r")
            row.bar:SetWidth(math.max(1,(WIDTH-12)*line.dmg/math.max(1,summary.sources[1].dmg)));row.bar:Show()
            row.left:Show();row.right:Show()
        else row.left:Hide();row.right:Hide();row.bar:Hide() end
    end
    local text=string.format(E.Text("Рядом врагов: %d","Enemies near: %d"),summary.near or 0)
    local named={}
    for _,unit in ipairs(summary.named or {}) do
        if table.getn(named)<4 then
            local kind=KIND_NAMES[unit.kind]
            table.insert(named,unit.name..(kind and (" ("..E.Text(kind[1],kind[2])..")") or ""))
        end
    end
    if table.getn(named)>0 then text=text..". "..table.concat(named,", ") end
    near:SetText(text)
    near:ClearAllPoints();near:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-26-4*ROW-6-shown*ROW-4)
    frame:SetHeight(26+4*ROW+6+shown*ROW+4+ROW*2+6)
    frame:Show()
end

-- Watching: snapshots while the run goes on, a summary the moment the hero dies or goes down.
local wasAlive,lastRunTime,age=true,0,0
local driver=CreateFrame("Frame","nfUIDeathWatch")
driver:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<STEP then return end;age=0
    local run=type(AZS_RUN)=="table" and AZS_RUN or nil
    if not run then return end
    local runTime=tonumber(run.t) or 0
    -- A new run: the old panel goes.
    if runTime<lastRunTime then frame:Hide();snapshots={};hits={};wasAlive=true end
    lastRunTime=runTime
    local down=run.ph=="dead" or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
    if not down then
        for _,unit in ipairs(type(AZS_DOWNED)=="table" and AZS_DOWNED or {}) do
            if type(unit)=="table" and unit.name==UnitName("player") and unit.state=="down" then down=true end
        end
    end
    local now=GetTime()
    if not down then
        if run.ph=="playing" then table.insert(snapshots,Snapshot());Trim(now) end
        wasAlive=true
    elseif wasAlive then
        wasAlive=false
        local ok,summary=pcall(Summarize)
        if ok and summary then
            if type(nfUIDB)=="table" then nfUIDB.lastDeath=summary end
            if E.On("deathSummary") then E.ShowDeathSummary(summary) end
        end
    end
end)

local command=SlashCmdList["NFUI"]
SlashCmdList["NFUI"]=function(message)
    if string.lower(message or "")=="death" then E.ShowDeathSummary();return end
    if command then command(message) end
end
