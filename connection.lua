--CODE BY JEAN VICTOR M SANTOS
--TO DOWNLOAD IT ACCESS VICTROBRAIN.COM
--CHECK IF IS THE FIRST RUN AND SET WIFI PARAMS
MODE_RECOVERY = false;
if(read_setting("TYPE_SERVER") == nil) then
    save_setting("TYPE_SERVER", "AP");
end
if(read_setting("WIFI_SSID") == nil) then
    save_setting("WIFI_SSID", "VICTRO_ADDON");
end
if(read_setting("WIFI_PASS") == nil) then
    save_setting("WIFI_PASS", "VICTRO842876");
end
if(read_setting("HOST") == nil) then
    save_setting("HOST", "victroaddon");
end
if(read_setting("IP_SERVER") == nil) then
    save_setting("IP_SERVER", "192.168.1.1");
end

--INIT CONNECTION
VICTRO_wifi = {} --PRIVATE
VICTRO_wifi.ssid = read_setting("WIFI_SSID") --PRIVATE
VICTRO_wifi.pwd = read_setting("WIFI_PASS") --PRIVATE

if(read_setting("TYPE_SERVER") == nil or read_setting("TYPE_SERVER") == "AP") then
    wifi.setmode(wifi.SOFTAP)
    wifi.ap.config(VICTRO_wifi)
    wifi.ap.setip({ip=read_setting("IP_SERVER"),netmask="255.255.255.0",gateway=read_setting("IP_SERVER")})
    tmr.alarm(0, 1000, 1, function()
       if wifi.ap.getip() == nil then
          print("Connecting...\n")
       else
          print("Connected via Access Point")
          mdns.register(read_setting("HOST"), { description="Victro Addon", service="http", port=80 })
          tmr.stop(0)
       end
    end)
elseif(read_setting("TYPE_SERVER") == "ST") then
    wifi.setmode(wifi.STATION)
    wifi.sta.config(VICTRO_wifi)
    local times_wifi = 0;
    tmr.alarm(0, 1000, 1, function()
       if wifi.sta.getip() == nil then
          times_wifi = times_wifi + 1;
          print("Connecting...\n")
          if(times_wifi > 30)then
            print("Recovery...\n")
            MODE_RECOVERY = true;
            VICTRO_wifi2 = {} --PRIVATE
            VICTRO_wifi2.ssid = "VICTRO_RECOVERY_"..node.chipid() --PRIVATE
            VICTRO_wifi2.pwd = "VICTRO"..node.chipid() --PRIVATE
            wifi.setmode(wifi.SOFTAP)
            wifi.ap.config(VICTRO_wifi2)
            wifi.ap.setip({ip=read_setting("IP_SERVER"),netmask="255.255.255.0",gateway=read_setting("IP_SERVER")})
            mdns.register(read_setting("HOST"), { description="Victro Addon", service="http", port=80 })
            tmr.stop(0)
          end
       else
          print("Connected via Station")
          mdns.register(read_setting("HOST"), { description="Victro Addon", service="http", port=80 })
          tmr.stop(0)
       end
    end)
end
