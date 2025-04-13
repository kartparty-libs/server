-- debug
local fLuaDebug = nil
local breakSocketHandle,debugXpCall = nil, nil

if is_windows() then
	fLuaDebug = dofile("./LuaDebug.lua")
	breakSocketHandle,debugXpCall = fLuaDebug and fLuaDebug("localhost",7004)
end

dofile("./ServerConfig.lua")

_open_pathfinderservice();

defineC = {};
defineS = {};


dofile("./Server/GameServer/GS_Include.lua");

-- local
local print = print;
local assert = assert;
local unpack = unpack;
local string_format = string.format
local ProtectedCall = ProtectedCall;
local Performance   = Performance

--global class
local defineC	= defineC;
local defineS	= defineS;

local CGameServer		= SingletonRequire("CGameServer");
-----------------------------------------------------------
--rpc

defineS.G_KPCall = function(roleid, msg, ...)

end

local function OnKSCall(i_sMsg, ...)
	assert(i_sMsg and defineS[i_sMsg], string_format("ERROR!!! OnKSCall Msg:%s.",i_sMsg))
    local f = Performance(i_sMsg)
    defineS[i_sMsg](...);
    f()
end
local fast_decode	= _codeservice.fast_decode;
local free			= _memoryservice.free;
function OnRpc(i_pDataPtr, i_nDataLen)
	ProtectedCall(function() OnKSCall(fast_decode(i_pDataPtr, i_nDataLen)) end);
	free(i_pDataPtr);
end


-----------------------------------------------------------
--GameService 
-- start
function OnStart()
	print("GameServer start.");
	return SingletonInitialize();
end
-- loop
local SingletonUpdate = SingletonUpdate;
function OnLoop()
	ProtectedCall(SingletonUpdate)
	if breakSocketHandle then
		breakSocketHandle( )
	end
end
-- shutdown
local SingletonDestruct = SingletonDestruct;
local bPrint;
function OnShutdown()
	if not bPrint then
		bPrint = true;
		print("GameServer shutdown...");
	end
	return SingletonDestruct();
end

setmetatable(_G, {__newindex = function(t, k, v)
				assert(false, string_format("ERROR!!!, Write to _G.%s.", k))
				end});
-- print("--------------GameServer---------------");
-- for k, v in pairs(_G) do
	-- print(k, v);
-- end;
-- print("--------------GameServer---------------");


