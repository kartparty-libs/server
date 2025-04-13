
-- global function
local table_insert = table.insert;
-- global singleton
local CGlobalInfoManager	= SingletonRequire("CGlobalInfoManager");
local CGuildManager			= SingletonRequire("CGuildManager", true);

local CDataLog          = SingletonRequire("CDataLog")
local CGameServerManager	= SingletonRequire("CGameServerManager");
local nGSNum 				= ServerInfo.ThreadNum;
function CGameServerManager:Initialize()
	self.m_tGSSet = {};
	for i = 1, nGSNum do
		local gs = ClassNew("CGameServer");
		if not gs:IsOK() then return false end;
		table_insert(self.m_tGSSet, gs);
	end
	self.m_nGSNum	= nGSNum;
    self.m_nIndex   = 0
	return true;
end

function CGameServerManager:Destruct()
	for _, gs in ipairs(self.m_tGSSet) do
		gs:Shutdown();
	end
end

function CGameServerManager:IsDestructOver()
	for _, gs in ipairs(self.m_tGSSet) do
		if gs:IsShutted() then
			gs:Destruct();
			self.m_nGSNum = self.m_nGSNum - 1;
		end
	end
	return self.m_nGSNum == 0;
end

function CGameServerManager:GetOneGS()
	-- local gs = self.m_tGSSet[1];
	-- for i = 2, nGSNum, 1 do
		-- local tGS = self.m_tGSSet[i];
		-- if tGS:GetPlayerNum() < gs:GetPlayerNum() then
			-- gs = tGS;
		-- elseif tGS:GetPlayerNum() == gs:GetPlayerNum() then
			-- if tGS:GetMapNum() < gs:GetMapNum() then
				-- gs = tGS;
			-- end
		-- end
	-- end
    local gs = self.m_tGSSet[self.m_nIndex % nGSNum + 1]
    self.m_nIndex = self.m_nIndex + 1
	return gs;
end

function CGameServerManager:RedoFile(i_sFileName)
	for _, gs in ipairs(self.m_tGSSet) do
		gs:Send("G_RedoFile", i_sFileName);
	end
end

function CGameServerManager:BroadcastDropAction(i_sActionID, i_tDropAction)
    for _, gs in ipairs(self.m_tGSSet) do
		gs:Send("G_DropAction", i_sActionID, i_tDropAction)
	end
end

function CGameServerManager:BroadcastBridgeHoleInfo(i_tInfo)
    for _, gs in ipairs(self.m_tGSSet) do
		gs:Send("G_SyncBridgeHoleHp", i_tInfo)
	end
end

function CGameServerManager:BroadcastMeanLevel(i_nLevel)
    for _, gs in ipairs(self.m_tGSSet) do
		gs:Send("G_SyncMeanLevel", i_nLevel)
	end
end

