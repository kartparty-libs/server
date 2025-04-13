-- global enum
local CJSON = SingletonRequire("CJSON")
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global class
local CDBCommand = SingletonRequire("CDBCommand")
local CCommercialService = SingletonRequire("CCommercialService")
local CDataReport = SingletonRequire("CDataReport")
local CPlayerManager = SingletonRequire("CPlayerManager")
local CDataCenterManager = SingletonRequire("CDataCenterManager")
local CPlayerSystemList = SingletonRequire("CPlayerSystemList")
local CCommonFunction = SingletonRequire("CCommonFunction")
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager")
local CDBServerManager = SingletonRequire("CDBServerManager")
local CInviteManager = SingletonRequire("CInviteManager")
local CDataLog = SingletonRequire("CDataLog")

-- global function
local math_floor = math.floor
local math_random = math.random
local math_ceil = math.ceil
local table_insert = table.insert
local string_format = string.format
local string_gmatch = string.gmatch
local now = _commonservice.now
local ProtectedCall = ProtectedCall
local IsSecInToday = CCommonFunction.IsSecInToday
local mSqrt = math.sqrt
-- 主地图配置Id
local __MainMapCfgId = 1
-- local
local IntervalMsec = 2 * 60000 -- 数据定时保存的间隔（ms）
local ReportPlayTimeIntervalMsec = 5 * 60000 -- 上报在线时长的间隔（ms）

local CPlayer = ClassRequire("CPlayer")
function CPlayer:_constructor(i_pSession, i_sIP, i_nIP)
    self.m_pSession = i_pSession
    self.m_sIP = i_sIP
    self.m_nIP = tostring(i_nIP)
    -- self.m_bActiveQuit = true
    if i_pSession then
        self:SetState(KSPlayerStateEnum.eConnect)
    end
end

function CPlayer:SetState(i_nState)
    self.m_nState = i_nState
end
function CPlayer:GetState()
    return self.m_nState
end

local malloc = _memoryservice.malloc
local free = _memoryservice.free
local fancy_encode = _codeservice.fancy_encode
local baseLen = 4096
local maxLen = 65535
local sendtosession = _netservice.sendtosession
function CPlayer:SendToClient(i_sMsg, ...)
    if self.m_pSession then
        local nBuffLen = baseLen
        while true do
            if nBuffLen > maxLen then
                print("ERROR!!! CPlayer:SendToClient > maxLen", nBuffLen, i_sMsg)
                break
            end
            local pData = malloc(nBuffLen)
            if pData then
                local params = CJSON.NetworkEncode(...)
                local nLen = fancy_encode(pData, nBuffLen, i_sMsg, unpack(params))
                if nLen > 0 then
                    -- self.m_nSendToClientLen = self.m_nSendToClientLen + nLen
                    sendtosession(self.m_pSession, pData, nLen)
                    free(pData)
                    break
                else
                    print("WARNING!!! CPlayer:SendToClient", nBuffLen, i_sMsg)
                    nBuffLen = nBuffLen + baseLen
                    free(pData)
                end
            else
                print("ERROR!!! CPlayer:SendToClient malloc", nBuffLen, i_sMsg)
                break
            end
        end
    end
end
function CPlayer:SendDataToClient(i_pData, i_nLen)
    if self.m_pSession then
        sendtosession(self.m_pSession, i_pData, i_nLen)
    end
end

local nReconnect = 60000
function CPlayer:OnDisconnect()
    self.m_pSession = nil
    -- 一些数据缓存清空
    self.m_bHaveAucData = nil
    delog("CPlayer:OnDisconnect", self.m_sRoleID)

    local nState = self:GetState()
    if nState == KSPlayerStateEnum.eConnect or nState == KSPlayerStateEnum.eLogin or nState == KSPlayerStateEnum.eWaitNew or nState == KSPlayerStateEnum.eLoadData or nState == KSPlayerStateEnum.eReadDBData then
        CPlayerManager:DeletePlayer(self)
    elseif nState == KSPlayerStateEnum.eInGame then
        if self.m_bActiveQuit then
            self:LeaveGame()
            delog("CPlayer:OnDisconnect LeaveGame", self.m_sRoleID)
        else
            if self.m_oReplacePlayer then
                self:BeReplace(self.m_oReplacePlayer)
                self.m_oReplacePlayer = nil
                delog("CPlayer:OnDisconnect m_oReplacePlayer", self.m_sRoleID)
            else
                self:SetState(KSPlayerStateEnum.eWaitReconnect)
                self.m_nReconnectTime = nReconnect
                delog("CPlayer:OnDisconnect not eWaitReconnect", self.m_sRoleID)
            end
        end
    end
