defineCM = {};

local ServerInfo    = ServerInfo;

-- global enum
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global function
local print			= print;
local logfile       = logfile
local pairs			= pairs;
local ipairs		= ipairs;
local unpack        = unpack
local tonumber      = tonumber
local now           = _commonservice.now
local math_floor    = math.floor
local table_insert	= table.insert;
local string_sub    = string.sub
local connectnormal = _netservice.connectnormal;
local sendtosession	= _netservice.sendtosession;
local closesession	= _netservice.closesession;
local fast_encode	= _codeservice.fast_encode;
local fast_decode	= _codeservice.fast_decode;
local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local hmac_sha1     = _commonservice.hmac_sha1;
local hex_encode    = _commonservice.hex_encode;
local ProtectedCall = ProtectedCall;
-- global singleton
local CGlobalInfoManager= SingletonRequire("CGlobalInfoManager");
local CPlayerManager    = SingletonRequire("CPlayerManager");
local CDBCommand        = SingletonRequire("CDBCommand")
local CCommonFunction 	= SingletonRequire("CCommonFunction");
local CPlatformManager 	= SingletonRequire("CPlatformManager")
local CChargeManager    = SingletonRequire("CChargeManager");

-- global class
local defineCM		= defineCM;

-- local
local CCommercialService = SingletonRequire("CCommercialService");
function CCommercialService:Initialize()
	self:Connect()
	return true
end;

local function onConnect(i_bRes, i_pSession)
	CCommercialService:OnConnect(i_bRes, i_pSession);
end;

local function OnCMSCall(i_sMsg, ...)
    local args = {...}
	ProtectedCall(function() defineCM[i_sMsg](unpack(args)) end)
end;

local function onRecv(i_pSession, i_pData, i_nLen)
	OnCMSCall(fast_decode(i_pData, i_nLen));
end;

local function onClose(i_pSession, i_sErrStr)
	CCommercialService:OnDisconnect(i_sErrStr);
end;

function CCommercialService:Connect()
	connectnormal(ServerInfo.commercial_ip, ServerInfo.commercial_port, onConnect, onClose, onRecv);
end;

local nReconnectTime = 3000;
function CCommercialService:OnConnect(i_bRes, i_pSession)
	if i_bRes then
		print("connect to commercial_server succeed!!!");
		self.m_pSession = i_pSession;
		self:Send("CM_Regist", CGlobalInfoManager:GetServerID(), CGlobalInfoManager:GetOpenTime(), CGlobalInfoManager:GetOpenTimeBeSet(), Version)
        for _, oPlayer in pairs(CPlayerManager:GetAllPlayer()) do
            self:ReportPlayerInServer(oPlayer)
        end
	else
		print("connect to commercial_server failed!!!");
		self.m_nReconnectTime = nReconnectTime;
	end;
end;

function CCommercialService:OnDisconnect(i_sErrStr)
	print("commercial_server disconnect!!!", i_sErrStr)
	self.m_pSession = nil;
	if self.m_bDestruct then
		self.m_bDestructOver = true;
	else
		self.m_nReconnectTime = nReconnectTime;
	end
	CPlayerManager:OnCommercialDisconnect()
end

function CCommercialService:Update(i_nDeltaMsec)
	if self.m_nReconnectTime then
		self.m_nReconnectTime = self.m_nReconnectTime - i_nDeltaMsec;
		if self.m_nReconnectTime <= 0 then
			self.m_nReconnectTime = nil;
			self:Connect();
		end;
	end;
end;

function CCommercialService:Destruct()
	self.m_bDestruct = true;
	if self.m_pSession then
		closesession(self.m_pSession);
	end;
end;

function CCommercialService:IsDestructOver()
	return self.m_bDestructOver;
end;

