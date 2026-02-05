# Buds and Buddies

**Komunitni socialni sit pro milovniky rostlin s AI skenerem, sifrovnym chatem a gamifikaci.**

---

## O aplikaci

Buds and Buddies je mobilni a webova aplikace postavena na Flutteru, ktera spojuje komunitu kolem pestovani a poznani rostlin. Kombinuje Reddit-style feed, end-to-end sifrovanou komunikaci, AI rozpoznavani odrud a interaktivni vzdelavaci nastroje - vse zabalene do unikatniho cyberpunk designu s pavoici tematikou.

### Hlavni pilire

- **Komunita** - Sdileni zkusenosti, diskuze, otazky a odpovedi ve feedu s thread typy
- **Soukromi** - Vojenska uroven sifrovani (X25519 + AES-256-GCM) v chatu
- **Vzdelavani** - AI skener rostlin, Brain Map terpenoveho profilu, databaze odrud
- **Gamifikace** - XP system, Spider Ranks, sberatelske karty, odznaky, denny ukoly
- **Bezpecnost** - Ghost mode, anonymni rezim, burner ucty, AI moderace obsahu
- **Harm Reduction** - Holotrop mod: dychaci cviceni, bio-hacky, grounding, edukace

### Pro koho

Aplikace je urcena pro ceskou a slovenskou komunitu zajimajici se o pestovani, genetiku a edukaci kolem rostlin. Duraz je kladen na bezpecnost, soukromi a kvalitni obsah.

---

## Architektura

```
Flutter 3.x + Dart 3.x
├── State Management:  Riverpod
├── Navigace:          GoRouter
├── Backend:           Supabase (Auth, DB, Storage, Realtime)
├── AI:                OpenAI GPT-4o Vision API
├── Sifrovani:         X25519 + AES-256-GCM
└── Platformy:         iOS, Android, Web (PWA)
```

---

## Funkcni prehled

### Legenda
| Symbol | Vyznam |
|--------|--------|
| ✅ | Hotovo - plne funkcni |
| 🔄 | Rozdelano - castecne implementovano |
| ❌ | Neni - zatim neimplementovano |

---

### Autentizace a Onboarding
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Email login | ✅ | Supabase Auth |
| Registrace | ✅ | S validaci |
| Forgot password | ✅ | Email reset |
| Onboarding flow | ✅ | 5 kroku s holografickym pruvodcem Buddy |
| Splash screen | ✅ | Cyberpunk animace, glitch efekty, matrix data stream |
| Session persistence | ✅ | Auto-login |

### Feed System
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Seznam prispevku | ✅ | Infinite scroll s pagination |
| Vytvoreni prispevku | ✅ | Text + multi-image upload |
| Detail prispevku | ✅ | S vnorenimi komentari |
| Thread Types | ✅ | Discussion, Question, Announcement |
| Webs (reakce) | ✅ | Pavoici vlakna misto klasickych lajku |
| Komentare | ✅ | Vnorene odpovedi |
| Bookmarks | ✅ | Ukladani prispevku |
| Tags/Hashtagy | ✅ | #tag parsing |
| Filtrovani | ✅ | Podle typu, casu |
| Pull to refresh | ✅ | |
| Video v prispevku | ❌ | |
| Ankety v prispevku | 🔄 | Model existuje, UI chybi |

### Chat System (E2EE)
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Seznam konverzaci | ✅ | S unread badge |
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
| Offline fronta | ✅ | Zpravy se odeslou po pripojeni |
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
| GlitchAvatar efekty | ✅ | 7 stylu (none, subtle, classic, neon, web, pulse, fire) |
| Profile banner | ✅ | 5 stylu |
| Bio s parsing | ✅ | #tag, @mention, URL |
| Statistiky profilu | ✅ | Followers, posts, webs |
| Follow/Unfollow | ✅ | |
| Privatni profil | ✅ | Follow requests pro schvaleni |
| Blokovani uzivatelu | ✅ | |

### Gamifikace
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Gamifikace dashboard | ✅ | Prehled XP, rank, progress |
| Spider Ranks (XP) | ✅ | 6 urovni progrese |
| Strain Cards | ✅ | Sberatelske karty, 4 rarity |
| Badges/Odznaky | ✅ | Odemykatelne odznaky |
| Leaderboard | ✅ | Zebricek uzivatelu |
| Daily Quests | ✅ | Denni ukoly za XP |
| Webs system | ✅ | Reputacni system |

