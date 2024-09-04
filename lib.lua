-- made by Omega.(@0megaa.) (discord)
-- 'your boy omegaaa >_< ヾ(≧▽≦*)o' -- somebody
-- let's all love lain.
-- add your own file system, i am lazy. / i couldn't test this due to solara being down and my country being annoying. BUT i will test it and fix any bugs that are relevant tmrw.

local game = game
local table = table
local string = string
local typeof = typeof
local tostring = tostring
local players = game:GetService('Players')

local main = {
	settings = {
		prefix = {'navi, ','owo ','uwu ','+'},
		splitter = '|',
		system_name = [[C:\user\]]..players.LocalPlayer.Name, -- this is for when you call the run_command function from the script
		run_commands_on_higher_ranked = false, -- can you run commands on people with higher ranks than you

		levels = {
			['owner'] = {['level'] = 2, ['players'] = {players.LocalPlayer.UserId}},
			['admin'] = {['level'] = 1, ['players'] = {}}
		}
	},

	player_cases = {},
	commands = {},
	hooks = {},
	logs = {},
}

-- admin

main.add_command = function(name, aliases, arguments, description, level, func)
	assert(typeof(name) == 'string', 'tried to add a command with an invalid name')
	assert(typeof(func) == 'function', 'tried to add a command with an invalid function')

	main.commands[name] = {
		name = name,
		aliases = typeof(aliases) == 'table' and aliases or {aliases},
		arguments = typeof(arguments) == 'table' and arguments or (arguments == nil and {} or {arguments}),
		description = typeof(description) == 'string' and description or "there isn't a description for this command",
		level = typeof(level) == 'number' and level or 0,
		func = func
	}
end

main.is_command = function(str) -- returns the command state, the command
	assert(typeof(str) == 'string', 'tried to find a command while using an invalid string')

	for _, command in pairs(main.commands) do
		if string.lower(command.name) == string.lower(str) or table.find(command.aliases, str) then
			return true, command
		end
	end

	return false
end

main.remove_command = function(command)
	local is_command,command = main.is_command(command)
	assert(is_command, "can't remove an invalid command")
	table.remove(main.commands,command)
end

main.overwrite_command = function(command,func)
	local is_command,command = main.is_command(command)
	assert(is_command, "can't overwrite an invalid command")
	assert(typeof(func) == 'function', "invalid function")
	
	command.func = func
end

main.get_level = function(player) -- returns the level, level name, player
	if not (typeof(player) == 'Instance' and player:IsA('Player')) then
		return math.huge, main.settings.system_name, players.LocalPlayer
	end

	for level_name, level_data in pairs(main.settings.levels) do
		if table.find(level_data.players, player.UserId) then
			return level_data.level, level_name, player
		end
	end

	return 0, 'nonadmin'
end

main.set_level = function(player, level)
	assert(player:IsA('Player'), 'tried to set the level of an invalid player')
	local level_type = typeof(level)

	-- level check
	level = (level_type == 'number' or level_type == 'string') and level or 0
	local player_level,player_level_name = main.get_level(player)
	local levels = main.settings.levels

	-- remove the player from their current admin state
	local found = table.find(levels.player_level_name.players,player.UserId)

	if found then
		table.remove(levels.player_level_name.players,found)
	end

	for level_name, level_data in pairs(levels) do
		if level_name == level or level_data.level == level then
			-- add the player to the wanted admin state
			table.insert(level_data.players,player.UserId)
			break
		end
	end
end

main.format_arguments = function(tbl, starting, ending) -- for example main.for_arguments(tbl,'<','>')
    assert(typeof(tbl) == 'table', 'tried to run format an invalid table of arguments')
    assert(typeof(starting) == 'string', 'invalid starting delimiter')
    assert(typeof(ending) == 'string', 'invalid ending delimiter')

    local formatted = {}

    for _, argument in pairs(tbl) do
        table.insert(formatted, starting..tostring(argument)..ending)
    end

    return table.concat(formatted, ' ')
end

