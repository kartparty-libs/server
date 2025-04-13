-- global function
local pairs = pairs
local ipairs = ipairs
local print = print
local logfile = logfile
local type = type
local now = _commonservice.now
local math_floor = math.floor
local table_insert = table.insert
local string_format = string.format
local string_gmatch = string.gmatch
local table_concat = table.concat
local ClassNew = ClassNew
local ProtectedCall = ProtectedCall
local CPlayerManager = SingletonRequire("CPlayerManager")
local CMapManager = SingletonRequire("CMapManager")
local MapTypeEnum = RequireEnum("MapTypeEnum")

local VariableEum = {
    RoomId = 1,
    MapId = 2,
    PlayerNum = 3,
    PlayerInfo = 4,
    MateAddRobotTime = 5,
    RobotNum = 6,
    Track = 7,
    LineMaxPlayerNum = 8,
    MateStartTime = 9
}

local PlayerInfoEum = {
    RoldId = 1,
    Name = 2,
    TrackIdx = 3,
    PlayerCfgId = 4,
    CarCfgId = 5,
    RobotMasterRoleId = 6,
    Head = 7,
    IsRoomOwner = 8,
    IsReady = 9
}

local MatchMapCfgId = 2

local CCompeMateManager = SingletonRequire("CCompeMateManager")
function CCompeMateManager:Initialize()
    self.m_nRoomMaxInstId = 0 --匹配房间最大实例Id
    self.m_tUseRoomMap = {} --使用中的地图
    self.m_tMateRoom = {} --正在匹配的房间
    self.m_tMateRoomNum = {} --正在匹配的房间数量
    self.m_nMateTime = ConfigExtend.GetMapCfg_Time(MatchMapCfgId) --匹配倒计时
    self.m_nMateStartTime = ConfigExtend.GetMapCfg_EndTime(MatchMapCfgId) --匹配人满开始倒计时

    self.m_nRobotMaxInstId = 0 --机器人最大实例Id
    self.m_nRobotNameMaxId = #ConfigExtend.GetNicknameCfg() -- 机器人随机名字最大数量

    local MapCfg = ConfigExtend.GetMapCfg()
    for mapid, cfg in pairs(MapCfg) do
        if cfg.SceneType ~= MapTypeEnum.eCommon then
            self.m_tMateRoom[mapid] = {}
            self.m_tMateRoomNum[mapid] = 0
        end
    end

    return true
end

function CCompeMateManager:Destruct()
end

