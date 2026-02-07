package com.pushed.android.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInScreen(
        onNavigateBack: () -> Unit,
        onSignInSuccess: () -> Unit,
        viewModel: SignInViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    LaunchedEffect(uiState) {
        if (uiState is SignInUiState.Success) {
            onSignInSuccess()
        }
    }

    Scaffold(
            topBar = {
                TopAppBar(
                        title = { Text("Sign In", color = Color.White) },
                        navigationIcon = {
                            IconButton(onClick = onNavigateBack) {
                                Icon(
                                        imageVector = Icons.Default.ArrowBack,
                                        contentDescription = "Back",
                                        tint = Color.White
                                )
                            }
                        },
                        colors =
                                TopAppBarDefaults.topAppBarColors(
                                        containerColor = Color.Transparent
                                )
                )
            },
            containerColor = Color(0xFF1A1A2E)
    ) { paddingValues ->
        Box(
                modifier =
                        Modifier.fillMaxSize().padding(paddingValues).background(Color(0xFF1A1A2E))
        ) {
            Column(
                    modifier =
                            Modifier.fillMaxSize()
                                    .padding(16.dp)
                                    .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                        text = "Welcome Back",
                        style = MaterialTheme.typography.headlineMedium,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(32.dp))

                OutlinedTextField(
                        value = email,
                        onValueChange = {
                            email = it
                            viewModel.clearError()
                        },
                        label = { Text("Email") },
                        singleLine = true,
                        keyboardOptions =
                                KeyboardOptions(
                                        keyboardType = KeyboardType.Email,
                                        imeAction = ImeAction.Next
                                ),
                        modifier = Modifier.fillMaxWidth(),
                        colors =
                                OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        cursorColor = Color(0xFF52B788),
                                        focusedBorderColor = Color(0xFF52B788),
                                        unfocusedBorderColor = Color.White.copy(alpha = 0.5f),
                                        focusedLabelColor = Color(0xFF52B788),
                                        unfocusedLabelColor = Color.White.copy(alpha = 0.7f)
                                )
                )

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                        value = password,
                        onValueChange = {
                            password = it
                            viewModel.clearError()
                        },
                        label = { Text("Password") },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions =
                                KeyboardOptions(
                                        keyboardType = KeyboardType.Password,
                                        imeAction = ImeAction.Done
                                ),
                        modifier = Modifier.fillMaxWidth(),
                        colors =
                                OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        cursorColor = Color(0xFF52B788),
                                        focusedBorderColor = Color(0xFF52B788),
                                        unfocusedBorderColor = Color.White.copy(alpha = 0.5f),
                                        focusedLabelColor = Color(0xFF52B788),
                                        unfocusedLabelColor = Color.White.copy(alpha = 0.7f)
                                )
                )

                Spacer(modifier = Modifier.height(24.dp))

                if (uiState is SignInUiState.Error) {
                    Text(
                            text = (uiState as SignInUiState.Error).message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }

                Button(
                        onClick = { viewModel.signIn(email, password) },
                        enabled = uiState !is SignInUiState.Loading,
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors =
                                ButtonDefaults.buttonColors(
                                        containerColor = Color(0xFF52B788),
                                        disabledContainerColor =
                                                Color(0xFF52B788).copy(alpha = 0.5f)
                                )
                ) {
                    if (uiState is SignInUiState.Loading) {
                        CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                color = Color.White
                        )
                    } else {
                        Text(
                                text = "Sign In",
                                fontSize = MaterialTheme.typography.titleMedium.fontSize,
                                fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
