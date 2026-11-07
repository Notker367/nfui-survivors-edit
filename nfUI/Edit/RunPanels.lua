-- Run panels from the game's own data: the bosses to come, the guardians and when they return, what has hurt the
-- hero, and this run's damage per second against earlier runs at the same moment.
local E=nfUIEdit
local ROW_HEIGHT,ROWS,WIDTH=14,5,200
local SOURCES={
    ["mob melee"]={"Удары врагов","Enemy melee"},["mob spell"]={"Заклинания врагов","Enemy spells"},
    ["boss melee"]={"Удары боссов","Boss melee"},["boss spell"]={"Заклинания боссов","Boss spells"},
    ["area"]={"Урон по области","Area damage"},["elite"]={"Элитные враги","Elites"},["guardian"]={"Стражи","Guardians"},
}
local RUN_PHASES={playing=true,choosing=true,paused=true}
local DONE={0.5,0.5,0.56}

local function Panel(frame,title,key,rowCount,moverKey)
    local c=E.COLORS
    local fill=frame:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT)
    fill:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0);fill:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
    frame.fill=fill;frame.key=key;frame.fullHeight=frame:GetHeight();frame.moverKey=moverKey
    fill:SetVertexColor(c.base[1],c.base[2],c.base[3],0.75)
    local function Fold()
        local folded=E.IsCollapsed(key)
        fill:SetHeight(folded and 20 or frame.fullHeight)
        -- The panel really shrinks, so the ones below move up; one placed by hand keeps its top where it is.
        local height=folded and 20 or frame.fullHeight
        local spot=frame.moverKey and type(nfUIDB)=="table" and type(nfUIDB.positions)=="table" and nfUIDB.positions[frame.moverKey]
        if spot and type(spot.y)=="number" and frame:GetHeight()~=height then
            spot.y=spot.y+(frame:GetHeight()-height)*frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        end
        frame:SetHeight(height)
        if spot and nfUIConfig.ApplyPositions then nfUIConfig.ApplyPositions() end
        for _,row in ipairs(frame.rows or {}) do
            if folded then row.left:Hide();row.right:Hide();row.bar:SetAlpha(0) else row.left:Show();row.right:Show();row.bar:SetAlpha(1) end
        end
    end
    frame.Fold=Fold
    E.Collapsible(frame,key,title,Fold)
    frame.rows={}
    for index=1,rowCount or ROWS do
        local row={}
        local y=-20-(index-1)*ROW_HEIGHT
        row.bar=frame:CreateTexture(nil,"BORDER");row.bar:SetTexture(E.FLAT);row.bar:SetHeight(ROW_HEIGHT-2)
        row.bar:SetPoint("TOPLEFT",frame,"TOPLEFT",4,y+1);row.bar:SetVertexColor(c.red[1],c.red[2],c.red[3],0.35);row.bar:Hide()
        row.left=frame:CreateFontString(nil,"OVERLAY");row.left:SetFont(E.FONT,10,"OUTLINE");row.left:SetPoint("TOPLEFT",frame,"TOPLEFT",6,y)
        row.left:SetWidth(WIDTH-72);row.left:SetHeight(ROW_HEIGHT-2);row.left:SetJustifyH("LEFT")
        row.right=frame:CreateFontString(nil,"OVERLAY");row.right:SetFont(E.FONT,10,"OUTLINE");row.right:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,y)
        frame.rows[index]=row
    end
    Fold()
end
local function Clear(row) row.left:SetText("");row.right:SetText("");row.bar:Hide() end
local function Clock(seconds)
    seconds=math.max(0,math.floor(seconds+0.5))
    return string.format("%d:%02d",math.floor(seconds/60),math.mod(seconds,60))
end

