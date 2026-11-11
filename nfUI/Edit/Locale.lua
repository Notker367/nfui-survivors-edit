-- Shared helpers for the Survivors Edit modules: language choice and the common frame styling.
nfUIEdit={}
local E=nfUIEdit
-- The game's own fonts for the languages Friz Quadrata has no letters for.
local LANGUAGE_FONTS={zh="Fonts\\AZS_SC.TTF",ja="Fonts\\AZS_JP.TTF",ko="Fonts\\AZS_KR.TTF"}
local language=GetCVar("azsLanguage")
-- A font that does not load leaves every text using it unable to show: test first, and fall back.
local FALLBACK_FONT="Fonts\\FRIZQT__.TTF"
local tester=CreateFrame("Frame"):CreateFontString(nil,"OVERLAY")
local function Usable(path)
    if not path then return nil end
    local ok=pcall(tester.SetFont,tester,path,12)
    if ok then ok=pcall(tester.SetText,tester,"1") end
    if ok then return path end
    return nil
end
NFUI_FONT=Usable(LANGUAGE_FONTS[language]) or FALLBACK_FONT
-- Narrower and clearer at small sizes, for the bars over heads. It has no Romanian s and t with a comma.
NFUI_PLATE_FONT=Usable(LANGUAGE_FONTS[language]) or (language=="ro" and FALLBACK_FONT) or Usable("Fonts\\ARIALN.TTF") or FALLBACK_FONT
E.FONT=NFUI_FONT
-- The name players see. The folder, the saved settings and /nfui keep the original nfUI name, so updates keep working.
E.NAME="Survivors HUD"
E.FLAT="Interface\\Buttons\\WHITE8X8"
-- The interface's colours, after Catppuccin Mocha. Level colours stay the classic game's.
local function RGB(hex)
    return {tonumber(string.sub(hex,1,2),16)/255,tonumber(string.sub(hex,3,4),16)/255,tonumber(string.sub(hex,5,6),16)/255}
end
E.COLORS={enemy=RGB("e0393e"),base=RGB("1e1e2e"),mantle=RGB("181825"),surface=RGB("313244"),text=RGB("cdd6f4"),red=RGB("f38ba8"),peach=RGB("fab387"),
    yellow=RGB("f9e2af"),green=RGB("a6e3a1"),sapphire=RGB("74c7ec"),blue=RGB("89b4fa"),mauve=RGB("cba6f7")}
-- A stable, gentle colour for a name: the same skill keeps its colour between runs.
local SOFT={"blue","mauve","sapphire","peach","green","yellow","red","teal","pink"}
E.COLORS.teal=RGB("94e2d5");E.COLORS.pink=RGB("f5c2e7")
function E.SoftColor(name)
    local total=0
    name=tostring(name or "")
    for index=1,string.len(name) do total=math.mod(total*31+string.byte(name,index),9973) end
    local tint=E.COLORS[SOFT[math.mod(total,table.getn(SOFT))+1]]
    -- Deep enough for white text to read on it.
    return {tint[1]*0.55,tint[2]*0.55,tint[3]*0.55}
end
-- The action buttons the game uses: 1 to 6 and the = key.
E.BUTTONS={1,2,3,4,5,6,12}

function E.Mode()
    return type(nfUIDB)=="table" and nfUIDB.uiMode or "default"
end
-- How much is shown is a set of defaults. Minimal keeps the fight; Default adds bosses, guardians, pools and the run
-- against the best; Detailed adds everything for testing builds. A switch the player sets by hand wins over the mode
-- and is marked as changed; "Reset section" gives it back to the mode.
E.MODE_DEFAULTS={
    hidden={bossSchedule=false,lairPanel=false,takenPanel=false,historyPanel=false,skillPool=false,jewelPool=false,legendRow=false,
        heroStats=false,dpsGraph=false,farPlates=false,skillRate=false,targetOfTarget=false,separateHits=false,banishMarks=false},
    default={takenPanel=false,heroStats=false,dpsGraph=false,farPlates=false,skillRate=false,targetOfTarget=false},
    detailed={takenPanel=true,heroStats=true,dpsGraph=true,farPlates=true,skillRate=true,targetOfTarget=false},
}
-- Earlier builds kept every switch with its value, so a switch differing from the old default is one the player chose.
local OLD_DEFAULT_OFF={colorblind=true}
local function Migrate(db)
    if db.editMigrated then return end
    db.editMigrated=true
    db.editSet=type(db.editSet)=="table" and db.editSet or {}
    for key,value in pairs(type(db.edit)=="table" and db.edit or {}) do
        local was=not OLD_DEFAULT_OFF[key]
        if (value~=false)~=was then db.editSet[key]=true end
    end
