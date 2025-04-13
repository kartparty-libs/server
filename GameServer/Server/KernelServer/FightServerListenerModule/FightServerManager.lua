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
local CJSON = SingletonRequire("CJSON")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local CCommonFunction = SingletonRequire("CCommonFunction")

local CFightServerManager = SingletonRequire("CFightServerManager")
function CFightServerManager:Initialize()
    self.m_tSession2FightServer = {}
    self.m_tFightServer2Id = {}
    self.m_nSessionNum = 0
    self.m_nFightServerNum = 0
    self.m_nFightServerId = 0
    self.m_nFreeFightServer = nil
    self.m_tUseRoom = {}
    self.m_tFreeRoom = {}
    self.m_nRoomId = 0
    return true
end

function CFightServerManager:Destruct()
    -- self.m_nDestructTime = now(1)
    -- for _, player in pairs(self.m_tSession2Player) do
    -- 	player:BeKick(PlayerBeKickReasonEnum.eServerShutdown)
    -- end
end

function CFightServerManager:OnServiceRegist(i_pSession, sip, nip)
    self.m_nFightServerId = self.m_nFightServerId + 1
    local oFightServer = ClassNew("CFightServer", i_pSession, sip, nip, self.m_nFightServerId)
    self.m_tSession2FightServer[i_pSession] = oFightServer
    self.m_tFightServer2Id[self.m_nFightServerId] = oFightServer
    self.m_nSessionNum = self.m_nSessionNum + 1
    self.m_nFreeFightServer = oFightServer
    print("FightServer enter session num:", self.m_nSessionNum, sip, i_pSession)
end

function CFightServerManager:GetServerBySession(i_pSession)
    return self.m_tSession2FightServer[i_pSession]
end

function CFightServerManager:DeleteFightServer(i_oFightServer)
    local sServerID = i_oFightServer:GetServerID()
    if sServerID then
        self.m_tFightServer2Id[sServerID] = nil
    end
    print("FightServer leave num:", i_oFightServer:GetIp())
end

function CFightServerManager:Disconnect(i_pSession, i_sErrStr)
    local oFightServer = self.m_tSession2FightServer[i_pSession]
    self.m_tSession2FightServer[i_pSession] = nil
    oFightServer:OnDisconnect()
    self.m_nSessionNum = self.m_nSessionNum - 1
    print("FightServer leave session num:", self.m_nSessionNum, oFightServer:GetIp(), i_pSession, i_sErrStr)
end

--创建游戏房间
function CFightServerManager:CreatGameRoom(i_tRoleId)
    local nRoomId = self:GetFreeRoomID()
    self.m_nFreeFightServer:CreatGameRoom(nRoomId, i_tRoleId)
    self.m_tUseRoom[nRoomId] = self.m_nFreeFightServer:GetServerID()
    return nRoomId
end

--删除游戏房间
function CFightServerManager:DestroyGameRoom(i_nRoomId)
    local oFightServer = self.m_tFightServer2Id[self.m_tUseRoom[i_nRoomId]]
    self.m_nFreeFightServer:DestroyGameRoom(i_nRoomId)
    table.insert(self.m_tFreeRoom, i_nRoomId)
end

--获取空的房间ID
function CFightServerManager:GetFreeRoomID()
    if #self.m_tFreeRoom > 0 then
        local nRoomId = self.m_tFreeRoom[1]
        table.remove(self.m_tFreeRoom, 1)
        return nRoomId
    else
        self.m_nRoomId = self.m_nRoomId + 1
        return self.m_nRoomId
    end
end

--心跳包收发
defineF.K_HeartBeat = function(i_oFightServer)
    i_oFightServer:SendToFightServer("F_HeartBeat")
end

--房间创建成功回调
defineF.K_CreatGameSuccess = function(i_oFightServer, i_nRoomId)
    local rr = 1
    -- i_oFightServer:SendToFightServer("C_HeartBeat");
end

defineF.K_DestroyRoomSuccess = function(i_oFightServer, i_nRoomId)
    local rr = 1
    -- i_oFightServer:SendToFightServer("C_HeartBeat");
end

-- --ping包收发
-- defineC.K_Ping = function(i_oPlayer)
--     i_oPlayer:SendToClient("C_Pong", now(1))
-- end
