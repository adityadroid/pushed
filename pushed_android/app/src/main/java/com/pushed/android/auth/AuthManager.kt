package com.pushed.android.auth

import android.content.Context
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager for Firebase Authentication.
 * 
 * Provides unified authentication across the Pushed system, ensuring
 * the same UID is used on both Android sender devices and watchOS receivers.
 * 
 * Supports:
 * - Google Sign-In
 * - Email/Password authentication
 */
@Singleton
class AuthManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val firebaseAuth: FirebaseAuth
) {

    /**
     * Observable flow of the current authentication state.
     */
    val authState: Flow<AuthState> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { auth ->
            val state = auth.currentUser?.let { user ->
                AuthState.Authenticated(
                    userId = user.uid,
                    email = user.email,
                    displayName = user.displayName,
                    photoUrl = user.photoUrl?.toString()
                )
            } ?: AuthState.Unauthenticated

            trySend(state)
        }

        firebaseAuth.addAuthStateListener(listener)

        awaitClose {
            firebaseAuth.removeAuthStateListener(listener)
        }
    }

    /**
     * Get the current user if authenticated.
     */
    val currentUser: FirebaseUser?
        get() = firebaseAuth.currentUser

    /**
     * Get the current user ID if authenticated.
     */
    val currentUserId: String?
        get() = firebaseAuth.currentUser?.uid

    /**
     * Check if user is currently authenticated.
     */
    val isAuthenticated: Boolean
        get() = firebaseAuth.currentUser != null

    /**
     * Sign in with Google credential.
     * 
     * @param idToken The Google ID token from Google Sign-In
     * @return Result containing the authenticated user or error
     */
    suspend fun signInWithGoogle(idToken: String): Result<FirebaseUser> {
        return try {
            val credential = GoogleAuthProvider.getCredential(idToken, null)
            val authResult = firebaseAuth.signInWithCredential(credential).await()
            
            authResult.user?.let { user ->
                Log.i(TAG, "Google sign-in successful: ${user.uid}")
                Result.success(user)
            } ?: Result.failure(AuthException("Sign-in succeeded but user is null"))
        } catch (e: Exception) {
            Log.e(TAG, "Google sign-in failed", e)
            Result.failure(AuthException("Google sign-in failed: ${e.message}", e))
        }
    }

    /**
     * Sign in with email and password.
     * 
     * @param email User's email address
     * @param password User's password
     * @return Result containing the authenticated user or error
     */
    suspend fun signInWithEmail(email: String, password: String): Result<FirebaseUser> {
        return try {
            val authResult = firebaseAuth.signInWithEmailAndPassword(email, password).await()
            
            authResult.user?.let { user ->
                Log.i(TAG, "Email sign-in successful: ${user.uid}")
                Result.success(user)
            } ?: Result.failure(AuthException("Sign-in succeeded but user is null"))
        } catch (e: Exception) {
            Log.e(TAG, "Email sign-in failed", e)
            Result.failure(AuthException("Email sign-in failed: ${e.message}", e))
        }
    }

    /**
     * Create a new account with email and password.
     * 
     * @param email User's email address
     * @param password User's password
     * @return Result containing the created user or error
     */
    suspend fun createAccountWithEmail(email: String, password: String): Result<FirebaseUser> {
        return try {
            val authResult = firebaseAuth.createUserWithEmailAndPassword(email, password).await()
            
            authResult.user?.let { user ->
                Log.i(TAG, "Account created successfully: ${user.uid}")
                Result.success(user)
            } ?: Result.failure(AuthException("Account creation succeeded but user is null"))
        } catch (e: Exception) {
            Log.e(TAG, "Account creation failed", e)
            Result.failure(AuthException("Account creation failed: ${e.message}", e))
        }
    }

    /**
     * Send password reset email.
     * 
     * @param email User's email address
     * @return Result indicating success or error
     */
    suspend fun sendPasswordResetEmail(email: String): Result<Unit> {
        return try {
            firebaseAuth.sendPasswordResetEmail(email).await()
            Log.i(TAG, "Password reset email sent to $email")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send password reset email", e)
            Result.failure(AuthException("Failed to send password reset: ${e.message}", e))
        }
    }

    /**
     * Sign out the current user.
     */
    fun signOut() {
        Log.i(TAG, "Signing out user: ${currentUserId}")
        firebaseAuth.signOut()
    }

    /**
     * Reload the current user's profile.
     * Useful after email verification or profile updates.
     */
    suspend fun reloadUser(): Result<FirebaseUser> {
        return try {
            currentUser?.reload()?.await()
            currentUser?.let { user ->
                Result.success(user)
            } ?: Result.failure(AuthException("No user to reload"))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reload user", e)
            Result.failure(AuthException("Failed to reload user: ${e.message}", e))
        }
    }

    companion object {
        private const val TAG = "AuthManager"
    }
}

/**
 * Represents the current authentication state.
 */
sealed class AuthState {
    data object Unauthenticated : AuthState()
    
    data class Authenticated(
        val userId: String,
        val email: String?,
        val displayName: String?,
        val photoUrl: String?
    ) : AuthState()
}

/**
 * Exception for authentication errors.
 */
class AuthException(
    message: String,
    cause: Throwable? = null
) : Exception(message, cause)
