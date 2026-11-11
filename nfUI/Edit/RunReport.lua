-- Run analysis: a window with every kept run of a class. On the left the runs; on the right the chosen one in tabs:
-- Overview (damage per second over time and the picks), Build (icons of what it was played with), Skills (damage
-- by skill) and Compare (against the class's best run). Opened from the quick menu, the sword by the minimap,
-- the settings window or `/nfui runs`.
local E=nfUIEdit
local WIDTH,HEIGHT,LIST_WIDTH,ROW,ROWS=820,620,250,22,20
local SIZE=11
local STEP=30
local GREEN,RED,GREY,GOLD="|cff7fd67f","|cffff7070","|cff8a8a96","|cffffd27f"

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
local function Tag(run)
    local _,_,heroic=string.find(run.mode or "","^(%d+)/")
    heroic=tonumber(heroic) or 0
    return tostring(run.zone or "?")..(heroic>0 and (E.Text(" Г"," H")..heroic) or "")
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

local state={class=nil,chosen=nil,tab="overview"}
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
    rows[index]=row
end

-- The right side: a header, the tabs, and a page per tab.
local LEFT=8+LIST_WIDTH+12
local PAGE_WIDTH=WIDTH-LEFT-10
local head=Font(frame,13,E.COLORS.yellow);head:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,-56);head:SetWidth(PAGE_WIDTH);head:SetHeight(16)
local sub=Font(frame,SIZE,E.COLORS.text);sub:SetPoint("TOPLEFT",head,"BOTTOMLEFT",0,-4);sub:SetWidth(PAGE_WIDTH);sub:SetHeight(30);sub:SetJustifyV("TOP")
local TABS={{"overview","Обзор","Overview"},{"build","Билд","Build"},{"skills","Скилы","Skills"},{"compare","Сравнение","Compare"}}
local tabButtons={}
for index,tab in ipairs(TABS) do
    local button=Tab(frame,20);button:SetWidth(96);button.tab=tab
    button:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT+(index-1)*100,-110)
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
local empty=Font(frame,SIZE,{0.6,0.6,0.65});empty:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,-60)

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
    local label=Text(page,firstText,SIZE-1,{0.6,0.6,0.65});label:SetPoint("TOPLEFT",page,"TOPLEFT",x,y);label:SetText(caption)
    local peak=Text(page,firstText+1,SIZE-1,{0.6,0.6,0.65},"RIGHT");peak:SetPoint("TOPRIGHT",back,"TOPRIGHT",-2,-2);peak:SetText(E.Short(top).." DPS")
    local startLabel=Text(page,firstText+2,SIZE-1,{0.6,0.6,0.65});startLabel:SetPoint("TOPLEFT",back,"BOTTOMLEFT",0,-2);startLabel:SetText("0:00")
    local endLabel=Text(page,firstText+3,SIZE-1,{0.6,0.6,0.65},"RIGHT");endLabel:SetPoint("TOPRIGHT",back,"BOTTOMRIGHT",0,-2);endLabel:SetText(Clock(count*STEP*(size or 1)))
    return barIndex,y-14-height-16
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
local function PickName(event)
    local _,_,name=string.find(event.text,"^%+? ?(.-) [%d]+ > [%d]+$")
    if not name then _,_,name=string.find(event.text,"^%+ (.-) ?[%d]*$") end
    return name or event.text
end
local function GroupText(group)
    local names,order={},{}
    for _,event in ipairs(group.picks) do
        local name=PickName(event)
        if not names[name] then names[name]={count=0,text=event.text};table.insert(order,name) end
        names[name].count=names[name].count+1;names[name].text=event.text
    end
    local parts={}
    for _,name in ipairs(order) do local item=names[name];table.insert(parts,item.count>1 and (name.." x"..item.count) or item.text) end
    return table.concat(parts,", ")
end

