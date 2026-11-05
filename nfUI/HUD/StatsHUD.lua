-- Persistent character stats use the same native values and sections as the character pane.
local C=nfUIConfig
local sections=C.CharacterStatSections or {}
local FONT=NFUI_FONT
C.defaults.statsDisplay={width=210,height=340,scale=1,font=11,valueFont=11,headingFont=12,backdrop=true,headings=true}
function C.StatSettingKey(source) return "stat_"..source[1] end
for _,section in ipairs(sections) do
    for _,source in ipairs(section.rows) do
        C.defaults.statsDisplay[C.StatSettingKey(source)]=source[1]~="Health" and source[1]~="Lives"
    end
end
local range=C.Range
C.Range=function(category,key)
    if category=="statsDisplay" then
        if key=="width" then return 160,600,1 end
        if key=="height" then return 100,UIParent:GetHeight(),1 end
        if key=="headingFont" or key=="valueFont" or key=="font" then return 6,40,1 end
    end
    return range(category,key)
end
