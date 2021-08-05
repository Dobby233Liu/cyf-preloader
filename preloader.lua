--[[
Dobby233Liu's easy & simple preloader.

To use, copy these files to Lua/Libraries/Preloader
and copy Lua/Libraries/Preloader/progressBarBack.png
to the Sprites/Preloader folder
Then simply add this to the end of your
encounter script:
require "Libraries/Preloader/preloader"
It is suggested to not play music first and
make the old EncounterStarting function
play some music after (it is tricky to implement)

This code is licensed with the MIT license.
It pretty much means you can freely edit this file,
but you need to credit me
]]

if not isCYF then
    error("This preloader is excepted to be run under CYF.")
end

-- The class itself.
local preloader = {}
--preloader.__index = preloader

-- Displayables.
preloader.text = nil
preloader.black = nil

-- Progress bar stuff.
preloader.progressBarBack = nil
preloader.progressBarFore = nil
preloader.progressBarTotal = 0
preloader.progressBarCurrent = 0

-- Controls fade effects.
preloader.fade = true
-- Controls creation of progress bar.
preloader.displayProgress = true

-- Load progress. (sorta)
preloader.con = 0

-- Asset-related variables so the preloader can load some.
preloader.explorer = require("Libraries/Preloader/explorer")
preloader._musicIndex = 0
preloader._soundIndex = 0
preloader._voiceIndex = 0
preloader._spriteIndex = 0
preloader.musicForLoading = nil
preloader.soundForLoading = nil
preloader.voiceForLoading = nil
preloader.spriteForLoading = nil

-- Magic enums
preloader._MUSIC = "music"
preloader._SOUND = "sound"
preloader._VOICE = "voice"

-- Debug toggle. Outputs log to debugger if enabled.
preloader.debug = true

-- Dummy functions
function preloader.dummy_func() end
-- Function to replace DEBUG in non-debug mode.
function preloader.dummy_log(_)
    if preloader.debug then DEBUG(_) end
end
-- Jump to Action Select.
function preloader.dummy_cb() State("ACTIONSELECT") end

-- Debug-related variables.
preloader.since = nil -- Start time of loading.
preloader.log = preloader.dummy_log -- A function called with log messages. It should output the log message somewhere.

-- Callback stuff (see start(...))
preloader.cb = preloader.dummy_cb

-- Magic booleans that you can't touch.
preloader._initalized = false
preloader._ranForOnce = false
preloader.running = false
preloader.resumeBeforeFade = false -- But you can touch this, and it's name is quite literal.

--[[
Magic numbers.
Update() function runs every frame, so these needs to be low...
except that textFadein is during loading so it can be fast.
]]
preloader._textFadein = 0.25
preloader._genFadeout = 0.0625/4

-- Loads an audio.
function preloader._loadAudio(name, type)
    preloader.log("Loading "..type..": "..name)
    if not NewAudio.Exists("Preloader") then
        NewAudio.CreateChannel("Preloader")
        NewAudio.SetVolume("Preloader", 0)
    end
    if type == preloader._MUSIC then
        NewAudio.PlayMusic("Preloader", name, false, 0)
    elseif type == preloader._SOUND then
        NewAudio.PlaySound("Preloader", name, false, 0)
    elseif type == preloader._VOICE then
        NewAudio.PlayVoice("Preloader", name, false, 0)
    else
        error("_loadAudio: Invaild audio type!")
    end
    NewAudio.Stop("Preloader")
end
function preloader._unloadAudioChannel()
    if NewAudio.Exists("Preloader") then
        NewAudio.Stop("Preloader")
        NewAudio.DestroyChannel("Preloader")
    end
end
function preloader._loadSprite(name)
    preloader.log("Loading sprite: "..name)

    local spr = CreateSprite(name, "Bottom", 1)
    spr.Remove()
end

