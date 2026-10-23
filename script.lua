if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- // Benzersiz Oturum
getgenv().MM2FarmSession = tick()
local mySession = getgenv().MM2FarmSession

-- // Servisler
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- // Eski GUI Temizliği
for _, name in ipairs({"MM2FarmUI", "VoidMM2_UI", "VoidIntroGui"}) do
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
		title = "VOİD | MM2 Farm",
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
		webhookTimer = "Webhook: ",
		coin = "Coin: ",
		time = "Süre: ",
		langStatus = "Dil: Türkçe",
		themeTitle = "Tema Ayarları",
		bgColor = "Arka Plan Rengi",
		borderColor = "Kenarlık Rengi",
		accentColor = "Vurgu Rengi",
		transparency = "Şeffaflık",
		presets = "Hazır Temalar",
		presetDark = "Koyu",
		presetPurple = "Mor",
		presetRed = "Kırmızı",
		presetBlue = "Mavi",
		presetGreen = "Yeşil",
		presetPink = "Pembe"
	},
	EN = {
		title = "VOİD | MM2 Farm",
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
		webhookTimer = "Webhook: ",
		coin = "Coins: ",
		time = "Time: ",
		langStatus = "Lang: English",
		themeTitle = "Theme Settings",
		bgColor = "Background Color",
		borderColor = "Border Color",
		accentColor = "Accent Color",
		transparency = "Transparency",
		presets = "Presets",
		presetDark = "Dark",
		presetPurple = "Purple",
		presetRed = "Red",
		presetBlue = "Blue",
		presetGreen = "Green",
		presetPink = "Pink"
	}
}

local function L(key)
	return translations[currentLang][key] or key
end

-- // İstatistik & Webhook
local totalCoins = 0
local startTime = os.time()
local webhookURL = "https://discord.com/api/webhooks/1454973948121972736/axP0KskgCgQa_VUgh65di5g6crIday2lOhwX6GSoQFF2hF8hOVZ-XuPoQDwqSecoSbhG"
local lastWebhook = os.time()
local webhookCooldown = 150
local targetUserId = LocalPlayer.UserId
local targetUserName = LocalPlayer.Name

-- // Farm Değişkenleri
local autoFarmEnabled = false
local farming = false
local bag_full = false
local start_position
local farmSpeed = 20
local autoResetEnabled = false
local resetting = false
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
-- KARAKTER STABİLİZASYON SİSTEMİ
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
	
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.Velocity = Vector3.zero
			part.RotVelocity = Vector3.zero
		end
	end
	
	hum.AutoRotate = false
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.PlatformStand = true
	hum.Sit = false
	
	local camera = Workspace.CurrentCamera
	if camera and camera.CameraSubject ~= hum then
		camera.CameraSubject = hum
	end
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
		if getgenv().MM2FarmSession ~= mySession then
			stabilizeConnection:Disconnect()
			stabilizeConnection = nil
			return
		end
		if noclipEnabled or (autoFarmEnabled and farming) then
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
-- AÇILIŞ ANİMASYONU — TÜM EKRANI KAPSAR
-- ============================================================
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "VoidIntroGui"
IntroGui.ResetOnSpawn = false
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
IntroGui.DisplayOrder = 999999
IntroGui.IgnoreGuiInset = true
IntroGui.Parent = CoreGui

local IntroFrame = Instance.new("Frame")
IntroFrame.Name = "Intro"
IntroFrame.Parent = IntroGui
IntroFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.BorderSizePixel = 0
IntroFrame.ZIndex = 100

local IntroText = Instance.new("TextLabel", IntroFrame)
IntroText.Size = UDim2.new(1, 0, 1, 0)
IntroText.BackgroundTransparency = 1
IntroText.Font = Enum.Font.GothamBlack
IntroText.Text = "VOID"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.TextSize = 72
IntroText.TextTransparency = 1
IntroText.ZIndex = 101

local IntroGlow = Instance.new("TextLabel", IntroFrame)
IntroGlow.Size = UDim2.new(1, 0, 1, 0)
IntroGlow.BackgroundTransparency = 1
IntroGlow.Font = Enum.Font.GothamBlack
IntroGlow.Text = "VOID"
IntroGlow.TextColor3 = Color3.fromRGB(70, 200, 100)
IntroGlow.TextSize = 72
IntroGlow.TextTransparency = 1
IntroGlow.ZIndex = 100
IntroGlow.Position = UDim2.new(0, 0, 0, 2)

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

local IntroBar = Instance.new("Frame", IntroFrame)
IntroBar.Size = UDim2.new(0, 0, 0, 2)
IntroBar.Position = UDim2.new(0.5, 0, 0.62, 0)
IntroBar.AnchorPoint = Vector2.new(0.5, 0)
IntroBar.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
IntroBar.BorderSizePixel = 0
IntroBar.ZIndex = 101