main.run_command = function(str, speaker)
	assert(typeof(str) == 'string', 'tried to run a command string with an invalid string')
	speaker = typeof(speaker) == 'Instance' and speaker:IsA('Player') and speaker or main.settings.system_name
	local level,level_name = main.get_level(speaker)

	local parts = {}

	-- gathers the parts
	for match in string.gmatch(str, '[^' .. main.settings.splitter .. ']+') do
		table.insert(parts, (string.gsub(match, '^%s+', '')))
	end

	for _, part in pairs(parts) do
		local has_prefix = false

		-- prefix check
		for _, prefix in pairs(main.settings.prefix) do
			if string.find(part, '^' .. prefix) then
				part = string.sub(part, #prefix+1) has_prefix = true
				break
			end
		end

		if not has_prefix then
			continue
		end

		-- command check
		local command_parts = part:split(' ')
		local is_command, command = main.is_command(command_parts[1])

		if not is_command then
			print(tostring(part).." isn't a valid command") continue
		end

		-- level check
		if level < command.level then
			continue
		end

		-- argument adjustment/gathering
		local argument_count = typeof(command.arguments) == 'table' and #command.arguments or 0
		table.remove(command_parts, 1) -- remove the command name from the command parts

		local arguments = {}
		local remaining_part = table.concat(command_parts, " ")

		for i = 1, argument_count do
			if i < argument_count then
				remaining_part, arguments[i] = remaining_part:gsub("^(%S+)%s*", "", 1)
			else
				arguments[i] = remaining_part
			end
		end

		-- calls the commands function
		local success, failure = pcall(function()
			command.func(speaker, unpack(arguments))
		end)

		if success then
			main.logs[#main.logs+1] = { -- kinda dumb but i don't care, probally will update later
				command_name = command.name,
				runner_name = (typeof(speaker) == 'Instance' and speaker:IsA('Player')) and speaker.Name or speaker,
				runner_id = (typeof(speaker) == 'Instance' and speaker:IsA('Player')) and speaker.UserId or 0,
				runner_level = level..' - '..level_name,
				ran_string = command.name..' '..table.concat(arguments,' '),
				required_args = (command.arguments and #command.arguments ~= 0) and main.format_arguments(command.arguments,'<','>') or 'none',
				used_args = (arguments and #arguments ~= 0) and main.format_arguments(arguments,'<','>') or 'none',
				ran_at = os.date('%m/%d/%Y %H:%M:%S')
			}
		else
			warn(failure) -- inside joke
		end
	end
end

-- get player

main.add_player_case = function(name, func)
	assert(typeof(name) == 'string',"can't create a player case without a valid name")
	assert(typeof(func) == 'function',"can't create a player case without a valid function")

	main.player_cases[name] = func
end

main.remove_player_case = function(name)
	assert(typeof(name) == 'string',"can't remove a player case without a valid name")
	local found = table.find(main.player_cases,name)

	if found then
		table.remove(main.player_cases,found)
	else
		error(name.." isn't a player case")
	end
end

main.get_player = function(str,speaker)  -- similar logic to the run command function
	assert(typeof(str) == 'string',"can't get players from an invalid string")
	speaker = typeof(speaker) == 'Instance' and speaker:IsA('Player') and speaker or main.settings.system_name
	local level,level_name,given_player = main.get_level(speaker)

	local returns = {}
	local parts = {}

	-- gathers the parts
	for match in string.gmatch(str, '[^,]+') do -- copy n paste :wink:
		table.insert(parts, (string.gsub(match, '^%s+', '')))
	end

	for _,part in pairs(parts) do -- my code is going to be so terrible i can just tell :sob:
		local negate = string.sub(part, 1, 1) == '-'
		part = negate and string.sub(part, 2) or part

		-- case checking
		local found_players = nil

		for playercase,func in pairs(main.player_cases) do -- changed to this method
			if string.match(part,playercase) or playercase == part then
				found_players = func()
				break
			end
		end

		if found_players == nil then
			found_players = {}

			for _,player in pairs(players:GetPlayers()) do
				if string.lower(string.sub(player.Name, 1, #part)) == string.lower(part) then
					table.insert(found_players,player)
				end
			end
		end

		for _,player in pairs(found_players) do
			-- level check
			if not main.settings.run_commands_on_higher_ranked and level < main.get_level(player) then
				continue
			end
			
			-- table operations
			local index = table.find(returns,player)
			if negate and index then
				table.remove(returns,index)
			elseif not (negate and index) then
				table.insert(returns,player)
			end
		end
	end

	return returns
end

-- hooks

main.create_hooks = function()
	for _,player in pairs(players:GetPlayers()) do
		main.hooks[player.UserId] = player.Chatted:Connect(function(message)
			if string.sub(message, 1, 2) == '/e' or string.sub(message, 1, 2) == '/w' then
				message = string.sub(message, 3)
			end
				
			main.run_command(message,player)
		end)
	end

	main.hooks['playeradded'] = players.PlayerAdded:Connect(function(player)
		main.hooks[player.UserId] = player.Chatted:Connect(function(message)
			if string.sub(message, 1, 2) == '/e' or string.sub(message, 1, 2) == '/w' then
				message = string.sub(message, 3)
			end
					
			main.run_command(message,player)
		end)
	end)

	main.hooks['playerremoving'] = players.PlayerRemoving:Connect(function(player)
		local found = table.find(main.hooks,player.UserId)

		if found then
			table.remove(main.hooks,found)
		end
	end)
end

main.disconnect_hooks = function()
	for i,v in pairs(main.hooks) do
		v:Disconnect()
	end
end

return main
