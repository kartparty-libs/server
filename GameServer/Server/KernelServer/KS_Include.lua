
--enum
dofile("./Server/EnumS/include.lua")

--common
dofile("./Server/Common/include.lua")

--config
dofile("./Server/ConfigS/include.lua")

--class declare
dofile("./Server/KernelServer/Declare.lua")

--module
dofile("./Server/KernelServer/DBModule/include.lua")
dofile("./Server/KernelServer/DBServerModule/include.lua")
dofile("./Server/KernelServer/GlobalInfoModule/include.lua")
dofile("./Server/KernelServer/CommercialModule/include.lua")
dofile("./Server/KernelServer/BridgeModule/include.lua")
dofile("./Server/KernelServer/ClientListenerModule/include.lua")
dofile("./Server/KernelServer/FightServerListenerModule/include.lua")
dofile("./Server/KernelServer/CompeMateModule/include.lua")
dofile("./Server/KernelServer/MapModule/include.lua");

dofile("./Server/KernelServer/PlayerSystemModule/include.lua")
dofile("./Server/KernelServer/PlayerModule/include.lua")
dofile("./Server/KernelServer/ServiceModule/include.lua")
dofile("./Server/KernelServer/GameServerModule/include.lua")
dofile("./Server/KernelServer/DataCenterModule/include.lua")
dofile("./Server/KernelServer/RankModule/include.lua")
dofile("./Server/KernelServer/InviteModule/include.lua");
dofile("./Server/KernelServer/AccountRobotModule/include.lua");


if ServerInfo.isbridge then -- 跨服系统
	
else -- 普通服系
    
end 