std = "lua51+luajit"
globals = {
	"core",
	"player_api",
	"x_player_api",
	"x_player_bridge",
	"armor",
	"wieldview",
}
read_globals = {
	"ItemStack",
	"table.copy",
	"vector",
}
files["test.lua"] = {
	std = "+busted",
	read_globals = {"assert"},
}
files["mods/x_player_bridge/test.lua"] = {
	std = "+busted",
	read_globals = {"assert"},
}
