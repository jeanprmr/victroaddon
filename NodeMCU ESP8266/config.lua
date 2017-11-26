--CODE BY JEAN VICTOR M SANTOS
--TO DOWNLOAD IT ACCESS VICTROBRAIN.COM
--CHECK IF IS THE FIRST RUN AND SET CONFIG PARAMS
if(read_setting("MODEL") == nil) then
    save_setting("MODEL", "VICTRO_ADDON");
end
if(read_setting("VERSION") == nil) then
    save_setting("VERSION", 1);
end
if(read_setting("PORT_SERVER") == nil) then
    save_setting("PORT_SERVER", "80");
end

VICTRO_ADDON_MODEL = read_setting("MODEL"); --PUBLIC
VICTRO_ADDON_VERSION = read_setting("VERSION"); --PUBLIC
VICTRO_ADDON_ID = node.chipid(); --PRIVATE
VICTRO_TOKEN_ADDON = nil; --PRIVATE
VICTRO_URL_SERVER = read_setting("URL_SERVER"); --PRIVATE
