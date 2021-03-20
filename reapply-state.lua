--
-- Reapply State for unreliable devices
--
-- Many devices on the 433.9 Mhz frequency are not reliable. A command is sent to a device and the assumption is that it is executed.
-- If not, there is a mismatch between the desired state and the actual state.
-- 
-- A closed loop would be nice, but since these devices do not provide status information the next best thing is to reapply the desired state periodically.
-- How often this is done depends on the number of devices and the 'failure' rate.
--
-- Heavily inspired by: https://www.domoticz.com/forum/viewtopic.php?p=115795#p115795

-- The state will only be reapplied if the last change was more than 1 minute ago to prevent raceconditions with timer operated switches.
--
--


--- Function to log messages
--- This allows to turn these messages on and off in a central location
--- Input: message to display
function logMessage(message)
    print(message)
end
---
--- Function to return how long a device is in a state
--- Input: DeviceName
--- Returns: Number of seconds that device is in its current state
function timeInState(device)
    local t1=os.time()
    local s = otherdevices_lastupdate[device]
    
    local year = string.sub(s, 1, 4)
    local month = string.sub(s, 6, 7)
    local day = string.sub(s, 9, 10)
    local hour = string.sub(s, 12, 13)
    local minutes = string.sub(s, 15, 16)
    local seconds = string.sub(s, 18, 19)
    local t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
    local difference = (os.difftime (t1, t2))
    return difference
end    
    
    
--- Function to reapply the state of a device again, it does not change the state.
--- The state is only reapplied if a device is in a state for a certain amount of time.
--- Input: minimum number of seconds a device has to be in a state.
--- Returns: None, it modifies the global variable commandArray
function reApplyState(minTimeInState)
    logMessage("Inside reApplyState")
    
    local sUrl = 'localhost' -- IP address of Domoticz
    local sPort = '8080'     -- port number of Domoticz
    
    -- The API returns JSON formatted data, load file to interpret it
    -- The location of the file can be different, on a Raspberry PI it often is:
    -- /home/pi/domoticz/scripts/lua/JSON.lua
    local json = (loadfile "/src/domoticz/scripts/lua/JSON.lua")()  -- For Linux
    
    -- get all the device info needed from API, since it is not available in lua
    local config=assert(io.popen('curl http://'..sUrl..':'..sPort..'/json.htm?type=devices'))
    local jsonDevice = config:read('*all')
    config:close()
    local deviceList = json:decode(jsonDevice)

    -- The result contain many interesting fields such as:
    -- "HardwareDisabled" : false
    -- "HardwareName" : "RF Link"
    -- "Name" : "Light-1"
    -- "Type" : "Light/Switch"
    -- "SubType" : "Unitec"
    -- "SwitchType" : "On/Off"
    -- "Status" : "On"

    -- Loop over results 
    for k,v in pairs(deviceList['result']) do
        -- Only reapply for certain devices:
        if v['HardwareName'] == "RF Link"
            and (v['HardwareDisabled'] == false) -- Skip if a device is disabled
            and (v['Type'] == "Light/Switch")
            and (v['SwitchType'] == 'On/Off')
            and (
                (v['Name'] == 'E....n')
            or  (v['Name'] == 'S....r')
            or  (v['Name'] == 'Lamp K....')
            or  (v['Name'] == 'Lamp B....')
            )
        --    and (v['Protected'] == 'false' )
        then
            if timeInState(v['Name']) >= minTimeInState 
            then 
                logMessage(v['Name'] .. " " .. timeInState(v['Name']))
                logMessage("Reappling state " .. v['Status'] .. " to " .. v['Name'])
                commandArray[v['Name']] = v['Status']
            end
        end
    end 
end

-- Start with an empty array of commands
commandArray = {}

-- Do not use low values when calling reApplyState. This script is timer based and runs once a minute.
-- A low value might cause race conditions again if there is a delay handling timers.
reApplyState(60)

return commandArray
