------------------------------------------------------------------------------------------
-- 账号自动管理器
------------------------------------------------------------------------------------------
-- global enum
local ScheduleTaskCycleTypeEnum = RequireEnum("ScheduleTaskCycleTypeEnum")

-- global function
local next = next
local now = _commonservice.now
local table_insert = table.insert
local table_remove = table.remove
local string_find = string.find
local string_format = string.format
local __ConfigExtend = ConfigExtend
local ClassNew = ClassNew
-- global singleton
local CDBCommand = SingletonRequire("CDBCommand")
local CCommonFunction = SingletonRequire("CCommonFunction")
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager")
local CDBService = SingletonRequire("CDBService")
local CPlayerManager = SingletonRequire("CPlayerManager")
local CPlayerSystemList = SingletonRequire("CPlayerSystemList")
local CDataCenterManager = SingletonRequire("CDataCenterManager")
local CSchedule = SingletonRequire("CSchedule")

-- local
local CAccountRobotManager = SingletonRequire("CAccountRobotManager")

local RobotType = {
    eActive1 = 1,
    eActive2 = 2,
    eActive3 = 3,
    eActive4 = 4
}

local TimeType = {
    eAfternoon = 1,
    eNight = 2
}

function CAccountRobotManager:Initialize()
    -- 账号列表
    self.m_tAccountRobotList = {}
    -- 每天随机累加的分数列表
    self.m_tRobotDayData = {}
    -- 执行列表
    self.m_tExecuteList = {}

    for k, v in pairs(TimeType) do
        self.m_tRobotDayData[v] = {}
        for i = 1, 16 do
            self.m_tRobotDayData[v][i] = {}
        end
    end

    math.randomseed(6666)
    delog("CAccountRobotManager Initialize => load accountRobot start")

    local oCmd = CDBCommand:CreateSelectCmd("role")
    oCmd:SetWheres("isr", 1, "=")
    local tRes = oCmd:Execute()
    if tRes and #tRes > 0 then
        for k, v in ipairs(tRes) do
            self:InitRobotData(v.roleid, v.kartkey)
        end
    else
        local nHeadNum = #__ConfigExtend.GetHeadCfg()
        local tKartKeyCfg = __ConfigExtend:GetKartKeyCfg()
        for k, v in pairs(tKartKeyCfg) do
            if v.IsRobot == 1 then
                local nHead = math.random(1, nHeadNum)
                local sRoleId = self:CreateRobot(k, v.RobotName, v.RobotEmail, nHead)
                if sRoleId then
                    self:InitRobotData(sRoleId, k)
                end
            end
        end
    end

    -- for k, v in pairs(self.m_tAccountRobotList) do
    --     delog("CAccountRobotManager Initialize => load " .. k .. " -> Score = " .. v[3])
    -- end

    delog("CAccountRobotManager Initialize => load accountRobot end")
    math.randomseed(now(1))

    for i, v in ipairs(ServerInfo.ExecuteRobotTime) do
        local function free()
            self:ExecuteRobot(i)
        end
        CSchedule:AddTask({m_sTime = v[1] .. ":" .. v[2]}, ScheduleTaskCycleTypeEnum.eDay, 1, 0, free, {self})
    end

    return true
end

function CAccountRobotManager:Destruct()
end

function CAccountRobotManager:SaveData(i_oPlayer)
    local sRoleID = i_oPlayer:GetRoleID()
end

function CAccountRobotManager:InitRobotData(i_sRoleId, i_sKartKey)
    local eRobotType = __ConfigExtend.GetKartKeyCfg_RobotType(i_sKartKey)
    self.m_tAccountRobotList[i_sKartKey] = {i_sRoleId, eRobotType, 0}

    local nDay = 0
    while true do
        nDay = nDay + 1
        local tParam = __ConfigExtend.GetRobotTypeyCfg_Param(eRobotType, nDay)
        if tParam and next(tParam) then
            local tProbability = tParam[1]
            local nLoginProbability = math.random(tProbability[1], tProbability[2])
            if nLoginProbability == 100 or nLoginProbability >= math.random(1, 100) then
                local nTimeProbability = tParam[2][1]
                local eTimeType = TimeType.eNight
                if nTimeProbability >= math.random(1, 100) then
                    eTimeType = TimeType.eAfternoon
                end

                local tScore = tParam[3]
                local nRandomScore = math.random(tScore[1], tScore[2]) * 10
                local nTotalScore = self.m_tAccountRobotList[i_sKartKey][3] + nRandomScore
                self.m_tRobotDayData[eTimeType][nDay][i_sRoleId] = nTotalScore
                self.m_tAccountRobotList[i_sKartKey][3] = nTotalScore
            end
        else
            break
        end
    end
