--[[
	@brief 本服排行榜
	@author Hou
]]
local ipairs = ipairs
local pairs = pairs
local next = next
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local table_unpack = table.unpack
local math_floor = math.floor
local math_min = math.min
local now = _commonservice.now
local CDBCommand = SingletonRequire("CDBCommand")
local CSchedule = SingletonRequire("CSchedule")
local RankTypeEnum = RequireEnum("RankTypeEnum")
local RankRoleDataIdxEnum = RequireEnum("RankRoleDataIdxEnum")
local ScheduleTaskCycleTypeEnum = RequireEnum("ScheduleTaskCycleTypeEnum")
local CCommonFunction = SingletonRequire("CCommonFunction")

-- 简要数据下标枚举
local RoleIdCol = 1 -- roleid在tRank中的下标
local MainCol = 2 -- 主数据在tRank中的下标
local ViceCol = 3 -- 两个条件数据在tRank中的下标
local NextCol = 4 -- 三个条件在tRank中的下标

-- 定时保存间隔
local SaveInterval = 30 * 60000
-- 一次保存的数量上限
local OneSaveMaxNum = 50

-- 最低排名
local MinRankEnum = {
    [RankTypeEnum.eScoreRank] = 10000
}

-- 排行榜条件类型
local tbRankType = {
    Main = 1, -- 一个条件
    Vice = 2, -- 两个条件
    Next = 3 -- 三个条件
}

-- 各种load函数
local tbRankFunc = {
    [tbRankType.Main] = function(tRank, tRolePos, res, pos)
        table_insert(
            tRank,
            {
                res.roleid,
                res.mainvalue
            }
        )
        tRolePos[res.roleid] = pos
    end,
    [tbRankType.Vice] = function(tRank, tRolePos, res, pos)
        table_insert(
            tRank,
            {
                res.roleid,
                res.mainvalue,
                res.vicevalue
            }
        )
        tRolePos[res.roleid] = pos
    end,
    [tbRankType.Next] = function(tRank, tRolePos, res, pos)
        table_insert(
            tRank,
            {
                res.roleid,
                res.mainvalue,
                res.vicevalue,
                res.nextvalue
            }
        )
        tRolePos[res.roleid] = pos
    end
}

-- 排序字段
local tbRankOrder = {
    [tbRankType.Main] = "`mainvalue` desc",
    [tbRankType.Vice] = "`mainvalue` desc, `vicevalue` desc",
    [tbRankType.Next] = "`mainvalue` desc, `vicevalue` desc, `nextvalue` desc"
}

-- 各种字段信息
local tbRankKeys = {
    [tbRankType.Main] = {"roleid", "mainvalue"},
    [tbRankType.Vice] = {"roleid", "mainvalue", "vicevalue"},
    [tbRankType.Next] = {"roleid", "mainvalue", "vicevalue", "nextvalue"}
}

local tbRankValues = {
    [tbRankType.Main] = function(tRank)
        return {tRank[RoleIdCol], tRank[MainCol]}
    end,
    [tbRankType.Vice] = function(tRank)
        return {tRank[RoleIdCol], tRank[MainCol], tRank[ViceCol]}
    end,
    [tbRankType.Next] = function(tRank)
        return {tRank[RoleIdCol], tRank[MainCol], tRank[ViceCol], tRank[NextCol]}
    end
}

-- 排行榜数据表信息
local RankDBInfo = {
    [RankTypeEnum.eScoreRank] = {tbName = "rank_score", nType = tbRankType.Main} -- 积分榜
}

