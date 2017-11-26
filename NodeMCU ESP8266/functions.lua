VICTRO_VARS = nil
function explode(div,str) -- credit: http://richard.warburton.it
    if (div=='') then return false end
    local pos,arr = 0,{}
    -- for each divider found
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
return arr
end
function save_setting(name, value)
    file.open(name..".vic", 'w') -- you don't need to do file.remove if you use the 'w' method of writing
    file.writeline(value)
    file.close()
end
function remove_setting(name)
    file.remove(name..".vic") -- you don't need to do file.remove if you use the 'w' method of writing
end
function read_setting(name)
    if (file.open(name..".vic")~=nil) then
        result = string.sub(file.readline(), 1, -2) -- to remove newline character
        file.close()
        return result
    else
        return nil
    end
end
function do_get(data1, token)
    if(read_setting("SCRIPT_SERVER") == nil) then
        save_setting("SCRIPT_SERVER", "sys/addon");
    end
    local linkpost = read_setting("URL_SERVER")..read_setting("SCRIPT_SERVER")
    print(linkpost)
    http.post(linkpost,
      'Content-Type: application/x-www-form-urlencoded\r\n',
      'JSON_VAR={"ID":"'..node.chipid()..'", "TOKEN":"'..token..'", "DATA":"'..data1..'", "CHIP":"NODEMCU ESP8266"}',
      function(code, data)
        if (code < 0) then
          print("HTTP request failed")
        else
          local c = data;
          m= string.sub(c,string.find(c,"(VICTRO_ADDON)")+13,string.find(c,"(END_VICTRO_ADDON)")-1)
            if (m ~= nil)then
                VICTRO_VARS = {}
                for k, v in string.gmatch(m, "(%w+)=(%w+)&*") do
                    VICTRO_VARS[k] = v
                end
            end
        end
    end)
end
function pins(t)
    local reqs = "";
    if(t.H == "G" or t.H == "GPIO") then
        reqs = '"HARDWARE":"GPIO"';
        reqs = reqs..',"PIN":"'..t.P..'"';
        if(t.T == "O" or t.T == "OUTPUT" or t.T == "OUT") then
            gpio.mode(t.P, gpio.OUTPUT);
            reqs = reqs..',"TYPE":"OUTPUT"';
        else
            gpio.mode(t.P, gpio.INPUT);
            reqs = reqs..',"TYPE":"INPUT"';
        end
        if(t.V == "H" or t.V == "HIGH") then
            gpio.write(t.P, gpio.HIGH);
            reqs = reqs..',"VOLT":"HIGH"';
        else
            gpio.write(t.P, gpio.LOW);
            reqs = reqs..',"VOLT":"LOW"';
        end
    elseif(t.H == "D11" or t.H == "DHT11") then
        reqs = '"HARDWARE":"DHT11"';
        reqs = reqs..',"PIN":"'..t.P..'"';
        status,temp,humi,temp_decimal,humi_decimal = dht.read11(t.P)
        reqs = reqs..',"STATUS":"'..status..'"';
        reqs = reqs..',"HUMIDITY":"'..humi..'"';
        reqs = reqs..',"TEMPERATURE":"'..temp..'"';
        reqs = reqs..',"TEMPERATURA_D":"'..temp_decimal..'"';
        reqs = reqs..',"HUMIDITY_D":"'..humi_decimal..'"';
    elseif(t.H == "A" or t.H == "ADC") then
        local moist_value = adc.read(0)
        reqs = '"HARDWARE":"ACD"';
        reqs = reqs..',"VALUE":"'..moist_value..'"';
    elseif(t.H == "TR") then
        print("AQ")
        save_setting("TIMER", t.TMR);
        save_setting("REQUESTS", t.REQ);
    end
    return reqs;
end
function pinsTime(t)
    local interval = tonumber(t.TM) * 1000;
    local sw, count = true, 0
    local reqs = pins(t);
    reqs = reqs..',"TIMER": "'..t.TM..' sec", "TO": "'..t.TMV..'"';
    tmr.create():alarm(interval, tmr.ALARM_SINGLE, function()
        t.V = t.TMV;
        reqs = reqs..pins(t)
    end)
    return reqs;
end
