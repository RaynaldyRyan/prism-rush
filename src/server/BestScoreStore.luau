-- Prism Rush: best-score persistence. DataStore when it is available, an
-- in-memory table when it is not (a Studio playtest without API access, for
-- example). Every DataStore call is pcall-wrapped, so the game never errors.

local DataStoreService = game:GetService("DataStoreService")

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("PrismRushBestScore")
end)

local memory = {}

local BestScoreStore = {}

function BestScoreStore.get(player)
	local cached = memory[player.UserId]
	if cached ~= nil then
		return cached
	end
	if store then
		local ok, value = pcall(function()
			return store:GetAsync("best_" .. player.UserId)
		end)
		if ok and typeof(value) == "number" then
			memory[player.UserId] = value
			return value
		end
	end
	return 0
end

function BestScoreStore.save(player, score)
	local best = math.max(BestScoreStore.get(player), score)
	memory[player.UserId] = best
	if store then
		pcall(function()
			store:SetAsync("best_" .. player.UserId, best)
		end)
	end
	return best
end

return BestScoreStore
