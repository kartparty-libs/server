
-- global function
local assert        = assert
local ipairs        = ipairs;
local table_insert  = table.insert;
local ProtectedCall = ProtectedCall;
local ClassNew      = ClassNew;
local Performance   = Performance

--local
local CPlayerSystemManager = ClassRequire("CPlayerSystemManager");
function CPlayerSystemManager:_constructor(i_oPlayer, i_tSystemClasses)
	self.m_oPlayer		= i_oPlayer;
	self.m_tName2System = {};
	self.m_tSystemSet	= {};
	for _, v in ipairs(i_tSystemClasses) do
		local oSystem = ClassNew(v);
		oSystem:_init(i_oPlayer, self, v);
		table_insert(self.m_tSystemSet, oSystem);
		self.m_tName2System[v] = oSystem;
	end
end

------------------- all ------------------
function CPlayerSystemManager:GetSystem(i_sName)
	return self.m_tName2System[i_sName];
end

function CPlayerSystemManager:Create(i_bDayRefresh, i_bWeekRefresh)
    local nErrorIndex = nil
	for k, v in ipairs(self.m_tSystemSet) do
		if not ProtectedCall(function() v:Create(i_bDayRefresh, i_bWeekRefresh) end) then
            print("ERROR!!! player system create.", v:GetName())
            nErrorIndex = k
            break
        end
	end
    if nErrorIndex then
        for k, v in ipairs(self.m_tSystemSet) do
            if k > nErrorIndex then
                break
            end
            ProtectedCall(function() self.m_tSystemSet[k]:Destroy() end)
        end
        assert(false, "ERROR!!! PlayerSystem Create Error.")
    end
end

function CPlayerSystemManager:Update(i_nDeltaMsec)
	for _, v in ipairs(self.m_tSystemSet) do
        v:Update(i_nDeltaMsec);
	end
end

function CPlayerSystemManager:Destroy()
	for _, v in ipairs(self.m_tSystemSet) do
        ProtectedCall(function() v:Destroy() end);
	end
end

function CPlayerSystemManager:OnDisconnect()
	for _, v in ipairs(self.m_tSystemSet) do
        v:OnDisconnect();
	end
end


function CPlayerSystemManager:OnEnterMap(i_nMapCfgID)
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnEnterMap(i_nMapCfgID) end) then
            res = false;
        end
	end
    return res;
end

function CPlayerSystemManager:OnLevelUp(i_nLevel)
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnLevelUp(i_nLevel) end) then
            res = false;
        end
	end
    return res;
end

function CPlayerSystemManager:OnDayRefresh()
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnDayRefresh() end) then
            res = false;
        end
	end
    return res;
end

function CPlayerSystemManager:OnDivorce()
    local res = true;
    for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnDivorce() end) then
            res = false;
        end 
	end
    return res;
end

------------------- ks ------------------

function CPlayerSystemManager:SendGSData()
	for _, v in ipairs(self.m_tSystemSet) do
        v:SendGSData();
	end
end

function CPlayerSystemManager:SyncClientData()
	for _, v in ipairs(self.m_tSystemSet) do
        v:SyncClientData();
	end
end

-- �����ϵͳ����
function CPlayerSystemManager:SaveData(i_bLogOut)
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        local f = Performance(v:GetName())
        if not ProtectedCall(function() v:SaveData(i_bLogOut) end) then
            res = false;
        end
        f()
	end
    return res;
end

------------------- gs ------------------

function CPlayerSystemManager:OnDied(i_oKiller)
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnDied(i_oKiller) end) then
            res = false;
        end
	end
    return res;
end

function CPlayerSystemManager:OnRelive()
    local res = true;
	for _, v in ipairs(self.m_tSystemSet) do
        if not ProtectedCall(function() v:OnRelive() end) then
            res = false;
        end
	end
    return res;
end