-- Overview: the graph against the best, and the picks with their icons.
local function Overview(page,run,best)
    local mine,bestSteps,size=Steps(run,best and best~=run and best or nil)
    local barIndex,y=Graph(page,1,1,0,0,PAGE_WIDTH,96,mine,bestSteps,
        E.Text("DPS по ходу забега","DPS through the run")..(bestSteps and ("  ·  "..GOLD..E.Text("жёлтый","yellow").."|r "..E.Text("этот, ","this one, ").."|cffc6a0f6"..E.Text("сиреневый","violet").."|r "..E.Text("лучший","the best")) or ""),size)
    HideFrom(page.bars,barIndex)
    local t=Text(page,5,SIZE,{1,0.82,0.5});t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y-6)
    t:SetText(E.Text("Прибавки: DPS за 30 с до и после, близкие покупки вместе","Picks: DPS 30 s before and after, close ones together"))
    y=y-26
    local groups=Groups(run.events)
    local textIndex,iconIndex=6,1
    if not groups[1] then
        local note=Text(page,textIndex,SIZE,{0.6,0.6,0.65});note:SetPoint("TOPLEFT",page,"TOPLEFT",6,y)
        note:SetText(E.Text("У этого забега их нет: они пишутся с версии 1.3.","None for this run: they are kept from version 1.3."));textIndex=textIndex+1
    end
    local first=math.max(1,table.getn(groups)-11)
    for index=first,table.getn(groups) do
        local group=groups[index]
        local when=Text(page,textIndex,SIZE,{0.6,0.6,0.65});textIndex=textIndex+1
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
        what:SetPoint("TOPLEFT",page,"TOPLEFT",92+4*20+4,y-3);what:SetWidth(PAGE_WIDTH-92-84-60);what:SetHeight(14);what:SetText(GroupText(group))
        local change=Text(page,textIndex,SIZE,nil,"RIGHT");textIndex=textIndex+1
        change:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y-3)
        change:SetText(group.gain and ((group.gain>=0 and GREEN or RED)..string.format("%+.0f%%",group.gain*100).."|r") or (GREY.."...|r"))
        y=y-22
    end
    HideFrom(page.texts,textIndex);HideFrom(page.icons,iconIndex)
end

