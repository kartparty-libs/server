-- 平台管理器
local Platform = ServerInfo.Platform
local CPlatformManager = SingletonRequire("CPlatformManager")
-- 平台枚举
local PlatformEnum = {
	["duowanclouds"] = 1,	-- 多玩
}
local PfIndex = PlatformEnum[ServerInfo.Platform] or 0
-- 获取平台枚举
CPlatformManager.GetIndex = function ()
	return PfIndex
end
-- 是否多玩平台
CPlatformManager.IsDuowan = function ()
	return PfIndex == PlatformEnum["duowanclouds"]
end

