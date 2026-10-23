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
for _, name in ipairs({"MM2FarmUI", "HexyMM2_UI", "HexyIntroGui", "HexyMM2_UI", "HexyIntroGui"}) do
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
		webhookTimer = "Time: ",
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

-- // İstatistik & Config
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

local IntroGlow = Instance.new("TextLabel", IntroFrame)
IntroGlow.Size = UDim2.new(1, 0, 1, 0)
IntroGlow.BackgroundTransparency = 1
IntroGlow.Font = Enum.Font.GothamBlack
IntroGlow.Text = "HEXY"
IntroGlow.TextColor3 = Color3.fromRGB(70, 200, 100)
IntroGlow.TextSize
