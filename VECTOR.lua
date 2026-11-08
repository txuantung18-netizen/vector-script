-- VECTOR release: install the local payload, then run it.
local payload = [=[-- VECTOR standalone release. Noclip starts OFF; toggle restores original character collisions.
-- Local lifecycle and storage adapter. No MCP connection or polling.
local underEnv = (type(getgenv)=="function" and getgenv()) or _G
local previousUnder = underEnv.__UnderStandalone
if previousUnder and type(previousUnder.cleanup)=="function" then previousUnder.cleanup() end
local underFilesRead, underFilesWrite = readfile, writefile
local function underPath(name)
    if name:sub(1,7)=="VECTOR/" then return name end
    return "VECTOR/"..name
end
local readfile = type(underFilesRead)=="function" and function(name) return underFilesRead(underPath(name)) end or nil
local writefile = type(underFilesWrite)=="function" and function(name,value) return underFilesWrite(underPath(name),value) end or nil
local LiveMCP = {}
local underTracked, underCallbacks, underExtensions = {}, {}, {}
function LiveMCP.track(instance) table.insert(underTracked,instance);return instance end
function LiveMCP.onCleanup(callback) table.insert(underCallbacks,callback) end
function LiveMCP.register(name,callback) underExtensions[name]=callback end
function LiveMCP.unregister(name) underExtensions[name]=nil end
function LiveMCP.cleanup()
    local callbacks,tracked=underCallbacks,underTracked
    underCallbacks={};underTracked={}
    for i=#callbacks,1,-1 do
        local ok,err=pcall(callbacks[i])
        if not ok then warn("[VECTOR] Cleanup: "..tostring(err)) end
    end
    for _,instance in ipairs(tracked) do pcall(function() instance:Destroy() end) end
    table.clear(underExtensions)
end
function LiveMCP.showWorkspace()
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="VECTOR storage",Text="Local files: VECTOR/ in your host workspace",Duration=6}) end)
end
underEnv.__UnderStandalone=LiveMCP

LiveMCP.cleanup()
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Actions = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local C = {bg = Color3.fromRGB(7, 28, 31), panel = Color3.fromRGB(12, 50, 48),
    edge = Color3.fromRGB(46, 112, 98), text = Color3.fromRGB(231, 255, 247),
    muted = Color3.fromRGB(145, 194, 180), accent = Color3.fromRGB(81, 240, 178)}
local function make(class, parent, properties)
    local obj = Instance.new(class)
    for key, value in pairs(properties or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius) make("UICorner", obj, {CornerRadius = UDim.new(0, radius or 8)}) end
local function text(parent, caption, x, y, width, height, size, color)
    return make("TextLabel", parent, {BackgroundTransparency = 1, Text = caption,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        TextColor3 = color or C.text, TextSize = size or 14, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left})
end
local function button(parent, caption, x, y, width, height)
    local b = make("TextButton", parent, {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, Text = caption, TextColor3 = C.text,
        TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = true})
    corner(b, 6)
    make("UIStroke", b, {Color = C.accent, Transparency = .78, Thickness = 1})
    make("UIGradient", b, {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(158,205,190))})
    return b
end
local playerGui = player:WaitForChild("PlayerGui")
local existingVector = playerGui:FindFirstChild("VectorLiveUI")
if existingVector then existingVector:Destroy() end
local gui = LiveMCP.track(make("ScreenGui", playerGui, {
    Name = "VectorLiveUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 20,
}))
local bounds = make("Frame", gui, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
local window = make("Frame", gui, {Size = UDim2.fromOffset(640, 510), BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true})
-- Internal controls remain hidden while Rayfield provides the visible UI.
window.Visible = false
window.BackgroundTransparency = .12
corner(window, 12)
make("UIStroke", window, {Color = C.accent, Transparency = .38, Thickness = 1.5})
make("UIGradient", window, {Rotation = 115, Color = ColorSequence.new(Color3.fromRGB(165,255,219), Color3.fromRGB(100,175,185))})
local uiScale = make("UIScale", window, {})
make("Frame", window, {BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2)})
local header = make("Frame", window, {BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 66), Active = true})
text(header, "V /", 22, 15, 46, 30, 24, C.accent).Font = Enum.Font.GothamBlack
text(header, "VECTOR", 78, 11, 200, 27, 23).Font = Enum.Font.GothamBold
text(header, "STANDALONE RELEASE  /  01", 79, 39, 230, 14, 9, C.muted)
local close = button(header, "X", 590, 15, 30, 30)
close.Position = UDim2.new(1, -50, 0, 15)
local maximize = button(header, "[ ]", 548, 15, 30, 30)
maximize.Position = UDim2.new(1, -92, 0, 15)
local shortcutLabel = text(header, "- / RSHIFT", 0, 23, 100, 18, 10, C.accent)
shortcutLabel.Position = UDim2.new(1, -208, 0, 23)
make("Frame", window, {Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.edge, BorderSizePixel = 0})
local sidebar = make("Frame", window, {Position = UDim2.fromOffset(0, 69), Size = UDim2.new(0, 150, 1, -69), BackgroundColor3 = C.panel, BorderSizePixel = 0})
sidebar.BackgroundTransparency = .14
make("Frame", sidebar, {Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.edge, BorderSizePixel = 0})
text(sidebar, "WORKSPACE", 18, 20, 120, 18, 9, C.muted)
local movement = button(sidebar, "01   MOVEMENT", 10, 52, 130, 37)
movement.BackgroundColor3 = Color3.fromRGB(31, 65, 61)
movement.TextColor3 = C.accent
local danceButton = button(sidebar, "02   DANCE: OFF", 10, 98, 130, 37)
danceButton.Visible = false
local emoteButton = button(sidebar, "05   ROBLOX DANCE: OFF", 10, 236, 130, 37)
emoteButton.TextSize = 9
emoteButton.Visible = false
text(window, "Movement", 172, 88, 440, 32, 27).Font = Enum.Font.GothamBold
text(window, "Character controls. Updated live through MCP.", 173, 126, 440, 19, 11, C.muted)
local card = make("Frame", window, {Position = UDim2.fromOffset(172, 163), Size = UDim2.fromOffset(446, 115), BackgroundColor3 = C.panel, BorderSizePixel = 0})
corner(card, 8)
text(card, "01 / COLLISION", 17, 14, 230, 17, 9, C.accent)
text(card, "Noclip", 17, 38, 230, 28, 23).Font = Enum.Font.GothamBold
text(card, "Disable character collisions while enabled.", 17, 78, 410, 18, 11, C.muted)
local toggle = button(card, "", 350, 35, 77, 34)
toggle.BackgroundColor3 = C.edge
local knob = make("Frame", toggle, {Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C.muted, BorderSizePixel = 0})
corner(knob, 13)
local function info(x, title, value)
    local box = make("Frame", window, {Position = UDim2.fromOffset(x, 292), Size = UDim2.fromOffset(216, 52), BackgroundColor3 = C.panel, BorderSizePixel = 0})
    corner(box, 6)
    text(box, title, 12, 7, 192, 15, 8, C.muted)
    return text(box, value, 12, 24, 192, 20, 12, C.accent)
end
local freeCard = make("Frame", window, {Position = UDim2.fromOffset(172, 290), Size = UDim2.fromOffset(446, 101), BackgroundColor3 = C.panel, BorderSizePixel = 0})
corner(freeCard, 8)
text(freeCard, "02 / CAMERA", 17, 10, 230, 17, 9, C.accent)
text(freeCard, "Freecam", 17, 30, 230, 28, 23).Font = Enum.Font.GothamBold
text(freeCard, "WASD + Q/E to fly; hold right mouse to look.", 17, 72, 410, 18, 11, C.muted)
local freeToggle = button(freeCard, "", 350, 30, 77, 34)
local freeKnob = make("Frame", freeToggle, {Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C.muted, BorderSizePixel = 0})
corner(freeKnob, 13)
local statusText = info(172, "NOCLIP STATUS", "DISABLED")
statusText.Parent.Position = UDim2.fromOffset(172, 402)
local freeStatus = info(402, "FREECAM STATUS", "DISABLED")
freeStatus.Parent.Position = UDim2.fromOffset(402, 402)
local save = button(window, "SAVE SCRIPT", 172, 462, 138, 33)
save.BackgroundColor3 = Color3.fromRGB(31, 65, 61)
save.TextColor3 = C.accent
local unload = button(window, "UNLOAD", 464, 462, 154, 33)
local reopen = button(gui, "V / VECTOR", 12, 12, 115, 34)
reopen.Visible = false

local connections, partConnections, originals = {}, {}, {}
local enabled, disposed, physics = false, false, nil
local rayfieldToggle
local uiHandlers = {}
local setESPExternal
local setESPOptionExternal
local stopPhysicalDance = function() end
local stopRobloxDance = function() end
local stopAnimationCapture = function() end
local danceTrack, danceJoints = nil, {}
local function stopDance()
    if danceTrack then danceTrack:Disconnect(); danceTrack = nil end
    for joint, initial in pairs(danceJoints) do pcall(function() joint.C1 = initial end) end
    danceJoints = {}
    danceButton.Text = "02   DANCE: OFF"
    danceButton.TextColor3 = C.text
end
local function startDance()
    stopPhysicalDance("switched to joint dance")
    stopRobloxDance()
    stopDance()
    local model = player.Character
    if not model then danceButton.Text = "NO CHARACTER"; return false end
    local motions = { ["Left Shoulder"] = -1, ["Right Shoulder"] = 1, LeftShoulder = -1, RightShoulder = 1,
        ["Left Hip"] = -1, ["Right Hip"] = 1, LeftHip = -1, RightHip = 1, Waist = 2, Neck = 3 }
    for _, joint in ipairs(model:GetDescendants()) do
        if joint:IsA("Motor6D") and motions[joint.Name] then
            danceJoints[joint] = joint.C1
        end
    end
    if not next(danceJoints) then danceButton.Text = "NO JOINTS"; return false end
    local started = os.clock()
    danceTrack = Run.Heartbeat:Connect(function()
        local phase = (os.clock() - started) * 10
        for joint, initial in pairs(danceJoints) do
            if joint.Parent then
                local motion = motions[joint.Name]
                local angle = math.sin(phase) * (motion == 2 and .40 or motion == 3 and .24 or 1.15)
                if joint.Name == "Left Shoulder" or joint.Name == "Right Shoulder"
                    or joint.Name == "LeftShoulder" or joint.Name == "RightShoulder" then
                    -- Oscillate from the original C1, avoiding accumulated drift.
                    local armPhase = (os.clock() - started) * 26
                    joint.C1 = initial * CFrame.Angles(math.sin(armPhase) * 2.25 * motion,
                        math.sin(armPhase * .73) * 1.1, math.cos(armPhase * 1.3) * 1.05)
                elseif motion == 2 or motion == 3 then
                    joint.C1 = initial * CFrame.Angles(0, math.sin(phase * .7) * .25, angle)
                else
                    joint.C1 = initial * CFrame.Angles(angle * motion, math.cos(phase * .8) * .35, angle * .6)
                end
            end
        end
    end)
    danceButton.Text = "02   DANCE: ON"
    danceButton.TextColor3 = C.accent
    return true
end
local robloxTrack, robloxDanceGeneration = nil, 0
stopRobloxDance = function()
    robloxDanceGeneration = robloxDanceGeneration + 1
    if robloxTrack then
        pcall(function() robloxTrack:Stop(); robloxTrack:Destroy() end)
        robloxTrack = nil
    end
    emoteButton.Text = "05   ROBLOX DANCE: OFF"
    emoteButton.TextColor3 = C.text
end
local function startRobloxDance()
    stopPhysicalDance("switched to Roblox dance")
    stopDance()
    stopRobloxDance()
    local model = player.Character
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 or not animator then
        emoteButton.Text = "R6 / ANIMATOR REQUIRED"
        return false
    end
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://182435998"
    local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
    animation:Destroy()
    if not ok or not track then emoteButton.Text = "ANIMATION LOAD FAILED"; return false end
    robloxTrack = track
    local played = pcall(function()
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        track:Play(.2)
    end)
    if not played then stopRobloxDance(); emoteButton.Text = "PLAY FAILED"; return false end
    emoteButton.Text = "05   ROBLOX DANCE: ON"
    emoteButton.TextColor3 = C.accent
    local generation = robloxDanceGeneration
    task.spawn(function()
        while robloxDanceGeneration == generation and robloxTrack do
            task.wait(.5)
            if robloxDanceGeneration ~= generation or not robloxTrack then break end
            if player.Character ~= model or not model.Parent or humanoid.Health <= 0 then
                stopRobloxDance()
                break
            end
            local state = humanoid:GetState()
            local busy = state == Enum.HumanoidStateType.Physics
                or state == Enum.HumanoidStateType.Ragdoll
                or state == Enum.HumanoidStateType.FallingDown
                or state == Enum.HumanoidStateType.GettingUp
            local current = robloxTrack
            local valid, playing = pcall(function() return current.IsPlaying end)
            if busy then
                emoteButton.Text = "05   DANCE: WAITING"
            elseif not valid or not playing then
                emoteButton.Text = "05   DANCE: RETRYING"
                pcall(function() current:Destroy() end)
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://182435998"
                local loaded, replacement = pcall(function() return animator:LoadAnimation(anim) end)
                anim:Destroy()
                if loaded and replacement then
                    robloxTrack = replacement
                    pcall(function()
                        replacement.Priority = Enum.AnimationPriority.Action
                        replacement.Looped = true
                        replacement:Play(.2)
                    end)
                end
            else
                emoteButton.Text = "05   ROBLOX DANCE: ON"
            end
        end
    end)
    return true
end
local freeEnabled, freeRender, rightLook = false, nil, false
local cameraLooking = false
local freeCamera, savedCamera, position, pitch, yaw, savedMouse
local cameraStop, cameraCleanup = function() end, function() end
local character = player.Character
local activeTween
local function connect(signal, fn)
    local connection = signal:Connect(fn)
    local handlers = uiHandlers[signal] or {}
    table.insert(handlers, fn)
    uiHandlers[signal] = handlers
    table.insert(connections, connection)
    return connection
end
local function invokeButton(control)
    local handlers = uiHandlers[control.Activated] or {}
    for _, fn in ipairs(handlers) do fn() end
end
local function restore()
    for part, value in pairs(originals) do
        pcall(function() part.CanCollide = value end)
    end
    originals = {}
end
local function capture(obj)
    if enabled and obj:IsA("BasePart") then
        if originals[obj] == nil then originals[obj] = obj.CanCollide end
        obj.CanCollide = false
    end
end
local function bindCharacter(model)
    for _, connection in ipairs(partConnections) do connection:Disconnect() end
    partConnections = {}
    restore()
    character = model
    if not model then return end
    table.insert(partConnections, model.DescendantAdded:Connect(capture))
    table.insert(partConnections, model.DescendantRemoving:Connect(function(obj)
        if originals[obj] ~= nil then
            local value = originals[obj]
            originals[obj] = nil
            pcall(function() obj.CanCollide = value end)
        end
    end))
    for _, obj in ipairs(model:GetDescendants()) do capture(obj) end
end
local function redraw()
    statusText.Text = enabled and "ENABLED" or "DISABLED"
    statusText.TextColor3 = enabled and C.accent or C.muted
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(31, 83, 69) or C.edge
    if activeTween then activeTween:Cancel() end
    activeTween = Tween:Create(knob, TweenInfo.new(.16), {
        Position = UDim2.fromOffset(enabled and 47 or 4, 4), BackgroundColor3 = enabled and C.accent or C.muted,
    })
    activeTween:Play()
end
local function setEnabled(value)
    assert(type(value) == "boolean", "enabled must be a boolean")
    if disposed then return end
    if value == enabled then return end
    enabled = value
    if physics then physics:Disconnect(); physics = nil end
    if value then
        if character then for _, obj in ipairs(character:GetDescendants()) do capture(obj) end end
        physics = Run.PreSimulation:Connect(function()
            for part in pairs(originals) do
                if character and part:IsDescendantOf(character) then part.CanCollide = false end
            end
        end)
    else restore() end
    redraw()
