-- 全局加速
local __tonumber = tonumber
local __table_insert = table.insert

local __ConfigExtend = {}

----------------------------------------------------------------
--参数表
-- local ParamCfg_S = RequireConfig("ParamCfg_S")

-- function __ConfigExtend.GetMainMapCfgId()
--     return ParamCfg_S.MainMapCfgId.Int
-- end

----------------------------------------------------------------
--地图场景表
local MapCfg_S = RequireConfig("MapCfg_S")
function __ConfigExtend.GetMapCfg()
    return MapCfg_S
end
function __ConfigExtend.GetMapCfg_Id(i_CfgId)
    return MapCfg_S[i_CfgId]
end
function __ConfigExtend.GetMapCfg_SceneType(i_CfgId)
    return MapCfg_S[i_CfgId].SceneType
end
function __ConfigExtend.GetMapCfg_LineMaxPlayerNum(i_CfgId)
    return MapCfg_S[i_CfgId].LineMaxPlayerNum
end
function __ConfigExtend.GetMapCfg_Time(i_CfgId)
    return MapCfg_S[i_CfgId].Time
end
function __ConfigExtend.GetMapCfg_EndTime(i_CfgId)
    return MapCfg_S[i_CfgId].EndTime
end
function __ConfigExtend.GetMapCfg_IsRobot(i_CfgId)
    return MapCfg_S[i_CfgId].IsRobot == 1
end

----------------------------------------------------------------
--任务表
local TaskCfg_S = RequireConfig("TaskCfg_S")
function __ConfigExtend.GetTaskCfg()
    return TaskCfg_S
end
function __ConfigExtend.GetTaskCfg_TaskType(i_CfgId)
    return TaskCfg_S[i_CfgId].TaskType
end
function __ConfigExtend.GetTaskCfg_TaskEvent(i_CfgId)
    return TaskCfg_S[i_CfgId].TaskEvent
end
function __ConfigExtend.GetTaskCfg_TaskConditionParams(i_CfgId)
    return TaskCfg_S[i_CfgId].TaskConditionParams
end
function __ConfigExtend.GetTaskCfg_TaskValueParam(i_CfgId)
    return TaskCfg_S[i_CfgId].TaskValueParam
end
function __ConfigExtend.GetTaskCfg_TaskAward(i_CfgId)
    return TaskCfg_S[i_CfgId].TaskAward
end

----------------------------------------------------------------
--角色表
local RoleCfg_S = RequireConfig("RoleCfg_S")
function __ConfigExtend.GetRoleCfg()
    return RoleCfg_S
end

----------------------------------------------------------------
--赛车表
local CarCfg_S = RequireConfig("CarCfg_S")
function __ConfigExtend.GetCarCfg()
    return CarCfg_S
end

----------------------------------------------------------------
--头像表
local HeadCfg_S = RequireConfig("HeadCfg_S")
function __ConfigExtend.GetHeadCfg()
    return HeadCfg_S
end

----------------------------------------------------------------
--名字表
local NicknameCfg_S = RequireConfig("NicknameCfg_S")
function __ConfigExtend.GetNicknameCfg()
    return NicknameCfg_S
end

----------------------------------------------------------------
--邀请码表
local KartKeyCfg_S = RequireConfig("KartKeyCfg_S")
function __ConfigExtend.GetKartKeyCfg()
    return KartKeyCfg_S
end
function __ConfigExtend.GetKartKeyCfg_Pledge(i_CfgId)
    local tCfg = KartKeyCfg_S[i_CfgId]
    if not tCfg then
        return 0
    end
    return tCfg.Pledge
end
function __ConfigExtend.GetKartKeyCfg_IsRobot(i_CfgId)
    local tCfg = KartKeyCfg_S[i_CfgId]
    if not tCfg then
        return false
    end
    return tCfg.IsRobot == 1
end
function __ConfigExtend.GetKartKeyCfg_RobotType(i_CfgId)
    local tCfg = KartKeyCfg_S[i_CfgId]
    if not tCfg then
        return 1
    end
    return tCfg.RobotType
end
function __ConfigExtend.GetKartKeyCfg_IsNotRank(i_CfgId)
    local tCfg = KartKeyCfg_S[i_CfgId]
    if not tCfg then
        return false
    end
    return tCfg.IsNotRank == 1
end
----------------------------------------------------------------
--机器人类型表
local RobotTypeCfg_S = RequireConfig("RobotTypeCfg_S")
function __ConfigExtend.GetRobotTypeCfg()
    return RobotTypeCfg_S
end
function __ConfigExtend.GetRobotTypeyCfg_Param(i_CfgId, i_nDay)
    local tCfg = RobotTypeCfg_S[i_CfgId]
    if not tCfg then
        return
    end
    return tCfg["Day" .. i_nDay]
end

-------------------------------------代码写在此行以上-----------------------------------------
-- 最后注册全局变量，以便可以使用代码提示
ConfigExtend = __ConfigExtend
