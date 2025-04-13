-------------------------------------------------------------------------------------------
-- 类支持 使Lua支持类的方式
-------------------------------------------------------------------------------------------

-- 全局加速
local type = type
local setmetatable = setmetatable
local debug_traceback = debug.traceback
local print = print

-- 类容器
local __tName2Class = {}

-- 类声明
local __ClassDeclare = function(i_sClassName)
    if type(i_sClassName) ~= "string" then
        print("err!!! regist class name type err!!!", i_sClassName)
        print(debug_traceback())
        return
    end

    if __tName2Class[i_sClassName] ~= nil then
        print("err!!! class already exist!!!", i_sClassName)
        print(debug_traceback())
        return
    end

    local pClass = {}
    pClass._className = i_sClassName
    pClass.__index = pClass
    __tName2Class[i_sClassName] = pClass
    _G[i_sClassName] = pClass
    return pClass
end

-- 类获取
local __ClassRequire = function(i_sClassName)
    local pClass = __tName2Class[i_sClassName]
    if not pClass then
        print("err!!! require class not exist!!!", i_sClassName)
        print(debug_traceback())
    end
    return pClass
end

-- 类继承
local __ClassInherit = function(i_sChildClassName, i_sParentClassName)
    local pChildClass = __ClassDeclare(i_sChildClassName)
    if pChildClass then
        local pParentClass = __ClassRequire(i_sParentClassName)
        if pParentClass then
            pChildClass._super = pParentClass
            pChildClass._className = i_sChildClassName
            setmetatable(pChildClass, pParentClass)
        end
        return pChildClass
    end
end

-- 类实例化
local __ClassNew = function(i_sClassName, ...)
    local pClass = __ClassRequire(i_sClassName)
    if pClass then
        local pInstance = {}
        setmetatable(pInstance, pClass)
        if pInstance._constructor then
            pInstance:_constructor(...)
        end
        return pInstance
    end
end

-- 定义类支持全局方法
ClassDeclare = __ClassDeclare
ClassInherit = __ClassInherit
ClassRequire = __ClassRequire
ClassNew = __ClassNew
