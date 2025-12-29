# Charlotte's Web - Community App

Komunitni aplikace pro Spiderbagzz s Reddit-style feedem, E2EE chatem a pokrocilou gamifikaci.

---

## Obsah

- [Funkce](#funkce)
- [Tech Stack](#tech-stack)
- [Architektura](#architektura)
- [Struktura projektu](#struktura-projektu)
- [Instalace](#instalace)
- [Konfigurace](#konfigurace)
- [Databaze](#databaze)
- [API Reference](#api-reference)
- [Widgety](#widgety)
- [TODO](#todo)

---

## Funkce

### Feed System
| Funkce | Popis |
|--------|-------|
| Thread Types | 3 typy prispevku: Discussion, Question, Announcement |
| Webs | Pavoici vlakna misto lajku - unikatni reputacni system |
| Comments | Vnorene komentare s odpoveďmi |
| Bookmarks | Ukladani prispevku do zalozek |
| Tags | Hashtagy pro kategorizaci (#tag) |
| Filters | Filtrovani podle typu, casu, popularity |
| Search | Fulltext vyhledavani v prispevkach |

### Chat System
| Funkce | Popis |
|--------|-------|
| E2EE | End-to-end sifrovani (X25519 + AES-256-GCM) |
| Voice Messages | Nahravani a prehravani hlasovych zprav |
| GIF Picker | Integrace s Giphy API |
| Emoji Picker | 9 kategorii emoji |
| Offline Queue | Fronta zprav pro offline rezim |
| Realtime | Supabase Realtime pro okamzite doruceni |

### Gamifikace System
| Funkce | Popis |
|--------|-------|
| **Spider Ranks** | XP system s 6 urovnemi |
| **Strain Cards** | Sberatelske karty (4 rarity) |
| **Daily Quests** | Denni ukoly za XP |
| **Badges** | Odznaky s raritami a animacemi |
| **Leaderboard** | Zebricek hracu |
| **Webs** | Pavoici vlakna - reputacni system misto lajku |

#### Spider Ranks (XP System)
```
Vajicko       →  0 - 100 XP
Maly krizak   →  100 - 500 XP
Lovec         →  500 - 2,000 XP
Tkadlec       →  2,000 - 5,000 XP
Vdova         →  5,000 - 15,000 XP
Spider Master →  15,000+ XP
```

#### Card Rarities
```
Common   → Seda barva, zakladni karty
Rare     → Modra barva, vzacnejsi karty
Exotic   → Fialova barva, exoticke karty
Legend   → Zlata barva, legendy s animaci
```

#### Webs (Pavoici vlakna)
```
Kazdy prispevek muze ziskat "webs" - pavoici vlakna
Vice webs = vetsi reputace = vyssi hodnoceni prispevku
Webs se zobrazuji jako animovana pavoici sit
```

### Profil System
| Widget | Popis |
|--------|-------|
| **GlitchAvatar** | Avatar s glitch efekty (7 stylu) |
| **ProfileBanner** | Profilove pozadi (5 stylu) |
| **ProfileBio** | Bio s #hashtag, @mention, URL parsing |
| **ReputationBadge** | Vizualizace webs - pavoici vlakna |
| **FollowButton** | Animovane tlacitko sledovani |
| **FollowersList** | Modal se seznamem sledujicich |

#### GlitchAvatar Styles
```dart
enum GlitchStyle {
  none,    // Zadny efekt
  subtle,  // Jemny glitch
  classic, // Klasicky RGB split
  neon,    // Neonovy okraj (pro adminy)
  web,     // Pavoici sit
  pulse,   // Pulzujici efekt
  fire,    // Ohne (pro Spider Master)
}
```

#### ProfileBanner Styles
```dart
enum BannerStyle {
  simple,          // Jednobarevny
  gradient,        // Gradient
  parallax,        // Parallax efekt
  blur,            // Rozmazany obrazek
  animatedGradient // Animovany gradient
}
```

### Privacy System
| Funkce | Popis |
|--------|-------|
| **Anonymni mod** | Skryti profilu z vyhledavani |
| **Ghost Mode** | Skryti polohy u fotek |
| **Burner Account** | Kompletni smazani vsech dat |

### Admin Panel
| Funkce | Popis |
|--------|-------|
| Dashboard | Statistiky a prehledy |
| User Management | Sprava uzivatelu, bany, role |
| Post Management | Mazani a editace prispevku |

---

## Tech Stack

### Frontend
| Technologie | Verze | Pouziti |
|-------------|-------|---------|
| Flutter | 3.x | UI framework |
| Dart | 3.x | Programovaci jazyk |
| Material 3 | - | Design system |

### State Management
| Technologie | Verze | Pouziti |
|-------------|-------|---------|
| flutter_riverpod | ^3.1.0 | State management |
| go_router | ^17.0.1 | Navigace |

### Backend (Supabase)
| Sluzba | Pouziti |
|--------|---------|
| Auth | Autentizace uzivatelu |
| PostgreSQL | Databaze |
| Storage | Ukladani souboru (avatary, obrazky) |
| Realtime | Real-time subscriptions |

### Sifrovani
| Technologie | Pouziti |
|-------------|---------|
| cryptography | X25519 key exchange, AES-256-GCM |
| flutter_secure_storage | Bezpecne ukladani klicu |

### Media & Files
| Technologie | Pouziti |
|-------------|---------|
| image_picker | Vyber obrazku |
| record | Nahravani hlasu |
| audioplayers | Prehravani audia |
| file_picker | Vyber souboru |
| cached_network_image | Cachovani obrazku |

### Ostatni
| Technologie | Pouziti |
|-------------|---------|
| geolocator | Lokace |
| url_launcher | Otevirani URL |
| http | HTTP requesty (Giphy) |
| connectivity_plus | Detekce pripojeni |
| shared_preferences | Lokalni nastaveni |
| intl | Internacionalizace |
| timeago | Casove udaje |
| google_fonts | Fonty |

---

## Architektura

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ Screens │  │ Widgets │  │ Dialogs │  │ Modals  │        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       └────────────┴────────────┴────────────┘              │
│                           │                                 │
│                           ▼                                 │
├─────────────────────────────────────────────────────────────┤
│                    State Layer (Riverpod)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Providers  │  │   Notifiers  │  │  Controllers │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         └─────────────────┴─────────────────┘               │
│                           │                                 │
│                           ▼                                 │
├─────────────────────────────────────────────────────────────┤
│                     Service Layer                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Auth   │  │  Posts  │  │  Chat   │  │ Profile │        │
│  │ Service │  │ Service │  │ Service │  │ Service │        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       └────────────┴────────────┴────────────┘              │
│                           │                                 │
│                           ▼                                 │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                     Supabase                          │  │
│  │  ┌──────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐   │  │
│  │  │ Auth │  │ Database │  │ Storage │  │ Realtime │   │  │
│  │  └──────┘  └──────────┘  └─────────┘  └──────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Struktura projektu

```
lib/
├── app.dart                      # Hlavni aplikacni widget
├── main.dart                     # Entry point
│
├── config/
│   ├── api_config.dart           # API klice a URL
│   └── app_router.dart           # GoRouter konfigurace
│
├── models/                       # Datove modely (15)
│   ├── badge_model.dart          # Model odznaku
│   ├── category_model.dart       # Kategorie prispevku
│   ├── comment_model.dart        # Komentare
│   ├── conversation_model.dart   # Chat konverzace
│   ├── daily_quest_model.dart    # Denni ukoly
│   ├── notification_model.dart   # Notifikace
│   ├── poll_model.dart           # Ankety
│   ├── post_model.dart           # Prispevky
│   ├── rank_model.dart           # Spider ranky
│   ├── reaction_model.dart       # Reakce (webs)
│   ├── strain_card_model.dart    # Sberatelske karty
│   ├── tag_model.dart            # Tagy
│   ├── thread_type_model.dart    # Typy vlaken
│   ├── user_model.dart           # Uzivatel
│   └── user_settings_model.dart  # Nastaveni uzivatele
│
├── providers/                    # Riverpod providers (15)
│   ├── auth_provider.dart        # Autentizace
│   ├── badge_provider.dart       # Odznaky
│   ├── bookmark_provider.dart    # Zalozky
│   ├── category_provider.dart    # Kategorie
│   ├── chat_provider.dart        # Chat
│   ├── follow_provider.dart      # Sledovani
│   ├── gamification_provider.dart # Gamifikace
│   ├── notification_provider.dart # Notifikace
│   ├── offline_queue_provider.dart # Offline fronta
│   ├── posts_provider.dart       # Prispevky
│   ├── profile_provider.dart     # Profil
│   ├── search_provider.dart      # Vyhledavani
│   ├── settings_provider.dart    # Nastaveni
│   ├── thread_type_provider.dart # Thread typy
│   └── user_provider.dart        # Uzivatel
│
├── screens/                      # Obrazovky (40 souboru)
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── post_management_screen.dart
│   │   └── user_management_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── chat/
│   │   ├── chat_screen.dart
│   │   └── widgets/              # Chat widgety
│   ├── feed/
│   │   ├── create_post_screen.dart
│   │   ├── feed_screen.dart
│   │   └── post_detail_screen.dart
│   ├── gamification/
│   │   ├── badges_screen.dart
│   │   ├── cards_screen.dart
│   │   ├── gamification_screen.dart
│   │   └── leaderboard_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   ├── profile/
│   │   ├── edit_profile_screen.dart
│   │   ├── profile_screen.dart
│   │   └── user_profile_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
├── services/                     # Business logika (21)
│   ├── admin_service.dart        # Admin operace
│   ├── auth_service.dart         # Autentizace
│   ├── badge_service.dart        # Odznaky
│   ├── bookmark_service.dart     # Zalozky
│   ├── category_service.dart     # Kategorie
│   ├── chat_service.dart         # Chat operace
│   ├── comment_service.dart      # Komentare
│   ├── encryption_service.dart   # E2EE sifrovani
│   ├── follow_service.dart       # Sledovani
│   ├── gamification_service.dart # XP, ranky, questy
│   ├── notification_service.dart # Notifikace
│   ├── offline_queue_service.dart # Offline operace
│   ├── post_service.dart         # CRUD prispevku
│   ├── profile_service.dart      # Profil operace
│   ├── reaction_service.dart     # Webs (reakce)
│   ├── search_service.dart       # Vyhledavani
│   ├── settings_service.dart     # Nastaveni
│   ├── storage_service.dart      # File storage
│   ├── tag_service.dart          # Tagy
│   ├── thread_type_service.dart  # Thread typy
│   └── voice_service.dart        # Hlasove zpravy
│
├── theme/
│   ├── app_colors.dart           # Barevna paleta
│   ├── app_theme.dart            # ThemeData
│   └── theme.dart                # Barrel export
│
└── widgets/                      # Znovupouzitelne widgety (54)
    ├── feed/                     # Feed widgety (8)
    │   ├── active_filters_bar.dart
    │   ├── empty_feed_state.dart
    │   ├── feed.dart
    │   ├── feed_error_state.dart
    │   ├── feed_fab.dart
    │   ├── posts_list_view.dart
    │   ├── thread_type_chip.dart
    │   └── thread_type_tabs.dart
    │
    ├── gamification/             # Gamifikace widgety (16)
    │   ├── badges/
    │   │   ├── badge_detail_dialog.dart
    │   │   ├── badge_grid.dart
    │   │   ├── badge_item.dart
    │   │   ├── badge_showcase.dart
    │   │   └── badges.dart
    │   ├── cards/
    │   │   ├── card_grid_item.dart
    │   │   ├── cards.dart
    │   │   ├── collection_stats_bar.dart
    │   │   └── empty_cards_state.dart
    │   ├── leaderboard/
    │   │   ├── leaderboard.dart
    │   │   ├── leaderboard_header.dart
    │   │   ├── leaderboard_item.dart
    │   │   ├── leaderboard_list.dart
    │   │   └── position_badge.dart
    │   ├── daily_quest_widget.dart
    │   ├── gamification.dart
    │   ├── rank_badge_widget.dart
    │   ├── strain_card_widget.dart
    │   └── web_avatar_widget.dart
    │
    ├── home/                     # Home widgety (5)
    │   ├── home.dart
    │   ├── home_app_bar.dart
    │   ├── home_bottom_nav.dart
    │   ├── search_bar_button.dart
    │   └── search_sheet.dart
    │
    ├── post_detail/              # Post detail widgety (3)
    │   ├── comment_input.dart
    │   ├── comments_section.dart
    │   └── post_detail.dart
    │
    ├── profile/                  # Profil widgety (15)
    │   ├── bookmarks_sheet.dart
    │   ├── follow_button.dart
    │   ├── followers_list.dart
    │   ├── glitch_avatar.dart
    │   ├── logout_dialog.dart
    │   ├── notification_badge.dart
    │   ├── privacy_settings.dart
    │   ├── profile.dart
    │   ├── profile_avatar.dart
    │   ├── profile_banner.dart
    │   ├── profile_bio.dart
    │   ├── profile_menu_card.dart
    │   ├── profile_stats_row.dart
    │   ├── reputation_badge.dart
    │   └── role_badge.dart
    │
    ├── comment_widget.dart
    ├── filter_sidebar.dart
    ├── post_card.dart
    ├── reaction_bar.dart
    └── user_avatar.dart

supabase/
└── migrations/                   # SQL migrace
    ├── add_profile_columns.sql
    ├── create_avatars_bucket.sql
    ├── create_badges.sql
    └── create_follows_table.sql
```

---

## Instalace

### Pozadavky
- Flutter 3.x
- Dart 3.x
- Xcode (pro iOS)
- Android Studio (pro Android)
- Supabase ucet

### Kroky

```bash
# 1. Klonovani repozitare
git clone <repo-url>
cd community_app

# 2. Instalace zavislosti
flutter pub get

# 3. iOS setup
cd ios && pod install && cd ..

# 4. Konfigurace environment (viz sekce Konfigurace)

# 5. Spusteni
flutter run
```

### Build pro produkci

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

---

## Konfigurace

### Environment Variables

Vytvorte soubor `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String giphyApiKey = 'YOUR_GIPHY_API_KEY';
}
```

### Supabase Setup

1. Vytvorte novy projekt na [supabase.com](https://supabase.com)
2. Zkopirujte URL a anon key
3. Povolte Email auth v Authentication settings
4. Spustte SQL migrace (viz sekce Databaze)

---

## Databaze

### Tabulky

| Tabulka | Popis |
|---------|-------|
| `profiles` | Uzivatelske profily |
| `posts` | Prispevky |
| `comments` | Komentare |
| `reactions` | Webs (pavoici vlakna) na prispevky |
| `bookmarks` | Zalozky |
| `follows` | Sledovani uzivatelu |
| `conversations` | Chat konverzace |
| `messages` | Chat zpravy |
| `badges` | Definice odznaku |
| `user_badges` | Odznaky uzivatelu |
| `strain_cards` | Definice karet |
| `user_cards` | Karty uzivatelu |
| `notifications` | Notifikace |

### Migrace

Spustte v Supabase SQL Editoru v tomto poradi:

```bash
1. supabase/migrations/add_profile_columns.sql
2. supabase/migrations/create_avatars_bucket.sql
3. supabase/migrations/create_badges.sql
4. supabase/migrations/create_follows_table.sql
```

### Storage Buckets

| Bucket | Popis | Public |
|--------|-------|--------|
| `avatars` | Profilove fotky | Ano |
| `posts` | Obrazky prispevku | Ano |
| `voice` | Hlasove zpravy | Ne |

---

## API Reference

### Auth Provider

```dart
// Aktualni uzivatel
final user = ref.watch(currentUserProvider);

// Je admin?
final isAdmin = ref.watch(isAdminProvider);

// Prihlaseni
await ref.read(authServiceProvider).signIn(email, password);

// Registrace
await ref.read(authServiceProvider).signUp(email, password, username);

// Odhlaseni
await ref.read(authServiceProvider).signOut();
```

### Posts Provider

```dart
// Seznam prispevku
final posts = ref.watch(postsProvider);

// Vytvoreni prispevku
await ref.read(postServiceProvider).createPost(
  content: 'Text',
  threadType: ThreadType.discussion,
);

// Webs (pavoici vlakna)
await ref.read(reactionServiceProvider).toggleWeb(postId);
```

### Profile Provider

```dart
// Statistiky profilu
final stats = ref.watch(profileStatsProvider(userId));

// Aktualizace profilu
await ref.read(profileNotifierProvider.notifier).updateProfile(
  username: 'novejmeno',
  bio: 'Moje bio',
);

// Upload avataru
await ref.read(profileNotifierProvider.notifier).uploadAvatar(bytes, filename);
```

### Follow Provider

```dart
// Sleduje uzivatel?
final isFollowing = ref.watch(isFollowingProvider(userId));

// Sledovat/Prestat sledovat
await ref.read(followServiceProvider).toggleFollow(userId);

// Seznam sledujicich
final followers = await ref.read(followServiceProvider).getFollowers(userId);
```

---

## Widgety

### Profile Widgety

#### GlitchAvatar
```dart
GlitchAvatar(
  imageUrl: user.avatarUrl,
  name: user.username,
  size: 86,
  glitchStyle: GlitchStyle.neon,
  showLevelBadge: true,
  onTap: () => {},
)
```

#### ProfileBanner
```dart
ProfileBanner(
  height: 100,
  style: BannerStyle.gradient,
  imageUrl: user.bannerUrl, // optional
)
```

#### ProfileBio
```dart
ProfileBio(
  bio: user.bio,
  onTagTap: (tag) => searchByTag(tag),
  onMentionTap: (username) => goToProfile(username),
)
```

#### FollowButton
```dart
FollowButton(
  userId: user.id,
  isCompact: true,
)
```

#### ReputationBadge (Webs)
```dart
ReputationBadge(
  webCount: user.totalWebs,
  style: ReputationStyle.animated,
)
```

### Feed Widgety

#### PostCard
```dart
PostCard(
  post: post,
  onTap: () => goToDetail(post.id),
  onWeb: () => toggleWeb(post.id),  // Webs misto lajku
  onBookmark: () => toggleBookmark(post.id),
)
```

#### ThreadTypeChip
```dart
ThreadTypeChip(
  type: ThreadType.question,
  isSelected: true,
  onTap: () => filterByType(type),
)
```

---

## Statistiky projektu

| Metrika | Hodnota |
|---------|---------|
| Dart soubory | 156 |
| Modely | 15 |
| Providers | 15 |
| Services | 21 |
| Screens | 40 |
| Widgety | 54 |
| Radky kodu | ~25,000 |

---

## TODO

- [ ] **Digitalni Stash**
  - [ ] My Stash - seznam vyzkoušených strainu
  - [ ] Vlastni fotky - galerie
  - [ ] Wishlist - co chci vyzkouset
- [ ] **Backend**
  - [ ] Privacy settings v Supabase
  - [ ] Banner URL sloupec v profiles
  - [ ] Push notifikace (FCM)
- [ ] **UI/UX**
  - [ ] Onboarding flow
  - [ ] Skeleton loading
  - [ ] Pull to refresh animace

---

## Licence

Proprietarni - Spiderbagzz

---

*Vytvoreno s Flutter a Supabase*
