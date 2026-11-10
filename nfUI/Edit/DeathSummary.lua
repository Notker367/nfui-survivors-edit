-- A short card beside the game's own end screen: what kind of death it was, in plain words, and how health and the
-- shield went in the last seconds. The game's "Death recap" lists every hit and enemy; this card does not repeat it.
-- It stays until clicked or a new run starts; `/nfui death` shows it again.
-- Also: a line on the hero's health bar at the biggest hit of the last minute. Below it, one more such hit kills.
local E=nfUIEdit
local WINDOW,KEEP,STEP=5,8,0.1
-- A volley or a single hit is drawn over its last seconds only, where it happened.
local SHORT_WINDOW=2
-- After going down in co-op and getting up, the card goes once the hero has been back in the fight this long.
local BACK_FOR=4
local WIDTH,ROW=300,14
-- The game reports a hit a moment late: the card waits for the last ones.
local SETTLE=1
-- Hits this close together, before the death, count as one volley.
local VOLLEY=1
local GRAPH_BARS,GRAPH_HEIGHT=20,22
local DANGER_KEEP=60
-- The line shows only for hits that matter: at least this share of health and shield together.
local DANGER_SHARE=0.25

local snapshots,hits,bigHits={},{},{}
-- Each hit on the hero, kept a few seconds for the card, and a minute for the danger line.
local heroHit=E.HeroHit
E.HeroHit=function(amount)
    local value=tonumber(amount)
    if value and value>0 then
        local hit={at=GetTime(),amount=value}
        table.insert(hits,hit);table.insert(bigHits,hit)
    end
    if heroHit then return heroHit(amount) end
end

-- The shield the hero wears, which a hit eats before health.
local function Shield()
    local get=nfUIConfig and nfUIConfig.GetShield
    if not get then return 0 end
    local ok,value=pcall(get,"player")
    return ok and tonumber(value) or 0
end
local function NearCount()
    local count=0
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.plate and overlay.plate:IsVisible() and overlay.nearHero and not overlay.petThin then count=count+1 end
    end
    return count
end
local function Snapshot()
    return {at=GetTime(),hp=UnitHealth("player") or 0,hpMax=UnitHealthMax("player") or 0,shield=Shield(),near=NearCount(),
        runTime=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0}
end
local function Trim(now)
    while snapshots[1] and now-snapshots[1].at>KEEP do table.remove(snapshots,1) end
    while hits[1] and now-hits[1].at>KEEP+SETTLE do table.remove(hits,1) end
end
-- The last snapshot taken at or before that moment.
local function At(moment)
    local found
    for _,snap in ipairs(snapshots) do if snap.at<=moment then found=snap end end
    return found or snapshots[1]
end

-- What kind of death: one hit, a volley, a crowd, or a slow wearing down.
local function Verdict(deathAt,last)
    local hpMax=last.hpMax
    local volley,volleyStart={count=0,total=0},nil
    local killHit=0
    for _,hit in ipairs(hits) do
        if hit.at<=deathAt+0.3 and deathAt-hit.at<=VOLLEY then
            volley.count=volley.count+1;volley.total=volley.total+hit.amount
            volleyStart=volleyStart and math.min(volleyStart,hit.at) or hit.at
            if deathAt-hit.at<=0.6 and hit.amount>killHit then killHit=hit.amount end
        end
    end
    local before=volleyStart and At(volleyStart-0.01) or last
    local share=hpMax>0 and before.hp/hpMax or 0
    if volley.count==1 and killHit>=(before.hp+(before.shield or 0))*0.9 and share>=0.5 then
        return {kind="oneshot",hit=killHit,hp=before.hp,shield=before.shield or 0,share=share}
    end
    if volley.count>=2 and share>=0.5 then
        return {kind="volley",count=volley.count,total=volley.total,span=math.max(0.1,deathAt-volleyStart),share=share}
    end
    if (last.near or 0)>=8 then return {kind="crowd",near=last.near} end
    local first=At(deathAt-WINDOW)
    local taken=0
    for _,hit in ipairs(hits) do if hit.at<=deathAt+0.3 and deathAt-hit.at<=WINDOW then taken=taken+hit.amount end end
    return {kind="worn",taken=taken,span=math.max(1,deathAt-(first and first.at or deathAt))}
