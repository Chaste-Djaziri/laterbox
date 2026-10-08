# Dependencies supply consumer rules for Room, WorkManager, Compose,
# Kotlin serialization, Supabase, and ML Kit. Avoid package-wide keep rules:
# they prevent R8 from shrinking and obfuscating unused dependency code.
# Keep source line information for crash reports retraced with mapping.txt.
-keepattributes SourceFile,LineNumberTable
