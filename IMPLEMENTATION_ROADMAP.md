# 🕷️ CHARLOTTE'S WEB - IMPLEMENTATION ROADMAP

> **Status:** Ready to implement
> **Marketplace features:** EXCLUDED (not allowed yet)
> **Timeline:** 6-month plan (Feb - Jul 2026)

---

## 🎯 STRATEGIC APPROACH

**Principles:**
1. **Quick wins first** - Features s high impact, low effort
2. **Foundation before fancy** - Core improvements před advanced features
3. **Test early** - Beta test s community každý měsíc
4. **Iterate fast** - Ship, measure, improve
5. **User feedback loop** - Community votes na next features

---

## 📅 PHASE 1: POLISH & FOUNDATION (Feb 2026) - 4 weeks

**Goal:** Vylepšit současné UX, přidat animations, zpevnit základ

### Week 1-2: Micro-interactions & Visual Polish
**Features:**
- ✅ Pull-to-refresh s pavučinou animací
- ✅ Card hover/tap effects (glow podle rarity)
- ✅ XP gain animation (particles do rank badge)
- ✅ Rank up celebration (fullscreen s confetti)
- ✅ Loading states - animated spider spinning web
- ✅ Button ripple effects (cyan ripple)
- ✅ Tab transitions (smooth slides)

**Files to modify:**
```
lib/widgets/
├── common/animated_xp_gain.dart (NEW)
├── common/spider_loader.dart (NEW)
├── gamification/rank_up_celebration.dart (NEW)
└── feed/pull_to_refresh_spider.dart (NEW)

lib/screens/
└── home/home_screen.dart (ADD tab animations)
```

**Effort:** Medium | **Impact:** High (visual wow factor)

---

### Week 3: Smart Onboarding
**Features:**
- ✅ Role selection (Grower / Consumer / Both / Learner)
- ✅ Experience level picker
- ✅ Interest selection (multi-select)
- ✅ Goal setting
- ✅ Personalized home screen based on preferences

**Files to create:**
```
lib/screens/onboarding/
├── role_selection_screen.dart (NEW)
├── experience_level_screen.dart (NEW)
├── interests_screen.dart (NEW)
└── goals_screen.dart (NEW)

lib/models/
└── user_preferences_model.dart (NEW)

lib/services/
└── personalization_service.dart (NEW)
```

**Effort:** Medium | **Impact:** High (retention boost)

---

### Week 4: Universal Search
**Features:**
- ✅ One search bar pro všechno
- ✅ Grouped results (Strains, Users, Posts, Grows, Wiki)
- ✅ Recent searches history
- ✅ Search filters
- ✅ Contextual search (based on current screen)

**Files to modify:**
```
lib/screens/search/
└── universal_search_screen.dart (MAJOR UPDATE)

lib/services/
└── search_service.dart (ADD universal search logic)

lib/widgets/search/
├── search_result_card.dart (NEW)
└── search_filters.dart (NEW)
```

**Effort:** Medium | **Impact:** High (discoverability)

---

## 📅 PHASE 2: AI & INTELLIGENCE (Mar 2026) - 4 weeks

**Goal:** Přidat AI features, které poskytují value

### Week 5-6: Charlotte AI Assistant
**Features:**
- ✅ Chat interface (FAB button)
- ✅ Conversational AI (OpenAI GPT-4 API)
- ✅ Strain recommendations via chat
- ✅ Growing advice
- ✅ Data insights summary
- ✅ Quick actions (log consumption, start T-break)

**Files to create:**
```
lib/screens/ai/
└── charlotte_chat_screen.dart (NEW)

lib/services/
└── charlotte_ai_service.dart (NEW)

lib/models/
├── chat_message_model.dart (NEW)
└── ai_context_model.dart (NEW)

lib/widgets/ai/
├── chat_bubble.dart (NEW)
├── typing_indicator.dart (NEW)
└── quick_action_chips.dart (NEW)
```

**API Integration:**
- OpenAI GPT-4 API
- Context building z user data (consumption, cognitive, grows)
- Streaming responses

**Effort:** High | **Impact:** VERY HIGH (game changer)

---

### Week 7-8: Mood-Based Strain Recommender
**Features:**
- ✅ AI recommendation engine
- ✅ Input: current mood, time, goals, history
- ✅ Output: Top 3 strain recommendations s reasoning
- ✅ "Why this?" explanations
- ✅ Best time to consume
- ✅ User feedback loop (thumbs up/down)

