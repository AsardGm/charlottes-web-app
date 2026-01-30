# 🕷️ CHARLOTTE'S WEB - ULTIMÁTNÍ DESIGN & FEATURE IDEAS

> **Připraveno:** 2026-01-30
> **Status:** Koncept pro budoucí vývoj
> **Priorita:** ⭐⭐⭐ = Must have | ⭐⭐ = Nice to have | ⭐ = Long-term

---

## 🎨 DESIGN SYSTEM UPGRADES

### 1. **Micro-interactions & Animations** ⭐⭐⭐
**Proč:** Aplikace je funkční, ale postrádá "živost" - animace zvyšují engagement o 30-40%

**Konkrétní nápady:**
- **Pull-to-refresh s pavučinou** - Když user stáhne feed dolů, animuje se pavučina, která se "protahuje" a pak "pružně" vrací
- **Card hover/tap effects** - Strain cards při hover/tap lehce "světélkují" podle rarity (Common = slabé, Legendary = intenzivní zlatý glow)
- **XP gain animation** - Když user získá XP, "vystřelí" číslo s particle efektem směrem k rank badge v headeru
- **Rank up celebration** - Při postupu na další rank fullscreen animace: pavučina se "roztočí", nový rank se zjeví s glow efektem, konfety
- **Loading states** - Místo boring spinner použít animovaného pavouka, který "spřádá pavučinu"
- **Button ripple effects** - Cyan ripple efekt při tapnutí tlačítek, připomínající "rozvibrování pavučiny"
- **Tab transitions** - Při přepínání mezi taby smooth slide animation s fade

**Technické řešení:**
```dart
// Použít Flutter built-in animace
AnimatedContainer, Hero, SlideTransition, FadeTransition
Lottie animations pro komplexnější efekty
```

---

### 2. **Dark Mode Pro++ & Theme Customization** ⭐⭐
**Proč:** Users milují personalizaci - 67% mobilních uživatelů preferuje dark mode varianty

**Návrh:**
- **3 Dark Mode varianty:**
  - **Spider Night** (současný) - Tmavě modrý s červenými akcenty
  - **Midnight Purple** - Tmavě fialový s cyber-purple akcenty (pro Weaver+ ranks)
  - **Neon Underground** - Černý background s intenzivními neon akcenty (pro Widow+ ranks)

- **Accent color picker** - User si může vybrat barvu akcentu:
  - Cyan (default), Neon Green, Electric Purple, Hot Pink, Acid Yellow
  - Uloženo v user preferences
  - Živý preview při výběru

- **Strain card styles** - User může přepnout mezi:
  - **Minimalist** - Čisté karty bez gradientů
  - **Cyberpunk** - Neon borders, glitch effects
  - **Classic** - Vintage look s texturami

**UI/UX:**
```
Profil → Nastavení → Vzhled
├── Téma (3 dark varianty)
├── Barva akcentu (color picker)
├── Styl karet (3 varianty)
└── Animace (zapnout/vypnout pro slow devices)
```

---

### 3. **Glassmorphism & Depth Layers** ⭐⭐
**Proč:** Moderní trend, který přidává "hloubku" UI - aplikace vypadá premium

**Kde aplikovat:**
- **Navigation bar** - Průhledný s blur efektem, viditelný background pod ním
- **Modal dialogy** - Frosted glass efekt s blur background
- **Cards overlay content** - Když se karta otevře přes jiný obsah
- **Toast notifications** - Průhledné s blur, elegantněší než solid color
- **Bottom sheets** - Glassmorphism místo solid dark surface

**CSS/Flutter approach:**
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(16),
    ),
  ),
)
```

---

### 4. **Neumorphism pro Calm Mode** ⭐
**Proč:** Holotrop/Calm Mode má být uklidňující - neumorphism je soft, tactile, terapeutický

**Redesign Calm Mode:**
- Soft shadows místo hard borders
- Tlačítka vypadají jako "vymačknuté" nebo "vyvýšené" povrchy
- Breathing circle s soft glow a subtle shadow
- Grounding checklist items s tactile pressed effect po označení
- Celkově více "fyzický" a méně "digitální" pocit

---

### 5. **Custom Illustrations & Iconography** ⭐⭐⭐
**Proč:** Aplikace používá Material Icons - custom ikony zvyšují brand identity

**Co vytvořit:**
- **Custom rank icons** - Místo emoji vlastní ilustrované ikony:
  - Egg: Praskající vejce s pavučinou
  - Spiderling: Roztomilý pavouk s velkýma očima
  - Hunter: Pavouk s lukem/mířidlem
  - Weaver: Pavouk spřádající pavučinu
  - Widow: Černá vdova s červeným hourglass
  - Spider Master: Majestátní pavouk s korunou

- **Custom tab bar icons** - Nahradit Material Icons:
  - Hub: Pavučina místo home icon
  - News: Noviny s pavoukem
  - Chat: Speech bubble s pavučinou
  - Lab: Experimentální baňka s pavoukem uvnitř
  - Profile: Spider silhouette

- **Empty states** - Krásné ilustrace místo "Žádný obsah":
  - Prázdný feed: Pavouk čekající na pavučině "Zatím tu nikdo nic nepřidal..."
  - Žádné zprávy: Pavouk s prázdnou speech bubble
  - Žádné grows: Prázdný květináč s pavučinou

- **Loading states** - Animovaný pavouk spřádající pavučinu

**Style:** Flat design s cyan/red/gold akcenty, konsistentní s brand colors

---

## 🚀 KILLER FEATURES (High Impact)

### 6. **AR Strain Scanner** ⭐⭐⭐
**Proč:** Rozšířená realita je budoucnost - nikdo jiný to v cannabis apce nemá

**Feature popis:**
- User namíří kameru na bud
- AR overlay zobrazí real-time info:
  - Detekce barvy (zelená, fialová, oranžová chloupky)
  - Trichome density estimate (na základě "třpytu")
  - Size measurement (pomocí reference objektu)
  - Suggestion: "Vypadá jako Indica-dominant"

- **AI suggestion engine:**
  - "Tato rostlina vykazuje 78% shodu s OG Kush"
  - "Vysoká trichome density = high THC potential"
  - "Fialové odstíny = anthokyaniny, pravděpodobně chladnější grow"

- **Save & compare:**
  - User může uložit AR scan do svého "Strain Vault"
  - Porovnat více buds vedle sebe
  - Track visual changes přes čas (během drying/curing)

**Tech stack:**
- ARCore (Android) / ARKit (iOS)
- Flutter plugin: `arcore_flutter_plugin` nebo `ar_flutter_plugin`
- ML model pro visual recognition

---

### 7. **Social Smoke Sessions (Live)** ⭐⭐⭐
**Proč:** Největší missing feature - social live experience, jako Twitch pro cannabis

**Feature:**
- **Vytvořit "Session Room":**
  - User zahájí live session (veřejnou nebo privátní)
  - Zvolí strain, který konzumuje
  - Nastaví timer (30min, 1h, 2h)

- **Co se děje v Session:**
  - Live chat s účastníky
  - Emoji reactions (floating na obrazovce)
  - Audio room (volitelně) - hlasový chat
  - Sdílení fotek bud/setup
  - Společné mini-hry (viz níže)
  - Real-time mood tracking (všichni vidí náladu ostatních)

- **Session Games:**
  - **Higher/Lower** - Hádání THC %
  - **Strain Guess** - Z obrázku hádat strain
  - **Story Chain** - Každý přidá jednu větu do story
  - **Munchies Bingo** - Checklist food cravings

- **Post-Session Recap:**
  - Statistika: Kolik lidí, délka, top moments
  - Highlights (top voted messages/moments)
  - Společné cognitive test score (průměr všech)
  - Badges za účast (Social Butterfly, Session Host)

**Monetizace potenciál:**
- Premium sessions (více lidí, delší čas)
- Custom session backgrounds
- Emote packs

---

### 8. **Mood-Based Strain Recommender AI** ⭐⭐⭐
**Proč:** Users neví, co chtějí - AI jim to řekne na základě dat

**Jak to funguje:**

**Input data pro AI:**
- Aktuální denní check-in (mood, energy, focus)
- Historie konzumace + post-consumption scores
- Čas dne (morning/afternoon/evening)
- Uživatelův cíl: "Chci být kreativní" / "Potřebuji spát" / "Chci socializovat"
- Terpene preferences (z minulých konsumací)
- Cognitive baseline (z brain heatmap)

**AI output:**
```
🎯 Doporučení pro tebe DNES:

