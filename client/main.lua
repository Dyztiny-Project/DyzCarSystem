-- Variable
local currVeh = 0; 
local cruiseEnabled, seatbeltEnabled = false, false;
local vehData = {
    hasBelt = false,
    engineRunning = false,
    hasCruise = false,

    currSpd = 0.0,
    cruiseSpd = 0.0,
    prevVelocity = {x = 0.0, y = 0.0, z = 0.0}, 
};

local inair = 0
local cruiseSpeeding = 0

local playerPed = nil;
-- Thread
Citizen.CreateThread(function()
    while true do
        if (currVeh ~= 0) then
            local position = GetEntityCoords(playerPed);

            -- //NOTE: Copy from original (DyzCarSystem)
            local EntityHealth = GetEntityHealth(currVeh);
            local maxEntityHealth = GetEntityMaxHealth(currVeh);
            local vehicleHealth = (EntityHealth / maxEntityHealth) * 100;

            SetPlayerVehicleDamageModifier(PlayerId(), 100);
            -- SetVehicleEngineHealth(currVeh, (EntityHealth + 0.00) * 1.5); -- //Note: Comment as suggested by #issuecomment-797556881

            local maxSpeed = 100 - ((100 - ((GetVehicleEngineHealth(currVeh) / maxEntityHealth) * 100)) / 1.5);
            if (vehicleHealth <= 30) then 
                SetVehicleMaxSpeed(currVeh, maxSpeed);
            else 
                SetVehicleMaxSpeed(currVeh, 200.0);
            end

            if (vehicleHealth == 0) then
                SetVehicleEngineOn(currVeh, false, false)
            end

            local heading = Config['Directions'][math.floor((GetEntityHeading(playerPed) + 45.0) / 90.0)];
            local zoneNameFull = Config['Zones'][GetNameOfZone(position.x, position.y, position.z)];
            local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(position.x, position.y, position.z));
            local locationText = heading;
            locationText = (streetName == "" or streetName == nil) and (locationText) or (locationText .. " | " .. streetName);
            locationText = (zoneNameFull == "" or zoneNameFull == nil) and (locationText) or (locationText .. " | " .. zoneNameFull);

            triggerNUI("updateInfo", {
                -- Vehicle Status
                carHealth = vehicleHealth,
                carFuel = math.floor(GetVehicleFuelLevel(currVeh)),

                -- Speed
                speed = Config['useKM'] and math.floor(vehData['currSpd'] * 3.6) or math.floor(vehData['currSpd'] * 2.236936),

                -- Gear
                gear = GetVehicleCurrentGear(currVeh),

                -- Streat name
                streetName = locationText,

                -- Unit
                speedUnit = Config['useKM'] and 'KM' or 'M'
            })
        end

        Citizen.Wait(currVeh == 0 and 500 or 100);
    end
end)

Citizen.CreateThread(function()
    while true do
        if (currVeh ~= 0) then
            local position = GetEntityCoords(playerPed);

            -- Seat Belt
            if (IsControlJustReleased(0, Config['seatbeltInput']) and vehData['hasBelt']) then 
                seatbeltEnabled = not seatbeltEnabled;
                triggerNUI("toggleBelt", { hasBelt = vehData['hasBelt'], beltOn = seatbeltEnabled });
            end
            
            local prevSpeed = vehData['currSpd'];
            vehData['currSpd'] = GetEntitySpeed(currVeh);

            if (not vehData['hasBelt'] or not seatbeltEnabled) then
                seatbeltEnabled = false;

                local vehIsMovingFwd = GetEntitySpeedVector(currVeh, true).y > 1.0;
                local vehAcc = (prevSpeed - vehData['currSpd']) / GetFrameTime();
                if (vehIsMovingFwd and (prevSpeed > (Config['seatbeltEjectSpeed']/2.237)) and (vehAcc > (Config['seatbeltEjectAccel']*9.81))) then
                    SetEntityCoords(playerPed, position.x, position.y, position.z - 0.47, true, true, true);
                    SetEntityVelocity(playerPed, vehData['prevVelocity'].x, vehData['prevVelocity'].y, vehData['prevVelocity'].z);
                    Citizen.Wait(1);
                    SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0);
                else
                    vehData['prevVelocity'] = GetEntityVelocity(currVeh);
                end
            elseif (seatbeltEnabled) then
                DisableControlAction(0, 75);
            end

            local isDriver = (GetPedInVehicleSeat(currVeh, -1) == playerPed);
            if (isDriver) then
                if (isDriver ~= vehData['hasCruise']) then
                    vehData['hasCruise']  = isDriver;
                    triggerNUI("toggleCruise", { hasCruise =  vehData['hasCruise'], cruiseStatus = cruiseEnabled });
                end
                if (IsControlJustReleased(0, Config['cruiseInput'])) then
                    cruiseEnabled = not cruiseEnabled;
                    triggerNUI("toggleCruise", { hasCruise = isDriver, cruiseStatus = cruiseEnabled });
                    vehData['cruiseSpd'] = vehData['currSpd'];
                    cruiseSpeeding = vehData['cruiseSpd'];
                end

                local maxSpeed = cruiseEnabled and vehData['cruiseSpd'] or GetVehicleHandlingFloat(currVeh,"CHandlingData","fInitialDriveMaxFlatVel");
                SetEntityMaxSpeed(currVeh, maxSpeed);

                local roll = GetEntityRoll(currVeh)


                if cruiseEnabled and not IsEntityInAir(currVeh) and inair >= 100 and not (roll > 75.0 or roll < -75.0) then
                    if cruiseSpeeding < maxSpeed then
                        cruiseSpeeding = cruiseSpeeding + 0.15
                    end


                    SetVehicleForwardSpeed(currVeh, cruiseSpeeding)
                
                elseif cruiseEnabled and not IsEntityInAir(currVeh) then
                    inair = inair + 1
                    cruiseSpeeding = vehData['currSpd'];
                elseif cruiseEnabled then
                    inair = 0
                end
            else
                cruiseEnabled = false;
            end

            local engineRunning = GetIsVehicleEngineRunning(currVeh);
            if (engineRunning ~= vehData['engineRunning']) then
                vehData['engineRunning'] = engineRunning;
                triggerNUI("toggleEngine", vehData['engineRunning']);
            end
        end

        Citizen.Wait(currVeh == 0 and 500 or 5);
    end
end)

Citizen.CreateThread(function()
    while true do
        playerPed = PlayerPedId();
        local veh = GetVehiclePedIsIn(playerPed, false);
        local placeNameEnabled = Config['placeNameEnabled'];
        triggerNUI("placeNameEnabled", { isEnabled = placeNameEnabled});

        if (veh ~= currVeh) then
            currVeh = veh;
            triggerNUI("toggleUI", veh ~= 0);

            if (veh == 0) then
                cruiseEnabled, seatbeltEnabled = false, false;
                vehData['hasCruise'] = false;
                vehData['currSpd'] = 0.0;
                triggerNUI("toggleCruise", { hasCruise =  vehData['hasCruise'], cruiseStatus = cruiseEnabled });
                triggerNUI("toggleBelt", { hasBelt = vehData['hasBelt'], beltOn = seatbeltEnabled });
            else
                local vehicleClass = GetVehicleClass(veh);
                vehData['hasBelt'] = isVehicleClassHasBelt(vehicleClass);
            end
        end

        Citizen.Wait(500);
    end
end)
