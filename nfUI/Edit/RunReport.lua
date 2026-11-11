-- Run analysis: a window with every kept run of a class. On the left the runs, on the right the chosen one: its
-- damage per second over time, the picks and what each did, its build, and how it differs from the class's best.
-- Opened from the quick menu or with `/nfui runs`.
local E=nfUIEdit
local WIDTH,HEIGHT,LIST_WIDTH,ROW,ROWS=800,600,260,22,20
-- One size for the window's text, larger than the HUD's: this is read at rest.
local SIZE=11
local STEP=30
local GRAPH_HEIGHT=56

local frame=CreateFrame("Frame","nfUIRunReport",UIParent)
-- Above the HUD's own texts, which sit high.
frame:SetWidth(WIDTH);frame:SetHeight(HEIGHT);frame:SetFrameStrata("FULLSCREEN_DIALOG");frame:EnableMouse(true);frame:Hide()
frame:SetPoint("CENTER",UIParent,"CENTER",0,40)
frame:SetMovable(true);frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",function() this:StartMoving() end)
frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
table.insert(UISpecialFrames,"nfUIRunReport")
local fill=frame:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT);fill:SetAllPoints(frame)
fill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.96)
E.Polish(frame)
local function Font(parent,size,color,justify)
    local text=parent:CreateFontString(nil,"OVERLAY");text:SetFont(E.FONT,size,"OUTLINE");text:SetJustifyH(justify or "LEFT")
    text:SetTextColor(color[1],color[2],color[3])
    return text
end
local function Flat(parent,layer)
    local texture=parent:CreateTexture(nil,layer or "BACKGROUND");texture:SetTexture(E.FLAT)
    return texture
end
local title=Font(frame,13,E.COLORS.mauve);title:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-9)
local close=CreateFrame("Button",nil,frame);close:SetWidth(18);close:SetHeight(18);close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-6)
close.label=Font(close,12,E.COLORS.text,"CENTER");close.label:SetPoint("CENTER",close,"CENTER",0,0);close.label:SetText("x")
close:SetScript("OnClick",function() frame:Hide() end)

local function Clock(seconds)
    seconds=math.max(0,math.floor((seconds or 0)+0.5))
    return string.format("%d:%02d",math.floor(seconds/60),math.mod(seconds,60))
end
local function Tag(run)
    local _,_,heroic=string.find(run.mode or "","^(%d+)/")
    heroic=tonumber(heroic) or 0
    return tostring(run.zone or "?")..(heroic>0 and (E.Text(" Г"," H")..heroic) or "")
end
local function Rate(run) return (run.dealt or 0)/math.max(1,run.t or 1) end
local function Runs()
    return type(nfUIDB)=="table" and type(nfUIDB.runHistory)=="table" and nfUIDB.runHistory or {}
end
local function IsNow(run) return type(AZS_ZONE)=="table" and AZS_ZONE.run~=nil and run.run==AZS_ZONE.run end

-- The classes that have runs, as buttons along the top.
local state={class=nil,chosen=nil}
local classButtons={}
local function ClassButton(index)
    local button=classButtons[index]
    if button then return button end
    button=CreateFrame("Button",nil,frame);button:SetHeight(18)
    button.back=Flat(button);button.back:SetAllPoints(button)
    button.label=Font(button,10,E.COLORS.text,"CENTER");button.label:SetPoint("CENTER",button,"CENTER",0,0)
    button:SetScript("OnClick",function() state.class=this.class;state.chosen=nil;frame.Refresh() end)
    classButtons[index]=button
    return button
end

-- The list of runs.
local listBack=Flat(frame,"BORDER");listBack:SetVertexColor(0,0,0,0.25)
listBack:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-56);listBack:SetWidth(LIST_WIDTH);listBack:SetHeight(ROWS*ROW+4)
local rows={}
for index=1,ROWS do
    local row=CreateFrame("Button",nil,frame);row:SetHeight(ROW-1);row:SetWidth(LIST_WIDTH-4)
    row:SetPoint("TOPLEFT",listBack,"TOPLEFT",2,-2-(index-1)*ROW)
    row.back=Flat(row);row.back:SetAllPoints(row)
    row.left=Font(row,SIZE,E.COLORS.text);row.left:SetPoint("LEFT",row,"LEFT",6,0);row.left:SetWidth(LIST_WIDTH-84);row.left:SetHeight(ROW)
    row.right=Font(row,SIZE,E.COLORS.text,"RIGHT");row.right:SetPoint("RIGHT",row,"RIGHT",-6,0)
    row:SetScript("OnClick",function() state.chosen=this.run;frame.Refresh() end)
    rows[index]=row
