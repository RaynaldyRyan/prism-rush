-- Prism Rush: the server entry point. One job: answer the client's best-score
-- requests through a RemoteFunction. The game itself runs on the client; the
-- server only guards the persistent best score.

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
