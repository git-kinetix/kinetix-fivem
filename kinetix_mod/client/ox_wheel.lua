local enableIcons = true

lib.registerRadial({
    id = 'emote_wheel',
    items = {}
})

function CreateEmoteWheel(data)
	lib.clearRadialItems()
	
	if #data == 0 then
		lib.addRadialItem({
            {
              id = 'create_new_emote_item',
              label = 'New emote',
			  icon = 'fa-solid fa-plus',
              onSelect = function()
				lib.hideRadial()
				lib.showContext('create_anim_root')
				TriggerServerEvent("requestInit")
              end
            },
          })
	end

    for _, emote in pairs(data) do
		local icon
		for _, obj in ipairs(emote.data.files) do
            if obj.extension == 'gif' and obj.name == 'thumbnail' then
                icon = obj.url
            end
        end
		local item = {
            {
              id = emote.data.uuid,
              label = emote.data.name,
              onSelect = function()
                ExecuteCommand('kinetix_anim ' .. emote.data.uuid)
              end
            },
          }
		  
		if enableIcons == true then
			item[1].icon = icon
			item[1].iconWidth = 60
			item[1].iconHeight = 60
		end
		
        lib.addRadialItem(item)
    end
end