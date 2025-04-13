
-- global function
local print			= print;
local logfile		= logfile
local type          = type
local pairs         = pairs
local tostring      = tostring
local table_insert  = table.insert
local table_concat  = table.concat
local math_floor	= math.floor;
local math_random   = math.random
local string_format	= string.format;
local string_gsub   = string.gsub
local string_len    = string.len
local string_sub    = string.sub
local string_byte   = string.byte
local string_gmatch	= string.gmatch

local now			= _commonservice.now;
local localtime		= _commonservice.localtime;
local mktime		= _commonservice.mktime;

-- local function
local oneminutesecs	= 60;
local onehoursecs	= 3600;
local onedaysecs	= 86400;
local oneweeksecs	= 604800;
local mod           = 10000
-- local leapyeardays		= {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
-- local nonleapyeardays	= {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};


----------------
-- isleapyear --
----------------
local function isleapyear(year)
	return (year % 400 == 0) or ((year % 4 == 0) and (year % 100 ~= 0));
end;
------------------
-- sec2calendar --
------------------
local function sec2calendar(sec)
	local year, month, day, hour, minute, sec, week = localtime(sec);
	return year, month, day, hour, minute, sec;
end;
------------------
-- sec2week --
------------------
local function sec2week(sec)
	local year, month, day, hour, minute, sec, week = localtime(sec);
	if week == 0 then
		week = 7;
	end;
	return week;
end;
-------------------
-- calendar2week --
-------------------
local function calendar2week(y, m, d)
	if (m == 1) then
		m = 13;
		y = y - 1;
	end
	if (m == 2) then
		m = 14;
		y = y - 1;
	end
	return (( d + (2 * m) + math_floor(3 * (m + 1) / 5) + y + math_floor(y / 4) - math_floor(y / 100) + math_floor(y / 400) ) % 7) + 1;
end;
------------------
-- calendar2sec --
------------------
local function calendar2sec(year, month, day, hour, minute, sec)
	return mktime(year, month, day, hour, minute, sec);
end;
-------------------
-- todaystartsec --
-------------------
local todaystartsec = 0;
local function gettodaystartsec()
	local cursec = now(1);
	if (cursec - todaystartsec) < onedaysecs then
		return todaystartsec;
	else
		local year, month, day = sec2calendar(cursec);
		todaystartsec = calendar2sec(year, month, day, 0, 0, 0);
		return todaystartsec;
	end;
end;
local function gettodaythistimesec(hour, minute, second)
	return gettodaystartsec() + hour * onehoursecs + minute * oneminutesecs + second;
end;

local function getstartsec(cursec)
    local year, month, day = sec2calendar(cursec)
    return calendar2sec(year, month, day, 0, 0, 0)
end;

-------------------
-- thisweekstartsec --
-------------------
local thisweekstartsec = 0;
local function getthisweekstartsec()
	local cursec = now(1);
	if (cursec - thisweekstartsec) < oneweeksecs then
		return thisweekstartsec;
	else
		thisweekstartsec = gettodaystartsec();
		local week = sec2week(thisweekstartsec);
		thisweekstartsec = thisweekstartsec - onedaysecs * (week - 1);
		return thisweekstartsec;
	end;
end;

------------------------------------------------------------------------------

-- local
local CCommonFunction = SingletonRequire("CCommonFunction");

-- 时间戳转星期几
CCommonFunction.Sec2Week = function(i_nSec)
	return sec2week(i_nSec);
end;
-- 时间戳毫秒数转星期几
CCommonFunction.Msec2Week = function(i_nMsec)
	return sec2week(math_floor(i_nMsec / 1000));
end;
-- 时间戳转日历日
CCommonFunction.Sec2Calendar = function(i_nSec, i_bStr)
	if i_bStr then
		return string_format("%04d-%02d-%02d %02d:%02d:%02d", sec2calendar(i_nSec));
	else
		return sec2calendar(i_nSec);
	end;
end;
-- 时间戳毫秒数转日历日
CCommonFunction.Msec2Calendar = function(i_nMsec, i_bStr)
	return CCommonFunction.Sec2Calendar(math_floor(i_nMsec / 1000), i_bStr);
end;
-- 日历日转星期几
CCommonFunction.Calendar2Week = function(i_nYear, i_nMonth, i_nDay)
	return calendar2week(i_nYear, i_nMonth, i_nDay);
end;
-- 日历日转时间戳
CCommonFunction.Calendar2Sec = function(i_nYear, i_nMonth, i_nDay, i_nHour, i_nMinute, i_nSecond)
	return calendar2sec(i_nYear, i_nMonth, i_nDay, i_nHour, i_nMinute, i_nSecond);
end;
-- 日历日转时间戳毫秒数
CCommonFunction.Calendar2Msec = function(i_nYear, i_nMonth, i_nDay, i_nHour, i_nMinute, i_nSecond)
	return calendar2sec(i_nYear, i_nMonth, i_nDay, i_nHour, i_nMinute, i_nSecond) * 1000;
end;
-- 获取今天开始时间戳
CCommonFunction.GetTodayStartSec = function()
	return gettodaystartsec();
end;
-- 获取今天开始时间戳毫秒数
CCommonFunction.GetTodayStartMsec = function()
	return gettodaystartsec() * 1000;
end;
-- 获取指定时间的那天开始时间戳
CCommonFunction.GetStartsec = function(cursec)
    return getstartsec(cursec);
end;
-- 获取今天指定时间的时间戳
CCommonFunction.GetTodayThisTimeSec = function(i_nHour, i_nMinute, i_nSecond)
	return gettodaythistimesec(i_nHour, i_nMinute, i_nSecond);
end;
-- 获取今天指定时间的时间戳毫秒数
CCommonFunction.GetTodayThisTimeMsec = function(i_nHour, i_nMinute, i_nSecond)
	return gettodaythistimesec(i_nHour, i_nMinute, i_nSecond) * 1000;
end;
-- 时间戳是否是在今天
CCommonFunction.IsSecInToday = function(i_nSec)
	local sec = gettodaystartsec();
	return (i_nSec >= sec) and (i_nSec < sec + onedaysecs)
end;
-- 时间戳毫秒数是否是在今天
CCommonFunction.IsMsecInToday = function(i_nMsec)
	return CCommonFunction.IsSecInToday(math_floor(i_nMsec / 1000));
end;
-- 指定时间戳是否在本周
CCommonFunction.IsSecInThisWeek = function(i_nSec)
	local sec = getthisweekstartsec();
	return (i_nSec >= sec) and (i_nSec < sec + oneweeksecs);
end
-- 指定时间戳毫秒数是否在本周
CCommonFunction.IsMsecInThisWeek = function(i_nMsec)
	return CCommonFunction.IsSecInThisWeek(math_floor(i_nMsec/ 1000));
end

-- 保护SQL防止SQL注入
CCommonFunction.ProtectSql = function(i_sSql)
	return string_gsub(i_sSql, "'", "’")
end

-- 获取字符串字符个数 汉字算一个
CCommonFunction.GetCharNum = function(i_sStr)
    local i = 1
    local num = 0
    local nLen = string_len(i_sStr)
    while (i <= nLen) do
        local s1 = string_sub(i_sStr, i, i)
        local byte1 = string_byte(s1)
        if byte1 > 0xF0 then  -- [1111 0xxx] [10xx xxxx] [10xx xxxx] [10xx xxxx]
            i = i + 4
        elseif byte1 > 0xE0 then  -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
            i = i + 3
        elseif byte1 > 0xC0 then -- [110x xxxx] [10xx xxxx]
            i = i + 2
        else
            i = i + 1
        end
        num = num + 1
    end
    return num
end

-- 打印表
local tRecursion = {}
local function print_table(tab, depth, f)
    local t = {}
    for i = 1, depth do
        table_insert(t, "  ")
    end
    local str = table_concat(t)
	for k, v in pairs(tab) do
		if type(v) == "table" then
        	f(str .. "[".. k .. "](" .. type(k) .. ") = " .. tostring(v))
        else
        	f(str .."[".. k .. "](" .. type(k) .. ") = " .. tostring(v) .. "(" .. type(v) .. ")")
        end
        if type(v) == "table" and not tRecursion[v] then
            tRecursion[v] = true
            print_table(v, depth + 1, f)
        end
    end
end

CCommonFunction.PrintTable = function(i_tTable, i_bStdOut)
    if type(i_tTable) ~= "table" then
        print("WARNING!!! PrintTable param not a table.")
        return
    end
    local f = i_bStdOut and print or logfile
    f("----- table print begin -----")
    print_table(i_tTable, 0, f)
    f("----- table print end ------")
    tRecursion = {}
end

function CCommonFunction.Get_db_str(i_tTokenInfo)
	local tTemp = {};
	for nPos, nValue in pairs(i_tTokenInfo) do
		table_insert(tTemp, string_format("%d,%d", tonumber(nPos), tonumber(nValue)));
	end
	return table_concat(tTemp, ";");
end

function CCommonFunction.Parse_db_str(i_sTokenInfo)
	local tTokenInfo = {};
	for nPos, nValue in string_gmatch(i_sTokenInfo, "(%d+),(%d+)") do
		tTokenInfo[tonumber(nPos)] = tonumber(nValue);
	end
	return tTokenInfo;
end

local bdelog = true 
-- 打log
function delog( sLog, ... )
	if bdelog then 
		if not sLog then
			print( "=====error====",nil )
			return
		end
		if type(sLog) == "table" then
		    print("************ table print begin **********")
			print_table(sLog, 3, print)
			print("************ table print end ***********")
			tRecursion = {}
		else
			print( sLog, ... )
		end
	end 
end

--[[
    --@brief 字符串分割函数
    --@param srcstr
    --@param delimiter
    --@return 返回一个table
--]]
function string.split(srcstr, delimiter)
    if type(srcstr) ~= "string" then
        assert(false, "srcstr need string");
        print(debug.traceback());
    end
    local len = string.len(srcstr);
    local itr, index = 1, 1;
    local array = {};
    while true do
        local beginpos, endpos = string.find(srcstr, delimiter, itr);
        if not beginpos then
            array[index] = string.sub(srcstr, itr, len);
            break;
        end
        array[index] = string.sub(srcstr, itr, beginpos - 1);
        itr = endpos + 1;
        index = index + 1;
    end
    return array;
end

-- 计算utf8字符长度
function string.utf8len(input)  
    local len  = string.len(input)  
    local left = len  
    local cnt  = 0  
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}  
    while left ~= 0 do  
        local tmp = string.byte(input, -left)  
        local i   = #arr  
        while arr[i] do  
            if tmp >= arr[i] then  
                left = left - i  
                break  
            end  
            i = i - 1  
        end  
        cnt = cnt + 1  
    end  
    return cnt  
