-- Run analysis: a window with every kept run of a class. On the left the runs; on the right the chosen one in tabs:
-- Overview (damage per second over time and the picks), Build (icons of what it was played with), Skills (damage
-- by skill) and Compare (against the class's best run). Opened from the quick menu, the sword by the minimap,
-- the settings window or `/nfui runs`.
local E=nfUIEdit
local WIDTH,HEIGHT,LIST_WIDTH,ROW,ROWS=820,620,250,22,20
local SIZE=11
local STEP=30
-- Grey light enough to read on the dark window.
local GREEN,RED,GREY,GOLD="|cff7fd67f","|cffff7070","|cffb4b4bc","|cffffd27f"
local MUTED={0.72,0.72,0.78}

local frame=CreateFrame("Frame","nfUIRunReport",UIParent)
-- Above the HUD's own texts, which sit high.
frame:SetWidth(WIDTH);frame:SetHeight(HEIGHT);frame:SetFrameStrata("FULLSCREEN_DIALOG");frame:EnableMouse(true);frame:Hide()
frame:SetPoint("CENTER",UIParent,"CENTER",0,30)
frame:SetMovable(true);frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",function() this:StartMoving() end)
frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
table.insert(UISpecialFrames,"nfUIRunReport")
local fill=frame:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT);fill:SetAllPoints(frame)
fill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.97)
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
local function Clock(seconds)
    seconds=math.max(0,math.floor((seconds or 0)+0.5))
    return string.format("%d:%02d",math.floor(seconds/60),math.mod(seconds,60))
end
-- Where a run was played, in the game's own names: short for lists, full for the header.
local function Tag(run,full)
    if E.RunPlace then return E.RunPlace(run,not full) end
    return tostring(run.zone or "?")
end
local function Rate(run) return (run.dealt or 0)/math.max(1,run.t or 1) end
local function Runs() return type(nfUIDB)=="table" and type(nfUIDB.runHistory)=="table" and nfUIDB.runHistory or {} end
local function IsNow(run) return type(AZS_ZONE)=="table" and AZS_ZONE.run~=nil and run.run==AZS_ZONE.run end
local function Named(piece) return piece.name..(piece.rank and (" "..piece.rank) or "") end
local PARTS={"skills","jewels","gear","talents"}
local function PartsByKey(build)
    local byKey={}
    for _,part in ipairs(PARTS) do
        for _,piece in ipairs(type(build)=="table" and build[part] or {}) do byKey[piece.key]=piece end
    end
    return byKey
end
-- A piece's icon by its name, for records kept before icons were.
local function IconByName(build,name)
    for _,part in ipairs(PARTS) do
        for _,piece in ipairs(type(build)=="table" and build[part] or {}) do
            if piece.icon and name and (piece.name==name or string.find(name,piece.name,1,true)==1) then return piece.icon end
        end
    end
end

local title=Font(frame,13,E.COLORS.mauve);title:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-9)
local close=CreateFrame("Button",nil,frame);close:SetWidth(18);close:SetHeight(18);close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-6)
close.label=Font(close,12,E.COLORS.text,"CENTER");close.label:SetPoint("CENTER",close,"CENTER",0,0);close.label:SetText("x")
close:SetScript("OnClick",function() frame:Hide() end)

-- versus: what a run is held against, "place" (the best other run of the same zone and difficulty) or "class".
local state={class=nil,chosen=nil,tab="overview",versus="place",significant=true}
-- Picks that changed DPS by less than this are hidden while "only notable" is on.
local NOTABLE=0.15
local function Tab(parent,height)
    local button=CreateFrame("Button",nil,parent);button:SetHeight(height or 18)
    button.back=Flat(button);button.back:SetAllPoints(button)
    button.label=Font(button,SIZE-1,E.COLORS.text,"CENTER");button.label:SetPoint("CENTER",button,"CENTER",0,0)
    return button
end
local function Lit(button,on)
    local c=on and E.COLORS.mauve or E.COLORS.surface
    button.back:SetVertexColor(c[1]*(on and 0.6 or 1),c[2]*(on and 0.6 or 1),c[3]*(on and 0.6 or 1),1)
end

-- Classes with runs, along the top.
local classButtons={}
local function ClassButton(index)
    if not classButtons[index] then
        local button=Tab(frame)
        button:SetScript("OnClick",function() state.class=this.class;state.chosen=nil;frame.Refresh() end)
        classButtons[index]=button
    end
    return classButtons[index]
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
    row:SetScript("OnEnter",function()
        local run=this.run
        if not run then return end
        frame.hovering=true
        GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(Tag(run,true),1,1,1)
        if run.when then GameTooltip:AddLine(run.when,0.75,0.75,0.8) end
        GameTooltip:AddDoubleLine(E.Text("Длительность","Length"),Clock(run.t),0.75,0.75,0.8,1,1,1)
        if run.level then GameTooltip:AddDoubleLine(E.Text("Уровень","Level"),run.level,0.75,0.75,0.8,1,1,1) end
        GameTooltip:AddDoubleLine("DPS",E.Short(Rate(run)),0.75,0.75,0.8,1,1,1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() frame.hovering=false;GameTooltip:Hide() end)
    rows[index]=row
end

-- The right side: a header, the tabs, and a page per tab.
local LEFT=8+LIST_WIDTH+12
local PAGE_WIDTH=WIDTH-LEFT-10
local head=Font(frame,13,E.COLORS.yellow);head:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,-56);head:SetWidth(PAGE_WIDTH);head:SetHeight(16)
local sub=Font(frame,SIZE,E.COLORS.text);sub:SetPoint("TOPLEFT",head,"BOTTOMLEFT",0,-4);sub:SetWidth(PAGE_WIDTH);sub:SetHeight(30);sub:SetJustifyV("TOP")
local TABS={{"overview","Обзор","Overview"},{"build","Билд","Build"},{"skills","Скилы","Skills"},{"compare","Сравнение","Compare"},{"profile","Профиль","Profile"},{"works","Что работает","What works"}}
local tabButtons={}
for index,tab in ipairs(TABS) do
    local button=Tab(frame,20);button:SetWidth(86);button.tab=tab
    button:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT+(index-1)*90,-110)
    button:SetScript("OnClick",function() state.tab=this.tab[1];frame.Refresh() end)
    tabButtons[index]=button
end
local PAGE_TOP=-136
local pages={}
for _,tab in ipairs(TABS) do
    local page=CreateFrame("Frame",nil,frame);page:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,PAGE_TOP)
    page:SetWidth(PAGE_WIDTH);page:SetHeight(HEIGHT+PAGE_TOP-10)
    pages[tab[1]]=page
