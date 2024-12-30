--!strict

--[[
    TODO:
    Implement PlayerAdded signal
    Implement PlayerRemoved signal
    Change OnCountdownChanged to signal
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type QueueSystem = {
	Players: { Player },
	Cooldown: number,
	CurrentCountdown: number,
	Part: Part,

	Connections: { RBXScriptSignal },
	OnCountdownChanged: { () -> () },
	PlayerAdded: { (player: Player) -> () },
	PlayerRemoved: { (player: Player) -> () },

	new: (part: Part) -> QueueSystem,
	Reset: (self: QueueSystem) -> (),
	Start: (self: QueueSystem) -> (),
	Stop: (self: QueueSystem) -> (),
	CountdownChanged: (self: QueueSystem, callback: () -> ()) -> (),
}

local QueueSystem: QueueSystem = {} :: QueueSystem
QueueSystem.__index = QueueSystem

local function fireCountdownCallbacks(queue: QueueSystem)
	for _, callback in next, queue.OnCountdownChanged do
		callback()
	end
end

function QueueSystem.new(part: Part): QueueSystem
	local self = setmetatable({}, QueueSystem) :: QueueSystem

	self.Players = {}
	self.Cooldown = 10
	self.CurrentCountdown = self.Cooldown
	self.Part = part
	self.Connections = {}
	self.OnCountdownChanged = {}

	return self
end

function QueueSystem.Reset(self: QueueSystem)
	table.clear(self.Players)
	self.CurrentCountdown = self.Cooldown
	fireCountdownCallbacks(self)
end

function QueueSystem.Start(self: QueueSystem)
	local currentTime = os.clock()

	local function teleportPlayers()
		for _, player in next, self.Players do
			print("Teleporting player: " .. player.Name)
		end
	end

	table.insert(
		self.Connections,
		self.Part.Touched:Connect(function(otherPart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)
			local playerExist = table.find(self.Players, player)

			if player and not playerExist then
				table.insert(self.Players, player)
			end
		end)
	)

	table.insert(
		self.Connections,
		self.Part.TouchEnded:Connect(function(otherPart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)
			local playerExist = table.find(self.Players, player)

			if player and playerExist then
				table.remove(self.Players, playerExist)
			end
		end)
	)

	table.insert(
		self.Connections,
		RunService.Stepped:Connect(function()
			local timePassed = os.clock()
			if timePassed - currentTime >= 1 then
				fireCountdownCallbacks(self)
				if self.CurrentCountdown == 0 then
					teleportPlayers()
					self:Reset()
				end

				self.CurrentCountdown -= 1
				currentTime = os.clock()
			end
		end)
	)
end

function QueueSystem.Stop(self: QueueSystem)
	for _, connection in next, self.Connections do
		connection:Disconnect()
	end
end

function QueueSystem.CountdownChanged(self: QueueSystem, callback: () -> ())
	table.insert(self.OnCountdownChanged, callback)
end

function QueueSystem.PlayerAdded(self: QueueSystem, callback: (player: Player) -> ())
	table.insert(self.PlayerAdded, callback)
end

function QueueSystem.PlayerRemoved(self: QueueSystem, callback: (player: Player) -> ())
	table.insert(self.PlayerRemoved, callback)
end

return table.freeze(QueueSystem)