local CRankManager = SingletonRequire("CRankManager")
function CRankManager:Initialize()
    -- 本服排行
    self.m_tRank = {}
    -- 辅助表（快速定位）
    self.m_tRolePos = {}
    -- 角色简要数据
    self.m_tRoleData = {}
    -- 用于定时保存数据
    self.m_nSaveTime = SaveInterval

    -- 定时缓存排行
    self.m_tBufferRank = {}
    -- 定时缓存玩家定位
    self.m_tBufferRolePos = {}

    for _, v in pairs(RankTypeEnum) do
        self.m_tRank[v] = {}
        self.m_tRolePos[v] = {}
    end
    self.m_tSaveRank = {}
    self:LoadData()
    self:AgainRankUpdate()

    for i, v in ipairs(ServerInfo.BufferRankTime) do
        CSchedule:AddTask({m_sTime = v[1] .. ":" .. v[2]}, ScheduleTaskCycleTypeEnum.eDay, 1, 0, self.AgainRankUpdate, {self})
    end

    return true
end

function CRankManager:LoadData()
    -- 填充 m_tRoleData
    local oCmd = CDBCommand:CreateSelectCmd("role")
    oCmd:SetFields("roleid")
    oCmd:SetFields("rolename")
    oCmd:SetFields("kartkey")
    oCmd:SetFields("email")
    local tRes = oCmd:Execute()
    if tRes and #tRes > 0 then
        local rid
        for _, res in ipairs(tRes) do
            rid = res.roleid
            local nPledge = ConfigExtend.GetKartKeyCfg_Pledge(res.kartkey)
            self.m_tRoleData[rid] = {
                [RankRoleDataIdxEnum.eRoleId] = rid, -- roleid
                [RankRoleDataIdxEnum.eName] = res.rolename, -- 名字
                [RankRoleDataIdxEnum.eEmail] = res.email, -- 邮箱
                [RankRoleDataIdxEnum.eScore] = nPledge, -- 先存质押分
                [RankRoleDataIdxEnum.eKartKey] = res.kartkey -- 激活码
            }
        end
    end
    oCmd = CDBCommand:CreateSelectCmd("role_basicinfo")
    oCmd:SetFields("roleid")
    oCmd:SetFields("head")
    oCmd:SetFields("score")
    local tInfoRes = oCmd:Execute()
    local tData
    if tInfoRes and #tInfoRes > 0 then
        for _, res in ipairs(tInfoRes) do
            tData = self.m_tRoleData[res.roleid]
            if tData then
                tData[RankRoleDataIdxEnum.eHead] = res.head or 1
                if res.score then
                    tData[RankRoleDataIdxEnum.eScore] = tData[RankRoleDataIdxEnum.eScore] + res.score
                end
            end
        end
    end

    -- delog("CRankManager LoadData => rank update start")
    -- if next(self.m_tRoleData) then
    --     for rankType, info in pairs(RankDBInfo) do
    --         for k, v in pairs(self.m_tRoleData) do
    --             if v[RankRoleDataIdxEnum.eScore] > 0 then
    --                 self:RankUpdate(info.nType, k, v[RankRoleDataIdxEnum.eScore])
    --             end
    --         end
    --     end
    -- end
    -- delog("CRankManager LoadData => rank update end")

    -- 填充 m_tRank m_tRolePos
    -- local tRank, tRoleP, func
    -- for rankType, info in pairs(RankDBInfo) do
    --     oCmd = CDBCommand:CreateSelectCmd(info.tbName)
    --     oCmd:OrderBy(tbRankOrder[info.nType], true, true)
    --     oCmd:SetLimit(MinRankEnum[rankType])
    --     tRes = oCmd:Execute()
    --     tRank = self.m_tRank[rankType]
    --     tRoleP = self.m_tRolePos[rankType]
    --     func = tbRankFunc[info.nType]
    --     if tRes and #tRes > 0 then
    --         for i, res in ipairs(tRes) do
    --             -- 这里是防止排行榜里存放了已经不存在的玩家
    --             if self.m_tRoleData[res.roleid] then
    --                 func(tRank, tRoleP, res, i)
    --             end
    --         end
    --     end
    -- end
end

local function sortFunc(a, b)
    return a[MainCol] > b[MainCol]
