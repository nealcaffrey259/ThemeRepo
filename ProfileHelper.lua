-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil
    util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code)
            local function parse_auto_update_result(result, headers, status_code)
                local error_prefix = "Error downloading auto-updater: "
                if status_code ~= 200 then
                    util.toast(error_prefix .. status_code, TOAST_ALL)
                    return false
                end
                if not result or result == "" then
                    util.toast(error_prefix .. "Found empty file.", TOAST_ALL)
                    return false
                end
                filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                if file == nil then
                    util.toast(error_prefix .. "Could not open file for writing.", TOAST_ALL)
                    return false
                end
                file:write(result)
                file:close()
                util.toast("Successfully installed auto-updater lib", TOAST_ALL)
                return true
            end
            auto_update_complete = parse_auto_update_result(result, headers, status_code)
        end, function()
            util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL)
        end)
    async_http.dispatch()
    local i = 1
    while (auto_update_complete == nil and i < 40) do
        util.yield(250)
        i = i + 1
    end
    if auto_update_complete == nil then
        error("Error downloading auto-updater lib. HTTP Request timeout")
    end
    auto_updater = require("auto-updater")
end
if auto_updater == true then
    error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again")
end

local auto_update_config = {
    source_url = "https://raw.githubusercontent.com/stagnate6628/stand-profile-helper/main/ProfileHelper.lua",
    script_relpath = SCRIPT_RELPATH,
    verify_file_begins_with = "--",
    check_interval = 86400,
    silent_updates = true,
    dependencies = {{
        name = "downloader",
        source_url = "https://raw.githubusercontent.com/stagnate6628/stand-profile-helper/main/lib/downloader.lua",
        script_relpath = "lib/downloader.lua",
        verify_file_begins_with = "function",
        is_required = true
    }}
}
auto_updater.run_auto_update(auto_update_config)
for _, dependency in auto_update_config.dependencies do
    if dependency.is_required then
        if dependency.loaded_lib == nil then
            util.toast("Error loading lib " .. dependency.name, TOAST_ALL)
        else
            local var_name = dependency.name
            _G[var_name] = dependency.loaded_lib
        end
    end
end

local texture_names<const> = {"Disabled", "Edit", "Enabled", "Friends", "Header Loading", "Link", "List", "Search",
                              "Toggle Off Auto", "Toggle Off", "Toggle On Auto", "Toggle On", "User", "Users"}
local tag_names<const> = {"00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14",
                          "15", "16", "17", "18", "19", "0A", "0B", "0C", "0D", "0E", "0F", "1A", "1B", "1C", "1D",
                          "1E", "1F"}
local tab_names<const> = {"Self", "Vehicle", "Online", "Players", "World", "Game", "Stand"}

local stand_dir = filesystem.stand_dir()
local theme_dir = stand_dir .. "Theme\\"
local header_dir = stand_dir .. "Headers\\Custom Header"
local resource_dir = filesystem.resources_dir() .. "ProfileHelper\\"

local home = menu.my_root()
local themes = home:list("Themes", {}, "")
local settings = home:list("Settings", {}, "")

local prevent_redownloads = true
local combine_profiles = false
local show_logs = true
settings:toggle("Re-Use Local Assets", {},
    "Re-uses downloaded assets and prevents any extra downloads if they exist. Note that if these files are not what they are supposed to be, then obviously the theme will look different or you may encounter issues. As long as you do not tamper with the files, this should be fine to leave enabled.",
    function(state)
        prevent_redownloads = state
    end, true)
settings:toggle("Combine Profiles", {},
    "Experimental: Attempts to combine relevant settings from the downloaded profile with the active profile (%appdata%\\Stand\\Meta State.txt). There will still be a clean copy of the downloaded theme inside the Profiles folder. Should not cause any issues but still recommended to leave this off in the event you lose any data.",
    function(state)
        combine_profiles = state
    end, false)
settings:toggle("Download Status", {}, "Display the download status with toasts", function(state)
    show_logs = state
end, true)
settings:action("Update Themes", {},
    "Updates the list of available themes to download. If there were no changes, then you may need to wait for the API to update or there were truly no changes.",
    function()
        download_themes()
    end)
settings:hyperlink("Open Themes Folder", "file:///" .. theme_dir)
settings:hyperlink("Open Profiles Folder", "file:///" .. stand_dir .. "Profiles")
settings:hyperlink("Open Custom Header Folder", "file:///" .. header_dir)
settings:hyperlink("Open Lua Scripts Folder", "file:///" .. filesystem.scripts_dir())
settings:hyperlink("Open Script Resources Folder", "file:///" .. resource_dir)
settings:action("Empty Script Log", {}, "", function()
    local log_path = resource_dir .. "\\log.txt"
    local log_file = io.open(log_path, "wb")
    log_file:write("")
    log_file:close()
end)
settings:action("Update Script", {}, "", function()
    auto_update_config.check_interval = 0
    log("Checking for script updates")
    auto_updater.run_auto_update(auto_update_config)
end)
settings:action("Restart Script", {}, "", function()
    util.restart_script()
end)