function preloader.updateProgressBar()
    if not preloader.displayProgress then return end
    
    local ratio = preloader.progressBarCurrent / preloader.progressBarTotal
    local width = 544*ratio
    preloader.progressBarFore.Scale(width*.5, 74*.5)
    preloader.progressBarFore.MoveTo(185+(width/4), 160)
end

-- Resumes the mod by calling callbacks.
function preloader._resume()
    -- Calls callback function.
    preloader.cb()
end

--[[
Update function of the preloader.
Should run early in the Update function.
]]

function preloader.update()
    if not preloader.running and (preloader.black == nil and preloader.text == nil) then -- Am I technically not loading and all displayables are removed?
        -- Quit gracefully.
        preloader._ranForOnce = true
        preloader._initalized = false
        return true
    end
    if preloader.running then -- I should be loading now.
        if preloader.con == 0 then
            State("NONE") -- Pause battle.
            -- Black coverup.
            preloader.black = CreateSprite("px", "BelowBullet")
            preloader.black.Scale(640, 480)
            preloader.black.color = {0,0,0}
            -- Notify the user. (I hate the engine's positioning)
            local twofourzero = 240
            if preloader.displayProgress then twofourzero = 300 end
            preloader.text = CreateText("[noskip][font:uidialog][instant]Please wait while assets are being loaded.", {50,twofourzero}, 640-50, "Top")
            preloader.text.HideBubble()
            preloader.text.progressmode = "none"
            preloader.text.color = {1,1,1}
            if preloader.fade then
                preloader.text.alpha = 0
            end
            if preloader.displayProgress then
                preloader.progressBarBack = CreateSprite("Preloader/progressBarBack", "Top")
                preloader.progressBarBack.Scale(0.5, 0.5)
                preloader.progressBarBack.MoveTo(320, 160)
                preloader.progressBarFore = CreateSprite("px", "Top")
                preloader.progressBarFore.Scale(0, 74*0.5)
                preloader.progressBarFore.MoveTo(185, 160)
            end
            preloader.con = 1 -- Next call to intermediate condition
        elseif preloader.con == 1 then
            if preloader.text.alpha < 1 then
                preloader.text.alpha = preloader.text.alpha + preloader._textFadein
            end
            if not preloader.musicForLoading then
                preloader.musicForLoading = preloader.explorer.getMusicForLoading()
                preloader.progressBarTotal = preloader.progressBarTotal + #preloader.musicForLoading
            end
            if not preloader.soundForLoading then
                preloader.soundForLoading = preloader.explorer.getSoundForLoading()
                preloader.progressBarTotal = preloader.progressBarTotal + #preloader.soundForLoading
            end
            if not preloader.voiceForLoading then
                preloader.voiceForLoading = preloader.explorer.getVoiceForLoading()
                preloader.progressBarTotal = preloader.progressBarTotal + #preloader.voiceForLoading
            end
            if not preloader.spriteForLoading then
                preloader.spriteForLoading = preloader.explorer.getSpriteForLoading()
                preloader.progressBarTotal = preloader.progressBarTotal + #preloader.spriteForLoading
            end
            if preloader._musicIndex < #preloader.musicForLoading then
                preloader._musicIndex = preloader._musicIndex + 1
                preloader._loadAudio(preloader.musicForLoading[preloader._musicIndex], preloader._MUSIC)
            end
            if preloader._soundIndex < #preloader.soundForLoading then
                preloader._soundIndex = preloader._soundIndex + 1
                preloader._loadAudio(preloader.soundForLoading[preloader._soundIndex], preloader._SOUND)
            end
            if preloader._voiceIndex < #preloader.voiceForLoading then
                preloader._voiceIndex = preloader._voiceIndex + 1
                preloader._loadAudio(preloader.voiceForLoading[preloader._voiceIndex], preloader._VOICE)
            end
            if preloader._spriteIndex < #preloader.spriteForLoading then
                preloader._spriteIndex = preloader._spriteIndex + 1
                preloader._loadSprite(preloader.spriteForLoading[preloader._spriteIndex])
            end
            preloader.progressBarCurrent = preloader._musicIndex + preloader._soundIndex + preloader._voiceIndex + preloader._spriteIndex
            preloader.updateProgressBar()
            if preloader.progressBarCurrent == preloader.progressBarTotal then
                preloader.con = 2
            end
        else
            -- We're done, disable loading
            preloader._unloadAudioChannel()
            preloader.running = false
            preloader.log("Load complete!")
            if preloader.resumeBeforeFade then
                preloader.log("Calling callback.")
                preloader._resume()
            end
            return preloader.resumeBeforeFade
        end
    elseif preloader.black != nil and preloader.text != nil then
        -- We're left with the displayables, (fade out and) hide them
        if preloader.displayProgress and preloader.progressBarBack != nil and preloader.progressBarFore != nil then
            preloader.log("Destroying progress bar.")
            preloader.progressBarBack.Remove()
            preloader.progressBarBack = nil
            preloader.progressBarFore.Remove()
            preloader.progressBarFore = nil
            preloader.text.MoveTo(50, 240)
        end
        if not preloader.fade or (preloader.black.alpha == 0 and preloader.text.alpha == 0) then
            preloader.log("Destroying overlay.")
            preloader.black.Remove()
            preloader.black = nil
            preloader.text.Remove()
            preloader.text = nil
            preloader.log("Loading finished!")
            preloader.log("Took "..tostring(Time.time - preloader.since).." seconds.")
            if not preloader.resumeBeforeFade then
                preloader.log("Calling callback.")
                preloader._resume()
            end
            return true
        elseif preloader.fade then
            preloader.black.alpha = preloader.black.alpha - preloader._genFadeout
            preloader.text.alpha = preloader.text.alpha - preloader._genFadeout
        end
    end
    if not preloader.running then
        -- We're already done with loading, left or not left the mod to do it's Update function while we fade out/destroy the displayables after a frame
        return preloader.resumeBeforeFade
    end
    return false -- Reject other Updating
end

--[[
Runs the preloader correctly.
Should be run in EncounterStarting

Parameters (not required but suggested):
    cb - callback function after loading. should do something like fixing the state
]]

function preloader.start(cb)
    if preloader.running then error("Can't start preloader while preloader is running.") end

    -- Do this first
    State("NONE")
    -- Initialize stuff
    preloader.con = 0
    preloader.since = Time.time
    preloader.cb = cb or PreloaderCallback or preloader.dummy_cb
    preloader._musicIndex = 0
    preloader._soundIndex = 0
    preloader._voiceIndex = 0
    preloader._spriteIndex = 0
    preloader.musicForLoading = nil
    preloader.soundForLoading = nil
    preloader.voiceForLoading = nil
    preloader.spriteForLoading = nil
    preloader.progressBarTotal = 0
    preloader.progressBarCurrent = 0
    preloader.running = true
    preloader._initalized = true

    return true
end

-- One-require install stuff.

local _Plcb = PreloaderCallback or EncounterStarting or preloader.dummy_cb
if PreloaderResume then
    preloader._resume = PreloaderResume
end
local _Update = Update
local _TopUpdate = PrePreloaderUpdate or preloader.dummy_func
local _UpdateStillBlocked = PostPreloaderUpdate or preloader.dummy_func

EncounterStarting = function()
    --Audio.Stop()
    if PrePreloaderStart then PrePreloaderStart() end
    preloader.start(_Plcb)
    if PostPreloaderStart then PostPreloaderStart() end
end
Update = function()
    _TopUpdate()
    if not preloader._ranForOnce and (not preloader._initalized or not preloader.update()) then
        if preloader._ranForOnce then Update = _Update end
        _UpdateStillBlocked()
        return
    end
    _Update()
end

-- return preloader
