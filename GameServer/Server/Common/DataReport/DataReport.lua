
local print		= print
local tostring  = tostring
local pairs = pairs
local now = _commonservice.now
local log360 = log360

local string_format	= string.format
local string_find   = string.find
local table_concat	= table.concat
local table_insert	= table.insert

local CURL  = SingletonRequire("CURL")
local serverid  = tostring(ServerInfo.serverid)

local Platform = ServerInfo.Platform or "youxi"
local deptid = ServerInfo.Deptid or 0
local CDataReport = SingletonRequire("CDataReport")

local youxi_log_str
if Platform == "youxi" then
    youxi_log_str = "gameinfo interface=%s&gname=jxbqp&gid=147&dept=263&%s"
elseif Platform == "wan" then
	youxi_log_str = "gameinfo interface=%s&gname=jxbqp&gid=147&dept=38&%s"
else
    youxi_log_str = "gameinfo interface=%s&gname=jxbqp&gid=147&dept=" .. deptid .. "&%s"
end
function CDataReport:DataReport(i_sInterface, i_tData, i_tPlayer)
	
end

-- 默认空方法 
function CDataReport:Reportchat(i_oPlayer, i_nType, i_sContent, i_oTarPlayer)
    
end
