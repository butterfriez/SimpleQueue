local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QueueSystem = require(ReplicatedStorage.Shared.QueueSystem)
local Queues = CollectionService:GetTagged("Queue")

for _, instance in next, Queues do
	local queue = QueueSystem.new(instance)
	queue:Start()

	queue.OnCountdownChanged:Connect(function(Countdown)
		if Countdown == 0 then
			queue:Destroy()
			print(queue)
		end
	end)
end
