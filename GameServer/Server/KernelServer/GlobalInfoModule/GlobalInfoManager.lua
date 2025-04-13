
-- global function
local now			= _commonservice.now;
local tonumber      = tonumber
local math_random	= math.random;
local string_match  = string.match
local tostring 		= tostring
-- global class
local CCommonFunction = SingletonRequire("CCommonFunction");
local CDBService	= SingletonRequire("CDBService");
local CDBCommand	= SingletonRequire("CDBCommand");
local CDBServerManager     = SingletonRequire("CDBServerManager");
local CDataReport		   = SingletonRequire("CDataReport");


-- local
local CGlobalInfoManager = SingletonRequire("CGlobalInfoManager");
function CGlobalInfoManager:Initialize()
	self.m_nServerID	= ServerInfo.serverid;
    self.m_nMailNum     = 0;    -- 至今为止邮件的总产量
	self.m_nMarryIndex  = 0;    -- 至今为止情缘的总量
	self.m_nFriendIndex = 0;    -- 至今为止好友的总量
    self.m_nRoleIndex	= 0;
	self.m_nGuildIndex  = 0;
	self.m_nChatWorldIndex  = 0;
	self.m_nMarryNum 	= 0;
	self.m_tRankVer	= {0, 0};	-- 跨服排行榜刷新时间
	self.m_sIncBattleId = "0";	-- 自增战斗Id
	if self.m_nServerID == 0 then
        return false
	end;

	-- 设置本服务器数据库连接属性
	CDBService:SetID2Info(self.m_nServerID, ServerInfo.gamedb_host, ServerInfo.gamedb_port,
		ServerInfo.gamedb_user, ServerInfo.gamedb_pwd, ServerInfo.gamedb_name)
    
	-- 设置本服务器数据库(另一个线程)连接属性
	CDBServerManager:DBThreadSetID(self.m_nServerID, ServerInfo.gamedb_host, ServerInfo.gamedb_port,
		ServerInfo.gamedb_user, ServerInfo.gamedb_pwd, ServerInfo.gamedb_name)
    -- 数据库初始化
    local res = CDBService:Execute('show tables like "dbinfo"', self.m_nServerID)
    if #res == 0 then
        local sql_insert
        if ServerInfo.isbridge then
            sql_insert = dofile("./Server/KernelServer/GlobalInfoModule/sql_init_bridge.lua")
        else
            sql_insert = dofile("./Server/KernelServer/GlobalInfoModule/sql_init_normal.lua")
			local tData = {
				timestamp = tostring(now(1)),
				status = "finished",
			}
			CDataReport:DataReport("retreat", tData)
        end
        for _, v in ipairs(sql_insert) do
            CDBService:Execute(v, self.m_nServerID)
        end
    end
    
    -- 刷数据库增量更新
    local oSelectCmd = CDBCommand:CreateSelectCmd("dbinfo")
	local res = oSelectCmd:Execute();
	local dbversion = 0
	if res[1] then
		dbversion = res[1].dbversion
	end
    
    local sql_update
    if ServerInfo.isbridge then
        sql_update = dofile("./Server/KernelServer/GlobalInfoModule/sql_bridge.lua")
    else
        sql_update = dofile("./Server/KernelServer/GlobalInfoModule/sql_normal.lua")
    end
    if #sql_update > dbversion then
        for i=1, #sql_update do
            if i > dbversion then
                CDBService:Execute(sql_update[i], self.m_nServerID)
            end
        end
        dbversion = #sql_update
        local oUpdateCmd = CDBCommand:CreateUpdateCmd("dbinfo")
        oUpdateCmd:SetFields("dbversion", dbversion)
        oUpdateCmd:SetNoWhere()
        oUpdateCmd:Execute()
        print("Log!!! cur db version.", dbversion)
    elseif #sql_update < dbversion then -- 如果当前数据库里的版本号比代码还高 说明版本回退了 不让起服
        print("ERROR!!! cur db version > #sql_update.", dbversion, #sql_update)
        return false
    end
    
    -- 初始化服务器信息
	oSelectCmd = CDBCommand:CreateSelectCmd("globalinfo");
	oSelectCmd:SetWheres("serverid", self.m_nServerID, "=");
	res = oSelectCmd:Execute();
	if res then
		if res[1] then
            if res[1].realopentime and res[1].realopentime > 0 then
                self.m_nOpenTime = res[1].realopentime
                self.m_bOpenTimeBeSet = true
            else
                self.m_nOpenTime = res[1].opentime
                self.m_bOpenTimeBeSet = false
            end
            self.m_nMailNum  = res[1].mailnum;
            self.m_nRoleIndex = res[1].roleindex;
			self.m_nGuildIndex= res[1].guildindex;
			self.m_nChatWorldIndex = res[1].chatworldindex
            self.m_nRefreshTime = res[1].refreshtime;
			self.m_nMarryNum = res[1].marrynum;
			self.m_nMarryIndex = res[1].marryindex;
			self.m_nFriendIndex = res[1].friendindex;
			self.m_nShuttime = res[1].shuttime
			self.m_bCrossDay = not CCommonFunction.IsSecInToday(self.m_nShuttime);	-- 设置跨天开服标记
			self.m_tRankVer[1] = res[1].rank1v1ver;
			self.m_tRankVer[2] = res[1].rank3v3ver;
			self.m_sIncBattleId = res[1].incbattleid;
			self.m_nHefuTime = res[1].hefu;
            self.m_nHefuCishu = res[1].hefutimes
            if self.m_nHefuTime and self.m_nHefuTime > 0 and self.m_nHefuCishu == 0 then -- 修正一下合服次数
                self.m_nHefuCishu = 1
                local oCmd = CDBCommand:CreateUpdateCmd("globalinfo")
                oCmd:SetFields("hefutimes", self.m_nHefuCishu);
                oCmd:SetWheres("serverid", self.m_nServerID, "=");
                oCmd:Execute();
            end
			self.m_nBridgeHoleLevel = res[1].bridgeholelevel;
		else
            self.m_nOpenTime = now(1)
            self.m_bOpenTimeBeSet = false
			self.m_nRefreshTime = 0
			self.m_nBridgeHoleLevel = 0
			local oInsertCmd = CDBCommand:CreateInsertCmd("globalinfo");
			oInsertCmd:SetFields("serverid", self.m_nServerID);
			oInsertCmd:SetFields("opentime", self.m_nOpenTime)
			oInsertCmd:SetFields("refreshtime", self.m_nRefreshTime);
			oInsertCmd:Execute(true);
		end
	else
		print("ERROR!!! CGlobalInfoManager:Initialize()");
        return false
	end
    
    local year, month, day, hour, minute = CCommonFunction.Sec2Calendar(self.m_nOpenTime)
    self.m_nOpenDayTime = CCommonFunction.Calendar2Sec(year, month, day, 0, 0, 0)
    print("Log!!! start time.", year, month, day, hour, minute, self.m_nOpenTime)
    -- 计算开服时所在周的周一零点时间戳
    local week = CCommonFunction.Sec2Week(self.m_nOpenTime)
    local year, month, day = CCommonFunction.Sec2Calendar(self.m_nOpenTime - (week-1) * 86400)
    self.m_nFirstMondayStartSec = CCommonFunction.Calendar2Sec(year, month, day, 0, 0, 0)
                
	-- 计算今天日历日
	self:CalCalendar();
	
	return true;
end

-- 计算今天日历日
function CGlobalInfoManager:CalCalendar()
	self.m_nYear, self.m_nMonth, self.m_nDay = CCommonFunction.Sec2Calendar(now(1));
	print("LOG!!! calendar.", self.m_nYear, self.m_nMonth, self.m_nDay);
end

-- 计算服务器数据存量
function CGlobalInfoManager:CalServerData()
end

function CGlobalInfoManager:OnDayRefresh()
	self:CalCalendar();
    self:CalServerData()
end
-- 是否是跨天开服
function CGlobalInfoManager:IsCrossDayOpen()
	return self.m_bCrossDay;
end

-- 获取上次关服时间
function CGlobalInfoManager:GetShuttime()
	return self.m_nShuttime;
end

function CGlobalInfoManager:GetFirstMondayStartSec()
	return self.m_nFirstMondayStartSec;
end

function CGlobalInfoManager:GetServerID()
	return self.m_nServerID;
end

function CGlobalInfoManager:GetOpenTime()
	return self.m_nOpenTime;
end

function CGlobalInfoManager:GetOpenTimeBeSet()
    return self.m_bOpenTimeBeSet
end

function CGlobalInfoManager:GetOpenDayTime()
    return self.m_nOpenDayTime
end

function CGlobalInfoManager:GetRefreshTime()
	return self.m_nRefreshTime;
end

function CGlobalInfoManager:GetRoleIndex()
	self.m_nRoleIndex = self.m_nRoleIndex + 1;
	self:SaveLater();
	return self.m_nRoleIndex;
end

function CGlobalInfoManager:GetMailNum()
	self.m_nMailNum = self.m_nMailNum + 1;
	self:SaveLater();
    return self.m_nMailNum;
end

function CGlobalInfoManager:GetMarryNum()
	self.m_nMarryNum = self.m_nMarryNum + 1;
	self:SaveLater();
	return self.m_nMarryNum;
end

function CGlobalInfoManager:GetMarryIndex()
	self.m_nMarryIndex = self.m_nMarryIndex + 1;
	self:SaveLater();
	return self.m_nMarryIndex;
end

function CGlobalInfoManager:GetFriendIndex()
	self.m_nFriendIndex = self.m_nFriendIndex + 1;
	self:SaveLater();
	return self.m_nFriendIndex;
end

function CGlobalInfoManager:GetGuildIndex()
	self.m_nGuildIndex = self.m_nGuildIndex + 1;
	self:SaveLater();
	return self.m_nGuildIndex;
end

function CGlobalInfoManager:GetChatWorldIndex()
	self.m_nChatWorldIndex = self.m_nChatWorldIndex + 1;
	self:SaveLater();
	return self.m_nChatWorldIndex;
end

function CGlobalInfoManager:GetBridgeHoleLevel()
	return self.m_nBridgeHoleLevel;
end

-- 获取现在是开服的第几天
function CGlobalInfoManager:GetOpenNowDayNum()
	local nTime = now(1)-self.m_nOpenDayTime
	local nDayNum = math.ceil(nTime/86400)
	return nDayNum;
end

-- 获取跨服排行版本号
function CGlobalInfoManager:GetRankVersion()
	return self.m_tRankVer;
end
local RankVerFields = {
	"rank1v1ver",
	"rank3v3ver",
}
-- 设置跨服排行版本（普通服用）
function CGlobalInfoManager:SetRankVersion(i_nType, i_nVersion)
    -- 写内存数据
    self.m_tRankVer[i_nType] = i_nVersion
    -- 写入数据库
    local oCmd = CDBCommand:CreateUpdateCmd("globalinfo");
	oCmd:SetFields(RankVerFields[i_nType], i_nVersion);
	oCmd:SetWheres("serverid", self.m_nServerID, "=");
	oCmd:Execute();
end
-- 增加跨服排行版本（跨服用）
function CGlobalInfoManager:IncRankVersion(i_nType)
	local nNewVer = self.m_tRankVer[i_nType] + 1;
	self.m_tRankVer[i_nType] = nNewVer;
    local oCmd = CDBCommand:CreateUpdateCmd("globalinfo");
	oCmd:SetFields(RankVerFields[i_nType], nNewVer);
	oCmd:SetWheres("serverid", self.m_nServerID, "=");
	oCmd:Execute();
	return nNewVer;
end

-- 获取服务器战斗唯一Id
function CGlobalInfoManager:GetServerBattleOnlyId()
	self.m_sIncBattleId = addInt(1, self.m_sIncBattleId);
	self:SaveLater();
	return self.m_sIncBattleId .. ServerInfo.serverid;
end

function CGlobalInfoManager:Save(i_bShut)
    local oCmd = CDBCommand:CreateUpdateCmd("globalinfo");
	
	oCmd:SetFields("marrynum", self.m_nMarryNum);
    oCmd:SetFields("mailnum", self.m_nMailNum);
    oCmd:SetFields("roleindex", self.m_nRoleIndex);
    oCmd:SetFields("guildindex", self.m_nGuildIndex);
	oCmd:SetFields("chatworldindex", self.m_nChatWorldIndex);
	oCmd:SetFields("incbattleid", self.m_sIncBattleId);

	if i_bShut then
		oCmd:SetFields("shuttime", now(1));
		if ServerInfo.isbridge then
			local CBridgeListener  = SingletonRequire("CBridgeListener");
			oCmd:SetFields("bridgeholelevel", CBridgeListener:GetMeanLevel());
		end
	end
	if not ServerInfo.isbridge then
		oCmd:SetFields("marryindex", self.m_nMarryIndex);
	    oCmd:SetFields("friendindex", self.m_nFriendIndex);
	end
	oCmd:SetWheres("serverid", self.m_nServerID, "=");
	oCmd:Execute();
end

function CGlobalInfoManager:UpdateRefreshTime(i_nTime)
	local oCmd = CDBCommand:CreateUpdateCmd("globalinfo");
	oCmd:SetFields("refreshtime", i_nTime);
	oCmd:SetWheres("serverid", self.m_nServerID, "=");
	oCmd:Execute();
	self.m_nRefreshTime = i_nTime;
end

function CGlobalInfoManager:Update(i_nDeltaTime)
	if not self.m_nDelay then return end;
	self.m_nDelay = self.m_nDelay - i_nDeltaTime;
	if self.m_nDelay > 0 then return end;
	self.m_nDelay = nil;
	self:Save();
end

function CGlobalInfoManager:Destruct()
	self:Save(true);
end

local g_nSavePeriod = 10000;
function CGlobalInfoManager:SaveLater()
	if not self.m_nDelay then
		self.m_nDelay = g_nSavePeriod;
	end
end

function CGlobalInfoManager:GetCalendar()
	return self.m_nYear, self.m_nMonth, self.m_nDay;
end

function CGlobalInfoManager:GetHefuTime()
	return self.m_nHefuTime or 0
end

function CGlobalInfoManager:GetHefuCishu()
    return self.m_nHefuCishu or 0
end