task.spawn(function()
	TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
	TweenService:Create(IntroGlow, TweenInfo.new(0.8), {TextTransparency = 0.6}):Play()
	TweenService:Create(IntroSub, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.3), {TextTransparency = 0}):Play()
	task.wait(0.5)
	TweenService:Create(IntroBar, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 200, 0, 2)}):Play()
	task.wait(1.8)
	TweenService:Create(IntroText, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	TweenService:Create(IntroGlow, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	TweenService:Create(IntroSub, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
	TweenService:Create(IntroBar, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	TweenService:Create(IntroFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
	task.wait(1)
	IntroGui:Destroy()
end)

-- ============================================================
-- ANA ARAYÜZ
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2FarmUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = theme.bg
MainFrame.BackgroundTransparency = theme.transparency
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.ClipsDescendants = true
MainFrame.Visible = false

task.delay(2.2, function()
	MainFrame.Visible = true
	TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 340)
	}):Play()
end)

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = theme.border
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.3
table.insert(themeElements, {obj = MainStroke, prop = "Color", key = "border"})

-- Üst Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = theme.bgLight
TopBar.BackgroundTransparency = 0.15
TopBar.BorderSizePixel = 0
table.insert(themeElements, {obj = TopBar, prop = "BackgroundColor3", key = "bgLight"})

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
local TopBarFix = Instance.new("Frame", TopBar)
TopBarFix.Size = UDim2.new(1, 0, 0, 12)
TopBarFix.Position = UDim2.new(0, 0, 1, -12)
TopBarFix.BackgroundColor3 = theme.bgLight
TopBarFix.BackgroundTransparency = 0.15
TopBarFix.BorderSizePixel = 0
table.insert(themeElements, {obj = TopBarFix, prop = "BackgroundColor3", key = "bgLight"})

local Title = Instance.new("TextLabel", TopBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 300, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = L("title")
Title.TextColor3 = theme.text
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
table.insert(themeElements, {obj = Title, prop = "TextColor3", key = "text"})

local LangLabel = Instance.new("TextLabel", TopBar)
LangLabel.BackgroundTransparency = 1
LangLabel.Position = UDim2.new(1, -110, 0, 0)
LangLabel.Size = UDim2.new(0, 100, 1, 0)
LangLabel.Font = Enum.Font.Gotham
LangLabel.Text = L("langStatus")
LangLabel.TextColor3 = theme.textDim
LangLabel.TextSize = 10
LangLabel.TextXAlignment = Enum.TextXAlignment.Right
table.insert(themeElements, {obj = LangLabel, prop = "TextColor3", key = "textDim"})

-- Sol Sekme Çubuğu
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 50, 1, -38)
Sidebar.Position = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = theme.bgLight
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
table.insert(themeElements, {obj = Sidebar, prop = "BackgroundColor3", key = "bgLight"})

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 0)

local SidebarStroke = Instance.new("UIStroke", Sidebar)
SidebarStroke.Color = theme.border
SidebarStroke.Thickness = 1
SidebarStroke.Transparency = 0.5
table.insert(themeElements, {obj = SidebarStroke, prop = "Color", key = "border"})

-- Sekme Butonları
local tabButtons = {}
local function createTabBtn(name, text, yPos)
	local btn = Instance.new("TextButton", Sidebar)
	btn.Size = UDim2.new(1, -8, 0, 36)
	btn.Position = UDim2.new(0, 4, 0, yPos)
	btn.BackgroundColor3 = (name == "Farm") and Color3.fromRGB(40, 40, 50) or theme.bgLighter
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = (name == "Farm") and Color3.fromRGB(255, 255, 255) or theme.textDim
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.Name = name .. "Tab"
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local MainTabBtn = createTabBtn("Farm", L("mainTab"), 10)
local MiscTabBtn = createTabBtn("Misc", L("miscTab"), 52)
local ThemeTabBtn = createTabBtn("Theme", L("themeTab"), 94)

tabButtons = {MainTabBtn, MiscTabBtn, ThemeTabBtn}

-- İçerik Alanı
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -50, 1, -88)
ContentFrame.Position = UDim2.new(0, 50, 0, 38)
ContentFrame.BackgroundTransparency = 1

local MainContent = Instance.new("ScrollingFrame", ContentFrame)
MainContent.Name = "MainContent"
MainContent.Size = UDim2.new(1, -10, 1, -5)
MainContent.Position = UDim2.new(0, 5, 0, 5)
MainContent.BackgroundTransparency = 1
MainContent.BorderSizePixel = 0
MainContent.ScrollBarThickness = 3
MainContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
MainContent.CanvasSize = UDim2.new(0, 0, 0, 0)

