package com.haposto.platform.qr

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.graphics.createBitmap
import androidx.core.graphics.set
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.io.File

/** QR code e adesivo "Prima di chiamare" generati sul telefono, senza servizi esterni. */
object QrCodes {

    fun bitmap(content: String, sizePx: Int = 720): Bitmap {
        val hints = mapOf(
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M,
            EncodeHintType.MARGIN to 1,
        )
        val matrix = QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)
        val bitmap = createBitmap(matrix.width, matrix.height)
        for (x in 0 until matrix.width) {
            for (y in 0 until matrix.height) {
                bitmap[x, y] = if (matrix.get(x, y)) Color.BLACK else Color.WHITE
            }
        }
        return bitmap
    }

    /** Immagine PNG del QR pronta da condividere (WhatsApp, email, stampa). */
    fun sharePng(context: Context, fileName: String, content: String): Intent {
        val file = File(shareDir(context), "$fileName.png")
        file.outputStream().use { bitmap(content, 1024).compress(Bitmap.CompressFormat.PNG, 100, it) }
        return shareIntent(context, file, "image/png")
    }

    /**
     * Adesivo A6 (105 × 148 mm) da stampare: nome del locale, invito e QR con il link della pagina.
     */
    fun stickerPdf(context: Context, fileName: String, restaurantName: String, url: String): Intent {
        val document = PdfDocument()
        val page = document.startPage(PdfDocument.PageInfo.Builder(298, 420, 1).create())
        val canvas: Canvas = page.canvas
        val ink = Color.rgb(0x17, 0x3A, 0x47)
        val title = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ink
            textSize = 22f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        val body = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ink
            textSize = 12f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawColor(Color.WHITE)
        canvas.drawText("Prima di chiamare,", 149f, 46f, title)
        canvas.drawText("guarda se c'è posto", 149f, 72f, title)
        canvas.drawBitmap(bitmap(url, 600), null, Rect(49, 92, 249, 292), null)
        canvas.drawText(restaurantName.take(40), 149f, 322f, Paint(body).apply { textSize = 15f; typeface = Typeface.DEFAULT_BOLD })
        canvas.drawText("Inquadra il codice con la fotocamera", 149f, 346f, body)
        canvas.drawText(url.removePrefix("https://"), 149f, 366f, body)
        canvas.drawText("HAPOSTO · Sai dove c'è posto. Ora.", 149f, 400f, Paint(body).apply { textSize = 10f })
        document.finishPage(page)

        val file = File(shareDir(context), "$fileName.pdf")
        file.outputStream().use(document::writeTo)
        document.close()
        return shareIntent(context, file, "application/pdf")
    }

    private fun shareDir(context: Context): File =
        File(context.cacheDir, "shared").apply { mkdirs() }

    private fun shareIntent(context: Context, file: File, mime: String): Intent {
        val uri: Uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return Intent.createChooser(send, null).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
}
