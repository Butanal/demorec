DemoRec = DemoRec or {}
DemoRec.Queue = DemoRec.Queue or {}
DemoRec.settings = DemoRec.settings or {}

function DemoRec.PostDemo(data, CurrentRecord)
    if not data or #data == 0 then
        return
    end

    local post_table = {}
    post_table["sid64"] = tostring(LocalPlayer():SteamID64())
    post_table["filename"] = CurrentRecord.filename
    post_table["cl_key"] = tostring(CurrentRecord.key)
    post_table["data_b64"] = util.Base64Encode(data)

    http.Post(DemoRec.settings.website, post_table, function(r, l, h, code)
        if code == 200 then
            net.Start("DemoRec.EndRequest")
            net.WriteBool(true)
            net.SendToServer()
        else
            local err = util.JSONToTable(r)["message"]
            net.Start("DemoRec.EndRequest")
            net.WriteBool(false)
            net.WriteString(err)
            net.SendToServer()
        end
    end, function(err)
        net.Start("DemoRec.EndRequest")
        net.WriteBool(false)
        net.WriteString(err)
        net.SendToServer()
    end)
end

function DemoRec.EndRecord()
    RunConsoleCommand("stop")
    DemoRec.recording = false
    local CurrentRecord = DemoRec.Queue[1] or DemoRec.CurrentRecord
    table.remove(DemoRec.Queue, 1)
    CurrentRecord.filename = CurrentRecord.file_prefix .. ".dem"

    if not CurrentRecord then
        return
    end

    timer.Simple(10, function()
        RunConsoleCommand("con_filter_enable", 0)
        RunConsoleCommand("con_filter_text_out", "")
        if file.Exists(CurrentRecord.filename, "DATA") then
            local data = file.Read(CurrentRecord.filename, "DATA")
            file.Delete(CurrentRecord.filename)
            DemoRec.PostDemo(data, CurrentRecord)
        end
    end)
end

function DemoRec.StartRecord()
    if not DemoRec then
        return
    end

    if DemoRec.recording then
        table.insert(DemoRec.Queue, DemoRec.CurrentRecord)
        DemoRec.EndRecord()
    end

    DemoRec.CurrentRecord = {}
    DemoRec.CurrentRecord.key = net.ReadUInt(18)
    local length = net.ReadUInt(12)
    DemoRec.CurrentRecord.file_prefix = net.ReadString()
    DemoRec.settings.website = net.ReadString() .. "postdemo"
    RunConsoleCommand("con_filter_enable", 1)
    RunConsoleCommand("con_filter_text_out", "Recording")
    RunConsoleCommand("record", "data/" .. DemoRec.CurrentRecord.file_prefix)
    DemoRec.recording = true
    timer.Simple(length, DemoRec.EndRecord)
    timer.Simple(1, function()
        RunConsoleCommand("con_filter_text_out", "Completed")
    end )
end

net.Receive("DemoRec.StartRecord", DemoRec.StartRecord)

hook.Add("Initialize", "DemoRec.Initialize", function()
    hook.Remove("HUDPaint", "DrawRecordingIcon")
end)