function download_themes()
    local children = menu.get_children(themes)
    if #children > 0 then
        for _, child in children do
            child:delete()
        end
    end

    local downloading = true
    async_http.init("raw.githubusercontent.com", "/stagnate6628/stand-profile-helper/main/credits.txt",
        function(res, _, status_code)
            if body == "API rate limit exceeded" or status_code == 429 then
                util.toast("You are currently ratelimited by Github. You can let it expire or a use a vpn.")
                util.stop_script()
            end

            local profile = res:split("\n")
            for _, v in pairs(profile) do
                if v == "" then
                    goto continue
                end

                local parts = v:split(";")
                local theme_name = parts[1]
                local theme_author = parts[2] or "unknown"
                local deps = {}

                if type(parts[3]) == "string" and parts[3]:endswith(".lua") then
                    table.insert(deps, parts[3])
                end

                themes:action(theme_name, {}, "Made by " .. theme_author, function()
                    download_theme(theme_name, deps)
                end)
                ::continue::
            end
            downloading = false
        end, function()
            log("Failed to download themes list.")
            downloading = false
        end)
    async_http.dispatch()

    while downloading do
        util.yield()
    end
end

if SCRIPT_MANUAL_START and not SCRIPT_SILENT_START then
    util.toast("It is recommended to backup any profiles, textures, and headers before selecting a theme.")
end

download_themes()

