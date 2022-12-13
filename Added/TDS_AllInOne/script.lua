if game.placeId == 5591597781 then
	local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
	local Window = OrionLib:MakeWindow({Name = "💥 TDS In-Game💥, by Godku#5459", HidePremium = true, IntroText = "Mid TDS", SaveConfig = false , ConfigFolder = "none"})
		
	local Players = game:GetService("Players")
	local connections = getconnections or get_signal_cons
	if connections then
		for i,v in pairs(connections(Players.LocalPlayer.Idled)) do
			if v["Disable"] then
				v["Disable"](v)
			elseif v["Disconnect"] then
				v["Disconnect"](v)
			end
		end
	else
		Players.LocalPlayer.Idled:Connect(function()
			local VirtualUser = game:GetService("VirtualUser")
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
		
		local Tab = Window:MakeTab({
			Name = "Utility",
			Icon = "",
			PremiumOnly = false
		})
		
		Tab:AddButton({
			Name = "Auto Chain",
			Callback = function()
				loadstring(game:HttpGet("https://banbus.cf/scripts/tdsautochain"))()
			  end    
		})
		
		Tab:AddButton({
			Name = "Auto Skip",
			Callback = function()
				local Prop = game.ReplicatedStorage.State.Voting.Enabled
				Prop:GetPropertyChangedSignal("Value"):Connect(function()
					if Prop.Value then
						game.ReplicatedStorage.RemoteEvent:FireServer("Waves","Skip")
					end
				end)
			  end    
		})
	
	
		Tab:AddButton({
			Name = "Skip With KeyBind (Press E)",
			Callback = function()
				game:GetService("UserInputService").InputBegan:Connect(function(input, chatting)
					if input.KeyCode == Enum.KeyCode.E and not chatting then
					game.ReplicatedStorage.RemoteEvent:FireServer("Waves","Skip")
					end
					end)
			  end    
		})
		
		Tab:AddButton({
			Name = "Auto Medic",
			Callback = function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/TacoCatBackWardsIsTacoCat/scripts/main/Auto%20Medic%20Ability.lua",true))()
			  end    
		})
	
	
		Tab:AddButton({
			Name = "Free Cam (Shift + P)",
			Callback = function()
					  --!nonstrict
	------------------------------------------------------------------------
	-- Freecam
	-- Cinematic free camera for spectating and video production.
	------------------------------------------------------------------------
	
	local pi    = math.pi
	local abs   = math.abs
	local clamp = math.clamp
	local exp   = math.exp
	local rad   = math.rad
	local sign  = math.sign
	local sqrt  = math.sqrt
	local tan   = math.tan
	
	local ContextActionService = game:GetService("ContextActionService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local StarterGui = game:GetService("StarterGui")
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")
	local Settings = UserSettings()
	local GameSettings = Settings.GameSettings
	
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		LocalPlayer = Players.LocalPlayer
	end
	
	local Camera = Workspace.CurrentCamera
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCamera = Workspace.CurrentCamera
		if newCamera then
			Camera = newCamera
		end
	end)
	
	local FFlagUserExitFreecamBreaksWithShiftlock
	do
		local success, result = pcall(function()
			return UserSettings():IsUserFeatureEnabled("UserExitFreecamBreaksWithShiftlock")
		end)
		FFlagUserExitFreecamBreaksWithShiftlock = success and result
	end
	 
	------------------------------------------------------------------------
	
	local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
	local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
	local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
	
	local NAV_GAIN = Vector3.new(1, 1, 1)*64
	local PAN_GAIN = Vector2.new(0.75, 1)*8
	local FOV_GAIN = 300
	
	local PITCH_LIMIT = rad(90)
	
	local VEL_STIFFNESS = 1.5
	local PAN_STIFFNESS = 1.0
	local FOV_STIFFNESS = 4.0
	
	------------------------------------------------------------------------
	
	local Spring = {} do
		Spring.__index = Spring
	
		function Spring.new(freq, pos)
			local self = setmetatable({}, Spring)
			self.f = freq
			self.p = pos
			self.v = pos*0
			return self
		end
	
		function Spring:Update(dt, goal)
			local f = self.f*2*pi
			local p0 = self.p
			local v0 = self.v
	
			local offset = goal - p0
			local decay = exp(-f*dt)
	
			local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
			local v1 = (f*dt*(offset*f - v0) + v0)*decay
	
			self.p = p1
			self.v = v1
	
			return p1
		end
	
		function Spring:Reset(pos)
			self.p = pos
			self.v = pos*0
		end
	end
	
	------------------------------------------------------------------------
	
	local cameraPos = Vector3.new()
	local cameraRot = Vector2.new()
	local cameraFov = 0
	
	local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
	local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
	local fovSpring = Spring.new(FOV_STIFFNESS, 0)
	
	------------------------------------------------------------------------
	
	local Input = {} do
		local thumbstickCurve do
			local K_CURVATURE = 2.0
			local K_DEADZONE = 0.15
	
			local function fCurve(x)
				return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
			end
	
			local function fDeadzone(x)
				return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
			end
	
			function thumbstickCurve(x)
				return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
			end
		end
	
		local gamepad = {
			ButtonX = 0,
			ButtonY = 0,
			DPadDown = 0,
			DPadUp = 0,
			ButtonL2 = 0,
			ButtonR2 = 0,
			Thumbstick1 = Vector2.new(),
			Thumbstick2 = Vector2.new(),
		}
	
		local keyboard = {
			W = 0,
			A = 0,
			S = 0,
			D = 0,
			E = 0,
			Q = 0,
			U = 0,
			H = 0,
			J = 0,
			K = 0,
			I = 0,
			Y = 0,
			Up = 0,
			Down = 0,
			LeftShift = 0,
			RightShift = 0,
		}
	
		local mouse = {
			Delta = Vector2.new(),
			MouseWheel = 0,
		}
	
		local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
		local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
		local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
		local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
		local FOV_WHEEL_SPEED    = 1.0
		local FOV_GAMEPAD_SPEED  = 0.25
		local NAV_ADJ_SPEED      = 0.75
		local NAV_SHIFT_MUL      = 0.25
	
		local navSpeed = 1
	
		function Input.Vel(dt)
			navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)
	
			local kGamepad = Vector3.new(
				thumbstickCurve(gamepad.Thumbstick1.X),
				thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
				thumbstickCurve(-gamepad.Thumbstick1.Y)
			)*NAV_GAMEPAD_SPEED
	
			local kKeyboard = Vector3.new(
				keyboard.D - keyboard.A + keyboard.K - keyboard.H,
				keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
				keyboard.S - keyboard.W + keyboard.J - keyboard.U
			)*NAV_KEYBOARD_SPEED
	
			local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	
			return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
		end
	
		function Input.Pan(dt)
			local kGamepad = Vector2.new(
				thumbstickCurve(gamepad.Thumbstick2.Y),
				thumbstickCurve(-gamepad.Thumbstick2.X)
			)*PAN_GAMEPAD_SPEED
			local kMouse = mouse.Delta*PAN_MOUSE_SPEED
			mouse.Delta = Vector2.new()
			return kGamepad + kMouse
		end
	
		function Input.Fov(dt)
			local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
			local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
			mouse.MouseWheel = 0
			return kGamepad + kMouse
		end
	
		do
			local function Keypress(action, state, input)
				keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
				return Enum.ContextActionResult.Sink
			end
	
			local function GpButton(action, state, input)
				gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
				return Enum.ContextActionResult.Sink
			end
	
			local function MousePan(action, state, input)
				local delta = input.Delta
				mouse.Delta = Vector2.new(-delta.y, -delta.x)
				return Enum.ContextActionResult.Sink
			end
	
			local function Thumb(action, state, input)
				gamepad[input.KeyCode.Name] = input.Position
				return Enum.ContextActionResult.Sink
			end
	
			local function Trigger(action, state, input)
				gamepad[input.KeyCode.Name] = input.Position.z
				return Enum.ContextActionResult.Sink
			end
	
			local function MouseWheel(action, state, input)
				mouse[input.UserInputType.Name] = -input.Position.z
				return Enum.ContextActionResult.Sink
			end
	
			local function Zero(t)
				for k, v in pairs(t) do
					t[k] = v*0
				end
			end
	
			function Input.StartCapture()
				ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
					Enum.KeyCode.W, Enum.KeyCode.U,
					Enum.KeyCode.A, Enum.KeyCode.H,
					Enum.KeyCode.S, Enum.KeyCode.J,
					Enum.KeyCode.D, Enum.KeyCode.K,
					Enum.KeyCode.E, Enum.KeyCode.I,
					Enum.KeyCode.Q, Enum.KeyCode.Y,
					Enum.KeyCode.Up, Enum.KeyCode.Down
				)
				ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
				ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
				ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
				ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
				ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
			end
	
			function Input.StopCapture()
				navSpeed = 1
				Zero(gamepad)
				Zero(keyboard)
				Zero(mouse)
				ContextActionService:UnbindAction("FreecamKeyboard")
				ContextActionService:UnbindAction("FreecamMousePan")
				ContextActionService:UnbindAction("FreecamMouseWheel")
				ContextActionService:UnbindAction("FreecamGamepadButton")
				ContextActionService:UnbindAction("FreecamGamepadTrigger")
				ContextActionService:UnbindAction("FreecamGamepadThumbstick")
			end
		end
	end
	
	local function GetFocusDistance(cameraFrame)
		local znear = 0.1
		local viewport = Camera.ViewportSize
		local projy = 2*tan(cameraFov/2)
		local projx = viewport.x/viewport.y*projy
		local fx = cameraFrame.rightVector
		local fy = cameraFrame.upVector
		local fz = cameraFrame.lookVector
	
		local minVect = Vector3.new()
		local minDist = 512
	
		for x = 0, 1, 0.5 do
			for y = 0, 1, 0.5 do
				local cx = (x - 0.5)*projx
				local cy = (y - 0.5)*projy
				local offset = fx*cx - fy*cy + fz
				local origin = cameraFrame.p + offset*znear
				local _, hit = Workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
				local dist = (hit - origin).magnitude
				if minDist > dist then
					minDist = dist
					minVect = offset.unit
				end
			end
		end
	
		return fz:Dot(minVect)*minDist
	end
	
	------------------------------------------------------------------------
	
	local function StepFreecam(dt)
		local vel = velSpring:Update(dt, Input.Vel(dt))
		local pan = panSpring:Update(dt, Input.Pan(dt))
		local fov = fovSpring:Update(dt, Input.Fov(dt))
	
		local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))
	
		cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
		cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
		cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))
	
		local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
		cameraPos = cameraCFrame.p
	
		Camera.CFrame = cameraCFrame
		Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
		Camera.FieldOfView = cameraFov
	end
	
	local function CheckMouseLockAvailability()
		local devAllowsMouseLock = Players.LocalPlayer.DevEnableMouseLock
		local devMovementModeIsScriptable = Players.LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
		local userHasMouseLockModeEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
		local userHasClickToMoveEnabled =  GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
		local MouseLockAvailable = devAllowsMouseLock and userHasMouseLockModeEnabled and not userHasClickToMoveEnabled and not devMovementModeIsScriptable
	
		return MouseLockAvailable
	end
	
	------------------------------------------------------------------------
	
	local PlayerState = {} do
		local mouseBehavior
		local mouseIconEnabled
		local cameraType
		local cameraFocus
		local cameraCFrame
		local cameraFieldOfView
		local screenGuis = {}
		local coreGuis = {
			Backpack = true,
			Chat = true,
			Health = true,
			PlayerList = true,
		}
		local setCores = {
			BadgesNotificationsActive = true,
			PointsNotificationsActive = true,
		}
	
		-- Save state and set up for freecam
		function PlayerState.Push()
			for name in pairs(coreGuis) do
				coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
			end
			for name in pairs(setCores) do
				setCores[name] = StarterGui:GetCore(name)
				StarterGui:SetCore(name, false)
			end
			local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if playergui then
				for _, gui in pairs(playergui:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Enabled then
						screenGuis[#screenGuis + 1] = gui
						gui.Enabled = false
					end
				end
			end
	
			cameraFieldOfView = Camera.FieldOfView
			Camera.FieldOfView = 70
	
			cameraType = Camera.CameraType
			Camera.CameraType = Enum.CameraType.Custom
	
			cameraCFrame = Camera.CFrame
			cameraFocus = Camera.Focus
	
			mouseIconEnabled = UserInputService.MouseIconEnabled
			UserInputService.MouseIconEnabled = false
	
			if FFlagUserExitFreecamBreaksWithShiftlock and CheckMouseLockAvailability() then
				mouseBehavior = Enum.MouseBehavior.Default
			else
				mouseBehavior = UserInputService.MouseBehavior
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	
		-- Restore state
		function PlayerState.Pop()
			for name, isEnabled in pairs(coreGuis) do
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
			end
			for name, isEnabled in pairs(setCores) do
				StarterGui:SetCore(name, isEnabled)
			end
			for _, gui in pairs(screenGuis) do
				if gui.Parent then
					gui.Enabled = true
				end
			end
	
			Camera.FieldOfView = cameraFieldOfView
			cameraFieldOfView = nil
	
			Camera.CameraType = cameraType
			cameraType = nil
	
			Camera.CFrame = cameraCFrame
			cameraCFrame = nil
	
			Camera.Focus = cameraFocus
			cameraFocus = nil
	
			UserInputService.MouseIconEnabled = mouseIconEnabled
			mouseIconEnabled = nil
	
			UserInputService.MouseBehavior = mouseBehavior
			mouseBehavior = nil
		end
	end
	
	local function StartFreecam()
		local cameraCFrame = Camera.CFrame
		cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
		cameraPos = cameraCFrame.p
		cameraFov = Camera.FieldOfView
	
		velSpring:Reset(Vector3.new())
		panSpring:Reset(Vector2.new())
		fovSpring:Reset(0)
	
		PlayerState.Push()
		RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
		Input.StartCapture()
	end
	
	local function StopFreecam()
		Input.StopCapture()
		RunService:UnbindFromRenderStep("Freecam")
		PlayerState.Pop()
	end
	
	------------------------------------------------------------------------
	
	do
		local enabled = false
	
		local function ToggleFreecam()
			if enabled then
				StopFreecam()
			else
				StartFreecam()
			end
			enabled = not enabled
		end
	
		local function CheckMacro(macro)
			for i = 1, #macro - 1 do
				if not UserInputService:IsKeyDown(macro[i]) then
					return
				end
			end
			ToggleFreecam()
		end
	
		local function HandleActivationInput(action, state, input)
			if state == Enum.UserInputState.Begin then
				if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
					CheckMacro(FREECAM_MACRO_KB)
				end
			end
			return Enum.ContextActionResult.Pass
		end
	
		ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
	end
			  end    
		})
	
		Tab:AddButton({
			Name = "Sell Farm Wave 40",
			Callback = function()
				if not game:IsLoaded() then game.Loaded:Wait() end
				if game.PlaceId ~= 5591597781 then return end
				local rf, id, StateReplicatorPath = game.ReplicatedStorage.RemoteFunction, game.Players.LocalPlayer.UserId
				for i,v in pairs(game.ReplicatedStorage.StateReplicators:GetChildren()) do
					if v:GetAttribute("Wave") then
						StateReplicatorPath = v
						break
					end
				end
				StateReplicatorPath:GetAttributeChangedSignal("Wave"):Wait()
				local FinalWaveAtDifferentMode = {["Easy"] = 30, ["Normal"] = 40, ["Insane"] = 40, ["Hardcore"] = 50}
				local FinalWave = FinalWaveAtDifferentMode[game.ReplicatedStorage.State.Difficulty.Value]
				StateReplicatorPath:GetAttributeChangedSignal("Wave"):Connect(function()
					if StateReplicatorPath:GetAttribute("Wave") == FinalWave then
						for i,v in ipairs(workspace.Towers:GetChildren()) do
							if v.Owner.Value == id and v.Replicator:GetAttribute("Type") == "Farm" then
								spawn(function()
									rf:InvokeServer("Troops","Sell",{["Troop"] = v})
								end)
							end
						end
					end
				end)
			  end    
		})
	
		Tab:AddButton({
			Name = "Potato PC",
			Callback = function()
				workspace:FindFirstChildOfClass('Terrain').WaterWaveSize = 0
				workspace:FindFirstChildOfClass('Terrain').WaterWaveSpeed = 0
				workspace:FindFirstChildOfClass('Terrain').WaterReflectance = 0
				workspace:FindFirstChildOfClass('Terrain').WaterTransparency = 0
				game:GetService("Lighting").GlobalShadows = false
				game:GetService("Lighting").FogEnd = 9e9
				settings().Rendering.QualityLevel = 1
				for i,v in pairs(game:GetDescendants()) do
					if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
						v.Material = "Plastic"
						v.Reflectance = 0
					elseif v:IsA("Decal") then
						v.Transparency = 1
					elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
						v.Lifetime = NumberRange.new(0)
					elseif v:IsA("Explosion") then
						v.BlastPressure = 1
						v.BlastRadius = 1
					end
				end
			  end    
		})
	
		Tab:AddButton({
			Name = "Auto Stack",
			Callback = function()
				local times = 1
				local event = game:GetService("ReplicatedStorage").RemoteFunction
				local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/banbuskox/dfhtyxvzexrxgfdzgzfdvfdz/main/jsdnfjdsfdjnsmvkjhlkslzLIB", true))()
				local w = library:CreateWindow("Auto Stack V3")
				local h = 8
				local Mouse = game.Players.LocalPlayer:GetMouse()
				w:Section("Stacking")
				local Toggle = w:Toggle('Stacking Enabled', {flag = "toggle1"})
				w:Slider("Amount",
					{
						precise = false,
						default = 1,
						min = 1,
						max = 15,
					},
				function(v)
					times = v
				end)
				w:Slider("Height",
					{
						precise = false,
						default = 8,
						min = 8,
						max = 150,
					},
				function(v)
					h = v
				end)
				w:Button('Upgrade All', function()
				for i,v in pairs(game.Workspace.Towers:GetChildren()) do
					if v:WaitForChild("Owner").Value == game.Players.LocalPlayer.UserId then
						event:InvokeServer("Troops","Upgrade","Set",{["Troop"] = v})
						wait()
					end
				end
				end)
				w:Section('DANGER ZONE')
				w:Button('Sell All', function()
					for i,v in pairs(game.Workspace.Towers:GetChildren()) do
						if v:WaitForChild("Owner").Value == game.Players.LocalPlayer.UserId then
							event:InvokeServer("Troops","Sell",{["Troop"] = v})
							wait()
						end
					end
				end)
				
				local OldNamecall
				OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
					local Args = {...}
					local NamecallMethod = getnamecallmethod()
					if w.flags.toggle1 and #Args == 4 and NamecallMethod == "InvokeServer" and Self == event and Args[1] == "Troops" and Args[2] == "Place" then
						spawn(function()
							for i = 1, times do
								event:InvokeServer(Args[1], Args[2], Args[3], {Rotation = CFrame.new(0,h,0),Position = Args[4]['Position']}, true)
								wait(.2)
							end
						end)
						return nil
					end
					return OldNamecall(Self, ...)
				end)
			  end    
		})
	
		local Tab = Window:MakeTab({
			Name = "Visual",
			Icon = "",
			PremiumOnly = false
		})
	
		Tab:AddButton({
			Name = "See Other Cash",
			Callback = function()
				local CollectionService = game:GetService("CollectionService")
				local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/banbuskox/dfhtyxvzexrxgfdzgzfdvfdz/main/jsdnfjdsfdjnsmvkjhlkslzLIB", true))()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/banbuskox/dfhtyxvzexrxgfdzgzfdvfdz/main/sjkdkjlfdjnnmklcvxjNotifCr"))()
				local w = lib:CreateWindow("Players Cash")
				local ToUpdate = {}
				local Players = {}
				for i,v in pairs(game:GetService("ReplicatedStorage").StateReplicators:GetChildren()) do
					if CollectionService:HasTag(v, "Player") and v:GetAttribute("Cash") ~= 0 then
						w:Section(v:GetAttribute("Name").." : "..v:GetAttribute("Cash"))
						for _,c in pairs(game.CoreGui:GetDescendants()) do
							if c:IsA("TextLabel") and string.find(c.Text, v:GetAttribute("Cash")) then
								ToUpdate[v:GetAttribute("Name")] = c
								Players[v:GetAttribute("Name")] = v
							end
						end
					end
				end
				say("SUCCESS","Loaded - Made By Money Maker")
				while wait(.3) do
					for i,v in next,ToUpdate do
						v.Text = i.." : "..Players[i]:GetAttribute("Cash")
					end
				end
			  end    
		})
	
	
	elseif game.placeId == 3260590327 then
	
			local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
			local Window = OrionLib:MakeWindow({Name = "💥 TDS Lobby 💥, by Godku#5459", HidePremium = true, IntroText = "Mid TDS", SaveConfig = false , ConfigFolder = "none"})
	
			local Tab = Window:MakeTab({
				Name = "Utility",
				Icon = "",
				PremiumOnly = false
			})
	
	
			local Players = game:GetService("Players")
			local connections = getconnections or get_signal_cons
			if connections then
				for i,v in pairs(connections(Players.LocalPlayer.Idled)) do
					if v["Disable"] then
						v["Disable"](v)
					elseif v["Disconnect"] then
						v["Disconnect"](v)
					end
				end
			else
				Players.LocalPlayer.Idled:Connect(function()
					local VirtualUser = game:GetService("VirtualUser")
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end
	
	
			Tab:AddButton({
				Name = "Free Cam (Shift + P)",
				Callback = function()
						  --!nonstrict
		------------------------------------------------------------------------
		-- Freecam
		-- Cinematic free camera for spectating and video production.
		------------------------------------------------------------------------
		
		local pi    = math.pi
		local abs   = math.abs
		local clamp = math.clamp
		local exp   = math.exp
		local rad   = math.rad
		local sign  = math.sign
		local sqrt  = math.sqrt
		local tan   = math.tan
		
		local ContextActionService = game:GetService("ContextActionService")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local StarterGui = game:GetService("StarterGui")
		local UserInputService = game:GetService("UserInputService")
		local Workspace = game:GetService("Workspace")
		local Settings = UserSettings()
		local GameSettings = Settings.GameSettings
		
		local LocalPlayer = Players.LocalPlayer
		if not LocalPlayer then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			LocalPlayer = Players.LocalPlayer
		end
		
		local Camera = Workspace.CurrentCamera
		Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			local newCamera = Workspace.CurrentCamera
			if newCamera then
				Camera = newCamera
			end
		end)
		
		local FFlagUserExitFreecamBreaksWithShiftlock
		do
			local success, result = pcall(function()
				return UserSettings():IsUserFeatureEnabled("UserExitFreecamBreaksWithShiftlock")
			end)
			FFlagUserExitFreecamBreaksWithShiftlock = success and result
		end
		 
		------------------------------------------------------------------------
		
		local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
		local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
		local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
		
		local NAV_GAIN = Vector3.new(1, 1, 1)*64
		local PAN_GAIN = Vector2.new(0.75, 1)*8
		local FOV_GAIN = 300
		
		local PITCH_LIMIT = rad(90)
		
		local VEL_STIFFNESS = 1.5
		local PAN_STIFFNESS = 1.0
		local FOV_STIFFNESS = 4.0
		
		------------------------------------------------------------------------
		
		local Spring = {} do
			Spring.__index = Spring
		
			function Spring.new(freq, pos)
				local self = setmetatable({}, Spring)
				self.f = freq
				self.p = pos
				self.v = pos*0
				return self
			end
		
			function Spring:Update(dt, goal)
				local f = self.f*2*pi
				local p0 = self.p
				local v0 = self.v
		
				local offset = goal - p0
				local decay = exp(-f*dt)
		
				local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
				local v1 = (f*dt*(offset*f - v0) + v0)*decay
		
				self.p = p1
				self.v = v1
		
				return p1
			end
		
			function Spring:Reset(pos)
				self.p = pos
				self.v = pos*0
			end
		end
		
		------------------------------------------------------------------------
		
		local cameraPos = Vector3.new()
		local cameraRot = Vector2.new()
		local cameraFov = 0
		
		local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
		local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
		local fovSpring = Spring.new(FOV_STIFFNESS, 0)
		
		------------------------------------------------------------------------
		
		local Input = {} do
			local thumbstickCurve do
				local K_CURVATURE = 2.0
				local K_DEADZONE = 0.15
		
				local function fCurve(x)
					return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
				end
		
				local function fDeadzone(x)
					return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
				end
		
				function thumbstickCurve(x)
					return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
				end
			end
		
			local gamepad = {
				ButtonX = 0,
				ButtonY = 0,
				DPadDown = 0,
				DPadUp = 0,
				ButtonL2 = 0,
				ButtonR2 = 0,
				Thumbstick1 = Vector2.new(),
				Thumbstick2 = Vector2.new(),
			}
		
			local keyboard = {
				W = 0,
				A = 0,
				S = 0,
				D = 0,
				E = 0,
				Q = 0,
				U = 0,
				H = 0,
				J = 0,
				K = 0,
				I = 0,
				Y = 0,
				Up = 0,
				Down = 0,
				LeftShift = 0,
				RightShift = 0,
			}
		
			local mouse = {
				Delta = Vector2.new(),
				MouseWheel = 0,
			}
		
			local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
			local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
			local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
			local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
			local FOV_WHEEL_SPEED    = 1.0
			local FOV_GAMEPAD_SPEED  = 0.25
			local NAV_ADJ_SPEED      = 0.75
			local NAV_SHIFT_MUL      = 0.25
		
			local navSpeed = 1
		
			function Input.Vel(dt)
				navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)
		
				local kGamepad = Vector3.new(
					thumbstickCurve(gamepad.Thumbstick1.X),
					thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
					thumbstickCurve(-gamepad.Thumbstick1.Y)
				)*NAV_GAMEPAD_SPEED
		
				local kKeyboard = Vector3.new(
					keyboard.D - keyboard.A + keyboard.K - keyboard.H,
					keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
					keyboard.S - keyboard.W + keyboard.J - keyboard.U
				)*NAV_KEYBOARD_SPEED
		
				local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		
				return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
			end
		
			function Input.Pan(dt)
				local kGamepad = Vector2.new(
					thumbstickCurve(gamepad.Thumbstick2.Y),
					thumbstickCurve(-gamepad.Thumbstick2.X)
				)*PAN_GAMEPAD_SPEED
				local kMouse = mouse.Delta*PAN_MOUSE_SPEED
				mouse.Delta = Vector2.new()
				return kGamepad + kMouse
			end
		
			function Input.Fov(dt)
				local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
				local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
				mouse.MouseWheel = 0
				return kGamepad + kMouse
			end
		
			do
				local function Keypress(action, state, input)
					keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
					return Enum.ContextActionResult.Sink
				end
		
				local function GpButton(action, state, input)
					gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
					return Enum.ContextActionResult.Sink
				end
		
				local function MousePan(action, state, input)
					local delta = input.Delta
					mouse.Delta = Vector2.new(-delta.y, -delta.x)
					return Enum.ContextActionResult.Sink
				end
		
				local function Thumb(action, state, input)
					gamepad[input.KeyCode.Name] = input.Position
					return Enum.ContextActionResult.Sink
				end
		
				local function Trigger(action, state, input)
					gamepad[input.KeyCode.Name] = input.Position.z
					return Enum.ContextActionResult.Sink
				end
		
				local function MouseWheel(action, state, input)
					mouse[input.UserInputType.Name] = -input.Position.z
					return Enum.ContextActionResult.Sink
				end
		
				local function Zero(t)
					for k, v in pairs(t) do
						t[k] = v*0
					end
				end
		
				function Input.StartCapture()
					ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
						Enum.KeyCode.W, Enum.KeyCode.U,
						Enum.KeyCode.A, Enum.KeyCode.H,
						Enum.KeyCode.S, Enum.KeyCode.J,
						Enum.KeyCode.D, Enum.KeyCode.K,
						Enum.KeyCode.E, Enum.KeyCode.I,
						Enum.KeyCode.Q, Enum.KeyCode.Y,
						Enum.KeyCode.Up, Enum.KeyCode.Down
					)
					ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
					ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
					ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
					ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
					ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
				end
		
				function Input.StopCapture()
					navSpeed = 1
					Zero(gamepad)
					Zero(keyboard)
					Zero(mouse)
					ContextActionService:UnbindAction("FreecamKeyboard")
					ContextActionService:UnbindAction("FreecamMousePan")
					ContextActionService:UnbindAction("FreecamMouseWheel")
					ContextActionService:UnbindAction("FreecamGamepadButton")
					ContextActionService:UnbindAction("FreecamGamepadTrigger")
					ContextActionService:UnbindAction("FreecamGamepadThumbstick")
				end
			end
		end
		
		local function GetFocusDistance(cameraFrame)
			local znear = 0.1
			local viewport = Camera.ViewportSize
			local projy = 2*tan(cameraFov/2)
			local projx = viewport.x/viewport.y*projy
			local fx = cameraFrame.rightVector
			local fy = cameraFrame.upVector
			local fz = cameraFrame.lookVector
		
			local minVect = Vector3.new()
			local minDist = 512
		
			for x = 0, 1, 0.5 do
				for y = 0, 1, 0.5 do
					local cx = (x - 0.5)*projx
					local cy = (y - 0.5)*projy
					local offset = fx*cx - fy*cy + fz
					local origin = cameraFrame.p + offset*znear
					local _, hit = Workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
					local dist = (hit - origin).magnitude
					if minDist > dist then
						minDist = dist
						minVect = offset.unit
					end
				end
			end
		
			return fz:Dot(minVect)*minDist
		end
		
		------------------------------------------------------------------------
		
		local function StepFreecam(dt)
			local vel = velSpring:Update(dt, Input.Vel(dt))
			local pan = panSpring:Update(dt, Input.Pan(dt))
			local fov = fovSpring:Update(dt, Input.Fov(dt))
		
			local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))
		
			cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
			cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
			cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))
		
			local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
			cameraPos = cameraCFrame.p
		
			Camera.CFrame = cameraCFrame
			Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
			Camera.FieldOfView = cameraFov
		end
		
		local function CheckMouseLockAvailability()
			local devAllowsMouseLock = Players.LocalPlayer.DevEnableMouseLock
			local devMovementModeIsScriptable = Players.LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
			local userHasMouseLockModeEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
			local userHasClickToMoveEnabled =  GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
			local MouseLockAvailable = devAllowsMouseLock and userHasMouseLockModeEnabled and not userHasClickToMoveEnabled and not devMovementModeIsScriptable
		
			return MouseLockAvailable
		end
		
		------------------------------------------------------------------------
		
		local PlayerState = {} do
			local mouseBehavior
			local mouseIconEnabled
			local cameraType
			local cameraFocus
			local cameraCFrame
			local cameraFieldOfView
			local screenGuis = {}
			local coreGuis = {
				Backpack = true,
				Chat = true,
				Health = true,
				PlayerList = true,
			}
			local setCores = {
				BadgesNotificationsActive = true,
				PointsNotificationsActive = true,
			}
		
			-- Save state and set up for freecam
			function PlayerState.Push()
				for name in pairs(coreGuis) do
					coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
				end
				for name in pairs(setCores) do
					setCores[name] = StarterGui:GetCore(name)
					StarterGui:SetCore(name, false)
				end
				local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
				if playergui then
					for _, gui in pairs(playergui:GetChildren()) do
						if gui:IsA("ScreenGui") and gui.Enabled then
							screenGuis[#screenGuis + 1] = gui
							gui.Enabled = false
						end
					end
				end
		
				cameraFieldOfView = Camera.FieldOfView
				Camera.FieldOfView = 70
		
				cameraType = Camera.CameraType
				Camera.CameraType = Enum.CameraType.Custom
		
				cameraCFrame = Camera.CFrame
				cameraFocus = Camera.Focus
		
				mouseIconEnabled = UserInputService.MouseIconEnabled
				UserInputService.MouseIconEnabled = false
		
				if FFlagUserExitFreecamBreaksWithShiftlock and CheckMouseLockAvailability() then
					mouseBehavior = Enum.MouseBehavior.Default
				else
					mouseBehavior = UserInputService.MouseBehavior
				end
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
		
			-- Restore state
			function PlayerState.Pop()
				for name, isEnabled in pairs(coreGuis) do
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
				end
				for name, isEnabled in pairs(setCores) do
					StarterGui:SetCore(name, isEnabled)
				end
				for _, gui in pairs(screenGuis) do
					if gui.Parent then
						gui.Enabled = true
					end
				end
		
				Camera.FieldOfView = cameraFieldOfView
				cameraFieldOfView = nil
		
				Camera.CameraType = cameraType
				cameraType = nil
		
				Camera.CFrame = cameraCFrame
				cameraCFrame = nil
		
				Camera.Focus = cameraFocus
				cameraFocus = nil
		
				UserInputService.MouseIconEnabled = mouseIconEnabled
				mouseIconEnabled = nil
		
				UserInputService.MouseBehavior = mouseBehavior
				mouseBehavior = nil
			end
		end
		
		local function StartFreecam()
			local cameraCFrame = Camera.CFrame
			cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
			cameraPos = cameraCFrame.p
			cameraFov = Camera.FieldOfView
		
			velSpring:Reset(Vector3.new())
			panSpring:Reset(Vector2.new())
			fovSpring:Reset(0)
		
			PlayerState.Push()
			RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
			Input.StartCapture()
		end
		
		local function StopFreecam()
			Input.StopCapture()
			RunService:UnbindFromRenderStep("Freecam")
			PlayerState.Pop()
		end
		
		------------------------------------------------------------------------
		
		do
			local enabled = false
		
			local function ToggleFreecam()
				if enabled then
					StopFreecam()
				else
					StartFreecam()
				end
				enabled = not enabled
			end
		
			local function CheckMacro(macro)
				for i = 1, #macro - 1 do
					if not UserInputService:IsKeyDown(macro[i]) then
						return
					end
				end
				ToggleFreecam()
			end
		
			local function HandleActivationInput(action, state, input)
				if state == Enum.UserInputState.Begin then
					if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
						CheckMacro(FREECAM_MACRO_KB)
					end
				end
				return Enum.ContextActionResult.Pass
			end
		
			ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
		end
				  end    
			})
	
			Tab:AddButton({
				Name = "Potato PC",
				Callback = function()
					workspace:FindFirstChildOfClass('Terrain').WaterWaveSize = 0
					workspace:FindFirstChildOfClass('Terrain').WaterWaveSpeed = 0
					workspace:FindFirstChildOfClass('Terrain').WaterReflectance = 0
					workspace:FindFirstChildOfClass('Terrain').WaterTransparency = 0
					game:GetService("Lighting").GlobalShadows = false
					game:GetService("Lighting").FogEnd = 9e9
					settings().Rendering.QualityLevel = 1
					for i,v in pairs(game:GetDescendants()) do
						if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
							v.Material = "Plastic"
							v.Reflectance = 0
						elseif v:IsA("Decal") then
							v.Transparency = 1
						elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
							v.Lifetime = NumberRange.new(0)
						elseif v:IsA("Explosion") then
							v.BlastPressure = 1
							v.BlastRadius = 1
						end
					end
				  end    
			})
	
	
			Tab:AddButton({
				Name = "Force Changing Map",
				Callback = function()
					local L = game.ReplicatedStorage.RemoteFunction
					for a, c in pairs(game:GetService('Workspace').Elevators:GetChildren()) do
					  local a = require(c.Settings).Type
					  local b = c.State.Players
					  if a == "Survival" and b.Value <= 0 then
						L:InvokeServer("Elevators", "Enter", c)
						wait(1)
						L:InvokeServer("Elevators", "Leave")
					  end
					end
					wait(0.6)
					L:InvokeServer("Elevators", "Leave")
					wait(1)
				  end    
			})
	
			Tab:AddButton({
				Name = "Free Private Server",
				Callback = function()
					print("Original From: https://v3rmillion.net/showthread.php?tid=1127661\nCreddit To: Aidez")
					repeat wait() until game:IsLoaded()
					if game.PlaceId == 3260590327 and #game:GetService("Players"):GetChildren() >= 14 then --If server has over 14 then it will teleport you to the less player server
						local HttpService = game:GetService("HttpService")
						local function GetServers(placeid)
							local Servers = {}
							local MaxPlayers = 12 --Max player
							local CurrentCursor = ""
							if placeid == nil then
								placeid = game.PlaceId
							end
							repeat
								local Success = pcall(function()
									local ListRaw = game:HttpGet("https://games.roblox.com/v1/games/"..tostring(placeid).."/servers/Public?sortOrder=Asc&limit=100&cursor="..CurrentCursor)
									local CurrentList = HttpService:JSONDecode(ListRaw) -- done in 2 steps for getting cursor later
									for i = 1,#CurrentList.data do
										if CurrentList ~= nil then
											if CurrentList.data[i].playing <= MaxPlayers then
												table.insert(Servers, CurrentList.data[i])
											end
										end
									end
									local CursorIndex = string.find(ListRaw, "nextPageCursor")
									local EndComma = string.find(ListRaw, ",", CursorIndex)
									local ToEdit = string.sub(ListRaw, CursorIndex, EndComma - 1)
									local ToEdit = string.gsub(ToEdit, '"', "")
									CurrentCursor = string.gsub(ToEdit, 'nextPageCursor:', "")
								end)
								task.wait()
							until CurrentCursor == "null" and Success == true
							return Servers
						end
						local Servers = GetServers()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Servers[math.random(1,#Servers)].id, game:GetService("Players").LocalPlayer)
					end
				  end    
			})
	
			local Tab = Window:MakeTab({
				Name = "Visual",
				Icon = "",
				PremiumOnly = false
			})
	
			Tab:AddButton({
				Name = "Get All Tower (Visual)",
				Callback = function()
					local Newby = game:GetService("Players").LocalPlayer.PlayerGui.LobbyGui.Menu.Containers.Inventory.Content.Pages.Troops.Holder.Troops
	
					Newby.UIGridLayout:Destroy()
					for i, v in pairs(Newby:GetChildren()) do
						v.Visible = true
					end
					
					Instance.new("UIGridLayout", game:GetService("Players").LocalPlayer.PlayerGui.LobbyGui.Menu.Containers.Inventory.Content.Pages.Troops.Holder.Troops)
				  end    
			})
	
	
		end
		OrionLib:Init()
	