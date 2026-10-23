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
for _, name in ipairs({"MM2FarmUI", "HexyMM2_UI", "HexyIntroGui"}) do
	local old = CoreGui:FindFirstChild(name)
	if old then old:Destroy() end
end

if LocalPlayer:FindFirstChild("PlayerGui") then
	local old = LocalPlayer.PlayerGui:FindFirstChild("CustomUI")
	if old then old:Destroy() end
end

-- // Dil Algılama
local currentLang = "EN"
pcall(function()
	local loc = LocalPlayer.LocaleId or LocalizationService:GetAbridgedRobloxLocale()
	if loc and loc:sub(1, 2):upper() == "TR" then currentLang = "TR" end
end)

local translations = {
	TR = {
		title = "HEXY | MM2 Farm (Made by HEXY)",
		mainTab = "Farm",
		miscTab = "Ayarlar",
		themeTab = "Tema",
		autoFarm = "Oto Coin Farm",
		speed = "Farm Hızı",
		warning = "25+ = Atılma Riski",
		autoReset = "Oto Reset (Çanta Dolunca)",
		underground = "Yeraltı Modu",
		antiAfk = "Anti-AFK",
		noclip = "Noclip",
		webhookPlaceholder = "Discord Webhook URL",
		langStatus = "Dil: Türkçe",
		themeTitle = "Tema Ayarları",
		bgColor = "Arka Plan Rengi",
		borderColor = "Kenarlık Rengi",
		accentColor = "Vurgu Rengi",
		transparency = "Şeffaflık",
		presets = "Hazır Temalar",
		presetDark = "Koyu",
		presetPurple = "Mor",
		presetRed = "Kırmızı"
	},
	EN = {
		title = "HEXY | MM2 Farm (Made by HEXY)",
		mainTab = "Farm",
		miscTab = "Settings",
		themeTab = "Theme",
		autoFarm = "Auto Coin Farm",
		speed = "Farm Speed",
		warning = "25+ = Kick Risk",
		autoReset = "Auto Reset (Bag Full)",
		underground = "Underground Mode",
		antiAfk = "Anti-AFK",
		noclip = "Noclip",
		webhookPlaceholder = "Discord Webhook URL",
		langStatus = "Lang: English",
		themeTitle = "Theme Settings",
		bgColor = "Background Color",
		borderColor = "Border Color",
		accentColor = "Accent Color",
		transparency = "Transparency",
		presets = "Presets",
		presetDark = "Dark",
		presetPurple = "Purple",
		presetRed = "Red"
	}
}

local function L(key)
	return translations[currentLang][key] or key
end

-- // Farm & Config Değişkenleri
local configFileName = "HexyMM2_Config.json"
local autoFarmEnabled = false
local farmSpeed = 20
local autoResetEnabled = false
local undergroundMode = false
local antiAfkEnabled = false
local noclipEnabled = false
local webhookURL = ""

local noclipConnection = nil

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
	local configData = {
		AutoFarm = autoFarmEnabled,
		FarmSpeed = farmSpeed,
		AutoReset = autoResetEnabled,
		Underground = undergroundMode,
		AntiAFK = antiAfkEnabled,
		Noclip = noclipEnabled,
		WebhookURL = webhookURL
	}
	pcall(function()
		if writefile then
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
local function unStabilizeCharacter()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.AutoRotate = true
	hum.WalkSpeed = 16
	hum.JumpPower = 50
	hum.PlatformStand = false
end

-- ============================================================
-- OYUN DURUMU & COIN ARAMA (Lobi Filtresi)
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

local IntroText = Instance.new("TextLabel", IntroFrame)
IntroText.Size = UDim2.new(1, 0, 1, 0)
IntroText.BackgroundTransparency = 1
IntroText.Font = Enum.Font.GothamBlack
IntroText.Text = "HEXY"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.TextSize = 72
IntroText.TextTransparency = 1

local IntroSub = Instance.new("TextLabel", IntroFrame)
IntroSub.Size = UDim2.new(1, 0, 0, 20)
IntroSub.Position = UDim2.new(0, 0, 0.55, 0)
IntroSub.BackgroundTransparency = 1
IntroSub.Font = Enum.Font.Gotham
IntroSub.Text = "MADE BY HEXY | MM2 FARM"
IntroSub.TextColor3 = Color3.fromRGB(150, 150, 160)
IntroSub.TextSize = 14
IntroSub.TextTransparency = 1

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
ScreenGui.Name = "MM2FarmUI"
ScreenGui.ResetOnSpawn = false
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

-- Üst Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = theme.bgLight
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", TopBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 350, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = L("title")
Title.TextColor3 = theme.text
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Sidebar & Content
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 60, 1, -38)
Sidebar.Position = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = theme.bgLight
Sidebar.BorderSizePixel = 0

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