end
local empty=Font(frame,SIZE,MUTED);empty:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,-60)

-- Icons: a picture with a rank in its corner and its name on hover. Each page keeps its own.
local function Icon(page,index,size)
    page.icons=page.icons or {}
    local icon=page.icons[index]
    if not icon then
        icon=CreateFrame("Frame",nil,page);icon:EnableMouse(true)
        icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints(icon);icon.texture:SetTexCoord(0.07,0.93,0.07,0.93)
        E.Ring(icon)
        icon.rank=Font(icon,SIZE,{1,0.82,0.3},"RIGHT");icon.rank:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",1,1)
        icon:SetScript("OnEnter",function()
            frame.hovering=true
            if not this.label then return end
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(this.label,1,1,1)
            if this.note then GameTooltip:AddLine(this.note,0.8,0.8,0.85,true) end
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave",function() frame.hovering=false;GameTooltip:Hide() end)
        page.icons[index]=icon
    end
    icon:SetWidth(size);icon:SetHeight(size)
    return icon
end
local function HideFrom(list,first) for index=first,table.getn(list or {}) do list[index]:Hide() end end
local function Text(page,index,size,color,justify)
    page.texts=page.texts or {}
    local text=page.texts[index]
    if not text then text=Font(page,size or SIZE,color or E.COLORS.text,justify);page.texts[index]=text end
    text:SetFont(E.FONT,size or SIZE,"OUTLINE");text:SetJustifyH(justify or "LEFT")
    local c=color or E.COLORS.text;text:SetTextColor(c[1],c[2],c[3])
    text:ClearAllPoints();text:Show()
    return text
end
local function Bar(page,index,layer)
    page.bars=page.bars or {}
    local bar=page.bars[index]
    if not bar then bar=Flat(page,layer or "ARTWORK");page.bars[index]=bar end
    bar:ClearAllPoints();bar:Show()
    return bar
end

-- Damage per second in each half minute of a run.
local function HalfMinutes(run)
    local list={}
    local m=type(run.marks)=="table" and run.marks or {}
    local step=1
    while m[step] do
        table.insert(list,math.max(0,(m[step]-(m[step-1] or 0))/STEP))
        step=step+1
    end
    return list
end
-- At most so many bars: a long run's half minutes are joined, so the graph always covers the whole run. Two runs
-- drawn together are joined alike, so that their bars stand for the same moments.
local BARS=40
local function Join(list,size)
    local out={}
    for first=1,table.getn(list),size do
        local sum,count=0,0
        for index=first,math.min(table.getn(list),first+size-1) do sum=sum+list[index];count=count+1 end
        table.insert(out,sum/math.max(1,count))
    end
    return out
end
local function Steps(one,two)
    local a,b=HalfMinutes(one),two and HalfMinutes(two) or nil
    local longest=math.max(table.getn(a),b and table.getn(b) or 0)
    local size=math.max(1,math.ceil(longest/BARS))
    return Join(a,size),b and Join(b,size) or nil,size
end
-- A bar graph of one or two runs over time: the chosen in yellow, the other in violet beside it.
local function Graph(page,firstBar,firstText,x,y,width,height,one,two,caption,size)
    local back=Bar(page,firstBar,"BORDER");back:SetVertexColor(0,0,0,0.3)
    back:SetPoint("TOPLEFT",page,"TOPLEFT",x,y-14);back:SetWidth(width);back:SetHeight(height)
    local count=math.max(table.getn(one),table.getn(two or {}))
    local top=1
    for _,v in ipairs(one) do top=math.max(top,v) end
    for _,v in ipairs(two or {}) do top=math.max(top,v) end
    local slot=width/math.max(1,count)
    local barIndex=firstBar+1
    local function Draw(list,color,offset,share)
        for index,value in ipairs(list) do
            local bar=Bar(page,barIndex);barIndex=barIndex+1
            bar:SetVertexColor(color[1],color[2],color[3],0.85)
            bar:SetWidth(math.max(1,slot*share-1));bar:SetHeight(math.max(1,height*value/top))
            bar:SetPoint("BOTTOMLEFT",back,"BOTTOMLEFT",(index-1)*slot+offset*slot,0)
        end
    end
    if two and two[1] then Draw(one,E.COLORS.yellow,0,0.5);Draw(two,E.COLORS.mauve,0.5,0.5) else Draw(one,E.COLORS.yellow,0,1) end
    local label=Text(page,firstText,SIZE-1,MUTED);label:SetPoint("TOPLEFT",page,"TOPLEFT",x,y);label:SetText(caption)
    local peak=Text(page,firstText+1,SIZE-1,MUTED,"RIGHT");peak:SetPoint("TOPRIGHT",back,"TOPRIGHT",-2,-2);peak:SetText(E.Short(top).." DPS")
    local startLabel=Text(page,firstText+2,SIZE-1,MUTED);startLabel:SetPoint("TOPLEFT",back,"BOTTOMLEFT",0,-2);startLabel:SetText("0:00")
    local endLabel=Text(page,firstText+3,SIZE-1,MUTED,"RIGHT");endLabel:SetPoint("TOPRIGHT",back,"BOTTOMRIGHT",0,-2);endLabel:SetText(Clock(count*STEP*(size or 1)))
    return barIndex,y-14-height-16,back,count*STEP*(size or 1)
end

-- Picks closer than half a minute make one group: late in a run they come every few seconds, and only the group's
-- change can be told. Its DPS before is the first pick's, after is the last one's.
local function Groups(events)
    local groups={}
    for _,event in ipairs(events or {}) do
        local group=groups[table.getn(groups)]
        if group and event.t-group.last.t<STEP then table.insert(group.picks,event);group.last=event
        else group={first=event,last=event,picks={event}};table.insert(groups,group) end
    end
    for _,group in ipairs(groups) do
        local before,after=group.first.before,group.last.after
        if before and before>0 and after then group.gain=after/before-1 end
    end
    return groups
end
-- A pick's name, its rank after it, and whether it was new: "Whirlwind 28 > 29" or "+ Whirlwind 1".
local function PickParts(event)
    local _,_,name,_,rank=string.find(event.text,"^(.-) (%d+) > (%d+)$")
    if name then return name,rank,false end
    local _,_,newName,newRank=string.find(event.text,"^%+ (.-) ?(%d*)$")
    if newName then return newName,newRank~="" and newRank or nil,true end
    return event.text,nil,false
end
local function PickName(event) local name=PickParts(event);return name end
-- Short enough for one line: "Whirlwind 30 (+2), Ring 13, Execute (new)".
local function GroupText(group)
    local items,order={},{}
    for _,event in ipairs(group.picks) do
        local name,rank,new=PickParts(event)
        local item=items[name]
        if not item then item={count=0};items[name]=item;table.insert(order,name) end
        item.count=item.count+1;item.rank=rank or item.rank;item.new=item.new or new
    end
    local parts={}
    for _,name in ipairs(order) do
        local item=items[name]
        local text=name..(item.rank and (" "..item.rank) or "")
        if item.new then text=name..E.Text(" (новый)"," (new)")
        elseif item.count>1 then text=text.." (+"..item.count..")" end
        table.insert(parts,text)
    end
    -- Two names fit a line; the rest are counted, and the row's tooltip lists them all.
    if table.getn(parts)>2 then return parts[1]..", "..parts[2]..E.Text(" и ещё "," and ")..(table.getn(parts)-2) end
    return table.concat(parts,", ")
end

-- The run in a sentence or two: its best and worst picks, and when its damage got going.
local function Summary(run)
    local top,bottom
    for _,group in ipairs(Groups(run.events)) do
        if group.gain then
            if not top or group.gain>top.gain then top=group end
            if not bottom or group.gain<bottom.gain then bottom=group end
        end
    end
    local lines={}
    if top and top.gain>0 then table.insert(lines,E.Text("Лучше всего: ","Best pick: ")..GroupText(top).."  "..GREEN..string.format("%+.0f%%",top.gain*100).."|r") end
    if bottom and bottom~=top and bottom.gain<0 then table.insert(lines,E.Text("Хуже всего: ","Worst pick: ")..GroupText(bottom).."  "..RED..string.format("%+.0f%%",bottom.gain*100).."|r") end
    local halves=HalfMinutes(run)
    local peak=0
    for _,value in ipairs(halves) do peak=math.max(peak,value) end
    for index,value in ipairs(halves) do
        if peak>0 and value>=peak*0.5 then
            table.insert(lines,string.format(E.Text("Половину пикового DPS набрал к %s из %s","Half the peak DPS by %s of %s"),Clock(index*STEP),Clock(run.t)))
            break
        end
    end
    return lines
end

-- Overview: the run in a few words, the graph against the chosen other run, and the picks with their icons.
local function Overview(page,run,best,bestName)
    local lines=Summary(run)
    -- Its own line, apart from the page's numbered texts.
    if not page.said then page.said=Font(page,SIZE+1,E.COLORS.text);page.said:SetJustifyV("TOP") end
    local said=page.said
    said:ClearAllPoints();said:SetPoint("TOPLEFT",page,"TOPLEFT",0,0);said:SetWidth(PAGE_WIDTH);said:SetHeight(18*3)
    said:SetText(table.concat(lines,"\n"))
    local top=-(math.max(1,table.getn(lines))*16+8)
    local mine,bestSteps,size=Steps(run,best)
    local barIndex,y,back,covered=Graph(page,1,1,0,top,PAGE_WIDTH,90,mine,bestSteps,
        E.Text("DPS по ходу забега","DPS through the run")..(bestSteps and ("   "..GOLD..E.Text("жёлтый","yellow").."|r "..E.Text("этот забег, ","this run, ").."|cffc6a0f6"..E.Text("сиреневый","violet").."|r "..(bestName or "")) or ""),size)
    HideFrom(page.bars,barIndex)
    -- Each group of picks as a mark under the graph, at its moment: green for a gain, red for a loss.
    page.ticks=page.ticks or {}
    local tickIndex=1
    for _,group in ipairs(Groups(run.events)) do
        if covered and covered>0 and group.first.t<=covered then
            local tick=page.ticks[tickIndex]
            if not tick then
                tick=CreateFrame("Frame",nil,page);tick:SetWidth(5);tick:SetHeight(9);tick:EnableMouse(true)
                tick.fill=tick:CreateTexture(nil,"OVERLAY");tick.fill:SetTexture(E.FLAT);tick.fill:SetAllPoints(tick)
                tick:SetScript("OnEnter",function()
                    frame.hovering=true
                    local g=this.group
                    GameTooltip:SetOwner(this,"ANCHOR_TOP")
                    GameTooltip:SetText(Clock(g.first.t)..(g.gain and ("   "..string.format("%+.0f%%",g.gain*100)) or ""),1,1,1)
                    for _,event in ipairs(g.picks) do GameTooltip:AddLine(event.text,0.85,0.85,0.9) end
                    GameTooltip:Show()
                end)
                tick:SetScript("OnLeave",function() frame.hovering=false;GameTooltip:Hide() end)
                page.ticks[tickIndex]=tick
            end
            tick.group=group
            local c=not group.gain and {0.6,0.6,0.65} or (group.gain>=0 and {0.5,0.85,0.5} or {1,0.45,0.45})
            tick.fill:SetVertexColor(c[1],c[2],c[3],0.95)
            tick:ClearAllPoints();tick:SetPoint("TOP",back,"BOTTOMLEFT",PAGE_WIDTH*group.first.t/covered,0);tick:Show()
            tickIndex=tickIndex+1
        end
    end
    for index=tickIndex,table.getn(page.ticks) do page.ticks[index]:Hide() end
    local t=Text(page,5,SIZE+1,{1,0.82,0.5});t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y-6)
    t:SetText(E.Text("Что дали покупки","What the picks did"))
    local hint=Text(page,6,SIZE-1,MUTED);hint:SetPoint("TOPLEFT",page,"TOPLEFT",0,y-22);hint:SetWidth(PAGE_WIDTH);hint:SetHeight(14)
    hint:SetText(E.Text("DPS за 30 с после покупки против 30 с до неё; покупки ближе 30 с друг к другу считаются вместе","DPS 30 s after a pick against 30 s before; picks closer than 30 s count together"))
    y=y-42
    local groups=Groups(run.events)
    local textIndex,iconIndex,hoverIndex=7,1,1
    page.hovers=page.hovers or {}
    -- A switch beside the title: only the picks that changed much.
    if not page.notable then
        page.notable=Tab(page,18);page.notable:SetWidth(170)
        page.notable:SetScript("OnClick",function() state.significant=not state.significant;frame.Refresh() end)
    end
    page.notable:ClearAllPoints();page.notable:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y+40)
    page.notable.label:SetText(E.Text("Только заметные (±15%)","Only notable (±15%)"));Lit(page.notable,state.significant)
    page.notable:Show()
    local shown,hidden={},0
    for _,group in ipairs(groups) do
        if state.significant and group.gain and math.abs(group.gain)<NOTABLE then hidden=hidden+1 else table.insert(shown,group) end
    end
    local biggest=0.01
    for _,group in ipairs(shown) do if group.gain then biggest=math.max(biggest,math.abs(group.gain)) end end
    if not groups[1] then
        local note=Text(page,textIndex,SIZE,MUTED);note:SetPoint("TOPLEFT",page,"TOPLEFT",6,y)
        note:SetText(E.Text("У этого забега покупки не записаны: они пишутся с версии 1.3.","This run has no picks kept: they are kept from version 1.3."));textIndex=textIndex+1
        y=y-20
    end
    local first=math.max(1,table.getn(shown)-10)
    local skipped=first-1+hidden
    if skipped>0 then
        local note=Text(page,textIndex,SIZE-1,MUTED);note:SetPoint("TOPLEFT",page,"TOPLEFT",6,y)
        note:SetText(string.format(E.Text("не показано: %d (раньше или меньше ±15%%)","not shown: %d (earlier or under ±15%%)"),skipped));textIndex=textIndex+1
        y=y-16
    end
    page.barsAt=page.barsAt or {}
    local barAt=1
    for index=first,table.getn(shown) do
        local group=shown[index]
        -- The whole row answers the mouse with every pick of the group.
        local hover=page.hovers[hoverIndex]
        if not hover then
            hover=CreateFrame("Frame",nil,page);hover:EnableMouse(true);hover:SetHeight(20);hover:SetWidth(PAGE_WIDTH)
            hover:SetScript("OnEnter",function()
                frame.hovering=true
                GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(E.Text("Покупки","Picks"),1,1,1)
                for _,event in ipairs(this.group.picks) do GameTooltip:AddDoubleLine(Clock(event.t),event.text,0.75,0.75,0.8,1,1,1) end
                GameTooltip:Show()
            end)
            hover:SetScript("OnLeave",function() frame.hovering=false;GameTooltip:Hide() end)
            page.hovers[hoverIndex]=hover
        end
        hover.group=group;hover:ClearAllPoints();hover:SetPoint("TOPLEFT",page,"TOPLEFT",0,y+1);hover:Show()
        hoverIndex=hoverIndex+1
        local when=Text(page,textIndex,SIZE,MUTED);textIndex=textIndex+1
        when:SetPoint("TOPLEFT",page,"TOPLEFT",6,y-3);when:SetText(Clock(group.first.t)..(group.last~=group.first and ("-"..Clock(group.last.t)) or ""))
        -- Up to four icons of the group's picks.
        local seen,x={},92
        for _,event in ipairs(group.picks) do
            local name=PickName(event)
            if not seen[name] and x<92+4*20 then
                seen[name]=true
                local icon=Icon(page,iconIndex,18);iconIndex=iconIndex+1
                icon:ClearAllPoints();icon:SetPoint("TOPLEFT",page,"TOPLEFT",x,y)
                icon.texture:SetTexture(event.icon or IconByName(run.build,name) or "Interface\\Icons\\INV_Misc_QuestionMark")
                icon.rank:SetText("");icon.label=event.text;icon.note=nil;icon:Show()
                x=x+20
            end
        end
        local what=Text(page,textIndex,SIZE);textIndex=textIndex+1
        what:SetPoint("TOPLEFT",page,"TOPLEFT",92+4*20+4,y-3);what:SetWidth(PAGE_WIDTH-92-84-4-150);what:SetHeight(14);what:SetText(GroupText(group))
        -- The change as a bar from the middle: right and green for a gain, left and red for a loss.
        local mid=PAGE_WIDTH-44-50
        local axis=page.barsAt[barAt] or Flat(page,"BORDER");page.barsAt[barAt]=axis;barAt=barAt+1
        axis:ClearAllPoints();axis:SetPoint("TOPLEFT",page,"TOPLEFT",mid,y-1);axis:SetWidth(1);axis:SetHeight(16);axis:SetVertexColor(0.5,0.5,0.55,0.8);axis:Show()
        local bar=page.barsAt[barAt] or Flat(page,"ARTWORK");page.barsAt[barAt]=bar;barAt=barAt+1
        if group.gain then
            local length=math.max(1,48*math.min(1,math.abs(group.gain)/biggest))
            bar:ClearAllPoints()
            if group.gain>=0 then bar:SetPoint("TOPLEFT",page,"TOPLEFT",mid+1,y-3);bar:SetVertexColor(0.5,0.85,0.5,0.85)
            else bar:SetPoint("TOPLEFT",page,"TOPLEFT",mid-length,y-3);bar:SetVertexColor(1,0.45,0.45,0.85) end
            bar:SetWidth(length);bar:SetHeight(12);bar:Show()
        else bar:Hide() end
        local change=Text(page,textIndex,SIZE,nil,"RIGHT");textIndex=textIndex+1
        change:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y-3);change:SetWidth(44)
        change:SetText(group.gain and ((group.gain>=0 and GREEN or RED)..string.format("%+.0f%%",group.gain*100).."|r") or (GREY.."...|r"))
        y=y-22
    end
    for index=barAt,table.getn(page.barsAt) do page.barsAt[index]:Hide() end
    HideFrom(page.texts,textIndex);HideFrom(page.icons,iconIndex);HideFrom(page.hovers,hoverIndex)
