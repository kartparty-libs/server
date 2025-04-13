--[[
	@brief	比赛场景
	@author	tm
]]
local now = _commonservice.now
local CCompetitionMap = ClassRequire("CCompetitionMap")
local TaskEventEnum = RequireEnum("TaskEventEnum")
local CDataLog = SingletonRequire("CDataLog")
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")

local CompetitionMapState = {
    ReadyGame = 1, -- 准备游戏
    StartGame = 2, -- 开始游戏
    EndGame = 3 -- 结束游戏
}

--场景初始化
function CCompetitionMap:_constructor(i_nCfgID, i_nInstID, i_oManager, i_tAppendInfo, i_oObserver, i_bOccupy)
    CCompetitionMap._super._constructor(self, i_nCfgID, i_nInstID, i_oManager, i_tAppendInfo, i_oObserver, i_bOccupy)
end

function CCompetitionMap:Init()
    -- 游戏状态
    self.m_eGameState = 0
    -- 加载地图玩家信息
    self.m_tMapLoadPlayer = {}
    -- 加载地图完成玩家数量
    self.m_nMapLoadPlayerNum = 0
    -- 完成比赛玩家信息
    self.m_tEndGamePlayer = {}
    -- 比赛开始时间
    self.m_nStartTime = 0
    -- 比赛结束时间
    self.m_nEndTime = 0
    -- 强制开始游戏时间
    self.m_nLoadMapCompleteTime = 0
    -- 地图最大玩家数量
    self.m_nLineMaxPlayerNum = ConfigExtend.GetMapCfg_LineMaxPlayerNum(self.m_nCfgID)

    self:ReadyGame()
end

--场景刷新
function CCompetitionMap:Update(i_nDeltaMsec)
    CCompetitionMap._super.Update(self, i_nDeltaMsec)
    if not self:GetMapOccupy() then
        return
    end
    if self.m_nLoadMapCompleteTime ~= 0 and self.m_nMapLoadPlayerNum > 0 and self.m_nLoadMapCompleteTime < now() then
        self:StartGame()
    end
    if self.m_nEndTime ~= 0 and self.m_nEndTime < now() then
        self:EndGame()
    end
end

-- 玩家进入
function CCompetitionMap:PlayerEnter(i_oPlayer)
    CCompetitionMap._super.PlayerEnter(self, i_oPlayer)
end

-- 踢出地图
function CCompetitionMap:LeaveMap()
    local tbPlayer = self:GetAllPlayer()
    for _, oPlayer in pairs(tbPlayer) do
        if oPlayer then
            oPlayer:LeaveMap()
            oPlayer:InitMapData()
        end
    end
    self:SetMapOccupy(false)
end

-- 玩家离开
function CCompetitionMap:OnPlayerLeave(i_oPlayer)
    CCompetitionMap._super.OnPlayerLeave(self, i_oPlayer)

    print("===============> OnPlayerLeave Player = " .. i_oPlayer:GetRoleID() .. " PlayerNum = " .. self.m_nPlayerNum .. " mapid = " .. self.m_nInstID)
    if self.m_nPlayerNum == 0 then
        self:SetMapOccupy(false)
        self:Init()
        print("===============> OnPlayerLeave MapOccupy = false")
    end
end

-- 准备游戏
function CCompetitionMap:ReadyGame()
    if self.m_eGameState == CompetitionMapState.ReadyGame then
        return
    end
    self.m_eGameState = CompetitionMapState.ReadyGame

    self:SendToAllPlayer("C_CompetitionGameState", self.m_eGameState)
end

-- 开始游戏
function CCompetitionMap:StartGame()
    if self.m_eGameState == CompetitionMapState.StartGame then
        return
    end
    self.m_eGameState = CompetitionMapState.StartGame
    self.m_nLoadMapCompleteTime = 0
    self.m_nStartTime = now() + 3000
    self.m_nEndTime = self.m_nStartTime + ConfigExtend.GetMapCfg_Time(self.m_nCfgID)
    self:SendToAllPlayer("C_CompetitionGameState", self.m_eGameState)

    -- 触发任务
    local tPlayer = self:GetAllPlayer()
    for i, player in ipairs(tPlayer) do
        player:GetSystem("CTaskSystem"):TriggerTaskEventAddValue(TaskEventEnum.ePlayMap, 1, {self.m_nCfgID})
    end

    -- print("===============> StartGame")
end

-- 结束游戏
function CCompetitionMap:EndGame()
    if self.m_eGameState == CompetitionMapState.EndGame then
        return
    end
    self.m_eGameState = CompetitionMapState.EndGame

    self:SendToAllPlayer("C_CompetitionGameState", self.m_eGameState)

    self:LeaveMap()
end

