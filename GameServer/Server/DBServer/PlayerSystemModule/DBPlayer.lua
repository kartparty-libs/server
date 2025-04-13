local CDBCommand = SingletonRequire("CDBCommand");

local function f(i_tRoleInfo, i_tResult)
	local sRoleID = i_tRoleInfo.m_sRoleID
	local bIsNew = i_tRoleInfo.m_bIsNew
	local bRefresh = i_tRoleInfo.m_bRefresh
	local nServerID = i_tRoleInfo.m_nServerID
	local nPlatformLevel = i_tRoleInfo.m_nPlatformLevel
	
	i_tResult["CPlayer"] = {}
	if bIsNew then
		local oInsertCmd = CDBCommand:CreateInsertCmd("role_info", nServerID);
		oInsertCmd:SetKeys({"roleid"});
		oInsertCmd:SetMultiValues({sRoleID});
		oInsertCmd:Execute();
	else
		local oSelectCmd = CDBCommand:CreateSelectCmd("role_info", nServerID);
		oSelectCmd:SetWheres("roleid", sRoleID, "=");
		oSelectCmd:SetLimit(1);
		local tRes = oSelectCmd:Execute();
		i_tResult["CPlayer"]["role_info"] = tRes
	end
end

SingletonRequire("CPlayerSystemList"):RegisterSystem("CPlayer", f)