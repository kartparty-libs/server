
-- global function
local table_insert	= table.insert;
local table_concat	= table.concat;
local string_format	= string.format;
local debug_traceback	= debug.traceback;
-- global class
local CDBService = SingletonRequire("CDBService");
local CDBServerManager = SingletonRequire("CDBServerManager", true);

--local
local CDBUpdateCmd = ClassRequire("CDBUpdateCmd");
function CDBUpdateCmd:_constructor(i_sTableName, i_nDBID)
	self.m_sTable	= i_sTableName;
	self.m_nDBID	= i_nDBID;
end

local str_key_value_equal = "`%s` = '%s'";
function CDBUpdateCmd:SetFields(i_sFieldKey, i_sFieldValue)
	if not i_sFieldKey or not i_sFieldValue then
		print("ERROR!!! fields not key or not value", debug_traceback())
		return;
	end
	self.m_tFields = self.m_tFields or {};
	table_insert(self.m_tFields, string_format(str_key_value_equal, i_sFieldKey, i_sFieldValue));
end

local str_key_symbol_value = "`%s` %s '%s'";
function CDBUpdateCmd:SetWheres(i_sWhereKey, i_sWhereValue, i_sSymbol)
	if not i_sWhereKey or not i_sWhereValue or not i_sSymbol then
		self.m_bError = true;
		print("ERROR!!! wheres not key or not value or not symbol.", debug_traceback())
		return;
	end
	self.m_tWheres = self.m_tWheres or {};
	table_insert(self.m_tWheres, string_format(str_key_symbol_value, i_sWhereKey, i_sSymbol, i_sWhereValue));
end

function CDBUpdateCmd:SetWheresOR()
    self.m_bWheresOR = true
end

function CDBUpdateCmd:SetNoWhere()
    self.m_bNoWhere = true
end

local str_update = "update `%s` set %s";
local str_update_where = "update `%s` set %s where %s";
function CDBUpdateCmd:Execute(i_bMainThread)
	if self.m_bError then
        print("ERROR!!! already error.", debug_traceback())
        return
    end
    self.m_bError = true -- 防止oCmd重用
	if not self.m_tFields then
		print("ERROR!!! no fields.", debug_traceback())
        return
	end
    
    local strFields = table_concat(self.m_tFields, ", ");
    local strFinal;
    if self.m_tWheres then
        local strWheres
        if self.m_bWheresOR then
            strWheres = table_concat(self.m_tWheres, " or ");
        else
            strWheres = table_concat(self.m_tWheres, " and ");
        end
        strFinal = string_format(str_update_where, self.m_sTable, strFields, strWheres)
    else
        if self.m_bNoWhere then
            strFinal = string_format(str_update, self.m_sTable, strFields);
        else
            print("ERROR!!! CDBUpdateCmd no where.", debug_traceback())
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



