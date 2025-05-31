# LavaLampBG
This module is used to make nice flowing background for frames, say you have a fancy weapon
	or a nice shop you want to have some movement to the backgrounds but dont want standard
	gradients. This module will put a few blobs to the background and move them around semi
	randomly to add some subtle, or very chaotic, life to your backgrounds.

The module will only work on frames and will set the frames to clip descendants just to try
	and minimize spoiling the effect

 ![RainbowBG](https://github.com/user-attachments/assets/e6271428-de98-45eb-9f14-1fcf308790b8)
![RadioactiveBG](https://github.com/user-attachments/assets/94e93ab7-dd1d-43bc-af81-fef29b5e5572)
![AuroraBG](https://github.com/user-attachments/assets/e16d309f-acf5-4467-a634-8d42822c4289)
![StarsBG](https://github.com/user-attachments/assets/de821889-5d40-46ef-a851-d06fc64973c5)
![SakuraBG](https://github.com/user-attachments/assets/c4c73f56-52e2-4eb7-b85f-64bab069b2d8)

A quick and simple setup of the module can just be 
===========================================================================================
local LavaLampBG = require(Path to module)

local Background = LavaLampBG.new({Frame = Path to frame you want to animate})

Background:Start()

Background Constructor
=====================

LavaLampBG.New({Parameters}) 

Creates a new background and returns the created one.

Available parameters
=================

StylePreset : Enum? - If you call Module.StylePresets.[should autofill to the 30 included]

(*) can be used to overright StylePresets

*BackgroundColor : Color3 - Overrides the background color of the frame

*BlobColors : {Color3} - An array of colors that will be used to determine blob colors

*BGTransperency : number - The transparency of the background

Frame : instance - The frame the background will be applied to. MUST be a frame

BlobCount : number - The amount of "Blobs" that will be used for the background

Blobsize : Udim2 - The size of the "Blobs". The aspect ratio is locked to 1:1

BlobTransparency : number - The transparency of the "Blobs"

MoveDelay : number - How long it takes the blobs to move * some randomness.

ImageId : ImageId - Overrides the blobs to whatever you set as the image id
[The star preview one uses a custom star image]

RandomRotation : boolean - Sets the blobs to rotate randomly during moves or not
	(only really needed with certain images so if using blobs doesn't have to be set.)


Background Methods
==================
LavaLampBG:Start()
Starts the animation.

LavaLampBG:Pause()
Pauses the current animation.

LavaLampBG:Resume()
Restarts the animation.

LavaLampBG:Stop(DestroyBlobs : boolean)
Will end animation and if DestroyBlobs == true will delete the blobs and blob folder.


Things to note
==============================

-The default style is Rainbow. you can change the default in the .new function
-I would suggest keeping the BlobSize to a scale between 1 and 2 and have roughly 15-30 blobs
if you want the background to be more "full" 
-If you want to have rounded corners for a ui the only way i have found is to use a CanvasGroup
due to clipdescendants being weird in general
-I have tested this place with several hundred blobs on my several year old laptop and got no
performance drops but i can't gurantee that for mobile devices etc so try to keep the amount of 
blobs to a minimum.

This was just a 3 hours chaos project so I likely wont be updating this much at all.

Anyways I hope you enjoy this module. First one I will have released. Likely has a lot to be 
improved and fixed. I am self taught so how this is laid out is likely awful and needs a rework
but I saw something I thought was cool for the new Android OneUI update and wanted to recreate
the moving backgrounds on some app icons. Its not perfect but its the closest I could come to 
with what I know roblox has. 
