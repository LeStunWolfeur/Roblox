-- Formatage des nombres et du temps pour l'affichage

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.short(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local text
	if i == 1 then
		text = tostring(math.floor(n))
	elseif n >= 100 then
		text = ("%d%s"):format(math.floor(n), SUFFIXES[i])
	elseif n >= 10 then
		text = ("%.1f%s"):format(math.floor(n * 10) / 10, SUFFIXES[i])
	else
		text = ("%.2f%s"):format(math.floor(n * 100) / 100, SUFFIXES[i])
	end
	return (negative and "-" or "") .. text
end

function Format.cash(n: number): string
	return "$" .. Format.short(n)
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return ("%dh %02dm"):format(h, m)
	elseif m > 0 then
		return ("%dm %02ds"):format(m, s)
	end
	return ("%ds"):format(s)
end

return Format