1. Blue Dream (91% match)
   ✨ Proč: Tvá kreativita je dnes nízká (4/10), Blue Dream ti
      pomohl v minulosti +3 body. Obsahuje Myrcene pro relax
      a Pinene pro focus.
   ⏰ Nejlepší čas: 16:00-18:00 (tvoje "creative window")

2. Sour Diesel (87% match)
   ✨ Proč: Vysoký obsah Limonene - v minulosti ti zvedl mood
      o průměrně 2.8 bodu. Energizing efekt, perfektní na tvou
      aktuální únavu.

3. Granddaddy Purple (82% match)
   ✨ Proč: Pro večer - Myrcene + Linalool kombinace ti vždy
      pomohla se spánkem. Tvůj anxiety level je dnes 7/10, toto
      ho historicky snížilo na ~3/10.
```

**UI Flow:**
```
Home Screen → FAB button "Doporuč mi strain" →
→ Quick questions (3 taps max) →
→ AI loading (3-5 sec) →
→ Results s reasoning
```

**Gamifikace:**
- "AI Trustpilot" - User hodnotí, jak moc pomohlo
- AI se učí z feedback
- Badge "AI Believer" za 50 úspěšných doporučení

---

### 9. **Strain Genetics Explorer (Interactive Tree)** ⭐⭐
**Proč:** Cannabis genetics je fascinující, ale komplexní - vizuální strom to zpřístupní

**Feature:**
- **Interactive family tree** - Jako genealogický strom:
  - Klikneš na "Blue Dream"
  - Vidíš rodiče: Blueberry × Haze
  - Klikneš na Blueberry → vidíš jeho rodiče: Purple Thai × Thai
  - Můžeš jít až k landrace strains (OG předkové)

- **Visual styling:**
  - Každý strain = node s ikonou/obrázkem
  - Lines connecting parents to child
  - Color coding podle typu (Indica=purple, Sativa=green, Hybrid=yellow)
  - Zoom in/out, pan, scroll

- **Strain info on tap:**
  - Rychlý popup s: THC%, terpenes, effects
  - "Add to wishlist" button
  - "I've tried this" checkbox → přidá badge na node

- **Discover mode:**
  - "Show me strains similar to X"
  - "Show me all strains with Myrcene"
  - "Show me Indica-dominant hybrids"

**Gamifikace:**
- **Genetics Nerd Badge** - Prozkoumej 50+ strains v tree
- **Landrace Hunter** - Najdi všech 10 landrace strains
- **Family Reunion** - Vyzkoušej parent strain a jeho child

**Tech:**
- D3.js port do Flutter nebo custom canvas painting
- Graph database (Neo4j) pro strain relationships
- Nebo hardcoded JSON tree s relationships

---

### 10. **Terpene Profile Builder & Blending** ⭐⭐
**Proč:** Pro pokročilé uživatele a growers - vytvoř si ideální terpene mix

**Feature:**

**Part 1: Personal Terpene Profile**
- User vyplní "Terpene Quiz":
  - "Jak reaguješ na citrusové vůně?" → Limonene sensitivity
  - "Preferuješ lavender relaxaci?" → Linalool preference
  - "Oceňuješ energizing efekty?" → Pinene/Limonene

- **Output: Tvůj Ideální Mix**
  ```
  Tvůj ideální terpene blend:
  - 35% Myrcene (relaxace)
  - 25% Limonene (mood boost)
  - 20% Caryophyllene (anxiety relief)
  - 15% Linalool (sleep aid)
  - 5% Pinene (focus)
  ```

**Part 2: Strain Blending Recommender**
- "Jaký efekt chceš dosáhnout?"
  - Kreativní práce → AI navrhne mix strainů
  - Sociální večer → Jiný mix
  - Spánek → Jiný mix

- **Blending suggestions:**
  ```
  Pro kreativní práci vyzkoušej:

  🌿 Morning: Sour Diesel (⅔) + Blue Dream (⅓)
     → High Limonene + balanced Myrcene
     → Očekávaný efekt: Focus 8/10, Creativity 9/10

  🌙 Evening: Zklidni se s Granddaddy Purple
     → Reset pro dobrý spánek
  ```

**Part 3: Grow Optimization**
- Pro growery: "Chceš strain s high Myrcene?"
  - Doporučení strains, které to přirozeně mají
  - Grow tipy: "Nižší teplota poslední 2 týdny zvýší Linalool"
  - "UV světlo zvyšuje trichome production"

---

### 11. **Plant Parenthood Mode** 🌱⭐⭐⭐
**Proč:** Growing je emocionální journey - gamifikuj to jako "Tamagotchi pro konopí"

**Feature:**
- **Name your plant:** User pojmenuje každý grow (ne jen strain, ale osobní jméno)
  - "Moje Zelinka", "Pablo Escogreen", "Mary Jane Supreme"

- **Daily check-ins:**
  - Každý den notification: "Jak se má Zelinka dnes?"
  - User uploadne foto, přidá note
  - **AI komentář:** "Zelinka vypadá skvěle! Listy jsou zdravě zelené. 🌿"
  - **Growth milestone:** "Zelinka má dnes 42 dní - je v peak flowering! 🌸"

- **Personality system:**
  - Každá rostlina má "traits" založené na grow historii:
    - "Tough Cookie" - přežila přehnojení
    - "Light Lover" - rychlý růst pod intenzivním světlem
    - "Thirsty Girl" - potřebovala hodně vody
    - "Frost Queen" - extrémní trichome production

- **Memory book:**
  - Časová osa všech fotek
  - "From seed to smoke" video generator (timelapse z fotek)
  - Downloadable certificate po harvestu:
    ```
    🏆 Certificate of Growth

    Congratulations! You successfully raised:
    "Zelinka" - Northern Lights

    Born: Jan 1, 2026
    Harvested: Mar 15, 2026
    Days alive: 73
    Final weight: 45g
    Quality rating: A+

    Your dedication earned you:
    - Green Thumb badge
    - 500 XP
    - Master Grower title
    ```

- **Post-harvest tribute:**
  - User může vytvořit "memorial post" s best fotkami
  - Community může reagovat a gratulovat
  - Share on social media

**Emotional connection = user retention!**

---

### 12. **Tolerance Break Tracker & Support** ⭐⭐⭐
**Proč:** Tolerance breaks jsou tough - app může pomoci, nikdo to zatím nedělá dobře

**Feature:**

**Phase 1: Decision & Setup**
- "Začít T-break?" → User zvolí délku (1 week, 2 weeks, 1 month)
- **Motivation picker:** "Proč to děláš?"
  - Snížit toleranci
  - Zdravotní důvody
  - Peníze ušetřit
  - Reset receptorů
  - Dokázat si, že to zvládneš

**Phase 2: Daily Support**
- **Daily check-in questions:**
  - "Jak se dnes cítíš?" (1-10)
  - "Měl jsi cravings?" (Yes/No)
  - "Jak ses vyspal?" (1-10)
  - "Úroveň anxiety?" (1-10)

- **Encouragement messages:**
  - Den 1: "První den je nejtěžší - jsi silnější než si myslíš! 💪"
  - Den 3: "Peak withdrawal - drž se! Za 4 dny bude lepší. 🌟"
  - Den 7: "Týden za tebou! Tvoje receptory ti děkují. 🧠"
  - Den 14: "Polovka! Tolerance je významně nižší. 🎯"
  - Poslední den: "DOKÁZAL JSI TO! 🎉"

- **Symptoms tracker:**
  - Irritability, insomnia, vivid dreams, appetite changes
  - Vizualizace: "Jak se měnily symptoms přes čas"
  - "Většina lidí má peak symptoms den 3-4, pak to jde z kopce"

**Phase 3: Gamifikace & Community**
- **Milestones:**
  - 24 hours → "First Day Hero" badge
  - 3 days → "Warrior" badge
  - 7 days → "Week Champion" badge
  - 14 days → "Tolerance Slayer" badge
  - 30 days → "Master of Willpower" badge (legendary rarity)

- **Leaderboard:**
  - Longest current T-break
  - Most T-breaks completed
  - Total days clean

- **Support Group Chat:**
  - Dedicated chat room pro lidi na T-break
  - Share progress, tips, encouragement
  - Veterans pomáhají newbies

- **Relapse forgiveness:**
  - Pokud user "spadne" ze T-breaku
  - App: "Je to OK! Zkusíme to znovu? Nastavme kratší cíl tentokrát."
  - No judgment, just support

**Phase 4: Return & Analysis**
- Po dokončení T-breaku:
  - **Before/After comparison:**
    - Tolerance level (estimated)
    - Baseline cognitive score před vs. po
    - Money saved calculator
    - Sleep quality trend

  - **First smoke back:**
    - App nabídne: "Zaznamenej svůj 'první smoke back'"
    - Extra detailed post-consumption check
    - "Jak se to lišilo od posledně?"
    - Community celebration post (optional)

**Monetizace:** Premium T-break coach s personalized tips

---

## 🎮 GAMIFIKACE 2.0

### 13. **Weekly Challenges & Raid Bosses** ⭐⭐
**Proč:** Daily quests jsou cool, ale weekly collective challenges zvyšují retention

**Feature:**

**Solo Weekly Challenges:**
- Každé pondělí nová sada 3 challenges:
  - **Explorer:** "Vyzkoušej 3 nové strains tento týden" (100 XP)
  - **Social Guru:** "Získej 50 reactions na své posty" (150 XP)
  - **Brain Athlete:** "Uděl cognitive test 5× a zlepši baseline" (200 XP)

**Community Raid Bosses:**
- Community goal, který všichni plní společně:
  ```
  🕷️ RAID BOSS: The Tolerance Titan

  Community cíl: Kolektivně udělejte 10,000 consumption trackingů
  Aktuální progress: 3,847 / 10,000 (38%)
  Čas do konce: 4 dny 13h

  Když dosáhneme cíle, všichni dostanete:
  - "Raid Hero" badge (rare)
  - 2x XP boost na 3 dny
  - Unlock nového strain card packu
  ```

- **Raid types:**
  - **Tolerance Titan** - Track consumption
  - **Knowledge Kraken** - Complete myth buster quizzes
  - **Growth Guardian** - Upload grow photos
  - **Chat Chimera** - Send messages in community rooms
  - **Brain Beast** - Do cognitive tests

**Live raid progress:**
- Real-time ticker na home screen: "Raid 47% completed! Přidej svůj příspěvek!"
- Top contributors leaderboard
- Animated boss "health bar" klesá s progress

---

### 14. **Achievement Showcase & Trophy Room** ⭐⭐
**Proč:** Users mají badges, ale nikde je neprezentují - trophy room = bragging rights

**Feature:**

**Trophy Room Screen:**
- 3D shelf nebo grid s:
  - Všemi badges (earned = barevné, locked = šedé)
  - Strain cards (nejlepší/nejzřídkavější)
  - Milestones (100 posts, 1000 XP, etc.)
  - Special achievements (First grow harvest, T-break 30 days)

**Customization:**
- User si vybere 3 "Featured achievements" na profil
- Zbytek viditelný jen v trophy room
- Pořadí lze přeházet drag & drop

**Showcase sharing:**
- "Share my trophy room" → generuje pěkný image pro social media
- Flex na Instagram/Twitter s: "Můj progress v Charlotte's Web 🕷️"

**Hidden achievements:**
- Některé badges jsou skryté (???)
- Community musí discovernout, jak je získat
- "Legend says someone found the 'Spider Lord' badge..."
- Vytváří mystery a exploration

---

### 15. **Seasonal Events & Limited Items** ⭐⭐
**Proč:** FOMO drives engagement - limited-time content zvyšuje daily active users

**Event ideas:**

**🎃 Halloween: "The Haunted Harvest"**
- Speciální halloween badges (Pumpkin King, Ghost Grower)
- Themed strain cards (Halloweed edition s halloween artwork)
- **Event quest:** "Post photo tvého scariest budu" → community voting
- **Raid:** "Harvest 666 grows as community"
- Limited halloween theme pro app (orange/black color scheme)
- Exclusive emoji reactions (pumpkin, ghost)

**🎄 Christmas: "Winter Wonderland"**
- Advent calendar - každý den unlock něčeho:
  - Den 1: Free rare strain card
  - Den 10: 2x XP boost
  - Den 24: Legendary "Santa's Secret" card
- **Snowball fight mini-game** v sessions
- Special winter strain recommendations
- "Gift a strain card" feature (pošli kamarádovi)

**🌱 Spring: "Green Awakening"**
- "Plant 100 grows as community" raid
- Free seeds (IRL giveaway integrace?)
- Grow tutorials spotlight
- "Best spring harvest" photo contest

**🔥 Summer: "Hot Streak Challenge"**
- Consecutive login streak competition
- Beach-themed strain cards
- "Chill sessions" - outdoor consumption tracking
- Summer blend recommendations (energizing strains)

**420 Event (April 20):**
- Celý den 4.20x XP multiplikátor
- Exclusive 420 badge (only earnable that day)
- Community sessions nabitý
- Special deals (pokud bude e-commerce)

---

### 16. **Referral Program & Grow Your Web** ⭐⭐
**Proč:** Organic growth je nejlevnější - incentivizuj users zvát kámoše

**Feature:**

**Invite mechanic:**
- User dostane unique referral link: `spiderbagzz.app/join/USERNAME`
- Sdílitelné na WhatsApp, Instagram, Twitter, SMS

**Rewards for referrer:**
- Každý nový user = 100 XP
- 5 friends = "Social Spider" badge + rare card pack
- 10 friends = "Web Builder" badge + 500 XP
- 25 friends = "Network Master" badge + legendary card

**Rewards for referred:**
- "Starter pack" po registraci:
  - 3 common strain cards
  - Welcome badge
  - 50 XP boost
  - "Invited by [Friend]" link v profilu (viditelné)

**Web visualization:**
- "Your web" screen: Graf všech lidí, kteří přišli přes tebe
- Jako pavučina - ty uprostřed, oni okolo
- Když oni pozvou další lidi, web se rozrůstá
- "Web size: 47 people"

**Leaderboard:**
- Biggest webs (kdo má nejvíc referrals)
- Monthly challenge: "Grow your web by 5 this month"

---

## 🧠 AI & ML INNOVATIONS

### 17. **Conversational AI Assistant "Charlotte"** ⭐⭐⭐
**Proč:** Chatbot průvodce je přístupnější než proklikávání menu

**Feature:**

**Meet Charlotte - Your Cannabis AI Guide:**
- Chat interface dostupný z FAB buttonu
- Conversational AI (GPT-powered nebo local model)

**Co Charlotte umí:**

**Strain recommendations:**
```
User: "Nemůžu spát"
Charlotte: "Chápu, problémy se spánkem jsou otravné.
Zkus Granddaddy Purple nebo Northern Lights - oba mají
vysoký Myrcene a Linalool, což pomáhá s relaxací.
Chceš víc detailů?"

