-- The edit's default profile, applied once, and the layout's fit to the screen.
local PROFILE_VERSION=8
local SPOTS={
    actionBar={674,255},xp={674,282},player={674,292},playerAuras={674,318},
    target={1189,292},targetDebuffs={1189,318},
    minimap={1840,655},dpsMeter={1836,27},tooltip={1790,190},
    chat1={21,21},chatInput={8,177},
    -- Hidden unless switched on; without a spot here it would keep a position made for another screen.
    runPanel={2028,196},
}
local function Merge(target,values)
    if type(target)~="table" then return end
    for key,value in pairs(values) do target[key]=value end
end
local function ApplyProfile(db)
    db.positions=db.positions or {}
    for key,spot in pairs(SPOTS) do
        db.positions[key]=db.positions[key] or {}
        db.positions[key].x=spot[1];db.positions[key].y=spot[2]
    end
    db.damageMode="quick";db.damageText=true;db.dpsCollapsed=true;db.compass=false
    Merge(db.nameplates,{amount="All",collision=false,stacking=false,rankColors=true,color={0.80,0.10,0.10},
        healthText="Numerical",healthFont=10,nameFont=12,width=70,height=7,abbreviate=false})
    Merge(db.chat,{backdropOpacity=0.75,editScale=1,width=330,height=130,font=14})
    Merge(db.minimap,{size=200,feather=0})
    Merge(db.dpsDisplay,{scale=0.68,backdropOpacity=0.7})
    Merge(db.action,{size=26,gap=2,cooldownFont=11,hotkeyFont=8,countFont=10})
    Merge(db.xp,{width=194,height=5})
    local frame={width=169,height=18,powerHeight=3,portrait=24,valueFont=11,nameFont=11}
    Merge(db.player,frame);Merge(db.target,frame)
    if db.player then db.player.healthArea="Left" end
    Merge(db.playerStyle,{healthText="Numerical"});Merge(db.targetStyle,{healthText="Numerical"})
    Merge(db.playerStyle,{showPortrait=true});Merge(db.targetStyle,{showPortrait=true})
    if db.sizeMatches then db.sizeMatches.player=nil end
    Merge(db.auras,{size=22,gap=2,timeFont=10,stackFont=10})
    Merge(db.debuffs,{size=22,gap=2,stackFont=10})
    SetCVar("hudClock","1");SetCVar("hudBosses","1");SetCVar("hudTally","1")
    SetCVar("nameplateLayout","overlap")
end
-- Profiles from earlier builds already hold these choices, with whatever was changed since.
local function Migrate(db)
    local found=false
    for key in pairs(db) do
        if type(key)=="string" and string.sub(key,1,10)=="localTweak" then found=true;db[key]=nil end
    end
    db.probeLoadout=nil;db.probePool=nil;db.probeMetres=nil;db.probeDistance=nil;db.layoutFitted=nil
    return found
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" then return end
    local migrated=Migrate(nfUIDB)
    local version=nfUIDB.editProfile or 0
    if version>=PROFILE_VERSION then return end
    nfUIDB.editProfile=PROFILE_VERSION
    if version==0 and not migrated then ApplyProfile(nfUIDB);return end
    -- Version 2: taller enemy plates in a clearer font.
    if version<2 then Merge(nfUIDB.nameplates,{height=7,healthFont=10,nameFont=12}) end
    -- Each later step runs once, so that what the player changed afterwards stays.
    local k=(type(nfUIDB.layoutBasis)=="table" and nfUIDB.layoutBasis.height or 853.33)/853.33
    local positions=type(nfUIDB.positions)=="table" and nfUIDB.positions or {}
    -- Version 4: every health bar shows the current health, without the percentage.
    if version<4 then
        Merge(nfUIDB.playerStyle,{healthText="Numerical"});Merge(nfUIDB.targetStyle,{healthText="Numerical"})
        Merge(nfUIDB.nameplates,{healthText="Numerical"})
    end
    -- Version 5: the chat with even margins.
    if version<5 then
        Merge(nfUIDB.chat,{backdropOpacity=0.75})
        positions.chat1={x=SPOTS.chat1[1]*k,y=SPOTS.chat1[2]*k}
    end
    -- Version 6: the two pools move over the chat.
    if version<6 then positions.blockPool=nil;positions.blockJewelPool=nil end
    -- Version 8: blocks stay chained unless dragged; opening the movers had pinned them all.
    if version<8 then
        for _,key in ipairs({"blockBosses","blockLairs","blockTaken","blockHistory","blockPool","blockJewelPool"}) do positions[key]=nil end
    end
    -- Version 7: the input above the chat's tabs, and the pools above that.
    if version<7 then
        positions.chatInput={x=SPOTS.chatInput[1]*k,y=SPOTS.chatInput[2]*k}
        positions.blockPool=nil;positions.blockJewelPool=nil
    end
