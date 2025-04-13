
-- global function
local now				= _commonservice.now;
local unpack			= unpack;
local print				= print;
local type				= type;
local tonumber			= tonumber;
local math_floor		= math.floor;
local math_ceil 		= math.ceil;
local string_match		= string.match;
local ClassNew			= ClassNew;
local ProtectedCall     = ProtectedCall;
local Performance       = Performance
local CCommonFunction	= SingletonRequire("CCommonFunction");
local Msec2Calendar		= CCommonFunction.Msec2Calendar;
local Calendar2Msec		= CCommonFunction.Calendar2Msec;
local Calendar2Week		= CCommonFunction.Calendar2Week;
local ScheduleTaskCycleTypeEnum = RequireEnum("ScheduleTaskCycleTypeEnum");

-- local
local function tointerger(i_sNum)
	local num = tonumber(i_sNum);
	num = num or -99999999;
	num = math_floor(num);
	return num;
end

--
-- CScheduleTask
--
local CScheduleTask = ClassRequire("CScheduleTask");
function CScheduleTask:_constructor(i_nGlobalID, i_nActionTime, i_nCycleTime, i_nRunTime, i_fFunc, i_tParam)
	self.m_nGlobalID = i_nGlobalID;
	self.m_nActionTime = i_nActionTime;
	self.m_nCycleTime	= i_nCycleTime;	
	if i_nRunTime and i_nRunTime > 0 then
		self.m_nRunTime = i_nRunTime;
	end
	self.m_fFunc = i_fFunc;
	self.m_tParam = i_tParam;
end

function CScheduleTask:Action()
	ProtectedCall(function() self.m_fFunc(unpack(self.m_tParam)) end);
	local bContinue = true;
	if self.m_nRunTime then
		self.m_nRunTime = self.m_nRunTime - 1;
		bContinue = self.m_nRunTime > 0;
	end
	if bContinue then
		self.m_nActionTime = self.m_nActionTime + self.m_nCycleTime;
	end
	return bContinue;
end

function CScheduleTask:GetActionTime()
	return self.m_nActionTime;
end

function CScheduleTask:GetGlobalID()
	return self.m_nGlobalID;
end

function CScheduleTask:GetNext()
	return self.m_oNext;
end

function CScheduleTask:SetNext(i_oTask)
	self.m_oNext = i_oTask;
end

--
-- CSchedule
--
local collectgarbage = collectgarbage;
local function collect_memory()
    local f = Performance("collect_memory")
	collectgarbage("collect");
    f()
end
local function print_memory()
    print("[memory]:", collectgarbage("count"));
end
local function day_refresh_singleton()
	SingletonDayRefresh();
end

local function week_refresh_singleton()
	SingletonWeekRefresh();
end

local CSchedule = SingletonRequire("CSchedule");
function CSchedule:Initialize()
	-- 任务链表
	self.m_oTaskListHead = nil;
	-- 任务ID，顺延++
	self.m_nGlobalID = 0;
	-- collectgarbage
	self:AddTask({m_nTime = now() + 30000}, ScheduleTaskCycleTypeEnum.eSecond, 30, 0, collect_memory, {});
    self:AddTask({m_nTime = now() + 30000}, ScheduleTaskCycleTypeEnum.eHour, 2, 0, print_memory, {});
    -- printperformance
    self:AddTask({m_nTime = now() + 30000}, ScheduleTaskCycleTypeEnum.eHour, 1, 0, PrintPerformance, {})
	-- dayrefresh
	self:AddTask({m_sTime = "0:0"}, ScheduleTaskCycleTypeEnum.eDay, 1, 0, day_refresh_singleton, {});
	-- weekrefresh
	self:AddTask({m_sWeek = "1", m_sTime = "0:0"}, ScheduleTaskCycleTypeEnum.eWeek, 1, 0, week_refresh_singleton, {});
	return true;
end

--更新定时器
function CSchedule:Update(i_nDeltaMsec)
	local nowTime = now();
	local task = self.m_oTaskListHead;

	if task and nowTime > task:GetActionTime() then
		self.m_oTaskListHead = task:GetNext();
		if task:Action() then
			self:AddTaskInList(task);
		end
		-- self:Trace();
	end
end

--遍历队列里所有任务并打印
function CSchedule:Trace()
	print("---------------CSchedule:Trace()-----------------")
	local temp = self.m_oTaskListHead;
	while temp do
		print("--", temp:GetGlobalID(), Msec2Calendar(temp:GetActionTime()));
		temp = temp:GetNext();
	end
	print("---------------CSchedule:Trace()-----------------")
end

