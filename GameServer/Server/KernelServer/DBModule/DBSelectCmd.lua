
-- global function
local table_insert	= table.insert;
local table_concat	= table.concat;
local string_format	= string.format;
local debug_traceback	= debug.traceback;
-- global class
local CDBService = SingletonRequire("CDBService");

--local
local CDBSelectCmd = ClassRequire("CDBSelectCmd");
function CDBSelectCmd:_constructor(i_sTableName, i_nDBID)
	self.m_sTable	= i_sTableName;
	self.m_nDBID	= i_nDBID;
end

function CDBSelectCmd:SetFields(i_sFieldName)
	if not i_sFieldName then
		self.m_bError = true;
		print("ERROR!!! fields not name.", debug_traceback())
		return;
	end
	self.m_tFields = self.m_tFields or {};
	table_insert(self.m_tFields, i_sFieldName);
end

local str_key_symbol_value = "`%s` %s '%s'";
function CDBSelectCmd:SetWheres(i_sWhereKey, i_sWhereValue, i_sSymbol)
	if not i_sWhereKey or not i_sWhereValue or not i_sSymbol then
		self.m_bError = true;
		print("ERROR!!! wheres not key or not value or not symbol.", debug_traceback())
		return;
	end
	self.m_tWheres = self.m_tWheres or {};
	table_insert(self.m_tWheres, string_format(str_key_symbol_value, i_sWhereKey, i_sSymbol, i_sWhereValue));
end

local str_key_like_value = "`%s` like '%%%s%%'"
function CDBSelectCmd:SetWheresLike(i_sWhereKey, i_sWhereValue)
	if not i_sWhereKey or not i_sWhereValue then
		self.m_bError = true
		print("ERROR!!! whereslike not key or not value.", debug_traceback())
		return
	end
	self.m_tWheres = self.m_tWheres or {}
	table_insert(self.m_tWheres, string_format(str_key_like_value, i_sWhereKey, i_sWhereValue))
end

function CDBSelectCmd:SetWheresOR()
    self.m_bWheresOR = true
end

function CDBSelectCmd:OrderBy(i_sField, i_bDesc, i_bMark)
	self.m_sOrderBy = i_sField;
	self.m_bDesc	= i_bDesc;
	self.m_bMark	= i_bMark
end

function CDBSelectCmd:SetLimit(i_nLimit)
	self.m_nLimit = i_nLimit;
end


local str_field			= "`%s`";
local str_where			= "where %s";
local str_orderby		= "order by `%s`";
local str_orderby_desc	= "order by `%s` desc";
local str_orderbys		= "order by %s";
local str_limit			= "limit %d";
local str_select_final	= "select %s from `%s` %s %s %s";

function CDBSelectCmd:Execute()
	if self.m_bError then
        print("ERROR!!! already error.", debug_traceback())
        return
    end
    self.m_bError = true -- 防止oCmd重用
	
	local strFields		= "*";
	local strWheres		= "";
	local strOrderBy	= "";
	local strLimit		= "";
	if self.m_tFields then
		strFields = string_format(str_field, table_concat(self.m_tFields, "`, `"));
	end
	if self.m_tWheres then
        if self.m_bWheresOR then
            strWheres = string_format(str_where, table_concat(self.m_tWheres, " or "));
        else
            strWheres = string_format(str_where, table_concat(self.m_tWheres, " and "));
        end
	end
	if self.m_sOrderBy then
		if not self.m_bMark then
			if self.m_bDesc then
				strOrderBy = string_format(str_orderby_desc, self.m_sOrderBy);
			else
				strOrderBy = string_format(str_orderby, self.m_sOrderBy);
			end
		else
			strOrderBy = string_format(str_orderbys, self.m_sOrderBy)
		end 
	end
	if self.m_nLimit then
		strLimit = string_format(str_limit, self.m_nLimit);
	end
	
	local strFinal = string_format(str_select_final, strFields, self.m_sTable, strWheres, strOrderBy, strLimit);
	return CDBService:Execute(strFinal, self.m_nDBID);
end



