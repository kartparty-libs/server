
-- global function
local dofile = dofile
local pairs = pairs
local print = print
local ProtectedCall = ProtectedCall

local CPlayerSystemList = SingletonRequire("CPlayerSystemList")

function CPlayerSystemList:Initialize()
	return true
end

function CPlayerSystemList:RegisterSystem(i_sSystemName, i_sFunName)
	self.m_tSysList = self.m_tSysList or {}
	self.m_tSysList[i_sSystemName] = i_sFunName
end

function CPlayerSystemList:LoadData(i_tRoleInfo, i_tResult)
	local bRes = true
	if not self.m_tSysList then
		self.m_tSysList = {}
	end
	for sSystemName, f in pairs(self.m_tSysList) do
		if not ProtectedCall(function () f(i_tRoleInfo, i_tResult) end) then
			print("ERROR!!! DBsystem Init Fail.", sSystemName)
			bRes = false
			break
		end
	end
	return bRes
end

-- dofile("./Server/DBServer/PlayerSystemModule/DBPlayer.lua")
dofile("./Server/DBServer/PlayerSystemModule/DBBasicInfoSystem.lua")
dofile("./Server/DBServer/PlayerSystemModule/DBTaskSystem.lua")

if ServerInfo.isbridge then
else
end
