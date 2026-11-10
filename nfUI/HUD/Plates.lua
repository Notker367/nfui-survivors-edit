-- nfUI enemy plate rendering and collision layout.
-- A flat health bar on a dark backing with a thin black border, the name above
-- it, the unit's health on it, an execute-range marker, and a highlighted
-- target with its debuffs. Elites, guardians and bosses get larger plates in their own colors.
--
-- The 1.12 client owns the nameplate frames: they are unnamed children of
-- WorldFrame, recognized by their border texture. Each one is skinned once,
-- its stock art blanked and an overlay drawn from the stock health bar's
-- values. The client recycles a plate for another unit, so the overlay
-- re-reads the name every frame.
--
-- Native plate anchors remain client-owned; nfUI offsets the visual bars
-- using collision rectangles, optional upward stacking and two-second easing.
--
-- Visibility, caps, colors, geometry and text share the Nameplates settings page.
--
-- Slash commands:
--   /nfplates all        toggle all enemies / current target
--   /nfplates names      toggle name labels
--   /nfplates scale N    plate size, 0.6 to 2 (default 1)

local FLAT = "Interface\\ChatFrame\\ChatFrameBackground"
local FONT = NFUI_PLATE_FONT
local PlateLevelTag
local BORDER_TEXTURE = "Interface\\Tooltips\\Nameplate-Border"

local EXECUTE_RANGE = 0.30      -- the game's execute effects start below this share of health

local KINDS = {
	-- Who is who at a glance: a thin plain bar for the crowd, then longer, thicker bars with a mark and a thicker edge.
	normal   = { width = 100, height = 9,  nameScale = 0.85, nameAlpha = 0.8, edge = 1, color = nfUIEdit.COLORS.enemy },
	elite    = { width = 130, height = 15, nameScale = 1.05, nameAlpha = 1, edge = 1, mark = "star", color = nfUIEdit.COLORS.peach, edgeColor = {0.95, 0.75, 0.3, 1} },
	guardian = { width = 150, height = 18, nameScale = 1.15, nameAlpha = 1, edge = 2, mark = "shield", color = nfUIEdit.COLORS.sapphire, edgeColor = {0.55, 0.85, 1, 1} },
	boss     = { width = 185, height = 24, nameScale = 1.3, nameAlpha = 1, edge = 2, mark = "skull", color = nfUIEdit.COLORS.mauve, edgeColor = {1, 0.85, 1, 1} },
}
local EXECUTE_COLOR = { 0.80, 0.10, 0.10 }
nfUIConfig.PlateKinds = KINDS

-- The five bosses of each zone.
local BOSSES = {
	-- Elwynn Forest
	"Hogger", "Mother Fang", "Rhahk'Zor", "Mr. Smite", "Edwin VanCleef",
	-- Duskwood
	"Naraxis", "Mor'Ladim", "Stitches", "Lupos", "Morbent Fel",
	-- Warsong Gulch
	"Doomguard Commander", "Mannoroth's Herald", "Varimathras", "Lord Hel'nurath", "Lord Kazzak",
	-- Arathi Basin
	"Patchwerk", "Lord Blackwood", "Baron Rivendare", "Anub'Rekhan", "Kel'Thuzad",
	-- Feralas
	"Zevrim Thornhoof", "Alzzin the Wildshaper", "Tendris Warpwood", "Immol'thar", "King Gordok",
	-- Gurubashi Arena
	"High Priestess Jeklik", "High Priest Venoxis", "Bloodlord Mandokir", "Jin'do the Hexxer", "Hakkar the Soulflayer",
	-- Alterac Valley
	"Korrak the Bloodrager", "Ivus the Forest Lord", "Lokholar the Ice Lord", "Glacius the Frozen Titan", "Azuregos",
	-- Blackrock Mountain
	"General Angerforge", "Warchief Rend Blackhand", "Emperor Dagran Thaurissan", "Majordomo Executus", "Nefarian",
	-- Gates of Ahn'Qiraj
	"Kurinnaxx", "General Rajaxx", "Princess Huhuran", "Ossirian the Unscarred", "C'Thun",
}

-- The elites of each zone's horde: the three enemies the game's own tables
-- flag as elite in every zone.
local ELITES = {
	"Kobold Taskmaster", "Gruff Swiftbite", "Bellygrub",
	"Nightbane Worgen Alpha", "Carrion Recluse", "Flesh Eating Abomination",
	"Felguard Elite", "Infernal", "Doomguard",
	"Crypt Fiend", "Bone Golem", "Death Knight Captain",
	"Gordunni Brute", "Warpwood Treant", "Ironbark Protector",
	"Gurubashi Berserker", "Zulian Crocolisk", "Gurubashi Champion",
	"Alterac Yeti Lord", "Mountain Giant", "Winterax Warlord",
	"Core Hound", "Black Drake", "Molten Giant",
	"Qiraji Champion", "Anubisath Sentinel", "Obsidian Destroyer",
}