end

--[[
	table与字符串转化	
--]]

local function ToStringEx(value, bArry)
    if type(value)=='table' then
       return TableToStr(value, bArry)
    elseif type(value)=='string' then
        return "\""..value.."\""
    else
       return tostring(value)
    end
end

function TableToStr(t, bArry)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if bArry then
            retstr = retstr..signal..ToStringEx(value, bArry)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end

        i = i+1
    end

	retstr = retstr.."}"
	return retstr
end

function StrToTable(str)
    if str == nil or type(str) ~= "string" or str == "" then
        return {}
    end
    return loadstring("return " .. str)()
end

function WeightRandom(i_tIdx, i_tWeight, i_nCount)
    local tResultIdx = {}
    local tAwardPool = { }
    local nTotalWeight = 0
    for i,v in ipairs(i_tIdx) do
        nTotalWeight = nTotalWeight + (i_tWeight[i] or 0)
        table_insert(tAwardPool, nTotalWeight)
    end
    
    for i = 1, i_nCount do
        local nRandom = math_random(1, nTotalWeight);
        for i,v in ipairs(tAwardPool) do
            if v >= nRandom then
                table_insert(tResultIdx, i_tIdx[i])
                break
            end
        end
    end
    return tResultIdx
end

function WeightRandomRetIdx(i_tIdx, i_tWeight, i_nCount)
    local tResultIdx = {}
    local tAwardPool = { }
    local nTotalWeight = 0
    for i,v in ipairs(i_tIdx) do
        nTotalWeight = nTotalWeight + (i_tWeight[i] or 0)
        table_insert(tAwardPool, nTotalWeight)
    end
    
    for i = 1, i_nCount do
        local nRandom = math_random(1, nTotalWeight);
        for i,v in ipairs(tAwardPool) do
            if v >= nRandom then
                table_insert(tResultIdx, i)
                break
            end
        end
    end
    return tResultIdx
