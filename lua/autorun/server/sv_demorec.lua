util.AddNetworkString("DemoRec.StartRecord")
util.AddNetworkString("DemoRec.SendSettings")
util.AddNetworkString("DemoRec.EndRequest")
DemoRec = DemoRec or {}
DemoRec.settings = DemoRec.settings or {}
DemoRec.requests = DemoRec.requests or {}
include("../../demorec_settings.lua")

function DemoRec.PlayerInitialSpawn(ply)
    DemoRec.requests[ply:SteamID64()] = DemoRec.requests[ply:SteamID64()] or {}
end

hook.Add("PlayerInitialSpawn", "DemoRec.PlayerInitialSpawn", DemoRec.PlayerInitialSpawn)

function DemoRec:ChatNotify(ply, message)
    if IsValid(ply) then
        ply:ChatPrint("[DemoRec] " .. message)
    end
end

function DemoRec:HasPermission(ply)
    return ply:IsSuperAdmin() or (DemoRec.settings.admin_allowed and ply:IsAdmin())
end

function DemoRec.ConCommand(ply, cmd, args)
    if IsValid(ply) and not DemoRec:HasPermission(ply) then
        return
    end

    local ident = args[1]
    local target = player.GetBySteamID64(ident)

    if not IsValid(target) then
        return
    end

    local length = tonumber(args[2])

    if length <= 0 or length > DemoRec.settings.MaxLength then
        return
    end

    DemoRec:RequestDemo(target, length)
    if IsValid(ply) then
        table.insert(DemoRec.requests[target:SteamID64()], ply:SteamID64())
        DemoRec:ChatNotify(ply, "Requested demo from " .. target:Name() .. ".")
    end
end

concommand.Add("demorec", DemoRec.ConCommand)

function DemoRec:AddWebClient(sid64, cl_key, file_prefix)
    local post_table = {}
    post_table["sid64"] = sid64
    post_table["filename"] = file_prefix .. ".dem"
    post_table["cl_key"] = tostring(cl_key)
    post_table["sv_key"] = DemoRec.settings.sv_key
    http.Post(DemoRec.settings.website .. "addclient", post_table)
end

function DemoRec:RequestDemo(ply, length)
    local key = math.random(100000)
    local file_prefix = os.date("%H_%M_%S__%d_%m_%Y", os.time())
    DemoRec:AddWebClient(ply:SteamID64(), key, file_prefix)
    net.Start("DemoRec.StartRecord")
    net.WriteUInt(key, 18)
    net.WriteUInt(length, 12)
    net.WriteString(file_prefix)
    net.WriteString(DemoRec.settings.website)
    net.Send(ply)
end

function DemoRec.EndRequest(len, ply)
    local success = net.ReadBool()

    if #DemoRec.requests[ply:SteamID64()] > 0 then
        for k, admin_sid64 in pairs(DemoRec.requests[ply:SteamID64()]) do
            local admin = player.GetBySteamID64(admin_sid64)
            if not IsValid(admin) then continue end
            if success then
                DemoRec:ChatNotify(player.GetBySteamID64(admin), "Demo successfully sent by " .. ply:Name() .. " to web server.")
            else
                local err = net.ReadString()
                DemoRec:ChatNotify(player.GetBySteamID64(admin), "Error from .. " .. ply:Name() .. " while sending demo to web server :\n" .. err)
            end
        end
        DemoRec.requests[ply:SteamID64()] = {}
    end
end

net.Receive("DemoRec.EndRequest", DemoRec.EndRequest)