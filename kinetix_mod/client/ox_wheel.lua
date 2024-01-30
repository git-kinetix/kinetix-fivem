lib.registerRadial({
    id = 'emote_wheel',
    items = {}
})

function CreateEmoteWheel(data)
    for _, emote in pairs(data) do
        lib.addRadialItem({
            {
              id = emote.data.uuid,
              label = emote.data.name,
              onSelect = function()
                ExecuteCommand('kinetix_anim ' .. emote.data.uuid)
              end
            },
          })
    end
end