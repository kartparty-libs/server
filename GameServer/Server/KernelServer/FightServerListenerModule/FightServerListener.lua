
-- global function
local print			= print;
local logfile       = logfile
local assert        = assert;
local fancy_decode	= _codeservice.fancy_decode;
local ProtectedCall = ProtectedCall;
local Performance = Performance
-- global enum
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global singleton
local CFightServerManager	= SingletonRequire("CFightServerManager");
local CJSON = SingletonRequire("CJSON");
---------------------------------------------------------------------
-- local
local function onFightAccept(session, sip, nip)
	print("*******onFightAccept***************", session, sip, nip);
    CFightServerManager:OnServiceRegist(session, sip, nip)
end
local function onFightClose(session, errstr)
	print("onFightClose", session, errstr);
    CFightServerManager:Disconnect(session, errstr);
end
local function OnFancyCall(i_oFightServer, i_sMsg, ...)
	assert(i_sMsg, "ERROR!!! fancy call no msg");
	local func = defineF[i_sMsg]; 
    if not func then
        print("WARNING!!! on fancy call msg not exit.", i_sMsg)
        return
    end
    local state = i_oFightServer:GetState()
    if state ~= KSPlayerStateEnum.eConnect  then
        logfile("WARNING!!! oFightServer state & msg not match", state, i_sMsg, i_oFightServer.m_sServerId, i_oFightServer.m_pSession,i_oFightServer.m_nIP)
    end
    local f = Performance(i_sMsg)
    -- local params = CJSON.NetworkDecode(...)
	func(i_oFightServer, ...);
    f()
end

local function onFightRecv(session, data, len)
	-- print("onFightRecv", session, errstr);
    local oFightServer = CFightServerManager:GetServerBySession(session);
	if not ProtectedCall(function() OnFancyCall(oFightServer, fancy_decode(data, len)) end) then
        print("ERROR!!! on fancy call roleid", oPlayer:GetRoleID(), len);
		oPlayer:BeKick(PlayerBeKickReasonEnum.eKSHandleCLMsgError)
	end
end

local CFightServerListener = SingletonRequire("CFightServerListener");
function CFightServerListener:Initialize()
    local ip = "0.0.0.0";
    print("CFightServerListener start listen at", ip .. ":" .. ServerInfo.fightserverport)
	
    self.m_oFightFancyListener = _netservice.listenfancy(
            ip, ServerInfo.fightserverport,
            onFightAccept,onFightClose,onFightRecv);
	return self.m_oFightFancyListener;
end

function CFightServerListener:Destruct()
	self.m_bDestructOver = true;
	if self.m_oFightFancyListener then
		_netservice.shutdownlistener(self.m_oFightFancyListener);
	end
end

function CFightServerListener:IsDestructOver()
	return self.m_bDestructOver;
end


