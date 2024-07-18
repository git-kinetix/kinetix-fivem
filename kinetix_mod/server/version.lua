local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local resourceName = "kinetix_mod"
local githubRepo = "git-kinetix/kinetix-fivem"

function checkForUpdates()
    PerformHttpRequest("https://api.github.com/repos/" .. githubRepo .. "/releases/latest", function(statusCode, response, headers)
        if statusCode == 200 then
            local latestRelease = json.decode(response)
            local latestVersion = latestRelease.tag_name:gsub('%v', '')

            if latestVersion ~= currentVersion then
				print("^0[^2INFO^0] ^3kinetix_mod^0 Latest version: ^2" .. latestVersion)
				print("^0[^2INFO^0] ^3kinetix_mod^0 Your version: ^4" .. currentVersion)
                print("^1Please update your resource from https://github.com/" .. githubRepo .. "/releases/latest^0")
            end
        else
            print("^1Failed to check for updates. Status code: " .. statusCode .. "^0")
        end
    end, "GET", "", {["User-Agent"] = "Mozilla/5.0"})
end

checkForUpdates()