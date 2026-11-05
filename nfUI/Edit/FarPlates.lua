-- Bars for the enemies the game's own nameplates do not reach. The game's anchors know every enemy on the map,
-- but not its health or level: a far bar shows the health last seen on a real plate, or a full bar.
local E,C=nfUIEdit,nfUIConfig
local QUERY={kinds={"enemy","elite","guardian","boss","finalBoss"}}
local KIND_STYLES={enemy="normal",elite="elite",guardian="guardian",boss="boss",finalBoss="boss"}
local MAX_BARS=48
local CATALOG_EVERY,FRAME_EVERY=0.5,0.03
local CLAIM=60*60
local layer=CreateFrame("Frame","nfUIFarPlates",WorldFrame)
layer:SetAllPoints(WorldFrame)
local pool,live,requests,lastShare,shareCount={},{},{},{},0
local catalogAt,frameAt=0,0
local shown=0

local function Bar(index)
    local bar=pool[index]
    if bar then return bar end
    bar=CreateFrame("StatusBar",nil,layer)
    bar:SetMinMaxValues(0,1);bar:SetStatusBarTexture(E.FLAT);bar:SetAlpha(0.6)
    bar.back=bar:CreateTexture(nil,"BORDER");bar.back:SetTexture(E.FLAT);bar.back:SetAllPoints(bar)
    bar.back:SetVertexColor(E.COLORS.base[1],E.COLORS.base[2],E.COLORS.base[3],0.95)
    bar.name=bar:CreateFontString(nil,"OVERLAY")
    bar.name:SetFont(NFUI_PLATE_FONT,10,"OUTLINE");bar.name:SetPoint("BOTTOMLEFT",bar,"TOPLEFT",0,2)
    bar:Hide()
    pool[index]=bar
    return bar
end
local function HideFrom(first)
    for index=first,shown do if pool[index] then pool[index]:Hide() end end
    shown=first-1
end
local function ReadCatalog()
    local catalog=AZS_GetWorldAnchors(QUERY,nil,256)
    local rows=type(catalog)=="table" and catalog.entries
    live={};requests={}
    -- Guardians and bosses are the enemies whose health the game does tell.
    for _,unit in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
        if type(unit)=="table" and unit.id and tonumber(unit.hp) and tonumber(unit.hpm) and tonumber(unit.hpm)>0 then
            lastShare[unit.id]=tonumber(unit.hp)/tonumber(unit.hpm)
        end
    end
    if type(rows)~="table" then return end
    for _,row in ipairs(rows) do
        if row.anchorId and row.state=="alive" and table.getn(requests)<256 then
            table.insert(requests,{anchorId=row.anchorId,attachment="overhead"})
            live[row.anchorId]=row
        end
    end
end
-- The spots real plates stand on; a far bar there would only double them. A plate's health is remembered.
local function ClaimSpots(spots)
    local claimed={}
    for _,overlay in ipairs(nfUIPlatesRegistry or {}) do
        if overlay.plate and overlay.plate:IsVisible() then
            local x,y=overlay.plate:GetCenter()
            if x and y then
                local best,bestGap=nil,CLAIM
                for _,spot in ipairs(spots) do
                    local dx,dy=spot.x-x,spot.y-y
                    local gap=dx*dx+dy*dy
                    if gap<bestGap and not claimed[spot.anchorId] then best,bestGap=spot,gap end
                end
                if best then
                    claimed[best.anchorId]=true
                    local row=live[best.anchorId]
                    if row and row.unitId and overlay.shownShare then
                        if not lastShare[row.unitId] then shareCount=shareCount+1 end
                        lastShare[row.unitId]=overlay.shownShare
                    end
                end
            end
        end
    end
    return claimed
end
-- Where an enemy of this name stands on screen, in UIParent units; several of them take turns.
local turn=0
function E.EnemySpot(name)
    local spots=E.enemySpots
    if not name or type(spots)~="table" then return nil end
    local total=table.getn(spots)
    if total==0 then return nil end
    turn=turn+1
    for offset=0,total-1 do
        local spot=spots[math.mod(turn+offset,total)+1]
        local row=spot and live[spot.anchorId]
        if row and row.name==name then
            local factor=WorldFrame:GetEffectiveScale()/UIParent:GetEffectiveScale()
            return spot.x*factor,spot.y*factor
        end
    end
    return nil
end
local function ByDistance(a,b) return a.playerDistance<b.playerDistance end
local function Draw()
    local now=GetTime()
    if now-frameAt<FRAME_EVERY then return end
    frameAt=now
    local settings=C.Settings and C.Settings().nameplates
    if type(AZS_ProjectWorldAnchors)~="function" then return end
    if now-catalogAt>=CATALOG_EVERY then catalogAt=now;ReadCatalog() end
    if table.getn(requests)==0 then HideFrom(1);return end
    local projected=AZS_ProjectWorldAnchors(requests)
    local spots=type(projected)=="table" and projected.entries
    if type(spots)~="table" then HideFrom(1);return end
    local radius=E.Size("farRadius",100)
    local visible={}
    for _,spot in ipairs(spots) do
        if spot.state=="onScreen" and spot.x and spot.y and type(spot.playerDistance)=="number" and spot.playerDistance<=radius and live[spot.anchorId] then
            table.insert(visible,spot)
        end
    end
    E.enemySpots=visible
    if not E.On("farPlates") or not settings or not settings.enabled then HideFrom(1);return end
    local claimed=ClaimSpots(visible)
    local free={}
    for _,spot in ipairs(visible) do if not claimed[spot.anchorId] then table.insert(free,spot) end end
    if table.getn(free)>MAX_BARS then table.sort(free,ByDistance) end
    local count=math.min(MAX_BARS,table.getn(free))
    local styles=C.PlateKinds
    for index=1,count do
        local spot=free[index]
        local row=live[spot.anchorId]
        local bar=Bar(index)
        local style=styles and styles[KIND_STYLES[row.kind] or "normal"] or {width=100,height=9,color=E.COLORS.enemy}
        local width,height=settings.width*style.width/100*settings.scale,settings.height*style.height/9*settings.scale
        if bar.barWidth~=width or bar.barHeight~=height then
            bar.barWidth=width;bar.barHeight=height;bar:SetWidth(width);bar:SetHeight(height)
        end
        if bar.color~=style.color then bar.color=style.color;bar:SetStatusBarColor(style.color[1],style.color[2],style.color[3]) end
        if bar.label~=row.name then bar.label=row.name;bar.name:SetText(row.name or "") end
        bar:SetValue(lastShare[row.unitId] or 1)
        bar:ClearAllPoints();bar:SetPoint("CENTER",WorldFrame,"BOTTOMLEFT",spot.x,spot.y)
        bar:Show()
    end
    HideFrom(count+1);shown=math.max(shown,count)
    if shareCount>2000 then lastShare={};shareCount=0 end
end
if AZS_RegisterCombatTextFrameHandler then AZS_RegisterCombatTextFrameHandler(Draw) end
