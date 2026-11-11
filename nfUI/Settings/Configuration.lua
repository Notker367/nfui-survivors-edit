-- nfUI configuration: the original compact layout, adjustable live.
local C=nfUIConfig
local FLAT="Interface\\ChatFrame\\ChatFrameBackground"
local FONT=NFUI_FONT
local categories={
    {key="layout",title="Overall layout",description="Overall scale. Use Movers to position each element independently.",
        fields={{"scale","Overall scale"}}},
    -- The switches, by what the player wants from them. Each says in a line what it does and where it shows.
    {key="main",title="Main",ru="Основное",description="How much to show and what matters most.",descRu="Сколько показывать и самое нужное.",fields={
        {"style","Style","style",ru="Стиль",desc={"Классический: как в старом WoW. Современный: всё под героем.","Classic: as in the old WoW. Modern: everything under the hero."}},
        {"textSize","Text size","textsize",ru="Размер текста",desc={"Все шрифты аддона и боковые панели вместе.","All the addon's fonts and side panels together."}},
        {"mode","How much to show","mode",ru="Сколько показывать",desc={"Минимум: только бой. Обычный: плюс боссы и пулы. Подробный: всё.","Minimal: the fight only. Default: adds bosses and pools. Detailed: all."}},
        {"dangerLine","One-shot line","switch",ru="Порог ваншота",desc={"Красная черта на ХП: ниже неё следующий такой удар убьёт.","A red line on health: below it the next hit like that kills."}},
        {"deathSummary","Death card","switch",ru="Карточка смерти",desc={"После смерти: что убило и кнопка разбора забега.","After a death: what killed you and a button to review the run."}},
        {"bossAlert","Boss warning","switch",ru="Предупреждение о боссе",desc={"Звук и надпись за 10 секунд до босса.","A sound and a line 10 seconds before a boss."}},
        {"skillStats","Rank and DPS under skills","switch",ru="Ранг и DPS под скилами",desc={"Под каждой кнопкой скила его ранг и урон в секунду.","Each skill button shows its rank and damage per second."}},
        {"dpsMeter","DPS meter","switch",ru="DPS-метр",desc={"Урон по скилам справа внизу; клик по заголовку разворачивает.","Damage by skill in the bottom right; click the header to unfold."}},
        {"runsButton","Run analysis button","switch",ru="Кнопка анализа забегов",desc={"Меч у мини-карты открывает разбор забегов.","A sword by the minimap opens the run analysis."}},
        {"lastRunCard","Last run at the start","switch",ru="Прошлый забег на старте",desc={"Перед забегом карточка прошлого: как далеко дошли и что убило.","Before a run, a card of the last one: how far it went and what killed you."}},
        {"colorblind","Colour-blind palette","switch",ru="Палитра для дальтоников",desc={"Красный и зелёный заменяются синим и оранжевым. Затем /reload.","Red and green become blue and orange. Then /reload."}},
        {"export","Run history as text","export",ru="История забегов текстом",desc={"Все забеги одной строкой, чтобы скопировать.","Every run in one line, to copy."}},
        {"updates","Version","update",ru="Версия",desc={"Где взять новую версию и куда писать об ошибках.","Where to get a new version and where to report a bug."}}}},
    {key="fight",title="Fight",ru="Бой",description="Numbers, enemy bars and the hero frame.",descRu="Цифры, полоски врагов и панель героя.",fields={
        {"risingDamage","Damage you take","switch",ru="Урон по вам",desc={"Красные цифры поднимаются над вашим ХП.","Red numbers rise above your health."}},
        {"risingHeal","Healing you get","switch",ru="Хил по вам",desc={"Зелёные цифры рядом с уроном.","Green numbers beside the damage."}},
        {"targetRising","Your hits on the target","switch",ru="Ваши удары по цели",desc={"Цифры над ХП цели со значком скила.","Numbers above the target's health with the skill's icon."}},
        {"levels","Enemy levels","switch",ru="Уровень врагов",desc={"Перед именем, в цветах классического WoW.","Before the name, in the classic WoW colours."}},
        {"metres","Metres to enemies","switch",ru="Метры до врагов",desc={"Расстояние рядом с полоской врага.","The distance beside an enemy's bar."}},
        {"redEdge","Red edge on close enemies","switch",ru="Красная рамка у ближних",desc={"Враг рядом с вами обведён красным.","An enemy close to you gets a red edge."}},
        {"farPlates","Far enemies","switch",ru="Дальние враги",desc={"Бледные полоски врагов за пределами обычных.","Pale bars for enemies beyond the game's own."}},
        {"petBars","Pet bars","switch",ru="Полоски питомцев",desc={"Тонкая полоска без имени у питомцев группы.","A thin nameless bar on the party's pets."}},
        {"noSpellEffects","Spell effects","cvar",ru="Эффекты заклинаний",invert=true,desc={"Вспышки и следы заклинаний. Без них проще видеть врагов.","Flashes and trails of spells. Without them enemies are easier to see."}},
        {"regenText","Regeneration per second","switch",ru="Реген в секунду",adv=true,desc={"Зелёное число на конце полоски ХП.","A green number at the end of the health bar."}},
        {"ownLevel","Hero level on the portrait","switch",ru="Уровень на портрете",adv=true,desc={"Число на портрете героя.","A number on the hero's portrait."}},
        {"chestIcon","Chest when affordable","switch",ru="Сундук по карману",adv=true,desc={"Значок у панели героя, когда золота хватает на сундук.","An icon by the hero frame when gold covers a cache."}},
        {"fullHits","Damage numbers in full","switch",ru="Урон полным числом",adv=true,desc={"12 345 вместо 12k.","12 345 instead of 12k."}},
        {"separateHits","Separate hits beside the total","switch",ru="Отдельные удары",adv=true,desc={"Каждый удар рядом с общей цифрой.","Each hit beside the total."}},
        {"hitImpact","Bars react to hits","switch",ru="Полоски вздрагивают",adv=true,desc={"Полоска врага вспыхивает от удара.","An enemy's bar flashes when hit."}},
        {"plateTrail","Health drain trail","switch",ru="След убывания ХП",adv=true,desc={"Убывающее ХП оставляет светлый след.","Lost health leaves a light trail."}},
        {"plateFade","Far and covered bars fade","switch",ru="Дальние полоски бледнее",adv=true,desc={"Чем дальше враг, тем бледнее его полоска.","The farther an enemy, the paler its bar."}},
        {"friendFade","Pets' bars stay faint","switch",ru="Питомцы бледнее",adv=true,desc={"Полоски питомцев не отвлекают от врагов.","Pets' bars do not draw the eye from enemies."}},
        {"targetOfTarget","Target of target","switch",ru="Цель цели",adv=true,desc={"В Survivors это почти всегда вы.","In Survivors it is almost always you."}}}},
    {key="build",title="Build",ru="Билд",description="What you have and what can still drop.",descRu="Что взято и что ещё может выпасть.",fields={
        {"skillPool","Skill pool","switch",ru="Пул скилов",desc={"Взятые скилы отдельным рядом, ниже то, что ещё может выпасть.","Picked skills in a row of their own, below what can still drop."}},
        {"jewelPool","Jewelry pool","switch",ru="Пул бижутерии",desc={"Кольца, талисманы и амулеты: надетое в рамке, остальное ещё возможно.","Rings, trinkets and amulets: worn ones framed, the rest still possible."}},
        {"legendRow","Skill legendaries","switch",ru="Легендарки на скилы",desc={"Легендарные амулеты ваших скилов сверху, с картинками из Кодекса.","Your skills' legendary amulets on top, with the Codex pictures."}},
        {"banishMarks","Banished cards","switch",ru="Изгнанные карты",desc={"Клик по значку в пуле отмечает его изгнанным.","A click on a pool icon marks it as banished."}},
        {"ownLoadout","Your jewelry","switch",ru="Ваша бижутерия",adv=true,desc={"Надетое под панелью скилов.","What you wear, under the skill bar."}},
        {"partyLoadout","Allies' loadouts","switch",ru="Снаряжение союзников",adv=true,desc={"Скилы и бижутерия под рамками группы.","Skills and jewelry under the party frames."}},
        {"allyLoadout","Chosen ally's loadout","switch",ru="Снаряжение выбранного союзника",adv=true,desc={"Под целью, когда выбран союзник.","Under the target when an ally is chosen."}},
        {"autoMarks","Mark downed allies","switch",ru="Метки на упавших",adv=true,desc={"Череп на упавшем союзнике, чтобы его подняли. Снимается после подъёма.","A skull on an ally who is down, so they get raised. Comes off once up."}}}},
    {key="run",title="Run",ru="Забег",description="Panels on the right: bosses, guardians, history.",descRu="Панели справа: боссы, стражи, история.",fields={
        {"bossSchedule","Bosses","switch",ru="Боссы",desc={"Отсчёт до каждого босса забега.","A countdown to each boss of the run."}},
        {"lairPanel","Guardians","switch",ru="Стражи",desc={"Когда проснётся каждый страж и сколько у него ХП.","When each guardian wakes and its health."}},
        {"historyPanel","You against your best","switch",ru="Ты против лучшего",desc={"DPS сейчас против прошлого и лучшего забега в ту же секунду.","DPS now against the last and best run at the same second."}},
        {"takenPanel","What hurts you","switch",ru="Кто бьёт героя",desc={"Доли урона по вам: враги, боссы, удары, заклинания.","Shares of the damage you take: enemies, bosses, hits, spells."}},
        {"heroStats","Hero stats","switch",ru="Статы героя",desc={"Урон, крит, скорость и остальное столбиком.","Damage, crit, speed and the rest in a column."}},
        {"dpsGraph","DPS graph","switch",ru="График DPS",desc={"DPS по ходу забега против прошлого.","DPS over the run against the last one."}},
        {"skillRate","Hits per second in the meter","switch",ru="Удары в секунду в метре",adv=true,desc={"В DPS-метре: как часто бьёт скил и самый сильный удар.","In the DPS meter: how often a skill hits and its biggest hit."}},
        {"mapPins","Guardians and caches on the minimap","switch",ru="Стражи и сундуки на карте",adv=true,desc={"Голубые стражи спят, оранжевые проснулись, жёлтые сундуки.","Blue guardians sleep, orange ones are awake, yellow are caches."}}}},
    {key="look",title="Look",ru="Внешний вид",description="Chat, minimap and the switches of each frame.",descRu="Чат, мини-карта и переключатели каждой панели.",fields={
        {"mapSettings","Gear by the minimap","switch",ru="Шестерёнка у мини-карты",desc={"Быстрое меню. Без неё настройки открываются командой /nfui.","The quick menu. Without it, settings open with /nfui."}},
        {"chatNarrowFont","Narrow chat font","switch",ru="Узкий шрифт чата",desc={"Чёткий шрифт, больше слов в строке.","A crisp font, more words per line."}},
        {"chatTabs","Chat tabs always visible","switch",ru="Вкладки чата всегда видны",desc={"Иначе появляются при наведении.","Otherwise they show on hover."}}}},
    {key="blocks",title="Blocks",description="Size of each movable block. Drag them with Movers; right-click one to lock it.",
        fields={{"headRight","Right panels","heading"},{"groupRightScale","Whole group"},{"bossesScale","Boss schedule"},{"lairsScale","Guardians"},{"takenScale","Damage taken"},{"historyScale","Run history"},{"graphScale","DPS graph"},{"statsScale","Hero stats"},{"headLeft","Skill and jewelry pools","heading"},{"groupLeftScale","Whole group"},{"poolScale","Skill pool"},{"jewelPoolScale","Jewelry pool"},{"pickedEdgeSize","Picked items: edge thickness"},{"banishedScale","Banished cards"},{"ownScale","Own jewelry"},{"headNumbers","Numbers","heading"},{"risingFont","Rising damage: font"},{"risingHeight","Rising damage: how high"},{"risingScale","Rising damage: block"},{"targetRisingScale","Damage on the target"},{"skillStatsFont","Rank and DPS font"},{"headBars","Enemy bars","heading"},{"farRadius","Far bars: radius (yards)"},{"allyPlateWidth","Ally bar width (%)"},{"allyPlateHeight","Ally bar height"},{"plateFadeScale","Farthest bars: opacity"},{"metresFont","Metres font"},{"headOther","Other","heading"},{"mapPinSize","Minimap icons: size"},{"ownLevelFont","Hero level font"},{"totScale","Target of target"},{"chestScale","Chest icon"},{"allyScale","Ally skills and jewelry"}}},
    {key="player",title="Player frame",description="Player size, text placement, health formatting, portrait, colors and shields.",
        fields={{"scale","Frame scale"},{"width","Health / power width"},{"height","Frame height"},{"portrait","Portrait size"},{"powerHeight","Power bar height"},{"nameFont","Name font"},{"valueFont","Health font"},{"hideName","Hide Name","check"},{"healthArea","Health display area","select"},{"showPortrait","Show portrait","check"},{"healthText","Health text","select"},{"healthColor","Color health by injury","check"},{"showShield","Show shields","check"},{"shieldHeight","Shield strip height"},{"shieldFont","Shield text font"}}},
    {key="target",title="Target frame",description="Target size, text, health formatting, portrait, colors and shields.",
        fields={{"scale","Frame scale"},{"width","Health / power width"},{"height","Frame height"},{"portrait","Portrait size"},{"powerHeight","Power bar height"},{"nameFont","Name font"},{"valueFont","Health font"},{"showPortrait","Show portrait","check"},{"healthText","Health text","select"},{"healthColor","Color health by injury","check"},{"showShield","Show shields","check"},{"shieldHeight","Shield strip height"},{"shieldFont","Shield text font"}}},
    {key="action",title="Action buttons",description="Buttons 1 to 6 and =, including bonus/stance actions.",
        fields={{"scale","Bar scale"},{"size","Button size"},{"gap","Button spacing"},{"hotkeyFont","Keybind font"},{"cooldownFont","Cooldown numbers"},{"countFont","Item count font"}}},
    {key="auras",title="Player auras",description="Buff and debuff icons above the player frame.",
        fields={{"size","Icon size"},{"gap","Icon spacing"},{"timeFont","Duration font"},{"stackFont","Stack count font"}}},
    {key="debuffs",title="Target debuffs",description="Debuff icons above the target frame.",
        fields={{"size","Icon size"},{"gap","Icon spacing"},{"stackFont","Stack count font"}}},
    {key="xp",title="Experience bar",description="Independent experience strip width and height.",
        fields={{"width","Strip width"},{"height","Strip height"},{"gap","Space below row"}}},
    {key="minimap",title="Minimap",description="Borderless minimap with adjustable edge feathering.",
        fields={{"size","Map size"},{"scale","Map scale"},{"feather","Edge feathering (%)"}}},
    {key="chat",title="Chat",description="Chat window dimensions and text sizes.",
        fields={{"width","Chat width"},{"height","Chat height"},{"font","Message font"},{"tabFont","Tab font"},{"editScale","Input box scale"},{"editFont","Input box font"},{"backdropOpacity","Backdrop opacity"}}},
    {key="nameplates",title="Nameplates",description="Enemy plate visibility, collision, stacking, colors and text.",
        fields={{"enabled","Nameplates enable","check"},{"amount","Nameplate amount","select"},{"collision","Nameplate collision","check"},{"stacking","Nameplate stacking","check"},{"scale","Scale"},{"height","Height"},{"width","Width"},{"color","Bar color","color"},{"rankColors","Use rank colors","check"},{"showNames","Show names","check"},{"abbreviate","Abbreviate names","check"},{"nameFont","Name font size"},{"healthFont","Health font size"},{"healthText","Health text","select"}}},
    {key="micro",title="Micro buttons",description="Scale the fading buttons in the bottom-right corner.",
        fields={{"scale","Button scale"}}},
    {key="compassStyle",title="Compass",description="Heading strip and detected map markers.",
        fields={{"width","Strip width"},{"height","Strip height"},{"anchor","Anchor position","select"},{"scale","Strip scale"},{"fullWidth","Full screen width","check"},{"iconSize","Icon size"},{"labelFont","Label size"},{"compass","Show compass","check","root"}}},
     {key="dpsDisplay",title="DPS Meter",description="Automatic dimensions fit the current damage-source entries.",
        fields={{"backdropOpacity","Backdrop opacity"},{"autoWidth","Fit width to entries","check"},{"autoHeight","Fit height to entries","check"},{"width","Expanded width"},{"height","Expanded height"},{"scale","Panel scale"},{"dpsCollapsed","Expanded","check","root",true}}},
    {key="combatText",title="Combat text",description="Scrolling styles apply to icon combat text.",
        fields={{"damageMode","Damage text mode","select","root"},{"sctStyle","Scrolling text style","select","root"}}}
}
-- What most players reach for is shown first. Everything else waits behind "Show advanced", with its values kept.
local ADVANCED_SECTIONS={look=true,blocks=true,auras=true,debuffs=true,xp=true,micro=true,compassStyle=true,statsDisplay=true,runDisplay=true}
local COMMON_FIELDS={
    blocks={allyPlateWidth=1,allyPlateHeight=1,groupRightScale=1,groupLeftScale=1,mapPinSize=1,plateFadeScale=1,pickedEdgeSize=1,farRadius=1,bossesScale=1,lairsScale=1,takenScale=1,historyScale=1,poolScale=1,jewelPoolScale=1,banishedScale=1,risingFont=1,risingHeight=1},
    player={scale=1,width=1,height=1,healthText=1,healthArea=1},
    target={scale=1,width=1,height=1,healthText=1},
    action={scale=1,size=1,gap=1},
    chat={width=1,height=1,font=1,backdropOpacity=1},
    minimap={size=1,scale=1},
    nameplates={amount=1,scale=1,width=1,height=1,nameFont=1,healthFont=1},
    dpsDisplay={scale=1,backdropOpacity=1},
}
local function ShowingAdvanced() return C.Settings().showAdvanced==true end
-- The rows of a section as they are shown now.
local function ShownFields(category)
    local common=COMMON_FIELDS[category.key]
    if ShowingAdvanced() then return category.fields end
    if not common then
        local shown={}
        for _,field in ipairs(category.fields) do if not field.adv then table.insert(shown,field) end end
        return shown
    end
    local shown={}
    for _,field in ipairs(category.fields) do
        if common[field[1]] or field[3]=="group" or field[3]=="heading" then table.insert(shown,field) end
    end
    return shown
