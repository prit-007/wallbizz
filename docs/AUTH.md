# Authentication Model

## Principle

**No auth for browsing. Auth only for wishlisting.**

Users can browse, view details, and download wallpapers as guests. Authentication is only triggered when a user taps the heart icon to save a wallpaper.

## Auth Providers

| Provider | When Used | Flow |
|----------|-----------|------|
| Google OAuth | "Continue with Google" button | Opens browser -> Google consent -> callback |
| Email/Password | "Sign in with Email" section | signInWithPassword() / signUp() -> instant |

Both managed by `supabase_flutter` SDK.

## Heart Tap Flow

```
Guest taps heart icon
    |
    v
auth.currentUser == null?
    |
    +-- YES --> Store pending Wallpaper object
    |           Show AuthBottomSheet
    |           |
    |           +--> "Continue with Google"
    |           |    signInWithOAuth(OProvider.google)
    |           |
    |           +--> Email + Password
    |                signInWithPassword() / signUp()
    |                |
    |                v
    |           AuthState.signedIn fires
    |           --> WallpaperActions.onAuthSuccess()
    |           --> INSERT INTO wishlists (user_id, wallpaper_id)
    |           --> Heart fills in
    |
    +-- NO --> Check isInWishlist?
              |
              +-- YES --> REMOVE from wishlists
              +-- NO --> INSERT into wishlists
```

## Pending Action Pattern

```dart
class WallpaperActions {
  static Wallpaper? _pendingWallpaper;   // Full object, not just ID
  static VoidCallback? _onPendingComplete;

  static void handleHeartTap(ctx, wallpaper, {onComplete}) {
    if (user == null) {
      _pendingWallpaper = wallpaper;     // Store full object
      _onPendingComplete = onComplete;
      showAuthBottomSheet(ctx);
      return;
    }
    _toggleWishlist(user.id, wallpaper, onComplete);
  }

  static void onAuthSuccess() {
    if (user != null && _pendingWallpaper != null) {
      _toggleWishlist(user.id, _pendingWallpaper!, _onPendingComplete);
      _pendingWallpaper = null;
    }
  }
}
```

## Auth Bottom Sheet

- **Header**: "Sign in to save wallpapers" + subtitle
- **Google button**: Full-width, white background, Google icon
- **Divider**: "or"
- **Email/Password fields**: Dark themed, rounded
- **Toggle**: "Sign In" <-> "Create Account"
- **Loading state**: Spinner while auth in progress

## Supabase Setup

### Enable Email/Password
1. Dashboard -> Authentication -> Providers
2. Enable **Email** provider

### Enable Google OAuth
1. [Google Cloud Console](https://console.cloud.google.com) -> Create OAuth 2.0 Client ID
2. Application type: Web application
3. Redirect URI: `https://{project}.supabase.co/auth/v1/callback`
4. Paste Client ID + Secret in Supabase Dashboard -> Authentication -> Providers -> Google

## Security

| Concern | Mitigation |
|---------|------------|
| Service Key exposure | Never in Flutter app, only in Golang backend |
| RLS enforcement | Wishlists scoped to `auth.uid()` |
| Token storage | Managed by supabase_flutter (secure device storage) |
| Google OAuth secrets | In Supabase dashboard, never in client code |
| Duplicate wishlists | `UNIQUE(user_id, wallpaper_id)` constraint |
