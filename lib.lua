-- made by 0megaa. / Omega. in late 2023 (?) i don't really remember. i guess have fun?

local admin = {
	settings = {
		prefixes = {'+','owo '},
		separators = {'|'},
	},
	
	commands = {},

	func = {}
}

admin.func.add_command = function(name,aliases,description,func)
	assert(typeof(name) == 'string', 'tried to run admin.func.add_command with an invalid name')
	assert(typeof(func) == 'function', 'tried to run admin.func.add_command with an invalid function')

	admin.commands[name] = {
		name = name,
		aliases = typeof(aliases) == 'table' and aliases or {aliases},
		description = typeof(description) == 'string' and description or "there isn't a description for this command",
		func = func
	}
end

admin.func.is_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.func.is_command with an invalid string')

	for _, command in pairs(admin.commands) do
		if command.name:lower() == str:lower() or table.find(command.aliases, str:lower()) then
			return true,command
		end
	end

	return false
end

admin.func.separate_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.func.separate_command with an invalid string')
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

admin.func.run_command = function(str)
	assert(typeof(str) == 'string', 'tried to run admin.func.run_command with an invalid string')
	local parts = admin.func.separate_command(str)
	
	if #parts <= 0 then
		return
	end
	
	for _,part in pairs(parts) do
		local args = part:split(' ')
		local command_exists,command = admin.func.is_command(args[1])
		
		if command_exists == false and command == nil then
			continue
		end
		
		local suc,err = pcall(function()
			command.func(args)
		end)
		
		if err then
			warn('failed to run a command\ncommand name: ' .. tostring(command.name) .. '\nargs: ' .. table.concat(args, ', ') .. '\nerror: ' .. tostring(err))
		end
	end
end

admin.func.add_command('commands', {'cmds'}, 'lists all the commands that are available', function()
	local x = 0 

	for name, data in pairs(admin.commands) do
		print("command name: " .. data.name)
		print("aliases: " .. table.concat(data.aliases, ", "))
		print("description: " .. data.description)
		x += 1
	end

	print("listed all the commands: "..tostring(x))
end)

return admin 
