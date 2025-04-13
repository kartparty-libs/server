
-- global function
local ipairs		= ipairs;
local table_insert	= table.insert;
local table_concat	= table.concat;
local string_format	= string.format;
local debug_traceback	= debug.traceback;
-- global class
local CDBService = SingletonRequire("CDBService");
local CDBServerManager = SingletonRequire("CDBServerManager", true);

--local
local CDBInsertCmd = ClassRequire("CDBInsertCmd");
function CDBInsertCmd:_constructor(i_sTableName, i_nDBID)
	self.m_sTable	= i_sTableName;
	self.m_nDBID	= i_nDBID;
end

local str_key_value_equal = "`%s` = '%s'";
function CDBInsertCmd:SetFields(i_sFieldKey, i_sFieldValue)
	if not i_sFieldKey or not i_sFieldValue then
		self.m_bError = true;
		print("ERROR!!! fields not key or not value.", debug_traceback())
		return;
	end
	self.m_tFields = self.m_tFields or {};
	table_insert(self.m_tFields, string_format(str_key_value_equal, i_sFieldKey, i_sFieldValue));
end

function CDBInsertCmd:SetKeys(i_tKey)
	if #i_tKey == 0 then
		self.m_bError = true;
		print("ERROR!!! #keys == 0.", debug_traceback())
		return;
	end
	self.m_tKey = i_tKey;
end
function CDBInsertCmd:SetMultiValues(i_tValue)
	if #i_tValue == 0 then
		self.m_bError = true;
		print("ERROR!!! #values == 0", debug_traceback())
		return;
	end
	self.m_tValues = self.m_tValues or {};
	table_insert(self.m_tValues, i_tValue);
end

function CDBInsertCmd:SetReplace()
    self.m_bReplace = true
end

local str_insert_set = "insert into `%s` set %s";
local str_insert_values = "insert into `%s` (`%s`) values %s";
local str_replace_insert_set = "replace into `%s` set %s";
local str_replace_insert_values = "replace into `%s` (`%s`) values %s";
function CDBInsertCmd:Execute(i_bMainThread)
	if self.m_bError then
        print("ERROR!!! already error.", debug_traceback())
        return
    end
    self.m_bError = true -- 防止oCmd重用
    
	if self.m_tFields then
		local strFields = table_concat(self.m_tFields, ", ");
        local strFinal
        if self.m_bReplace then
            strFinal = string_format(str_replace_insert_set, self.m_sTable, strFields);
        else
            strFinal = string_format(str_insert_set, self.m_sTable, strFields);
        end
		if i_bMainThread then
			return CDBService:Execute(strFinal, self.m_nDBID);
		else
			if CDBServerManager then
				CDBServerManager:Execute(strFinal, self.m_nDBID)
			else
				CDBService:Execute(strFinal, self.m_nDBID);
			end
		end
	elseif (self.m_tKey and self.m_tValues) then
		local strKeys = table_concat(self.m_tKey, "`, `");
		local tValues = {};
		for _, t in ipairs(self.m_tValues) do
			table_insert(tValues, string_format("('%s')", table_concat(t, "', '") ) );
		end
		local strValues = table_concat(tValues, ", ");
		local strFinal
        if self.m_bReplace then
            strFinal = string_format(str_replace_insert_values, self.m_sTable, strKeys, strValues);
        else
            strFinal = string_format(str_insert_values, self.m_sTable, strKeys, strValues);
        end
		if i_bMainThread then
			return CDBService:Execute(strFinal, self.m_nDBID);
		else
			if CDBServerManager then
				CDBServerManager:Execute(strFinal, self.m_nDBID)
			else
				CDBService:Execute(strFinal, self.m_nDBID);
			end
		end
	end
end