end
local selected=categories[1]
for _,category in ipairs(categories) do if category.key=="main" then selected=category end end
-- A tab's or a row's own words: Russian written beside the English, or else the shared table.
local function Words(item,english,russian)
    if russian then return nfUIEdit.Text(russian,english) end
    return nfUIEdit.L(english)
end
local ROW=54
local function SettingsCategory(key)
    if selected.key=="player" or selected.key=="target" then
        local style=selected.key.."Style"
        if C.defaults[style][key]~=nil then return style end
    end
    return selected.key
end
local function SelectedField(key)
    for _,field in ipairs(selected.fields) do if field[1]==key then return field end end
end
local function SelectedSettings(key)
    local field=SelectedField(key)
    return field and field[4]=="root" and C.Settings() or C.Settings()[SettingsCategory(key)]
end
-- A switch moved here from its own section still lives in that section's settings.
local function StoreOf(store)
    if store.root then return C.Settings() end
    return C.Settings()[store.category]
end
local function ReadValue(key)
    local field=SelectedField(key)
    if field and field[3]=="switch" then return nfUIEdit.On(key) end
    if field and field[3]=="cvar" then local on=GetCVar(key)=="1";if field.invert then return not on end;return on end
    -- A group's own switch is on while any of its members is.
    if field and field.keys then
        for _,member in ipairs(field.keys) do
            if C.Settings().edit[member]~=false then return true end
        end
        return false
    end
    if field and field.store then
        local value=StoreOf(field.store)[field.store.key]
        if field.store.invert then return not value end
        return value
    end
    local value=SelectedSettings(key)[key]
    if field and field[5] then return not value end
    return value
