# Spiderbagzz Community App - TODO

## HOTOVO

### Follow system
- [x] FollowButton widget (animace, kompaktni verze)
- [x] FollowersListModal (seznam sledujicich/sledovanych)
- [x] UserProfileScreen (profil ciziho uzivatele)
- [x] Navigace na profil z feedu, komentaru, vyhledavani
- [x] Route /profile/:userId

### Gamifikace
- [x] Badges system (odznaky s raritami)
- [x] XP a levely
- [x] Leaderboard
- [x] Sbirka karet

### Zakladni funkce
- [x] Feed s thread typy (Diskuze, Otazka, Oznameni)
- [x] Komentare
- [x] Reakce (lajky)
- [x] Bookmarky
- [x] Notifikace
- [x] E2EE chat
- [x] Admin dashboard
- [x] Vyhledavani (prispevky + uzivatele)
- [x] Dark theme

### Vizualni identita (Customization) - NOVE
- [x] GlitchAvatar widget - glitch efekty, neonovy okraj podle ranku
  - Styly: none, subtle, classic, neon, web, pulse, fire
  - Automaticky styl podle ranku (master=fire, widow=neon, weaver=web...)
  - SpiderIllustration - vyber pavoucich ilustraci
- [x] ProfileBanner widget - profilove pozadi
  - Styly: simple, gradient, parallax, blur, animatedGradient
  - BannerPresets - prednastavene gradienty
  - BannerPicker widget pro vyber
- [x] ProfileBio widget - bio s tagy a odkazy
  - Parsovani #hashtagu, @zminky, URL odkazu
  - BioTagPicker - vyber tagu (emoji + label)
  - BioEditor - kompletni editor s nahledem
  - ProfileInfoRow - lokace a web

### Herni statistiky
- [x] Level Bar: Viditelny ukazatel XP
- [x] Badges (Odznaky): Male ikonky pod jmenem
- [x] ReputationBadge widget - pavoici vlakna (lajky)
  - Styly: simple, web, animated, compact
  - ReputationStats - detailni statistiky

### Nastaveni soukromi a bezpecnosti
- [x] PrivacySettings model a widget
- [x] Anonymni mod: Skryti profilu z vyhledavani
- [x] Ghost Mode: Skryti polohy u fotek
- [x] Burner Account: Dialog pro smazani vsech dat
- [x] AnonymousModeToggle - rychly prepinac

### Obrazovka profilu (UI)
- [x] Hlavicka: Kruhovy avatar s neonovym okrajem
- [x] Stats Row: 3 sloupce (Prispevky, Sledovatele, Sleduje)
- [x] Bio: Podpora pro tagy, emoji, odkazy
- [x] Tab Bar: Prepinac Galerie / Ulozene / Oznacene



## K IMPLEMENTACI

### Digitalni "Stash" (Vlastni sbirka)
Unikatni funkce pro tuhle komunitu. Profil by mel slouzit jako archiv:
- [ ] My Stash: Seznam strainu, ktere uzivatel vyzkousel a ohodnotil
- [ ] Vlastni fotky: Galerie vsech fotek, ktere uzivatel nahral
- [ ] Wishlist: Co by chtel uzivatel vyzkouset

### Dalsí vylepseni
- [ ] Integrace novych widgetu do ProfileScreen a EditProfileScreen
- [ ] Backend pro privacy settings (Supabase)
- [ ] Backend pro banner URL v profiles tabulce