end
-- Whether the player has set this switch by hand.
function E.SwitchChanged(key)
    local db=type(nfUIDB)=="table" and nfUIDB
    if not db then return false end
    Migrate(db)
    return type(db.editSet)=="table" and db.editSet[key]==true
end
function E.SetSwitch(key,value)
    if type(nfUIDB)~="table" then return end
    Migrate(nfUIDB)
    if type(nfUIDB.edit)~="table" then nfUIDB.edit={} end
    nfUIDB.edit[key]=value and true or false
    nfUIDB.editSet[key]=true
end
function E.ResetSwitch(key)
    if type(nfUIDB)~="table" then return end
    Migrate(nfUIDB)
    nfUIDB.editSet[key]=nil
    if type(nfUIDB.edit)=="table" then nfUIDB.edit[key]=nil end
end
-- A switch as it works now: the player's own choice, else the mode's default, else on.
function E.On(key)
    local db=type(nfUIDB)=="table" and nfUIDB
    if db and E.SwitchChanged(key) then return type(db.edit)~="table" or db.edit[key]~=false end
    local preset=E.MODE_DEFAULTS[E.Mode()]
    if preset and preset[key]~=nil then return preset[key] end
    if OLD_DEFAULT_OFF[key] then return false end
    return true
end

function E.IsRussian() return GetCVar("azsLanguage")=="ru" end
-- Text the game itself provides, in the client's language.
function E.Pick(texts)
    if type(texts)~="table" then return nil end
    local text=texts[GetCVar("azsLanguage")] or texts.en
    if text=="" then return nil end
    return text
end
-- Picks the Russian or the English text.
function E.Text(russian,english) if E.IsRussian() then return russian end return english end

-- The level before a name, coloured by its difference from the hero's, as the classic game does:
-- red, orange, yellow, green, grey. Tags are kept, because every plate asks on every update.
local levelTags,levelTagsFor={},nil
local function LevelColor(level,own)
    local gap=level-own
    if gap>=5 then return "ff1919" end
    if gap>=3 then return "ff8040" end
    if gap>=-2 then return "ffff00" end
    local grey=0
    if own>=40 then grey=own-1-math.floor(own/5) elseif own>=6 then grey=own-5-math.floor(own/10) end
    if level>grey then return "40c040" end
    return "808080"
end
function E.LevelTag(level)
    if not E.On("levels") then return "" end
    local number=tonumber(level)
    if not number and level~="??" then return "" end
    local own=UnitLevel("player") or 1
    if own~=levelTagsFor then levelTags={};levelTagsFor=own end
    local key=number or "??"
    local tag=levelTags[key]
    if not tag then
        if number and number>0 then tag="|cff"..LevelColor(number,own)..number.."|r "
        else tag="|cffff1919??|r " end
        levelTags[key]=tag
    end
    return tag
end

-- How solid a bar is at this distance: whole up close, down to the chosen floor far away.
local FADE_NEAR,FADE_FAR=5,22
function E.DistanceFade(yards)
    if not E.On("plateFade") or type(yards)~="number" then return 1 end
    local floor=E.Size("plateFadeScale",0.35)
    local part=math.max(0,math.min(1,(yards-FADE_NEAR)/(FADE_FAR-FADE_NEAR)))
    return 1-(1-floor)*part
end

