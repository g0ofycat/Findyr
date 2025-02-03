--Script in SSS

local http = game:GetService("HttpService")

game.ReplicatedStorage.Events:WaitForChild("Http").OnServerEvent:Connect(function(player, API)
	task.spawn(function()
		local success, info = pcall(function() 
			return http:GetAsync(API) 
		end) 
		
		if success then 
			game.ReplicatedStorage.Events:WaitForChild("Http"):FireClient(player, info)
		else 
			print("Failed to fetch data:", info) 
		end
	end)
end)

--LocalScript in the GUI

local Ts = game:GetService("TweenService")
local Button = script.Parent
local ButtonSize = Button.Size
local Module = require(game.ReplicatedStorage.Modules:WaitForChild("RichText"))
local ErrorModule = require(game.ReplicatedStorage.Modules:WaitForChild("ErrorModule"))
local Players = game:GetService("Players")
local US = game:GetService("UserService")
local http = game:GetService("HttpService")
local VerifiedBadge = Button.Parent.Info:WaitForChild("VerifiedBadge")
local Info = Button.Parent.Info
local DisplayTextLabel = Info:WaitForChild("DisplayName")
local NameTextLabel = Info:WaitForChild("Name")
local IDTextLabel = Info:WaitForChild("UserID")
local InformationText = Info.MainInfo.ScrollingFrame:WaitForChild("Information")
local PlayerWorldModel = Info:WaitForChild("Player").WorldModel
local Errors = Button.Parent.Errors
local ErrorTextTemplate = game.ReplicatedStorage.UI:WaitForChild("ErrorText"):Clone()

local tt = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tt2 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local BiggerSize = UDim2.new(ButtonSize.X.Scale * 1.1, ButtonSize.X.Offset * 1.1, ButtonSize.Y.Scale * 1.1, ButtonSize.Y.Offset * 1.1)
local Tween = Ts:Create(Button, tt, {Size = BiggerSize})
local Tween2 = Ts:Create(Button, tt, {Size = ButtonSize})

local function playDialogueAnimation(texts, instance)
	for _, text in ipairs(texts) do
		local textObject = Module:New(instance, text)
		textObject:Animate(true)
	end
end

Button.InputBegan:Connect(function()
	Tween:Play()
end)

Button.InputEnded:Connect(function()
	Tween2:Play()
end)

local currentUserID = nil

local function displayUserInfo(userId, userInfo)
	if userId == currentUserID then return end
	ErrorModule.Main(Errors, ErrorTextTemplate, "Success!", Color3.fromRGB(55, 255, 10))
	
	local Tween1 = Ts:Create(Info, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
	Tween1:Play()
	Info.Visible = true

	PlayerWorldModel:ClearAllChildren()
	local PlayerRig = game.Players:CreateHumanoidModelFromUserId(userId)
	PlayerRig.Parent = PlayerWorldModel

	local API = "https://users.roproxy.com/v1/users/"..userId
	
	game.ReplicatedStorage.Events:WaitForChild("Http"):FireServer(API)
	
	playDialogueAnimation({"Display Name: " .. userInfo[1].DisplayName}, DisplayTextLabel)
	playDialogueAnimation({"Username: @" .. userInfo[1].Username}, NameTextLabel)
	playDialogueAnimation({"User ID: " .. tostring(userId)}, IDTextLabel)

	currentUserID = userId
end

Button.Activated:Connect(function()
	local input = Button.Parent:WaitForChild("PlayerLookup").Text
	if tonumber(input) then
		local UserID = tonumber(input)

		if UserID == currentUserID then
			return
		end
		
		local success, userInfo = pcall(function()
			return US:GetUserInfosByUserIdsAsync({UserID})
		end)

		if success and userInfo and userInfo[1] then
			displayUserInfo(UserID, userInfo)
		else
			ErrorModule.Main(Button.Parent.Errors, game.ReplicatedStorage.UI:WaitForChild("ErrorText"):Clone(), "Error: Invalid User ID!", Color3.fromRGB(255, 0, 0))
		end
	else
		local success, userId = pcall(function()
			return Players:GetUserIdFromNameAsync(input)
		end)

		if success and userId then
			if userId == currentUserID then
				return
			end

			local success2, userInfo = pcall(function()
				return US:GetUserInfosByUserIdsAsync({userId})
			end)

			if success2 and userInfo and userInfo[1] then
				displayUserInfo(userId, userInfo)
			else
				ErrorModule.Main(Button.Parent.Errors, game.ReplicatedStorage.UI:WaitForChild("ErrorText"):Clone(), "Error: Player not found!", Color3.fromRGB(255, 0, 0))
			end
		else
			ErrorModule.Main(Button.Parent.Errors, game.ReplicatedStorage.UI:WaitForChild("ErrorText"):Clone(), "Error: Invalid Username!", Color3.fromRGB(255, 0, 0))
		end
	end
end)

game.ReplicatedStorage.Events:WaitForChild("Http").OnClientEvent:Connect(function(info)
	local data = http:JSONDecode(info)
	
	if data.hasVerifiedBadge then
		Ts:Create(VerifiedBadge, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	else
		Ts:Create(VerifiedBadge, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
	end

	playDialogueAnimation({
		"Description: " .. data.description .. "\n" ..
			"Created: " .. data.created .. "\n" ..
			"isBanned: " .. tostring(data.isBanned)
	}, InformationText)
end)
