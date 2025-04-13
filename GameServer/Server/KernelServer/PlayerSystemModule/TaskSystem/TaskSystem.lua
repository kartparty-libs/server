------------------------------------------------------------------------------------------
-- 任务系统
------------------------------------------------------------------------------------------
-- global enum
local TaskTypeEnum = RequireEnum("TaskTypeEnum")
local TaskEventEnum = RequireEnum("TaskEventEnum")

-- global function
local next = next
local now = _commonservice.now
local table_insert = table.insert
local CInviteManager = SingletonRequire("CInviteManager")
local CDataLog = SingletonRequire("CDataLog")

-- local
local CTaskSystem = ClassRequire("CTaskSystem")

-- 任务数据索引
local TaskDataIdx = {
    -- 任务配置Id
    TaskCfgId = 1,
    -- 任务当前数值
    TaskValue = 2,
    -- 是否已领取奖励
    IsReceiveAward = 3
}
local TaskPlayTimeIntervalMsec = 60000 -- 任务在线时长通知的间隔（ms）

function CTaskSystem:Create(bRefresh)
    local pPlayer = self:GetPlayer()
    -- 存盘脏位
    self.tSaveCaches = {}
    -- 任务数据列表
    self.pTaskDatas = {}
    -- 任务类型映射列表
    self.pTaskTypeMapping = {}
    -- 任务事件映射列表
    self.pTaskEventMapping = {}
    -- 任务在线时长通知的间隔（ms）
    self.m_nTaskPlayTime = TaskPlayTimeIntervalMsec
    -- 任务完成次数记录
    self.pTaskCompleteRecord = {}

    local tTaskCfg = ConfigExtend.GetTaskCfg()
    for i, v in pairs(tTaskCfg) do
        local nTaskType = ConfigExtend.GetTaskCfg_TaskType(i)
        local nTaskEvent = ConfigExtend.GetTaskCfg_TaskEvent(i)

        self.pTaskDatas[i] = self:CreateTaskData(i)

        if self.pTaskTypeMapping[nTaskType] == nil then
            self.pTaskTypeMapping[nTaskType] = {}
        end
        table_insert(self.pTaskTypeMapping[nTaskType], i)

        if self.pTaskEventMapping[nTaskEvent] == nil then
            self.pTaskEventMapping[nTaskEvent] = {}
        end
        table_insert(self.pTaskEventMapping[nTaskEvent], i)
    end

    local tData = pPlayer:GetPlayerData("CTaskSystem")
    if tData and next(tData) then
        local taskinfo = StrToTable(tData.taskinfo)
        for _, v in pairs(taskinfo) do
            local pTaskData = v
            local nTaskCfgId = pTaskData[TaskDataIdx.TaskCfgId]
            if pTaskData[TaskDataIdx.IsReceiveAward] == nil then
                delog("CTaskSystem:Create =======> ", pPlayer:GetRoleID(), nTaskCfgId)
                pTaskData[TaskDataIdx.IsReceiveAward] = 0
            end
            self.pTaskDatas[nTaskCfgId] = pTaskData
        end
        local completerecord = StrToTable(tData.completerecord)
        for id, num in pairs(completerecord) do
            self.pTaskCompleteRecord[id] = num
        end
    end

    if pPlayer:IsNew() or bRefresh then
        self:OnDayRefreshEvent(false)
    end
    CInviteManager:OnTriggerTask(pPlayer)
    -- self:PlayerXZdata()
end

function CTaskSystem:OnDayRefresh()
    self:OnDayRefreshEvent(true)
end

function CTaskSystem:PlayerXZdata()
    local pPlayer = self:GetPlayer()
    if pPlayer:GetLoginNum() == 2 then
        local bRefresh = true
        for id, num in pairs(self.pTaskCompleteRecord) do
            if ConfigExtend.GetTaskCfg_TaskType(id) == TaskTypeEnum.eDailyTask then
                if num >= 2 then
                    bRefresh = false
                    break
                end
            end
        end
        if bRefresh then
            self:OnDayRefreshEvent(false)
        end
    end
end