-- How a health bar takes a hit: it drops at once, a copy of the lost piece is torn off and falls, a bright line marks
-- the new edge, and the lost piece itself stays white-hot for a moment before it drains. State is kept on the table
-- given, one for each bar.
local HOLD,FLASH_TIME=0.2,0.18
local CHIP_LIFE,CHIP_FALL,CHIPS_PER_BAR=0.95,26,4
local flying={}
local chipDriver=CreateFrame("Frame","nfUIEditChips")
chipDriver:SetScript("OnUpdate",function()
    local elapsed=arg1 or 0
    for index=table.getn(flying),1,-1 do
        local chip=flying[index]
        chip.age=chip.age+elapsed
        if chip.age>=CHIP_LIFE then
            chip.piece:Hide();chip.line:Hide();chip.busy=false
            table.remove(flying,index)
        else
            local part=chip.age/CHIP_LIFE
            -- It hangs for an instant, then falls faster and faster and tips toward its broken side.
            local drop=CHIP_FALL*part*part
            chip.piece:ClearAllPoints()
            chip.piece:SetPoint("LEFT",chip.bar,"LEFT",chip.x+chip.drift*part,-drop)
            local fade=1-part*part
            chip.piece:SetAlpha(fade)
            chip.piece:SetVertexColor(1,0.86-0.4*part,0.62-0.45*part)
            chip.line:SetAlpha(math.max(0,1-part*2.5))
        end
    end
end)
local function TearOff(bar,from,to)
    local width=bar:GetWidth()
    if not width or width<=0 then return end
    bar.nfuiChips=bar.nfuiChips or {}
    local chip
    for _,one in ipairs(bar.nfuiChips) do if not one.busy then chip=one;break end end
    if not chip then
        if table.getn(bar.nfuiChips)>=CHIPS_PER_BAR then return end
        chip={bar=bar,piece=bar:CreateTexture(nil,"OVERLAY"),line=bar:CreateTexture(nil,"OVERLAY")}
        chip.piece:SetTexture(E.FLAT);chip.line:SetTexture(E.FLAT);chip.line:SetVertexColor(1,1,1,1)
        table.insert(bar.nfuiChips,chip)
    end
    chip.busy=true;chip.age=0
    chip.x=width*to;chip.drift=4+math.min(14,width*(from-to)*0.15)
    chip.piece:SetWidth(math.max(2,width*(from-to)));chip.piece:SetHeight(bar:GetHeight())
    chip.piece:ClearAllPoints();chip.piece:SetPoint("LEFT",bar,"LEFT",chip.x,0);chip.piece:SetAlpha(1);chip.piece:SetVertexColor(1,0.86,0.62);chip.piece:Show()
    chip.line:SetWidth(2);chip.line:SetHeight(bar:GetHeight()+4)
    chip.line:ClearAllPoints();chip.line:SetPoint("CENTER",bar,"LEFT",chip.x,0);chip.line:SetAlpha(1);chip.line:Show()
    table.insert(flying,chip)
end
function E.HitTrail(state,share,elapsed,bar)
    local shown,trail=state.shown or share,state.trail or share
    local impact=E.On("hitImpact")
    if share<(state.last or share)-0.001 then
        state.hold=HOLD
        state.flash=1
        state.hit=(state.last or share)-share
        if impact and bar and state.hit>=0.008 then TearOff(bar,state.last,share) end
    end
    state.last=share
    if share<shown then
        if impact then shown=share else shown=shown+(share-shown)*math.min(1,elapsed*12) end
    else
        shown=shown+(share-shown)*math.min(1,elapsed*12)
    end
    if math.abs(share-shown)<0.002 then shown=share end
    if trail<share then
        trail=share
    elseif impact and (state.hold or 0)>0 then
        state.hold=state.hold-elapsed
    else
        trail=math.max(share,trail-elapsed*(0.6+(trail-share)*4))
    end
    state.flash=math.max(0,(state.flash or 0)-elapsed/FLASH_TIME)
    state.shown,state.trail=shown,trail
    return shown,trail,impact and state.flash or 0
end
-- The lost piece's colour: white at the blow, settling into the trail's colour.
function E.TrailColor(flash)
    local c=E.COLORS.yellow
    -- Warm rather than pure white, so that the white text over the bar stays readable.
    return c[1]+(1-c[1])*flash,c[2]+(0.86-c[2])*flash,c[3]+(0.62-c[3])*flash
end

-- Hits by skill over the last minute, in one-second buckets: how often it fires and its biggest hit.
local hitLog={}
-- The combat log and the meter can word a skill in different languages: one key for all its names.
local skillKeys
local function SkillKey(name)
    if not skillKeys then
        skillKeys={}
        for key,names in pairs(E.SKILL_NAMES or {}) do
            for _,word in pairs(names) do skillKeys[word]=key end
        end
    end
    return skillKeys[name] or name
end
function E.TrackHit(spell,amount)
    local value=tonumber(amount)
    if not value then return end
    local key=(spell and spell~="") and SkillKey(spell) or "Melee"
    local log=hitLog[key]
    if not log then log={};hitLog[key]=log end
    local second=math.floor(GetTime())
    local bucket=log[second]
    if not bucket then
        bucket={count=0,max=0};log[second]=bucket
        log[second-61]=nil
    end
    bucket.count=bucket.count+1
    if value>bucket.max then bucket.max=value end
