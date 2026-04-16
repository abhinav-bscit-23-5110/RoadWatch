════════════════════════════════════════════════════════════════════════
  DARK MODE ENHANCEMENTS - IMPLEMENTATION GUIDE
════════════════════════════════════════════════════════════════════════

This guide explains the premium dark mode features and how to use them.

════════════════════════════════════════════════════════════════════════
🎨 USING GLASSMORPHIC CARDS
════════════════════════════════════════════════════════════════════════

Import:
```dart
import 'package:roadwatch/widgets/glass_card.dart';
```

Basic Usage:
```dart
GlassCard(
  padding: const EdgeInsets.all(16),
  borderRadius: 16,
  blur: 12.0,
  child: Column(
    children: [
      Text('Your content here'),
      // ... more widgets
    ],
  ),
)
```

With Gradient (Dashboard Stats):
```dart
GlassCardGradient(
  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
  blur: 14.0,
  child: Row(
    children: [
      _buildStatItem('12', 'Reports', Icons.assessment_outlined),
      _buildStatItem('8', 'Verified', Icons.verified_user_outlined),
      _buildStatItem('47', 'Upvotes', Icons.thumb_up_outlined),
    ],
  ),
)
```

Interactive (With Tap):
```dart
GlassCard(
  onTap: () => Navigator.push(context, slideFromRightRoute(MyScreen())),
  child: ListTile(
    title: Text('Tap me'),
    subtitle: Text('I have glass effect'),
  ),
)
```

Properties:
  - borderRadius:    Corner radius (default: 16.0)
  - padding:         Inner padding (default: 16.0 all sides)
  - margin:          Outer margin (default: 0)
  - onTap:           Optional tap callback
  - blur:            Backdrop blur sigma (default: 12.0)
  - backgroundColor: Override glass color
  - borderColor:     Override border color

════════════════════════════════════════════════════════════════════════
🌙 ACCESSING THEME COLORS
════════════════════════════════════════════════════════════════════════

Recommended: Use Theme.of(context)
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

Color textColor = isDark 
    ? AppTheme.darkTextPrimary 
    : AppTheme.lightTextPrimary;
```

Or directly:
```dart
import 'package:roadwatch/theme/app_theme.dart';

// Dark theme colors
AppTheme.darkBackground      // #0F172A
AppTheme.darkSurface         // #1E293B
AppTheme.darkCardBg          // #243044
AppTheme.darkTextPrimary     // #EAEDEF (92% white)
AppTheme.darkTextSecondary   // #B8C1CC (70% white)
AppTheme.darkTextTertiary    // #8B95A5 (55% white)
AppTheme.darkAccentBlue      // #60A5FA
AppTheme.darkAccentPurple    // #A78BFA
AppTheme.darkAccentCyan      // #22D3EE

// Light theme colors
AppTheme.lightBackground     // #F8F9FA
AppTheme.lightSurface        // #FFFFFF
AppTheme.lightTextPrimary    // #202124
```

════════════════════════════════════════════════════════════════════════
📍 APPLYING GOOGLE MAPS DARK STYLE
════════════════════════════════════════════════════════════════════════

In your maps widget:
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roadwatch/services/google_maps_style.dart';

late GoogleMapController _mapController;

@override
Widget build(BuildContext context) {
  return GoogleMap(
    onMapCreated: (GoogleMapController controller) {
      _mapController = controller;
      _applyMapStyle();
    },
    // ... other properties
  );
}

Future<void> _applyMapStyle() async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final style = getGoogleMapsStyle(isDark);
  await _mapController.setMapStyle(style);
}
```

