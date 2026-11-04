-- Initialize only nfUI-owned saved variables. Existing profiles are retained.
if type(nfUIDB)~="table" or not next(nfUIDB) then
    nfUIDB=nfUIBuildStarterProfile(UIParent:GetWidth(),UIParent:GetHeight())
end
if type(nfUIPlatesDB)~="table" then nfUIPlatesDB={} end
if nfUIDB.damageText==nil then nfUIDB.damageText=true end
if nfUIDB.damageMode==nil then nfUIDB.damageMode=nfUIDB.damageText and "sct" or "off" end
if nfUIDB.sctStyle~="Methodical" and nfUIDB.sctStyle~="Biggest Hit" then nfUIDB.sctStyle="Explosive" end
if nfUIDB.compass==nil then nfUIDB.compass=true end

-- Apply the user's verified zoom limit after saved client settings load.
local camera=CreateFrame("Frame","nfUICameraStartup",UIParent)
camera:RegisterEvent("VARIABLES_LOADED")
camera:RegisterEvent("PLAYER_LOGIN")
camera:RegisterEvent("ADDON_LOADED")
camera:SetScript("OnEvent",function()
    if event=="ADDON_LOADED" and arg1~="nfUI" then return end
    if GetCVar("cameraDistanceMaxFactor")~="5" then SetCVar("cameraDistanceMaxFactor","5") end
end)

-- Local tweak, applied once per profile (2026-11-04), after saved variables load.
local function LocalTweak()
    if nfUIDB.localTweak20261104 then return end
    nfUIDB.localTweak20261104=true
    nfUIDB.damageMode="quick";nfUIDB.damageText=true
    nfUIDB.dpsCollapsed=true
    local plates=nfUIDB.nameplates
    if plates then
        plates.nameFont=10;plates.healthFont=10
        plates.amount="All";plates.collision=false;plates.stacking=false
        plates.rankColors=false;plates.color={0.80,0.10,0.10}
    end
    local chat=nfUIDB.chat
    if chat then chat.backdropOpacity=0.5;chat.editScale=1;chat.width=420;chat.height=140 end
    local map=nfUIDB.minimap
    if map then
        local spot=nfUIDB.positions and nfUIDB.positions.minimap
        if spot and spot.x then spot.x=spot.x+((map.size or 155)-200)*(map.scale or 1) end
        map.size=200;map.feather=0
    end
    SetCVar("hudClock","1");SetCVar("hudBosses","1");SetCVar("hudTally","1")
end
local tweak=CreateFrame("Frame")
tweak:RegisterEvent("ADDON_LOADED")
tweak:SetScript("OnEvent",function()
    if arg1=="nfUI" and type(nfUIDB)=="table" then LocalTweak() end
end)

-- Local tweak: party frames' health bars and names in class colours.
-- The stock bar recolours itself when health changes, so this runs every frame.
local PARTY_SHAMAN={r=0.00,g=0.44,b=0.87}
local PARTY_BARS={"HealthBar","ManaBar"}
local PARTY_BAR_WIDTH=140
local partyColors=CreateFrame("Frame","nfUIPartyClassColors")
local partyColorsAge=0
partyColors:SetScript("OnUpdate",function()
    partyColorsAge=partyColorsAge+(arg1 or 0)
    -- Pets and bar colours must be corrected often, but not on every frame.
    if partyColorsAge<0.1 or not UnitExists("party1") then return end
    partyColorsAge=0
    for index=1,4 do
        local unit="party"..index
        -- Allies' pets hidden, allies' bars at full length without the stock art around them.
        local pet=getglobal("PartyMemberFrame"..index.."PetFrame")
        if pet and pet:IsShown() then pet:Hide() end
        local art=getglobal("PartyMemberFrame"..index.."Texture")
        if art and art:IsShown() then art:Hide() end
        for _,suffix in ipairs(PARTY_BARS) do
            local long=getglobal("PartyMemberFrame"..index..suffix)
            if long and long:GetWidth()~=PARTY_BAR_WIDTH then long:SetWidth(PARTY_BAR_WIDTH) end
        end
        if UnitExists(unit) then
            local _,class=UnitClass(unit)
            local color=class=="SHAMAN" and PARTY_SHAMAN or (class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
            if color then
                local bar=getglobal("PartyMemberFrame"..index.."HealthBar")
                if bar then bar:SetStatusBarColor(color.r,color.g,color.b) end
                local name=getglobal("PartyMemberFrame"..index.."Name")
                if name then name:SetTextColor(color.r,color.g,color.b) end
            end
        end
    end
end)

-- Local tweak: layout from the planner (2026-11-05), applied once per profile.
local function LocalTweak2()
    if nfUIDB.localTweak20261105 then return end
    nfUIDB.localTweak20261105=true
    nfUIDB.compass=false
    local positions={minimap={1632,532},xp={716,304},dpsMeter={1652,24},player={716,284},actionBar={716,252},
        targetDebuffs={1060,228},target={1060,252},chatInput={8,4},playerAuras={716,224},chat1={8,32}}
    nfUIDB.positions=nfUIDB.positions or {}
    for key,spot in pairs(positions) do
        nfUIDB.positions[key]=nfUIDB.positions[key] or {}
        nfUIDB.positions[key].x=spot[1];nfUIDB.positions[key].y=spot[2]
    end
    if nfUIDB.dpsDisplay then nfUIDB.dpsDisplay.scale=0.68 end
    local plates=nfUIDB.nameplates
    if plates then plates.healthText="CurrentHP+%";plates.healthFont=9;plates.nameFont=9;plates.width=73;plates.height=6 end
    local chat=nfUIDB.chat
    if chat then chat.width=330;chat.font=14;chat.height=130 end
end
local tweak2=CreateFrame("Frame")
tweak2:RegisterEvent("ADDON_LOADED")
tweak2:SetScript("OnEvent",function()
    if arg1=="nfUI" and type(nfUIDB)=="table" then LocalTweak2() end
end)

-- Local tweak: enemy plates coloured by rank, once per profile.
local tweak3=CreateFrame("Frame")
tweak3:RegisterEvent("ADDON_LOADED")
tweak3:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105b then return end
    nfUIDB.localTweak20261105b=true
    if nfUIDB.nameplates then nfUIDB.nameplates.rankColors=true end
end)