local MainTabBtn = createTabBtn("Farm", L("mainTab"), 10)
local MiscTabBtn = createTabBtn("Misc", L("miscTab"), 52)
local ThemeTabBtn = createTabBtn("Theme", L("themeTab"), 94)

tabButtons = {MainTabBtn, MiscTabBtn, ThemeTabBtn}

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -60, 1, -38)
ContentFrame.Position = UDim2.new(0, 60, 0, 38)
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

-- Toggles
local toggleObjects = {}

local function createToggle(parent, name, text, callback)
	local TFrame = Instance.new("Frame", parent)
	TFrame.Size = UDim2.new(1, -10, 0, 36)
	TFrame.BackgroundColor3 = theme.bgLighter
	TFrame.BorderSizePixel = 0
	Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 8)
	
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

-- Controls
createToggle(MainContent, "AutoFarm", L("autoFarm"), function(state)
	autoFarmEnabled = state
	if not state then unStabilizeCharacter() end
end)

createToggle(MainContent, "Underground", L("underground"), function(state)
	undergroundMode = state
end)

createToggle(MainContent, "AutoReset", L("autoReset"), function(state)
	autoResetEnabled = state
end)

local _, speedBox = createInput(MainContent, L("speed"), tostring(farmSpeed), function(val)
	local num = tonumber(val)
	if num then
		farmSpeed = math.clamp(num, 1, 50)
		speedBox.Text = tostring(farmSpeed)
	end
end)

createToggle(MiscContent, "AntiAFK", L("antiAfk"), function(state)
	antiAfkEnabled = state
	if state then
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/nahsqn/scripts/refs/heads/main/antiafk"))()
		end)
	end
end)

createToggle(MiscContent, "Noclip", L("noclip"), function(state)
	noclipEnabled = state
	if state then
		if not noclipConnection then
			noclipConnection = RunService.Stepped:Connect(function()
				if getgenv().HEXYFarmSession ~= mySession then return end
				local char = LocalPlayer.Character
				if char then
					for _, part in pairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end
			end)
		end
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		unStabilizeCharacter()
	end
end)

local _, webhookBox = createInput(MiscContent, L("webhookPlaceholder"), webhookURL, function(val)
	webhookURL = val
end)

-- ============================================================
-- AUTO FARM DÖNGÜSÜ (Tur Başlamasını Bekler)
-- ============================================================
task.spawn(function()
	while true do
		task.wait(0.1)
		if getgenv().HEXYFarmSession ~= mySession then break end
		
		if autoFarmEnabled then
			local coinContainer = getActiveCoinContainer()
			if coinContainer and #coinContainer:GetChildren() > 0 then
				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				
				if hrp then
					for _, coin in ipairs(coinContainer:GetChildren()) do
						if not autoFarmEnabled then break end
						if coin:IsA("BasePart") or coin:FindFirstChild("Coin") then
							local targetPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
							if targetPart then
								local targetPos = targetPart.Position
								if undergroundMode then
									targetPos = targetPos - Vector3.new(0, 6, 0)
								end
								
								hrp.CFrame = CFrame.new(targetPos)
								task.wait(math.clamp(1 / farmSpeed, 0.05, 0.5))
							end
						end
					end
				end
			end
		end
	end
end)

-- ============================================================
-- KAYITLI AYARLARI OTOMATİK YÜKLEME (AUTO LOAD)
-- ============================================================
local savedData = loadConfig()
if savedData then
	if savedData.AutoFarm ~= nil and toggleObjects["AutoFarm"] then
		toggleObjects["AutoFarm"](savedData.AutoFarm, true)
	end
	if savedData.Underground ~= nil and toggleObjects["Underground"] then
		toggleObjects["Underground"](savedData.Underground, true)
	end
	if savedData.AutoReset ~= nil and toggleObjects["AutoReset"] then
		toggleObjects["AutoReset"](savedData.AutoReset, true)
	end
	if savedData.AntiAFK ~= nil and toggleObjects["AntiAFK"] then
		toggleObjects["AntiAFK"](savedData.AntiAFK, true)
	end
	if savedData.Noclip ~= nil and toggleObjects["Noclip"] then
		toggleObjects["Noclip"](savedData.Noclip, true)
	end
	if savedData.FarmSpeed ~= nil then
		farmSpeed = savedData.FarmSpeed
		speedBox.Text = tostring(farmSpeed)
	end
	if savedData.WebhookURL ~= nil then
		webhookURL = savedData.WebhookURL
		webhookBox.Text = webhookURL
	end
end
