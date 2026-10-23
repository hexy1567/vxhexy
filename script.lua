if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- // Benzersiz Oturum
getgenv().HEXYFarmSession = tick()
local mySession = getgenv().HEXYFarmSession

-- // Servisler
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- // Eski GUI Temizliği
for _, name in ipairs({"MM2FarmUI", "HexyMM2_UI", "HexyIntroGui", "VoidMM2_UI", "VoidIntroGui"}) do
	local old = CoreGui:FindFirstChild(name)
	if old then old:Destroy() end
end

if LocalPlayer:FindFirstChild("PlayerGui") then
	local old = LocalPlayer.PlayerGui:FindFirstChild("CustomUI")
	if old then old:Destroy() end
end

-- // Farm & Config Değişkenleri
local configFileName = "HexyMM2_Config.json"
local webhookURL = ""
local autoFarmEnabled = false
local farmSpeed = 20
local autoResetEnabled = false
local undergroundMode = false
local noclipEnabled = false
local noclipConnection = nil
local stabilizeConnection = nil

-- // Tema Değişkenleri
local theme = {
	bg = Color3.fromRGB(12, 12, 16),
	bgLight = Color3.fromRGB(18, 18, 22),
	bgLighter = Color3.fromRGB(22, 22, 28),
	border = Color3.fromRGB(45, 45, 55),
	accent = Color3.fromRGB(70, 200, 100),
	text = Color3.fromRGB(220, 220, 225),
	textDim = Color3.fromRGB(150, 150, 160),
	transparency = 0.25
}

local themeElements = {}

-- ============================================================
-- AUTO SAVE & LOAD SİSTEMİ
-- ============================================================
local function saveConfig()
	pcall(function()
		if writefile then
			local configData = {
				AutoFarm = autoFarmEnabled,
				FarmSpeed = farmSpeed,
				AutoReset = autoResetEnabled,
				Underground = undergroundMode,
				Noclip = noclipEnabled,
				WebhookURL = webhookURL,
				Theme = {
					bgR = theme.bg.R, bgG = theme.bg.G, bgB = theme.bg.B,
					bgLightR = theme.bgLight.R, bgLightG = theme.bgLight.G, bgLightB = theme.bgLight.B,
					bgLighterR = theme.bgLighter.R, bgLighterG = theme.bgLighter.G, bgLighterB = theme.bgLighter.B,
					borderR = theme.border.R, borderG = theme.border.G, borderB = theme.border.B,
					accentR = theme.accent.R, accentG = theme.accent.G, accentB = theme.accent.B,
					transparency = theme.transparency
				}
			}
			writefile(configFileName, HttpService:JSONEncode(configData))
		end
	end)
end

local function loadConfig()
	local success, result = pcall(function()
		if readfile and isfile and isfile(configFileName) then
			return HttpService:JSONDecode(readfile(configFileName))
		end
	end)
	if success and type(result) == "table" then
		return result
	end
	return nil
end

-- ============================================================
-- KARAKTER KONTROLÜ
-- ============================================================
local function getHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function stabilizeCharacter()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = getHRP()
	local hum = getHumanoid()
	if not hrp or not hum then return end
	
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Velocity = Vector3.zero
	hrp.RotVelocity = Vector3.zero
	
	hum.AutoRotate = false
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.PlatformStand = true
	hum.Sit = false
end

local function unStabilizeCharacter()
	local hum = getHumanoid()
	if not hum then return end
	hum.AutoRotate = true
	hum.WalkSpeed = 16
	hum.JumpPower = 50
	hum.PlatformStand = false
end

local function startStabilization()
	if stabilizeConnection then return end
	stabilizeConnection = RunService.Heartbeat:Connect(function()
		if getgenv().HEXYFarmSession ~= mySession then
			stabilizeConnection:Disconnect()
			stabilizeConnection = nil
			return
		end
		if noclipEnabled or autoFarmEnabled then
			stabilizeCharacter()
		end
	end)
end

local function stopStabilization()
	if stabilizeConnection then
		stabilizeConnection:Disconnect()
		stabilizeConnection = nil
	end
	unStabilizeCharacter()