end
local function WriteValue(key,value)
    local field=SelectedField(key)
    if field and field[3]=="switch" then nfUIEdit.SetSwitch(key,value);if nfUIEdit.RefreshPools then nfUIEdit.RefreshPools() end;return end
    if field and field[3]=="cvar" then if field.invert then value=not value end;SetCVar(key,value and "1" or "0");return end
    if field and field.keys then
        for _,member in ipairs(field.keys) do C.Settings().edit[member]=value end
        return
    end
    local store=field and field.store
    if store then
        key=store.key
        if store.invert then value=not value end
        if key~="runCollapsed" and key~="dpsCollapsed" then StoreOf(store)[key]=value;return end
    elseif field and field[5] then value=not value end
    if key=="sctStyle" then C.SetSCTStyle(value)
    elseif key=="damageMode" then C.SetDamageMode(value)
    elseif key=="runCollapsed" then C.SetRunCollapsed(value)
    elseif key=="dpsCollapsed" then C.SetDPSCollapsed(value)
    else SelectedSettings(key)[key]=value end
end
local damageModes={"sct","quick","default","off"}
local damageLabels={sct="Icon combat text",quick="Compact damage labels",default="Native damage text",off="Disabled"}
local function ChoiceLabel(key,value)
    if key=="damageMode" then return damageLabels[value] end
    if key=="anchor" then return value=="TOP" and "Top Center" or "Bottom Center" end
    return value