local kindByName = {}
for index = 1, table.getn(ELITES) do
	kindByName[ELITES[index]] = "elite"
end
for index = 1, table.getn(BOSSES) do
	kindByName[BOSSES[index]] = "boss"
end

-- The same elites and bosses under their Russian names, from the game's own tables.
for _,name in ipairs({"Кобольд-надсмотрщик","Сердитый Быстрокус","Брюхоед","Вожак воргов из Ночной Погибели","Паук-трупоед","Поганище-пожиратель плоти","Элитный страж Скверны","Инфернал","Стражник ужаса","Громила Гордунни","Древень Криводрева","Защитник Железной Коры","Берсерк Гурубаши","Зулианский кроколиск","Чемпион Гурубаши","Альтеракский повелитель йети","Горный великан","Полководець Зимосокир","Гончая Недр","Черный дракон","Огненный великан","Чемпион киражи","Анубисат-часовой","Обсидиановый разрушитель"}) do kindByName[name]="elite" end
for _,name in ipairs({"Дробитель","Матушка Клык","Рак'Зор","Мистер Шлеп","Эдвин ван Клиф","Наракис","Мор'Ладим","Стежок","Лупос","Морбент Злоб","Командир стражников ужаса","Глашатай Маннорота","Вариматрас","Владыка Хел'нурат","Владыка Каззак","Лоскутик","Ануб'Рекан","Кел'Тузад","Зеврим Терновое Копыто","Алззин Перевертень","Тендрис Криводрев","Иммол'тар","Король Гордок","Верховная жрица Джеклик","Верховный жрец Веноксис","Мандокир Повелитель Крови","Джин'до Проклинатель","Хаккар Свежеватель Душ","Коррак Кровожадный","Ивус Лесной Властелин","Локолар Владыка Льда","Гляциус Замёрзший Титан","Азурегос","Генерал Кузня Гнева","Вождь Ренд Чернорук","Император Дагран Тауриссан","Мажордом Экзекутус","Нефариан","Куриннакс","Генерал Раджакс","Принцесса Хухуран","Оссириан Неуязвимый","К'Тун"}) do kindByName[name]="boss" end

-- What the game said each name is, counted only from unambiguous matches: in a crowd the nearest anchor is often
-- a neighbour, and one wrong guess would shrink an elite's bar or swell a plain one.
local learned = {}
local function LearnedKind(name)
	local votes = learned[name]
	if not votes then return nil end
	local top, count = nil, 0
	for kind, n in pairs(votes) do if n > count then top, count = kind, n end end
	if count >= 2 then return top end
	return nil
end
local function Classify(name)
	if not name then
		return "normal"
	end
	-- A guardian's plate reads "<name> (Guardian)".
	if string.find(name, "(Guardian)", 1, true) then
		return "guardian"
	end
	return kindByName[name] or LearnedKind(name) or "normal"
end

local function Settings()
    local db=nfUIConfig.Settings().nameplates
    if not nfUIDB.nameplatesMigrated then
        if nfUIPlatesDB then db.scale=nfUIPlatesDB.scale or db.scale;db.showNames=nfUIPlatesDB.names~=false end
        nfUIDB.nameplatesMigrated=true
    end
    if db.stacking then db.collision=true end
    return db
end

-- 1234, 12.3k, 1.2m
local function Short(value)
	if value >= 999500000 then
		return string.format(value >= 99950000000 and "%.0fb" or "%.1fb", value / 1000000000)
	elseif value >= 99950000 then
		return string.format("%.0fm", value / 1000000)
	elseif value >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	elseif value >= 10000 then
		return string.format("%.1fk", value / 1000)
	end
	return math.floor(value + 0.5)
end

local overlays = {}
nfUIPlatesRegistry = overlays