**Files to create:**
```
lib/screens/recommender/
└── strain_recommender_screen.dart (NEW)

lib/services/
└── recommendation_ai_service.dart (NEW)

lib/models/
└── recommendation_model.dart (NEW)

lib/widgets/recommender/
├── recommendation_card.dart (NEW)
└── reasoning_explanation.dart (NEW)
```

**Algorithm:**
- ML model nebo rule-based na začátku
- Weighted scoring:
  - Historical preference: 40%
  - Terpene match: 30%
  - Time of day: 15%
  - Current mood delta: 15%

**Effort:** High | **Impact:** VERY HIGH (instant value)

---

## 📅 PHASE 3: SOCIAL & ENGAGEMENT (Apr 2026) - 4 weeks

**Goal:** Posílit social features, zvýšit engagement

### Week 9-10: Social Smoke Sessions (Live)
**Features:**
- ✅ Create session room (public/private)
- ✅ Live chat v session
- ✅ Emoji reactions (floating)
- ✅ Timer countdown
- ✅ Real-time mood tracking
- ✅ Session games (Higher/Lower, Strain Guess)
- ✅ Post-session recap

**Files to create:**
```
lib/screens/sessions/
├── create_session_screen.dart (NEW)
├── live_session_screen.dart (NEW)
└── session_recap_screen.dart (NEW)

lib/services/
├── session_service.dart (NEW)
└── session_realtime_service.dart (NEW - Supabase Realtime)

lib/models/
├── session_model.dart (NEW)
└── session_participant_model.dart (NEW)

lib/widgets/sessions/
├── floating_emoji.dart (NEW)
├── session_timer.dart (NEW)
├── session_game_card.dart (NEW)
└── mood_tracker_live.dart (NEW)
```

**Backend:**
- Supabase Realtime channels
- Session state management
- Auto-cleanup finished sessions

**Effort:** Very High | **Impact:** VERY HIGH (viral potential)

---

### Week 11-12: Weekly Challenges & Raid Bosses
**Features:**
- ✅ Weekly challenge system
- ✅ Community raid bosses
- ✅ Progress bars & live updates
- ✅ Rewards (badges, XP boosts, card packs)
- ✅ Leaderboards (top contributors)
- ✅ Raid types (consumption tracking, quizzes, grows, tests)

**Files to create:**
```
lib/screens/challenges/
├── weekly_challenges_screen.dart (NEW)
├── raid_boss_screen.dart (NEW)
└── challenge_leaderboard_screen.dart (NEW)

lib/services/
├── challenge_service.dart (NEW)
└── raid_service.dart (NEW)

lib/models/
├── challenge_model.dart (NEW)
└── raid_boss_model.dart (NEW)

lib/widgets/challenges/
├── challenge_card.dart (NEW)
├── raid_progress_bar.dart (NEW)
└── raid_boss_animation.dart (NEW)
```

**Gamification:**
- Weekly rotation (reset každé pondělí)
- Community progress aggregation
- Celebration při dokončení raidu

**Effort:** High | **Impact:** High (retention)

---

## 📅 PHASE 4: WELLNESS & TRACKING (May 2026) - 4 weeks

**Goal:** Health features, T-break support, advanced tracking

### Week 13-14: Tolerance Break Tracker
**Features:**
- ✅ T-break setup (délka, motivace)
- ✅ Daily check-ins
- ✅ Encouragement messages (personalized)
- ✅ Symptoms tracker
- ✅ Milestones & badges
- ✅ Support group chat
- ✅ Relapse handling (no judgment)
- ✅ Before/after comparison

**Files to create:**
```
lib/screens/tbreak/
├── tbreak_setup_screen.dart (NEW)
├── tbreak_dashboard_screen.dart (NEW)
├── tbreak_daily_checkin_screen.dart (NEW)
└── tbreak_completion_screen.dart (NEW)

lib/services/
└── tbreak_service.dart (NEW)

lib/models/
├── tbreak_model.dart (NEW)
└── tbreak_checkin_model.dart (NEW)

lib/widgets/tbreak/
├── tbreak_timer.dart (NEW)
├── encouragement_card.dart (NEW)
├── symptoms_tracker.dart (NEW)
└── milestone_badge.dart (NEW)
```

**Support features:**
- Push notifications (daily encouragement)
- Symptom education (co čekat)
- Money saved calculator

**Effort:** Medium | **Impact:** High (wellness focus)

---

