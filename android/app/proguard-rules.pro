# flutter_local_notifications uses Gson with TypeToken for serialization.
# R8 strips generic type info causing "Missing type parameter" crash.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications plugin classes
-keep class com.dexterous.** { *; }