end

-- ============================================================
-- OYUN DURUMU & COIN KONTROLÜ (Lobi Filtresi)
-- ============================================================
local function getActiveCoinContainer()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:FindFirstChild("CoinContainer") then
			return child.CoinContainer
		end
	end
	return Workspace:FindFirstChild("CoinContainer")
end

-- ============================================================
-- AÇILIŞ ANİMASYONU
-- ============================================================
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "HexyIntroGui"
IntroGui.ResetOnSpawn = false
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
IntroGui.DisplayOrder = 999999
IntroGui.IgnoreGuiInset = true
IntroGui.Parent = CoreGui

local IntroFrame = Instance.new("Frame", IntroGui)
IntroFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.BorderSizePixel = 0
IntroFrame.ZIndex = 100

local IntroText = Instance.new("TextLabel", IntroFrame)
IntroText.Size = UDim2.new(1, 0, 1, 0)
IntroText.BackgroundTransparency = 1
IntroText.Font = Enum.Font.GothamBlack
IntroText.Text = "HEXY"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.TextSize = 72
IntroText.TextTransparency = 1
IntroText.ZIndex = 101

local IntroSub = Instance.new("TextLabel", IntroFrame)
IntroSub.Size = UDim2.new(1, 0, 0, 20)
IntroSub.Position = UDim2.new(0, 0, 0.55, 0)
IntroSub.BackgroundTransparency = 1
IntroSub.Font = Enum.Font.Gotham
IntroSub.Text = "MM2 FARM HUB"
IntroSub.TextColor3 = Color3.fromRGB(150, 150, 160)
IntroSub.TextSize = 14
IntroSub.TextTransparency = 1
IntroSub.ZIndex = 101

task.spawn(function()
	TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
	TweenService:Create(IntroSub, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.3), {TextTransparency = 0}):Play()
	task.wait(1.8)
	TweenService:Create(IntroText, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	TweenService:Create(IntroSub, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	TweenService:Create(IntroFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
	task.wait(0.8)
	IntroGui:Destroy()
end)

-- ============================================================
-- ANA ARAYÜZ
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HexyMM2_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = theme.bg
MainFrame.BackgroundTransparency = theme.transparency
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.ClipsDescendants = true
MainFrame.Visible = false

task.delay(1.8, function()
	MainFrame.Visible = true
end)

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = theme.border
MainStroke.Thickness = 1.2
table.insert(themeElements, {obj = MainStroke, prop = "Color", key = "border"})

-- Üst Bar & Sürükleme (Draggable)
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = theme.bgLight
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
table.insert(themeElements, {obj = TopBar, prop = "BackgroundColor3", key = "bgLight"})

local dragging = false
local dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local Title = Instance.new("TextLabel", TopBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 300, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "HEXY | MM2 Farm"
Title.TextColor3 = theme.text
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
table.insert(themeElements, {obj = Title, prop = "TextColor3", key = "text"})

local LangLabel = Instance.new("TextLabel", TopBar)
LangLabel.BackgroundTransparency = 1
LangLabel.Position = UDim2.new(1, -110, 0, 0)
LangLabel.Size = UDim2.new(0, 100, 1, 0)
LangLabel.Font = Enum.Font.Gotham
LangLabel.Text = "HEXY HUB"
LangLabel.TextColor3 = theme.textDim
LangLabel.TextSize = 10
LangLabel.TextXAlignment = Enum.TextXAlignment.Right
table.insert(themeElements, {obj = LangLabel, prop = "TextColor3", key = "textDim"})

-- Sidebar & Content
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 50, 1, -38)
Sidebar.Position = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = theme.bgLight
Sidebar.BorderSizePixel = 0
table.insert(themeElements, {obj = Sidebar, prop = "BackgroundColor3", key = "bgLight"})

local tabButtons = {}
local function createTabBtn(name, text, yPos)
	local btn = Instance.new("TextButton", Sidebar)
	btn.Size = UDim2.new(1, -8, 0, 36)
	btn.Position = UDim2.new(0, 4, 0, yPos)
	btn.BackgroundColor3 = (name == "Farm") and Color3.fromRGB(40, 40, 50) or theme.bgLighter
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Name = name .. "Tab"
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local MainTabBtn = createTabBtn("Farm", "Farm", 10)
local MiscTabBtn = createTabBtn("Misc", "Ayarlar", 52)
local ThemeTabBtn = createTabBtn("Theme", "Tema", 94)

tabButtons = {MainTabBtn, MiscTabBtn, ThemeTabBtn}

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -50, 1, -38)
ContentFrame.Position = UDim2.new(0, 50, 0, 38)
ContentFrame.BackgroundTransparency = 1

local MainContent = Instance.new("ScrollingFrame", ContentFrame)
MainContent.Size = UDim2.new(1, -10, 1, -5)
MainContent.Position = UDim2.new(0, 5, 0, 5)
MainContent.BackgroundTransparency = 1
MainContent.BorderSizePixel = 0

local MiscContent = Instance.new("ScrollingFrame", ContentFrame)
MiscContent.Size = UDim2.new(1, -10, 1, -5)
MiscContent.Position = UDim2.new(0, 5, 0, 5)
MiscContent.BackgroundTransparency = 1
MiscContent.BorderSizePixel = 0
MiscContent.Visible = false

local ThemeContent = Instance.new("ScrollingFrame", ContentFrame)
ThemeContent.Size = UDim2.new(1, -10, 1, -5)
ThemeContent.Position = UDim2.new(0, 5, 0, 5)
ThemeContent.BackgroundTransparency = 1
ThemeContent.BorderSizePixel = 0
ThemeContent.Visible = false

for _, scroll in ipairs({MainContent, MiscContent, ThemeContent}) do
	local list = Instance.new("UIListLayout", scroll)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
	end)