### Week 15-16: Predictive Consumption Patterns
**Features:**
- ✅ AI pattern detection dashboard
- ✅ Temporal patterns (kdy konzumuješ)
- ✅ Mood correlation analysis
- ✅ Strain effectiveness over time
- ✅ Health warnings (cognitive decline, anxiety spikes)
- ✅ Predictive alerts

**Files to create:**
```
lib/screens/insights/
└── patterns_dashboard_screen.dart (NEW)

lib/services/
└── pattern_detection_service.dart (NEW)

lib/models/
└── pattern_insight_model.dart (NEW)

lib/widgets/insights/
├── pattern_chart.dart (NEW)
├── correlation_heatmap.dart (NEW)
└── prediction_card.dart (NEW)
```

**Analytics:**
- Time series analysis
- Correlation matrices
- Threshold alerts
- Trend lines

**Effort:** High | **Impact:** High (data-driven value)

---

## 📅 PHASE 5: ADVANCED FEATURES (Jun 2026) - 4 weeks

**Goal:** Cutting-edge features, deep personalization

### Week 17-18: Strain Genetics Explorer (Interactive Tree)
**Features:**
- ✅ Interactive family tree visualization
- ✅ Zoom/pan controls
- ✅ Strain info on tap
- ✅ Parent-child relationships
- ✅ Color coding (Indica/Sativa/Hybrid)
- ✅ Discover mode (filters)
- ✅ "I've tried this" badges
- ✅ Genetics Nerd badge

**Files to create:**
```
lib/screens/genetics/
└── genetics_explorer_screen.dart (NEW)

lib/services/
└── genetics_service.dart (NEW)

lib/models/
└── strain_genetics_model.dart (NEW)

lib/widgets/genetics/
├── genetics_tree_widget.dart (NEW - Custom Canvas)
├── strain_node.dart (NEW)
└── genetics_info_popup.dart (NEW)

lib/data/
└── strain_genetics_tree.json (NEW - relationships data)
```

**Visualization:**
- Custom Flutter Canvas painting
- Graph layout algorithm (force-directed)
- Nebo použít graphview package

**Effort:** Very High | **Impact:** Medium (niche, but cool)

---

### Week 19-20: Terpene Profile Builder & Blending
**Features:**
- ✅ Terpene quiz (personal sensitivity)
- ✅ Personal terpene profile
- ✅ Ideal mix calculation
- ✅ Strain blending recommender
- ✅ Grow optimization tips (pro growery)

**Files to create:**
```
lib/screens/terpenes/
├── terpene_quiz_screen.dart (NEW)
├── terpene_profile_screen.dart (NEW)
└── blend_recommender_screen.dart (NEW)

lib/services/
└── terpene_blending_service.dart (NEW)

lib/models/
├── terpene_profile_model.dart (NEW)
└── blend_recommendation_model.dart (NEW)

lib/widgets/terpenes/
├── terpene_wheel.dart (NEW)
├── blend_chart.dart (NEW)
└── profile_radar_chart.dart (NEW)
```

**Science:**
- Terpene synergy calculations
- Entourage effect modeling
- Grow condition recommendations

**Effort:** High | **Impact:** Medium (advanced users)

---

## 📅 PHASE 6: GAMIFICATION 2.0 & POLISH (Jul 2026) - 4 weeks

**Goal:** Finální gamifikace, seasonal events, achievements

### Week 21-22: Achievement Showcase & Trophy Room
**Features:**
- ✅ Trophy room 3D shelf/grid
- ✅ Featured achievements (3 on profile)
- ✅ Customization (drag & drop order)
- ✅ Share trophy room (social media graphics)
- ✅ Hidden achievements (???)
- ✅ Discovery hints

**Files to create:**
```
lib/screens/gamification/
├── trophy_room_screen.dart (NEW)
└── achievement_detail_screen.dart (NEW)

lib/widgets/gamification/
├── trophy_shelf.dart (NEW)
├── achievement_card_3d.dart (NEW)
└── trophy_share_generator.dart (NEW)

lib/services/
└── achievement_service.dart (UPGRADE)
```

**Visuals:**
- 3D-style shelf rendering
- Shimmer effects na rare items
- Particle effects při unlock

**Effort:** Medium | **Impact:** Medium (bragging rights)

---

### Week 23: Seasonal Events System
**Features:**
- ✅ Event framework (setup)
- ✅ Event calendar
- ✅ Event-specific badges, cards, themes
- ✅ Limited-time challenges
- ✅ Event leaderboards

