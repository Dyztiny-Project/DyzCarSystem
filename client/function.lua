function isVehicleClassHasBelt(class)
    if not class then return false end
    class = tonumber(class)
    for i = 1, #Configs.vehicleClassHasSeatBelt do 
        local curClassMap = Configs.vehicleClassHasSeatBelt[i]
        if class >= curClassMap[1] and class <= curClassMap[2] then
            return true
        end
    end
    
    return false
end

function triggerNUI(eventName, payload)
    SendNUIMessage({
        event = eventName,
        payload = payload
    })
end