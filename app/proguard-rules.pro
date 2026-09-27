# Regole ProGuard/R8 del progetto HAPOSTO.
# Lo Step 7 non abilita la minificazione in debug; questo file è pronto per il release.
# Aggiungi qui eventuali regole quando attiverai isMinifyEnabled = true.

# Kotlinx Serialization (DTO Supabase annotati @Serializable)
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