local nMaxLen = 4 * 4096;
function CCommercialService:Send(i_sMsg, ...)
    local bRes = false
	if self.m_pSession then
		local pData = malloc(nMaxLen);
		if pData then
			local nLen = fast_encode(pData, nMaxLen, i_sMsg, ...);
			if nLen > 0 then
				sendtosession(self.m_pSession, pData, nLen);
                bRes = true
			else
				print("ERROR!!! CCommercialService:Send fast_encode", nLen);
			end
			free(pData);
		else
			print("ERROR!!! CCommercialService:Send malloc");
		end
	else
		print("ERROR!!! CommercialServer Disappeared!!!")
	end
    return bRes
end

function CCommercialService:GetPFGift(i_oPlayer, i_sCode, i_tUsed)
    if self.m_pSession then
        self:Send("CM_GetPFGift", i_oPlayer:GetRoleID(), i_sCode, i_tUsed, i_oPlayer:GetPf())
    else
        i_oPlayer:SendSystemTips(1002199, {})
    end
end

defineCM.K_GetPFGiftRes = function(i_sRoleID, i_nErrCode, i_nMainType, i_nSubType)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:GetSystem("CGiftSystem"):GetPFGiftRes(i_nErrCode, i_nMainType, i_nSubType)
    end
end

function CCommercialService:PlayerLogin(i_tAccountInfo)    
    if not self:Send("CM_PlayerLogin", i_tAccountInfo) then
        i_tAccountInfo.ok = false;
        CPlayerManager:PlayerLoginRes(i_tAccountInfo);
    end
end
-- 登陆结果
defineCM.K_PlayerLoginRes = function(i_tAccountInfo)
	CPlayerManager:PlayerLoginRes(i_tAccountInfo);
end

function CCommercialService:ReportPlayerCreateChar(i_oPlayer)
    local data = {
        serverid = i_oPlayer:GetLoginServerID(),
        pfid = i_oPlayer:GetOpenID(),
        roleid = i_oPlayer:GetRoleID(),
        rolename = i_oPlayer:GetName(),
        level = 0,
        exp = 0,
        ts = now(1),
    }
    self:Send("CM_ReportPlayerCreateChar", data)
end
function CCommercialService:ReportPlayerRename(i_sNewName, i_sOldName)
    self:Send("CM_ReportPlayerRename", i_sNewName, i_sOldName)
