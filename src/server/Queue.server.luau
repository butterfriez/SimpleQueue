local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QueueSystem = require(ReplicatedStorage.Shared.QueueSystem)
local Queues = CollectionService:GetTagged("Queue")

for _, instance in next, Queues do
	local queue = QueueSystem.new(instance)
	queue:Start()
	queue:CountdownChanged(function()
		print(queue.CurrentCountdown)
	end)
end