-- Local tweak: bigger centred bars at the bottom, map in the corner, narrower enemy plates.
-- Registered last, so it wins over the earlier one-time tweaks until those flags are saved.
local tweak4=CreateFrame("Frame")
tweak4:RegisterEvent("ADDON_LOADED")
tweak4:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105c then return end
    nfUIDB.localTweak20261105c=true
    local spots={actionBar={773,8},player={773,50},xp={773,83},playerAuras={773,96},
        target={1110,8},targetDebuffs={1110,44},minimap={1636,570}}
    nfUIDB.positions=nfUIDB.positions or {}
    for key,spot in pairs(spots) do
        nfUIDB.positions[key]=nfUIDB.positions[key] or {}
        nfUIDB.positions[key].x=spot[1];nfUIDB.positions[key].y=spot[2]
    end
    local db=nfUIDB
    if db.action then db.action.size=44;db.action.gap=2;db.action.cooldownFont=18;db.action.hotkeyFont=10;db.action.countFont=14 end
    if db.player then db.player.width=320;db.player.height=34;db.player.powerHeight=8;db.player.valueFont=16 end
    if db.xp then db.xp.width=320;db.xp.height=10 end
    if db.auras then db.auras.size=28 end
    if db.nameplates then db.nameplates.width=58 end
end)

-- Local tweak: the planner's layout on the real canvas (2038.5 x 853.3), with bars stacked at their new size.
local tweak5=CreateFrame("Frame")
tweak5:RegisterEvent("ADDON_LOADED")
tweak5:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105d then return end
    nfUIDB.localTweak20261105d=true
    local spots={actionBar={796,280},player={796,322},xp={796,355},playerAuras={796,249},
        target={1178,280},targetDebuffs={1178,253},minimap={1840,655},
        chat1={9,36},chatInput={9,4},dpsMeter={1836,27}}
    nfUIDB.positions=nfUIDB.positions or {}
    for key,spot in pairs(spots) do
        nfUIDB.positions[key]=nfUIDB.positions[key] or {}
        nfUIDB.positions[key].x=spot[1];nfUIDB.positions[key].y=spot[2]
    end
end)

-- Local tweak: see-through bars and buttons, and a target-of-target frame beside the target.
local HUD_ALPHA=0.9
local hudButtons={1,2,3,4,5,6,12}
local totFrame
local function BuildTargetOfTarget(anchor)
    local flat="Interface\\Buttons\\WHITE8X8"
    local frame=CreateFrame("Button","nfUITargetOfTarget",UIParent)
    frame:SetWidth(194);frame:SetHeight(13);frame:SetScale(anchor:GetScale())
    frame:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-7)
    frame:EnableMouse(false)
    frame:SetBackdrop({bgFile=flat});frame:SetBackdropColor(0.04,0.05,0.07,0.7)
    frame.bar=CreateFrame("StatusBar",nil,frame)
    frame.bar:SetStatusBarTexture(flat);frame.bar:SetMinMaxValues(0,1)
    frame.bar:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-1);frame.bar:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1)
    frame.label=frame.bar:CreateFontString(nil,"OVERLAY")
    frame.label:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
    frame.label:SetPoint("LEFT",frame.bar,"LEFT",3,0);frame.label:SetPoint("RIGHT",frame.bar,"RIGHT",-3,0)
    frame:Hide()
    return frame
end
local mapEdge
local function Polish(object,backed)
    if not object or object.nfuiPolished or not nfUIWidgets then return end
    object.nfuiPolished=true
    nfUIWidgets.Fill(object,{0,0,0,0.18},"BACKGROUND",-3)
    nfUIWidgets.Fill(object,{0,0,0,0.28},"BACKGROUND",-2)
    nfUIWidgets.Fill(object,{0,0,0,0.9},"BACKGROUND",-1)
    if backed then nfUIWidgets.Fill(object,{0.04,0.05,0.07,0.7},"BACKGROUND",0) end
end
-- Local tweak: a thin edge outside a button; the icon lies in the bottom layer, so nothing goes over it.
local function Ring(object)
    if not object or object.nfuiRing then return end
    object.nfuiRing=true
    local function Line(a,b,x1,y1,x2,y2)
        local line=object:CreateTexture(nil,"OVERLAY")
        line:SetTexture("Interface\\Buttons\\WHITE8X8");line:SetVertexColor(0,0,0,0.9)
        line:SetPoint(a,object,a,x1,y1);line:SetPoint(b,object,b,x2,y2)
        return line
    end
    Line("TOPLEFT","TOPRIGHT",-1,1,1,1):SetHeight(1)
    Line("BOTTOMLEFT","BOTTOMRIGHT",-1,-1,1,-1):SetHeight(1)
    Line("TOPLEFT","BOTTOMLEFT",-1,1,-1,-1):SetWidth(1)
    Line("TOPRIGHT","BOTTOMRIGHT",1,1,1,-1):SetWidth(1)
end
-- Local tweak: a quiet background that groups each side's information into one block.
local playerBlock,targetBlock
local function Block(x,y,width,height)
    local frame=CreateFrame("Frame",nil,UIParent)
    frame:SetFrameStrata("BACKGROUND");frame:SetWidth(width);frame:SetHeight(height)
    frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});frame:SetBackdropColor(0.04,0.05,0.07,0.35)
    Polish(frame)
    return frame
end
-- Local tweak: each skill's rank under its icon, read from the same tooltip the game shows.
local rankScan,rankAge=nil,1
local function ReadRank(action)
    if not rankScan then
        local ok,tip=pcall(CreateFrame,"GameTooltip","nfUIRankScan",UIParent,"GameTooltipTemplate")
        if not ok or not tip then return nil end
        rankScan=tip;tip:SetAlpha(0)
    end
    rankScan:SetOwner(UIParent,"ANCHOR_NONE");rankScan:ClearLines();rankScan:SetAction(action)
    local right=getglobal("nfUIRankScanTextRight1")
    local text=right and right:GetText()
    local left=getglobal("nfUIRankScanTextLeft1")
    local spell=left and left:GetText()
    rankScan:Hide()
    local number
    if text then _,_,number=string.find(text,"(%d+)") end
    return number,spell
