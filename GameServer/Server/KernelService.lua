-- debug
local fLuaDebug = nil
local breakSocketHandle,debugXpCall = nil, nil

if is_windows() then
	fLuaDebug = dofile("./LuaDebug.lua")
	breakSocketHandle,debugXpCall = fLuaDebug and fLuaDebug("localhost",7003)
end

dofile("./Server/version.lua")
dofile("./ServerConfig.lua")

if ServerInfo.district_log_host then
    district_logindex = _setlogdb(
    	ServerInfo.district_log_host,
        ServerInfo.district_log_user, 
        ServerInfo.district_log_pwd,
        ServerInfo.district_log_name, 
        ServerInfo.district_log_port
    )
end
if ServerInfo.public_log_host then
    public_logindex = _setlogdb(
    	ServerInfo.public_log_host,
        ServerInfo.public_log_user, 
        ServerInfo.public_log_pwd,
        ServerInfo.public_log_name, 
        ServerInfo.public_log_port
   	)
end

print("district_logindex", district_logindex)
print("public_logindex", public_logindex)

if is_windows() then
    _set360file("./Log/", "act.log")
else
    _set360file(string.format("/data/gameinfo/s%d/", ServerInfo.serverid), "act.log")
end


defineC = {};
defineS = {};
defineF = {};	


dofile("./Server/KernelServer/KS_Include.lua");

-- local
local print     = print;
local ipairs    = ipairs;
local assert    = assert
local unpack    = unpack
local string_format = string.format
local ProtectedCall = ProtectedCall;
local Performance   = Performance
-- local
local PlayerBeKickReasonEnum = RequireEnum("PlayerBeKickReasonEnum")
--global class
local defineS	= defineS;

local CPlayerManager		= SingletonRequire("CPlayerManager");
local CDataLog = SingletonRequire("CDataLog")
CDataLog:SetDistrictLogDBIndex(district_logindex)
-----------------------------------------------------------
-- rpc
defineS.K_GPCall = function(roleid, msg, ...)
	local player = CPlayerManager:GetPlayerByRoleID(roleid);
	local func = defineS[msg];
    assert(func, "ERROR!!! K_GPCall msg not exist:" .. msg);
	-- print("K_GPCall", msg);
    local f = Performance(msg)
    local arg = {...}
	if not ProtectedCall(function() func(player, unpack(arg)) end) then
        player:BeKick(PlayerBeKickReasonEnum.eKSHandleGSMsgError)
    end
    f()
end
local function OnGSCall(i_nFromID, i_sMsg, ...)
    assert(i_sMsg, "ERROR!!! OnGSCall no msg");
    local func = defineS[i_sMsg];
    assert(func, "ERROR!!! OnGSCall msg not exist:" .. i_sMsg);
	-- print("OnGSCall", i_sMsg);
    local f = Performance(i_sMsg)
	func(...);
    f()
end
local fast_decode	= _codeservice.fast_decode;
local free			= _memoryservice.free;
function OnRpc(i_nFromID, i_pDataPtr, i_nDataLen, i_pAppendDataPtr, i_nAppendDataLen)
	if i_pAppendDataPtr then -- transmit
		-- print("+++", i_pDataPtr, i_nDataLen, i_pAppendDataPtr, i_nAppendDataLen)
		local tRole = fast_decode(i_pDataPtr, i_nDataLen);
		if tRole then
			for _, sRoleID in ipairs(tRole) do
				local oPlayer = CPlayerManager:GetPlayerByRoleID(sRoleID);
                if oPlayer then
                    oPlayer:SendDataToClient(i_pAppendDataPtr, i_nAppendDataLen);
                end
			end
		else
			print("ERROR!!! OnRpc Transmit.");
		end  
		free(i_pAppendDataPtr);
	else
		ProtectedCall(function() OnGSCall(i_nFromID, fast_decode(i_pDataPtr, i_nDataLen)) end);
	end
	free(i_pDataPtr);
end

-----------------------------------------------------------
--KernelService 
-- start
function OnStart()
	print("KernelService Start!");
	return SingletonInitialize();
end
local bStartShutdown;
-- loop
local SingletonUpdate = SingletonUpdate;


function OnLoop()
    if not bStartShutdown then
        ProtectedCall(SingletonUpdate)
	end
    -- 调试debug
	if breakSocketHandle then
		breakSocketHandle()
	end
end
-- shutdown
local SingletonDestruct = SingletonDestruct;

function OnShutdown()
	if not bStartShutdown then
		bStartShutdown = true;
		print("KernelServer shutdown...");
	end
	return SingletonDestruct();
end

setmetatable(_G, {__newindex = function(t, k, v)
				assert(false, string_format("ERROR!!!, Write to _G.%s.", k))
				end});
-- print("--------------KernelServer---------------");
-- for k, v in pairs(_G) do
	-- print(k, v);
-- end;
-- print("--------------KernelServer---------------");