-- The game's raid marks and skull.
local RAID_MARKS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local MARKS = {
	star = {RAID_MARKS, 0, 0.25, 0, 0.25},
	shield = {RAID_MARKS, 0.5, 0.75, 0, 0.25},
	skull = {"Interface\\TargetingFrame\\UI-TargetingFrame-Skull", 0, 1, 0, 1},
}
local function ApplyKind(overlay, kind)
	local style = KINDS[kind]
	local settings = Settings()
	local scale = settings.scale
	overlay.kind = kind
	overlay.style = style
	-- The ally sizing below runs again over the new size.
	overlay.allyWidth = nil
	overlay.petThin = nil
	overlay.bar:SetWidth(settings.width * style.width / 100 * scale)
	overlay.bar:SetHeight(settings.height * style.height / 9 * scale)
	overlay.marker:SetHeight(settings.height * style.height / 9 * scale)
	overlay.marker:SetPoint("LEFT", overlay.bar, "LEFT", settings.width * style.width / 100 * scale * EXECUTE_RANGE, 0)
	local nameSize = math.floor(settings.nameFont * scale * style.nameScale + 0.5)
	overlay.name:SetFont(FONT, nameSize, "OUTLINE")
	overlay.name:SetWidth(math.max(170,overlay.bar:GetWidth()+40));overlay.name:SetHeight(nameSize+4)
	overlay.nameAlpha = style.nameAlpha
	overlay.border.SetSize(style.edge)
	if style.mark then
		local mark = MARKS[style.mark]
		overlay.mark:SetTexture(mark[1]);overlay.mark:SetTexCoord(mark[2],mark[3],mark[4],mark[5])
		local markSize = math.max(12,overlay.bar:GetHeight()+6)
		overlay.mark:SetWidth(markSize);overlay.mark:SetHeight(markSize);overlay.mark:Show()
	else overlay.mark:Hide() end
	overlay.health:SetFont(FONT, settings.healthFont * scale, "OUTLINE")
	overlay.levelTag = PlateLevelTag(overlay.stock)
	overlay.name:SetText(overlay.levelTag .. (settings.abbreviate and nfUI_AbbreviateName(overlay.stock.name:GetText()) or overlay.stock.name:GetText() or ""))

	overlay.named = settings.showNames
	if overlay.named and not overlay.put then
		overlay.name:Show()
	else
		overlay.name:Hide()
	end

end

-- Debuffs on the target's plate, with their stacks. The 1.12 client only tells
-- an addon about the debuffs of a unit it can name, and of all the plates on
-- screen only the target's can be told apart (it alone keeps full alpha).
local PLATE_DEBUFFS = 6
local DEBUFF_SIZE = 11
-- Which unit a plate's debuffs can be read from: the target, or an ally by name.
-- The party is looked up twice a second, not for every plate on every frame.
local partyUnits,partyColors,partyPets,partyRead={},{},{},-1
local function ReadParty()
    local now=GetTime()
    if now-partyRead<0.5 then return end
    partyRead=now
    partyUnits,partyColors,partyPets={},{},{}
    if UnitExists("pet") then local name=UnitName("pet");if name then partyPets[name]=true end end
    for index=1,4 do
        local unit="party"..index
        if UnitExists(unit) then
            local name=UnitName(unit)
            if name then
                partyUnits[name]=unit
                local _,class=UnitClass(unit)
                local color=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if class=="SHAMAN" then partyColors[name]={0.00,0.44,0.87}
                elseif color then partyColors[name]={color.r,color.g,color.b} end
            end
        end
        local pet="partypet"..index
        if UnitExists(pet) then local name=UnitName(pet);if name then partyPets[name]=true end end
    end
end
local function PartyUnitByName(name)
    if not name then return nil end
    ReadParty()
    return partyUnits[name]
end

-- An ally's level comes from the party; everyone else's from the plate.
function PlateLevelTag(stock)
    local ally=stock.name and PartyUnitByName(stock.name:GetText())
    if ally then return nfUIEdit.LevelTag(UnitLevel(ally)) end
    return nfUIEdit.LevelTag(stock.level and stock.level:GetText())
end

-- The hero's own spells by icon: the game does not say who cast a debuff, so a debuff wearing one of these is the hero's.
local ownIcons,ownRead={},-10
local function IconKey(texture)
    if not texture then return nil end
    local _,_,last=string.find(string.lower(texture),"([^\\/]+)$")
    return last
end
local function IsOwn(texture)
    local now=GetTime()
    if now-ownRead>5 then
        ownRead=now;ownIcons={}
        local index=1
        while GetSpellName(index,"spell") do
            local key=IconKey(GetSpellTexture(index,"spell"))
            if key then ownIcons[key]=true end
            index=index+1
        end
    end
    local key=IconKey(texture)
    return key and ownIcons[key]
end
-- A boss's or guardian's debuffs come from the game by its id; any other enemy's only while it is the target.
local function GameDebuffs(name)
    if not name or not AZS_GetDebuffs then return nil end
    for _,unit in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
        if unit.name==name and unit.id then
            local ok,list=pcall(AZS_GetDebuffs,unit.id)
            if ok and type(list)=="table" and list[1] then return list end
        end
    end
    return nil