end
local empty=Font(frame,11,{0.6,0.6,0.65});empty:SetPoint("TOPLEFT",listBack,"TOPRIGHT",14,-4)

-- The chosen run.
local DETAIL_LEFT=8+LIST_WIDTH+12
local DETAIL_WIDTH=WIDTH-DETAIL_LEFT-10
local head=Font(frame,13,E.COLORS.yellow);head:SetPoint("TOPLEFT",frame,"TOPLEFT",DETAIL_LEFT,-56);head:SetWidth(DETAIL_WIDTH);head:SetHeight(16)
local sub=Font(frame,SIZE,E.COLORS.text);sub:SetPoint("TOPLEFT",head,"BOTTOMLEFT",0,-4);sub:SetWidth(DETAIL_WIDTH);sub:SetHeight(32);sub:SetJustifyV("TOP")
local graphCaption=Font(frame,10,{0.55,0.55,0.6});graphCaption:SetPoint("TOPLEFT",sub,"BOTTOMLEFT",0,-4)
local graphBack=Flat(frame,"BORDER");graphBack:SetVertexColor(0,0,0,0.3)
graphBack:SetPoint("TOPLEFT",graphCaption,"BOTTOMLEFT",0,-2);graphBack:SetWidth(DETAIL_WIDTH);graphBack:SetHeight(GRAPH_HEIGHT)
local bars={}
local GRAPH_BARS=40
for index=1,GRAPH_BARS do
    local bar=Flat(frame,"ARTWORK");bar:SetWidth(math.max(1,DETAIL_WIDTH/GRAPH_BARS-1))
    bar:SetPoint("BOTTOMLEFT",graphBack,"BOTTOMLEFT",(index-1)*DETAIL_WIDTH/GRAPH_BARS,0)
    bars[index]=bar
end
-- The class's best run, as marks over the bars at the same moments.
local marks={}
for index=1,GRAPH_BARS do
    local mark=Flat(frame,"OVERLAY");mark:SetWidth(math.max(1,DETAIL_WIDTH/GRAPH_BARS-1));mark:SetHeight(2)
    mark:SetVertexColor(E.COLORS.mauve[1],E.COLORS.mauve[2],E.COLORS.mauve[3],0.9)
    marks[index]=mark
end
-- Below the graph, laid out anew for each run: section titles, the picks in three columns (when, what, change),
-- and the build as labelled lines that wrap.
local LINE,LABEL,WHEN,CHANGE=14,100,84,56
local slots={}
local function Slot(index)
    local slot=slots[index]
    if slot then return slot end
    slot={left=Font(frame,SIZE,{0.6,0.6,0.65}),mid=Font(frame,SIZE,E.COLORS.text),right=Font(frame,SIZE,E.COLORS.text,"RIGHT")}
    slot.mid:SetJustifyV("TOP");slot.left:SetJustifyV("TOP")
    slots[index]=slot
    return slot
end
local function Place(text,x,y,width,height)
    text:ClearAllPoints();text:SetPoint("TOPLEFT",graphBack,"BOTTOMLEFT",x,y);text:SetWidth(width);text:SetHeight(height)