User: "Jo"
Charlotte: "Granddaddy Purple je indica-dominant (80/20).
Průměrně 17% THC, dominantní terpeny: Myrcene 0.6%,
Caryophyllene 0.3%, Linalool 0.2%. Users reportují:
- Relaxace: 9/10
- Zlepšení spánku: 8.5/10
- Má ho na skladě Dispensary XY, cca 15 min od tebe.
Chceš přidat do wishlist?"
```

**Growing advice:**
```
User: "Listy žloutnou"
Charlotte: "Může to být několik věcí:
1. Nitrogen deficiency (nejčastější) - žloutnutí
   od spodu nahoru
2. Overwatering - kořeny nemají kyslík
3. pH problém - nutrient lockout

Uploadni fotku a já to určím přesněji! 📸"
```

**Data insights:**
```
User: "Jak se mi daří poslední týden?"
Charlotte: "Podívala jsem se na tvoje data:

📊 Cognitive trend: Klesá (-12% od baseline)
😴 Sleep: Horší (průměr 6.2h, obvykle 7.5h)
😟 Anxiety: Vyšší (průměr 6.8/10)

💡 Doporučení:
- Zvaž tolerance break
- Zkus strain s high Linalool (uklidní anxiety)
- Cognitive test pausni na pár dní

Chceš začít T-break? Pomůžu ti!"
```

**Quick actions:**
```
User: "Log consumption"
Charlotte: "Jasně! Jaký strain?"
User: "Blue Dream"
Charlotte: "Super. Kolik?"
User: "Joint"
Charlotte: "Noted. Jak se cítíš teď? (nebo to skipni)"
→ Rychlejší než proklikávat formuláře
```

**Personality:**
- Friendly, encouraging, non-judgmental
- Humor (lehký, ne přeháněný)
- Používá emojis občas
- Oslovuje "kamaráde", "bro", casual český styl

---

### 18. **Predictive Consumption Patterns** ⭐⭐
**Proč:** ML může odhalit patterns, které user sám nevidí

**Feature:**

**AI Pattern Detection Dashboard:**

**Temporal patterns:**
```
📅 Tvoje consumption vzorce:

