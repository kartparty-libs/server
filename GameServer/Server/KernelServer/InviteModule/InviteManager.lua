------------------------------------------------------------------------------------------
-- 邀请管理器
------------------------------------------------------------------------------------------
-- global enum
local TaskEventEnum = RequireEnum("TaskEventEnum")

-- global function
local next = next
local now = _commonservice.now
local table_insert = table.insert

-- global singleton
local CPlayerManager = SingletonRequire("CPlayerManager")
local CDBCommand = SingletonRequire("CDBCommand")

-- local
local InviteCodeMaxCount = 5

local InviteCodeData_Owner = 1 -- 邀请码绑定的role
local InviteCodeData_LoginNum = 2 -- 邀请码玩家的累计登入次数
local InviteCodeData_Head = 3 -- 头像

local CInviteManager = SingletonRequire("CInviteManager")
function CInviteManager:Initialize()
    -- 改服玩家绑定邀请码
    self.m_tAllPlayerInviteCodes = {}
    -- 已绑定邀请码的累计登录记录
    self.m_tInviteCodeData = {}

    local oCmd = CDBCommand:CreateSelectCmd("invite")
    oCmd:SetFields("roleid")
    oCmd:SetFields("invitecodes")
    local tRes = oCmd:Execute()
    if tRes and #tRes > 0 then
        for i, res in ipairs(tRes) do
            self.m_tAllPlayerInviteCodes[res.roleid] = StrToTable(res.invitecodes)
        end
    end

    if next(self.m_tAllPlayerInviteCodes) then
        for k, v in pairs(self.m_tAllPlayerInviteCodes) do
            for _, code in pairs(v) do
                self.m_tInviteCodeData[code] = {k, 0, 0}
                local tInviteCodeData = self.m_tInviteCodeData[code]
                self:SelectInviteCodeData(code, tInviteCodeData)
            end
        end
    end
    return true
end

function CInviteManager:Destruct()
end

function CInviteManager:SaveData(i_oPlayer)
    local sRoleID = i_oPlayer:GetRoleID()
    local tPlayerInviteCode = self.m_tAllPlayerInviteCodes[sRoleID]
    if tPlayerInviteCode == nil then
        return
    end

    local oCmd = CDBCommand:CreateSelectCmd("invite")
    oCmd:SetWheres("roleid", sRoleID, "=")
    oCmd:SetLimit(1)
    local res = oCmd:Execute()
    if res and next(res) then
        oCmd = CDBCommand:CreateUpdateCmd("invite")
        oCmd:SetFields("invitecodes", TableToStr(tPlayerInviteCode))
        oCmd:SetWheres("roleid", sRoleID, "=")
        oCmd:Execute()
    else
        local oCmd = CDBCommand:CreateInsertCmd("invite")
        oCmd:SetFields("roleid", sRoleID)
        oCmd:SetFields("invitecodes", TableToStr(tPlayerInviteCode))
        oCmd:Execute()
    end
end

function CInviteManager:OnTriggerTask(i_oPlayer)
    local sRoleID = i_oPlayer:GetRoleID()
    local tPlayerInviteCode = self.m_tAllPlayerInviteCodes[sRoleID]
    if tPlayerInviteCode == nil then
        return
    end

    for k, v in pairs(tPlayerInviteCode) do
        local tInviteCodeData = self.m_tInviteCodeData[v]
        if tInviteCodeData then
            i_oPlayer:GetSystem("CTaskSystem"):TriggerTaskEventSetValue(TaskEventEnum.eInvite, tInviteCodeData[InviteCodeData_LoginNum], {k})
        end
    end
end

-- 玩家累计登录通知
function CInviteManager:OnCumulativeLogin(i_oPlayer, i_nLoginNum)
    if i_nLoginNum == nil or type(i_nLoginNum) ~= "number" then
        return
    end

    local sInviteCodes = i_oPlayer:GetKartKey()
    local tInviteCodeData = self.m_tInviteCodeData[sInviteCodes]
    if tInviteCodeData == nil then
        return
    end
    tInviteCodeData[InviteCodeData_LoginNum] = i_nLoginNum

    local oOwnerPlayer = CPlayerManager:GetPlayerByRoleID(tInviteCodeData[InviteCodeData_Owner])
    if oOwnerPlayer then
        self:OnTriggerTask(oOwnerPlayer)
    end
end

-- 改变头像通知
function CInviteManager:SetHeadChange(i_oPlayer)
    local sInviteCodes = i_oPlayer:GetKartKey()
    local tInviteCodeData = self.m_tInviteCodeData[sInviteCodes]
    if tInviteCodeData == nil then
        return
    end
    self.m_tInviteCodeData[sInviteCodes][InviteCodeData_Head] = i_oPlayer:GetSystem("CBasicInfoSystem"):GetHead()