local bossFrame,takenFrame=E.blocks.bosses,E.blocks.taken
Panel(bossFrame,E.Text("Боссы","Bosses"),"bosses",nil,"blockBosses")
Panel(takenFrame,E.Text("Кто бьёт героя","Damage taken"),"taken",nil,"blockTaken")
local lairFrame,historyFrame=E.blocks.lairs,E.blocks.history
local LAIR_ROWS,HISTORY_ROWS=4,6
Panel(lairFrame,E.Text("Стражи","Guardians"),"lairs",LAIR_ROWS,"blockLairs")
Panel(historyFrame,E.Text("История: DPS сейчас","History: DPS now"),"history",HISTORY_ROWS,"blockHistory")
local foldedOnce
local statsFrame,graphFrame=E.blocks.stats,E.blocks.graph
local STAT_ROWS,GRAPH_BARS,GRAPH_HEIGHT=10,24,38
Panel(statsFrame,E.Text("Герой","Hero"),"stats",STAT_ROWS,"blockStats")
Panel(graphFrame,E.Text("DPS по времени","DPS over time"),"graph",0,"blockGraph")
for _,row in ipairs(statsFrame.rows) do row.left:SetWidth(90) end

local warned={}
-- What a folded panel says in its title: words at the left, numbers at the right where they are never cut.
local function Summarize(frame,text,color,value)
    local header=frame.collapseHeader
    if not header then return end
    header.summary=text;header.summaryValue=value;header.summaryColor=color or E.COLORS.text
    header.Refresh()
end
-- Each row's numbers keep their full width; the name beside them gives way.
local function Fit(frame)
    if E.IsCollapsed(frame.key) then return end
    local width=frame:GetWidth()
    for _,row in ipairs(frame.rows or {}) do
        local text=row.right:GetText()
        local used=(text and text~="") and (row.right:GetStringWidth()+8) or 0
        row.left:SetWidth(math.max(20,width-12-used))
    end
end
local function UpdateBosses()
    local now=AZS_GetRunTime and AZS_GetRunTime() or 0
    local c=E.COLORS
    local shown=0
    bossFrame.nextBoss=nil
    for _,boss in ipairs(type(AZS_SCHEDULE)=="table" and AZS_SCHEDULE or {}) do
        if boss.state=="due" and tonumber(boss.at) and not bossFrame.nextBoss then bossFrame.nextBoss=boss end
        if shown<ROWS and type(boss)=="table" and tonumber(boss.at) then
            shown=shown+1
            local row=bossFrame.rows[shown]
            local left=boss.at-now
            local color=c.text
            row.left:SetText(boss.name or "?")
            if boss.state=="due" then
                row.right:SetText(Clock(left))
                if left>0 and left<=10 and E.On("bossAlert") then
                    local key=tostring(type(AZS_ZONE)=="table" and AZS_ZONE.run).."/"..tostring(boss.index)
                    if not warned[key] then
                        warned[key]=true
                        E.Alert(E.Text("Босс через 10 сек: ","Boss in 10 sec: ")..(boss.name or "?"))
                    end
                end
                if left<=10 then color=c.red elseif left<=30 then color=c.yellow elseif boss.final==1 then color=c.mauve end
            else
                -- Up or already beaten: the game only says it is no longer to come.
                row.right:SetText("-");color=DONE
            end
            row.left:SetTextColor(color[1],color[2],color[3]);row.right:SetTextColor(color[1],color[2],color[3])
        end
    end
    for index=shown+1,ROWS do Clear(bossFrame.rows[index]) end
    local nextBoss=bossFrame.nextBoss
    if nextBoss then
        local left=nextBoss.at-now
        Summarize(bossFrame,nextBoss.name or "?",left<=10 and c.red or left<=30 and c.yellow or c.text,Clock(left))
    else Summarize(bossFrame,E.Text("Боссов больше нет","No bosses left"),DONE) end
    return shown>0
end
local function ByDamage(a,b) return a.dmg>b.dmg end
-- Each source's damage per second over the last ten seconds, from the run's totals sampled as they come.
local RATE_WINDOW=10
local samples={}
local function RateOf(source,amount,now)
    local list=samples[source]
    if not list then list={};samples[source]=list end
    table.insert(list,{at=now,dmg=amount})
    while list[2] and now-list[2].at>=RATE_WINDOW do table.remove(list,1) end
    local first=list[1]
    local span=math.max(1,now-first.at)
    return math.max(0,(amount-first.dmg)/span)
