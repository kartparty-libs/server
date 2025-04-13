defineS.K_PlayerDestroyMsg = function(i_oPlayer)
    local res = ProtectedCall(function() i_oPlayer:LeaveGSComplete() end)
    if not res then
        -- i_oPlayer:Destroy()
    end
end