-- A permanent invisible anchor gives tooltip placement a visible unlock handle.
local C=nfUIConfig
local anchor=CreateFrame("Frame","nfUITooltipAnchor",UIParent)
anchor:SetWidth(240);anchor:SetHeight(90);anchor:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,90)
anchor:EnableMouse(false);anchor:SetAlpha(0)
C.tooltipAnchor=anchor
if C.RegisterMover then C.RegisterMover("tooltip","Tooltip",anchor,"tooltip") end
local function Place(tooltip)
    tooltip:ClearAllPoints();tooltip:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",0,0)
end
local originalDefault=GameTooltip_SetDefaultAnchor
GameTooltip_SetDefaultAnchor=function(tooltip,parent)
    if tooltip~=GameTooltip then if originalDefault then originalDefault(tooltip,parent) end;return end
    tooltip:SetOwner(parent,"ANCHOR_NONE");Place(tooltip);tooltip.default=1
end
-- The fixed spot is for the world's tooltips (units under the cursor) and for those that ask for no place of
-- their own. A tooltip that names a side of its owner, such as an icon in a pool, opens beside it: far from
-- the cursor it reads as belonging to something else.
local nearOwner,lastNear,currentOwner,ourTitle
-- The skill buttons sit under the hero: a big tooltip beside them would cover the fight, so theirs keeps the spot.
local function Beside(owner,kind)
    if not owner or owner==UIParent or owner==WorldFrame or not kind or kind=="ANCHOR_NONE" or kind=="ANCHOR_CURSOR" then return false end
    local name=owner.GetName and owner:GetName()
    if name and (string.find(name,"ActionButton",1,true) or string.find(name,"^MultiBar")) then return false end
    return true
end
if GameTooltip then
    if GameTooltip.SetClampedToScreen then GameTooltip:SetClampedToScreen(true) end
    local originalOwner=GameTooltip.SetOwner
    GameTooltip.SetOwner=function(self,owner,kind,x,y)
        currentOwner=owner
        if Beside(owner,kind) then nearOwner=owner;lastNear=owner;ourTitle=nil;originalOwner(self,owner,kind,x,y);return end
        nearOwner=nil;originalOwner(self,owner,"ANCHOR_NONE",x,y);Place(self)
    end
    local originalShow=GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow",function() if originalShow then originalShow() end;if not nearOwner then Place(GameTooltip) end end)
    local originalHide=GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide",function() nearOwner=nil;if originalHide then originalHide() end end)
    -- While the cursor rests on one of these icons, the unit behind it does not take the tooltip over:
    -- the icon's own tooltip comes back.
    local guard=CreateFrame("Frame")
    local guardAge=0
    guard:SetScript("OnUpdate",function()
        guardAge=guardAge+(arg1 or 0);if guardAge<0.05 then return end;guardAge=0
        local owner=lastNear
        if not owner or not GetMouseFocus then return end
        local focus=GetMouseFocus()
        if focus~=owner then lastNear=nil;return end
        -- This client's tooltip cannot name its owner, so the addon keeps track of it, and of the first line the
        -- icon wrote: a unit the game shows under the cursor changes one or the other.
        local first=GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
        local shown=GameTooltip:IsShown()
        if shown and currentOwner==owner and not ourTitle then ourTitle=first;return end
        local taken=not shown or currentOwner~=owner or (ourTitle and first~=ourTitle)
        if taken and owner:IsVisible() and owner:GetScript("OnEnter") then
            local previous=this;this=owner;pcall(owner:GetScript("OnEnter"));this=previous
            ourTitle=GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
        end
    end)
end