end
local function ByRate(a,b) if a.rate~=b.rate then return a.rate>b.rate end;return a.dmg>b.dmg end
local function UpdateTaken()
    local lines,total={},0
    local now=GetTime()
    for _,line in ipairs(type(AZS_TAKEN)=="table" and AZS_TAKEN or {}) do
        local amount=type(line)=="table" and tonumber(line.dmg)
        if amount and amount>0 then total=total+amount;table.insert(lines,{source=line.source,dmg=amount,rate=RateOf(tostring(line.source),amount,now)}) end
    end
    -- What hurts now comes first; the run's total is in brackets.
    table.sort(lines,ByRate)
    local perSecond=E.Text("/с","/s")
    local language=E.IsRussian() and 1 or 2
    for index=1,ROWS do
        local row,line=takenFrame.rows[index],lines[index]
        if line then
            local name=SOURCES[line.source]
            row.left:SetText(name and name[language] or tostring(line.source))
            row.left:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
            row.right:SetText(E.Short(line.rate)..perSecond.."  |cff8a8a96"..E.Text("всего ","total ")..E.Short(line.dmg).."|r")
            row.right:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
            local top=math.max(1,lines[1].rate)
            row.bar:SetWidth(math.max(1,(WIDTH-8)*line.rate/top));row.bar:Show()
        else Clear(row) end
    end
    if lines[1] then
        local name=SOURCES[lines[1].source]
        local biggest=E.BiggestRecentHit and E.BiggestRecentHit() or 0
        local all=0
        for _,line in ipairs(lines) do all=all+line.rate end
        Summarize(takenFrame,name and name[language] or tostring(lines[1].source),E.COLORS.enemy,E.Short(all)..perSecond..(biggest>0 and (E.Text("  макс ","  max ")..E.Short(biggest)) or ""))
    end
    return total>0
end
-- Guardians. An empty lair counts down to its guardian; one killed is remembered with the time of its death.
local killedAt,wasHolding={},{}
local function UpdateLairs()
    local c=E.COLORS
    local now=AZS_GetRunTime and AZS_GetRunTime() or 0
    local health={}
    for _,unit in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
        if type(unit)=="table" and unit.id then health[unit.id]=unit end
    end
    local shown=0
    -- For the folded title: one awake first, then the nearest to appear, then the one the game points at.
    local awake,soonest,flagged
    for _,lair in ipairs(type(AZS_LAIRS)=="table" and AZS_LAIRS or {}) do
        if shown<LAIR_ROWS and type(lair)=="table" then
            shown=shown+1
            local row=lairFrame.rows[shown]
            local index=lair.index or shown
            local empty=lair.state=="empty"
            if wasHolding[index] and empty then killedAt[index]=now end
            wasHolding[index]=not empty
            if not empty then killedAt[index]=nil end
            local unit=lair.id and health[lair.id]
            local color,text=c.text,""
            if lair.state~="empty" and lair.state~="asleep" and not awake then awake=lair end
            if empty and tonumber(lair.left) and tonumber(lair.left)>=0 and (not soonest or tonumber(lair.left)<tonumber(soonest.left)) then soonest=lair end
            if lair.flag==1 then flagged=lair end
            if empty then
                local left=tonumber(lair.left)
                if left and left>=0 then
                    text=Clock(left);color=left<=10 and c.yellow or c.text
                else text="-";color=DONE end
            elseif lair.state=="asleep" then text=E.Text("спит","asleep");color=DONE
            else
                text=E.Text("активен","awake");color=c.peach
                if unit and tonumber(unit.hpm) and tonumber(unit.hpm)>0 then text=E.Short(tonumber(unit.hp))..E.Text(" ХП"," HP") end
            end
            if killedAt[index] then text=E.Text("убит ","slain ")..Clock(killedAt[index]).."  "..text end
            row.left:SetText((lair.flag==1 and "> " or "")..(lair.name or "?"))
            row.left:SetTextColor(color[1],color[2],color[3]);row.right:SetText(text);row.right:SetTextColor(color[1],color[2],color[3])
        end
    end
    for index=shown+1,LAIR_ROWS do Clear(lairFrame.rows[index]) end
    if awake then
        local unit=awake.id and health[awake.id]
        local share=unit and tonumber(unit.hpm) and tonumber(unit.hpm)>0 and (E.Short(tonumber(unit.hp))..E.Text(" ХП"," HP")) or E.Text("активен","awake")
        Summarize(lairFrame,awake.name or "?",c.peach,share)
    elseif soonest then Summarize(lairFrame,soonest.name or "?",tonumber(soonest.left)<=10 and c.yellow or c.text,Clock(tonumber(soonest.left)))
    elseif flagged then Summarize(lairFrame,"> "..(flagged.name or "?"),c.text)
    else Summarize(lairFrame,E.Text("Стражи","Guardians"),DONE) end
    return shown>0