-- 加载地图完成
function CCompetitionMap:SyncPlayerLoadMapComplete(i_oPlayer)
    self.m_tMapLoadPlayer[i_oPlayer:GetRoleID()] = 1
    self.m_nMapLoadPlayerNum = self.m_nMapLoadPlayerNum + 1
    self.m_nLoadMapCompleteTime = now() + 10000
    -- print("===============> SyncPlayerLoadMapComplete -> RoleID = " .. i_oPlayer:GetRoleID() .. " MapLoadPlayerNum = " .. self.m_nMapLoadPlayerNum .. " PlayerNum = " .. self.m_nPlayerNum)

    if not i_oPlayer:IsR() then
        CDataLog:LogDistMap_log(i_oPlayer:GetAccountID(), i_oPlayer:GetRoleID(), self.m_nCfgID, 0, 0)
    end
    
    if self.m_eGameState == CompetitionMapState.StartGame then
        i_oPlayer:SendToClient("C_CompetitionGameState", self.m_eGameState)
    elseif self.m_nMapLoadPlayerNum >= self.m_nPlayerNum then
        self:StartGame()
    end
end

-- 同步玩家状态
function CCompetitionMap:SyncPlayerStateInfo(i_oPlayer, i_tState)
    for _, oPlayer in pairs(self.m_tPlayerRoleIdSet) do
        if oPlayer:GetState() == KSPlayerStateEnum.eInGame then
            oPlayer:SendToClient("C_PlayerStateInfo", i_tState)
        end
    end
end

-- 同步完成比赛
function CCompetitionMap:PlayerCompleteGame(i_oPlayer, i_nTime, i_sRobotRoleId, i_sRobotName)
    if #self.m_tEndGamePlayer == 0 then
        local nEndTime = ConfigExtend.GetMapCfg_EndTime(self.m_nCfgID)
        if self.m_nEndTime - now() > nEndTime then
            self.m_nEndTime = now() + nEndTime
        end
    end

    local roleId = i_oPlayer:GetRoleID()
    local name = i_oPlayer:GetName()
    local time = 0

    -- 做临时兼容 有机会修正
    if i_nTime ~= nil and type(i_nTime) == "number"  then
        time = i_nTime
    end

    if i_nTime ~= nil and type(i_nTime) == "string" and i_sRobotRoleId ~= nil and type(i_sRobotRoleId) == "string" then
        roleId = i_nTime
        name = i_sRobotRoleId
    elseif i_nTime ~= nil and type(i_nTime) == "number" and i_sRobotRoleId ~= nil and type(i_sRobotRoleId) == "string" and i_sRobotName ~= nil and type(i_sRobotName) == "string" then
        roleId = i_sRobotRoleId
        name = i_sRobotName
    end

    -- if i_sRobotRoleId and i_sRobotName then
    --     roleId = i_sRobotRoleId
    --     name = i_sRobotName
    -- end

    local tInfo = {
        [1] = now() - self.m_nStartTime,
        [2] = roleId,
        [3] = name,
        [4] = self.m_nEndTime - now()
    }
    table.insert(self.m_tEndGamePlayer, tInfo)

    local nRank = #self.m_tEndGamePlayer
    if nRank >= self.m_nLineMaxPlayerNum then
        if self.m_nEndTime - now() > 3000 then
            self.m_nEndTime = now() + 3000
        end
    end

    self:SendToAllPlayer("C_CompleteGamePlayerInfo", tInfo)

    -- 触发任务
    if i_sRobotRoleId == nil then
        i_oPlayer:GetSystem("CTaskSystem"):TriggerTaskEventAddValue(TaskEventEnum.eAccomplishGame, 1)
        if nRank == 1 then
            i_oPlayer:GetSystem("CTaskSystem"):TriggerTaskEventAddValue(TaskEventEnum.eChampionship, 1)
        end
    end

    if not i_oPlayer:IsR() and i_sRobotRoleId == nil then
        CDataLog:LogDistMap_log(i_oPlayer:GetAccountID(), i_oPlayer:GetRoleID(), self.m_nCfgID, nRank, time)
    end
end

---------------------- 消息专区 -------------------------

-- 加载地图完成
defineC.K_PlayerLoadMapCompleteReq = function(i_oPlayer)
    if i_oPlayer:GetState() == KSPlayerStateEnum.eInGame and i_oPlayer:GetMap() and not i_oPlayer:IsInCommonMap() then
        i_oPlayer:GetMap():SyncPlayerLoadMapComplete(i_oPlayer)
    end
end

-- 同步状态
defineC.K_PlayerStateInfoReq = function(i_oPlayer, i_tState)
    if i_oPlayer:GetState() == KSPlayerStateEnum.eInGame and i_oPlayer:GetMap() and not i_oPlayer:IsInCommonMap() then
        if i_oPlayer:GetMap():OnPlayerIsInMap(i_oPlayer) then
            i_oPlayer:GetMap():SyncPlayerStateInfo(i_oPlayer, i_tState)
        end
    end
end

-- 同步完成比赛
defineC.K_PlayerCompleteGame = function(i_oPlayer, i_nTime, i_sRobotRoleId, i_sRobotName)
    if i_oPlayer:GetState() == KSPlayerStateEnum.eInGame and i_oPlayer:GetMap() and not i_oPlayer:IsInCommonMap() then
        i_oPlayer:GetMap():PlayerCompleteGame(i_oPlayer, i_nTime, i_sRobotRoleId, i_sRobotName)
    end
end

-- 玩家离开比赛地图
defineC.K_PlayerLeaveMapReq = function(i_oPlayer)
    if i_oPlayer:GetState() == KSPlayerStateEnum.eInGame and i_oPlayer:GetMap() and not i_oPlayer:IsInCommonMap() then
        i_oPlayer:LeaveMap()
    end
end
