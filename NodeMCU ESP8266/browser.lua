if srv~=nil then
    srv:close()
end
VICTRO_REQUESTS = 0;
verify_loop = false
remove_setting("TIMER");
remove_setting("REQUESTS")
srv=net.createServer(net.TCP, 1);
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = "<html><center><h1>What are you doing here? I need a brain to come alive!</h1><BR><h2>Go to victrobrain.com to download it</h2></center></html>";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end
        if(MODE_RECOVERY == true) then
            buf = "<h1>VictroAddon cannot connect to SSID given, recovery mode is on</h1>";
            if(path == "/recovery.vic") then
                buf = '{"SSID":"'..read_setting("WIFI_SSID")..'"}';
                if(_GET.TYPE ~= nil and _GET.SSID ~= nil and _GET.PASS ~= nil and _GET.PASSOLD == read_setting("WIFI_PASS")) then
                    save_setting("TYPE_SERVER", _GET.TYPE);
                    save_setting("WIFI_SSID", _GET.SSID);
                    save_setting("WIFI_PASS", _GET.PASS);
                    buf = '{"CHIP":"NODEMCU ESP8266", "ID": "'..node.chipid()..'", "SSID": "'.._GET.SSID..'", "MODEL": "'.._read_setting("MODEL")..'", "HOST": "'.._read_setting("HOST")..'.local", "VERSION":"'..VICTRO_ADDON_VERSION..'"}'; 
                end
            end
            client:send(buf);
            client:close();
            collectgarbage();
        elseif(path == "/config.vic") then
            if((read_setting("TYPE_SERVER") == "AP" and read_setting("WIFI_SSID") == "VICTRO_ADDON" and read_setting("WIFI_PASS") == "VICTRO842876"))then
                buf = "<h1>Waiting for wifi configuration via VictroBrain</h1>";
                if(_GET.TYPE ~= nil and _GET.SSID ~= nil and _GET.PASS ~= nil) then
                    save_setting("TYPE_SERVER", _GET.TYPE);
                    save_setting("WIFI_SSID", _GET.SSID);
                    save_setting("WIFI_PASS", _GET.PASS);
                    save_setting("MODEL", _GET.MODEL);
                    save_setting("URL_SERVER", encoder.fromBase64(encoder.fromHex(_GET.URL)));
                    save_setting("HOST", _GET.HOST);
                    buf = '{"CHIP":"NODEMCU ESP8266", "ID": "'..node.chipid()..'", "SSID": "'.._GET.SSID..'", "MODEL": "'.._GET.MODEL..'", "HOST": "'.._GET.HOST..'.local", "VERSION":"'..VICTRO_ADDON_VERSION..'"}'; 
                end
                client:send(buf);
                client:close();
                collectgarbage();
            end
        elseif(path == "/commands.vic") then
            if(_GET.TOKEN ~= nil)then
                local array_token = encoder.fromBase64(encoder.fromHex(_GET.TOKEN));
                local count = 1;
                for i in string.gmatch(array_token, "%S+") do
                    if(count == 1) then
                        VICTRO_TOKEN_ADDON = i;
                    elseif(count == 2) then
                        VICTRO_URL_SERVER = i;
                        save_setting("URL_SERVER", i);
                    elseif(count == 3) then
                        save_setting("PORT_SERVER", i);
                    end
                    count = count + 1;
                end

                if(VICTRO_TOKEN_ADDON == nil) then
                    buf = "Token not found";
                    client:send(buf);
                    client:close();
                    collectgarbage();
                else
                    VICTRO_VARS = nil
                    do_get("TOKEN", VICTRO_TOKEN_ADDON);
                    timeout = 0;
                    tmr.alarm(1, 1000, 1, function()
                        if VICTRO_VARS == nil and verify_loop == false then
                            print("Loading vars... " .. timeout)
                            timeout = timeout + 1
                            if timeout == 5 then
                                print("TIMEOUT")
                                tmr.stop(1)
                                buf = "Is VictroBrain alive? Token does not reply!";
                                client:send(buf);
                                client:close();
                                collectgarbage();
                                tmr.stop(1)
                                conn:close();
                            end
                        elseif(verify_loop == false) then
                            verify_loop = true;
                            tmr.stop(1)
                            if(VICTRO_VARS.TOKEN == "OK" and VICTRO_VARS.VERSION == VICTRO_ADDON_VERSION and VICTRO_VARS.ID == "v"..VICTRO_ADDON_ID and VICTRO_VARS.MODEL == VICTRO_ADDON_MODEL) then
                                if(_GET.PIN ~= nil) then
                                    VICTRO_REQUESTS = VICTRO_REQUESTS + 1;
                                    local array_pin = encoder.fromBase64(encoder.fromHex(_GET.PIN));
                                    buf = '{"ERROR":false,';
                                    local countReq = 1;
                                    local reqs = "";
                                    for i in string.gmatch(array_pin, "%S+") do
                                        reqs = "";
                                         t = {}
                                         for x, v in string.gmatch(i, "(%w+):(%w+)&*") do
                                           t[x] = v
                                         end
                                        if(t.TM ~= nil) then
                                            reqs = pinsTime(t);
                                        else 
                                            reqs = pins(t);
                                        end
                                        buf = buf..'"REQ'..countReq..'": {'..reqs..'},';
                                        countReq = countReq+1;
                                    end
                                    buf = buf.."}";
                                    print("ENDD");
                                    if(read_setting("TIMER") ~= nil and read_setting("REQUESTS") ~= nil and tonumber(read_setting("REQUESTS")) > 0 and VICTRO_REQUESTS == 1) then
                                        local intervalTimer = tonumber(read_setting("TIMER")) * 1000;
                                        print("TIMER");
                                        tmr.alarm(5, intervalTimer, 1, function()
                                            if(tonumber(read_setting("REQUESTS")) > VICTRO_REQUESTS) then
                                                node.restart();
                                                tmr.stop(5)
                                            end
                                        end)
                                    end
                                end
                            else
                                buf = '{"ERROR": true, "MESSAGE": "INVALID TOKEN"}'; 
                            end
                            client:send(buf);
                            client:close();
                            collectgarbage();
                            conn:close();
                        end
                    end)
                end
            end
        else
            client:send(buf);
            client:close();
            collectgarbage();
            conn:close();
        end
        verify_loop = false
        
    end)
    conn:on("sent", function(client,request)
        conn:close();
    end)
end)