end

-- A row of icons for a part of a build, with a title; returns the y below it. With names, each icon has its name
-- under it, cut to the cell; the full name is on hover.
local function IconRow(page,state2,titleText,pieces,y,size,withNames)
    local t=Text(page,state2.text,SIZE,{1,0.82,0.5});state2.text=state2.text+1
    t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y);t:SetText(titleText)
    y=y-18
    local cell=withNames and (size+56) or (size+6)
    local tall=withNames and (size+18) or (size+6)
    local perRow=math.floor(PAGE_WIDTH/cell)
    local column=0
    for _,piece in ipairs(pieces) do
        if column>=perRow then column=0;y=y-tall end
        local icon=Icon(page,state2.icon,size);state2.icon=state2.icon+1
        local x=column*cell+(withNames and (cell-size)/2 or 0)
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",page,"TOPLEFT",x,y)
        icon.texture:SetTexture(piece.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon.rank:SetText(piece.rank or "");icon.label=piece.name;icon.note=piece.note;icon:Show()
        if withNames then
            local name=Text(page,state2.text,SIZE-2,{0.85,0.85,0.9},"CENTER");state2.text=state2.text+1
            name:SetPoint("TOP",icon,"BOTTOM",0,-2);name:SetWidth(cell-4);name:SetHeight(12);name:SetText(piece.name)
        end
        column=column+1
    end
    return y-tall-8
end

-- Build: icons of every part, talents and luck as text.
local function Build(page,run)
    local build=run.build
    local s2={text=1,icon=1}
    if type(build)~="table" then
        local note=Text(page,1,SIZE,MUTED);note:SetPoint("TOPLEFT",page,"TOPLEFT",0,0)
        note:SetText(E.Text("У этого забега билд не записан.","No build was kept for this run."))
        HideFrom(page.texts,2);HideFrom(page.icons,1)
        return
    end
    local y=0
    local titles={skills=E.Text("Скилы","Skills"),jewels=E.Text("Бижутерия","Jewelry"),gear=E.Text("Снаряжение","Gear")}
    for _,part in ipairs({"skills","jewels","gear"}) do
        if build[part] and build[part][1] then y=IconRow(page,s2,titles[part],build[part],y,32,true) end
    end
    if build.talents and build.talents[1] then
        local t=Text(page,s2.text,SIZE,{1,0.82,0.5});s2.text=s2.text+1;t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y);t:SetText(E.Text("Таланты","Talents"))
        y=y-18
        local names={}
        for _,piece in ipairs(build.talents) do table.insert(names,Named(piece)) end
        local body=Text(page,s2.text,SIZE);s2.text=s2.text+1
        body:SetPoint("TOPLEFT",page,"TOPLEFT",6,y);body:SetWidth(PAGE_WIDTH-6);body:SetHeight(90);body:SetJustifyV("TOP");body:SetText(table.concat(names,", "))
        y=y-96
    end
    if build.luck then
        local t=Text(page,s2.text,SIZE);s2.text=s2.text+1;t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        t:SetText(GOLD..E.Text("Удача","Luck").."|r  "..string.format("%+.0f%%",build.luck*100))
    end
    HideFrom(page.texts,s2.text);HideFrom(page.icons,s2.icon)