local interval = 800
local update = interval
function CCompeMateManager:Update(i_nDeltaTime)
    update = update - i_nDeltaTime
    if update > 0 then
        return
    end

    -- 分配机器人
    for mapCfgId, mateRoomList in pairs(self.m_tMateRoom) do
        for roomId, mateRoom in pairs(mateRoomList) do
            if mateRoom[VariableEum.MateStartTime] ~= 0 then
                if mateRoom[VariableEum.MateStartTime] <= now() then
                    self:InToCompeMap(mateRoom)
                end
            elseif mateRoom[VariableEum.MateAddRobotTime] ~= 0 and mateRoom[VariableEum.MateAddRobotTime] < now() then
                local bRobot = ConfigExtend.GetMapCfg_IsRobot(mateRoom[VariableEum.MapId])
                if bRobot then
                    local nRandom = math.random(1, 100)
                    if nRandom < 30 then
                        local nNum = mateRoom[VariableEum.PlayerNum] + mateRoom[VariableEum.RobotNum]
                        local nAddNum = ConfigExtend.GetMapCfg_LineMaxPlayerNum(mateRoom[VariableEum.MapId]) - nNum

                        local tPlayer = {}
                        for k, v in pairs(mateRoom[VariableEum.PlayerInfo]) do
                            if v[PlayerInfoEum.RobotMasterRoleId] == 0 then
                                table_insert(tPlayer, k)
                            end
                        end
                        local nPlayerNum = #tPlayer

                        if nAddNum ~= 0 and nPlayerNum ~= 0 then
                            if nAddNum > 2 and math.random(1, 100) < 10 then
                                nAddNum = 2
                            else
                                nAddNum = 1
                            end

                            for i = 1, nAddNum do
                                local idx = (nNum + 1) % nPlayerNum
                                if idx == 0 then
                                    idx = nPlayerNum
                                end

                                local nRoleCfgId = math.random(1, #ConfigExtend.GetRoleCfg())
                                local nCarCfgId = math.random(1, #ConfigExtend.GetCarCfg())
                                local nHead = math.random(1, #ConfigExtend.GetHeadCfg())

                                local oPlayer = CPlayerManager:GetPlayerByRoleID(tPlayer[idx])
                                if oPlayer then
                                    self:AddRobot(oPlayer, nRoleCfgId, nCarCfgId, nHead)
                                end
                            end
                        end
                    end

                    if mateRoom[VariableEum.RobotNum] > 1 and nRandom > 30 and nRandom < 35 then
                        local tRobot = {}
                        for k, v in pairs(mateRoom[VariableEum.PlayerInfo]) do
                            if v[PlayerInfoEum.RobotMasterRoleId] ~= 0 then
                                table_insert(tRobot, k)
                            end
                        end
                        if #tRobot > 0 then
                            local nRandomIdx = math.random(1, #tRobot)
                            local nRobotRoleId = tRobot[nRandomIdx]
                            self:EndMateCompe(nil, nRobotRoleId)
                        end
                    end
                end
            end
        end
    end

    update = interval
end

--获取新的房间ID
function CCompeMateManager:GetNewRoomID()
    self.m_nRoomMaxInstId = self.m_nRoomMaxInstId + 1
    return self.m_nRoomMaxInstId
end

-- 获取房间下一个赛道Id
function CCompeMateManager:GetNextTrackIdx(tMateRoom, i_sRoleId)
    for i = 1, tMateRoom[VariableEum.LineMaxPlayerNum] do
        if tMateRoom[VariableEum.Track][i] == nil then
            tMateRoom[VariableEum.Track][i] = i_sRoleId
            return i
        end
    end
    return tMateRoom[VariableEum.LineMaxPlayerNum]
end

-- 获取玩家所在的房间信息
function CCompeMateManager:GetPlayerRoom(i_sRoleId)
    local tMateRoom
    for mapCfgId, mateRoomList in pairs(self.m_tMateRoom) do
        for roomId, mateRoom in pairs(mateRoomList) do
            if mateRoom[VariableEum.PlayerInfo][i_sRoleId] then
                tMateRoom = mateRoom
                break
            end
        end
    end
    return tMateRoom
end

-- 创建房间
function CCompeMateManager:CreateRoom(i_nMapCfgId)
    local tMateRoom = {}
    tMateRoom[VariableEum.RoomId] = self:GetNewRoomID()
    tMateRoom[VariableEum.MapId] = i_nMapCfgId
    tMateRoom[VariableEum.PlayerInfo] = {}
    tMateRoom[VariableEum.PlayerNum] = 0
    tMateRoom[VariableEum.RobotNum] = 0
    tMateRoom[VariableEum.MateAddRobotTime] = 0
    tMateRoom[VariableEum.Track] = {}
    tMateRoom[VariableEum.LineMaxPlayerNum] = ConfigExtend.GetMapCfg_LineMaxPlayerNum(i_nMapCfgId)
    tMateRoom[VariableEum.MateStartTime] = 0

    self.m_tMateRoom[i_nMapCfgId][tMateRoom[VariableEum.RoomId]] = tMateRoom
    self.m_tMateRoomNum[i_nMapCfgId] = self.m_tMateRoomNum[i_nMapCfgId] + 1

    print("===============> CreateRoom -> MapCfgId = " .. i_nMapCfgId .. " RoomId = " .. tMateRoom[VariableEum.RoomId])
    return tMateRoom
end

-- 删除房间
function CCompeMateManager:RemoveRoom(tMateRoom)
    local nMapId = tMateRoom[VariableEum.MapId]
    local nRoomId = tMateRoom[VariableEum.RoomId]
    self.m_tMateRoom[nMapId][nRoomId] = nil
    self.m_tMateRoomNum[nMapId] = self.m_tMateRoomNum[nMapId] - 1
    print("===============> RemoveRoom -> MapCfgId = " .. nMapId .. " RoomId = " .. nRoomId)
end

-- 获取匹配中的房间
function CCompeMateManager:GetMateingRoom(i_nMapCfgId)
    local tMapMateRoom = self.m_tMateRoom[i_nMapCfgId]
    for k, room in pairs(tMapMateRoom) do
        if room[VariableEum.MateStartTime] == 0 then
            return room
        end
    end
    return nil
end

--开始匹配比赛
function CCompeMateManager:StartMateCompe(i_oPlayer, i_nMapCfgId, i_nRoleCfgId, i_nCarCfgId)
    local sRoleId = i_oPlayer:GetRoleID()
    local sName = i_oPlayer:GetName()
    local tMateRoom = self:GetPlayerRoom(sRoleId)
    if not tMateRoom then
        local bRobot = ConfigExtend.GetMapCfg_IsRobot(i_nMapCfgId)
        if bRobot then
            local nWinNum = i_oPlayer:GetSystem("CTaskSystem"):GetTaskData(10)[2]
            local nFlagNum = 0
            if nWinNum >= 5 and nWinNum < 7 then
                nFlagNum = 2
            elseif nWinNum >= 7 and nWinNum < 10 then
                nFlagNum = 5
            elseif nWinNum >= 10 then
                nFlagNum = 9
            end
            local nRandomNum = math.random(1, 10)
            bRobot = nRandomNum >= nFlagNum
        end
        if bRobot then
            tMateRoom = self:CreateRoom(i_nMapCfgId)
        else
            tMateRoom = self:GetMateingRoom(i_nMapCfgId)
            if not tMateRoom then
                tMateRoom = self:CreateRoom(i_nMapCfgId)
            end
        end
    end

    if tMateRoom[VariableEum.PlayerInfo][sRoleId] == nil then
        local nTrackIdx = self:GetNextTrackIdx(tMateRoom, sRoleId)
        local pBasicInfoSystem = i_oPlayer:GetSystem("CBasicInfoSystem")
        local nPlayerCfgId = pBasicInfoSystem:GetPlayerCfgId()
        local nCarCfgId = pBasicInfoSystem:GetCarCfgId()
        local nHead = pBasicInfoSystem:GetHead()
        local nIsRoomOwner = 0
        local nIsReady = 1
        if tMateRoom[VariableEum.PlayerNum] == 0 then
            nIsRoomOwner = 1
            nIsReady = 1
        end
        tMateRoom[VariableEum.PlayerInfo][sRoleId] = {
            sRoleId,
            sName,
            nTrackIdx,
            nPlayerCfgId,
            nCarCfgId,
            0,
            nHead,
            nIsRoomOwner,
            nIsReady
        }
        tMateRoom[VariableEum.PlayerNum] = tMateRoom[VariableEum.PlayerNum] + 1
    -- print("===============> PlayerEnterMap -> MapCfgId = " .. i_nMapCfgId .. " RoomId = " .. tMateRoom[VariableEum.RoomId] .. " CurrPlayerNum = " .. tMateRoom[VariableEum.PlayerNum])
    end

    i_oPlayer:SendToClient("C_StartMateCompe", tMateRoom)

    self:BroadcastRoomPlayerInfo(tMateRoom, sRoleId)
    self:CheckMateRoomStartGame(tMateRoom)
end

--取消匹配比赛
function CCompeMateManager:EndMateCompe(i_oPlayer, i_nRobotRoleId)
    local sRoleId
    if not i_oPlayer and i_nRobotRoleId then
        sRoleId = i_nRobotRoleId
    else
        sRoleId = i_oPlayer:GetRoleID()
    end

    local tMateRoom = self:GetPlayerRoom(sRoleId)
    if not tMateRoom then
        return
    end

    local tPlayerInfo = tMateRoom[VariableEum.PlayerInfo][sRoleId]
    local nTrackIdx = tPlayerInfo[PlayerInfoEum.TrackIdx]

    if i_nRobotRoleId then
        tMateRoom[VariableEum.RobotNum] = tMateRoom[VariableEum.RobotNum] - 1
    else
        tMateRoom[VariableEum.PlayerNum] = tMateRoom[VariableEum.PlayerNum] - 1
        if tMateRoom[VariableEum.PlayerNum] > 0 then
            if tPlayerInfo[PlayerInfoEum.IsRoomOwner] == 1 then
                local sChangeRoleId = next(tMateRoom[VariableEum.PlayerInfo])
                tMateRoom[VariableEum.PlayerInfo][sChangeRoleId][PlayerInfoEum.IsRoomOwner] = 1
                tMateRoom[VariableEum.PlayerInfo][sChangeRoleId][PlayerInfoEum.IsReady] = 1
                self:BroadcastRoomPlayerInfo(tMateRoom, sChangeRoleId)
            end
        end
    end
    tMateRoom[VariableEum.Track][nTrackIdx] = nil
    tMateRoom[VariableEum.PlayerInfo][sRoleId] = nil
    tMateRoom[VariableEum.MateStartTime] = 0

    self:BroadcastRoomPlayerQuit(tMateRoom, sRoleId)

    if tMateRoom[VariableEum.PlayerNum] <= 0 then
        self:RemoveRoom(tMateRoom)
    end
end

-- 添加机器人
function CCompeMateManager:AddRobot(i_oPlayer, i_nRoleCfgId, i_nCarCfgId, i_nHead)
    local sRoleId = i_oPlayer:GetRoleID()
    local tMateRoom = self:GetPlayerRoom(sRoleId)
    if tMateRoom == nil then
        return
    end

    if tMateRoom[VariableEum.MateStartTime] ~= 0 then
        return
    end

    local sRobotRoleId = "Robot" .. self.m_nRobotMaxInstId
    local sRobotName = math.random(1, self.m_nRobotNameMaxId) .. "+" .. math.random(1, self.m_nRobotNameMaxId)
    self.m_nRobotMaxInstId = self.m_nRobotMaxInstId + 1
    if tMateRoom[VariableEum.PlayerInfo][sRobotRoleId] == nil then
        local nTrackIdx = self:GetNextTrackIdx(tMateRoom, sRobotRoleId)
        tMateRoom[VariableEum.PlayerInfo][sRobotRoleId] = {
            sRobotRoleId,
            sRobotName,
            nTrackIdx,
            i_nRoleCfgId,
            i_nCarCfgId,
            sRoleId,
            i_nHead,
            0,
            1
        }
        tMateRoom[VariableEum.RobotNum] = tMateRoom[VariableEum.RobotNum] + 1
    -- print("===============> RobotEnterMap -> MapCfgId = " .. tMateRoom[VariableEum.MapId] .. " RoomId = " .. tMateRoom[VariableEum.RoomId] .. " CurrRobotNum = " .. tMateRoom[VariableEum.RobotNum])
    end

    self:BroadcastRoomPlayerInfo(tMateRoom, sRobotRoleId)
    self:CheckMateRoomStartGame(tMateRoom)
end

-- 玩家准备通知
function CCompeMateManager:PlayerReadyMateCompe(i_oPlayer)
    local sRoleId = i_oPlayer:GetRoleID()
    local tMateRoom = self:GetPlayerRoom(sRoleId)
    if tMateRoom == nil then
        return
    end

    local tPlayerInfo = tMateRoom[VariableEum.PlayerInfo][sRoleId]
    if tPlayerInfo ~= nil and tPlayerInfo[PlayerInfoEum.IsReady] == 0 then
        tPlayerInfo[PlayerInfoEum.IsReady] = 1
        self:BroadcastRoomPlayerInfo(tMateRoom, sRoleId)
    end
end

-- 房主开始游戏通知
function CCompeMateManager:RoomOwnerStartMateCompe(i_oPlayer)
    local sRoleId = i_oPlayer:GetRoleID()
    local tMateRoom = self:GetPlayerRoom(sRoleId)
    if tMateRoom == nil then
        return
    end

    if tMateRoom[VariableEum.MateAddRobotTime] == 0 then
        tMateRoom[VariableEum.MateAddRobotTime] = now() + self.m_nMateTime
    end
end

-- 检测匹配房间开始游戏
function CCompeMateManager:CheckMateRoomStartGame(tMateRoom)
    local nNum = tMateRoom[VariableEum.PlayerNum] + tMateRoom[VariableEum.RobotNum]

    if nNum >= tMateRoom[VariableEum.LineMaxPlayerNum] then
        tMateRoom[VariableEum.MateStartTime] = now() + self.m_nMateStartTime
    end
end

-- 通知房间玩家信息改变
function CCompeMateManager:BroadcastRoomPlayerInfo(i_tMateRoom, i_sRoleId)
    for sRoleID, _ in pairs(i_tMateRoom[VariableEum.PlayerInfo]) do
        local oPlayer = CPlayerManager:GetPlayerByRoleID(sRoleID)
        if oPlayer then
            oPlayer:SendToClient("C_RoomPlayerInfoChange", i_tMateRoom, i_sRoleId)
        end
    end
end

-- 通知房间玩家退出
function CCompeMateManager:BroadcastRoomPlayerQuit(i_tMateRoom, i_sRoleId)
    for sRoleID, _ in pairs(i_tMateRoom[VariableEum.PlayerInfo]) do
        local oPlayer = CPlayerManager:GetPlayerByRoleID(sRoleID)
        if oPlayer then
            oPlayer:SendToClient("C_RoomPlayerQuit", i_sRoleId)
        end
    end
end

-- 进入比赛地图
function CCompeMateManager:InToCompeMap(i_tMateRoom)
    -- print("===============> InToCompeMap -> RoomId = " .. i_tMateRoom[VariableEum.RoomId])
    for k, v in pairs(CMapManager:GetInstID2Map()) do
        print("===============> InToCompeMap -> m_tInstID2Map = ", v:GetMapCfgID(), v:GetPlayerNum())
    end
    local oMap = CMapManager:GetOneMapByCfgId(i_tMateRoom[VariableEum.MapId])
    oMap:Init()
    oMap:SetMapOccupy(true)
    for sRoleID, _ in pairs(i_tMateRoom[VariableEum.PlayerInfo]) do
        local oPlayer = CPlayerManager:GetPlayerByRoleID(sRoleID)
        if oPlayer then
            if not oPlayer:IsInCommonMap() then
                oPlayer:LeaveMap()
            end
            oPlayer:SendToClient("C_StartMateCompeComplete")
            oPlayer:SetNextMapInfo(oMap)
            oPlayer:EnterMap()
        end
    end
    -- self.m_tUseRoomMap[i_tMateRoom[VariableEum.RoomId]] = oMap
    self:RemoveRoom(i_tMateRoom)
end

function CCompeMateManager:OnPlayerLeaveGame(i_oPlayer)
    CCompeMateManager:EndMateCompe(i_oPlayer)
end

---------------------------------------------------------------------------------------------------------------------
-- 开始匹配比赛
defineC.K_StartMateCompe = function(i_oPlayer, i_nMapCfgId, i_nRoleCfgId, i_nCarCfgId)
    CCompeMateManager:StartMateCompe(i_oPlayer, i_nMapCfgId, i_nRoleCfgId, i_nCarCfgId)
end

-- 结束匹配比赛
defineC.K_EndMateCompe = function(i_oPlayer)
    CCompeMateManager:EndMateCompe(i_oPlayer)
end

-- 玩家准备通知
defineC.K_PlayerReadyMateCompe = function(i_oPlayer)
    CCompeMateManager:PlayerReadyMateCompe(i_oPlayer)
end

-- 房主开始游戏通知
defineC.K_RoomOwnerStartMateCompe = function(i_oPlayer)
    CCompeMateManager:RoomOwnerStartMateCompe(i_oPlayer)
end

-- 测试添加机器人
defineC.K_TestAddRobot = function(i_oPlayer, i_nRoleCfgId, i_nCarCfgId, i_nHead)
    CCompeMateManager:AddRobot(i_oPlayer, i_nRoleCfgId, i_nCarCfgId, i_nHead)
end
