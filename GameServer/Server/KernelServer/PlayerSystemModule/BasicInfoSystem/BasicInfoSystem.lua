------------------------------------------------------------------------------------------
-- 基本信息系统
------------------------------------------------------------------------------------------

local next = next
local StrToTable = StrToTable
local addInt = addInt
local subInt = subInt
local delog = delog
local now = _commonservice.now
local CBasicInfoSystem = ClassRequire("CBasicInfoSystem")
local __ConfigExtend = ConfigExtend
local CRankManager = SingletonRequire("CRankManager")
local CInviteManager = SingletonRequire("CInviteManager")

local BasicInfoEnum = {
    level = 1,
    exp = 2,
    viplv = 3,
    gold = 4,
    diamond = 5,
    energy = 6,
    head = 7,
    playercfgid = 8,
    carcfgid = 9,
    score = 10,

}
function CBasicInfoSystem:Create(bRefresh)
    local pPlayer = self:GetPlayer()
    -- 存盘脏位
    self.tSaveCaches = {}
    -- 基本信息
    self.tBasicInfo = {}
    self.tBasicInfo[BasicInfoEnum.level] = 1
    self.tBasicInfo[BasicInfoEnum.exp] = 0
    self.tBasicInfo[BasicInfoEnum.viplv] = 0
    self.tBasicInfo[BasicInfoEnum.gold] = 0
    self.tBasicInfo[BasicInfoEnum.diamond] = 0
    self.tBasicInfo[BasicInfoEnum.energy] = 0
    self.tBasicInfo[BasicInfoEnum.head] = 1
    self.tBasicInfo[BasicInfoEnum.playercfgid] = 1
    self.tBasicInfo[BasicInfoEnum.carcfgid] = 1
    self.tBasicInfo[BasicInfoEnum.score] = 0
    self.bUpdataFlag = false
    local tData = pPlayer:GetPlayerData("CBasicInfoSystem")
    if tData then
        if next(tData) then
            local pBasicInfo = {}
            for k, v in pairs(tData) do
                if BasicInfoEnum[k] then
                    pBasicInfo[BasicInfoEnum[k]] = v
                end
            end
            self.tBasicInfo = pBasicInfo
        end
    end
    if pPlayer:IsNew() then
        local nPledge = ConfigExtend.GetKartKeyCfg_Pledge(self:GetPlayer():GetKartKey())
        if nPledge > 0 then
            CRankManager:OnScoreChange(self:GetPlayer(), self:GetScoreAndPledge())
        end
    end
    if bRefresh then
        self:OnDayRefresh(bRefresh)
        return
    end
end

function CBasicInfoSystem:OnDayRefresh()
end

function CBasicInfoSystem:Update(i_nDeltaMsec)
end

-- 存盘
function CBasicInfoSystem:SaveData()
    if next(self.tSaveCaches) then
        local oPlayer = self:GetPlayer()
        local sRoleID = oPlayer:GetRoleID()
        local oUpdateCmd = oPlayer:CreateUpdateCmd("role_basicinfo")
        for k, v in pairs(self.tSaveCaches) do
            oUpdateCmd:SetFields(k, v)
        end
        oUpdateCmd:SetWheres("roleid", sRoleID, "=")
        oUpdateCmd:Execute()
        self.tSaveCaches = {}
    end
end

-- 基本信息同步
function CBasicInfoSystem:SyncClientData()
    local tInfo = {}
    for k,v in pairs(self.tBasicInfo) do
        tInfo[k] = v
    end
    local pPlayer = self:GetPlayer()
    if not pPlayer:IsR() then
        tInfo[BasicInfoEnum.score] = pPlayer:GetSystem("CTaskSystem"):GetTaskScore() + ConfigExtend.GetKartKeyCfg_Pledge(pPlayer:GetKartKey())
    end

    pPlayer:SendToClient("C_SyncBasicInfo", tInfo)
end

--------------------------------------------------------------------------------------------------------------------------------
-- 等级获取最大等级
function CBasicInfoSystem:GetMaxLevel()
    return __ConfigExtend.GetPlayerMaxLevel()
end

-- 等级获取
function CBasicInfoSystem:GetLevel()
    return self.tBasicInfo[BasicInfoEnum.level]
end

-- 等级设置
function CBasicInfoSystem:SetLevel(i_nLevel)
    local oPlayer = self:GetPlayer()
    self.tSaveCaches["level"] = i_nLevel
    self:ChangeLevelSyncClient()
end

-- 等级改变同步
function CBasicInfoSystem:ChangeLevelSyncClient()
    self:GetPlayer():SendToClient("C_ChangeLevel", self.tBasicInfo[BasicInfoEnum.level])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 经验获取
