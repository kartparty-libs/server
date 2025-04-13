
local print         = print
local debug_traceback= debug.traceback


local malloc		= _memoryservice.malloc;
local free			= _memoryservice.free;
local fast_encode	= _codeservice.fast_encode;
local sendtomaster 	= _sendtomaster;

local CKS = SingletonRequire("CKS");

function CKS:Initialize()
	self.m_tRoleIDToMultiple = {}
	return true;
end

local nMaxLen		= 4096;
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

function CKS:AddRole(i_sRoleID)
	self.m_tRoleIDToMultiple[i_sRoleID] = self.m_tRoleIDToMultiple[i_sRoleID] or {}
end

function CKS:SendToKSByAutoMalloc(i_sMsg, i_sSystem, i_sRoleID, ...)
	local multiple = self.m_tRoleIDToMultiple[i_sRoleID][i_sSystem] or 1;
	local res = false;
	while true do
		local pData = malloc(nMaxLen * multiple);
		if pData then
			local nLen = fast_encode(pData, nMaxLen * multiple, i_sMsg, i_sRoleID, ...);
			if nLen > 0 then
				res = sendtomaster(pData, nLen);
				if not res then
					print("ERROR!!! CKS:SendToKSByAutoMalloc sendtomaster failed.", i_sMsg)
					free(pData);
				end
				break;
			elseif nLen < 0 then
				print("WARNING!!! CKS:SendToKSByAutoMalloc fast_encode failed.", i_sMsg, i_sSystem, nLen);
				free(pData);
				break;
			else
				print("WARNING!!! CKS:SendToKSByAutoMalloc fast_encode buffer small", i_sMsg, i_sSystem, multiple)
				free(pData);
				multiple = multiple * 2;
				self.m_tRoleIDToMultiple[i_sRoleID][i_sSystem] = multiple;
			end
		else
			print("ERROR!!! CKS:SendToKSByAutoMalloc malloc error.", i_sMsg)
			break;
		end
	end
	if not res then
        print(debug_traceback())
    end
end
