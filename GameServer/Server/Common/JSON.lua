local type		= type
local pairs		= pairs
local ipairs	= ipairs
local print		= print
local tonumber	= tonumber
local tostring	= tostring
local math_floor	= math.floor
local string_format = string.format
local string_byte	= string.byte
local string_char	= string.char
local string_sub	= string.sub
local string_gsub	= string.gsub
local string_len	= string.len
local string_find	= string.find
local table_insert	= table.insert
local table_maxn	= table.maxn
local table_concat	= table.concat

local tRefTable = {}
local fEncode, fDecode

local CJSON = SingletonRequire("CJSON")

function CJSON.Encode(i_Value, i_bUnicode)
	tRefTable = {}
	return fEncode(i_Value, i_bUnicode)
end

function CJSON.Decode(i_sStr, i_bUnicode)
	if i_sStr == "" then
		return { }
	end 
    i_sStr = string_gsub(i_sStr, '\\"', '\\k')
	local res1, res2 = fDecode(i_sStr, 1, i_bUnicode)
    return res1
end

function CJSON.NetworkEncode(...)
    local arg = {...}
    local params = {}
    for i, v in ipairs(arg) do
        if type(v) == "table" then
            v = "_t" .. CJSON.Encode(v, true)
			--平掉发消息不能发MAP
            -- if string_sub(v, 0, 3) == "_t{" then
            --     print("erro: NetworkEncode table not array", debug.traceback());
            -- end
        end
        table.insert(params, v)
    end
    return params
end

function CJSON.NetworkDecode(...)
    local arg = {...}
    local params = {}
    for i, v in ipairs(arg) do
        if type(v) == "string" then
            local first = string_sub(v, 0, 3)
            if first == "_t[" or first == "_t{" then
                v = string_sub(v, 3, string_len(v))
                v = CJSON.Decode(v, true)
            end
        end
        table_insert(params, v)
    end
    return params
end

------------
-- encode --
------------
local encode_escape_list = {
    ['"']  = '\\"',
    ['\\'] = '\\\\',
    ['/']  = '\\/', 
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
}
local function fEncodeString(i_sStr, i_bUnicode)
    i_sStr = string_gsub(i_sStr, ".", function(c) return encode_escape_list[c] end)
	if i_bUnicode then
		local tTemp = {}
		local i = 1
		local nLen = string_len(i_sStr)
		while (i <= nLen) do
			local s1 = string_sub(i_sStr, i, i)
			local byte1 = string_byte(s1)
			if byte1 > 0xE0 then  -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
				local s2 = string_sub(i_sStr, i+1, i+1)
				local byte2 = string_byte(s2)
				local s3 = string_sub(i_sStr, i+2, i+2)
				local byte3 = string_byte(s3)
				table_insert(tTemp, string_format("\\u%04x", (byte1 % 0x10) * 0x1000 + (byte2 % 0x40) * 0x40 + (byte3 % 0x40)))
				i = i + 3
			elseif byte1 > 0x80 then -- [110x xxxx] [10xx xxxx]
				local s2 = string_sub(i_sStr, i+1, i+1)
				local byte2 = string_byte(s2)
				table_insert(tTemp, string_format("\\u%04x", (byte1 % 0x20) * 0x40 + (byte2 % 0x40)))
				i = i + 2
			else
				table_insert(tTemp, s1)
				i = i + 1
			end
		end
		return string_format('"%s"', table_concat(tTemp))
	else
		return string_format('"%s"', i_sStr)
	end
end
local function fIsArray(i_tTable)
	local nCount = 0
	for key, value in pairs(i_tTable) do
		if not (type(key) == "number" and math_floor(key) == key and key >= 1) then
			return false
		end
		nCount = nCount + 1
	end
	if nCount == table_maxn(i_tTable) then
		return true
	else
		return false
	end
