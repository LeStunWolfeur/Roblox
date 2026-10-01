-- Références partagées entre les services (remplies par Main au démarrage).
-- Évite les require circulaires : un service appelle Hub.Gallery.X() au moment voulu.

local Hub = {
	Map = nil :: any,
	Gallery = nil :: any,
	Grading = nil :: any,
	Training = nil :: any,
	Zones = nil :: any,
	Events = nil :: any,
	Combat = nil :: any,
	Players = nil :: any,
	Loot = nil :: any,
}

return Hub
