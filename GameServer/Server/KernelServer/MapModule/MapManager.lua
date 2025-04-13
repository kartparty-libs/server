-- global enum
local MapTypeEnum = RequireEnum("MapTypeEnum")
local EnterMapError = RequireEnum("EnterMapError")

local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
local CPlayerManager = SingletonRequire("CPlayerManager")
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager")
local now = _commonservice.now
-- global function
local print = print
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local math_ceil = math.ceil
local math_floor = math.floor
local math_random = math.random
local NewClass = ClassNew
-- global singleton
-- global config

-- 各类地图映射
local MapClassStr = {
    [MapTypeEnum.eCommon] = "CMap", -- 公共场景
    [MapTypeEnum.eCompetition] = "CCompetitionMap", -- 比赛场景
    [MapTypeEnum.eDodgems] = "CDodgemsMap", -- 碰碰车场景
}

local CMapManager = SingletonRequire("CMapManager")
function CMapManager:Initialize()
    self.m_nInstanceID = 1
    self.m_tInstID2Map = {}
    self.m_tMapGrop = {}
    for k, nSceneType in pairs(MapTypeEnum) do
        self.m_tMapGrop[nSceneType] = {}
    end
    local MapCfg = ConfigExtend.GetMapCfg()
    for mapid, cfg in pairs(MapCfg) do
        if not self.m_tMapGrop[cfg.SceneType] then
            self.m_tMapGrop[cfg.SceneType] = {}
        end
        self.m_tMapGrop[cfg.SceneType][mapid] = NewClass("CMapGroup", mapid, cfg.LineMaxPlayerNum)
    end

    return true
end

function CMapManager:OnDayRefresh()
end

function CMapManager:Update(i_nDeltaMsec)
    for i,oMap in pairs(self.m_tInstID2Map) do
        oMap:Update(i_nDeltaMsec);
    end
end

function CMapManager:CreateMap(i_nMapCfgID, i_tAppendInfo, i_oObserver, i_bOccupy)
    local nType = ConfigExtend.GetMapCfg_SceneType(i_nMapCfgID)
    local sClassStr = MapClassStr[nType]
    local oMap = NewClass(sClassStr, i_nMapCfgID, self.m_nInstanceID, self, i_tAppendInfo, i_oObserver, i_bOccupy)
    self.m_tInstID2Map[self.m_nInstanceID] = oMap
    self.m_nInstanceID = self.m_nInstanceID + 1
    return oMap
end

function CMapManager:DestroyMap(i_nMapInstID)
    local oMap = self.m_tInstID2Map[i_nMapInstID]
    local nMapCfgID = oMap:GetMapCfgID()
    if self:IsCommon(nMapCfgID) then
        print("=====WARNING!!! DestroyMap=====", i_nMapInstID, nMapCfgID)
        print(debug.traceback())
        return
    end
    self.m_tInstID2Map[i_nMapInstID] = nil
    oMap:Destruct()
end

-- 根据地图实例ID获取地图对象
function CMapManager:GetMapByInstID(i_nInstID)
    return self.m_tInstID2Map[i_nInstID]
end
function CMapManager:GetInstID2Map()
    return self.m_tInstID2Map
end

-- 根据地图配置ID获取一个图
function CMapManager:GetOneMapByCfgId(i_nMapCfgID)
    local nSceneType = ConfigExtend.GetMapCfg_SceneType(i_nMapCfgID)
    local oMapGroup = self.m_tMapGrop[nSceneType][i_nMapCfgID]
    if oMapGroup then
        return oMapGroup:GetOneMap()
    end
end

-- 根据地图配置ID和线路ID获取一个地图
function CMapManager:GetoneMapByCfgIdLineId(i_nMapCfgID, i_nLineID)
    local nSceneType = ConfigExtend.GetMapCfg_SceneType(i_nMapCfgID)
    local oMapGroup = self.m_tMapGrop[nSceneType][i_nMapCfgID]
    if oMapGroup then
        return oMapGroup:GetMapByLineID(i_nLineID)
    end
end

local fCheckValid
-- 进入场景实例(场景已经创建)
function CMapManager:EnterInstMap(i_nMapInstID, i_tPlayerSet)
    local oMap = self:GetMapByInstID(i_nMapInstID)
    if not oMap then
        return false
    end
    if oMap:GetCanNotEnter() then
        return false
    end
    local nMapCfgID = oMap:GetMapCfgID()
    print("CMapManager:EnterInstMap", nMapCfgID, type(nMapCfgID))
    local bResult, tErrorInfo = fCheckValid(nMapCfgID, i_tPlayerSet)
    if bResult then
        -- 切换地图
        for _, oPlayer in ipairs(i_tPlayerSet) do
            oPlayer:SwitchMap(oMap)
        end
    end
    return bResult, tErrorInfo
end

-- 进入配置场景(创建场景)
function CMapManager:CreateAndEnterCfgMap(i_nMapCfgID, i_tPlayerSet, i_tAppendInfo, i_oObserver)
    local bResult, tErrorInfo = fCheckValid(i_nMapCfgID, i_tPlayerSet)
    local oMap
    if bResult then
        i_tAppendInfo = i_tAppendInfo or {}
        -- 创建副本
        oMap = self:CreateMap(i_nMapCfgID, i_tAppendInfo, i_oObserver)
        for _, oPlayer in ipairs(i_tPlayerSet) do
            oPlayer:SwitchMap(oMap)
        end
    end
    return bResult, tErrorInfo, oMap
end

-- 是否是主场景
function CMapManager:IsCommon(i_nMapCfgID)
    return ConfigExtend.GetMapCfg_SceneType(i_nMapCfgID) == MapTypeEnum.eCommon
end

-------------
-- private --
-------------

-- 检测玩家是否能够进入指定配置ID地图
fCheckValid = function(i_nMapCfgID, i_tPlayerSet)
    if #i_tPlayerSet == 0 then
        return false, {EnterMapError.eNoPlayer}
    end
    return true, {EnterMapError.eSuccess}
end

----
-- msg --
---------
-- GS上地图需要销毁
defineS.K_MapDestroyReq = function(i_nMapInstID, i_tReport)
    local oMap = CMapManager:GetMapByInstID(i_nMapInstID)
    oMap:Destroy(i_tReport)
end

defineS.K_MapTimeNotEnough = function(i_nMapInstID)
    local oMap = CMapManager:GetMapByInstID(i_nMapInstID)
    oMap:SetCanNotEnter()
end
