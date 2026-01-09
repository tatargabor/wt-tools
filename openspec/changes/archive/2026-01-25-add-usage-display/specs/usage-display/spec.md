# Usage Display

## ADDED Requirements

### Requirement: Display Claude Capacity Statistics
The Control Center GUI SHALL display Claude Code capacity statistics via progress bars.

#### Scenario: Capacity displayed via progress bars
Given the Control Center is running
And usage data is available from Claude Settings API
When the GUI refreshes
Then it displays 5h block capacity as a progress bar with percentage
And it displays weekly capacity as a progress bar with percentage

#### Scenario: Capacity color coding
Given usage data is available
When capacity is below 70%
Then the progress bar is displayed in green
When capacity is between 70% and 90%
Then the progress bar is displayed in yellow
When capacity is above 90%
Then the progress bar is displayed in red

#### Scenario: Graceful fallback when data unavailable
Given usage data cannot be fetched
When the GUI attempts to display capacity
Then it displays "N/A"
And does not show errors to the user

### Requirement: Background Usage Data Fetching
Usage data SHALL be fetched periodically in a background thread to avoid blocking the UI.

#### Scenario: Periodic data refresh
Given the Control Center is running
When 30 seconds have elapsed since the last fetch
Then the usage worker fetches fresh data
And updates the progress bars

### Requirement: Subscription-Based Limits
Usage limits SHALL be based on the subscription capacity, not USD cost.

#### Scenario: 5h block limit
Given the user has a Claude Max subscription
When the 5h block capacity is measured
Then it reflects the rolling 5-hour window usage
And can be used by Ralph loop for capacity limiting

#### Scenario: Weekly limit
Given the user has a Claude Max subscription
When the weekly capacity is measured
Then it reflects the current week's total usage
