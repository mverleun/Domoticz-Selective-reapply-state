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

--
--
time = os.date("*t")
weekday = os.date("%A")
minutes = time.min + time.hour * 60



local function reApplyState()
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
        if (v['HardwareName'] == "RF Link" or v['HardwareName'] == "RFXtrx") 
            and (v['HardwareDisabled'] == false) -- Skip if a device is disabled
            and (v['Type'] == "Light/Switch")
            and (v['SwitchType'] == 'On/Off')
            and (v['Protected'] == 'false' )
        then
          -- print("Reappling state " .. v['Status'] .. " to " .. v['Name'])
          -- Add command to commandArray
          commandArray[v['Name']] = v['Status']
        end
    end 
end

-- Start with an empty array of commands
commandArray = {}

-- Run every 5 minutes
if (time.min % 5) == 0 then
    reApplyState()
end

return commandArray
