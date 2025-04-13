--global function
local type				= type;
local pairs				= pairs;
local ipairs			= ipairs;
local print				= print;
local table_insert		= table.insert;
local now				= _commonservice.now;
local ProtectedCall     = ProtectedCall;
local Performance       = Performance
--local
local tName2Singleton	= {};
local tSingletonSet		= {};
local tUpdateSet		= {};

-- 断点测试代码 之后可能会用到
--local breakSocketHandle,debugXpCall = dofile("./LuaDebug.lua")("localhost",8888) 

SingletonRegist = function(i_sSingletonName, i_bUpdate)
	if type(i_sSingletonName) == "string" then
		if tName2Singleton[i_sSingletonName] then
			print("ERROR!!! regist singleton repeat.", i_sSingletonName);
		else
			local singleton = {_name = i_sSingletonName};
			tName2Singleton[i_sSingletonName] = singleton;
			table_insert(tSingletonSet, singleton);
			if i_bUpdate then
				table_insert(tUpdateSet, singleton);
			end
			return singleton;
		end		
	else
		print("ERROR!!! regist singleton type ERROR!!!", i_sSingletonName);
		print(debug.traceback());
	end
end


SingletonRequire = function(i_sSingletonName, i_bIgnore)
	local oSingleton = tName2Singleton[i_sSingletonName];
	if not oSingleton and not i_bIgnore then
		print("ERROR!!! require singleton ERROR!!!", i_sSingletonName);
		print(debug.traceback());
	end
	return oSingleton;
end


local nDestructIndex = nil;
local nDestructOverIndex = nil;
SingletonInitialize = function()
	math.randomseed(now(1));
	nDestructIndex = #tSingletonSet;
	for k, v in ipairs(tSingletonSet) do
		if v.Initialize then
			local res1, res2 = ProtectedCall(function() return v:Initialize() end);
            --print("SingletonInitialize", v._name, res1, res2);
			if (not res1) or (not res2) then
                print("ERROR!!! SingletonInitialize Failed", v._name, res1, res2);
                return false;
			end
		end
	end
	-- 一些开服处理
	for k, v in ipairs(tSingletonSet) do
		if v.Openserverdis then
			ProtectedCall(function() return v:Openserverdis() end)
		end
	end
	return true;
end


local lasttime = now();
local curtime = 0;
SingletonUpdate = function()
	local curtime = now();
	local delta = curtime - lasttime;
   	lasttime = curtime;
	    if delta <= 0 then
	        return
	    end
	for _, v in ipairs(tUpdateSet) do
	        local f = Performance(v._name)
			-- print("SingletonUpdate", v._name);
	        ProtectedCall(function() v:Update(delta) end);
	        f()
	end
end


SingletonDayRefresh = function()
	for k, v in ipairs(tSingletonSet) do
		local OnDayRefresh = v.OnDayRefresh;
		if v.OnDayRefresh then
			-- print("SingletonDayRefresh", v._name);
			ProtectedCall(function() v:OnDayRefresh() end);
		end
	end
end

SingletonWeekRefresh = function()
	for k, v in ipairs(tSingletonSet) do
		local OnWeekRefresh = v.OnWeekRefresh;
		if v.OnWeekRefresh then
			-- print("SingletonWeekRefresh", v._name);
			ProtectedCall(function() v:OnWeekRefresh() end);
		end
	end
end


SingletonDestruct = function()
	-- print("------", nDestructIndex, nDestructOverIndex)
	if nDestructIndex then
		if nDestructIndex == 0 then return true end;
		local singleton = tSingletonSet[nDestructIndex];
		if singleton.Destruct then
			print("SingletonDestruct", singleton._name);
			ProtectedCall(function() singleton:Destruct() end);
			nDestructOverIndex = nDestructIndex;
			nDestructIndex = nil;
		else
			nDestructIndex = nDestructIndex - 1;
		end
	else
		local singleton = tSingletonSet[nDestructOverIndex];
		local res = true;
		if singleton.IsDestructOver then
			local res1, res2 = ProtectedCall(function() return singleton:IsDestructOver() end);
			if res1 then
				res = res2;
			else
				res = true;
			end
		end
		if res then
			nDestructIndex = nDestructOverIndex - 1;
			nDestructOverIndex = nil;
		end
	end
	return false;
end



