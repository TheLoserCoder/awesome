local awful = require("awful")
local gears = require("gears")

local ImageLoader = {}
local image_cache = {}

function ImageLoader.load_from_url(url, callback)
    if image_cache[url] then
        callback(image_cache[url])
        return
    end

    local temp_file = "/tmp/awesome_img_" .. os.time() .. math.random(1000, 9999)
    
    awful.spawn.easy_async({ "curl", "-s", "-L", "-o", temp_file, url }, function(stdout, stderr, reason, exit_code)
        if exit_code == 0 then
            image_cache[url] = temp_file
            callback(temp_file)
            
            gears.timer.start_new(10, function()
                awful.spawn({ "rm", "-f", temp_file })
                return false
            end)
        else
            callback(nil)
        end
    end)
end

function ImageLoader.is_url(path)
    return path:match("^https?://") ~= nil
end

function ImageLoader.is_file_url(path)
    return path:match("^file://") ~= nil
end

function ImageLoader.is_base64_data(path)
    return path:match("^data:image/[^;]+;base64,") ~= nil
end

function ImageLoader.load_from_base64(data, callback)
    local base64_data = data:match("^data:image/[^;]+;base64,(.+)$")
    if not base64_data then
        callback(nil)
        return
    end
    
    local temp_file = "/tmp/awesome_b64_" .. os.time() .. math.random(1000, 9999)
    
    awful.spawn.easy_async_with_shell("echo '" .. base64_data .. "' | base64 -d > '" .. temp_file .. "'", function(stdout, stderr, reason, exit_code)
        if exit_code == 0 then
            callback(temp_file)
            
            gears.timer.start_new(10, function()
                awful.spawn({ "rm", "-f", temp_file })
                return false
            end)
        else
            callback(nil)
        end
    end)
end

function ImageLoader.file_url_to_path(file_url)
    return file_url:gsub("^file://", "")
end

return ImageLoader
