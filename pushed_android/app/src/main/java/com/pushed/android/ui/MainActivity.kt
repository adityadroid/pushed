package com.pushed.android.ui

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.pushed.android.auth.AuthManager
import com.pushed.android.auth.AuthState
import com.pushed.android.firebase.DeviceManager
import com.pushed.android.service.PushedNotificationListener
import com.pushed.android.ui.theme.PushedTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import kotlinx.coroutines.launch

/**
 * Main Activity for Pushed Android application.
 *
 * Provides the main user interface for:
 * - Displaying connection and permission status
 * - Enabling notification listener permission
 * - Authenticating with Firebase
 * - Managing sync preferences
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var authManager: AuthManager

    @Inject lateinit var deviceManager: DeviceManager

    private val notificationPermissionLauncher =
            registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
                // Permission result handled by state refresh
            }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            PushedTheme {
                MainScreen(
                        authManager = authManager,
                        deviceManager = deviceManager,
                        onRequestNotificationListenerPermission =
                                ::openNotificationListenerSettings,
                        onRequestNotificationPermission = ::requestNotificationPermission,
                        checkNotificationListenerEnabled = ::isNotificationListenerEnabled,
                        checkNotificationPermissionGranted = ::isNotificationPermissionGranted
                )
            }
        }
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val componentName = ComponentName(this, PushedNotificationListener::class.java)
        val enabledListeners =
                Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return enabledListeners?.contains(componentName.flattenToString()) == true
    }

    private fun isNotificationPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            true // Not required below Android 13
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
        authManager: AuthManager,
        deviceManager: DeviceManager,
        onRequestNotificationListenerPermission: () -> Unit,
        onRequestNotificationPermission: () -> Unit,
        checkNotificationListenerEnabled: () -> Boolean,
        checkNotificationPermissionGranted: () -> Boolean
) {
    val authState by authManager.authState.collectAsState(initial = AuthState.Unauthenticated)
    var notificationListenerEnabled by remember { mutableStateOf(false) }
    var notificationPermissionGranted by remember { mutableStateOf(false) }

    // Refresh permission states periodically
    LaunchedEffect(Unit) {
        while (true) {
            notificationListenerEnabled = checkNotificationListenerEnabled()
            notificationPermissionGranted = checkNotificationPermissionGranted()
            kotlinx.coroutines.delay(1000)
        }
    }

    val gradientColors = listOf(Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460))

    Surface(modifier = Modifier.fillMaxSize(), color = Color(0xFF1A1A2E)) {
        Scaffold(
                topBar = {
                    TopAppBar(
                            title = {
                                Text(
                                        text = "Pushed",
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                )
                            },
                            colors =
                                    TopAppBarDefaults.topAppBarColors(
                                            containerColor = Color.Transparent
                                    )
                    )
                },
                containerColor = Color.Transparent
        ) { paddingValues ->
            Box(
                    modifier =
                            Modifier.fillMaxSize()
                                    .background(Brush.verticalGradient(gradientColors))
                                    .padding(paddingValues)
            ) {
                Column(
                        modifier =
                                Modifier.fillMaxSize()
                                        .verticalScroll(rememberScrollState())
                                        .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Status Header
                    StatusHeader(
                            isAuthenticated = authState is AuthState.Authenticated,
                            notificationListenerEnabled = notificationListenerEnabled,
                            notificationPermissionGranted = notificationPermissionGranted
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Permission Cards
                    PermissionCard(
                            title = "Notification Access",
                            description =
                                    "Required to intercept and forward notifications to your Apple Watch",
                            isGranted = notificationListenerEnabled,
                            onRequestPermission = onRequestNotificationListenerPermission,
                            buttonText = "Open Settings"
                    )

                    PermissionCard(
                            title = "Post Notifications",
                            description = "Required to show sync status and connection updates",
                            isGranted = notificationPermissionGranted,
                            onRequestPermission = onRequestNotificationPermission,
                            buttonText = "Grant Permission"
                    )

                    // Authentication Card
                    AuthenticationCard(
                            authState = authState,
                            onSignIn = { /* TODO: Implement sign in flow */}
                    )

                    // Device Info Card
                    if (authState is AuthState.Authenticated) {
                        DeviceInfoCard(deviceManager = deviceManager)
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Footer
                    Text(
                            text = "Pushed bridges your Android notifications to your Apple Watch",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.6f),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 32.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun StatusHeader(
        isAuthenticated: Boolean,
        notificationListenerEnabled: Boolean,
        notificationPermissionGranted: Boolean
) {
    val allReady = isAuthenticated && notificationListenerEnabled && notificationPermissionGranted

    Card(
            modifier = Modifier.fillMaxWidth(),
            colors =
                    CardDefaults.cardColors(
                            containerColor =
                                    if (allReady) Color(0xFF1B4332).copy(alpha = 0.8f)
                                    else Color(0xFF3D1308).copy(alpha = 0.8f)
                    ),
            shape = RoundedCornerShape(16.dp)
    ) {
        Row(
                modifier = Modifier.fillMaxWidth().padding(20.dp),
                verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                    modifier =
                            Modifier.size(56.dp)
                                    .clip(CircleShape)
                                    .background(
                                            if (allReady) Color(0xFF2D6A4F) else Color(0xFF9D0208)
                                    ),
                    contentAlignment = Alignment.Center
            ) {
                Icon(
                        imageVector = if (allReady) Icons.Filled.Check else Icons.Filled.Warning,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(32.dp)
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column {
                Text(
                        text = if (allReady) "All Systems Ready" else "Setup Required",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                )
                Text(
                        text =
                                if (allReady) "Notifications are being forwarded to your watch"
                                else "Complete the setup below to start forwarding",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.8f)
                )
            }
        }
    }
}

@Composable
fun PermissionCard(
        title: String,
        description: String,
        isGranted: Boolean,
        onRequestPermission: () -> Unit,
        buttonText: String
) {
    Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E2E).copy(alpha = 0.9f)),
            shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                        modifier =
                                Modifier.size(12.dp)
                                        .clip(CircleShape)
                                        .background(
                                                if (isGranted) Color(0xFF52B788)
                                                else Color(0xFFE85D04)
                                        )
                )

                Spacer(modifier = Modifier.width(12.dp))

                Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.7f)
            )

            if (!isGranted) {
                Spacer(modifier = Modifier.height(16.dp))

                Button(
                        onClick = onRequestPermission,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE85D04)),
                        shape = RoundedCornerShape(12.dp)
                ) { Text(text = buttonText, fontWeight = FontWeight.SemiBold) }
            }
        }
    }
}

