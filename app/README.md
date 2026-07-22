# Wallbizz — Flutter Client

Flutter web PWA + Android app for the Wallbizz wallpaper platform.

## Run

```bash
cp .env.example .env  # fill in SUPABASE_URL, SUPABASE_ANON_KEY, BACKEND_URL
flutter pub get
flutter run -d chrome
```

## Test

```bash
flutter test        # 162 tests
flutter analyze     # zero issues
```

## Build

```bash
flutter build web --release  # outputs to build/web/
```

## Structure

```
lib/
├── main.dart                # Entry: dotenv → Hive → Supabase → pure black splash
├── config/                  # backend_config, supabase_config, theme_config
├── models/                  # Wallpaper, DownloadedWallpaper, Moodboard
├── services/                # supabase_service, wallpaper_actions, wallhaven_search,
│                            # download_service, downloads_service, moodboard_service
├── screens/                 # home, search, detail, wishlist, downloads, settings,
│                            # splash, wallpaper_editor, verify_email, forgot_password
├── widgets/                 # staggered_grid, wallpaper_card, category_tabs, specs_card,
│                            # auth_bottom_sheet, add_to_moodboard_sheet, moodboard_picker,
│                            # gesture_hint_overlay, network_image, dynamic_theme
└── utils/                   # color_utils, share_utils
```