end

-- History. Every 30 seconds of a run its total damage is written down, so any moment of it can be compared later.
local STEP,KEEP_RUNS,MAX_STEPS=30,30,240
local current
local function History()
    if type(nfUIDB.runHistory)~="table" then nfUIDB.runHistory={} end
    return nfUIDB.runHistory
end
-- Runs are compared only with runs of the same class, zone and difficulty.
local function RunMode()
    return tostring(AZS_ZONE.heroic or 0).."/"..tostring(AZS_ZONE.diff or 0)
end
local function Record()
    local run=type(AZS_ZONE)=="table" and AZS_ZONE.run
    local t,dealt=tonumber(AZS_RUN and AZS_RUN.t),tonumber(AZS_RUN and AZS_RUN.dealt)
    if not run or not t or not dealt then return nil end
    local list=History()
    if not current or current.run~=run then
        current=nil
        for _,entry in ipairs(list) do if entry.run==run then current=entry end end
        if not current then
            current={run=run,class=AZS_ZONE.cname,zone=AZS_ZONE.zone,mode=RunMode(),marks={[0]=0}}
            table.insert(list,current)
            while table.getn(list)>KEEP_RUNS do table.remove(list,1) end
        end
    end
    current.t=t;current.dealt=dealt;current.level=tonumber(AZS_RUN.lvl)
    -- The run's best skills, for its summary.
    if type(AZS_METER)=="table" and AZS_METER[1] then
        current.skills={}
        for index=1,math.min(5,table.getn(AZS_METER)) do
            local line=AZS_METER[index]
            if type(line)=="table" and line.name then table.insert(current.skills,{name=line.name,dmg=tonumber(line.dmg) or 0}) end
        end
    end
    local step=math.floor(t/STEP)
    if step>0 and step<=MAX_STEPS and not current.marks[step] then current.marks[step]=dealt end
    return current,t,dealt
end
-- Damage per second a run had reached by this moment, or nil if it did not last that long.
local function RateAt(entry,t)
    if not entry.t or entry.t<t or t<=0 then return nil end
    local step=math.floor(t/STEP)
    local low,high=entry.marks[step],entry.marks[step+1]
    if not low then return nil end
    high=high or entry.dealt
    return (low+(high-low)*(t-step*STEP)/STEP)/t
end
local function Compare(row,label,rate,now)
    row.left:SetText(label)
    row.left:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
    if not rate or rate<=0 then
        row.right:SetText(E.Text("нет данных","no data"));row.right:SetTextColor(DONE[1],DONE[2],DONE[3]);return
    end
    local gain=math.floor((now/rate-1)*100+0.5)
    row.right:SetText(E.Short(rate).." DPS ("..(gain>=0 and "+" or "")..gain.."%)")
    local color=gain>=0 and E.COLORS.green or E.COLORS.enemy
    row.right:SetTextColor(color[1],color[2],color[3])
