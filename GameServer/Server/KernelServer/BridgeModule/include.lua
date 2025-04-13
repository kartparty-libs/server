
if ServerInfo.isbridge then
	dofile("./Server/KernelServer/BridgeModule/BridgeListener.lua");
else
	dofile("./Server/KernelServer/BridgeModule/BridgeConnector.lua");
end