function CTaskSystem:OnDayRefreshEvent(i_bNotSendClient)
    local pPlayer = self:GetPlayer()
    self:TriggerTaskEventSetValue(TaskEventEnum.eLogin, pPlayer:GetLoginNum(), nil, i_bNotSendClient)
    CInviteManager:OnCumulativeLogin(pPlayer, pPlayer:GetLoginNum())

    for _, taskCfgId in pairs(self.pTaskTypeMapping[TaskTypeEnum.eDailyTask]) do
        self.pTaskDatas[taskCfgId] = self:CreateTaskData(taskCfgId)
    end
    local tSaveData = {}
    for taskCfgId, data in pairs(self.pTaskDatas) do
        if data[TaskDataIdx.TaskValue] ~= 0 then
            table_insert(tSaveData, data)
        end
    end
    self.tSaveCaches["taskinfo"] = TableToStr(tSaveData, true)
    if i_bNotSendClient then
        pPlayer:SendToClient("C_SyncTaskDayRefresh", self.pTaskDatas)
    end
end

function CTaskSystem:Update(i_nDeltaMsec)
    -- 触发任务 在线时长
    self.m_nTaskPlayTime = self.m_nTaskPlayTime - i_nDeltaMsec
    if self.m_nTaskPlayTime <= 0 then
        self.m_nTaskPlayTime = TaskPlayTimeIntervalMsec
        self:TriggerTaskEventAddValue(TaskEventEnum.eOnlineTime, 1)
    end
end

-- 存盘
function CTaskSystem:SaveData()
    if next(self.tSaveCaches) then
        local oPlayer = self:GetPlayer()
        local sRoleID = oPlayer:GetRoleID()
        local oUpdateCmd = oPlayer:CreateUpdateCmd("role_taskinfo")
        for k, v in pairs(self.tSaveCaches) do
            oUpdateCmd:SetFields(k, v)
        end
        oUpdateCmd:SetWheres("roleid", sRoleID, "=")
        oUpdateCmd:Execute()
        self.tSaveCaches = {}
    end
end

-- 基本信息同步
function CTaskSystem:SyncClientData()
    self:GetPlayer():SendToClient("C_SyncTaskData", self.pTaskDatas)
end

--------------------------------------------------------------------------------------------------------------------------------

-- 创建任务数据
function CTaskSystem:CreateTaskData(i_nTaskCfgId)
    return {i_nTaskCfgId, 0, 0}
end

-- 获取任务数据
function CTaskSystem:GetTaskData(i_nTaskCfgId)
    return self.pTaskDatas[i_nTaskCfgId]
end

-- 触发任务事件
function CTaskSystem:TriggerTaskEventAddValue(i_eTaskEventEnum, i_nAddTaskValue, i_tTaskConditions, i_bNotSendClient)
    if i_nAddTaskValue == nil or type(i_nAddTaskValue) ~= "number" then
        return
    end
    for _, taskCfgId in ipairs(self.pTaskEventMapping[i_eTaskEventEnum]) do
        local tTaskData = self:GetTaskData(taskCfgId)
        if tTaskData and not self:IsCompleted(taskCfgId, tTaskData) and self:CheckTaskCondition(taskCfgId, i_tTaskConditions) then
            tTaskData[TaskDataIdx.TaskValue] = tTaskData[TaskDataIdx.TaskValue] + i_nAddTaskValue
            self:ChangeTaskData(tTaskData, i_bNotSendClient)
        end
    end
end

-- 触发任务事件
function CTaskSystem:TriggerTaskEventSetValue(i_eTaskEventEnum, i_nSetTaskValue, i_tTaskConditions, i_bNotSendClient)
    if i_nSetTaskValue == nil or type(i_nSetTaskValue) ~= "number" then
        return
    end
    for _, taskCfgId in ipairs(self.pTaskEventMapping[i_eTaskEventEnum]) do
        local tTaskData = self:GetTaskData(taskCfgId)
        if tTaskData and not self:IsCompleted(taskCfgId, tTaskData) and self:CheckTaskCondition(taskCfgId, i_tTaskConditions) then
            tTaskData[TaskDataIdx.TaskValue] = i_nSetTaskValue
            self:ChangeTaskData(tTaskData, i_bNotSendClient)
        end
    end
end

-- 检测任务条件是否通过
function CTaskSystem:CheckTaskCondition(i_nTaskCfgId, i_tTaskConditions)
    local tTaskConditionParams = ConfigExtend.GetTaskCfg_TaskConditionParams(i_nTaskCfgId)
    if #tTaskConditionParams == 0 then
        return true
    end
    if i_tTaskConditions == nil or #i_tTaskConditions == 0 then
        return false
    end

    for i, v in ipairs(tTaskConditionParams) do
        if not i_tTaskConditions[i] then
            return false
        end

        if i_tTaskConditions[i] ~= v then
            return false
        end
    end
    return true