end
-- Hovering a past run shows its summary.
local hovers={}
local function SummaryHover(index,run)
    local hover=hovers[index]
    if not hover then
        hover=CreateFrame("Frame",nil,historyFrame);hover:SetHeight(ROW_HEIGHT-1)
        hover:SetPoint("TOPLEFT",historyFrame,"TOPLEFT",2,-20-(index-1)*ROW_HEIGHT);hover:SetPoint("TOPRIGHT",historyFrame,"TOPRIGHT",-2,-20-(index-1)*ROW_HEIGHT)
        hover:EnableMouse(true)
        hover:SetScript("OnEnter",function()
            local shown=this.run
            if not shown then return end
            GameTooltip:SetOwner(this,"ANCHOR_LEFT")
            GameTooltip:SetText((shown.class or "?").." "..Clock(shown.t or 0),1,1,1)
            GameTooltip:AddDoubleLine(E.Text("Урон","Damage"),E.Short(shown.dealt or 0),1,0.82,0,1,1,1)
            GameTooltip:AddDoubleLine("DPS",E.Short((shown.dealt or 0)/math.max(1,shown.t or 1)),1,0.82,0,1,1,1)
            for _,skill in ipairs(shown.skills or {}) do GameTooltip:AddDoubleLine(skill.name,E.Short(skill.dmg),0.8,0.8,0.85,1,1,1) end
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave",function() GameTooltip:Hide() end)
        hovers[index]=hover
    end
    hover.run=run
    if run and not E.IsCollapsed("history") then hover:Show() else hover:Hide() end
end
local function UpdateHistory()
    local entry,t,dealt=Record()
    if not entry then return false end
    local now=t>0 and dealt/t or 0
    local c=E.COLORS
    local rows=historyFrame.rows
    rows[1].left:SetText(E.Text("Сейчас ","Now ")..Clock(t));rows[1].left:SetTextColor(c.text[1],c.text[2],c.text[3])
    rows[1].right:SetText(E.Short(now).." DPS");rows[1].right:SetTextColor(c.yellow[1],c.yellow[2],c.yellow[3])
    local list=History()
    local previous,best
    for index=table.getn(list),1,-1 do
        local other=list[index]
        if other~=entry and other.class==entry.class and other.zone==entry.zone and other.mode==entry.mode then
            local rate=RateAt(other,t)
            if rate then
                if not previous then previous=rate end
                if not best or rate>best then best=rate end
            end
        end
    end
    Compare(rows[2],E.Text("Прошлый забег","Last run"),previous,now)
    Compare(rows[3],E.Text("Лучший забег","Best run"),best,now)
    if best and best>0 then
        local gain=math.floor((now/best-1)*100+0.5)
        Summarize(historyFrame,E.Text("К лучшему","Vs best"),gain>=0 and c.green or E.COLORS.enemy,E.Short(now).." DPS  "..(gain>=0 and "+" or "")..gain.."%")
    else Summarize(historyFrame,E.Text("Сейчас","Now"),c.yellow,E.Short(now).." DPS") end
    local row=4
    for index=table.getn(list),1,-1 do
        local other=list[index]
        if row<=HISTORY_ROWS and other~=entry and (other.t or 0)>=30 and other.class==entry.class and other.zone==entry.zone then
            rows[row].left:SetText(Clock(other.t)..(other.level and (E.Text(" ур.", " lv.")..other.level) or ""))
            rows[row].left:SetTextColor(DONE[1],DONE[2],DONE[3])
            rows[row].right:SetText(E.Short((other.dealt or 0)/other.t).." DPS");rows[row].right:SetTextColor(DONE[1],DONE[2],DONE[3])
            SummaryHover(row,other)
            row=row+1
        end
    end
    for index=row,HISTORY_ROWS do Clear(rows[index]);SummaryHover(index,nil) end
    return true
end
-- The hero's numbers, from the line the game's own character pane reads.
local function Percent(value) return string.format("%.0f%%",(value or 0)*100) end
local function Plus(value) return string.format("%+.0f%%",((value or 1)-1)*100) end
local STATS={
    {"Урон","Damage",function(s) return Plus(s.dmg) end},
    {"Шанс крита","Crit chance",function(s) return Percent(s.crit) end},
    {"Урон крита","Crit damage",function(s) return Percent(s.cm) end},
    {"Перезарядка","Cooldowns",function(s) return Plus(s.cd) end},
    {"Броня","Armor",function(s) return Percent(s.arm) end},
    {"Реген","Regen",function(s) return string.format("%.1f/s",s.reg or 0) end},
    {"Область","Area",function(s) return Plus(s.area) end},
    {"Скорость","Speed",function(s) return Plus(s.spd) end},
    {"Подбор","Pickup",function(s) return string.format("%.0f",s.pick or 0) end},
    {"Удача","Luck",function(s) return Percent(s.luck) end},
}
local function UpdateStats()
    if type(AZS_STATS)~="table" then return false end
    local language=E.IsRussian() and 1 or 2
    for index,stat in ipairs(STATS) do
        local row=statsFrame.rows[index]
        row.left:SetText(stat[language]);row.left:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
        row.right:SetText(stat[3](AZS_STATS));row.right:SetTextColor(E.COLORS.yellow[1],E.COLORS.yellow[2],E.COLORS.yellow[3])
    end
    Summarize(statsFrame,STATS[1][language],E.COLORS.yellow,STATS[1][3](AZS_STATS))
    return true
end
-- Damage per second in each 30 seconds of this run, with the last run's as marks.
local bars,marks={},{}
local function GraphPiece(list,index,layer)
    local piece=list[index]
    if not piece then
        piece=graphFrame:CreateTexture(nil,layer);piece:SetTexture(E.FLAT)
        list[index]=piece
    end
    return piece
end
local function RatesOf(entry)
    local rates={}
    if not entry or type(entry.marks)~="table" then return rates end
    local step=1
    while entry.marks[step] do
        rates[step]=(entry.marks[step]-(entry.marks[step-1] or 0))/STEP
        step=step+1
    end
    return rates
end
local function UpdateGraph()
    local entry=current
    if not entry then return false end
    -- Folded, the last finished half minute: the history's title already gives the run's average.
    local recent=RatesOf(entry)
    local last=recent[table.getn(recent)]
    Summarize(graphFrame,E.Text("За 30 сек","Last 30 sec"),E.COLORS.yellow,last and (E.Short(last).." DPS") or "-")
    if E.IsCollapsed("graph") then
        for _,piece in ipairs(bars) do piece:Hide() end
        for _,piece in ipairs(marks) do piece:Hide() end
        return true
    end
    local previous
    local list=History()
    for index=table.getn(list),1,-1 do
        local other=list[index]
        if other~=entry and other.class==entry.class and other.zone==entry.zone and other.mode==entry.mode then previous=other;break end
    end
    local own,theirs=RatesOf(entry),RatesOf(previous)
    local count=table.getn(own)
    local first=math.max(1,count-GRAPH_BARS+1)
    local top=1
    for index=first,math.max(count,first+GRAPH_BARS-1) do
        top=math.max(top,own[index] or 0,theirs[index] or 0)
    end
    local width=(graphFrame:GetWidth()-12)/GRAPH_BARS
    for slot=1,GRAPH_BARS do
        local index=first+slot-1
        local bar,mark=GraphPiece(bars,slot,"BORDER"),GraphPiece(marks,slot,"ARTWORK")
        local x=6+(slot-1)*width
        if own[index] then
            bar:ClearAllPoints();bar:SetPoint("BOTTOMLEFT",graphFrame,"BOTTOMLEFT",x,6)
            bar:SetWidth(math.max(1,width-1));bar:SetHeight(math.max(1,GRAPH_HEIGHT*own[index]/top))
            bar:SetVertexColor(E.COLORS.yellow[1],E.COLORS.yellow[2],E.COLORS.yellow[3],0.8);bar:Show()
        else bar:Hide() end
        if theirs[index] then
            mark:ClearAllPoints();mark:SetPoint("BOTTOMLEFT",graphFrame,"BOTTOMLEFT",x,6+GRAPH_HEIGHT*theirs[index]/top)
            mark:SetWidth(math.max(1,width-1));mark:SetHeight(2)
            mark:SetVertexColor(E.COLORS.mauve[1],E.COLORS.mauve[2],E.COLORS.mauve[3],1);mark:Show()
        else mark:Hide() end
    end
    return true
end
E.Every(0.25,function()
    -- Saved choices arrive after this file loads.
    if not foldedOnce and type(nfUIDB)=="table" then
        foldedOnce=true;bossFrame.Fold();takenFrame.Fold();lairFrame.Fold();historyFrame.Fold();statsFrame.Fold();graphFrame.Fold()
    end
    local inRun=AZS_GetPhase and RUN_PHASES[AZS_GetPhase() or ""]
    if inRun and E.On("bossSchedule") and UpdateBosses() then bossFrame:Show() else E.Conceal(bossFrame) end
    if inRun and E.On("takenPanel") and UpdateTaken() then takenFrame:Show() else E.Conceal(takenFrame) end
    if inRun and E.On("lairPanel") and UpdateLairs() then lairFrame:Show() else E.Conceal(lairFrame) end
    if inRun and E.On("historyPanel") and UpdateHistory() then historyFrame:Show() else E.Conceal(historyFrame) end
    if inRun and E.On("heroStats") and UpdateStats() then statsFrame:Show() else E.Conceal(statsFrame) end
    if inRun and E.On("dpsGraph") and UpdateGraph() then graphFrame:Show() else E.Conceal(graphFrame) end
    if inRun then Fit(bossFrame);Fit(takenFrame);Fit(lairFrame);Fit(historyFrame);Fit(statsFrame) end
end)