end

function WeightByArray(i_tWeight)
    local tResultIdx = {}
    local tAwardPool = { }
    local nTotalWeight = 0
    for i,v in ipairs(i_tWeight) do
        nTotalWeight = nTotalWeight + (i_tWeight[i] or 0)
        table_insert(tAwardPool, nTotalWeight)
    end
    local nRandom = math_random(1, nTotalWeight);
    for i,v in ipairs(tAwardPool) do
        if v >= nRandom then
            return i
        end
    end
end

local function creat(s)
    if s == nil then
        return
    end
    if type(s) == "number" then
        s = tostring(s)
    end
    if s["xyBitInt"] == true then
        return s
    end
    local n,t,a = math.floor(#s/4),1,{}
    a["xyBitInt"] = true
    if #s%4 ~= 0 then
        a[n + 1] ,t = tonumber(string.sub(s,1,#s%4),10),#s%4 + 1
    end
    for i = n,1,-1 do
        a[i],t = tonumber(string.sub(s,t,t+3),10),t+4
    end
    return a
end

local function get(a)
    local s = {a[#a]}
    for i = #a -1,1,-1 do
        table.insert(s,string.format("%04d",a[i]))
    end
    return table.concat(s,"")
end
-- 大数实现加
function addInt(a,b)
    local a,b,c,t = creat(a),creat(b),creat("0"),0
    for i = 1,math.max(#a,#b) do
        t = t + (a[i] or 0) + (b[i] or 0)
        c[i],t = t%mod,math.floor(t/mod)
    end
    while t ~= 0 do
        c[#c + 1],t = t%mod,math.floor(t/mod)
    end
    return get(c)
end
-- 大数实现减
function subInt(a,b)
    local a,b,c,t = creat(a),creat(b),creat("0"),0
    if #a < #b then
        return get(a),false
    end
    for i = 1,#a do
        c[i] = a[i] - t -(b[i] or 0)
        if c[i] < 0 then
            t,c[i] = 1,c[i] + mod
        else
            t = 0
        end
    end
    if t == 0 then
        local str_num = get(c)
        -- 去掉首位连续的零
        local len = string_len(str_num)
        local list = {}         -- 数组
        for i = 1,len do
            list[i] = string_sub(str_num,i,i)
        end
        local cout = 1
        local iszero = true
        for i = 1,len do
            if tonumber(list[i]) ~= 0 then -- 找到首不为0的位
                cout = i
                iszero = false
                break
            end
        end
        if iszero then
            return "0",true     -- 正好够
        end
        local s = ""    -- 拼接
        for i = cout,len do
            s = s..list[i]
        end
        return s,true
    else
        return get(a),false
    end
end
-- 大数实现乘(整型)
function byInt(a,b)
    local a,b,c,t = creat(a),creat(b),creat("0"),0
    for i = 1,#a do
        for j = 1,#b do
            t = t + (c[i+j - 1] or 0) + a[i] * b[j]
            c[i + j - 1], t = t%mod,math.floor(t/mod)
        end
        if t ~= 0 then
            c[i + #b],t = t + (c[i + #b] or 0),0
        end
    end
    return get(c)
end

-- 大数实现乘(ab是小数),只返回整数部分
function byFloat(a,b)
    if type(a) ~= "string" or type(b) ~= "string" then
        return
    end
    local rem = getstrRem(a) + getstrRem(b)
    local n_a = floatToInt(a)
    local n_b = floatToInt(b)
    local c = byInt(n_a,n_b)
    
    if rem == 0 then
        return c
    end
    local c_len = string_len(c)
    if rem >= c_len then
        return "0" -- 只保留整数部分
    end
    
    local c_list = {}
    for i = 1,c_len do
        c_list[i] = string_sub(c,i,i)       -- 转数组
    end
    local d = ""
    for i = 1,c_len do
        if i == (c_len - rem + 1) then
            break
        else
            d = d..c_list[i]
        end
    end
    return d
end

-- Table长度
function TableLeng(t)
    local leng = 0
    for k, v in pairs(t) do
        leng = leng + 1
    end
    return leng
end

-- 保留n位小数
function GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum;
    end
    n = n or 0;
    n = math.floor(n)
    if n < 0 then
        n = 0;
    end
    local nDecimal = 10 ^ n
    local nTemp = math.floor(nNum * nDecimal);
    local nRet = nTemp / nDecimal;
    return nRet;
end

-- 线是否在矩形内
-- i_tLineStartPoint : 线段起点 {x = x轴值, y = y轴值}
-- i_tLineEndPoint : 线段终点 {x = x轴值, y = y轴值}
-- i_tRect : 矩形 {{左下点},{左上点},{右上点},{右下点}}
function LineInRect(i_tLineStartPoint, i_tLineEndPoint, i_tRect)
    if i_tLineStartPoint.x < i_tRect[1].x or i_tLineStartPoint.x > i_tRect[3].x then
        return false
    end
    if i_tLineStartPoint.y > i_tRect[1].y or i_tLineStartPoint.y < i_tRect[2].y then
        return false
    end
    if i_tLineEndPoint.x < i_tRect[1].x or i_tLineEndPoint.x > i_tRect[3].x then
        return false
    end
    if i_tLineEndPoint.y > i_tRect[1].y or i_tLineEndPoint.y < i_tRect[2].y then
        return false
    end
    return true
end

-- 线与矩形是否相交
-- i_tLineStartPoint : 线段起点 {x = x轴值, y = y轴值}
-- i_tLineEndPoint : 线段终点 {x = x轴值, y = y轴值}
-- i_tRect : 矩形 {{左下点},{左上点},{右上点},{右下点}}
function LineIntersectRect(i_tLineStartPoint, i_tLineEndPoint, i_tRect)
    if LineIntersectLine(i_tLineStartPoint, i_tLineEndPoint, i_tRect[1], i_tRect[2]) then
        return true
    end
    if LineIntersectLine(i_tLineStartPoint, i_tLineEndPoint, i_tRect[1], i_tRect[3]) then
        return true
    end
    if LineIntersectLine(i_tLineStartPoint, i_tLineEndPoint, i_tRect[3], i_tRect[4]) then
        return true
    end
    if LineIntersectLine(i_tLineStartPoint, i_tLineEndPoint, i_tRect[4], i_tRect[2]) then
        return true
    end
    return false
end

-- 线与线是否相交
function LineIntersectLine(i_tStartPoint1, i_tEndPoint1, i_tStartPoint2, i_tEndPoint2)
    return QuickReject(i_tStartPoint1, i_tEndPoint1, i_tStartPoint2, i_tEndPoint2) and Straddle(i_tStartPoint1, i_tEndPoint1, i_tStartPoint2, i_tEndPoint2)
end

-- 快速排序。  true=通过， false=不通过
function QuickReject(i_tStartPoint1, i_tEndPoint1, i_tStartPoint2, i_tEndPoint2)
    local l1xMax = math.max(i_tStartPoint1.x, i_tEndPoint1.x)
    local l1yMax = math.max(i_tStartPoint1.y, i_tEndPoint1.y)
    local l1xMin = math.min(i_tStartPoint1.x, i_tEndPoint1.x)
    local l1yMin = math.min(i_tStartPoint1.y, i_tEndPoint1.y)

    local l2xMax = math.max(i_tStartPoint2.x, i_tEndPoint2.x)
    local l2yMax = math.max(i_tStartPoint2.y, i_tEndPoint2.y)
    local l2xMin = math.min(i_tStartPoint2.x, i_tEndPoint2.x)
    local l2yMin = math.min(i_tStartPoint2.y, i_tEndPoint2.y)

    if l1xMax < l2xMin or l1yMax < l2yMin or l2xMax < l1xMin or l2yMax < l1yMin then
        return false
    end

    return true
end

-- 跨立实验
function Straddle(i_tStartPoint1, i_tEndPoint1, i_tStartPoint2, i_tEndPoint2)
    local l1x1 = i_tStartPoint1.x
    local l1x2 = i_tEndPoint1.x
    local l1y1 = i_tStartPoint1.y
    local l1y2 = i_tEndPoint1.y
    local l2x1 = i_tStartPoint2.x
    local l2x2 = i_tEndPoint2.x
    local l2y1 = i_tStartPoint2.y
    local l2y2 = i_tEndPoint2.y

    if (((l1x1 - l2x1) * (l2y2 - l2y1) - (l1y1 - l2y1) * (l2x2 - l2x1)) * ((l1x2 - l2x1) * (l2y2 - l2y1) - (l1y2 - l2y1) * (l2x2 - l2x1))) > 0 or
       (((l2x1 - l1x1) * (l1y2 - l1y1) - (l2y1 - l1y1) * (l1x2 - l1x1)) * ((l2x2 - l1x1) * (l1y2 - l1y1) - (l2y2 - l1y1) * (l1x2 - l1x1))) > 0
    then
        return false
    end
    return true
end