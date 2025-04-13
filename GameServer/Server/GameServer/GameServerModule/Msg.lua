--global
local CGameServer	= SingletonRequire("CGameServer");
local CDataLog = SingletonRequire("CDataLog")

defineS.G_RedoFile = function(i_sFileName)
	CGameServer:RedoFile(i_sFileName);
end





