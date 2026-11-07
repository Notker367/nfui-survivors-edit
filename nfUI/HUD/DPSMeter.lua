-- Native run-wide meter data, rendered in nfUI's own flat collapsible panel.
nfUIModules:NewMod("DPSMeter",5,function()
    local C=nfUIConfig
    local FONT=NFUI_FONT
    local panel=CreateFrame("Frame","nfUIDPSMeter",UIParent)
    panel:SetWidth(112);panel:SetHeight(32);panel:SetFrameStrata("MEDIUM")
    panel:EnableMouse(true)
    panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});panel:SetBackdropColor(0.04,0.04,0.07,0.88)
    local header=CreateFrame("Button","nfUIDPSHeader",panel);header:SetHeight(32)
    header:EnableMouse(true);header:RegisterForClicks("LeftButtonUp")
    header:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",0,0);header:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",0,0)
    local title=header:CreateFontString(nil,"OVERLAY");title:SetFont(FONT,11,"OUTLINE")
    title:SetPoint("LEFT",header,"LEFT",8,0);title:SetText(nfUIEdit.L("DPS Meter"));title:SetTextColor(1,0.82,0)
    local toggle=CreateFrame("Button","nfUIDPSCollapse",header,"UIPanelButtonTemplate")
    toggle:EnableMouse(true);toggle:RegisterForClicks("LeftButtonUp")
    toggle:SetFrameLevel(header:GetFrameLevel()+5)
    toggle:SetWidth(22);toggle:SetHeight(22);toggle:SetPoint("RIGHT",header,"RIGHT",-5,0)
    local scroll=CreateFrame("ScrollFrame","nfUIDPSScroll",panel)
    scroll:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",8,36)
    local content=CreateFrame("Frame",nil,scroll);content:SetHeight(1);scroll:SetScrollChild(content)
    local summary=content:CreateFontString(nil,"OVERLAY");summary:SetFont(FONT,11,"OUTLINE")
    summary:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
    local rows,offset={},0
    local fittedWidth,fittedHeight=112,66
    local measure=panel:CreateFontString(nil,"OVERLAY");measure:SetFont(FONT,11,"OUTLINE");measure:Hide()
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function()
        local maximum=math.max(0,content:GetHeight()-scroll:GetHeight())
        offset=math.max(0,math.min(maximum,offset-(arg1 or 0)*30));scroll:SetVerticalScroll(offset)
    end)
    local function Settings()
        local db=C.Settings();db.positions=db.positions or {};db.elements=db.elements or {}
        if db.dpsCollapsed==nil then db.dpsCollapsed=true end
        if not db.positions.dpsMeter then db.positions.dpsMeter={x=UIParent:GetWidth()-136,y=90} end
        local old=db.elements.dpsMeter
        if old then for _,key in ipairs({"width","height","scale"}) do if old[key] then db.dpsDisplay[key]=old[key];old[key]=nil end end end
        return db,db.dpsDisplay,db.positions.dpsMeter
    end
    function C.CaptureDPSPosition()
        local _,_,p=Settings();return {x=p.x,y=p.y}
    end
    function C.AnchorDPSPosition(position)
        local _,_,p=Settings();p.x=position.x;p.y=position.y;C.LayoutDPSMeter()
    end
    local layoutKey
    function C.LayoutDPSMeter()
        local db,size,p=Settings()
        local scale=size.scale or 1;panel:SetScale(scale)
        local width=db.dpsCollapsed and 112 or (size.autoWidth and fittedWidth or size.width)
        local height=db.dpsCollapsed and 32 or (size.autoHeight and fittedHeight or size.height)
        width=math.min(width,UIParent:GetWidth()/scale);height=math.min(height,UIParent:GetHeight()/scale)
        panel:SetBackdropColor(0.04,0.04,0.07,size.backdropOpacity)
        if C.MatchedDimension then width=C.MatchedDimension("dpsMeter","width",width);height=C.MatchedDimension("dpsMeter","height",height) end
        local right=p.x+56*scale>UIParent:GetWidth()/2
        local key=width..":"..height..":"..scale..":"..p.x..":"..p.y..":"..tostring(right)
        if layoutKey~=key or panel:GetWidth()~=width or panel:GetHeight()~=height then
            layoutKey=key;panel:SetWidth(width);panel:SetHeight(height)
            panel:ClearAllPoints()
            panel:SetPoint(right and "BOTTOMRIGHT" or "BOTTOMLEFT",UIParent,"BOTTOMLEFT",(p.x+(right and 112*scale or 0))/scale,p.y/scale)
        end
        toggle:SetText(db.dpsCollapsed and (right and "<" or ">") or (right and ">" or "<"))
        scroll:SetWidth(math.max(1,width-16));scroll:SetHeight(math.max(1,height-44));content:SetWidth(math.max(1,width-16))
        if db.dpsCollapsed then scroll:Hide() else scroll:Show() end
    end
    function C.SetDPSCollapsed(collapsed)
        local db=Settings();db.dpsCollapsed=collapsed and true or false
        C.LayoutDPSMeter();C.RefreshDPSMeter()
    end
    local function Toggle()
        local db=Settings();C.SetDPSCollapsed(not db.dpsCollapsed)
    end
    toggle:SetScript("OnClick",Toggle)
    header:SetScript("OnClick",function()
        if MouseIsOver and MouseIsOver(toggle) then return end
        Toggle()
    end)
    local originalShown,owned
    local function Restore()
        if owned and AZS_SetHudShown then pcall(AZS_SetHudShown,"meter",originalShown) end
        owned=nil;panel:Hide()
    end
    local function Number(value) return type(value)=="number" and value>=0 and value-value==0 end
    local function Short(value) return nfUIEdit.Short(value) end
    -- Skill icons by name, for the hero's own meter and the party's.
    local topIcons,topIconsAge={},-1000
    local function RefreshTopIcons()
        if GetTime()-topIconsAge<15 then return end
        topIconsAge=GetTime()
        local context=AZS_GetMeterContext and AZS_GetMeterContext()
        if type(context)~="table" or not context.runId then return end
        local function Add(sources)
            if type(sources)~="table" then return end
            for _,source in pairs(sources) do
                if type(source)=="table" and source.name and type(source.icon)=="table" and source.icon.path then topIcons[source.name]=source.icon.path end
            end
        end
        local mine=AZS_GetMeterSnapshot({apiVersion=1,runId=context.runId,metric="damage",scope="self",period="run",groupBy="source",windowSeconds=0})
        if type(mine)=="table" then Add(mine.sources) end
        local own=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
        if type(own)=="table" then Add(own.sources) end
        if context.partyState and context.partyState~="solo" then
            local snapshot=AZS_GetMeterSnapshot({apiVersion=1,runId=context.runId,metric="damage",scope="party",period="run",groupBy="owner",windowSeconds=0})
            if type(snapshot)=="table" and type(snapshot.actors)=="table" then
                for id,actor in pairs(snapshot.actors) do
                    if type(actor)=="table" and actor.kind=="hero" then
                        local loadout=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId,ownerId=id})
                        if type(loadout)=="table" then Add(loadout.sources) end
                    end
                end
            end
        end
    end
    function C.RefreshDPSMeter()
        C.LayoutDPSMeter()
        local phase=AZS_GetPhase and AZS_GetPhase()
        local ok,lines,total,dps=false
        if phase and AZS_GetMeter then ok,lines,total,dps=pcall(AZS_GetMeter) end
        if not ok or type(lines)~="table" or not Number(total) or not Number(dps) then
            Restore();if C.editing then panel:Show() end;return
        end
        for _,line in ipairs(lines) do
            if type(line)~="table" or type(line.name)~="string" or not Number(line.dmg) or not Number(line.dps) or not Number(line.share) then Restore();return end
        end
        if not AZS_IsHudShown or not AZS_SetHudShown then Restore();return end
        if not owned then
            local success,shown=pcall(AZS_IsHudShown,"meter")
            if not success or shown==nil then Restore();return end
            originalShown=shown==true or shown==1 or shown=="1";owned=true
        end
        local success=pcall(AZS_SetHudShown,"meter",false)
        if not success then Restore();return end
        local checked,shown=pcall(AZS_IsHudShown,"meter")
        if not checked or (shown~=false and shown~=0 and shown~="0") then Restore();return end
        -- Switched off: the game's own meter stays hidden too.
        if not nfUIEdit.On("dpsMeter") and not C.editing then panel:Hide();return end
        panel:Show();summary:SetText(Short(dps).." DPS   |   "..Short(total)..nfUIEdit.L(" damage"))
        local function Measure(text)
            measure:SetText(text)
            return measure.GetStringWidth and measure:GetStringWidth() or string.len(text)*7
        end
        for _,line in ipairs(lines) do
            if not topIcons[line.name] then pcall(RefreshTopIcons);break end
        end
        fittedWidth=math.max(112,Measure(summary:GetText())+16)
        -- After a skill's DPS and share: how often it fired and its biggest hit, both over the last minute.
        local function RowValue(line)
            return Short(line.dps).." | "..string.format("%.0f%%",line.share*100)
        end
        -- They stand in two captioned columns of their own, to the right of the bars, as wide as their widest number.
        local showRates=nfUIEdit.On("skillRate")
        local stats={}
        local RATE_WIDTH=Measure(nfUIEdit.Text("уд/с","hit/s"))
        local BIG_WIDTH=Measure(nfUIEdit.Text("макс","max"))
        for index,line in ipairs(lines) do
            local count,biggest=nfUIEdit.HitStats(line.name)
            stats[index]={rate=nfUIEdit.Rate(count),big=biggest and Short(biggest) or "-"}
            RATE_WIDTH=math.max(RATE_WIDTH,Measure(stats[index].rate));BIG_WIDTH=math.max(BIG_WIDTH,Measure(stats[index].big))
        end
        RATE_WIDTH=RATE_WIDTH+4;BIG_WIDTH=BIG_WIDTH+4
        local columnsWidth=showRates and (RATE_WIDTH+BIG_WIDTH+6) or 0
        for _,line in ipairs(lines) do
            local value=RowValue(line)
            fittedWidth=math.max(fittedWidth,Measure(nfUIEdit.L(line.name))+Measure(value)+66+columnsWidth)
        end
        fittedHeight=66+table.getn(lines)*23
        C.LayoutDPSMeter()
        local width=math.max(1,panel:GetWidth()-16)
        for index,line in ipairs(lines) do
            local row=rows[index]
            if not row then
                row=CreateFrame("StatusBar",nil,content);row:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                row:SetMinMaxValues(0,1);row:SetHeight(20)
                row.icon=row:CreateTexture(nil,"OVERLAY");row.icon:SetWidth(16);row.icon:SetHeight(16)
                row.icon:SetPoint("RIGHT",row,"LEFT",-3,0);row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
                row.name=row:CreateFontString(nil,"OVERLAY");row.name:SetFont(FONT,11,"OUTLINE");row.name:SetPoint("LEFT",row,"LEFT",4,0);row.name:SetJustifyH("LEFT")
                row.back=row:CreateTexture(nil,"BACKGROUND");row.back:SetTexture("Interface\\Buttons\\WHITE8X8");row.back:SetVertexColor(0.2,0.22,0.27,0.35);row.back:SetAllPoints(row)
                row.valueText=row:CreateFontString(nil,"OVERLAY");row.valueText:SetFont(FONT,11,"OUTLINE");row.valueText:SetPoint("RIGHT",row,"RIGHT",-4,0)
                -- Details on hover.
                row:EnableMouse(true)
                row:SetScript("OnEnter",function()
                    local info=this.info
                    if not info then return end
                    GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(info.name,1,1,1)
                    GameTooltip:AddDoubleLine(nfUIEdit.Text("Урон за забег","Run damage"),Short(info.dmg),1,0.82,0,1,1,1)
                    GameTooltip:AddDoubleLine("DPS",Short(info.dps),1,0.82,0,1,1,1)
                    GameTooltip:AddDoubleLine(nfUIEdit.Text("Доля урона","Damage share"),string.format("%.1f%%",info.share*100),1,0.82,0,1,1,1)
                    local count,biggest=nfUIEdit.HitStats(info.name)
                    if count then
                        GameTooltip:AddDoubleLine(nfUIEdit.Text("Ударов в секунду (10 сек)","Hits per second (10 sec)"),nfUIEdit.Rate(count),1,0.82,0,1,1,1)
                        GameTooltip:AddDoubleLine(nfUIEdit.Text("Самый сильный удар за минуту","Biggest hit in the last minute"),Short(biggest),1,0.82,0,1,1,1)
                    end
                    if info.proc==1 then GameTooltip:AddLine(nfUIEdit.Text("Срабатывающий эффект","Proc"),0.6,0.8,1) end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave",function() GameTooltip:Hide() end)
                rows[index]=row
            end
            -- The icon stands left of the bar, so the whole bar can be read.
            row:SetWidth(math.max(1,width-20-columnsWidth));row:SetPoint("TOPLEFT",content,"TOPLEFT",20,-22-(index-1)*23)
            if not row.rate then
                row.rate=row:CreateFontString(nil,"OVERLAY");row.rate:SetFont(FONT,11,"OUTLINE");row.rate:SetJustifyH("RIGHT")
                row.big=row:CreateFontString(nil,"OVERLAY");row.big:SetFont(FONT,11,"OUTLINE");row.big:SetJustifyH("RIGHT")
                row.rate:SetTextColor(0.62,0.78,0.91);row.big:SetTextColor(0.91,0.69,0.54)
            end
            row.rate:SetWidth(RATE_WIDTH);row.rate:SetHeight(14);row.rate:ClearAllPoints();row.rate:SetPoint("LEFT",row,"RIGHT",3,0)
            row.big:SetWidth(BIG_WIDTH);row.big:SetHeight(14);row.big:ClearAllPoints();row.big:SetPoint("LEFT",row,"RIGHT",3+RATE_WIDTH+3,0)
            if showRates then
                row.rate:SetText(stats[index].rate);row.big:SetText(stats[index].big);row.rate:Show();row.big:Show()
            else row.rate:Hide();row.big:Hide() end
            if not content.rateCaption then
                content.rateCaption=content:CreateFontString(nil,"OVERLAY");content.rateCaption:SetFont(FONT,9,"OUTLINE");content.rateCaption:SetJustifyH("RIGHT");content.rateCaption:SetTextColor(0.62,0.78,0.91)
                content.bigCaption=content:CreateFontString(nil,"OVERLAY");content.bigCaption:SetFont(FONT,9,"OUTLINE");content.bigCaption:SetJustifyH("RIGHT");content.bigCaption:SetTextColor(0.91,0.69,0.54)
                content.rateCaption:SetText(nfUIEdit.Text("уд/с","hit/s"));content.bigCaption:SetText(nfUIEdit.Text("макс","max"))
            end
            content.rateCaption:SetWidth(RATE_WIDTH);content.bigCaption:SetWidth(BIG_WIDTH)
            content.rateCaption:ClearAllPoints();content.bigCaption:ClearAllPoints()
            content.rateCaption:SetPoint("BOTTOMRIGHT",row.rate,"TOPRIGHT",0,2+(index-1)*23);content.bigCaption:SetPoint("BOTTOMRIGHT",row.big,"TOPRIGHT",0,2+(index-1)*23)
            if showRates then content.rateCaption:Show();content.bigCaption:Show() else content.rateCaption:Hide();content.bigCaption:Hide() end
            local tint=nfUIEdit.SoftColor(line.name);row:SetStatusBarColor(tint[1],tint[2],tint[3],line.proc==1 and 0.6 or 0.95)
            local value=RowValue(line)
            local valueWidth=Measure(value)
            row:SetValue(math.min(1,line.share));row.name:SetWidth(math.max(1,width-20-columnsWidth-valueWidth-12))
            if topIcons[line.name] then row.icon:SetTexture(topIcons[line.name]);row.icon:Show() else row.icon:Hide() end
            row.name:SetHeight(14);row.name:SetText(nfUIEdit.L(line.name))
            row.valueText:SetWidth(valueWidth);row.valueText:SetHeight(14);row.valueText:SetJustifyH("RIGHT");row.valueText:SetText(value);row.info=line;row:Show()
        end
        for index=table.getn(lines)+1,table.getn(rows) do rows[index]:Hide() end
        content:SetHeight(22+table.getn(lines)*23)
        local maximum=math.max(0,content:GetHeight()-scroll:GetHeight());offset=math.min(offset,maximum);scroll:SetVerticalScroll(offset)
    end
    C.dpsFrame=panel;C.dpsRows=rows;C.LayoutDPSMeter()
    if C.RegisterMover then C.RegisterMover("dpsMeter","DPS Meter",panel,"dpsMeter") end
    local age=0
    local driver=CreateFrame("Frame","nfUIDPSDriver",UIParent)
    driver:RegisterEvent("PLAYER_LOGOUT");driver:RegisterEvent("PLAYER_LEAVING_WORLD");driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    local inWorld=true
    driver:SetScript("OnEvent",function() if event=="PLAYER_ENTERING_WORLD" then inWorld=true;C.RefreshDPSMeter() else inWorld=false;Restore() end end)
    driver:SetScript("OnUpdate",function() age=age+(arg1 or 0);if age<0.2 then return end;age=0;if inWorld then C.RefreshDPSMeter() end end)
    C.RefreshDPSMeter()
    -- The party's meter, left of the hero's own.
    local party=CreateFrame("Frame","nfUIPartyDPS",UIParent)
    party:SetWidth(190);party:SetHeight(32);party:SetFrameStrata("MEDIUM")
    party:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});party:SetBackdropColor(0.04,0.05,0.07,0.7)
    party:SetPoint("BOTTOMRIGHT",panel,"BOTTOMLEFT",-4,0);party:Hide()
    local partyTitle=party:CreateFontString(nil,"OVERLAY");partyTitle:SetFont(FONT,11,"OUTLINE")
    partyTitle:SetPoint("TOPLEFT",party,"TOPLEFT",8,-7);partyTitle:SetTextColor(1,0.82,0)
    local partyRows={}
    local function RefreshParty()
        local ok,lines,total,dps=false
        if AZS_GetPhase and AZS_GetPhase() and AZS_GetPartyMeter then ok,lines,total,dps=pcall(AZS_GetPartyMeter) end
        if not ok or type(lines)~="table" or table.getn(lines)==0 or not Number(total) or not Number(dps) then party:Hide();return end
        party:SetScale(panel:GetScale())
        for _,line in ipairs(lines) do
            if type(line.top)=="string" and not topIcons[line.top] then pcall(RefreshTopIcons);break end
        end
        partyTitle:SetText(nfUIEdit.Text("\208\147\209\128\209\131\208\191\208\191\208\176: ","Party: ")..Short(dps).." DPS")
        -- As wide as the longest name with its numbers, so big values never run into the name.
        local function Width(text,size)
            measure:SetText(text or "")
            local w=measure.GetStringWidth and measure:GetStringWidth() or string.len(text or "")*7
            return w*(size or 11)/11
        end
        local partyWidth=math.max(190,Width(partyTitle:GetText())+16)
        for _,line in ipairs(lines) do
            local value=(Number(line.dps) and Short(line.dps) or "-").." | "..(Number(line.share) and string.format("%.0f%%",line.share*100) or "-")
            partyWidth=math.max(partyWidth,Width(type(line.name)=="string" and line.name or "?")+Width(value)+28)
            if type(line.top)=="string" and Number(line.topdps) then
                partyWidth=math.max(partyWidth,Width(line.top,9)+Width(Short(line.topdps).." | 100%",9)+48)
            end
        end
        partyWidth=math.ceil(partyWidth)
        party:SetWidth(partyWidth)
        for index,line in ipairs(lines) do
            local row=partyRows[index]
            if not row then
                row=CreateFrame("StatusBar",nil,party);row:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                row:SetMinMaxValues(0,1);row:SetHeight(20);row:SetWidth(174);row:EnableMouse(true)
                row:SetPoint("TOPLEFT",party,"TOPLEFT",8,-24-(index-1)*37)
                -- Under each hero, their top skill: icon, share of their damage, DPS.
                row.top=CreateFrame("StatusBar",nil,row);row.top:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                row.top:SetMinMaxValues(0,1);row.top:SetHeight(13);row.top:SetWidth(158)
                row.top:SetPoint("TOPRIGHT",row,"BOTTOMRIGHT",0,-1)
                row.top.back=row.top:CreateTexture(nil,"BACKGROUND");row.top.back:SetTexture("Interface\\Buttons\\WHITE8X8")
                row.top.back:SetVertexColor(0.2,0.22,0.27,0.3);row.top.back:SetAllPoints(row.top)
                row.top.icon=row:CreateTexture(nil,"OVERLAY");row.top.icon:SetWidth(13);row.top.icon:SetHeight(13)
                row.top.icon:SetTexCoord(0.08,0.92,0.08,0.92);row.top.icon:SetPoint("RIGHT",row.top,"LEFT",-3,0)
                row.top.name=row.top:CreateFontString(nil,"OVERLAY");row.top.name:SetFont(FONT,9,"OUTLINE")
                row.top.name:SetPoint("LEFT",row.top,"LEFT",3,0);row.top.name:SetWidth(92);row.top.name:SetHeight(12);row.top.name:SetJustifyH("LEFT")
                row.top.value=row.top:CreateFontString(nil,"OVERLAY");row.top.value:SetFont(FONT,9,"OUTLINE")
                row.top.value:SetPoint("RIGHT",row.top,"RIGHT",-3,0)
                row.name=row:CreateFontString(nil,"OVERLAY");row.name:SetFont(FONT,11,"OUTLINE");row.name:SetPoint("LEFT",row,"LEFT",4,0)
                row.value=row:CreateFontString(nil,"OVERLAY");row.value:SetFont(FONT,11,"OUTLINE");row.value:SetPoint("RIGHT",row,"RIGHT",-4,0)
                row:SetScript("OnEnter",function()
                    local info=this.info
                    if not info then return end
                    GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText(type(info.name)=="string" and info.name or "?",1,1,1)
                    if Number(info.dmg) then GameTooltip:AddDoubleLine(nfUIEdit.Text("Урон за забег","Run damage"),Short(info.dmg),1,0.82,0,1,1,1) end
                    if Number(info.dps) then GameTooltip:AddDoubleLine("DPS",Short(info.dps),1,0.82,0,1,1,1) end
                    if Number(info.share) then GameTooltip:AddDoubleLine(nfUIEdit.Text("Доля урона","Damage share"),string.format("%.1f%%",info.share*100),1,0.82,0,1,1,1) end
                    if type(info.top)=="string" then GameTooltip:AddDoubleLine(nfUIEdit.Text("Лучшее: ","Top: ")..info.top,Number(info.topdps) and Short(info.topdps).." DPS" or "",0.6,0.8,1,1,1,1) end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave",function() GameTooltip:Hide() end)
                partyRows[index]=row
            end
            local class=type(line.class)=="string" and string.upper(line.class) or ""
            local color=class=="SHAMAN" and {r=0,g=0.44,b=0.87} or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or {r=0.4,g=0.4,b=0.45}
            row:SetStatusBarColor(color.r,color.g,color.b,0.7)
            row:SetValue(Number(line.share) and math.min(1,line.share) or 0)
            row.name:SetText(type(line.name)=="string" and line.name or "?")
            row.value:SetText((Number(line.dps) and Short(line.dps) or "-").." | "..(Number(line.share) and string.format("%.0f%%",line.share*100) or "-"))
            row.info=line
            row:SetWidth(partyWidth-16);row.top:SetWidth(partyWidth-32)
            local topShare=Number(line.topdps) and Number(line.dps) and line.dps>0 and math.min(1,line.topdps/line.dps) or nil
            if type(line.top)=="string" and topShare then
                row.top:SetStatusBarColor(color.r,color.g,color.b,0.4);row.top:SetValue(topShare)
                row.top.name:SetText(line.top)
                row.top.value:SetText(Short(line.topdps).." | "..string.format("%.0f%%",topShare*100))
                row.top.name:SetWidth(math.max(1,partyWidth-32-Width(row.top.value:GetText(),9)-12))
                local path=topIcons[line.top]
                if path then row.top.icon:SetTexture(path);row.top.icon:Show() else row.top.icon:Hide() end
                row.top:Show()
            else row.top:Hide();row.top.icon:Hide() end
            row:Show()
        end
        for index=table.getn(lines)+1,table.getn(partyRows) do partyRows[index]:Hide() end
        party:SetHeight(30+table.getn(lines)*37);party:Show()
    end
    local partyAge=0
    party.driver=CreateFrame("Frame",nil,UIParent)
    party.driver:SetScript("OnUpdate",function()
        partyAge=partyAge+(arg1 or 0);if partyAge<0.2 then return end;partyAge=0
        if inWorld then RefreshParty() else party:Hide() end
    end)
end)