Pondělí-Pátek:
- Peak čas: 18:00-20:00 (večer po práci)
- Preferované strains: Sativas (energizing po working day)

Víkendy:
- Rozprostřené přes den
- Preferované: Hybrids a indicas (chilll mode)

⚠️ Upozornění:
- Každý čtvrtek konzumace stoupá 2x
  (stress pattern? Weekend anticipation?)
```

**Mood correlation:**
```
💡 Zjistil jsem:

Když tvůj pre-consumption mood < 4/10:
- Konzumuješ o 30% víc
- Volíš strains s high Myrcene
- Post-consumption anxiety je vyšší

Doporučení: Když máš bad mood, nejdřív:
1. Holotrop breathing (5 min)
2. Pak konzumuj nižší množství
→ Data ukazují, že pak je post-anxiety o 40% nižší!
```

**Strain effectiveness over time:**
```
📉 Blue Dream effectiveness klesá:

První 3× použití: Focus boost +4.2 (avg)
Posledních 5× použití: Focus boost +1.8 (avg)

→ Možné důvody:
   - Tolerance build-up k tomuto strainuu
   - Receptor desensitization

💡 Doporučení: Rotuj strain. Zkus Sour Diesel
   (podobný profile, ale jiné terpeny)
```

**Health warnings:**
```
🚨 Health Alert:

