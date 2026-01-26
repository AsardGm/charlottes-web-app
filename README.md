# Charlotte's Web - Community App

Komunitni aplikace pro Spiderbagzz s Reddit-style feedem, E2EE chatem a pokrocilou gamifikaci.

---

## Status projektu

| Legenda | Vyznam |
|---------|--------|
| ✅ | **Hotovo** - plne funkcni |
| 🔄 | **Rozdelano** - castecne implementovano |
| ❌ | **Neni** - zatim neimplementovano |

---

## Prehled funkci

### Autentizace a Onboarding
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Email login | ✅ | Supabase Auth |
| Registrace | ✅ | S validaci |
| Forgot password | ✅ | Email reset |
| Onboarding flow | ✅ | 3 kroky uvodu |
| Splash screen | ✅ | S animaci |
| Session persistence | ✅ | Auto-login |

### Feed System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Seznam prispevku | ✅ | S pagination |
| Vytvoreni prispevku | ✅ | Text + obrazky |
| Detail prispevku | ✅ | S komentari |
| Thread Types | ✅ | Discussion, Question, Announcement |
| Webs (reakce) | ✅ | Pavoici vlakna misto lajku |
| Komentare | ✅ | Vnorene odpovedi |
| Bookmarks | ✅ | Ukladani prispevku |
| Tags/Hashtagy | ✅ | #tag parsing |
| Filtrovani | ✅ | Podle typu, casu |
| Pull to refresh | ✅ | |
| Obrazky v prispevku | ✅ | Multi-image upload |
| Video v prispevku | ❌ | |
| Ankety v prispevku | 🔄 | Model existuje, UI chybi |

### Chat System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Seznam konverzaci | ✅ | conversations_screen |
| Chat obrazovka | ✅ | Plne funkcni |
| E2EE sifrovani | ✅ | X25519 + AES-256-GCM |
| Textove zpravy | ✅ | S formatovanim |
| Hlasove zpravy | ✅ | Nahravani + prehravani |
| GIF picker | ✅ | Giphy integrace |
| Emoji picker | ✅ | 9 kategorii |
| Prilohy/soubory | ✅ | file_message_widget |
| Lokace | ✅ | location_message_widget |
| Odpovedi na zpravy | ✅ | reply_preview |
| Pripnute zpravy | ✅ | pinned_messages_widget |
| Vyhledavani v chatu | ✅ | message_search_sheet |
| Typing indicator | ✅ | Realtime |
| Offline fronta | ✅ | offline_queue_indicator |
| Preposilani zprav | ✅ | forward_message_dialog |
| Ankety v chatu | ✅ | poll_message_widget |
| Skupinove chaty | ❌ | |
| Volani (audio/video) | ❌ | |

### Profil System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Zobrazeni profilu | ✅ | user_profile_screen |
| Editace profilu | ✅ | Username, bio, avatar |
| Avatar upload | ✅ | S crop |
| GlitchAvatar efekty | ✅ | 7 stylu |
| Profile banner | ✅ | 5 stylu |
| Bio s parsing | ✅ | #tag, @mention, URL |
| Statistiky profilu | ✅ | Followers, posts, webs |
| Reputation badge | ✅ | Webs vizualizace |

### Follow System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Sledovani uzivatelu | ✅ | |
| Odsledovani | ✅ | |
| Seznam followers | ✅ | |
| Seznam following | ✅ | |
| Follow requests | ✅ | Pro privatni profily |
| Privatni profil | ✅ | is_private flag |

### Vyhledavani
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Vyhledavani uzivatelu | ✅ | |
| Vyhledavani prispevku | ✅ | Fulltext |
| Vyhledavani tagu | ✅ | |
| Historie hledani | 🔄 | |

### Notifikace
| Funkce | Status | Poznamka |
|--------|--------|----------|
| In-app notifikace | ✅ | notifications_screen |
| Push notifikace (iOS) | 🔄 | Service existuje, testovani |
| Push notifikace (Android) | 🔄 | FCM setup |
| Push notifikace (Web) | ✅ | web_push_service |
| Nastaveni notifikaci | ✅ | V settings |

### Nastaveni
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Obecne nastaveni | ✅ | settings_screen |
| Privacy & Security | ✅ | privacy_security_screen |
| Blokovani uzivatelu | ✅ | blocked_users_screen |
| Ghost mode | ✅ | Skryti lokace |
| Anonymni mod | ✅ | Skryti z vyhledavani |
| Smazani uctu | ✅ | Burner account |
| Dark/Light mode | 🔄 | Theme existuje |

### Gamifikace System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Gamifikace dashboard | ✅ | gamification_screen |
| Spider Ranks (XP) | ✅ | 6 urovni |
| Strain Cards | ✅ | cards_screen, 4 rarity |
| Badges/Odznaky | ✅ | badges_screen |
| Leaderboard | ✅ | leaderboard_screen |
| Daily Quests | ✅ | Denni ukoly |
| Webs system | ✅ | Reputacni system |

### Admin Panel
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Admin dashboard | ✅ | Statistiky |
| User management | ✅ | Bany, role |
| Post management | ✅ | Mazani, editace |
| Reports | ✅ | Nahlaseni |
| Analytics | ✅ | Grafy, metriky |
| Moderation | ✅ | Content moderation AI |
| Content management | ✅ | |
| User tools | ✅ | Admin nastroje |
| Audit log | ✅ | Historie akci |

### Scanner (Strain Scanner)
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Scanner screen | 🔄 | Existuje lokalne, NENI v git |
| Scan result | 🔄 | Existuje lokalne, NENI v git |
| Scan history | 🔄 | Existuje lokalne, NENI v git |
| Strain database | 🔄 | strain_service, migrace pripravena |
| AI rozpoznavani | ❌ | |

