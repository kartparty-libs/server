-- global function
local print = print
local logfile = logfile
local assert = assert
local fancy_decode = _codeservice.fancy_decode
local ProtectedCall = ProtectedCall
local Performance = Performance
-- global enum
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global singleton
local CPlayerManager = SingletonRequire("CPlayerManager")
local CJSON = SingletonRequire("CJSON")
---------------------------------------------------------------------
-- local
local function onAccept(session, sip, nip)
    print("*******onAccept", session, sip, nip)
    CPlayerManager:NewPlayer(session, sip, nip)
end
local function onClose(session, errstr)
    print("*******onClose", session, errstr);
    CPlayerManager:Disconnect(session, errstr)
end

defineC.K_CSendToGS = function(i_oPlayer, i_sMsg, ...)
    i_oPlayer:TransmitToGS(i_sMsg, ...)
end

local tValidMsg = {
    [KSPlayerStateEnum.eConnect] = {
        K_EnterKSReqMsg = true,
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true
    },
    [KSPlayerStateEnum.eLogin] = {
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    },
    [KSPlayerStateEnum.eWaitNew] = {
        K_CreateCharReqMsg = true,
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    },
    [KSPlayerStateEnum.eLoadData] = {
        K_PlayerCreate = true,
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    },
    [KSPlayerStateEnum.eReadDBData] = {
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    },
    [KSPlayerStateEnum.eWaitReconnect] = {
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    },
    [KSPlayerStateEnum.eDestroy] = {
        K_LeaveKSReqMsg = true,
        K_Ping = true,
        K_P = true,
        K_Pong = true,
        K_HeartBeat = true
    }
}

local tInvalidMsg = {
    [KSPlayerStateEnum.eInGame] = {
        K_EnterKSReqMsg = true,
        K_CreateCharReqMsg = true
    }
}

local function OnFancyCall(i_oPlayer, i_sMsg, ...)
    assert(i_sMsg, "ERROR!!! fancy call no msg")
    local func = defineC[i_sMsg]
    if not func then
        print("WARNING!!! on fancy call msg not exit.", i_sMsg, i_oPlayer.m_sRoleID, i_oPlayer.m_pSession)
        return
    end

    local state = i_oPlayer:GetState()
    local tTemp = tValidMsg[state]
    if tTemp then
        if not tTemp[i_sMsg] then
            -- logfile("WARNING!!! state & msg not match", state, i_sMsg, i_oPlayer.m_sRoleID, i_oPlayer.m_pSession)
            return
        end
    end
    tTemp = tInvalidMsg[state]
    if tTemp then
        if tTemp[i_sMsg] then
            -- logfile("WARNING!!! state & msg not match", state, i_sMsg, i_oPlayer.m_sRoleID, i_oPlayer.m_pSession)
            return
        end
    end

    -- print("--client call", i_sMsg);
    local f = Performance(i_sMsg)
    local params = CJSON.NetworkDecode(...)
    func(i_oPlayer, unpack(params))
    f()
end
local function onRecv(session, data, len)
    -- print("onRecv", session, data, len);
    local oPlayer = CPlayerManager:GetPlayerBySession(session)
    if
        not ProtectedCall(
            function()
                OnFancyCall(oPlayer, fancy_decode(data, len))
            end
        )
     then
        print("ERROR!!! on fancy call roleid", oPlayer:GetRoleID(), len)
        oPlayer:BeKick(PlayerBeKickReasonEnum.eKSHandleCLMsgError)
    end
end

local CClientListener = SingletonRequire("CClientListener")
function CClientListener:Initialize()
    local ip = "0.0.0.0"
    print("CClientListener start listen at", ip .. ":" .. ServerInfo.clientport)
    self.m_oFancyListener = _netservice.listenfancy(ip, ServerInfo.clientport, onAccept, onClose, onRecv)
    return self.m_oFancyListener
end

function CClientListener:Destruct()
    self.m_bDestructOver = true
    if self.m_oFancyListener then
        _netservice.shutdownlistener(self.m_oFancyListener)
    end
end

function CClientListener:IsDestructOver()
    return self.m_bDestructOver
end