end
function UpdateRanks()
    rankAge=rankAge+0.1;if rankAge<2 then return end;rankAge=0
    if not ActionButton_GetPagedID then return end
    -- Local tweak: each skill's own DPS under its rank, refreshed every 2 seconds.
    local dpsByName={}
    if AZS_GetMeter then
        local okMeter,lines=pcall(AZS_GetMeter)
        if okMeter and type(lines)=="table" then
            for _,line in ipairs(lines) do
                if type(line)=="table" and line.name and type(line.dps)=="number" then dpsByName[line.name]=line.dps end
            end
        end
    end
    for _,prefix in ipairs({"ActionButton","BonusActionButton"}) do
        for _,id in ipairs(hudButtons) do
            local button=getglobal(prefix..id)
            if button and button:IsVisible() then
                if not button.nfuiRank then
                    button.nfuiRank=button:CreateFontString(nil,"OVERLAY")
                    button.nfuiRank:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
                    button.nfuiRank:SetPoint("TOP",button,"BOTTOM",0,-2);button.nfuiRank:SetTextColor(1,0.82,0.3)
                end
                local ok,action=pcall(ActionButton_GetPagedID,button)
                local number,spell
                if ok and action and HasAction(action) then number,spell=ReadRank(action) end
                button.nfuiRank:SetText(number and ("Р"..number) or "")
                if not button.nfuiDps then
                    button.nfuiDps=button:CreateFontString(nil,"OVERLAY")
                    button.nfuiDps:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
                    button.nfuiDps:SetPoint("TOP",button.nfuiRank,"BOTTOM",0,-1);button.nfuiDps:SetTextColor(0.75,0.9,1)
                end
                local rate=spell and dpsByName[spell]
                if not rate then button.nfuiDps:SetText("")
                elseif rate>=10000 then button.nfuiDps:SetText(string.format("%.0fk",rate/1000))
                elseif rate>=1000 then button.nfuiDps:SetText(string.format("%.1fk",rate/1000))
                else button.nfuiDps:SetText(string.format("%.0f",rate)) end
            end
        end
    end
end
-- Local tweak: distance to the target in the frame's top right corner. Enemies sharing a name: the nearest.
-- Local tweak: a chest beside the hero's frame once the next cache is affordable.
local chestIcon
function UpdateChestIcon(frame)
    if not chestIcon then
        chestIcon=CreateFrame("Frame","nfUIChestReady",UIParent);chestIcon:SetWidth(24);chestIcon:SetHeight(24)
        chestIcon:SetScale(frame:GetScale());chestIcon:SetPoint("LEFT",frame,"RIGHT",6,0)
        local image=chestIcon:CreateTexture(nil,"ARTWORK");image:SetAllPoints(chestIcon)
        image:SetTexture("Interface\\Icons\\INV_Crate_01");image:SetTexCoord(0.07,0.93,0.07,0.93)
        Ring(chestIcon);chestIcon:Hide()
    end
    local run=AZS_RUN
    local ready=type(run)=="table" and type(run.gold)=="number" and type(run.chest)=="number" and run.chest<=run.gold
    if ready and AZS_GetPhase and AZS_GetPhase() then chestIcon:Show() else chestIcon:Hide() end
end
local aggroEdge
local distanceLabel,distanceAge=nil,1
-- Local tweak: metres over every enemy's plate, and a red edge on those close enough to hit the hero.
-- The game names no enemy's target, so nearness stands in for aggro. Plates and anchors are matched by
-- screen position alone: names can differ between the client's language and the game's data.
local NEAR_YARDS=6
local distanceKinds={kinds={"enemy","elite","guardian","boss","finalBoss"}}
local function ReadEnemyDistances()
    local catalog=AZS_GetWorldAnchors(distanceKinds,nil,256)
    local rows=type(catalog)=="table" and catalog.entries
    if type(rows)~="table" then return nil end
    local live={}
    local requests={}
    for _,row in ipairs(rows) do
        if row.anchorId and row.state~="dead" and table.getn(requests)<256 then
            table.insert(requests,{anchorId=row.anchorId,attachment="overhead"})
            live[row.anchorId]=row
        end
    end
    if table.getn(requests)==0 then return {} end
    local projected=AZS_ProjectWorldAnchors(requests)
    local out={}
    for _,spot in ipairs(type(projected)=="table" and projected.entries or {}) do
        local row=live[spot.anchorId]
        if row and type(spot.playerDistance)=="number" then
            table.insert(out,{name=row.name,unitId=row.unitId,x=spot.x,y=spot.y,onScreen=spot.state=="onScreen",yards=spot.playerDistance})
        end
    end
    return out
end
local function MetreText(yards) return string.format("%.0f",yards).."\208\188" end
function UpdateTargetDistance(frame)
    distanceAge=distanceAge+0.1;if distanceAge<0.5 then return end;distanceAge=0
    if not distanceLabel then
        distanceLabel=frame.health:CreateFontString(nil,"OVERLAY")
        distanceLabel:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
        distanceLabel:SetPoint("BOTTOMRIGHT",frame.health,"TOPRIGHT",0,1);distanceLabel:SetTextColor(0.85,0.85,0.85)
    end
    local ok,spots=pcall(ReadEnemyDistances)
    if not ok or type(spots)~="table" then spots={} end
    local targetId=UnitExists("target") and AZS_TARGET and AZS_TARGET.id
    local targetText=""
    for _,spot in ipairs(spots) do
        if targetId and spot.unitId==targetId then targetText=MetreText(spot.yards) end
    end
    distanceLabel:SetText(targetText)
    local stats={ok=ok,spots=table.getn(spots),shown=0,matched=0,gap=0,w=UIParent:GetWidth(),h=UIParent:GetHeight(),eff=UIParent:GetEffectiveScale()}
    nfUIMetreStats=stats
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.bar then
            if not overlay.distanceText then
                -- A small box right of the bar, the number centred in it.
                local box=CreateFrame("Frame",nil,overlay);box:SetWidth(22);box:SetHeight(11)
                box:SetFrameLevel(overlay:GetFrameLevel()+6);box:SetPoint("LEFT",overlay.bar,"RIGHT",3,0)
                local fill=box:CreateTexture(nil,"BACKGROUND");fill:SetTexture("Interface\\Buttons\\WHITE8X8")
                fill:SetVertexColor(0.12,0.13,0.16,0.8);fill:SetAllPoints(box)
                overlay.distanceBox=box
                overlay.distanceText=box:CreateFontString(nil,"OVERLAY")
                overlay.distanceText:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
                overlay.distanceText:SetPoint("CENTER",box,"CENTER",0,0);overlay.distanceText:SetTextColor(0.95,0.95,0.95)
                box:Hide()
            end
            local best,bestGap=nil,60*60
            if overlay.plate and overlay.plate:IsShown() then
                local x,y=overlay.plate:GetCenter()
                if x and y then
                    for _,spot in ipairs(spots) do
                        if spot.onScreen and spot.x and spot.y then
                            local dx,dy=spot.x-x,spot.y-y
                            local gap=dx*dx+dy*dy
                            if gap<bestGap then best,bestGap=spot,gap end
                        end
                    end
                end
            end
            if overlay.plate and overlay.plate:IsShown() then
                stats.shown=stats.shown+1
                if best then stats.matched=stats.matched+1;stats.gap=math.max(stats.gap,bestGap) end
                if not stats.sample then
                    local x,y=overlay.plate:GetCenter()
                    stats.sample={x=x,y=y,name=overlay.stock.name:GetText(),spot=spots[1] and {x=spots[1].x,y=spots[1].y,name=spots[1].name,on=spots[1].onScreen}}
                end
            end
            if best then
                overlay.distanceText:SetText(MetreText(best.yards));overlay.distanceBox:Show()
                overlay.nearHero=best.yards<=NEAR_YARDS
            else
                overlay.distanceBox:Hide();overlay.nearHero=nil
            end
        end
    end
