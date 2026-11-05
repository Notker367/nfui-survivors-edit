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
E.FLAT="Interface\\Buttons\\WHITE8X8"
-- The interface's colours, after Catppuccin Mocha. Level colours stay the classic game's.
local function RGB(hex)
    return {tonumber(string.sub(hex,1,2),16)/255,tonumber(string.sub(hex,3,4),16)/255,tonumber(string.sub(hex,5,6),16)/255}
end
E.COLORS={enemy=RGB("ee6b83"),base=RGB("1e1e2e"),mantle=RGB("181825"),surface=RGB("313244"),text=RGB("cdd6f4"),red=RGB("f38ba8"),peach=RGB("fab387"),
    yellow=RGB("f9e2af"),green=RGB("a6e3a1"),sapphire=RGB("74c7ec"),blue=RGB("89b4fa"),mauve=RGB("cba6f7")}
-- The action buttons the game uses: 1 to 6 and the = key.
E.BUTTONS={1,2,3,4,5,6,12}

function E.Mode()
    return type(nfUIDB)=="table" and nfUIDB.uiMode or "default"
end
-- What the hidden mode takes away, and what only the detailed mode adds.
local INFO_PANELS={bossSchedule=true,lairPanel=true,takenPanel=true,historyPanel=true,skillPool=true,jewelPool=true,heroStats=true,dpsGraph=true}
local DETAILED_ONLY={heroStats=true,dpsGraph=true}
-- A switch from the settings' Switches tab. Anything not switched off counts as on.
function E.On(key)
    local mode=E.Mode()
    if mode=="hidden" and INFO_PANELS[key] then return false end
    if mode~="detailed" and DETAILED_ONLY[key] then return false end
    local switches=type(nfUIDB)=="table" and nfUIDB.edit
    return not switches or switches[key]~=false
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

function E.Short(value)
    if value>=1000000 then return string.format("%.1fm",value/1000000) end
    if value>=10000 then return string.format("%.0fk",value/1000) end
    if value>=1000 then return string.format("%.1fk",value/1000) end
    return string.format("%.0f",value)
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
    function edge.Show() for _,line in ipairs(edge) do line:Show() end end
    function edge.Hide() for _,line in ipairs(edge) do line:Hide() end end
    return edge
end

-- A small clickable title that folds a panel away and back. The choice is kept between sessions.
function E.IsCollapsed(key)
    local db=type(nfUIDB)=="table" and nfUIDB.collapsed
    return type(db)=="table" and db[key]==true
end
function E.Collapsible(frame,key,title,onChange,above)
    local header=CreateFrame("Button",nil,frame)
    header:SetHeight(14);header:SetWidth(math.min(frame:GetWidth(),150))
    if above then header:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",0,1) else header:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-3) end
    header.label=header:CreateFontString(nil,"OVERLAY");header.label:SetFont(E.FONT,11,"OUTLINE")
    header.label:SetPoint("LEFT",header,"LEFT",2,0);header.label:SetTextColor(E.COLORS.mauve[1],E.COLORS.mauve[2],E.COLORS.mauve[3])
    local function Show() header.label:SetText((E.IsCollapsed(key) and "[+] " or "[-] ")..title) end
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
