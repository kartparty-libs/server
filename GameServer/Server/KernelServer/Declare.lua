
-- singleton
SingletonRegist("CDBService")
SingletonRegist("CDBCommand")
SingletonRegist("CDBServerManager")
SingletonRegist("CGlobalInfoManager", true)
SingletonRegist("CCommercialService", true)
SingletonRegist("CGameServerManager");
SingletonRegist("CMapManager", true);

if ServerInfo.isbridge then -- 跨服
    SingletonRegist("CBridgeListener")
else -- 普通服
    SingletonRegist("CBridgeConnector", true)
end

SingletonRegist("CServiceConnector", true)

-------------------------------------------
SingletonRegist("CPlayerSystemList")
SingletonRegist("CPlayerManager", true)
SingletonRegist("CDataCenterManager",true)
SingletonRegist("CClientListener")
SingletonRegist("CFightServerManager")
SingletonRegist("CFightServerListener")
SingletonRegist("CCompeMateManager",true)
SingletonRegist("CChargeManager")
SingletonRegist("CRankManager",true)
SingletonRegist("CInviteManager")
SingletonRegist("CAccountRobotManager",true)

-- class
ClassDeclare("CFightServer")
ClassDeclare("CDBDeleteCmd")
ClassDeclare("CDBInsertCmd")
ClassDeclare("CDBSelectCmd")
ClassDeclare("CDBUpdateCmd")
ClassDeclare("CGameServer")
ClassDeclare("CMap");
ClassInherit("CCompetitionMap", "CMap")
ClassInherit("CDodgemsMap", "CMap")

ClassDeclare("CMapGroup");
ClassDeclare("CPlayer")
ClassInherit("CBasicInfoSystem", "CPlayerSystem")
ClassInherit("CTaskSystem", "CPlayerSystem")
ClassInherit("CLastSyncSystem", "CPlayerSystem")

if ServerInfo.isbridge then
    
else    
   
end