end

local panel,content,rows,contentScroll
local resize
local rowCount=7
local scrollOffset=0
local buttons={}
local refreshing=false

local function Text(parent,text,x,y,size,color)
    local label=parent:CreateFontString(nil,"OVERLAY")
    label:SetFont(FONT,size or 12)
    if label.SetNonSpaceWrap then label:SetNonSpaceWrap(false) end
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    label:SetText(nfUIEdit.L(text))
    if color then label:SetTextColor(color[1],color[2],color[3]) else label:SetTextColor(0.85,0.87,0.9) end
    return label
end

local function Flat(parent,r,g,b,a)
    local fill=parent:CreateTexture(nil,"BACKGROUND")
    fill:SetTexture(FLAT); fill:SetVertexColor(r,g,b,a or 1); fill:SetAllPoints(parent)
    return fill
end

local function Button(name,parent,text,x,y,width,callback)
    local button=CreateFrame("Button",name,parent)
    button:SetWidth(width); button:SetHeight(28)
    button:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    button.back=Flat(button,0.13,0.15,0.19)
    button.label=Text(button,text,10,-7,12)
    button.SetText=function(self,value) self.label:SetText(nfUIEdit.L(value)) end
    button:SetHighlightTexture(FLAT)
    local highlight=button:GetHighlightTexture()
    if highlight then highlight:SetVertexColor(0.15,0.6,0.8,0.25) end
    button:SetScript("OnClick",callback)
    return button
end

local function Format(key,value)
    if key=="scale" or string.find(key,"Scale$") or key=="backdropOpacity" then return math.floor(value*100+0.5).."%" end
    return tostring(math.floor(value+0.5)).." px"
end

function C.Refresh()
    if not panel then return end
    refreshing=true
    local db=C.Settings()
    for key,button in pairs(buttons) do
        if key==selected.key then
            button.back:SetVertexColor(nfUIEdit.COLORS.surface[1],nfUIEdit.COLORS.surface[2],nfUIEdit.COLORS.surface[3],1)
            button.label:SetTextColor(nfUIEdit.COLORS.mauve[1],nfUIEdit.COLORS.mauve[2],nfUIEdit.COLORS.mauve[3])
        else
            button.back:SetVertexColor(nfUIEdit.COLORS.mantle[1],nfUIEdit.COLORS.mantle[2],nfUIEdit.COLORS.mantle[3],1)
            button.label:SetTextColor(nfUIEdit.COLORS.text[1],nfUIEdit.COLORS.text[2],nfUIEdit.COLORS.text[3])
        end
    end
    if not ShowingAdvanced() and ADVANCED_SECTIONS[selected.key] then selected=categories[1] end
    local shownFields=ShownFields(selected)
    content.title:SetText(Words(selected,selected.title,selected.ru))
    content.description:SetText(Words(selected,selected.description,selected.descRu))
    content:SetHeight(math.max(435,60+table.getn(shownFields)*ROW))
    if C.LayoutSidebar then C.LayoutSidebar() end
    if C.advancedButton then C.advancedButton:SetText(ShowingAdvanced() and "Hide advanced" or "Show advanced") end
    scrollOffset=math.min(scrollOffset,math.max(0,content:GetHeight()-contentScroll:GetHeight()/0.7))
    contentScroll:SetVerticalScroll(scrollOffset*0.7)
    for i=1,rowCount do
        local row=rows[i]
        local field=shownFields[i]
        if field then
            local key=field[1]
            row.key=key
            local lo,hi,step=C.Range(SettingsCategory(key),key)
            local label=field.store and field[2] or Words(field,field[2],field.ru)
            -- A switch set by hand over the mode says so, and "Reset section" gives it back.
            if field[3]=="switch" and nfUIEdit.SwitchChanged(key) then label=label.."  |cff8a8a96"..nfUIEdit.Text("изменено","changed").."|r" end
            row.label:SetText(label)
            row.desc:SetText(field.desc and nfUIEdit.Text(field.desc[1],field.desc[2]) or "")
            -- Beside a button the line would run under it, so it goes below the button there.
            local buttonRow=field[3]=="mode" or field[3]=="style" or field[3]=="textsize" or field[3]=="export" or field[3]=="update" or field[3]=="select" or field[3]=="color"
            row.desc:ClearAllPoints();row.desc:SetPoint("TOPLEFT",row,"TOPLEFT",0,buttonRow and -31 or -18)
            row.check:Hide(); row.choice:Hide(); row.menu:Hide(); row.slider:Hide(); row.value:Hide();row.color:Hide();row.action:Hide()
            local isTitle=field[3]=="group" or field[3]=="heading"
            local tint=isTitle and nfUIEdit.COLORS.mauve or {0.85,0.87,0.9}
            row.label:SetTextColor(tint[1],tint[2],tint[3])
            if field[3]=="heading" then
                -- A title only.
            elseif field[3]=="group" then
                row.check:SetChecked(ReadValue(key));row.check:Show()
            elseif field[3]=="style" then
                row.action:SetText((nfUIDB.layoutPreset=="classic" and nfUIEdit.Text("Классический","Classic") or nfUIEdit.Text("Современный","Modern")).."  >");row.action:Show()
            elseif field[3]=="textsize" then
                local now=nfUIEdit.TextSize()
                for _,size in ipairs(nfUIEdit.TEXT_SIZES) do if size[1]==now then row.action:SetText(nfUIEdit.Text(size[3],size[4]).."  >") end end
                row.action:Show()
            elseif field[3]=="mode" then
                row.action:SetText(nfUIEdit.ModeName().."  >");row.action:Show()
            elseif field[3]=="export" then
                row.action:SetText("Export");row.action:Show()
            elseif field[3]=="update" then
                row.label:SetText(nfUIEdit.L(field[2]).." "..(GetAddOnMetadata("nfUI","Version") or "?"))
                row.action:SetText("Check for updates");row.action:Show()
            elseif field[3]=="action" then
                row.action:SetText("Reset tracking");row.action:Show()
            elseif field[3]=="check" or field[3]=="switch" or field[3]=="cvar" then
                row.check:SetChecked(ReadValue(key)); row.check:Show()
            elseif field[3]=="select" then
                row.choiceValues=key=="sctStyle" and {"Explosive","Methodical","Biggest Hit"} or key=="damageMode" and damageModes or key=="amount" and {"Target","All","5 max","10 max"} or key=="anchor" and {"BOTTOM","TOP"} or key=="healthArea" and {"Left","Middle","Right"} or {"Percentage","CurrentHP+%","Numerical"}
                row.choice:SetText(ChoiceLabel(key,ReadValue(key))); row.choice:Show()
                row.menu:SetHeight(table.getn(row.choiceValues)*31+6)
                for index,item in ipairs(row.choiceItems) do
                    local value=row.choiceValues[index]
                    if value then item:SetText(ChoiceLabel(key,value)); item:Show() else item:Hide() end
                end
            elseif field[3]=="color" then
                local color=db[SettingsCategory(key)][key]
                row.color.back:SetVertexColor(color[1],color[2],color[3],1);row.color:Show()
            else
            row.slider:Show(); row.value:Show()
            row.slider:SetMinMaxValues(lo,hi); row.slider:SetValueStep(step)
            row.slider:SetValue(db[SettingsCategory(key)][key])
            row.value:RefreshNumber()
            getglobal(row.slider:GetName().."Low"):SetText(Format(key,lo))
            getglobal(row.slider:GetName().."High"):SetText(Format(key,hi))
            end
            row:Show()
        else row:Hide(); row.menu:Hide() end
    end
    refreshing=false