Tvůj cognitive score klesl 3 týdny v řadě:
Week 1: 78/100
Week 2: 71/100
Week 3: 65/100

Anxiety průměr: 7.2/10 (high)
Consumption frequency: Denně

Strongly recommend:
- 7-day tolerance break
- Holotrop sessions (snížit anxiety)
- Po T-breaku nižší dávky
```

**UI:** Dashboard přístupný z Profile → Insights & Patterns

---

### 19. **Voice Logging & Hands-Free Mode** ⭐
**Proč:** Když jsi high, typing je annoying - voice je easy

**Feature:**

**Voice command system:**
```
"Hey Charlotte, log consumption"
→ Charlotte: "Sure! What strain?"
→ User: "Northern Lights, one joint"
→ Charlotte: "Got it. Northern Lights, joint method, logged!"

"Hey Charlotte, how am I feeling?"
→ Charlotte analyzuje poslední check-in a řekne summary

"Hey Charlotte, start breathing exercise"
→ Holotrop spustí breathing cycle

"Hey Charlotte, recommend something for creativity"
→ AI strain recommendation spustí
```

**Hands-free session mode:**
- Při smoke session aktivuj "Session Mode"
- App reaguje jen na voice
- Dimmed screen (battery save + discrete)
- Auto-log consumption na konci session
- Voice-activated music control (Spotify integration)
- "Charlotte, play chill vibes"

---

## 🌐 SOCIAL & COMMUNITY 2.0

### 20. **Grower Marketplace (Community-Driven)** ⭐⭐
**Proč:** Growers chtějí sdílet/trade seeds, clones, tips - community marketplace

**Feature:**

**⚠️ Legal disclaimer first:** Pouze pro legální jurisdikce, user potvrdí age/legal status

**Co lze tradovat:**
1. **Seeds** - Strain seeds, originals, crossbreeds
2. **Clones** - Živé klony od growerů
3. **Grow Equipment** - Použité lampy, stany, pots (second-hand)
4. **Knowledge** - Placené grow consultations (experienced grower → newbie)

**Listing creation:**
- Fotka item
- Popis, strain info (pokud seed/clone)
- Cena nebo "Trade only"
- Location (city level, ne přesná adresa)
- Reputation score (seller rating)

**Safety features:**
- Verified growers (badge systém)
- Rating/review system
- Escrow payments (pokud platby)
- Report system pro scams
- Age verification před přístupem

**Community aspect:**
- "Seed library" - dokumentace všech dostupných seeds
- Genetics tracking (kdo vypěstoval co z čeho)
- "I grew this from your seed!" shoutouts
- Grower reputation badges

**Monetizace:** 5% fee na transaction (pokud platby), nebo premium listings

---

### 21. **Collaborative Grow Journals** ⭐⭐
**Proč:** Growing přátelé chtějí trackovat společné grows

**Feature:**

**Create "Grow Crew":**
- 2-5 growerů shared grow journal
- Společný log:
  - Každý může přidat fotky, notes
  - Timeline je shared
  - Notifications pro všechny členky crew

**Use cases:**
- **Strain comparison grow:** 3 growers, každý stejný strain, different conditions → compare results
- **Mentorship grow:** Experienced grower + newbie, mentor sleduje progress a dává tipy
- **Outdoor grow group:** Kamarádi s outdoors v podobné location sledují weather, pesty společně

**Features:**
- Comments na fotky ostatních
- Voting "Best plant of the week"
- Milestones celebrations společně
- Final harvest party post

**Gamifikace:**
- "Dream Team" badge - úspěšný group grow
- "Mentor Master" badge - pomohl 5 newbies

---

### 22. **Strain Review System 2.0** ⭐⭐⭐
**Proč:** Reviews existují, ale líp gamifikovat a důvěryhodnost

**Upgrade:**

**Verified Reviews:**
- Review je "verified" pokud:
  - User uploadnul fotku budu
  - Má consumption log s tím strainem
  - Post-consumption check je vyplněný
- Verified reviews mají 🔹 badge a větší váhu v ratings

**Review struktur (detailnější):**
```
Strain: Blue Dream
Overall: 8.5/10

🎨 Bag Appeal: 9/10 (frosty, vibrant)
👃 Smell: 8/10 (berry + earthy)
👅 Taste: 7/10 (smooth, sweet)
💨 Smoke: 8/10 (not harsh)

Effects (věrohodné díky post-consumption data):
- Focus: +3.5 (measured)
- Mood: +2.8 (measured)
- Anxiety: -1.2 (snížení)
- Duration: 2.5h

📝 Notes: "Perfektní na kreativní práci. Neměl jsem
paranoia, ale hunger byl silný. Doporučuju pro daytime use."

