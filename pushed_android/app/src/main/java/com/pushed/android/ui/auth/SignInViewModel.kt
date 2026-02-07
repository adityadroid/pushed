package com.pushed.android.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pushed.android.auth.AuthManager
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class SignInViewModel @Inject constructor(private val authManager: AuthManager) : ViewModel() {

    private val _uiState = MutableStateFlow<SignInUiState>(SignInUiState.Idle)
    val uiState: StateFlow<SignInUiState> = _uiState.asStateFlow()

    fun signIn(email: String, password: String) {
        if (email.isBlank() || password.isBlank()) {
            _uiState.value = SignInUiState.Error("Email and password cannot be empty")
            return
        }

        viewModelScope.launch {
            _uiState.value = SignInUiState.Loading
            val result = authManager.signInWithEmail(email, password)
            result.onSuccess { _uiState.value = SignInUiState.Success }.onFailure { exception ->
                val errorMessage =
                        when {
                            exception.message?.contains("API key not valid") == true ->
                                    "Configuration Error: Invalid API Key. Please update google-services.json."
                            exception.message?.contains("network error") == true ->
                                    "Network Error: Please check your connection."
                            else -> exception.message ?: "Sign in failed"
                        }
                _uiState.value = SignInUiState.Error(errorMessage)
            }
        }
    }

    fun clearError() {
        if (_uiState.value is SignInUiState.Error) {
            _uiState.value = SignInUiState.Idle
        }
    }
}

sealed class SignInUiState {
    data object Idle : SignInUiState()
    data object Loading : SignInUiState()
    data object Success : SignInUiState()
    data class Error(val message: String) : SignInUiState()
}
