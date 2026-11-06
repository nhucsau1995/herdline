# Herdline - Design System

Herdline is an offline-first dairy herd management app for farm teams (Admin, Manager, Worker,
Veterinarian). Bright, calm, data-forward, built for use in the barn with one hand.

## Color (use ONLY these colors; no default violet or indigo, no flat neutral grey)

| Token | Hex | Use |
|---|---|---|
| background | #F4F7FC | page background (cool tinted near-white) |
| surface | #FFFFFF | cards, sheets, tab bar |
| surfaceAlt | #F4F7FC | grouped rows inside cards |
| accent | #2B7BFF | active tab, icons, large fills, big numerals |
| accentFill | #1B65DA | buttons and chips with WHITE labels, links |
| accentTint | #E3EEFF | selected chips, icon pills, badges (text #1B65DA on it) |
| accentPressed | #2262CA | pressed primary button |
| support | #4ADE80 | decoration, illustration accents |
| supportStrong | #1EAA52 | second chart series, positive trend lines |
| text.primary | #0C131F | headings, body |
| text.secondary | #4A5568 | secondary text |
| text.tertiary | #677283 | hints, metadata, placeholders |
| border | #DCE3EE | hairline dividers |
| borderStrong | #8B92B8 | input and control borders |
| success | #0E7C3A on #E3F4E9 | success chips (Pregnant, Confirmed) |
| warning | #A75906 on #FAEFE1 | warning chips (Withdrawal, Low stock, Due) |
| danger | #CE2020 on #FBE5E5 | errors and destructive actions only |
| info | #1B65DA on #E4EDFB | info chips (Milking, Inseminated) |

Hero gradient (any surface carrying white text): #1B65DA -> #2262CA, nothing lighter. A soft
#2B7BFF -> #4ADE80 blend may be used as decoration only, never behind text.

## Typography

- UI and body: Inter. Display, hero numbers and screen titles: Sora.
- display 32 / 700 / -0.02em (hero numbers, big titles)
- title 20 / 600 (section headers, card titles, app bar)
- body 16 / 400
- label 14 / 500 (buttons, tabs, chips)
- caption 13 / 500 (metadata, secondary color)
- Use only these 5 sizes. Minimum text 12px (13px chips and tags, 14px safety or legal text).

## Frame and layout

- 393x852 mobile frame. Keep the top ~59px (status bar) and bottom ~34px (home indicator) clear.
- 8pt spacing scale (4, 8, 12, 16, 24, 32), 20px screen edge padding, generous vertical rhythm.
- Radius: card 20, control 14, input 12, pill 999.
- Elevation: soft only, card = 0 1px 2px rgba(12,19,31,.04) + 0 8px 24px rgba(12,19,31,.06).
- One bold focal element per screen (a hero stat card, a big number, a hero photo or a chart).

## Icons

One set only: rounded outline (Lucide style), 24px, 1.75 stroke. Never mix outline and filled.

## Controls (one spec each, reused on every screen)

- Primary button: pill, #1B65DA background, white 14/500 label, 52px tall; pressed #2262CA; disabled 40% opacity.
- Secondary button: pill, white background, 1.5px #1B65DA border, #1B65DA label.
- Text input: 12px radius, white fill, 1px #8B92B8 border, label above in 13/500 #4A5568; focus = 2px #2B7BFF ring; error = #CE2020 border + 13px #CE2020 helper text below.
- Card: white, 20px radius, soft shadow, 16px padding.
- Chip: pill, 13/500. Neutral chip #E3EEFF with #1B65DA text. Status chips use the status pairs above.
- Floating action: pill primary button bottom-right above the tab bar, with a plus icon.

## Shared components

### Bottom tab bar (identical on every screen that shows navigation)

Flat white bar, 1px #DCE3EE top border, no gradient. Exactly these 5 tabs in this order:

1. Dashboard - layout-dashboard icon
2. Herd - list icon
3. Milk - droplet icon
4. Breeding - heart icon
5. Reports - bar-chart icon

Active tab: icon and 12px label in #2B7BFF with a small #E3EEFF pill behind the icon.
Inactive tabs: icon and label in #677283. Never rename, reorder, add or remove tabs.
Detail, form, modal and sign-in screens show NO tab bar.

### Top app bar

Screen title left in Sora 20/600 #0C131F. On Dashboard and Herd, a small chip on the right:
cloud-off icon + "Offline - saved on device" in 13/500 #1B65DA on #E3EEFF.
Detail screens: back arrow left, title, action icons right.

## Imagery

Real photography only: Holstein and Jersey dairy cows, bulls, barns, pastures, farm staff
portraits. Empty states and onboarding also use real photos or flat 2D vector art. NO 3D
renders, claymorphism, isometric, CGI or glossy plastic objects.

## Meaning of color

Red only for errors, destructive actions and truly urgent states. Non-urgent flags (withdrawal,
low stock, due soon) use the warning pair with an icon.

## Copy scope

Do not mention: Sync, Synced, Cloud backup, Push notification, Firebase, API, Marketplace,
Payment, Subscription, Login with Google. No invented integrations or diagnoses beyond the
brief. People names only from the brief: Lena Park (Manager), Tom Reyes (Worker),
Dr. Sam Okafor (Veterinarian), Priya Shah (Admin).