function CBasicInfoSystem:GetExp()
    return self.tBasicInfo[BasicInfoEnum.exp]
end

-- 经验设置
function CBasicInfoSystem:SetExp(i_nExp)
    self.tBasicInfo[BasicInfoEnum.exp] = i_nExp
    self.tSaveCaches["exp"] = i_nExp
    self:ChangeExpSyncClient()
end

-- 经验增加
function CBasicInfoSystem:AddExp(i_nExp)
    self:SetExp(i_nExp)
end

-- 经验改变同步
function CBasicInfoSystem:ChangeExpSyncClient()
    self:GetPlayer():SendToClient("C_ChangeExp", self.tBasicInfo[BasicInfoEnum.exp])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 会员等级获取
function CBasicInfoSystem:GetVipLv()
    return self.tBasicInfo[BasicInfoEnum.viplv]
end

-- 会员等级设置
function CBasicInfoSystem:SetVipLv(i_nVipLv)
    self.tBasicInfo[BasicInfoEnum.viplv] = i_nVipLv
    self.tSaveCaches["viplv"] = i_nVipLv
    self:ChangeVipLvSyncClient()
end

-- 会员等级改变同步
function CBasicInfoSystem:ChangeVipLvSyncClient()
    self:GetPlayer():SendToClient("C_ChangeVipLv", self.tBasicInfo[BasicInfoEnum.viplv])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 金币获取
function CBasicInfoSystem:GetGold()
    return self.tBasicInfo[BasicInfoEnum.gold]
end

-- 金币设置
function CBasicInfoSystem:SetGold(i_nGold)
    self.tBasicInfo[BasicInfoEnum.gold] = i_nGold
    self.tSaveCaches["gold"] = i_nGold
    self:ChangeGoldSyncClient()
end

-- 金币增加
function CBasicInfoSystem:AddGold(i_nGold)
    if i_nGold == nil then
        delog("======== Add gold is nil! ========")
        return
    end

    local nNewGold = i_nGold + self.tBasicInfo[BasicInfoEnum.gold]
    self:SetGold(nNewGold)
end

-- 金币消耗
function CBasicInfoSystem:CostGold(i_nGold)
    local nSubGold = self.tBasicInfo[BasicInfoEnum.gold] - i_nGold
    if nSubGold >= 0 then
        self:SetGold(nSubGold)
        return true
    end
    return false
end

-- 金币改变同步
function CBasicInfoSystem:ChangeGoldSyncClient()
    self:GetPlayer():SendToClient("C_ChangeGold", self.tBasicInfo[BasicInfoEnum.gold])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 钻石获取
function CBasicInfoSystem:GetDiamond()
    return self.tBasicInfo[BasicInfoEnum.diamond]
end

-- 钻石设置
function CBasicInfoSystem:SetDiamond(i_nDiamond)
    self.tBasicInfo[BasicInfoEnum.diamond] = i_nDiamond
    self.tSaveCaches["diamond"] = i_nDiamond
    self:ChangeDiamondSyncClient()
end

-- 钻石增加
function CBasicInfoSystem:AddDiamond(i_nDiamond)
    if i_nDiamond == nil then
        delog("======== Add diamond is nil! ========")
        return
    end

    local nNewDiamond = i_nDiamond + self.tBasicInfo[BasicInfoEnum.diamond]
    self:SetDiamond(nNewDiamond)
end

-- 钻石消耗
function CBasicInfoSystem:CostDiamond(i_nDiamond)
    local nSubDiamond = self.tBasicInfo[BasicInfoEnum.diamond] - i_nDiamond
    if nSubDiamond >= 0 then
        self:SetDiamond(nSubDiamond)
        return true
    end
    return false
end

-- 钻石改变同步
function CBasicInfoSystem:ChangeDiamondSyncClient()
    self:GetPlayer():SendToClient("C_ChangeDiamond", self.tBasicInfo[BasicInfoEnum.diamond])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 体力获取
function CBasicInfoSystem:GetEnergy()
    return self.tBasicInfo[BasicInfoEnum.energy]
end

-- 体力设置
function CBasicInfoSystem:SetEnergy(i_nEnergy)
    self.tBasicInfo[BasicInfoEnum.energy] = i_nEnergy
    self.tSaveCaches["energy"] = i_nEnergy
    self:ChangeEnergySyncClient()
end

-- 体力改变同步
function CBasicInfoSystem:ChangeEnergySyncClient()
    self:GetPlayer():SendToClient("C_ChangeEnergy", self.tBasicInfo[BasicInfoEnum.energy])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 头像获取
function CBasicInfoSystem:GetHead()
    return self.tBasicInfo[BasicInfoEnum.head]
