-- 调试工具

local tostring = tostring
local print = print
local logfile = logfile
local type = type
local pairs = pairs
local ipairs = ipairs
local math_huge = math.huge
local string_format = string.format
local table_insert = table.insert
local table_sort = table.sort
local debug_getinfo = debug.getinfo
local debug_getlocal = debug.getlocal
local debug_sethook = debug.sethook

local function ValStr(value)
	if type(value) == "string" then
		return "'"..value.."'"
	end
	return tostring(value)
end
local function ShowTable(space, tb)
	local sType
	for k,v in pairs(tb) do
		sType = type(v)
		if sType ~= "function" then
			if sType == "table" then
				print(space.."["..ValStr(k).."] = {")
				ShowTable(space.."  ", v)
				print(space.."},")
			else
				print(space.."["..ValStr(k).."] = "..ValStr(v) .. ",")
			end
		end
	end
end

-- 查看局部变量
-- param:DetailLevel,变量详情等级
-- nil	为默认等级，不显示table内部数据
-- 1	会显示table内数据，但不显示table中的table的内部数据	
-- 2	最强等级，将table里的东东统统显示出来
local function bp(DetailLevel)
	local t = debug_getinfo(2, 'nl')
	print("==================== ShowLocalValues ====================")
	print("function:"..tostring(t.name),"line:"..t.currentline)
	local sType
	for i = 1, math.huge do
		local name, value = debug_getlocal(2, i)
		if not name then break end
		sType = type(value)
		if sType ~= "function" then
			if sType ~= "table" then
				print(tostring(name).." = "..ValStr(value))
			elseif not DetailLevel then
				print(tostring(name).." = "..ValStr(value))
			elseif DetailLevel == 2 then
				print(tostring(name).." = {")
				ShowTable("  ", value);
				print("}")
			else
				print(tostring(name).." = {")
				for k,v in pairs(value) do
					if type(v) ~= "function" then
						print("  ["..ValStr(k).."] = ".. ValStr(v) .. ",")
					end
				end
				print("}")
			end
		end
	end
	print("========================= End ===========================")
end

-- 查看指定变量
local function bp1(showVal, DetailLevel)
	local t = debug_getinfo(2, 'nl')
	print("==================== ShowLocalValues ====================")
	print("function:"..tostring(t.name),"line:"..t.currentline)
	local sType
	for i = 1, math.huge do
		local name, value = debug_getlocal(2, i)
		if not name then break end
		if showVal == tostring(name) then
			sType = type(value)
			if sType ~= "function" then
				if sType ~= "table" then
					print(tostring(name).." = "..ValStr(value))
				elseif not DetailLevel then
					print(tostring(name).." = "..ValStr(value))
				elseif DetailLevel == 2 then
					print(tostring(name).." = {")
					ShowTable("  ", value);
					print("}")
				else
					print(tostring(name).." = {")
					for k,v in pairs(value) do
						if type(v) ~= "function" then
							print("  ["..ValStr(k).."] = ".. ValStr(v) .. ",")
						end
					end
					print("}")
				end
			end
			break
		end
	end
	print("========================= End ===========================")
end

-- 服务于xpcall_err
local function bp2()
	local sType
	for i = 1, math.huge do
		local name, value = debug_getlocal(3, i)
		if not name then break end
		sType = type(value)
		if sType ~= "function" then
			print(tostring(name).." = "..ValStr(value))
		end
	end
end

--- 性能剖析相关
local Counters = {}
local Names = {}
local bPause = false
local bPrinting = false
-- 开启性能剖析
local function pfStart()
	debug_sethook(function ()
		if bPause or bPrinting then return end
		
		local info = debug_getinfo(2, "Sn")
		if info.what == "C" then return end	-- 排除c函数
		
		local f = debug_getinfo(2, "f").func
		if Counters[f] then
			Counters[f] = Counters[f] + 1
		else
			Counters[f] = 1
			Names[f] = info
		end
	end, "c")
end
-- 结束性能剖析
local function pfEnd()
	debug_sethook()
end

local function getName(func)
	local n = Names[func]
	local lc = string_format("[%s]:%s", n.short_src, n.linedefined)
	if n.namewhat ~= "" then
		return string_format("%s (%s)", lc, n.name)
	else
		return lc
	end
end

local function sortFunc(a,b)
	return a[2] > b[2]
end
-- 打印剖析情况
-- num:查看调用次数前num名的函数
local function pfPrint(num)
	bPrinting = true;
	local temp = {}
	print("================== ShowProfileDetails ===================")
	for func, cnt in pairs(Counters) do
		temp[#temp+1] = {func, cnt}
	end
	table_sort(temp, sortFunc)
	for i = 1, num do
		if not temp[i] then break end
		print(getName(temp[i][1]), "count:"..temp[i][2])
	end
	print("========================= End ===========================")
	bPrinting = false;
end

-- 清空计数
local function pfClear()
	Counters = {}
	Names = {}
end

-- 暂停性能剖析
local function pfPause()
	bPause = true
end

-- 恢复性能剖析
local function pfResume()
	bPause = false
end

DebugTool = {
	bp = bp;
	bp1 = bp1;
	bp2 = bp2;
	pfStart = pfStart;
	pfEnd = pfEnd;
	pfPrint = pfPrint;
	pfClear = pfClear;
	pfPause = pfPause;
	pfResume = pfResume;
}


-- 性能统计
local realnow = _commonservice.realnow
local tTemp = {}
Performance = function(i_sLog)
    local a1, a2 = realnow()
    return function()
        local b1, b2 = realnow()
        local c = (b1-a1) * 1000000 + (b2-a2)
        if c >= 100000 then
            local info = tTemp[i_sLog] or {name = i_sLog, times = 0, totalmcs = 0, maxmcs = 0, averagemcs = 0}
            info.times = info.times + 1
            info.totalmcs = info.totalmcs + c
            if info.maxmcs < c then
                info.maxmcs = c
            end
            tTemp[i_sLog] = info
        end
    end
end

PrintPerformance = function()
    -- 按次数排
    local temp_times = {}
    -- 按执行时间排
    local temp_mcs = {}
    
    for _, info in pairs(tTemp) do
        info.averagemcs = info.totalmcs / info.times
        table_insert(temp_times, info)
        table_insert(temp_mcs, info)
    end
    table_sort(temp_times, function(a, b)
        return a.times > b.times
    end)
    table_sort(temp_mcs, function(a, b)
        return a.averagemcs > b.averagemcs
    end)
    logfile("-----performance times-----")
    for _, info in ipairs(temp_times) do
        logfile(info.name, info.times, info.maxmcs, info.averagemcs)
    end
    logfile("-----performance times-----")
    logfile("-----performance averagemcs-----")
    for _, info in ipairs(temp_mcs) do
        logfile(info.name, info.times, info.maxmcs, info.averagemcs)
    end
    logfile("-----performance averagemcs-----")
    
    tTemp = {}
end


