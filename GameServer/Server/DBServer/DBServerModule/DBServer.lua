
--global function
local pairs			= pairs;
local print			= print;
local dofile		= dofile;
local ProtectedCall = ProtectedCall
local CKS 			= SingletonRequire("CKS");
local CPlayerSystemList = SingletonRequire("CPlayerSystemList");
--local
local CDBServer = SingletonRequire("CDBServer");
function CDBServer:Initialize()
	return true;
end

function CDBServer:RedoFile(i_sFileName)
	print("LOG!!! redofile : ", i_sFileName);
    ProtectedCall(function() dofile(i_sFileName) end);
end

function CDBServer:CreateExecute(i_nCallBackID, i_tRoleInfo)
	local sRoleID = i_tRoleInfo.m_sRoleID
	CKS:AddRole(sRoleID)
	local tResult = {}
	local bRes = CPlayerSystemList:LoadData(i_tRoleInfo, tResult)
	if not bRes then
		-- 发送消息通知KS踢人
		CKS:SendToKS("K_DBCallBackResult", i_nCallBackID, sRoleID)
		return
	end
	
	for k,v in pairs(tResult) do
		CKS:SendToKSByAutoMalloc("K_DBCallBackResultStart", k, sRoleID, {[k] = v})
	end
	CKS:SendToKS("K_DBCallBackResult",i_nCallBackID, sRoleID, {})
end

function CDBServer:DestroyPlayer(i_nCallBackID, i_tRoleInfo)
	-- print("DBServer PlayerDestroyOver.", i_tRoleInfo.m_sRoleID)
	CKS:SendToKS("K_DBDestroyPlayerOver", i_nCallBackID)
end