local header_path = filesystem.resources_dir() .. 'ThemeRepo\\Themes\\Off-White\\Header.bmp'

if not io.exists(header_path) then
	util.toast('[ThemeRepo] Header not found!')
	util.stop_script()
end

local header = directx.create_texture(header_path)

while true do
	if menu.is_open() then
			local x = menu.get_main_view_position_and_size()
			directx.draw_texture(header, 0.0375, 0.0375, x + 0.37, 0.5, 110 / 1920, 0.2491, 0, 1, 1, 1, 1)
	end
	util.yield()
end