end

local function Summarize(deathAt,how)
    local last=At(deathAt)
    if not last then return nil end
    local verdict=Verdict(deathAt,last)
    -- Health over the last seconds, oldest first, as shares of the most; and when the shield last held.
    local span=(verdict.kind=="volley" or verdict.kind=="oneshot") and SHORT_WINDOW or WINDOW
    local hpLine={}
    for index=1,GRAPH_BARS do
        local snap=At(deathAt-span+(index-1)*span/(GRAPH_BARS-1))
        hpLine[index]=(snap and snap.hpMax>0 and snap.at>=deathAt-span-STEP) and snap.hp/snap.hpMax or -1
    end
    hpLine[GRAPH_BARS]=0
    local shieldPeak,shieldGone=0,nil
    for _,snap in ipairs(snapshots) do
        if deathAt-snap.at<=WINDOW and snap.at<=deathAt then
            if (snap.shield or 0)>shieldPeak then shieldPeak=snap.shield end
            if (snap.shield or 0)>=1 then shieldGone=nil elseif shieldPeak>0 and not shieldGone then shieldGone=snap.at end
        end
    end
    return {runTime=last.runTime,level=UnitLevel("player"),verdict=verdict,hpLine=hpLine,graphSpan=span,how=how,
        shieldPeak=shieldPeak,shieldGone=shieldGone and (deathAt-shieldGone) or nil,shieldLeft=last.shield or 0}
end

-- The card.
local frame=CreateFrame("Button","nfUIDeathSummary",UIParent)
frame:SetWidth(WIDTH);frame:SetFrameStrata("DIALOG");frame:EnableMouse(true);frame:Hide()
frame:RegisterForClicks("LeftButtonUp","RightButtonUp")
frame:SetScript("OnClick",function() this:Hide() end)
-- To the right of the game's end screen, level with its top; that screen grows with the window's height.
local function Place()
    local height=GetScreenHeight()
    frame:ClearAllPoints();frame:SetPoint("TOPLEFT",UIParent,"TOP",height*0.27,-height*0.15)
end
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
local verdictText=Text(12,E.COLORS.yellow);verdictText:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-26);verdictText:SetWidth(WIDTH-16);verdictText:SetHeight(ROW*2+4)
local shieldText=Text(10,E.COLORS.sapphire or E.COLORS.text);shieldText:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-26-ROW*2-6);shieldText:SetWidth(WIDTH-16);shieldText:SetHeight(ROW)
-- Health over the last five seconds: a bar for each moment, red when low.
local GRAPH_TOP=26+ROW*3+10
local graphCaption=Text(9,{0.55,0.55,0.6});graphCaption:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-GRAPH_TOP)
local graphBack=frame:CreateTexture(nil,"BORDER");graphBack:SetTexture(E.FLAT);graphBack:SetVertexColor(0,0,0,0.35)
graphBack:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-GRAPH_TOP-11);graphBack:SetWidth(WIDTH-16);graphBack:SetHeight(GRAPH_HEIGHT)
local graph={}
local barWidth=(WIDTH-16)/GRAPH_BARS
for index=1,GRAPH_BARS do
    local bar=frame:CreateTexture(nil,"ARTWORK");bar:SetTexture(E.FLAT);bar:SetWidth(math.max(1,barWidth-1))
    bar:SetPoint("BOTTOMLEFT",graphBack,"BOTTOMLEFT",(index-1)*barWidth,0)
    graph[index]=bar
end
frame:SetHeight(GRAPH_TOP+11+GRAPH_HEIGHT+8)

local function Clock(seconds)
    seconds=math.max(0,math.floor((seconds or 0)+0.5))
    return string.format("%d:%02d",math.floor(seconds/60),math.mod(seconds,60))
