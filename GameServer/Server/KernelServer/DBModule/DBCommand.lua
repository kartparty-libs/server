
-- global function
local ClassNew = ClassNew;

--local
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager", true);
local CDBCommand = SingletonRequire("CDBCommand");

function CDBCommand:CreateSelectCmd(i_sTableName, i_nDBID)
	i_nDBID = i_nDBID or CGlobalInfoManager:GetServerID();
	return ClassNew("CDBSelectCmd", i_sTableName, i_nDBID);
end

function CDBCommand:CreateInsertCmd(i_sTableName, i_nDBID)
	i_nDBID = i_nDBID or CGlobalInfoManager:GetServerID();
	return ClassNew("CDBInsertCmd", i_sTableName, i_nDBID);
end

function CDBCommand:CreateUpdateCmd(i_sTableName, i_nDBID)
	i_nDBID = i_nDBID or CGlobalInfoManager:GetServerID();
	return ClassNew("CDBUpdateCmd", i_sTableName, i_nDBID);
end

function CDBCommand:CreateDeleteCmd(i_sTableName, i_nDBID)
	i_nDBID = i_nDBID or CGlobalInfoManager:GetServerID();
	return ClassNew("CDBDeleteCmd", i_sTableName, i_nDBID);
end


