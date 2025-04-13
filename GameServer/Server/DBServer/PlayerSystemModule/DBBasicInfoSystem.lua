local CDBCommand = SingletonRequire("CDBCommand")
local function CSignInSystemInsert2DB(i_sRoleID, i_nServerID)
	local oCmd = CDBCommand:CreateInsertCmd("role_basicinfo", i_nServerID)
	oCmd:SetFields("roleid", i_sRoleID)
	oCmd:SetFields("level", 1)
	oCmd:SetFields("exp", 0)
	oCmd:SetFields("viplv", 0)
	oCmd:SetFields("gold", 0)
	oCmd:SetFields("diamond", 0)
	oCmd:SetFields("energy", 0)
	oCmd:SetFields("head", 1)
	oCmd:SetFields("playercfgid", 1)
	oCmd:SetFields("carcfgid", 1)
	oCmd:SetFields("score", 0)
	oCmd:Execute()
end

local function f(i_tRoleInfo, i_tResult)
	local sRoleID = i_tRoleInfo.m_sRoleID
	local bIsNew = i_tRoleInfo.m_bIsNew
	local bRefresh = i_tRoleInfo.m_bRefresh
	local nServerID = i_tRoleInfo.m_nServerID
	
	if bIsNew then
		CSignInSystemInsert2DB(sRoleID, nServerID)
	else
		local oCmd = CDBCommand:CreateSelectCmd("role_basicinfo", nServerID)
		oCmd:SetWheres("roleid", sRoleID, "=")
		oCmd:SetLimit(1)
		local res = oCmd:Execute()
		if res[1] then
			i_tResult["CBasicInfoSystem"] = res[1]
		else
			CSignInSystemInsert2DB(sRoleID, nServerID)
		end
	end
end

SingletonRequire("CPlayerSystemList"):RegisterSystem("CBasicInfoSystem", f)