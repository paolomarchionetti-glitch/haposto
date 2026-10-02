package com.haposto.platform.files

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import kotlin.math.max

/** File pronto da caricare: foto già ridotta (JPEG) o PDF. */
class PreparedFile(val bytes: ByteArray, val mimeType: String) {
    val isPdf: Boolean get() = mimeType == "application/pdf"
}

/**
 * Prepara il file del locale prima del caricamento: le foto diventano JPEG con il lato lungo di
 * 1600 px (il ricampionamento toglie anche i dati EXIF, compresa la posizione GPS); i PDF si
 * caricano così come sono, fino a 2 MB. Il server ricontrolla tipo, peso e dimensioni.
 * Da chiamare fuori dal thread principale (decodifica dell'immagine).
 */
object RestaurantFileReader {

    const val MAX_SIDE = 1600
    const val MAX_PDF_BYTES = 2_097_152
    private const val MAX_IMAGE_BYTES = 900_000
    private const val MAX_SOURCE_BYTES = 40 * 1024 * 1024

    sealed interface Result {
        data class Ready(val file: PreparedFile) : Result
        data class Error(val message: String) : Result
    }

    fun read(context: Context, uri: Uri): Result {
        val resolver = context.contentResolver
        val type = resolver.getType(uri).orEmpty()
        return try {
            when {
                type == "application/pdf" -> readPdf(resolver, uri)
                type.startsWith("image/") -> shrinkImage(resolver, uri)
                else -> Result.Error("Si possono caricare solo foto o PDF.")
            }
        } catch (_: Exception) {
            Result.Error("Non riesco a leggere il file. Riprova o scegline un altro.")
        } catch (_: OutOfMemoryError) {
            Result.Error("Foto troppo grande per questo telefono: scegline un'altra.")
        }
    }

    private fun readPdf(resolver: ContentResolver, uri: Uri): Result {
        val bytes = resolver.openInputStream(uri)?.use { it.readAtMost(MAX_PDF_BYTES + 1) }
            ?: return Result.Error("Non riesco a leggere il file.")
        if (bytes.size > MAX_PDF_BYTES) {
            return Result.Error("PDF troppo grande (massimo 2 MB). Fotografa il menù: la foto si riduce da sola.")
        }
        return Result.Ready(PreparedFile(bytes, "application/pdf"))
    }

    private fun shrinkImage(resolver: ContentResolver, uri: Uri): Result {
        val original = resolver.openInputStream(uri)?.use { it.readAtMost(MAX_SOURCE_BYTES + 1) }
            ?: return Result.Error("Non riesco a leggere la foto.")
        if (original.size > MAX_SOURCE_BYTES) return Result.Error("Foto troppo grande: scegline un'altra.")

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(original, 0, original.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return Result.Error("Foto non leggibile.")
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_SIDE) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(
            original,
            0,
            original.size,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return Result.Error("Foto non leggibile.")

        val scale = MAX_SIDE.toFloat() / max(decoded.width, decoded.height)
        val matrix = Matrix().apply {
            if (scale < 1f) postScale(scale, scale)
            postRotate(exifRotation(original))
        }
        val oriented = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)

        var quality = 82
        var bytes = oriented.toJpeg(quality)
        while (bytes.size > MAX_IMAGE_BYTES && quality > 50) {
            quality -= 10
            bytes = oriented.toJpeg(quality)
        }
        if (bytes.size > MAX_IMAGE_BYTES) return Result.Error("Foto troppo pesante anche ridotta: prova con un'altra.")
        return Result.Ready(PreparedFile(bytes, "image/jpeg"))
    }

    private fun exifRotation(bytes: ByteArray): Float = runCatching {
        when (ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
    }.getOrDefault(0f)

    private fun Bitmap.toJpeg(quality: Int): ByteArray =
        ByteArrayOutputStream().also { compress(Bitmap.CompressFormat.JPEG, quality, it) }.toByteArray()

    /** Legge al massimo [limit] byte: oltre, il file è comunque troppo grande. */
    private fun InputStream.readAtMost(limit: Int): ByteArray {
        val out = ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        while (out.size() < limit) {
            val read = read(buffer, 0, minOf(buffer.size, limit - out.size()))
            if (read < 0) break
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }
}