@Composable
fun AuthenticationCard(authState: AuthState, onSignIn: () -> Unit) {
    Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E2E).copy(alpha = 0.9f)),
            shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                        modifier =
                                Modifier.size(12.dp)
                                        .clip(CircleShape)
                                        .background(
                                                if (authState is AuthState.Authenticated)
                                                        Color(0xFF52B788)
                                                else Color(0xFFE85D04)
                                        )
                )

                Spacer(modifier = Modifier.width(12.dp))

                Text(
                        text = "Account",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            when (authState) {
                is AuthState.Authenticated -> {
                    Text(
                            text = "Signed in as",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.6f)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                            text = authState.email ?: authState.displayName ?: "User",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium,
                            color = Color.White
                    )
                }
                is AuthState.Unauthenticated -> {
                    Text(
                            text = "Sign in to sync notifications across devices",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.7f)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedButton(
                            onClick = onSignIn,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(
                                text = "Sign In",
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DeviceInfoCard(deviceManager: DeviceManager) {
    val deviceName = remember { deviceManager.getDeviceName() }
    val deviceId = remember { deviceManager.getDeviceId() }

    Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E2E).copy(alpha = 0.9f)),
            shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(20.dp)) {
            Text(
                    text = "Device Info",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
            )

            Spacer(modifier = Modifier.height(16.dp))

            InfoRow(label = "Device Name", value = deviceName)
            Spacer(modifier = Modifier.height(8.dp))
            InfoRow(label = "Device ID", value = deviceId.take(24) + "...")
        }
    }
}

@Composable
fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.6f)
        )
        Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = Color.White
        )
    }
}
