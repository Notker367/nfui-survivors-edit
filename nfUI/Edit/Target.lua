-- Around the frames: target of target, red aggro edge, cache-ready chest, the map's edge, and metres on plates.
local E=nfUIEdit
-- The game names no enemy's target, so nearness stands in for aggro on the plates.
local NEAR_YARDS=6
local QUERY={kinds={"enemy","elite","guardian","boss","finalBoss"}}
local ToT,aggroEdge,chest,mapEdge,distanceLabel

local function BuildTargetOfTarget(anchor)
    local frame=E.blocks.tot
    frame:SetBackdrop({bgFile=E.FLAT});frame:SetBackdropColor(0.04,0.05,0.07,0.7)
    frame.bar=CreateFrame("StatusBar",nil,frame)
    frame.bar:SetStatusBarTexture(E.FLAT);frame.bar:SetMinMaxValues(0,1)
    frame.bar:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-1);frame.bar:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1)
    frame.label=frame.bar:CreateFontString(nil,"OVERLAY");frame.label:SetFont(E.FONT,9,"OUTLINE")
    frame.label:SetPoint("LEFT",frame.bar,"LEFT",3,0);frame.label:SetPoint("RIGHT",frame.bar,"RIGHT",-3,0)
    frame:SetAlpha(0.9);frame:Hide()
    return frame
end
local function UpdateTargetOfTarget(anchor)
    ToT=ToT or BuildTargetOfTarget(anchor)
    E.totFrame=ToT
    if not UnitExists("targettarget") or not E.On("targetOfTarget") then E.Conceal(ToT);return end
    local maximum=UnitHealthMax("targettarget") or 0
    ToT.bar:SetValue(maximum>0 and (UnitHealth("targettarget") or 0)/maximum or 0)
    local _,class=UnitClass("targettarget")
    local color=UnitIsPlayer("targettarget") and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then ToT.bar:SetStatusBarColor(color.r,color.g,color.b)
    elseif UnitCanAttack("player","targettarget") then ToT.bar:SetStatusBarColor(E.COLORS.red[1],E.COLORS.red[2],E.COLORS.red[3])
    else ToT.bar:SetStatusBarColor(E.COLORS.green[1],E.COLORS.green[2],E.COLORS.green[3]) end
    ToT.label:SetText(UnitName("targettarget") or "")
    ToT:Show()
end
local function UpdateAggroEdge(frame)
    aggroEdge=aggroEdge or E.Edge(frame.health,1,0.08,0.08,1)
    if E.On("redEdge") and UnitExists("targettarget") and UnitIsUnit("targettarget","player") and UnitCanAttack("player","target") then aggroEdge:Show() else aggroEdge:Hide() end
end
local function UpdateChest(frame)
    if not chest then
        chest=E.blocks.chest
        local image=chest:CreateTexture(nil,"ARTWORK");image:SetAllPoints(chest)
        image:SetTexture("Interface\\Icons\\INV_Crate_01");image:SetTexCoord(0.07,0.93,0.07,0.93)
        E.Ring(chest);chest:Hide()
    end
    local run=AZS_RUN
    local ready=type(run)=="table" and type(run.gold)=="number" and type(run.chest)=="number" and run.chest<=run.gold
    if ready and E.On("chestIcon") and AZS_GetPhase and AZS_GetPhase() then chest:Show() else E.Conceal(chest) end
end
local function UpdateMapEdge()
    if mapEdge or not Minimap then return end
    mapEdge=CreateFrame("Frame",nil,UIParent)
    mapEdge:SetFrameStrata(Minimap:GetFrameStrata());mapEdge:SetFrameLevel(math.max(0,Minimap:GetFrameLevel()-1))
    mapEdge:SetAllPoints(Minimap);E.Polish(mapEdge)
end
E.Every(0.1,function()
    local C=nfUIConfig
    if not C or not C.player or not C.target or not nfUIWidgets then return end
    -- The health panels do not catch the mouse: it stuck on them during camera turns.
    C.player:EnableMouse(false);C.target:EnableMouse(false)
    UpdateTargetOfTarget(C.target)
    UpdateAggroEdge(C.target)
    UpdateChest(C.player)
    UpdateMapEdge()
end)

-- Distances. Plates and the game's anchors are matched by screen position alone: names can differ
-- between the client's language and the game's data.
local function ReadDistances()
    local catalog=AZS_GetWorldAnchors(QUERY,nil,256)
    local rows=type(catalog)=="table" and catalog.entries
    if type(rows)~="table" then return {} end
    local live,requests={},{}
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
        if row and type(spot.playerDistance)=="number" and spot.state=="onScreen" and spot.x and spot.y then
            table.insert(out,{unitId=row.unitId,kind=row.kind,x=spot.x,y=spot.y,yards=spot.playerDistance})
        end
    end
    return out
