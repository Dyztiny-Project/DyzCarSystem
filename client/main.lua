-- Variable Declaration
local cruiseIsOn = false
local seatbeltIsOn = false
local engineOn = false

Citizen.CreateThread(function()
    local currSpeed = 0.0
    local cruiseSpeed = 1000.0
    local prevVelocity = {x = 0.0, y = 0.0, z = 0.0}
    local lastToggleState = {
        0, -- 1 = UI
        0, -- 2 = Seatbelt
        0, -- 3 = Cruise
        0, -- 4 = Engine
    }
    local lastClassDetail = {
        class = 0,
        hasBelt = true
    }
    
    while true do
        (function()
            local player = GetPlayerPed(-1)
            -- Check if player isn't in any vehicle then send nui message and skip other operation.
            local isShow = IsPedInAnyVehicle(player, false)
            if lastToggleState[1] ~= isShow then
                lastToggleState[1] = isShow
                triggerNUI("toggleUI", isShow) -- Update toggleUI state
            end
            if not isShow then
                cruiseIsOn = false
                seatbeltIsOn = false

                -- Make a delay to reduce the functionality of the resource.
                Citizen.Wait(500)
                return false
            end

            local vehicle = GetVehiclePedIsIn(player, false)

			local prevSpeed = currSpeed
            currSpeed = GetEntitySpeed(vehicle)
            local position = GetEntityCoords(player)

            -- Check vehicle class if has belt or not
            local vehicleClass = GetVehicleClass(vehicle)
            if lastClassDetail.class ~= vehicleClass then
                lastClassDetail.class = vehicleClass
                lastClassDetail.hasBelt = isVehicleClassHasBelt(vehicleClass)
            end

            local hasBelt = lastClassDetail.hasBelt

            if IsControlJustReleased(0, Configs.seatbeltInput) and hasBelt then 
                seatbeltIsOn = not seatbeltIsOn
            end

            if not hasBelt or not seatbeltIsOn then
                seatbeltIsOn = false
                -- Eject PED when moving forward, vehicle was going over 45 MPH and acceleration over 100 G's
                local vehIsMovingFwd = GetEntitySpeedVector(vehicle, true).y > 1.0
                local vehAcc = (prevSpeed - currSpeed) / GetFrameTime()
                if (vehIsMovingFwd and (prevSpeed > (Configs.seatbeltEjectSpeed/2.237)) and (vehAcc > (Configs.seatbeltEjectAccel*9.81))) then
                    SetEntityCoords(player, position.x, position.y, position.z - 0.47, true, true, true)
                    SetEntityVelocity(player, prevVelocity.x, prevVelocity.y, prevVelocity.z)
                    Citizen.Wait(1)
                    SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
                else
                    -- Update previous velocity for ejecting player
                    prevVelocity = GetEntityVelocity(vehicle)
                end
            else
                DisableControlAction(0, 75)
            end

            -- Update seatbelt state
            if lastToggleState[2] ~= seatbeltIsOn then
                lastToggleState[2] = seatbeltIsOn
                triggerNUI("toggleBelt", {
                    hasBelt = hasBelt,
                    beltOn = seatbeltIsOn
                })
            end

            local isDriver = (GetPedInVehicleSeat(vehicle, -1) == player)
            if isDriver then
                -- Check if cruise control button pressed, toggle state and set maximum speed appropriately
                if IsControlJustReleased(0, Configs.cruiseInput) then
                    cruiseIsOn = not cruiseIsOn
                    cruiseSpeed = currSpeed
                end

                local maxSpeed = cruiseIsOn and cruiseSpeed or GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel")
                SetEntityMaxSpeed(vehicle, maxSpeed)
            else
                -- Reset cruise control
                cruiseIsOn = false
            end

            -- Update cruise state
            if lastToggleState[3] ~= cruiseIsOn then
                lastToggleState[3] = cruiseIsOn
                triggerNUI("toggleCruise", {
                    hasCruise = isDriver,
                    cruiseStatus = cruiseIsOn
                })
            end

            engineOn = GetIsVehicleEngineRunning(vehicle)
            -- Update engine state
            if lastToggleState[4] ~= engineOn then
                lastToggleState[4] = engineOn
                triggerNUI("toggleEngine", engineOn)
            end

            local EntityHealth = GetEntityHealth(vehicle)
            local maxEntityHealth = GetEntityMaxHealth(vehicle)
            local vehicleHealth = (EntityHealth / maxEntityHealth) * 100
            --print(vehicleHealth)
            SetPlayerVehicleDamageModifier(PlayerId(), 100)
            SetVehicleEngineHealth(vehicle, (EntityHealth + 0.00) * 1.5)

            local maxSpeed = 100 - ((100 - ((GetVehicleEngineHealth(vehicle) / maxEntityHealth) * 100)) / 1.5)
            if vehicleHealth <= 30 then 
                SetVehicleMaxSpeed(vehicle, maxSpeed) 
            else 
                SetVehicleMaxSpeed(vehicle, 200.0) 
            end
            if vehicleHealth == 0 then
                SetVehicleEngineOn(vehicle, false, false)
            end
            
            local heading = Configs.Directions[math.floor((GetEntityHeading(player) + 45.0) / 90.0)]
            local zoneNameFull = Configs.Zones[GetNameOfZone(position.x, position.y, position.z)]
            local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(position.x, position.y, position.z))
			local locationText = heading
			locationText = (streetName == "" or streetName == nil) and (locationText) or (locationText .. " | " .. streetName)
            locationText = (zoneNameFull == "" or zoneNameFull == nil) and (locationText) or (locationText .. " | " .. zoneNameFull)

            triggerNUI("updateInfo", {
                -- Vehicle Status
                carHealth = vehicleHealth,
                carFuel = math.floor(((GetVehicleFuelLevel(vehicle) / 100) * 100)),

                -- Speed
                speed = Configs.isUseKM and math.floor(currSpeed * 3.6) or math.floor(currSpeed * 2.236936),

                -- Gear
                gear = GetVehicleCurrentGear(vehicle),

                -- Streat name
                streetName = locationText,

                -- Unit
                speedUnit = Configs.isUseKM and 'KM' or 'M'
            })

        end)()
        Citizen.Wait(5)
    end
end)