end

local closesession = _netservice.closesession
function CPlayer:CloseSession()
    if self.m_pSession then
        logfile("Log!!! closesession.", self.m_sRoleID, self.m_pSession)
        closesession(self.m_pSession)
        return true
    else
        print("ERROR!!! closesession nil.", self.m_sAccountID, self.m_sRoleID)
        return false
    end
end

-- 账号替换
function CPlayer:BeReplace(i_oPlayer)
    CPlayerManager:ReplacePlayerA2B(self, i_oPlayer)
    self:SendToClient("C_LoadCharListMsg", 1)
    self:SetState(KSPlayerStateEnum.eInGame)
    self.m_bBeKick = nil
end

-- 顶号
function CPlayer:ReplaceBy(i_oPlayer)
    print("LOG!!! player raplace A.", self.m_sAccountID, self.m_sRoleID or "", self:GetState(), self:GetIP())
    print("LOG!!! player replace B.", i_oPlayer:GetIP())
    if self:GetState() == KSPlayerStateEnum.eInGame then
        if self.m_oReplacePlayer then
            print("LOG!!! self.m_oReplacePlayer ", self.m_oReplacePlayer:GetState())
            if self.m_oReplacePlayer:GetState() == KSPlayerStateEnum.eLogin then
                self:LeaveGame()
            else
                self.m_oReplacePlayer:BeKick(PlayerBeKickReasonEnum.eRepeatLogin, i_oPlayer:GetIP())
                self.m_oReplacePlayer = i_oPlayer
            end
        else
            self:BeKick(PlayerBeKickReasonEnum.eRepeatLogin, i_oPlayer:GetIP())
            self.m_oReplacePlayer = i_oPlayer
        end
    elseif self:GetState() == KSPlayerStateEnum.eWaitReconnect then
        self.m_nReconnectTime = nil
        self:BeReplace(i_oPlayer)
    elseif self:GetState() == KSPlayerStateEnum.eWaitNew or self:GetState() == KSPlayerStateEnum.eLoadData then
        self:BeKick(PlayerBeKickReasonEnum.eRepeatLogin, i_oPlayer:GetIP())
        i_oPlayer:BeKick(PlayerBeKickReasonEnum.eRepeatLogin, self:GetIP())
    else
        i_oPlayer:BeKick(PlayerBeKickReasonEnum.eRepeatLogin, self:GetIP())
    end
end

-- 被踢
function CPlayer:BeKick(i_nReason, i_AppendData)
    -- print(debug.traceback())
    -- 内部错误 记录数据库 用来做查询
    if i_nReason >= PlayerBeKickReasonEnum.eGSError then
    end
    --
    local nState = self:GetState()
    print("WARNING!!! player be kick", self.m_sAccountID, self.m_sRoleID, nState, i_nReason, self:GetIP())
    self.m_bBeKick = true
    self:SendToClient("C_LastError", i_nReason, i_AppendData or now(1))
    if nState == KSPlayerStateEnum.eInGame then
        if i_nReason == PlayerBeKickReasonEnum.eRepeatLogin then
            if not self:CloseSession() then
                self:LeaveGame()
            end
        else
            self:LeaveGame()
        end
    elseif nState == KSPlayerStateEnum.eWaitReconnect then
        self:LeaveGame()
    else
        if not self:CloseSession() then
            self:LeaveGame()
        end
    end
end

function CPlayer:SetSaveDataRole(i_sKey, i_Value)
    self.m_tSaveDataRole[i_sKey] = i_Value
end

function CPlayer:SetSaveDataRoleInfo(i_sKey, i_Value)
    self.m_tSaveDataRoleInfo[i_sKey] = i_Value
end
function CPlayer:SetOffLineBaseInfo(info)
    -- 定时存盘时间
    self.m_nSaveTime = IntervalMsec
    self.m_tSaveDataRole = {}
    self.m_tSaveDataRoleInfo = {}
    -- 数据初始化
    -- self.m_sRoleID = info.roleid
    -- self.m_sName = info.rolename
    -- self.m_nNewFlag = info.newflag
    self:SetBaseInfo(info)