local MiscContent = Instance.new("ScrollingFrame", ContentFrame)
MiscContent.Name = "MiscContent"
MiscContent.Size = UDim2.new(1, -10, 1, -5)
MiscContent.Position = UDim2.new(0, 5, 0, 5)
MiscContent.BackgroundTransparency = 1
MiscContent.BorderSizePixel = 0
MiscContent.ScrollBarThickness = 3
MiscContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
MiscContent.CanvasSize = UDim2.new(0, 0, 0, 0)
MiscContent.Visible = false

local ThemeContent = Instance.new("ScrollingFrame", ContentFrame)
ThemeContent.Name = "ThemeContent"
ThemeContent.Size = UDim2.new(1, -10, 1, -5)
ThemeContent.Position = UDim2.new(0, 5, 0, 5)
ThemeContent.BackgroundTransparency = 1
ThemeContent.BorderSizePixel = 0
ThemeContent.ScrollBarThickness = 3
ThemeContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
ThemeContent.CanvasSize = UDim2.new(0, 0, 0, 0)
ThemeContent.Visible = false

local contentsList = {MainContent, MiscContent, ThemeContent}
for _, scroll in ipairs(contentsList) do
	local list = Instance.new("UIListLayout", scroll)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
	end)
end

-- Sekme Değiştirme
local function switchTab(tabName)
	local contents = {Farm = MainContent, Misc = MiscContent, Theme = ThemeContent}
	for _, btn in ipairs(tabButtons) do
		if btn.Name == tabName .. "Tab" then
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = theme.bgLighter
			btn.TextColor3 = theme.textDim
		end
	end
	for name, frame in pairs(contents) do
		frame.Visible = (name == tabName)
	end
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
	TopBarFix.BackgroundColor3 = theme.bgLight
	Sidebar.BackgroundColor3 = theme.bgLight
	SidebarStroke.Color = theme.border
	MainStroke.Color = theme.border
	Title.TextColor3 = theme.text
	LangLabel.TextColor3 = theme.textDim
end

-- ============================================================
-- MODERN TOGGLE
-- ============================================================
local toggles = {}

local function createToggle(parent, name, text, callback)
	local TFrame = Instance.new("Frame")
	TFrame.Parent = parent
	TFrame.Size = UDim2.new(1, -10, 0, 36)
	TFrame.BackgroundColor3 = theme.bgLighter
	TFrame.BackgroundTransparency = 0.15
	TFrame.BorderSizePixel = 0
	Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 8)
	table.insert(themeElements, {obj = TFrame, prop = "BackgroundColor3", key = "bgLighter"})
	
	local TStroke = Instance.new("UIStroke", TFrame)
	TStroke.Color = theme.border
	TStroke.Thickness = 1
	TStroke.Transparency = 0.4
	table.insert(themeElements, {obj = TStroke, prop = "Color", key = "border"})
	
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
	SwitchBg.BorderSizePixel = 0
	Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
	
	local SwitchCircle = Instance.new("Frame", SwitchBg)
	SwitchCircle.Size = UDim2.new(0, 16, 0, 16)
	SwitchCircle.Position = UDim2.new(0, 2, 0, 2)
	SwitchCircle.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	SwitchCircle.BorderSizePixel = 0
	Instance.new("UICorner", SwitchCircle).CornerRadius = UDim.new(1, 0)
	
	local Btn = Instance.new("TextButton", TFrame)
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	
	local state = false
	toggles[name] = state
	
	Btn.MouseButton1Click:Connect(function()
		state = not state
		toggles[name] = state
		
		local goalBg = state and theme.accent or Color3.fromRGB(55, 55, 65)
		local goalPos = state and UDim2.new(0, 20, 0, 2) or UDim2.new(0, 2, 0, 2)
		
		TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = goalBg}):Play()
		TweenService:Create(SwitchCircle, TweenInfo.new(0.2), {Position = goalPos}):Play()
		TText.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
		
		if callback then callback(state) end
	end)
	
	return TFrame
end

