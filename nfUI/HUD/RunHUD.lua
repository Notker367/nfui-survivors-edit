-- Run data and layout are separate. The saved header corner stays fixed while the panel expands upward.
local C=nfUIConfig
local FONT=NFUI_FONT
C.defaults.runDisplay={width=206,height=320,scale=1,font=11,backdrop=true}
local range=C.Range
C.Range=function(category,key)
    if category=="runDisplay" then
        if key=="width" then return 140,800,1 end
        if key=="height" then return 100,UIParent:GetHeight(),1 end
        if key=="scale" then return 0.5,2,0.01 end
        if key=="font" then return 8,28,1 end
    end
    return range(category,key)
end
-- The panel itself is removed in this edit; the settings window still calls these.
function C.SetRunCollapsed() end
function nfUI_ResetRun() end
function nfUI_ToggleRun() end