end
local OWN_SIZE,ALLY_SIZE=15,10
local found={}
local function UpdatePlateDebuffs(overlay,target)
    local name=overlay.stock.name:GetText()
    local count=0
    local unit=target and "target" or PartyUnitByName(name)
    if unit then
        for index=1,16 do
            local texture,stacks=UnitDebuff(unit,index)
            if not texture then break end
            count=count+1;found[count]={texture,stacks}
        end
    elseif overlay.kind=="boss" or overlay.kind=="guardian" then
        for _,debuff in ipairs(GameDebuffs(name) or {}) do
            local texture=debuff.icon
            if texture and texture~="" then
                if not string.find(texture,"\\") then texture="Interface\\Icons\\"..texture end
                count=count+1;found[count]={texture,tonumber(debuff.stacks)}
            end
        end
    end
    if count==0 then
        if overlay.debuffsShown then for _,icon in ipairs(overlay.debuffs or {}) do icon:Hide() end end
        overlay.debuffsShown=nil;return
    end
    local W=nfUIWidgets
    overlay.debuffs=overlay.debuffs or {};overlay.debuffsShown=true
    local lift=overlay.named and Settings().nameFont*Settings().scale+7 or 4
    -- The hero's own first and larger, then the allies' small beside them.
    local x,shown=0,0
    for pass=1,2 do
        for index=1,count do
            local texture,stacks=found[index][1],found[index][2]
            local own=IsOwn(texture) and true or false
            if (pass==1)==own and shown<PLATE_DEBUFFS+2 then
                shown=shown+1
                local icon=overlay.debuffs[shown]
                if not icon then
                    icon=CreateFrame("Frame",nil,overlay.bar)
                    icon.texture=W.Fill(icon,{1,1,1,1},"ARTWORK");icon.texture:SetTexCoord(0.08,0.92,0.08,0.92)
                    icon.count=W.Label(icon,9,"BOTTOMRIGHT",1,-1)
                    overlay.debuffs[shown]=icon
                end
                local size=own and OWN_SIZE or ALLY_SIZE
                icon:SetWidth(size);icon:SetHeight(size)
                icon:ClearAllPoints();icon:SetPoint("BOTTOMLEFT",overlay.bar,"TOPLEFT",x,lift)
                x=x+size+2
                icon.texture:SetTexture(texture);icon.count:SetText(stacks and stacks>1 and stacks or "")
                icon:SetAlpha(own and 1 or 0.8);icon:Show()
            end
        end
    end
    for index=shown+1,table.getn(overlay.debuffs) do overlay.debuffs[index]:Hide() end
end

local function SuppressStock(overlay)
    local stock=overlay.stock
    -- Some native plate drivers restore child visibility when a unit changes.
    -- Our overlay is a sibling of the health bar, so hiding it keeps our view
    -- and the native parent/hit region alive. Hidden bars still expose values.
    if stock.health:IsShown() then stock.health:Hide() end
    for _,region in ipairs(stock.hiddenRegions or {}) do
        if region:IsShown() then region:Hide() end
    end
    if stock.fill and stock.fill:IsShown() then stock.fill:Hide() end
end

-- Allies' plates alongside enemies': allies in their class colour, others in the game's own
-- friendly colour, and the party's pets left out.
local function FriendlyColor(overlay)
	local r,g,b=overlay.stock.health:GetStatusBarColor()
	if not r or (g<=r+0.2 and b<=r+0.2) then return nil end
	ReadParty()
	local known=partyColors[overlay.stock.name:GetText()]
	if known then return known end
	overlay.friendColor=overlay.friendColor or {}
	overlay.friendColor[1],overlay.friendColor[2],overlay.friendColor[3]=r,g,b
	return overlay.friendColor
end
local function IsPartyPet(overlay)
    local name=overlay.stock.name:GetText()
    if not name then return false end
    ReadParty()
    return partyPets[name]==true
end

-- The game's own word for what this enemy is, which works in every language.
local GAME_KINDS={enemy="normal",elite="elite",guardian="guardian",boss="boss",finalBoss="boss"}
function nfUIConfig.SetPlateKind(overlay,gameKind,sure)
    local kind=GAME_KINDS[gameKind]
    local name=overlay.stock and overlay.stock.name:GetText()
    if not kind or not name then return end
    -- The game's own tables already named it.
    if kindByName[name] or string.find(name,"(Guardian)",1,true) then return end
    if sure then
        local votes=learned[name] or {}
        learned[name]=votes;votes[kind]=(votes[kind] or 0)+1
    end
    local known=LearnedKind(name)
    if known and overlay.kind~=known then ApplyKind(overlay,known) end
end