end

local nNameMaxLen = 30
local sql_count_accountid = "select count(*) as count from role where `accountid` = '%s'"
function CAccountRobotManager:CreateRobot(sKartKey, i_sRoleName, i_sEMail, i_nHeadID)
    if type(i_sRoleName) ~= "string" then
        return
    end
    if type(i_sEMail) ~= "string" then
        return
    end
    if type(i_nHeadID) ~= "number" then
        return
    end

    local sAccountID = string_format("%s%04d", sKartKey, 1)
    if not sAccountID then
        return
    end

    if #i_sRoleName > nNameMaxLen then
        -- delog("CAccountRobotManager CreateRobot 1 => ", sKartKey)
        return
    end

    -- 检测是否有英文标点
    if string_find(i_sRoleName, "%p") then
        -- delog("CAccountRobotManager CreateRobot 2 => ", sKartKey)
        return
    end
    i_sRoleName = CCommonFunction.ProtectSql(i_sRoleName)
    local i_sCmd = string_format(sql_count_accountid, sAccountID)
    -- role num too many
    local res = CDBService:Execute(i_sCmd, CGlobalInfoManager:GetServerID())
    if not res then
        return
    end
    if res[1].count > 0 then
        return
    end
    -- insert to db
    local nowTime = now(1)
    local info = {
        accountid = sAccountID,
        roleid = CPlayerManager:GetNewRoleID(),
        rolename = i_sRoleName,
        createtime = nowTime,
        refreshtime = nowTime,
        newflag = 0,
        kartkey = sKartKey,
        email = i_sEMail,
        isr = 1
    }

    local oInsertCmd = CDBCommand:CreateInsertCmd("role")
    oInsertCmd:SetFields("accountid", info.accountid)
    oInsertCmd:SetFields("roleid", info.roleid)
    oInsertCmd:SetFields("rolename", info.rolename)
    oInsertCmd:SetFields("createtime", info.createtime)
    oInsertCmd:SetFields("refreshtime", info.refreshtime)
    oInsertCmd:SetFields("kartkey", info.kartkey)
    oInsertCmd:SetFields("email", info.email)
    oInsertCmd:SetFields("isr", info.isr)
    oInsertCmd:SetFields("newflag", info.newflag)
    res = oInsertCmd:Execute(true)
    if not res then
        return
    end

    CDataCenterManager:GetPlayerByRoleID(
        info.roleid,
        function(i_oPlayer)
            i_oPlayer:SetBaseInfo(info)
            i_oPlayer:GetSystem("CBasicInfoSystem"):SetHead(i_nHeadID)
            CDataCenterManager:DeletePlayer(info.roleid)
        end
    )
    -- delog("CAccountRobotManager CreateRobot succeed => ", sKartKey, i_sRoleName, i_sEMail, i_nHeadID)
    return info.roleid
end

function CAccountRobotManager:ExecuteRobot(i_eTimeType)
    if not self.m_tRobotDayData[i_eTimeType] then
        return
    end
    local nOpenNowDayNum = CGlobalInfoManager:GetOpenNowDayNum()
    local tRobotList = self.m_tRobotDayData[i_eTimeType][nOpenNowDayNum]
    if not tRobotList then
        return
    end

    for k, v in pairs(tRobotList) do
        table_insert(self.m_tExecuteList, {k, v})
    end
    delog("CAccountRobotManager ExecuteRobot => eTimeType = ", i_eTimeType)
end

local interval = 500
local update = interval
function CAccountRobotManager:Update(i_nDeltaTime)
    update = update - i_nDeltaTime
    if update > 0 then
        return
    end

    if #self.m_tExecuteList > 0 then
        local tRobotData = table_remove(self.m_tExecuteList)
        local sRoleId = tRobotData[1]
        local nScore = tRobotData[2]
        CDataCenterManager:GetPlayerByRoleID(
            sRoleId,
            function(i_oPlayer)
                i_oPlayer:GetSystem("CBasicInfoSystem"):SetScore(nScore)
                print("CAccountRobotManager -> " .. sRoleId .. "  nScore = " .. nScore)
                CDataCenterManager:DeletePlayer(sRoleId)
            end
        )
    end
    update = interval
end

----------------------------------------------------------------
-- 客户端请求
----------------------------------------------------------------

-- 请求测试时间段执行机器人
defineC.K_ReqTastExecuteRobot = function(i_oPlayer, i_eTimeType)
    CAccountRobotManager:ExecuteRobot(i_eTimeType)
end
