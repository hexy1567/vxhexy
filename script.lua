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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- OYUN DURUMU & COIN ARAMA (Lobi Kontrolü)
-- ============================================================
local function getActiveCoinContainer()
	-- MM2'de aktif haritadaki CoinContainer nesnesini bulur
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
	task.wait(
