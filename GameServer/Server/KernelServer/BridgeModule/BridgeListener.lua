
-- 消息定义
local defineBS = {};

-- global function
local print			= print;
local logfile		= logfile;
local pairs			= pairs;
local ipairs		= ipairs;
local table_insert	= table.insert;
local sendtosession	= _netservice.sendtosession;
local closesession	= _netservice.closesession;
local fast_encode	= _codeservice.fast_encode;
local fast_decode	= _codeservice.fast_decode;
local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local math_floor	= math.floor;
local ClassNew			= ClassNew;

-- global singleton
local CDBService		= SingletonRequire("CDBService")
local CPlayerManager	= SingletonRequire("CPlayerManager")
local CGlobalInfoManager= SingletonRequire("CGlobalInfoManager")
local CRankMatchManager = SingletonRequire("CRankMatchManager")

local nGSNum = ServerInfo.ThreadNum;
-- local
local CBridgeListener = SingletonRequire("CBridgeListener");
local CDBServerManager = SingletonRequire("CDBServerManager");

-- 跨服分组
local tBridgewarGroup = {}
if ServerInfo.bridge_group then
	for nGroup, info in ipairs(ServerInfo.bridge_group) do
		for _, serverid in ipairs(info) do
			tBridgewarGroup[serverid] = nGroup;
		end
	end
end

-- listen
local function onAccept(session, ip)
	CBridgeListener:OnAccept(session, ip);
end
local function onClose(session, errstr)
	CBridgeListener:OnClose(session, errstr);
end
local function onRecv(session, data, len)
	CBridgeListener:OnRecv(session, data, len);
end


function CBridgeListener:Initialize()
	self.m_sWanIP = ServerInfo.bridge_wan_ip .. ":" .. ServerInfo.clientport;

	self.m_tSession2Info = {};
	self.m_tID2Session = {};
	self.m_nSessionNum = 0;
	
	self.m_tLevelInfo = {};   --记录玩家等级信息(游戏服上报)
	
    local ip = "0.0.0.0"
	print("CBridgeListener start listen at", ip .. ":" .. ServerInfo.bridge_port);
	self.m_pListener = _netservice.listennormal(
        ip, ServerInfo.bridge_port,
        onAccept, onClose, onRecv);
	return self.m_pListener;
end

function CBridgeListener:Destruct()
	if self.m_pListener then
		_netservice.shutdownlistener(self.m_pListener);
		self.m_pListener = nil;
	end
	for session, _ in pairs(self.m_tSession2Info) do
		_netservice.closesession(session);
	end
end

function CBridgeListener:IsDestructOver()
	return self.m_nSessionNum == 0;
end

function CBridgeListener:OnReport(i_pSession, i_nServerID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName, i_tRankVer, i_nMeanLevel)
	print("on report.", i_pSession, i_nServerID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName);
    if self.m_tID2Session[i_nServerID] then
        print("ERROR!!! ServerID repeat", i_nServerID)
        _netservice.closesession(i_pSession)
        return
    end
	self.m_tID2Session[i_nServerID] = i_pSession;
	self.m_tSession2Info[i_pSession].m_nID = i_nServerID;
	self.m_tLevelInfo[i_nServerID] = i_nMeanLevel;
	-- 设置服务器数据库连接属性
	CDBService:SetID2Info(i_nServerID, i_sHost, i_nPort,
		i_sUser, i_sPwd, i_sName);
	-- 设置服务器数据库(另一个线程)连接属性
	CDBServerManager:DBThreadSetID(i_nServerID, i_sHost, i_nPort,
		i_sUser, i_sPwd, i_sName);
	-- 返回本跨服服务器的外网链接
	self:Send(i_nServerID, "SetWanIP", self.m_sWanIP, CGlobalInfoManager:GetServerID());
	
	
	if not ServerInfo.bridge_group then
		tBridgewarGroup[i_nServerID] = 1
	end
	self:CalMeanLevel();
end

function CBridgeListener:OnReportMeanLevel(i_nServerID, i_nMeanLevel)
	self.m_tLevelInfo[i_nServerID] = i_nMeanLevel;
	self:CalMeanLevel();
end

function CBridgeListener:CalMeanLevel()
end

-- 获得所有服务器平均世界boss等级
function CBridgeListener:GetMeanLevel()
	return 0
end

