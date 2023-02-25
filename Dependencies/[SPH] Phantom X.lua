local status, err = pcall(require, "downloader")

local header_path = filesystem.resources_dir() .. "ProfileHelper\\Phantom X\\Header.bmp"
local footer_path = filesystem.resources_dir() .. "ProfileHelper\\Phantom X\\Footer.bmp"
local subheader_path = filesystem.resources_dir() .. "ProfileHelper\\Phantom X\\Subheader.bmp"

if not io.exists(header_path) then
    if not status then
        util.toast("[SPH] Header not found, you may need to manually download this file.")
        should_exit = true
        return
    end

    util.toast("[SPH] Header not found, attempting download. The script will automatically restart when finished.")
    download_file("Themes/Phantom X/Header.bmp", {header_path})
    util.toast("[SPH] Restarting")
    util.restart_script()
end

if not io.exists(footer_path) then
    if not status then
        util.toast("[SPH] Could not find footer, you may need to manually download this file.")
        should_exit = true
        return
    end

    util.toast("[SPH] Footer not found, attempting download. The script will automatically restart when finished.")
    download_file("Themes/Phantom X/Footer.bmp", {footer_path})
    util.toast("[SPH] Restarting")
    util.restart_script()
end

if not io.exists(subheader_path) then
    if not status then
        util.toast("[SPH] Could not find subheader, you may need to manually download this file.")
        should_exit = true
        return
    end

    util.toast("[SPH] Subheader not found, attempting download. The script will automatically restart when finished.")
    download_file("Themes/Phantom X/Subheader.bmp", {subheader_path})
    util.toast("[SPH] Restarting")
    util.restart_script()
end

if should_exit then
    util.stop_script()
end

local header = directx.create_texture(header_path)
local footer = directx.create_texture(footer_path)
local subheader = directx.create_texture(subheader_path)

while true do
    if menu.is_open() then
        local x, y, w, h = menu.get_main_view_position_and_size()
        -- directx.draw_texture(header, 1, (83.3 / 1080) / 2, 0, 0, x, y - 127 / 1080, 0, 1, 1, 1, 1)
        -- directx.draw_texture(footer, 1, (31 / 1080) / 2, 0, 0, x - 0.01 / 1920, (y + h - (1 / 1080)), 0, 1, 1, 1, 1)
    end
    util.yield()
end

util.keep_running()