-- A row of icons for a part of a build, with a title; returns the y below it.
local function IconRow(page,state2,titleText,pieces,y,size)
    local t=Text(page,state2.text,SIZE,{1,0.82,0.5});state2.text=state2.text+1
    t:SetPoint("TOPLEFT",page,"TOPLEFT",0,y);t:SetText(titleText)
    y=y-18
    local perRow=math.floor(PAGE_WIDTH/(size+6))
    local column=0
    for _,piece in ipairs(pieces) do
        if column>=perRow then column=0;y=y-size-6 end
        local icon=Icon(page,state2.icon,size);state2.icon=state2.icon+1
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",page,"TOPLEFT",column*(size+6),y)
        icon.texture:SetTexture(piece.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon.rank:SetText(piece.rank or "");icon.label=piece.name;icon.note=piece.note;icon:Show()
        column=column+1
    end
    return y-size-12
end

-- Build: icons of every part, talents and luck as text.
local function Build(page,run)
    local build=run.build
    local s2={text=1,icon=1}
    if type(build)~="table" then
        local note=Text(page,1,SIZE,{0.6,0.6,0.65});note:SetPoint("TOPLEFT",page,"TOPLEFT",0,0)
        note:SetText(E.Text("У этого забега билд не записан.","No build was kept for this run."))
        HideFrom(page.texts,2);HideFrom(page.icons,1)
        return
    end
    local y=0
    local titles={skills=E.Text("Скилы","Skills"),jewels=E.Text("Бижутерия","Jewelry"),gear=E.Text("Снаряжение","Gear")}
    for _,part in ipairs({"skills","jewels","gear"}) do
        if build[part] and build[part][1] then y=IconRow(page,s2,titles[part],build[part],y,32) end
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
        local note=Text(page,textIndex,SIZE,{0.6,0.6,0.65});textIndex=textIndex+1;note:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        note:SetText(E.Text("Урон по скилам не записан.","No damage by skill was kept."))
    end
    HideFrom(page.texts,textIndex);HideFrom(page.icons,iconIndex);HideFrom(page.bars,barIndex)
end

-- Compare: this run against the class's best, over time and in the build.
local function Compare(page,run,best)
    if not best or best==run then
        local note=Text(page,1,SIZE,{0.6,0.6,0.65});note:SetPoint("TOPLEFT",page,"TOPLEFT",0,0)
        note:SetText(run==best and E.Text("Это и есть лучший забег класса: выберите другой слева.","This is the class's best run: choose another on the left.")
            or E.Text("Не с чем сравнить.","Nothing to compare with."))
        HideFrom(page.texts,2);HideFrom(page.icons,1);HideFrom(page.bars,1)
        return
    end
    local gain=Rate(best)>0 and (Rate(run)/Rate(best)-1) or 0
    local mine,theirs,size=Steps(run,best)
    local barIndex,y=Graph(page,1,1,0,0,PAGE_WIDTH,110,mine,theirs,
        GOLD..E.Text("этот","this one").."|r "..E.Short(Rate(run)).." DPS   |cffc6a0f6"..E.Text("лучший","best").."|r "..Tag(best).." "..E.Short(Rate(best)).." DPS   "
        ..(gain>=0 and GREEN or RED)..string.format("%+.0f%%",gain*100).."|r",size)
    HideFrom(page.bars,barIndex)
    local s2={text=5,icon=1}
    local here,there=PartsByKey(run.build),PartsByKey(best.build)
    local only,missing,ranks={},{},{}
    for key,piece in pairs(here) do
        if not there[key] then table.insert(only,piece)
        elseif piece.rank and there[key].rank and piece.rank~=there[key].rank then
            table.insert(ranks,{name=piece.name,icon=piece.icon,rank=piece.rank,note=E.Text("Ранг здесь ","Rank here ")..piece.rank..E.Text(", в лучшем ",", in the best ")..there[key].rank})
        end
    end
    for key,piece in pairs(there) do if not here[key] then table.insert(missing,piece) end end
    y=y-4
    if type(run.build)~="table" or type(best.build)~="table" then
        local note=Text(page,s2.text,SIZE,{0.6,0.6,0.65});s2.text=s2.text+1;note:SetPoint("TOPLEFT",page,"TOPLEFT",0,y)
        note:SetText(E.Text("У одного из забегов билд не записан.","One of the runs has no build kept."))
    else
        if only[1] then y=IconRow(page,s2,E.Text("Только в этом","Only in this one"),only,y,28) end
        if missing[1] then y=IconRow(page,s2,E.Text("Только в лучшем","Only in the best"),missing,y,28) end
        if ranks[1] then y=IconRow(page,s2,E.Text("Другой ранг (наведите)","Another rank (hover)"),ranks,y,28) end
    end
    HideFrom(page.texts,s2.text);HideFrom(page.icons,s2.icon)
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
    for _,page in pairs(pages) do page:Hide() end
    if not run then
        empty:SetText(E.Text("Пока нет забегов длиннее 30 секунд.","No runs longer than 30 seconds yet."));empty:Show()
        head:SetText("");sub:SetText("")
        for _,button in ipairs(tabButtons) do button:Hide() end
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
    for _,button in ipairs(tabButtons) do button.label:SetText(E.Text(button.tab[2],button.tab[3]));Lit(button,button.tab[1]==state.tab);button:Show() end
    local page=pages[state.tab]
    if state.tab=="overview" then Overview(page,run,best)
    elseif state.tab=="build" then Build(page,run)
    elseif state.tab=="skills" then Skills(page,run)
    else Compare(page,run,best) end
    page:Show()
end

function E.ToggleRunReport()
    if frame:IsShown() then frame:Hide();return end
    state.chosen=nil;state.class=nil
    frame.Refresh();frame:Show()
end
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
