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
		title = "HEXY | MM2 Farm",
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
		title = "HEXY | MM2 Farm",
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
local webhookURL = ""
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
-- KARAKTER KONTROL SİSTEMİ (Havada Asılı Kalma Düzeltildi)
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
-- AÇILIŞ ANİMASYONU — TÜM EKRANI KAPSAR
-- ============================================================
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "HexyIntroGui"
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
IntroText.Text = "HEXY"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.TextSize = 72
IntroText.TextTransparency = 1
IntroText.ZIndex = 101

local IntroGlow = Instance.new("TextLabel", IntroFrame)
IntroGlow.Size = UDim2.new(1, 0, 1, 0)
IntroGlow.BackgroundTransparency = 1
IntroGlow.Font = Enum.Font.GothamBlack
IntroGlow.Text = "HEXY"
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

local MainTabBtn = createTabBtn("Farm", L("