end

-- Skills: damage by skill as horizontal bars with icons.
local function Skills(page,run)
    local list=run.skills or {}
    local total=0
    for _,skill in ipairs(list) do total=total+(skill.dmg or 0) end
    local top=math.max(1,list[1] and list[1].dmg or 1)
    local t=Text(page,1,SIZE,{1,0.82,0.5});t:SetPoint("TOPLEFT",page,"TOPLEFT",0,0)
    t:SetText(E.Text("Урон по скилам (пять главных)","Damage by skill (the top five)"))
    local y=-22
    local textIndex,iconIndex,barIndex=2,1,1
    for _,skill in ipairs(list) do
        local icon=Icon(page,iconIndex,28);iconIndex=iconIndex+1
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        icon.texture:SetTexture(IconByName(run.build,skill.name) or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon.rank:SetText("");icon.label=skill.name;icon.note=nil;icon:Show()
        local back=Bar(page,barIndex,"BORDER");barIndex=barIndex+1;back:SetVertexColor(0,0,0,0.3)
        back:SetPoint("TOPLEFT",page,"TOPLEFT",36,y-2);back:SetWidth(PAGE_WIDTH-36);back:SetHeight(24)
        local bar=Bar(page,barIndex);barIndex=barIndex+1;bar:SetVertexColor(E.COLORS.yellow[1],E.COLORS.yellow[2],E.COLORS.yellow[3],0.55)
        bar:SetPoint("TOPLEFT",back,"TOPLEFT",0,0);bar:SetHeight(24);bar:SetWidth(math.max(1,(PAGE_WIDTH-36)*(skill.dmg or 0)/top))
        local name=Text(page,textIndex,SIZE);textIndex=textIndex+1;name:SetPoint("LEFT",back,"LEFT",6,0);name:SetText(skill.name)
        local value=Text(page,textIndex,SIZE,nil,"RIGHT");textIndex=textIndex+1;value:SetPoint("RIGHT",back,"RIGHT",-6,0)
        value:SetText(E.Short(skill.dmg or 0).."  "..GREY..string.format("%.0f%%",100*(skill.dmg or 0)/math.max(1,total)).."|r")
        y=y-34
    end
    if not list[1] then
        local note=Text(page,textIndex,SIZE,MUTED);textIndex=textIndex+1;note:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        note:SetText(E.Text("Урон по скилам не записан.","No damage by skill was kept."))
    end
    HideFrom(page.texts,textIndex);HideFrom(page.icons,iconIndex);HideFrom(page.bars,barIndex)
end

-- What to compare with: two buttons at the top of the Compare tab.
local VERSUS={{"place","Та же карта и сложность","Same zone and difficulty"},{"class","Лучший забег класса","The class's best run"}}
local versusButtons={}
local function VersusButtons(page)
    for index,choice in ipairs(VERSUS) do
        local button=versusButtons[index]
        if not button then
            button=Tab(page,20);button:SetWidth(230);button.choice=choice
            button:SetPoint("TOPLEFT",page,"TOPLEFT",(index-1)*236,0)
            button:SetScript("OnClick",function() state.versus=this.choice[1];frame.Refresh() end)
            versusButtons[index]=button
        end
        button.label:SetText(E.Text(choice[2],choice[3]));Lit(button,state.versus==choice[1])
    end
end
-- Compare: this run against the chosen other one, over time and in the build.
local function Compare(page,run,best,bestName)
    VersusButtons(page)
    if not best then
        local note=Text(page,1,SIZE,MUTED);note:SetPoint("TOPLEFT",page,"TOPLEFT",0,-30)
        note:SetText(state.versus=="place" and E.Text("На этой карте и сложности других забегов класса нет. Сравните с лучшим забегом класса кнопкой выше.","No other run of this class on this zone and difficulty. Compare with the class's best with the button above.")
            or E.Text("Это и есть лучший забег класса: выберите другой слева.","This is the class's best run: choose another on the left."))
        HideFrom(page.texts,2);HideFrom(page.icons,1);HideFrom(page.bars,1)
        return
    end
    local gain=Rate(best)>0 and (Rate(run)/Rate(best)-1) or 0
    local mine,theirs,size=Steps(run,best)
    local barIndex,y=Graph(page,1,1,0,-30,PAGE_WIDTH,110,mine,theirs,
        GOLD..E.Text("этот забег","this run").."|r "..E.Short(Rate(run)).." DPS   |cffc6a0f6"..bestName.."|r "..Tag(best).." "..E.Short(Rate(best)).." DPS   "
        ..(gain>=0 and GREEN or RED)..string.format("%+.0f%%",gain*100).."|r",size)
    HideFrom(page.bars,barIndex)
    local s2={text=5,icon=1}
    local here,there=PartsByKey(run.build),PartsByKey(best.build)
    local only,missing,ranks={},{},{}
    for key,piece in pairs(here) do
        if not there[key] then table.insert(only,piece)
        elseif piece.rank and there[key].rank and piece.rank~=there[key].rank then
            table.insert(ranks,{name=piece.name,icon=piece.icon,rank=piece.rank,note=E.Text("Ранг в этом забеге ","Rank in this run ")..piece.rank..E.Text(", в том ",", in that one ")..there[key].rank})
        end
    end
    for key,piece in pairs(there) do if not here[key] then table.insert(missing,piece) end end
    y=y-4
    if type(run.build)~="table" or type(best.build)~="table" then
        local note=Text(page,s2.text,SIZE,MUTED);s2.text=s2.text+1;note:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        note:SetText(E.Text("У одного из забегов билд не записан.","One of the runs has no build kept."))
    else
        if only[1] then y=IconRow(page,s2,E.Text("Было только в этом забеге","Only in this run"),only,y,28) end
        if missing[1] then y=IconRow(page,s2,E.Text("Было только в том забеге","Only in that run"),missing,y,28) end
        if ranks[1] then y=IconRow(page,s2,E.Text("Разные ранги (наведите на иконку)","Different ranks (hover an icon)"),ranks,y,28) end
    end
    HideFrom(page.texts,s2.text);HideFrom(page.icons,s2.icon)
end

-- Each run's DPS against the average of its zone and difficulty: 1 is average there. Hard and easy zones then
-- weigh alike when runs are set side by side.
local function Scores(list)
    local sums,counts={},{}
    for _,run in ipairs(list) do
        local place=tostring(run.zone).."|"..tostring(run.mode)
        sums[place]=(sums[place] or 0)+Rate(run);counts[place]=(counts[place] or 0)+1
    end
    local scores={}
    for _,run in ipairs(list) do
        local place=tostring(run.zone).."|"..tostring(run.mode)
        local average=sums[place]/counts[place]
        scores[run]=average>0 and Rate(run)/average or 1
    end
    return scores
end
local function Title(page,index,y,text)
    local t=Text(page,index,SIZE+1,{1,0.82,0.5});t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y);t:SetText(text)
