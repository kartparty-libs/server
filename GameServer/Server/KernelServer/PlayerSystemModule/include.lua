-- global function
local table_insert = table.insert

dofile("./Server/KernelServer/PlayerSystemModule/BasicInfoSystem/include.lua")
dofile("./Server/KernelServer/PlayerSystemModule/TaskSystem/include.lua")
dofile("./Server/KernelServer/PlayerSystemModule/LastSyncSystem/include.lua")
if ServerInfo.isbridge then
else
end

--在此填入要注册的玩家系统
local CPlayerSystemList = SingletonRequire("CPlayerSystemList")

function CPlayerSystemList:Initialize()
	self.m_tSysList = 
	{
		"CBasicInfoSystem",		--基本信息系统
		"CTaskSystem",			--任务系统
	}

	if ServerInfo.isbridge then
		
	else
	
	end

	table_insert(self.m_tSysList, "CLastSyncSystem")		-- 信息同步系统（放到最后）
	return true
end

function CPlayerSystemList:GetSysList()
	return self.m_tSysList
end