end

local function EditLayout()
    if C.ToggleMovers then
        panel:Hide()
        C.ToggleMovers()
    end
end

-- The game gives addons no network and no files, so checking and installing happen outside it:
-- this shows where the releases are and how to run the updater.
local RELEASES="https://github.com/Notker367/nfui-survivors-edit/releases"
-- And where to tell about a bug or an idea.
local ISSUES="https://github.com/Notker367/nfui-survivors-edit/issues"
local updates
function C.ShowUpdates()
    if not updates then
        updates=CreateFrame("Frame","nfUIUpdates",UIParent)
        updates:SetWidth(460);updates:SetHeight(196);updates:SetPoint("CENTER",UIParent,"CENTER",0,40)
        updates:SetFrameStrata("FULLSCREEN_DIALOG");updates:EnableMouse(true)
        Flat(updates,0.055,0.065,0.085)
        Text(updates,nfUIEdit.Text("\208\158\208\177\208\189\208\190\208\178\208\187\208\181\208\189\208\184\209\143","Updates"),14,-12,14,{0.3,0.82,1})
        local note=Text(updates,nfUIEdit.Text(
            "\208\152\208\179\209\128\208\176 \208\189\208\181 \208\180\208\176\209\145\209\130 \208\176\208\180\208\180\208\190\208\189\208\176\208\188 \208\178\209\139\209\133\208\190\208\180\208\176 \208\178 \209\129\208\181\209\130\209\140. \208\151\208\176\208\191\209\131\209\129\209\130\208\184\209\130\208\181 update-nfUI.bat \208\178 \208\191\208\176\208\191\208\186\208\181 \208\184\208\179\209\128\209\139 \208\184\208\187\208\184 \208\190\209\130\208\186\209\128\208\190\208\185\209\130\208\181 \209\129\209\129\209\139\208\187\208\186\209\131:",
            "The game gives addons no network access. Run update-nfUI.bat in the game folder, or open this link:"),14,-38,11)
        note:SetWidth(432);note:SetJustifyH("LEFT")
        local link=CreateFrame("EditBox","nfUIUpdatesLink",updates)
        link:SetWidth(432);link:SetHeight(22);link:SetPoint("TOPLEFT",updates,"TOPLEFT",14,-78)
        link:SetFont(FONT,11);link:SetAutoFocus(false);Flat(link,0.1,0.12,0.15)
        link:SetScript("OnEscapePressed",function() this:ClearFocus();updates:Hide() end)
        link:SetScript("OnTextChanged",function() if this:GetText()~=RELEASES then this:SetText(RELEASES);this:HighlightText() end end)
        updates.link=link
        Text(updates,nfUIEdit.Text("Отзывы, идеи и ошибки:","Feedback, ideas and bugs:"),14,-108,11)
        local issues=CreateFrame("EditBox","nfUIUpdatesIssues",updates)
        issues:SetWidth(432);issues:SetHeight(22);issues:SetPoint("TOPLEFT",updates,"TOPLEFT",14,-126)
        issues:SetFont(FONT,11);issues:SetAutoFocus(false);Flat(issues,0.1,0.12,0.15)
        issues:SetScript("OnEscapePressed",function() this:ClearFocus();updates:Hide() end)
        issues:SetScript("OnTextChanged",function() if this:GetText()~=ISSUES then this:SetText(ISSUES) end end)
        updates.issues=issues
        Button("nfUIUpdatesClose",updates,"Done",346,-156,100,function() updates:Hide() end)
        table.insert(UISpecialFrames,"nfUIUpdates")
    end
    updates:Show();updates.issues:SetText(ISSUES);updates.link:SetText(RELEASES);updates.link:SetFocus();updates.link:HighlightText()
end

-- Past runs as text, to select and copy.
local exportBox
function C.ShowExport()
    if not exportBox then
        exportBox=CreateFrame("Frame","nfUIExport",UIParent)
        exportBox:SetWidth(560);exportBox:SetHeight(110);exportBox:SetPoint("CENTER",UIParent,"CENTER",0,40)
        exportBox:SetFrameStrata("FULLSCREEN_DIALOG");exportBox:EnableMouse(true)
        Flat(exportBox,nfUIEdit.COLORS.base[1],nfUIEdit.COLORS.base[2],nfUIEdit.COLORS.base[3])
        Text(exportBox,nfUIEdit.Text("История забегов: выделите и скопируйте","Run history: select and copy"),14,-12,12,nfUIEdit.COLORS.mauve)
        local field=CreateFrame("EditBox","nfUIExportText",exportBox)
        field:SetWidth(532);field:SetHeight(22);field:SetPoint("TOPLEFT",exportBox,"TOPLEFT",14,-38)
        field:SetFont(FONT,11);field:SetAutoFocus(false);Flat(field,0.1,0.12,0.15)
        field:SetScript("OnEscapePressed",function() this:ClearFocus();exportBox:Hide() end)
        exportBox.field=field
        Button("nfUIExportClose",exportBox,"Done",446,-70,100,function() exportBox:Hide() end)
        table.insert(UISpecialFrames,"nfUIExport")
    end
    exportBox:Show();exportBox.field:SetText(nfUIEdit.ExportText());exportBox.field:SetFocus();exportBox.field:HighlightText()
