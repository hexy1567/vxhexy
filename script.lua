if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- // Benzersiz Oturum
local environment = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then environment = result end
end
environment.MM2FarmSession = tick()
local mySession = environment.MM2FarmSession

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

-- // GUI kökü: Executor destekliyorsa gethui, değilse PlayerGui/CoreGui kullan.
local GuiRoot = nil
if type(gethui) == "function" then
    local ok, root = pcall(gethui)
    if ok and root then GuiRoot = root end
end
if not GuiRoot then
    local ok, playerGui = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 5) end)
    if ok and playerGui then GuiRoot = playerGui end
end
if not GuiRoot then GuiRoot = CoreGui end

-- // HEXY AutoSave: ayarlar executor destekliyorsa dosyaya kaydedilir.
local CONFIG_FILE = "HEXY_MM2_Settings.json"
local savedSettings = {}
if readfile and isfile then
    pcall(function()
        if isfile(CONFIG_FILE) then
            savedSettings = HttpService:JSONDecode(readfile(CONFIG_FILE)) or {}
        end
    end)
end
local function saveSettings()
    if writefile then
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(savedSettings)) end)
    end
end

-- // Eski GUI Temizliği
for _, root in ipairs({GuiRoot, CoreGui}) do
    for _, name in ipairs({"MM2FarmUI", "HexyMM2_UI", "HexyIntroGui"}) do
        local old = root and root:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end
end
local playerGuiForCleanup = LocalPlayer:FindFirstChild("PlayerGui")
if playerGuiForCleanup then
    local old = playerGuiForCleanup:FindFirstChild("CustomUI")
    if old then old:Destroy() end
end

-- Erken başlatılan GUI: kodun ilerleyen bölümlerinde hata olsa bile H düğmesi oluşur.
local MainFrame = nil
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2FarmUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10000
local guiParentOk = pcall(function() ScreenGui.Parent = GuiRoot end)
if not guiParentOk then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "HEXY_MenuToggle"
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.fromOffset(48, 48)
ToggleButton.Position = UDim2.new(0, 16, 0.5, -24)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
ToggleButton.BackgroundTransparency = 0.08
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "H"
ToggleButton.TextColor3 = Color3.fromRGB(70, 200, 100)
ToggleButton.Font = Enum.Font.GothamBlack
ToggleButton.TextSize = 21
ToggleButton.AutoButtonColor = true
ToggleButton.ZIndex = 5000
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(80, 80, 90)
ToggleStroke.Thickness = 1.5
ToggleButton.Activated:Connect(function()
    if MainFrame and MainFrame.Parent then
        MainFrame.Visible = not MainFrame.Visible
    else
        ToggleButton.Text = "..."
    end
end)

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