function CBridgeListener:PlayerLeave(i_nServerID, i_sAccountID)
	self:Send(i_nServerID, "PlayerLeave", i_sAccountID);
end

function CBridgeListener:OnAccept(i_pSession, i_sIP)
	self.m_tSession2Info[i_pSession] = {
		m_sIP = i_sIP;
	};
	self.m_nSessionNum = self.m_nSessionNum + 1;
	print("bridge connected", i_pSession, i_sIP);
	print("session number", self.m_nSessionNum);
end

function CBridgeListener:OnClose(i_pSession, i_sErrStr)
	self.m_nSessionNum = self.m_nSessionNum - 1;
	local tInfo = self.m_tSession2Info[i_pSession];
	self.m_tSession2Info[i_pSession] = nil;
	if tInfo.m_nID then
		self.m_tID2Session[tInfo.m_nID] = nil;
		
		if not ServerInfo.bridge_group then
			tBridgewarGroup[tInfo.m_nID] = nil
		end
        
        CPlayerManager:KickPlayerByServerID(tInfo.m_nID)
	end
	print("bridge disconnected", i_pSession, i_sErrStr, tInfo.m_sIP, tInfo.m_nID);
	print("session number", self.m_nSessionNum);
end

function CBridgeListener:KickPlayer(i_pSession, i_sAccountID)
    logfile("LOG!!! CBridgeListener:KickPlayer.", self.m_tSession2Info[i_pSession].m_nID, i_sAccountID)
    CPlayerManager:KickPlayer(self.m_tSession2Info[i_pSession].m_nID, i_sAccountID)
end

local function OnBCCall(i_pSession, i_sMsg, ...)
	if i_sMsg and defineBS[i_sMsg] then
		defineBS[i_sMsg](i_pSession, ...);
	else
		print("ERROR!!! OnBCCall", i_sMsg);
	end
end
function CBridgeListener:OnRecv(i_pSession, i_pData, i_nLen)
	OnBCCall(i_pSession, fast_decode(i_pData, i_nLen));
end


local nMaxLen = 16384;
function CBridgeListener:Send(i_nServerID, i_sMsg, ...)
	local pSession = self.m_tID2Session[i_nServerID];
	if pSession then
		local pData = malloc(nMaxLen);
		if pData then
			local nLen = fast_encode(pData, nMaxLen, i_sMsg, ...);
			if nLen > 0 then
				sendtosession(pSession, pData, nLen);
			else
				print("ERROR!!! CBridgeListener:Send fast_encode", nLen);
			end
			free(pData);
		else
			print("ERROR!!! CBridgeListener:Send malloc");
		end
	else
		print("ERROR!!! CBridgeConnector Disappeared!!!", i_nServerID);
	end
end

-- 广播到其他服务器
function CBridgeListener:Broadcast(i_sMsg, ...)
	local pData = malloc(nMaxLen);
	if pData then
		local nLen = fast_encode(pData, nMaxLen, i_sMsg, ...);
		if nLen > 0 then
			for id, ses in pairs(self.m_tID2Session) do
				sendtosession(ses, pData, nLen);
			end
		else
			print("ERROR!!! CBridgeListener:Broadcast fast_encode", nLen);
		end
		free(pData);
	else
		print("ERROR!!! CBridgeListener:Broadcast malloc");
	end
end

-- 跨服喇叭
function CBridgeListener:Chat(i_tMsg)
    CBridgeListener:Broadcast("K_Chat", i_tMsg)
end


-- 跨服系统消息
function CBridgeListener:ChatNotice(i_tMsg)
	CBridgeListener:Broadcast("K_ChatNotice", i_tMsg)
end

function CBridgeListener:GetBridgeGroup(i_nServerID)
	return tBridgewarGroup[i_nServerID]
end

function CBridgeListener:GetServerIDByGroupID(i_nGroupID)
	if ServerInfo.bridge_group then
		return ServerInfo.bridge_group[i_nGroupID]
	else 
		local tTemp = {}
		for i_nServerID in pairs(tBridgewarGroup) do
			table_insert(tTemp, i_nServerID);
		end
		return tTemp
	end
end


defineBS.ReportMeanLevel = function(i_pSession, i_nServerID, i_nMeanLevel)
    CBridgeListener:OnReportMeanLevel(i_nServerID, i_nMeanLevel)
end