end

-- Gathers each section's on and off choices into the Switches tab. The long list of character-sheet
-- stats stays in its own section.
local switchesMoved
local function MoveSwitches()
    if switchesMoved then return end
    switchesMoved=true
    local tab
    for _,category in ipairs(categories) do if category.key=="look" then tab=category end end
    for _,category in ipairs(categories) do
        if category~=tab and category.key~="statsDisplay" and category.key~="main" and category.key~="fight" and category.key~="build" and category.key~="run" then
            local kept={}
            for _,field in ipairs(category.fields) do
                if field[3]=="check" then
                    local owner=category.key
                    if (owner=="player" or owner=="target") and C.defaults[owner.."Style"][field[1]]~=nil then owner=owner.."Style" end
                    local label=string.gsub(field[2],"^Nameplates? ","")
                    table.insert(tab.fields,{category.key.."."..field[1],nfUIEdit.L(category.title)..": "..nfUIEdit.L(label),"check",
                        store={category=owner,key=field[1],root=field[4]=="root",invert=field[5]}})
                else table.insert(kept,field) end
            end
            category.fields=kept
        end
    end
end

local function Build()
    if panel then return end
    rows={}
    for _,category in ipairs(categories) do
        if category.key=="statsDisplay" and C.CharacterStatSections then
            for _,section in ipairs(C.CharacterStatSections) do
                for _,source in ipairs(section.rows) do
                    table.insert(category.fields,{C.StatSettingKey(source),source[1],"check"})
                end
            end
        end
    end
    MoveSwitches()
    for _,category in ipairs(categories) do rowCount=math.max(rowCount,table.getn(category.fields)) end
    panel=CreateFrame("Frame","nfUISettings",UIParent)
    -- Wider than before, so the words read at a normal size; a window kept from an earlier build grows once.
    local db=C.Settings()
    if not db.settingsWindowV2 then db.settingsWindowV2=true;db.settingsWindow=nil end
    local window=db.settingsWindow or {width=math.min(UIParent:GetWidth()-40,780),height=math.min(UIParent:GetHeight()-60,720)}
    panel:Hide(); panel:SetWidth(window.width); panel:SetHeight(window.height)
    panel:SetPoint("CENTER",UIParent,"CENTER",0,40)
    panel:SetFrameStrata("DIALOG"); panel:SetMovable(true); panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    Flat(panel,nfUIEdit.COLORS.base[1],nfUIEdit.COLORS.base[2],nfUIEdit.COLORS.base[3])
    panel:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
        insets={left=2,right=2,top=2,bottom=2}})
    panel:SetBackdropBorderColor(0.16,0.2,0.26,1)
    local body=CreateFrame("Frame","nfUISettingsBody",panel)
    body:SetPoint("TOPLEFT",panel,"TOPLEFT",0,0);body:SetWidth(594.1);body:SetHeight(555)
    local header=CreateFrame("Frame","nfUISettingsHeader",body)
    header:SetWidth(590.1); header:SetHeight(48); header:SetPoint("TOP",body,"TOP",0,-2)
    Flat(header,nfUIEdit.COLORS.mantle[1],nfUIEdit.COLORS.mantle[2],nfUIEdit.COLORS.mantle[3])
    Text(header,nfUIEdit.NAME,18,-14,16,nfUIEdit.COLORS.mauve)
    Text(header,"CONFIGURATION",170,-18,11)
    header:EnableMouse(true)
    header:SetScript("OnMouseDown",function() panel:StartMoving() end)
    header:SetScript("OnMouseUp",function() panel:StopMovingOrSizing() end)
    local sidebarScroll=CreateFrame("ScrollFrame","nfUISettingsSidebarScroll",body)
    sidebarScroll:SetWidth(165);sidebarScroll:SetHeight(439);sidebarScroll:SetPoint("TOPLEFT",body,"TOPLEFT",12,-61)
    local sidebar=CreateFrame("Frame",nil,sidebarScroll)
    sidebar:SetWidth(165); sidebar:SetHeight(439)
    sidebar:SetHeight(table.getn(categories)*28+10);sidebarScroll:SetScrollChild(sidebar)
    local sideOffset=0
    sidebarScroll:EnableMouseWheel(true)
    sidebarScroll:SetScript("OnMouseWheel",function()
        sideOffset=math.max(0,math.min(math.max(0,sidebar:GetHeight()-sidebarScroll:GetHeight()),sideOffset-(arg1 or 0)*28))
        sidebarScroll:SetVerticalScroll(sideOffset)
    end)
    Flat(sidebar,nfUIEdit.COLORS.mantle[1],nfUIEdit.COLORS.mantle[2],nfUIEdit.COLORS.mantle[3])
    for i,category in ipairs(categories) do
        local choice=category
        buttons[choice.key]=Button("nfUISettingsCategory"..i,sidebar,Words(choice,choice.title,choice.ru),4,-5-(i-1)*28,157,
            function() C.CancelNumberInputs(); selected=choice;scrollOffset=0;C.Refresh() end)
    end
    function C.LayoutSidebar()
        local shown=0
        for _,category in ipairs(categories) do
            local button=buttons[category.key]
            if ShowingAdvanced() or not ADVANCED_SECTIONS[category.key] then
                button:ClearAllPoints();button:SetPoint("TOPLEFT",sidebar,"TOPLEFT",4,-5-shown*28);button:Show();shown=shown+1
            else button:Hide() end
        end
    end
    C.advancedButton=Button("nfUISettingsAdvanced",header,"Show advanced",395,-10,180,function()
        C.Settings().showAdvanced=not ShowingAdvanced() or nil
        scrollOffset=0;C.Refresh()
    end)
    contentScroll=CreateFrame("ScrollFrame","nfUISettingsScroll",body)
    contentScroll:SetWidth(387.1);contentScroll:SetHeight(435);contentScroll:SetPoint("TOPLEFT",body,"TOPLEFT",192,-64)
    contentScroll:EnableMouseWheel(true)
    contentScroll:SetScript("OnMouseWheel",function()
        scrollOffset=math.max(0,math.min(math.max(0,content:GetHeight()-contentScroll:GetHeight()/0.7),scrollOffset-(arg1 or 0)*ROW))
        contentScroll:SetVerticalScroll(scrollOffset*0.7)
    end)
    content=CreateFrame("Frame",nil,contentScroll)
    content:SetScale(0.7)
    content:SetWidth(553);content:SetHeight(445);content:SetPoint("TOPLEFT",contentScroll,"TOPLEFT",0,0)
    contentScroll:SetScrollChild(content)
    content.title=Text(content,"",0,0,17,{0.93,0.94,0.96})
    content.description=Text(content,"",0,-27,11)
    content.description:SetWidth(535);content.description:SetHeight(16);content.description:SetJustifyH("LEFT")
    for i=1,rowCount do
        local option=CreateFrame("Frame","nfUISettingsOption"..i,content)
        rows[i]=option
        option:SetWidth(535); option:SetHeight(48)
        option:SetPoint("TOPLEFT",content,"TOPLEFT",0,-60-(i-1)*ROW)
        option.label=Text(option,"",0,0,13)
        option.desc=Text(option,"",0,-18,11,{0.62,0.64,0.7});option.desc:SetWidth(480);option.desc:SetJustifyH("LEFT")
        option.value=C.CreateNumberInput("nfUISettingsInput"..i,option,86,20,{
            get=function() return SelectedSettings(option.key)[option.key] end,
            percent=function() return option.key=="scale" or string.find(option.key or "","Scale$") or option.key=="backdropOpacity" end,
            range=function() return C.Range(SettingsCategory(option.key),option.key) end,
            set=function(value)
                SelectedSettings(option.key)[option.key]=value
                if selected.key=="compassStyle" and option.key=="width" then C.Settings().compassStyle.fullWidth=false end
                C.Apply(); C.Refresh()
            end})
        option.value:SetPoint("TOPRIGHT",option,"TOPRIGHT",0,4)
        local slider=CreateFrame("Slider","nfUISettingsSlider"..i,option,"OptionsSliderTemplate")
        option.slider=slider
        slider:SetWidth(510); slider:SetHeight(16)
        slider:SetPoint("TOPLEFT",option,"TOPLEFT",2,-20)
        getglobal(slider:GetName().."Text"):SetText("")
        option.check=CreateFrame("CheckButton","nfUISettingsCheck"..i,option,"UICheckButtonTemplate")
        option.check:SetWidth(24); option.check:SetHeight(24)
        option.check:SetPoint("TOPRIGHT",option,"TOPRIGHT",-15,0)
        option.check:SetScript("OnClick",function()
            if refreshing or not option.key then return end
            WriteValue(option.key,this:GetChecked() and true or false)
            local store=SelectedField(option.key).store
            if store and store.category=="nameplates" then
                local settings=C.Settings().nameplates
                if store.key=="stacking" and settings.stacking then settings.collision=true end
                if store.key=="collision" and not settings.collision then settings.stacking=false end
            end
            C.Apply(); C.Refresh()
        end)
        option.action=Button("nfUISettingsAction"..i,option,"",235,0,275,function()
            if option.key=="resetRun" then nfUI_ResetRun();C.Refresh()
            elseif option.key=="updates" then C.ShowUpdates()
            elseif option.key=="mode" then nfUIEdit.CycleMode()
            elseif option.key=="style" then nfUIEdit.ApplyLayout(nfUIDB.layoutPreset=="classic" and "mine" or "classic");C.Refresh()
            elseif option.key=="textSize" then
                local sizes,now,nextSize=nfUIEdit.TEXT_SIZES,nfUIEdit.TextSize(),nil
                for index,size in ipairs(sizes) do if size[1]==now then nextSize=sizes[math.mod(index,table.getn(sizes))+1][1] end end
                nfUIEdit.SetTextSize(nextSize or "normal");C.Refresh()
            elseif option.key=="export" then C.ShowExport() end
        end)
        option.choice=Button("nfUISettingsChoice"..i,option,"",235,0,275,function()
            if option.menu:IsShown() then option.menu:Hide() else option.menu:Show() end
        end)
        option.menu=CreateFrame("Frame","nfUISettingsChoiceMenu"..i,option)
        option.menu:SetWidth(275); option.menu:SetHeight(100)
        option.menu:SetPoint("TOPLEFT",option.choice,"BOTTOMLEFT",0,0)
        option.menu:SetFrameStrata("FULLSCREEN_DIALOG")
        option.menu:SetFrameLevel(option:GetFrameLevel()+20)
        Flat(option.menu,0.06,0.09,0.13)
        option.choiceItems={}
        for index,value in ipairs({"Percentage","CurrentHP+%","Numerical","10 max"}) do
            local choiceIndex=index
            option.choiceItems[index]=Button("nfUISettingsChoice"..i.."Item"..index,option.menu,value,3,-3-(index-1)*31,269,function()
                WriteValue(option.key,option.choiceValues[choiceIndex])
                if selected.key=="player" and option.key=="healthArea" then
                    local positions=C.Settings().positions
                    if positions then positions.playerValue=nil;positions.playerName=nil end
                end
                if selected.key=="compassStyle" and option.key=="anchor" then
                    local db=C.Settings(); if db.positions then db.positions.compass=nil end
                end
                C.Apply(); C.Refresh(); option.menu:Hide()
            end)
        end
        option.color=Button("nfUISettingsColor"..i,option,"Choose color",235,0,275,function()
            if not ColorPickerFrame then return end
            local category,key=SettingsCategory(option.key),option.key
            local old=C.Settings()[category][key];local previous={old[1],old[2],old[3]}
            local previousRank=category=="nameplates" and C.Settings().nameplates.rankColors
            local function Commit(color)
                C.Settings()[category][key]={color[1],color[2],color[3]}
                if category=="nameplates" then C.Settings().nameplates.rankColors=false end
                C.Apply();C.Refresh()
            end
            ColorPickerFrame:Hide();ColorPickerFrame.hasOpacity=false
            ColorPickerFrame.func=function() local r,g,b=ColorPickerFrame:GetColorRGB();Commit({r,g,b}) end
            ColorPickerFrame.cancelFunc=function()
                Commit(previous)
                if category=="nameplates" then C.Settings().nameplates.rankColors=previousRank;C.Apply();C.Refresh() end
            end
            ColorPickerFrame:SetColorRGB(previous[1],previous[2],previous[3]);ColorPickerFrame:Show()
        end)
        option.menu:Hide()

        slider:SetScript("OnValueChanged",function()
            if refreshing then return end
            C.CancelNumberInputs()
            local key=option.key
            if not key then return end
            local lo,hi,step=C.Range(SettingsCategory(key),key)
            local value=this:GetValue()
            value=lo+math.floor((value-lo)/step+0.5)*step
            value=math.max(lo,math.min(hi,value))
            SelectedSettings(key)[key]=value
            if selected.key=="compassStyle" and key=="width" then C.Settings().compassStyle.fullWidth=false end
            C.Apply(); C.Refresh()
        end)
    end
    local footer=CreateFrame("Frame",nil,body)
    footer:SetScale(570.1/736)
    footer:SetWidth(736); footer:SetHeight(40); footer:SetPoint("BOTTOM",body,"BOTTOM",0,10)
    Flat(footer,0.075,0.085,0.11)
    Button("nfUISettingsMove",footer,"Movers",7,-6,115,EditLayout)
    Button("nfUISettingsReset",footer,"Reset section",130,-6,124,function()
        if selected.key=="compassStyle" then C.Settings().compass=true
        elseif selected.key=="runDisplay" then C.Settings().runPanel=true;C.SetRunCollapsed(true)
        elseif selected.key=="dpsDisplay" then C.SetDPSCollapsed(true)
        elseif selected.key=="combatText" then C.SetDamageMode("quick");C.SetSCTStyle("Explosive")
        elseif selected.key=="main" or selected.key=="fight" or selected.key=="build" or selected.key=="run" or selected.key=="look" then
            for _,field in ipairs(selected.fields) do if field[3]=="switch" then nfUIEdit.ResetSwitch(field[1]) end end
            if nfUIEdit.RefreshPools then nfUIEdit.RefreshPools() end
            for _,field in ipairs(selected.fields) do
                local store=field.store
                if store and not store.root then C.Settings()[store.category][store.key]=C.defaults[store.category][store.key] end
            end
        end
        C.ResetSection(selected.key);C.Refresh()
    end)
    -- Everything goes back at once, so the first click only asks; a second within a few seconds does it.
    local resetAll
    resetAll=Button("nfUISettingsResetAll",footer,"Reset all",262,-6,105,function()
        if not resetAll.armed or GetTime()-resetAll.armed>4 then
            resetAll.armed=GetTime();resetAll:SetText(nfUIEdit.Text("Точно?","Sure?"))
            resetAll:SetScript("OnUpdate",function() if GetTime()-(resetAll.armed or 0)>4 then resetAll.armed=nil;resetAll:SetText("Reset all");resetAll:SetScript("OnUpdate",nil) end end)
            return
        end
        resetAll.armed=nil;resetAll:SetText("Reset all");resetAll:SetScript("OnUpdate",nil)
        C.Settings().compass=true;C.Settings().runPanel=true
        C.SetRunCollapsed(true);C.SetDPSCollapsed(true);C.SetDamageMode("quick");C.SetSCTStyle("Explosive")
        C.ResetAll();C.Refresh()
    end)
    Button("nfUISettingsRuns",footer,"Run analysis",375,-6,132,function() if nfUIEdit.ToggleRunReport then panel:Hide();nfUIEdit.ToggleRunReport() end end)
    Button("nfUISettingsDone",footer,"Done",625,-6,100,function() panel:Hide() end)
    Text(footer,"Saved automatically",514,-13,10)
    local function LayoutWindow()
        local factor=panel:GetWidth()/594.1
        body:SetScale(factor);body:SetHeight(panel:GetHeight()/factor)
        contentScroll:SetHeight(math.max(60,body:GetHeight()-120))
        sidebarScroll:SetHeight(math.max(60,body:GetHeight()-116))
        sideOffset=math.min(sideOffset,math.max(0,sidebar:GetHeight()-sidebarScroll:GetHeight()));sidebarScroll:SetVerticalScroll(sideOffset)
        scrollOffset=math.min(scrollOffset,math.max(0,content:GetHeight()-contentScroll:GetHeight()/0.7));contentScroll:SetVerticalScroll(scrollOffset*0.7)
    end
    C.ResizeSettings=function(width,height)
        panel:SetWidth(math.max(480,math.min(UIParent:GetWidth(),width)))
        panel:SetHeight(math.max(320,math.min(UIParent:GetHeight(),height)))
        C.Settings().settingsWindow={width=panel:GetWidth(),height=panel:GetHeight()}
        LayoutWindow()
    end
    local grip=CreateFrame("Button","nfUISettingsResizeGrip",panel)
    grip:SetWidth(24);grip:SetHeight(24);grip:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-2,2)
    grip:SetFrameLevel(panel:GetFrameLevel()+30)
    local mark=grip:CreateFontString(nil,"OVERLAY");mark:SetFont(FONT,12);mark:SetText("///");mark:SetPoint("CENTER",grip,"CENTER",0,0);mark:SetTextColor(0.3,0.82,1)
    grip:SetScript("OnMouseDown",function()
        if arg1~="LeftButton" then return end
        C.CancelNumberInputs()
        local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
        local left,top=panel:GetLeft(),panel:GetTop()
        if left and top then panel:ClearAllPoints();panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top) end
        resize={x=x,y=y,width=panel:GetWidth(),height=panel:GetHeight(),scale=scale}
    end)
    grip:SetScript("OnMouseUp",function() resize=nil end)
    grip:SetScript("OnEnter",function() GameTooltip:SetOwner(grip,"ANCHOR_TOP");GameTooltip:AddLine(nfUIEdit.L("Drag to resize settings"),0.3,0.82,1);GameTooltip:Show() end)
    grip:SetScript("OnLeave",function() GameTooltip:Hide() end)
    panel:SetScript("OnUpdate",function()
        if not resize then return end
        local x,y=GetCursorPosition()
        C.ResizeSettings(resize.width+(x-resize.x)/resize.scale,resize.height-(y-resize.y)/resize.scale)
    end)
    LayoutWindow()
    panel:SetScript("OnShow",function() C.Apply(); C.Refresh() end)
    panel:SetScript("OnHide",function()
        resize=nil
        for _,option in ipairs(rows) do option.menu:Hide() end
    end)
    table.insert(UISpecialFrames,"nfUISettings")
    C.panel=panel
    C.SelectedCategory=function() return selected.key end
end

function C.Toggle()
    Build()
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

SLASH_NFUI1="/nfui"
SlashCmdList["NFUI"]=C.Toggle


function C.OpenCategory(key)
    if key=="playerStyle" then key="player" elseif key=="targetStyle" then key="target" elseif key=="edit" then key="main" end
    Build()
    C.CancelNumberInputs();scrollOffset=0
    for _,category in ipairs(categories) do if category.key==key then selected=category end end
    if ADVANCED_SECTIONS[selected.key] or (COMMON_FIELDS[selected.key]==nil and selected.key~="layout" and selected.key~="combatText" and selected.key~="main" and selected.key~="fight" and selected.key~="build" and selected.key~="run") then C.Settings().showAdvanced=true end
    panel:Show(); C.Refresh()
end