end
--[[
    info 是数据库属性
]]
function CPlayer:SetBaseInfo(info)
    -- 定时存盘时间
    self.m_nSaveTime = IntervalMsec
    -- 上报在线时长的间隔（ms）
    self.m_nReportPlayTime = ReportPlayTimeIntervalMsec
    self.m_tSaveDataRole = {}
    self.m_tSaveDataRoleInfo = {}

    -- 数据初始化
    self.m_sRoleID = info.roleid -- 角色ID
    self.m_sName = info.rolename -- 角色名称
    self.m_nNewFlag = info.newflag -- 是否是新注册玩家
    self.m_nLoginNum = info.loginnum or 1 -- 登陆天数
    self.m_nCreateTime = info.createtime -- 角色创建时间(时间戳，秒)
    self.m_nRefreshTime = info.refreshtime -- 每日刷新时间(时间戳，秒)
    self.m_nTodayTime = info.todaytime or 0 -- 本日在线时间
    self.m_nTodayHour = math_floor((info.todaytime or 0) / 3600) -- 本日在线小时
    self.m_nPlayTime = info.totaltime or 0 -- 在线总时间(msec)
    self.m_nLogoutTime = info.logouttime or 0 -- 上次下线时间
    self.m_sKartKey = info.kartkey or "" -- 激活码
    self.m_sEmail = info.email or "" -- 邮箱
    self.m_bIsr = ConfigExtend.GetKartKeyCfg_IsRobot(self.m_sKartKey) -- 是否机器

    self:BanSpeak(info.banspeak or 0, true) -- 禁言时间
    self:SetState(KSPlayerStateEnum.eLoadData)
    if self.m_tLoginData then
        local tData = {
            login_type = tostring(self.m_tLoginData.login_type),
            browser_type = tostring(self.m_tLoginData.browser_type),
            system_type = tostring(self.m_tLoginData.system_type),
            desk_version = tostring(self.m_tLoginData.desk_version)
        }
        CDataReport:DataReport("client_info", tData, {self})
        self.m_tLoginData = nil

        self:InitMapData(__MainMapCfgId)
    end
end

function CPlayer:SyncClientData()
    -- 同步玩家基础数据
    self:SendToClient("C_SyncPlayerInfoMsg", self:GetSyncCLInfo())
    -- 同步给客户端服务器时间
    self:SendToClient("C_ServerTime", now(1), CGlobalInfoManager:GetOpenTime(), ServerInfo.serverid)
    -- 同步各系统数据
    self.m_oSystemMgr:SyncClientData()
end

function CPlayer:Create()
    logfile("KS Player Create", self.m_sRoleID)
    if not ServerInfo.isbridge then
        CCommercialService:ReportPlayerLogin(self)
    end
    CCommercialService:ReportPlayerInServer(self)
    CPlayerManager:SetPlayer2RoleID(self)

    if self:IsNew() then
    else
        local tRes1 = self:GetPlayerData("CPlayer")
    end

    -- 系统管理器
    self.m_oSystemMgr = ClassNew("CPlayerSystemManager", self, CPlayerSystemList:GetSysList())

    -- 解析刷新数据
    if IsSecInToday(self.m_nRefreshTime) then -- 每日刷新时间为本日
        self.m_oSystemMgr:Create()
    else -- 刷新时间不为本日
        -- 重置每日刷新相关数据
        self:DayRefresh()
        self.m_oSystemMgr:Create(true)
        CCommercialService:ReportPlayerEverydayEnter(self)
    end
    -- 同步给客户端数据
    if not self.m_bNoInit2Client then
        self:SyncClientData()
    else
        self.m_bNoInit2Client = nil
    end

    local bIsNew = false
    if self:IsNew() then
        self.m_nNewFlag = 0
        self:SetSaveDataRole("newflag", self.m_nNewFlag)
        CCommercialService:ReportPlayerEverydayEnter(self)
        bIsNew = true
    end

    if not self:IsR() then
        CDataLog:LogDistAccount_log(self:GetAccountID(), self:GetRoleID(), 1)
    end

    self:EnterGame(true, bIsNew)
end

