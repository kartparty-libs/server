--[[
	@brief	带超链接的系统提示类
	@author	Hou
]]
local table_insert = table.insert
-- 类型枚举
local ETypeRole = 1	-- 角色信息（角色名，角色id，vip等级）
local ETypeItem = 2	-- 道具信息（配置id）
local ETypeMon = 3		-- 怪物信息（配置怪物id）
local ETypeWeapon = 4	-- 武器信息（武器id, 觉醒状态）

local TipsType = {
			CommonEnum = 1, --普通信息
			RoleEnum = 2, 	--玩家信息
			ItemEnum = 3, 	--物品信息
			}

local KnowTypeEnum = {
}
local CLinkTips = ClassRequire("CLinkTips")
function CLinkTips:_constructor()
	self.m_tParams = {}
end
-- 增加普通参数
function CLinkTips:AddParam(...)
	for i, i_Param in ipairs(arg) do
		table_insert(self.m_tParams, {TipsType.CommonEnum, i_Param})
	end
end

-- 增加物品信息
function CLinkTips:AddItemInfo(nItemID)
	table_insert(self.m_tParams, {TipsType.ItemEnum, nItemID})
end

-- 增加角色信息
function CLinkTips:AddRoleInfo(sName)
	table_insert(self.m_tParams, {TipsType.RoleEnum, sName})
end

function CLinkTips:GetParams()
	return self.m_tParams
end

