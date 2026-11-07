-- The edit's movable blocks. They are made here, before the movers load, so each can be dragged, locked and
-- resized like any other panel. Each starts beside the frame it belongs to and at that frame's scale.
local E,C=nfUIEdit,nfUIConfig
local function Block(name,width,height,point,anchor,relative,x,y)
    local frame=CreateFrame("Frame",name,UIParent)
    frame:SetWidth(width);frame:SetHeight(height);frame:SetPoint(point,anchor,relative,x,y);frame:Hide()
    return frame
end
local tot=Block("nfUITargetOfTarget",194,13,"TOPLEFT",C.target,"BOTTOMLEFT",0,-7)
-- Two groups that move and scale as one. A panel dragged by itself (Movers > Details) leaves its group.
local rightGroup=Block("nfUIGroupRight",200,472,"TOPRIGHT",Minimap,"BOTTOMRIGHT",0,-30);rightGroup:Show()
local leftGroup=Block("nfUIGroupLeft",357,190,"BOTTOMLEFT",ChatFrame1,"TOPLEFT",-9,70);leftGroup:Show()
E.blocks={
    tot=tot,
    chest=Block("nfUIChestReady",24,24,"LEFT",C.player,"RIGHT",6,0),
    own=Block("nfUIOwnPanel",194,20,"TOPLEFT",C.row,"BOTTOMLEFT",0,-27),
    ally=Block("nfUIAllyPanel",194,20,"TOPLEFT",tot,"BOTTOMLEFT",0,-4),
    rising=Block("nfUIRisingAnchor",60,16,"BOTTOM",C.player.health,"TOP",0,40),
    banished=Block("nfUIBanished",190,38,"TOPRIGHT",Minimap,"TOPLEFT",-8,-44),
    bosses=Block("nfUIBossSchedule",200,94,"TOPRIGHT",rightGroup,"TOPRIGHT",0,0),
}
E.blocks.lairs=Block("nfUILairPanel",200,80,"TOPRIGHT",E.blocks.bosses,"BOTTOMRIGHT",0,-6)
E.blocks.taken=Block("nfUITakenPanel",200,94,"TOPRIGHT",E.blocks.lairs,"BOTTOMRIGHT",0,-6)
E.blocks.history=Block("nfUIHistoryPanel",200,108,"TOPRIGHT",E.blocks.taken,"BOTTOMRIGHT",0,-6)
E.blocks.graph=Block("nfUIDpsGraph",200,70,"TOPRIGHT",E.blocks.history,"BOTTOMRIGHT",0,-6)
E.blocks.stats=Block("nfUIHeroStats",150,160,"TOPRIGHT",E.blocks.bosses,"TOPLEFT",-6,0)
E.blocks.rising:Show()
E.blocks.targetRising=Block("nfUITargetRising",60,16,"BOTTOM",C.target.health,"TOP",0,40)
E.blocks.targetRising:Show()
-- The two pools stand over the chat and its input, as wide as the chat, below the party frames.
E.blocks.jewelPool=Block("nfUIJewelPool",357,63,"BOTTOMLEFT",leftGroup,"BOTTOMLEFT",0,0)
E.blocks.pool=Block("nfUIPoolPanel",336,63,"BOTTOMLEFT",E.blocks.jewelPool,"TOPLEFT",0,17)
-- Mover key, label, block, the frame its size follows, and its slider in the Blocks tab.
E.blockList={
    {"blockTot","Target of target",E.blocks.tot,C.target,"totScale"},
    {"blockChest","Chest icon",E.blocks.chest,C.player,"chestScale"},
    {"blockOwn","Own jewelry",E.blocks.own,C.row,"ownScale"},
    {"blockPool","Skill pool",E.blocks.pool,C.row,"poolScale"},
    {"blockAlly","Ally skills and jewelry",E.blocks.ally,C.target,"allyScale"},
    {"blockRising","Rising damage",E.blocks.rising,C.player,"risingScale"},
    {"blockTargetRising","Damage on the target",E.blocks.targetRising,C.target,"targetRisingScale"},
    {"blockJewelPool","Jewelry pool",E.blocks.jewelPool,C.row,"jewelPoolScale"},
    {"blockBanished","Banished cards",E.blocks.banished,C.row,"banishedScale"},
    {"blockBosses","Boss schedule",E.blocks.bosses,C.row,"bossesScale"},
    {"blockLairs","Guardians",E.blocks.lairs,C.row,"lairsScale"},
    {"blockTaken","Damage taken",E.blocks.taken,C.row,"takenScale"},
    {"blockHistory","Run history",E.blocks.history,C.row,"historyScale"},
    {"blockGraph","DPS graph",E.blocks.graph,C.row,"graphScale"},
    {"blockStats","Hero stats",E.blocks.stats,C.row,"statsScale"},
}
table.insert(E.blockList,{"blockGroupRight","Right panels",rightGroup,C.row,"groupRightScale"})
table.insert(E.blockList,{"blockGroupLeft","Skill and jewelry pools",leftGroup,C.row,"groupLeftScale"})
-- Which group each panel belongs to.
E.GROUP_OF={blockBosses="groupRightScale",blockLairs="groupRightScale",blockTaken="groupRightScale",blockHistory="groupRightScale",blockGraph="groupRightScale",blockStats="groupRightScale",blockPool="groupLeftScale",blockJewelPool="groupLeftScale"}
function E.SyncBlocks()
    local sizes=C.Settings().blocks
    for _,block in ipairs(E.blockList) do
        local fit=1
        -- On a narrow screen the pools are smaller, so that they do not reach the hero's frame.
        if (block[1]=="blockPool" or block[1]=="blockJewelPool") and UIParent:GetWidth()/UIParent:GetEffectiveScale()<1250 then fit=0.75 end
        local inGroup=E.GROUP_OF[block[1]]
        block[3]:SetScale(block[4]:GetScale()*(tonumber(sizes[block[5]]) or 1)*fit*(inGroup and tonumber(sizes[inGroup]) or 1))
    end
end
-- While the movers are open a block stays visible, so that it can be grabbed.
function E.Conceal(frame)
    if C.editing then frame:Show() else frame:Hide() end
end
function E.Size(key,fallback)
    local db=type(nfUIDB)=="table" and nfUIDB.blocks
    return db and tonumber(db[key]) or fallback
end
