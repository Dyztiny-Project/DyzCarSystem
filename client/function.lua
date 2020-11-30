function isVehicleClassHasBelt(class)
    if (not class) then return false end

    local hasBelt = Config.BeltClass[class];
    if (not hasBelt or hasBelt == nil) then return false end

    return hasBelt;
end 

function triggerNUI(eventName, payload)
    SendNUIMessage({
        event = eventName,
        payload = payload
    })
end