end

-- 任务是否已完成
function CTaskSystem:IsCompleted(i_nTaskCfgId, i_tTaskData)
    if not i_tTaskData then
        i_tTaskData = self:GetTaskData(i_nTaskCfgId)
        if not i_tTaskData then
            return false
        end
    end

    if i_tTaskData[TaskDataIdx.TaskValue] == nil then
        i_tTaskData[TaskDataIdx.TaskValue] = 0
    end

    if i_tTaskData[TaskDataIdx.TaskValue] >= ConfigExtend.GetTaskCfg_TaskValueParam(i_nTaskCfgId) then
        return true
    end
    return false
end

-- 任务是否已领取
function CTaskSystem:IsReceiveAward(i_nTaskCfgId, i_tTaskData)
    if not i_tTaskData then
        i_tTaskData = self:GetTaskData(i_nTaskCfgId)
        if not i_tTaskData then
            return false
        end
    end

    if i_tTaskData[TaskDataIdx.IsReceiveAward] == nil then
        i_tTaskData[TaskDataIdx.IsReceiveAward] = 0
    end

    if i_tTaskData[TaskDataIdx.IsReceiveAward] == 1 then
        return true
    end
    return false
end

-- 领取任务奖励
function CTaskSystem:TaskReceiveAward(i_nTaskCfgId)
    local tTaskData = self:GetTaskData(i_nTaskCfgId)
    if not self:IsCompleted(i_nTaskCfgId, tTaskData) then
        return
    end
    if self:IsReceiveAward(i_nTaskCfgId, tTaskData) then
        return
    end

    local pPlayer = self:GetPlayer()

    if not self.pTaskCompleteRecord[i_nTaskCfgId] then
        self.pTaskCompleteRecord[i_nTaskCfgId] = 0
        delog("========> TaskReceiveAward -> not self.pTaskCompleteRecord[i_nTaskCfgId]", pPlayer:GetRoleID(), i_nTaskCfgId)
    end
    self.pTaskCompleteRecord[i_nTaskCfgId] = self.pTaskCompleteRecord[i_nTaskCfgId] + 1
    delog("========> TaskReceiveAward -> i_nTaskCfgId CompleteRecord = ", pPlayer:GetRoleID(), i_nTaskCfgId, self.pTaskCompleteRecord[i_nTaskCfgId])
    pPlayer:GetSystem("CBasicInfoSystem"):SetScore(self:GetTaskScore())

    tTaskData[TaskDataIdx.IsReceiveAward] = 1
    self:ChangeTaskData(tTaskData)
    pPlayer:SendToClient("C_SyncChangeTaskData", tTaskData)

    if not pPlayer:IsR() then
        CDataLog:LogDistTask_log(pPlayer:GetAccountID(), pPlayer:GetRoleID(), i_nTaskCfgId)
    end
end

-- 获取任务积分  版本特殊积分处理， 每日任务完成16次后，不再加积分，每次完成任务 重新按完成次数计算积分
function CTaskSystem:GetTaskScore()
    local nScore = 0
    for id, num in pairs(self.pTaskCompleteRecord) do
        local nNum = num
        if nNum > 16 then
            nNum = 16
        end
        nScore = nScore + ConfigExtend.GetTaskCfg_TaskAward(id) * nNum
    end
    return nScore
end

-- 任务数据变化
function CTaskSystem:ChangeTaskData(i_tTaskData, i_bNotSendClient)
    local tSaveData = {}
    for taskCfgId, data in pairs(self.pTaskDatas) do
        if data[TaskDataIdx.TaskValue] ~= 0 then
            table_insert(tSaveData, data)
        end
    end
    self.tSaveCaches["taskinfo"] = TableToStr(tSaveData, true)
    self.tSaveCaches["completerecord"] = TableToStr(self.pTaskCompleteRecord)

    local pPlayer = self:GetPlayer()
    if not i_bNotSendClient then
        pPlayer:SendToClient("C_SyncChangeTaskData", i_tTaskData)
    end
end

----------------------------------------------------------------
-- 客户端请求
----------------------------------------------------------------

-- 请求领取任务奖励
defineC.K_ReceiveTaskAwardReq = function(i_oPlayer, i_nTaskCfgId)
    i_oPlayer:GetSystem("CTaskSystem"):TaskReceiveAward(i_nTaskCfgId)
end
