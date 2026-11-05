-- Banished cards. The game tells addons nothing about them, so the player marks them: a click on an icon in a
-- pool. The marks last for the run; the panel shows how many there are and which, crossed out.
local E=nfUIEdit
local panel,icons,caption=E.blocks.banished,{},nil
local SIZE,GAP=22,2
local function Marks()
    local run=type(AZS_ZONE)=="table" and AZS_ZONE.run or "none"
    local db=nfUIDB
    if type(db.banished)~="table" or db.banished.run~=run then db.banished={run=run,list={}} end
    return db.banished.list
end
function E.IsBanished(key)
    if type(nfUIDB)~="table" then return false end
    for _,mark in ipairs(Marks()) do if mark.key==key then return true end end
    return false
end
local function Cross(parent)
    local cross=parent:CreateFontString(nil,"OVERLAY")
    cross:SetFont(E.FONT,math.floor(parent:GetHeight()+4),"OUTLINE");cross:SetPoint("CENTER",parent,"CENTER",0,0)
    cross:SetTextColor(1,0.25,0.25);cross:SetText("X")
    return cross
end
E.BanishCross=Cross
function E.RefreshBanished()
    if not E.On("banishMarks") then E.Conceal(panel);return end
    local list=Marks()
    if not caption then
        caption=panel:CreateFontString(nil,"OVERLAY");caption:SetFont(E.FONT,11,"OUTLINE")
        caption:SetPoint("TOPRIGHT",panel,"TOPRIGHT",0,0);caption:SetTextColor(E.COLORS.text[1],E.COLORS.text[2],E.COLORS.text[3])
    end
    caption:SetText(E.Text("Изгнано: ","Banished: ")..table.getn(list))
    for index,mark in ipairs(list) do
        local icon=icons[index]
        if not icon then
            icon=CreateFrame("Frame",nil,panel);icon:SetWidth(SIZE);icon:SetHeight(SIZE)
            icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints(icon);icon.texture:SetTexCoord(0.08,0.92,0.08,0.92)
            E.Ring(icon);Cross(icon)
            icon:EnableMouse(true)
            icon:SetScript("OnEnter",function()
                GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(this.label or "",1,1,1)
                GameTooltip:AddLine(E.Text("Клик: снять отметку","Click: remove the mark"),0.7,0.7,0.7);GameTooltip:Show()
            end)
            icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
            icon:SetScript("OnMouseUp",function() E.ToggleBanish(this.key,this.textureName,this.label) end)
            icons[index]=icon
        end
        icon.key=mark.key;icon.label=mark.label;icon.textureName=mark.texture
        icon.texture:SetTexture(mark.texture);icon.texture:SetVertexColor(0.55,0.55,0.55)
        icon:ClearAllPoints();icon:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-((index-1)*(SIZE+GAP)),-15);icon:Show()
    end
    for index=table.getn(list)+1,table.getn(icons) do icons[index]:Hide() end
    if table.getn(list)>0 then panel:Show() else E.Conceal(panel) end
end
function E.ToggleBanish(key,texture,label)
    local list=Marks()
    local removed=false
    for index,mark in ipairs(list) do
        if mark.key==key then table.remove(list,index);removed=true;break end
    end
    if not removed then table.insert(list,{key=key,texture=texture,label=label}) end
    E.RefreshBanished()
    if E.RefreshPools then E.RefreshPools() end
end
E.Every(1,function() if type(nfUIDB)=="table" then E.RefreshBanished() end end)
