
local delog		= delog
local type		= type
local pairs		= pairs
local ipairs	= ipairs
local tostring  = tostring
local string_format = string.format

local logdb     = logdb
local now       = _commonservice.now

local IsNotDataLog = ServerInfo.IsNotDataLog

local dist_id = ServerInfo.serverdistid or 0

local CDataLog = SingletonRequire("CDataLog")

function CDataLog:SetDistrictLogDBIndex(i_sDistrictLogDBIndex)
    self.m_sDistrictLogDBIndex = i_sDistrictLogDBIndex
    delog("district_logindex", self.m_sDistrictLogDBIndex)
end

function CDataLog:SetPublicLogDBIndex(i_sPublicLogDBIndex)
    self.m_sPublicLogDBIndex = i_sPublicLogDBIndex
    delog("Publiclogdbindex", self.m_sPublicLogDBIndex)
end

function CDataLog:GetDistrictLogDBIndex( )
    return self.m_sDistrictLogDBIndex
end

function CDataLog:GetPublicLogDBIndex( )
    return self.m_sPublicLogDBIndex
end

function CDataLog:LogDistrictDB(i_sSql)
    if self.m_sDistrictLogDBIndex then
        logdb(self.m_sDistrictLogDBIndex, i_sSql)
    else
        delog("WARNING!!! districlogdbindex is nil.")
    end
end

function CDataLog:LogPublicDB(i_sSql)
    -- if IsNotDataLog then return end
    if self.m_sPublicLogDBIndex then
        logdb(self.m_sPublicLogDBIndex, i_sSql)
    else
        delog("WARNING!!! publiclogdbindex is nil.")
    end
end

-- 添加账号表
-- event_type 1：登录，0：登出
local str_account_log = "insert account_login( account_id, role_id, event_type, update_time ) values('%s', '%s', '%d', NOW())"
function CDataLog:LogDistAccount_log( account_id, role_id, event_type )
    self:LogDistrictDB(string_format( str_account_log, account_id, role_id, event_type) )
end
local str_task_log = "insert task_log( account_id, role_id, task_id, update_time ) values('%s', '%s', '%d', NOW())"
function CDataLog:LogDistTask_log( account_id, role_id, task_id )
    self:LogDistrictDB(string_format( str_task_log, account_id, role_id, task_id))
end
-- rank_num  0:开始比赛 1：结束比赛
local str_map_log = "insert map_log( account_id, role_id, map_id, rank_num, finish_time, update_time ) values('%s', '%s', '%d', '%d', '%d', NOW())"
function CDataLog:LogDistMap_log( account_id, role_id, map_id, rank_num, finish_time)
    self:LogDistrictDB(string_format( str_map_log, account_id, role_id, map_id,rank_num, finish_time) )
end
-------- 以下废弃 仅供参考------------------------
local str_log_mail = "call log_mail('%s', '%d', '%d', '%d', '%s')"
function CDataLog:GameLogGotMail(i_sRoleID, i_sMailID, i_nState, i_nTs, i_sItem)
    -- self:LogGameDB(string_format(str_log_mail, i_sRoleID, i_sMailID, i_nState, i_nTs, i_sItem))
end