end
local function Layout(lines)
    local y,bottom=-10,-(HEIGHT-56-16-36-16-GRAPH_HEIGHT-14)
    local used=0
    for index,line in ipairs(lines) do
        local slot=Slot(index)
        slot.left:SetText("");slot.mid:SetText("");slot.right:SetText("")
        local height=LINE
        if line.kind=="title" then
            if index>1 then y=y-8 end
            Place(slot.left,0,y,DETAIL_WIDTH,LINE);slot.left:SetText(line.text)
            slot.left:SetTextColor(1,0.82,0.5)
        elseif line.kind=="pick" then
            Place(slot.left,6,y,WHEN,LINE);slot.left:SetText(line.when);slot.left:SetTextColor(0.6,0.6,0.65)
            Place(slot.mid,6+WHEN,y,DETAIL_WIDTH-6-WHEN-CHANGE,LINE);slot.mid:SetText(line.text)
            Place(slot.right,DETAIL_WIDTH-CHANGE,y,CHANGE,LINE);slot.right:SetText(line.change)
        elseif line.kind=="pair" then
            Place(slot.left,6,y,LABEL,LINE);slot.left:SetText(line.label);slot.left:SetTextColor(0.75,0.75,0.8)
            local width=DETAIL_WIDTH-6-LABEL
            slot.mid:SetText(line.text)
            -- Wrapping breaks at words, so a line holds less than its width: counted with room to spare.
            local rows=math.max(1,math.ceil((slot.mid:GetStringWidth() or 0)/math.max(1,width*0.85)))
            height=rows*LINE
            Place(slot.mid,6+LABEL,y,width,height)
        else
            Place(slot.mid,6,y,DETAIL_WIDTH-6,LINE);slot.mid:SetText(line.text)
        end
        y=y-height-2
        -- What does not fit is left out rather than drawn over the frame's edge.
        if y<bottom then
            slot.left:SetText("");slot.mid:SetText("");slot.right:SetText("")
            break
        end
        used=index
    end
    for index=used+1,table.getn(slots) do slots[index].left:SetText("");slots[index].mid:SetText("");slots[index].right:SetText("") end
end

-- Damage per second in each half minute of a run.
local function Steps(run)
    local list={}
    local m=type(run.marks)=="table" and run.marks or {}
    local step=1
    while m[step] and step<=GRAPH_BARS do
        table.insert(list,math.max(0,(m[step]-(m[step-1] or 0))/STEP))
        step=step+1
    end
    return list
end
local function PartsByKey(build)
    local byKey={}
    for _,part in ipairs({"skills","gear","jewels","talents"}) do
        for _,piece in ipairs(type(build)=="table" and build[part] or {}) do byKey[piece.key]=piece end
    end
    return byKey
end
local function Named(piece) return piece.name..(piece.rank and (" "..piece.rank) or "") end
local function Joined(list)
    local names={}
    for _,piece in ipairs(list or {}) do table.insert(names,Named(piece)) end
    return table.concat(names,", ")
end
local GREEN,RED,GREY,GOLD="|cff7fd67f","|cffff7070","|cff8a8a96","|cffffd27f"

-- Picks closer than half a minute make one group: late in a run they come every few seconds, and only the group's
-- change can be told. Its DPS before is the first pick's, after is the last one's.
local function Groups(events)
    local groups={}
    for _,event in ipairs(events or {}) do
        local group=groups[table.getn(groups)]
        if group and event.t-group.last.t<STEP then
            table.insert(group.picks,event);group.last=event
        else
            group={first=event,last=event,picks={event}};table.insert(groups,group)
        end
    end
    for _,group in ipairs(groups) do
        local before,after=group.first.before,group.last.after
        if before and before>0 and after then group.gain=after/before-1 end
    end
    return groups
end
-- "Whirlwind 29 > 30, Ring 12 > 13, Shield Slam x3".
local function GroupText(group)
    local names,order={},{}
    for _,event in ipairs(group.picks) do
        local _,_,name=string.find(event.text,"^%+? ?(.-) [%d]+ > [%d]+$")
        name=name or event.text
        if not names[name] then names[name]={count=0,text=event.text};table.insert(order,name) end
        names[name].count=names[name].count+1;names[name].text=event.text
    end
    local parts={}
    for _,name in ipairs(order) do
        local item=names[name]
        table.insert(parts,item.count>1 and (name.." x"..item.count) or item.text)
    end
    return table.concat(parts,", ")
end