-- 跨服战场
defineBS.K_GetBridgeHoleBossInfo = function(i_pSession)

end;

defineBS.Report = function(i_pSession, i_nServerID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName, i_tRankVer, i_nMeanLevel)
	CBridgeListener:OnReport(i_pSession, i_nServerID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName, i_tRankVer, i_nMeanLevel);
end
defineBS.SetToken = function(i_pSession, i_nServerID, i_sAccountID, i_nState)
	logfile("LOG!!! set token.", i_nServerID, i_sAccountID, i_nState)
	CPlayerManager:SetToken(i_sAccountID, i_nServerID, i_nState)
end
defineBS.KickPlayer = function(i_pSession, i_sAccountID)
    CBridgeListener:KickPlayer(i_pSession, i_sAccountID)
end
-- gm指令刷新跨服排行
defineBS.K_WorldRankSortByGm = function ()
end

-- 跨服喇叭
defineBS.K_Chat = function(i_pSession, i_tMsg)
    CBridgeListener:Chat(i_tMsg)
end




-- 跨服喇叭
defineBS.K_ChatNotice = function(i_pSession,i_tMsg)
    CBridgeListener:ChatNotice(i_tMsg)
end

-- 本服向跨服请求名次
defineBS.K_WRankingBridgeReq = function (i_pSession, i_nServerID, i_sRoleID, i_nType)
end

-- 本服向跨服请求排行榜数据
defineBS.K_WRDataBridgeReq = function (i_pSession, i_nServerID, i_sRoleID, i_nType, i_nPage)
end

-- 本服角色改名更新跨服数据
defineBS.K_RoleRename = function (i_pSession, i_sRoleID, i_sNewName)
end

-- 本服向跨服请求组队
defineBS.K_GroupJoinCheck = function(i_pSession,i_nServerID,i_sRoleID,i_sLeaderId, i_nClientFlag, i_nMapID, i_nGroupID, i_nFighterPower)
end;

-- 本服向跨服发送世界等级
defineBS.K_SendMeanLevel = function(i_pSession,i_nServerID,i_nMeanLevel)
end;

-- 本服向跨服请求跨服战前三玩家的信息
defineBS.K_ReqHighPlayerData = function(i_pSession,i_oPlayer, i_nRoleId)
end;

-- 目标服向跨服返回跨服战前三玩家的信息
defineBS.K_RetHighPlayerData = function(i_pSession,i_nRoleId, tInfo)
end;


-- 本服向跨服发送开服时间
defineBS.K_SendOpenTime = function(i_pSession,i_nServerID,i_nOpenTime)
end;

------------跨服竞技场----------------------
-- 玩家加入跨服竞技场
defineBS.K_RMAddRank = function(i_pSession, i_nServerID, i_sRoleId, i_tImageData )
	CRankMatchManager:AddRank( i_sRoleId, i_tImageData )
end;

-- 玩家改名通知跨服竞技场
defineBS.K_RMPlayerRename = function(i_pSession, i_nServerID, i_sRoleID, i_sNewName )
	CRankMatchManager:OnPlayerRename( i_sRoleID, i_sNewName )
end;

-- 请求挑战(主要是从gs上拿到镜像数据)
defineBS.K_RMChallengeReq = function(i_pSession, i_nServerID, i_sRoleID, i_sTagId, i_nTagRank, i_ParseData )
	CRankMatchManager:ChallengeReq( i_nServerID, i_sRoleID, i_sTagId, i_nTagRank, i_ParseData )
end;

-- 请求随机数据
defineBS.K_RMRandomOpponentReq = function(i_pSession, i_nServerID, i_sRoleID )
	CRankMatchManager:RandomOpponentReq( i_nServerID, i_sRoleID )
end;

-- 请求玩家信息
defineBS.K_RMSelfImageDataReq = function(i_pSession, ... )
	CRankMatchManager:SelfImageDataReq( ... )
end;

-- 请求排行榜数据
defineBS.K_RMReqRankMatchRank = function(i_pSession, i_nServerID, i_sRoleID )
	CRankMatchManager:ReqRankMatchRank( i_sRoleID )
end;

-- 请求排行榜数据
defineBS.K_RMSendReport2Client = function(i_pSession, i_nServerID, i_sRoleID )
	CRankMatchManager:SendReport2Client( i_nServerID, i_sRoleID )
end;