-- ============================================================
-- INPUT OLUŞTURUCU
-- ============================================================
local function createInput(parent, text, defaultText, callback)
	local IFrame = Instance.new("Frame")
	IFrame.Parent = parent
	IFrame.Size = UDim2.new(1, -10, 0, 52)
	IFrame.BackgroundColor3 = theme.bgLighter
	IFrame.BackgroundTransparency = 0.15
	IFrame.BorderSizePixel = 0
	Instance.new("UICorner", IFrame).CornerRadius = UDim.new(0, 8)
	table.insert(themeElements, {obj = IFrame, prop = "BackgroundColor3", key = "bgLighter"})
	
	local IStroke = Instance.new("UIStroke", IFrame)
	IStroke.Color = theme.border
	IStroke.Thickness = 1
	IStroke.Transparency = 0.4
	table.insert(themeElements, {obj = IStroke, prop = "Color", key = "border"})
	
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
	TextBox.BackgroundTransparency = 0.2
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.Font = Enum.Font.Gotham
	TextBox.TextSize = 11
	TextBox.Text = defaultText
	TextBox.ClearTextOnFocus = false
	TextBox.BorderSizePixel = 0
	Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
	
	local TBStroke = Instance.new("UIStroke", TextBox)
	TBStroke.Color = Color3.fromRGB(55, 55, 65)
	TBStroke.Thickness = 1
	TBStroke.Transparency = 0.5
	
	TextBox.FocusLost:Connect(function()
		if callback then callback(TextBox.Text) end
	end)
	
	return IFrame, TextBox
end

-- ============================================================
-- RENK PICKER
-- ============================================================
local function createColorPicker(parent, labelText, colorKey, defaultColor)
	local frame = Instance.new("Frame")
	frame.Parent = parent
	frame.Size = UDim2.new(1, -10, 0, 40)
	frame.BackgroundColor3 = theme.bgLighter
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	table.insert(themeElements, {obj = frame, prop = "BackgroundColor3", key = "bgLighter"})
	
	local fStroke = Instance.new("UIStroke", frame)
	fStroke.Color = theme.border
	fStroke.Thickness = 1
	fStroke.Transparency = 0.4
	table.insert(themeElements, {obj = fStroke, prop = "Color", key = "border"})
	
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local preview = Instance.new("Frame", frame)
	preview.Size = UDim2.new(0, 28, 0, 28)
	preview.Position = UDim2.new(1, -40, 0.5, -14)
	preview.BackgroundColor3 = defaultColor
	preview.BorderSizePixel = 0
	Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
	
	local previewStroke = Instance.new("UIStroke", preview)
	previewStroke.Color = Color3.fromRGB(255, 255, 255)
	previewStroke.Thickness = 1.5
	previewStroke.Transparency = 0.5
	
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	
	btn.MouseButton1Click:Connect(function()
		local colors = {
			Color3.fromRGB(12, 12, 16),
			Color3.fromRGB(30, 0, 45),
			Color3.fromRGB(45, 0, 0),
			Color3.fromRGB(0, 15, 35),
			Color3.fromRGB(0, 25, 10),
			Color3.fromRGB(35, 0, 20),
			Color3.fromRGB(25, 20, 0),
		}
		local current = preview.BackgroundColor3
		local nextIdx = 1
		for i, c in ipairs(colors) do
			if math.abs(c.R - current.R) < 0.01 and math.abs(c.G - current.G) < 0.01 and math.abs(c.B - current.B) < 0.01 then
				nextIdx = (i % #colors) + 1
				break
			end
		end
		local newColor = colors[nextIdx]
		preview.BackgroundColor3 = newColor
		theme[colorKey] = newColor
		applyTheme()
	end)
	
	return frame
end

-- ============================================================
-- PRESET BUTON
-- ============================================================
local function createPresetBtn(parent, text, presetData, xPos, yPos)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Size = UDim2.new(0.3, -6, 0, 32)
	btn.Position = UDim2.new(xPos, 0, 0, yPos)
	btn.BackgroundColor3 = presetData.bg
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local pStroke = Instance.new("UIStroke", btn)
	pStroke.Color = presetData.border
	pStroke.Thickness = 1.5
	pStroke.Transparency = 0.3
	
	btn.MouseButton1Click:Connect(function()
		theme.bg = presetData.bg
		theme.bgLight = presetData.bgLight
		theme.bgLighter = presetData.bgLighter
		theme.border = presetData.border
		theme.accent = presetData.accent
		applyTheme()
	end)
	
	return btn
end

-- ============================================================
-- ANA SAYFA ELEMANLARI
-- ============================================================
createToggle(MainContent, "AutoFarm", L("autoFarm"), function(state)
	autoFarmEnabled = state
	if state then
		startStabilization()
	else
		if not noclipEnabled then
			stopStabilization()
		end
	end
end)

createToggle(MainContent, "Underground", L("underground"), function(state)
	undergroundMode = state
end)

createToggle(MainContent, "AutoReset", L("autoReset"), function(state)
	autoResetEnabled = state
end)

local speedInputFrame, speedBox = createInput(MainContent, L("speed"), tostring(farmSpeed), function(val)
	local num = tonumber(val)
	if num then
		farmSpeed = math.clamp(num, 1, 50)
		speedBox.Text = tostring(farmSpeed)
	end
end)

local WarningLabel = Instance.new("TextLabel", MainContent)
WarningLabel.Size = UDim2.new(1, -10, 0, 16)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Font = Enum.Font.Gotham
WarningLabel.Text = "⚠️ " .. L("warning")
WarningLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
WarningLabel.TextSize = 10
WarningLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
-- DİĞER SAYFA ELEMANLARI
-- ============================================================
createToggle(MiscContent, "AntiAFK", L("antiAfk"), function(state)
	if state then
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/nahsqn/scripts/refs/heads/main/antiafk"))()
		end)
	end
end)

