local function get_total_increment(text)
	local total = 0
    for operator, increment in string.gmatch(text, "([+-])(%d*)") do
		if increment == "" then
			increment = 1
		end
		total = total + tonumber(operator .. increment)
    end
	return total
end

return {
	get_total_increment = get_total_increment
}