end
local function Percent(share) return math.floor((share or 0)*100+0.5) end
local function VerdictText(v)
    if type(v)~="table" then return "" end
    if v.kind=="oneshot" then
        local text=string.format(E.Text("Ваншот: один удар %s при %s здоровья (%d%%)","One-shot: a single hit of %s at %s health (%d%%)"),
            E.Short(v.hit),E.Short(v.hp),Percent(v.share))
        if (v.shield or 0)>=1 then text=text..E.Text(" и щите "," and a shield of ")..E.Short(v.shield) end
        return text
    elseif v.kind=="volley" then
        return string.format(E.Text("Залп: %d ударов за %.1f с, %s урона, здоровье с %d%% до нуля","Volley: %d hits in %.1f s, %s damage, health from %d%% to nothing"),
            v.count,v.span,E.Short(v.total),Percent(v.share))
    elseif v.kind=="crowd" then
        return string.format(E.Text("Задавили: рядом %d врагов","Swarmed: %d enemies near"),v.near or 0)
    end
    return string.format(E.Text("Сточили: %s урона за %d с","Worn down: %s damage in %d s"),E.Short(v.taken or 0),math.floor((v.span or 0)+0.5))
end
local function ShieldLine(summary)
    if (summary.shieldPeak or 0)<1 then return E.Text("Щита не было","No shield") end
    if summary.shieldGone then
        return string.format(E.Text("Щит до %s сбит за %.1f с до смерти","Shield of up to %s broken %.1f s before the death"),E.Short(summary.shieldPeak),summary.shieldGone)
    end
    return string.format(E.Text("Щит держался до конца: осталось %s","The shield held to the end: %s left"),E.Short(summary.shieldLeft or 0))
end
function E.ShowDeathSummary(summary)
    summary=summary or (type(nfUIDB)=="table" and nfUIDB.lastDeath)
    if type(summary)~="table" or type(summary.verdict)~="table" then
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("nfUI: "..E.Text("смертей в этой сессии ещё не было","no death recorded yet")) end
        return
    end
    -- In co-op the hero goes down first and may be raised.
    title:SetText((summary.how=="down" and E.Text("Упал","Down") or E.Text("Смерть","Death")).."  "..Clock(summary.runTime)..(summary.level and (E.Text("  · ур. ","  · lvl ")..summary.level) or ""))
    close:SetText(E.Text("клик: закрыть","click to close"))
    verdictText:SetText(VerdictText(summary.verdict))
    shieldText:SetText(ShieldLine(summary))
    local span=summary.graphSpan or WINDOW
    graphCaption:SetText(string.format(E.Text("Здоровье за последние %d с","Health over the last %d s"),span))
    local low,high=E.COLORS.red,E.COLORS.green
    for index,bar in ipairs(graph) do
        local share=summary.hpLine and summary.hpLine[index] or -1
        if share>=0 then
            bar:SetVertexColor(low[1]+(high[1]-low[1])*share,low[2]+(high[2]-low[2])*share,low[3]+(high[3]-low[3])*share,0.9)
            bar:SetHeight(math.max(1,GRAPH_HEIGHT*share));bar:Show()
        else bar:Hide() end
    end
    Place();frame:Show()
end

-- Watching: snapshots while the run goes on, the card a moment after the hero dies or goes down.
local wasAlive,lastRunTime,age,deathAt,deathHow,backSince=true,0,0,nil,nil,nil
-- "dead", "down" (co-op, can be raised), or nil while standing.
local function IsDown(run)
    if run.ph=="dead" then return "dead" end
    for _,unit in ipairs(type(AZS_DOWNED)=="table" and AZS_DOWNED or {}) do
        if type(unit)=="table" and unit.name==UnitName("player") and unit.state=="down" then return "down" end
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return "dead" end
    return nil
