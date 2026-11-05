-- Allies' frames: class colours and full-length bars, without pets or the stock art.
local E=nfUIEdit
local SHAMAN={r=0.00,g=0.44,b=0.87}
local BAR_WIDTH=140
-- The experience bar in the palette's colour; the stock code sets it back when experience changes.
E.Every(0.5,function()
    if MainMenuExpBar then MainMenuExpBar:SetStatusBarColor(E.COLORS.mauve[1],E.COLORS.mauve[2],E.COLORS.mauve[3]) end
end)
-- The chat's tabs stay readable: the current one in the accent colour, the others plain.
E.Every(0.25,function()
    for index=1,7 do
        local tab,text=getglobal("ChatFrame"..index.."Tab"),getglobal("ChatFrame"..index.."TabText")
        if tab and text and tab:IsShown() then
            if E.On("chatTabs") then tab:SetAlpha(1) end
            local chosen=SELECTED_CHAT_FRAME==getglobal("ChatFrame"..index)
            local color=chosen and E.COLORS.mauve or E.COLORS.text
            text:SetTextColor(color[1],color[2],color[3])
            text:SetFont(E.On("chatNarrowFont") and NFUI_PLATE_FONT or E.FONT,12,"OUTLINE")
        end
    end
end)
-- The stock bar recolours itself when health changes, so this runs often.
E.Every(0.1,function()
    if not UnitExists("party1") then return end
    for index=1,4 do
        local prefix="PartyMemberFrame"..index
        local pet=getglobal(prefix.."PetFrame")
        if pet and pet:IsShown() then pet:Hide() end
        local art=getglobal(prefix.."Texture")
        if art and art:IsShown() then art:Hide() end
        local health,power=getglobal(prefix.."HealthBar"),getglobal(prefix.."ManaBar")
        for _,bar in ipairs({health,power}) do
            if bar:GetWidth()~=BAR_WIDTH then bar:SetWidth(BAR_WIDTH) end
            E.Polish(bar,true)
        end
        local unit="party"..index
        if UnitExists(unit) then
            local _,class=UnitClass(unit)
            local color=class=="SHAMAN" and SHAMAN or (class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
            if color then
                health:SetStatusBarColor(color.r,color.g,color.b)
                local name=getglobal(prefix.."Name")
                if name then name:SetTextColor(color.r,color.g,color.b) end
            end
            -- The level before the name; the stock frame writes the bare name back, so this repeats.
            local label=getglobal(prefix.."Name")
            if label then
                local wanted=E.LevelTag(UnitLevel(unit))..(UnitName(unit) or "")
                if label:GetText()~=wanted then label:SetText(wanted) end
            end
        end
    end
end)