end
function CRankManager:AgainRankUpdate()
    self.m_tRank = {}
    self.m_tRolePos = {}

    for _, v in pairs(RankTypeEnum) do
        self.m_tRank[v] = {}
        self.m_tRolePos[v] = {}
    end

    delog("CRankManager LoadData => rank update start")
    if next(self.m_tRoleData) then
        for rankType, info in pairs(RankDBInfo) do
            for k, v in pairs(self.m_tRoleData) do
                if v[RankRoleDataIdxEnum.eScore] > 0 then
                    self:RankUpdate(info.nType, k, v[RankRoleDataIdxEnum.eScore])
                end
            end
        end
    end

    -- 剔除不参与排行的机器人
    for _, v in pairs(RankTypeEnum) do
        local nRankNum = #self.m_tRank[v]
        for i = nRankNum, 1, -1 do
            local tData = self.m_tRank[v][i]
            tData = self.m_tRoleData[tData[1]]
            local sKartKey = tData[RankRoleDataIdxEnum.eKartKey]
            if sKartKey and ConfigExtend.GetKartKeyCfg_IsNotRank(sKartKey) then
                table_remove(self.m_tRank[v], i)
            end
        end
    end

    for _, v in pairs(RankTypeEnum) do
        table.sort(self.m_tRank[v], sortFunc)

        for i, data in ipairs(self.m_tRank[v]) do
            self.m_tRolePos[v][data[RoleIdCol]] = i
        end
    end
    self:BufferRank()
    delog("CRankManager LoadData => rank update end")
end

function CRankManager:SaveData()
    -- local oCmd, getFunc
    -- for rankType, info in pairs(RankDBInfo) do
    --     repeat
    --         oCmd = CDBCommand:CreateDeleteCmd(info.tbName)
    --         oCmd:SetNoWhere()
    --         oCmd:Execute()
    --         if not next(self.m_tRank[rankType]) then
    --             break
    --         end
    --         oCmd = CDBCommand:CreateInsertCmd(info.tbName)
    --         oCmd:SetKeys(tbRankKeys[info.nType])
    --         getFunc = tbRankValues[info.nType]
    --         for _, v in ipairs(self.m_tRank[rankType]) do
    --             oCmd:SetMultiValues(getFunc(v))
    --         end
    --         oCmd:Execute()
    --     until true
    -- end
    self:BeginDelaySave()
    self:DelaySaveData()
end

function CRankManager:BeginDelaySave()
    local getFunc, temp
    for rankType, info in pairs(RankDBInfo) do
        self.m_tSaveRank[rankType] = {}
        temp = self.m_tSaveRank[rankType]
        getFunc = tbRankValues[info.nType]
        for _, v in ipairs(self.m_tRank[rankType]) do
            table_insert(temp, getFunc(v))
        end
    end
end

function CRankManager:DelaySaveData()
    local nType, tData = next(self.m_tSaveRank)
    if not nType then
        return
    end

    if not tData or not next(tData) then
        self.m_tSaveRank[nType] = nil
        return
    end

    local tbInfo = RankDBInfo[nType]
    local oCmd = CDBCommand:CreateDeleteCmd(tbInfo.tbName)
    oCmd:SetNoWhere()
    oCmd:Execute()

    local nNum = #tData
    while nNum > 0 do
        local tInsertData = {}
        if #tData > OneSaveMaxNum then
            for i = 1, OneSaveMaxNum do
                table_insert(tInsertData, table_remove(tData))
            end

            nNum = #tData
        else
            tInsertData = tData
            nNum = 0
        end
        oCmd = CDBCommand:CreateInsertCmd(tbInfo.tbName)
        oCmd:SetKeys(tbRankKeys[tbInfo.nType])

        for _, v in ipairs(tInsertData) do
            oCmd:SetMultiValues(v)
        end
        oCmd:Execute()
    end

    self.m_tSaveRank[nType] = nil
end