end
function CCommercialService:ReportPlayerLevel(i_oPlayer, i_nNeedExp)
    self:Send("CM_ReportCharactersInfo", {level = i_oPlayer:GetSystem("CBasicInfoSystem"):GetLevel( ), needexp = i_nNeedExp, roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerTransLevel(i_oPlayer, i_nTransLevel)
    self:Send("CM_ReportCharactersInfo", {translevel = i_nTransLevel,roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerGuildName(i_RoleID, sGuildName)
    self:Send("CM_ReportCharactersInfo", {guildname = sGuildName,roleid = i_RoleID})
end
function CCommercialService:ReportPlayerWinNum(i_oPlayer, i_nWinNumber)
    self:Send("CM_ReportCharactersInfo", {winnum = i_nWinNumber,roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerLogin(i_oPlayer)
    self:Send("CM_ReportCharactersInfo", {last_login = now(1), ip = i_oPlayer:GetIP(), mac = i_oPlayer:GetMAC(), onserver = i_oPlayer:GetServerID(), roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerInServer(i_oPlayer)
	self:Send("CM_ReportCharactersInfo", {online = 1, roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerOutServer(i_oPlayer)
    self:Send("CM_ReportCharactersInfo", {last_logout = now(1), loginlong = math_floor(i_oPlayer:GetPlayTime() /1000), online = 0, roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerPlayerTime(i_oPlayer)
    self:Send("CM_ReportCharactersInfo", {loginlong = math_floor(i_oPlayer:GetPlayTime() /1000), todaytime = math_floor(i_oPlayer:GetTodayTime() /1000), roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerMap(i_oPlayer)
	self:Send("CM_ReportCharactersInfo", {mapid = i_oPlayer:GetMapCfgID(), roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerVip(i_oPlayer)
	self:Send("CM_ReportCharactersInfo", {vip = i_oPlayer:GetVipLevel(), roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportPlayerGold(i_oPlayer)
	self:Send("CM_ReportCharactersInfo", {gold = i_oPlayer:GetSystem("CItemSystem"):GetGold(), roleid = i_oPlayer:GetRoleID()})
end
function CCommercialService:ReportCharge(i_sRoleID, i_nMoney)
	self:Send("CM_ReportCharactersInfo", {charge = i_nMoney, roleid = i_sRoleID})
end
function CCommercialService:ReportActivity(i_tData)
	self:Send("CM_ReportActivityInfo", i_tData)
end
-- function CCommercialService:ReportPlayerTaskSuc(i_oPlayer, i_sTaskID, i_nStep)
    -- self:Send("CM_ReportPlayerTaskSuc", i_oPlayer:GetOpenID(), i_sTaskID, i_nStep)
-- end
function CCommercialService:ReportPlayerEverydayEnter(i_oPlayer)
    -- if CPlatformManager.IsPPS() then
    --     local now_ts = now(1)
    --     local year, month, day = CCommonFunction.Sec2Calendar(now_ts)
    --     local today_date = year * 10000 + month * 100 + day
    --     self:Send("CM_ReportPlayerEverydayEnter", {
    --         pfid = i_oPlayer:GetOpenID(),
    --         serverid = i_oPlayer:GetServerID(),
    --         roleid = i_oPlayer:GetRoleID(),
    --         rolename = i_oPlayer:GetName(),
    --         level = i_oPlayer:GetSystem("CBasicInfoSystem"):GetLevel( ),
    --         ts = now_ts,
    --         logindate = today_date
    --     })
    -- end
end
function CCommercialService:ReportPlayerEveryday5Min(i_oPlayer)
end
function CCommercialService:ReportPlayerLoverName(i_sRoleID, i_sLoverName)
	self:Send("CM_ReportCharactersInfo", {marry = i_sLoverName, roleid = i_sRoleID})
end

-- 关服
defineCM.K_Shutdown = function()
	_shutdown();	
end;

-- 广播公告
defineCM.K_Notice = function(i_nPosition,i_tMsg)
    for _, oPlayer in pairs(CPlayerManager:GetAllPlayer()) do
        oPlayer:SendToClient("C_NoticeRes", i_nPosition, i_tMsg)
    end
end

-- 踢人
defineCM.K_KickPlayer = function(i_sRoleID)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:BeKick(PlayerBeKickReasonEnum.eGMKick)
    end
end

-- 强制销毁玩家（服务器出错导致玩家卡住踢不下去）
defineCM.K_DestroyPlayer = function(i_sRoleID)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:Destroy()
    end
end

-- 封号
defineCM.K_BanPlay = function(i_sRoleID, i_nTime)
	if not i_nTime then
		local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
		if oPlayer then
			oPlayer:BeKick(PlayerBeKickReasonEnum.eLockMac)
		end
	else
		if i_nTime > 0 then
			local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
			if oPlayer then
				oPlayer:BeKick(PlayerBeKickReasonEnum.eBanPlay, i_nTime)
			end
		end
	end
end

-- 踢号
defineCM.K_KickPlay = function(i_tRoleID)
	if #i_tRoleID > 0 then
		for _, sRoleID in pairs(i_tRoleID) do
			local oPlayer = CPlayerManager:GetPlayerByRoleID(sRoleID)
			if oPlayer then
				oPlayer:BeKick(PlayerBeKickReasonEnum.eGMKick)
			end
		end
	else
		for _, oPlayer in pairs(CPlayerManager:GetAllPlayer()) do
			oPlayer:BeKick(PlayerBeKickReasonEnum.eGMKick)
		end
	end
end


-- 禁言
defineCM.K_BanSpeak = function(i_sRoleID, i_nTime)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:BanSpeak(i_nTime)
    end
end

-- 发运营邮件
defineCM.K_SendMail = function(i_sRoleID, i_sTitle, i_sContent, i_tItems, i_bSendOnline)
end

-- 充值
defineCM.K_Charge = function(i_sRoleID, i_nGold, i_sOrderID, i_nMoney, i_tData)
    -- CChargeManager:Charge(i_sRoleID, i_nGold, i_sOrderID, i_nMoney, i_tData);
end

-- 推送运营活动
defineCM.K_PushActivities = function(i_tData)
    print("LOG!!! on push activities")
end

-- ping pong
defineCM.K_Ping = function()
    CCommercialService:Send("CM_Pong")
end

-- 重新加载文件
defineCM.K_RedoFile = function(i_sFileName)
    print("LOG!!! redofile.", i_sFileName);
	if string.find(i_sFileName, "./Server/KernelServer/") then
		ProtectedCall(function() dofile(i_sFileName) end);
	elseif string.find(i_sFileName, "./Server/GameServer/") then
		CGameServerManager:RedoFile(i_sFileName);
    else
        HotUpdateConfig(i_sFileName);
	end
end

-- 设置开服时间
defineCM.K_SetOpenTime = function(i_nTs)
    print("LOG!!! set opentime.", i_nTs)
    local oUpdateCmd = CDBCommand:CreateUpdateCmd("globalinfo")
    oUpdateCmd:SetFields("realopentime", i_nTs)
    oUpdateCmd:SetWheres("serverid", CGlobalInfoManager:GetServerID(), "=")
    oUpdateCmd:Execute()
    _shutdown()
end

-- 设置常置公告
defineCM.K_SetAlwaysNotice = function(i_tData)

end

-- 大乐透相关
function CCommercialService:InitLotto(i_tData)
    self:Send("CM_InitLotto", i_tData)
end

function CCommercialService:BookLotto(i_sRoleID, i_sActionID, i_sSpecialID, i_nIndex)
    self:Send("CM_BookLotto", i_sRoleID, i_sActionID, i_sSpecialID, i_nIndex)
end

defineCM.K_BookLottoRes = function(i_sRoleID, i_sActionID, i_tRes)
end

function CCommercialService:GetLottoData(i_sRoleID, i_sSpecialID)
    self:Send("CM_GetLottoData", i_sSpecialID, i_sRoleID)
end

defineCM.K_GetLottoDataRes = function(i_sRoleID, i_sActionID, i_tData)
    -- SingletonRequire("CCommonFunction").PrintTable(i_tData, true)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:SendToClient("C_GetLottoDataRes", i_sActionID, i_tData)
    end
end

function CCommercialService:GetLottoCount(i_sRoleID, i_sSpecialID)
    self:Send("CM_GetLottoCount", i_sSpecialID, i_sRoleID)
end

defineCM.K_GetLottoCountRes = function(i_sRoleID, i_sActionID, i_tData)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:SendToClient("C_GetLottoCountRes", i_sActionID, i_tData)
    end
end

defineCM.K_LottoLuckyInfo = function(i_sActionID, i_nIndex, i_nTime, i_nNumber, i_sRoleName, i_nVipLevel, i_nCount, i_nMinCount)
   -- print("--lotto lucky info--", i_sActionID, i_nIndex, i_nTime, i_nNumber, i_sRoleName, i_nVipLevel)
    CPlayerManager:SendMsgToAllClient("C_LottoLuckyInfo", i_sActionID, i_nIndex, i_nTime, i_nNumber, i_sRoleName, i_nVipLevel, i_nCount, i_nMinCount)
end

-- 分享成功
defineCM.K_TieBaShare = function(i_sRoleID, reqbody)
    local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
    if oPlayer then
        oPlayer:ReqShareGame( reqbody )
    end
end

-- 账号邀请成功
defineCM.K_SendInviteNum = function(i_sRoleID, bNew, invitee)
    delog( "defineCM.K_SendInviteNum",  i_sRoleID, bNew, invitee)
    CPlayerManager:PlayerOnInviteFlag( i_sRoleID, bNew, invitee )
end