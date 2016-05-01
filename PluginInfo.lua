local LrView = import 'LrView'
local LrHttp = import 'LrHttp'
local bind = import 'LrBinding'
local app = import 'LrApplication'

PluginInfo = {}

function PluginInfo.sectionsForTopOfDialog(f,p)
   return {
      {
         title = "Custom Metadata Sample",
         f:row {
            spacing = f:control_spacing(),
            f:static_text {
               title = 'Click the button',
               alignment = 'left',
               fill_horizontal = 1,
               
            },
            f:push_button {
               width = 150,
               title = 'Connect',
               enabled = true,
               action = function()
                  LrHttp.openUrlInBrowser(_G.URL)
               end,
            }
         },
         f:row {
            f:static_text {
               title = "display image: ",
               alignment = 'left',
            },
            f:static_text {
               title = _G.currentDisplayImage,
               fill_horizontal = 1,
            },
         },
      }
   }
end
