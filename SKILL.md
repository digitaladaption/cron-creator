---
name: cron-creator
description: "Create Clawdbot cron jobs from natural language. Use when: users want to schedule recurring messages, reminders, or check-ins without using terminal commands. Examples: 'Create a daily reminder at 8am', 'Set up a weekly check-in on Mondays', 'Remind me to drink water every 2 hours'."
---

# Cron Creator

Create Clawdbot cron jobs automatically from natural language requests.

## Trigger Patterns

This skill activates when users ask to create cron jobs:
- "Create a cron job for..."
- "Set up a reminder..."
- "Schedule a..."
- "Remind me to..."
- "Create a daily/weekly check-in..."
- "Add a recurring..."

## Workflow

1. **Parse the request** - Extract: time, frequency, channel, message, destination
2. **Generate command** - Build appropriate `clawdbot cron add` command
3. **Execute** - Run the command via exec tool
4. **Confirm** - Report success/failure with job details

## Parsing Rules

### Time Extraction
| Input | Cron Expression |
|-------|-----------------|
| "8am" | `0 8 * * *` |
| "8:45am" | `45 8 * * *` |
| "9pm" | `0 21 * * *` |
| "9:30pm" | `30 21 * * *` |
| "noon" | `0 12 * * *` |
| "midnight" | `0 0 * * *` |

### Frequency Extraction
| Input | Cron Expression |
|-------|-----------------|
| "daily" | `* * * * *` (with time) |
| "every day" | `* * * * *` (with time) |
| "weekdays" | `0 9 * * 1-5` |
| "mondays" | `0 9 * * 1` |
| "weekly" | `0 9 * * 0` (Sunday) or infer day |
| "monthly" | `0 9 1 * *` |
| "every hour" | `0 * * * *` |
| "every 30 minutes" | `*/30 * * * *` |
| "every 2 hours" | `0 */2 * * *` |

### Channel Detection
| Input | Channel |
|-------|---------|
| "whatsapp" | whatsapp |
| "on whatsapp" | whatsapp |
| "telegram" | telegram |
| "on telegram" | telegram |
| "slack" | slack |
| "discord" | discord |
| Default | whatsapp (use user's known number) |

### Destination Extraction
- Look for phone numbers (E.164 format)
- Look for channel identifiers (#channel, @username)
- Use known user contact if available
- Default to user's primary WhatsApp

## Default Messages

If no message provided, use appropriate defaults:

| Type | Default Message |
|------|-----------------|
| Daily check-in | "🌅 Good morning! Time for your daily check-in. How are you feeling?" |
| Evening | "🌙 Evening check-in! How was your day?" |
| Reminder | "⏰ Reminder: [inferred topic]" |
| Health | "💧 Time to drink water and stretch! Stay healthy!" |
| Learning | "📚 Learning time! What did you learn today?" |
| Weekly | "📊 Weekly check-in! Review your goals and set intentions." |

## Command Generation

Build the `clawdbot cron add` command:

```bash
clawdbot cron add \
  --name="[NAME]" \
  --cron="[EXPRESSION]" \
  --message="[MESSAGE]" \
  --channel=[CHANNEL] \
  --to=[DESTINATION] \
  --agent=main
```

### Name Generation
- Use descriptive name based on purpose
- Include frequency if helpful
- Examples: "Daily Morning Check-in", "Weekly Ikigai Review"

## Execution

Execute the command using exec tool with `host: "gateway"` to run on the Clawdbot server.

## Confirmation

Report success with:
- Job name
- Schedule
- Channel and destination
- Message preview
- Next run time

## Examples

### Example 1: "Create a daily reminder at 8:45am for Ikigai journaling"
```
1. Extract: time=8:45am, frequency=daily, purpose=Ikigai journaling
2. Generate cron: "45 8 * * *"
3. Build command:
   clawdbot cron add \
     --name="Ikigai Morning Journal" \
     --cron="45 8 * * *" \
     --message="🌅 Ikigai Morning Journal\n\n1. Purpose - What gives you energy today?\n2. Food - Hara Hachi Bu goal?\n3. Movement - One move today?" \
     --channel=whatsapp \
     --to=+447751115542 \
     --agent=main
4. Execute via exec
5. Confirm: "✅ Created 'Ikigai Morning Journal' - runs daily at 8:45am on WhatsApp"
```

### Example 2: "Remind me to drink water every 2 hours"
```
1. Extract: frequency=every 2 hours, purpose=drink water
2. Generate cron: "0 */2 * * *"
3. Build command:
   clawdbot cron add \
     --name="Water Reminder" \
     --cron="0 */2 * * *" \
     --message="💧 Time to drink water! Stay hydrated! 🚰" \
     --channel=whatsapp \
     --to=+447751115542 \
     --agent=main
4. Execute
5. Confirm: "✅ Created 'Water Reminder' - runs every 2 hours on WhatsApp"
```

### Example 3: "Set up a weekly check-in on Mondays at 9am"
```
1. Extract: time=9am, frequency=Mondays, purpose=weekly check-in
2. Generate cron: "0 9 * * 1"
3. Build command:
   clawdbot cron add \
     --name="Weekly Check-in" \
     --cron="0 9 * * 1" \
     --message="📊 Weekly Check-in\n\n1. What went well this week?\n2. What could improve?\n3. Goal for next week?" \
     --channel=whatsapp \
     --to=+447751115542 \
     --agent=main
4. Execute
5. Confirm: "✅ Created 'Weekly Check-in' - runs every Monday at 9am on WhatsApp"
```

## Error Handling

### Invalid time format
Ask for clarification: "What time should this run? (e.g., 8am, 9:30pm, noon)"

### Invalid frequency
Ask for clarification: "How often? (e.g., daily, weekly, every hour, weekdays)"

### Missing channel
Default to WhatsApp, confirm: "Should this go to WhatsApp?"

### Execution failed
- Check clawdbot is running: `clawdbot status`
- Check gateway connectivity
- Report specific error and suggest manual fallback

## Special Cases

### One-time reminders
If user says "remind me in 20 minutes" or "at 3pm tomorrow":
- Use `--at="+20m"` or `--at="15:00"` instead of `--cron`
- Add `--delete-after-run` flag

### Complex schedules
For complex requests like "first Monday of every month":
- Use appropriate cron: `0 9 1-7 * 1` (first Monday)
- Explain the schedule to user

### With options
If user specifies thinking mode, model, etc.:
- Add `--thinking=[level]` if requested
- Add `--model=[model]` if requested
- Add `--best-effort-deliver` if requested

## Implementation

This skill uses the `exec` tool to run commands on the gateway:

```json
{
  "command": "clawdbot cron add",
  "args": ["--name=...", "--cron=...", ...],
  "host": "gateway"
}
```

Ensure exec tool has proper permissions to run clawdbot commands.
