# How a native target draws: prior art and feasibility (late 2026)

Study for the owed decision "how iOS draws" (`docs/2026_11_16_UI.md`, Direction). Written
2026-11-17. The fixed constraints are: native by default, theming limited to what each platform
honours, "drawn" as an explicit opt-in, one component source, a small component set first.

Plans: **A** drives UIKit (and Android Views) through the C ABI and the Objective-C runtime,
our diff applying mutations. **B** hands the neutral tree to SwiftUI (and Compose) through a
small Swift shim, and lets the platform's differ render it. **H** (added here) is UIKit views we
own as the default, with SwiftUI islands where Apple requires SwiftUI or only offers a feature
there.

Conventions: web claims carry their link inline; **[UNVERIFIED]** marks what I could not confirm
against a primary or current source this session (some from my own platform knowledge, and the
tag says so); **[LOCAL]** is read from this repository on 2026-11-17, branch `program`;
secondary sources are named as such.

---

## 0. The answer in one screen

- **iOS: hybrid, with UIKit as the spine (Plan A plus islands).** It matches the owner's
  constraints most closely:
  - It keeps one differ, ours.
  - It keeps our layout solver, which is already oracle-tested against a browser.
  - It needs no Swift compiler for the default path.
  - It gets OS redesigns at recompile time, because UIKit's standard controls adopt Liquid Glass
    automatically ([Apple, Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)).
