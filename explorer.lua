--[[
Module that helps getting keys for all the assets
in the mod.

Internal use only.
]]

if not isCYF then
    error("This module requires CYF.")
end

local self = {}

function self._directoryFiles(dirname)
    local list = {}
    if not Misc.FileExists(dirname) then return list end
    local t = Misc.ListDir(dirname, true)
    for i=1,#t do
        table.insert(list, "directory::://\\\\"..t[i])
    end
    t = Misc.ListDir(dirname, false)
    for i=1,#t do
        table.insert(list, t[i])
    end
    return list
end
function self._startsWith(entry,s)
    local a,_,_ = string.find(entry, s, 1, false)
    return (a == 1)
end
function self._stripSuffix(s, suf)
    for i=1,#suf do
        if string.sub(s, string.len(s)-string.len(suf[i])+1, string.len(s)) == suf[i] then
            return string.sub(s, 1, string.len(s)-string.len(suf[i]))
        end
    end
    return nil
end
function self._allFilesRecurse(dirname, post, root, _list)
    local list = _list or {}
    local t = self._directoryFiles(dirname)
    root = root or dirname.."/"
    for i=1,#t do
      local entry = t[i]
      if self._startsWith(entry,"directory::://\\\\") then
          if dirname != "Sounds" or entry != "directory::://\\\\Voices" then
              list = self._allFilesRecurse(dirname.."/"..string.sub(entry, string.len("directory::://\\\\")+1,string.len(entry)), post, root, list)
          end
      else
        local strp = self._stripSuffix(entry, post)
        if strp != nil then
            table.insert(list, string.sub(dirname.."/", string.len(root)+1,string.len(dirname.."/"))..strp)
        end
      end
    end
    return list
end

function self.getMusicForLoading()
    return self._allFilesRecurse("Audio", {".ogg", ".wav"}, nil, {"mus_gameover"})
end
function self.getSoundForLoading()
    return self._allFilesRecurse("Sounds", {".ogg", ".wav"})
end
function self.getVoiceForLoading()
    return self._allFilesRecurse("Sounds/Voices", {".ogg", ".wav"})
end
function self.getSpriteForLoading()
    return self._allFilesRecurse("Sprites", {".png"})
end

return self