function CPlayer:OffLineCreate(i_nCallBackID)
    self.nCallBackID = i_nCallBackID
    local function f()
        if
            not ProtectedCall(
                function()
                    -- 系统管理器
                    self.m_oSystemMgr = ClassNew("CPlayerSystemManager", self, CPlayerSystemList:GetSysList())
                    self.m_oSystemMgr:Create()
                    CDataCenterManager:OffLinePlayerCreate(self.nCallBackID, self)
                    self.nCallBackID = nil
                end
            )
         then
            print("ERROR!!! Player Create Error.", self:GetRoleID())
        end

        CDBServerManager:ClearPlayerData(self:GetRoleID())
    end
    local tRoleInfo = {
        m_sRoleID = self:GetRoleID(),
        m_bIsNew = self:IsNew(),
        m_bRefresh = true,
        m_nServerID = self:GetServerID()
    }
    if self:IsNew() then
        return
    end
    self:SendDB(f, tRoleInfo)
end
-- 离线玩家删除
function CPlayer:OffLineDestroy(i_nCallBackID)
    self:SaveData(true) -- 保存数据
    self.m_oSystemMgr:Destroy()
    if i_nCallBackID then
        CDataCenterManager:OffLinePlayerCreateError(i_nCallBackID)
    end
    -- local tRoleInfo = {
    --     m_sRoleID = self:GetRoleID(),
    --     m_bDestroy = true
    -- }
    -- self:SendDB(nil, tRoleInfo)
end

function CPlayer:ClientCreate()
    if self:GetState() == KSPlayerStateEnum.eLoadData then
        local function f()
            if self.m_pSession then -- 可能会在异步读取数据时断开连接了
                if
                    not ProtectedCall(
                        function()
                            self:Create()
                        end
                    )
                 then
                    print("ERROR!!! Player Create Error.", self:GetRoleID())
                    self:BeKick(PlayerBeKickReasonEnum.eKSHandleCLMsgError)
                end
            end
            CDBServerManager:ClearPlayerData(self:GetRoleID())
        end
        local tRoleInfo = {
            m_sRoleID = self:GetRoleID(),
            m_bIsNew = self:IsNew(),
            m_bRefresh = not IsSecInToday(self.m_nRefreshTime),
            m_nServerID = self:GetServerID()
        }
        self:SendDB(f, tRoleInfo)
        self:SetState(KSPlayerStateEnum.eReadDBData)
    elseif self:GetState() == KSPlayerStateEnum.eInGame then
        -- 同步给客户端数据
        self:SyncClientData()

        self:EnterGame(false, self:IsNew())
    end
end

function CPlayer:Update(i_nDeltaMsec)
    self.m_nPlayTime = self.m_nPlayTime + i_nDeltaMsec
    self:SetSaveDataRole("totaltime", self.m_nPlayTime)
    -- 断线重连等待时间
    if self.m_nReconnectTime then
        self.m_nReconnectTime = self.m_nReconnectTime - i_nDeltaMsec
        if self.m_nReconnectTime <= 0 then
            self.m_nReconnectTime = nil
            self:LeaveGame()
        end
    end
    -- 定时存盘
    self.m_nSaveTime = self.m_nSaveTime - i_nDeltaMsec
    if self.m_nSaveTime <= 0 then
        self.m_nSaveTime = IntervalMsec
        self:SaveData()
    end
    -- 上报在线时长
    self.m_nReportPlayTime = self.m_nReportPlayTime - i_nDeltaMsec
    if self.m_nReportPlayTime <= 0 then
        self.m_nReportPlayTime = ReportPlayTimeIntervalMsec
        CCommercialService:ReportPlayerPlayerTime(self)
    end
    -- 更新本日在线时间
    self:UpdateTodayTime(i_nDeltaMsec)
    -- 系统更新
    self.m_oSystemMgr:Update(i_nDeltaMsec)
end

function CPlayer:UpdateTodayTime(i_nDeltaMsec)
    local nTodayTime = self.m_nTodayTime
    self.m_nTodayTime = self.m_nTodayTime + i_nDeltaMsec
    -- print("----", nTodayTime, self.m_nTodayTime)
    if nTodayTime <= 300000 and self.m_nTodayTime >= 300000 then
        CCommercialService:ReportPlayerEveryday5Min(self)
    end
    self:SetSaveDataRole("todaytime", self.m_nTodayTime)
    local nHour = math_floor(self.m_nTodayTime / 3600000)
    -- print("--------", self.m_nTodayTime/1000, nHour);
    if self.m_nTodayHour < nHour then
        self.m_nTodayHour = nHour
    end