--将任务添加到链表中
function CSchedule:AddTaskInList(i_oTask)
	local temp = self.m_oTaskListHead;
	if not temp or i_oTask:GetActionTime() <= temp:GetActionTime() then
		self.m_oTaskListHead = i_oTask;
		i_oTask:SetNext(temp);
	else
		while temp do
			local temp1 = temp:GetNext();
			if not temp1 or i_oTask:GetActionTime() <= temp1:GetActionTime() then
				temp:SetNext(i_oTask);
				i_oTask:SetNext(temp1);
				break;
			else
				temp = temp1; 
			end
		end
	end
	-- self:Trace(); -- 测试用
end

-- 删除任务
-- i_nGlobalID为AddTask时返回的GlobalID
function CSchedule:DelTask(i_nGlobalID)
	local temp1 = self.m_oTaskListHead;
	if not temp1 then
		return false;
	end
	local temp2 = temp1:GetNext();
	--如果是头结点
	if temp1:GetGlobalID() == i_nGlobalID then
		self.m_oTaskListHead = temp2;
		return true;
	end
	--向后查找
	while temp2 do
		if temp2:GetGlobalID() == i_nGlobalID then
			temp1:SetNext(temp2:GetNext());
			return true;
		else
			temp1 = temp2;
			temp2 = temp2:GetNext();
		end
	end
	return false;
end;