### Brain Map (Terpeny)
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Brain map screen | ✅ | Vizualizace |
| Terpene detail | ✅ | terpene_detail_sheet |
| Terpene database | ✅ | Migrace existuje |
| Interaktivni mapa | 🔄 | |

### Dalsi planovane funkce
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Digitalni Stash | ❌ | My Stash, galerie, wishlist |
| Stories | ❌ | Instagram-style |
| Live streaming | ❌ | |
| Marketplace | ❌ | |
| Events | ❌ | |

---

## Spider Ranks (XP System)
```
Vajicko       →  0 - 100 XP
Maly krizak   →  100 - 500 XP
Lovec         →  500 - 2,000 XP
Tkadlec       →  2,000 - 5,000 XP
Vdova         →  5,000 - 15,000 XP
Spider Master →  15,000+ XP
```

## Card Rarities
```
Common   → Seda barva, zakladni karty
Rare     → Modra barva, vzacnejsi karty
Exotic   → Fialova barva, exoticke karty
Legend   → Zlata barva, legendy s animaci
```

## GlitchAvatar Styles
```
none     → Zadny efekt
subtle   → Jemny glitch
classic  → Klasicky RGB split
neon     → Neonovy okraj (pro adminy)
web      → Pavoici sit
pulse    → Pulzujici efekt
fire     → Ohne (pro Spider Master)
```

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
| Storage | Ukladani souboru |
| Realtime | Real-time subscriptions |
| Edge Functions | Serverless funkce |

### Sifrovani
| Technologie | Pouziti |
|-------------|---------|
| cryptography | X25519 + AES-256-GCM |
| flutter_secure_storage | Bezpecne ukladani klicu |

---

## Struktura projektu

```
lib/
├── config/
│   ├── api_config.dart
│   ├── app_router.dart
│   └── supabase_config.dart
│
├── models/                    # 15+ modelu
│
├── providers/                 # 15+ provideru
│
├── screens/
│   ├── admin/                 # 9 obrazovek ✅
│   ├── auth/                  # 3 obrazovky ✅
│   ├── brain_map/             # 2 obrazovky ✅
│   ├── chat/                  # 2 obrazovky + 20 widgetu ✅
│   ├── feed/                  # 3 obrazovky ✅
│   ├── gamification/          # 4 obrazovky ✅
│   ├── home/                  # 1 obrazovka ✅
│   ├── notifications/         # 1 obrazovka ✅
│   ├── onboarding/            # 1 obrazovka ✅
│   ├── profile/               # 4 obrazovky ✅
│   ├── scanner/               # 3 obrazovky 🔄 (neni v git)
│   ├── search/                # 1 obrazovka ✅
│   ├── settings/              # 3 obrazovky ✅
│   └── splash/                # 1 obrazovka ✅
│
├── services/                  # 34 services
│
├── theme/
│
└── widgets/                   # 54+ widgetu

supabase/
└── migrations/                # 17 SQL migraci
```

---

## Instalace

### Pozadavky
- Flutter 3.x
- Dart 3.x
- Xcode 15+ (pro iOS)
- Android Studio (pro Android)
- Supabase ucet

### Kroky

```bash
# 1. Klonovani
git clone https://github.com/AsardGm/charlottes-web-app.git
cd community_app

# 2. Instalace zavislosti
flutter pub get

# 3. iOS setup
cd ios && pod install && cd ..

# 4. Konfigurace (viz sekce Konfigurace)

# 5. Spusteni
flutter run
```

---

## Konfigurace

### Environment Variables

Vytvorte `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String giphyApiKey = 'YOUR_GIPHY_API_KEY';
}
```

---

## Databaze

### Migrace (v poradi)

```
1. add_profile_columns.sql
2. create_avatars_bucket.sql
3. create_push_tokens.sql
4. create_user_settings.sql
5. 20260105_create_notifications_table.sql
6. 20260105_add_is_private_to_profiles.sql
7. 20260106_follow_requests.sql
8. 20260106_blocked_users.sql
9. 20260106_reports.sql
10. 20240107_admin_tools.sql
11. 20260106_admin_policies.sql
12. 20260109_strain_scanner.sql (pro scanner)
13. 20260109_terpene_brain_map.sql (pro brain map)
```

### Storage Buckets

| Bucket | Popis | Public |
|--------|-------|--------|
| `avatars` | Profilove fotky | Ano |
| `posts` | Obrazky prispevku | Ano |
| `voice` | Hlasove zpravy | Ne |
| `chat-files` | Chat prilohy | Ne |

---

## Statistiky projektu

| Metrika | Hodnota |
|---------|---------|
| Screens | 37 |
| Services | 34 |
| Widgets | 54+ |
| Models | 15+ |
| Providers | 15+ |
| SQL Migrations | 17 |
| Chat widgets | 20 |

---

## TODO - Prioritni ukoly

### Vysoka priorita
- [ ] Dokoncit a pushnout Scanner feature
- [ ] Otestovat push notifikace na iOS/Android
- [ ] Opravit content moderation false positives

### Stredni priorita
- [ ] Implementovat Stories
- [ ] Skupinove chaty
- [ ] Video v prispevku
- [ ] Digitalni Stash

### Nizka priorita
- [ ] Audio/Video volani
- [ ] Marketplace
- [ ] Events system
- [ ] Live streaming

---

## Licence

Proprietarni - Rob a Patrik

---

*Vytvoreno s Flutter a Supabase*
*Posledni aktualizace: Leden 2026*