end
-- Profile: the class over all its kept runs.
local function Profile(page,list)
    local s2={text=1,icon=1}
    local count,time,levels,levelCount,kills,killCount=0,0,0,0,0,0
    local longest,strongest
    local places,placeOrder={},{}
    local pieces={skills={},jewels={}}
    local withBuild=0
    for _,run in ipairs(list) do
        count=count+1;time=time+(run.t or 0)
        if run.level then levels=levels+run.level;levelCount=levelCount+1 end
        local final=type(run.final)=="table" and run.final or nil
        if final and tonumber(final.kills) then kills=kills+final.kills;killCount=killCount+1 end
        if not longest or (run.t or 0)>(longest.t or 0) then longest=run end
        if not strongest or Rate(run)>Rate(strongest) then strongest=run end
        local place=tostring(run.zone).."|"..tostring(run.mode)
        local entry=places[place]
        if not entry then entry={run=run,count=0,longest=0,best=0};places[place]=entry;table.insert(placeOrder,entry) end
        entry.count=entry.count+1;entry.longest=math.max(entry.longest,run.t or 0);entry.best=math.max(entry.best,Rate(run))
        if type(run.build)=="table" then
            withBuild=withBuild+1
            for part,tally in pairs(pieces) do
                for _,piece in ipairs(run.build[part] or {}) do
                    local item=tally[piece.key]
                    if not item then item={name=piece.name,icon=piece.icon,count=0};tally[piece.key]=item end
                    item.count=item.count+1;item.icon=item.icon or piece.icon
                end
            end
        end
    end
    local y=0
    Title(page,s2.text,y,E.Text("Класс за все забеги","The class over all runs"));s2.text=s2.text+1;y=y-22
    local function Pair(label,value)
        local l=Text(page,s2.text,SIZE,MUTED);s2.text=s2.text+1;l:SetPoint("TOPLEFT",page,"TOPLEFT",6,y);l:SetText(label)
        local v=Text(page,s2.text,SIZE);s2.text=s2.text+1;v:SetPoint("TOPLEFT",page,"TOPLEFT",190,y);v:SetText(value)
        y=y-16
    end
    Pair(E.Text("Забегов","Runs"),count..GREY..E.Text("  ·  всего ","  ·  in all ")..Clock(time).."|r")
    if longest then Pair(E.Text("Дольше всего","Longest"),Clock(longest.t).."  "..GREY..Tag(longest).."|r") end
    if strongest then Pair(E.Text("Сильнее всего","Strongest"),E.Short(Rate(strongest)).." DPS  "..GREY..Tag(strongest).."|r") end
    if count>0 then Pair(E.Text("В среднем","On average"),Clock(time/count)..(levelCount>0 and (E.Text("  ·  ур. ","  ·  lv. ")..math.floor(levels/levelCount+0.5)) or "")
        ..(killCount>0 and ("  ·  "..E.Short(kills/killCount)..E.Text(" убийств"," kills")) or "")) end
    y=y-8
    -- The places played, most played first.
    table.sort(placeOrder,function(a,b) return a.count>b.count end)
    Title(page,s2.text,y,E.Text("Где играл","Where you played"));s2.text=s2.text+1;y=y-20
    for index=1,math.min(5,table.getn(placeOrder)) do
        local entry=placeOrder[index]
        local name=Text(page,s2.text,SIZE);s2.text=s2.text+1;name:SetPoint("TOPLEFT",page,"TOPLEFT",6,y);name:SetText(Tag(entry.run))
        local value=Text(page,s2.text,SIZE,nil,"RIGHT");s2.text=s2.text+1;value:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y)
        value:SetText(entry.count..E.Text(" заб.  ·  до "," runs  ·  up to ")..Clock(entry.longest).."  ·  "..E.Short(entry.best).." DPS")
        y=y-16
    end
    y=y-8
    -- What the class plays most, as icons with their share of runs.
    local function Favourites(part,titleText)
        local list2={}
        for _,item in pairs(pieces[part]) do table.insert(list2,item) end
        table.sort(list2,function(a,b) return a.count>b.count end)
        if not list2[1] then return end
        local shown={}
        for index=1,math.min(8,table.getn(list2)) do
            local item=list2[index]
            table.insert(shown,{name=item.name,icon=item.icon,rank=string.format("%d%%",100*item.count/math.max(1,withBuild)),note=string.format(E.Text("В %d из %d забегов с билдом","In %d of %d runs with a build"),item.count,withBuild)})
        end
        y=IconRow(page,s2,titleText,shown,y,30,true)
    end
    Favourites("skills",E.Text("Чаще всего берёшь: скилы (доля забегов)","Picked most: skills (share of runs)"))
    Favourites("jewels",E.Text("Чаще всего носишь: бижутерия","Worn most: jewelry"))
    HideFrom(page.texts,s2.text);HideFrom(page.icons,s2.icon)
