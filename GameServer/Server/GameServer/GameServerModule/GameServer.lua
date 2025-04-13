
-- local
local ProtectedCall = ProtectedCall;
-- global function
local CKS 			= SingletonRequire("CKS");
local CCommonFunction = SingletonRequire("CCommonFunction");
-- global class
local selfid		= _selfid;

--local
local CGameServer = SingletonRequire("CGameServer");
function CGameServer:Initialize()
	return true;
end

function CGameServer:GetThreadID()
	return selfid;
end

-- 重新加载文件
local function fDofile(i_sFileName)
	dofile(i_sFileName);
end
function CGameServer:RedoFile(i_sFileName)
	print("LOG!!! redofile : ", i_sFileName);
    ProtectedCall(function() dofile(i_sFileName) end);
end



