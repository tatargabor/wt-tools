## REMOVED Requirements

### Requirement: Memory count guard
**Reason**: The code does not implement this guard, and it is unnecessary — an empty recall result is harmless and correct behavior. Removing the requirement to match code reality.
**Migration**: No action needed. Recall executes on every prompt regardless of memory count.
