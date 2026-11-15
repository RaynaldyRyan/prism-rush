-- Prism Rush: server entry. Answers best-score requests via RemoteFunction; the game runs on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BestScoreStore = require(script.BestScoreStore)

local remote = Instance.new("RemoteFunction")
remote.Name = "BestScore"
remote.Parent = ReplicatedStorage

remote.OnServerInvoke = function(player, action, value)
	if action == "get" then
		return BestScoreStore.get(player)
	elseif action == "save" and typeof(value) == "number" then
		return BestScoreStore.save(player, value)
	end
	return 0
end
