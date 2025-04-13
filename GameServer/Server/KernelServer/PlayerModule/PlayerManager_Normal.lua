-- global enum
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global function
local string_format = string.format
local string_find = string.find
local now = _commonservice.now
-- global singleton
local CCommonFunction = SingletonRequire("CCommonFunction")
local CDBCommand = SingletonRequire("CDBCommand")
local CDBService = SingletonRequire("CDBService")
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager")
local CCommercialService = SingletonRequire("CCommercialService")
local CBridgeConnector = SingletonRequire("CBridgeConnector")
-- global config

-- local
local CPlayerManager = SingletonRequire("CPlayerManager")
local CDataCenterManager = SingletonRequire("CDataCenterManager")

function CPlayerManager:InitSpecial()
    self.m_tLogin = {}
    self.m_nLoginSeq = 1
    self.m_tInviteFlag = {}
    self:ResetBridgeState()
end

function CPlayerManager:UpdateSpecial()
end

function CPlayerManager:GetNewRoleID()
    return string_format("%d%04d", CGlobalInfoManager:GetRoleIndex(), CGlobalInfoManager:GetServerID())
end

function CPlayerManager:SetBridgeState(i_sAccountID, i_bState)
    self.m_tBridgeState[i_sAccountID] = i_bState
end

function CPlayerManager:GetBridgeState(i_sAccountID)
    return self.m_tBridgeState[i_sAccountID]
end

function CPlayerManager:ResetBridgeState()
    self.m_tBridgeState = {}
end

function CPlayerManager:OnDeletePlayer(i_oPlayer)
end

function CPlayerManager:OnCommercialDisconnect()
    for _, oPlayer in pairs(self.m_tLogin) do
        oPlayer:BeKick(PlayerBeKickReasonEnum.eLoginServerError)
    end
    self.m_tLogin = {}
end

function CPlayerManager:PlayerOffLineLogin(i_sRoleId, i_nCallBackID)
    local oPlayer = ClassNew("CPlayer")
    oPlayer:SetDBID(CGlobalInfoManager:GetServerID())
    local oSelectCmd = oPlayer:CreateSelectCmd("role")
    oSelectCmd:SetWheres("roleid", i_sRoleId, "=")
    oSelectCmd:SetLimit(1)
    local res = oSelectCmd:Execute()
    if res and res[1] then
        oPlayer:SetOffLineBaseInfo(res[1])
        oPlayer:OffLineCreate(i_nCallBackID)
    else
        oPlayer:OffLineDestroy(i_nCallBackID)
    end
end

function CPlayerManager:PlayerLogin(i_oPlayer, i_tAccountInfo, i_bNoInit2Client)
    delog("CPlayerManager:PlayerLogin ========= ")
    if not i_bNoInit2Client and self:IsHeavyLoad() then
        i_oPlayer:BeKick(PlayerBeKickReasonEnum.eServerHeavyLoad)
        return
    end
    logfile("Log. player login req.", i_tAccountInfo.openid, i_oPlayer:GetIP())

    i_oPlayer.m_bNoInit2Client = i_bNoInit2Client
    i_oPlayer.m_deviceId = i_tAccountInfo.deviceId or "没有设备ID"
    self.m_tLogin[self.m_nLoginSeq] = i_oPlayer
    i_tAccountInfo.loginseq = self.m_nLoginSeq
    self.m_nLoginSeq = self.m_nLoginSeq + 1
    if i_bNoInit2Client then -- 从跨服返回
        i_tAccountInfo.ok = true
        self:PlayerLoginRes(i_tAccountInfo)
    else
        i_tAccountInfo.ok = false
        CCommercialService:PlayerLogin(i_tAccountInfo)
    end
end

