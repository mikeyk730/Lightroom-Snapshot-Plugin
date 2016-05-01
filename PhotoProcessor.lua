local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'


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


--Create a develop snapshot fro the supplied photo.  If no name is supplied
--the user will be prompted with a dialog
--todo:move to standalone plugin
function PhotoProcessor.runCommandCreateSnapshot(photo, name)
   logger:trace("Entering runCommandCreateSnapshot", photo.path)
   
   --todo:
   if name == nil then
      logger:trace("Snapshot canceled", photo.path)
      return
   end

   logger:trace("Creating snapshot", name, photo.path)
   local catalog = LrApplication.activeCatalog()
   catalog:withWriteAccessDo("Create Snapshot", function(context) 
         photo:createDevelopSnapshot(name, true)
   end, { timeout=60 })
end


function PhotoProcessor.promptUser(action)
   local props = {}

   if action == "createSnapshot" then
      props.name = PhotoProcessor.promptForSnapshotName()
   end

   return props
end


function PhotoProcessor.processPhoto(photo, action, props)
   --LrTasks.startAsyncTask(function(context)
         local available = photo:checkPhotoAvailability()
         if available then         

            --Skip files that are not Canon Raw files
            local ft = photo:getFormattedMetadata('fileType')
            local make = photo:getFormattedMetadata('cameraMake')
            if ft ~= 'Raw' or make ~= 'Canon' then
               logger:trace("Skipping unsupported file", make, ft, photo.path)
               return
            end

         if action == "createSnapshot" then
               PhotoProcessor.runCommandCreateSnapshot(photo, props.name)
            else
               logger:error("Unknown action: " .. action)
            end
         else
            logger:warn("Photo not available: " .. photo.path)
         end
   --end)
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
function PhotoProcessor.processPhotos(action)
   local photos = PhotoProcessor.getSelectedPhotos()
   local totalPhotos = #photos
   logger:trace("Starting task", action, totalPhotos)
   --todo:rework so each photo can be a task
   LrTasks.startAsyncTask(function(context)
         local progressScope = LrProgressScope {title=action.." "..totalPhotos.." photos"}
         --todo:doens't work, progress hangs on error
         --progressScope:attachToFunctionContext(context)
         progressScope:setCancelable(true)

         local props = PhotoProcessor.promptUser(action)

         for i,v in ipairs(photos) do
            if progressScope:isCanceled() then 
               logger:trace("Canceled task", action, i)
               break
            end
            progressScope:setPortionComplete(i, totalPhotos)
            progressScope:setCaption(action.." "..i.." of "..totalPhotos)
            PhotoProcessor.processPhoto(v, action, props)
         end

         logger:trace("Completed task", action, totalPhotos)
         progressScope:done()
   end)
end
