--global
local CDBServer 	= SingletonRequire("CDBServer");
local CDBService	= SingletonRequire("CDBService");

defineS.D_RedoFile = function(i_sFileName)
	CDBServer:RedoFile(i_sFileName);
end

defineS.D_Execute = function(i_sSql, i_nDBID)
	CDBService:Execute(i_sSql, i_nDBID)
end

defineS.D_SendDB = function(i_nCallBackID, i_tRoleInfo)
	if i_tRoleInfo.m_bDestroy then
		CDBServer:DestroyPlayer(i_nCallBackID, i_tRoleInfo)
	else
		CDBServer:CreateExecute(i_nCallBackID, i_tRoleInfo)
	end
end
defineS.D_SyncToDBThread = function(i_nDBID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName)
	CDBService:SetID2Info(i_nDBID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName)
	CDBService:Execute('show tables like "dbinfo"', i_nDBID)
end