end
local function Metres(yards) return string.format("%.0f",yards)..E.Text("\208\188","m") end
local function DistanceBox(overlay)
    local box=CreateFrame("Frame",nil,overlay);box:SetWidth(22);box:SetHeight(11)
    box:SetFrameLevel(overlay:GetFrameLevel()+6);box:SetPoint("LEFT",overlay.bar,"RIGHT",3,0)
    local fill=box:CreateTexture(nil,"BACKGROUND");fill:SetTexture(E.FLAT)
    fill:SetVertexColor(0.12,0.13,0.16,0.8);fill:SetAllPoints(box)
    overlay.distanceBox=box
    overlay.distanceText=box:CreateFontString(nil,"OVERLAY");overlay.distanceText:SetFont(E.FONT,9,"OUTLINE")
    overlay.distanceText:SetPoint("CENTER",box,"CENTER",0,0);overlay.distanceText:SetTextColor(0.95,0.95,0.95)
    box:Hide()
end
local function NearestSpot(overlay,spots)
    if not overlay.plate or not overlay.plate:IsShown() then return nil end
    local x,y=overlay.plate:GetCenter()
    if not x or not y then return nil end
    local best,bestGap,secondGap=nil,60*60,nil
    for _,spot in ipairs(spots) do
        local dx,dy=spot.x-x,spot.y-y
        local gap=dx*dx+dy*dy
        if gap<bestGap then secondGap=bestGap;best,bestGap=spot,gap
        elseif not secondGap or gap<secondGap then secondGap=gap end
    end
    -- Sure only when it is close and no other enemy stands nearly as close.
    local sure=best and bestGap<=25*25 and (not secondGap or secondGap>=math.max(bestGap*4,15*15))
    return best,sure
end
E.Every(0.5,function()
    local frame=nfUIConfig and nfUIConfig.target
    if not frame or type(AZS_GetWorldAnchors)~="function" or type(AZS_ProjectWorldAnchors)~="function" then return end
    if not distanceLabel then
        distanceLabel=frame.health:CreateFontString(nil,"OVERLAY");distanceLabel:SetFont(E.FONT,9,"OUTLINE")
        distanceLabel:SetPoint("BOTTOMRIGHT",frame.health,"TOPRIGHT",0,1);distanceLabel:SetTextColor(0.85,0.85,0.85)
    end
    local ok,spots=pcall(ReadDistances)
    if not ok or type(spots)~="table" then spots={} end
    local targetId=UnitExists("target") and AZS_TARGET and AZS_TARGET.id
    local text=""
    for _,spot in ipairs(spots) do
        if targetId and spot.unitId==targetId then text=Metres(spot.yards) end
    end
    local metres=E.On("metres")
    distanceLabel:SetText(metres and text or "")
    local metresFont=E.Size("metresFont",9)
    local shown,matched=0,0
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.bar then
            if not overlay.distanceText then DistanceBox(overlay) end
            local best,sure=NearestSpot(overlay,spots)
            if overlay.plate and overlay.plate:IsShown() then shown=shown+1 end
            if best then
                matched=matched+1
                overlay.distanceText:SetText(Metres(best.yards));if metres then overlay.distanceBox:Show() else overlay.distanceBox:Hide() end
                if overlay.metresFont~=metresFont then overlay.metresFont=metresFont;overlay.distanceText:SetFont(E.FONT,metresFont,"OUTLINE") end
                overlay.nearHero=best.yards<=NEAR_YARDS
                overlay.yards=best.yards
                if nfUIConfig.SetPlateKind then nfUIConfig.SetPlateKind(overlay,best.kind,sure) end
            else
                overlay.distanceBox:Hide();overlay.nearHero=nil;overlay.yards=nil
            end
        end
    end
    E.metres={shown=shown,matched=matched,spots=table.getn(spots)}
    -- Depth: the nearer of two bars lies on top, and one behind another is fainter still.
    local active={}
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.bar and overlay.plate and overlay.plate:IsVisible() then
            local yards=overlay.yards
            overlay.plateFade=E.DistanceFade(yards)
            if E.On("plateFade") and type(yards)=="number" then
                local level=20+math.max(0,60-math.floor(yards))
                if overlay.depthLevel~=level then
                    overlay.depthLevel=level
                    overlay:SetFrameLevel(level);overlay.bar:SetFrameLevel(level+1)
                    if overlay.distanceBox then overlay.distanceBox:SetFrameLevel(level+2) end
                end
                table.insert(active,overlay)
            end
        end
    end
    for _,back in ipairs(active) do
        local bx,by=back.bar:GetCenter()
        if bx then
            for _,front in ipairs(active) do
                if front~=back and front.yards<back.yards then
                    local fx,fy=front.bar:GetCenter()
                    if fx and math.abs(fx-bx)<(front.bar:GetWidth()+back.bar:GetWidth())/2 and math.abs(fy-by)<(front.bar:GetHeight()+back.bar:GetHeight())/2+10 then
                        back.plateFade=back.plateFade*0.7
                        break
                    end
                end
            end
        end
    end
end)
