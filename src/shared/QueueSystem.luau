--!strict

--[[
	TODO:
	Change method of listening for player adding/removing (Touched TouchEnded fires multiple times, probably due to character's multiple parts)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local FastSignal = require(ReplicatedStorage.Packages.Signal)
type QueueSystem = {
	Players: { Player },
	Cooldown: number,
	CurrentCountdown: number,
	Part: Part,
	Janitor: Janitor.Janitor,

	OnCountdownChanged: FastSignal.ScriptSignal,
	PlayerAdded: FastSignal.ScriptSignal,
	PlayerRemoved: FastSignal.ScriptSignal,

	new: (part: Part) -> QueueSystem,
	Reset: (self: QueueSystem) -> (),
	Start: (self: QueueSystem) -> (),
	Destroy: (self: QueueSystem) -> (),
}

local QueueSystem: QueueSystem = {} :: QueueSystem
QueueSystem.__index = QueueSystem

function QueueSystem.new(part: Part): QueueSystem
	local self = setmetatable({}, QueueSystem) :: QueueSystem

	self.Players = {}
	self.Cooldown = 10
	self.CurrentCountdown = self.Cooldown
	self.Part = part
	self.Janitor = Janitor.new()

	self.OnCountdownChanged = FastSignal.new()
	self.PlayerAdded = FastSignal.new()
	self.PlayerRemoved = FastSignal.new()

	self.Janitor:Add(self.OnCountdownChanged, "Destroy")
	self.Janitor:Add(self.PlayerAdded, "Destroy")
	self.Janitor:Add(self.PlayerRemoved, "Destroy")

	return self
end

function QueueSystem.Reset(self: QueueSystem)
	table.clear(self.Players)
	self.CurrentCountdown = self.Cooldown
	self.OnCountdownChanged:Fire(self.CurrentCountdown)
end

function QueueSystem.Start(self: QueueSystem)
	local currentTime = os.clock()

	local function teleportPlayers()
		for _, player in next, self.Players do
			print("Teleporting player: " .. player.Name)
		end
		self:Reset()
	end

	self.Janitor:Add(
		self.Part.Touched:Connect(function(otherPart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)
			if not player then
				return
			end

			local playerExist = table.find(self.Players, player)

			if not playerExist then
				table.insert(self.Players, player)
				self.PlayerAdded:Fire(player)
			end
		end),
		"Disconnect"
	)

	self.Janitor:Add(
		self.Part.TouchEnded:Connect(function(otherPart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)
			if not player then
				return
			end

			local playerExist = table.find(self.Players, player)

			if playerExist then
				table.remove(self.Players, playerExist)
				self.PlayerRemoved:Fire(player)
			end
		end),
		"Disconnect"
	)

	self.Janitor:Add(
		RunService.PostSimulation:Connect(function()
			local timePassed = os.clock()
			if timePassed - currentTime >= 1 then
				self.OnCountdownChanged:Fire(self.CurrentCountdown)
				if self.CurrentCountdown == 0 then
					teleportPlayers()
				end

				self.CurrentCountdown -= 1
				currentTime = os.clock()
			end
		end),
		"Disconnect"
	)
end

function QueueSystem.Destroy(self: QueueSystem)
	if self.Janitor then
		self.Janitor:Destroy()
		self.Janitor = nil
	end
end

return table.freeze(QueueSystem)