function CPlayerManager:PlayerLoginRes(i_tAccountInfo)
    local oPlayer = self.m_tLogin[i_tAccountInfo.loginseq]
    self.m_tLogin[i_tAccountInfo.loginseq] = nil
    logfile("Log. player login res1.", i_tAccountInfo.openid, oPlayer:GetIP())
    if not oPlayer.m_pSession then
        delog("not oPlayer.m_pSession")
        return
    end
    logfile("Log. player login res2.", i_tAccountInfo.openid, oPlayer:GetIP())

    local sGM =string.sub(i_tAccountInfo.openid,1,7)
    if sGM == "GM@kart" then
        i_tAccountInfo.openid = string.sub(i_tAccountInfo.openid,8)
    end

    if ConfigExtend.GetKartKeyCfg()[i_tAccountInfo.openid] == nil then
        oPlayer:SendSystemTips(16, {})
        oPlayer:SetState(KSPlayerStateEnum.eConnect)
        return
    end

    local nNowTime = now(1)
	local nLast = #ServerInfo.PlayerLoginTime
	local tStartTime = ServerInfo.PlayerLoginTime[1]
	local tLastTime = ServerInfo.PlayerLoginTime[nLast]
	local nStartTime = CCommonFunction.GetTodayThisTimeSec(tStartTime[1], tStartTime[2], tStartTime[3])
	local nEndTime = CCommonFunction.GetTodayThisTimeSec(tLastTime[1], tLastTime[2], tLastTime[3])

    local sIOSTS =string.sub(i_tAccountInfo.openid,1,5)

    if (nNowTime < nStartTime or nNowTime > nEndTime) and  sGM ~="GM@kart" and sIOSTS ~= "IOSTS" then
		if nStartTime < nNowTime then
			nStartTime = nStartTime + 86400
		end
        oPlayer:BeKick(PlayerBeKickReasonEnum.eServerShutdown, nStartTime - nNowTime)
        return
    end

    if not i_tAccountInfo.ok then
        if i_tAccountInfo.bantime then
            oPlayer:BeKick(PlayerBeKickReasonEnum.eBanPlay, i_tAccountInfo.bantime - now(1))
        else
            oPlayer:BeKick(PlayerBeKickReasonEnum.eLoginFailed)
        end
        return
    end
    logfile("Log. player login res3.", i_tAccountInfo.openid, oPlayer:GetIP())
    local sAccountID = string_format("%s%04d", i_tAccountInfo.openid, i_tAccountInfo.serverid)
    sAccountID = CCommonFunction.ProtectSql(sAccountID)
    local oAnotherPlayer = self:GetPlayerByAccountID(sAccountID)
    oPlayer.m_tLoginData = i_tAccountInfo
    if oAnotherPlayer then
        oAnotherPlayer:ReplaceBy(oPlayer)
        -- oPlayer:SetState(KSPlayerStateEnum.eConnect)
        return;
    end
    if self:GetBridgeState(sAccountID) then
        print("ERROR!!! player is in bridge", sAccountID)
        oPlayer:BeKick(PlayerBeKickReasonEnum.ePlayerInBridge)
        CBridgeConnector:KickPlayer(sAccountID)
        return
    end

    oPlayer:SetMAC(i_tAccountInfo.mac)
    oPlayer:SetLoginServerID(i_tAccountInfo.serverid)
    oPlayer:SetDBID(CGlobalInfoManager:GetServerID())
    oPlayer:SetLoginTime()

    local oSelectCmd = oPlayer:CreateSelectCmd("role")
    oSelectCmd:SetWheres("accountid", sAccountID, "=")
    oSelectCmd:SetLimit(1)
    local res = oSelectCmd:Execute()
    if res then
        self:SetPlayer2AccountID(oPlayer, sAccountID, i_tAccountInfo.openid, i_tAccountInfo.pf or "unknown")
        if res[1] then
            local nBanPlay = i_tAccountInfo.banplaytime
            if nBanPlay and nBanPlay >= now(1) then
                oPlayer:BeKick(PlayerBeKickReasonEnum.eBanPlay, nBanPlay - now(1))
                return
            end
            -- 禁言时间
            res[1].banspeak = i_tAccountInfo.banspeaktime
            oPlayer:SetBaseInfo(res[1])
            --删除离线但有数据的玩家
            CDataCenterManager:DeletePlayer(res[1].roleid)
            if oPlayer.m_bNoInit2Client then
                oPlayer:ClientCreate()
            else
                oPlayer:SendToClient("C_LoadCharListMsg", 1)
            end
            CPlayerManager:OnInvite(false, i_tAccountInfo.inviteroleid, res[1].roleid)
        else
            if oPlayer.m_bNoInit2Client then
                oPlayer:BeKick(PlayerBeKickReasonEnum.eNoPlayerData)
            else
                if ConfigExtend.GetKartKeyCfg()[i_tAccountInfo.openid] == nil then
                    oPlayer:SendSystemTips(16, {})
                    oPlayer:SetState(KSPlayerStateEnum.eConnect)
                else
                    oPlayer:SetState(KSPlayerStateEnum.eWaitNew)
                    oPlayer:SendToClient("C_LoadCharListMsg", 0)
                end
            end
        end
    else
        oPlayer:BeKick(PlayerBeKickReasonEnum.eSelectPlayerError)
    end
end

