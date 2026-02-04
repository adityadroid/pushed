package com.pushed.android.data.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.time.Instant

/**
 * Custom serializer for java.time.Instant.
 * Serializes to/from ISO-8601 string format.
 */
object InstantSerializer : KSerializer<Instant> {
    override val descriptor: SerialDescriptor = 
        PrimitiveSerialDescriptor("Instant", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: Instant) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): Instant {
        return Instant.parse(decoder.decodeString())
    }
}

/**
 * Custom serializer for List<NotificationAction>.
 * Used by Room to store actions as JSON string.
 */
object NotificationActionListSerializer : KSerializer<List<NotificationAction>> {
    private val delegateSerializer = ListSerializer(NotificationAction.serializer())
    
    override val descriptor: SerialDescriptor = delegateSerializer.descriptor

    override fun serialize(encoder: Encoder, value: List<NotificationAction>) {
        delegateSerializer.serialize(encoder, value)
    }

    override fun deserialize(decoder: Decoder): List<NotificationAction> {
        return delegateSerializer.deserialize(decoder)
    }
}