--添加定时任务
--
---- i_tTime结构体定义任务从什么时候开始，如开始时间小于now()，会自动按循环周期
---- 向后滚动直到大于now()或超出执行次数任务失败。
--------从now()开始，则为
--------{}
--------从指定时间戳开始，则为
--------{m_nTime = xxx} 单位毫秒
--------今天的几点几分，如20点30分，则为
--------{m_sTime = "20:30"}
--------本月的几号的几点几分，如5号的20点30分，则为
--------{m_sDay = "5", m_sTime = "20:30" };
--------本年的几月几号的几点几分，如5月5号的20点30分，则为
--------{m_sMonth = "5", m_sDay = "5", m_sTime = "20:30"};
--------几年几月几号的几点几分，如2012年5月5号20点30分，则为
--------{m_sYear = "2012", m_sMonth = "5", m_sDay = "5", m_sTime = "20:30"};
--------本周星期几的几点几分，如星期一20点30分，则为
--------{m_sWeek = "1", m_sTime = "20:30"}周一是1， 以此类推，7为周日
--
----i_nCycleType	循环周期单位
---- ScheduleTaskCycleTypeEnum = {
	-- eMinute 	= 1,--周期单位分钟
	-- eHour	= 2,--周期单位小时
	-- eDay		= 3,--周期单位天
	-- eWeek	= 4,--周期单位周
-- --};
-- 
----i_nCycleTime	循环间隔 几分钟、几小时、几天、几周
--
----i_nRunTime		循环执行次数，大于0为有效次数，小于等于0为无限循环直到海枯石烂
--
----i_fFunc			执行的函数
--
----i_tParam		执行的函数参数表
--
----返回值为任务ID，用于删除操作，如返回0，则说明添加任务失败
function CSchedule:AddTask(i_tTime, i_nCycleType, i_nCycleTime, i_nRunTime, i_fFunc, i_tParam, i_bIsTest)
	-- if not i_bIsTest then return 0 end;
	-- 检测参数有效性
	---- 验证时间参数
	if type(i_tTime) ~= "table" then
		print("ERROR!!! i_tTime error!", i_tTime);
		return;
	end
	---- 验证执行次数
	if type(i_nRunTime) ~= "number" then
		print("ERROR!!! i_nRunTime error!", i_nRunTime);
		return;
	end
	---- 验证循环周期
	if i_nRunTime ~= 1 then
		if type(i_nCycleType) ~= "number" then
			print("ERROR!!! i_nCycleType error!", i_nCycleType);
			return;
		end
		if (i_nCycleType < ScheduleTaskCycleTypeEnum.eSecond) or (i_nCycleType > ScheduleTaskCycleTypeEnum.eWeek) then
			print("ERROR!!! i_nCycleType error!", i_nCycleType);
			return;
		end
		if type(i_nCycleTime) ~= "number" then
			print("ERROR!!! i_nCycleTime error!", i_nCycleTime);
			return;
		end
		if i_nCycleTime <= 0 then
			print("ERROR!!! i_nCycleTime error!", i_nCycleTime);
			return;
		end
	end
	---- 验证执行函数
	if type(i_fFunc) ~= "function" then
		print("ERROR!!! i_fFunc error!", i_fFunc);
		return;
	end
	---- 验证执行函数参数
	if type(i_tParam) ~= "table" then
		print("ERROR!!! i_tParam error!", i_tParam);
		return;
	end
	
	-- 当前时间
	local nowTime = now();
	-- 执行时间
	local actionTime;
	if i_tTime.m_sTime then -- 指定时间字符串"05:30"
		local year, month, day, hour, minute, second = Msec2Calendar(nowTime);
		if i_tTime.m_sWeek then
			local week = tointerger(i_tTime.m_sWeek);
			if (week < 1) or (week > 7) then
				print("ERROR!!! week error!", week);
				return;
			end
			local todayWeek = Calendar2Week(year, month, day);
			day = day + week - todayWeek;
		else
			if i_tTime.m_sYear then
				year = tointerger(i_tTime.m_sYear);
				if year < 1970 or year > 2030 then
					print("ERROR!!! year error!", year);
					return;
				end
			end
			if i_tTime.m_sMonth then
				month = tointerger(i_tTime.m_sMonth);
				if month < 1 or month > 12 then
					print("ERROR!!! month error!", month);
					return;
				end
			end
			if i_tTime.m_sDay then
				day = tointerger(i_tTime.m_sDay);
				if day < 0 then
					print("ERROR!!! day error!", day);
					return;
				end
			end
		end
		local s_Hour, s_Minute = string_match(i_tTime.m_sTime, "(%d*):(%d*)");
		hour = tointerger(s_Hour);
		minute = tointerger(s_Minute);
		second = 0;
		if hour < 0 or hour > 24 or minute < 0 or minute > 60 then
			print("ERROR!!! hour or minute error!", hour, minute);
			return;
		end
		actionTime = Calendar2Msec(year, month, day, hour, minute, second);
	elseif i_tTime.m_nTime then -- 指定时间戳毫秒
		actionTime = i_tTime.m_nTime;
	else -- 下一帧立即执行
		actionTime = nowTime
	end
	
	local cycleTime;
	if i_nRunTime ~= 1 then
        if i_nCycleType == ScheduleTaskCycleTypeEnum.eSecond then
            cycleTime = i_nCycleTime * 1000
		elseif i_nCycleType == ScheduleTaskCycleTypeEnum.eMinute then
			cycleTime = i_nCycleTime * 60000;
		elseif i_nCycleType == ScheduleTaskCycleTypeEnum.eHour then
			cycleTime = i_nCycleTime * 3600000;
		elseif i_nCycleType == ScheduleTaskCycleTypeEnum.eDay then
			cycleTime = i_nCycleTime * 86400000;
		elseif i_nCycleType == ScheduleTaskCycleTypeEnum.eWeek then
			cycleTime = i_nCycleTime * 604800000;
		else
			print("ERROR!!! i_nCycleType error!", i_nCycleType);
			return;
		end
	end
    if cycleTime then
        cycleTime = math_ceil(cycleTime)
    end
	
	if i_nRunTime <= 0 then
		while actionTime < nowTime do
			actionTime = actionTime + cycleTime;
		end
	else
		while actionTime < nowTime do
			i_nRunTime = i_nRunTime - 1;
			if i_nRunTime <= 0 then
				print("ERROR!!! actionTime error! out of date.");
				return
			end
			actionTime = actionTime + cycleTime;
		end
	end

	self.m_nGlobalID = self.m_nGlobalID + 1;
	local task = ClassNew("CScheduleTask", self.m_nGlobalID, actionTime, cycleTime, i_nRunTime, i_fFunc, i_tParam);
	self:AddTaskInList(task);
	return self.m_nGlobalID;
end

-------------------------------------------------test----------------------------------------------------------
-- local Time1 = {m_sWeek = "0", m_sTime = "21:45"};
-- local Time2 = {m_sWeek = "1", m_sTime = "21:45"};
-- local Time3 = {m_sWeek = "2", m_sTime = "21:45"};
-- local Time4 = {m_sWeek = "3", m_sTime = "21:45"};
-- local Time5 = {m_sWeek = "4", m_sTime = "21:45"};
-- local Time6 = {m_sWeek = "5", m_sTime = "21:45"};
-- local Time7 = {m_sWeek = "6", m_sTime = "21:45"};
-- CSchedule:AddTask(Time1, ScheduleTaskCycleTypeEnum.eHour, 1, 2, print, {"-------2"}, true);
-- CSchedule:AddTask(Time1, ScheduleTaskCycleTypeEnum.eDay, 1, 2, print, {"-------3"}, true);
-- CSchedule:AddTask(Time1, ScheduleTaskCycleTypeEnum.eWeek, 1, 2, print, {"-------4"}, true);


