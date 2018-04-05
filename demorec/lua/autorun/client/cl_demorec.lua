DemoRec = DemoRec or {}
DemoRec.Queue = DemoRec.Queue or {}
DemoRec.settings = DemoRec.settings or {}


function DemoRec.PostDemo(data, CurrentRecord)
	if not data or #data == 0 then return end

	local post_table = {}
	post_table["sid64"] = tostring(LocalPlayer():SteamID64())
	post_table["filename"] = CurrentRecord.filename
	post_table["cl_key"] = tostring(CurrentRecord.key)
	post_table["data_b64"] = util.Base64Encode(data)

	http.Post(DemoRec.settings.website, post_table)
end


function DemoRec.EndRecord()
	RunConsoleCommand("stop")
	DemoRec.recording = false
	table.remove(DemoRec.Queue, 1)

	CurrentRecord = DemoRec.Queue[1] and DemoRec.Queue[1] or DemoRec.CurrentRecord

	CurrentRecord.filename = CurrentRecord.file_prefix .. ".dem"

	if not CurrentRecord then return end

	timer.Simple(10, function()

		if file.Exists(CurrentRecord.filename, "DATA") then
			local data = file.Read(CurrentRecord.filename, "DATA")
			file.Delete(CurrentRecord.filename)
			DemoRec.PostDemo(data, CurrentRecord)
		end

	end )

end


function DemoRec.StartRecord()
	if not DemoRec then return end

	if DemoRec.recording then
		table.insert(DemoRec.Queue, DemoRec.CurrentRecord)
		DemoRec.EndRecord()
	end

	DemoRec.CurrentRecord = {}
	DemoRec.CurrentRecord.key = net.ReadUInt(18)
	local length = net.ReadUInt(12)

	DemoRec.CurrentRecord.file_prefix = net.ReadString()
	DemoRec.settings.website = net.ReadString() .. "postdemo"

	RunConsoleCommand("record", "data/" .. DemoRec.CurrentRecord.file_prefix)
	DemoRec.recording = true

	timer.Simple(length, DemoRec.EndRecord)

end

net.Receive("DemoRec.StartRecord", DemoRec.StartRecord)


hook.Add("Initialize", "RemoRec.Initialize", function()
	hook.Remove("HUDPaint", "DrawRecordingIcon")
end )


function DemoRec.ReceiveSettings()
	DemoRec.settings = net.ReadTable()
end

net.Receive("DemoRec.SendSettings", DemoRec.ReceiveSettings)
