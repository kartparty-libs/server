local math_random = math.random;
local pairs = pairs;

local CWeightMethod = ClassRequire("CWeightMethod");
function CWeightMethod:_constructor()
	self.m_tWeightRecord = {};
	self.m_nTotalWeight = 0;
end

function CWeightMethod:SetWeightInfo(i_nWeightId, i_nWeightValue)
	if self.m_tWeightRecord[i_nWeightId] then
		print("ERROR!!! Input i_nWeightId repeat!", i_nWeightId, debug.traceback());
		return;
	end
	self.m_tWeightRecord[i_nWeightId] = i_nWeightValue;
	self.m_nTotalWeight = self.m_nTotalWeight + i_nWeightValue;
end

function CWeightMethod:ExecuteWeight()
	if self.m_nTotalWeight <= 0 then
		return nil;
	end
	local nRandom = math_random(1, self.m_nTotalWeight);
	local nWeight = nRandom;
	for nId, nWeightValue in pairs(self.m_tWeightRecord) do
		nWeight = nWeight - nWeightValue;
		if nWeight <= 0 then	
			self.m_nTotalWeight = self.m_nTotalWeight - nWeightValue;
			self.m_tWeightRecord[nId] = nil;
			return nId;
		end
	end
end