end
-- What works: each skill and piece of jewelry, runs with it against runs without, each run against the average of
-- its own zone and difficulty.
local function Works(page,list)
    local scores=Scores(list)
    local tally,built={},0
    for _,run in ipairs(list) do
        if type(run.build)=="table" then
            built=built+1
            local seen={}
            for _,part in ipairs({"skills","jewels"}) do
                for _,piece in ipairs(run.build[part] or {}) do
                    if not seen[piece.key] then
                        seen[piece.key]=true
                        local item=tally[piece.key]
                        if not item then item={name=piece.name,icon=piece.icon,with=0,withScore=0,withTime=0};tally[piece.key]=item end
                        item.with=item.with+1;item.withScore=item.withScore+scores[run];item.withTime=item.withTime+(run.t or 0)
                    end
                end
            end
        end
    end
    local allScore,allTime=0,0
    for _,run in ipairs(list) do if type(run.build)=="table" then allScore=allScore+scores[run];allTime=allTime+(run.t or 0) end end
    local rows={}
    for _,item in pairs(tally) do
        local without=built-item.with
        -- Only what some runs had and some did not, at least twice each way.
        if item.with>=2 and without>=2 then
            local withScore,withoutScore=item.withScore/item.with,(allScore-item.withScore)/without
            local withTime,withoutTime=item.withTime/item.with,(allTime-item.withTime)/without
            item.dps=withoutScore>0 and withScore/withoutScore-1 or 0
            item.time=withoutTime>0 and withTime/withoutTime-1 or 0
            item.without=without
            table.insert(rows,item)
        end
    end
    table.sort(rows,function(a,b) return a.dps>b.dps end)
    Title(page,1,0,E.Text("Что работает: забеги с этим против забегов без","What works: runs with it against runs without"))
    local hint=Text(page,2,SIZE-1,MUTED);hint:SetPoint("TOPLEFT",page,"TOPLEFT",0,-20);hint:SetWidth(PAGE_WIDTH);hint:SetHeight(28);hint:SetJustifyV("TOP")
    hint:SetText(E.Text("DPS каждого забега сравнивается со средним по его карте и сложности. Мало забегов — мало уверенности: смотрите на число в скобках.","Each run's DPS is taken against the average of its zone and difficulty. Few runs, little certainty: mind the count in brackets."))
    local head1=Text(page,3,SIZE-1,MUTED,"RIGHT");head1:SetPoint("TOPRIGHT",page,"TOPRIGHT",-90,-50);head1:SetText("DPS")
    local head2=Text(page,4,SIZE-1,MUTED,"RIGHT");head2:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,-50);head2:SetText(E.Text("время","time"))
    local y,textIndex,iconIndex=-66,5,1
    if not rows[1] then
        local note=Text(page,textIndex,SIZE,MUTED);textIndex=textIndex+1;note:SetPoint("TOPLEFT",page,"TOPLEFT",6,y)
        note:SetWidth(PAGE_WIDTH-6);note:SetHeight(32);note:SetJustifyV("TOP")
        note:SetText(E.Text("Нужно больше забегов с билдом: каждая вещь должна быть хотя бы в двух забегах и отсутствовать хотя бы в двух.","More runs with a build are needed: each thing must be in at least two runs and missing from at least two."))
    end
    local shown=0
    for index,item in ipairs(rows) do
        -- The best eight and the worst four.
        if index<=8 or index>table.getn(rows)-4 then
            if y<-(HEIGHT+PAGE_TOP-40) then break end
            local icon=Icon(page,iconIndex,20);iconIndex=iconIndex+1
            icon:ClearAllPoints();icon:SetPoint("TOPLEFT",page,"TOPLEFT",6,y+2);icon.texture:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            icon.rank:SetText("");icon.label=item.name;icon.note=nil;icon:Show()
            local name=Text(page,textIndex,SIZE);textIndex=textIndex+1;name:SetPoint("TOPLEFT",page,"TOPLEFT",32,y-2);name:SetWidth(PAGE_WIDTH-32-200);name:SetHeight(14)
            name:SetText(item.name..GREY..string.format("  (%d / %d)",item.with,item.without).."|r")
            local dps=Text(page,textIndex,SIZE,nil,"RIGHT");textIndex=textIndex+1;dps:SetPoint("TOPRIGHT",page,"TOPRIGHT",-90,y-2)
            dps:SetText((item.dps>=0 and GREEN or RED)..string.format("%+.0f%%",item.dps*100).."|r")
            local time=Text(page,textIndex,SIZE,nil,"RIGHT");textIndex=textIndex+1;time:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y-2)
            time:SetText((item.time>=0 and GREEN or RED)..string.format("%+.0f%%",item.time*100).."|r")
            y=y-24;shown=shown+1
        end
    end
    HideFrom(page.texts,textIndex);HideFrom(page.icons,iconIndex)