🏷️ Best for: Creative work, Socializing, Daytime
❌ Not for: Sleep, Anxiety relief

👍 32 users found this helpful
```

**Community helpfulness voting:**
- "Was this review helpful?" → upvote/downvote
- Helpful reviews = vyšší v řazení
- Top reviewers dostávají "Critic" badge

**Comparison tool:**
- "Compare Blue Dream reviews across 50 users"
- See consistency: "94% users report mood boost"
- Divergence: "30% report anxiety, 70% don't" → depends on tolerance/sensitivity

**Reviewer reputation:**
- Reviewers mají trust score
- Based on: Verified reviews, helpfulness votes, consistency with data
- "Trusted Reviewer" badge

---

### 23. **Local Community & Meetups** ⭐
**Proč:** Online je cool, IRL meetups budují stronger connections

**Feature:**

**Local chapter discovery:**
- "Find users near you" (opt-in location)
- Filtr podle city
- Vidíš local leaderboard

**Meetup creation:**
- User vytvoří event:
  - "Smoke & Hike - Prague, Petřín Hill"
  - Datum, čas, místo (general area)
  - Max attendees (5-20)
  - Public nebo invite-only

**Event page:**
- Komentáře a RSVP
- "Who's coming" list
- Pre-event poll: "Jaký strain bereš?"
- Post-event photo dump
- Group session log (všichni dohromady)

**Safety features:**
- Age verification required
- Report system
- Meetup guidelines (respect, consent, legality)

**Gamifikace:**
- "Social Butterfly" badge - Attend 5 meetups
- "Event Host" badge - Host 3 meetups
- Group photo = bonus XP pro všechny attendees

---

## 🛠️ UX & QOL IMPROVEMENTS

### 24. **Smart Onboarding & Personalization** ⭐⭐⭐
**Proč:** Současný onboarding je generic - personalizuj experience od začátku

**New onboarding flow:**

**Step 1: Role selection**
```
Kdo jsi především?

🌱 Grower - Pěstuji vlastní
  → Přizpůsobíme Lab tools, diagnostics, nutrients

💨 Consumer - Konzumuji, negroduji
  → Focus na strain tracking, consumption logs, social

🧪 Both - Dělám obojí
  → Full experience

📚 Curious Learner - Chci jen info
  → Education-first (wiki, myths, terpenes)
```

**Step 2: Experience level**
```
Jaká je tvoje zkušenost s konopím?

🌱 Začátečník (0-1 rok)
🌿 Středně pokročilý (1-3 roky)
🍁 Zkušený (3-5 let)
🏆 Expert (5+ let)

→ Určuje složitost UI, dostupné features, tutorial depth
```

**Step 3: Interests (multi-select)**
```
Co tě zajímá?

- Strain genetics a história
- Terpene profily a effects
- Growing techniques
- Health & wellness
- Community a socializing
- Competitions & challenges

→ Přizpůsobí home feed, notifications, suggested content
```

**Step 4: Goals**
```
Proč používáš Charlotte's Web?

- Track consumption & effects
- Improve grows
- Connect with community
- Learn about cannabis
- Manage tolerance
- Health & cognitive tracking

→ Featured features na home screen podle goals
```

**Result:** Každý user má customized experience!

---

### 25. **Universal Search (Smart & Contextual)** ⭐⭐
**Proč:** Současná search je basic - smart search finds anything

**Feature:**

**One search bar pro vše:**
```
User types: "blue"

Results grouped:
🌿 Strains (3)
  - Blue Dream
  - Blue Cheese
  - Blueberry

👤 Users (5)
  - @bluesky
  - @blue_grower
  - @bluemoon_farm

📝 Posts (12)
  - "Just harvested Blue Dream..."
  - "Blue lights better for veg?"

🧪 Lab Grows (2)
  - "Blue Dream Grow #3" by @user

📰 Wiki (4)
  - "Blue Dream - Strain Info"
  - "Blueberry Genetics"

🔬 Terpenes (1)
  - Articles mentioning "blue"
```

**Smart contextual search:**
```
User is in Lab screen + searches "nitrogen"
→ Prioritizes: Nutrient deficiency articles, lab diagnostics, related posts

User is in Profile + searches "badges"
→ Shows: Badge list, how to earn, who has most
```

**Recent searches:**
- History posledních 10 searches
- Quick access

**Search filters:**
- Filter by: People, Strains, Posts, Grows, Wiki
- Sort by: Relevance, Recent, Popular

**Voice search:**
- "Hey Charlotte, find Blue Dream"

---

### 26. **Offline Mode & Sync** ⭐⭐
**Proč:** Users growují v basement/outdoor = no internet

**Feature:**

**Full offline support:**
- **Write offline:**
  - Create grow notes
  - Log consumption
  - Take photos (stored local)
  - Daily check-ins
  - Cognitive tests (works offline)

- **Offline queue:**
  - Všechny akce se queue-ují
  - Jakmile je internet, auto-sync
  - Notification: "Synced 5 items"

- **Pre-cache content:**
  - User can "Download for offline":
    - Wiki articles
    - Strain database
    - Terpene info
    - Grow journal (photos preloaded)

- **Offline indicator:**
  - Subtle banner: "Offline mode - will sync when online"
  - Shows queue count: "3 items waiting to sync"

**Smart sync:**
- Sync přes WiFi (ne mobile data) pro velké soubory
- Compression photos before upload
- Batch sync (ne každý item zvlášť)

---

### 27. **Accessibility & Inclusivity** ⭐⭐⭐
**Proč:** Každý by měl mít přístup, včetně users s disabilities

**Features:**

**Screen reader support:**
- Všechny images mají alt text
- Buttons properly labeled
- Navigation hierarchy clear

**Font size control:**
- Settings: Malé / Střední / Velké / Extra velké
- Re-scales všechno UI

**High contrast mode:**
- Pro users s vision impairment
- Vyšší contrast mezi text a background
- Thicker borders

**Dyslexia-friendly font:**
- Option zapnout OpenDyslexic font
- Larger letter spacing

**Color blind modes:**
- Protanopia (red-blind)
- Deuteranopia (green-blind)
- Tritanopia (blue-blind)
- Adjustuje barvy rarity, ranks, graphs

**Voice controls:**
- Celá app ovládatelná voice (viz feature 19)

**Simplified UI mode:**
- Pro users s cognitive challenges
- Removes clutter, bigger buttons, clearer labels

---

### 28. **Data Export & Privacy Tools** ⭐⭐⭐
**Proč:** GDPR compliance + users chtějí vlastnit data

**Features:**

**Export all data:**
- Settings → Privacy → Export My Data
- Generates ZIP file:
  - JSON všech consumption logs
  - Cognitive test results (CSV)
  - Grow journals (photos + notes)
  - Posts, comments, messages
  - Badges, cards, XP history

**Delete account:**
- Jasný button "Delete My Account"
- Warning o necessary
- Confirmation + password
- Permanent deletion do 30 dní (grace period)

**Privacy dashboard:**
- See who follows you
- See who you've blocked
- Message encryption status
- Location data usage

**Granular permissions:**
- "Who can see my consumption logs?" → Nobody/Friends/Everyone
- "Who can see my grows?" → Private/Friends/Public
- "Show me in local discovery?" → Yes/No
- "Allow AI training on my data?" → Yes/No

**Transparency report:**
- "Your data usage":
  - How many posts
  - How much storage
  - What's shared publicly vs private

---

## 📊 ANALYTICS & INSIGHTS

### 29. **Annual Wrapped / Year in Review** ⭐⭐⭐
**Proč:** Spotify Wrapped je viral každý rok - Charlotte's Wrapped by bylo epické

**Feature:**

**Generate každý prosinec:**

```
🕷️ YOUR 2026 CHARLOTTE'S WEB WRAPPED