end
function fEncode(i_Value, i_bUnicode)
	local sType = type(i_Value)
	if sType == "string" then
		return fEncodeString(i_Value, i_bUnicode)
	elseif sType == "number" or sType == "boolean" then
		return tostring(i_Value)
	elseif sType == "table" then
		if tRefTable[i_Value] then
			print("ERROR!!! JSON object recursive.")
			return
		end
		tRefTable[i_Value] = true
		local sTemp
		if fIsArray(i_Value) then
			local tTemp = {}
			for i=1, #i_Value do
				local sValue = fEncode(i_Value[i], i_bUnicode)
				if sValue then
					table_insert(tTemp, sValue)
				else
					return
				end
			end
			sTemp = string_format("[%s]", table_concat(tTemp, ","))
		else
			local tTemp = {}
			for key, value in pairs(i_Value) do
				local sKeyType = type(key)
				if sKeyType == "string" then
					local sKey	= fEncodeString(tostring(key), i_bUnicode)
					local sValue = fEncode(value, i_bUnicode)
					if sValue then
						table_insert(tTemp, string_format("%s:%s", sKey, sValue))
					else
						return
					end
				elseif sKeyType == "number" then
					local sKey	= fEncodeString("_$" .. key, i_bUnicode)
					local sValue = fEncode(value, i_bUnicode)
					if sValue then
						table_insert(tTemp, string_format("%s:%s", sKey, sValue))
					else
						return
					end
				else
					print("ERROR!!! JSON encode object key type err:", sKeyType)
					return
				end
			end
			sTemp = string_format("{%s}", table_concat(tTemp, ","))
		end
		tRefTable[i_Value] = nil
		return sTemp
	else
		print("ERROR!!! JSON can't encode:", sType)
	end
end
------------
-- decode --
------------
local whitespace = " \n\r\t"
local function scan_whitespace(str, start_pos)
	local string_len = string_len(str)
	while ( string_find(whitespace, string_sub(str, start_pos, start_pos), 1, true)
	and start_pos <= string_len ) do
		start_pos = start_pos + 1
	end
	return start_pos
end
local decode_escape_list = {
    ['\\k']  = '"',
    ['\\\\']= '\\',
    ['\\/'] = '/', 
    ['\\b'] = '\b',
    ['\\f'] = '\f',
    ['\\n'] = '\n',
    ['\\r'] = '\r',
    ['\\t'] = '\t'
}
local function fDecodeString(i_sStr, i_nStartPos, i_bUnicode)
	local nStartPos, nEndPos = string_find(i_sStr, '^.-"', i_nStartPos + 1)
	if nStartPos then
		local sStr = string_sub(i_sStr, i_nStartPos + 1, nEndPos - 1)
        sStr = string_gsub(sStr, "\\.", function(c) return decode_escape_list[c] end)
		if i_bUnicode then
			sStr = string_gsub(sStr, "\\u(%x%x%x%x)", function(s)
				local n = tonumber(s, 16)
				if n < 0x80 then
					return string_char(n)
				elseif n < 0x800 then -- [110x xxxx] [10xx xxxx]
					return string_char(0xC0 + math_floor(n / 0x40),
										0x80 + (n % 0x40))
				else -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
					return string_char(0xE0 + (math_floor(n / 0x1000) % 0x10),
										0x80 + (math_floor(n / 0x40) % 0x40),
										0x80 + (n % 0x40))
				end
			end)
		end
		return sStr, nEndPos + 1
	end
end
local function fDecodeNumber(i_sStr, i_nStartPos)
	local nStartPos, nEndPos = string_find(i_sStr, "^[+-]?%d+", i_nStartPos)
	if nStartPos then
		local nNumber = tonumber(string_sub(i_sStr, nStartPos, nEndPos))
		return nNumber, nEndPos + 1
	end