createToggle(MiscContent, "Noclip", L("noclip"), function(state)
	noclipEnabled = state
	if state then
		startStabilization()
		noclipConnection = RunService.Stepped:Connect(function()
			if getgenv().MM2FarmSession ~= mySession then return end
			local char = LocalPlayer.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		if not autoFarmEnabled then
			stopStabilization()
		end
	end
end)

createInput(MiscContent, L("webhookPlaceholder"), webhookURL, function(val)
	webhookURL = val
end)

local WebhookTimerLabel = Instance.new("TextLabel", MiscContent)
WebhookTimerLabel.Size = UDim2.new(1, -10, 0, 20)
WebhookTimerLabel.BackgroundTransparency = 1
WebhookTimerLabel.Font = Enum.Font.GothamBold
WebhookTimerLabel.Text = L("webhookTimer") .. "00:00"
WebhookTimerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
WebhookTimerLabel.TextSize = 11
WebhookTimerLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
-- TEMA SAYFA ELEMANLARI
-- ============================================================
local ThemeTitle = Instance.new("TextLabel", ThemeContent)
ThemeTitle.Size = UDim2.new(1, -10, 0, 20)
ThemeTitle.BackgroundTransparency = 1
ThemeTitle.Font = Enum.Font.GothamBold
ThemeTitle.Text = L("themeTitle")
ThemeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeTitle.TextSize = 13
ThemeTitle.TextXAlignment = Enum.TextXAlignment.Left

createColorPicker(ThemeContent, L("bgColor"), "bg", theme.bg)
createColorPicker(ThemeContent, L("borderColor"), "border", theme.border)
createColorPicker(ThemeContent, L("accentColor"), "accent", theme.accent)

local TransFrame = Instance.new("Frame", ThemeContent)
TransFrame.Size = UDim2.new(1, -10, 0, 40)
TransFrame.BackgroundColor3 = theme.bgLighter
TransFrame.BackgroundTransparency = 0.15
TransFrame.BorderSizePixel = 0
Instance.new("UICorner", TransFrame).CornerRadius = UDim.new(0, 8)
table.insert(themeElements, {obj = TransFrame, prop = "BackgroundColor3", key = "bgLighter"})

local TransStroke = Instance.new("UIStroke", TransFrame)
TransStroke.Color = theme.border
TransStroke.Thickness = 1
TransStroke.Transparency = 0.4
table.insert(themeElements, {obj = TransStroke, prop = "Color", key = "border"})

local TransLbl = Instance.new("TextLabel", TransFrame)
TransLbl.Size = UDim2.new(0.5, 0, 1, 0)
TransLbl.Position = UDim2.new(0, 12, 0, 0)
TransLbl.BackgroundTransparency = 1
TransLbl.Font = Enum.Font.GothamMedium
TransLbl.Text = L("transparency")
TransLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
TransLbl.TextSize = 12
TransLbl.TextXAlignment = Enum.TextXAlignment.Left

local TransVal = Instance.new("TextLabel", TransFrame)
TransVal.Size = UDim2.new(0, 40, 1, 0)
TransVal.Position = UDim2.new(1, -50, 0, 0)
TransVal.BackgroundTransparency = 1
TransVal.Font = Enum.Font.GothamBold
TransVal.Text = "25%"
TransVal.TextColor3 = Color3.fromRGB(255, 255, 255)
TransVal.TextSize = 11

local TransSlider = Instance.new("TextButton", TransFrame)
TransSlider.Size = UDim2.new(0, 80, 0, 6)
TransSlider.Position = UDim2.new(0.5, 10, 0.5, -3)
TransSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
TransSlider.BorderSizePixel = 0
TransSlider.Text = ""
Instance.new("UICorner", TransSlider).CornerRadius = UDim.new(1, 0)

local TransFill = Instance.new("Frame", TransSlider)
TransFill.Size = UDim2.new(0.25, 0, 1, 0)
TransFill.BackgroundColor3 = theme.accent
TransFill.BorderSizePixel = 0
Instance.new("UICorner", TransFill).CornerRadius = UDim.new(1, 0)

local TransKnob = Instance.new("Frame", TransSlider)
TransKnob.Size = UDim2.new(0, 12, 0, 12)
TransKnob.Position = UDim2.new(0.25, -6, 0.5, -6)
TransKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TransKnob.BorderSizePixel = 0
Instance.new("UICorner", TransKnob).CornerRadius = UDim.new(1, 0)

local draggingSlider = false
TransSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local pos = math.clamp((input.Position.X - TransSlider.AbsolutePosition.X) / TransSlider.AbsoluteSize.X, 0, 1)
		TransFill.Size = UDim2.new(pos, 0, 1, 0)
		TransKnob.Position = UDim2.new(pos, -6, 0.5, -6)
		theme.transparency = 1 - pos
		TransVal.Text = math.floor(pos * 100) .. "%"
		MainFrame.BackgroundTransparency = theme.transparency
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end)

