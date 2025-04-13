local print		= print
local type		= type
local pairs		= pairs
local ipairs	= ipairs
local tonumber	= tonumber
local string_find	= string.find
local string_byte	= string.byte
local string_char	= string.char
local string_gsub	= string.gsub
local string_format	= string.format
local string_gmatch	= string.gmatch
local table_concat	= table.concat
local table_insert	= table.insert

local CURL = SingletonRequire("CURL")

local function url_encode(str)
	return string_gsub(str, "[^_%-%.%w]", function(c)
		-- print("--", c, string_byte(c), string_format("%%%02X", string_byte(c)))
		return string_format("%%%02X", string_byte(c))
		end)
end
function CURL.Encode(i_Value)
	if type(i_Value) == "string" then
		return url_encode(i_Value)
	elseif type(i_Value) == "table" then
		local temp = {}
		for k, v in pairs(i_Value) do
			if (type(k) ~= "string") or (type(v) ~= "string") then
				print("ERROR!!! CURL.Encode table k or v type error.", k, v)
				return
			end
			table_insert(temp, string_format("%s=%s", url_encode(k), url_encode(v)))
		end
		return table_concat(temp, "&")
	end
end

local function url_decode(str)
	return string_gsub(str, "%%(%x%x)", function(h)
		-- print("--", h)
		return string_char(tonumber(h, 16))
		end)
end
function CURL.Decode(i_sStr)
	if type(i_sStr) ~= "string" then
		print("ERROR!!! CURL.Decode not a string.", i_sStr)
		return
	end
	if string_find(i_sStr, "=", 1, true) then
		local temp = {}
		for key, value in string_gmatch(i_sStr, "([^&=]*)=([^&=]*)") do
			temp[url_decode(key)] = url_decode(value)
		end
		return temp
	else
		return url_decode(i_sStr)
	end
end