function CRankManager:Update(i_nDeltaMSec)
    self.m_nSaveTime = self.m_nSaveTime - i_nDeltaMSec
    if self.m_nSaveTime <= 0 then
        self.m_nSaveTime = self.m_nSaveTime + SaveInterval
        self:BeginDelaySave()
    else
        self:DelaySaveData()
    end
end

-- 每日调用发奖励
function CRankManager:OnDayRefresh()
end

function CRankManager:OnWeekRefresh()
    self:SendRankAward()
end

function CRankManager:SendRankAward()
end

function CRankManager:Destruct()
    self.m_tSaveRank = {}
    self:SaveData()
end

-- 排行榜刷新
function CRankManager:RankUpdate(i_nType, i_sRoleId, i_nMainValue, i_nViceValue, i_nNextValue)
    local tRank = self.m_tRank[i_nType]
    local tRoleP = self.m_tRolePos[i_nType]
    local nCurPos = tRoleP[i_sRoleId]
    -- 获取排行榜数据类型
    local nRankType = RankDBInfo[i_nType].nType
    local tbValues = {i_nMainValue, i_nViceValue, i_nNextValue}
    if #tbValues <= 0 then
        return
    end
    -- 如果已在榜内
    if nCurPos then
        local bCanUpdate = false
        local tbOldValues = tbRankValues[nRankType](tRank[nCurPos])
        for nIdx, nVal in ipairs(tbValues) do
            local nOldVal = tbOldValues[nIdx + 1] -- 为什么nIdx要+1 因为这个里面1是roleid
            if nVal < nOldVal then
                bCanUpdate = false
                break
            elseif nVal > nOldVal then
                bCanUpdate = true
                break
            end
        end
        -- 如果当前的属性和之前的一样或者不如之前的 则不刷新排行
        if not bCanUpdate then
            return
        end

        -- 附上值
        for nIdx, nVal in ipairs(tbValues) do
            tRank[nCurPos][nIdx + 2] = nVal
        end

        local nPos = nCurPos
        while nPos > 1 do
            local bCurPos = false
            -- 获取上一名的信息
            local tbLastValues = tbRankValues[nRankType](tRank[nPos - 1])
            for nIdx, nVal in ipairs(tbValues) do
                local nLastVal = tbLastValues[nIdx + 1] -- 为什么nIdx要+1 因为这个里面1是roleid
                if nVal > nLastVal then
                    break
                elseif nVal < nLastVal then
                    bCurPos = true
                    break
                elseif (nVal <= nLastVal) and (nIdx == #tbValues) then
                    bCurPos = true
                    break
                end
            end
            if bCurPos then
                break
            end
            nPos = nPos - 1
        end
        if nPos ~= nCurPos then
            tRoleP[i_sRoleId] = nPos
            local tTemp = tRank[nCurPos]
            for i = nCurPos - 1, nPos, -1 do
                tRoleP[tRank[i][RoleIdCol]] = tRoleP[tRank[i][RoleIdCol]] + 1
                tRank[i + 1] = tRank[i]
            end
            tRank[nPos] = tTemp
        end
    else -- 没在榜内
        local nNum = #tRank
        local nPos = nNum + 1
        while nPos > 1 do
            local bCurPos = false
            -- 获取上一名的信息
            local tbLastValues = tbRankValues[nRankType](tRank[nPos - 1])
            for nIdx, nVal in ipairs(tbValues) do
                local nLastVal = tbLastValues[nIdx + 1] -- 为什么nIdx要+1 因为这个里面1是roleid
                if nVal > nLastVal then
                    break
                elseif nVal < nLastVal then
                    bCurPos = true
                    break
                elseif (nVal <= nLastVal) and (nIdx == #tbValues) then
                    bCurPos = true
                    break
                end
            end
            if bCurPos then
                break
            end
            nPos = nPos - 1
        end
        if nPos > MinRankEnum[i_nType] then -- 没进榜
            return
        end
        local tRankInfo = {
            i_sRoleId
        }
        for _, nVal in ipairs(tbValues) do
            table_insert(tRankInfo, nVal)
        end
        table_insert(tRank, nPos, tRankInfo)
        tRoleP[i_sRoleId] = nPos
        -- 去掉垫底的
        if nNum == MinRankEnum[i_nType] then
            local tRem = table_remove(tRank)
            tRoleP[tRem[RoleIdCol]] = nil
        end
        for i = nPos + 1, #tRank do
            tRoleP[tRank[i][RoleIdCol]] = tRoleP[tRank[i][RoleIdCol]] + 1
        end
    end
end

-- 新增roledata
function CRankManager:AddRoleData(i_oPlayer)
    local sRoleId = i_oPlayer:GetRoleID()
    self.m_tRoleData[sRoleId] = {
        [RankRoleDataIdxEnum.eRoleId] = sRoleId,
        [RankRoleDataIdxEnum.eName] = i_oPlayer:GetName(), -- 名字
        [RankRoleDataIdxEnum.eHead] = i_oPlayer:GetSystem("CBasicInfoSystem"):GetHead(), -- 头像
        [RankRoleDataIdxEnum.eScore] = i_oPlayer:GetSystem("CBasicInfoSystem"):GetScoreAndPledge(), -- 积分
        [RankRoleDataIdxEnum.eEmail] = i_oPlayer:GetEmail(), -- 邮箱
        [RankRoleDataIdxEnum.eKartKey] = i_oPlayer:GetKartKey() -- 激活码
    }
end

-- 缓存排行榜
function CRankManager:BufferRank()
    self.m_tBufferRank = {}
    self.m_tBufferRolePos = {}
    for i, type in pairs(RankTypeEnum) do
        local tRolePos = self.m_tRolePos[type]
        if tRolePos then
            self.m_tBufferRolePos[type] = {}
            for k, v in pairs(tRolePos) do
                self.m_tBufferRolePos[type][k] = v
            end
        end

        local tRank = self.m_tRank[type]
        if tRank then
            self.m_tBufferRank[type] = {}
            local nNum = #tRank
            if nNum > 0 then
                local tData
                local tTemp
                for i = 1, nNum do
                    tData = tRank[i]
                    if not tData then
                        break
                    end
                    local tTemp = {}
                    local tRoleData = self.m_tRoleData[tData[1]]
                    if not tRoleData then
                        break
                    end
                    table_insert(tTemp, i)
                    for key, value in ipairs(tRoleData) do
                        if key == RankRoleDataIdxEnum.eKartKey then
                            table_insert(tTemp, "")
                        else
                            table_insert(tTemp, value)
                        end
                    end
                    table_insert(self.m_tBufferRank[type], tTemp)
                end
            end
        end
    end

    print("CRankManager buffer rank")
end

-- 请求本服排行
function CRankManager:DataReqHandler(i_oPlayer, i_nType, i_nStartIndex, i_nEndIndex)
    local tBufferRolePos = self.m_tBufferRolePos[i_nType]
    local tBufferRank = self.m_tBufferRank[i_nType]
    if not tBufferRank then
        return
    end

    local tBuffer = {}
    local nBufferNum = #tBufferRank
    if nBufferNum == 0 or i_nStartIndex > nBufferNum then
        return
    end

    local nStart = i_nStartIndex
    local nEnd = i_nEndIndex
    if nEnd > nBufferNum then
        nEnd = nBufferNum
    end

    for i = nStart, nEnd do
        table_insert(tBuffer, tBufferRank[i])
    end
    i_oPlayer:SendToClient("C_RankData", i_nType, tBuffer)
end

-- function CRankManager:DataReqHandler(i_oPlayer, i_nType, i_nStartIndex, i_nEndIndex)
--     local tRank = self.m_tRank[i_nType]
--     if not tRank then
--         return
--     end
--     local tBuffer = {}
--     local tOnline = {}
--     local tOtherData = {}
--     local nNum = #tRank
--     local tSelfRankData = {}
--     local nRolePos = self.m_tRolePos[i_nType][i_oPlayer:GetRoleID()]
--     if not nRolePos then
--         table_insert(tSelfRankData, 0)
--     else
--         local tData = tRank[nRolePos]
--         if tData then
--             local tRoleData = self.m_tRoleData[i_oPlayer:GetRoleID()]
--             if tRoleData then
--                 table_insert(tSelfRankData, nRolePos)
--                 for key, value in ipairs(tRoleData) do
--                     table_insert(tSelfRankData, value)
--                 end
--             end
--         end
--     end

--     if nNum == 0 or i_nStartIndex > nNum then
--         return
--     end

--     local nEnd = i_nEndIndex > nNum and nNum or i_nEndIndex
--     local tData
--     local tTemp
--     for i = i_nStartIndex, nEnd do
--         tData = tRank[i]
--         if not tData then
--             break
--         end
--         local tTemp = {}
--         local tRoleData = self.m_tRoleData[tData[1]]
--         if not tRoleData then
--             break
--         end
--         table_insert(tTemp, i)
--         for key, value in ipairs(tRoleData) do
--             table_insert(tTemp, value)
--         end
--         table_insert(tBuffer, tTemp)
--     end

--     i_oPlayer:SendToClient("C_RankData", i_nType, tBuffer, tSelfRankData)
-- end

function CRankManager:ReqSelfRankData(i_oPlayer, i_nType)
    local tBufferRolePos = self.m_tBufferRolePos[i_nType]
    local tBufferRank = self.m_tBufferRank[i_nType]
    if not tBufferRank then
        return
    end

    local tSelfRankData = {0}
    if tBufferRolePos then
        local nRolePos = tBufferRolePos[i_oPlayer:GetRoleID()]
        if nRolePos and nRolePos > 0 and #tBufferRank >= nRolePos then
            tSelfRankData = tBufferRank[nRolePos]
        end
    end

    local nNowTime = now(1)
    local nRankStartTime = CCommonFunction.GetTodayThisTimeSec(ServerInfo.BufferRankTime[1][1], ServerInfo.BufferRankTime[1][2], 0)
    local nRankEndTime = CCommonFunction.GetTodayThisTimeSec(ServerInfo.BufferRankTime[2][1], ServerInfo.BufferRankTime[2][2], 0)
    local nTime = nRankStartTime

    if nNowTime < nRankStartTime then
        nTime = nRankStartTime - nNowTime
    elseif nNowTime < nRankEndTime then
        nTime = nRankEndTime - nNowTime
    else
        nTime = nRankStartTime + 86400 - nNowTime
    end
    i_oPlayer:SendToClient("C_SelfRankData", i_nType, tSelfRankData, nTime)
end

function CRankManager:RoleResumeReq(i_oPlayer, i_sRoleId)
    local tData = self.m_tRoleData[i_sRoleId]
    if not tData then
        i_oPlayer:SendToClient("C_RoleResume")
        return
    end
    i_oPlayer:SendToClient(
        "C_RoleResume",
        {
            tData[RankRoleDataIdxEnum.eRoleId],
            tData[RankRoleDataIdxEnum.eName],
            tData[RankRoleDataIdxEnum.eHead],
            tData[RankRoleDataIdxEnum.eScore],
            tData[RankRoleDataIdxEnum.eEmail]
        }
    )
end

-- 取得玩家简要数据
function CRankManager:GetRankRoleResume(i_sRoleID)
    local tData = self.m_tRoleData[i_sRoleID]
    if not tData then
        return
    end
    return tData
end

-- 取得排行名次
function CRankManager:GetRankOrder(i_nType, i_sRoleID)
    return self.m_tRolePos[i_nType][i_sRoleID] or 0
end

--获取某个排行榜数据
function CRankManager:GetRankBuyType(i_nType)
    return self.m_tRank[i_nType] or {}
end

--获取某个排行榜数据
function CRankManager:GetRankNumBuyType(i_nType)
    return #self.m_tRank[i_nType] or 0
end

--获取某个排行榜某个排名数据
function CRankManager:GetRankInfoBuyPos(i_nType, i_nPos)
    if not self.m_tRank[i_nType] or not self.m_tRank[i_nType][i_nPos] then
        return nil
    end
    return self.m_tRank[i_nType][i_nPos]
end

-- 玩家积分变化
function CRankManager:OnScoreChange(i_oPlayer, i_nScore)
    local tData = self.m_tRoleData[i_oPlayer:GetRoleID()]
    if not tData then
        self:AddRoleData(i_oPlayer)
    else
        tData[RankRoleDataIdxEnum.eScore] = i_nScore
    end

    if ConfigExtend.GetKartKeyCfg_IsNotRank(i_oPlayer:GetKartKey()) then
        return
    end

    self:RankUpdate(RankTypeEnum.eScoreRank, i_oPlayer:GetRoleID(), i_nScore)
end

-- 玩家头像变化
function CRankManager:SetHeadChange(i_oPlayer, i_nHeadId)
    local tData = self.m_tRoleData[i_oPlayer:GetRoleID()]
    if tData then
        tData[RankRoleDataIdxEnum.eHead] = i_nHeadId
    end
end

-- 玩家名字变化
function CRankManager:SetNameChange(i_oPlayer, i_sName)
    local tData = self.m_tRoleData[i_oPlayer:GetRoleID()]
    if tData then
        tData[RankRoleDataIdxEnum.eName] = i_sName
    end
end

function CRankManager:ReqRank(i_oPlayer, i_nType)
    local nRoleID = i_oPlayer:GetRoleID()
    local nRank = self.m_tRolePos[i_nType][nRoleID]
    i_oPlayer:SendToClient("C_ReqRank", nRank)
end

-- 获取排行榜
function CRankManager:GetRank(i_nType)
    return self.m_tRank[i_nType]
end

-- 将玩家从排行榜移除
function CRankManager:RankRemovalPlayer(i_oPlayer, i_nType)
    local nRoleID = i_oPlayer:GetRoleID()
    local tRolePos = self.m_tRolePos[i_nType]
    local nRank = tRolePos[nRoleID]
    if not nRank then
        return
    end
    local tRank = self.m_tRank[i_nType]
    self.m_tRolePos[i_nType][nRoleID] = nil
    table_remove(tRank, nRank)
    for nFlag = nRank, #tRank do
        local nRID = tRank[nFlag][RoleIdCol]
        tRolePos[nRID] = nFlag
    end
end

----清空某个排行榜数据
function CRankManager:ClearOneRank(i_nRankType)
    self.m_tRank[i_nRankType] = {}
    self.m_tRolePos[i_nRankType] = {}
    local oImageCmd = CDBCommand:CreateDeleteCmd(RankDBInfo[i_nRankType].tbName)
    oImageCmd:SetNoWhere()
    oImageCmd:Execute(true)
end

---------------消息专区----------------
-- 请求本服排行数据
defineC.K_RankDataReq = function(i_oPlayer, i_nType, i_nStartIndex, i_nEndIndex)
    if type(i_nStartIndex) ~= "number" then
        return
    end
    CRankManager:DataReqHandler(i_oPlayer, i_nType, i_nStartIndex, i_nEndIndex)
end

-- 请求玩家自己的排名数据
defineC.K_ReqSelfRankData = function(i_oPlayer, i_nType)
    CRankManager:ReqSelfRankData(i_oPlayer, i_nType)
end

-- 请求测试时间段排行榜快照
defineC.K_ReqBufferRank = function(i_oPlayer)
end

-- 请求测试时间段排行榜快照
defineC.K_ReqBufferRankTest = function(i_oPlayer)
    CRankManager:AgainRankUpdate()
end