function download_theme(theme_name, dependencies)
    io.makedirs(resource_dir .. theme_name .. "\\Custom Header")
    io.makedirs(resource_dir .. theme_name .. "\\Theme\\Custom")
    io.makedirs(resource_dir .. theme_name .. "\\Theme\\Tabs")

    local profile_path = get_profile_path_by_name(theme_name)
    local font_path = theme_dir .. "Font.spritefont"

    local resource_profile_path = get_resource_dir_by_name(theme_name, theme_name .. ".txt")
    if io.exists(resource_profile_path) and prevent_redownloads then
        copy_file(resource_profile_path, profile_path)
        log("Re-using cached profile")
    else
        download_file("Themes/" .. theme_name .. "/" .. theme_name .. ".txt", {profile_path, resource_profile_path})
        log("Downloaded profile")
    end

    -- todo: see if moving font.spritefont to theme/ is better
    local font_path = get_local_theme_dir_by_name("Font.spritefont")
    local font_url_path = get_remote_theme_dir_by_name(theme_name, "Font.spritefont")
    if not does_remote_file_exist(font_url_path) then
        font_url_path = get_remote_theme_dir_by_name("Stand", "Font.spritefont")
    end

    local resource_font_path = get_resource_dir_by_name(theme_name, "Font.spritefont")
    if io.exists(resource_font_path) and prevent_redownloads then
        copy_file(resource_font_path, font_path)
        log("Re-using cached font file")
    else
        download_file(font_url_path, {font_path, get_resource_dir_by_name(theme_name, "Font.spritefont")})
        log("Downloaded font")
    end

    local footer_url_path = get_remote_theme_dir_by_name(theme_name, "Footer.bmp")
    local resource_footer_path = get_resource_dir_by_name(theme_name, "Footer.bmp")
    if io.exists(resource_footer_path) and prevent_redownloads then
        log("Re-using cached footer file")
    else
        if does_remote_file_exist(footer_url_path) then
            download_file(footer_url_path, {resource_footer_path})
            log("Downloaded footer")
        else
            log("Skipping footer")
        end
    end

    local subheader_exists = false
    local subheader_url_path = get_remote_theme_dir_by_name(theme_name, "Subheader.bmp")
    local resource_subheader_path = get_resource_dir_by_name(theme_name, "Subheader.bmp")

    if io.exists(resource_subheader_path) and prevent_downloads then
        log("Re-using cached subheader file")
    else
        if does_remote_file_exist(subheader_url_path) then
            download_file(subheader_url_path, {resource_subheader_path})
            log("Downloaded subheader")
        else
            log("Skipping subheader")
        end
    end

    local header_url_path = get_remote_theme_dir_by_name(theme_name, "Header.bmp")
    local animated_header_url_path = get_remote_theme_dir_by_name(theme_name, "Header1.bmp")
    if does_remote_file_exist(header_url_path) then
        -- header.bmp exists in root of a theme dir
        log("Downloaded header (1)")
        hide_header()

        -- todo: move only .bmp files to resource_dir ?
        if not subheader_exists then
            empty_headers_dir()
            download_file(header_url_path, {get_local_theme_dir_by_name("Header.bmp")})
            custom_header()
        else
            download_file(header_url_path, {get_resource_dir_by_name(theme_name, "Header.bmp")})
        end
    elseif does_remote_file_exist(animated_header_url_path) then
        -- header1.bmp up to headerX.bmp exists in root of theme dir
        log("Downloaded header (2)")
        local i = 1
        download_file(animated_header_url_path, {get_resource_dir_by_name(theme_name, "Header1.bmp")})
        log("Downloaded header " .. i)
        i = i + 1

        hide_header()
        animated_header_url_path = get_remote_theme_dir_by_name(theme_name, "Header" .. i .. ".bmp")

        while does_remote_file_exist(animated_header_url_path) do
            log("Downloaded header " .. i)
            download_file(animated_header_url_path, {get_resource_dir_by_name(theme_name, "Header" .. i .. ".bmp")})
            i = i + 1

            animated_header_url_path = get_remote_theme_dir_by_name(theme_name, "Header" .. i .. ".bmp")
            util.yield(100)
        end
    else
        empty_headers_dir()
        -- this method header.png being in root should probably be deprecated in favor of Custom Headers\header.png
        local header_png_url_path = get_remote_theme_dir_by_name(theme_name, "Header.png")
        if does_remote_file_exist(header_png_url_path) then
            log("Using custom header (3)")
            download_file(header_png_url_path, {header_dir .. "\\" .. theme_name .. ".png"})
            hide_header()
            custom_header()
        else
            hide_header()
            -- everything in custom header dir
            if download_directory(get_remote_theme_dir_by_name(theme_name, "Custom Header"), header_dir) then
                custom_header()
                log("Using custom header (4)")
            else
                log("Using no header (5)")
            end
        end
    end

    for _, texture_name in texture_names do
        local texture_url_path = get_remote_theme_dir_by_name(theme_name, "Theme/" .. texture_name .. ".png")
        local def
        if not does_remote_file_exist(texture_url_path) then
            def = true
            texture_url_path = get_remote_theme_dir_by_name("Stand", "Theme/" .. texture_name .. ".png")
        end

        local texture_path = theme_dir .. texture_name .. ".png"
        local resource_texture_path = get_resource_dir_by_name(theme_name, "Theme\\" .. texture_name .. ".png")
        if io.exists(resource_texture_path) and prevent_redownloads then
            copy_file(resource_texture_path, texture_path)
            log("Copied texture " .. texture_name)
        else
            download_file(texture_url_path, {texture_path, resource_texture_path})
            if def then
                log("Downloaded default texture " .. texture_name)
            else
                log("Downloaded custom texture " .. texture_name)
            end
        end
    end

    for _, tag_name in tag_names do
        local tag_url_path = get_remote_theme_dir_by_name(theme_name, "Theme/Custom/" .. tag_name .. ".png")
        local def
        if not does_remote_file_exist(tag_url_path) then
            def = true
            tag_url_path = get_remote_theme_dir_by_name("Stand", "Theme/Custom/" .. tag_name .. ".png")
        end

        local tag_path = get_local_theme_dir_by_name("Custom\\" .. tag_name .. ".png")
        local resource_tag_path = get_resource_dir_by_name(theme_name, "Theme\\Custom\\" .. tag_name .. ".png")
        if io.exists(resource_tag_path) and prevent_redownloads then
            copy_file(resource_tag_path, tag_path)
            log("Copied tag " .. tag_name)
        else
            download_file(tag_url_path, {tag_path, resource_tag_path})
            if def then
                log("Downloaded default tag " .. tag_name)
            else
                log("Downloaded custom tag " .. tag_name)
            end
        end
    end

    for _, tab_name in tab_names do
        local tab_url_path = get_remote_theme_dir_by_name(theme_name, "Theme/Tabs/" .. tab_name .. ".png")
        local def
        if not does_remote_file_exist(tab_url_path) then
            tab_url_path = get_remote_theme_dir_by_name("Stand", "Theme/Tabs/" .. tab_name .. ".png")
            def = true
        end

        local resource_tab_path = get_resource_dir_by_name(theme_name, "Theme\\Tabs\\" .. tab_name .. ".png")
        local tab_path = get_local_theme_dir_by_name("Tabs\\" .. tab_name .. ".png")
        if io.exists(resource_tab_path) and prevent_redownloads then
            copy_file(resource_tab_path, tab_path)
            log("Copied tab " .. tab_name)
        else
            download_file(tab_url_path, {tab_path, resource_tab_path})
            if def then
                log("Downloaded default tab " .. tab_name)
            else
                log("Downloaded custom tab " .. tab_name)
            end
        end
    end

    util.yield(1000)

    trigger_command("reloadfont")
    trigger_command("reloadtextures")

    for _, script in dependencies do
        local dep_url_path = "Dependencies/" .. script
        if does_remote_file_exist(dep_url_path) then
            download_file(dep_url_path, {filesystem.scripts_dir() .. script})
            log("Downloaded dependency " .. script)
        end
    end

    load_profile(theme_name)