### AI Skener
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Live camera preview | ✅ | Dedicovany camera screen |
| AI rozpoznavani | ✅ | OpenAI GPT-4o Vision API |
| Scan result | ✅ | Detailni analyza odrudy |
| Scan history | ✅ | Historie vsech skenu |
| Vyber z galerie | ✅ | Alternativa k foceni |
| Flash control | ✅ | Off/Auto/On/Torch |

### Holotrop (Harm Reduction)
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Plovouci pristupove tlacitko | ✅ | Pulzujici neon button na Hub a Comms |
| Dychaci cviceni 4-4-4 | ✅ | Animovany kruh s fazemi (nadech/zadrzet/vydech) |
| Bio-hack protokol | ✅ | Terminal-style instrukce (pepr, voda, CBD, citron) |
| Grounding 5-4-3-2-1 | ✅ | Cyberpunk krokove karty s interakci |
| Edukacni obsah | ✅ | CB1 receptory, synteticke kanabinoidy |
| Charlotte meditace | ✅ | Specialni meditation state pruvodce |
| Vizualni prechod | ✅ | Animovana zmena z cyberpunk do calming palety |
| Uklidnujici texty | ✅ | Dynamicke texty behem dychani |
| Progress tracking | ✅ | Cyklus indikatory + section progress |

### Lab
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Lab dashboard | ✅ | Prehled modulu (Grow Diary, Brain Map, Skener, Kalkulator, Holotrop) |
| Grow Diary | ✅ | Seznam a vytvareni grow zaznamu |
| AI Lab service | ✅ | AI analyza pro lab funkce |

### Brain Map (Terpeny)
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Brain map screen | ✅ | Interaktivni vizualizace |
| Terpene detail | ✅ | terpene_detail_sheet |
| Terpene database | ✅ | Migrace existuje |
| Interaktivni mapa | 🔄 | |

### Admin Panel
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Admin dashboard | ✅ | Statistiky a metriky |
| User management | ✅ | Bany, role, editace |
| Post management | ✅ | Mazani, editace |
| Reports | ✅ | Nahlaseni od uzivatelu |
| Analytics | ✅ | Grafy, metriky |
| AI Moderation | ✅ | Automaticka kontrola obsahu |
| Content management | ✅ | |
| User tools | ✅ | Admin nastroje |
| Audit log | ✅ | Historie vsech admin akci |

### Notifikace
| Funkce | Status | Poznamka |
|--------|--------|----------|
| In-app notifikace | ✅ | |
| Push (Web) | ✅ | web_push_service |
| Push (iOS) | 🔄 | Service existuje |
| Push (Android) | 🔄 | FCM setup |

### Bezpecnost a Soukromi
| Funkce | Status | Poznamka |
|--------|--------|----------|
| Ghost mode | ✅ | Skryti lokace |
| Anonymni mod | ✅ | Neviditelnost ve vyhledavani |
| Privatni profil | ✅ | Schvalovani followeru |
| Smazani uctu | ✅ | Burner account |
| E2EE chat | ✅ | Military-grade sifrovani |
| AI moderace | ✅ | Automaticka kontrola obsahu |

---

## Spider Ranks (XP System)

```
Vajicko       →  0 - 100 XP        (novy uzivatel)
Maly krizak   →  100 - 500 XP      (aktivni clen)
Lovec         →  500 - 2,000 XP    (pravidelny contributor)
Tkadlec       →  2,000 - 5,000 XP  (zkuseny clen)
Vdova         →  5,000 - 15,000 XP (veteransky clen)
Spider Master →  15,000+ XP        (legendarni status)
```

## Card Rarities

