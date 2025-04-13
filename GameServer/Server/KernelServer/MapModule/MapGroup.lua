-- global function
local print = print
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_remove = table.remove
-- global enum
local MapTypeEnum = RequireEnum("MapTypeEnum")
local ScheduleTaskCycleTypeEnum = RequireEnum("ScheduleTaskCycleTypeEnum");
-- global singleton
local CMapManager = SingletonRequire("CMapManager")
local CPlayerManager = SingletonRequire("CPlayerManager")
local CSchedule				= SingletonRequire("CSchedule");

-- local
local CMapGroup = ClassRequire("CMapGroup")

function CMapGroup:_constructor(i_nCfgID, i_nMaxPlayerNum)
    self.m_nCfgID = i_nCfgID
    self.m_tMapSet = {}
    self.m_nMapNum = 0
    self.m_nPlayerNum = 0
    self.m_nMaxPlayerNum = i_nMaxPlayerNum
    self:CreateNewMap(false)

    local function free()
        self:FreeTheLastMap()
    end
    CSchedule:AddTask({}, ScheduleTaskCycleTypeEnum.eMinute, 1, 0, free, {})
end

function CMapGroup:CreateNewMap(i_bOccupy)
    self.m_nMapNum = self.m_nMapNum + 1
    local oMap = CMapManager:CreateMap(self.m_nCfgID, {m_nLineID = self.m_nMapNum}, self, i_bOccupy)
    table_insert(self.m_tMapSet, oMap)
    oMap:SetGroupInfo(self, self.m_nMapNum)
    return oMap
end

function CMapGroup:FreeTheLastMap()
    if self.m_nMapNum == 1 then
        return
    end
    local oMap = self.m_tMapSet[self.m_nMapNum]
    if not self:IsCompetition() then
        return
    end
    -- print(debug.traceback())
    if oMap:GetPlayerNum() > 0 then
        return
    end
    if oMap:GetOrderNum() > 0 then
        return
    end
    if oMap:GetMapOccupy() then
        return
    end
    print("=====WARNING!!! FreeTheLastMap=====", oMap:GetMapCfgID(), self.m_nMapNum)
    self.m_tMapSet[self.m_nMapNum] = nil
    self.m_nMapNum = self.m_nMapNum - 1
    oMap:Destroy()
end

function CMapGroup:GetOneMap()
    local oOne, nIdx
    if not self:IsCompetition() then
        for i, oMap in ipairs(self.m_tMapSet) do
            if oMap:GetPlayerNum() < self.m_nMaxPlayerNum then
                oOne = oMap
                nIdx = i
                break
            end
        end
        oOne = oOne or self:CreateNewMap(false)
    else
        for i, oMap in ipairs(self.m_tMapSet) do
            if not oMap:GetMapOccupy() then
                oOne = oMap
                nIdx = i
                break
            end
        end
        oOne = oOne or self:CreateNewMap(true)
    end
    return oOne
end

-- 是否是比赛地图组
function CMapGroup:IsCompetition()
    return ConfigExtend.GetMapCfg_SceneType(self.m_nCfgID) == MapTypeEnum.eCompetition
end

function CMapGroup:GetLineNum()
    return self.m_nMapNum
end

function CMapGroup:GetMapByLineID(i_nLineID)
    return self.m_tMapSet[i_nLineID]
end

function CMapGroup:OnPlayerEnterMap(i_oMap, i_oPlayer)
    self.m_nPlayerNum = self.m_nPlayerNum + 1
end

function CMapGroup:OnPlayerLeaveMap(i_oMap, i_oPlayer)
    self.m_nPlayerNum = self.m_nPlayerNum - 1
end

function CMapGroup:OnMapDestruct(i_tReport, i_oMap)
end
