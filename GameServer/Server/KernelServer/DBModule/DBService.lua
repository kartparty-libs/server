
--global function
local print			= print;
local fConnect		= _dbservice.connect;
local fExecute		= _dbservice.execute;
local fDisconnect	= _dbservice.disconnect;
local Performance   = Performance

--local
local CDBService = SingletonRequire("CDBService");
function CDBService:Initialize()
	self.m_tID2DBInfo = {};		-- 数据库ID对应数据库配置信息
	self.m_tID2DBConn = {};		-- 数据库ID对应数据库连接
	return true;
end


function CDBService:Destruct()
	print("disconnect from db begin");
	for nID, pDBConn in pairs(self.m_tID2DBConn) do
        print("disconnect from db", nID, pDBConn)
		fDisconnect(pDBConn);
	end
	self.m_tID2DBConn = {};
    print("disconnect from db end");
end

function CDBService:CloseDBConn(i_nDBID)
    if self.m_tID2DBConn[i_nDBID] then
        fDisconnect(self.m_tID2DBConn[i_nDBID])
        self.m_tID2DBConn[i_nDBID] = nil
    end
end

function CDBService:SetID2Info(i_nDBID, i_sHost, i_nPort, i_sUser, i_sPwd, i_sName)
	self.m_tID2DBInfo[i_nDBID] = {
		m_sHost = i_sHost;
		m_nPort	= i_nPort;
		m_sUser = i_sUser;
		m_sPwd	= i_sPwd;
		m_sName	= i_sName;
	};
    -- 重新设置了要重连
    self:CloseDBConn(i_nDBID)
end

function CDBService:ConnectAndExecute(i_nDBID, i_sCmd)
	local tDBInfo = self.m_tID2DBInfo[i_nDBID];
    self:CloseDBConn(i_nDBID)
	local pDBConn = fConnect(tDBInfo.m_sHost, tDBInfo.m_sUser, tDBInfo.m_sPwd, tDBInfo.m_sName, tDBInfo.m_nPort);
	if pDBConn then
		self.m_tID2DBConn[i_nDBID] = pDBConn;
        local res1, res2 = fExecute(pDBConn, i_sCmd);
        if res1 then
            return res2;
        else
            print("ERROR!!! Sql:", i_sCmd);
        end
    else
        print("ERROR!!! mysql has gone away.", i_sCmd)
	end
end

function CDBService:RealExecute(i_sCmd, i_nDBID)
	if not i_nDBID then
		print("ERROR!!! i_nDBID nil", i_nDBID);
		return;
	end
	local tDBInfo = self.m_tID2DBInfo[i_nDBID];
	if not tDBInfo then
		print("ERROR!!! i_nDBID error", i_nDBID);
		return;
	end
	
	local pDBConn = self.m_tID2DBConn[i_nDBID];
	if pDBConn then
		local res1, res2 = fExecute(pDBConn, i_sCmd);
		if res1 then
			return res2;
		else
			if res2 == 2 then -- disconnect
				return self:ConnectAndExecute(i_nDBID, i_sCmd);
			else
				print("ERROR!!! Sql:", i_sCmd);
			end
		end
	else
		return self:ConnectAndExecute(i_nDBID, i_sCmd);
	end
end

function CDBService:Execute(i_sCmd, i_nDBID)
    -- local f = Performance(i_sCmd)
    local res = self:RealExecute(i_sCmd, i_nDBID)
    -- f()
    return res
end


