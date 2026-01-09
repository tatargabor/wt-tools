# Proposal: Running Row Visual Effect

JIRA Key: EXAMPLE-568
Story: EXAMPLE-466

**Status: IMPLEMENTED** - Option A chosen, with 1s cycle

## Summary

Visually highlighted "running" status rows - with pulsing or animated background effect.

## Implemented Features

- **Running rows**: Green pulsing background (1s cycle, sine wave)
- **Compacting rows**: Purple background with ⟳ icon (context summarization)
- **Waiting rows**: Yellow background (blinking when needs attention)
- **Status colors**: Theme-dependent (light/dark/high_contrast)

## Options

### Option A: Opacity Pulse (Recommended)
Background color opacity pulsing 0.3 → 0.6 → 0.3 (2s cycle)

```
Row background: rgba(34, 197, 94, opacity)  // green
opacity animates: 0.3 → 0.6 → 0.3 (sine wave)
```

**Advantage:** Minimal resources, QPropertyAnimation, GPU accelerated
**Resources:** ~0.1% CPU

### Option B: Gradient Sweep
Left-to-right light sweep effect

```
Linear gradient position animates: -100% → 100%
```

**Advantage:** Eye-catching "scanning" effect
**Disadvantage:** Slightly more GPU usage

### Option C: Border Glow
Pulsing border/outline around the row

```
Border: 2px solid rgba(34, 197, 94, opacity)
Box-shadow pulse
```

**Advantage:** Doesn't modify the background
**Disadvantage:** QSS limitations

## Implementation (Option A)

```python
class PulseDelegate(QStyledItemDelegate):
    """Delegate that pulses background for running rows"""

    def __init__(self):
        self.opacity = 0.3
        self.timer = QTimer()
        self.timer.timeout.connect(self._update_opacity)
        self.timer.start(50)  # 20 FPS
        self.phase = 0

    def _update_opacity(self):
        self.phase = (self.phase + 0.05) % (2 * math.pi)
        self.opacity = 0.3 + 0.15 * (1 + math.sin(self.phase))

    def paint(self, painter, option, index):
        if index.data(Qt.UserRole) == "running":
            painter.fillRect(option.rect,
                QColor(34, 197, 94, int(self.opacity * 255)))
        super().paint(painter, option, index)
```

## Alternative: CSS Animation (simpler)

```python
# In refresh, toggle class every 500ms
if status == "running":
    row.setProperty("pulse", self.pulse_state)
    self.pulse_state = not self.pulse_state

# QSS
QTableWidget::item[pulse="true"] {
    background: rgba(34, 197, 94, 0.4);
}
QTableWidget::item[pulse="false"] {
    background: rgba(34, 197, 94, 0.2);
}
```

## Config

```json
{
  "control_center": {
    "running_row_effect": "pulse",  // "pulse", "none"
    "pulse_speed_ms": 2000
  }
}
```

## Effort

- ~50 LOC
- Option A: QPropertyAnimation + custom delegate
- Option CSS: simpler, but less smooth