end
local function setFreecam(value)
    assert(type(value) == "boolean", "enabled must be a boolean")
    if disposed or value == freeEnabled then return end
    freeEnabled = value
    if freeRender then freeRender:Disconnect(); freeRender = nil end
    if value then
        cameraStop()
        local camera = workspace.CurrentCamera
        if not camera then freeEnabled = false; return end
        freeCamera = camera
        savedCamera = {kind = camera.CameraType, subject = camera.CameraSubject,
            frame = camera.CFrame, focus = camera.Focus}
        savedMouse = Input.MouseBehavior
        position = camera.CFrame.Position
        pitch, yaw = camera.CFrame:ToOrientation()
        camera.CameraType = Enum.CameraType.Scriptable
        Actions:BindActionAtPriority("VectorFreecamMove", function()
            return Enum.ContextActionResult.Sink
        end, false, 3000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S,
            Enum.KeyCode.D, Enum.KeyCode.Q, Enum.KeyCode.E)
        freeRender = Run.RenderStepped:Connect(function(dt)
            if workspace.CurrentCamera ~= camera then setFreecam(false); return end
            if rightLook then
                local delta = Input:GetMouseDelta()
                yaw = yaw - delta.X * .0024
                pitch = math.clamp(pitch - delta.Y * .0024, -1.5, 1.5)
            end
            local rotation = CFrame.fromOrientation(pitch, yaw, 0)
            local x = (Input:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local z = (Input:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local y = (Input:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.Q) and 1 or 0)
            local move = rotation.RightVector * x + rotation.LookVector * z + Vector3.new(0, y, 0)
            if move.Magnitude > 0 then
                local speed = Input:IsKeyDown(Enum.KeyCode.LeftShift) and 48 or 16
                position = position + move.Unit * speed * math.min(dt, .1)
            end
            camera.CFrame = CFrame.new(position) * rotation
            camera.Focus = CFrame.new(position + rotation.LookVector * 12)
        end)
    else
        Actions:UnbindAction("VectorFreecamMove")
        rightLook = false
        if savedMouse then Input.MouseBehavior = savedMouse end
        if freeCamera and freeCamera.Parent and savedCamera then
            freeCamera.CFrame = savedCamera.frame
            freeCamera.Focus = savedCamera.focus
            if savedCamera.subject and savedCamera.subject.Parent then
                freeCamera.CameraSubject = savedCamera.subject
            end
            freeCamera.CameraType = savedCamera.kind
        end
        freeCamera, savedCamera = nil, nil
    end
    freeStatus.Text = freeEnabled and "ENABLED" or "DISABLED"
    freeStatus.TextColor3 = freeEnabled and C.accent or C.muted
    freeToggle.BackgroundColor3 = freeEnabled and Color3.fromRGB(31, 83, 69) or C.edge
    Tween:Create(freeKnob, TweenInfo.new(.16), {
        Position = UDim2.fromOffset(freeEnabled and 47 or 4, 4),
        BackgroundColor3 = freeEnabled and C.accent or C.muted,
    }):Play()
end
local function clampPosition(x, y)
    local available, size = bounds.AbsoluteSize, window.AbsoluteSize
    return math.clamp(x, 6, math.max(6, available.X - size.X - 6)), math.clamp(y, 6, math.max(6, available.Y - size.Y - 6))
end
local maximized, windowPosition = false, nil
local function resize(center)
    local available = bounds.AbsoluteSize
    uiScale.Scale = math.max(.1, math.min(1.2, (available.X - 12) / 640, (available.Y - 12) / 510))
    if maximized then
        window.Size = UDim2.fromOffset(available.X / uiScale.Scale, available.Y / uiScale.Scale)
        window.Position = UDim2.fromOffset(0, 0)
        return
    end
    window.Size = UDim2.fromOffset(640, 510)
    local x, y = window.Position.X.Offset, window.Position.Y.Offset
    if center then x, y = (available.X - window.AbsoluteSize.X) / 2, (available.Y - window.AbsoluteSize.Y) / 2 end
    x, y = clampPosition(x, y)
    window.Position = UDim2.fromOffset(x, y)
end
connect(maximize.Activated, function()
    if not maximized then
        windowPosition = window.Position
        maximized = true
        maximize.Text = "-"
        resize(false)
    else
        maximized = false
        maximize.Text = "[ ]"
        if windowPosition then window.Position = windowPosition end
        resize(false)
    end
end)
local function shutdown()
    if disposed then return end
    stopAnimationCapture()
    cameraCleanup()
    stopPhysicalDance("UI closed")
    stopDance()
    stopRobloxDance()
    setFreecam(false)
    disposed = true
    if physics then physics:Disconnect(); physics = nil end
    enabled = false
    restore()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, connection in ipairs(partConnections) do connection:Disconnect() end
    if activeTween then activeTween:Cancel() end
    LiveMCP.unregister("noclip")
    LiveMCP.unregister("noclip_status")
    LiveMCP.unregister("dance")
    LiveMCP.unregister("roblox_dance")
    LiveMCP.unregister("cursor_status")
    LiveMCP.unregister("toggle_vector_ui")
    LiveMCP.unregister("r6_physics_dance")
    LiveMCP.unregister("r6_physics_status")
    gui:Destroy()
end
LiveMCP.onCleanup(shutdown)
connect(gui.Destroying, shutdown)
connect(player.CharacterAdded, function(model)
    stopDance()
    stopRobloxDance()
    if freeEnabled then setFreecam(false) end
    bindCharacter(model)
    task.defer(function()
        if disposed then return end
        local currentGui = player:FindFirstChildOfClass("PlayerGui")
        if currentGui then
            pcall(function()
                if gui.Parent ~= currentGui then gui.Parent = currentGui end
                gui.Enabled = true
            end)
        end
    end)
end)
connect(player.CharacterRemoving, function(model)
    if character == model then stopPhysicalDance("character removed"); stopRobloxDance(); bindCharacter(nil) end
end)
bindCharacter(character)
connect(toggle.Activated, function() setEnabled(not enabled) end)
connect(danceButton.Activated, function()
    if danceTrack then stopDance() else startDance() end
end)
connect(emoteButton.Activated, function()
    if robloxTrack then stopRobloxDance() else startRobloxDance() end
end)
connect(freeToggle.Activated, function() setFreecam(not freeEnabled) end)
connect(save.Activated, LiveMCP.showWorkspace)
connect(unload.Activated, shutdown)
connect(close.Activated, function() window.Visible = false end)
connect(window:GetPropertyChangedSignal("Visible"), function()
    reopen.Visible = false
    if window.Visible then window.Visible = false end
end)
connect(bounds:GetPropertyChangedSignal("AbsoluteSize"), function() resize(false) end)
local dragging, origin, start
connect(header.InputBegan, function(input)
    if maximized then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, origin, start = input, input.Position, window.Position
    end
end)
connect(Input.InputChanged, function(input)
    if not dragging then return end
    if dragging.UserInputType == Enum.UserInputType.Touch and input ~= dragging then return end
    if dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = input.Position - origin
    local x, y = clampPosition(start.X.Offset + delta.X, start.Y.Offset + delta.Y)
    window.Position = UDim2.fromOffset(x, y)
end)
connect(Input.InputEnded, function(input) if input == dragging then dragging = nil end end)
connect(Input.InputBegan, function(input, processed)
    if freeEnabled and input.UserInputType == Enum.UserInputType.MouseButton2 and not processed then
        rightLook = true
        Input.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)
connect(Input.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightLook = false
        if freeEnabled and savedMouse then Input.MouseBehavior = savedMouse end
    end
end)
connect(Input.WindowFocusReleased, function() dragging = nil; rightLook = false end)
connect(Input.InputBegan, function(input, processed)
    if Input:GetFocusedTextBox() then return end
    if (input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus) and rayfieldToggle then
        rayfieldToggle()
        return
    end
    if processed then return end
    if input.KeyCode == Enum.KeyCode.N then setEnabled(not enabled)
    end
end)
LiveMCP.register("noclip", function(args)
    setEnabled(args.enabled)
    return {enabled = enabled}
end)
LiveMCP.register("dance", function(args)
    assert(type(args.enabled) == "boolean", "enabled must be a boolean")
    if args.enabled then return {enabled = startDance()} end
    stopDance()
    return {enabled = false}
end)
LiveMCP.register("roblox_dance", function(args)
    assert(type(args.enabled) == "boolean", "enabled must be a boolean")
    if args.enabled then return {enabled = startRobloxDance()} end
    stopRobloxDance()
    return {enabled = false}
end)
LiveMCP.register("noclip_status", function()
    local count = 0
    for _ in pairs(originals) do count = count + 1 end
    return {enabled = enabled, tracked_parts = count, character = character and character.Name or "respawning"}
end)
LiveMCP.register("freecam", function(args)
    setFreecam(args.enabled)
    return {enabled = freeEnabled}
end)
LiveMCP.register("freecam_status", function() return {enabled = freeEnabled} end)
LiveMCP.register("cursor_status", function()
    return {mouse = tostring(Input.MouseBehavior), icon = Input.MouseIconEnabled, menu_visible = window.Visible}
end)
LiveMCP.register("toggle_vector_ui", function(args)
    if args and args.check_only then return {available = rayfieldToggle ~= nil} end
    if Input:GetFocusedTextBox() then return {toggled = false, reason = "typing"} end
    if not rayfieldToggle then return {toggled = false, reason = "Rayfield is not ready"} end
    rayfieldToggle()
    return {toggled = true}
end)
-- Camera management is installed inside the VECTOR client environment.
local cams, selected, selecting = {}, 0, false
local viewing, viewCamera, viewState, viewStep = false, nil, nil, nil
local orbitYaw, orbitPitch, viewingMouse = 0, 0, false
local baseYaw, basePitch, thirdPerson = 0, 0, false
local previewModel, previewItem, previewTarget, previewMount
local nextCameraNumber = 1
local boxesEnabled, boxFrames, boxTick = false, {}, 0
local nightEnabled, nightEffect, nightLamp = false, nil, nil
local setNight = function() end
local camMenu = button(sidebar, "02   CAMERAS", 10, 98, 130, 37)
local camPanel = make("Frame", window, {Name = "CameraPanel", Size = UDim2.new(1, -150, 1, -69),
    Position = UDim2.fromOffset(150, 69), BackgroundColor3 = C.bg,
    BorderSizePixel = 0, Visible = false, ZIndex = 30})
local titleCam = text(camPanel, "Camera tracking", 22, 19, 360, 32, 25)
titleCam.Font = Enum.Font.GothamBold
text(camPanel, "Place a camera and follow a moving object.", 23, 56, 440, 18, 11, C.muted)
local camClose = button(camPanel, "BACK", 403, 20, 65, 28)
local statusCam = text(camPanel, "No camera selected", 22, 82, 440, 18, 10, C.accent)
statusCam.TextTruncate = Enum.TextTruncate.AtEnd
local camList = make("ScrollingFrame", camPanel, {Position = UDim2.fromOffset(22, 107), Size = UDim2.fromOffset(446, 136),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
corner(camList, 5)
make("UIListLayout", camList, {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
local pick = button(camPanel, "ADD CAMERA", 22, 254, 140, 32)
local watch = button(camPanel, "VIEW", 174, 254, 140, 32)
local removeCam = button(camPanel, "DELETE", 326, 254, 142, 32)
local left = button(camPanel, "<  LOOK", 22, 294, 140, 32)
local right = button(camPanel, "LOOK  >", 174, 294, 140, 32)
local boxes = button(camPanel, "BOXES: OFF", 326, 294, 142, 32)
local zoomIn = button(camPanel, "ZOOM +", 22, 334, 140, 32)
local zoomOut = button(camPanel, "ZOOM -", 174, 334, 140, 32)
local stop = button(camPanel, "STOP VIEW", 326, 334, 142, 32)
local night = button(camPanel, "NIGHT: OFF", 22, 377, 140, 32)
local viewMode = button(camPanel, "MODE: FIRST", 174, 377, 140, 32)
text(camPanel, "RMB: look / Esc: cancel", 326, 381, 142, 24, 9, C.muted).TextWrapped = true
setNight = function(on)
    if on and not viewing then statusCam.Text = "Start viewing a camera first"; return end
    if nightEffect then nightEffect:Destroy(); nightEffect = nil end
    if nightLamp then nightLamp:Destroy(); nightLamp = nil end
    nightEnabled = on
    night.Text = on and "NIGHT: ON" or "NIGHT: OFF"
    night.TextColor3 = on and C.accent or C.text
    if on then
        nightEffect = make("ColorCorrectionEffect", game:GetService("Lighting"), {
            Name = "VectorNightVision", Saturation = -1, Contrast = .18, Brightness = .12,
        })
        nightLamp = make("Part", workspace, {Name = "VectorNightLight", Size = Vector3.new(.2, .2, .2),
            Anchored = true, Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false})
        make("PointLight", nightLamp, {Brightness = 2, Range = 60, Shadows = false})
        if viewCamera then nightLamp.CFrame = viewCamera.CFrame end
    end
end
connect(night.Activated, function() setNight(not nightEnabled) end)
local function updateList()
    for _, child in ipairs(camList:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    for i, item in ipairs(cams) do
        local row = button(camList, (i == selected and ">  " or "    ") .. item.name .. (item.broken and "  [BROKEN]" or ""), 0, 0, 434, 30)
        row.TextTruncate = Enum.TextTruncate.AtEnd
        row.LayoutOrder = i
        row.TextColor3 = i == selected and C.accent or C.text
        row.Activated:Connect(function()
            if viewing then cameraStop() end
            selected = i
            statusCam.Text = "Selected: " .. item.name
            updateList()
        end)
    end
end
local clearBoxes
cameraStop = function()
    setNight(false)
    if clearBoxes then clearBoxes() end
    if viewStep then viewStep:Disconnect(); viewStep = nil end
    if viewing and cams[selected] and cams[selected].model then
        for _, piece in ipairs(cams[selected].pieces) do
            if piece.part.Parent then piece.part.LocalTransparencyModifier = 0 end
        end
        if cams[selected].labelGui.Parent then cams[selected].labelGui.Enabled = true end
    end
    if viewing and viewCamera and viewCamera.Parent and viewState then
        viewCamera.CFrame = viewState.frame
        viewCamera.Focus = viewState.focus
        viewCamera.FieldOfView = viewState.fov
        if viewState.subject and viewState.subject.Parent then viewCamera.CameraSubject = viewState.subject end
        viewCamera.CameraType = viewState.kind
    end
    if viewState and viewState.mouse then Input.MouseBehavior = viewState.mouse end
    viewingMouse = false
    cameraLooking = false
    viewing, viewCamera, viewState = false, nil, nil
    watch.Text = "VIEW"
    boxes.Text = boxesEnabled and "BOXES: ON" or "BOXES: OFF"
end
local function startView()
    local item = cams[selected]
    if not item or item.broken or not item.part:IsDescendantOf(workspace) then statusCam.Text = "Camera unavailable or broken"; return end
    if freeEnabled then setFreecam(false) end
    cameraStop()
    local camera = workspace.CurrentCamera
    if not camera then statusCam.Text = "Camera unavailable"; return end
    viewCamera, viewing = camera, true
    viewState = {frame = camera.CFrame, focus = camera.Focus, subject = camera.CameraSubject,
        kind = camera.CameraType, fov = camera.FieldOfView, mouse = Input.MouseBehavior}
    baseYaw, basePitch = item.baseYaw, item.basePitch
    orbitYaw, orbitPitch = item.yaw or 0, item.pitch or 0
    local hideModel = not thirdPerson
    for _, piece in ipairs(item.pieces) do piece.part.LocalTransparencyModifier = hideModel and 1 or 0 end
    item.labelGui.Enabled = not hideModel
    camera.CameraType = Enum.CameraType.Scriptable
    watch.Text = "VIEWING"
    local function collisionSet(yaw, pitch)
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {item.model}
        params.MaxParts = 100
        local mount = item.part.CFrame * item.offset
        local rotation = CFrame.fromOrientation(basePitch + pitch, baseYaw + yaw, 0)
        local head = CFrame.new(mount.Position) * rotation * CFrame.new(0, 0, -.20)
        local hits = {}
        for _, part in ipairs(workspace:GetPartBoundsInBox(head, Vector3.new(1.12, .62, 1.05), params)) do
            local model = part:FindFirstAncestorOfClass("Model")
            if part.CanCollide or part.Transparency < 1 or (model and model:FindFirstChildOfClass("Humanoid")) then hits[part] = true end
        end
        return hits
    end
    local function tryLook(yaw, pitch)
        yaw = math.clamp(yaw, -math.pi/2, math.pi/2)
        pitch = math.clamp(pitch, math.max(-1.2, -1.5 - basePitch), math.min(1.2, 1.5 - basePitch))
        local ok, before, after = pcall(function() return collisionSet(orbitYaw, orbitPitch), collisionSet(yaw, pitch) end)
        if not ok then statusCam.Text = "Collision check unavailable"; return end
        for part in pairs(after) do
            if not before[part] then statusCam.Text = "Camera blocked by " .. part.Name; return end
        end
        orbitYaw, orbitPitch = yaw, pitch
        item.yaw, item.pitch = yaw, pitch
    end
    item.tryLook = tryLook
    viewStep = Run.RenderStepped:Connect(function()
        if item.broken or not item.part:IsDescendantOf(workspace) or workspace.CurrentCamera ~= camera then
            cameraStop(); statusCam.Text = item.broken and "Camera broken" or "Target unavailable"; return
        end
        if viewingMouse then
            local delta = Input:GetMouseDelta()
            if delta.Magnitude > 0 then tryLook(orbitYaw - delta.X * .0025, orbitPitch - delta.Y * .0025) end
        end
        local mount = item.part.CFrame * item.offset
        local head = CFrame.new(mount.Position) * CFrame.fromOrientation(basePitch + orbitPitch, baseYaw + orbitYaw, 0)
        local eye = head * CFrame.new(0, 0, -.65)
        if thirdPerson then
            local desired = (head * CFrame.new(3, 2, 6)).Position
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {item.model}
            local hit = workspace:Raycast(mount.Position, desired - mount.Position, params)
            if hit then desired = hit.Position + hit.Normal * .25 end
            item.camera.CFrame = CFrame.lookAt(desired, mount.Position, Vector3.yAxis)
            item.camera.Focus = CFrame.new(mount.Position)
        else
            item.camera.CFrame = eye
            item.camera.Focus = eye * CFrame.new(0, 0, -12)
        end
        camera.CFrame = item.camera.CFrame
        camera.Focus = item.camera.Focus
        if nightLamp then nightLamp.CFrame = camera.CFrame end
    end)
end
connect(viewMode.Activated, function()
    thirdPerson = not thirdPerson
    viewMode.Text = thirdPerson and "MODE: THIRD" or "MODE: FIRST"
    local item = viewing and cams[selected]
    if item and item.model.Parent then
        local hideModel = not thirdPerson
        for _, piece in ipairs(item.pieces) do piece.part.LocalTransparencyModifier = hideModel and 1 or 0 end
        item.labelGui.Enabled = not hideModel
    end
end)
local function showCameraPage(show)
    camPanel.Visible = show
    camMenu.BackgroundColor3 = show and Color3.fromRGB(31, 65, 61) or C.panel
    camMenu.TextColor3 = show and C.accent or C.text
    movement.BackgroundColor3 = show and C.panel or Color3.fromRGB(31, 65, 61)
    movement.TextColor3 = show and C.text or C.accent
end
connect(camMenu.Activated, function() showCameraPage(true) end)
local function createCameraModel(mount, name, ghost)
    local model = Instance.new("Model")
    model.Name = name
    local pieces = {}
    local function piece(name, size, relative, color, material, shape)
        local partObject = make("Part", model, {Name = name, Size = size, CFrame = mount * relative,
            Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
            Color = color, Material = material, Shape = shape or Enum.PartType.Block, Transparency = ghost and .55 or 0})
        table.insert(pieces, {part = partObject, offset = relative,
            rotates = name ~= "MountArm" and name ~= "MountBase"})
        return partObject
    end
    local housing = Color3.fromRGB(56, 64, 72)
    local dark = Color3.fromRGB(20, 26, 34)
    local body = piece("CameraBody", Vector3.new(1.15,.65,.65), CFrame.new(), housing, Enum.Material.Metal)
    piece("FrontPlate", Vector3.new(.85,.52,.09), CFrame.new(0,0,-.36), dark, Enum.Material.Metal)
    piece("LensRim", Vector3.new(.18,.46,.46), CFrame.new(0,0,-.46) * CFrame.Angles(0,math.pi/2,0), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
    piece("LensGlass", Vector3.new(.06,.34,.34), CFrame.new(0,0,-.57) * CFrame.Angles(0,math.pi/2,0), Color3.fromRGB(75,180,205), Enum.Material.Glass, Enum.PartType.Cylinder)
    piece("StatusLight", Vector3.new(.09,.09,.05), CFrame.new(.42,.18,-.42), Color3.fromRGB(255,80,74), Enum.Material.Neon)
    piece("MountArm", Vector3.new(.14,.14,.44), CFrame.new(0,0,.53), housing, Enum.Material.Metal)
    piece("MountBase", Vector3.new(.48,.42,.10), CFrame.new(0,0,.80), dark, Enum.Material.Metal)
    local labelGui = make("BillboardGui", body, {Size = UDim2.fromOffset(120, 22), StudsOffset = Vector3.new(0,1,0), AlwaysOnTop = true, MaxDistance = 100})
    labelGui.Enabled = not ghost
    local modelLabel = text(labelGui, model.Name, 0, 0, 120, 22, 11, C.text)
    modelLabel.TextXAlignment = Enum.TextXAlignment.Center
    local attachedCamera = make("Camera", model, {Name = "ViewCamera", CameraType = Enum.CameraType.Scriptable, CFrame = mount})
    model.PrimaryPart = body
    model.Parent = workspace
    return {name = name, model = model, body = body, camera = attachedCamera,
        pieces = pieces, labelGui = labelGui, label = modelLabel, yaw = 0, pitch = 0}
end
local function cancelPreview()
    selecting = false
    if previewModel then previewModel:Destroy() end
    previewModel, previewItem, previewTarget, previewMount = nil, nil, nil, nil
    pick.Text = "ADD CAMERA"
end
-- Use one fresh raycast for both the selected part and the hit surface; legacy
-- Mouse.Target/Mouse.Hit can disagree with an unlocked cursor in first person.
local function placementUnderCursor()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local pointer = Input:GetMouseLocation()
    local ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 2048, params)
    if not hit or not hit.Instance:IsA("BasePart") or not hit.Instance:IsDescendantOf(workspace) then return nil end
    local normal = hit.Normal.Unit
    -- MountBase ends .85 studs behind the body center, placing it on the hit surface.
    local position = hit.Position + normal * .85
    local up = math.abs(normal:Dot(Vector3.yAxis)) > .98 and Vector3.xAxis or Vector3.yAxis
    return hit.Instance, CFrame.lookAt(position, position + normal, up)
end
connect(movement.Activated, function() cancelPreview(); showCameraPage(false) end)
connect(camClose.Activated, function() cancelPreview(); showCameraPage(false) end)
connect(pick.Activated, function()
    if selecting then cancelPreview(); statusCam.Text = "Placement cancelled"; return end
    selecting = true
    previewItem = createCameraModel(CFrame.new(0, -10000, 0), "Preview", true)
    previewModel = previewItem.model
    pick.Text = "CANCEL"
    statusCam.Text = "Move the mouse and click a part to place Camera " .. nextCameraNumber
end)
connect(Input.InputBegan, function(input, processed)
    if selecting and input.KeyCode == Enum.KeyCode.Escape then cancelPreview(); statusCam.Text = "Placement cancelled"; return end
    if not selecting or processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local part, mount = placementUnderCursor()
    if not part or not mount or not previewItem then statusCam.Text = "No valid surface under cursor; try again"; return end
    local item = previewItem
    item.name = "Camera " .. nextCameraNumber
    nextCameraNumber = nextCameraNumber + 1
    item.model.Name, item.label.Text = item.name, item.name
    item.labelGui.Enabled = true
    for _, component in ipairs(item.pieces) do component.part.Transparency = 0 end
    item.part, item.offset = part, part.CFrame:ToObjectSpace(mount)
    local forward = mount.LookVector
    item.baseYaw = math.atan2(-forward.X, -forward.Z)
    item.basePitch = math.asin(math.clamp(forward.Y, -1, 1))
    previewModel, previewItem, previewTarget, previewMount = nil, nil, nil, nil
    selecting = false
    pick.Text = "ADD CAMERA"
    table.insert(cams, item)
    selected = #cams
    statusCam.Text = "Added " .. item.name .. " on " .. part.Name
    updateList()
end)
connect(watch.Activated, function() if viewing then cameraStop() else startView() end end)
connect(stop.Activated, cameraStop)
connect(removeCam.Activated, function()
    if cams[selected] then
        cameraStop(); cams[selected].model:Destroy(); table.remove(cams, selected); selected = math.min(selected, #cams)
        statusCam.Text = selected > 0 and "Selected: " .. cams[selected].name or "No camera selected"
        updateList()
    end
end)
connect(left.Activated, function() if viewing and cams[selected] then cams[selected].tryLook(orbitYaw - math.rad(25), orbitPitch) end end)
connect(right.Activated, function() if viewing and cams[selected] then cams[selected].tryLook(orbitYaw + math.rad(25), orbitPitch) end end)
connect(zoomIn.Activated, function()
    if not viewing then return end
    if viewCamera then viewCamera.FieldOfView = math.max(15, viewCamera.FieldOfView - 5) end
end)
connect(zoomOut.Activated, function()
    if not viewing then return end
    if viewCamera then viewCamera.FieldOfView = math.min(100, viewCamera.FieldOfView + 5) end
end)
connect(Input.InputBegan, function(input)
    if viewing and input.UserInputType == Enum.UserInputType.MouseButton2 then
        viewingMouse = true
        cameraLooking = true
        Input.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)
connect(Input.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and viewingMouse then
        viewingMouse = false
        cameraLooking = false
        if viewState and viewState.mouse then Input.MouseBehavior = viewState.mouse end
    end
end)
connect(Input.WindowFocusReleased, function()
    if viewingMouse then
        viewingMouse = false
        cameraLooking = false
        if viewState and viewState.mouse then Input.MouseBehavior = viewState.mouse end
    end
end)
local mountStep = Run.RenderStepped:Connect(function()
    if selecting and previewItem and previewModel and previewModel.Parent then
        local target, mount = placementUnderCursor()
        if target and mount then
            previewTarget, previewMount = target, mount
            for _, component in ipairs(previewItem.pieces) do
                component.part.CFrame = mount * component.offset
                component.part.LocalTransparencyModifier = 0
            end
        else
            previewTarget, previewMount = nil, nil
            for _, component in ipairs(previewItem.pieces) do component.part.LocalTransparencyModifier = 1 end
        end
    end
    for _, item in ipairs(cams) do
        if not item.broken and item.part:IsDescendantOf(workspace) and item.model.Parent and item.body.Parent then
            local mount = item.part.CFrame * item.offset
            local head = CFrame.new(mount.Position) * CFrame.fromOrientation(item.basePitch + item.pitch, item.baseYaw + item.yaw, 0)
            for _, component in ipairs(item.pieces) do
                component.part.CFrame = (component.rotates and head or mount) * component.offset
            end
        elseif not item.broken then
            item.broken = true
            if item.model.Parent then item.model:Destroy() end
            if cams[selected] == item then
                if viewing then cameraStop() end
                statusCam.Text = item.name .. " BROKEN - attachment or camera was destroyed"
            end
            updateList()
        end
    end
end)
clearBoxes = function()
    for _, frame in pairs(boxFrames) do frame:Destroy() end
    boxFrames = {}
end
connect(boxes.Activated, function()
    boxesEnabled = not boxesEnabled
    boxes.Text = boxesEnabled and "BOXES: ON" or "BOXES: OFF"
    if not boxesEnabled then clearBoxes() end
end)
connect(Players.PlayerRemoving, function(other)
    if boxFrames[other] then boxFrames[other]:Destroy(); boxFrames[other] = nil end
end)
local boxStep = Run.RenderStepped:Connect(function(dt)
    if not boxesEnabled or not viewing then return end
    boxTick = boxTick + dt
    if boxTick < .1 then return end
    boxTick = 0
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local function project(point)
        return camera:WorldToScreenPoint(point)
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = player.Character and {player.Character} or {}
    rayParams.IgnoreWater = true
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character or boxFrames[other] then
            local model = other.Character
            local root = model and model:FindFirstChild("HumanoidRootPart")
            local frame = boxFrames[other]
            if not frame then
                frame = make("Frame", gui, {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
                make("UIStroke", frame, {Color = C.accent, Thickness = 2})
                local tag = text(frame, other.DisplayName .. (other == player and " (YOU)" or ""), 0, -18, 150, 18, 10, C.accent)
                tag.TextTruncate = Enum.TextTruncate.AtEnd
                boxFrames[other] = frame
            end
            frame.Visible = false
            if root and model.Parent then
                local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
                if ok then
                    local minX, minY, maxX, maxY, valid = math.huge, math.huge, -math.huge, -math.huge, true
                    for _, x in ipairs({-1,1}) do for _, y in ipairs({-1,1}) do for _, z in ipairs({-1,1}) do
                        local point = project(cf:PointToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
                        if point.Z <= .1 then valid = false end
                        minX, minY = math.min(minX,point.X), math.min(minY,point.Y)
                        maxX, maxY = math.max(maxX,point.X), math.max(maxY,point.Y)
                    end end end
                    local unobstructed = false
                    if valid and maxX > 0 and maxY > 0 and minX < viewport.X and minY < viewport.Y then
                        for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
                            local target = model:FindFirstChild(name)
                            if target and target:IsA("BasePart") then
                                local projected, onScreen = project(target.Position)
                                if onScreen and projected.Z > 0 then
                                    local ray = workspace:Raycast(camera.CFrame.Position, target.Position - camera.CFrame.Position, rayParams)
                                    if not ray or ray.Instance:IsDescendantOf(model) then unobstructed = true; break end
                                end
                            end
                        end
                    end
                    if unobstructed then
                        minX, minY = math.max(0,minX), math.max(0,minY)
                        maxX, maxY = math.min(viewport.X,maxX), math.min(viewport.Y,maxY)
                        frame.Position, frame.Size, frame.Visible = UDim2.fromOffset(minX,minY), UDim2.fromOffset(maxX-minX,maxY-minY), true
                    end
                end
            end
        end
    end
end)
cameraCleanup = function()
    selecting, boxesEnabled = false, false
    cancelPreview()
    cameraStop()
    boxStep:Disconnect()
    mountStep:Disconnect()
    for _, item in ipairs(cams) do item.model:Destroy() end
    cams = {}
    clearBoxes()
    camPanel:Destroy()
end

-- Local R6 ownership experiment. Server/other-player visibility is not guaranteed.
local r6Physical = (function()
    local active, heartbeat, deathConnection, records = false, nil, nil, {}
    local activeCharacter, activeTorso, lastReason = nil, nil, "off"
    local buttonR6 = button(sidebar, "04   R6 PHYS: OFF", 10, 190, 130, 37)
    buttonR6.Visible = false
    buttonR6.TextSize = 10
    local function draw()
        buttonR6.Text = active and "04   R6 PHYS: ON" or "04   R6 PHYS: OFF"
        buttonR6.TextColor3 = active and C.accent or C.text
        buttonR6.BackgroundColor3 = active and Color3.fromRGB(31, 65, 61) or C.panel
    end
    local function stop(reason)
        active = false
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
        if deathConnection then deathConnection:Disconnect(); deathConnection = nil end
        local restored, propertiesRestored = 0, 0
        for _, arm in ipairs(records) do
            pcall(function()
                if arm.joint.Parent and arm.part.Parent and arm.joint.Part1 == nil then
                    if arm.joint.Part0 and arm.joint.Part0.Parent and arm.part.AssemblyRootPart
                        and arm.part.AssemblyRootPart ~= arm.joint.Part0.AssemblyRootPart then
                        arm.part.CFrame = arm.joint.Part0.CFrame * arm.joint.C0 * arm.joint.Transform * arm.joint.C1:Inverse()
                        arm.part.AssemblyLinearVelocity = arm.joint.Part0.AssemblyLinearVelocity
                        arm.part.AssemblyAngularVelocity = Vector3.zero
                    end
                    arm.joint.Part1 = arm.part
                end
                if arm.joint.Parent and arm.joint.Part1 == arm.part then restored = restored + 1 end
            end)
            pcall(function()
                if arm.part.Parent then
                    arm.part.CanCollide = arm.canCollide
                    arm.part.CanTouch = arm.canTouch
                    arm.part.Massless = arm.massless
                    if arm.part.CanCollide == arm.canCollide and arm.part.CanTouch == arm.canTouch
                        and arm.part.Massless == arm.massless then propertiesRestored = propertiesRestored + 1 end
                end
            end)
        end
        records, activeCharacter, activeTorso = {}, nil, nil
        lastReason = reason or "stopped"
        draw()
        return restored, propertiesRestored
    end
    stopPhysicalDance = stop
    local function start()
        if active then return true end
        local model = player.Character
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        local torso = model and model:FindFirstChild("Torso")
        if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 or humanoid.Health <= 0 or not torso then
            lastReason = "A living R6 character is required"
            return false, lastReason
        end
        local prepared = {}
        for _, info in ipairs({{"Left Shoulder", "Left Arm", -1}, {"Right Shoulder", "Right Arm", 1}}) do
            local joint, part = torso:FindFirstChild(info[1]), model:FindFirstChild(info[2])
            if not joint or not joint:IsA("Motor6D") or not part or not part:IsA("BasePart") or joint.Part1 ~= part then
                lastReason = "Both original R6 shoulders and arms are required"
                return false, lastReason
            end
            table.insert(prepared, {joint = joint, part = part, side = info[3],
                canCollide = part.CanCollide, canTouch = part.CanTouch, massless = part.Massless})
        end
        stopDance()
        stopRobloxDance()
        records, activeCharacter, activeTorso, active = prepared, model, torso, true
        local ok, err = pcall(function()
            for _, arm in ipairs(records) do
                arm.joint.Part1 = nil
                arm.part.CanCollide = false
                arm.part.CanTouch = false
                arm.part.Massless = true
            end
        end)
        if not ok then stop("detach failed: " .. tostring(err)); return false, lastReason end
        local started = os.clock()
        deathConnection = humanoid.Died:Connect(function() stop("character died") end)
        heartbeat = Run.Heartbeat:Connect(function()
            if not activeCharacter or player.Character ~= activeCharacter or not activeCharacter.Parent
                or not activeTorso or not activeTorso.Parent then stop("character changed"); return end
            local t = os.clock() - started
            for _, arm in ipairs(records) do
                if not arm.part:IsDescendantOf(activeCharacter) or not arm.joint.Parent or arm.joint.Part1 ~= nil then
                    stop("arm or joint changed"); return
                end
                -- A write to a shared assembly would also move the torso.
                if not arm.part.AssemblyRootPart or arm.part.AssemblyRootPart == activeTorso.AssemblyRootPart then
                    stop("arm shares torso assembly"); return
                end
            end
            for _, arm in ipairs(records) do
                local good = pcall(function()
                    local angle = math.sin(t * 16) * 2
                    arm.part.CFrame = activeTorso.CFrame * CFrame.new(1.5 * arm.side, 0, 0)
                        * CFrame.Angles(angle * arm.side, 0, math.cos(t * 11) * .5)
                    arm.part.AssemblyLinearVelocity = activeTorso.AssemblyLinearVelocity
                    arm.part.AssemblyAngularVelocity = Vector3.zero
                end)
                if not good then stop("physics update failed"); return end
            end
        end)
        lastReason = "running"
        draw()
        return true
    end
    local function status()
        local arms = {}
        for _, arm in ipairs(records) do
            local owned = "unavailable"
            if type(isnetworkowner) == "function" then
                local ok, value = pcall(isnetworkowner, arm.part)
                if ok then owned = value end
            end
            arms[arm.part.Name] = {client_owns_reported = owned,
                detached = arm.joint.Part1 == nil,
                own_assembly = arm.part.AssemblyRootPart == arm.part}
        end
        return {enabled = active, reason = lastReason, arms = arms,
            visibility_to_others = "unverified"}
    end
    connect(buttonR6.Activated, function()
        if active then stop("disabled by user")
        else
            local ok, err = start()
            if not ok then buttonR6.Text = "R6 UNAVAILABLE"; warn("[VECTOR] " .. tostring(err)) end
        end
    end)
    LiveMCP.register("r6_physics_dance", function(args)
        assert(type(args.enabled) == "boolean", "enabled must be a boolean")
        if args.enabled then
            local ok, err = start()
            assert(ok, err)
        else
            local restored, propertiesRestored = stop("disabled via MCP")
            local result = status()
            result.restored_joints = restored
            result.restored_arm_properties = propertiesRestored
            return result
        end
        return status()
    end)
    LiveMCP.register("r6_physics_status", function() return status() end)
    return {status = status}
end)()

local animationMenu = button(sidebar, "03   ANIMATIONS", 10, 144, 130, 37)
local animationPanel = make("Frame", window, {Name = "AnimationPanel", Size = UDim2.new(1, -150, 1, -69),
    Position = UDim2.fromOffset(150, 69), BackgroundColor3 = C.bg,
    BorderSizePixel = 0, Visible = false, ZIndex = 30})
text(animationPanel, "Playing animations", 22, 19, 360, 32, 25).Font = Enum.Font.GothamBold
text(animationPanel, "Live character tracks  /  click a row to copy its ID", 23, 56, 440, 18, 11, C.muted)
local animationClose = button(animationPanel, "BACK", 403, 20, 65, 28)
local animationStatus = text(animationPanel, "Waiting for character...", 22, 82, 440, 18, 10, C.accent)
local captureButton = button(animationPanel, "RECORD: OFF", 22, 107, 105, 32)
local copyCapture = button(animationPanel, "COPY JSON", 135, 107, 113, 32)
local captureStatus = text(animationPanel, "Record, then copy JSON", 22, 145, 440, 18, 10, C.muted)
local animationList = make("ScrollingFrame", animationPanel, {Position = UDim2.fromOffset(22, 168),
    Size = UDim2.new(1, -44, 1, -186), BackgroundColor3 = C.panel, BorderSizePixel = 0,
    ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
corner(animationList, 5)
make("UIListLayout", animationList, {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
local capture, captureStarted, captureConnections = nil, nil, {}
local captureOn, captureLastSample = false, 0
local function captureBucket(now)
    local second = math.floor(now - captureStarted)
    if second >= 60 then return nil end
    local index = second + 1
    if not capture.seconds[index] then
        capture.seconds[index] = {second = second, rapid = 0, space = 0, switches = 0,
            sequence = "", sequence_truncated = false, samples = 0, rapid_position_sum = 0,
            space_position_sum = 0, rapid_samples = 0, space_samples = 0}
    end
    return capture.seconds[index]
end
local capturePrevious
stopAnimationCapture = function()
    if not captureOn then return end
    captureOn = false
    capture.duration_seconds = math.floor((os.clock() - captureStarted) * 1000 + .5) / 1000
    for _, connection in ipairs(captureConnections) do connection:Disconnect() end
    captureConnections = {}
    captureButton.Text = "RECORD: OFF"
    captureButton.TextColor3 = C.text
    captureStatus.Text = string.format("%.1fs recorded; copy JSON", capture.duration_seconds)
end
connect(captureButton.Activated, function()
    if captureOn then stopAnimationCapture(); return end
    local model = player.Character
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then captureStatus.Text = "No Animator found"; return end
    capture = {version = 2, note = "Each bucket counts observed AnimationPlayed events. R=RapidSlash; S=Space Sword Swing. Samples are client-observed. Final second may be partial.", seconds = {}}
    captureStarted, captureLastSample, captureOn, capturePrevious = os.clock(), 0, true, nil
    captureButton.Text = "RECORD: ON"
    captureButton.TextColor3 = C.accent
    table.insert(captureConnections, animator.AnimationPlayed:Connect(function(track)
        local ok, id, speed, position = pcall(function()
            return track.Animation and track.Animation.AnimationId or "", track.Speed, track.TimePosition
        end)
        if not ok then return end
        local symbol = id:match("72042024$") and "R" or (id:match("168268306$") and "S" or nil)
        if not symbol then return end
        local bucket = captureBucket(os.clock())
        if not bucket then stopAnimationCapture(); return end
        if symbol == "R" then bucket.rapid = bucket.rapid + 1 else bucket.space = bucket.space + 1 end
        if capturePrevious and capturePrevious ~= symbol then bucket.switches = bucket.switches + 1 end
        capturePrevious = symbol
        if #bucket.sequence < 80 then bucket.sequence = bucket.sequence .. symbol else bucket.sequence_truncated = true end
        bucket.last_play_speed, bucket.last_play_position = speed, position
    end))
    table.insert(captureConnections, Run.Heartbeat:Connect(function()
        if player.Character ~= model or not model.Parent then stopAnimationCapture(); return end
        local now = os.clock()
        if now - captureLastSample < .05 then return end
        captureLastSample = now
        local bucket = captureBucket(now)
        if not bucket then stopAnimationCapture(); return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function()
                local id = track.Animation and track.Animation.AnimationId or ""
                if id:match("72042024$") then
                    bucket.rapid_samples = bucket.rapid_samples + 1
                    bucket.rapid_position_sum = bucket.rapid_position_sum + track.TimePosition
                    bucket.rapid_speed = track.Speed
                elseif id:match("168268306$") then
                    bucket.space_samples = bucket.space_samples + 1
                    bucket.space_position_sum = bucket.space_position_sum + track.TimePosition
                    bucket.space_speed = track.Speed
                end
            end)
        end
        bucket.samples = bucket.samples + 1
        captureStatus.Text = string.format("Recording %.1fs  /  Rapid %d  Space %d", now - captureStarted, bucket.rapid, bucket.space)
    end))
end)
connect(copyCapture.Activated, function()
    if not capture then captureStatus.Text = "Record first"; return end
    if captureOn then stopAnimationCapture() end
    local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode(capture) end)
    local copy = setclipboard or toclipboard
    if ok and type(copy) == "function" and pcall(copy, json) then
        captureStatus.Text = "JSON copied; paste it into chat"
    elseif ok then
        local overlay = make("Frame", gui, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg})
        local box = make("TextBox", overlay, {Size = UDim2.new(.8, 0, .65, 0), Position = UDim2.new(.1, 0, .15, 0),
            BackgroundColor3 = C.panel, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Code,
            Text = json, MultiLine = true, ClearTextOnFocus = false, TextWrapped = false})
        local done = button(overlay, "COPY TEXT / CLOSE", 20, 20, 210, 32)
        done.Activated:Connect(function() overlay:Destroy() end)
        box:CaptureFocus()
    else captureStatus.Text = "JSON encode failed" end
end)
local pinnedAnimations = {}
local function showAnimations(show)
    animationPanel.Visible = show
    animationMenu.TextColor3 = show and C.accent or C.text
    animationMenu.BackgroundColor3 = show and Color3.fromRGB(31, 65, 61) or C.panel
end
connect(animationMenu.Activated, function() showCameraPage(false); showAnimations(true) end)
connect(animationClose.Activated, function() showAnimations(false) end)
connect(movement.Activated, function() showAnimations(false) end)
connect(camMenu.Activated, function() showAnimations(false) end)
local playMenu = button(sidebar, "04   PLAY ANIMATION", 10, 190, 130, 37)
playMenu.TextSize = 10
local playPanel = make("Frame", window, {Name = "PlayAnimationPanel", Size = UDim2.new(1, -150, 1, -69),
    Position = UDim2.fromOffset(150, 69), BackgroundColor3 = C.bg, BorderSizePixel = 0, Visible = false, ZIndex = 30})
text(playPanel, "Play animation", 22, 19, 360, 32, 25).Font = Enum.Font.GothamBold
text(playPanel, "Add an ID, then toggle one or more animations.", 23, 56, 440, 18, 11, C.muted)
local playClose = button(playPanel, "BACK", 403, 20, 65, 28)
local idInput = make("TextBox", playPanel, {Position = UDim2.fromOffset(22, 86), Size = UDim2.fromOffset(320, 34),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, TextColor3 = C.text, PlaceholderColor3 = C.muted,
    PlaceholderText = "Paste animation ID or rbxassetid://...", Text = "", TextSize = 12,
    Font = Enum.Font.GothamMedium, ClearTextOnFocus = false})
corner(idInput, 6)
local addAnimation = button(playPanel, "ADD", 350, 86, 118, 34)
addAnimation.TextColor3 = C.accent
local playStatus = text(playPanel, "Tap PLAY to loop an animation", 22, 126, 445, 18, 10, C.muted)
local playList = make("ScrollingFrame", playPanel, {Position = UDim2.fromOffset(22, 151),
    Size = UDim2.new(1, -44, 1, -169), BackgroundColor3 = C.panel, BorderSizePixel = 0,
    ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
corner(playList, 5)
make("UIListLayout", playList, {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
local playEntries = {}
local animationFile = "animations.json"
local http = game:GetService("HttpService")
local function savePlayEntries()
    if type(writefile) ~= "function" then
        playStatus.Text = "Executor cannot save files; changes last for this session"
        return false
    end
    local ok = pcall(function() writefile(animationFile, http:JSONEncode({version = 1, animations = playEntries})) end)
    if not ok then playStatus.Text = "Could not save animations.json" end
    return ok
end
if type(readfile) == "function" then
    pcall(function()
        local saved = http:JSONDecode(readfile(animationFile))
        if type(saved) ~= "table" then return end
        if type(saved.animations) == "table" then saved = saved.animations end
        local found, loaded = {}, {}
        for _, entry in ipairs(saved) do
            if type(entry) == "table" and type(entry.id) == "string" and entry.id:match("^%d+$") and not found[entry.id] then
                found[entry.id] = true
                table.insert(loaded, {id = entry.id, enabled = entry.enabled == true})
            end
        end
        playEntries = loaded
    end)
end
local playTracks, playAnimator = {}, nil
local function clearPlayTrack(id)
    local track = playTracks[id]
    if track then pcall(function() track:Stop(.1); track:Destroy() end); playTracks[id] = nil end
end
local function drawPlayEntries()
    for _, child in ipairs(playList:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    for i, entry in ipairs(playEntries) do
        local row = make("Frame", playList, {Size = UDim2.new(1, -8, 0, 38), BackgroundColor3 = C.bg,
            BorderSizePixel = 0, LayoutOrder = i})
        corner(row, 5)
        text(row, "rbxassetid://" .. entry.id, 10, 4, 235, 30, 11, C.text).TextTruncate = Enum.TextTruncate.AtEnd
        local togglePlay = button(row, entry.enabled and "ON" or "PLAY", 0, 3, 65, 32)
        togglePlay.Position = UDim2.new(1, -137, 0, 3)
        togglePlay.TextColor3 = entry.enabled and C.accent or C.text
        local remove = button(row, "X", 0, 3, 56, 32)
        remove.Position = UDim2.new(1, -60, 0, 3)
        togglePlay.Activated:Connect(function()
            entry.enabled = not entry.enabled
            if not entry.enabled then clearPlayTrack(entry.id) end
            savePlayEntries(); drawPlayEntries()
        end)
        remove.Activated:Connect(function()
            clearPlayTrack(entry.id)
            for index, item in ipairs(playEntries) do if item == entry then table.remove(playEntries, index); break end end
            if savePlayEntries() then playStatus.Text = "Deleted " .. entry.id .. " from JSON" end
            drawPlayEntries()
        end)
    end
end
connect(addAnimation.Activated, function()
    local value = idInput.Text:match("^%s*(.-)%s*$")
    local id = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
    if not id then playStatus.Text = "Enter a numeric ID or rbxassetid://ID"; return end
    for _, entry in ipairs(playEntries) do if entry.id == id then playStatus.Text = "Already added"; return end end
    table.insert(playEntries, {id = id, enabled = false})
    idInput.Text = ""
    if savePlayEntries() then playStatus.Text = "Saved " .. id .. " to JSON" end
    drawPlayEntries()
end)
local function showPlay(show)
    playPanel.Visible = show
    playMenu.TextColor3 = show and C.accent or C.text
    playMenu.BackgroundColor3 = show and Color3.fromRGB(31, 65, 61) or C.panel
end
connect(playMenu.Activated, function() showCameraPage(false); showAnimations(false); showPlay(true) end)
connect(playClose.Activated, function() showPlay(false) end)
connect(movement.Activated, function() showPlay(false) end)
connect(camMenu.Activated, function() showPlay(false) end)
connect(animationMenu.Activated, function() showPlay(false) end)
LiveMCP.onCleanup(function() for id in pairs(playTracks) do clearPlayTrack(id) end end)
drawPlayEntries()
task.spawn(function()
    while not disposed do
        local model = player.Character
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if animator ~= playAnimator then
            for id in pairs(playTracks) do clearPlayTrack(id) end
            playAnimator = animator
        end
        local state = humanoid and humanoid:GetState()
        local ready = humanoid and humanoid.Health > 0 and animator and state ~= Enum.HumanoidStateType.Physics
            and state ~= Enum.HumanoidStateType.Ragdoll and state ~= Enum.HumanoidStateType.FallingDown
            and state ~= Enum.HumanoidStateType.GettingUp
        if ready then
            for _, entry in ipairs(playEntries) do
                if entry.enabled then
                    local track = playTracks[entry.id]
                    if not track then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = "rbxassetid://" .. entry.id
                        local ok, loaded = pcall(function() return animator:LoadAnimation(anim) end)
                        anim:Destroy()
                        if ok and loaded then
                            track = loaded
                            playTracks[entry.id] = track
                            pcall(function() track.Priority = Enum.AnimationPriority.Action; track.Looped = true end)
                        else playStatus.Text = "Could not load " .. entry.id end
                    end
                    if track then
                        local ok, playing = pcall(function() return track.IsPlaying end)
                        if ok and not playing then pcall(function() track:Play(.15) end) end
                        if not ok then clearPlayTrack(entry.id) end
                    end
                end
            end
        end
        task.wait(.5)
    end
end)
task.spawn(function()
    while not disposed do
        if animationPanel.Visible then
            for _, child in ipairs(animationList:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
            local model = player.Character
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            local ok, tracks = false, nil
            if animator then ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end) end
            if not ok then tracks = {} end
            animationStatus.Text = ok and (tostring(#tracks) .. " track(s) playing  /  updates every 0.5s") or "No Animator found on your character"
            do
                local entries, seen = {}, {}
                for _, track in ipairs(tracks) do
                    local okTrack, entry = pcall(function()
                        local anim = track.Animation
                        return {id = anim and anim.AnimationId or "unknown", name = anim and anim.Name or track.Name,
                            priority = track.Priority.Name, playing = true}
                    end)
                    if okTrack and not seen[entry.id] then
                        seen[entry.id] = true
                        table.insert(entries, entry)
                    end
                end
                for id, entry in pairs(pinnedAnimations) do
                    if not seen[id] then
                        table.insert(entries, {id = id, name = entry.name, priority = entry.priority, playing = false})
                    end
                end
                table.sort(entries, function(a, b)
                    local ap, bp = pinnedAnimations[a.id] ~= nil, pinnedAnimations[b.id] ~= nil
                    if ap ~= bp then return ap end
                    return a.id < b.id
                end)
                for i, entry in ipairs(entries) do
                    local item = make("Frame", animationList, {Size = UDim2.new(1, -8, 0, 34),
                        BackgroundColor3 = C.bg, BorderSizePixel = 0, LayoutOrder = i})
                    corner(item, 5)
                    local row = button(item, entry.name .. " | " .. entry.id .. " | " .. entry.priority
                        .. (entry.playing and "" or " | stopped"), 0, 0, 350, 34)
                    row.Size = UDim2.new(1, -75, 1, 0)
                    row.TextTruncate = Enum.TextTruncate.AtEnd
                    local pin = button(item, pinnedAnimations[entry.id] and "PINNED" or "PIN", 0, 0, 70, 34)
                    pin.Position = UDim2.new(1, -70, 0, 0)
                    pin.BackgroundColor3 = pinnedAnimations[entry.id] and Color3.fromRGB(31, 100, 80) or Color3.fromRGB(31, 65, 61)
                    pin.TextColor3 = C.accent
                    pin.Activated:Connect(function()
                        if entry.id == "unknown" or entry.id == "" then return end
                        if pinnedAnimations[entry.id] then pinnedAnimations[entry.id] = nil
                        else pinnedAnimations[entry.id] = {name = entry.name, priority = entry.priority} end
                    end)
                    row.Activated:Connect(function()
                        local copy = setclipboard or toclipboard
                        if type(copy) == "function" and entry.id ~= "unknown" then
                            local copied = pcall(copy, entry.id)
                            animationStatus.Text = copied and ("Copied: " .. entry.id) or "Copy failed"
                        else animationStatus.Text = "Clipboard unavailable" end
                    end)
                end
            end
        end
        task.wait(.5)
    end
end)
do
    local espOn, watchers, labels = false, {}, {}
    local options={ultOnly=false,baldOnly=false,ultimate=true,meter=true}
    local tracked={}
    local notifications=LiveMCP.track(make("ScreenGui",playerGui,{Name="VectorESPNotices",ResetOnSpawn=false,DisplayOrder=120}))
    local noticeList=make("Frame",notifications,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,60),Size=UDim2.fromOffset(310,260),BackgroundTransparency=1})
    make("UIListLayout",noticeList,{Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Right})
    local function notice(text,color)
        local item=make("TextLabel",noticeList,{Size=UDim2.fromOffset(300,38),BackgroundColor3=Color3.fromRGB(14,21,30),BackgroundTransparency=.2,TextColor3=color,Text=text,Font=Enum.Font.GothamBold,TextSize=12,TextWrapped=true,BorderSizePixel=0})
        corner(item,6);task.delay(4,function() if item.Parent then item:Destroy() end end)
    end
    local espButton = button(sidebar, "ESP: OFF", 10, 374, 130, 37)
    espButton.TextSize = 10

    local function removeLabel(other)
        local label = labels[other]
        labels[other] = nil
        if label then label:Destroy() end
    end
    local function attach(other, model)
        removeLabel(other)
        task.spawn(function()
            local head = model:FindFirstChild("Head") or model:WaitForChild("Head", 10)
            if not espOn or disposed or other.Character ~= model or not other.Parent or not head or not head:IsA("BasePart") then return end
            removeLabel(other)
            local marker = make("BillboardGui", gui, {
                Name = "VectorPlayerESP", Adornee = head, AlwaysOnTop = true,
                Size = UDim2.fromOffset(190, 40), StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0),
                MaxDistance = 0, LightInfluence = 0,
            })
            local name = make("TextLabel", marker, {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                Text = "•  " .. other.DisplayName, TextColor3 = Color3.fromRGB(168, 241, 210),
                TextTransparency = .18, TextStrokeTransparency = .55,
                TextSize = 11, Font = Enum.Font.GothamMedium, TextWrapped=true,
            })
            labels[other] = marker
        end)
    end
    local function unwatch(other)
        local watcher = watchers[other]
        if watcher then
            watcher.added:Disconnect()
            watcher.removing:Disconnect()
            watchers[other] = nil
        end
        removeLabel(other)
        tracked[other]=nil
    end
    local function watch(other)
        if other == player or watchers[other] then return end
        watchers[other] = {
            added = other.CharacterAdded:Connect(function(model) attach(other, model) end),
            removing = other.CharacterRemoving:Connect(function() removeLabel(other) end),
        }
        if other.Character then attach(other, other.Character) end
    end
    local function setESP(enabled)
        espOn = enabled
        espButton.Text = enabled and "ESP: ALL" or "ESP: OFF"
        espButton.TextColor3 = enabled and C.accent or C.text
        if enabled then
            for _, other in ipairs(Players:GetPlayers()) do watch(other) end
        else
            local existing = {}
            for other in pairs(watchers) do table.insert(existing, other) end
            for _, other in ipairs(existing) do unwatch(other) end
        end
    end
    setESPExternal = setESP
    setESPOptionExternal=function(key,value) if options[key]~=nil then options[key]=value end end
    task.spawn(function()
        while not disposed do
            if espOn then
                local now=os.clock()
                for other,marker in pairs(labels) do
                    local model=other.Character
                    local label=marker:FindFirstChildWhichIsA("TextLabel")
                    if model and label then
                        local characterType=model:GetAttribute("Character")
                        local bald=characterType=="Bald"
                        local ult=model:GetAttribute("Ulted")==true
                        local counter=model:GetAttribute("HoldingDeathCounter")==true
                        local state=tracked[other]
                        if not state or state.model~=model then
                            state={model=model,ult=ult,counter=counter,counterUntil=counter and now+10 or nil}
                            tracked[other]=state
                        end
                        local characterName=bald and "SAITAMA" or (type(characterType)=="string" and characterType~="" and characterType or "UNKNOWN")
                        if counter and not state.counter then state.counterUntil=now+10 end
                        if options.ultimate then
                            if ult and not state.ult then notice(other.DisplayName.." · "..characterName.." ULT!",Color3.fromRGB(255,200,90)) end
                            if not ult and state.ult then notice(other.DisplayName.." · "..characterName.." ULT ĐÃ HẾT",Color3.fromRGB(170,220,255)) end
                            if counter and not state.counter then
                                notice(other.DisplayName.." · DEATH COUNTER!",Color3.fromRGB(255,80,80))
                            end
                            if state.counterUntil and now>=state.counterUntil then
                                state.counterUntil=nil;notice(other.DisplayName.." · DEATH COUNTER HẾT 10 GIÂY",Color3.fromRGB(255,170,120))
                            end
                        end
                        state.ult=ult;state.counter=counter
                        local alert=state.counterUntil and now<state.counterUntil
                        local rage=other:GetAttribute("Ultimate")
                        local line=other.DisplayName.." · "..characterName..(ult and " · ULT" or "")
                        if options.meter then line=line.."\nNỘ: "..(type(rage)=="number" and (tostring(math.floor(math.clamp(rage,0,100)+.5)).."%") or "?") end
                        if alert then line="⚠ DEATH COUNTER ⚠\n"..line end
                        label.Text=line;label.TextSize=alert and 16 or 11
                        label.Font=alert and Enum.Font.GothamBlack or Enum.Font.GothamMedium
                        label.TextColor3=alert and Color3.fromRGB(255,45,45) or Color3.fromRGB(168,241,210)
                        marker.StudsOffsetWorldSpace=Vector3.new(alert and math.sin(now*32)*.24 or 0,alert and 3 or 2.6,0)
                        marker.Enabled=(not options.ultOnly or ult or alert) and (not options.baldOnly or bald)
                    end
                end
            end
            task.wait(.08)
        end
    end)
    connect(espButton.Activated, function() setESP(not espOn) end)
    connect(Players.PlayerAdded, function(other) if espOn then watch(other) end end)
    connect(Players.PlayerRemoving, unwatch)
    LiveMCP.onCleanup(function() setESP(false) end)
end

do
(function()
-- Combat workspace: one bounded scheduler, opt-in controls and persistent settings.
local combatConfig = {mode = "Random", position = "Under", predict = true, speed = false,
    safe = true, void = true, selected = {}, blacklist = {}, skills = false}
local combatOn, combatTarget, combatCalls, combatErrors, combatIndex = false, nil, 0, 0, 0
local isStrongestBattlegrounds = game.GameId == 3808081382 or game.PlaceId == 10449761463
local combatHttp = game:GetService("HttpService")
if type(readfile) == "function" then
    pcall(function()
        local data = combatHttp:JSONDecode(readfile("combat.json"))
        for _, k in ipairs({"predict", "speed", "safe", "void", "skills"}) do
            if type(data[k]) == "boolean" then combatConfig[k] = data[k] end
        end
        if table.find({"Random", "Selected", "Multi"}, data.mode) then combatConfig.mode = data.mode end
        if table.find({"Under", "Circle"}, data.position) then combatConfig.position = data.position end
        for _, k in ipairs({"selected", "blacklist"}) do
            if type(data[k]) == "table" then
                for id, v in pairs(data[k]) do if tostring(id):match("^%d+$") and v == true then combatConfig[k][tostring(id)] = true end end
            end
        end
    end)
end
combatConfig.position="Under";combatConfig.predict=true
local predictionSamples=setmetatable({},{__mode="k"})
local predictionInfo={latency=0,jitter=0,horizon=0,offset=0}
local pingUpdated=-math.huge
local function predictCombatPosition(targetRoot)
    local now=os.clock()
    if now-pingUpdated>=.5 then
        pingUpdated=now
        local ok,value=pcall(function() return player:GetNetworkPing() end)
        if ok and type(value)=="number" and value==value and value>=0 and value<3 then
            local prior=predictionInfo.latency
            predictionInfo.latency=prior==0 and value or prior*.8+value*.2
            predictionInfo.jitter=predictionInfo.jitter*.8+math.abs(value-prior)*.2
        end
    end
    local position,velocity=targetRoot.Position,targetRoot.AssemblyLinearVelocity
    local old=predictionSamples[targetRoot]
    local acceleration=Vector3.zero
    if old then
        local dt=now-old.time
        if dt>=.005 and dt<=.5 and (position-old.position).Magnitude<math.max(12,old.velocity.Magnitude*dt*3) then
            acceleration=(velocity-old.velocity)/dt
            if acceleration.Magnitude>80 then acceleration=acceleration.Unit*80 end
            velocity=old.velocity:Lerp(velocity,.65)
        elseif (position-old.position).Magnitude>=math.max(12,old.velocity.Magnitude*math.max(dt,.01)*3) then
            velocity=Vector3.zero
        end
    end
    predictionSamples[targetRoot]={time=now,position=position,velocity=velocity}
    local horizon=math.clamp(predictionInfo.latency+math.min(predictionInfo.jitter,.03),0,.25)
    local lead=velocity*horizon+acceleration*(.5*horizon*horizon)
    if lead.Magnitude>8 then lead=lead.Unit*8 end
    predictionInfo.horizon=horizon;predictionInfo.offset=lead.Magnitude
    return position+lead,velocity
end
LiveMCP.register("combat_prediction_status",function() return predictionInfo end)
LiveMCP.onCleanup(function() LiveMCP.unregister("combat_prediction_status") end)
local combatMenu = button(sidebar, "05   COMBAT", 10, 236, 130, 37)
combatMenu.Visible = isStrongestBattlegrounds
local combatPanel = make("Frame", window, {Position = UDim2.fromOffset(150, 69), Size = UDim2.new(1,-150,1,-69),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Visible = false, ZIndex = 30})
text(combatPanel, "Combat workspace", 22, 19, 380, 34, 25).Font = Enum.Font.GothamBold
text(combatPanel, "CONTROLS  /  TARGETS  /  LIVE TELEMETRY", 23, 58, 440, 16, 9, C.muted)
make("Frame", combatPanel, {Position=UDim2.fromOffset(22,84),Size=UDim2.new(1,-44,0,1),BackgroundColor3=C.edge,BorderSizePixel=0})
make("Frame", combatPanel, {Position=UDim2.fromOffset(245,98),Size=UDim2.new(0,1,1,-200),BackgroundColor3=C.edge,BorderSizePixel=0})
local autoCombat = button(combatPanel,"AUTO: OFF",22,100,210,34)
local modeCombat = button(combatPanel,"",22,142,210,30)
local posCombat = button(combatPanel,"",22,180,210,30)
local predictCombat = button(combatPanel,"",22,218,210,30)
local speedCombat = button(combatPanel,"",22,256,210,30)
local safeCombat = button(combatPanel,"",22,294,100,30)
local voidCombat = button(combatPanel,"",130,294,102,30)
local skillsCombat = button(combatPanel,"",22,332,210,30)
text(combatPanel,"TARGET LIST · SELECT / BLOCK",260,100,208,18,9,C.accent)
local targetsList = make("ScrollingFrame",combatPanel,{Position=UDim2.fromOffset(260,126),Size=UDim2.fromOffset(208,196),
    BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
make("UIListLayout",targetsList,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
local safeNow = button(combatPanel,"SAFE NOW",260,332,100,30)
safeNow.TextColor3 = C.accent
local safeReturn = button(combatPanel,"RETURN",368,332,100,30)
local combatStats = text(combatPanel,"READY",22,373,446,30,10,C.accent)
combatStats.TextWrapped=true
local saveCombat = button(combatPanel,"SAVE SETTINGS",22,410,210,27)
local combatSaveStatus = text(combatPanel,"Combat starts OFF",244,410,224,27,9,C.muted)
local frameCount, fpsStarted, liveFPS = 0, os.clock(), 0
connect(Run.Heartbeat, function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - fpsStarted >= 1 then
        liveFPS = math.floor(frameCount / (now - fpsStarted) + .5)
        fpsStarted, frameCount = now, 0
    end
end)
for _, nav in ipairs({movement, camMenu, animationMenu, playMenu, combatMenu}) do
    make("UIStroke", nav, {Color = C.edge, Thickness = 1, Transparency = .35})
    connect(nav.Activated, function()
        for _, other in ipairs({movement, camMenu, animationMenu, playMenu, combatMenu}) do
            other.BackgroundColor3 = other == nav and Color3.fromRGB(31, 65, 61) or C.panel
            other.TextColor3 = other == nav and C.accent or C.text
        end
    end)
end
local originalSpeeds = {}
local kaitunUltSafety=false
local safePlatform, safeCharacter, safeReturnFrame, safeManual = nil, nil, nil, false
local function leaveSafeZone(returnToMap)
    local model = player.Character
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local h = model and model:FindFirstChildOfClass("Humanoid")
    if returnToMap and model == safeCharacter and root and h and h.Health > 0 and safeReturnFrame then
        pcall(function()
            root.CFrame = safeReturnFrame + Vector3.new(0, 2, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if safePlatform then safePlatform:Destroy() end
    safePlatform, safeCharacter, safeReturnFrame, safeManual = nil, nil, nil, false
    safeNow.Text = "SAFE NOW"
end
local function enterSafeZone(manual)
    if safePlatform then return end
    local model = player.Character
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local h = model and model:FindFirstChildOfClass("Humanoid")
    if not root or not h or h.Health <= 0 then combatSaveStatus.Text = "Wait for a living character"; return end
    safeReturnFrame, safeCharacter, safeManual = root.CFrame, model, manual == true
    safePlatform = make("Part", workspace, {Name = "VectorSafePlatform", Size = Vector3.new(80, 1, 80),
        CFrame = CFrame.new(root.Position + Vector3.new(0, 60, 0)), Anchored = true,
        CanCollide = true, CanTouch = false, Transparency = .35, Color = C.accent})
    root.CFrame = safePlatform.CFrame + Vector3.new(0, 5, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    safeNow.Text = "IN SAFE ZONE"
end
connect(safeNow.Activated, function() enterSafeZone(true) end)
connect(safeReturn.Activated, function() leaveSafeZone(true) end)
connect(player.CharacterRemoving, function(model) if model == safeCharacter then leaveSafeZone(false) end end)
LiveMCP.onCleanup(function() leaveSafeZone(true) end)
local function drawCombat()
    autoCombat.Text = combatOn and "AUTO: ON" or "AUTO: OFF"
    autoCombat.TextColor3 = combatOn and C.accent or C.text
    modeCombat.Text="TARGET: "..combatConfig.mode
    posCombat.Text="POSITION: "..combatConfig.position
    predictCombat.Text="PREDICTION: "..(combatConfig.predict and "ON" or "OFF")
    speedCombat.Text="SPEED 50: "..(combatConfig.speed and "ON" or "OFF")
    safeCombat.Text="SAFE: "..(combatConfig.safe and "AUTO" or "OFF")
    voidCombat.Text="VOID: "..(combatConfig.void and "ON" or "OFF")
    skillsCombat.Text="AUTO TOOLS: "..(combatConfig.skills and "ON" or "OFF")
end
local function saveCombatConfig()
    if type(writefile) ~= "function" then combatSaveStatus.Text="File saving unavailable"; return end
    local ok=pcall(function() writefile("combat.json",combatHttp:JSONEncode(combatConfig)) end)
    combatSaveStatus.Text=ok and "Settings saved" or "Save failed"
end
connect(saveCombat.Activated,saveCombatConfig)
connect(autoCombat.Activated,function() combatOn=not combatOn; combatTarget=nil; drawCombat() end)
connect(modeCombat.Activated,function()
    local modes={"Random","Selected","Multi"}; combatConfig.mode=modes[(table.find(modes,combatConfig.mode) or 1)%3+1]
    combatTarget=nil; drawCombat()
end)
connect(posCombat.Activated,function()
    local modes={"Under","Circle"}; combatConfig.position=modes[(table.find(modes,combatConfig.position) or 1)%3+1]; drawCombat()
end)
for _, item in ipairs({{predictCombat,"predict"},{speedCombat,"speed"},{voidCombat,"void"},{skillsCombat,"skills"}}) do
    connect(item[1].Activated,function() combatConfig[item[2]]=not combatConfig[item[2]]; drawCombat() end)
end
connect(safeCombat.Activated, function()
    combatConfig.safe = not combatConfig.safe
    if not combatConfig.safe and safePlatform and not safeManual then leaveSafeZone(true) end
    drawCombat()
end)
local function drawTargets()
    for _,v in ipairs(targetsList:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do if p~=player then
        local id=tostring(p.UserId)
        local row=make("Frame",targetsList,{Size=UDim2.new(1,-4,0,32),BackgroundTransparency=1})
        local pick=button(row,(combatConfig.selected[id] and "+ " or "")..p.DisplayName,0,0,151,30)
        pick.TextTruncate=Enum.TextTruncate.AtEnd
        pick.TextColor3=combatConfig.selected[id] and C.accent or C.text
        pick.Activated:Connect(function() combatConfig.selected[id]=not combatConfig.selected[id] or nil; drawTargets() end)
        local block=button(row,combatConfig.blacklist[id] and "UNB" or "BLK",155,0,45,30)
        block.Activated:Connect(function() combatConfig.blacklist[id]=not combatConfig.blacklist[id] or nil; combatTarget=nil; drawTargets() end)
    end end
end
connect(Players.PlayerAdded,drawTargets); connect(Players.PlayerRemoving,function() task.defer(drawTargets) end)
local function hideCombat() combatPanel.Visible=false; combatMenu.TextColor3=C.text end
connect(combatMenu.Activated,function()
    if not isStrongestBattlegrounds then return end
    showCameraPage(false); showAnimations(false); showPlay(false)
    combatPanel.Visible=true; combatMenu.TextColor3=C.accent; drawTargets()
end)
for _, menu in ipairs({movement,camMenu,animationMenu,playMenu}) do connect(menu.Activated,hideCombat) end
local function restoreSpeeds()
    for h,s in pairs(originalSpeeds) do pcall(function() h.WalkSpeed=s end) end
    originalSpeeds={}
end
LiveMCP.onCleanup(function() combatOn=false; restoreSpeeds() end)
local nextAttack, lastTargetScan, lastStats = 0,0,0
local nextRagdollDash, dashMoveUntil, nextBaldSkill = 0,0,0
local nextUltimateAttempt = 0
local baldComboPending, baldComboDeadline = false, 0
local dashTargetModel, dashTriggered = nil,false
local circleAngle=0
local candidates={}
local function validTarget(p)
    if not p or p==player or not p.Parent or combatConfig.blacklist[tostring(p.UserId)] then return false end
    if combatConfig.mode~="Random" and not combatConfig.selected[tostring(p.UserId)] then return false end
    local c=p.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); local r=c and c:FindFirstChild("HumanoidRootPart")
    return h and h.Health>0 and r and (not combatConfig.void or r.Position.Y>workspace.FallenPartsDestroyHeight+50)
end
-- Luex-style heartbeat scheduler and attack cadence.
task.spawn(function()
    while not disposed and isStrongestBattlegrounds do
        local now=os.clock()
        local model=player.Character; local h=model and model:FindFirstChildOfClass("Humanoid"); local root=model and model:FindFirstChild("HumanoidRootPart")
        if safePlatform and (safeCharacter ~= model or not h or h.Health <= 0 or not safePlatform.Parent) then
            leaveSafeZone(false)
        end
        if h and root and h.Health > 0 then
            local health = h.Health / math.max(h.MaxHealth, 1)
            if safePlatform then
                if not safeManual and not kaitunUltSafety and health >= .8 then
                    leaveSafeZone(true)
                else
                    local pos, center = root.Position, safePlatform.Position
                    if math.abs(pos.X-center.X)>36 or math.abs(pos.Z-center.Z)>36 or pos.Y<center.Y+3 then
                        root.CFrame = safePlatform.CFrame + Vector3.new(0, 5, 0)
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            elseif combatConfig.safe and health < .35 then enterSafeZone(false) end
        end
        if combatConfig.speed and h and h.Health>0 then
            if not originalSpeeds[h] then originalSpeeds[h]=h.WalkSpeed end
            h.WalkSpeed=50
        elseif next(originalSpeeds) then restoreSpeeds() end
        if now-lastTargetScan>=.5 then
            lastTargetScan=now; candidates={}
            for _,p in ipairs(Players:GetPlayers()) do if validTarget(p) then table.insert(candidates,p) end end
        end
        local status="OFF"
        if combatOn and h and root and h.Health>0 then
            status="SEARCHING"
            if not validTarget(combatTarget) then
                combatIndex=combatIndex+1
                combatTarget=#candidates>0 and candidates[combatConfig.mode=="Random" and math.random(1,#candidates) or ((combatIndex-1)%#candidates+1)] or nil
            end
            local state=h:GetState()
            local paused=safePlatform or state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll
            if paused then status=safePlatform and (safeManual and "SAFE ZONE / MANUAL" or "SAFE ZONE / RECOVERING") or "PAUSED / RAGDOLL"
            elseif validTarget(combatTarget) then
                local targetRoot=combatTarget.Character:FindFirstChild("HumanoidRootPart")
                local targetModel=combatTarget.Character
                status="TRACKING "..combatTarget.DisplayName
                local ok=pcall(function()
                    local ragdoll=targetModel:FindFirstChild("Ragdoll")
                    local isRagdolled=ragdoll and ragdoll:IsA("Accessory")
                    if dashTargetModel~=targetModel then dashTargetModel=targetModel;dashTriggered=false end
                    if not isRagdolled then dashTriggered=false end
                    local rage=player:GetAttribute("Ultimate")
                    local baldFull=model:GetAttribute("Character")=="Bald" and type(rage)=="number" and rage>=100
                    if baldComboPending and (now>=baldComboDeadline or model:GetAttribute("Character")~="Bald") then baldComboPending=false end
                    local pos=targetRoot.Position
                    local velocity=targetRoot.Velocity
                    if combatConfig.predict and velocity.Magnitude>1 then
                        local okPing,ping=pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000 end)
                        pos=pos+velocity*(math.clamp(okPing and ping or .05,.05,.5)+.08)
                    end
                    local offset=Vector3.new(0,-6,0)
                    if combatConfig.position=="Circle" then
                        circleAngle=circleAngle+math.rad(10)
                        offset=Vector3.new(math.cos(circleAngle)*5,-3,math.sin(circleAngle)*5)
                    end
                    if baldFull or baldComboPending then
                        local look=targetRoot.CFrame.LookVector
                        local flat=Vector3.new(look.X,0,look.Z)
                        if flat.Magnitude<.01 then flat=Vector3.new(0,0,-1) else flat=flat.Unit end
                        offset=-flat*10
                    end
                    if now>=dashMoveUntil and (not combatConfig.void or (pos+offset).Y>workspace.FallenPartsDestroyHeight+50) then
                        local destination=pos+offset
                        root.CFrame=CFrame.lookAt(destination,pos)
                    end
                    local remote=model:FindFirstChild("Communicate")
                    if remote and remote:IsA("RemoteEvent") and type(rage)=="number" and rage>=100 and model:GetAttribute("Ulted")~=true and now>=nextUltimateAttempt then
                        remote:FireServer({MoveDirection=Vector3.zero,Goal="KeyPress",Key=Enum.KeyCode.G})
                        nextUltimateAttempt=now+3
                        if model:GetAttribute("Character")=="Bald" then baldComboPending=true;baldComboDeadline=now+15 end
                    end
                    if remote and remote:IsA("RemoteEvent") and isRagdolled and not dashTriggered and now>=nextRagdollDash then
                        remote:FireServer({Goal="KeyPress",Key=Enum.KeyCode.Q,Dash=Enum.KeyCode.W,MousePos=targetRoot.CFrame,Tick=1})
                        remote:FireServer({Goal="KeyRelease",Key=Enum.KeyCode.Q,Tick=1})
                        dashTriggered=true;nextRagdollDash=now+2;dashMoveUntil=now+.5
                    end
                    if baldComboPending and model:GetAttribute("Ulted")==true and remote and remote:IsA("RemoteEvent") and now>=nextBaldSkill then
                        local pack=player:FindFirstChildOfClass("Backpack")
                        local tools={}
                        if pack then for _,tool in ipairs(pack:GetChildren()) do if tool:IsA("Tool") then table.insert(tools,tool) end end end
                        if tools[4] then remote:FireServer({Goal="Console Move",Tool=tools[4]});nextBaldSkill=now+2;baldComboPending=false end
                    end
                    if remote and remote:IsA("RemoteEvent") and now>=nextAttack then
                        remote:FireServer({MoveDirection=Vector3.zero,Goal="KeyPress",Key=Enum.KeyCode.Q})
                        remote:FireServer({Goal="LeftClick",Mobile=true}); combatCalls=combatCalls+1; nextAttack=now+.01
                        if combatConfig.skills and not baldFull and not baldComboPending then
                            local pack=player:FindFirstChildOfClass("Backpack")
                            if pack then
                                for _,tool in ipairs(pack:GetChildren()) do
                                    if tool:IsA("Tool") then remote:FireServer({Goal="Console Move",Tool=tool});combatCalls=combatCalls+1 end
                                end
                            end
                        end
                    end
                end)
                if not ok then combatErrors=combatErrors+1 end
            end
        elseif combatOn then status="WAITING FOR CHARACTER"
        elseif safePlatform then status="SAFE ZONE / COMBAT OFF" end
        if now-lastStats>=.5 then
            lastStats=now
            combatStats.Text=string.format("%s  |  %d FPS\nTARGETS %d  /  SENT %d  /  ERR %d",status,liveFPS,#candidates,combatCalls,combatErrors)
        end
        Run.Heartbeat:Wait()
    end
    restoreSpeeds()
end)
drawCombat(); drawTargets()

-- Session tracker observes values from the moment VECTOR is loaded.
local boardMenu = button(sidebar, isStrongestBattlegrounds and "06   LEADERBOARD" or "05   LEADERBOARD", 10, isStrongestBattlegrounds and 282 or 236, 130, 37)
local board = make("Frame", window, {Name="LeaderboardPanel",Position=UDim2.fromOffset(150,69),Size=UDim2.new(1,-150,1,-69),
    BackgroundColor3=C.bg,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false,ZIndex=30})
text(board,"Leaderboard",22,18,350,32,25).Font=Enum.Font.GothamBold
text(board,"LIVE STATS / THIS SERVER",23,55,400,16,9,C.muted)
make("Frame",board,{Position=UDim2.fromOffset(22,78),Size=UDim2.new(1,-44,0,1),BackgroundColor3=C.edge,BorderSizePixel=0})
local boardStats = text(board,"Loading...",22,88,446,39,11,C.accent)
boardStats.TextWrapped=true
local boardStatus = text(board,"",22,127,446,18,10,C.muted)
local headerRow = make("Frame",board,{Position=UDim2.fromOffset(22,153),Size=UDim2.new(1,-44,0,28),BackgroundColor3=C.panel,BorderSizePixel=0})
text(headerRow,"PEOPLE",8,2,160,24,10,C.muted)
text(headerRow,"KILLS",175,2,65,24,10,C.muted)
text(headerRow,"TOTAL",245,2,70,24,10,C.muted)
text(headerRow,"+ KILLS",328,2,90,24,10,C.accent)
local boardList=make("ScrollingFrame",board,{Position=UDim2.fromOffset(22,185),Size=UDim2.new(1,-44,1,-202),
    BackgroundColor3=C.panel,BackgroundTransparency=.2,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make("UIListLayout",boardList,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
local env=type(getgenv)=="function" and getgenv() or _G
local session=env.__VectorBoardSession
if type(session)~="table" or session.jobId~=game.JobId then
    session={jobId=game.JobId,baseline={},deaths=0}
    env.__VectorBoardSession=session
end
local timePath="playtime.json"
local totalSeconds, timerStart, savedAt=0,os.clock(),os.clock()
local persistence=type(writefile)=="function" and type(readfile)=="function"
if type(readfile)=="function" then pcall(function()
    local d=combatHttp:JSONDecode(readfile(timePath))
    if type(d)=="table" and type(d.total_seconds)=="number" then totalSeconds=math.max(0,d.total_seconds) end
end) end
local function storeTime()
    local now=os.clock()
    totalSeconds=totalSeconds+math.max(0,now-savedAt)
    savedAt=now
    if not persistence then return false end
    return pcall(function() writefile(timePath,combatHttp:JSONEncode({version=1,total_seconds=math.floor(totalSeconds)})) end)
end
local deathConnection, characterConnection
local function watchDeath(model)
    if deathConnection then deathConnection:Disconnect(); deathConnection=nil end
    task.spawn(function()
        local h=model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid",10)
        if not h or player.Character~=model or disposed then return end
        deathConnection=h.Died:Connect(function() session.deaths=session.deaths+1 end)
    end)
end
characterConnection=player.CharacterAdded:Connect(watchDeath)
if player.Character then watchDeath(player.Character) end
LiveMCP.onCleanup(function()
    if characterConnection then characterConnection:Disconnect() end
    if deathConnection then deathConnection:Disconnect() end
    storeTime()
end)
local function statValue(p, name)
    local leader=p:FindFirstChild("leaderstats")
    if not leader then return nil end
    for _,obj in ipairs(leader:GetChildren()) do
        if obj.Name:lower():gsub("[%s_%-]","")==name and (obj:IsA("IntValue") or obj:IsA("NumberValue")) then return obj.Value end
    end
    return nil
end
local function numberText(v) return v==nil and "—" or tostring(v) end
local function formatTime(seconds)
    seconds=math.floor(seconds)
    return string.format("%02d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
local function refreshBoard()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do
        local kills=statValue(p,"kills")
        local total=statValue(p,"totalkills")
        local key=tostring(p.UserId)
        if kills~=nil and session.baseline[key]==nil then session.baseline[key]=kills end
        table.insert(list,{player=p,kills=kills,total=total,delta=kills~=nil and session.baseline[key]~=nil and kills-session.baseline[key] or nil})
    end
    table.sort(list,function(a,b) return (a.kills or -math.huge)>(b.kills or -math.huge) end)
    if not board.Visible then return end
    for _,v in ipairs(boardList:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    for i,item in ipairs(list) do
        local row=make("Frame",boardList,{Size=UDim2.new(1,-5,0,32),BackgroundColor3=C.bg,BackgroundTransparency=.15,BorderSizePixel=0,LayoutOrder=i})
        corner(row,5)
        local name=text(row,item.player.DisplayName,8,3,160,26,11,C.text); name.TextTruncate=Enum.TextTruncate.AtEnd
        text(row,numberText(item.kills),175,3,65,26,11,C.text)
        text(row,numberText(item.total),245,3,70,26,11,C.text)
        text(row,item.delta~=nil and string.format("%+d",item.delta) or "—",328,3,90,26,11,C.accent)
    end
end
connect(boardMenu.Activated,function()
    showCameraPage(false);showAnimations(false);showPlay(false);hideCombat()
    board.Visible=true;boardMenu.TextColor3=C.accent
    for _,nav in ipairs({movement,camMenu,animationMenu,playMenu,combatMenu}) do nav.BackgroundColor3=C.panel;nav.TextColor3=C.text end
    boardMenu.BackgroundColor3=Color3.fromRGB(31,65,61)
    refreshBoard()
end)
for _,nav in ipairs({movement,camMenu,animationMenu,playMenu,combatMenu}) do connect(nav.Activated,function()
    board.Visible=false;boardMenu.TextColor3=C.text;boardMenu.BackgroundColor3=C.panel
end) end
local lastWrite=os.clock()
task.spawn(function()
    while not disposed do
        refreshBoard()
        local now=os.clock()
        if now-lastWrite>=15 then
            local ok=storeTime();lastWrite=now
            if persistence and not ok then persistence=false end
        end
        if board.Visible then
            boardStats.Text=string.format("SERVER TIME  %s     |     YOUR DEATHS  %d\nTOTAL VECTOR TIME  %s",formatTime(now-timerStart),session.deaths,formatTime(totalSeconds+now-savedAt))
            boardStatus.Text=persistence and "Session starts when VECTOR loads · time saves every 15 sec" or "Session starts when VECTOR loads · time not saved (file access unavailable)"
        end
        task.wait(1)
    end
end)


-- Aim assist uses the normal camera; unsupported silent mode is never falsely enabled.
local aimMenu=button(sidebar,"07   AIM",10,328,130,37)
local aimPanel=make("Frame",window,{Name="AimPanel",Position=UDim2.fromOffset(150,69),Size=UDim2.new(1,-150,1,-69),
    BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,ZIndex=30})
text(aimPanel,"Aim settings",22,19,360,32,25).Font=Enum.Font.GothamBold
text(aimPanel,"CAMERA ASSIST  /  AUTOMATIC",23,56,430,18,10,C.muted)
make("Frame",aimPanel,{Position=UDim2.fromOffset(22,83),Size=UDim2.new(1,-44,0,1),BackgroundColor3=C.edge,BorderSizePixel=0})
local aimToggle=button(aimPanel,"LEGIT AIM: OFF",22,102,210,36)
local aimFov=button(aimPanel,"",22,151,210,36)
local aimSmooth=button(aimPanel,"",22,200,210,36)
local aimSpeed=button(aimPanel,"",22,249,210,36)
local recommend=button(aimPanel,"RECOMMENDED",22,298,210,36)
local silent=button(aimPanel,"SILENT AIM: UNAVAILABLE",250,102,218,36)
silent.TextSize=10
local silentFov=button(aimPanel,"",250,151,218,36)
local aimInfo=text(aimPanel,"Silent aim depends on each game's weapon and server. This mode is not connected.",250,200,218,90,11,C.muted)
aimInfo.TextWrapped=true
aimInfo.TextYAlignment=Enum.TextYAlignment.Top
local aimHelp=text(aimPanel,"Put a visible player inside the FOV circle.",22,350,446,60,11,C.muted)
aimHelp.TextWrapped=true
aimHelp.TextYAlignment=Enum.TextYAlignment.Top
local aimEnabled, aimRadius, silentRadius, smooth, aimRate = false,120,120,2,36
local silentEnv=type(getgenv)=="function" and getgenv() or _G
local oldSilent=silentEnv.__VectorSilentDemo
if type(oldSilent)=="table" then oldSilent.enabled=false end
local silentState=silentEnv.__VectorSilentDemoV2
if type(silentState)~="table" then silentState={installed=false,enabled=false};silentEnv.__VectorSilentDemoV2=silentState end
silentState.enabled=false;silentState.targetPosition=nil;silentState.targetModel=nil
silentState.screenMode=true
local silentSupported=game.PlaceId==93466613073564 and type(hookmetamethod)=="function" and type(getnamecallmethod)=="function"
local function setSilent(enabled)
    if not enabled then silentState.enabled=false;return true end
    if not silentSupported then return false end
    local storage=game:GetService("ReplicatedStorage")
    local remoteFolder=storage:FindFirstChild("Remote")
    remoteFolder=remoteFolder and remoteFolder:FindFirstChild("Event")
    remoteFolder=remoteFolder and remoteFolder:FindFirstChild("Fire")
    local fire=remoteFolder and remoteFolder:FindFirstChild("[C-S]FireEvent")
    if not fire then return false end
    silentState.remote=fire
    if not silentState.installed then
        local original
        local ok=pcall(function()
            original=hookmetamethod(game,"__namecall",function(remote,...)
                if silentState.enabled and remote==silentState.remote and getnamecallmethod()=="FireServer" then
                    local args=table.pack(...)
                    local shot=args[2]
                    local target=silentState.targetPosition
                    local model=silentState.targetModel
                    if type(shot)=="table" and typeof(shot.origin)=="Vector3" and target and model then
                        local direction=target-shot.origin
                        if direction.Magnitude>.001 then
                            local copy=table.clone(shot)
                            copy.direction=direction.Unit
                            args[1]=model
                            args[2]=copy
                            return original(remote,table.unpack(args,1,args.n))
                        end
                    end
                end
                return original(remote,...)
            end)
        end)
        if not ok then return false end
        silentState.installed=true
    end
    silentState.enabled=true
    return true
end
local silentUpdate=Run.RenderStepped:Connect(function()
    silentState.targetPosition=nil;silentState.targetModel=nil
    if not silentState.enabled or disposed then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local center=camera.ViewportSize/2
    local bestDistance=silentState.screenMode and math.huge or silentRadius
    for _,other in ipairs(Players:GetPlayers()) do
        local freeForAll=player.Team and player.Team.Name:upper()=="FFA"
        if other~=player and (freeForAll or player.Neutral or other.Neutral or not player.Team or not other.Team or player.Team~=other.Team) then
            local character=other.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local target=character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
            if humanoid and humanoid.Health>0 and target and target:IsA("BasePart") then
                local point,visible=camera:WorldToViewportPoint(target.Position)
                local distance=(Vector2.new(point.X,point.Y)-center).Magnitude
                if visible and point.Z>0 and distance<bestDistance then
                    bestDistance=distance;silentState.targetPosition=target.Position;silentState.targetModel=character
                end
            end
        end
    end
end)
LiveMCP.onCleanup(function() silentState.enabled=false;silentState.targetPosition=nil;silentState.targetModel=nil;silentUpdate:Disconnect() end)
local aimInstant, aimWallCheck = false, true
local aimMode = "Camera"
local relativeMove = type(mousemoverel)=="function" and mousemoverel or nil
local aimWindowFocused = true
connect(Input.WindowFocusReleased,function() aimWindowFocused=false end)
connect(Input.WindowFocused,function() aimWindowFocused=true end)
local triggerEnabled, triggerTeamCheck, triggerDelay, triggerLastFire = false, true, .15, 0
local triggerClick = type(mouse1click) == "function" and mouse1click or nil
local triggerPress = type(mouse1press) == "function" and mouse1press or nil
local triggerRelease = type(mouse1release) == "function" and mouse1release or nil
local triggerAvailable = triggerClick ~= nil or (triggerPress ~= nil and triggerRelease ~= nil)
local aimDiagnostic="OFF"
local isRayUIOpen = function() return true end
local bhopEnabled, bhopLastJump = false, 0
local bhopConnection = Run.Heartbeat:Connect(function()
    if not bhopEnabled or disposed or isRayUIOpen() or freeEnabled or cameraLooking or Input:GetFocusedTextBox() then return end
    if not Input:IsKeyDown(Enum.KeyCode.Space) or os.clock() - bhopLastJump < .12 then return end
    local model = player.Character
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 or humanoid.Sit or humanoid.FloorMaterial == Enum.Material.Air then return end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then return end
    bhopLastJump = os.clock()
    humanoid.Jump = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)
LiveMCP.onCleanup(function() bhopEnabled=false;bhopConnection:Disconnect() end)
local overlay=LiveMCP.track(make("ScreenGui",playerGui,{Name="VectorAimFOV",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=19}))
local circle=make("Frame",overlay,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(240,240),BackgroundTransparency=1,Visible=false})
make("UICorner",circle,{CornerRadius=UDim.new(1,0)})
make("UIStroke",circle,{Color=C.accent,Transparency=.35,Thickness=1})
local function drawAim()
    aimToggle.Text=aimEnabled and "LEGIT AIM: ON" or "LEGIT AIM: OFF"
    aimToggle.TextColor3=aimEnabled and C.accent or C.text
    aimFov.Text="LEGIT FOV: "..aimRadius.." PX"
    silentFov.Text="SILENT FOV: "..silentRadius.." PX"
    aimSmooth.Text="SMOOTH: "..smooth
    aimSpeed.Text="AIM SPEED: "..aimRate
    circle.Size=UDim2.fromOffset(aimRadius*2,aimRadius*2)
    circle.Visible=aimEnabled
end
connect(aimToggle.Activated,function() aimEnabled=not aimEnabled;drawAim() end)
connect(aimFov.Activated,function() aimRadius=aimRadius>=240 and 60 or aimRadius+30;drawAim() end)
connect(silentFov.Activated,function() silentRadius=silentRadius>=240 and 60 or silentRadius+30;drawAim() end)
connect(aimSmooth.Activated,function() smooth=smooth>=8 and 1 or smooth+1;drawAim() end)
connect(aimSpeed.Activated,function() aimRate=aimRate>=120 and 8 or aimRate+8;drawAim() end)
connect(recommend.Activated,function() aimRadius=120;silentRadius=120;smooth=2;aimRate=36;drawAim() end)
connect(silent.Activated,function()
    local ok=setSilent(not silentState.enabled)
    silent.Text=silentState.enabled and "SILENT AIM: ON" or "SILENT AIM: OFF"
    aimInfo.Text=ok and "Experimental: redirects shots toward a player inside the FOV." or "Unavailable in this game or executor."
end)
local function hideAim() aimPanel.Visible=false;aimMenu.BackgroundColor3=C.panel;aimMenu.TextColor3=C.text end
connect(aimMenu.Activated,function()
    showCameraPage(false);showAnimations(false);showPlay(false);hideCombat();board.Visible=false
    boardMenu.TextColor3=C.text;boardMenu.BackgroundColor3=C.panel
    aimPanel.Visible=true;aimMenu.TextColor3=C.accent;aimMenu.BackgroundColor3=Color3.fromRGB(31,65,61)
    for _,nav in ipairs({movement,camMenu,animationMenu,playMenu,combatMenu}) do nav.BackgroundColor3=C.panel;nav.TextColor3=C.text end
end)
for _,nav in ipairs({movement,camMenu,animationMenu,playMenu,combatMenu,boardMenu}) do connect(nav.Activated,hideAim) end
local aimRenderName = "VectorAim_" .. game:GetService("HttpService"):GenerateGUID(false)
Run:BindToRenderStep(aimRenderName, Enum.RenderPriority.Last.Value + 1000, function(dt)
    if not aimEnabled or disposed then aimDiagnostic="OFF"; return end
    if freeEnabled or cameraLooking then aimDiagnostic="CAMERA MODE ACTIVE"; return end
    if window.Visible or isRayUIOpen() then aimDiagnostic="HIDE VECTOR TO AIM"; return end
    if not aimWindowFocused or Input.MouseIconEnabled then aimDiagnostic="CURSOR VISIBLE OR WINDOW UNFOCUSED"; return end
    if aimMode == "Relative mouse" and Input.MouseBehavior ~= Enum.MouseBehavior.LockCenter and Input.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition then
        aimDiagnostic="MOUSE NOT LOCKED"; return
    end
    if aimMode == "Relative mouse" and not relativeMove then aimDiagnostic="RELATIVE MOUSE UNAVAILABLE"; return end
    if Input:GetFocusedTextBox() then return end
    local camera=workspace.CurrentCamera
    if not camera or not player.Character then aimDiagnostic="WAITING FOR CHARACTER"; return end
    local center=camera.ViewportSize/2
    local best, bestPoint, bestDistance=nil,nil,aimRadius
    for _,other in ipairs(Players:GetPlayers()) do
        if other~=player then
            local model=other.Character
            local human=model and model:FindFirstChildOfClass("Humanoid")
            local head=model and model:FindFirstChild("Head")
            if human and human.Health>0 and head and head:IsA("BasePart") then
                local point,onScreen=camera:WorldToViewportPoint(head.Position)
                local distance=(Vector2.new(point.X,point.Y)-center).Magnitude
                if onScreen and point.Z>0 and distance<bestDistance then
                    local visible = true
                    if aimWallCheck then
                        local params=RaycastParams.new()
                        params.FilterType=Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances={player.Character,camera}
                        local hit=workspace:Raycast(camera.CFrame.Position,head.Position-camera.CFrame.Position,params)
                        visible = not hit or hit.Instance:IsDescendantOf(model)
                    end
                    if visible then best=head;bestPoint=point;bestDistance=distance end
                end
            end
        end
    end
    if best then
        local alpha=aimInstant and 1 or (1-math.exp(-math.clamp(dt,0,.1)*aimRate/math.max(smooth,1)))
        if aimMode == "Relative mouse" then
            local delta = Vector2.new(bestPoint.X,bestPoint.Y)-center
            local ok = pcall(relativeMove,math.clamp(delta.X*alpha,-80,80),math.clamp(delta.Y*alpha,-80,80))
            aimDiagnostic=ok and "TRACKING / RELATIVE" or "RELATIVE MOUSE FAILED"
        else
            camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,best.Position),alpha)
            aimDiagnostic="TRACKING / CAMERA"
        end
    else aimDiagnostic="NO VISIBLE TARGET IN FOV" end
end)
LiveMCP.onCleanup(function() aimEnabled=false;Run:UnbindFromRenderStep(aimRenderName);overlay:Destroy() end)
LiveMCP.register("aim_status",function()
    local camera=workspace.CurrentCamera
    return {enabled=aimEnabled,instant=aimInstant,wall_check=aimWallCheck,ui_open=isRayUIOpen(),mode=aimMode,
        cursor_visible=Input.MouseIconEnabled,mouse_behavior=tostring(Input.MouseBehavior),focused=aimWindowFocused,
        status=aimDiagnostic,camera_type=camera and tostring(camera.CameraType) or "unavailable"}
end)
LiveMCP.onCleanup(function() LiveMCP.unregister("aim_status") end)
local triggerRenderName = "VectorTrigger_" .. game:GetService("HttpService"):GenerateGUID(false)
Run:BindToRenderStep(triggerRenderName, Enum.RenderPriority.Last.Value + 1, function()
    if not triggerEnabled or not triggerAvailable or disposed or isRayUIOpen() or freeEnabled or cameraLooking then return end
    if Input:GetFocusedTextBox() or os.clock() - triggerLastFire < triggerDelay then return end
    local camera, character = workspace.CurrentCamera, player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not camera or not character or not humanoid or humanoid.Health <= 0 then return end
    local size = camera.ViewportSize
    local ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, camera}
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 2048, params)
    if not hit then return end
    local part = hit.Instance
    local target
    while part and part ~= workspace do
        if part:IsA("Model") then
            target = Players:GetPlayerFromCharacter(part)
            if target then break end
        end
        part = part.Parent
    end
    if not target or target == player then return end
    local targetHumanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return end
    if triggerTeamCheck and player.Team ~= nil and not player.Neutral and not target.Neutral and target.Team == player.Team then return end
    triggerLastFire = os.clock()
    if triggerClick then
        pcall(triggerClick)
    else
        local pressed = pcall(triggerPress)
        if pressed then pcall(triggerRelease) end
    end
end)
LiveMCP.onCleanup(function()
    triggerEnabled=false
    Run:UnbindFromRenderStep(triggerRenderName)
end)
task.spawn(function()
    while not disposed do
        if aimPanel.Visible then aimHelp.Text="STATUS: "..aimDiagnostic.."\nHide VECTOR and put a visible player inside the FOV circle." end
        task.wait(.25)
    end
end)
drawAim()

-- Rayfield Gen2 presents all VECTOR workspaces.
local rayfieldStatus = {state="loading",trigger_available=triggerAvailable}
LiveMCP.register("rayfield_status",function() return rayfieldStatus end)
LiveMCP.onCleanup(function() LiveMCP.unregister("rayfield_status") end)
local kaitun={enabled=false}
local openVectorUI
local kaitunStopGui
local lastQueue=-math.huge
local function kaitunQueue()
    combatOn=false;combatTarget=nil
    if os.clock()-lastQueue<30 then return false end
    local ranked=game:GetService("ReplicatedStorage"):FindFirstChild("Ranked")
    local q=ranked and ranked:FindFirstChild("QueueHandler")
    if not q then return false end
    local ok,err=pcall(function() q:FireServer("JoinQueue",{IsRanked=true,Mode="1v1s"}) end)
    if ok then lastQueue=os.clock() else warn("[KAITUN] queue failed: "..tostring(err)) end
    return ok
end
local function kaitunSave(value)
    assert(type(writefile)=="function","File saving unavailable")
    local data={}
    pcall(function() data=combatHttp:JSONDecode(readfile("config.json")) end)
    if type(data)~="table" then data={} end
    data.kaitun=value;data.version=1
    writefile("config.json",combatHttp:JSONEncode(data))
end
pcall(function() kaitun.enabled=combatHttp:JSONDecode(readfile("config.json")).kaitun==true end)
local function kaitunStop()
    kaitunSave(false);kaitun.enabled=false;combatOn=false;combatTarget=nil
    kaitunUltSafety=false
    leaveSafeZone(true)
    if kaitunStopGui then kaitunStopGui:Destroy();kaitunStopGui=nil end
    if openVectorUI then openVectorUI() end
end
local function kaitunStart(resuming)
    kaitunSave(true);kaitun.enabled=true;combatOn=false
    combatConfig.mode="Random";combatConfig.position="Under";combatConfig.safe=true;combatConfig.skills=true;combatConfig.predict=true
    if not kaitunStopGui then
        kaitunStopGui=LiveMCP.track(make("ScreenGui",playerGui,{Name="VectorKaitunStop",ResetOnSpawn=false,DisplayOrder=150}))
        local b=button(kaitunStopGui,"STOP KAITUN",20,80,180,42)
        connect(b.Activated,kaitunStop)
    end
    if not resuming then kaitunQueue() end
end
local function kaitunLocation()
    local people=Players:GetPlayers()
    if #people>2 then return "lobby" end
    local hasRank=false
    for _,p in ipairs(people) do
        local stats=p:FindFirstChild("leaderstats")
        if stats then for _,v in ipairs(stats:GetChildren()) do
            local n=v.Name:lower()
            if n:find("kill",1,true) then return "lobby" end
            if n:find("rank",1,true) then hasRank=true end
        end end
    end
    return hasRank and "ranked" or "loading"
end
-- Resume the installed local release after teleport; no bridge is needed.
connect(player.OnTeleport,function(state)
    if not kaitun.enabled or state~=Enum.TeleportState.Started then return end
    local queue=queue_on_teleport or queueonteleport
    if type(queue)=="function" and type(readfile)=="function" then
        local ok,err=pcall(queue,[[if not game:IsLoaded() then game.Loaded:Wait() end
local ok,c=pcall(function()return game:GetService("HttpService"):JSONDecode(readfile("VECTOR/config.json"))end)
if ok and c.kaitun then assert(loadstring(readfile("VECTOR/main.lua")))() end]])
        if not ok then warn("[VECTOR] resume failed: "..tostring(err)) end
    end
end)

task.spawn(function()
    local matchSince=nil
    local deadSince,opponentId=nil,nil
    local observedCharacter,attributeConnection
    local holdingDuringUlt,wasUlted,ultCycleStart,safeUntil=false,false,nil,0
    local counterUsedThisUlt=false
    local safeLandingReady=false
    local function watchCharacter(character)
        if character==observedCharacter then return end
        if attributeConnection then attributeConnection:Disconnect();attributeConnection=nil end
        observedCharacter=character;holdingDuringUlt=false;safeUntil=0;ultCycleStart=nil;safeLandingReady=false;counterUsedThisUlt=false
        wasUlted=character and character:GetAttribute("Ulted")==true or false
        if character then
            for name,value in pairs(character:GetAttributes()) do
                if value==true and name:sub(1,7)=="Holding" and name~="HoldingM1" and name~="HoldingSpace" then
                    if name=="HoldingDeathCounter" then
                        safeUntil=os.clock()+10;counterUsedThisUlt=true
                    elseif wasUlted then holdingDuringUlt=true end
                end
            end
        end
        if character then
            attributeConnection=character.AttributeChanged:Connect(function(name)
                local now=os.clock();local value=character:GetAttribute(name)
                if name=="HoldingDeathCounter" and value==true then
                    counterUsedThisUlt=true
                    safeUntil=math.max(safeUntil,now+10)
                elseif name:sub(1,7)=="Holding" and name~="HoldingM1" and name~="HoldingSpace" and value==true then
                    if wasUlted or character:GetAttribute("Ulted")==true then holdingDuringUlt=true end
                elseif name=="Ulted" then
                    if wasUlted and value~=true and holdingDuringUlt then safeUntil=math.max(safeUntil,now+10) end
                    if value==true and not wasUlted then holdingDuringUlt=false;counterUsedThisUlt=false end
                    wasUlted=value==true
                end
            end)
        end
    end
    LiveMCP.onCleanup(function() if attributeConnection then attributeConnection:Disconnect();attributeConnection=nil end end)
    local function positionSafeBehind(enemy)
        if not safePlatform or safeManual or not enemy then return false end
        local enemyRoot=enemy:FindFirstChild("HumanoidRootPart")
        local myCharacter=player.Character
        local myRoot=myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        if not enemyRoot or not myRoot then return false end
        local look=enemyRoot.CFrame.LookVector;look=Vector3.new(look.X,0,look.Z)
        if look.Magnitude<.01 then look=Vector3.new(0,0,-1) else look=look.Unit end
        local behind=enemyRoot.Position-look*32
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={enemy,myCharacter,safePlatform}
        local ground=workspace:Raycast(behind+Vector3.new(0,30,0),Vector3.new(0,-120,0),params)
        if not ground or not ground.Instance.CanCollide or ground.Normal.Y<.6 then return false end
        local landing=ground.Position+Vector3.new(0,3,0)
        safeReturnFrame=CFrame.lookAt(landing,Vector3.new(enemyRoot.Position.X,landing.Y,enemyRoot.Position.Z))
        safePlatform.CFrame=CFrame.new(landing+Vector3.new(0,60,0))
        myRoot.CFrame=safePlatform.CFrame+Vector3.new(0,5,0);myRoot.AssemblyLinearVelocity=Vector3.zero
        return true
    end
    while not disposed do
        if kaitun.enabled then
            local location=kaitunLocation()
            local opponent
            if location=="ranked" then
                for _,other in ipairs(Players:GetPlayers()) do if other~=player then opponent=other;break end end
            end
            local enemy=opponent and opponent.Character
            watchCharacter(enemy)
            local now=os.clock()
            local baldUlt=enemy and enemy:GetAttribute("Character")=="Bald" and enemy:GetAttribute("Ulted")==true
            local otherUlt=enemy and enemy:GetAttribute("Character")~="Bald" and enemy:GetAttribute("Ulted")==true
            if baldUlt then ultCycleStart=ultCycleStart or now else ultCycleStart=nil end
            -- Once Death Counter has been used, resume after its ten-second window
            -- instead of restarting the normal Saitama attack/rest cycle.
            local ultThreat=now<safeUntil or otherUlt or (baldUlt and not counterUsedThisUlt and ((now-ultCycleStart)%4)>=1)
            if not ultThreat and kaitunUltSafety and safePlatform and not safeManual and enemy then
                safeLandingReady=positionSafeBehind(enemy)
                if not safeLandingReady then ultThreat=true end
            end
            if ultThreat then
                kaitunUltSafety=true
                combatOn=false;combatTarget=nil
                if not safePlatform then enterSafeZone(false) end
                safeLandingReady=positionSafeBehind(enemy)
            elseif kaitunUltSafety then
                kaitunUltSafety=false
                local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
                if safePlatform and not safeManual and h and h.Health>0 and h.Health/math.max(h.MaxHealth,1)>=.8 then leaveSafeZone(true) end
            end
            if location=="ranked" then
                matchSince=matchSince or os.clock()
                if not opponent then
                    combatOn=false;combatTarget=nil;deadSince=nil;opponentId=nil
                    kaitunQueue()
                else
                if opponent.UserId~=opponentId then
                    opponentId=opponent.UserId;deadSince=nil
                end
                local character=opponent and opponent.Character
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health>0 then
                    deadSince=nil
                    combatOn=not ultThreat and os.clock()-matchSince>=15
                elseif humanoid and humanoid.Health<=0 or deadSince then
                    combatOn=false;combatTarget=nil
                    deadSince=deadSince or os.clock()
                    if os.clock()-deadSince>=15 then kaitunQueue() end
                else
                    combatOn=false -- Character not spawned yet; do not infer a death.
                end
                end
            else
                matchSince=nil;deadSince=nil;opponentId=nil;combatOn=false
                if location=="lobby" then kaitunQueue() end
            end
        else matchSince=nil;deadSince=nil;opponentId=nil;kaitunUltSafety=false;watchCharacter(nil) end
        task.wait(.1)
    end
end)
if kaitun.enabled then kaitunStart(true) end
LiveMCP.onCleanup(function() combatOn=false end)

openVectorUI=function()
task.spawn(function()
    local rayWindow
    local ok, err = pcall(function()
        local cache=getgenv and getgenv() or _G
        local rayfield=cache.__VectorRayfieldLibrary
        local lastError
        for attempt=1,3 do
            if type(rayfield)=="table" and type(rayfield.CreateWindow)=="function" then break end
            local loaded,result=pcall(function()
                local source=game:HttpGet("https://sirius.menu/gen2",true)
                local loader,loadError=loadstring(source)
                assert(loader,loadError)
                local library=loader()
                assert(type(library)=="table" and type(library.CreateWindow)=="function","Rayfield returned no library")
                return library
            end)
            if loaded then rayfield=result;cache.__VectorRayfieldLibrary=result else lastError=result;task.wait(attempt) end
        end
        assert(type(rayfield)=="table" and type(rayfield.CreateWindow)=="function",tostring(lastError))
        if disposed then return end
        rayWindow = rayfield:CreateWindow({name="VECTOR", subtitle="Standalone release", sidebarLayout=true, theme="cobalt", showName="VECTOR"})
        if disposed then rayWindow:Unload(); return end
        isRayUIOpen = function() return rayWindow.unloaded or rayWindow.animating or rayWindow.hidden ~= true end
        local movementTab=rayWindow:CreateTab({name="Movement"})
        movementTab:CreateToggle({name="Noclip",value=enabled,callback=function(v) setEnabled(v) end})
        movementTab:CreateToggle({name="Auto bhop",description="Hold Space to jump repeatedly; pauses while UI is open",value=false,callback=function(v) bhopEnabled=v end})
        local cframeSpeedOn,cframeSpeed=false,16
        local vectorPickupBusy=false
        movementTab:CreateToggle({name="CFrame speed boost",value=false,callback=function(v) cframeSpeedOn=v end})
        movementTab:CreateSlider({name="Movement speed",range={1,100},increment=1,value=16,suffix="stud/s",callback=function(v) cframeSpeed=v end})
        connect(game:GetService("RunService").Heartbeat,function(dt)
            if not cframeSpeedOn or vectorPickupBusy then return end
            local character=player.Character;local h=character and character:FindFirstChildOfClass("Humanoid");local root=character and character:FindFirstChild("HumanoidRootPart")
            if h and root and h.Health>0 and h.MoveDirection.Magnitude>0 and not safePlatform then root.CFrame=root.CFrame+h.MoveDirection*(cframeSpeed-h.WalkSpeed)*math.min(dt,.1) end
        end)
        movementTab:CreateToggle({name="Freecam",description="WASD + Q/E; hold right mouse to look",value=freeEnabled,callback=function(v) setFreecam(v) end})
        movementTab:CreateToggle({name="ESP · all players",value=false,callback=function(v) if setESPExternal then setESPExternal(v) end end})
        movementTab:CreateToggle({name="ESP · only Ulted",value=false,callback=function(v) if setESPOptionExternal then setESPOptionExternal("ultOnly",v) end end})
        movementTab:CreateToggle({name="ESP · only Saitama",value=false,callback=function(v) if setESPOptionExternal then setESPOptionExternal("baldOnly",v) end end})
        movementTab:CreateToggle({name="ESP · ultimate notifications",value=true,callback=function(v) if setESPOptionExternal then setESPOptionExternal("ultimate",v) end end})
        movementTab:CreateToggle({name="ESP · rage percentage",value=true,callback=function(v) if setESPOptionExternal then setESPOptionExternal("meter",v) end end})
        movementTab:CreateButton({name="Local storage",description="Show the local VECTOR storage folder",callback=function() LiveMCP.showWorkspace() end})
        movementTab:CreateButton({name="Unload VECTOR",callback=function() LiveMCP.cleanup() end})

        local camTab=rayWindow:CreateTab({name="Cameras"})
        local camChoices=camTab:CreateDropdown({name="Camera",options={},callback=function(value)
            for i,item in ipairs(cams) do if item.name==value then selected=i;updateList();break end end
        end})
        local function refreshCameraChoices()
            local options={};for _,item in ipairs(cams) do table.insert(options,item.name) end
            camChoices:Refresh(options)
        end
        camTab:CreateButton({name="Add camera",description="Move your cursor to a surface and click; Esc cancels",callback=function()
            rayWindow:Hide();invokeButton(pick)
        end})
        camTab:CreateButton({name="Refresh camera list",callback=refreshCameraChoices})
        camTab:CreateButton({name="View / stop camera",callback=function() invokeButton(watch) end})
        camTab:CreateButton({name="Delete selected camera",callback=function() invokeButton(removeCam);refreshCameraChoices() end})
        camTab:CreateButton({name="Look left",callback=function() invokeButton(left) end})
        camTab:CreateButton({name="Look right",callback=function() invokeButton(right) end})
        camTab:CreateButton({name="Zoom in",callback=function() invokeButton(zoomIn) end})
        camTab:CreateButton({name="Zoom out",callback=function() invokeButton(zoomOut) end})
        camTab:CreateButton({name="Toggle first / third person",callback=function() invokeButton(viewMode) end})
        camTab:CreateToggle({name="Player boxes",value=false,callback=function(v) if boxesEnabled~=v then invokeButton(boxes) end end})
        camTab:CreateToggle({name="Night vision",value=false,callback=function(v) setNight(v) end})

        local animationTab=rayWindow:CreateTab({name="Animations"})
        local observed=animationTab:CreateDropdown({name="Playing animation",options={},callback=function(value)
            local id=value and value:match("rbxassetid://(%d+)")
            if id then local copy=setclipboard or toclipboard;if type(copy)=="function" then pcall(copy,"rbxassetid://"..id) end end
        end})
        local function refreshObserved()
            local values={};local model=player.Character;local h=model and model:FindFirstChildOfClass("Humanoid")
            local animator=h and h:FindFirstChildOfClass("Animator")
            if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
                local anim=track.Animation
                if anim then table.insert(values,anim.Name.." | "..anim.AnimationId.." | "..track.Priority.Name) end
            end end
            for id,item in pairs(pinnedAnimations) do table.insert(values,"PIN | "..item.name.." | "..id) end
            observed:Refresh(values)
        end
        animationTab:CreateButton({name="Refresh playing animations",callback=refreshObserved})
        animationTab:CreateInput({name="Pin / unpin animation ID",placeholder="rbxassetid://...",callback=function(value)
            local id=value:match("(%d+)$")
            if id then local asset="rbxassetid://"..id;if pinnedAnimations[asset] then pinnedAnimations[asset]=nil else pinnedAnimations[asset]={name="Animation",priority="Action"} end;refreshObserved() end
        end})
        animationTab:CreateButton({name="Start / stop recording",callback=function() invokeButton(captureButton) end})
        animationTab:CreateButton({name="Copy recording JSON",callback=function() invokeButton(copyCapture) end})

        local playTab=rayWindow:CreateTab({name="Play animation"})
        local playChoices=playTab:CreateDropdown({name="Saved animation",options={},callback=function(value) end})
        local function refreshPlayChoices()
            local values={};for _,entry in ipairs(playEntries) do table.insert(values,entry.id) end
            playChoices:Refresh(values)
        end
        playTab:CreateInput({name="Add animation ID",placeholder="rbxassetid://...",callback=function(value)
            idInput.Text=value;invokeButton(addAnimation);refreshPlayChoices()
        end})
        playTab:CreateButton({name="Toggle selected animation",callback=function()
            local id=playChoices.value and playChoices.value[1]
            for _,entry in ipairs(playEntries) do if entry.id==id then
                entry.enabled=not entry.enabled;if not entry.enabled then clearPlayTrack(id) end
                savePlayEntries();drawPlayEntries();break
            end end
        end})
        playTab:CreateButton({name="Delete selected animation",callback=function()
            local id=playChoices.value and playChoices.value[1]
            for i,entry in ipairs(playEntries) do if entry.id==id then clearPlayTrack(id);table.remove(playEntries,i);savePlayEntries();drawPlayEntries();break end end
            refreshPlayChoices()
        end})
        refreshPlayChoices()

        if isStrongestBattlegrounds then
            local combatTab=rayWindow:CreateTab({name="Combat"})
            local pingStat=combatTab:CreateStat({name="Measured network latency",value=0,suffix=" ms"})
            local leadStat=combatTab:CreateStat({name="Prediction lead",value=0,suffix=" studs"})
            task.spawn(function()
                while not disposed and not rayWindow.unloaded do
                    pingStat:Set(math.floor(predictionInfo.latency*1000))
                    leadStat:Set(math.floor(predictionInfo.offset*100)/100)
                    task.wait(.5)
                end
            end)
            -- One-shot trash interaction for The Strongest Battlegrounds.
do
(function()
    local floatGui = LiveMCP.track(make("ScreenGui", playerGui, {Name="VectorTrashButton", ResetOnSpawn=false, DisplayOrder=40}))
    local container = make("Frame", floatGui, {Size=UDim2.fromOffset(155,68),Position=UDim2.new(.05,0,.4,0),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,Active=true})
    corner(container,8)
    make("UIStroke",container,{Color=C.accent,Transparency=.35,Thickness=1})
    local grip=make("TextLabel",container,{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,Text="☰  DRAG HERE",TextSize=10,TextColor3=C.muted,Font=Enum.Font.GothamBold,Active=true})
    local runButton=button(container,"TRASH · HIT ONCE",8,26,139,34)
    runButton.TextSize=10
    local dragging,start,origin=nil,nil,nil
    connect(grip.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=input;start=input.Position;origin=container.Position
        end
    end)
    connect(Input.InputChanged,function(input)
        if not dragging then return end
        if dragging.UserInputType==Enum.UserInputType.Touch and input~=dragging then return end
        if dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=input.Position-start
        container.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
    end)
    connect(Input.InputEnded,function(input) if input==dragging then dragging=nil end end)
    local busy=false
    local faceTrash
    local pickupFrame
    local savedAutoRotate,lockedHumanoid
    local function releasePickup()
        faceTrash=nil;pickupFrame=nil;vectorPickupBusy=false
        if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.AutoRotate=savedAutoRotate end
        lockedHumanoid=nil
    end
    local runService=game:GetService("RunService")
    runService:BindToRenderStep("VectorTrashFacing",Enum.RenderPriority.Last.Value+10,function()
        if not faceTrash or not faceTrash.Parent then return end
        local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then local p=faceTrash:GetPivot().Position;local pos=pickupFrame and pickupFrame.Position or r.Position;r.CFrame=CFrame.lookAt(pos,Vector3.new(p.X,pos.Y,p.Z));r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;local h=c:FindFirstChildOfClass("Humanoid");if h then
            if lockedHumanoid~=h then lockedHumanoid=h;savedAutoRotate=h.AutoRotate end
            h.AutoRotate=false;h:Move(Vector3.zero,false)
        end end
    end)
    LiveMCP.onCleanup(function() runService:UnbindFromRenderStep("VectorTrashFacing");releasePickup() end)
    local soul, soulConnection, savedSubject,savedSoulCameraType
    local returnFromSoul=false
    local savedMouseBehavior,savedMouseIcon
    connect(Input.InputBegan,function(input,processed)
        if not processed and soul and input.KeyCode==Enum.KeyCode.E then returnFromSoul=true end
    end)
    local function endSoul()
        local cf=soul and soul:GetPivot()
        if soulConnection then soulConnection:Disconnect();soulConnection=nil end
        runService:UnbindFromRenderStep("VectorTrashSoulCamera")
        if savedMouseBehavior then Input.MouseBehavior=savedMouseBehavior;savedMouseBehavior=nil end
        if savedMouseIcon~=nil then Input.MouseIconEnabled=savedMouseIcon;savedMouseIcon=nil end
        local camera=workspace.CurrentCamera
        if camera and soul then camera.CameraType=savedSoulCameraType or Enum.CameraType.Custom;camera.CameraSubject=savedSubject or (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) end
        if soul then soul:Destroy();soul=nil end
        return cf
    end
    local function startSoul(character)
        endSoul()
        local old=character.Archivable;character.Archivable=true
        soul=character:Clone();character.Archivable=old
        assert(soul,"Could not clone character")
        soul.Name="VECTOR Local Soul"
        for _,v in ipairs(soul:GetDescendants()) do
            if v:IsA("BaseScript") then v:Destroy()
            elseif v:IsA("BasePart") then v.LocalTransparencyModifier=0;v.Transparency=1;v.Anchored=false;v.CanCollide=false
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false end
        end
        local h=soul:FindFirstChildOfClass("Humanoid");local r=soul:FindFirstChild("HumanoidRootPart")
        assert(h and r,"Clone has no humanoid")
        h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        local originalHumanoid=character:FindFirstChildOfClass("Humanoid")
        local defaultSpeed=originalHumanoid.WalkSpeed
        r.CanCollide=true;soul.Parent=workspace
        local camera=workspace.CurrentCamera;savedSubject=camera.CameraSubject;savedSoulCameraType=camera.CameraType;camera.CameraSubject=h
        returnFromSoul=false
        savedMouseBehavior=Input.MouseBehavior;savedMouseIcon=Input.MouseIconEnabled
        local _,yaw=camera.CFrame:ToOrientation();local pitch=0
        runService:BindToRenderStep("VectorTrashSoulCamera",Enum.RenderPriority.Last.Value+20,function()
            if not soul or not r.Parent then return end
            Input.MouseBehavior=Enum.MouseBehavior.LockCenter;Input.MouseIconEnabled=false
            local d=Input:GetMouseDelta();yaw=yaw-d.X*.003;pitch=math.clamp(pitch-d.Y*.003,-1.3,1.3)
            local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable
            c.CFrame=CFrame.new(r.Position+Vector3.new(0,1.5,0))*CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)
        end)
        local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
        soulConnection=game:GetService("RunService").Heartbeat:Connect(function()
            if not soul or not r.Parent then return end
            local c=workspace.CurrentCamera;local move=controls:GetMoveVector()
            local world=c.CFrame:VectorToWorldSpace(move);world=Vector3.new(world.X,0,world.Z)
            if world.Magnitude>1 then world=world.Unit end
            h.WalkSpeed=cframeSpeedOn and cframeSpeed or defaultSpeed
            h:Move(world,false)
            if Input:IsKeyDown(Enum.KeyCode.Space) then h.Jump=true end
            c.CameraSubject=h
        end)
    end
    LiveMCP.onCleanup(endSoul)
    local function availableTrash(obj)
        if not obj or not obj:IsA("Model") or obj.Name:lower():gsub("[%s_%-]","")~="trashcan" or not obj:IsDescendantOf(workspace) then return false end
        local part=obj:FindFirstChild("Trashcan")
        return part and part:IsA("BasePart") and obj:GetAttribute("Broken")==false and part.Transparency==0 and part.CanCollide and part.Anchored
    end
    local function visitTrash()
        if busy and soul then returnFromSoul=true;return end
        if busy or vectorPickupBusy then return end
        busy=true;runButton.Text="SEARCHING..."
        local moved,original,character,root,humanoid,remote,held=false,nil,nil,nil,nil,nil,false
        local ok,err=pcall(function()
            character=player.Character
            humanoid=character and character:FindFirstChildOfClass("Humanoid")
            root=character and character:FindFirstChild("HumanoidRootPart")
            remote=character and character:FindFirstChild("Communicate")
            assert(humanoid and humanoid.Health>0 and root and remote and remote:IsA("RemoteEvent"),"Character or remote unavailable")
            local candidates={}
            for _,obj in ipairs(workspace:GetDescendants()) do
                local name=obj.Name:lower():gsub("[%s_%-]","")
                if availableTrash(obj) then
                    local parent=obj.Parent
                    local parentName=parent and parent.Name:lower():gsub("[%s_%-]","") or ""
                    local containsTrashcan=false
                    if name=="trash" then
                        for _,child in ipairs(obj:GetDescendants()) do
                            if child:IsA("Model") and child.Name:lower():gsub("[%s_%-]","")=="trashcan" then containsTrashcan=true;break end
                        end
                    end
                    if parentName~="trashcan" and not containsTrashcan then table.insert(candidates,obj) end
                end
            end
            assert(#candidates>0,"No trash models found")
            -- Randomize the list; try another model if there is no ground behind it.
            for i=#candidates,2,-1 do local j=math.random(i);candidates[i],candidates[j]=candidates[j],candidates[i] end
            local chosen,destination
            for _,obj in ipairs(candidates) do
                local cf,size=obj:GetBoundingBox()
                local direction=cf.LookVector
                direction=Vector3.new(direction.X,0,direction.Z)
                direction=direction.Magnitude>.01 and direction.Unit or Vector3.new(0,0,-1)
                local behind=cf.Position-direction*(size.Z/2+3)
                local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character,obj}
                local ground=workspace:Raycast(behind+Vector3.new(0,30,0),Vector3.new(0,-80,0),params)
                if ground and ground.Instance:IsA("BasePart") and ground.Instance.CanCollide and ground.Normal.Y>.65 then
                    local position=ground.Position+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.5,0)
                    chosen=obj;destination=CFrame.lookAt(position,Vector3.new(cf.Position.X,position.Y,cf.Position.Z));break
                end
            end
            assert(chosen and destination,"No ground behind a trash model")
            original=root.CFrame
            startSoul(character)
            faceTrash=chosen
            pickupFrame=destination;vectorPickupBusy=true
            root.CFrame=destination;root.AssemblyLinearVelocity=Vector3.zero;moved=true
            runButton.Text="MOVING...";task.wait(.35)
            assert(player.Character==character and humanoid.Health>0 and root.Parent and availableTrash(chosen),"Character or target changed")
            assert((root.Position-destination.Position).Magnitude<8,"Game did not keep the teleport")
            remote:FireServer({Goal="LeftClick",MousePos=CFrame.new(chosen:GetPivot().Position),Tick=1});held=true
            runButton.Text="ATTACKING...";task.wait(.12)
            remote:FireServer({Goal="LeftClickRelease",Tick=1});held=false
            task.wait(.7)
            local pickupDeadline=os.clock()+4.3
            repeat task.wait(.1) until character:FindFirstChild("Trash Can") or player.Character~=character or humanoid.Health<=0 or disposed or os.clock()>=pickupDeadline
            assert(character:FindFirstChild("Trash Can"),"Pickup not confirmed within 5 seconds")
            runButton.Text="E · RETURN TO BODY"
            repeat task.wait(.05) until returnFromSoul or player.Character~=character or humanoid.Health<=0 or disposed or not soul
        end)
        if held and remote and remote.Parent and player.Character==character then pcall(function() remote:FireServer({Goal="LeftClickRelease",Tick=1}) end) end
        local returned=false
        releasePickup()
        local soulPosition=endSoul()
        if moved and original and player.Character==character and humanoid and humanoid.Health>0 and root and root.Parent then
            returned=pcall(function() root.CFrame=soulPosition or original;root.AssemblyLinearVelocity=Vector3.zero end)
        end
        runButton.Text=ok and returned and "DONE · RETURNED" or (ok and "RETURN FAILED" or "FAILED · SEE LOG")
        if not ok then warn("[VECTOR Trash] "..tostring(err)) end
        task.delay(2,function() if runButton.Parent and not busy then runButton.Text="TRASH · HIT ONCE" end end)
        busy=false
    end
    connect(runButton.Activated,function() task.spawn(visitTrash) end)
    combatTab:CreateToggle({name="Floating trash button",description="Drag the handle; press once to visit a random trashcan, hit once and return",value=false,callback=function(value) container.Visible=value end})
    local trashTab=rayWindow:CreateTab({name="Trash Combat"})
    local distance=10
    local selectedTarget
    local panel=make("Frame",floatGui,{Size=UDim2.fromOffset(200,250),Position=UDim2.new(.7,0,.2,0),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,Active=true})
    corner(panel,8)
    local header=button(panel,"TARGETS     —",5,4,190,26)
    local list=make("ScrollingFrame",panel,{Position=UDim2.fromOffset(5,34),Size=UDim2.new(1,-10,1,-39),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new()})
    make("UIListLayout",list,{Padding=UDim.new(0,4)})
    local minimized=false
    connect(header.Activated,function() minimized=not minimized;list.Visible=not minimized;panel.Size=UDim2.fromOffset(200,minimized and 34 or 250) end)
    local dragInput,dragStart,dragOrigin
    connect(panel.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragInput=i;dragStart=i.Position;dragOrigin=panel.Position end end)
    connect(Input.InputChanged,function(i)
        if not dragInput then return end
        if dragInput.UserInputType==Enum.UserInputType.Touch and i~=dragInput then return end
        if dragInput.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=i.Position-dragStart;panel.Position=UDim2.new(dragOrigin.X.Scale,dragOrigin.X.Offset+d.X,dragOrigin.Y.Scale,dragOrigin.Y.Offset+d.Y)
    end)
    connect(Input.InputEnded,function(i) if i==dragInput then dragInput=nil end end)
    local function refreshTargets()
        for _,v in ipairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local choices=Players:GetPlayers();table.sort(choices,function(a,b) return a.Name<b.Name end)
        local count=0
        for _,p in ipairs(choices) do if p~=player then
            count=count+1
            local b=button(list,(selectedTarget==p and "✓ " or "")..p.DisplayName,0,0,180,28)
            b.Activated:Connect(function() selectedTarget=selectedTarget==p and nil or p;refreshTargets() end)
        end end
        list.CanvasSize=UDim2.fromOffset(0,count*32)
    end
    connect(Players.PlayerAdded,refreshTargets);connect(Players.PlayerRemoving,function(p) if p==selectedTarget then selectedTarget=nil end;task.defer(refreshTargets) end)
    refreshTargets()
    trashTab:CreateToggle({name="Show target panel",value=false,callback=function(v) panel.Visible=v;refreshTargets() end})
    trashTab:CreateSlider({name="Distance behind target",range={3,30},increment=1,value=10,suffix="studs",callback=function(v) distance=v end})
    local running=false
    local generation=0
    local focusedTarget
    local previousSubject
    local previousCameraType
    local ragdollFrame
    local rejectedCans=setmetatable({},{__mode="k"})
    local function isRagdoll(character)
        local h=character and character:FindFirstChildOfClass("Humanoid")
        if not h then return false end
        local state=h:GetState()
        return h.PlatformStand or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.Physics or character:GetAttribute("Ragdoll")==true or character:GetAttribute("Ragdolled")==true
    end
    local function validTrashTarget(p)
        local c=p and p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
        return p and p~=player and p.Parent and h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
    end
    connect(game:GetService("RunService").RenderStepped,function()
        if not running or not validTrashTarget(focusedTarget) then return end
        local camera=workspace.CurrentCamera;local targetHumanoid=focusedTarget.Character:FindFirstChildOfClass("Humanoid")
        local tr=focusedTarget.Character:FindFirstChild("HumanoidRootPart")
        if camera and targetHumanoid and tr then
            camera.CameraType=Enum.CameraType.Scriptable;camera.CameraSubject=targetHumanoid
            local focus=tr.Position+Vector3.new(0,2,0)
            camera.CFrame=CFrame.lookAt(focus-tr.CFrame.LookVector*12+Vector3.new(0,5,0),focus)
        end
    end)
    local ghost
    local function clearGhost() if ghost then ghost:Destroy();ghost=nil end end
    local function makeGhost(character)
        clearGhost()
        local old=character.Archivable;character.Archivable=true
        local ok,copy=pcall(function() return character:Clone() end);character.Archivable=old
        if not ok or not copy then return end
        ghost=copy
        for _,v in ipairs(copy:GetDescendants()) do
            if v:IsA("BaseScript") then v:Destroy()
            elseif v:IsA("BasePart") then v.LocalTransparencyModifier=0;v.Transparency=math.max(v.Transparency,.45);v.CanCollide=false;v.Anchored=true
            elseif v:IsA("Humanoid") then v.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        end
        copy.Parent=workspace
    end
    local function click(remote,pos)
        remote:FireServer({Goal="LeftClick",MousePos=CFrame.new(pos),Tick=1})
        task.wait(.12)
        if remote.Parent then remote:FireServer({Goal="LeftClickRelease",Tick=1}) end
    end
    local function holdingTrash(character)
        local part=character and character:FindFirstChild("Trash Can")
        return part ~= nil and part:IsA("BasePart")
    end
    connect(game:GetService("RunService").Heartbeat,function()
        if running then
            local character=player.Character;local r=character and character:FindFirstChild("HumanoidRootPart")
            local h=character and character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health>0 and isRagdoll(character) then
                if not ragdollFrame then ragdollFrame=r.CFrame+Vector3.new(0,60,0) end
                faceTrash=nil;pickupFrame=nil;vectorPickupBusy=true
                r.CFrame=ragdollFrame;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
                return
            elseif ragdollFrame then ragdollFrame=nil;vectorPickupBusy=false end
        end
        if not running or busy or vectorPickupBusy or safePlatform or not validTrashTarget(focusedTarget) then return end
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        local hum=character and character:FindFirstChildOfClass("Humanoid")
        local tr=focusedTarget.Character:FindFirstChild("HumanoidRootPart")
        if root and hum and hum.Health>0 and tr and holdingTrash(character) then
            local aim=predictCombatPosition(tr)
            root.CFrame=CFrame.lookAt(aim-tr.CFrame.LookVector*distance,aim);root.AssemblyLinearVelocity=Vector3.zero
        end
    end)
    trashTab:CreateToggle({name="Auto combat trash",value=false,callback=function(value)
        running=value;generation=generation+1
        if value then
            local camera=workspace.CurrentCamera;previousSubject=camera and camera.CameraSubject;previousCameraType=camera and camera.CameraType
            combatOn=false
            local myGeneration=generation
            task.spawn(function()
                local target
                while running and generation==myGeneration and not disposed do
                    local ok,err=pcall(function()
                        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
                        local hum=character and character:FindFirstChildOfClass("Humanoid")
                        local remote=character and character:FindFirstChild("Communicate")
                        if busy or not root or not hum or hum.Health<=0 or not remote or safePlatform or isRagdoll(character) then task.wait(.5);return end
                        if selectedTarget then target=selectedTarget end
                        if not validTrashTarget(target) then
                            local targets={};for _,p in ipairs(Players:GetPlayers()) do if validTrashTarget(p) then table.insert(targets,p) end end
                            target=#targets>0 and targets[math.random(#targets)] or nil
                        end
                        focusedTarget=target
                        if not target then task.wait(1);return end
                        if holdingTrash(character) then
                            local tr=target.Character:FindFirstChild("HumanoidRootPart")
                            local aim=predictCombatPosition(tr)
                            local behind=aim-tr.CFrame.LookVector*distance
                            root.CFrame=CFrame.lookAt(behind,aim);root.AssemblyLinearVelocity=Vector3.zero
                            if running and validTrashTarget(target) and player.Character==character and hum.Health>0 and not safePlatform and holdingTrash(character) then click(remote,aim) end
                            local deadline=os.clock()+3
                            repeat task.wait(.1) until not running or player.Character~=character or not holdingTrash(character) or os.clock()>deadline
                            task.wait(.5);return
                        end
                        local cans={};for _,obj in ipairs(workspace:GetDescendants()) do if availableTrash(obj) and (rejectedCans[obj] or 0)<os.clock() then table.insert(cans,obj) end end
                        if #cans==0 then task.wait(1);return end
                        local can=cans[math.random(#cans)];local cf,size=can:GetBoundingBox()
                        local dir=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z);dir=dir.Magnitude>.01 and dir.Unit or Vector3.new(0,0,-1)
                        local back=cf.Position-dir*(size.Z/2+3)
                        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character,can}
                        local hit=workspace:Raycast(back+Vector3.new(0,30,0),Vector3.new(0,-80,0),params)
                        if not hit or not hit.Instance.CanCollide or hit.Normal.Y<.65 then task.wait(.3);return end
                        local original=root.CFrame
                        faceTrash=can
                        local pos=hit.Position+Vector3.new(0,hum.HipHeight+root.Size.Y/2+.5,0)
                        root.CFrame=CFrame.lookAt(pos,Vector3.new(cf.Position.X,pos.Y,cf.Position.Z));root.AssemblyLinearVelocity=Vector3.zero
                        pickupFrame=root.CFrame;vectorPickupBusy=true
                        local untilTime=os.clock()+.35
                        repeat
                            if not running or not root.Parent or isRagdoll(character) or not availableTrash(can) then break end
                            local look=can:GetPivot().Position;root.CFrame=CFrame.lookAt(root.Position,Vector3.new(look.X,root.Position.Y,look.Z))
                            task.wait()
                        until os.clock()>=untilTime
                        if not running or player.Character~=character or hum.Health<=0 or isRagdoll(character) or not availableTrash(can) or (root.Position-pos).Magnitude>8 or safePlatform then
                            if player.Character==character and hum.Health>0 and not safePlatform and not isRagdoll(character) then root.CFrame=original end
                            clearGhost();return
                        end
                        click(remote,cf.Position)
                        task.wait(.5)
                        local deadline=os.clock()+5
                        repeat task.wait(.1) until not running or player.Character~=character or isRagdoll(character) or holdingTrash(character) or os.clock()>deadline
                        clearGhost()
                        if not holdingTrash(character) then rejectedCans[can]=os.clock()+15 end
                        if not holdingTrash(character) and player.Character==character and hum.Health>0 and not safePlatform and not isRagdoll(character) then root.CFrame=original;task.wait(.5) end
                    end)
                    releasePickup();clearGhost()
                    if not ok then warn("[VECTOR Trash Combat] "..tostring(err));task.wait(1) end
                end
                clearGhost()
            end)
        else clearGhost();ragdollFrame=nil;vectorPickupBusy=false;local camera=workspace.CurrentCamera;if camera then camera.CameraType=previousCameraType or Enum.CameraType.Custom;camera.CameraSubject=previousSubject or (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) end end
    end})
    LiveMCP.onCleanup(function() running=false;faceTrash=nil;pickupFrame=nil;vectorPickupBusy=false;clearGhost();local camera=workspace.CurrentCamera;if camera and previousSubject then camera.CameraType=previousCameraType or Enum.CameraType.Custom;camera.CameraSubject=previousSubject end end)
    LiveMCP.onCleanup(function() if floatGui then floatGui:Destroy() end end)
end)()
end

            combatTab:CreateToggle({name="Auto combat",value=false,callback=function(v) combatOn=v;combatTarget=nil;drawCombat() end})
            combatTab:CreateDropdown({name="Target mode",options={"Random","Selected","Multi"},value=combatConfig.mode,callback=function(v) combatConfig.mode=v;combatTarget=nil;drawCombat() end})
            combatTab:CreateDropdown({name="Position",options={"Under","Circle"},value=combatConfig.position,callback=function(v) combatConfig.position=v;drawCombat() end})
            for _,item in ipairs({{"Prediction","predict"},{"Speed 50","speed"},{"Void check","void"},{"Auto tools","skills"}}) do
                local label,key=item[1],item[2]
                combatTab:CreateToggle({name=label,value=combatConfig[key],callback=function(v)
                    combatConfig[key]=v
                    if key=="safe" and not v and safePlatform and not safeManual then leaveSafeZone(true) end
                    drawCombat()
                end})
            end
            local targetSelect=combatTab:CreateDropdown({name="Selected players",multiSelect=true,options={},callback=function(values)
                combatConfig.selected={};for _,name in ipairs(values) do local p=Players:FindFirstChild(name);if p then combatConfig.selected[tostring(p.UserId)]=true end end;combatTarget=nil
            end})
            local targetBlock=combatTab:CreateDropdown({name="Blacklist",multiSelect=true,options={},callback=function(values)
                combatConfig.blacklist={};for _,name in ipairs(values) do local p=Players:FindFirstChild(name);if p then combatConfig.blacklist[tostring(p.UserId)]=true end end;combatTarget=nil
            end})
            local function refreshPlayers()
                local options,selectedNames,blockedNames={},{},{}
                for _,p in ipairs(Players:GetPlayers()) do if p~=player then
                    table.insert(options,p.Name)
                    if combatConfig.selected[tostring(p.UserId)] then table.insert(selectedNames,p.Name) end
                    if combatConfig.blacklist[tostring(p.UserId)] then table.insert(blockedNames,p.Name) end
                end end
                targetSelect:Refresh(options);targetBlock:Refresh(options)
                targetSelect:Set(selectedNames,true);targetBlock:Set(blockedNames,true)
            end
            combatTab:CreateButton({name="Refresh player list",callback=refreshPlayers})
            local safeTab=rayWindow:CreateTab({name="Safe"})
            safeTab:CreateToggle({name="Safe zone auto",value=combatConfig.safe,callback=function(v)
                combatConfig.safe=v
                if not v and safePlatform and not safeManual then leaveSafeZone(true) end
                drawCombat()
            end})
            safeTab:CreateButton({name="Safe zone now",callback=function() enterSafeZone(true) end})
            safeTab:CreateButton({name="Return from safe zone",callback=function() leaveSafeZone(true) end})
            combatTab:CreateButton({name="Save combat settings",callback=saveCombatConfig})
            refreshPlayers()
        end
        local boardTab=rayWindow:CreateTab({name="Leaderboard"})
        local deaths=boardTab:CreateStat({name="Your deaths",value=session.deaths})
        local seconds=boardTab:CreateStat({name="Total VECTOR playtime",value=math.floor(totalSeconds),suffix=" s"})
        local scoreboard=boardTab:CreateDropdown({name="Players · Kills / Total / change",options={}})
        local function refreshScoreboard()
            refreshBoard()
            local rows={}
            for _,p in ipairs(Players:GetPlayers()) do
                local kills=statValue(p,"kills");local total=statValue(p,"totalkills");local base=session.baseline[tostring(p.UserId)]
                local delta=kills and base and kills-base or nil
                table.insert(rows,p.Name.." | "..numberText(kills).." / "..numberText(total).." / "..(delta and tostring(delta) or "—"))
            end
            scoreboard:Refresh(rows)
            deaths:Set(session.deaths);seconds:Set(math.floor(totalSeconds+os.clock()-savedAt))
        end
        boardTab:CreateButton({name="Refresh leaderboard",callback=refreshScoreboard})
        refreshScoreboard()
        task.spawn(function() while not disposed and rayWindow and not rayWindow.unloaded do
            task.wait(5);if not disposed and not rayWindow.unloaded then pcall(refreshScoreboard) end
        end end)

        local tab = rayWindow:CreateTab({name="Aim"})
        tab:CreateToggle({name="Automatic aim", value=false, callback=function(value) aimEnabled=value;drawAim() end})
        tab:CreateDropdown({name="Aim control",options={"Camera","Relative mouse"},value="Camera",description=relativeMove and "Aim pauses when the cursor is visible" or "Relative mouse is unavailable in this executor",callback=function(value) aimMode=value end})
        tab:CreateToggle({name="Instant aim",description="Snap directly to the target when Automatic aim is enabled",value=false,callback=function(value) aimInstant=value end})
        tab:CreateToggle({name="Aim wall check",description="Only aim when the target is not blocked",value=true,callback=function(value) aimWallCheck=value end})
        tab:CreateToggle({name="Trigger bot", description=triggerAvailable and "Fires when the crosshair points at a player; pauses while UI is open" or "Unavailable: executor has no mouse click function",value=false,callback=function(value)
            triggerEnabled=value and triggerAvailable
        end})
        tab:CreateToggle({name="Trigger team check",description="Skip teammates when Roblox team data is available",value=true,callback=function(value) triggerTeamCheck=value end})
        tab:CreateSlider({name="Trigger delay",range={.05,1},increment=.05,value=triggerDelay,suffix="s",callback=function(value) triggerDelay=value end})
        local rayAimFov=tab:CreateSlider({name="FOV", range={30,400},increment=10,value=aimRadius,suffix="px",callback=function(value) aimRadius=value;drawAim() end})
        local rayAimSmooth=tab:CreateSlider({name="Smooth", range={1,8},increment=1,value=smooth,callback=function(value) smooth=value;drawAim() end})
        local rayAimSpeed=tab:CreateSlider({name="Aim speed",range={8,120},increment=4,value=aimRate,callback=function(value) aimRate=value;drawAim() end})
        tab:CreateButton({name="Recommended aim settings",callback=function()
            aimRadius=120;smooth=2;aimRate=36
            rayAimFov:Set(aimRadius,true);rayAimSmooth:Set(smooth,true);rayAimSpeed:Set(aimRate,true)
            drawAim()
        end})
        tab:CreateToggle({name="Silent aim (demo)",description=silentSupported and "Selects a player in FOV and redirects the shot" or "Unavailable in this game or executor",value=false,callback=function(value)
            if not setSilent(value) then warn("[VECTOR] Silent aim unavailable") end
        end})
        tab:CreateSlider({name="Silent FOV",range={30,400},increment=10,value=silentRadius,suffix="px",callback=function(value) silentRadius=value;drawAim() end})
        tab:CreateToggle({name="Silent: whole screen",description="Choose the player nearest the crosshair anywhere on screen; disable to use Silent FOV",value=true,callback=function(value) silentState.screenMode=value end})
        -- Rayfield workspace for local Humanoid navigation.
do
(function()
    local pathService = game:GetService("PathfindingService")
    local obbyTab = rayWindow:CreateTab({name = "Obby"})
    local status = obbyTab:CreateText({name = "Navigation", text = "Select a destination to begin."})
    local goal, marker, selecting, generation = nil, nil, false, 0
    local running, selectionConnection, cancelSelectionConnection = false, nil, nil
    local activeHumanoid, activeRoot
    local function update(message)
        pcall(function() status:Set(message) end)
    end
    local function clearSelection()
        selecting = false
        if selectionConnection then selectionConnection:Disconnect(); selectionConnection = nil end
        if cancelSelectionConnection then cancelSelectionConnection:Disconnect(); cancelSelectionConnection = nil end
    end
    local function stopMovement(reason)
        generation = generation + 1
        running = false
        clearSelection()
        if activeHumanoid and activeRoot and activeHumanoid.Parent and activeRoot.Parent then
            pcall(function() activeHumanoid:MoveTo(activeRoot.Position) end)
        end
        activeHumanoid, activeRoot = nil, nil
        if reason then update(reason) end
    end
    local function clearMarker()
        if marker then marker:Destroy(); marker = nil end
    end
    local function selectedPoint()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local viewport = camera.ViewportSize
        local location = Input.MouseBehavior == Enum.MouseBehavior.LockCenter and Vector2.new(viewport.X/2, viewport.Y/2) or Input:GetMouseLocation()
        local ray = camera:ViewportPointToRay(location.X, location.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {}
        if player.Character then table.insert(excluded, player.Character) end
        if marker then table.insert(excluded, marker) end
        table.insert(excluded, camera)
        params.FilterDescendantsInstances = excluded
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
        if not result or not result.Instance:IsA("BasePart") or not result.Instance.CanCollide then return nil end
        return result.Position
    end
    local function beginSelection()
        stopMovement()
        selecting = true
        update("Select a solid surface in the world. Esc cancels.")
        rayWindow:Hide()
        local token = generation
        task.delay(.2, function()
            if not selecting or disposed or generation ~= token then return end
            selectionConnection = Input.InputBegan:Connect(function(input, processed)
                if not selecting or processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local point = selectedPoint()
                if not point then update("No solid surface selected. Click a solid surface or press Esc."); return end
                goal = point
                clearSelection(); clearMarker()
                marker = Instance.new("Part")
                marker.Name = "VectorObbyGoal"
                marker.Shape = Enum.PartType.Ball
                marker.Size = Vector3.new(1,1,1)
                marker.Color = C.accent
                marker.Material = Enum.Material.Neon
                marker.Transparency = .15
                marker.Anchored = true
                marker.CanCollide = false
                marker.CanTouch = false
                marker.CanQuery = false
                marker.Position = point + Vector3.new(0,.55,0)
                marker.Parent = workspace
                update(string.format("Destination selected: %.0f, %.0f, %.0f. Press Find and walk.",point.X,point.Y,point.Z))
                rayWindow:Show()
            end)
            cancelSelectionConnection = Input.InputBegan:Connect(function(input)
                if selecting and input.KeyCode == Enum.KeyCode.Escape then
                    clearSelection(); update("Destination selection cancelled."); rayWindow:Show()
                end
            end)
        end)
    end
    local function currentCharacter()
        local model = player.Character
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        local root = model and model:FindFirstChild("HumanoidRootPart")
        if not model or not humanoid or humanoid.Health <= 0 or not root then return nil end
        return model, humanoid, root
    end
    local function requestJump(model, humanoid, root, token)
        if not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            return false, "Jump state disabled by game"
        end
        if humanoid.Sit or humanoid.PlatformStand then return false, "Character cannot jump right now" end
        local landingDeadline = os.clock() + 1.5
        while running and generation==token and not disposed and player.Character==model and humanoid.Health>0 do
            local state=humanoid:GetState()
            if humanoid.FloorMaterial ~= Enum.Material.Air or state == Enum.HumanoidStateType.Climbing then break end
            if os.clock() >= landingDeadline then return false, "Not grounded before jump" end
            task.wait(.05)
        end
        if not running or generation~=token or disposed or player.Character~=model or humanoid.Health<=0 then return false,"Cancelled" end
        local startY = root.Position.Y
        local lastAttempt = 0
        local deadline = os.clock() + .7
        while running and generation==token and not disposed and player.Character==model and humanoid.Health>0 and os.clock()<deadline do
            local now=os.clock()
            if now-lastAttempt >= .12 then
                lastAttempt=now
                humanoid.Jump=true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            Run.Heartbeat:Wait()
            local state=humanoid:GetState()
            if root.Position.Y > startY + .3 or root.AssemblyLinearVelocity.Y > 2
                or state==Enum.HumanoidStateType.Jumping then return true end
        end
        return false,"Jump was not registered"
    end
    LiveMCP.register("obby_jump_status", function()
        local model, humanoid, root=currentCharacter()
        if not model then return {ready=false,running=running} end
        return {ready=true,running=running,state=tostring(humanoid:GetState()),floor=tostring(humanoid.FloorMaterial),
            jump_enabled=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),jump_power=humanoid.JumpPower,
            jump_height=humanoid.JumpHeight,use_jump_power=humanoid.UseJumpPower,platform_stand=humanoid.PlatformStand,
            seated=humanoid.Sit,vertical_velocity=root.AssemblyLinearVelocity.Y}
    end)
    LiveMCP.onCleanup(function() LiveMCP.unregister("obby_jump_status") end)
    -- Bounded geometric fallback: build a directed graph of actual landing surfaces.
    -- It estimates jumps from the character's own movement stats; it never teleports.
    local function buildPlatformRoute(model, humanoid, root, destination, rejected, token)
        local start = root.Position
        local delta = destination - start
        if delta.Magnitude > 300 then return nil, "Destination too far for platform scan" end
        local overlap = OverlapParams.new()
        overlap.FilterType = Enum.RaycastFilterType.Exclude
        overlap.FilterDescendantsInstances = {model}
        overlap.MaxParts = 300
        local size = Vector3.new(math.min(math.abs(delta.X)+100,350), math.min(math.abs(delta.Y)+100,250), math.min(math.abs(delta.Z)+100,350))
        local center = (start+destination)*.5
        local ok, parts = pcall(function() return workspace:GetPartBoundsInBox(CFrame.new(center),size,overlap) end)
        if not ok then return nil, "Platform scan unavailable" end
        local candidates = {}
        for _, part in ipairs(parts) do
            if part:IsA("BasePart") and part.CanCollide and part.CanQuery and part.Anchored and part.Transparency < .98
                and part.Size.X >= 1.2 and part.Size.Z >= 1.2 and part.CFrame.UpVector.Y >= .65
                and not part:IsDescendantOf(model) then
                table.insert(candidates,part)
            end
        end
        table.sort(candidates,function(a,b)
            return (a.Position-start).Magnitude+(a.Position-destination).Magnitude < (b.Position-start).Magnitude+(b.Position-destination).Magnitude
        end)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {model}
        local startHit = workspace:Raycast(start,Vector3.new(0,-12,0),rayParams)
        if not startHit or not startHit.Instance.CanCollide then return nil, "No support beneath character" end
        local nodes = {{Position=startHit.Position, part=startHit.Instance}, {Position=destination, part=nil}}
        local goalHit = workspace:Raycast(destination+Vector3.new(0,2,0),Vector3.new(0,-6,0),rayParams)
        if not goalHit or not goalHit.Instance.CanCollide or goalHit.Normal.Y < .65 then return nil, "Destination has no supported landing surface" end
        nodes[2].Position=goalHit.Position;nodes[2].part=goalHit.Instance
        local function addNode(part, x, z)
            local localTop = Vector3.new(x,part.Size.Y/2,z)
            local surface = part.CFrame:PointToWorldSpace(localTop)
            local origin = surface+Vector3.new(0,3,0)
            local hit=workspace:Raycast(origin,Vector3.new(0,-6,0),rayParams)
            if not hit or hit.Instance~=part or hit.Normal.Y<.65 then return end
            for _,node in ipairs(nodes) do if (node.Position-hit.Position).Magnitude < .35 then return end end
            table.insert(nodes,{Position=hit.Position,part=part})
        end
        for i=1,math.min(#candidates,45) do
            if token and (not running or generation~=token or disposed) then return nil,"Cancelled" end
            local part=candidates[i]
            local marginX=math.max(0,part.Size.X*.5-1)
            local marginZ=math.max(0,part.Size.Z*.5-1)
            addNode(part,0,0)
            for _,point in ipairs({start,destination}) do
                local relative=part.CFrame:PointToObjectSpace(point)
                addNode(part,math.clamp(relative.X,-marginX,marginX),math.clamp(relative.Z,-marginZ,marginZ))
            end
            if #nodes>=110 then break end
            if i%10==0 then task.wait() end
        end
        local gravity=workspace.Gravity
        if gravity<=0 then return nil,"Unsupported gravity" end
        local jumpVelocity=humanoid.UseJumpPower and humanoid.JumpPower or math.sqrt(math.max(0,2*gravity*humanoid.JumpHeight))
        local speed=math.max(0,humanoid.WalkSpeed)
        if jumpVelocity<=0 or speed<=0 then return nil,"Jump or movement is disabled" end
        local maxRise=jumpVelocity*jumpVelocity/(2*gravity)
        local function edgeKey(a,b)
            local function key(v) return string.format("%.0f,%.0f,%.0f",v.X,v.Y,v.Z) end
            return key(a.Position)..">"..key(b.Position)
        end
        local function walkable(a,b)
            local horizontal=Vector3.new(b.Position.X-a.Position.X,0,b.Position.Z-a.Position.Z).Magnitude
            if horizontal>8 or math.abs(b.Position.Y-a.Position.Y)>1.8 then return false end
            local steps=math.max(1,math.ceil(horizontal/2))
            for k=1,steps-1 do
                local p=a.Position:Lerp(b.Position,k/steps)
                local hit=workspace:Raycast(p+Vector3.new(0,3,0),Vector3.new(0,-6,0),rayParams)
                if not hit or not hit.Instance.CanCollide or hit.Normal.Y<.65 or math.abs(hit.Position.Y-p.Y)>2 then return false end
            end
            return true
        end
        local function jumpable(a,b)
            local diff=b.Position-a.Position
            local horizontal=Vector3.new(diff.X,0,diff.Z).Magnitude
            if horizontal<.5 or diff.Y>maxRise*.8 or diff.Y < -18 then return false end
            local discriminant=jumpVelocity*jumpVelocity-2*gravity*diff.Y
            if discriminant<=0 then return false end
            local flight=(jumpVelocity+math.sqrt(discriminant))/gravity
            if horizontal > speed*flight*.78 or flight>2.5 then return false end
            -- Approximate the swept body along a ballistic arc; reject solid obstacles.
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
            local excluded={model};if a.part then table.insert(excluded,a.part) end;if b.part and b.part~=a.part then table.insert(excluded,b.part) end
            params.FilterDescendantsInstances=excluded
            local previous=a.Position+Vector3.new(0,2.5,0)
            for step=1,8 do
                local fraction=step/8
                local t=flight*fraction
                local point=Vector3.new(a.Position.X+diff.X*fraction,a.Position.Y+jumpVelocity*t-.5*gravity*t*t+2.5,a.Position.Z+diff.Z*fraction)
                local movement=point-previous
                if movement.Magnitude>.01 then
                    local result=workspace:Raycast(previous,movement,params)
                    if result and result.Instance.CanCollide then return false end
                end
                previous=point
            end
            return true
        end
        local distance, previous, action, used = {[1]=0}, {}, {}, {}
        local checks=0
        for _=1,#nodes do
            local current, best=nil,math.huge
            for i=1,#nodes do if not used[i] and distance[i] and distance[i]<best then current,best=i,distance[i] end end
            if not current then break end
            if current==2 then break end
            used[current]=true
            for j=1,#nodes do
                if j~=current and not used[j] then
                    local from,to=nodes[current],nodes[j]
                    local key=edgeKey(from,to)
                    local direct=(to.Position-from.Position).Magnitude
                    if direct<=speed*1.4+6 and not rejected[key] then
                        local walking=walkable(from,to)
                        local jumping=not walking and jumpable(from,to)
                        if walking or jumping then
                            local cost=best+direct+(jumping and 4 or 0)
                            if not distance[j] or cost<distance[j] then
                                distance[j],previous[j]=cost,current
                                action[j]={jump=jumping,key=key}
                            end
                        end
                    end
                end
                checks=checks+1
                if checks%250==0 then
                    if token and (not running or generation~=token or disposed) then return nil,"Cancelled" end
                    task.wait()
                end
            end
        end
        if not previous[2] then return nil,string.format("No platform route found (%d surfaces)",#nodes) end
        local reverse,at={},2
        while at do
            local node=nodes[at];local edge=action[at]
            table.insert(reverse,{Position=node.Position,Action=edge and edge.jump and Enum.PathWaypointAction.Jump or Enum.PathWaypointAction.Walk,
                edgeKey=edge and edge.key or nil})
            at=previous[at]
        end
        local route={}
        for i=#reverse,1,-1 do table.insert(route,reverse[i]) end
        return route,nil,#nodes
    end
    -- Geometry-only diagnostic; it never moves the player's character.
    LiveMCP.register("obby_self_test", function()
        local folder=Instance.new("Folder")
        folder.Name="VectorObbyDiagnostic"
        folder.Parent=workspace
        local ok,result=pcall(function()
            local base=Vector3.new(10000,5000,10000)
            local function platform(x,z)
                local part=Instance.new("Part")
                part.Name="Platform"
                part.Size=Vector3.new(4,1,4)
                part.Anchored=true
                part.CanCollide=true
                part.Position=base+Vector3.new(x,0,z or 0)
                part.Parent=folder
                return part
            end
            platform(0)
            local middle=platform(7)
            local last=platform(14)
            local dummy=Instance.new("Model")
            dummy.Parent=folder
            local root=Instance.new("Part")
            root.Name="HumanoidRootPart"
            root.Size=Vector3.new(2,2,1)
            root.Anchored=true
            root.Position=base+Vector3.new(0,3,0)
            root.Parent=dummy
            local humanoid=Instance.new("Humanoid")
            humanoid.WalkSpeed=16
            humanoid.UseJumpPower=true
            humanoid.JumpPower=50
            humanoid.Parent=dummy
            local route,err,nodes=buildPlatformRoute(dummy,humanoid,root,base+Vector3.new(14,.5,0),{},nil)
            local jumps=0
            if route then for _,step in ipairs(route) do if step.Action==Enum.PathWaypointAction.Jump then jumps=jumps+1 end end end
            last.Position=base+Vector3.new(40,0,0)
            local unreachable,reason=buildPlatformRoute(dummy,humanoid,root,base+Vector3.new(40,.5,0),{},nil)
            middle.Position=base+Vector3.new(0,0,7)
            platform(7,7)
            platform(14,7)
            last.Position=base+Vector3.new(14,0,0)
            local detour,detourError=buildPlatformRoute(dummy,humanoid,root,base+Vector3.new(14,.5,0),{},nil)
            local detourJumps=0
            if detour then for _,step in ipairs(detour) do if step.Action==Enum.PathWaypointAction.Jump then detourJumps=detourJumps+1 end end end
            humanoid.WalkSpeed=3
            local slowRoute=buildPlatformRoute(dummy,humanoid,root,base+Vector3.new(14,.5,0),{},nil)
            return {reachable=route~=nil,jumps=jumps,nodes=nodes or 0,reachable_error=err or "",unreachable=unreachable==nil,
                unreachable_reason=reason or "",detour=detour~=nil,detour_jumps=detourJumps,detour_error=detourError or "",slow_jump_rejected=slowRoute==nil}
        end)
        folder:Destroy()
        assert(ok,result)
        return result
    end)
    LiveMCP.onCleanup(function() LiveMCP.unregister("obby_self_test") end)
    local function startNavigation()
        if not goal then update("Select a destination first."); return end
        stopMovement()
        local model, humanoid, root = currentCharacter()
        if not model then update("Character not ready. Try again after respawn."); return end
        if humanoid.Sit then update("Stand up before starting navigation."); return end
        if freeEnabled or cameraLooking then update("Stop camera mode before navigating."); return end
        generation = generation + 1
        local token, destination = generation, goal
        running, activeHumanoid, activeRoot = true, humanoid, root
        update("Finding a walk / jump / climb route...")
        task.spawn(function()
            local attempts, failure, rejected = 0, "No route found", {}
            while running and not disposed and generation == token and attempts < 3 do
                attempts = attempts + 1
                if player.Character ~= model or not model.Parent or humanoid.Health <= 0 or not root.Parent then
                    failure = "Character changed or died"; break
                end
                local path, points, routeType, scanError
                if attempts == 1 then
                    local ok = pcall(function()
                        path = pathService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
                            AgentCanClimb = true, WaypointSpacing = 4, Costs = {Water = math.huge}})
                        path:ComputeAsync(root.Position, destination)
                    end)
                    if ok and path and path.Status == Enum.PathStatus.Success then
                        local candidate=path:GetWaypoints()
                        local hasJump=false
                        for _,waypoint in ipairs(candidate) do
                            if waypoint.Action == Enum.PathWaypointAction.Jump then hasJump=true;break end
                        end
                        if not hasJump then
                            points=candidate;routeType="ROBLOX"
                        else
                            -- Check jump segments against the character's configured movement abilities.
                            path:Destroy();path=nil
                        end
                    else
                        if path then path:Destroy();path=nil end
                    end
                end
                if not points then
                    update("Scanning nearby platforms and possible jumps...")
                    local ok, route, reason = pcall(buildPlatformRoute,model,humanoid,root,destination,rejected,token)
                    if ok then points,scanError=route,reason else scanError="Platform scan error: "..tostring(route):sub(1,100) end
                    routeType="PLATFORMS"
                end
                if not running or generation ~= token or disposed then if path then path:Destroy() end; return end
                if not points or #points == 0 then
                    failure=scanError or "No route found"
                    if path then path:Destroy() end
                    task.wait(.3)
                else
                    local currentIndex, blocked = 1, false
                    local blockedConnection
                    if path then blockedConnection = path.Blocked:Connect(function(index)
                        if index >= currentIndex then blocked = true end
                    end) end
                    local reachedEnd = true
                    for i = 2, #points do
                        currentIndex = i
                        if not running or generation ~= token or disposed then reachedEnd = false; break end
                        if player.Character ~= model or not model.Parent or humanoid.Health <= 0 or not root.Parent then
                            failure="Character changed or died"; reachedEnd=false; break
                        end
                        local waypoint = points[i]
                        if blocked then failure="Path blocked";reachedEnd=false;break end
                        local jumping=waypoint.Action == Enum.PathWaypointAction.Jump
                        update(string.format("%s %d / %d · %s (attempt %d/3)",jumping and "Jumping" or "Walking",i,#points,routeType,attempts))
                        if jumping then
                            -- Hold position while waiting to land before attempting the next jump.
                            humanoid:MoveTo(root.Position)
                            local waitUntil=os.clock()+1.5
                            while running and generation==token and not disposed and player.Character==model and humanoid.Health>0
                                and humanoid.FloorMaterial==Enum.Material.Air and humanoid:GetState()~=Enum.HumanoidStateType.Climbing
                                and os.clock()<waitUntil do task.wait(.05) end
                        end
                        local finished, reached = false, false
                        local finishedConnection = humanoid.MoveToFinished:Connect(function(okMove) finished=true;reached=okMove end)
                        humanoid:MoveTo(waypoint.Position)
                        if jumping then
                            local jumped, jumpReason=requestJump(model,humanoid,root,token)
                            if not jumped then
                                finishedConnection:Disconnect()
                                if type(waypoint)=="table" and waypoint.edgeKey then rejected[waypoint.edgeKey]=true end
                                failure=jumpReason;reachedEnd=false;break
                            end
                        end
                        local deadline = os.clock() + math.clamp((root.Position-waypoint.Position).Magnitude / math.max(humanoid.WalkSpeed,4) * 3 + 2, 4, 10)
                        while running and generation==token and not disposed and not finished and not blocked and os.clock()<deadline
                            and player.Character==model and model.Parent and humanoid.Health>0 do task.wait(.1) end
                        finishedConnection:Disconnect()
                        if not running or generation~=token or disposed then reachedEnd=false;break end
                        if blocked or not finished or not reached then
                            if type(waypoint)=="table" and waypoint.edgeKey then rejected[waypoint.edgeKey]=true end
                            failure=blocked and "Path blocked" or "Could not reach waypoint";reachedEnd=false;break
                        end
                    end
                    if blockedConnection then blockedConnection:Disconnect() end
                    if path then path:Destroy() end
                    if not running or generation~=token or disposed then return end
                    if reachedEnd and (root.Position-destination).Magnitude <= 8 then
                        running=false;activeHumanoid=nil;activeRoot=nil
                        update("ARRIVED · destination reached.");return
                    end
                    if reachedEnd then failure="Destination was not reached" end
                    task.wait(.3)
                end
            end
            if running and generation==token and not disposed then
                running=false;activeHumanoid=nil;activeRoot=nil
                if failure=="Character changed or died" then update("STOPPED · character changed or died.")
                elseif failure=="Jump was not registered" or failure=="Jump state disabled by game" or failure=="Not grounded before jump" then
                    update("JUMP BLOCKED · "..failure..". Check the game's jump rules.")
                else update("IMPOSSIBLE · "..failure.." after 3 attempts.") end
            end
        end)
    end
    obbyTab:CreateButton({name="Select destination",description="Hide the UI, then click a solid surface. Esc cancels.",callback=beginSelection})
    obbyTab:CreateButton({name="Find and walk",description="Find a route and walk, jump or climb to the destination",callback=startNavigation})
    obbyTab:CreateButton({name="Stop",description="Cancel navigation and destination selection",callback=function() stopMovement("STOPPED · navigation cancelled.") end})
    obbyTab:CreateButton({name="Clear destination",callback=function() stopMovement("Destination cleared.");goal=nil;clearMarker() end})
    connect(player.CharacterRemoving,function(model)
        if player.Character == model or (activeHumanoid and activeHumanoid:IsDescendantOf(model)) then
            stopMovement("STOPPED · character removed.")
        end
    end)
    connect(Input.InputBegan,function(input,processed)
        if running and not processed and (input.KeyCode==Enum.KeyCode.W or input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.S or input.KeyCode==Enum.KeyCode.D) then
            stopMovement("STOPPED · manual movement detected.")
        end
    end)
    LiveMCP.onCleanup(function() stopMovement();clearMarker() end)
end)()
end

        local kt=rayWindow:CreateTab({name="Kaitun"})
        kt:CreateToggle({name="Auto Kaitun 1v1s",value=kaitun.enabled,callback=function(v)
            if v then kaitunStart();rayWindow:Unload() else kaitunStop() end
        end})
        rayfieldToggle=function() rayWindow:ToggleHide() end
        LiveMCP.onCleanup(function()
            rayfieldToggle=nil
            isRayUIOpen=function() return true end
            pcall(function() rayWindow:Unload() end)
        end)
        window.Visible=false
        rayfieldStatus.state="ready"
    end)
    if not ok then
        rayfieldStatus={state="failed",error=tostring(err)}
        if rayWindow then pcall(function() rayWindow:Unload() end) end
        warn("[VECTOR] Rayfield Gen2 unavailable: "..tostring(err))
        -- Keep the retired window hidden if Rayfield cannot be loaded.
    end
end)
end
if not kaitun.enabled then openVectorUI() end

end)()

end

redraw()
task.defer(function() if not disposed then resize(true) end end)
return "VECTOR UI updated. Noclip OFF; Freecam OFF. Minus / Right Shift = show/hide."
]=]
if type(makefolder)=="function" then
    local ok,err=pcall(function()
        if type(isfolder)~="function" or not isfolder("VECTOR") then makefolder("VECTOR") end
    end)
    if not ok then warn("[VECTOR] Cannot create storage folder: "..tostring(err)) end
end
if type(writefile)=="function" then
    local ok,err=pcall(writefile,"VECTOR/main.lua",payload)
    if not ok then warn("[VECTOR] Cannot install local resume file: "..tostring(err)) end
end
assert(loadstring,"VECTOR requires a host with loadstring support")
return assert(loadstring(payload,"VECTOR"))()