end

function frame.Refresh()
    title:SetText(E.Text("Анализ забегов","Run analysis"))
    local runs=Runs()
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
            Lit(button,class==state.class);button:Show()
        else button:Hide() end
    end
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
    -- What the run is held against: the best other run of its zone and difficulty, or the class's best.
    local target,targetName,versusWords
    if run and state.versus=="class" then
        target=best~=run and best or nil;targetName=E.Text("лучший класса","class best");versusWords=E.Text("к лучшему забегу класса","vs the class's best run")
    elseif run then
        for _,other in ipairs(list) do
            if other~=run and other.zone==run.zone and other.mode==run.mode and (not target or Rate(other)>Rate(target)) then target=other end
        end
        targetName=E.Text("лучший здесь","best here");versusWords=E.Text("к лучшему забегу здесь","vs the best run here")
    end
    for _,page in pairs(pages) do page:Hide() end
    if not run then
        empty:SetText(E.Text("Пока нет забегов длиннее 30 секунд.","No runs longer than 30 seconds yet."));empty:Show()
        head:SetText("");sub:SetText("")
        for _,button in ipairs(tabButtons) do button:Hide() end
        return
    end
    empty:Hide()
    head:SetText(Tag(run,true).."  ·  "..Clock(run.t)..(run.level and (E.Text("  ·  уровень ","  ·  level ")..run.level) or "")..(run.when and ("  ·  "..run.when) or ""))
    local versus=""
    if run==best then versus="   "..GOLD..E.Text("лучший забег класса","the class's best run").."|r"
    elseif target and Rate(target)>0 then
        local gain=math.floor((Rate(run)/Rate(target)-1)*100+0.5)
        versus="   "..(gain>=0 and GREEN or RED)..string.format("%+d%% %s (%s)",gain,versusWords,Tag(target)).."|r"
    end
    -- Damage by skill is on its own tab; the header keeps to the totals.
    sub:SetText(E.Text("Урон ","Damage ")..E.Short(run.dealt or 0).."  ·  "..E.Short(Rate(run))..E.Text(" DPS в среднем"," DPS on average")..versus)
    for _,button in ipairs(tabButtons) do button.label:SetText(E.Text(button.tab[2],button.tab[3]));Lit(button,button.tab[1]==state.tab);button:Show() end
    local page=pages[state.tab]
    if state.tab=="overview" then Overview(page,run,target,targetName)
    elseif state.tab=="build" then Build(page,run)
    elseif state.tab=="skills" then Skills(page,run)
    elseif state.tab=="profile" then Profile(page,list)
    elseif state.tab=="works" then Works(page,list)
    else Compare(page,run,target,targetName) end
    page:Show()
