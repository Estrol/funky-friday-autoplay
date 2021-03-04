local framework;
local funcs = {}

local islclosure = islclosure or is_l_closure
local getinfo = getinfo or debug.getinfo

for i, v in next, getgc(true) do
    if type(v) == 'table' and rawget(v, 'GameUI') then
        framework = v;
    end

    if type(v) == 'function' and islclosure(v) then
        local name = getinfo(v).name;
        if (name == 'KeyUp' or name == 'KeyDown') and getinfo(v).source:match('%.Arrows$') then
            funcs[name] = v;
        end
    end
end

if type(framework) ~= 'table' or (not rawget(framework, 'UI')) then
    return game.Players.LocalPlayer:Kick('Failed to locate framework.')
elseif (not (funcs.KeyDown and funcs.KeyUp)) then
    return game.Players.LocalPlayer:Kick('Failed to locate key functions.')
end


local marked = {}
local map = { [0] = 'Left', [1] = 'Down', [2] = 'Up', [3] = 'Right', }
local keys = { Up = Enum.KeyCode.W; Down = Enum.KeyCode.S; Left = Enum.KeyCode.A; Right = Enum.KeyCode.D; }

-- https://eryn.io/gist/3db84579866c099cdd5bb2ff37947cec
-- bla bla spawn and wait are bad 
-- can also use bindables for the fastspawn idc

local runService = game:GetService('RunService')

local fastWait, fastSpawn do
    function fastWait(t)
        local d = 0;
        while d < t do
            d += runService.RenderStepped:wait()
        end
    end

    function fastSpawn(f)
        coroutine.wrap(f)()
    end
end

while runService.RenderStepped:wait() do
    for _, arrow in next, framework.UI.ActiveSections do
        if arrow.Side ~= framework.UI.CurrentSide then continue end -- ignore the opponent's arrows
        if marked[arrow] then continue end -- ignore marked arrows so we dont spam them
        
        local index = arrow.Data.Position % 4
        local position = map[index] -- % 4 because the right side numbers are 4, 5, 6, 7 and are not in the key map
        if (not position) then continue end -- oh well the position got eaten

        local distance = (1 - math.abs(arrow.Data.Time - framework.SongPlayer.CurrentlyPlaying.TimePosition)) * 100 -- get the "distance" or whatever
        if distance >= 95 then -- if above a certain threshold, we do this
            marked[arrow] = true; -- mark the arrow
            fastSpawn(function()
                funcs.KeyDown(position)
                if arrow.Data.Length > 0 then
                    fastWait(arrow.Data.Length) -- usually these are held long enough
                else
                    fastWait(0.1) -- wait a tiny bit of time so the fucking animations play and you dont get called out as bad :)
                end
                funcs.KeyUp(position)
                marked[arrow] = nil
            end)
        end
    end
end