end

local function switchTab(tabName)
	for _, btn in ipairs(tabButtons) do
		btn.BackgroundColor3 = (btn.Name == tabName .. "Tab") and Color3.fromRGB(40, 40, 50) or theme.bgLighter
	end
	MainContent.Visible = (tabName == "Farm")
	MiscContent.Visible = (tabName == "Misc")
	ThemeContent.Visible = (tabName == "Theme")
end

MainTabBtn.MouseButton1Click:Connect(function() switchTab("Farm") end)
MiscTabBtn.MouseButton1Click:Connect(function() switchTab("Misc") end)
ThemeTabBtn.MouseButton1Click:Connect(function() switchTab("Theme") end)

-- ============================================================
-- TEMA UYGULAMA
-- ============================================================
local function applyTheme()
	for _, item in ipairs(themeElements) do
		if item.obj and item.obj.Parent then
			item.obj[item.prop] = theme[item.key]
		end
	end
	MainFrame.BackgroundColor3 = theme.bg
	MainFrame.BackgroundTransparency = theme.transparency
	TopBar.BackgroundColor3 = theme.bgLight
	Sidebar.BackgroundColor3 = theme.bgLight
	MainStroke.Color = theme.border
	Title.TextColor3 = theme.text
	saveConfig()
end

-- ============================================================
-- TOGGLE & INPUT OLUŞTURUCULAR
-- ============================================================
local toggleObjects = {}

