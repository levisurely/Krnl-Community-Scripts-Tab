local averageGameTime = 14 --In minutes

local function SendWebHook(reason, url) --Remind me to make a loadstring to handle all of these when I make autostratX lol
	if not url and isfile('TDS_AutoStrat\\Webhook (Logs).txt') then
		local c = readfile('TDS_AutoStrat\\Webhook (Logs).txt')
		if c ~= 'WEBHOOK HERE' then
			url = c
		else
			return
		end
	end
	if not url then return end
	local WebhookData = {
	  content= nil,
	  embeds= {
		{
		  title= "Auto Rejoin - Rejoined Game!",
		  description= reason,
		  color= 15123739
		}
	  },
	}
	local https = game:GetService('HttpService')
	local data = https:JSONEncode(WebhookData)
	
	local success,errorm = pcall(function()
		(syn and syn.request or http_request){Url=url, Method='POST',Headers = {
			['Content-Type'] = 'application/json';
		},Body=data}
	end)
	if not success then warn(errorm) end
end

local function Rejoin(reason)
    reason = reason or 'No reason provided'
if game.PlaceId == 5591597781 then--support for other games
    game:GetService("TeleportService"):Teleport(3260590327)
    SendWebHook(reason)
else
    reason = reason or 'Game timed out!'
    game:GetService('TeleportService'):Teleport(game.PlaceId, game.Players.LocalPlayer)
    SendWebHook(reason)
end
end
local lobbyKickTime = 180 --3 minutes, dont need to change
local gameKickTime = averageGameTime*60 --dont change, convertes minutes to seconds
spawn(function()
    if game.PlaceId == 3260590327 then --in lobby
        print("Lobby")
        wait(lobbyKickTime)
        Rejoin('Lobby Timeout! \nCould be due to script breaking or not finding elevator in time')
    elseif game.PlaceId == 5591597781 then --in game
        print("Game")
        wait(gameKickTime+180)--3 minute for bad rng
        Rejoin('Game Timeout! \nThis could be due to incorrect game time settings or the script breaking')
    end
end)
game.Players.PlayerAdded:Wait()
local GC = getconnections or get_signal_cons
	if GC then
		for i,v in pairs(GC(game.Players.LocalPlayer.Idled)) do
			if v["Disable"] then
				v["Disable"](v)
			elseif v["Disconnect"] then
				v["Disconnect"](v)
			end
		end
      end
game.Players.LocalPlayer.Idled:Connect(function(time)
     game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)
local Dir = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
	Dir.DescendantAdded:Connect(function(Err)
	task.wait()
	msg = Err:FindFirstChild('MessageArea'):FindFirstChild('ErrorFrame'):FindFirstChild('ErrorMessage').Text or 'Could not fetch error!'
	appendfile('test.txt',Err:FindFirstChild('MessageArea'):FindFirstChild('ErrorFrame'):FindFirstChild('ErrorMessage').Text)
	Rejoin('**Roblox error message:**\n\n'..msg)
end)
if #Dir:GetChildren()>0 then
     local Err = Dir:GetChildren()[1]
     task.wait()
     msg = Err:FindFirstChild('MessageArea'):FindFirstChild('ErrorFrame'):FindFirstChild('ErrorMessage').Text or 'Could not fetch error!' 
     Rejoin('**Roblox error message:**\n\n'..msg)
end