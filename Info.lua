return {
   LrSdkVersion = 5.0,
   LrToolkitIdentifier = 'com.mkaminski.snapshot',
   LrPluginName = LOC "$$$/Metadata/PluginName=Snapshot",

   LrInitPlugin = 'PluginInit.lua',
   LrPluginInfoProvider = "PluginInfoProvider.lua",
   LrPluginInfoUrl = "http://www.mkaminski.com",

   LrLibraryMenuItems = {
      {
         title = "Create &Snapshot",
         file = "MenuItemCreateSnapshot.lua",
         enabledWhen = "photosSelected",
      },
   },
}