local function UpdatePlate()
	local overlay = this
	local stock = overlay.stock
    SuppressStock(overlay)

	local name = stock.name:GetText()
	local levelTag = PlateLevelTag(stock)
	if name ~= overlay.lastName or levelTag ~= overlay.levelTag then
		if name ~= overlay.lastName then
			ApplyKind(overlay, Classify(name))
			overlay.shownShare = nil
			overlay.trailShare = nil
		end
		overlay.lastName = name
		overlay.levelTag = levelTag
		overlay.name:SetText(levelTag .. ((Settings().abbreviate and nfUI_AbbreviateName(name) or name) or ""))
	end

	-- The client dims every plate but the target's.
	local isTarget = UnitExists("target") and overlay.plate:GetAlpha() == 1

	if overlay.put then return end

	local low, high = stock.health:GetMinMaxValues()
	local value = stock.health:GetValue()
	local share = high > low and (value - low) / (high - low) or 0
	local percent = math.floor(share * 100 + 0.5)
	-- A hit drops the bar at once and the lost piece flares, holds and drains. A rise is instant here: plates are
	-- reused for new enemies.
	local elapsed = arg1 or 0
	overlay.hitState = overlay.hitState or {}
	if overlay.shownShare == nil or share > (overlay.hitState.last or 0) + 0.02 then overlay.hitState = {shown = share, trail = share, last = share} end
	local shown, trail, flash = nfUIEdit.HitTrail(overlay.hitState, share, elapsed, overlay.bar)
	if not nfUIEdit.On("plateTrail") then
		shown = share
		trail = share
	end
	overlay.shownShare = shown
	overlay.trailShare = trail
	overlay.ghost:SetVertexColor(nfUIEdit.TrailColor(flash))
	if trail - shown > 0.002 then
		local barWidth = overlay.bar:GetWidth()
		overlay.ghost:ClearAllPoints()
		overlay.ghost:SetPoint("LEFT", overlay.bar, "LEFT", barWidth * shown, 0)
		overlay.ghost:SetWidth(math.max(1, barWidth * (trail - shown)))
		overlay.ghost:SetHeight(overlay.bar:GetHeight())
		overlay.ghost:Show()
	else
		overlay.ghost:Hide()
	end
	overlay.bar:SetValue(shown)
	-- The target stays solid; the others fade with distance and when another bar stands in front.
	local plateFade = isTarget and 1 or (overlay.plateFade or 1)
	-- Elites, guardians and bosses stay solid at any distance and behind other bars.
	local strong = overlay.kind == "elite" or overlay.kind == "guardian" or overlay.kind == "boss"
	if strong then plateFade = 1 end
	-- Pets and other friends are not what the hero must read in a fight; party members keep their bars.
	if not isTarget and nfUIEdit.On("friendFade") and not (PartyUnitByName(stock.name:GetText())) then
		local fr, fg = stock.health:GetStatusBarColor()
		if fg and fr and fg > fr * 1.5 then plateFade = math.min(plateFade, 0.3) end
	end
	-- Party members' bars can be wider than enemies' (Blocks > Ally bar width).
	local wide = PartyUnitByName(stock.name:GetText()) and nfUIEdit.Size("allyPlateWidth",100) or nil
	if wide ~= overlay.allyWidth then
		overlay.allyWidth = wide
		local settings = Settings()
		local style = overlay.style or KINDS.normal
		overlay.bar:SetWidth(settings.width * (wide or style.width) / 100 * settings.scale)
		-- And taller, so an ally's health reads at a glance (Blocks > Ally bar height).
		local tall = wide and nfUIEdit.Size("allyPlateHeight",16) or style.height
		overlay.bar:SetHeight(settings.height * tall / 9 * settings.scale)
		overlay.marker:SetHeight(settings.height * tall / 9 * settings.scale)
		overlay.petThin = nil
	end
	-- The party's pets: a thin bar without a name, so that they do not cover the enemies (Switches > Pet bars).
	local pet = IsPartyPet(overlay)
	if pet ~= overlay.petThin then
		overlay.petThin = pet
		local settings = Settings()
		local style = overlay.style or KINDS.normal
		local tall = pet and 3 or (overlay.allyWidth and nfUIEdit.Size("allyPlateHeight",16) or style.height)
		overlay.bar:SetHeight(math.max(2, settings.height * tall / 9 * settings.scale))
		overlay.marker:SetHeight(math.max(2, settings.height * tall / 9 * settings.scale))
	end
	overlay.bar:SetAlpha(((isTarget or strong) and 1 or 0.85) * plateFade)
	overlay.name:SetAlpha(overlay.petThin and 0 or plateFade * (isTarget and 1 or (overlay.nameAlpha or 1)))
	if overlay.distanceBox then overlay.distanceBox:SetAlpha(plateFade) end

	-- A 0 to 100 bar means the client only knows the percentage; anything else
	-- is the unit's real health.
    local mode=Settings().healthText
    if mode=="Numerical" then overlay.health:SetText(Short(value))
    elseif mode=="CurrentHP+%" then overlay.health:SetText(Short(value).." | "..percent.."%")
    else overlay.health:SetText(percent.."%") end
    if overlay.petThin then overlay.health:SetText("") end

	local color = FriendlyColor(overlay) or (Settings().rankColors and overlay.style.color or Settings().color)
	if share <= EXECUTE_RANGE then
		overlay.marker:Hide()
	else
		overlay.marker:Hide()
	end
	overlay.bar:SetStatusBarColor(color[1], color[2], color[3], 1)

	-- Red edge when the target is looking at the hero. The game names only the target's target.
	if nfUIEdit.On("redEdge") and (overlay.nearHero or (isTarget and UnitExists("targettarget") and UnitIsUnit("targettarget","player") and UnitCanAttack("player","target"))) then
		overlay.border.SetColor(1, 0.08, 0.08, 1)
	elseif isTarget then
		overlay.border.SetColor(1, 1, 1, 1)
	else
		local edgeColor = overlay.style and overlay.style.edgeColor
		local classColor = not overlay.petThin and partyColors[stock.name:GetText() or ""]
		if classColor then overlay.border.SetColor(classColor[1], classColor[2], classColor[3], 1)
		elseif edgeColor then overlay.border.SetColor(edgeColor[1], edgeColor[2], edgeColor[3], edgeColor[4])
		else overlay.border.SetColor(0.12, 0.13, 0.16, 0.55) end
	end
	UpdatePlateDebuffs(overlay, isTarget)
