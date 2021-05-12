-- updated 5/12/21
-- should choke less

-- only tested on Synapse X

local framework, scrollHandler do
	for _, obj in next, getgc(true) do
		if type(obj) == 'table' and rawget(obj, 'GameUI') then
			framework = obj;
			break
		end	
	end

	for _, module in next, getloadedmodules() do
		if module.Name == 'ScrollHandler' then
			scrollHandler = module;
			break;
		end
	end
end

local runService = game:GetService('RunService')
local userInputService = game:GetService('UserInputService')

local fastWait, fastSpawn do
	-- https://eryn.io/gist/3db84579866c099cdd5bb2ff37947cec
	-- bla bla spawn and wait are bad 
	-- can also use bindables for the fastspawn idc

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

local function fireSignal(target, signal, ...)
	syn.set_thread_identity(2) -- getconnections with InputBegan / InputEnded does not work without setting Synapse to the game's ContextLevel
	for _, signal in next, getconnections(signal) do
		if type(signal.Function) == 'function' and islclosure(signal.Function) then
			local scr = rawget(getfenv(signal.Function), 'script')
			if scr == target then
				pcall(signal.Function, ...)
			end
		end
	end
	syn.set_thread_identity(6)
end

local map = { [0] = 'Left', [1] = 'Down', [2] = 'Up', [3] = 'Right', }
local keys = { Up = Enum.KeyCode.W; Down = Enum.KeyCode.S; Left = Enum.KeyCode.A; Right = Enum.KeyCode.D; }
local marked = {}

if shared._id then
	pcall(runService.UnbindFromRenderStep, runService, shared._id)
end

shared._id = game:GetService('HttpService'):GenerateGUID(false)
runService:BindToRenderStep(shared._id, 1, function()
	for _, arrow in next, framework.UI.ActiveSections do
		if (arrow.Side == framework.UI.CurrentSide) and (not marked[arrow]) then 
			local indice = (arrow.Data.Position % 4) -- mod 4 because 5%4 -> 0, 6%4 = 1, etc
			local position = map[indice]

			if (position) then
				local currentTime = framework.SongPlayer.CurrentlyPlaying.TimePosition
				local distance = (1 - math.abs(arrow.Data.Time - currentTime)) * 100

				if distance >= 95 then
					marked[arrow] = true;
					fireSignal(scrollHandler, userInputService.InputBegan, { KeyCode = keys[position], UserInputType = Enum.UserInputType.Keyboard }, false)

					-- wait depending on the arrows length so the animation can play
					if arrow.Data.Length > 0 then
						fastWait(arrow.Data.Length)
					else
						fastWait(0.075) -- 0.1 seems to make it miss more, this should be fine enough?
					end

					fireSignal(scrollHandler, userInputService.InputEnded, { KeyCode = keys[position], UserInputType = Enum.UserInputType.Keyboard }, false)
					marked[arrow] = false;
				end
			end
		end
	end
end)
