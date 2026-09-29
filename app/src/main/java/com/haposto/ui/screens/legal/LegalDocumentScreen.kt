package com.haposto.ui.screens.legal

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.haposto.ui.components.SimpleScreen

/** Documenti legali inclusi nell'app (stesso testo pubblicato sul sito). */
enum class LegalDocument(val key: String, val file: String, val title: String) {
    PRIVACY("privacy", "privacy.md", "Privacy"),
    TERMS("termini", "termini.md", "Termini d'uso"),
    RESTAURANT_TERMS("termini-ristoranti", "termini-ristoranti.md", "Condizioni per i ristoranti"),
    COOKIES("cookie", "cookie.md", "Cookie"),
    LICENSES("licenze", "licenze.md", "Licenze e crediti"),
    ;

    companion object {
        fun fromKey(key: String?): LegalDocument = entries.firstOrNull { it.key == key } ?: PRIVACY
    }
}

@Composable
fun LegalDocumentRoute(document: LegalDocument, onBack: () -> Unit) {
    val context = LocalContext.current
    val text = remember(document) {
        runCatching {
            context.assets.open("legal/${document.file}").bufferedReader().use { it.readText() }
        }.getOrDefault("Documento non disponibile.")
    }
    SimpleScreen(title = document.title, onBack = onBack) {
        MarkdownText(text)
        Spacer(Modifier.height(24.dp))
    }
}

/** Rendering essenziale del Markdown dei documenti: titoli, elenchi, tabelle, grassetto. */
@Composable
fun MarkdownText(markdown: String) {
    markdown.lines().forEach { raw ->
        val line = raw.trimEnd()
        when {
            line.isBlank() -> Spacer(Modifier.height(2.dp))
            line.startsWith("# ") -> Text(
                inline(line.removePrefix("# ")),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
            )
            line.startsWith("## ") -> Text(
                inline(line.removePrefix("## ")),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp),
            )
            line.startsWith("### ") -> Text(
                inline(line.removePrefix("### ")),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
            )
            line.startsWith("> ") -> Text(
                inline(line.removePrefix("> ")),
                style = MaterialTheme.typography.bodySmall,
                fontStyle = FontStyle.Italic,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            line.startsWith("- ") -> Row {
                Text("•  ", style = MaterialTheme.typography.bodyMedium)
                Text(inline(line.removePrefix("- ")), style = MaterialTheme.typography.bodyMedium)
            }
            line.startsWith("|") -> {
                val cells = line.trim('|').split('|').map { it.trim() }
                if (cells.all { cell -> cell.all { it == '-' || it == ':' } }) return@forEach
                Text(inline(cells.joinToString("  ·  ")), style = MaterialTheme.typography.bodySmall)
            }
            else -> Text(inline(line), style = MaterialTheme.typography.bodyMedium)
        }
    }
}

private fun inline(text: String): AnnotatedString = buildAnnotatedString {
    text.split("**").forEachIndexed { index, part ->
        if (index % 2 == 1) withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(part) } else append(part)
    }
}