end

function CPlayer:DayRefresh()
    -- 每日刷新时间(时间戳，秒)
    self.m_nRefreshTime = now(1)
    self:SetSaveDataRole("refreshtime", self.m_nRefreshTime)
    -- 本日在线时间
    self.m_nTodayTime = 0
    self:SetSaveDataRole("todaytime", self.m_nTodayTime)
    self.m_nTodayHour = 0 -- 本日在线小时
    -- 登陆天数+1
    self.m_nLoginNum = self.m_nLoginNum + 1
    delog("self.m_nLoginNum    = self.m_nLoginNum + 1", self.m_nLoginNum)

    self:SetSaveDataRole("loginnum", self.m_nLoginNum)
end

function CPlayer:OnDayRefresh()
    -- self:GetSystem("CResourcebackSystem"):DayRefresh()
    self:DayRefresh()
    self.m_oSystemMgr:OnDayRefresh()
    self:SendToClient("C_DayRefreshMsg")
    CCommercialService:ReportPlayerEverydayEnter(self)
end

-- 保存role数据
function CPlayer:SaveRoleData(i_bLogOut)
    if next(self.m_tSaveDataRole) or i_bLogOut then
        local oUpdateCmd = self:CreateUpdateCmd("role")
        for k, v in pairs(self.m_tSaveDataRole) do
            oUpdateCmd:SetFields(k, v)
        end
        if i_bLogOut then
            oUpdateCmd:SetFields("logouttime", now(1))
        end
        oUpdateCmd:SetWheres("roleid", self.m_sRoleID, "=")
        oUpdateCmd:Execute()
        self.m_tSaveDataRole = {}
    end
end

-- 保存role_scores数据
function CPlayer:SaveScoresData()
end

-- 保存数据
function CPlayer:SaveData(i_bLogOut)
    -- self:PrintSendToClientLen()
    local res =
        ProtectedCall(
        function()
            self:SaveRoleData(i_bLogOut)
        end
    )
    if not res then
        print("ERROR!!! Player SaveRoleData", self.m_sRoleID)
    end
    res =
        ProtectedCall(
        function()
            self:SaveScoresData(i_bLogOut)
        end
    )
    if not res then
        print("ERROR!!! Player SaveScoresData", self.m_sRoleID)
    end
    -- 保存角色各种系统数据 SystemMgr里已经ProtectedCall了
    self.m_oSystemMgr:SaveData(i_bLogOut)
end

function CPlayer:Destroy(i_fCloseSession)
    CCommercialService:ReportPlayerOutServer(self)
    self:SetState(KSPlayerStateEnum.eDestroy)
    -- 打点记录
    self:SaveData(true) -- 保存数据
    self.m_oSystemMgr:Destroy()

    -- 删除Player
    local res =
        ProtectedCall(
        function()
            CPlayerManager:DeletePlayer(self)
        end
    )
    if not res then
        print("ERROR!!! Player CPlayerManager:DeletePlayer", self.m_sRoleID)
    end

    -- 异步存储全部执行后在关闭session
    if i_fCloseSession then
        local tRoleInfo = {
            m_sRoleID = self:GetRoleID(),
            m_bDestroy = true
        }
        self:SendDB(i_fCloseSession, tRoleInfo)
    end
    -- 离线上报
    local tData = {
        map_id = tostring(self.GetMapCfgID()),
        ip = self.m_sIP,
        onlinetime = tostring(now(1) - self:GetLoginTime())
    }
    CDataReport:DataReport("logout", tData, {self})
end
function CPlayer:GetSomeInfo()
    return {
        self.m_sRoleID,
        self.m_sName
    }
end

function CPlayer:GetSyncCLInfo()
    return {
        [1] = self.m_sRoleID,
        [2] = self.m_sName,
        [3] = self.m_nCreateTime
    }
end

------------
---- db ----
------------
function CPlayer:GetServerID()
    return self.m_nDBID
end

function CPlayer:SetDBID(i_nDBID)
    self.m_nDBID = i_nDBID
end

