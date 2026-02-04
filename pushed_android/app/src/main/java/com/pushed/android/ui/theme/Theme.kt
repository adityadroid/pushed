package com.pushed.android.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme =
        darkColorScheme(
                primary = Color(0xFFE85D04),
                onPrimary = Color.White,
                primaryContainer = Color(0xFFBF4A04),
                onPrimaryContainer = Color.White,
                secondary = Color(0xFF52B788),
                onSecondary = Color.White,
                secondaryContainer = Color(0xFF2D6A4F),
                onSecondaryContainer = Color.White,
                tertiary = Color(0xFF7B2CBF),
                onTertiary = Color.White,
                background = Color(0xFF1A1A2E),
                onBackground = Color.White,
                surface = Color(0xFF1E1E2E),
                onSurface = Color.White,
                surfaceVariant = Color(0xFF2E2E3E),
                onSurfaceVariant = Color(0xFFCAC4D0),
                error = Color(0xFFEF476F),
                onError = Color.White
        )

private val LightColorScheme =
        lightColorScheme(
                primary = Color(0xFFE85D04),
                onPrimary = Color.White,
                primaryContainer = Color(0xFFFFE0B2),
                onPrimaryContainer = Color(0xFF3E2723),
                secondary = Color(0xFF2D6A4F),
                onSecondary = Color.White,
                secondaryContainer = Color(0xFFA8DADC),
                onSecondaryContainer = Color(0xFF1D3557),
                tertiary = Color(0xFF6A1B9A),
                onTertiary = Color.White,
                background = Color(0xFFFFFBFE),
                onBackground = Color(0xFF1C1B1F),
                surface = Color(0xFFFFFBFE),
                onSurface = Color(0xFF1C1B1F),
                surfaceVariant = Color(0xFFE7E0EC),
                onSurfaceVariant = Color(0xFF49454F)
        )

@Composable
fun PushedTheme(
        darkTheme: Boolean = isSystemInDarkTheme(),
        // Dynamic color is available on Android 12+
        dynamicColor: Boolean = false,
        content: @Composable () -> Unit
) {
    val colorScheme =
            when {
                dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    val context = LocalContext.current
                    if (darkTheme) dynamicDarkColorScheme(context)
                    else dynamicLightColorScheme(context)
                }
                darkTheme -> DarkColorScheme
                else -> LightColorScheme
            }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(colorScheme = colorScheme, content = content)
}
