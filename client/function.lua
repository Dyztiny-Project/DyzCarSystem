function isVehicleClassHasBelt(class)
    if not class then return false end

    for i = 1, #Configs.vehicleClassHasSeatBelt do 
        local curClassMap = Configs.vehicleClassHasSeatBelt[i]
        if class >= curClassMap[0] and curClassMap <= curClassMap[1] then
            return true
        end
    end
    
    return false
end

function triggerNUI(eventName, payload) {
    SendNUIMessage({
        event = eventName,
        payload = payload
    })
}