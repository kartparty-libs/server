

local CPlayerSystem = ClassRequire("CPlayerSystem");

function CPlayerSystem:_init(i_oPlayer, i_oManager, i_sName)
	self._sysdata = {
		m_oPlayer	= i_oPlayer;
		m_oManager	= i_oManager;
		m_sName		= i_sName;
	};
end;

------------------- all ------------------

function CPlayerSystem:GetPlayer()
	return self._sysdata.m_oPlayer;
end;

function CPlayerSystem:GetSystem(i_sName)
	return self._sysdata.m_oManager:GetSystem(i_sName);
end;

function CPlayerSystem:GetName()
	return self._sysdata.m_sName;
end;

function CPlayerSystem:Create(i_bDayRefresh) -- i_bDayRefresh only ks

end;

function CPlayerSystem:OnEnterMap(i_nMapCfgID)
end;

function CPlayerSystem:OnLevelUp(i_nLevel)

end;

function CPlayerSystem:OnDisconnect()

end;

function CPlayerSystem:OnDayRefresh()

end;

function CPlayerSystem:OnWeekRefresh()

end;

function CPlayerSystem:Update(i_nDeltaMsec)

end;

function CPlayerSystem:Destroy()

end;

function CPlayerSystem:OnDivorce()

end

------------------- ks ------------------

function CPlayerSystem:SendGSData()

end;

function CPlayerSystem:SyncClientData()

end;

function CPlayerSystem:SaveData() end

------------------- gs ------------------

function CPlayerSystem:OnDied(i_oKiller)

end;

function CPlayerSystem:OnRelive()

end;