📅 This Year You...
- Logged 247 consumption sessions
- Tried 38 unique strains
- Your favorite: Blue Dream (consumed 32x)
- Total: 156g tracked

🧠 Your Mind This Year:
- Completed 89 cognitive tests
- Average score: 76/100 (↑ 8% from 2025!)
- Best month: June (82/100 avg)
- Your brain health: Stable 💚

🌱 Growing Journey:
- Completed 3 grows
- Harvested 127g total
- Best yield: Northern Lights (62g)
- You earned "Green Thumb" badge

🎮 Gamification Stats:
- XP gained: 4,892
- Rank achieved: Weaver 🕸️
- Badges earned: 12 (incl. 2 rares!)
- Strain cards collected: 47

💬 Social Highlights:
- Posts created: 34
- Comments: 189
- Likes given: 1,203
- New friends: 24
- Most liked post: "My first successful harvest! 🌿"

🏆 Your Achievements:
- Longest T-break: 14 days
- Best cognitive test: 94/100 (Mar 15)
- Highest XP day: 250 XP (Apr 20 - 420 event)

🌟 Your Top Terpene: Myrcene
You gravitated toward strains with high Myrcene
this year. It helped you with relaxation and sleep.

📈 2027 Goals:
Based on your data, we suggest:
- Try Sativa-dominant strains more
- Experiment with edibles
- Join more community sessions
- Complete all daily quests (you did 68% this year)