**Files to create:**
```
lib/screens/events/
├── event_calendar_screen.dart (NEW)
└── active_event_screen.dart (NEW)

lib/services/
└── event_service.dart (NEW)

lib/models/
├── event_model.dart (NEW)
└── event_reward_model.dart (NEW)

lib/data/events/
├── halloween_event.json (NEW)
├── christmas_event.json (NEW)
└── 420_event.json (NEW)
```

**Event types:**
- 🎃 Halloween (Oct)
- 🎄 Christmas (Dec)
- 🌱 Spring (Mar-Apr)
- 🔥 420 (Apr 20)

**Effort:** Medium | **Impact:** High (engagement spikes)

---

### Week 24: Referral Program & Grow Your Web
**Features:**
- ✅ Unique referral links
- ✅ Rewards for referrer & referred
- ✅ Web visualization (pavučina růstu)
- ✅ Leaderboard (biggest webs)
- ✅ Referral badges

**Files to create:**
```
lib/screens/referral/
├── referral_screen.dart (NEW)
└── web_visualization_screen.dart (NEW)

lib/services/
└── referral_service.dart (NEW)

lib/models/
└── referral_model.dart (NEW)

lib/widgets/referral/
├── referral_link_card.dart (NEW)
└── web_graph_widget.dart (NEW)
```

**Backend:**
- Unique link generation
- Referral tracking
- Reward distribution

**Effort:** Medium | **Impact:** High (organic growth)

---

## 📅 PHASE 7: UX POLISH & EXTRAS (Ongoing)

### Features to sprinkle throughout:

**Dark Mode Variants** (Low effort)
- 3 dark themes
- Accent color picker
- Settings integration

**Glassmorphism** (Medium effort)
- Navigation bar
- Modal dialogs
- Bottom sheets
- Toast notifications

**Voice Logging** (High effort)
- Voice commands
- Hands-free mode
- Charlotte voice responses

**Offline Mode** (High effort)
- Offline queue
- Content pre-cache
- Smart sync

**Accessibility** (Medium effort)
- Screen reader support
- Font size control
- High contrast mode
- Color blind modes

**Data Export** (Low effort)
- Export all data (ZIP)
- Privacy dashboard
- Delete account flow

---

## 📅 PHASE 8: ANALYTICS & INSIGHTS (Aug 2026)

### Week 25-26: Annual Wrapped
**Features:**
- ✅ Year in Review generator
- ✅ Stats summary (consumption, cognitive, growing, social)
- ✅ Top strains, achievements, highlights
- ✅ Shareable graphics (Instagram-style)
- ✅ 2027 goals suggestions

**Files to create:**
```
lib/screens/wrapped/
├── wrapped_intro_screen.dart (NEW)
├── wrapped_stats_screen.dart (NEW)
└── wrapped_share_screen.dart (NEW)

lib/services/
└── wrapped_generator_service.dart (NEW)

lib/widgets/wrapped/
├── wrapped_card.dart (NEW)
└── share_graphic_generator.dart (NEW)
```

**Data aggregation:**
- Celý rok data processing
- Beautiful visualizations
- Share buttons (IG, Twitter, FB)

**Effort:** High | **Impact:** VERY HIGH (viral potential)

---

### Week 27-28: Real-Time Dashboard Pro
**Features:**
- ✅ Pro subscription setup
- ✅ Advanced analytics
- ✅ Live stats
- ✅ Strain correlation matrix
- ✅ Terpene sensitivity breakdown
- ✅ Predictive insights
- ✅ Custom alerts
- ✅ PDF reports

**Files to create:**
```
lib/screens/pro/
├── pro_dashboard_screen.dart (NEW)
├── pro_subscription_screen.dart (NEW)
└── pro_analytics_screen.dart (NEW)

lib/services/
├── subscription_service.dart (NEW)
└── advanced_analytics_service.dart (NEW)

lib/models/
└── subscription_model.dart (NEW)
```

**Monetization:**
- 99 Kč/měsíc nebo 999 Kč/rok
- Payment integration (Stripe nebo RevenueCat)
- Free trial (7 dní)

**Effort:** Very High | **Impact:** High (revenue stream)

---

## 📅 FUTURE (Q4 2026 & beyond)

### AR Strain Scanner
- Requires: ARCore/ARKit integration
- ML model training
- High complexity

### Collaborative Grow Journals
- Shared grow logs
- Multi-user permissions
- Real-time sync

### Local Community & Meetups
- Location features
- Event creation
- Safety features

### VR Grow Room Tours
- 360° video support
- WebXR or VR plugin
- Very niche

### IoT Integration
- Smart device APIs
- Real-time sensor data
- Automation

