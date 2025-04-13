-- global config

-- global function
local print = print
local logfile = logfile
local pairs = pairs
local ProtectedCall = ProtectedCall
local table_insert = table.insert
-- local
local CMap = ClassRequire("CMap")

function CMap:_constructor(i_nCfgID, i_nInstID, i_oManager, i_tAppendInfo, i_oObserver, i_bOccupy)
    self.m_nCfgID = i_nCfgID
    self.m_nInstID = i_nInstID
    self.m_nLineID = 1
    self.m_bOccupy = i_bOccupy
    self.m_oManager = i_oManager
    self.m_tCfg = ConfigExtend.GetMapCfg_Id(i_nCfgID)
    self.m_oObserver = i_oObserver
    self.m_tPlayerSet = {}
    self.m_tPlayerRoleIdSet = {}
    self.m_nPlayerNum = 0
    self.m_nOrderNum = 0
end

function CMap:Destruct()
    -- clear state by the time not enough can not enter
    self.m_bCanNotEnter = nil
    -- clear player
    for _, oPlayer in pairs(self.m_tPlayerRoleIdSet) do
        oPlayer:LeaveCurMap()
    end
    -- notice observer
    if self.m_oObserver then
        self.m_oObserver:OnMapDestruct(self.m_tReport, self)
    end
end

function CMap:Update(i_nDeltaMsec)
end

function CMap:Destroy(i_tReport)
    self.m_tReport = i_tReport
    self.m_oManager:DestroyMap(self.m_nInstID)
end
function CMap:GetMapCfgID()
    return self.m_nCfgID
end

function CMap:GetInstID()
    return self.m_nInstID
end

function CMap:GetPlayerNum()
    return self.m_nPlayerNum
end

function CMap:GetMapOccupy()
    return self.m_bOccupy
end
function CMap:SetMapOccupy(i_bOccupy)
    self.m_bOccupy = i_bOccupy
end

function CMap:SetGroupInfo(i_oMapGroup, i_nLineID)
    self.m_oGroup = i_oMapGroup
    self.m_nLineID = i_nLineID
end

function CMap:GetLineID()
    return self.m_nLineID
end

function CMap:GetLineNum()
    return self.m_oGroup and self.m_oGroup:GetLineNum() or 0
end

function CMap:GetMapByLineID(i_nLineID)
    return self.m_oGroup and self.m_oGroup:GetMapByLineID(i_nLineID)
end

function CMap:OnPlayerEnter(i_oPlayer)
    self:CancelOrder()
    if self.m_oObserver then
        ProtectedCall(
            function()
                self.m_oObserver:OnPlayerEnterMap(self, i_oPlayer)
            end
        )
    end

	if not self.m_tPlayerRoleIdSet[i_oPlayer:GetRoleID()] then
        self.m_nPlayerNum = self.m_nPlayerNum + 1
	end
	self.m_tPlayerRoleIdSet[i_oPlayer:GetRoleID()] = i_oPlayer
end

function CMap:OnPlayerLeave(i_oPlayer)
    if self.m_oObserver then
        ProtectedCall(
            function()
                self.m_oObserver:OnPlayerLeaveMap(self, i_oPlayer)
            end
        )
    end
    if self.m_tPlayerRoleIdSet[i_oPlayer:GetRoleID()] then
        self.m_tPlayerRoleIdSet[i_oPlayer:GetRoleID()] = nil
        self.m_nPlayerNum = self.m_nPlayerNum - 1
    end
end

function CMap:OnPlayerIsInMap(i_oPlayer)
    if self.m_tPlayerRoleIdSet[i_oPlayer:GetRoleID()] then
        return true
    end
    return false
end

function CMap:Order()
    self.m_nOrderNum = self.m_nOrderNum + 1
    -- print("---order number--", self.m_nOrderNum)
end

function CMap:CancelOrder()
    self.m_nOrderNum = self.m_nOrderNum - 1
    if self.m_nOrderNum < 0 then
        print("WARNING!!! KS map order num < 0", self.m_nOrderNum)
    end
    -- print("---order number--", self.m_nOrderNum)
end

function CMap:GetOrderNum()
    return self.m_nOrderNum
end

function CMap:GetPlayer(i_sRoleId)
    return self.m_tPlayerRoleIdSet[i_sRoleId]
end

function CMap:GetAllPlayer()
    local temp = {}
    for _, oPlayer in pairs(self.m_tPlayerRoleIdSet) do
        table_insert(temp, oPlayer)
    end
    return temp
end

function CMap:SendToAllPlayer(i_sMsg, ...)
    for _, oPlayer in pairs(self.m_tPlayerRoleIdSet) do
        oPlayer:SendToClient(i_sMsg, ...)
    end
end

function CMap:BroadcastToAllClient()
    -- local tPlayer
end

-- 设置场景剩余时间不足不能进入的标志
function CMap:SetCanNotEnter()
    self.m_bCanNotEnter = true
end

function CMap:GetCanNotEnter()
    return self.m_bCanNotEnter
end
