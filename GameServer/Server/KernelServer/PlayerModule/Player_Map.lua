-- global enum
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local CPlayer = ClassRequire("CPlayer")
local CMapManager = SingletonRequire("CMapManager")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
local CCompeMateManager = SingletonRequire("CCompeMateManager")
local CDataLog = SingletonRequire("CDataLog")

-- 主地图配置Id
local __MainMapCfgId = 1

function CPlayer:InitMapData(i_nMapCfgID)
    local nMapCfgID = i_nMapCfgID or __MainMapCfgId
    -- print("--InitMapData--", nMapCfgID)
    local oMap = CMapManager:GetOneMapByCfgId(nMapCfgID)
    self.m_tNextMapInfo = {
        oMap:GetInstID(),
        nMapCfgID
    }
end
function CPlayer:SetNextMapInfo(i_oMap)
    print("--SetNextMapInfo--", i_oMap:GetInstID(), i_oMap:GetMapCfgID())
    self.m_tNextMapInfo = {
        i_oMap:GetInstID(),
        i_oMap:GetMapCfgID()
    }
end
function CPlayer:GetMapCfgID()
    return 0
end
function CPlayer:GetMap()
    return self.m_oMap
end
function CPlayer:IsInGame()
    return self:GetState() == KSPlayerStateEnum.eInGame
end
-- 玩家进入游戏
function CPlayer:EnterGame(i_bLogin, i_bIsNew)
    if i_bLogin and not self:IsInCommonMap() then
        self:LeaveMap()
        self:InitMapData()
    end
    --只进入KS放开注释
    self:SetState(KSPlayerStateEnum.eInGame)
    print("--EnterGame--", i_bLogin, i_bIsNew)
    -- self:SendToClient("C_EnterMap", __MainMapCfgId)
    self:EnterMap()
end

function CPlayer:SetCommonMapInfo(i_nMapCfgID)
    local oMap = CMapManager:GetOneMapByCfgId(i_nMapCfgID)
    self.m_tCommonMapInfo = {oMap:GetInstID(), i_nMapCfgID}
end
-- 进入地图
function CPlayer:EnterMap()
    local oMap = CMapManager:GetMapByInstID(self.m_tNextMapInfo[1])
    local nMapCfgID = self.m_tNextMapInfo[2]
    if not oMap then
        print("=====ERROR!!!!===oMap is nil==========")
        print("====ERROR!!!!===nMapCfgID==========", nMapCfgID)
        print("=====nMapInstID==========", self.m_tNextMapInfo[1])
        return
    end
    oMap:Order()
    self.m_oMap = oMap
    self.m_oMap:OnPlayerEnter(self)
    self.m_oSystemMgr:OnEnterMap(nMapCfgID)
    self:SendToClient("C_EnterMap", self.m_tNextMapInfo[2])
    -- delog("KS player entermap ", self.m_sRoleID, self.m_tNextMapInfo[1], self.m_tNextMapInfo[2])
end
function CPlayer:LeaveMap()
    if self.m_oMap then
        self.m_oMap:OnPlayerLeave(self)
        self.m_oMap = nil
    end
end

function CPlayer:LeaveCurMap()
    self:InitMapData()
    self:EnterMap()
end

function CPlayer:SwitchMap(i_oMap)
    local nState = self:GetState()
    delog("CPlayer:SwitchMap Done")
end

-- 请求进入实例ID地图
function CPlayer:EnterInstMap(i_nMapInstID)
    return CMapManager:EnterInstMap(i_nMapInstID, {self})
end
-- 请求进入配置ID地图
function CPlayer:EnterCfgMap(i_nMapCfgID, i_nLineID, bol)
    if not self.m_oMap then
        print("WARNING!!! player not in map.", self:GetRoleID())
        return
    end
    local oMap
    if i_nLineID then
        oMap = CMapManager:GetoneMapByCfgIdLineId(i_nMapCfgID, i_nLineID)
    else
        oMap = CMapManager:GetOneMapByCfgId(i_nMapCfgID)
    end
    if oMap then
        return self:EnterInstMap(oMap:GetInstID())
    end
    delog("CPlayer:EnterCfgMap ERROR")
end

function CPlayer:RequestGoBack()
    if self:IsInCommonMap() then
        self:GoBackMainMap()
    end
end

function CPlayer:IsInCommonMap()
    return self.m_oMap and CMapManager:IsCommon(self.m_oMap:GetMapCfgID())
end

-- 退出场景消息()
defineS.K_LeaveMapMsg = function(i_oPlayer)
    if i_oPlayer:IsInCommonMap() then
        return
    end
    i_oPlayer:LeaveCurMap()
end

-- 客户端请求进入场景
defineC.K_EnterCfgMap = function(i_oPlayer, i_nMapCfgID, i_nLineID)
    i_oPlayer:EnterCfgMap(i_nMapCfgID, i_nLineID)
end

-- 客户端请求回主场景
defineC.K_GoBackMainMapReq = function(i_oPlayer)
    i_oPlayer:RequestGoBack()
end

-- 玩家离开游戏
function CPlayer:LeaveGame()
    delog("CPlayer:LeaveGame")
    self:LeaveMap()
    CCompeMateManager:OnPlayerLeaveGame(self)
    self:LeaveGameComplete()

    if not self:IsR() then
        CDataLog:LogDistAccount_log(self:GetAccountID(), self:GetRoleID(), 0)
    end
end

-- 玩家销毁、下线
function CPlayer:LeaveGameComplete()
    self:Destroy()
end