local PresetTitle = Instance.new("TextLabel", ThemeContent)
PresetTitle.Size = UDim2.new(1, -10, 0, 20)
PresetTitle.BackgroundTransparency = 1
PresetTitle.Font = Enum.Font.GothamBold
PresetTitle.Text = L("presets")
PresetTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PresetTitle.TextSize = 12
PresetTitle.TextXAlignment = Enum.TextXAlignment.Left

local PresetGrid = Instance.new("Frame", ThemeContent)
PresetGrid.Size = UDim2.new(1, -10, 0, 80)
PresetGrid.BackgroundTransparency = 1
PresetGrid.BorderSizePixel = 0

local presets = {
	{L("presetDark"), {bg = Color3.fromRGB(12, 12, 16), bgLight = Color3.fromRGB(18, 18, 22), bgLighter = Color3.fromRGB(22, 22, 28), border = Color3.fromRGB(45, 45, 55), accent = Color3.fromRGB(70, 200, 100)}},
	{L("presetPurple"), {bg = Color3.fromRGB(25, 0, 40), bgLight = Color3.fromRGB(35, 0, 55), bgLighter = Color3.fromRGB(45, 0, 70), border = Color3.fromRGB(120, 50, 180), accent = Color3.fromRGB(180, 100, 255)}},
	{L("presetRed"), {bg = Color3.fromRGB(30, 0, 0), bgLight = Color3.fromRGB(45, 0, 0), bgLighter = Color3.fromRGB(55, 5, 5), border = Color3.fromRGB(150, 30, 30), accent = Color3.fromRGB(255, 60, 60)}},
	{L("presetBlue"), {bg = Color3.fromRGB(0, 10, 30), bgLight = Color3.fromRGB(0, 15, 45), bgLighter = Color3.fromRGB(5, 20, 55), border = Color3.fromRGB(30, 80, 150), accent = Color3.fromRGB(60, 150, 255)}},
	{L("presetGreen"), {bg = Color3.fromRGB(0, 20, 10), bgLight = Color3.fromRGB(0, 30, 15), bgLighter = Color3.fromRGB(5, 40, 20), border = Color3.fromRGB(30, 120, 60), accent = Color3.fromRGB(80, 220, 120)}},
	{L("presetPink"), {bg = Color3.fromRGB(30, 0, 20), bgLight = Color3.fromRGB(45, 0, 30), bgLighter = Color3.fromRGB(55, 5, 40), border = Color3.fromRGB(150, 50, 120), accent = Color3.fromRGB(255, 100, 180)}},
}

for i, preset in ipairs(presets) do
	local col = (i - 1) % 3
	local row = math.floor((i - 1) / 3)
	createPresetBtn(PresetGrid, preset[1], preset[2], col * 0.333 + (col > 0 and 0.02 or 0), row * 40)
end

-- ============================================================
-- ALT PROFİL ÇUBUĞU (SADECE KAFA GÖSTERİLİR)
-- ============================================================
local BottomBar = Instance.new("Frame", MainFrame)
BottomBar.Size = UDim2.new(1, 0, 0, 50)
BottomBar.Position = UDim2.new(0, 0, 1, -50)
BottomBar.BackgroundColor3 = theme.bgLight
BottomBar.BackgroundTransparency = 0.15
BottomBar.BorderSizePixel = 0
table.insert(themeElements, {obj = BottomBar, prop = "BackgroundColor3", key = "bgLight"})

Instance.new("UICorner", BottomBar).CornerRadius = UDim.new(0, 12)
local BottomFix = Instance.new("Frame", BottomBar)
BottomFix.Size = UDim2.new(1, 0, 0, 12)
BottomFix.Position = UDim2.new(0, 0, 0, 0)
BottomFix.BackgroundColor3 = theme.bgLight
BottomFix.BackgroundTransparency = 0.15
BottomFix.BorderSizePixel = 0
table.insert(themeElements, {obj = BottomFix, prop = "BackgroundColor3", key = "bgLight"})