Or listen to theme changes:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (mounted) {
    _applyMapStyle();
  }
}
```

════════════════════════════════════════════════════════════════════════
🎭 SMOOTH THEME TRANSITIONS
════════════════════════════════════════════════════════════════════════

Theme switching happens automatically in Profile → Appearance.

To test:
  1. Open app in Chrome
  2. Go to Profile screen (bottom nav)
  3. Tap Appearance section
  4. Click Light / Dark / System buttons
  5. Observe smooth 300ms color transition

Behind the scenes:
```dart
// lib/main.dart - AnimatedTheme wrapper
Widget _buildAnimatedApp(bool isDarkMode) {
  return AnimatedTheme(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    data: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
    child: MaterialApp(
      // ... rest of app
    ),
  );
}
```

════════════════════════════════════════════════════════════════════════
🎨 CREATING NEW GLASS CARDS
════════════════════════════════════════════════════════════════════════

Example: Custom report card
```dart
GlassCard(
  borderRadius: AppTheme.borderRadius16,
  padding: const EdgeInsets.all(14),
  margin: const EdgeInsets.symmetric(vertical: 8),
  blur: 12.0,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              report['title'],
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Text(
              report['status'],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      // Details
      Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 16,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              report['location'],
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  ),
)
```

════════════════════════════════════════════════════════════════════════
🎯 BEST PRACTICES
════════════════════════════════════════════════════════════════════════

✅ DO:
  • Use Theme.of(context) for adaptive colors
  • Apply GlassCard to dashboards and lists
  • Keep glass cards visible and readable
  • Test in both light and dark modes
  • Use AppTheme constants for consistency
  • Blur values between 12-16
  • Opacity between 0.06-0.10

❌ DON'T:
  • Hardcode colors in widgets
  • Use GlassCard for forms/inputs
  • Blur the entire screen
  • Use glass effect on primary CTAs
  • Make glass cards transparent
  • Skip testing theme switching
  • Use very high blur values (>20)

════════════════════════════════════════════════════════════════════════
📊 COLOR PALETTE REFERENCE
════════════════════════════════════════════════════════════════════════

LIGHT THEME:
  Background:     #F8F9FA (light gray)
  Surface:        #FFFFFF (white)
  Card:           #FAFAFA (off-white)
  Text Primary:   #202124 (dark gray)
  Text Secondary: #5F6368 (medium gray)
  Text Tertiary:  #9AA0A6 (light gray)
  Divider:        #E8EAED (very light gray)

DARK THEME (PREMIUM):
  Background:     #0F172A (deep navy) ← Dominant color
  Surface:        #1E293B (muted slate)
  Card/Elevated:  #243044 (bright slate) ← Glass card base
  Text Primary:   #EAEDEF (92% white)
  Text Secondary: #B8C1CC (70% white)
  Text Tertiary:  #8B95A5 (55% white)
  Divider:        #334155 (subtle)

ACCENT COLORS:
  Primary Blue:   #1A73E8 (action buttons)
  Soft Blue:      #60A5FA (premium accent)
  Purple:         #A78BFA (elevation highlights)
  Cyan:           #22D3EE (interactive elements)

SEMANTIC:
  Success Green:  #34A853
  Warning Red:    #EA4335
  Info Blue:      #1A73E8

════════════════════════════════════════════════════════════════════════
🔧 DEBUGGING
════════════════════════════════════════════════════════════════════════

No glass effect showing?
  → Check BorderRadius isn't set to 0
  → Verify blur value > 5
  → Ensure child widgets fit in container

Dark colors not applying?
  → Check Theme.of(context).brightness
  → Verify AppTheme.darkTheme is set
  → Check if color is being overridden locally

Theme transitions stuttering?
  → Check for expensive widgets in build
  → Verify no setState in Consumer builder
  → Profile with DevTools

Map style not applying?
  → Ensure GoogleMapController is initialized
  → Call setMapStyle in onMapCreated
  → Check isDark matches actual theme

════════════════════════════════════════════════════════════════════════
📦 FILE STRUCTURE
════════════════════════════════════════════════════════════════════════

lib/
├── theme/
│   ├── app_theme.dart              ← Theme definitions + glass colors
│   └── theme_provider.dart         ← Theme state management
├── widgets/
│   └── glass_card.dart             ← Glass effect component
├── services/
│   └── google_maps_style.dart      ← Dark map style JSON
├── home_screen.dart                ← Uses GlassCardGradient
├── reports_screen.dart             ← Uses GlassCard
├── alerts_screen.dart              ← Uses GlassCard
└── main.dart                       ← AnimatedTheme wrapper

════════════════════════════════════════════════════════════════════════

Questions? Check the source files - all code is well-commented! 💙

════════════════════════════════════════════════════════════════════════