end

-- 头像设置
function CBasicInfoSystem:SetHead(i_nHead)
    self.tBasicInfo[BasicInfoEnum.head] = i_nHead
    self.tSaveCaches["head"] = i_nHead
    self:ChangeHeadSyncClient()
end

-- 头像改变同步
function CBasicInfoSystem:ChangeHeadSyncClient()
    self:GetPlayer():SendToClient("C_ChangeHead", self.tBasicInfo[BasicInfoEnum.head])
    CRankManager:SetHeadChange(self:GetPlayer(), self.tBasicInfo[BasicInfoEnum.head])
    CInviteManager:SetHeadChange(self:GetPlayer())
end

--------------------------------------------------------------------------------------------------------------------------------
-- 玩家外显id获取
function CBasicInfoSystem:GetPlayerCfgId()
    return self.tBasicInfo[BasicInfoEnum.playercfgid]
end

-- 玩家外显id设置
function CBasicInfoSystem:SetPlayerCfgId(i_nPlayerCfgId)
    self.tBasicInfo[BasicInfoEnum.playercfgid] = i_nPlayerCfgId
    self.tSaveCaches["playercfgid"] = i_nPlayerCfgId
    self:ChangePlayerCfgIdSyncClient()
end

-- 玩家外显id改变同步
function CBasicInfoSystem:ChangePlayerCfgIdSyncClient()
    self:GetPlayer():SendToClient("C_ChangePlayerCfgId", self.tBasicInfo[BasicInfoEnum.playercfgid])
end

--------------------------------------------------------------------------------------------------------------------------------
-- 赛车id获取
function CBasicInfoSystem:GetCarCfgId()
    return self.tBasicInfo[BasicInfoEnum.carcfgid]
end

-- 赛车id设置
function CBasicInfoSystem:SetCarCfgId(i_nCarCfgId)
    self.tBasicInfo[BasicInfoEnum.carcfgid] = i_nCarCfgId
    self.tSaveCaches["carcfgid"] = i_nCarCfgId
    self:ChangeCarCfgIdSyncClient()
end

-- 赛车id改变同步
function CBasicInfoSystem:ChangeCarCfgIdSyncClient()
    self:GetPlayer():SendToClient("C_ChangeCarCfgId", self.tBasicInfo[BasicInfoEnum.carcfgid])
end

--------------------------------------------------------------------------------------------------------------------------------

-- 积分+质押分获取
function CBasicInfoSystem:GetScoreAndPledge()
    local nPledge = ConfigExtend.GetKartKeyCfg_Pledge(self:GetPlayer():GetKartKey())
    return self.tBasicInfo[BasicInfoEnum.score] + nPledge
end

-- 积分获取
function CBasicInfoSystem:GetScore()
    return self.tBasicInfo[BasicInfoEnum.score]
end

-- 积分设置
function CBasicInfoSystem:SetScore(i_nScore)
    self.tBasicInfo[BasicInfoEnum.score] = i_nScore
    self.tSaveCaches["score"] = i_nScore
    self:ChangeScoreSyncClient()
end

-- 积分增加
function CBasicInfoSystem:AddScore(i_nScore)
    if i_nScore == nil then
        delog("======== Add score is nil! ========")
        return
    end

    local nNewScore = i_nScore + self.tBasicInfo[BasicInfoEnum.score]
    self:SetScore(nNewScore)
end

-- 积分消耗
function CBasicInfoSystem:CostScore(i_nScore)
    local nSubScore = self.tBasicInfo[BasicInfoEnum.score] - i_nScore
    if nSubScore >= 0 then
        self:SetScore(nSubScore) 
        return true
    end
    return false
end

-- 积分改变同步
function CBasicInfoSystem:ChangeScoreSyncClient()
    self:GetPlayer():SendToClient("C_ChangeScore", self:GetScoreAndPledge())
    CRankManager:OnScoreChange(self:GetPlayer(), self:GetScoreAndPledge())
end

----------------------------------------------------------------
--客户端请求
----------------------------------------------------------------

defineC.K_ChangeHeadReq = function(i_oPlayer, i_nHead)
    i_oPlayer:GetSystem("CBasicInfoSystem"):SetHead(i_nHead)
end

defineC.K_ChangePlayerCfgIdReq = function(i_oPlayer, i_nPlayerCfgId)
    i_oPlayer:GetSystem("CBasicInfoSystem"):SetPlayerCfgId(i_nPlayerCfgId)
end

defineC.K_ChangeCarCfgIdReq = function(i_oPlayer, i_nCarCfgId)
    i_oPlayer:GetSystem("CBasicInfoSystem"):SetCarCfgId(i_nCarCfgId)
end