function CPlayer:CreateSelectCmd(i_sTableName)
    return CDBCommand:CreateSelectCmd(i_sTableName, self.m_nDBID)
end

function CPlayer:CreateInsertCmd(i_sTableName)
    return CDBCommand:CreateInsertCmd(i_sTableName, self.m_nDBID)
end

function CPlayer:CreateUpdateCmd(i_sTableName)
    return CDBCommand:CreateUpdateCmd(i_sTableName, self.m_nDBID)
end

function CPlayer:CreateDeleteCmd(i_sTableName)
    return CDBCommand:CreateDeleteCmd(i_sTableName, self.m_nDBID)
end

----------------------------------------------------------------------------------------------

function CPlayer:SendDB(i_fCallBack, i_tRoleInfo)
    CDBServerManager:SendDB(i_fCallBack, i_tRoleInfo)
end

function CPlayer:GetPlayerData(i_sModule)
    return CDBServerManager:GetPlayerData(self.m_sRoleID, i_sModule)
end

-- 获取系统
function CPlayer:GetSystem(i_sSystemName)
    return self.m_oSystemMgr:GetSystem(i_sSystemName)
end

-- 设置账号、OpenId、平台
function CPlayer:SetAccountID(i_sAccountID, i_sOpenID, i_sPf)
    self.m_sAccountID = i_sAccountID
    self.m_sOpenID = i_sOpenID
    self.m_sPf = i_sPf
end

-- 获取账号
function CPlayer:GetAccountID()
    return self.m_sAccountID
end

-- 获取OpenId
function CPlayer:GetOpenID()
    return self.m_sOpenID
end

-- 获取平台
function CPlayer:GetPf()
    return self.m_sPf
end

--设置登录服务器Id
function CPlayer:SetLoginServerID(i_nServerID)
    self.m_nLoginServerID = i_nServerID
end

-- 获取服务器Id
function CPlayer:GetLoginServerID()
    return self.m_nLoginServerID
end

-- 获取IP
function CPlayer:GetIP()
    return self.m_sIP
end

-- 获取IP
function CPlayer:GetNIP()
    return self.m_nIP
end

-- 设置MAC
function CPlayer:SetMAC(i_sMAC)
    self.m_sMAC = i_sMAC
end

-- 获取MAC
function CPlayer:GetMAC()
    return self.m_sMAC
end

-- 是否是新注册
function CPlayer:IsNew()
    return self.m_nNewFlag == 1
end

-- 获取玩家Id
function CPlayer:GetRoleID()
    return self.m_sRoleID
end

-- 获取玩家名称
function CPlayer:GetName()
    return self.m_sName
end

-- 获取离线时间
function CPlayer:GetLeaveTime()
    return self.nLeaveTime or 0
end

-- 系统提示
function CPlayer:SendSystemTips(i_nTipsId, i_tParam)
    self:SendToClient("C_SystemTips", i_nTipsId, i_tParam)
end

-- 获取上次下线时间
function CPlayer:GetLogoutTime()
    return self.m_nLogoutTime
end

-- 获取本日在线时间
function CPlayer:GetTodayTime()
    return self.m_nTodayTime
end

-- 获取登录天数
function CPlayer:GetLoginNum()
    return self.m_nLoginNum
end

-- 获取在线总时间
function CPlayer:GetPlayTime()
    return self.m_nPlayTime
end

-- 获取登录时间
function CPlayer:GetLoginTime()
    return self.m_nLoginTime
end

-- 设置登录时间
function CPlayer:SetLoginTime()
    self.m_nLoginTime = now(1) + 1
end

-- 禁言
function CPlayer:BanSpeak(i_nTime, i_bInit)
    self.m_nBanSpeakTime = i_nTime
    if not i_bInit then
        self:SendToClient("C_BanSpeak", self.m_nBanSpeakTime)
    end
end

-- 是否禁言
function CPlayer:IsBanSpeak()
    return self.m_nBanSpeakTime >= now(1)
end

-- 获取禁言时间
function CPlayer:GetBanSpeakTime()
    return self.m_nBanSpeakTime
end

-- 获取激活码
function CPlayer:GetKartKey()
    return self.m_sKartKey
end

-- 获取邮箱
function CPlayer:GetEmail()
    return self.m_sEmail
end

-- 是否机器
function CPlayer:IsR()
    return self.m_bIsr
end