Share your Wrapped! 🔗
```

**Shareable graphics:**
- Generuje Instagram-style graphics:
  - "My #1 strain: Blue Dream"
  - "I'm a Weaver in Charlotte's Web"
  - "Collected 47 strain cards in 2026"
- Users sdílí na social media → viral marketing!

---

### 30. **Real-Time Dashboard (Pro Feature)** ⭐⭐
**Proč:** Power users chtějí detailní statistiky live

**Feature:**

**Charlotte's Web Pro:**
- Měsíční subscription (99 Kč/měsíc nebo 999 Kč/rok)

**Pro Dashboard obsahuje:**

**Live Stats:**
- Real-time cognitive score trend
- Current tolerance estimate
- Consumption frequency graph
- Money spent calculator (CZK)
- Health score meter (0-100)

**Advanced Analytics:**
- Strain correlation matrix:
  - Která kombinace strains má best synergy
  - "Blue Dream + Northern Lights evenings = best sleep"

- Terpene sensitivity breakdown:
  - Jak každý terpene ovlivňuje tvoje metrics
  - "Limonene boosts your mood +2.8 avg"

- Predictive insights:
  - "Based on trends, you'll need T-break in 3 weeks"
  - "Your focus peaks at 4pm - ideal time for work strains"

- Comparison to community:
  - "Your consumption: 20% below average"
  - "Your cognitive score: Top 15% of users"

**Export reports:**
- PDF report měsíčně
- Share s lékařem (pokud medical patient)

**Custom alerts:**
- "Alert me when anxiety > 7 for 3 days"
- "Notify me when cognitive score drops 15%"

---

## 🔮 FUTURE-FORWARD FEATURES

### 31. **IoT Integration** ⭐
**Proč:** Smart devices jsou budoucnost growing

**Feature:**

**Connect smart devices:**

**Supported devices:**
- **Smart grow tents:** Grobo, Cloudponics, etc.
- **Environment sensors:** Temp, humidity, CO2
- **Smart lights:** Philips Hue, grow lights s WiFi
- **Irrigation systems:** Automated watering

**Integration:**
- Auto-log environment data do grow journal
- Graphs: temp/humidity trends přes čas
- Alerts: "Humidity too high! (78%)"
- Automation: "Turn on lights at 6am daily"

**Grow optimization AI:**
- AI analyzuje sensor data + tvůj grow outcome
- "Your humidity was suboptimal week 3-4, that's why yield was lower"
- "Next time, increase light intensity week 5 → +15% yield predicted"

---

### 32. **VR Grow Room Tours** ⭐
**Proč:** Showcase growery virtuálně, immersive experience

**Feature:**

**Create VR tour:**
- User nahraje 360° video nebo fotky grow setup
- Upload do app
- Others můžou "navštívit" grow room v VR

**Use cases:**
- **Showoff:** "Check out my grow room!"
- **Learning:** New growers see expert setups
- **Marketplace:** Sell equipment = showcase in VR

**VR session rooms:**
- Smoking session v VR space
- Avatars, voice chat
- Shared virtual environment (lounge, forest, space)

**Tech:** WebXR nebo Flutter VR plugin, accessible přes VR headsets nebo cardboard

---

### 33. **Blockchain Strain Provenance** ⭐
**Proč:** Authenticate genetics, track seed origin, NFT collectibles

**Feature:**

**Strain NFTs:**
- Limited edition strain cards jako NFTs
- Vlastnictví on-chain
- Tradeable na marketplace
- Rarity verified blockchain

**Seed provenance:**
- Každý seed batch má blockchain record:
  - Breeder origin
  - Parent genetics
  - Batch number
  - Grow history (kdo to growoval, yield)
- "Certificate of Authenticity" pro rare genetics

**Grower reputation on-chain:**
- Immutable grow history
- Verified harvests
- Can't fake reputation

**Monetizace:**
- Trading fee na NFT marketplace
- Premium genetics sellers

---

### 34. **Integration s E-commerce / Dispensaries** ⭐⭐
**Proč:** Seamless buy flow = convenience

**Feature:**

**Dispensary locator:**
- Mapa local dispensaries (legal markets)
- Real-time stock info (pokud dispensaries integrate API)
- Reviews of dispensaries

**Direct ordering:**
```
User browsing Blue Dream strain page →
Button: "Buy Near Me"
→ Shows 3 dispensaries with stock
→ Click → redirect to dispensary website/app
→ (nebo in-app checkout pokud partnerships)
```

**Price comparison:**
- Strain X na 5 dispensaries: Prices od 200-350 Kč/g
- Best deal highlighted

**Affiliate commissions:**
- Každý nákup přes app = Charlotte's Web dostává cut
- Revenue stream

**Loyalty program integration:**
- Dispensary loyalty card integrated do app
- Track points, discounts v Charlotte's Web

---

### 35. **Cannabis Genome Sequencing Integration** ⭐
**Proč:** Cutting-edge science - genomika přináší přesné info

**Feature:**

**Partner s labs:**
- Phylos Bioscience, Medicinal Genomics
- Users můžou poslat sample do lab
- Lab sekvenuje genome
- Výsledky importované do Charlotte's Web

**Co genome sequencing dává:**
- Přesné terpene profily
- Cannabinoid breakdown (nejen THC/CBD, ale i CBG, CBN, THCV...)
- True genetic lineage (ne jen claimed genetics)
- Contamination detection (mold, pesticides on DNA level)

**In-app:**
- "Genome Verified" badge na strain
- Detail genome report visualized
- Compare genome vs. claimed genetics
- "This 'Blue Dream' je actually 73% match to true Blue Dream genetics"

**Community science:**
- Aggregate genome data → best strain database ever
- "Crowdsourced Cannabis Genome Project"

---

## 🎬 BONUS: WILD MOONSHOT IDEAS

### 36. **AI-Generated Strain Simulator** 🌙
"Vyzkoušej" strain virtuálně before trying IRL
- Popis effects based na terpene profile
- VR visuals simulující headspace
- Audio (binaural beats matching strain vibe)
- "Experience Sativa vs Indica virtually"

### 37. **Dream Journal Integration** 🌙
Trackuj dreams během T-breaku
- "Vivid dreams" jsou common symptom
- Log dreams daily
- AI analyzuje themes
- Correlation mezi strain use a dream patterns

### 38. **Music Mood Matcher** 🌙
AI generuje playlist based na strain
- "Blue Dream vibes" → chill electronic
- "Sour Diesel vibes" → upbeat hip-hop
- Spotify/Apple Music integration
- Community-voted playlists per strain

### 39. **Munchies AI** 🌙
What to eat when high
- Recommends food based na:
  - Appetite level (tracked in post-consumption)
  - Time of day
  - Dietary restrictions
  - "Users who like Blue Dream also crave pizza"
- Recipe suggestions
- Delivery integration (Wolt, UberEats)

### 40. **Pet Cam Integration** 🌙
Watch your pets when you're high
- Integrate pet cam feed do app
- "Chill with your cat while smoking"
- Community share funny pet videos
- Badge "Pet Parent"

---

## 🏁 IMPLEMENTATION PRIORITY MATRIX

### **Phase 1: Foundation (Q1 2026)** ⭐⭐⭐
1. Micro-interactions & animations (#1)
2. Smart onboarding (#24)
3. Universal search (#25)
4. Charlotte AI assistant (#17)
5. Mood-based recommender (#8)

### **Phase 2: Engagement (Q2 2026)** ⭐⭐⭐
6. Social smoke sessions (#7)
7. Weekly challenges & raids (#13)
8. Tolerance break tracker (#12)
9. Annual Wrapped (#29)
10. Strain review 2.0 (#22)

### **Phase 3: Depth (Q3 2026)** ⭐⭐
11. AR strain scanner (#6)
12. Genetics explorer (#9)
13. Terpene profile builder (#10)
14. Plant parenthood mode (#11)
15. Predictive patterns (#18)

### **Phase 4: Ecosystem (Q4 2026)** ⭐⭐
16. Grower marketplace (#20)
17. E-commerce integration (#34)
18. Referral program (#16)
19. IoT integration (#31)
20. Real-time dashboard Pro (#30)

### **Phase 5: Innovation (2027)** ⭐
21. VR experiences (#32)
22. Blockchain provenance (#33)
23. Genome sequencing (#35)
24. Wild moonshot ideas (#36-40)

---

## 🎯 METRICS TO TRACK SUCCESS

**Engagement:**
- Daily Active Users (DAU)
- Session length
- Feature adoption rate
- Retention (D1, D7, D30)

**Social:**
- Posts per user per week
- Comments & reactions
- Session room usage
- Referrals

**Gamification:**
- XP growth rate
- Badge completion %
- Daily quest completion
- Card collection rate

**Revenue (if monetized):**
- Pro subscription conversion
- Marketplace transaction volume
- Affiliate commission
- In-app purchases

---

## 💭 CLOSING THOUGHTS

Charlotte's Web je už teď **nejkomplexnější cannabis tracking app** na trhu. Tyto features by ji posunuly na úplně jinou úroveň:

1. **AI-first experience** - Charlotte asistent + predictive insights
2. **Social interactions** - Live sessions, collaborative grows, meetups
3. **Deep personalization** - Od onboardingu po customizable themes
4. **Science-backed** - Genome sequencing, IoT, terpene profiling
5. **Gamifikace 2.0** - Raids, seasonal events, hidden achievements
6. **Wellness focus** - T-break support, Holotrop, cognitive monitoring

**Konkurence nemá šanci. 🕷️**

---

**Next steps:**
1. Prioritizuj features podle resources a impact
2. User research - co users nejvíc chtějí?
3. Prototypuj top 5 features
4. Beta test s community
5. Iterate based na feedback
6. Ship! 🚀

---

*Vytvořil Claude Sonnet 4.5 | 2026-01-30*