end

function log(msg)
    if not show_logs then
        return
    end

    util.toast(msg)

    local log_path = resource_dir .. "\\log.txt"
    local log_file = io.open(log_path, "a+")
    log_file:write("[" .. os.date("%c") .. "] " .. msg .. "\n")
    log_file:close()
end

function hide_header()
    trigger_command_by_ref("Stand>Settings>Appearance>Header>Header>Be Gone")
end

function custom_header()
    trigger_command_by_ref("Stand>Settings>Appearance>Header>Header>Custom")
end

function load_profile(profile_name)
    profile_name = clean_profile_name(profile_name)

    util.yield(500)
    trigger_command_by_ref("Stand>Profiles")
    util.yield(100)
    trigger_command_by_ref("Stand")
    util.yield(100)
    trigger_command_by_ref("Stand>Profiles")
    util.yield(500)

    if combine_profiles then
        local active_profile_name = clean_profile_name(get_active_profile_name())
        for k, v in util.read_colons_and_tabs_file(get_profile_path_by_name(profile_name)) do
            if k:startswith("Stand>Settings>Appearance") or k:startswith("Stand>Lua Scripts") then
                local ref = menu.ref_by_path(k .. ">" .. v, 43)
                if not ref:isValid() then
                    trigger_command_by_ref(k, v)
                else
                    trigger_command_by_ref(k .. ">" .. v)
                end
            end
            util.yield()
        end
        util.yield(100)
        trigger_command("save" .. active_profile_name)
    else
        if not trigger_command_by_ref("Stand>Profiles>" .. profile_name .. ">Active") then
            util.toast("Failed to set " .. profile_name .. " as the active profile. You may need to do this yourself.")
        end
        util.yield(100)
        trigger_command("load" .. profile_name)
        util.yield(500)
    end

    util.yield(100)
    trigger_command_by_ref("Stand>Lua Scripts")
    util.yield(100)
    trigger_command_by_ref("Stand>Lua Scripts>ProfileHelper")
    util.yield(100)
    trigger_command("clearstandnotifys")
end

function clean_profile_name(profile_name)
    return string.gsub(string.gsub(profile_name, "%-", ""), " ", ""):lower()
end

function get_profile_path_by_name(profile_name)
    return stand_dir .. "Profiles\\" .. profile_name .. ".txt"
end

function get_active_profile_name()
    local meta_state_path = filesystem.stand_dir() .. "Meta State.txt"
    local file = io.open(meta_state_path, "rb")

    if file == nil then
        return file
    end

    local str = file:read("*a")
    file:close()

    if str:startswith("Active Profile:") then
        local active_profile_name = str:gsub("[\n\r]", ""):split(": ")[2]
        return active_profile_name
    end

    return nil
end

function get_remote_theme_dir_by_name(theme_name, file_name)
    return "Themes/" .. theme_name .. "/" .. file_name
end

function get_local_theme_dir_by_name(file_name)
    return theme_dir .. file_name
end

function get_resource_dir_by_name(theme_name, file_name)
    local str = resource_dir .. theme_name
    if file_name ~= nil then
        str = str .. "\\" .. file_name
    end

    return str
end

function does_profile_exist_by_name(profile_name)
    local profile_path = get_profile_path_by_name(profile_name)
    return filesystem.exists(profile_path) and filesystem.is_regular_file(profile_path)
end

function empty_headers_dir()
    for _, path in io.listdir(header_dir) do
        if filesystem.is_regular_file(path) then
            io.remove(path)
        end
    end
end

function trigger_command(command, args)
    if args then
        menu.trigger_commands(command .. " " .. args)
        return
    end

    menu.trigger_commands(command)
end

function trigger_command_by_ref(ref, args)
    local _ref = menu.ref_by_path(ref, 43)
    if not _ref:isValid() then
        return false
    end

    if args == nil then
        menu.trigger_command(_ref)
        return true
    end

    menu.trigger_command(_ref, args)
    return true
end

util.keep_running()