end
local hudAge=0
local hudDriver=CreateFrame("Frame","nfUIHudTweaks")
hudDriver:SetScript("OnUpdate",function()
    hudAge=hudAge+(arg1 or 0);if hudAge<0.1 then return end;hudAge=0
    local C=nfUIConfig
    if not C or not C.player or not C.target then return end
    C.player:SetAlpha(1);C.target:SetAlpha(1)
    -- Local tweak: the health panels no longer catch the mouse.
    C.player:EnableMouse(false);C.target:EnableMouse(false)
    LOCK_ACTIONBAR="1"
    local xp=getglobal("MainMenuExpBar");if xp then xp:SetAlpha(HUD_ALPHA) end
    for _,id in ipairs(hudButtons) do
        local button=getglobal("ActionButton"..id);if button then button:SetAlpha(HUD_ALPHA) end
        button=getglobal("BonusActionButton"..id);if button then button:SetAlpha(HUD_ALPHA) end
    end
    Polish(getglobal("MainMenuExpBar"))
    for _,id in ipairs(hudButtons) do Ring(getglobal("ActionButton"..id));Ring(getglobal("BonusActionButton"..id)) end
    UpdateRanks()
    UpdateTargetDistance(C.target)
    UpdateChestIcon(C.player)
    -- Local tweak: the target frame gets the same red edge while the target is on the hero.
    if not aggroEdge and nfUIWidgets then aggroEdge=nfUIWidgets.Fill(C.target.health,{1,0.08,0.08,1},"BACKGROUND",-2) end
    if aggroEdge then
        if UnitExists("targettarget") and UnitIsUnit("targettarget","player") and UnitCanAttack("player","target") then aggroEdge:Show() else aggroEdge:Hide() end
    end
    if Minimap and not mapEdge then
        mapEdge=CreateFrame("Frame",nil,UIParent)
        mapEdge:SetFrameStrata(Minimap:GetFrameStrata());mapEdge:SetFrameLevel(math.max(0,Minimap:GetFrameLevel()-1))
        mapEdge:SetAllPoints(Minimap);Polish(mapEdge)
    end
    for index=1,4 do
        Polish(getglobal("PartyMemberFrame"..index.."HealthBar"),true)
        Polish(getglobal("PartyMemberFrame"..index.."ManaBar"),true)
    end
    if not totFrame then totFrame=BuildTargetOfTarget(C.target) end
    if UnitExists("targettarget") then
        local maximum=UnitHealthMax("targettarget") or 0
        totFrame.bar:SetValue(maximum>0 and (UnitHealth("targettarget") or 0)/maximum or 0)
        local _,class=UnitClass("targettarget")
        local color=UnitIsPlayer("targettarget") and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then totFrame.bar:SetStatusBarColor(color.r,color.g,color.b)
        elseif UnitCanAttack("player","targettarget") then totFrame.bar:SetStatusBarColor(0.8,0.1,0.1)
        else totFrame.bar:SetStatusBarColor(0.2,0.7,0.25) end
        totFrame.label:SetText(UnitName("targettarget") or "")
        totFrame:SetAlpha(HUD_ALPHA);totFrame:Show()
    else
        totFrame:Hide()
    end
end)

-- Local tweak: compact hero and target frames, mirrored around the screen's centre (1019).
local tweak6=CreateFrame("Frame")
tweak6:RegisterEvent("ADDON_LOADED")
tweak6:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105e then return end
    nfUIDB.localTweak20261105e=true
    local db=nfUIDB
    local spots={player={797,322},target={1079,322},targetDebuffs={1079,366}}
    db.positions=db.positions or {}
    for key,spot in pairs(spots) do
        db.positions[key]=db.positions[key] or {}
        db.positions[key].x=spot[1];db.positions[key].y=spot[2]
    end
    if db.sizeMatches then db.sizeMatches.player=nil end
    if db.player then db.player.width=180;db.player.height=24;db.player.powerHeight=4;db.player.valueFont=12 end
    if db.target then db.target.width=180;db.target.height=24;db.target.powerHeight=4;db.target.valueFont=12;db.target.nameFont=11 end
    if db.targetStyle then db.targetStyle.showPortrait=false end
    if db.auras then db.auras.size=30;db.auras.timeFont=12;db.auras.stackFont=12 end
    if db.debuffs then db.debuffs.size=28;db.debuffs.stackFont=12 end
end)

-- Local tweak: frames 25% smaller with portraits, further from the centre, still mirrored.
local tweak7=CreateFrame("Frame")
tweak7:RegisterEvent("ADDON_LOADED")
tweak7:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105f then return end
    nfUIDB.localTweak20261105f=true
    local db=nfUIDB
    local spots={player={765,322},target={1129,322},targetDebuffs={1129,346}}
    db.positions=db.positions or {}
    for key,spot in pairs(spots) do
        db.positions[key]=db.positions[key] or {}
        db.positions[key].x=spot[1];db.positions[key].y=spot[2]
    end
    for _,unit in ipairs({"player","target"}) do
        local data=db[unit]
        if data then data.width=135;data.height=18;data.powerHeight=3;data.portrait=24;data.valueFont=11;data.nameFont=11 end
        local style=db[unit.."Style"]
        if style then style.showPortrait=true end
    end
    if db.player then db.player.healthArea="Left" end