end

local function IsNameplate(frame)
	local region = frame:GetRegions()
	return region and region.GetObjectType and region:GetObjectType() == "Texture"
		and region:GetTexture() == BORDER_TEXTURE
end

local function SkinPlate(plate)
    if plate.nfUIPlateOverlay then return end
    local bar=plate:GetChildren()
    if not bar or not bar.GetMinMaxValues then return end
    local regions={plate:GetRegions()};local source={health=bar,hiddenRegions={}}
    for index,region in ipairs(regions) do
        local kind=region:GetObjectType()
        if kind=="FontString" then
            if not source.name then source.name=region else source.level=region end
            region:SetAlpha(0);table.insert(source.hiddenRegions,region)
        elseif kind=="Texture" and index<table.getn(regions) then
            region:SetAlpha(0);region:SetTexCoord(0,0,0,0);table.insert(source.hiddenRegions,region)
        end
    end
    if not source.name then return end
    -- A nil status-bar texture is a no-op on some clients. Hide only the
    -- native bar child; the plate stays visible as our anchor/data source.
    source.health:SetAlpha(0)
    source.fill=source.health.GetStatusBarTexture and source.health:GetStatusBarTexture()
    if source.fill and not source.fill.Hide then source.fill=nil end
    if source.fill then source.fill:SetAlpha(0) end
    local W=nfUIWidgets
    local overlay=CreateFrame("Frame",nil,plate)
    overlay.stock=source;overlay.plate=plate;overlay.motion={};overlay:SetAllPoints(plate);overlay:SetAlpha(0)
    SuppressStock(overlay)
    overlay.bar=CreateFrame("StatusBar",nil,overlay)
    overlay.bar:SetMinMaxValues(0,1);overlay.bar:SetStatusBarTexture(W.texture);overlay.bar:SetPoint("CENTER",overlay,"CENTER",0,8)
    -- Lines around the bar, not a fill behind it: what was lost stays see-through.
    overlay.border=nfUIEdit.Edge(overlay.bar,0.12,0.13,0.16,0.55);overlay.border.SetSize(1);overlay.border.Show()
    overlay.mark=overlay.bar:CreateTexture(nil,"OVERLAY");overlay.mark:SetPoint("RIGHT",overlay.bar,"LEFT",-2,0);overlay.mark:Hide()
    overlay.backing=W.Fill(overlay.bar,{nfUIEdit.COLORS.base[1],nfUIEdit.COLORS.base[2],nfUIEdit.COLORS.base[3],0.12},"BORDER")
    overlay.marker=W.Fill(overlay.bar,{1,1,1,0.7},"OVERLAY");overlay.marker:ClearAllPoints();overlay.marker:SetWidth(1)
    overlay.ghost=overlay.bar:CreateTexture(nil,"ARTWORK");overlay.ghost:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.ghost:SetVertexColor(nfUIEdit.COLORS.yellow[1],nfUIEdit.COLORS.yellow[2],nfUIEdit.COLORS.yellow[3],0.9);overlay.ghost:Hide()
    overlay.name=W.Label(overlay,11,"BOTTOM",0,0,nil,{1,1,1});overlay.name:SetFont(FONT,11,"OUTLINE")
    overlay.name:ClearAllPoints();overlay.name:SetPoint("BOTTOMLEFT",overlay.bar,"TOPLEFT",0,2);overlay.name:SetJustifyH("LEFT")
    overlay.name:SetTextColor(1,1,1);overlay.name:SetShadowColor(0,0,0,1);overlay.name:SetShadowOffset(1,-1)
    overlay.health=W.Label(overlay.bar,10,"CENTER",0,0,nil,{1,1,1});overlay.health:SetFont(FONT,10,"OUTLINE");overlay.health:SetJustifyH("CENTER")
    ApplyKind(overlay,"normal")
    overlay:SetScript("OnUpdate",UpdatePlate)
    plate.nfUIPlateOverlay=overlay;table.insert(overlays,overlay)
