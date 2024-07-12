-- made by 0megaa. / Omega. in mid~ 2023 (?) i don't really remember. i guess have fun?

--[[
a little tweak made in 2024.
]]

local admin = {
	settings = {
		prefixes = {'+','owo '},
		separators = {'|'},

		--hide_commands = true -- later
	},
	
	commands = {},
}

admin.add_command = function(name, aliases, description, arguments, func)
	assert(typeof(name) == 'string', 'tried to run admin.add_command with an invalid name')
	assert(typeof(func) == 'function', 'tried to run admin.add_command with an invalid function')

	admin.commands[name] = {
		name = name,
		aliases = typeof(aliases) == 'table' and aliases or {aliases},
		description = typeof(description) == 'string' and description or "there isn't a description for this command",
		arguments = typeof(arguments) == 'table' and arguments or (arguments == nil and {} or {arguments}),
		func = func
	}
end

admin.is_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.is_command with an invalid string')

	for _, command in pairs(admin.commands) do
		if command.name:lower() == str:lower() or table.find(command.aliases, str:lower()) then
			return true,command
		end
	end

	return false
end

admin.separate_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.separate_command with an invalid string')
	local parts = {}
	local separators = typeof(admin.settings.separators) == 'table' and table.concat(admin.settings.separators, '') or admin.settings.separators

	for part in str:lower():gmatch('%s*([^'..separators..']*)') do
		local command_part = part:gsub('%s+',' ')
		
		for _,prefix in pairs(admin.settings.prefixes) do
			if command_part:find('^'..prefix) then
				table.insert(parts,command_part:sub(#prefix+1))
				break
			end
		end
	end
	
	return parts
end

admin.run_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.run_command with an invalid string')
	local parts = admin.separate_command(str)
	
	if #parts <= 0 then
		return
	end
	
	for _, part in pairs(parts) do
		local args = part:split(' ')
		local command_exists, command = admin.is_command(args[1])
		
		if not command_exists then
			continue
		end

		if #args < #command.arguments + 1 then
            continue
		end

        local adjusted_args = {args[1]} -- i don't care if this is stupid.

        for i = 2, #command.arguments do
            table.insert(adjusted_args, args[i])
        end

        adjusted_args[#command.arguments + 1] = table.concat(args, ' ', #command.arguments + 1)
        args = adjusted_args
		
		local suc,err = pcall(function()
			command.func(args)
		end)
		
		if err then
			warn('failed to run a command\ncommand name: '..tostring(command.name)..'\nargs: '..table.concat(args, ', ')..'\nerror: ' .. tostring(err))
		end
	end
end

admin.add_command('commands', {'cmds'}, 'lists all the commands that are available', nil, function()
	local x = 0 

	for name, data in pairs(admin.commands) do
		print("command name: "..data.name)
		print("aliases: "..table.concat(data.aliases, ", "))
		print("description: "..data.description)
		print('arguments: '..if data.arguments ~= nil and #data.arguments >= 1 then table.concat(data.arguments,' '):gsub("([^ ]+)", "<%1>") else 'argumentless') -- literally was like "yeah, no i can't be bothered with and/or"
		x += 1
	end

	print("listed all the commands: "..tostring(x))
end)

game:GetService('Players').LocalPlayer.Chatted:Connect(function(message, recipient)
    admin.run_command(message)
end)

return admin