local nNameMaxLen = 30
local str_name = "s%d.%s"
local sql_count_rolename = "select count(*) as count from role where `rolename` = '%s'"
local sql_count_accountid = "select count(*) as count from role where `accountid` = '%s'"
defineC.K_CreateCharReqMsg = function(i_oPlayer, i_sRoleName, i_sEMail, i_nHeadID, sInviteRoleID)
    delog("defineC.K_CreateCharReqMsg, ", i_sRoleName, i_sEMail, i_nHeadID)
    if i_oPlayer then
        print("recv K_CreateCharReqMsg", i_oPlayer:GetAccountID(), i_sRoleName, i_sEMail, i_nHeadID)
    end
    if type(i_sRoleName) ~= "string" then
        return
    end
    if type(i_sEMail) ~= "string" then
        return
    end
    -- if type(i_nHeadID) ~= "number" then return end;
    i_oPlayer.sInviteRoleID = sInviteRoleID
    local sAccountID = i_oPlayer:GetAccountID()
    if not sAccountID then
        return
    end
    if #i_sRoleName > nNameMaxLen then
        return
    end
    -- 检测是否有英文标点
    if string_find(i_sRoleName, "%p") then
        i_oPlayer:SendSystemTips(8, {})
        return
    end
    i_sRoleName = CCommonFunction.ProtectSql(i_sRoleName)
    --i_sRoleName = string_format(str_name, i_oPlayer:GetLoginServerID(), i_sRoleName);
    -- rolename exist
    -- 重名检测
    local i_sCmd = string_format(sql_count_rolename, i_sRoleName)
    local res = CDBService:Execute(i_sCmd, CGlobalInfoManager:GetServerID())
    if not res then
        return
    end
    if res[1].count > 0 then
        i_oPlayer:SendToClient("C_CreateCharResMsg", 1)
        return
    end
    i_sCmd = string_format(sql_count_accountid, sAccountID)
    -- role num too many
    res = CDBService:Execute(i_sCmd, CGlobalInfoManager:GetServerID())
    if not res then
        return
    end
    if res[1].count > 0 then
        i_oPlayer:SendToClient("C_CreateCharResMsg", 2)
        i_oPlayer:BeKick(PlayerBeKickReasonEnum.eTooManyPlayer)
        return
    end
    -- 这里是新玩家进入的地图ID
    local nBornMap = 0
    -- insert to db
    local nowTime = now(1)
    local info = {
        accountid = sAccountID,
        roleid = CPlayerManager:GetNewRoleID(),
        rolename = i_sRoleName,
        createtime = nowTime,
        refreshtime = nowTime,
        newflag = 1,
        kartkey = i_oPlayer:GetOpenID(),
        email = i_sEMail
    }

    local oInsertCmd = CDBCommand:CreateInsertCmd("role")
    oInsertCmd:SetFields("accountid", info.accountid)
    oInsertCmd:SetFields("roleid", info.roleid)
    oInsertCmd:SetFields("rolename", info.rolename)
    oInsertCmd:SetFields("createtime", info.createtime)
    oInsertCmd:SetFields("refreshtime", info.refreshtime)
    oInsertCmd:SetFields("kartkey", info.kartkey)
    oInsertCmd:SetFields("email", info.email)

    res = oInsertCmd:Execute(true)
    if not res then
        i_oPlayer:BeKick(PlayerBeKickReasonEnum.eInsertPlayerError)
        return
    end
    -- success
    i_oPlayer:SetBaseInfo(info)
    i_oPlayer:SendToClient("C_LoadCharListMsg", 1)

    CCommercialService:ReportPlayerCreateChar(i_oPlayer)
    CPlayerManager:AddOneRegistNum()
    delog("*********************Create:", info.roleid, sAccountID, sInviteRoleID)
    if (not sInviteRoleID) or (sInviteRoleID == "") then
        sInviteRoleID = CPlayerManager.m_tInviteFlag[sAccountID]
        CPlayerManager.m_tInviteFlag[sAccountID] = nil
        print("not sInviteRoleID", sInviteRoleID)
    end
    CPlayerManager:OnInvite(true, sInviteRoleID, info.roleid)
end

function CPlayerManager:PlayerOnInviteFlag(i_sRoleID, bNew, invitee)
    local sAccID = string_format("%s%04d", invitee, ServerInfo.serverid)
    if bNew then
        self.m_tInviteFlag[sAccID] = i_sRoleID
    else
        local oDBCmd = CDBCommand:CreateSelectCmd("role")
        oDBCmd:SetWheres("accountid", sAccID, "=")
        oDBCmd:SetLimit(1)
        local res = oDBCmd:Execute()
        local data = res[1]
        if not data then
            return
        end
        delog("data.roleid :", data.roleid)
        self:OnInvite(true, i_sRoleID, data.roleid)
    end
end