local function createToggle(parent, name, text, callback)
	local TFrame = Instance.new("Frame", parent)
	TFrame.Size = UDim2.new(1, -10, 0, 36)
	TFrame.BackgroundColor3 = theme.bgLighter
	TFrame.BorderSizePixel = 0
	Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 8)
	table.insert(themeElements, {obj = TFrame, prop = "BackgroundColor3", key = "bgLighter"})
	
	local TText = Instance.new("TextLabel", TFrame)
	TText.Size = UDim2.new(1, -70, 1, 0)
	TText.Position = UDim2.new(0, 12, 0, 0)
	TText.BackgroundTransparency = 1
	TText.Font = Enum.Font.GothamMedium
	TText.Text = text
	TText.TextColor3 = Color3.fromRGB(200, 200, 200)
	TText.TextSize = 12
	TText.TextXAlignment = Enum.TextXAlignment.Left
	
	local SwitchBg = Instance.new("Frame", TFrame)
	SwitchBg.Size = UDim2.new(0, 38, 0, 20)
	SwitchBg.Position = UDim2.new(1, -48, 0.5, -10)
	SwitchBg.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
	
	local SwitchCircle = Instance.new("Frame", SwitchBg)
	SwitchCircle.Size = UDim2.new(0, 16, 0, 16)
	SwitchCircle.Position = UDim2.new(0, 2, 0, 2)
	SwitchCircle.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	Instance.new("UICorner", SwitchCircle).CornerRadius = UDim.new(1, 0)
	
	local Btn = Instance.new("TextButton", TFrame)
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	
	local state = false
	
	local function updateState(newState, silent)
		state = newState
		local goalBg = state and theme.accent or Color3.fromRGB(55, 55, 65)
		local goalPos = state and UDim2.new(0, 20, 0, 2) or UDim2.new(0, 2, 0, 2)
		
		TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = goalBg}):Play()
		TweenService:Create(SwitchCircle, TweenInfo.new(0.2), {Position = goalPos}):Play()
		TText.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
		
		if not silent then
			saveConfig()
		end
		if callback then callback(state) end
	end
	
	Btn.MouseButton1Click:Connect(function()
		updateState(not state)
	end)
	
	toggleObjects[name] = updateState
	return TFrame
end

local function createInput(parent, text, defaultText, callback)
	local IFrame = Instance.new("Frame", parent)
	IFrame.Size = UDim2.new(1, -10, 0, 52)
	IFrame.BackgroundColor3 = theme.bgLighter
	Instance.new("UICorner", IFrame).CornerRadius = UDim.new(0, 8)
	table.insert(themeElements, {obj = IFrame, prop = "BackgroundColor3", key = "bgLighter"})
	
	local IText = Instance.new("TextLabel", IFrame)
	IText.Size = UDim2.new(1, -16, 0, 16)
	IText.Position = UDim2.new(0, 10, 0, 6)
	IText.BackgroundTransparency = 1
	IText.Font = Enum.Font.GothamMedium
	IText.Text = text
	IText.TextColor3 = Color3.fromRGB(160, 160, 170)
	IText.TextSize = 11
	IText.TextXAlignment = Enum.TextXAlignment.Left
	
	local TextBox = Instance.new("TextBox", IFrame)
	TextBox.Size = UDim2.new(1, -20, 0, 22)
	TextBox.Position = UDim2.new(0, 10, 0, 24)
	TextBox.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.Font = Enum.Font.Gotham
	TextBox.TextSize = 11
	TextBox.Text = defaultText
	TextBox.ClearTextOnFocus = false
	Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
	
	TextBox.FocusLost:Connect(function()
		if callback then callback(TextBox.Text) end
		saveConfig()
	end)
	
	return IFrame, TextBox
end

-- ============================================================
-- KONTROL ELEMANLARI
-- ============================================================
createToggle(MainContent, "AutoFarm", "Oto Coin Farm", function(state)
	autoFarmEnabled = state
	if state then
		startStabilization()
	else
		if not noclipEnabled then
			stopStabilization()
		end
	end
end)

createToggle(MainContent, "Underground", "Yeraltı Modu", function(state)
	undergroundMode = state
end)

createToggle(MainContent, "AutoReset", "Oto Reset (Çanta Dolunca)", function(state)
	autoResetEnabled = state
end)

local _, speedBox = createInput(MainContent, "Farm Hızı", tostring(farmSpeed), function(val)
	local num = tonumber(val)
	if num then
		farmSpeed = math.clamp(num, 1, 50)
		speedBox.Text = tostring(farmSpeed)
	end
end)

createToggle(MiscContent, "AntiAFK", "Anti-AFK", function(state)
	if state then
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/nahsqn/scripts/refs/heads/main/antiafk"))()
		end)
	end
end)

createToggle(MiscContent, "Noclip", "Noclip", function(state)
	noclipEnabled = state
	if state then
		startStabilization()
		noclipConnection = RunService.Stepped:Connect(function()
			if getgenv().HEXYFarmSession ~= mySession then return end
			local char = LocalPlayer.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end)
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		if not autoFarmEnabled
