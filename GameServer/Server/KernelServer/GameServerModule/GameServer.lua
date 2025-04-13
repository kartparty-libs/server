
-- local
local CGameServer = ClassRequire("CGameServer");

function CGameServer:_constructor()
	local pGSPtr, nTreadID = _newslave("./Server/GameService.lua");
	self.m_pGSPtr	= pGSPtr;
	self.m_nPlayerNum = 0;
	self.m_nMapNum = 0;
end

function CGameServer:IsOK()
	return self.m_pGSPtr and true or false;
end


function CGameServer:GetPlayerNum()
	return self.m_nPlayerNum;
end

function CGameServer:OnPlayerEnter()
	self.m_nPlayerNum = self.m_nPlayerNum + 1;
end

function CGameServer:OnPlayerLeave()
	self.m_nPlayerNum = self.m_nPlayerNum - 1;
end

function CGameServer:GetMapNum()
	return self.m_nMapNum;
end

function CGameServer:OnMapCreate()
	self.m_nMapNum = self.m_nMapNum + 1;
end

function CGameServer:OnMapDestroy()
	self.m_nMapNum = self.m_nMapNum - 1;
end

function CGameServer:Shutdown()
	_shutdownslave(self.m_pGSPtr);
end

function CGameServer:IsShutted()
	if self.m_pGSPtr then
		return _isslaveshutted(self.m_pGSPtr);
	end
end

function CGameServer:Destruct()
	_deleteslave(self.m_pGSPtr);
	self.m_pGSPtr = nil;
end

local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local fast_encode	= _codeservice.fast_encode;
local sendtoslave	= _sendtoslave;
local nMaxLen		= 8192;
function CGameServer:Send(i_sMsg, ...)
	local multiple = 1;
	while true do
		local pData = malloc(nMaxLen * multiple);
		if pData then
			local nLen = fast_encode(pData, nMaxLen * multiple, i_sMsg, ...);
			if nLen > 0 then
				local res = sendtoslave(self.m_pGSPtr, pData, nLen);
				if not res then
					print("ERROR!!! CGameServer:Send sendtoslave failed.");
					free(pData);
				end
				break;
			elseif nLen < 0 then
				print("ERROR!!! CGameServer:Send fast_encode failed.", i_sMsg, nLen);
				free(pData);
				break;
			else
				print("WARNING!!! CGameServer:Send fast_encode buffer small.", i_sMsg, multiple);
				free(pData);
				multiple = multiple * 2;
			end
		else
			print("ERROR!!! CGameServer:Send malloc error.")
			break;
		end
	end
end