local BottomStroke = Instance.new("UIStroke", BottomBar)
BottomStroke.Color = theme.border
BottomStroke.Thickness = 1
BottomStroke.Transparency = 0.4
table.insert(themeElements, {obj = BottomStroke, prop = "Color", key = "border"})

-- SADECE KAFA (HEADSHOT) GÖSTERİLİR
local ProfileIcon = Instance.new("ImageLabel", BottomBar)
ProfileIcon.BackgroundTransparency = 1
ProfileIcon.Size = UDim2.new(0, 36, 0, 36)
ProfileIcon.Position = UDim2.new(0, 10, 0.5, -18)
ProfileIcon.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..targetUserId.."&width=420&height=420&format=png"
Instance.new("UICorner", ProfileIcon).CornerRadius = UDim.new(1, 0)

local ProfileStroke = Instance.new("UIStroke", ProfileIcon)
ProfileStroke.Color = Color3.fromRGB(80, 80, 90)
ProfileStroke.Thickness = 1.5
ProfileStroke.Transparency = 0.3

local NameLabel = Instance.new("TextLabel", BottomBar)
NameLabel.BackgroundTransparency = 1
NameLabel.Position = UDim2.new(0, 54, 0, 6)
NameLabel.Size = UDim2.new(0, 150, 0, 18)
NameLabel.Font = Enum.Font.GothamBold
NameLabel.Text = targetUserName
NameLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
NameLabel.TextSize = 12
NameLabel.TextXAlignment = Enum.TextXAlignment.Left

local CoinLabel = Instance.new("TextLabel", BottomBar)
CoinLabel.BackgroundTransparency = 1
CoinLabel.Position = UDim2.new(0, 54, 0, 24)
CoinLabel.Size = UDim2.new(0, 120, 0, 16)
CoinLabel.Font = Enum.Font.GothamBold
CoinLabel.Text = L("coin") .. "0"
CoinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
CoinLabel.TextSize = 11
CoinLabel.TextXAlignment = Enum.TextXAlignment.Left

local TimeLabel = Instance.new("TextLabel", BottomBar)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Position = UDim2.new(1, -130, 0, 6)
TimeLabel.Size = UDim2.new(0, 120, 0, 18)
TimeLabel.Font = Enum.Font.GothamBold
TimeLabel.Text = "00:00:00"
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
TimeLabel.TextSize = 12
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right

local LangStatus = Instance.new("TextLabel", BottomBar)
LangStatus.BackgroundTransparency = 1
LangStatus.Position = UDim2.new(1, -130, 0, 24)
LangStatus.Size = UDim2.new(0, 120, 0, 16)
LangStatus.Font = Enum.Font.Gotham
LangStatus.Text = L("langStatus")
LangStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
LangStatus.TextSize = 10
LangStatus.TextXAlignment = Enum.TextXAlignment.Right

-- ============================================================
-- SÜRE & WEBHOOK SAYAÇ DÖNGÜLERİ
-- ============================================================
task.spawn(function()
	while task.wait(1) do
		if getgenv().MM2FarmSession ~= mySession then break end
		local diff = os.difftime(os.time(), startTime)
		local h = math.floor(diff / 3600)
		local m = math.floor((diff % 3600) / 60)
		local s = diff % 60
		TimeLabel.Text = string.format("%02d:%02d:%02d", h, m, s)
		CoinLabel.Text = L("coin") .. tostring(totalCoins)
		
		local elapsed = os.time() - lastWebhook
		local remaining = math.max(0, webhookCooldown - elapsed)
		local mins = math.floor(remaining / 60)
		local secs = remaining % 60
		WebhookTimerLabel.Text = L("webhookTimer") .. string.format("%02d:%02d", mins, secs)
	end
end)

-- ============================================================
-- SÜRÜKLEME
-- ============================================================
local dragging = false
local dragStart, startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ============================================================
-- OYUN MEKANİKLERİ & FARM MANTIĞI
-- ============================================================
local collectedCoins = {}
local COIN_COOLDOWN = 3
local isDead = false
local roundActive = false

local function isCoinValid(coin)
	if getgenv().MM2FarmSession ~= mySession then return false end
	if not coin or not coin.Parent then return false end
	if not coin:FindFirstChild("TouchInterest") then return false end
	if collectedCoins[coin] then
		if tick() - collectedCoins[coin] < COIN_COOLDOWN then
			return false
		else
			collectedCoins[coin] = nil
		end
	end
	return true
end