- **SwiftUI is still owed for a short, closed list of surfaces:** widgets, Live Activities, App
  Intents snippets, and a handful of SwiftUI-first controls. Those are islands hosted through
  `UIHostingController`, as Expo UI hosts SwiftUI inside React Native today
  ([Expo, Host](https://docs.expo.dev/versions/latest/sdk/ui/swift-ui/host.md)).
- **Android is not symmetric with iOS, and this is the surprise of the study.** Google put
  `android.widget` Views, RecyclerView and Fragments into **maintenance mode on 19 May 2026**:
  "no new features"
  ([Android Developers, Compose First](https://developer.android.com/blog/posts/android-ui-development-is-compose-first)).
  Apple, by contrast, is still shipping UIKit features (§8). So "Plan A on both platforms" is
  sound on iOS and **a dead end on Android**. On Android the native-by-default path is Compose,
  which means Plan B's shape: a Kotlin shim and a tree handed to Compose.
- **The precedents for B on Apple did not last:**
  - LiveView Native, which fed a server-side tree into SwiftUI, was **archived 10 Feb 2026**
    ([live_view_native](https://github.com/liveview-native/live_view_native)).
  - Tokamak, a SwiftUI-compatible renderer, was archived as well (GitHub API: `archived: true`,
    last push 2024-03-23, [TokamakUI/Tokamak](https://github.com/TokamakUI/Tokamak)).
- **The precedents for A on Apple are what large shops actually run:**
  - React Native Fabric: UIKit views, its own C++ shadow tree, Yoga layout
    ([RN render pipeline](https://reactnative.dev/architecture/render-pipeline)).
  - Yandex DivKit: UIKit plus its own `LayoutKit` block layout (repo tree,
    [divkit/client/ios](https://github.com/divkit/divkit/tree/main/client/ios)).
- **The decisive unknowns are text input, lists, and navigation driven from our state.** A
  two-week spike can measure all three (§E).

---

## PART 1 — How others put a foreign language's UI onto native controls

### 1. React Native: old bridge → New Architecture

**What moved.**

- **Old architecture.** JS sent batched, serialized JSON messages over an asynchronous bridge to
  native code. Native created UIKit/Android views and ran Yoga for layout. Nothing could be
  synchronous, so a native event could not get a JS answer within the same frame.
- **New architecture: Fabric, JSI and TurboModules.**
  - JS holds C++ objects directly through JSI.
  - The shadow tree lives in C++, is immutable, and is diffed in C++. Shadow nodes "contain
    layout information (x, y, width, height). In Fabric, React Shadow Node objects exist in C++"
    ([RN glossary](https://reactnative.dev/architecture/glossary)).
  - Mount instructions are applied to platform views on the UI thread.
- **View flattening.** Layout-only views are removed from the host tree during the diff. It is
  "implemented in C++ and its benefits are shared by default on all supported platforms"
  ([RN view flattening](https://reactnative.dev/docs/next/view-flattening)). A production tree of
  "about 600-1000 React Shadow Nodes (before view flattening)" shrinks to "~200 nodes after"
  ([RN render pipeline](https://reactnative.dev/architecture/render-pipeline)).
- **The flattening history is a lesson in itself.** Flattening existed only on Android until the
  C++ core was shared ([GitNation talk](https://gitnation.com/contents/bringing-the-new-react-native-architecture-to-the-oss-community-907)).
  One shared diff core paid off on both platforms at once.
- **Status.**
  - 0.82 (Oct 2025) is "the first React Native that runs entirely on the New Architecture". The
    legacy flags are ignored, and removal of the legacy APIs is scheduled from the next version
    ([RN 0.82](https://reactnative.dev/blog/2025/10/08/react-native-0.82)).
  - React Native Windows 0.82 removed Paper, the old renderer, entirely
    ([MS devblog](https://devblogs.microsoft.com/react-native/%f0%9f%9a%80react-native-windows-v0-82-is-here/)).

**Why they moved.**

- Asynchronous serialization made several things impossible within a frame: synchronous layout
  reads, measuring a native view from JS, and interrupting work for a higher-priority update.
- The two platforms had duplicate, diverging implementations, flattening being one example.

**How RN maps one component to UIKit.**

- Each host component is a `RCTViewComponentView` subclass, registered in a dictionary keyed by
  component name.
- It receives `updateProps`, `updateState`, `updateLayoutMetrics` and `finalizeUpdates` during
  mounting ([RN Fabric iOS components](https://reactnative.dev/docs/next/fabric-native-components-ios);
  [RCTComponentViewProtocol.h](https://cdn.jsdelivr.net/npm/react-native@0.85.1/React/Fabric/Mounting/RCTComponentViewProtocol.h)).
- Frames come from Yoga. The UIKit view is a dumb receiver of frames and props. **This is exactly
  Plan A's shape.**

**Text measurement from a foreign layout engine (RN's answer).**

- The C++ `ParagraphShadowNode` calls `TextLayoutManager::measure`.
- On iOS that is a façade over `RCTTextLayoutManager`, which measures an `NSAttributedString`
  with TextKit and feeds the result to Yoga's measure callback, through a measure cache
  (mirrored sources: [TextLayoutManager.h](https://cdn.jsdelivr.net/npm/react-native-coocaatv@0.63.5/ReactCommon/fabric/textlayoutmanager/platform/ios/TextLayoutManager.h),
  [ParagraphShadowNode.cpp 0.85.1](https://cdn.jsdelivr.net/npm/react-native@0.85.1/ReactCommon/react/renderer/components/text/ParagraphShadowNode.cpp)).
- So **the platform measures and the foreign solver places**.

**What still hurts (2025–2026).**

- **Controlled text input.** The text lives in the native `UITextField`/`UITextView`, so a
  controlled `value` round-trips to JS: formatting while typing flickers and the cursor jumps.
  Expo's answer is a UI-thread worklet for `onChangeText`, noting that `maxLength`/`editable`
  apply natively without flicker
  ([Expo, controlled components](https://docs.expo.dev/guides/controlled-components/)). An
  upstream PR removes a main→JS→main round trip for auto-growing inputs and warns that
  `flushSync` can drop frames when the JS thread is busy
  ([facebook/react-native#46973](https://github.com/facebook/react-native/pull/46973)).
  **Whoever is not on the main thread loses the race with the keyboard.**
- **Lists.** FlashList v2 was rewritten for the New Architecture: up to 50% less blank area, no
  size estimates, recycling pools per item type. Memoizing props is critical, and changing `key`
  props stop recycling ([Shopify Engineering](https://shopify.engineering/flashlist-v2);
  [repo](https://github.com/shopify/flash-list)). Recycling plus stable identity is the game.
- **Recycled-view state leaks.** Fabric's view recycling carried a stale
  `automaticallyAdjustKeyboardInsets` across reuse
  ([dev.to](https://dev.to/pragathijayaram/the-bug-that-survived-being-recycled-automaticallyadjustkeyboardinsets-and-fabric-view-recycling-5e1e),
  secondary). Every property a recycler resets is one it can forget.
- **Navigation.** The serious libraries do not draw it: `react-native-screens`' native stack is
  `UINavigationController` / Fragments
  ([README](https://github.com/software-mansion/react-native-screens/blob/main/native-stack/README.md)),
  and React Navigation 8 (alpha, 2026) makes `UITabBarController`-backed native tabs the default
  ([InfoQ](https://infoq.com/news/2026/04/react-navigation-8-alpha)). JS state and the native
  container still disagree at the edges, e.g. the fifth tab popping to the top on focus
  ([react-native-bottom-tabs#461](https://github.com/callstack/react-native-bottom-tabs/issues/461)).
- **Native look lag.** Liquid Glass reached RN through wrappers, not the core
  (`@callstack/liquid-glass`, RN 0.80+ and Xcode 26,
  [README](https://cdn.jsdelivr.net/npm/@callstack/liquid-glass@0.8.0/README.md); Expo's
  `GlassEffect`). Glass tabs need react-native-screens 4.25+ built against the iOS 26 SDK
  ([React Navigation](https://reactnavigation.org/docs/8.x/upgrading-from-7.x/)). Where RN *uses*
  the real UIKit container, recompiling brought the redesign; where it drew an imitation (JS
  tabs), it did not.
- **Keyboard.** The de-facto fix is a third-party native module, `react-native-keyboard-controller`
  [UNVERIFIED this session; widely used per my knowledge]. Keyboard avoidance is the platform's
  job, and a foreign layout engine must be told the keyboard's frame every frame of its animation.

**Engines.** Hermes V1 is opt-in and experimental in 0.82. "Static Hermes", which compiles JS to
native, is explicitly not yet included
([RN 0.82](https://reactnative.dev/blog/2025/10/08/react-native-0.82)). Its 2026 maturity is
[UNVERIFIED]. The industry's best JS answer is converging on what Avra already is: ahead-of-time
native code.

### 2. .NET MAUI / Xamarin.Forms

- **The shift.** Xamarin.Forms *renderers* wrapped each platform control and injected extra
  container views. MAUI *handlers* map a cross-platform interface to one native view through a
  property mapper
  ([Microsoft Learn, renderer→handler](https://learn.microsoft.com/dotnet/maui/migration/renderer-to-handler);
  [Telerik](https://www.telerik.com/blogs/xamarin-renderers-net-maui-handlers)).
  The stated motive was performance: renderers injected extra view elements. Xamarin.Forms support ended in May 2024 [UNVERIFIED this session].
- **What broke.** Migrated apps report slower screens, ANRs and crashes on MAUI 8
  ([dotnet/maui #26567](https://github.com/dotnet/maui/discussions/26567)). The chronic complaint
  is the lowest common denominator: anything past the platforms' intersection needs a handler
  per platform [UNVERIFIED as a 2025–26 survey]. The ecosystem now ships *drawn* MAUI stacks,
  DrawnUI (no native views or handlers) and SkiaUi.Maui
  ([DrawnUI](https://taublast.github.io/posts/MauiJuly);
  [SkiaUi.Maui](https://www.nuget.org/packages/SkiaUi.Maui)): a native wrapper with a weak escape
  hatch pushes users off native altogether.
- **Lesson for Avra.** A per-control mapper is the right unit: our `Prim` is that unit. The
  failure is a *thin* mapper with no honest per-platform escape and no measured performance. Our
  doctrine already has both: per-target refusal reporting, and `foreign` islands.

### 3. Kotlin Multiplatform: native UI vs Compose Multiplatform on iOS

- **Shared logic with SwiftUI UI is the mainstream 2025–2026 pattern**
  ([STRV, Jan 2026](https://www.strv.com/blog/kotlin-multiplatform-in-production-what-worked-what-didn-t);
  [Q42/McDonald's](https://engineering.q42.nl/multiplatform/);
  [Babbel](https://www.babbel.com/en/magazine/how-we-brought-kotlin-multiplatform-into-babbels-mobile-apps)).
  The cost is two UIs: Kittysplit found SwiftUI "more work than they initially anticipated"
  (search summary; the body did not load: [Kittysplit](https://blog.kittysplit.com/building-kittysplit-apps-in-cmp/)).
- **Compose Multiplatform on iOS draws with Skia (Skiko).** It went stable in 1.8.0, May 2025
  ([JetBrains](https://blog.jetbrains.com/kotlin/2025/05/compose-multiplatform-1-8-0-released-compose-multiplatform-for-ios-is-stable-and-production-ready/)).
  - **Accessibility is a mirrored tree** synced lazily to iOS
    ([1.8.0 notes](https://kotlinlang.org/docs/multiplatform/whats-new-compose-180.html)). A
    TextField not recognised as a text input by VoiceOver was reported after "stable" (CMP-7649,
    via [Kotlin Slack](https://slack-chats.kotlinlang.org/t/28069309/https-blog-jetbrains-com-kotlin-2025-05-compose-multiplatfor)).
  - **Text input is the tell.** In 1.11 (May 2026) JetBrains added an *opt-in* "native text
    input" built on a `UIView` that adopts `UITextInput`/`UIKeyInput`, while the drawn input remains the
    stable default
    ([CMP 1.11](https://blog.jetbrains.com/kotlin/2026/05/compose-multiplatform-1-11-0);
    [1.11 notes](https://kotlinlang.org/docs/multiplatform/whats-new-compose-111.html)).
    A drawn toolkit ends up hosting a native text view, because IME, autocorrect, dictation and
    selection are too deep to reimplement.
- **Lesson.** The industry has split. A real native UI per platform (KMP+SwiftUI) is preferred
  for "hero" screens, and drawn UI is accepted for utility screens
  ([DEV opinion piece](https://dev.to/devin-rosario/kotlin-multiplatform-in-2026-stable-apis-for-ios-ui-sharing-39c5),
  secondary). Avra's goal is one source that realizes as native UI without writing a second UI.
  Nobody in the KMP world has that.

### 4. NativeScript and Titanium: direct runtime access

- **NativeScript** generates metadata for every Objective-C/Java API at build time and lets JS
  call any of them. A selector is spelled as a string, and structs, blocks and pointers are
  marshalled by rules
  ([iOS marshalling](https://docs.nativescript.org/guide/ios-marshalling);
  [runtime overview](https://v7.docs.nativescript.org/core-concepts/ios-runtime/overview)).
  - **What it bought:** 100% API reach on day one of every OS release. There is no wrapper lag,
    because metadata is regenerated from the SDK headers.
  - **What it cost:** a large runtime, with JSC and then V8 plus metadata. The cost is per
    crossing, not per message send: `objc_msgSend` itself is ~2.6 ns
    ([Mike Ash 2016](https://mikeash.com/pyblog/friday-qa-2016-04-15-performance-comparisons-of-common-operations-2016-edition.html)).
    And it is unsafe: any misuse crashes inside native code. NativeScript's own perf series
    frames the boundary crossing as *the* metric
    ([NativeScript perf part 1](https://blog.nativescript.org/perf-metrics-universal-javascript-part1)).
- **Titanium** wrapped native controls behind its own proxies (classic "proxy per view") and
  aged with its wrapper set [UNVERIFIED this session].
- **Lesson for Avra.** A compiled language makes the crossing nearly free: an `extern` call to
  `objc_msgSend` costs what Objective-C pays, with no marshalling and no second VM. Keep
  NativeScript's *good* idea, typed bindings generated from the SDK headers so reach never lags
  (our L0 "generated bindings" ledger item, `docs/2026_11_16_UI.md`).

### 5. Swift elsewhere, and "SwiftUI as a render target"

- **SwiftCrossUI** is a SwiftUI-like API with *backends*: AppKit, UIKit, WinUI and GTK 4. It is
  alive, with its last push 2026-11-16 and ~1.8k stars, and still self-described as a
  "work-in-progress"
  ([repo](https://github.com/moreSwift/swift-cross-ui);
  [Swift Forums](https://forums.swift.org/t/swiftui-for-linux-windows-and-web-still-experimental/85463)).
  - It is the closest analogue to Avra's shape: one declarative tree, its own differ and layout,
    and per-platform native-widget backends. Notably, its UIKit backend drives *UIKit*, not
    SwiftUI.
- **Tokamak**, a SwiftUI-compatible renderer for web and others, is **archived**
  ([repo](https://github.com/TokamakUI/Tokamak)).
- **Skip** transpiles Swift/SwiftUI to Kotlin/Compose ("Lite"), or runs native Swift on Android
  with a SwiftUI→Compose bridge ("Fuse"). It is free and open source since 1.7, under LGPL
  ([Skip FAQ](https://skip.tools/docs/faq); [skip-ui](https://skip.tools/docs/modules/skip-ui)).
  - This is evidence that **Compose can render an externally supplied, SwiftUI-shaped tree**.
    SkipUI "mirror[s] as much of SwiftUI as possible" on Compose.
- **Feeding an external tree into SwiftUI at runtime.**
  - **LiveView Native** (Elixir) sent "very small UI diffs over a socket … and build[s] actual
    Native UI view trees" in SwiftUI ([DockYard](https://dockyard.com/blog/2024/09/09/liveview-native-is-here)).
    - It needed a stylesheet language to map modifiers, platform-specific templates
      (`*.ios.heex`), and per-node publishers so as not to re-render the whole tree.
    - The Jetpack client never reached readiness
      ([DockYard tutorial](https://dockyard.com/blog/2024/09/20/create-your-first-liveview-native-app-part-1)).
    - The core repo was **archived 2026-02-10**
      ([live_view_native](https://github.com/liveview-native/live_view_native)).
    - Its own framing, "LiveView Native is a browser"
      ([DockYard](https://dockyard.com/blog/2024/09/26/liveview-native-is-a-browser)), is the
      honest description of Plan B: you build a SwiftUI browser for your tree format.
  - **Airbnb Ghost Platform** is server-driven, but the server sends *sections and data*, not a
    view tree. Each client renders sections with hand-written native components in Swift, Kotlin
    and TS ([Airbnb Eng](https://medium.com/airbnb-engineering/a-deep-dive-into-airbnbs-server-driven-ui-system-842244c5f5)).
    - Separately, Airbnb moved its *hand-written* iOS UI from Epoxy/UIKit to SwiftUI over
      2022–24. It bridged both ways with `UIHostingController`/`UIViewRepresentable`, and the
      third phase waited on navigation APIs
      ([Airbnb, Unlocking SwiftUI](https://medium.com/airbnb-engineering/unlocking-swiftui-at-airbnb-ea58f50cde49);
      [InfoQ](https://www.infoq.com/news/2023/10/airbnb-transitioning-swiftui/)).
    - Note the distinction: SwiftUI works well for code *written in Swift*. Ghost did not ship
      a generic tree interpreter into SwiftUI.
  - **DivKit** (Yandex) sends JSON layouts and renders them natively.
    - Its iOS client is **UIKit with its own layout engine**: `client/ios/LayoutKit/…/UI/Blocks/
      *Block+UIViewRenderableBlock.swift`, `LaidOutBlock`, and a `GenericCollectionView*` for
      galleries (repo listing,
      [divkit/client/ios](https://github.com/divkit/divkit/tree/main/client/ios)).
    - That is Plan A's shape, run in production at Yandex scale, and maintained.
  - **Expo UI** goes the other direction. A `Host` component embeds real SwiftUI views inside RN's
    UIKit tree "using UIHostingController", and `RNHostView` puts RN views back inside SwiftUI,
    syncing size into Yoga
    ([Expo Host](https://docs.expo.dev/versions/latest/sdk/ui/swift-ui/host.md);
    [RNHostView](https://docs.expo.dev/versions/latest/sdk/ui/swift-ui/rnhostview.md)).
    **This is the hybrid, shipping today.**
  - Judo, Rise and Backpack: not researched in depth this session [UNVERIFIED].
- **How the external-tree efforts handle the four hard things.**
  - **State.** The tree's owner holds the truth. SwiftUI `@State` inside the renderer is only for
    view-local state: focus, scroll and transient animation.
  - **Identity.** Explicit ids on every dynamic node. LVN keyed per node, and DivKit keys blocks
    by path/id.
  - **Animation.** Explicit animation hints carried in the tree, such as transitions on
    insert/remove. Implicit SwiftUI animation does not know *why* a value changed.
  - **Navigation.** A path held by the owner and projected into `NavigationStack(path:)` or a
    `UINavigationController`. Every effort that drew its own stack was replaced by the platform
    container (RN, §1).

### 6. Rust, Zig, Go and C driving UIKit/AppKit directly

- **objc2 (Rust)** is the most complete modern binding.
  - Its UIKit crate is generated from the SDK headers and takes a `MainThreadMarker` on every
    main-thread-only constructor (e.g. `UIAction::actionWithHandler(handler, mtm)`).
  - Block-taking APIs sit behind the `block2` feature.
  - `define_class!` declares an Objective-C class at runtime, with ivars and protocols.
  - `Retained<T>` is the owning smart pointer
    ([objc2 docs](https://docs.rs/objc2/latest/objc2/);
    [objc2-ui-kit](https://docs.rs/objc2-ui-kit/0.3.2/objc2_ui_kit/struct.UIAction.html)).
  - Even so, its own example is full of `unsafe` with `// SAFETY:` comments, and the bindings are
    "generated in a very macOS-centric manner".
- **cacao (Rust)** is "experimental, but working!": AppKit is "beta quality", UIKit "alpha
  quality", hand-written, with rampant `unsafe`
  ([cacao](https://github.com/ryanmcgrath/cacao)). The lesson is that hand-written wrappers lag.
- **Dioxus Native / Blitz** *draws* HTML/CSS with Vello, not native controls. Form controls are
  still missing, and native-widget integration is a longer-term goal
  ([Blitz](https://github.com/DioxusLabs/blitz)). **Tauri** is a webview. **Slint** draws its own
  widgets [UNVERIFIED this session]. None of them are prior art for native-by-default.
- **Zig: Ghostty** is the instructive counter-example.
  - The core is Zig behind a C API, and the macOS GUI is **Swift** (SwiftUI plus AppKit). About
    93% of the repo is Zig/C and 4% is Swift GUI
    ([Hashimoto, Zig and SwiftUI](https://mitchellh.com/writing/zig-and-swiftui)).
  - They later "rip[ped] out the SwiftUI app and window lifecycle … rewrite it ourselves using
    plain old AppKit", keeping SwiftUI for views
    ([devlog 002](https://mitchellh.com/writing/ghostty-devlog-002)).
  - Even a SwiftUI-first team retreated to the imperative toolkit for lifecycle and windows.
- **gomobile** binds Go as a library to Swift/ObjC and Java, with no UI layer of its own
  [UNVERIFIED this session].
- **Lynx (ByteDance)** pairs JS on a background thread with a main-thread engine (PrimJS) that
  renders **native views**: UIKit on iOS and Views on Android. Sources conflict on the details
  ([The New Stack](https://thenewstack.io/cross-platform-ui-framework-lynx-competes-with-react-native/);
  [appwrite](https://appwrite.io/blog/post/bytedance-lynx-vs-react-native), secondary). It is
  another 2025 entrant choosing UIKit, not SwiftUI, as the native surface.

**What direct `objc_msgSend` from a foreign compiled language is like in practice.** These are
platform facts; the ones not re-fetched are marked.

- **Selectors and sends.**
  - `sel_registerName` once, cached, then `objc_msgSend` **cast to the exact function type** of
    the method.
  - On arm64, `objc_msgSend` must never be called through a variadic prototype: arguments land in
    the wrong registers or stack slots. Struct returns use different trampolines on x86_64
    (`objc_msgSend_stret`) but not on arm64 [platform knowledge, UNVERIFIED this session].
  - **[LOCAL]** CLAUDE.md already records this exact hazard: "a variadic callee reads its
    argument from the STACK … calling one through the other returns the PREVIOUS call's value".
    An Avra `extern` row per *signature shape* (`msg_id_id`, `msg_void_id_sel_ul`, …) is the safe
    spelling.
- **Callbacks.** There are three mechanisms, in order of how foreign-friendly they are:
  1. **Target–action.** Make one runtime class, `objc_allocateClassPair` + `class_addMethod` with
     a C `IMP` + `objc_registerClassPair`, and route `addTarget:action:forControlEvents:` to it.
     It needs no blocks, and one class serves every control. The control does **not** retain its
     target, so we keep the target alive [platform knowledge].
  2. **Delegates/data sources.** Use the same runtime class with `class_addProtocol` and the
     protocol's methods. `UICollectionViewDataSource`, `UITextFieldDelegate` and
     `UISheetPresentationControllerDelegate` all work this way. Delegates are weak, so we own
     them.
  3. **Blocks.** Required by many newer APIs: `UIAction`, diffable data source cell providers,
     `UIView.animate`, completion handlers. A block is a struct (`isa`, flags, `invoke` fn
     pointer, descriptor, captures) per the Clang Blocks ABI. A non-Clang compiler must emit that
     layout itself, or call a tiny C helper compiled by clang that wraps a C fn pointer plus
     context in a heap block [platform knowledge; ABI documented in Clang's
     `BlockLanguageSpec`/`Block-ABI-Apple`, not re-fetched].
- **Retain/release interop with a foreign refcount.** `objc_retain`/`objc_release` are plain C
  calls. An Avra box *holds +1* on its `UIView`, and the view points back at an Avra box for its
  handlers (associated object or ivar). **That is a cycle**: CLAUDE.md's "A CLOSURE STORED IN A
  VALUE THAT CAPTURES THE VALUE'S OWNER IS A CYCLE", in UIKit's clothes, so one side is weak or
  torn down at `Remove`. Wrap each turn in `objc_autoreleasePoolPush`/`Pop`, or autoreleased
  results pile up until the run loop drains [platform knowledge].
- **Main thread.** UIKit is main-thread-only. objc2 encodes this as a type; Avra would encode it
  as a task affinity (the turn loop runs on the main thread), and Xcode's Main Thread Checker
  flags violations at debug time [platform knowledge].
- **Auto Layout vs frames.** A foreign solver sets `frame`/`bounds`/`center` directly, with
  `translatesAutoresizingMaskIntoConstraints` left true. RN and DivKit both do this. Mixing in
  Auto Layout for some subtrees is possible but creates two solvers fighting over one view.
- **Swift-only APIs.** No Objective-C surface, so Plan A needs a Swift shim for: SwiftUI,
  WidgetKit views, ActivityKit's UI, App Intents snippet views, TipKit, Swift Charts, Observation,
  and some newer UIKit overlays [UNVERIFIED list; check per API]. UIKit's WWDC25 observation
  tracking observes Swift `@Observable` objects, so it is useless to a C caller. A does not need
  it: our diff already knows what changed.

### 7. Layout: who owns it?

- **Our own solver computing frames.** This is RN/Yoga and DivKit/LayoutKit.
  - Measurement is delegated to the platform: text through TextKit/CoreText, and controls through
    `sizeThatFits:`/`intrinsicContentSize`.
  - Frames are pushed to views. The UI is byte-identical in structure across platforms, and the
    web parity is ours to prove (we have a Firefox oracle).
- **Auto Layout.** It is the platform's solver, but slow at scale and imperative. Nobody driving
  UIKit from a foreign tree uses it as the primary engine [observation from RN/DivKit sources
  above].
- **SwiftUI layout.** It is bottom-up, proposal/response. A WWDC26 lab noted "UIKit laying out
  top-down and SwiftUI laying out bottom-up, which makes deep interleaving subtle"
  ([blakecrosley.com, WWDC26 notes](https://blakecrosley.com/blog/swiftui-performance-interop-ios-27),
  secondary, paraphrased). Under Plan B, **our solver is unused on iOS**. Our `Layout` vocabulary
  must be re-expressed as stacks, spacers and frames, so web/iOS parity becomes approximate.
- **The details any owner must get right:**
  - **Dynamic Type.** Fonts come from `UIFont.preferredFont(forTextStyle:)` /
    `UIFontMetrics.scaledValue`, and the solver re-runs on
    `UIContentSizeCategoryDidChangeNotification`/trait change.
  - **Safe areas.** The root view's `safeAreaInsets` is the solver's outer padding.
  - **Keyboard.** Use `keyboardLayoutGuide` (iOS 15+), or observe keyboard frames and re-solve
    with a bottom inset, animating with the keyboard's curve.
  - **Scroll views.** We set `contentSize`, and nested scrolling belongs to UIKit.
  - **Recycled lists.** Use `UICollectionView` with a compositional list layout, fed by our keyed
    children through a diffable data source snapshot. Self-sizing cells ask our solver for a
    height at a width.
  - These are platform facts [UNVERIFIED this session against current docs; stable APIs since
    iOS 13–15].
- **The SwiftUI side of lists** has its own cliffs.
  - `LazyVStack` loads only near-visible views and *estimates* the rest, so absolute offsets are
    unstable.
  - Work done in `onAppear` discards prefetching.
  - A dynamic subview count inside `ForEach` keeps views alive by index
    ([WWDC26 session 321 notes](https://blakecrosley.com/blog/swiftui-performance-interop-ios-27),
    secondary).

---

## PART 2 — What the platforms allow and require (late 2026)

### 8. UIKit vs SwiftUI status

- **Apple is still investing in UIKit.**
  - **WWDC25:** UIKit gained built-in Swift Observation tracking, the `updateProperties()` pass,
    and Liquid Glass across "bars and search fields to alerts, popovers and split views"
    ([WWDC25 243, What's new in UIKit](https://developer.apple.com/videos/play/wwdc2025/243/);
    [WWDC25 284](https://developer.apple.com/videos/play/wwdc2025/284)).
  - **WWDC26 / iOS 27:**
    - The headline was "Modernize your UIKit app" (session 278), about resizable layouts for
      iPhone Mirroring and iPad ([session](https://developer.apple.com/videos/play/wwdc2026/278)).
    - TextKit 2 gained tables, viewport rendering and attachment reuse.
    - Bars gained `barMinimizeBehavior` and `visibilityPriority`. Tab bars gained batch updates
      and sidebar APIs.
    - "No public UIKit classes were removed"
      ([iKyle, UIKit in iOS 27](https://www.ikyle.me/blog/2026/whats-new-in-uikit-ios-27), from
      the SDK diff).
  - It is a small release, but a living one.
- **What UIKit gets automatically.** "If your app uses standard components from SwiftUI, UIKit,
  or AppKit, your interface picks up the latest look and feel … build your app with the latest
  SDKs." Bars, sheets, popovers and controls adopt the material
  ([Apple, Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)).
  Custom materials use `UIGlassEffect` in a `UIVisualEffectView`.
- **The opt-out is ending.** `UIDesignRequiresCompatibility` stops being honoured once an app
  links the iOS 27 SDK ([Apple Forums](https://developer.apple.com/forums/thread/832543)).
  - For us this is good news. Native by default means a recompile *is* the redesign, for UIKit
    and SwiftUI alike.
- **A hard requirement for Plan A's shell.** "Apps built with the iOS 27 SDK or later must adopt
  the scene-based life cycle or they fail to launch", and a launch screen is required
  ([iKyle](https://www.ikyle.me/blog/2026/whats-new-in-uikit-ios-27); also
  [WWDC26 iOS guide](https://developer.apple.com/wwdc26/guides/ios/)). Our C entry must
  therefore:
  - register a `UIApplicationDelegate` *and* a `UIWindowSceneDelegate` runtime class;
  - ship `UIApplicationSceneManifest` in Info.plist.
- **What is SwiftUI-only or SwiftUI-first** (each needs an island or a generated Swift
  projection):
  - WidgetKit widgets and Live Activities, whose UI is SwiftUI views
    ([WidgetKit](https://developer.apple.com/documentation/widgetkit)) [UNVERIFIED re-fetch;
    long-standing].
  - App Intents snippets / interactive snippets [UNVERIFIED].
  - visionOS volumes and immersive spaces (`RealityView`) [UNVERIFIED].
  - Many new controls arrive in SwiftUI first. WWDC26's SwiftUI additions (reorderable
    containers, swipe actions in any scroll container, `Tab(role: .prominent)`,
    `ToolbarOverflowMenu`, item-bound `.alert`/`.confirmationDialog`) are presented with no UIKit
    equivalents named
    ([dev.to WWDC26 SwiftUI breakdown](https://dev.to/arshtechpro/wwdc26-whats-new-in-swiftui-a-developers-breakdown-1333),
    secondary).
- **What is UIKit-only or better in UIKit** [platform knowledge, UNVERIFIED this session]:
  - Fine-grained `UICollectionView` (huge lists, custom layouts, precise prefetch).
  - `UITextView`/TextKit 2 control. The new TextKit 2 tables are UIKit.
  - Scene and window management. Ghostty's retreat to AppKit for lifecycle is the macOS
    instance.
  - Deterministic imperative control of presentation.
- **Interop.**
  - `UIHostingController` puts a SwiftUI view in a UIKit tree.
  - `UIHostingConfiguration` (iOS 16+) is a SwiftUI cell content configuration inside
    `UICollectionView`.
  - `UIViewRepresentable` puts UIKit in SwiftUI.
  - WWDC26 framed it as "no expectation that an app be entirely SwiftUI to benefit"
    ([session 272 notes](https://blakecrosley.com/blog/swiftui-performance-interop-ios-27),
    secondary).

### 9. Hosting a dynamic, externally described tree in SwiftUI

- **The shape.** A recursive `NodeView` switches on `Prim` and recurses into children with
  `ForEach(children, id: \.key)`. Its body returns `_ConditionalContent` or `AnyView`.
- **AnyView cost.**
  - Type erasure removes *structural* identity, so SwiftUI must compare more at runtime.
  - Measurements disagree. One benchmark found AnyView construction faster with no diffing
    penalty. Another measured 10–16% frame-rate loss in lists
    ([Swift Forums benchmarks](https://forums.swift.org/t/swiftui-and-anyview-performance-benchmarks/65717?page=2);
    [Forums thread](https://forums.swift.org/t/anyview-performance/59947)).
  - The settled point is identity, not speed: "explicit identity … structural identity — defined
    by the view type and position"
    ([WWDC21 Demystify SwiftUI notes](https://wwdcnotes.com/documentation/wwdc21-10022-demystify-swiftui/)).
  - An externally typed tree has only *explicit* identity. So **every node must carry an `.id`
    derived from our identity**. **[LOCAL]** We have one: `tree/identity.av` gives each node
    "WHERE IT STANDS — its parent, then its own STEP: its key, or the SITE".
- **Updates from C.**
  - Either replace the whole tree, so SwiftUI re-runs `body` for every node and diffs all of it,
  - or keep an `@Observable` object per node and mutate only changed nodes. That means writing a
    patch applier in Swift anyway, which is Appendix A's option 1, "SHIP OPS", in disguise.
  - LVN chose per-node publishers for this reason (§5).
  - **The second differ does not save the first:** we still must know what changed to update
    efficiently.
- **Animations.** SwiftUI animates changes made inside `withAnimation` or under
  `.animation(_:value:)`. A change from C animates only if applied inside a transaction, so the
  tree must carry animation intent per change (our "animation is declared on the node", UI.md
  Direction). Transitions need stable identity: a key change is a remove plus an insert.
- **Navigation.** `NavigationStack(path:)` on an external path works if the path round-trips
  (a back-swipe mutates SwiftUI's binding, and C must hear it). `.sheet(item:)` and item-bound
  alerts (widened in iOS 27) make presentation data. Airbnb's adoption waited on these APIs (§5).
- **Known cliffs.** Per-frame environment changes invalidate every reader; `onAppear` sizing
  discards prefetch; dynamic child counts are kept by index (§7 sources); a deep generic tree is
  debugged from outside SwiftUI's attribute graph [UNVERIFIED as a measured cost].

### 10. Calling Swift from C, the app bundle, and App Review

- **`@c` is official.** SE-0495 "C compatible functions and enums", status **Implemented
  (Swift 6.3)**. `@c` functions use the C calling convention, allow only C-representable types,
  and are printed into a C section of the generated header. `@c @implementation` checks against
  a hand-written header
  ([SE-0495](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0495-cdecl.md),
  read via the GitHub API). `@_cdecl` stays as the old underscored form, and switching between
  them is ABI-breaking.
- **Can a non-Swift compiler call Swift directly?**
  - Swift's ABI is stable on Apple platforms (Swift 5 / iOS 12.2+), but calling Swift-native
    entry points means reproducing the Swift calling convention (`swiftcc`, self/error/context
    registers), resilience, generics metadata and witness tables [platform knowledge, UNVERIFIED].
  - LLVM does have `swiftcc`, which a backend could emit, but SwiftUI's API surface is generic
    and resilient, so "call SwiftUI directly" is impractical.
  - **Plan B therefore requires a Swift shim compiled by `swiftc`**, exposing `@c` entry points
    that take our tree (or patches) as C data.
- **What must exist either way** [platform knowledge; standard bundle layout]:
  - An `.app` directory with the Mach-O, Info.plist (including the scene manifest and launch
    screen), and `Assets.car` compiled by `actool` (app icon, colours, SF Symbols need no
    asset).
  - An entitlements plist, an embedded `.mobileprovision`, a code signature over everything, and
    privacy manifests for required-reason APIs [UNVERIFIED re-check of current
    PrivacyInfo.xcprivacy rules].
  - None of this requires an `.xcodeproj`. All of it requires tools that ship inside Xcode
    (`clang`, `ld`, `actool`, `codesign`, `swiftc` for B).
- **App Review and language.** No guideline names a source language. 2.5.1 requires public
  APIs, which our runtime calls satisfy; 2.5.2 forbids downloading or executing "code which
  introduces or changes features or functionality"
  ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)). AOT native
  code with no JIT is the safest profile; Flutter (AOT Dart), Unity (IL2CPP) and RN (Hermes
  bytecode) all ship [UNVERIFIED per-app this session]. Server-driven UI passes as *data*, but a
  tree that changes "features or functionality" is a reviewer's call, which matters if trees ever
  travel over the network.
- **The SDK floor.** Since 28 Apr 2026, uploads "must be built with Xcode 26 or later" against
  the iOS 26 SDK
  ([Apple, Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)).
  Expect the iOS 27 SDK floor in spring 2027 [the date is UNVERIFIED].

### 11. Building for iOS without Xcode (the IDE)

- **On a Mac**, one scriptable command, with Xcode the app never opened: `xcrun --sdk iphoneos
  clang -target arm64-apple-ios17.0 -isysroot $(xcrun --sdk iphoneos --show-sdk-path)` linking
  `-framework UIKit -framework Foundation`; `actool` for assets; `codesign --entitlements …`;
  `xcrun devicectl device install app` to a device, or `arm64-apple-ios-simulator` with `simctl`
  [platform knowledge; `devicectl` since Xcode 15, UNVERIFIED this session]. **[LOCAL]** Avra
  already emits LLVM IR, so the iOS target is a triple plus a link line.
- **Off a Mac.**
  - **xtool** builds SwiftPM packages into iOS apps, signs them and installs them from Linux or
    WSL. It needs a user-supplied `Xcode.xip` for the SDK and is still experimental. App Store
    submission still needs a Mac
    ([xtool](https://github.com/xtool-org/xtool);
    [Swift Forums](https://forums.swift.org/t/xtool-cross-platform-xcode-replacement-build-ios-apps-on-linux-and-more/79803)).
  - **rcodesign** (apple-codesign) signs Mach-O and bundles on any OS and talks to the Notary API
    ([docs](https://gregoryszorc.com/docs/apple-codesign/main/)). iOS signing is reported to
    work but is thinly documented
    ([Szorc blog](https://gregoryszorc.com/blog/2022/08/08/achieving-a-completely-open-source-implementation-of-apple-code-signing-and-notarization/)).
  - **Legal state.** The SDK licence restricts use to "Apple-branded" computers. Whether Linux on
    Apple hardware, or a VM, complies is disputed ([OSNews on xtool](https://www.osnews.com/story/142331/xtool-cross-platform-xcode-replacement-for-linux-windows-and-macos/)).
  - **Conclusion:** keep iOS builds on macOS, and CI on macOS runners.
- **Toolchain asymmetry.** Plan A needs only clang and ld (clang only for a block helper,
  avoidable if Avra emits block literals). Plan B adds `swiftc` and the SwiftUI module interface:
  a second compiler with its own incremental model and versioning.
- **Xcode 27 is Apple-Silicon-only** ([WWDC26 viewing guide, via search](https://useyourloaf.com/blog/wwdc-2026-viewing-guide/),
  secondary).

### 12. Android, the same A/B in brief

- **Views via JNI (A).**
  - It works mechanically. JNI is "cumbersome at times [but] reasonably efficient".
  - The guidance is to "minimize marshalling … [and] the frequency", cache `jclass`/`jmethodID`,
    hold `NewGlobalRef` for anything kept, and never compare refs with `==`.
  - `@CriticalNative` calls are "almost as cheap as a non-inline call in C/C++" since Android 12
    ([Android, JNI tips](https://developer.android.com/training/articles/perf-jni)).
  - A batched frame (one JNI call carrying many ops, applied by a small Kotlin/Java applier) is
    the standard shape.
- **But Views are now frozen.** As of 19 May 2026, "all Android UI should be built with Compose
  … View components … in maintenance mode … no new features", and the same holds for
  RecyclerView and Fragments
  ([Android Developers](https://developer.android.com/blog/posts/android-ui-development-is-compose-first)).
  - Material's Views library (MDC-Android) is in maintenance too, with Expressive only partially
    available there ([DEV summary](https://dev.to/pulkitgovrani/android-views-is-now-in-maintenance-mode-heres-what-that-actually-means-for-android-devs-1pmd),
    secondary).
  - **"Native by default, follows OS redesigns" on Android now means Compose.**
- **Compose fed an external tree (B).**
  - It is proven: SkipUI renders a SwiftUI-shaped tree on Compose (§5), and SDUI-on-Compose is a
    common pattern
    ([proandroiddev](https://proandroiddev.com/server-driven-ui-using-jetpack-compose-8fae9889bb2b)).
  - Stability matters: a whole-tree replace defeats skipping, so the model must be stable and
    keyed ([Compose perf](https://developer.android.com/jetpack/compose/performance/bestpractices)).
  - A Kotlin shim is unavoidable, since Compose is a Kotlin compiler plugin. Any Android app
    needs a Java/Kotlin `Activity` anyway, so the shim's marginal cost is small.
- **Net.** Android is Plan B, by Google's decree. iOS has a genuine choice.

### 13. What comes free with real native controls

With **native controls** (UIKit or SwiftUI alike) these come free, and a drawn toolkit must
rebuild each: VoiceOver traits and rotor; Dynamic Type; RTL mirroring
(`semanticContentAttribute`); dark mode and increased contrast; haptics on standard controls;
context menus; drag and drop on text; the full text system (IME and marked text, autocorrect,
autofill and passwords, dictation, Scribble, the loupe, the edit menu); keyboard focus and full
keyboard access; Large Content Viewer. [Platform knowledge, stable since iOS 13–17; UNVERIFIED
re-fetch.]

How each approach loses some of these:

- **Plan A loses nothing per control, but owns the glue:**
  - Accessibility *grouping and order* across our containers, by setting
    `accessibilityElements`/`shouldGroupAccessibilityChildren` on our container views.
  - Accessibility on custom *drawn* primitives.
  - Focus order. Our solver's frame order is not UIKit's `focusGroup` order unless we say so.
  - RTL. Our solver must mirror; UIKit will not mirror frames we set by hand.
  - Dynamic Type relayout, on trait change.
- **Plan B gets grouping, focus, RTL and Dynamic Type relayout from SwiftUI's layout.** It loses
  precise control of our layout semantics and web parity.
- **Drawn approaches (Flutter, CMP)** maintain a parallel semantics tree, and lag:
  - CMP-7649's TextField-not-a-text-input (§3).
  - Flutter's Cupertino set *declining* Liquid Glass, while system sheets and keyboards around a
    Flutter screen do turn glass, leaving visible seams
    ([VGV](https://verygood.ventures/blog/a-new-era-for-app-design-and-what-it-means-for-flutter/);
    [issoh, Aug 2026](https://www.issoh.co.jp/tech/details/16743/), secondary).
  - This is the owner's "native by default" decision, vindicated by 2025–26 events.

---

## PART 3 — Local facts: the seam a native target plugs into [LOCAL]

Read on `program`, 2026-11-17, from `packages/std-ui/src`. No builds were run.

- **The neutral tree** (`tree/node.av`).
  - `Prim` has 24 variants (Text, Heading, Button, Link, Image, Field, Checkbox, Row, Column,
    Dialog, Divider, Icon, Surface, List, Item, Card, Progress, Alert, Spinner, Form, Fieldset,
    Switch, Slider, Key): "Every target answers every one, or the build names the target."
  - `Attribute` carries content, state flags (`Disabled`, `Checked`, `Open`, `Invalid`, `Masked`,
    …), and list windowing (`Skipped(path, rows, extent)`, `Placed(at, of, reveal)`): windowing
    is decided in Avra, and the target reports extents.
  - `Node = { prim, attrs, box (style + layout), children, events: List<Action>, sites,
    drawn_by_order }`. An `Action` is `{ seat, handler }`: "a target subscribes to the kind and
    echoes WHICH node spoke, never the code."
- **Events** (`tree/seats.av`). Seats are `@seat` consts gathered into `seat_rows`. A `SeatRow`
  has **one field per target** (`web: DomEvent?`, `terminal: Key?`), so a new target adds a field.
- **Identity** (`tree/identity.av`). A node is its parent plus its step (key, or lexical site
  plus turn). A live target numbers nodes (`NodeId`) while they stand. This is target-neutral and
  is what a diffable snapshot, `ForEach(id:)` or Compose `key()` wants.
- **The diff is HTML-shaped today.**
  - `realize/html/element.av` lowers `Node` to elements.
  - `realize/dom/patch.av` diffs two element trees by id into `Patch` (`Create(id, HtmlTag)`,
    `CreateText`, `Place(id, parent?, after?)`, `Remove`, `SetAttr`/`DropAttr`, `SetProp`,
    `SetText`, `Listen`/`Unlisten`, `Style(css)`, `Call(verb)`, `SetVar`/`DropVar`, `Adopt`).
  - `realize/dom/wire.av` sends a binary, versioned frame (v15) to a JS host that "holds no tree
    of its own". `realize/dom/exact.av` emits `SetText` for only the readings whose cells changed.
  - **For iOS:** the algorithm (keyed placement and moves, property vs attribute, verb "doors"
    like `showModal`) is reusable. The vocabulary (`HtmlTag`, `HtmlAttrName`, CSS) is not. Either
    the diff goes neutral over `Node` with per-target lowering, or a `uikit` lowering feeds a diff
    generic over its element type.
- **Layout.**
  - `place/solve.av` is "CSS flexbox over the `Layout` vocabulary", checked against Firefox by
    `tools/layout-oracle`: a tree, a `dyn Measure` and a width in, `Rect`s out.
  - `Measure` (`place/measure.av`) is the only unit-bearing seam: `own(n, avail)`, `min_own`,
    `kept`, `hidden`, `holds`, and gap/pad per axis, in sixtieths of a unit.
  - **The terminal is placed by our solver; the web is not** (the browser lays out from the CSS
    `realize/html/css.av` writes). A UIKit target would answer `Measure` from UIKit and apply
    `Rect`s as frames, which is RN's division of labour.
- **The second target.** `realize/tui` places and paints. `terminal/terminal.av` keeps one focus
  by path and no text ("a field shows what the view says").
- **What a new target must implement:**
  1. an answer for every `Prim`;
  2. a `SeatRow` field;
  3. a lowering plus a diff driver, or a neutral diff consumer;
  4. a `Measure`, if it uses our solver;
  5. a host applier;
  6. focus, scroll and presentation state kept by identity;
  7. theme roles mapped to what the platform honours, refused per target where it does not.

**The two recorded positions** (`docs/2026_11_16_UI.md`):

- **Position 1, UIKit / Android Views through the C ABI** (ledger, "native — PLANNED"):
  - "both reachable from compiled Avra through the C ABI (Obj-C runtime, JNI), accessible,
    mature, and neither runs a second diffing framework under ours; SwiftUI/Compose are `foreign`
    islands where only they offer a feature."
  - WidgetKit, Live Activities and Glance "GENERATE Swift/Kotlin as a projection needing
    `swiftc`/`kotlinc` — printed, never hidden."
  - "Decision 3 … (recommend yes)". Ladder rung 4: `aarch64-apple-ios` + `uikit`, layout engine
    v0, shell.
- **Position 2, "SHIP THE TREE"** (Appendix A, 2026-10-02, from `d71eacb562`, "Never landed"):
  - It rejects "SHIP OPS — a Swift applier … Works, but re-implements diffing" for "a Swift `Node`
    model plus a `NodeView` … let SwiftUI diff it (the platform IS the differ)", on Apple and
    Android.
  - "The op stream exists for targets with NO differ (DOM, canvas, print)". It carries a
    Prim→SwiftUI table.
- **The current Direction** keeps both open.
- **Position 2 predates three facts:**
  - Android Views entering maintenance mode (May 2026), which *helps* it on Android.
  - LiveView Native being archived (Feb 2026).
  - Our diff becoming exact and per-site (`exact.av`). We diff anyway, so "re-implements diffing"
    no longer argues for B: a second differ is pure cost.

---

## SYNTHESIS

### A. Plan A vs Plan B vs Hybrid

"Free" means the platform does it. "Build" means we must.

| Axis | A: UIKit via C ABI, our diff | B: SwiftUI consumes our tree | H: UIKit spine + SwiftUI islands |
|---|---|---|---|
| Native look, incl. OS redesigns | Free for standard controls at recompile ([Apple](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)). New SwiftUI-first controls need an island or a wait. | Free, including SwiftUI-first controls as they ship. | A's, plus islands for SwiftUI-first controls on demand. |
| Lists / scroll | Build: diffable `UICollectionView` adapter keyed by our identity. Best ceiling (RN/DivKit/FlashList lessons). Our `Skipped/Placed` windowing either maps to or yields to cell recycling. | Free `List`/`LazyVStack`, with known cliffs (estimated offsets, onAppear, index-kept subviews). Large dynamic lists are SwiftUI's weakest area [UNVERIFIED as measured]. | A's. |
| Text input | Free full text system (`UITextField`/`UITextView`). Build: the "what the view says" sync. Our turn runs on the main thread, so it can be synchronous: RN's flicker came from an async JS thread, which we do not have. | Free `TextField`, but every keystroke goes through a `Binding` to C and back. Synchronous if the shim calls C on main. IME marked text through a binding is a classic SwiftUI bug source [UNVERIFIED]. | A's. |
| Navigation, sheets, alerts | Build: drive `UINavigationController`/`UITabBarController`/`UISheetPresentationController`/`UIAlertController` from our state, and hear the user's back-swipe and dismiss (delegates). RN-screens shows it works, and where it hurts. | Free containers, driven by `NavigationStack(path:)`, `.sheet(item:)`, item `.alert`. Build: the path round-trip. | A's. A SwiftUI island may host a whole flow if wanted. |
| Animation | Build: `UIView.animate`/`UIViewPropertyAnimator` around frame and alpha changes. Our diff knows what entered, left and moved, which is the information animation needs. Blocks are required. | Free implicit animation, but only when changes arrive inside a transaction with stable ids. Build: carrying intent across the C boundary. | A's. |
| Accessibility | Free per control. Build: container grouping and order, RTL frame mirroring, Dynamic Type relayout. | Free incl. grouping and order from SwiftUI's layout. | A's. |
| Layout ownership | **Ours**: `place/` plus a UIKit `Measure`. Web/terminal/iOS parity is provable (oracle). | **SwiftUI's**. Our solver is unused, and `Layout` is mapped approximately to stacks and spacers. | Ours. Islands lay themselves out at a size we give them, via `sizeThatFits` on the hosting controller, as Expo `matchContents` does. |
| Theming hooks | Every UIKit appearance knob: `tintColor`, `UIButton.Configuration`, fonts, dynamic colours, `overrideUserInterfaceStyle`, bar appearances (mind Apple's advice not to override bar backgrounds). Refusals per target are reportable. | SwiftUI modifiers: `.tint`, `.font`, `.foregroundStyle`, `ButtonStyle`, `.preferredColorScheme`. Roughly equal reach, different spelling. | A's. |
| Toolchain | Xcode's clang/ld/actool/codesign. **No Swift compiler** (blocks via Avra-emitted literals or a C helper). | Adds `swiftc` and a Swift module per app. Two compilers, two incremental models. | `swiftc` only when an island or projection is used: "printed, never hidden" (ledger). |
| Binary size | Our code plus UIKit (system). Smallest [UNVERIFIED, no measurement yet]. | Plus the Swift shim (Swift runtime and SwiftUI are system dylibs, so modest) [UNVERIFIED]. | A plus islands used. |
| Startup | Direct: `UIApplicationMain` → scene → first frame from our tree. | Plus SwiftUI graph construction for the whole tree. | A's. |
| Debuggability | One differ. View Debugger shows real UIViews. Crashes are in our code or UIKit's. | Two differs. A wrong render can be ours or SwiftUI's identity. The attribute graph is opaque. | A's, with islands as opaque leaves. |
| Deprecation risk | UIKit is alive (WWDC25/26 features, no removals), but SwiftUI-first is Apple's direction. A slow erosion, not a cliff. | Aligned with Apple's direction. Risk is churn in SwiftUI behaviour per release, and the precedent (LVN) dying. | Lowest: if Apple's centre moves, islands grow. The spine is replaceable per Prim. |
| Android counterpart | Views via JNI, **now in maintenance mode**. Wrong long-term bet. | Compose via a Kotlin shim. The right bet on Android. | On Android: Compose-B. |

**Read.**

- On iOS, H dominates A, because A must have islands anyway (widgets), and dominates B on
  layout ownership, a single differ, toolchain and debuggability.
- On Android, B is forced.
- So the cross-platform architecture is: **a neutral diff in Avra (ours, exact, keyed)**, and
  **per target, an applier**:
  - DOM: patches to JS.
  - UIKit: patches to runtime calls.
  - Compose: patches to a Kotlin snapshot-state tree, which Compose then renders without
    re-diffing structure.
- B's "let the platform diff" becomes, on Android, "let the platform *render* a state tree we
  mutate". That is how a second differ is avoided even with Compose: mutate `mutableStateOf` per
  node from our patches, and do not hand Compose a new tree.

### B. Who owns layout, and can "native by default" coexist with our solver?

- **Yes.** RN is the existence proof: Yoga owns placement, the platform owns measurement, and the
  controls are real UIKit. DivKit is the second proof.
- What RN learned:
  1. Measure text with the platform's text stack, cached (`TextLayoutManager` → TextKit).
  2. Ask native controls for their intrinsic sizes rather than hard-coding them.
  3. Flatten layout-only nodes so the host tree stays shallow (§1: 600–1000 → ~200).
  4. Put the solver and the diff in one shared core, so every platform gets the same
     optimisations.
- **Our seam already matches.** `Measure` is the only unit-bearing interface, and the solver is
  oracle-tested.
- **What native-by-default adds:**
  - Dynamic Type and trait changes must trigger a re-solve.
  - Safe-area and keyboard insets are solver inputs.
  - RTL mirroring is the solver's job, since UIKit won't mirror explicit frames.
  - Scroll containers (`List`, a scrolling `Column`) hand their content size to `UIScrollView`.
- **Where the platform must own layout:** inside its own containers. Bars, sheets'
  detents, tab bars, alerts and the keyboard are laid out by UIKit. Our solver lays out *the
  content area* those containers give us. Any attempt to place a nav bar by frame is fighting the
  platform.

### C. Who owns navigation and presentation?

- **The platform's containers draw and animate. Our state decides.**
- Every serious project converged on this:
  - RN: `react-native-screens`, then native tabs by default in React Navigation 8.
  - Airbnb: waited on SwiftUI navigation APIs rather than draw its own.
  - Ghostty: moved window lifecycle back to AppKit.
- **The cost of fighting it:** imitation bars and tabs miss OS redesigns. Liquid Glass tabs
  required the native `UITabBarController` path in RN. Imitations also miss interactive pop
  gestures, state restoration, accessibility escape gestures and iPad/Mac idioms.
- **The obligation it creates.** Presentation becomes *two-way* state:
  - The user can pop, dismiss a sheet by swipe, or switch tabs without asking us.
  - So a target must report those as events (a `dismiss`/`back` seat) and the program's state
    must accept them, or the next diff re-pushes what the user just closed. RN's tab bug (§1) is
    exactly this disagreement.
- **[LOCAL]** Our dialog already has the web analogue: `on dismiss` and the patch "doors" (a
  dialog closed by the page "before the program hears of it"). iOS generalises the door to
  stacks, tabs and detents.

### D. Identity and state: can two differs coexist?

- **They can coexist only if one of them is reduced to an applier.**
- If both diff, they disagree at the edges:
  - We see a key change as remove plus insert. SwiftUI, given a recycled `.id`, sees an update,
    or the reverse. So transitions run backwards or not at all.
  - SwiftUI view-local state (`@FocusState`, scroll position, a `TextField`'s in-flight marked
    text) is keyed by *SwiftUI's* identity. Any mismatch with ours resets focus or scroll, or
    drops IME composition mid-word.
  - Animations require changes inside SwiftUI transactions. Changes that arrive as "a new tree"
    have no transaction semantics.
- **[LOCAL]** Our identity design already says what must keep its own: "what must keep its own
  through a reorder wears a key", and the terminal keeps focus "by path (follows a keyed row)".
  That is the same contract `UICollectionView` diffable snapshots and Compose `key()` take, so
  one identity feeds every applier.
- **The rule:** **one differ (ours), many appliers.** Platform-side state (focus, scroll,
  composition) lives on host objects that survive because *our* identity kept them.

### E. The smallest spike that decides it (≤ 2 weeks)

**The program.** One screen of the board app, the same component source as the web:

- a nav stack (list → detail push);
- a `List` of N items, each `item { text, switch }`;
- a search `field`;
- a `button` that opens a `dialog` as a sheet;
- an `alert`.

N runs at 1k and 10k.

**Build it two ways**, both on the same Avra diff:

- **A/H (UIKit applier).** About 8 Prims: column, row, text, button, field, switch, list/item,
  dialog. Built from runtime calls through typed `extern` msgSend rows; one runtime class for
  target/action, delegates and data source; `UICollectionView` list with a diffable snapshot;
  frames from `place/` with a UIKit `Measure`; `UINavigationController` and
  `UISheetPresentationController` driven from state. Blocks: one C helper or Avra-emitted block
  literals, whichever the first two days show is cheaper.
- **B (SwiftUI applier).** A Swift shim with `@c` entry points, a per-node `@Observable` store
  mutated by our patches (not a whole-tree swap), and a recursive `NodeView` with explicit `.id`.
  `NavigationStack(path:)` and `.sheet(item:)` are bound to C.

**Measure** (each a number or a pass/fail, recorded with the commit):

1. **Scroll:** frame-time p99 and hitches during a 10k-row fling (Instruments, Hitches template).
2. **Update:** time from a state write to a committed frame when toggling 1 of 10k switches, and
   when inserting a row above the viewport. Does scroll position hold?
3. **Text:** a keystroke-to-model round trip. Japanese IME marked-text composition survives a
   re-render mid-word. Autocorrect and QuickType work. A reformatting `field` (uppercase as you
   type) shows no cursor jump.
4. **Identity:** focus survives an insert above the focused row. Insert/remove animate in the
   right direction.
5. **Navigation:** back-swipe and sheet swipe-dismiss reach the program as events, and the next
   diff does not re-present them.
6. **Accessibility:** a VoiceOver walk order matches reading order, Dynamic Type at AX5 re-lays
   without truncation, and RTL mirrors.
7. **Look:** build against the iOS 26 and iOS 27 SDKs, and screenshot both. Liquid Glass
   appears with no code change.
8. **Cost:** binary size delta, cold start to first frame, lines of applier code, and the number
   of tool binaries the build needs (is `swiftc` required?).
9. **Debug:** seed three bugs (wrong key, stale prop, leak) and time to diagnose each.

**Decision rule, set before the spike:**

- If A/H matches B on 3–5 within noise and beats it on 1, 2, 8 and 9, H wins on iOS.
- If B wins text input (3) or identity (4) outright, reconsider B for iOS.
- Android is decided already (Compose) unless the spike shows the Compose applier cannot avoid a
  second structural diff.

### F. The ten lessons, ranked

1. **Whoever draws the controls inherits the OS redesign lag.** Flutter declined Liquid Glass in
   Cupertino, while UIKit/SwiftUI standard controls got it at recompile
   ([VGV](https://verygood.ventures/blog/a-new-era-for-app-design-and-what-it-means-for-flutter/);
   [Apple](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)).
2. **Text input is where foreign UI breaks first.** Compose Multiplatform added a native
   `UITextInput` view in 2026, and RN's async controlled inputs flicker
   ([CMP 1.11](https://blog.jetbrains.com/kotlin/2026/05/compose-multiplatform-1-11-0);
   [Expo](https://docs.expo.dev/guides/controlled-components/)).
3. **Android Views are frozen (May 2026), so the Android realizer must target Compose**
   ([Android Developers](https://developer.android.com/blog/posts/android-ui-development-is-compose-first)).
4. **Use the platform's navigation and presentation containers, and treat their user-initiated
   changes as events** ([react-native-screens](https://github.com/software-mansion/react-native-screens/blob/main/native-stack/README.md);
   [RN tabs bug](https://github.com/callstack/react-native-bottom-tabs/issues/461)).
5. **One differ, many appliers.** RN's shared C++ diff gave flattening to iOS too, while "ship
   the tree to SwiftUI" products (LVN, Tokamak) were archived
   ([RN](https://reactnative.dev/docs/next/view-flattening);
   [LVN](https://github.com/liveview-native/live_view_native)).
6. **Our solver places, and the platform measures** (RN's `TextLayoutManager` → TextKit; DivKit
   LayoutKit on UIKit)
   ([RN source](https://cdn.jsdelivr.net/npm/react-native@0.85.1/ReactCommon/react/renderer/components/text/ParagraphShadowNode.cpp);
   [DivKit](https://github.com/divkit/divkit/tree/main/client/ios)).
7. **Lists need platform recycling plus stable keys.** Unstable keys or props defeat recycling
   ([FlashList v2](https://shopify.engineering/flashlist-v2)).
8. **Stay synchronous on the main thread.** RN rebuilt its architecture to escape the async
   bridge, and Avra's in-process turn starts where RN ended up
   ([RN 0.82](https://reactnative.dev/blog/2025/10/08/react-native-0.82)).
9. **SwiftUI is still owed for widgets, Live Activities and new SwiftUI-first controls, so plan
   islands from day one.** Expo UI is the shipping pattern
   ([Expo Host](https://docs.expo.dev/versions/latest/sdk/ui/swift-ui/host.md)).
10. **The shell is a contract that moves.** It needs UIScene (iOS 27 SDK), an Xcode 26+ SDK
    floor for uploads, and the SDK licensed to Apple hardware, so build iOS on macOS
    ([iKyle](https://www.ikyle.me/blog/2026/whats-new-in-uikit-ios-27);
    [Apple requirements](https://developer.apple.com/news/upcoming-requirements/);
    [OSNews](https://www.osnews.com/story/142331/xtool-cross-platform-xcode-replacement-for-linux-windows-and-macos/)).

---

## Appendix — unknowns this study could not close

- Measured SwiftUI vs `UICollectionView` numbers for a 10k-row list under external mutation
  (iOS 27). The spike measures it.
- IME marked text through a SwiftUI `Binding` round-tripping to C [UNVERIFIED folklore].
- Objective-C surfaces of UIKit's new observation and `updateProperties()` APIs [UNVERIFIED].
  They are not needed by A.
- Avra-emitted Clang-ABI blocks vs a small clang-compiled C helper (spike day 1).
- Static Hermes / Hermes V1 2026 status, and App Store Connect upload without Xcode from
  non-Mac hosts [UNVERIFIED].
- Judo, Rise, Backpack, Lyft and Spotify SDUI internals. The full current list of SwiftUI-only
  system surfaces should be rechecked at implementation time.