### Blockchain/NFTs
- Strain NFTs
- Provenance tracking
- Crypto wallet integration

---

## 🛠️ TECHNICAL CONSIDERATIONS

### Infrastructure needs:

**APIs:**
- OpenAI GPT-4 (Charlotte AI)
- Image recognition ML (diagnostics, AR)
- Push notifications (Firebase)
- Payment processing (Stripe/RevenueCat)

**Backend (Supabase):**
- Realtime subscriptions (sessions, raids)
- Storage buckets (images, videos)
- Edge functions (complex calculations)
- Database indexes (performance)

**Flutter packages:**
```yaml
dependencies:
  # Existing
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  supabase_flutter: ^2.0.0

  # New additions
  lottie: ^3.0.0                    # Animations
  fl_chart: ^0.66.0                 # Charts
  graphview: ^1.2.0                 # Genetics tree
  image_picker: ^1.0.0              # Photos
  record: ^5.0.0                    # Voice recording
  speech_to_text: ^6.0.0           # Voice commands
  shared_preferences: ^2.2.0        # Local storage
  connectivity_plus: ^5.0.0         # Offline detection
  in_app_purchase: ^3.0.0          # Pro subscriptions
  share_plus: ^7.0.0               # Social sharing
  url_launcher: ^6.2.0             # Links
  confetti: ^0.7.0                 # Celebrations
  shimmer: ^3.0.0                  # Loading effects
  flutter_animate: ^4.0.0          # Animations
```

### Performance optimization:
- Image compression
- Lazy loading
- Pagination
- Caching strategies
- Background sync
- Memory management

---

## 📊 SUCCESS METRICS

### Phase 1 (Polish):
- Bounce rate < 20%
- Session length +30%
- Onboarding completion 80%+

### Phase 2 (AI):
- Charlotte usage: 60% of users
- Recommendation acceptance: 50%+
- User satisfaction: 8/10+

### Phase 3 (Social):
- Session rooms created: 100+/week
- Avg participants: 3-5
- Raid completion: 80%+

### Phase 4 (Wellness):
- T-break starts: 50+/month
- Completion rate: 40%+
- Pattern insights viewed: 70% users

### Phase 5 (Advanced):
- Genetics explorer engagement: 40% users
- Terpene profile completion: 60% users

### Phase 6 (Gamification):
- Trophy room visits: 80% users
- Event participation: 70%+ during events
- Referrals: 0.5 per user average

### Phase 7-8 (Analytics & Pro):
- Wrapped shares: 30% users
- Pro conversion: 5-10%
- Revenue: 50k+ CZK/month

---

## 🚀 GETTING STARTED

### Week 1 Action Plan:

**Day 1-2: Setup**
- [ ] Create feature branches
- [ ] Update dependencies
- [ ] Setup Lottie animations folder
- [ ] Create new widget directories

**Day 3-5: Pull-to-refresh spider**
- [ ] Design spider animation (Lottie or custom)
- [ ] Implement PullToRefreshSpider widget
- [ ] Integrate do FeedScreen, LabScreen
- [ ] Test na iOS & Android

**Day 6-7: XP gain animation**
- [ ] Create AnimatedXPGain widget
- [ ] Particle effect system
- [ ] Trigger na XP events
- [ ] Sound effect (optional)

### Priority #1 features to start:
1. **Micro-interactions** (Week 1-2) - Quick visual improvement
2. **Charlotte AI** (Week 5-6) - Biggest impact feature
3. **Social Sessions** (Week 9-10) - High engagement driver

---

## 💬 QUESTIONS TO DECIDE:

1. **Charlotte AI:** OpenAI GPT-4 API (cost ~$0.03-0.06 per conversation) nebo local model (cheaper ale méně smart)?

2. **Pro subscription:** Spustit hned s Phase 8 nebo později?

3. **Seasonal events:** První event kdy? (April 420 je blízko!)

4. **Beta testing:** Chceš closed beta group z community?

5. **Design help:** Potřebuješ UI designer nebo děláme in-house?

---

## 🎯 NEXT STEPS

1. **Prioritizuj:** Které features jsou must-have pro Q1?
2. **Resource check:** Kolik času máš týdně?
3. **Pick starting point:** Začneme Phase 1 Week 1?
4. **Setup:** Git branches, project structure
5. **Ship early:** První release s animations za 2 týdny?

---

**Let's build this! 🕷️🚀**

*Vytvořil Claude Sonnet 4.5 | 2026-01-30*