end

-- 获取玩家已绑定邀请码
function CInviteManager:GetBoundInviteCode(i_oPlayer)
    local sRoleID = i_oPlayer:GetRoleID()
    local tPlayerInviteCodes = self.m_tAllPlayerInviteCodes[sRoleID]
    if not tPlayerInviteCodes then
        return
    end

    local tBuffer = {}
    for i = 1, InviteCodeMaxCount do
        local sInviteCodes = tPlayerInviteCodes[i]
        local nLoginNum = 0
        local nHead = 0
        if sInviteCodes == nil then
            sInviteCodes = ""
        else
            local tInviteCodeData = self.m_tInviteCodeData[sInviteCodes]
            if tInviteCodeData ~= nil then
                nLoginNum = tInviteCodeData[InviteCodeData_LoginNum]
                nHead = tInviteCodeData[InviteCodeData_Head]
            end
        end

        table_insert(tBuffer, {sInviteCodes, nLoginNum, nHead})
    end
    i_oPlayer:SendToClient("C_GetBoundInviteCode", tBuffer)
end

-- 绑定邀请码
function CInviteManager:BindInviteCode(i_oPlayer, i_nIndex, i_sInviteCode)
    if i_nIndex > InviteCodeMaxCount then
        return
    end

    if ConfigExtend.GetKartKeyCfg()[i_sInviteCode] == nil then
        i_oPlayer:SendSystemTips(18, {})
        return
    end

    if i_sInviteCode == i_oPlayer:GetKartKey() then
        i_oPlayer:SendSystemTips(20, {})
        return
    end

    if self.m_tInviteCodeData[i_sInviteCode] then
        i_oPlayer:SendSystemTips(17, {})
        return
    end

    local sRoleID = i_oPlayer:GetRoleID()
    local tPlayerInviteCodes = self.m_tAllPlayerInviteCodes[sRoleID]

    if tPlayerInviteCodes == nil then
        self.m_tAllPlayerInviteCodes[sRoleID] = {}
        tPlayerInviteCodes = self.m_tAllPlayerInviteCodes[sRoleID]
    end

    if tPlayerInviteCodes[i_nIndex] == nil or tPlayerInviteCodes[i_nIndex] == 0 then
        tPlayerInviteCodes[i_nIndex] = i_sInviteCode
        self.m_tInviteCodeData[i_sInviteCode] = {sRoleID, 0, 0}
        local tInviteCodeData = self.m_tInviteCodeData[i_sInviteCode]

        local oInvitePlayer = CPlayerManager:GetPlayerByOpenID(i_sInviteCode)
        if oInvitePlayer then
            tInviteCodeData[InviteCodeData_LoginNum] = oInvitePlayer:GetLoginNum()
        else
            self:SelectInviteCodeData(i_sInviteCode, tInviteCodeData)
        end
        i_oPlayer:SendToClient("C_BindInviteCode", i_nIndex, {i_sInviteCode, tInviteCodeData[InviteCodeData_LoginNum], tInviteCodeData[InviteCodeData_Head]})

        self:SaveData(i_oPlayer)
        self:OnTriggerTask(i_oPlayer)
    end
end

-- 查找设置邀请码的信息
function CInviteManager:SelectInviteCodeData(i_sInviteCode, i_tInviteCodeData)
    local oSelectCmd = CDBCommand:CreateSelectCmd("role")
    oSelectCmd:SetWheres("kartkey", i_sInviteCode, "=")
    oSelectCmd:SetLimit(1)
    local res = oSelectCmd:Execute()
    if res and next(res) then
        res = res[1]
        i_tInviteCodeData[InviteCodeData_LoginNum] = res.loginnum
        oSelectCmd = CDBCommand:CreateSelectCmd("role_basicinfo")
        oSelectCmd:SetWheres("roleid", res.roleid, "=")
        oSelectCmd:SetLimit(1)
        local res = oSelectCmd:Execute()
        if res and next(res) then
            res = res[1]
            i_tInviteCodeData[InviteCodeData_Head] = res.head
        end
    end
end

----------------------------------------------------------------
-- 客户端请求
----------------------------------------------------------------

-- 获取玩家已绑定邀请码请求
defineC.K_GetBoundInviteCodeReq = function(i_oPlayer)
    CInviteManager:GetBoundInviteCode(i_oPlayer)
end

-- 绑定邀请码请求
defineC.K_BindInviteCodeReq = function(i_oPlayer, i_nIndex, i_sInviteCode)
    CInviteManager:BindInviteCode(i_oPlayer, i_nIndex, i_sInviteCode)
end