```
Common   → Seda barva    - zakladni karty
Rare     → Modra barva   - vzacnejsi karty
Exotic   → Fialova barva - exoticke karty
Legend   → Zlata barva   - legendy s animaci
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

| Vrstva | Technologie | Pouziti |
|--------|-------------|---------|
| Framework | Flutter 3.x | Cross-platform UI |
| Jazyk | Dart 3.x | Business logic |
| State | flutter_riverpod | Reaktivni state management |
| Navigace | go_router | Routing |
| Backend | Supabase | Auth, DB, Storage, Realtime |
| AI | OpenAI GPT-4o Vision | Rozpoznavani odrud |
| Sifrovani | cryptography | X25519 + AES-256-GCM |
| Klice | flutter_secure_storage | Bezpecne uloziste |
| Kamera | camera + permission_handler | Live preview, permissions |
| Media | image_picker, record, audioplayers | Fotky, hlas, prehravani |
| Lokace | geolocator | GPS pozice |
| Fonty | google_fonts | Rajdhani, Bangers, MightySpidey |

---

## Struktura projektu

```
lib/
├── config/
│   ├── api_config.dart          # API klice (OpenAI, Giphy)
│   ├── app_router.dart          # GoRouter konfigurace
│   └── supabase_config.dart     # Supabase credentials
│
├── models/                       # 15+ datovych modelu
│
├── providers/                    # 15+ Riverpod provideru
│
├── screens/
│   ├── admin/                    # 9 obrazovek (dashboard, users, posts, reports...)
│   ├── auth/                     # 3 obrazovky (login, register, forgot)
│   ├── brain_map/                # 2 obrazovky (mapa, terpene detail)
│   ├── chat/                     # 2 obrazovky + 20 widgetu
│   ├── feed/                     # 3 obrazovky (feed, create, detail)
│   ├── gamification/             # 4 obrazovky (dashboard, cards, badges, leaderboard)
│   ├── holotrop/                  # 4 obrazovky (breathing, biohacks, grounding, main)
│   ├── home/                     # 1 obrazovka (shell s bottom nav)
│   ├── lab/                      # 3 obrazovky (dashboard, grow list, create grow)
│   ├── notifications/            # 1 obrazovka
│   ├── onboarding/               # 1 obrazovka (5 kroku)
│   ├── profile/                  # 4 obrazovky (view, edit, follow requests, user)
│   ├── scanner/                  # 4 obrazovky (camera, scanner, result, history)
│   ├── search/                   # 1 obrazovka
│   ├── settings/                 # 3 obrazovky (settings, privacy, blocked)
│   └── splash/                   # 1 obrazovka
│
├── services/                     # 34+ services
│
├── theme/                        # Cyberpunk dark theme, barvy, fonty
│
└── widgets/                      # 54+ widgetu

supabase/
└── migrations/                   # SQL migrace
```

---

## Statistiky

| Metrika | Hodnota |
|---------|---------|
| Screens | 45+ |
| Services | 36+ |
| Widgets | 60+ |
| Models | 17+ |
| Providers | 17+ |
| SQL Migrations | 19 |
| Chat widgets | 20+ |

---

## Instalace

### Pozadavky
- Flutter 3.x
- Dart 3.x
- Xcode 15+ (iOS)
- Android Studio (Android)
- Supabase ucet

### Setup

```bash
git clone https://github.com/AsardGm/charlottes-web-app.git
cd community_app
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Konfigurace

Vytvorte `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String giphyApiKey = 'YOUR_GIPHY_API_KEY';
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
}
```

---

## Databaze

### Migrace (v poradi)
```
1.  add_profile_columns.sql
2.  create_avatars_bucket.sql
3.  create_push_tokens.sql
4.  create_user_settings.sql
5.  20260105_create_notifications_table.sql
6.  20260105_add_is_private_to_profiles.sql
7.  20260106_follow_requests.sql
8.  20260106_blocked_users.sql
9.  20260106_reports.sql
10. 20240107_admin_tools.sql
11. 20260106_admin_policies.sql
12. 20260109_strain_scanner.sql
13. 20260109_terpene_brain_map.sql
```

### Storage Buckets

| Bucket | Popis | Public |
|--------|-------|--------|
| `avatars` | Profilove fotky | Ano |
| `posts` | Obrazky prispevku | Ano |
| `voice` | Hlasove zpravy | Ne |
| `chat-files` | Chat prilohy | Ne |

---

## Planovane funkce

- [x] Lab sekce (grow diary, moduly)
- [x] Holotrop harm reduction mod
- [ ] Skupinove chaty
- [ ] Stories (Instagram-style)
- [ ] Video v prispevku
- [ ] Audio/Video volani
- [ ] Digitalni Stash (galerie, wishlist)
- [ ] Events system

---

## Licence

Proprietarni - Rob a Patrik

---

*Postaveno na Flutter + Supabase | Posledni aktualizace: 27. Leden 2026*
 
