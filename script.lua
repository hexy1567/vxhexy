	while tween.PlaybackState == Enum.PlaybackState.Playing do
		if getgenv().MM2FarmSession ~= mySession or not roundActive or not hrp or not hrp.Parent or bag_full then
			tween:Cancel()
			return false
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		task.wait()
	end
	return true
end

-- ============================================================
-- FARM DÖNGÜSÜ
-- ============================================================
task.spawn(function()
	while true do
		task.wait(0.03)
		if getgenv().MM2FarmSession ~= mySession then break end
		if autoFarmEnabled and farming and not bag_full and not isDead and roundActive then
			local hrp = getHRP()
			if hrp and hrp.Parent then
				local coin, dist = get_nearest_coin()
				if coin then
					if undergroundMode then
						local targetPos = Vector3.new(coin.Position.X, coin.Position.Y - 3.5, coin.Position.Z)
						tweenTo(hrp, targetPos)
						
						if firetouchinterest then
							firetouchinterest(hrp, coin, 0)
							firetouchinterest(hrp, coin, 1)
						else
							coin.CFrame = hrp.CFrame
						end
						
						if isCoinValid(coin) and roundActive then
							collectedCoins[coin] = tick()
						end
					else
						if tweenTo(hrp, coin.Position) then
							if isCoinValid(coin) and roundActive then
								collectedCoins[coin] = tick()
							end
						end
					end
				else
					task.wait(0.2)
				end
			end
		end
	end
end)

-- ============================================================
-- OYUN TOPBAR BUTONU
-- ============================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local gameTopbar = playerGui:WaitForChild("GameTopbar")
local container = gameTopbar:WaitForChild("Container")

if container:FindFirstChild("MenuToggleButton") then
	container.MenuToggleButton:Destroy()
end

local buttonSize = 45
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MenuToggleButton"
ToggleButton.Parent = container
ToggleButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Text = ""
ToggleButton.AutoButtonColor = false

if GuiService:IsTenFootInterface() then
	ToggleButton.Visible = false
end

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local BtnStroke = Instance.new("UIStroke", ToggleButton)
BtnStroke.Color = Color3.fromRGB(80, 80, 90)
BtnStroke.Thickness = 1.5
BtnStroke.Transparency = 0.4

local ToggleIcon = Instance.new("ImageLabel", ToggleButton)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Size = UDim2.new(0, buttonSize - 16, 0, buttonSize - 16)
ToggleIcon.Position = UDim2.new(0.5, -(buttonSize - 16)/2, 0.5, -(buttonSize - 16)/2)
ToggleIcon.Image = "rbxassetid://83217542970502"

local BLabel = Instance.new("TextLabel", ToggleButton)
BLabel.BackgroundTransparency = 1
BLabel.Size = UDim2.new(0, 16, 0, 16)
BLabel.Position = UDim2.new(1, -16, 1, -16)
BLabel.Font = Enum.Font.GothamBold
BLabel.Text = "B"
BLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BLabel.TextSize = 22
BLabel.TextXAlignment = Enum.TextXAlignment.Center
BLabel.TextYAlignment = Enum.TextYAlignment.Center
BLabel.Visible = UserInputService.KeyboardEnabled

local isVisible = false
MainFrame.Visible = false

task.delay(2.2, function()
	isVisible = true
	MainFrame.Visible = true
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if getgenv().MM2FarmSession ~= mySession then break end
		if isVisible then
			local t1 = TweenService:Create(BtnStroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(200, 200, 255), Transparency = 0})
			t1:Play()
			t1.Completed:Wait()
			if getgenv().MM2FarmSession ~= mySession or not isVisible then break end
			local t2 = TweenService:Create(BtnStroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(80, 80, 90), Transparency = 0.4})
			t2:Play()
			t2.Completed:Wait()
		else
			task.wait(0.2)
		end
	end
end)

local function toggleMenu()
	isVisible = not isVisible
	MainFrame.Visible = isVisible
end

ToggleButton.MouseButton1Click:Connect(toggleMenu)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleMenu()
	end
end)