end)

local function ScreenUnits()
    -- GetWidth and GetHeight leave out the UI scale; positions are laid out in the scaled units.
    local uiScale=UIParent:GetEffectiveScale()
    return UIParent:GetWidth()/uiScale,UIParent:GetHeight()/uiScale
end
-- The layout was made on a 3440x1440 screen, which is this many UI units.
local BASIS_WIDTH,BASIS_HEIGHT=2038.5,853.33
-- The edit's settings as a first start would make them, fitted to this screen. "Reset" returns to these.
function nfUIEdit.FreshProfile()
    local fresh=nfUIBuildStarterProfile(UIParent:GetWidth(),UIParent:GetHeight())
    for name,defaults in pairs(nfUIConfig.defaults) do
        if type(fresh[name])~="table" then fresh[name]={} end
        for key,value in pairs(defaults) do
            if fresh[name][key]==nil then fresh[name][key]=value end
        end
    end
    ApplyProfile(fresh)
    fresh.editProfile=PROFILE_VERSION
    local width,height=ScreenUnits()
    nfUILayoutRescale(fresh,BASIS_WIDTH,BASIS_HEIGHT,width,height)
    fresh.layoutBasis={width=width,height=height}
    return fresh
end
-- Fits the layout to any screen. Positions are kept relative to where they belong: the two central
-- blocks to the screen's centre, everything else to its nearest corner. Sizes follow the screen's height.
-- Runs again only when the screen's shape or UI scale changes, so moving things by hand is kept.
local LAYOUT_CENTERED={actionBar=true,xp=true,player=true,playerAuras=true,target=true,targetDebuffs=true}
function nfUILayoutRescale(db,oldWidth,oldHeight,width,height)
    local k=height/oldHeight
    for key,spot in pairs(db.positions or {}) do
        if type(spot)=="table" and type(spot.x)=="number" and type(spot.y)=="number" and not spot.centered then
            if LAYOUT_CENTERED[key] then
                spot.x=width/2+(spot.x-oldWidth/2)*k
                spot.y=spot.y*k
            else
                if spot.x>oldWidth/2 then spot.x=width+(spot.x-oldWidth)*k else spot.x=spot.x*k end
                if spot.y>oldHeight/2 then spot.y=height+(spot.y-oldHeight)*k else spot.y=spot.y*k end
            end
        end
    end
    if db.layout and db.layout.scale then db.layout.scale=db.layout.scale*k end
    if db.minimap and db.minimap.scale then db.minimap.scale=db.minimap.scale*k end
    if db.dpsDisplay and db.dpsDisplay.scale then db.dpsDisplay.scale=db.dpsDisplay.scale*k end
    if db.micro and db.micro.scale then db.micro.scale=db.micro.scale*k end
    if db.nameplates and db.nameplates.scale then db.nameplates.scale=db.nameplates.scale*k end
    if db.chat then
        if db.chat.width then db.chat.width=db.chat.width*k end
        if db.chat.height then db.chat.height=db.chat.height*k end
        if db.chat.font then db.chat.font=math.max(10,math.floor(db.chat.font*k+0.5)) end
    end
end
-- The screen's real size can arrive only after the world loads, so it is checked once a second.
nfUIEdit.Every(1,function()
    if type(nfUIDB)~="table" or not nfUIConfig or not nfUIConfig.player then return end
    local uiScale=UIParent:GetEffectiveScale()
    if not uiScale or uiScale<=0 then return end
    local width,height=ScreenUnits()
    if not width or not height or width<=0 or height<=0 then return end
    local basis=nfUIDB.layoutBasis or {width=BASIS_WIDTH,height=BASIS_HEIGHT}
    if math.abs(basis.width-width)>2 or math.abs(basis.height-height)>2 then
        nfUILayoutRescale(nfUIDB,basis.width,basis.height,width,height)
        nfUIDB.layoutBasis={width=width,height=height}
        if nfUIConfig.Apply then pcall(nfUIConfig.Apply) end
    else
        nfUIDB.layoutBasis=basis
    end
end)