end

-- New plates only ever get appended to WorldFrame's children.
local scanned = 0
local scanner = CreateFrame("Frame")
scanner:SetScript("OnUpdate", function()
	local count = WorldFrame:GetNumChildren()
	if count ~= scanned then
		local ok, children = pcall(function() return { WorldFrame:GetChildren() } end)
		if not ok then scanned = count; return end
		for index = scanned + 1, count do
			local child = children[index]
			if child and IsNameplate(child) then
				SkinPlate(child)
			end
		end
		scanned = count
	end
end)

-- Enemy nameplates are off by default; a run is unreadable without them.
scanner:RegisterEvent("PLAYER_ENTERING_WORLD")
scanner:SetScript("OnEvent", function() nfUIConfig.ApplyNameplates() end)

local function Restyle()
	for index = 1, table.getn(overlays) do
		ApplyKind(overlays[index], overlays[index].kind or "normal")
	end
end

local function Nearer(a,b)
    if a.depth~=b.depth then return a.depth>b.depth end
    if a.y~=b.y then return a.y<b.y end
    return a.index<b.index
end
local function MotionValue(state,now)
    local t=math.max(0,math.min(1,(now-state.started)/0.1)) -- Was 2 s, plates lagged behind
    local ease=t*t*(3-2*t)
    return state.from+(state.target-state.from)*ease,t
end
local function Animate(overlay,key,target)
    local now=GetTime();overlay.motion=overlay.motion or {}
    local state=overlay.motion[key]
    if state and math.abs(state.target-target)<0.01 then return end
    local current=state and MotionValue(state,now) or 0
    overlay.motion[key]={from=current,target=target,started=now}
end
local function UpdateAnimations()
    local now=GetTime()
    for _,overlay in ipairs(overlays) do
        if overlay.motion then
            local move=overlay.motion.offset
            if move then
                local offset=MotionValue(move,now)
                if overlay.drawOffset~=offset then
                    overlay.bar:ClearAllPoints();overlay.bar:SetPoint("CENTER",overlay,"CENTER",0,8+offset);overlay.drawOffset=offset
                end
            end
            local fade=overlay.motion.fade
            if fade then
                local alpha,t=MotionValue(fade,now)
                if overlay.drawAlpha~=alpha then overlay:SetAlpha(alpha);overlay.drawAlpha=alpha end
                if t>=1 and fade.target==0 then overlay.bar:Hide();overlay.name:Hide() end
            end
        end
    end
