
-- global function
local table_insert	= table.insert;
local table_concat	= table.concat;
local string_format	= string.format;
local debug_traceback	= debug.traceback;
-- global class
local CDBService = SingletonRequire("CDBService");
local CDBServerManager = SingletonRequire("CDBServerManager", true);

--local
local CDBDeleteCmd = ClassRequire("CDBDeleteCmd");
function CDBDeleteCmd:_constructor(i_sTableName, i_nDBID)
	self.m_sTable	= i_sTableName;
	self.m_nDBID	= i_nDBID;
end

local str_key_symbol_value = "`%s` %s '%s'";
function CDBDeleteCmd:SetWheres(i_sWhereKey, i_sWhereValue, i_sSymbol)
	if not i_sWhereKey or not i_sWhereValue or not i_sSymbol then
		self.m_bError = true;
		print("ERROR!!! wheres not key or not value or not symbol.", debug_traceback())
		return
	end
	self.m_tWheres = self.m_tWheres or {};
	table_insert(self.m_tWheres, string_format(str_key_symbol_value, i_sWhereKey, i_sSymbol, i_sWhereValue));
end

function CDBDeleteCmd:SetWheresOR()
    self.m_bWheresOR = true
end

function CDBDeleteCmd:SetNoWhere()
    self.m_bNoWhere = true
end

local str_delete = "delete from `%s`";
local str_delete_where = "delete from `%s` where %s";
function CDBDeleteCmd:Execute(i_bMainThread)
	if self.m_bError then
        print("ERROR!!! already error.", debug_traceback())
        return
    end
    self.m_bError = true -- 防止oCmd重用
    
	local strFinal;
	if self.m_tWheres then
		local strWheres
        if self.m_bWheresOR then
            strWheres = table_concat(self.m_tWheres, " or ")
        else
            strWheres = table_concat(self.m_tWheres, " and ")
        end
		strFinal = string_format(str_delete_where, self.m_sTable, strWheres)
	else
        if self.m_bNoWhere then
            strFinal = string_format(str_delete, self.m_sTable);
        else
            print("ERROR!!! CDBDeleteCmd no where", debug_traceback())
            return
        end
	end
	if i_bMainThread then
		return CDBService:Execute(strFinal, self.m_nDBID)
	else
		if CDBServerManager then
			CDBServerManager:Execute(strFinal, self.m_nDBID);
		else
			CDBService:Execute(strFinal, self.m_nDBID)
		end
	end
end



