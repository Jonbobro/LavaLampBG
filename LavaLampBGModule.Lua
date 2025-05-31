local TweenService = game:GetService("TweenService")

local LavaLampBG = {}
LavaLampBG.__index = LavaLampBG

--[[
---------------===========###Lava lamp BG module by @Jonbobro ###===========---------------

This module is used to make nice flowing background for frames, say you have a fancy weapon
	or a nice shop you want to have some movement to the backgrounds but dont want standard
	gradients. This module will put a few blobs to the background and move them around semi
	randomly to add some subtle, or very chaotic, life to your backgrounds.

The module will only work on frames and will set the frames to clip descendants just to try
	and minimize spoiling the effect though it barely works.

A quick and simple setup of the module can just be 
===========================================================================================
local LavaLampBG = require(Path.To.Module)

local Background = LavaLampBG.new({Frame = Path to frame you want to animate})

Background:Start()
===========================================================================================
Background Constructor

LavaLampBG.New({Parameters}) 

Creates a new background and returns the created one.

Available parameters

StylePreset : Enum? - If you call Module.StylePresets.[should autofill to the 30 included]

(*) can be used to overright StylePresets
*BackgroundColor : Color3 - Overrides the background color of the frame.
*BlobColors : {Color3} - An array of colors that will be used to determine blob colors.
*BGTransperency : number - The transparency of the background.
Frame : instance - The frame the background will be applied to. MUST be a frame!
BlobCount : number - The amount of "Blobs" that will be used for the background.
Blobsize : Udim2 - The size of the "Blobs". The aspect ratio is locked to 1:1.
BlobTransparency : number - The transparency of the "Blobs"
MoveDelay : number - How long it takes the blobs to move * some randomness. 
ImageId : ImageId - Overrides the blobs to whatever you set as the image id.
RandomRotation : boolean - Sets the blobs to rotate randomly during moves or not
	(only really needed with certain images so if using blobs doesn't have to be set.)
--------------------------------------------------------------------------------------------
Background Methods

LavaLampBG:Start()
Starts the animation.

LavaLampBG:Pause()
Pauses the current animation.

LavaLampBG:Resume()
Restarts the animation.

LavaLampBG:Stop(DestroyBlobs : boolean)
Will end animation and if DestroyBlobs == true will delete the blobs and blob folder.

=============================================================================================
Things to note,

-The default style is Rainbow. you can change the default in the .new function
-I would suggest keeping the BlobSize to a value between 1 and 2 and have roughly 15-30 blobs
if you want the background to be more "full" 
-If you want to have rounded corners for a ui the only way i have found is to use a CanvasGroup
due to clipdescendants being weird with uicorners.
-I have tested this place with several hundred blobs on my several year old laptop and got no
performance drops but i can't gurantee that for mobile devices etc so try to keep the amount of 
blobs to a minimum.

This was just a 3 hours chaos project so I likely wont be updating this much at all.

Anyways I hope you enjoy this module. First one I will have released. Likely has a lot to be 
improved and fixed. I am self taught so how this is laid out is likely awful and needs a rework
but I saw something I thought was cool for the new Android OneUI update and wanted to recreate
the moving backgrounds on some app icons. Its not perfect but its the closest I could come to 
with what I know roblox has. 
]]


--===CONSTRUCTOR===--
function LavaLampBG.new(config)
	local self = setmetatable({}, LavaLampBG)
	
	--[Must have a frame for blobs to be contained inside]--
	if config.Frame.ClassName ~= "Frame" then
		error("[LavaLampBG] Expected a gui Frame for the Frame got " .. config.Frame.ClassName .. " instead!")
	end
	
	config.Frame.ClipsDescendants = true
	
	--[If a parameter is invalid will reset to nil to use the default, 100% jank but its how my brain works]--
	if typeof(config.MoveDelay) ~= "number" then config.MoveDelay = nil end
	if typeof(config.BackgroundTransparency) ~= "number" then config.BackgroundTransparency = nil end
	if typeof(config.BlobCount) ~= "number" then
		config.BlobCount = nil
	else
		config.BlobCount = math.floor(config.BlobCount)
	end
	if typeof(config.RandomRotation) ~= "boolean" then config.RandomRotation = false end
	if typeof(config.BackgroundColor) ~= "Color3" then config.BackgroundColor = nil end
	if typeof(config.BlobSize) ~= "UDim2" then config.BlobSize = nil end
	if typeof(config.BlobTransparency) ~= "number" then config.BlobTransparency = nil end
	
	--[Removes invalid colors from override if its not a color3]--
	if config.BlobColors then
		for i = #config.BlobColors, 1, -1 do
			if typeof(config.BlobColors) ~= "Color3" then
				table.remove(config.BlobColors, i)
			end
		end
	end
	
	local preset = nil
	
	if typeof(config.StylePreset) == "string" then
		preset = LavaLampBG.StylePresets[config.StylePreset]
	elseif typeof(config.StylePreset) == "table" then
		preset = config.StylePreset
	end

	if not preset then
		warn("[LavaLampBG] Invalid StylePreset. Falling back to 'Rainbow'.")
		preset = LavaLampBG.StylePresets.Rainbow
	end
	
	--[Chaos to handle defaults, overrides, and the presets]--
	self.Frame = config.Frame
	self.ImageId = config.ImageId or "http://www.roblox.com/asset/?id=8119252523"
	self.BackgroundColor = config.BackgroundColor or preset.BackgroundColor
	self.BlobColors = config.BlobColors or preset.BlobColors
	self.BackgroundTransparency = config.BackgroundTransparency or preset.BackgroundTransparency or 0
	self.BlobSize = config.BlobSize or UDim2.fromScale(2, 2)
	self.BlobCount = config.BlobCount or 30
	self.MoveDelay = config.MoveDelay or 2
	self.BlobTransparency = config.BlobTransparency or 0
	self.RandomRotation = config.RandomRotation or false
	
	--[Holders to manage the runtime functions]--
	self.Running = false
	self.BlobTweens = {}
	self.Blobs = {}

	self:Initialize()
	return self
end


--===ANIMATOR===--
function LavaLampBG:AnimateBlob(blob, index, totalBlobs)
	task.spawn(function()
		while self.Running and blob and blob.Parent do
			--[Sets blob to a random rotation if allowed]--
			local randomRotation = 0
			if self.RandomRotation then
				randomRotation = math.random(0, 180)
			end

			--[Sets the direction for the blob to go to with slight randomness]--
			local baseAngle = ((index - 1) / totalBlobs) * 2 * math.pi
			local randomOffset = math.rad(math.random(-20, 20))
			local angle = baseAngle + randomOffset
			
			--[Determines the distance from the center]--
			local radius
			if math.random() < 0.15 then
				radius = 0.4 + math.random() * 0.1
			else
				radius = 0.6 + math.random() * 0.3
			end
			
			--[Calculates the actual position of the blobs]--
			local centerX, centerY = 0.5, 0.5
			local x = centerX + math.cos(angle) * radius
			local y = centerY + math.sin(angle) * radius
			
			--[Sets blob size, Likely dont need to set both just did for fun]--
			local goalSize = UDim2.fromScale(
				self.BlobSize.X.Scale * (0.9 + math.random() * 0.3),
				self.BlobSize.Y.Scale * (0.9 + math.random() * 0.3)
			)
			
			--[Tween Setups]--
			local goalColor = self.BlobColors[math.random(1, #self.BlobColors)]
			local duration = self.MoveDelay * (0.75 + math.random() * 0.5)

			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

			local tween = TweenService:Create(blob, tweenInfo, {
				Position = UDim2.fromScale(x, y),
				Size = goalSize,
				ImageColor3 = goalColor,
				Rotation = randomRotation
			})
			
			--[Play and register tween]--
			tween:Play()
			self.BlobTweens[blob] = tween
			
			--[Loop cleanup]--
			tween.Completed:Wait()
			self.BlobTweens[blob] = nil
		end
	end)
end

--===INITIALIZER===--
function LavaLampBG:Initialize()
	self.Frame.BackgroundColor3 = self.BackgroundColor
	self.Frame.BackgroundTransparency = self.BackgroundTransparency
	
	--[Setup Blob folder]--
	local blobFolder = Instance.new("Folder")
	blobFolder.Name = "BlobHolder"
	blobFolder.Parent = self.Frame
	
	for i = 1, self.BlobCount do
		local blob = Instance.new("ImageLabel")
		blob.Name = "Blob_" .. i
		blob.BackgroundTransparency = 1
		blob.Image = self.ImageId
		blob.ImageColor3 = self.BlobColors[math.random(1, #self.BlobColors)]
		blob.ImageTransparency = self.BlobTransparency
		blob.Size = self.BlobSize
		blob.Position = UDim2.new(math.random(), 0, math.random(), 0)
		blob.AnchorPoint = Vector2.new(0.5, 0.5)
		blob.ZIndex = 0
		blob.Parent = blobFolder
		
		if self.RandomRotation then
			local randomRotation = math.random(-180,180)
			blob.Rotation = randomRotation
		end
		
		--[Used to keep blobs circular]--
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = blob
		
		--[Register blob]--
		table.insert(self.Blobs, blob)
	end
end

--===START ANIMATION===--
function LavaLampBG:Start()
	if self.Running then return end
	self.Running = true
	
	--[Starts the animation loop for all blobs]--
	for i, blob in ipairs(self.Blobs) do
		self:AnimateBlob(blob, i, #self.Blobs)
	end
end

--===PAUSE ANIMATION===--
function LavaLampBG:Pause()
	if not self.Running then return end
	self.Running = false

	for _, tween in pairs(self.BlobTweens) do
		if tween then
			tween:Cancel()
		end
	end
end

--===RESUME ANIMATION===--
function LavaLampBG:Resume()
	if self.Running then return end
	self:Start()
end

--===STOP ANIMATION===--
function LavaLampBG:Stop(destroyBlobs) --If true will delete all blobs
	self:Pause()

	if destroyBlobs then
		for _, blob in ipairs(self.Blobs) do
			if blob and blob.Parent then
				blob:Destroy()
			end
		end
		self.Frame.BlobHolder:Destroy()
		self.Blobs = {}
	end
end

--===COLOR STYLE PRESETS===--
LavaLampBG.StylePresets = {
	Vaporwave = {
		BackgroundColor = Color3.fromRGB(30, 30, 50),
		BlobColors = {
			Color3.fromRGB(255, 100, 150),
			Color3.fromRGB(100, 200, 255),
			Color3.fromRGB(200, 100, 255),
			Color3.fromRGB(255, 255, 150),
		},
		BackgroundTransparency = 0,
	},
	Sunset = {
		BackgroundColor = Color3.fromRGB(25, 10, 35),
		BlobColors = {
			Color3.fromRGB(255, 94, 77),
			Color3.fromRGB(255, 195, 113),
			Color3.fromRGB(255, 115, 115),
		},
		BackgroundTransparency = 0.1,
	},
	Ice = {
		BackgroundColor = Color3.fromRGB(200, 230, 255),
		BlobColors = {
			Color3.fromRGB(180, 220, 255),
			Color3.fromRGB(150, 200, 240),
			Color3.fromRGB(255, 255, 255),
		},
		BackgroundTransparency = 0,
	},
	Forest = {
		BackgroundColor = Color3.fromRGB(25, 40, 25),
		BlobColors = {
			Color3.fromRGB(50, 130, 100),
			Color3.fromRGB(30, 80, 60),
			Color3.fromRGB(20, 100, 40),
		},
		BackgroundTransparency = 0.1,
	},
	Lava = {
		BackgroundColor = Color3.fromRGB(20, 10, 0),
		BlobColors = {
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 30, 0),
			Color3.fromRGB(255, 180, 0),
		},
		BackgroundTransparency = 0,
	},
	Aurora = {
		BackgroundColor = Color3.fromRGB(10, 10, 30),
		BlobColors = {
			Color3.fromRGB(0, 255, 200),
			Color3.fromRGB(80, 120, 255),
			Color3.fromRGB(120, 255, 180),
		},
		BackgroundTransparency = 0,
	},
	Midnight = {
		BackgroundColor = Color3.fromRGB(5, 5, 15),
		BlobColors = {
			Color3.fromRGB(30, 30, 80),
			Color3.fromRGB(60, 60, 140),
			Color3.fromRGB(90, 90, 180),
		},
		BackgroundTransparency = 0.2,
	},
	Sakura = {
		BackgroundColor = Color3.fromRGB(255, 245, 250),
		BlobColors = {
			Color3.fromRGB(255, 160, 190),
			Color3.fromRGB(255, 210, 230),
			Color3.fromRGB(255, 180, 200),
		},
		BackgroundTransparency = 0.1,
	},
	Seafoam = {
		BackgroundColor = Color3.fromRGB(220, 255, 250),
		BlobColors = {
			Color3.fromRGB(150, 255, 210),
			Color3.fromRGB(180, 255, 240),
			Color3.fromRGB(100, 255, 200),
		},
		BackgroundTransparency = 0.05,
	},
	Candy = {
		BackgroundColor = Color3.fromRGB(255, 245, 255),
		BlobColors = {
			Color3.fromRGB(255, 120, 180),
			Color3.fromRGB(255, 190, 240),
			Color3.fromRGB(255, 130, 200),
		},
		BackgroundTransparency = 0.05,
	},
	Fireflies = {
		BackgroundColor = Color3.fromRGB(10, 15, 5),
		BlobColors = {
			Color3.fromRGB(255, 255, 180),
			Color3.fromRGB(255, 255, 120),
			Color3.fromRGB(255, 255, 80),
		},
		BackgroundTransparency = 0.15,
	},
	Storm = {
		BackgroundColor = Color3.fromRGB(30, 30, 40),
		BlobColors = {
			Color3.fromRGB(60, 60, 80),
			Color3.fromRGB(90, 90, 130),
			Color3.fromRGB(120, 120, 150),
		},
		BackgroundTransparency = 0.1,
	},
	Neon = {
		BackgroundColor = Color3.fromRGB(5, 5, 10),
		BlobColors = {
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(255, 255, 0),
		},
		BackgroundTransparency = 0,
	},
	Blueberry = {
		BackgroundColor = Color3.fromRGB(200, 220, 255),
		BlobColors = {
			Color3.fromRGB(120, 150, 255),
			Color3.fromRGB(100, 120, 240),
			Color3.fromRGB(80, 100, 220),
		},
		BackgroundTransparency = 0,
	},
	Peach = {
		BackgroundColor = Color3.fromRGB(255, 235, 220),
		BlobColors = {
			Color3.fromRGB(255, 190, 130),
			Color3.fromRGB(255, 170, 120),
			Color3.fromRGB(255, 210, 150),
		},
		BackgroundTransparency = 0.05,
	},
	Glacier = {
		BackgroundColor = Color3.fromRGB(230, 250, 255),
		BlobColors = {
			Color3.fromRGB(180, 220, 255),
			Color3.fromRGB(200, 230, 255),
			Color3.fromRGB(210, 240, 255),
		},
		BackgroundTransparency = 0.05,
	},
	BloodMoon = {
		BackgroundColor = Color3.fromRGB(20, 5, 5),
		BlobColors = {
			Color3.fromRGB(255, 80, 80),
			Color3.fromRGB(180, 20, 20),
			Color3.fromRGB(255, 100, 100),
		},
		BackgroundTransparency = 0.15,
	},
	Grayscale = {
		BackgroundColor = Color3.fromRGB(30, 30, 30),
		BlobColors = {
			Color3.fromRGB(100, 100, 100),
			Color3.fromRGB(200, 200, 200),
			Color3.fromRGB(150, 150, 150),
		},
		BackgroundTransparency = 0.1,
	},
	Sandstorm = {
		BackgroundColor = Color3.fromRGB(250, 240, 200),
		BlobColors = {
			Color3.fromRGB(240, 210, 160),
			Color3.fromRGB(255, 220, 180),
			Color3.fromRGB(230, 200, 140),
		},
		BackgroundTransparency = 0.1,
	},
	Ink = {
		BackgroundColor = Color3.fromRGB(10, 10, 20),
		BlobColors = {
			Color3.fromRGB(50, 50, 100),
			Color3.fromRGB(30, 30, 80),
			Color3.fromRGB(70, 70, 110),
		},
		BackgroundTransparency = 0.1,
	},

	-- CHAOTIC + VIBRANT STYLES
	ChaosCandy = {
		BackgroundColor = Color3.fromRGB(15, 15, 20),
		BlobColors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(0, 255, 255),
		},
		BackgroundTransparency = 0,
	},
	Rainbow = {
		BackgroundColor = Color3.fromRGB(10, 10, 10),
		BlobColors = {
			Color3.fromHSV(0/6, 1, 1),
			Color3.fromHSV(1/6, 1, 1),
			Color3.fromHSV(2/6, 1, 1),
			Color3.fromHSV(3/6, 1, 1),
			Color3.fromHSV(4/6, 1, 1),
			Color3.fromHSV(5/6, 1, 1),
		},
		BackgroundTransparency = 0,
	},
	Radioactive = {
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		BlobColors = {
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(80, 255, 80),
			Color3.fromRGB(180, 255, 180),
		},
		BackgroundTransparency = 0,
	},
	Hologram = {
		BackgroundColor = Color3.fromRGB(5, 5, 10),
		BlobColors = {
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(255, 255, 255),
		},
		BackgroundTransparency = 0.05,
	},
	Static = {
		BackgroundColor = Color3.fromRGB(10, 10, 10),
		BlobColors = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(0, 0, 0),
			Color3.fromRGB(127, 127, 127),
		},
		BackgroundTransparency = 0.1,
	},
	Firestorm = {
		BackgroundColor = Color3.fromRGB(30, 0, 0),
		BlobColors = {
			Color3.fromRGB(255, 90, 0),
			Color3.fromRGB(255, 150, 0),
			Color3.fromRGB(255, 220, 0),
		},
		BackgroundTransparency = 0.05,
	},
	Slime = {
		BackgroundColor = Color3.fromRGB(10, 20, 10),
		BlobColors = {
			Color3.fromRGB(0, 255, 80),
			Color3.fromRGB(80, 255, 120),
			Color3.fromRGB(20, 255, 60),
		},
		BackgroundTransparency = 0.15,
	},
	Electric = {
		BackgroundColor = Color3.fromRGB(0, 0, 10),
		BlobColors = {
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 120, 255),
			Color3.fromRGB(255, 255, 255),
		},
		BackgroundTransparency = 0,
	},
	Toxic = {
		BackgroundColor = Color3.fromRGB(20, 30, 10),
		BlobColors = {
			Color3.fromRGB(180, 255, 0),
			Color3.fromRGB(100, 200, 0),
			Color3.fromRGB(150, 255, 100),
		},
		BackgroundTransparency = 0.05,
	},
	Confetti = {
		BackgroundColor = Color3.fromRGB(250, 250, 255),
		BlobColors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(0, 255, 255),
		},
		BackgroundTransparency = 0.05,
	},
}

return LavaLampBG

--[[
MIT License

Copyright (c) 2025 Jonbobro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