end
nfUIConfig.UpdateNameplateAnimations=UpdateAnimations
local function LayoutPlates()
    local settings=Settings();local candidates={}
    for index,overlay in ipairs(overlays) do
        overlay.layoutAccepted=false
        if overlay.plate:IsShown() then
            local x,y=overlay.plate:GetCenter()
            if x and y then
                local ratio=overlay.plate:GetEffectiveScale()/UIParent:GetEffectiveScale()
                local target=UnitExists("target") and overlay.plate:GetAlpha()==1
                if settings.enabled and (settings.amount~="Target" or target) and not (IsPartyPet(overlay) and not nfUIEdit.On("petBars")) then
                    local halfWidth=overlay.bar:GetWidth()*ratio/2+3
                    local halfHeight=overlay.bar:GetHeight()*ratio/2+3
                    local above=settings.showNames and settings.nameFont*settings.scale*ratio+5 or 0
                    if target and overlay.debuffsShown then above=above+(DEBUFF_SIZE+3)*ratio end
                    table.insert(candidates,{overlay=overlay,index=index,x=x*ratio,y=(y-4)*ratio,width=halfWidth,height=halfHeight,above=above,ratio=ratio,depth=ratio,target=target})
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.target~=b.target then return a.target and true or false end
        return Nearer(a,b)
    end)
    local limit=settings.amount=="5 max" and 5 or settings.amount=="10 max" and 10 or table.getn(candidates)
    local selected={}
    for index=1,math.min(limit,table.getn(candidates)) do table.insert(selected,candidates[index]) end
    table.sort(selected,Nearer)
    local placed={}
    local function Rect(entry,y) return {left=entry.x-entry.width,right=entry.x+entry.width,bottom=y-entry.height,top=y+entry.height+entry.above} end
    local function Overlap(a,b) return a.left<b.right and a.right>b.left and a.bottom<b.top and a.top>b.bottom end
    for _,entry in ipairs(selected) do
        local y=entry.y
        if settings.collision then
            -- Each accepted invisible rectangle becomes an obstacle for later plates.
            for attempt=1,table.getn(placed)+1 do
                local bounds=Rect(entry,y);local hit
                for _,other in ipairs(placed) do if Overlap(bounds,other) then hit=other;break end end
                if not hit then break end
                local up=hit.top+entry.height+2
                local down=hit.bottom-entry.height-entry.above-2
                y=settings.stacking and up or (math.abs(up-entry.y)<=math.abs(down-entry.y) and up or down)
            end
        end
        local bounds=Rect(entry,y)
        if settings.stacking and bounds.top>UIParent:GetHeight() then
            -- Prefer upward slots, then use space below when the top is full.
            y=entry.y
            for attempt=1,table.getn(placed)+1 do
                local hit;local candidate=Rect(entry,y)
                for _,other in ipairs(placed) do if Overlap(candidate,other) then hit=other;break end end
                if not hit then break end
                y=hit.bottom-entry.height-entry.above-2
            end
            bounds=Rect(entry,y)
        end
        -- If the screen cannot fit another complete rectangle, omit it rather than overlap.
        local blocked=false
        if settings.collision then
            for _,other in ipairs(placed) do if Overlap(bounds,other) then blocked=true end end
            if bounds.top>UIParent:GetHeight() or bounds.bottom<0 then blocked=true end
        end
        if not blocked then
            local overlay=entry.overlay;overlay.put=nil;overlay.layoutAccepted=true
            -- Enemies low on the screen are nearer and look bigger, so their plate sits higher.
            local nearness=1-math.max(0,math.min(1,entry.y/UIParent:GetHeight()))
            local offset=(y-entry.y)/entry.ratio+math.floor(nearness*16+0.5)
            overlay.collisionOffset=offset
            Animate(overlay,"offset",offset);Animate(overlay,"fade",1)
            overlay.collisionBounds=bounds;overlay.bar:Show()
            if overlay.named then overlay.name:Show() end
            table.insert(placed,bounds)
        end
    end
    for _,overlay in ipairs(overlays) do
        if not overlay.layoutAccepted then
            overlay.put=true
            Animate(overlay,"fade",0)
            overlay.collisionBounds=nil
        end
    end
end
local pendingHide
local nativeEnabled=true
function nfUIConfig.ApplyNameplates()
    local settings=Settings()
    if settings.enabled then
        pendingHide=nil
        if not nativeEnabled or not NAMEPLATES_ON then ShowNameplates();NAMEPLATES_ON=1 end
        if not FRIENDNAMEPLATES_ON then ShowFriendNameplates();FRIENDNAMEPLATES_ON=1 end
        nativeEnabled=true
    elseif nativeEnabled and not pendingHide then pendingHide=GetTime()+2 end
    Restyle();LayoutPlates()
end
nfUIConfig.LayoutNameplates=LayoutPlates
local layoutDriver=CreateFrame("Frame","nfUIPlateLayout",UIParent)
local layoutAge=0
layoutDriver:SetScript("OnUpdate",function()
    UpdateAnimations()
    if pendingHide and GetTime()>=pendingHide then
        HideNameplates();NAMEPLATES_ON=nil;nativeEnabled=false;pendingHide=nil
        HideFriendNameplates();FRIENDNAMEPLATES_ON=nil
    end
    layoutAge=layoutAge+(arg1 or 0);if layoutAge<0.03 then return end;layoutAge=0;LayoutPlates()
end)

local function Say(text)
	DEFAULT_CHAT_FRAME:AddMessage("nfUI Plates: "..text)
end

SLASH_NFUIPLATES1 = "/nfplates"
SlashCmdList["NFUIPLATES"] = function(msg)
	local settings = Settings()
	local _, _, command, argument = string.find(msg or "", "^(%S*)%s*(.*)$")
	local number = tonumber(argument)

	if command == "all" then
		settings.amount = settings.amount=="All" and "Target" or "All"
		Say("plates: "..settings.amount..".")
	elseif command == "names" then
		settings.showNames = not settings.showNames
		Say("names on "..(settings.showNames and "every plate" or "no plates")..".")
	elseif command == "scale" and number then
		settings.scale = math.max(0.6, math.min(2, number))
		Say("scale "..settings.scale..".")
	else
		Say("/nfplates all | names | scale 0.6-2")
		return
	end
	nfUIConfig.ApplyNameplates()
end
