
-- global function
local pairs = pairs
local print = print
local tonumber = tonumber
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
-- global singleton
local CPlayerManager = SingletonRequire("CPlayerManager");
local CDBServerManager	= SingletonRequire("CDBServerManager");
function CDBServerManager:Initialize()
	self.m_pDBPtr = _newslave("./Server/DBService.lua");
	self.m_tDBPlayerData = {}
	if not self.m_pDBPtr then return false end;
	return true;
end

function CDBServerManager:DBThreadSetID(i_nDBID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName)
	self:Send("D_SyncToDBThread","",i_nDBID,i_sHost,i_nPort,i_sUser,i_sPwd,i_sName);
end

function CDBServerManager:Destruct()
	_shutdownslave(self.m_pDBPtr);
end

function CDBServerManager:IsDestructOver()
	if _isslaveshutted(self.m_pDBPtr) then
		_deleteslave(self.m_pDBPtr);
		self.m_pDBPtr = nil;
		return true;
	end
end

function CDBServerManager:RedoFile(i_sFileName)
	self:Send("D_RedoFile","", i_sFileName);
end

-- 此函数除了select
function CDBServerManager:Execute(i_sSql, i_nDBID)
	self:Send("D_Execute", i_sSql, i_sSql, i_nDBID);
end

function CDBServerManager:SendDB(i_fCallBack, i_tRoleInfo)
	self.m_nDBCallBack = self.m_nDBCallBack or 1;
	self.m_tDBCallBack = self.m_tDBCallBack or {};
	self.m_tDBCallBack[self.m_nDBCallBack] = i_fCallBack;
	local nDBCallBack = self.m_nDBCallBack
	self.m_nDBCallBack = self.m_nDBCallBack + 1;
	self:Send("D_SendDB", "", nDBCallBack, i_tRoleInfo);
end

function CDBServerManager:SendDBCallBack(i_nCallBackID, i_sRoleID, i_tRes)
	if i_tRes then
		self:DBCallBackPart(i_sRoleID, i_tRes)
		self.m_tDBCallBack[i_nCallBackID]();
	else
		-- 读取数据失败踢人
		local oPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleID)
		if oPlayer then
			oPlayer:BeKick(PlayerBeKickReasonEnum.eLoadDBDataError)
		end
	end
	self.m_tDBCallBack[i_nCallBackID] = nil;
end

function CDBServerManager:DBCallBackPart(i_sRoleID, i_tResPart)
	self.m_tDBPlayerData[i_sRoleID] = self.m_tDBPlayerData[i_sRoleID] or {}
	for k,v in pairs(i_tResPart) do
		self.m_tDBPlayerData[i_sRoleID][k] = v
	end
end

function CDBServerManager:DBDestroyPlayerOver(i_nCallBackID)
	self.m_tDBCallBack[i_nCallBackID]();
	self.m_tDBCallBack[i_nCallBackID] = nil;
end

function CDBServerManager:GetPlayerData(i_sRoleID, i_sModule)
	return self.m_tDBPlayerData[i_sRoleID] and self.m_tDBPlayerData[i_sRoleID][i_sModule]
end

function CDBServerManager:ClearPlayerData(i_sRoleID)
	self.m_tDBPlayerData[i_sRoleID] = nil
end

defineS.K_DBCallBackResult = function (i_nCallBackID, i_sRoleID, i_tRes)
	CDBServerManager:SendDBCallBack(i_nCallBackID, i_sRoleID, i_tRes)
end

defineS.K_DBCallBackResultStart = function (i_sRoleID, i_tResPart)
	CDBServerManager:DBCallBackPart(i_sRoleID, i_tResPart)
end

defineS.K_DBDestroyPlayerOver = function (i_nCallBackID)
	CDBServerManager:DBDestroyPlayerOver(i_nCallBackID)
end

local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local fast_encode	= _codeservice.fast_encode;
local sendtoslave	= _sendtoslave;
local nMaxLen		= 8192;
function CDBServerManager:Send(i_sMsg, i_sSystem, ...)
	local multiple = 1;
	while true do
		local pData = malloc(nMaxLen * multiple);
		if pData then
			local nLen = fast_encode(pData, nMaxLen * multiple, i_sMsg, ...);
			if nLen > 0 then
				local res = sendtoslave(self.m_pDBPtr, pData, nLen);
				if not res then
					print("ERROR!!! CDBServerManager:Send sendtoslave failed.");
					free(pData);
				end
				break;
			elseif nLen < 0 then
				print("ERROR!!! CDBServerManager:Send fast_encode failed.", i_sMsg, i_sSystem, nLen);
				free(pData);
				break;
			else
				print("WARNING!!! CDBServerManager:Send fast_encode buffer small.", i_sMsg, i_sSystem, multiple);
				free(pData);
				multiple = multiple * 2;
			end
		else
			print("ERROR!!! CDBServerManager:Send malloc error.")
			break;
		end
	end
end