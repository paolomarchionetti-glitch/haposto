package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.haposto.data.loyalty.LoyaltyRules
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.ui.components.LabeledValue
import java.time.ZoneId
import java.time.format.DateTimeFormatter

internal val LOYALTY_DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy").withZone(ZoneId.systemDefault())
internal val LOYALTY_TIME: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.systemDefault())

/** Le regole di una versione, come le vedono staff e clienti (T27). */
@Composable
internal fun RulesSummary(rules: LoyaltyRules, forCustomer: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        LabeledValue("Timbri per il premio", "${rules.stampsRequired}")
        LabeledValue("Condizione per il timbro", LoyaltyTexts.condition(rules.condition))
        LabeledValue("Giorno doppio", LoyaltyTexts.doubleDay(rules.doubleDay))
        LabeledValue("Premio", LoyaltyTexts.reward(rules.reward, forCustomer))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            LoyaltyTexts.rewardUse(rules.reward).forEach { line ->
                Text("• $line", style = MaterialTheme.typography.bodyMedium)
            }
            Text(
                "• I timbri si azzerano dopo ${rules.inactivityMonths} mesi senza visite",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

/** Numero con «−» e «+» a passi di [step] (grande e facile da toccare). */
@Composable
internal fun NumberStepper(
    value: Int,
    range: IntRange,
    onChange: (Int) -> Unit,
    format: (Int) -> String,
    step: Int = 1,
    enabled: Boolean = true,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        OutlinedButton(
            onClick = { onChange((value - step).coerceIn(range)) },
            enabled = enabled && value > range.first,
            modifier = Modifier.heightIn(min = 52.dp),
        ) { Text("−", style = MaterialTheme.typography.titleLarge) }
        Text(
            format(value),
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )
        OutlinedButton(
            onClick = { onChange((value + step).coerceIn(range)) },
            enabled = enabled && value < range.last,
            modifier = Modifier.heightIn(min = 52.dp),
        ) { Text("+", style = MaterialTheme.typography.titleLarge) }
    }
}

/** Una scelta fra più (pallino). */
@Composable
internal fun ChoiceRow(text: String, selected: Boolean, onSelect: () -> Unit, enabled: Boolean = true) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .selectable(selected = selected, enabled = enabled, role = Role.RadioButton, onClick = onSelect)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        RadioButton(selected = selected, onClick = null, enabled = enabled)
        Text(text, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.padding(start = 8.dp))
    }
}

/** Una voce da spuntare. */
@Composable
internal fun CheckRow(text: String, checked: Boolean, onChange: (Boolean) -> Unit, enabled: Boolean = true) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .toggleable(value = checked, enabled = enabled, role = Role.Checkbox, onValueChange = onChange)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Checkbox(checked = checked, onCheckedChange = null, enabled = enabled)
        Text(text, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.padding(start = 8.dp))
    }
}

/** Testo e interruttore sulla stessa riga. */
@Composable
internal fun SwitchRow(text: String, checked: Boolean, onChange: (Boolean) -> Unit, enabled: Boolean = true) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(text, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChange, enabled = enabled)
    }
}
