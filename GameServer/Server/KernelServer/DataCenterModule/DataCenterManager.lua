
-- global function
local assert        = assert
local ipairs        = ipairs;
local table_insert  = table.insert;
local ProtectedCall = ProtectedCall;
local ClassNew      = ClassNew;
local Performance   = Performance
local now = _commonservice.now
--local
local CPlayerManager	= SingletonRequire("CPlayerManager")
local CDataCenterManager = SingletonRequire("CDataCenterManager")
local DataEnum={
    player = 1,
    createtime = 2
}
local nClearinterval = 60*30 --离线玩家清理时间间隔
function CDataCenterManager:Initialize()
    self.m_nCallBackID = 1
	self.m_tCallBack = {}
    self.m_tOffLinePlayer = {}
    return true
end

function CDataCenterManager:GetPlayerByRoleID(i_sRoleId,i_fCallBack)
    local pPlayer = CPlayerManager:GetPlayerByRoleID(i_sRoleId)
    if pPlayer then
        i_fCallBack(pPlayer)
        return
    end
    if self.m_tOffLinePlayer[i_sRoleId] then
        self.m_tOffLinePlayer[i_sRoleId][DataEnum.createtime] = now(1)
        i_fCallBack(self.m_tOffLinePlayer[i_sRoleId][DataEnum.player])
        return
    end 
    self.m_tCallBack[self.m_nCallBackID] = i_fCallBack
    local nCallBackID = self.m_nCallBackID
    self.m_nCallBackID = self.m_nCallBackID + 1
    CPlayerManager:PlayerOffLineLogin(i_sRoleId,nCallBackID)  
end

function CDataCenterManager:OffLinePlayerCreate(i_nCallBackID,i_oPlayer)
    if i_oPlayer then
        self.m_tOffLinePlayer[i_oPlayer:GetRoleID()] = {}
        self.m_tOffLinePlayer[i_oPlayer:GetRoleID()][DataEnum.player] = i_oPlayer
        self.m_tOffLinePlayer[i_oPlayer:GetRoleID()][DataEnum.createtime] = now(1)
		self.m_tCallBack[i_nCallBackID](i_oPlayer)
    end
    self.m_tCallBack[i_nCallBackID] = nil
end

function CDataCenterManager:OffLinePlayerCreateError(i_nCallBackID)
	self.m_tCallBack[i_nCallBackID]("PlayerCreateError")
    self.m_tCallBack[i_nCallBackID] = nil
end


function CDataCenterManager:DeletePlayer(i_sRoleID)
    if self.m_tOffLinePlayer[i_sRoleID] then
        self.m_tOffLinePlayer[i_sRoleID][DataEnum.player]:OffLineDestroy()
	    self.m_tOffLinePlayer[i_sRoleID] = nil
    end
end

local interval	= 1000*3600
local update	= interval
function CDataCenterManager:Update( i_nDeltaTime)
	update = update - i_nDeltaTime
	if update > 0 then return end
    for roleid,value in pairs(self.m_tOffLinePlayer) do
        local ncreatetime = value[DataEnum.createtime]
        local nTime = now(1) - ncreatetime
        if nTime >= nClearinterval then
            self:DeletePlayer(roleid)
        end
    end
	update = interval
end


