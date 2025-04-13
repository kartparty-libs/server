-- global function
local type = type
local pairs = pairs
local ipairs = ipairs
local print = print
local string_format = string.format
local ProtectedCall = ProtectedCall

--local
local tConfigS = {}

local function fDofileConfig(i_sModuleName, i_sFileName)
    local res1, res2 =
        ProtectedCall(
        function()
            return dofile(i_sFileName)
        end
    )
    if res1 then
        if type(res2) == "table" then
            tConfigS[i_sModuleName] = {
                m_sFileName = i_sFileName,
                m_tConfig = res2
            }
        else
            print("ERROR!!! config not a table!!!")
        end
    end
end

RequireConfig = function(i_sModuleName, i_bIgnoreError)
    local t = tConfigS[i_sModuleName]
    if t then
        return t.m_tConfig
    elseif (not i_bIgnoreError) then
        print("ERROR!!! config not exist!!!", i_sModuleName)
    end
end

HotUpdateConfig = function(i_sModuleName)
    local t = tConfigS[i_sModuleName]
    if t then
        fDofileConfig(i_sModuleName, t.m_sFileName)
        dofile("./Server/ConfigS/ConfigExtend.lua")
    end
end

-------------------------------------------------------------

local tDofileTable = {
    "MapCfg_S",
    "RoleCfg_S",
    "CarCfg_S",
    "HeadCfg_S",
    "NicknameCfg_S",
    "TaskCfg_S",
    "KartKeyCfg_S",
    "RobotTypeCfg_S",
}

-------------------------------------------------------------

local sPath = "./Server/ConfigS/%s.lua"
for _, sModuleName in ipairs(tDofileTable) do
    local sFileName = string_format(sPath, sModuleName)
    fDofileConfig(sModuleName, sFileName)
end

dofile("./Server/ConfigS/ConfigExtend.lua")