end

function E.ToggleRunReport()
    if frame:IsShown() then frame:Hide();return end
    state.chosen=nil;state.class=nil
    frame.Refresh();frame:Show()
end
-- Open on one run: the one given, else the current or just ended one, on its Overview.
function E.OpenRunReport(run)
    if not run and type(AZS_ZONE)=="table" then
        for _,entry in ipairs(Runs()) do if entry.run==AZS_ZONE.run then run=entry end end
    end
    state.class=run and run.class or nil;state.chosen=run;state.tab="overview"
    frame.Refresh();frame:Show()
    -- A run shorter than half a minute is not listed; the latest listed one stands in.
    if run and state.chosen~=run then state.chosen=nil;frame.Refresh() end
end

-- Before a run starts ("move to begin"), a card with the last run of the class: where, how long, how it went
-- against the best there, and a button to its analysis. It goes as soon as the run starts.
local card=CreateFrame("Frame","nfUILastRun",UIParent)
card:SetWidth(420);card:SetHeight(74);card:SetFrameStrata("HIGH");card:SetPoint("TOP",UIParent,"TOP",0,-110);card:Hide()
local cardFill=card:CreateTexture(nil,"BACKGROUND");cardFill:SetTexture(E.FLAT);cardFill:SetAllPoints(card)
cardFill:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.9)
E.Polish(card)
local cardTitle=Font(card,12,E.COLORS.mauve);cardTitle:SetPoint("TOPLEFT",card,"TOPLEFT",10,-8)
local cardLine=Font(card,SIZE,E.COLORS.text);cardLine:SetPoint("TOPLEFT",card,"TOPLEFT",10,-26);cardLine:SetWidth(400);cardLine:SetHeight(14)
local cardNote=Font(card,SIZE,E.COLORS.text);cardNote:SetPoint("TOPLEFT",card,"TOPLEFT",10,-42);cardNote:SetWidth(290);cardNote:SetHeight(26);cardNote:SetJustifyV("TOP")
local cardButton=Tab(card,22);cardButton:SetWidth(110);cardButton:SetPoint("BOTTOMRIGHT",card,"BOTTOMRIGHT",-8,8);Lit(cardButton,true)
cardButton:SetScript("OnClick",function() card:Hide();card.dismissed=true;E.OpenRunReport(card.run) end)
local cardClose=CreateFrame("Button",nil,card);cardClose:SetWidth(16);cardClose:SetHeight(16);cardClose:SetPoint("TOPRIGHT",card,"TOPRIGHT",-4,-4)
cardClose.label=Font(cardClose,11,E.COLORS.text,"CENTER");cardClose.label:SetPoint("CENTER",cardClose,"CENTER",0,0);cardClose.label:SetText("x")
cardClose:SetScript("OnClick",function() card:Hide();card.dismissed=true end)
local cardAge=0
local cardDriver=CreateFrame("Frame")
cardDriver:SetScript("OnUpdate",function()
    cardAge=cardAge+(arg1 or 0);if cardAge<0.5 then return end;cardAge=0
    local ready=AZS_GetPhase and AZS_GetPhase()=="ready"
    if not ready then card:Hide();card.dismissed=nil;return end
    if card.dismissed or not E.On("lastRunCard") or type(AZS_ZONE)~="table" then card:Hide();return end
    -- The class's latest finished run, other than the one about to start.
    local last,best
    local runs=Runs()
    for index=table.getn(runs),1,-1 do
        local run=runs[index]
        if run.class==AZS_ZONE.cname and run.run~=AZS_ZONE.run and (run.t or 0)>=30 then
            if not last then last=run end
            if last and run~=last and run.zone==last.zone and run.mode==last.mode and (not best or Rate(run)>Rate(best)) then best=run end
        end
    end
    if not last then card:Hide();return end
    card.run=last
    cardTitle:SetText(E.Text("Прошлый забег","Last run")..(last.when and ("  "..GREY..last.when.."|r") or ""))
    local final=type(last.final)=="table" and last.final or {}
    cardLine:SetText(Tag(last,true).."  ·  "..Clock(last.t)..(last.level and (E.Text("  ·  ур. ","  ·  lv. ")..last.level) or "")
        .."  ·  "..E.Short(Rate(last)).." DPS"..(final.kills and ("  ·  "..E.Short(final.kills)..E.Text(" убийств"," kills")) or ""))
    local note
    if best and Rate(best)>0 then
        local gain=Rate(last)/Rate(best)-1
        note=(gain>=0 and (GREEN..E.Text("Лучший здесь","Best here").."|r") or ((RED..string.format("%+.0f%%",gain*100).."|r")..E.Text(" к лучшему здесь"," vs the best here")))
    else note=GREY..E.Text("Других забегов здесь нет","No other runs here").."|r" end
    local summary=Summary(last)
    cardNote:SetText(note..(summary[1] and ("\n"..summary[1]) or ""))
    cardButton.label:SetText(E.Text("Разбор","Review"))
    card:Show()
end)
-- Kept fresh while open, as the current run goes on; not while the mouse is over an icon, so its tooltip stays.
local age=0
frame:SetScript("OnUpdate",function()
    age=age+(arg1 or 0);if age<2 then return end;age=0
    if frame.hovering then return end
    frame.Refresh()
end)

local command=SlashCmdList["NFUI"]
SlashCmdList["NFUI"]=function(message)
    local word=string.lower(message or "")
    if word=="runs" or word=="analysis" then E.ToggleRunReport();return end
    if command then command(message) end
end