end)

-- Local tweak: tooltips above both DPS panels, at the right edge.
local tweak8=CreateFrame("Frame")
tweak8:RegisterEvent("ADDON_LOADED")
tweak8:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105g then return end
    nfUIDB.localTweak20261105g=true
    nfUIDB.positions=nfUIDB.positions or {}
    nfUIDB.positions.tooltip=nfUIDB.positions.tooltip or {}
    nfUIDB.positions.tooltip.x=1790;nfUIDB.positions.tooltip.y=190
end)

-- Local tweak: one aligned row around the screen's centre (1019) in one style.
local tweak9=CreateFrame("Frame")
tweak9:RegisterEvent("ADDON_LOADED")
tweak9:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105h then return end
    nfUIDB.localTweak20261105h=true
    local db=nfUIDB
    local spots={actionBar={910,280},xp={910,312},playerAuras={910,250},
        player={726,286},target={1168,286},targetDebuffs={1168,308}}
    db.positions=db.positions or {}
    for key,spot in pairs(spots) do
        db.positions[key]=db.positions[key] or {}
        db.positions[key].x=spot[1];db.positions[key].y=spot[2]
    end
    if db.action then db.action.size=32;db.action.gap=3;db.action.cooldownFont=13;db.action.hotkeyFont=8;db.action.countFont=11 end
    if db.xp then db.xp.width=242;db.xp.height=6 end
    if db.auras then db.auras.size=24;db.auras.gap=3;db.auras.timeFont=10;db.auras.stackFont=10 end
    if db.debuffs then db.debuffs.size=24;db.debuffs.gap=3;db.debuffs.stackFont=10 end
    if db.chat then db.chat.backdropOpacity=0.7 end
    if db.dpsDisplay then db.dpsDisplay.backdropOpacity=0.7 end
end)

-- Local tweak: two blocks further from the centre: hero, experience and skills on the left, target on the right.
local tweak10=CreateFrame("Frame")
tweak10:RegisterEvent("ADDON_LOADED")
tweak10:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105i then return end
    nfUIDB.localTweak20261105i=true
    local db=nfUIDB
    local spots={actionBar={674,255},xp={674,282},player={674,292},playerAuras={674,318},
        target={1189,292},targetDebuffs={1189,318}}
    db.positions=db.positions or {}
    for key,spot in pairs(spots) do
        db.positions[key]=db.positions[key] or {}
        db.positions[key].x=spot[1];db.positions[key].y=spot[2]
    end
    if db.action then db.action.size=26;db.action.gap=2;db.action.cooldownFont=11;db.action.hotkeyFont=8;db.action.countFont=10 end
    if db.xp then db.xp.width=194;db.xp.height=5 end
    if db.player then db.player.width=169 end
    if db.target then db.target.width=169 end
    if db.auras then db.auras.size=22;db.auras.gap=2 end
    if db.debuffs then db.debuffs.size=22;db.debuffs.gap=2 end
end)

-- Local tweak: plates stay right over their enemy instead of the game shifting them apart.
local tweak11=CreateFrame("Frame")
tweak11:RegisterEvent("ADDON_LOADED")
tweak11:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105j then return end
    nfUIDB.localTweak20261105j=true
    SetCVar("nameplateLayout","overlap")
end)

-- Local tweak: taller, narrower enemy plates.
local tweak12=CreateFrame("Frame")
tweak12:RegisterEvent("ADDON_LOADED")
tweak12:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105k then return end
    nfUIDB.localTweak20261105k=true
    if nfUIDB.nameplates then nfUIDB.nameplates.width=50;nfUIDB.nameplates.height=9 end
end)

-- Local tweak: narrower enemy plates.
local tweak13=CreateFrame("Frame")
tweak13:RegisterEvent("ADDON_LOADED")
tweak13:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105l then return end
    nfUIDB.localTweak20261105l=true
    if nfUIDB.nameplates then nfUIDB.nameplates.width=42 end
end)

-- Local tweak: full, readable names on plates.
local tweak14=CreateFrame("Frame")
tweak14:RegisterEvent("ADDON_LOADED")
tweak14:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105m then return end
    nfUIDB.localTweak20261105m=true
    if nfUIDB.nameplates then nfUIDB.nameplates.abbreviate=false;nfUIDB.nameplates.nameFont=11 end
end)

-- Local tweak: wider, lower enemy plates.
local tweak15=CreateFrame("Frame")
tweak15:RegisterEvent("ADDON_LOADED")
tweak15:SetScript("OnEvent",function()
    if arg1~="nfUI" or type(nfUIDB)~="table" or nfUIDB.localTweak20261105n then return end
    nfUIDB.localTweak20261105n=true
    if nfUIDB.nameplates then nfUIDB.nameplates.width=70;nfUIDB.nameplates.height=5 end
end)

-- Local tweak: selecting an ally shows their skills (with ranks) and items under the target frame.
-- What each jewel adds, from the game's own Russian texts; the exact number depends on the rank.
local ALLY_EFFECTS={
    ["jewel.accuria"]="+…% к урону",
    ["jewel.archimtiros"]="+…% к снижению урона…, +…% к макс. здоровью",
    ["jewel.blackhand"]="+…% к критическому урону",
    ["jewel.blooddrinker"]="…% всего нанесённого урона исцеляет вас",
    ["jewel.carrot"]="+…% к скорости передвижения",
    ["jewel.chosen"]="+…% удачи",
    ["jewel.dark_iron"]="+…% к макс. здоровью",
    ["jewel.devoured"]="+… здоровья в секунду",
    ["jewel.dragonslayer"]="+…% к шансу критического удара",
    ["jewel.eldre_thalas"]="+…% золота",
    ["jewel.hoj"]="…% вероятность, что заклинание применится дважды",
    ["jewel.insignia"]="+…% опыта",
    ["jewel.onyxia_blood"]="Каждое убийство восполняет … ед. здоровья",
    ["jewel.quick_strike"]="-…% к времени восстановления",
    ["jewel.remote"]="+…% к радиусу подбора",
    ["jewel.seal_damned"]="Ваши заклинания периодического урона срабатывают на …% быстрее",
    ["jewel.soulstone"]="+… возвращение к жизни с половиной здоровья (не более 2)",
    ["jewel.spell_power"]="+…% к области действия",
    ["jewel.star_of_mystaria"]="+…% к макс. здоровью, +…% к снижению урона…",
    ["jewel.war_horn"]="Ваши положительные эффекты сильнее на …%",
}
local ALLY_SIZE,ALLY_GAP,ALLY_PER_ROW=19,2,9
local ownerByName={}
local function AllyOwnerId(name,context)
    if ownerByName[name] then return ownerByName[name] end
    local snapshot=AZS_GetMeterSnapshot({apiVersion=1,runId=context.runId,metric="damage",scope="party",period="run",groupBy="owner",windowSeconds=0})
    if type(snapshot)~="table" or type(snapshot.actors)~="table" then return nil end
    for id,actor in pairs(snapshot.actors) do
        if type(actor)=="table" and actor.kind=="hero" and actor.name then ownerByName[actor.name]=id end
    end
    return ownerByName[name]
