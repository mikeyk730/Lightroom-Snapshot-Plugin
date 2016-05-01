local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'
local LrLogger = import 'LrLogger'

logger = LrLogger('Lightroom-Snapshot-Plugin')
logger:enable("logfile")


PhotoProcessor = {}

function PhotoProcessor.promptForSnapshotName()
   local r = "Untitled"
   LrFunctionContext.callWithContext("promptForSnapshotName", function(context)
      local props = LrBinding.makePropertyTable(context)
      props.name = r

      local f = LrView.osFactory()
      local c = f:row {
         bind_to_object = props,
         f:edit_field {
            value = LrView.bind("name")
         },
      }

      local result = LrDialogs.presentModalDialog({
            title = "Enter Name For Snapshot",
            contents = c
      })
      
      if result == "ok" then
         r = props.name
      else
         r = nil
      end
   end)
   return r
end


--Create a develop snapshot for the supplied photo.
function PhotoProcessor.createSnapshot(photo, name)
   logger:trace("Create Snapshot", name, photo.path)
   if photo:checkPhotoAvailability() then         
      local catalog = LrApplication.activeCatalog()
      catalog:withWriteAccessDo("Create Snapshot", function(context) 
          photo:createDevelopSnapshot(name, true)
      end, { timeout=60 })
   else
      logger:warn("Photo not available: " .. photo.path)
   end
end


function PhotoProcessor.startSnapshotTask(photo, name)
   LrTasks.startAsyncTask(function(context)
         PhotoProcessor.createSnapshot(photo, name)
   end)
end


--Returns a table of the files that are currently selected in Lightroom
function PhotoProcessor.getSelectedPhotos()
   local catalog = LrApplication.activeCatalog()
   local photo = catalog:getTargetPhoto()
   local photos = catalog:getTargetPhotos()

   if photo ~= nil then
      return photos
   else
      return {}
   end
end


--Main entry point for scripts associated with menu items
function PhotoProcessor.processPhotos()
   local photos = PhotoProcessor.getSelectedPhotos()
   local totalPhotos = #photos
   logger:trace("processPhotos", totalPhotos)

   local name = PhotoProcessor.promptForSnapshotName()
   if name == nil then
      logger:trace("No name provided")
      return
   end

   local progressScope = LrProgressScope {title="Create Snapshot For  "..totalPhotos.." Photos"}
   --todo:doens't work, progress hangs on error
   --progressScope:attachToFunctionContext(context)
   progressScope:setCancelable(true)

   for i,photo in ipairs(photos) do
      if progressScope:isCanceled() then 
         logger:trace("Canceled task", i)
         break
      end
      progressScope:setPortionComplete(i, totalPhotos)
      progressScope:setCaption("Snapshot "..i.." of "..totalPhotos)

      PhotoProcessor.startSnapshotTask(photo, name)
   end

   logger:trace("Completed task", totalPhotos)
   progressScope:done()
end