local function Detail(run,best)
    local lines={}
    -- Picks in groups, with what each group did.
    local events=run.events or {}
    table.insert(lines,{kind="title",text=E.Text("Прибавки: DPS за 30 с до и после, близкие покупки вместе","Picks: DPS 30 s before and after, close ones together")})
    if events[1] then
        local groups=Groups(events)
        local first=math.max(1,table.getn(groups)-9)
        if first>1 then table.insert(lines,{kind="note",text=GREY..string.format(E.Text("раньше ещё %d","%d earlier"),first-1).."|r"}) end
        for index=first,table.getn(groups) do
            local group=groups[index]
            local change=GREY.."...|r"
            if group.gain then change=(group.gain>=0 and GREEN or RED)..string.format("%+.0f%%",group.gain*100).."|r" end
            local when=Clock(group.first.t)..(group.last~=group.first and ("-"..Clock(group.last.t)) or "")
            table.insert(lines,{kind="pick",when=when,text=GroupText(group),change=change})
        end
    else
        table.insert(lines,{kind="note",text=GREY..E.Text("У этого забега их нет: они пишутся с версии 1.3.","None for this run: they are kept from version 1.3.").."|r"})
    end
    -- The build.
    local build=run.build
    table.insert(lines,{kind="title",text=E.Text("Билд","Build")})
    if type(build)=="table" then
        local titles={skills=E.Text("Скилы","Skills"),gear=E.Text("Снаряжение","Gear"),jewels=E.Text("Бижутерия","Jewelry"),talents=E.Text("Таланты","Talents")}
        for _,part in ipairs({"skills","jewels","gear","talents"}) do
            if build[part] and build[part][1] then table.insert(lines,{kind="pair",label=titles[part],text=Joined(build[part])}) end
        end
        if build.luck then table.insert(lines,{kind="pair",label=E.Text("Удача","Luck"),text=string.format("%+.0f%%",build.luck*100)}) end
        -- Against the class's best.
        if best and best~=run and type(best.build)=="table" then
            local here,there=PartsByKey(build),PartsByKey(best.build)
            local only,missing={},{}
            for key,piece in pairs(here) do if not there[key] then table.insert(only,Named(piece)) end end
            for key,piece in pairs(there) do if not here[key] then table.insert(missing,Named(piece)) end end
            if only[1] or missing[1] then
                table.insert(lines,{kind="title",text=E.Text("Против лучшего забега класса","Against the class's best run")})
                if only[1] then table.insert(lines,{kind="pair",label=E.Text("Только здесь","Only here"),text=table.concat(only,", ")}) end
                if missing[1] then table.insert(lines,{kind="pair",label=E.Text("Только там","Only there"),text=table.concat(missing,", ")}) end
            end
        end
    else
        table.insert(lines,{kind="note",text=GREY..E.Text("У этого забега билд не записан.","No build was kept for this run.").."|r"})
    end
    return lines
end

