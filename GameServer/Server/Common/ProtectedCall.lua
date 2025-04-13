local print = print;
local xpcall= xpcall;
local debug_traceback = debug.traceback;
local DebugTool_bp2 = DebugTool.bp2;
local xpcall_err = function(err)
    print("ERROR!!!", err);
	DebugTool_bp2();
    print(debug_traceback());
end

ProtectedCall = function(f)
    return xpcall(f, xpcall_err);
end


