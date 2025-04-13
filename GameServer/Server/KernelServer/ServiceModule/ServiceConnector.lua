
-- 消息定义
defineSC = {};

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
local CServiceConnector = SingletonRequire("CServiceConnector");

local function onConnect(i_bRes, i_pSession)
	CServiceConnector:OnConnect(i_bRes, i_pSession);
end

local function OnSSCall(i_sMsg, ...)
	if i_sMsg and defineSC[i_sMsg] then
		defineSC[i_sMsg](...);
	else
		print("ERROR!!! OnSSCall", i_sMsg);
	end
end

-- 监听消息
local function onRecv(i_pSession, i_pData, i_nLen)
	OnSSCall(fast_decode(i_pData, i_nLen));
end

local function onClose(i_pSession, i_sErrStr)
	CServiceConnector:OnDisconnect(i_sErrStr);
end

function CServiceConnector:Initialize()
	--self:Connect();
	return true;
end

-- 获取ID和端口号 用来做唯一标识
function CServiceConnector:GetIPStr( )
	return ServerInfo.self_ip .. ":" .. ServerInfo.clientport
end

-- 开始链接
function CServiceConnector:Connect()
	print( "CServiceConnector:Connect Done  :" .. ServerInfo.service_lan_ip .. ":" .. ServerInfo.service_port )
	connectnormal(ServerInfo.service_lan_ip, ServerInfo.service_port, onConnect, onClose, onRecv);
end

local nReconnectTime = 30000;
function CServiceConnector:OnConnect(i_bRes, i_pSession)
	if i_bRes then
		print("connect to server succeed!!!");
		self.m_pSession = i_pSession;
		self:Send("Report", self:GetIPStr());
	else
		print("connect to server failed!!!");
		self.m_nReconnectTime = nReconnectTime;
	end
end

function CServiceConnector:OnDisconnect(i_sErrStr)
	print("service_server disconnect!!!", i_sErrStr)
	self.m_pSession = nil;
	if self.m_bDestruct then
		self.m_bDestructOver = true;
	else
		self.m_nReconnectTime = nReconnectTime;
	end
end

function CServiceConnector:Update(i_nDeltaMsec)
	if self.m_nReconnectTime then
		self.m_nReconnectTime = self.m_nReconnectTime - i_nDeltaMsec;
		if self.m_nReconnectTime <= 0 then
			self.m_nReconnectTime = nil;
			self:Connect();
		end
	end
end

function CServiceConnector:Destruct()
	if self.m_pSession then
		closesession(self.m_pSession);
		self.m_bDestruct = true;
	else
		self.m_bDestructOver = true;
	end
end

function CServiceConnector:IsDestructOver()
	return self.m_bDestructOver;
end

local nMaxLen = 8192;
function CServiceConnector:Send(i_sMsg, ...)
	if self.m_pSession then
		local pData = malloc(nMaxLen);
		if pData then
			local nLen = fast_encode(pData, nMaxLen, i_sMsg, ...);
			if nLen > 0 then
				sendtosession(self.m_pSession, pData, nLen);
			else
				print("ERROR!!! CServiceConnector:Send fast_encode", i_sMsg, nLen);
			end
			free(pData);
		else
			print("ERROR!!! CServiceConnector:Send malloc");
		end
	else
		print("ERROR!!! CServiceServer Disappeared!!!")
	end
end