function frame.Refresh()
    title:SetText(E.Text("Анализ забегов","Run analysis"))
    local runs=Runs()
    -- Classes with runs; the current class first chosen.
    local classes,seen={},{}
    for index=table.getn(runs),1,-1 do
        local class=runs[index].class
        if class and not seen[class] then seen[class]=true;table.insert(classes,class) end
    end
    if not state.class or not seen[state.class] then
        state.class=(type(AZS_ZONE)=="table" and seen[AZS_ZONE.cname] and AZS_ZONE.cname) or classes[1]
    end
    local x=10
    for index=1,math.max(table.getn(classes),table.getn(classButtons)) do
        local button=ClassButton(index)
        local class=classes[index]
        if class then
            button.class=class;button.label:SetText(class)
            button:SetWidth(button.label:GetStringWidth()+16);button:ClearAllPoints();button:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-30)
            x=x+button:GetWidth()+4
            local on=class==state.class
            local c=on and E.COLORS.mauve or E.COLORS.surface
            button.back:SetVertexColor(c[1]*(on and 0.6 or 1),c[2]*(on and 0.6 or 1),c[3]*(on and 0.6 or 1),1)
            button:Show()
        else button:Hide() end
    end
    -- The class's runs, newest first; the best is marked.
    local list,best={},nil
    for index=table.getn(runs),1,-1 do
        local run=runs[index]
        if run.class==state.class and (run.t or 0)>=30 then
            table.insert(list,run)
            if not best or Rate(run)>Rate(best) then best=run end
        end
    end
    if not state.chosen or state.chosen.class~=state.class then state.chosen=list[1] end
    for index,row in ipairs(rows) do
        local run=list[index]
        if run then
            row.run=run
            local when=run.when and (GREY..run.when.."|r  ") or ""
            row.left:SetText(when..Tag(run).."  "..Clock(run.t)..(IsNow(run) and (GOLD..E.Text("  сейчас","  now").."|r") or ""))
            row.right:SetText((run==best and GOLD or "")..E.Short(Rate(run)).." DPS"..(run==best and "|r" or ""))
            local on=run==state.chosen
            row.back:SetVertexColor(on and 0.35 or 0,on and 0.3 or 0,on and 0.45 or 0,on and 0.9 or 0)
            row:Show()
        else row:Hide() end
    end
    local run=state.chosen
    if not run then
        empty:SetText(E.Text("Пока нет забегов длиннее 30 секунд.","No runs longer than 30 seconds yet."));empty:Show()
        head:SetText("");sub:SetText("");graphCaption:SetText("");Layout({})
        for index=1,GRAPH_BARS do bars[index]:Hide();marks[index]:Hide() end
        return
    end
    empty:Hide()
    head:SetText(Tag(run).."  ·  "..Clock(run.t)..(run.level and (E.Text("  ·  ур. ","  ·  lv. ")..run.level) or "")..(run.when and ("  ·  "..run.when) or ""))
    local versus=""
    if best and best~=run and Rate(best)>0 then
        local gain=math.floor((Rate(run)/Rate(best)-1)*100+0.5)
        versus="   "..(gain>=0 and GREEN or RED)..string.format(E.Text("%+d%% к лучшему (%s)","%+d%% vs best (%s)"),gain,Tag(best)).."|r"
    elseif run==best then versus="   "..GOLD..E.Text("лучший забег класса","the class's best run").."|r" end
    local skills={}
    for index,skill in ipairs(run.skills or {}) do if index<=3 then table.insert(skills,skill.name.." "..E.Short(skill.dmg)) end end
    sub:SetText(E.Text("Урон ","Damage ")..E.Short(run.dealt or 0).."  ·  "..E.Short(Rate(run)).." DPS"..versus
        ..(skills[1] and ("\n"..GREY..E.Text("Больше всего: ","Most: ")..table.concat(skills,", ").."|r") or ""))
    -- DPS over time, and the best run's marks at the same moments.
    local steps=Steps(run)
    local bestSteps=best and best~=run and Steps(best) or {}
    local top=1
    for _,value in ipairs(steps) do top=math.max(top,value) end
    for _,value in ipairs(bestSteps) do top=math.max(top,value) end
    graphCaption:SetText(E.Text("DPS по полминуты","DPS per half minute")..(bestSteps[1] and E.Text(";  черта: лучший забег",";  line: best run") or ""))
    for index=1,GRAPH_BARS do
        local value=steps[index]
        if value then
            local share=value/top
            bars[index]:SetHeight(math.max(1,GRAPH_HEIGHT*share))
            bars[index]:SetVertexColor(E.COLORS.yellow[1],E.COLORS.yellow[2],E.COLORS.yellow[3],0.75);bars[index]:Show()
        else bars[index]:Hide() end
        local other=bestSteps[index]
        if other then
            marks[index]:ClearAllPoints()
            marks[index]:SetPoint("BOTTOMLEFT",graphBack,"BOTTOMLEFT",(index-1)*DETAIL_WIDTH/GRAPH_BARS,math.max(0,GRAPH_HEIGHT*other/top-1))
            marks[index]:Show()
        else marks[index]:Hide() end
    end
    Layout(Detail(run,best))
end

function E.ToggleRunReport()
    if frame:IsShown() then frame:Hide();return end
    state.chosen=nil;state.class=nil
    frame.Refresh();frame:Show()
end
-- Kept fresh while open: the current run goes on.
local age=0
frame:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<2 then return end;age=0
    local chosen=state.chosen
    frame.Refresh()
    state.chosen=chosen or state.chosen
end)

local command=SlashCmdList["NFUI"]
SlashCmdList["NFUI"]=function(message)
    local word=string.lower(message or "")
    if word=="runs" or word=="analysis" then E.ToggleRunReport();return end
    if command then command(message) end
end