end
local function LoadoutIcon(holder,index)
    local icon=holder.icons[index]
    if icon then return icon end
    icon=CreateFrame("Frame",nil,holder.frame);icon:SetWidth(ALLY_SIZE);icon:SetHeight(ALLY_SIZE)
    icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints(icon);icon.texture:SetTexCoord(0.08,0.92,0.08,0.92)
    Ring(icon)
    icon.rank=icon:CreateFontString(nil,"OVERLAY");icon.rank:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
    icon.rank:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",1,-1);icon.rank:SetTextColor(1,0.82,0.3)
    icon:EnableMouse(true)
    icon:SetScript("OnEnter",function()
        if not this.label then return end
        GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(this.label,1,1,1)
        if this.rankValue then GameTooltip:AddLine("\208\160\208\176\208\189\208\179 "..this.rankValue,1,0.82,0) end
        if this.effect then GameTooltip:AddLine(this.effect,0.75,0.9,1,true) end
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
    holder.icons[index]=icon
    return icon
end
local JEWEL_CELLS={
    {"amulet",1,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck","Пусто: амулет"},
    {"ring",2,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger","Пусто: кольцо"},
    {"trinket",2,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket","Пусто: талисман"},
}
local function FillLoadout(holder,runId,owner,withSkills)
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=runId,ownerId=owner})
    if type(loadout)~="table" or type(loadout.sources)~="table" then return false end
    local count,x,y=0,0,0
    local function Place(entry)
        local source=entry.sourceKey and loadout.sources[entry.sourceKey]
        local path=source and type(source.icon)=="table" and source.icon.path
        if not path then return end
        if x>=ALLY_PER_ROW then x=0;y=y+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",x*(ALLY_SIZE+ALLY_GAP),-y*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture(path);icon.label=source.name;icon.rankValue=source.rank
        icon.effect=source.localizationKey and ALLY_EFFECTS[source.localizationKey] or nil
        icon.rank:SetText(source.rank or "");icon:SetAlpha(1);icon:Show()
        x=x+1
    end
    if withSkills then
        for _,entry in ipairs(loadout.abilities or {}) do
            if entry.learned and entry.selected and not entry.passive then Place(entry) end
        end
        if x>0 then x=0;y=y+1 end
    end
    -- Only what matters in a run: gear with its own effects, and the run's jewelry. Starter gear is left out.
    for _,entry in ipairs(loadout.equipment or {}) do
        if entry.occupied and type(entry.effectSourceKeys)=="table" and table.getn(entry.effectSourceKeys)>0 then Place(entry) end
    end
    -- Local tweak: jewelry in fixed cells, with empty cells for what is not picked yet.
    local function PlaceEmpty(texture,label)
        if x>=ALLY_PER_ROW then x=0;y=y+1 end
        count=count+1
        local icon=LoadoutIcon(holder,count)
        icon:ClearAllPoints();icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",x*(ALLY_SIZE+ALLY_GAP),-y*(ALLY_SIZE+ALLY_GAP))
        icon.texture:SetTexture(texture);icon.label=label;icon.rankValue=nil;icon.effect=nil
        icon.rank:SetText("");icon:SetAlpha(0.45);icon:Show()
        x=x+1
    end
    local byCategory={}
    for _,entry in ipairs(loadout.runJewelry or {}) do
        local kind=entry.category or "other"
        byCategory[kind]=byCategory[kind] or {}
        table.insert(byCategory[kind],entry)
    end
    for _,cell in ipairs(JEWEL_CELLS) do
        local list=byCategory[cell[1]] or {}
        for index=1,math.max(cell[2],table.getn(list)) do
            if list[index] then Place(list[index]) else PlaceEmpty(cell[3],cell[4]) end
        end
    end
    for _,entry in ipairs(byCategory.other or {}) do Place(entry) end
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    return count>0
end
local function ShowAlly(holder)
    local context=AZS_GetMeterContext()
    if type(context)~="table" or not context.runId then return false end
    local owner=AllyOwnerId(UnitName("target"),context)
    if not owner then return false end
    return FillLoadout(holder,context.runId,owner,true)
end
local function ShowOwn(holder)
    local context=AZS_GetMeterContext()
    if type(context)~="table" or not context.runId or not context.localOwnerId then return false end
    return FillLoadout(holder,context.runId,context.localOwnerId,false)
end
-- Each class's skill pool: { key, Russian name, icon }, from the game's own tables.
local SKILL_POOL={
    DRUID={{"wrath","Гнев","Ability_ThunderClap"},{"moonfire","Лунный огонь","Spell_Nature_StarFall"},{"starfire","Звездный огонь","Spell_Arcane_StarFire"},{"hurricane","Гроза","Spell_Nature_Cyclone"},{"insect_swarm","Рой насекомых","Spell_Nature_InsectSwarm"},{"entangling_roots","Гнев деревьев","Spell_Nature_StrangleVines"},{"rejuvenation","Омоложение","Spell_Nature_Rejuvenation"},{"regrowth","Восстановление","Spell_Nature_ResistNature"},{"thorns","Шипы","Spell_Nature_Thorns"},{"swipe","Размах","INV_Misc_MonsterClaw_03"},{"faerie_fire","Волшебный огонь","Spell_Nature_FaerieFire"},{"shred","Полоснуть","Spell_Shadow_VampiricAura"}},
    HUNTER={{"auto_shot","Автоматическая стрельба","Ability_Whirlwind"},{"arcane_shot","Чародейский выстрел","Ability_ImpalingBolt"},{"multi_shot","Залп","Ability_UpgradeMoonGlaive"},{"serpent_sting","Укус змеи","Ability_Hunter_Quickshot"},{"volley","Град стрел","Ability_Marksmanship"},{"kill_command","Команда «Взять!»","Ability_Hunter_BeastCall"},{"concussive_shot","Контузящий выстрел","Spell_Frost_Stun"},{"aimed_shot","Прицельный выстрел","INV_Spear_07"},{"immolation_trap","Обжигающая ловушка","Spell_Fire_FlameShock"},{"frost_trap","Ледяная ловушка","Spell_Frost_FreezingBreath"},{"hunters_mark","Метка охотника","Ability_Hunter_SniperShot"}},
    MAGE={{"fireball","Огненный шар","Spell_Fire_FlameBolt"},{"frostbolt","Ледяная стрела","Spell_Frost_FrostBolt02"},{"arcane_missiles","Чародейские стрелы","Spell_Nature_StarFall"},{"frost_nova","Кольцо льда","Spell_Frost_FrostNova"},{"arcane_explosion","Чародейский взрыв","Spell_Nature_WispSplode"},{"blizzard","Снежная буря","Spell_Frost_IceStorm"},{"flamestrike","Огненный столб","Spell_Fire_SelfDestruct"},{"fire_blast","Огненный взрыв","Spell_Fire_Fireball"},{"cone_of_cold","Конус холода","Spell_Frost_Glacier"},{"blast_wave","Взрывная волна","Spell_Holy_Excorcism_02"},{"pyroblast","Огненная глыба","Spell_Fire_Fireball02"},{"ice_barrier","Ледяная преграда","Spell_Ice_Lament"},{"polymorph","Превращение","Spell_Nature_Polymorph"}},
    PALADIN={{"consecration","Освящение","Spell_Holy_InnerFire"},{"exorcism","Экзорцизм","Spell_Holy_Excorcism_02"},{"hammer_of_wrath","Молот гнева","Ability_ThunderClap"},{"holy_shock","Шок небес","Spell_Holy_SearingLight"},{"holy_wrath","Гнев небес","Spell_Holy_Excorcism"},{"judgement","Правосудие","Spell_Holy_RighteousFury"},{"hammer_of_justice","Молот правосудия","Spell_Holy_SealOfMight"},{"holy_light","Свет небес","Spell_Holy_HolyBolt"},{"divine_shield","Божественный щит","Spell_Holy_DivineIntervention"},{"holy_shield","Щит небес","Spell_Holy_BlessingOfProtection"},{"redemption","Искупление","Spell_Holy_Resurrection"}},
    PRIEST={{"smite","Кара","Spell_Holy_HolySmite"},{"sw_pain","Слово Тьмы: Боль","Spell_Shadow_ShadowWordPain"},{"mind_blast","Взрыв разума","Spell_Shadow_UnholyFrenzy"},{"holy_nova","Кольцо света","Spell_Holy_HolyNova"},{"pw_shield","Слово силы: Щит","Spell_Holy_PowerWordShield"},{"renew","Обновление","Spell_Holy_Renew"},{"holy_fire","Священный огонь","Spell_Holy_SearingLight"},{"mind_flay","Пытка разума","Spell_Shadow_SiphonMana"},{"psychic_scream","Ментальный крик","Spell_Shadow_PsychicScream"},{"devouring_plague","Всепожирающая чума","Spell_Shadow_BlackPlague"}},
    ROGUE={{"sinister_strike","Коварный удар","Spell_Shadow_RitualOfSacrifice"},{"eviscerate","Потрошение","Ability_Rogue_Eviscerate"},{"blade_flurry","Шквал клинков","Ability_Warrior_PunishingBlow"},{"rupture","Рваная рана","Ability_Rogue_Rupture"},{"kidney_shot","Удар по почкам","Ability_Rogue_KidneyShot"},{"gouge","Парализующий удар","Ability_Gouge"},{"ghostly_strike","Призрачный удар","Spell_Shadow_Curse"},{"adrenaline_rush","Выброс адреналина","Spell_Shadow_ShadowWordDominate"},{"backstab","Удар в спину","Ability_BackStab"},{"slice_and_dice","Мясорубка","Ability_Rogue_SliceDice"},{"seal_fate","Печать судьбы","Spell_Shadow_ChillTouch"}},
    SHAMAN={{"lightning_bolt","Молния","Spell_Nature_Lightning"},{"chain_lightning","Цепная молния","Spell_Nature_ChainLightning"},{"earth_shock","Земной шок","Spell_Nature_EarthShock"},{"flame_shock","Огненный шок","Spell_Fire_FlameShock"},{"frost_shock","Ледяной шок","Spell_Frost_FrostShock"},{"lightning_shield","Щит молний","Spell_Nature_LightningShield"},{"magma_totem","Тотем магмы","Spell_Fire_SelfDestruct"},{"searing_totem","Опаляющий тотем","Spell_Fire_SearingTotem"},{"fire_nova","Кольцо огня","Spell_Fire_SealOfFire"},{"healing_wave","Волна исцеления","Spell_Nature_MagicImmunity"},{"stormstrike","Удар бури","Ability_Shaman_Stormstrike"}},
    WARLOCK={{"shadow_bolt","Стрела Тьмы","Spell_Shadow_ShadowBolt"},{"corruption","Порча","Spell_Shadow_AbominationExplosion"},{"immolate","Жертвенный огонь","Spell_Fire_Immolation"},{"curse_of_agony","Проклятие агонии","Spell_Shadow_CurseOfSargeras"},{"rain_of_fire","Огненный ливень","Spell_Shadow_RainOfFire"},{"hellfire","Адское пламя","Spell_Fire_Incinerate"},{"death_coil","Лик смерти","Spell_Shadow_DeathCoil"},{"searing_pain","Жгучая боль","Spell_Fire_SoulBurn"},{"drain_life","Похищение жизни","Spell_Shadow_LifeDrain02"},{"fear","Страх","Spell_Shadow_Possession"},{"soul_fire","Ожог души","Spell_Fire_Fireball02"},{"demonic_empowerment","Демоническое усиление","Spell_Nature_RemoveCurse"}},
    WARRIOR={{"cleave","Рассекающий удар","Ability_Warrior_Cleave"},{"whirlwind","Вихрь","Ability_Whirlwind"},{"thunder_clap","Удар грома","Spell_Nature_ThunderClap"},{"mortal_strike","Смертельный удар","Ability_Warrior_SavageBlow"},{"execute","Казнь","INV_Sword_48"},{"demo_shout","Деморализующий крик","Ability_Warrior_WarCry"},{"battle_shout","Боевой крик","Ability_Warrior_BattleShout"},{"bloodthirst","Жажда крови","Spell_Nature_BloodLust"},{"rend","Кровопускание","Ability_Gouge"},{"shield_slam","Мощный удар щитом","INV_Shield_05"},{"bloodrage","Кровавая ярость","Ability_Racial_BloodRage"}},
}
local POOL_PICKS=6
-- Local tweak: the skills still in the pool, shown until six are picked. Banished cards are not known yet.
local function ShowPool(holder)
    local context=AZS_GetMeterContext()
    if type(context)~="table" or not context.runId then return false end
    local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
    if type(loadout)~="table" then return false end
    -- The run's hero decides the class: the character's own class may be a different one.
    local hero=type(loadout.actors)=="table" and loadout.actors[loadout.ownerId or context.localOwnerId]
    local class=type(hero)=="table" and type(hero.classKey)=="string" and string.upper(hero.classKey)
    local pool=class and SKILL_POOL[class]
    if not pool then return false end
    local picked,total={},0
    for _,entry in ipairs(loadout.abilities or {}) do
        if entry.selected and type(entry.sourceKey)=="string" then
            local _,_,key=string.find(entry.sourceKey,"^ability:([%w_]+):")
            if key then picked[key]=true end
        end
    end
    for _,skill in ipairs(pool) do if picked[skill[1]] then total=total+1 end end
    -- Stays up once the six are picked, fainter. The game does not tell addons which cards were banished.
    local faint=total>=POOL_PICKS
    local count=0
    for _,skill in ipairs(pool) do
        if not picked[skill[1]] then
            count=count+1
            local icon=LoadoutIcon(holder,count)
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT",holder.frame,"TOPLEFT",math.mod(count-1,ALLY_PER_ROW)*(ALLY_SIZE+ALLY_GAP),-math.floor((count-1)/ALLY_PER_ROW)*(ALLY_SIZE+ALLY_GAP))
            icon.texture:SetTexture("Interface\\Icons\\"..skill[3]);icon.label=skill[2];icon.rankValue=nil;icon.effect=nil
            icon.rank:SetText("");icon:SetAlpha(faint and 0.35 or 0.8);icon:Show()
        end
    end
    for index=count+1,table.getn(holder.icons) do holder.icons[index]:Hide() end
    return count>0
end
local function NewHolder(name,scale,point,anchor,relative,x,y)
    local frame=CreateFrame("Frame",name,UIParent)
    frame:SetScale(scale);frame:SetWidth(194);frame:SetHeight(1);frame:SetPoint(point,anchor,relative,x,y);frame:Hide()
    return {frame=frame,icons={}}
end
local allyHolder,ownHolder,poolHolder
local allyAge=0
local ownWait=5
local allyDriver=CreateFrame("Frame","nfUIAllyLoadout")
allyDriver:RegisterEvent("PLAYER_TARGET_CHANGED")
allyDriver:SetScript("OnEvent",function() allyAge=ownWait;ownerByName={} end)
allyDriver:SetScript("OnUpdate",function()
    allyAge=allyAge+(arg1 or 0);if allyAge<ownWait then return end;allyAge=0
    -- These calls ask the game for a lot, and a refused one sends a request to the server, so they
    -- wait for a run in progress and back off while the game is not ready.
    local phase=AZS_GetPhase and AZS_GetPhase()
    if phase~="playing" and phase~="choosing" and phase~="paused" then ownWait=3;return end
    local C=nfUIConfig
    if not totFrame or not C or not C.row then return end
    if not allyHolder then
        allyHolder=NewHolder("nfUIAllyPanel",totFrame:GetScale(),"TOPLEFT",totFrame,"BOTTOMLEFT",0,-4)
        -- Under the skills, below their rank and DPS lines.
        ownHolder=NewHolder("nfUIOwnPanel",C.row:GetScale(),"TOPLEFT",C.row,"BOTTOMLEFT",0,-27)
        poolHolder=NewHolder("nfUIPoolPanel",C.row:GetScale(),"TOPLEFT",C.row,"BOTTOMLEFT",0,-50)
    end
    local isAlly=UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target","player") and not UnitCanAttack("player","target")
    local ok,shown=false,false
    if isAlly then ok,shown=pcall(ShowAlly,allyHolder) end
    if ok and shown then allyHolder.frame:Show() else allyHolder.frame:Hide() end
    ok,shown=pcall(ShowOwn,ownHolder)
    if ok and shown then ownHolder.frame:Show();ownWait=4 else ownHolder.frame:Hide();ownWait=10 end
    ok,shown=pcall(ShowPool,poolHolder)
    if ok and shown then poolHolder.frame:Show() else poolHolder.frame:Hide() end
end)

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
local responsive=CreateFrame("Frame","nfUILayoutWatcher")
local responsiveAge=1
responsive:SetScript("OnUpdate",function()
    responsiveAge=responsiveAge+(arg1 or 0);if responsiveAge<1 then return end;responsiveAge=0
    if type(nfUIDB)~="table" or not nfUIConfig or not nfUIConfig.player then return end
    -- GetWidth and GetHeight leave out the UI scale; positions are laid out in the scaled units.
    local uiScale=UIParent:GetEffectiveScale()
    if not uiScale or uiScale<=0 then return end
    local width,height=UIParent:GetWidth()/uiScale,UIParent:GetHeight()/uiScale
    if not width or not height or width<=0 or height<=0 then return end
    -- The layout was made on a 3440x1440 screen, which is this many UI units.
    local basis=nfUIDB.layoutBasis or {width=2038.5,height=853.33}
    if math.abs(basis.width-width)>2 or math.abs(basis.height-height)>2 then
        nfUILayoutRescale(nfUIDB,basis.width,basis.height,width,height)
        nfUIDB.layoutBasis={width=width,height=height}
        if nfUIConfig.Apply then pcall(nfUIConfig.Apply) end
    else
        nfUIDB.layoutBasis=basis
    end
end)
