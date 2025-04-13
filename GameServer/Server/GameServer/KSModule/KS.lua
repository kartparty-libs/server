
local print         = print
local debug_traceback= debug.traceback


local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local fast_encode	= _codeservice.fast_encode;
local sendtomaster 	= _sendtomaster;

local CKS = SingletonRequire("CKS");

local nMaxLen		= 8192;
function CKS:SendToKS(i_sMsg, ...)
	local multiple = 1;
	local res = false;
	while true do
		local pData = malloc(nMaxLen * multiple);
		if pData then
			local nLen = fast_encode(pData, nMaxLen * multiple, i_sMsg, ...);
			if nLen > 0 then
				res = sendtomaster(pData, nLen);
				if not res then
					print("ERROR!!! CKS:Send sendtomaster failed.", i_sMsg)
					free(pData);
				end
				break;
			elseif nLen < 0 then
				print("ERROR!!! CKS:Send fast_encode failed.", i_sMsg, nLen);
				free(pData);
				break;
			else
				print("WARNING!!! CKS:Send fast_encode buffer small", i_sMsg, multiple)
				free(pData);
				multiple = multiple * 2;
			end
		else
			print("ERROR!!! CKS:Send malloc error.", i_sMsg)
			break;
		end
	end
	if not res then
        print(debug_traceback())
    end
end

local fancy_encode	= _codeservice.fancy_encode;
local nMaxMsgLen	= 4096;
function CKS:TransmitToClient(i_tRole, i_sMsg, ...)
    if #i_tRole == 0 then return end
	local pData = malloc(nMaxLen);
	local pAppend = malloc(nMaxMsgLen);
	local res = false;
	if pData and pAppend then
		local nLen = fast_encode(pData, nMaxLen, i_tRole);
		local nAppendLen = fancy_encode(pAppend, nMaxMsgLen, i_sMsg, ...);
		if nLen <= 0 or nAppendLen == 0 then
			print("ERROR!!! CKS:TransmitToClient encode error.", nLen, nAppendLen, i_sMsg);
			free(pData);
			free(pAppend);
		else
			-- print("---", pData, nLen, pAppend, nAppendLen)
			res = sendtomaster(pData, nLen, pAppend, nAppendLen);
			if not res then
				print("ERROR!!! CKS:TransmitToClient sendtomaster failed.", i_sMsg);
				free(pData);
				free(pAppend);
			end
		end
	else
		print("ERROR!!! CKS:Send malloc error.")
	end
	if not res then
        print(debug_traceback())
    end
end

function CKS:SendMsgToAllClient( i_Msg, ... )
	self:SendToKS("K_SendMsgToAllClient", i_Msg, ... )
end

-- 广播系统提示给所有玩家
function CKS:SendSystemTipsToAll(i_nMsgID, i_tParams)
	self:SendToKS("K_SystemTipsToAll", i_nMsgID, i_tParams);
end