end
local driver=CreateFrame("Frame","nfUIDeathWatch")
driver:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<STEP then return end;age=0
    local run=type(AZS_RUN)=="table" and AZS_RUN or nil
    if not run then return end
    local runTime=tonumber(run.t) or 0
    -- A new run: the old card goes.
    if runTime<lastRunTime then frame:Hide();snapshots={};hits={};bigHits={};wasAlive=true;deathAt=nil;backSince=nil end
    lastRunTime=runTime
    local now=GetTime()
    if deathAt and now-deathAt>=SETTLE then
        local at=deathAt;deathAt=nil
        local ok,summary=pcall(Summarize,at,deathHow)
        if ok and summary then
            if type(nfUIDB)=="table" then nfUIDB.lastDeath=summary end
            if E.On("deathSummary") then E.ShowDeathSummary(summary);frame.auto=true end
        end
    end
    local down=IsDown(run)
    if not down then
        if run.ph=="playing" then
            table.insert(snapshots,Snapshot());Trim(now)
            -- Raised and fighting again: the card has been read, it goes.
            if frame.auto and frame:IsVisible() and not deathAt then
                backSince=backSince or now
                if now-backSince>=BACK_FOR then frame:Hide();backSince=nil end
            end
        end
        wasAlive=true
    elseif wasAlive then
        wasAlive=false;deathAt=now;deathHow=down;backSince=nil
    end
end)

-- The danger line: on the hero's health bar, at the biggest hit taken in the last minute. While health and shield
-- together are under it, the bar's edge pulses red and a note beside the frame says so.
local danger
local function DangerParts(widget)
    if danger and danger.widget==widget then return danger end
    local bar=widget.health
    danger={widget=widget}
    danger.line=bar:CreateTexture(nil,"OVERLAY");danger.line:SetTexture(E.FLAT);danger.line:SetVertexColor(1,0.25,0.2,0.95);danger.line:SetWidth(2)
    danger.edge=E.Edge(bar,1,0.2,0.15,1);danger.edge.SetSize(2);danger.edge.Hide()
    -- Beside the frame, not above it, where the buffs are.
    danger.label=bar:CreateFontString(nil,"OVERLAY");danger.label:SetFont(E.FONT,10,"OUTLINE");danger.label:SetTextColor(1,0.35,0.3)
    danger.label:SetPoint("LEFT",widget,"RIGHT",6,0)
    return danger
end
local function Biggest(now)
    while bigHits[1] and now-bigHits[1].at>DANGER_KEEP do table.remove(bigHits,1) end
    local biggest=0
    for _,hit in ipairs(bigHits) do if hit.amount>biggest then biggest=hit.amount end end
    return biggest
end
local pulse,dangerAge=0,0
local watcher=CreateFrame("Frame","nfUIDangerWatch")
watcher:SetScript("OnUpdate",function()
    local elapsed=arg1 or 0
    pulse=pulse+elapsed;dangerAge=dangerAge+elapsed
    local widget=getglobal("nfUIPlayer")
    if not widget or not widget.health then return end
    local parts=DangerParts(widget)
    if dangerAge>=0.1 then
        dangerAge=0
        local biggest=Biggest(GetTime())
        local hp,most=UnitHealth("player") or 0,UnitHealthMax("player") or 0
        local inRun=AZS_GetPhase and AZS_GetPhase()=="playing"
        local shield=Shield()
        if E.On("dangerLine") and inRun and biggest>0 and most>0 and hp>0 and biggest>=(hp+shield)*DANGER_SHARE then
            local x=widget.health:GetWidth()*math.min(1,biggest/most)
            parts.line:ClearAllPoints()
            parts.line:SetPoint("TOP",widget.health,"TOPLEFT",x,0);parts.line:SetPoint("BOTTOM",widget.health,"BOTTOMLEFT",x,0)
            parts.line:Show()
            -- The shield is drawn right after health, so the two together are read against the line.
            parts.deadly=hp+shield<=biggest
            if parts.deadly then
                parts.label:SetText(E.Text("Следующий такой удар убьёт: ","The next such hit kills: ")..E.Short(biggest)
                    ..(shield>=1 and E.Text(" (щит не спасёт)"," (the shield will not save you)") or ""))
                parts.label:Show()
            else parts.label:Hide() end
        else
            parts.line:Hide();parts.label:Hide();parts.deadly=false
        end
    end
    if parts.deadly then parts.edge.SetColor(1,0.2,0.15,0.7+0.3*math.sin(pulse*8));parts.edge.Show() else parts.edge.Hide() end
end)

local command=SlashCmdList["NFUI"]
SlashCmdList["NFUI"]=function(message)
    if string.lower(message or "")=="death" then E.ShowDeathSummary();frame.auto=false;return end
    if command then command(message) end
end