end
-- Hits per second over the last 10 seconds (the game speeds up, so a minute's count says little) and the
-- biggest hit over the last minute.
local RATE_SECONDS=10
function E.HitStats(name)
    local log=hitLog[SkillKey(name)]
    if not log and name==E.L("Melee") then log=hitLog.Melee end
    if not log then return nil end
    local now=math.floor(GetTime())
    local count,biggest=0,0
    for second=now-59,now do
        local bucket=log[second]
        if bucket then
            if second>now-RATE_SECONDS then count=count+bucket.count end
            if bucket.max>biggest then biggest=bucket.max end
        end
    end
    if biggest==0 then return nil end
    return count/RATE_SECONDS,biggest
end
function E.Rate(perSecond)
    if not perSecond then return "-" end
    if perSecond<10 then return string.format("%.1f",perSecond) end
    return string.format("%.0f",perSecond)
end

-- A hit in full, its thousands set apart: 12 345.
function E.Full(value)
    local text=string.format("%.0f",tonumber(value) or 0)
    local grouped=text
    while true do
        local result,count=string.gsub(grouped,"^(-?%d+)(%d%d%d)","%1 %2")
        grouped=result
        if count==0 then break end
    end
    return grouped
end

-- At most five characters at any size: 999, 9.9k, 999k, 99.9m, 999m, 99.9b.
function E.Short(value)
    value=tonumber(value) or 0
    local sign=value<0 and "-" or "";value=math.abs(value)
    if value>=99950000000 then return sign..string.format("%.0fb",value/1000000000) end
    if value>=999500000 then return sign..string.format("%.1fb",value/1000000000) end
    if value>=99950000 then return sign..string.format("%.0fm",value/1000000) end
    if value>=999500 then return sign..string.format("%.1fm",value/1000000) end
    if value>=9995 then return sign..string.format("%.0fk",value/1000) end
    if value>=999.5 then return sign..string.format("%.1fk",value/1000) end
    return sign..string.format("%.0f",value)
end

-- Soft shadow and a thin edge behind a frame. Not for action buttons: their icon lies in the same layer.
function E.Polish(object,backed)
    if not object or object.nfuiPolished or not nfUIWidgets then return end
    object.nfuiPolished=true
    nfUIWidgets.Fill(object,{0,0,0,0.18},"BACKGROUND",-3)
    nfUIWidgets.Fill(object,{0,0,0,0.28},"BACKGROUND",-2)
    nfUIWidgets.Fill(object,{0,0,0,0.9},"BACKGROUND",-1)
    if backed then local c=E.COLORS.base;nfUIWidgets.Fill(object,{c[1],c[2],c[3],0.7},"BACKGROUND",0) end
end

-- A thin edge outside a frame, which leaves whatever is inside it visible.
function E.Ring(object)
    if not object or object.nfuiRing then return end
    object.nfuiRing=true
    local function Line(a,b,x1,y1,x2,y2)
        local line=object:CreateTexture(nil,"OVERLAY")
        line:SetTexture(E.FLAT);line:SetVertexColor(0,0,0,0.9)
        line:SetPoint(a,object,a,x1,y1);line:SetPoint(b,object,b,x2,y2)
        return line
    end
    Line("TOPLEFT","TOPRIGHT",-1,1,1,1):SetHeight(1)
    Line("BOTTOMLEFT","BOTTOMRIGHT",-1,-1,1,-1):SetHeight(1)
    Line("TOPLEFT","BOTTOMLEFT",-1,1,-1,-1):SetWidth(1)
    Line("TOPRIGHT","BOTTOMRIGHT",1,1,1,-1):SetWidth(1)
end

-- A thin coloured line along each side of a frame, leaving what is inside it visible.
function E.Edge(object,r,g,b,a)
    local edge={}
    local function Line(p1,p2,x1,y1,x2,y2)
        local line=object:CreateTexture(nil,"OVERLAY")
        line:SetTexture(E.FLAT);line:SetVertexColor(r,g,b,a);line:Hide()
        line:SetPoint(p1,object,p1,x1,y1);line:SetPoint(p2,object,p2,x2,y2)
        table.insert(edge,line)
        return line
    end
    Line("TOPLEFT","TOPRIGHT",-1,1,1,1):SetHeight(1)
    Line("BOTTOMLEFT","BOTTOMRIGHT",-1,-1,1,-1):SetHeight(1)
    Line("TOPLEFT","BOTTOMLEFT",-1,1,-1,-1):SetWidth(1)
    Line("TOPRIGHT","BOTTOMRIGHT",1,1,1,-1):SetWidth(1)
    -- Thicker lines grow outward; lines are the four first entries.
    function edge.SetSize(size)
        size=size or 1
        if edge.size==size then return end
        edge.size=size
        edge[1]:ClearAllPoints();edge[1]:SetPoint("TOPLEFT",object,"TOPLEFT",-size,size);edge[1]:SetPoint("TOPRIGHT",object,"TOPRIGHT",size,size);edge[1]:SetHeight(size)
        edge[2]:ClearAllPoints();edge[2]:SetPoint("BOTTOMLEFT",object,"BOTTOMLEFT",-size,-size);edge[2]:SetPoint("BOTTOMRIGHT",object,"BOTTOMRIGHT",size,-size);edge[2]:SetHeight(size)
        edge[3]:ClearAllPoints();edge[3]:SetPoint("TOPLEFT",object,"TOPLEFT",-size,size);edge[3]:SetPoint("BOTTOMLEFT",object,"BOTTOMLEFT",-size,-size);edge[3]:SetWidth(size)
        edge[4]:ClearAllPoints();edge[4]:SetPoint("TOPRIGHT",object,"TOPRIGHT",size,size);edge[4]:SetPoint("BOTTOMRIGHT",object,"BOTTOMRIGHT",size,-size);edge[4]:SetWidth(size)
    end
    function edge.SetColor(red,green,blue,alpha)
        for _,line in ipairs(edge) do line:SetVertexColor(red,green,blue,alpha) end
    end
    function edge.Show() for _,line in ipairs(edge) do line:Show() end end
    function edge.Hide() for _,line in ipairs(edge) do line:Hide() end end
    return edge
end

-- A small clickable title that folds a panel away and back. The choice is kept between sessions. A folded panel can
-- give the one thing that matters most, which then takes the title's place.
function E.IsCollapsed(key)
    local db=type(nfUIDB)=="table" and nfUIDB.collapsed
    return type(db)=="table" and db[key]==true
end
function E.Collapsible(frame,key,title,onChange,above)
    local header=CreateFrame("Button",nil,frame)
    header:SetHeight(14);header:SetWidth(above and math.min(frame:GetWidth(),150) or frame:GetWidth()-8)
    if above then header:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",0,1) else header:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-3) end
    header.label=header:CreateFontString(nil,"OVERLAY");header.label:SetFont(E.FONT,11,"OUTLINE")
    header.label:SetPoint("LEFT",header,"LEFT",2,0);header.label:SetTextColor(E.COLORS.mauve[1],E.COLORS.mauve[2],E.COLORS.mauve[3])
    header.label:SetWidth(header:GetWidth()-2);header.label:SetHeight(13);header.label:SetJustifyH("LEFT")
    -- Folded, the numbers stand at the right and are never cut; the words take what room is left.
    header.value=header:CreateFontString(nil,"OVERLAY");header.value:SetFont(E.FONT,11,"OUTLINE")
    header.value:SetPoint("RIGHT",header,"RIGHT",-2,0);header.value:SetHeight(13);header.value:SetJustifyH("RIGHT")
    local function Show()
        local folded=E.IsCollapsed(key)
        local value=folded and header.summaryValue or ""
        header.value:SetText(value)
        local valueWidth=value~="" and (header.value:GetStringWidth()+6) or 0
        header.label:SetWidth(math.max(10,header:GetWidth()-2-valueWidth))
        header.label:SetText((folded and "[+] " or "[-] ")..(folded and header.summary or title))
        local color=folded and header.summaryColor or E.COLORS.mauve
        header.label:SetTextColor(color[1],color[2],color[3]);header.value:SetTextColor(color[1],color[2],color[3])
    end
    header.Refresh=Show
    header:SetScript("OnClick",function()
        if type(nfUIDB.collapsed)~="table" then nfUIDB.collapsed={} end
        nfUIDB.collapsed[key]=(not nfUIDB.collapsed[key]) or nil
        Show()
        if onChange then onChange() end
    end)
    Show()
    frame.collapseHeader=header
    return header
end

-- Runs a job every so many seconds from one shared timer.
local jobs={}
function E.Every(seconds,job) table.insert(jobs,{every=seconds,age=seconds,job=job}) end
local timer=CreateFrame("Frame","nfUIEditTimer")
timer:SetScript("OnUpdate",function()
    local elapsed=arg1 or 0
    for _,item in ipairs(jobs) do
        item.age=item.age+elapsed
        if item.age>=item.every then
            item.age=0
            local ok,message=pcall(item.job)
            if not ok and geterrorhandler then geterrorhandler()(message) end
        end
    end
end)
