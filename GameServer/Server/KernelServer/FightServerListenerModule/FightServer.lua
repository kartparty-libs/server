-- global enum
local CJSON = SingletonRequire("CJSON")
local KSPlayerStateEnum = RequireEnum("KSPlayerStateEnum")
-- global class
local CFightServerManager = SingletonRequire("CFightServerManager")
-- global function
local math_floor = math.floor
local math_random = math.random
local math_ceil = math.ceil
local table_insert = table.insert
local string_format = string.format
local string_gmatch = string.gmatch
local now = _commonservice.now
local ProtectedCall = ProtectedCall
local mSqrt = math.sqrt

local CFightServer = ClassRequire("CFightServer")
function CFightServer:_constructor(i_pSession, i_sIP, i_nIP, i_ServerId)
    self.m_pSession = i_pSession
    self.m_sIP = i_sIP
    self.m_sServerId = i_ServerId
    self.m_nIP = tostring(i_nIP)
    if i_pSession then
        self:SetState(KSPlayerStateEnum.eConnect)
    end
end

function CFightServer:SetState(i_nState)
    self.m_nState = i_nState
end
function CFightServer:GetState()
    return self.m_nState
end
function CFightServer:GetSession()
    return self.m_pSession
end

function CFightServer:GetServerID()
    return self.m_sServerId
end
function CFightServer:GetIp()
    return self.m_nIP
end

function CFightServer:CreatGameRoom(i_nRoomId,i_tRoleId)
    self:SendToFightServer("F_CreatGameRoom",i_nRoomId,i_tRoleId)
end

function CFightServer:DestroyGameRoom(i_nRoomId)
    self:SendToFightServer("F_DestroyGameRoom",i_nRoomId)
end

local malloc = _memoryservice.malloc
local free = _memoryservice.free
local fancy_encode = _codeservice.fancy_encode
local baseLen = 4096
local maxLen = 65535
local sendtosession = _netservice.sendtosession
function CFightServer:SendToFightServer(i_sMsg, ...)
    if self.m_pSession then
        local nBuffLen = baseLen
        while true do
            if nBuffLen > maxLen then
                print("ERROR!!! CFightServer:SendToFightServer > maxLen", nBuffLen, i_sMsg)
                break
            end
            local pData = malloc(nBuffLen)
            if pData then
                -- local params = CJSON.NetworkEncode(...)
                local nLen = fancy_encode(pData, nBuffLen, i_sMsg, ...)
                if nLen > 0 then
                    sendtosession(self.m_pSession, pData, nLen)
                    free(pData)
                    break
                else
                    print("WARNING!!! CFightServer:SendToFightServer", nBuffLen, i_sMsg)
                    nBuffLen = nBuffLen + baseLen
                    free(pData)
                end
            else
                print("ERROR!!! CFightServer:SendToFightServer malloc", nBuffLen, i_sMsg)
                break
            end
        end
    end
end

function CFightServer:OnDisconnect()
    self.m_pSession = nil
    local nState = self:GetState()
    if nState == KSPlayerStateEnum.eConnect  then
        CFightServerManager:DeleteFightServer(self)
    end
end