end
local function fDecodeArray(i_sStr, i_nStartPos, i_bUnicode)
	local nStrLen = string_len(i_sStr)
	local tTemp = {}
	local nCurPos = i_nStartPos + 1
	while true do
		if nCurPos > nStrLen then return end
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		local sCurChar = string_sub(i_sStr, nCurPos, nCurPos)
		if sCurChar == ']' then break end
		local value
		value, nCurPos = fDecode(i_sStr, nCurPos, i_bUnicode)
		if nCurPos == nil then return end
		table_insert(tTemp, value)
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		if nCurPos > nStrLen then return end
		sCurChar = string_sub(i_sStr, nCurPos, nCurPos)
		if sCurChar == ',' then nCurPos = nCurPos + 1 end
	end
	return tTemp, nCurPos + 1
end
local function fDecodeObject(i_sStr, i_nStartPos, i_bUnicode)
	local nStrLen = string_len(i_sStr)
	local tTemp = {}
	local nCurPos = i_nStartPos + 1	
	while true do
		if nCurPos > nStrLen then return end
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		local sCurChar = string_sub(i_sStr, nCurPos, nCurPos)
		if sCurChar == '}' then break end
		if sCurChar ~= '"' then return end
		local key, value
		key, nCurPos = fDecodeString(i_sStr, nCurPos, i_bUnicode)
		if nCurPos == nil then return end
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		if nCurPos > nStrLen then return end
		sCurChar = string_sub(i_sStr, nCurPos, nCurPos)
		if sCurChar ~= ":" then return end
		nCurPos = nCurPos + 1
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		if nCurPos > nStrLen then return end
		value, nCurPos = fDecode(i_sStr, nCurPos, i_bUnicode)
		if nCurPos == nil then return end
		tTemp[key] = value
		nCurPos = scan_whitespace(i_sStr, nCurPos)
		if nCurPos > nStrLen then return end
		sCurChar = string_sub(i_sStr, nCurPos, nCurPos)
		if sCurChar == ',' then nCurPos = nCurPos + 1 end
	end
	return tTemp, nCurPos + 1
end
function fDecode(i_sStr, i_nStartPos, i_bUnicode)
	i_nStartPos = scan_whitespace(i_sStr, i_nStartPos)
	local s1 = string_sub(i_sStr, i_nStartPos, i_nStartPos)
	if s1 == '{' then
		local tTable, nNextPos = fDecodeObject(i_sStr, i_nStartPos, i_bUnicode)
		if nNextPos then
			return tTable, nNextPos
		else
			print(string_format("ERROR!!! json string error:%s table at pos:%d", i_sStr, i_nStartPos))
		end
	elseif s1 == '"' then
		local sString, nNextPos = fDecodeString(i_sStr, i_nStartPos, i_bUnicode)
		if nNextPos then
			return sString, nNextPos
		else
			print(string_format("ERROR!!! json string error:%s string at pos:%d", i_sStr, i_nStartPos))
		end
	elseif s1 == "[" then
		local tTable, nNextPos = fDecodeArray(i_sStr, i_nStartPos, i_bUnicode)
		if nNextPos then
			return tTable, nNextPos
		else
			print(string_format("ERROR!!! json string error:%s array at pos:%d", i_sStr, i_nStartPos))
		end
	elseif string_find("+-0123456789", s1, 1, true) then
		local nNumber, nNextPos = fDecodeNumber(i_sStr, i_nStartPos)
		if nNextPos then
			return nNumber, nNextPos
		else
			print(string_format("ERROR!!! json string error:%s number at pos:%d", i_sStr, i_nStartPos))
		end
	else
		if string_sub(i_sStr, i_nStartPos, i_nStartPos + 4) == "false" then
			return false, i_nStartPos + 5
		elseif string_sub(i_sStr, i_nStartPos, i_nStartPos + 3) == "true" then
			return true, i_nStartPos + 4
		elseif string_sub(i_sStr, i_nStartPos, i_nStartPos + 3) == "null" then
			return nil, i_nStartPos + 4
		else
			print(string_format("ERROR!!! json string error:%s type at pos:%d", i_sStr, i_nStartPos))
		end
	end
end

