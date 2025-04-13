
-- global function
local type	= type;
local print	= print;
local debug_traceback = debug.traceback;
-- local
local tEnumS = {};

local registenum =  function(i_sEnumName, i_tEnum)
	if type(i_sEnumName) == "string" then
		if tEnumS[i_sEnumName] then
			print("ERROR!!! enum already exist!!!", i_sEnumName);
			print(debug_traceback());
			return;
		end;
		tEnumS[i_sEnumName] = i_tEnum;
	else
		print("ERROR!!! regist enum name type ERROR!!!", i_sEnumName);
		print(debug_traceback());
	end;
end;


local requireenum = function(i_sEnumName)
	local tEnum = tEnumS[i_sEnumName];
	if not tEnum then
		print("ERROR!!! require enum not exist!!!", i_sEnumName);
		print(debug_traceback());
	end;
	return tEnum;
end;

RegistEnum	= registenum;
RequireEnum	= requireenum;
dofile("./Server/EnumS/KSEnum.lua")
dofile("./Server/EnumS/ScheduleEnum.lua")