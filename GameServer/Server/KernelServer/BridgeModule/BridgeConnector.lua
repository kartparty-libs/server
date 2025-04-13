
-- 消息定义
defineBC = {};

-- global function
local print			= print;
local logfile		= logfile
local pairs			= pairs;
local ipairs		= ipairs;
local string_format	= string.format;
local connectnormal = _netservice.connectnormal;
local sendtosession	= _netservice.sendtosession;
local closesession	= _netservice.closesession;
local fast_encode	= _codeservice.fast_encode;
local fast_decode	= _codeservice.fast_decode;
local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
-- global singleton
local CPlayerManager		= SingletonRequire("CPlayerManager")
local CGlobalInfoManager	= SingletonRequire("CGlobalInfoManager")
local CDBService 			= SingletonRequire("CDBService");

-- local
local CBridgeConnector = SingletonRequire("CBridgeConnector");

local function onConnect(i_bRes, i_pSession)
	CBridgeConnector:OnConnect(i_bRes, i_pSession);
end

local function OnBSCall(i_sMsg, ...)
	if i_sMsg and defineBC[i_sMsg] then
		defineBC[i_sMsg](...);
	else
		print("ERROR!!! OnBSCall", i_sMsg);
	end
end

local function onRecv(i_pSession, i_pData, i_nLen)
	OnBSCall(fast_decode(i_pData, i_nLen));
end

local function onClose(i_pSession, i_sErrStr)
	CBridgeConnector:OnDisconnect(i_sErrStr);
end


function CBridgeConnector:Initialize()
	--self:Connect();
	return true;
end

function CBridgeConnector:Connect()
	connectnormal(ServerInfo.bridge_lan_ip, ServerInfo.bridge_port, onConnect, onClose, onRecv);
end

function CBridgeConnector:GetBridgeID()
    return self.m_nBridgeID
end

local nReconnectTime = 30000;
function CBridgeConnector:OnConnect(i_bRes, i_pSession)
	if i_bRes then
		print("connect to bridge_server succeed!!!");
		self.m_pSession = i_pSession;
		self:Send("Report", CGlobalInfoManager:GetServerID(),
			ServerInfo.bridge_access_db_host or ServerInfo.gamedb_host, 
            ServerInfo.bridge_access_db_port or ServerInfo.gamedb_port,
			ServerInfo.bridge_access_db_user or ServerInfo.gamedb_user, 
            ServerInfo.bridge_access_db_pwd or ServerInfo.gamedb_pwd,
            ServerInfo.gamedb_name,
			CGlobalInfoManager:GetRankVersion());
		self:Send("K_GetBridgeHoleBossInfo");
	else
		print("connect to bridge_server failed!!!");
		self.m_nReconnectTime = nReconnectTime;
	end
end

function CBridgeConnector:OnDisconnect(i_sErrStr)
	print("bridge_server disconnect!!!", i_sErrStr)
	self.m_pSession = nil;
	self.m_sWanIP = nil;
	CPlayerManager:ResetBridgeState()
	if self.m_bDestruct then
		self.m_bDestructOver = true;
	else
		self.m_nReconnectTime = nReconnectTime;
	end
end

function CBridgeConnector:OnDayRefresh()
	self:Send("ReportMeanLevel", CGlobalInfoManager:GetServerID())
end

function CBridgeConnector:Update(i_nDeltaMsec)
	if self.m_nReconnectTime then
		self.m_nReconnectTime = self.m_nReconnectTime - i_nDeltaMsec;
		if self.m_nReconnectTime <= 0 then
			self.m_nReconnectTime = nil;
			self:Connect();
		end
	end
end

function CBridgeConnector:Destruct()
	if self.m_pSession then
		closesession(self.m_pSession);
		self.m_bDestruct = true;
	else
		self.m_bDestructOver = true;
	end
end

function CBridgeConnector:IsDestructOver()
	return self.m_bDestructOver;
end

function CBridgeConnector:SetWanIP(i_sWanIP, i_nBridgeID)
	print("set bridge server wan ip", i_sWanIP, i_nBridgeID);
	self.m_sWanIP = i_sWanIP;
    self.m_nBridgeID = i_nBridgeID
end

function CBridgeConnector:GetWanIP()
	return self.m_sWanIP;
end

function CBridgeConnector:SetToken(i_sAccountID, i_nState)
    logfile("LOG!!! player set token.", i_sAccountID, i_nState)
	self:Send("SetToken", CGlobalInfoManager:GetServerID(), i_sAccountID, i_nState);
	CPlayerManager:SetBridgeState(i_sAccountID, true);
end

function CBridgeConnector:KickPlayer(i_sAccountID)
    logfile("LOG!!! kick player.", i_sAccountID)
    self:Send("KickPlayer", i_sAccountID)
end

function CBridgeConnector:PlayerLeave(i_sAccountID)
	logfile("LOG!!! player leave bridge.", i_sAccountID);
	CPlayerManager:SetBridgeState(i_sAccountID, nil);
end

local nMaxLen = 8192;
function CBridgeConnector:Send(i_sMsg, ...)
	if self.m_pSession then
		local pData = malloc(nMaxLen);
		if pData then
			local nLen = fast_encode(pData, nMaxLen, i_sMsg, ...);
			if nLen > 0 then
				sendtosession(self.m_pSession, pData, nLen);
			else
				print("ERROR!!! CBridgeConnector:Send fast_encode", i_sMsg, nLen);
			end
			free(pData);
		else
			print("ERROR!!! CBridgeConnector:Send malloc");
		end
	else
		print("ERROR!!! CBridgeServer Disappeared!!!")
	end
end