local function get_nearest_coin()
	local hrp = getHRP()
	if not hrp then return nil, math.huge end
	local closest, dist = nil, math.huge
	for _, m in pairs(workspace:GetChildren()) do
		if getgenv().MM2FarmSession ~= mySession then return nil, math.huge end
		if m:FindFirstChild("CoinContainer") then
			for _, coin in pairs(m.CoinContainer:GetChildren()) do
				if coin:IsA("BasePart") and isCoinValid(coin) then
					local d = (hrp.Position - coin.Position).Magnitude
					if d < dist then
						closest, dist = coin, d
					end
				end
			end
		end
	end
	return closest, dist
end

local function sendEnhancedWebhook()
	if webhookURL == "" or not webhookURL:find("discord") then return end
	local diff = os.difftime(os.time(), startTime)
	local h = math.floor(diff / 3600)
	local m = math.floor((diff % 3600) / 60)
	local s = diff % 60
	local perHour = (diff > 0) and math.floor((totalCoins / (diff / 3600))) or 0
	local characterImg = "https://www.roblox.com/avatar-thumbnail/image?userId="..targetUserId.."&width=420&height=420&format=png"
	
	local data = {
		["username"] = "MM2 Farm Hub",
		["avatar_url"] = characterImg,
		["embeds"] = {{
			["title"] = "🚀 MM2 Farm Raporu (VOİD Hub)",
			["description"] = "**Durum / Status:** Farm Devam Ediyor / Running...",
			["color"] = 14513407,
			["thumbnail"] = {["url"] = characterImg},
			["fields"] = {
				{["name"] = "👤 Oyuncu / Player", ["value"] = "```" .. targetUserName .. "```", ["inline"] = true},
				{["name"] = "⏳ Süre / Time", ["value"] = "```" .. string.format("%02d:%02d:%02d", h, m, s) .. "```", ["inline"] = true},
				{["name"] = "🪙 Coin", ["value"] = "```" .. totalCoins .. "```", ["inline"] = true},
				{["name"] = "📈 Hız / Speed", ["value"] = "```" .. perHour .. " / Saat-Hour```", ["inline"] = true}
			},
			["footer"] = { ["text"] = "MM2 Farm Hub - Auto Language Support", ["icon_url"] = characterImg }
		}}
	}
	
	local request = (syn and syn.request) or (http and http.request) or http_request or request
	pcall(function()
		if request then
			request({
				Url = webhookURL,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode(data)
			})
		end
	end)
	lastWebhook = os.time()
end

local RoundStart = ReplicatedStorage.Remotes.Gameplay.RoundStart
local RoundEnd = ReplicatedStorage.Remotes.Gameplay.RoundEndFade
local CoinCollected = ReplicatedStorage.Remotes.Gameplay.CoinCollected

RoundStart.OnClientEvent:Connect(function()
	if getgenv().MM2FarmSession ~= mySession then return end
	roundActive = true
	isDead = false
	bag_full = false
	farming = true
	collectedCoins = {}
	local hrp = getHRP()
	if hrp then start_position = hrp.CFrame end
end)

RoundEnd.OnClientEvent:Connect(function()
	if getgenv().MM2FarmSession ~= mySession then return end
	roundActive = false
	farming = false
	local hrp = getHRP()
	if start_position and hrp then hrp.CFrame = start_position end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
	if getgenv().MM2FarmSession ~= mySession then return end
	isDead = false
	farming = false
	bag_full = false
	local hum = newChar:WaitForChild("Humanoid", 3)
	if hum then
		hum.Died:Connect(function()
			isDead = true
			farming = false
			bag_full = false
		end)
	end
end)

CoinCollected.OnClientEvent:Connect(function(_, current, max)
	if getgenv().MM2FarmSession ~= mySession then return end
	totalCoins = totalCoins + 1
	
	if current >= max then
		bag_full = true
		farming = false
		sendEnhancedWebhook()
	end

	if current == max and not resetting and autoResetEnabled then
		resetting = true
		bag_full = true
		farming = false
		local hrp = getHRP()
		if start_position and hrp then
			local tween = TweenService:Create(hrp, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = start_position})
			tween:Play()
			tween.Completed:Wait()
		end
		task.wait(0.2)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
			LocalPlayer.Character.Humanoid.Health = 0
		end
		task.wait(1)
		resetting = false
		bag_full = false
	end
end)

local function tweenTo(hrp, targetPos)
	if getgenv().MM2FarmSession ~= mySession or not hrp or not hrp.Parent or bag_full or not roundActive then return false end
	
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Velocity = Vector3.zero
	hrp.RotVelocity = Vector3.zero
	
	local distance = (hrp.Position - targetPos).Magnitude
	local duration = distance / farmSpeed
	if duration < 0.03 then duration = 0.03 end
	
	local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
	tween:Play()
	
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
