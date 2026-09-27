package com.haposto.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.haposto.R

/*
 * Scala tipografica HAPOSTO — STEP 7.8.
 * Font brand Poppins, bundlato in res/font/ (licenza OFL in docs/POPPINS_OFL.txt).
 * Nessuna dipendenza né rete a runtime.
 */
private val Brand = FontFamily(
    Font(R.font.poppins_regular, FontWeight.Normal),
    Font(R.font.poppins_medium, FontWeight.Medium),
    Font(R.font.poppins_semibold, FontWeight.SemiBold),
    Font(R.font.poppins_bold, FontWeight.Bold),
    Font(R.font.poppins_black, FontWeight.Black),
)

val HaPostoTypography = Typography(
    displaySmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Black,
        fontSize = 34.sp, lineHeight = 40.sp, letterSpacing = (-0.5).sp,
    ),
    headlineMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 26.sp, lineHeight = 32.sp, letterSpacing = (-0.3).sp,
    ),
    headlineSmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 22.sp, lineHeight = 28.sp, letterSpacing = (-0.2).sp,
    ),
    titleLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 20.sp, lineHeight = 26.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.SemiBold,
        fontSize = 17.sp, lineHeight = 22.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 16.sp, lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 14.sp, lineHeight = 20.sp,
    ),
    bodySmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 13.sp, lineHeight = 17.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp, lineHeight = 18.sp, letterSpacing = 0.1.sp,
    ),
    labelMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Medium,
        fontSize = 12.sp, lineHeight = 16.sp,
    ),
    labelSmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Medium,
        fontSize = 11.sp, lineHeight = 14.sp,
    ),
)
