# Theming — prior art, with the failures first

Study for the Avra UI library's theming system. Researched 2026-11-16.
Requirements it answers to: native by default; brandable on demand; a
web default of its own; one component source; a theme is plain typed
data; components name ROLES, never values.

Conventions: every claim carries its source inline. **UNVERIFIED** marks
a claim from memory or a secondary source I could not confirm against a
primary one. "Forum report" means one developer's report, not a
confirmed platform behaviour.

---

## 0. The answer in one screen

- **The portable core is small**: accent/tint, a light/dark appearance,
  contrast level, text-size scale, and a handful of SEMANTIC colour roles
  the platform already defines (label/secondary label, background
  levels, separator, destructive). Every native toolkit honours those
  natively. Almost everything else — corner radius, control height,
  fill colour of a native button, bar backgrounds — is a CLIFF on at
  least one platform.
- **The cliff is real and recent**: iOS 26's Liquid Glass stopped
  honouring bar backgrounds and window tint that apps had set for years
  ([forum 788176](https://developer.apple.com/forums/thread/788176),
  [forum 799700](https://developer.apple.com/forums/thread/799700)), and
  Apple's own guidance is "reduce custom backgrounds in navigation
  elements". The opt-out key dies when building against iOS 27
  ([forum 832543](https://developer.apple.com/forums/thread/832543)).
  A native-by-default library must assume the OS will repaint its
  controls under it and that brand overrides on chrome will be ignored.
- **Draw-it-yourself frameworks lose exactly that race**: Flutter's
  Cupertino still has no Liquid Glass 17 months after WWDC25; the team
  said in June 2025 it would not build it or accept contributions
  ([flutter#170310](https://github.com/flutter/flutter/issues/170310)),
  and froze Material/Cupertino in the framework, moving them to
  `material_ui`/`cupertino_ui` packages
  ([Flutter blog](https://flutter.dev/blog/decoupling-material-cupertino)).
- **Theme = layered, mode axes are orthogonal**: appearance x contrast x
  density x brand, each a small record; never one fat record per
  combination.
- **Contrast is provable at build time from roles**, provided roles come
  in `bg`/`on-bg` PAIRS (Material's `on*`, libadwaita's `-bg`/`-fg`,
  shadcn's `-foreground`). Prove against WCAG 2.x; APCA is not in WCAG 3
  ([Roselli, Apr 2026](https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html)).

---

## 1. Token architectures (primitive -> semantic -> component)

### (a) The model

Three tiers: **primitive/global** (`blue-60 = #0f6cbd`), **semantic/alias**
(`colorBrandBackground = blue-60`), **component** (`button.primary.bg =
colorBrandBackground`). Material 3 calls them reference / system /
component tokens; Fluent 2 global / alias / component
([Fluent 2 tokens](https://fluent2.microsoft.design/design-tokens),
[Fluent colour tokens](https://fluent2.microsoft.design/color-tokens));
Spectrum "global / alias / component"
([Spectrum tokens](https://spectrum.adobe.com/page/design-tokens)).
The W3C DTCG format standardises the file: `{"$type": "color",
"$value": "{color.blue.60}"}`, aliases as `{path}`.

```json
{ "brand": { "$type": "color", "$value": "#0f6cbd" },
  "accent": { "$type": "color", "$value": "{brand}" } }
```

DTCG reached its **first stable version, 2025.10**, on 2025-10-28, with
a Format module and a separate **Resolver module** for multi-context
(light/dark) sets
([W3C CG announcement](https://w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/),
[Format 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/),
[Resolver 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-resolver-20251028/)).
It is a Community Group report, **not** a W3C standard.

### (b) What authors hate

- **The component tier explodes and gets taken back.** Adobe Spectrum
  deprecated **540 component-specific spacing tokens** in one release,
  repointing each to a semantic one (671 tokens changed)
  ([spectrum-design-data releases](https://github.gg22.workers.dev/adobe/spectrum-design-data/releases)).
  Rangle's practitioner account: as a system matures, component tokens
  "can be folded into semantic tokens"
  ([Rangle](https://rangle.io/blog/developing-your-token-structure)).
- **Over-engineering for small products**: a full three-tier pipeline
  for one theme and no native targets is called over-engineering by
  practitioner guides; size tiers to targets shipped
  ([summary of guides](https://awesome-everything.pages.dev/en/learn/frontend/04-tokens/01-overview/)) — UNVERIFIED as a primary critique; no
  canonical "tiers are bureaucracy" essay surfaced.
- **Alias chains are opaque**: Tailwind v4 had to add `@theme inline`
  because a variable referencing another variable "resolves where it's
  defined, which can produce unexpected fallbacks"
  ([Tailwind theme docs](https://tailwindcss.com/docs/theme)). The same
  class of bug — an alias resolved in the wrong scope — recurs in every
  CSS-variable token system.
- **Value-named tokens rot at rebrand** (`blue-600` used as "primary"),
  which is the whole reason the semantic tier exists
  ([OUP rebrand write-up](https://design-profiler.oup.com/design-tokens-rebrand/)).
- **Naming bikeshed**: Nathan Curtis's taxonomy (namespace, category,
  variant, scale; modifiers last) is the reference, and large systems
  still run 2-4 levels of name
  ([Curtis, EightShapes](https://nathanacurtis.substack.com/p/naming-tokens-in-design-systems-9e86c7444676)).

### (c) What the authors changed

- Spectrum: migrating to a new "cascade" token format as source of
  truth, generating the legacy format from it
  ([Spectrum Design Data evolution](https://opensource.adobe.com/spectrum-design-data/spec/evolution));
  Spectrum Web Components moved from "Spectrum Vars" to "Core Tokens"
  ([SWC core tokens](https://opensource.adobe.com/spectrum-web-components/tools/core-tokens)).
- DTCG split "how to resolve modes" into its own module rather than
  putting modes in the token file — the format group's own admission
  that theming is a SEPARATE axis from token definition.

**Lesson for Avra**: two tiers are the default (palette -> roles);
component tokens exist only as a component's OWN typed defaults, never
as a global namespace. A third tier is a smell that roles are missing.

---

## 2. Platform-native semantic systems

### 2.1 Apple (iOS/iPadOS/macOS 26)

**(a) Model.** Dynamic system colours "semantically defined by [their]
purpose, rather than [their] appearance" — `label`,
`secondaryLabel`…`quaternaryLabel`, `systemBackground` and its
secondary/tertiary/grouped variants, `systemFill` levels, `separator`;
one app **accent/tint**; **Dynamic Type** text styles (largeTitle,
title1-3, headline, body, callout, subheadline, footnote, caption1-2);
**materials** (Liquid Glass regular/clear for the control layer;
ultra-thin…thick for the content layer) with vibrant label/fill
colours designed for each; SF Symbols; control sizes
(mini…extraLarge). All quotes from the HIG
([Color](https://developer.apple.com/design/human-interface-guidelines/color),
[Typography](https://developer.apple.com/design/human-interface-guidelines/typography),
[Materials](https://developer.apple.com/design/human-interface-guidelines/materials)).

```swift
Text("Title").font(.headline).foregroundStyle(.secondary)
view.backgroundColor = .systemBackground
```

HIG rules that matter for a theme system (verbatim):
"Avoid hard-coding system color values in your app." "Avoid redefining
the semantic meanings of dynamic system colors." "Even if your app ships
in a single appearance mode, provide both light and dark colors to
support Liquid Glass adaptivity." "Apply color sparingly to the Liquid
Glass material." On macOS: if the user picks an accent other than
multicolor, "the system applies their chosen color … replacing your
accent color" ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)).
Minimum contrast 4.5:1 up to 17 pt, 3:1 at 18 pt or bold; "if your app
doesn't provide this minimum contrast by default, ensure it at least
provides a higher contrast color scheme when … Increase Contrast is
turned on". Default/minimum control size: iOS 44x44 / 28x28 pt, macOS
28x28 / 20x20 pt
([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)).

**What a third-party app may restyle**: accent/tint; its own custom
colours (asset catalog with light/dark/high-contrast variants); fonts
(custom fonts must be tied to a text style to scale:
`.custom("Avenir", size: 17, relativeTo: .body)`); button styles
(`.borderedProminent`, custom `ButtonStyle`). **Not** reliably: bar
backgrounds, glass tint, system sheets, menus, alerts, keyboard, share
sheet.

**(b) Failure modes.**
- **Liquid Glass broke existing brand customisations**: forum reports
  that iOS 26 no longer honours `tintColor` on window/nav bar/toolbar
  for glass components ([788176](https://developer.apple.com/forums/thread/788176));
  `UINavigationBarAppearance.backgroundColor` drew over the large title,
  fixed by applying it only below iOS 26
  ([Classmethod](https://dev.classmethod.jp/en/articles/ios26-navigationstack-large-title-hidden-bug/));
  asset-catalog colours ignored on glass where system colours work
  ([825708](https://developer.apple.com/forums/thread/825708)); popover
  `backgroundColor` reportedly ignored
  ([neil95](https://origin-devforums.apple.com/forums/profile/neil95)).
  Apple's reply in threads: TN3106 says reduce custom backgrounds in
  navigation elements; custom appearances "may interfere"
  ([822878](https://developer.apple.com/forums/thread/822878)).
  Field guide: [fatbobman](https://fatbobman.com/en/posts/liquid-glass-a-field-guide-to-uikit-compatibility-pitfalls/).
- **Opt-out is temporary**: `UIDesignRequiresCompatibility` is "a
  temporary key … ignored when you build for iOS 27"
  ([forum 832543](https://developer.apple.com/forums/thread/832543),
  [801712](https://developer.apple.com/forums/thread/801712)). Any App
  Store date (April 2027) is a projection, UNVERIFIED
  ([Baytech](https://www.baytechconsulting.com/blog/liquid-glass-app-store-deadline-misunderstood)).
- **macOS Tahoe made controls taller**; autoresizing-mask layouts broke,
  and Apple added `prefersCompactControlSizeMetrics` to get macOS 15
  metrics ([NSButtons bigger](https://developer.apple.com/forums/thread/791190),
  [AppKit doc](https://developer.apple.com/documentation/appkit/nsview/preferscompactcontrolsizemetrics.md));
  a 26.1 point release changed SF Symbol scaling in glass buttons again
  ([807274](https://developer.apple.com/forums/thread/807274)).
  **Native metrics move between OS releases.** A theme that pins heights
  in points is a bug report a year later.
- **Dynamic Type breaks fixed layouts**: DTS lists fixed-height
  containers, non-preferred fonts and missing
  `adjustsFontForContentSizeCategory` as the causes
  ([815615](https://developer.apple.com/forums/thread/815615)); the
  escape hatch `maximumContentSizeCategory` / `.dynamicTypeSize(...)`
  is capping, which hides the problem from the users who need it
  ([useyourloaf](https://useyourloaf.com/blog/restricting-dynamic-type-sizes/)).

**(c) What Apple changed.** Liquid Glass (June 2025) re-centred the
system on "content layer vs functional layer": colour belongs to
content, controls take their colour from what is behind them. HIG Color
page updated 2025-06-09 and 2025-12-16 for Liquid Glass. The SF Symbols
licence restricts use to software for Apple platforms
([forum 739523](https://developer.apple.com/forums/thread/739523),
[757407](https://developer.apple.com/forums/thread/757407)).

### 2.2 Android (Material 3 / Material You / M3 Expressive)

**(a) Model.** A `ColorScheme` of named roles, generated from one seed
via HCT tonal palettes (13 tones per key colour; five key colours:
primary, secondary, tertiary, neutral, neutral-variant); Dynamic Color
(Android 12+) derives the seed from the wallpaper; variants Tonal Spot,
Neutral, Vibrant, Expressive
([Android dynamic colours](https://developer.android.com/develop/ui/views/theming/dynamic-colors)).
Compose's `ColorScheme` currently has **48 colour properties**
(primary/on/container/on-container x3, error x4, five surface-container
levels plus dim/bright/variant/tint, inverse x3, outline x2, scrim,
the six `*Fixed`/`*FixedDim` and four `on*Fixed[Variant]` per accent
family) — counted from the [reference](https://developer.android.com/reference/kotlin/androidx/compose/material3/ColorScheme).
Typography: 15 styles (display/headline/title/body/label x L/M/S);
shape scale; elevation via tonal surface levels.
M3 Expressive adds `MaterialExpressiveTheme(colorScheme, motionScheme,
shapes, typography)` with `MotionScheme.expressive()` and morphable
`MaterialShapes`, still `@ExperimentalMaterial3ExpressiveApi`
([API](https://kotlinlang.org/api/compose-multiplatform/material3/androidx.compose.material3/-material-expressive-theme.html),
[Androidify post](https://android-developers.googleblog.com/2025/05/androidify-building-delightful-ui-with-compose.html)).

```kotlin
MaterialTheme(colorScheme = if (dynamic) dynamicLightColorScheme(ctx) else brandLight) {
  Text("Hi", color = MaterialTheme.colorScheme.onSurfaceVariant)
}
```

**What a third-party app may restyle**: everything inside its own
window — Material is a library, not the OS. The OS-drawn parts are few
(status/nav bars, system dialogs, notifications, widgets' dynamic colour).

**(b) Failure modes.**
- **Brand vs dynamic colour**: turning on dynamic colour replaces the
  brand palette with the wallpaper's. Google's own answer is two escape
  hatches: keep custom colours outside the scheme, or **harmonize**
  them — `HarmonizedColors` shifts the brand hue toward the user's
  ([Android docs](https://developer.android.com/develop/ui/views/theming/dynamic-colors#retain)).
  i.e. even Google concedes the brand loses unless it opts out.
- **Role count**: 48 roles, several of which (`surfaceVariant`,
  `background`/`onBackground`, `surfaceTint`) were superseded by the
  surface-container ladder in 2023 but kept for compatibility (role
  names from the reference; the supersession narrative is UNVERIFIED —
  the m3 site would not render for me).
- **Large font scaling is non-linear since Android 14 (to 200%)**;
  `4sp + 20sp` no longer equals `24sp`, and rows of buttons stop
  fitting ([Flutter breaking-change note](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration),
  [FontScaleConverter](https://developer.android.com/reference/android/content/res/FontScaleConverter),
  [CommonsWare](https://commonsware.com/blog/2023/07/08/text-will-not-always-scale.html)).
- **Styling a component across many parameters** — Google's own framing
  for the new Compose **Styles** API (experimental since Compose 1.11,
  April 2026) is "a unified, performant way to style components"
  ([April 2026](https://android-developers.googleblog.com/2026/04/jetpack-compose-april-2026-updates.html),
  [August 2026](https://android-developers.googleblog.com/2026/08/jetpack-compose-august-2026-release.html)).

**(c) What Google changed.** The Styles API was **pulled back** after
I/O feedback: "we're evolving the API to make the core Styles APIs less
opinionated. Instead of the foundation layer defining visual properties,
property definitions are moving to the design system layer … (`stylePropertyOf`
/ `styleLocalOf`)" and the docs were temporarily removed
([Compose styles page](https://developer.android.com/develop/ui/compose/styles/state-animations)).
That is the single most relevant regret for Avra: **the foundation
must not own the property vocabulary; the design system does.**

### 2.3 Windows (Fluent 2 / WinUI 3)

**(a) Model.** Theme resources (`ThemeDictionaries` Light/Dark/
HighContrast), system accent with light/dark shades, backdrop
materials Mica / Mica Alt / Acrylic; Fluent 2 alias tokens such as
`colorNeutralForeground1`, `colorBrandBackground`, a 16-step brand ramp
(`shade10…shade160`) fed to `createLightTheme(brand)` in Fluent React
([@fluentui/react-theme](https://www.npmjs.com/package/@fluentui/react-theme),
[Fluent colour tokens](https://fluent2.microsoft.design/color-tokens)).
"Lightweight styling" overrides one control's resource keys for a
subtree without re-templating.

**(b) Failure modes.**
- Mica falls back to a solid colour on weak GPUs or when the user turns
  transparency off (`SolidBackgroundFillColorBase`)
  ([Mica docs](https://learn.microsoft.com/windows/apps/design/style/mica)) —
  fine, but a theme must never assume translucency.
- High contrast: "Do not choose color resource for aesthetics …
  the colors change with the theme" — hard-coded colours break HC
  ([contrast themes](https://msdn.microsoft.com/en-us/library/windows/apps/xaml/mt244346)).
- Accent change events: a WinUI 3 developer reports needing
  `UISettings.ColorValuesChanged` because the expected event doesn't
  fire ([In The Hand](https://inthehand.com/2023/07/11/titlebars-and-themes-a-winui-adventure/)) — forum-grade.

**(c)** Fluent 2 unified tokens across web/iOS/Android/Windows under one
alias vocabulary; it is the closest existing "one theme, many native
targets" token set, but each platform's control library is still
separate (Fluent UI React, Fluent UI Apple, WinUI). UNVERIFIED as to how
much they actually share at runtime.

### 2.4 GNOME / libadwaita

**(a) Model.** CSS variables in **bg/fg pairs**: `--accent-bg-color`/
`--accent-fg-color`/`--accent-color`, destructive, success, warning,
error, window, view, headerbar, sidebar, card, dialog, popover…; nine
accent presets (blue, teal, green, yellow, orange, red, pink, purple,
slate); style classes (`.suggested-action`, `.destructive-action`,
`.accent`, `.card`…). Apps follow the system accent by default
(libadwaita 1.6+, `AdwStyleManager:accent-color`)
([CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html),
[Styles & appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.7/styles-and-appearance.html)).

```css
:root { --accent-bg-color: var(--accent-purple); }
```

App may override UI colour variables; must keep header-bar/sidebar
`*-backdrop-color` in sync; must not override helper variables
(`--border-opacity`, `--dim-opacity`…); the GTK3 `@define-color`
names "don't pick up overridden colors … avoid using these colors
entirely" (ibid.).

**(b) Failure modes / politics.**
- **"Please don't theme our apps"** (2019): app developers asked
  distributions to stop shipping GTK/icon themes by default because
  themes broke apps, changed icon metaphors, denied brand control, and
  users filed the theme's bugs against the app
  ([stopthemingmy.app](https://stopthemingmy.app/),
  [OMG! Ubuntu](https://www.omgubuntu.co.uk/2019/05/open-letter-stop-gtk-theming-distros)).
  Ubuntu and Pop!_OS stopped theming third-party icons. Critics called
  it at odds with software freedom
  ([Arch forum](https://bbs.archlinux.org/viewtopic.php?id=246650)).
- libadwaita answered by making **the stylesheet part of the API**,
  frozen at 1.0 ([alatiera](https://blogs.gnome.org/alatiera/2021/09/18/the-truth-they-are-not-telling-you-about-themes/)),
  exposing recolouring through named colours instead of a theming API
  (31 named colours at 1.0, per the 1.0 announcement summarised from
  [Libadwaita 1.0](https://blogs.gnome.org/alexm/2021/12)), and adding
  accent colour only in 1.6 with a fixed preset list.

**(c) Lesson**: the platform drew a line between **recolouring** (allowed,
via a closed set of named role colours) and **restyling** (geometry,
widget drawing — not allowed). That is the same line Apple drew in
practice with Liquid Glass. It is the portable line.

---

## 3. "Native controls, cross-platform source"

### 3.1 React Native

**(a)** Core components map to native views; styling is a CSS subset
(flexbox, colours, borders, radius) applied to native views.
`PlatformColor('label')` reads the platform's semantic colour;
`DynamicColorIOS({light, dark, highContrastLight, highContrastDark})`
mirrors `UIColor(dynamicProvider:)`
([colors](https://reactnative.dev/docs/colors),
[DynamicColorIOS](https://reactnative.dev/docs/dynamiccolorios)).
Theming is entirely userland: NativeWind (Tailwind classes compiled to
StyleSheet, CSS-variable themes), Unistyles 3 (theme deps tracked in
C++, no React re-render on theme change; New Architecture + RN 0.78+),
Tamagui (compiler + themes)
([comparison 2026](https://reactnativerelay.com/article/react-native-styling-2026-nativewind-unistyles-tamagui-compared),
[LogRocket](https://blog.logrocket.com/unistyles-vs-tamagui-cross-platform-react-native-styles/)).

**(b) The cliff, stated by the docs**: `Button` "Supports a minimal
level of customization" — its only style prop is `color` ("Color of the
text (iOS), or background color of the button (Android)" — one prop,
two meanings) — and "If this button doesn't look right for your app,
you can build your own button using Pressable"
([Button docs](https://reactnative.dev/docs/button)). In practice every
branded RN app builds its own buttons, so "native" survives only for
Switch, pickers, text input, scroll, modals. Three competing styling
libraries with different theme models exist because core has none;
performance claims between them are vendor benchmarks
([Tamagui benchmarks](https://tamagui.dev/docs/intro/benchmarks)).

**(c)** Meta never shipped a core theming API; PlatformColor/
DynamicColorIOS were the concession (2020). Platform-specific overrides
are `Platform.select` / `.ios.tsx` files.

### 3.2 .NET MAUI / Xamarin.Forms

**(a)** Cross-platform controls are mapped to native views by
**handlers**; a `Mapper` maps each property to a native setter.
Customisation = `ButtonHandler.Mapper.AppendToMapping("x", (h, v) =>
h.PlatformView…)`, inside `#if IOS` blocks
([customize handlers](https://learn.microsoft.com/dotnet/maui/user-interface/handlers/customize)).
Theme = XAML `ResourceDictionary` + `AppThemeBinding Light=… Dark=…`.

**(b)** Mapper customisations are **global** — every instance of the
control changes unless you subclass and type-check
([MAUI wiki](https://www.github.com/dotnet/maui/wiki/Customizing-Controls-with-Handlers));
MAUI controls "may not expose all the APIs available in their native
counterparts", so styling routinely drops to platform code
([Syncfusion](https://www.syncfusion.com/blogs/post/how-to-customize-net-maui-controls-with-handler-architecture)).
Leaking native event handlers if not unsubscribed in `HandlerChanging`.
The lowest-common-denominator property set (BackgroundColor,
CornerRadius, BorderColor) is honoured differently per platform —
UNVERIFIED specific cases.

**(c)** Xamarin.Forms' renderers were replaced by handlers precisely to
make the native escape cheaper and less coupled. Xamarin.Forms
"Visual=Material" (one look on both platforms) did not carry into MAUI
— UNVERIFIED (no Microsoft statement found; a migration error report
only, [Q&A](https://techcommunity.microsoft.com/t5/app-development/issue-with-upgrade-xamarin-to-net-6/m-p/2942596/highlight/true)).

### 3.3 Compose Multiplatform (iOS)

Draws its own UI with Skia on iOS; Material 3 is the only first-party
look; JetBrains said at alpha it had not decided whether to provide a
native look ([InfoQ 2023](https://www.infoq.com/news/2023/05/compose-multiplatform-ios-alpha));
1.8 (May 2025) declared iOS stable and emphasised native-feeling
gestures and scrolling, not native controls
([JetBrains](https://blog.jetbrains.com/kotlin/2025/05/compose-multiplatform-1-8-0-released)).
Investment since is **interop** (UIKit view sizing in 1.10)
([1.10 notes](https://kotlinlang.org/docs/multiplatform/whats-new-compose-110.html)).
Community fills the gap: compose-cupertino (look-alike widgets, plus a
`cupertino-native` module wrapping real UIKit controls)
([GitHub](https://www.github.com/alexzhirkevich/compose-cupertino)),
NativeComposeKit (Material on Android, UIKit on iOS behind one API, 0.3)
([klibs](https://klibs.io/project/Apdelrahman1911/NativeComposeKit)).
Forum consensus: "unless you swap in the native widgets under the hood,
like Redwood seems to do, you will not get the full alignment"
([kotlinlang slack](https://slack-chats.kotlinlang.org/t/5060495/does-compose-look-native-look-and-feel-on-ios-or-like-materi)).

### 3.4 NativeScript

CSS on native views, but "only a subset of the CSS language is
supported", plus native-only properties (`android-elevation`,
`tab-text-color`, `horizontal-align`); unsupported rules are parsed and
ignored silently ([styling](https://docs.nativescript.org/guide/styling),
[legacy docs](https://old.docs.nativescript.org/angular/ui/styling)).
Failure mode: **silent ignore** — a property that works on web does
nothing on a native view and nobody is told.

### 3.5 Qt Widgets / wxWidgets

- **Qt**: applying a style sheet replaces the widget's `QStyle` with a
  wrapper that forwards to the native style only for parts the sheet
  doesn't touch; on macOS, setting a sheet on a container made its
  native controls stop drawing natively
  ([Qt stylesheet docs](https://doc.qt.io/qt-6/stylesheet.html),
  [qt-interest 2010](https://lists.qt-project.org/pipermail/qt-interest-old/2010-November/028967.html)).
  Projects respond by forcing Fusion everywhere
  ([inishell issue](https://models.slf.ch/p/inishell-ng/issues/804/)).
  **That is the cliff in its purest form: one property customised ->
  the whole control silently becomes non-native.**
- **wxWidgets**: "Changing colours of the native controls can't be
  relied on … could be not supported at all depending on the control and
  platform" ([commit message](https://git.amebis.si/Amebis/wxWidgets/commit/540fed921647308e952ec56d4624d2ebd09ea07a));
  wxButton on a coloured background leaves artifacts around rounded
  corners on macOS ([wx-dev](https://groups.google.com/g/wx-dev/c/qNacMaZnhJ0));
  setting background colours broke macOS dark mode for a wxPython app
  ([discuss](https://discuss.wxpython.org/t/alpha-background-on-macos/34732)).
  Remedy is "generic" (custom-drawn) controls.

**Cross-cutting lesson**: every native-wrapping framework has a
property set that some platform ignores, and every one fails SILENTLY.
Avra can do better: the compiler knows the target, so a theme property
a target cannot honour natively is a **diagnostic**, and the switch to
a custom-drawn control is an **explicit, spelled choice** at the site.

---

## 4. "Draw it ourselves", for contrast

### Flutter

**(a)** `ThemeData` (colorScheme, textTheme, ~40 component sub-themes
like `elevatedButtonTheme`); Cupertino has its own `CupertinoThemeData`;
`.adaptive` constructors (`Switch.adaptive`, `Slider.adaptive`) pick a
Cupertino widget when `ThemeData.platform` is iOS/macOS
([Switch.adaptive](https://api.flutter.dev/flutter/material/Switch/Switch.adaptive.html)).

**(b) What it loses.**
- **New OS looks**: Liquid Glass open since 2025-06-10, P3, now labelled
  for the `cupertino_ui` package; team: not developing Apple '26 design,
  won't accept contributions in-framework
  ([#170310](https://github.com/flutter/flutter/issues/170310)). Early
  `liquid_glass` PRs to cupertino_ui appeared Oct 2026 (merge status
  unknown). Third parties use **platform views of real UIKit controls**
  to get it ([cupertino_native_better](https://pub.dev/documentation/cupertino_native_better/1.6.0/))
  — i.e. the draw-it-yourself framework's answer to native look is
  "embed native controls".
- **The seam**: OS-drawn UI (keyboard, share sheet) is glass on iOS 26;
  Flutter screens beside it are not ([issoh, Aug 2026](https://www.issoh.co.jp/tech/details/16743/), secondary).
- **Two themes, two widget sets**: Material and Cupertino theme data
  don't share roles; `.adaptive` swaps the widget but not the layout
  idiom, and a commenter on the decoupling proposal says the doc
  considers deprecating `.adaptive` entirely — UNVERIFIED
  ([Reddit](https://reddit.zackpollard.pro/r/FlutterDev/comments/1md1t9f/flutter_team_is_making_a_muchneeded_architectural)).
- **Accessibility drift**: Flutter had to ship a breaking change to
  follow Android 14's non-linear text scaling; `TextScaler.linear`
  silently flattens it back
  ([breaking change](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration)).
  Every OS a11y feature must be re-implemented.

**(c)** Material & Cupertino frozen in-framework from Flutter 3.44 (April
7th freeze), `material_ui`/`cupertino_ui` 1.0 shipped with 3.47
matching the frozen code, in-framework libraries to be deprecated; the
team "not actively developing Material 3 Expressive" either
([decoupling blog](https://flutter.dev/blog/decoupling-material-cupertino),
[code freeze](https://flutter.dev/blog/flutters-material-and-cupertino-code-freeze),
[migration](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)).
The self-drawn framework now lags BOTH platform design languages.

### Compose Multiplatform on iOS
Loses: native controls (Material on iOS), Liquid Glass, system text
editing nuance, and OS-version restyles; keeps one codebase. See 3.3.

**Lesson**: a self-drawn look is a promise to re-implement every OS's
next redesign on the OS's schedule. Neither Google (Flutter) nor
JetBrains kept that promise for iOS. Native-by-default is the only
design where an OS redesign is free.

---

## 5. Web theming

**(a) The platform today.**
- Custom properties as tokens; `color-scheme: light dark` +
  `light-dark(a, b)` (Baseline 2024; requires `color-scheme` to include
  `dark`; only two states — contrast is separate)
  ([MDN light-dark](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark)).
- `@scope` Baseline since Firefox 146 (Dec 2025)
  ([web.dev Dec 2025](https://web.dev/blog/web-platform-12-2025));
  `contrast-color()` Baseline newly available (Chrome 133, Firefox 142,
  Safari 26.2 per web.dev; locales disagree — verify)
  (same source).
- `@layer` cascade layers (Baseline 2022 — from memory, UNVERIFIED
  date) — the cure for specificity wars between reset, library, theme
  and app.
- System colours (`Canvas`, `CanvasText`, `ButtonText`, `AccentColor`…)
  and `accent-color` for native form controls; `forced-colors: active`
  overrides `color`, `background-color`, `border-color`, `outline-color`,
  SVG fill/stroke, forces `box-shadow: none` — "intended usage is to make
  small tweaks", don't build a separate design
  ([MDN forced-colors](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors)).
- `prefers-contrast`, `prefers-reduced-motion` (broad support);
  `prefers-reduced-transparency`: Chrome/Edge 118+, Firefox only
  recently, **Safari none** (privacy concern)
  ([Chrome blog](https://developer.chrome.com/blog/css-prefers-reduced-transparency),
  [caniuse](https://caniuse.com/wf-prefers-reduced-transparency)).
- Tailwind v4: tokens declared in CSS via `@theme`, which generates
  utilities AND emits real CSS variables; namespaces `--color-*`,
  `--spacing`, `--radius-*`, `--text-*`, `--breakpoint-*`; `--color-*:
  initial` removes defaults; unused variables dropped unless `@theme
  static`; theme variables "can't be nested under selectors or media
  queries" ([Tailwind theme](https://tailwindcss.com/docs/theme)).
  Dark mode defaults to the media query; class-based needs
  `@custom-variant dark (&:where(.dark, .dark *))`.
- shadcn/ui: unstyled Radix primitives + copied component source +
  CSS variables in **`--x` / `--x-foreground` pairs** (`--primary`,
  `--primary-foreground`, `--muted`, `--muted-foreground`, `--card`,
  `--popover`, `--border`, `--ring`…), OKLCH by default in v4, wired to
  Tailwind with `@theme inline`
  ([shadcn theming](https://ui.shadcn.com/docs/theming)).

**(b) What authors hate.**
- **Runtime CSS-in-JS**: an Emotion maintainer: "the runtime performance
  cost of Emotion far outweighed the developer-experience benefits";
  inserting rules at render is "fundamentally bad for performance"
  ([Magura, 2022](https://dev.to/srmagura/why-were-breaking-up-wiht-css-in-js-4g9b),
  [InfoQ](https://www.infoq.com/news/2022/10/prefer-build-time-css-js/)).
  React Server Components then made runtime-injected styles awkward;
  the field moved to build-time extraction (vanilla-extract, StyleX,
  Panda) and utility CSS.
- **Specificity/override wars**: a library's `.btn.btn-primary` vs the
  app's `.my-btn` vs `!important`; layers and `:where()` (zero
  specificity) exist because of this. UNVERIFIED as cited history —
  common knowledge.
- **Tailwind's utility soup** for variants -> `cva`, `tailwind-variants`,
  `tailwind-merge` (to resolve conflicting classes at runtime) — a
  runtime class-merging step that exists only because two override
  sources collide.
- **Portals escape the theme**: Radix Themes: a custom portal "naturally
  appears outside of the root Theme component, which means it won't
  have access to most of the theme tokens" — wrap it in another `<Theme>`
  ([Radix styling](https://radix-ui.com/themes/docs/overview/styling));
  primitives Dialog losing theme styles
  ([discussion #2862](https://github-redirect.dependabot.com/radix-ui/primitives/discussions/2862));
  Headless UI dark: modifier not applying in dialogs
  ([lightrun](https://lightrun.com/answers/tailwindlabs-headlessui-bug-dark-modifier-doesnt-seem-to-work-with-dialogs)).

**(c)** The web's own trajectory is the lesson: **tokens became CSS
variables; theming moved from JS runtime to build time + the cascade;
modes moved into the platform (`light-dark`, `prefers-*`).** Avra's web
target should emit static CSS with role variables and let the browser
switch modes — zero runtime theme code.

---

## 6. Subtree and scoped theming

| System | How | What breaks |
|---|---|---|
| SwiftUI | `.environment(\.colorScheme, .dark)`, `.tint()`, `.preferredColorScheme` | Sheets/alerts/menus are OS-drawn; a subtree override does not reach presented system UI reliably (UNVERIFIED specific cases) |
| UIKit | `overrideUserInterfaceStyle` per view/VC; `UIAppearance` proxies `whenContainedInInstancesOf:` | appearance proxies are global, process-wide; glass bars now ignore many of them (2.1) |
| Compose | nest `MaterialTheme(...)`; `CompositionLocalProvider(LocalContentColor provides …)` | `Dialog`/`Popup` create a new window — CompositionLocals do propagate in Compose (UNVERIFIED for every popup type); Views-based dialogs don't |
| Android Views | `ThemeOverlay` on a view / `ContextThemeWrapper` | a dialog built from the Activity context, not the wrapped one, loses it (UNVERIFIED — common bug class) |
| WinUI | `RequestedTheme` on an element; lightweight styling per subtree | flyouts/popups live in a separate visual tree root (UNVERIFIED) |
| libadwaita | CSS on a widget class/name | stylesheet is app-wide CSS; no typed scope |
| Web | variables re-declared on a subtree; `color-scheme: dark` on an element flips `light-dark()` inside; `@scope` | **portals to `body`** escape (Radix, Headless UI above) |
| Radix Themes | nested `<Theme appearance="dark">` | custom portals need their own `<Theme>` |

**Lesson**: subtree theming fails at the **overlay boundary** in every
system, because overlays are re-parented to a root (DOM body, a new
window, an OS-owned sheet). The fix is structural: an overlay's theme is
the theme **at its trigger**, captured when it opens — not the theme at
its DOM/window parent. A compiler that knows the component tree can
pass that by construction.

---

## 7. State-dependent styling

| Approach | Example | Composes? |
|---|---|---|
| CSS pseudo-classes | `:hover`, `:active`, `:focus-visible`, `:disabled`, `[aria-invalid]` | yes, but specificity combinatorics; `:focus-visible` vs `:focus` is a classic trap |
| Material state layers | overlay of the content colour at a fixed opacity per state (hover/focus/press/drag); "only one state layer is applied at a time" ([M2 states](https://m2.material.io/go/design-states)) | yes — one rule covers all colours; exact M3 opacities UNVERIFIED (sources disagree 10% vs 12%) |
| Function of state | SwiftUI `ButtonStyle.makeBody(configuration:)` reads `configuration.isPressed` ([ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle)); Compose `interactionSource.collectIsPressedAsState()` + `Indication` ([Medium, Android Devs](https://medium.com/androiddevelopers/illuminating-interactions-visual-state-in-jetpack-compose-188fa041b791)) | yes and typed; but every style re-implements every state |
| Variant classes | Tailwind `hover:bg-x focus-visible:ring disabled:opacity-50`, cva | readable per site; no guarantee all states covered |
| Native controls | the OS draws states | free and correct — if you accept the OS's states |

**Failure modes**: forgetting a state (disabled+hover, selected+pressed);
state colours computed by hand per brand colour; focus rings removed for
looks (`outline: none`) — WCAG 2.2 added 2.4.11 Focus Not Obscured (AA)
and 2.4.13 Focus Appearance (AAA)
([WCAG 2.2](https://www.w3.org/TR/WCAG22/)).

**What composes**: state as a **derived transform of a role**
(Material's overlay; Radix's step+1 for hover, step+2 for pressed —
[Radix scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale))
rather than a new token per state. Compose's Styles rework (2.2) is
Google conceding the per-parameter model doesn't scale.

---

## 8. Variants and sizes

- **Boolean prop explosion**: `<Button primary small outline danger>`
  — impossible combos representable. Remedy everywhere is enums:
  `intent: primary|secondary`, `size: sm|md|lg`.
- **cva**: `variants`, `compoundVariants` ("apply when multiple other
  variant conditions are met"), `defaultVariants`
  ([cva docs](https://cva.style/docs/getting-started/variants)). It is
  the de facto web answer, and it is a typed `match` over a product of
  enums dressed as an object literal.
- **Native**: SwiftUI `.buttonStyle(.borderedProminent)`,
  `.controlSize(.large)`, `.buttonBorderShape(.capsule)` — orthogonal
  modifiers, each a closed enum; Material: separate components per
  emphasis (Filled/Tonal/Outlined/Text/Elevated button) — five
  components, not a prop.
- **Density**: Material density scale (0, -1, -2…; UNVERIFIED current
  M3 status); macOS `controlSize`; Fluent `size`. macOS Tahoe changed
  what "regular" means (2.1), so density must be a ROLE the platform
  resolves, never a pixel delta.

**Lesson**: variants are closed enums per component; compound rules are
a `match` on the tuple; the compiler checks exhaustiveness. Never
booleans for mutually exclusive looks.

---

## 9. Colour

- **Seeded palettes**: Material Color Utilities / HCT — tone is L*, and
  "a difference of 40 in HCT tone guarantees a contrast ratio >= 3.0,
  and a difference of 50 guarantees >= 4.5" (code comment in the HCT
  source; [MCU](https://github.com/material-foundation/material-color-utilities/),
  [science of colour](https://material.io/blog/science-of-color-design)).
  That is the cleanest known way to make contrast **provable by
  construction** from tone pairs. OKLCH is the web's equivalent
  perceptual space (shadcn and Tailwind v4 default to it).
- **Radix 12 steps**: 1-2 backgrounds, 3-5 component bg (normal/hover/
  pressed), 6-8 borders, 9-10 solid (+hover), 11-12 text; steps 11/12
  "guaranteed" APCA Lc 60 / Lc 90 on step 2
  ([Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)).
  A scale whose STEPS are roles — and the guarantee is per-scale.
- **WCAG 2 vs APCA**: APCA was dropped from the WCAG 3 draft in 2023;
  "The contrast algorithm used in WCAG 3 is yet to be determined";
  WCAG 3 perhaps 2030; build to WCAG 2.x
  ([Roselli](https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html)).
  Radix's guarantee is APCA, Material's is WCAG ratio — they cannot both
  be the legal bar.
- **Dark mode derivation**: Material derives dark from the same tonal
  palettes (different tones per role); Apple requires both appearances
  even for single-appearance apps (Liquid Glass adaptivity).
  Inverting lightness naively fails for brand colours (UNVERIFIED as a
  cited claim — widely reported).
- **Dynamic/system accent**: Android wallpaper colour, macOS user accent
  (overrides the app's unless "multicolor"), GNOME 9 presets, Windows
  accent. Each OS decides whether the USER or the APP wins; macOS and
  GNOME say the user.
- **Wide gamut**: P3 via asset catalogs / `color(display-p3 …)` /
  `oklch()`; no evidence surfaced of contrast tooling handling gamut
  mapping — UNVERIFIED gap.
- **High contrast**: iOS Increase Contrast variants in asset catalogs;
  RN `highContrastLight/Dark`; Windows HC themes replace all colours;
  web `forced-colors`. Four different models of "more contrast".

**Who proves contrast at build time today?** Material Theme Builder and
MCU's DynamicScheme (by construction, for its own roles); Radix (by
construction, per scale); Style Dictionary/Terrazzo have lint plugins
but I found no stock contrast rule — UNVERIFIED. Nobody proves contrast
for **the pairs a component actually uses**.

---

## 10. Typography

- Platform text styles: Apple's 11 Dynamic Type styles (scale with user
  size, Bold Text); Material's 15-role type scale; GNOME's
  `--document-font-*`/`--monospace-font-*` and style classes
  (`.title-1`…); web: no semantic system styles except `system-ui`
  font family.
- **Custom fonts must still scale**: tie to a text style
  (`relativeTo: .body`, `UIFontMetrics`); a fixed-size custom font
  silently opts out of Dynamic Type
  ([useyourloaf](https://useyourloaf.com/blog/restricting-dynamic-type-sizes/)).
- **Layouts break at large sizes** (2.1, 2.2); Android non-linear
  scaling breaks sp arithmetic. Lesson: a type role must carry
  "scales with user preference" as a property, and layout code must be
  tested at max size — a compiler can't prove layout fits, but it can
  refuse a FIXED-HEIGHT container around scalable text (UNVERIFIED
  feasibility; idea, not prior art).
- HIG minimums: iOS default 17 pt / min 11 pt; macOS 13 / 10
  ([HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)).
- Line-height/tracking vary per size in SF (optical sizes; tracking
  tables) — the platform does it when you use system styles; a custom
  scale must carry per-size leading and tracking. Variable fonts
  (`opsz`, `wght`) make this data, not separate files.

---

## 11. Spacing, radius, elevation, shape

- Touch targets: iOS 44x44 pt default (28 min), macOS 28x28 (20 min)
  ([HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility));
  Material 48x48 dp (UNVERIFIED this session; long-standing guidance);
  WCAG 2.2 2.5.8 Target Size (Minimum) 24x24 CSS px, AA
  ([WCAG 2.2](https://www.w3.org/TR/WCAG22/)).
- Control heights differ per platform AND per OS release (Tahoe).
- Radius: Liquid Glass uses concentric/capsule shapes tied to device
  corners; M3 Expressive adds morphing shapes; libadwaita
  `--window-radius` is a helper "not meant to be overridden". Radius on
  a native control is NOT portable (Qt/wx cliffs; RN Button has none).
- Elevation: Material moved from shadows to tonal surface levels;
  Apple uses materials/glass layers; Windows Mica/Acrylic; web uses
  shadows (killed by `forced-colors`). Portable concept = **surface
  level** (base, raised, overlay), never a shadow value.
- Spacing: Tailwind v4 has one `--spacing` base and multiplies
  ([Tailwind](https://tailwindcss.com/docs/theme)); platforms use
  layout margins / readable content guides (Apple), 4dp grid (Material).
  Portable: a small step scale; the platform default margins win where
  they exist.

---

## 12. Icons

- **SF Symbols**: licensed for UIs of software on Apple's platforms
  only; Apple staff decline to interpret per case; no use in logos/app
  icons ([forum 739523](https://developer.apple.com/forums/thread/739523),
  [757407](https://developer.apple.com/forums/thread/757407)). So a
  cross-platform library **cannot ship SF Symbols on Android/web/
  Windows/Linux**.
- **Material Symbols**: Apache 2.0, variable font with fill/weight/
  grade/optical-size axes, three styles
  ([Google guide](https://developers.google.com/fonts/docs/material_symbols)).
- GNOME: symbolic icons recolour with text colour; icon themes were a
  stopthemingmy.app grievance (metaphors changed).
- Fluent System Icons (MIT — UNVERIFIED this session).
- **Lesson**: an icon is a **semantic name** (`share`, `delete`,
  `settings`) mapped per target to SF Symbol / Material Symbol / Fluent
  / Adwaita symbolic. Share icon differs per platform (iOS box-arrow vs
  Android three-node) — noted even in the CMP forum thread. A custom
  icon set is an explicit brand choice, and the compiler can check every
  semantic name has a mapping on every target.

---

## 13. Designer -> developer flow

- Figma Variables (collections x modes) -> tokens. Figma announced
  native DTCG export/import at Schema 2025; a December 2025 forum thread
  says the help-page note was removed and users still waited; export
  reportedly omitted `description`
  ([Figma forum](https://forum.figma.com/ask-the-community-7/native-variable-export-feature-47831)).
  The Variables REST API is Enterprise-only (same thread / secondary).
  Booleans and strings have no DTCG type
  ([atomize](https://atomize.tools/blog/figma-variables-export-json/), secondary).
- Tools: Tokens Studio (plugin), Style Dictionary v4/v5 (DTCG `$value`/
  `$type`; v5 aligned to 2025.10; cannot mix legacy and DTCG in one
  instance), Terrazzo/Cobalt
  ([zeroheight](https://help.zeroheight.com/hc/en-us/articles/48049028236187),
  [Terrazzo](https://terrazzo.app/docs/reference/tokens/)).
- **Where it breaks**: (1) modes don't map 1:1 — Figma modes are one
  axis per collection while code has several orthogonal axes; DTCG
  needed a whole Resolver module; (2) composite types (typography,
  shadow) are the last to stabilise and the first to be lossy;
  (3) names drift — Zeroheight warns generated variable names can
  shift on the v5 move; (4) the pipeline is ONE-WAY and nobody checks
  the code still uses what design shipped (unused/missing tokens).

**Lesson**: Avra's theme is the source of truth as typed data; DTCG is
an import/export PROJECTION (P12), not the authoring format.

---

## 14. Accessibility as part of theming

| Need | Apple | Android | Windows | GNOME | Web |
|---|---|---|---|---|---|
| Contrast boost | Increase Contrast; asset HC variants | Material contrast levels (UNVERIFIED API name) | High Contrast themes replace colours | high-contrast style (UNVERIFIED) | `prefers-contrast`, `forced-colors` |
| Text scaling | Dynamic Type, Bold Text | font scale to 200%, non-linear | text scaling | text scaling factor | browser zoom, `rem` |
| Motion | Reduce Motion | remove animations | animation effects off | reduced motion setting (UNVERIFIED) | `prefers-reduced-motion` |
| Transparency | Reduce Transparency (Liquid Glass adapts) | n/a | transparency off -> Mica solid fallback | n/a | `prefers-reduced-transparency` (no Safari) |
| Focus | system focus ring | focus indication | focus visuals | focus ring | `:focus-visible`, WCAG 2.4.11/13 |

Every OS exposes these as **inputs**; native controls honour them for
free. Custom-drawn controls must re-read every one — the hidden cost of
the cliff.

---

## SYNTHESIS

### A. The portable core, the platform-specific, and the cliff

Legend: **N** honoured natively by the platform's own controls with no
custom drawing; **P** partially (some controls, or only via the
platform's own style enum); **X** not honoured — requires a
custom-drawn control or is ignored; **—** concept absent.

| Theme property | iOS UIKit/SwiftUI | Android Views/Compose (M3) | Web (own default) | macOS AppKit | Windows WinUI | GTK/libadwaita |
|---|---|---|---|---|---|---|
| Appearance light/dark | N | N | N (`color-scheme`, `light-dark`) | N | N | N |
| Accent / tint colour | N (tint; glass bars may ignore — forum) | N (`primary`; dynamic colour may replace) | N (`accent-color`, own roles) | P (user accent overrides unless multicolor) | N (accent resources) | N (`--accent-bg-color`; user accent default) |
| Semantic text roles (primary/secondary/disabled) | N (`label`…) | N (`onSurface`/`onSurfaceVariant`) | N (own roles) | N (`labelColor`…) | N (`TextFillColorPrimary`… UNVERIFIED names) | N (`--window-fg-color`, `.dim-label`) |
| Background levels / surfaces | N (system backgrounds, grouped) | N (surface containers) | N | N (window/control backgrounds) | N (Mica/solid fill levels) | N (window/view/card) |
| Status roles (destructive/success/warning) | P (destructive role on buttons; colours are system palette) | P (error only; success/warning are app colours) | N | P | P | N (destructive/success/warning/error) |
| Text roles + user scaling | N (Dynamic Type styles) | N (type scale + sp) | P (`rem` + zoom; no system styles) | P (text styles; no Dynamic Type on macOS) | P | N (font settings; classes) |
| Custom font family | P (must map to text style to scale) | N | N | P | P | P (app CSS) |
| Contrast level | N (Increase Contrast) | P (contrast levels in scheme) | N (`prefers-contrast`, `forced-colors`) | N | N (HC themes) | P |
| Density / control size | P (`controlSize` on some controls) | P (density on some components) | N (own) | N (`controlSize`; metrics changed in 26) | P | X |
| Spacing step scale | N (layout only, ours) | N | N | N | N | N |
| Corner radius on controls | P (`buttonBorderShape` enum only) | N (shape scale) | N | X (bezel styles only) | P (CornerRadius resources) | X (helper "not meant to be overridden") |
| Fill colour of a standard button | P (`.borderedProminent` + tint) | N | N | P (bezelColor, limited) | P (lightweight styling) | P (style classes) |
| Bar / chrome background | X on iOS 26 glass (discouraged, ignored per forums) | N | N | X (glass toolbars) | P (title bar customisation APIs) | P (`--headerbar-bg-color`) |
| Elevation / surface level | P (materials, glass — system decides) | N (tonal) | N | P | N (Mica/Acrylic, solid fallback) | P (`.card`, shade colours) |
| Shadows | X | P | N (but `forced-colors` kills) | X | X | X |
| Icons by semantic name | N (SF Symbols) | N (Material Symbols) | N (licensed set) | N (SF Symbols) | N (Segoe Fluent Icons) | N (symbolic) |
| Motion curves / durations | P (system animations) | N (`MotionScheme`) | N | P | P | X |
| Overlay/sheet styling | X (system sheets/alerts) | N (app-drawn dialogs) | N | X (alerts/panels) | P | P |

**The cliff, exactly**: a customisation crosses the cliff when it asks a
native control for something outside the platform's own **enum of
styles** — an arbitrary radius, an arbitrary bar background, a shadow,
a gradient fill, a custom pressed-state colour on iOS/macOS controls.
Within the enum (tint, prominence, control size, border shape enum,
role colours) everything is native. So: **portable theme = roles +
accent + appearance + contrast + type roles with scaling + spacing
steps + density enum + semantic icons + surface levels.** Geometry and
effects on platform controls are platform-specific, and asking for them
must be an explicit `drawn` choice that the compiler reports per target
(P7: visible magic).

### B. One record or layered?

Layered, with orthogonal axes:
- **DTCG** split modes into a separate Resolver module (§1).
- **Figma** has modes per collection; **Material** composes a scheme from
  seed x variant x contrast level x appearance; **Apple** resolves
  colour by (appearance x contrast x elevation level x vibrancy);
  **web** composes `color-scheme` x `prefers-contrast` x
  `forced-colors` x `prefers-reduced-motion`; **Windows** has Light/
  Dark/HighContrast dictionaries.
- Successful systems make each axis a **function input**, not a
  pre-multiplied record: Material's `dynamicColorScheme(seed, isDark,
  contrastLevel)`; Apple's dynamic colour provider closures; CSS's
  `light-dark()`.

Recommendation: `Theme = { palette, roles(appearance, contrast),
type, space, shape, density, icons }` where roles is a typed function of
the axes the OS supplies; brand is a palette + optional overrides of
named roles; the compiler instantiates the product at build time for
the web (static CSS per mode) and defers to OS dynamic colours natively.

### C. Smallest role vocabulary

| System | Colour roles |
|---|---|
| Material 3 (Compose) | 48 properties (counted) |
| Apple (UIKit) | labels x4, backgrounds x3 + grouped x3, fills x4, separators x2, placeholder, link, plus system palette colours (~18 semantic) — UNVERIFIED exact count |
| libadwaita | ~20 bg/fg families (accent, destructive, success, warning, error, window, view, headerbar, sidebar x2, card, dialog, popover, overview, active toggle) |
| Radix | 12 steps per scale, used as roles; any number of scales |
| shadcn | ~19 pairs (background, foreground, card, popover, primary, secondary, muted, accent, destructive, border, input, ring, chart-1..5, sidebar-*) — UNVERIFIED exact list |

Proposed minimal vocabulary (derived, not prior art):
- **Colour (pairs, bg + on)**: `canvas`, `surface` (with levels
  base/raised/overlay), `accent`, `neutral` (secondary action), and
  status `danger`, `success`, `warning`; text roles `text`, `muted`,
  `faint/disabled`; lines `border`, `separator`; `focus`; `link`.
  ~14 roles, each mapping cleanly to Apple semantic colours, M3 roles
  and libadwaita variables. Material's container/fixed/tertiary/inverse
  stay Android-specific extensions.
- **Type**: `display`, `title` (1-3), `headline`, `body`, `callout`,
  `caption`, `label`, `mono` — maps onto Apple's 11 and Material's 15.
- **Space**: 6-7 steps (`xs`…`xxl`) on one base; platform margins win.
- **Radius**: `none, small, medium, large, full` — honoured only where
  the shape is ours (see A).
- **Elevation**: surface levels (`base`, `raised`, `overlay`), never
  shadow values.

### D. State and variants

- States are a **closed enum** the component library defines (`hover`,
  `pressed`, `focused`, `disabled`, `selected`, `invalid`, `busy`),
  read by a style as a `match` — the SwiftUI/Compose "function of
  state" shape, typed and exhaustive.
- Colour per state is a **derived transform of a role** (state layer /
  scale step), so a brand changes one colour and every state follows;
  a per-state override is a named exception.
- Variants are **enums per component** (`kind`, `size`), compound rules
  are a `match` over the tuple with exhaustiveness checked — cva's
  `compoundVariants` with a compiler.
- Native controls: states belong to the OS; the theme says nothing.
- The foundation does not own the property vocabulary (Compose Styles
  regret, §2.2); each component declares the typed properties it
  accepts.

### E. What to prove at build time

| Proof | Today, who |
|---|---|
| Every `on-X` on `X` meets WCAG 2.x (4.5/3.0) in every mode x contrast level | MCU/Material by construction (tone delta); Radix per scale (APCA); nobody for custom overrides |
| Every role a component uses exists in every theme layer and target | TypeScript types in some libs (Tamagui, Fluent's typed tokens) — partial |
| Every semantic icon has a mapping on each target, licence-legal (no SF Symbols off Apple) | nobody |
| A theme property a target cannot honour natively is reported (the cliff) | nobody — Qt, wx, NativeScript, RN all ignore silently |
| Unused roles/tokens | Tailwind v4 drops unused at build ([theme docs](https://tailwindcss.com/docs/theme)); nobody warns |
| Focus indicator present and visible on every interactive component | nobody at build; axe at runtime (UNVERIFIED) |
| Scalable text not inside a fixed-height box | nobody |

### F. The ten lessons, ranked

1. **Native means the OS repaints you; design for it** — Liquid Glass ignored bar/tint overrides and the opt-out expires with iOS 27 ([forum 788176](https://developer.apple.com/forums/thread/788176), [832543](https://developer.apple.com/forums/thread/832543)).
2. **Self-drawn looks lag every redesign** — Flutter: no Liquid Glass, contributions refused, design libs frozen ([#170310](https://github.com/flutter/flutter/issues/170310), [decoupling](https://flutter.dev/blog/decoupling-material-cupertino)).
3. **The portable line is recolour, not restyle** — libadwaita's named colours and stopthemingmy.app; Apple's "avoid redefining semantic colors" ([libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html), [HIG](https://developer.apple.com/design/human-interface-guidelines/color)).
4. **The cliff must speak** — Qt sheets, wx colours, NativeScript CSS and RN's `color` all fail silently ([Qt](https://doc.qt.io/qt-6/stylesheet.html), [wx](https://git.amebis.si/Amebis/wxWidgets/commit/540fed921647308e952ec56d4624d2ebd09ea07a), [RN Button](https://reactnative.dev/docs/button)).
5. **Roles come in bg/on pairs, so contrast is provable** — Material `on*`, libadwaita `-fg`, shadcn `-foreground`; HCT tone delta 50 => 4.5:1 ([MCU](https://github.com/material-foundation/material-color-utilities/)).
6. **The foundation must not own the style vocabulary** — Compose Styles was pulled back to let design systems define properties ([Compose styles](https://developer.android.com/develop/ui/compose/styles/state-animations)).
7. **Theme at build time, modes in the platform** — runtime CSS-in-JS lost on cost; `light-dark()`/`prefers-*` do modes for free ([Magura](https://dev.to/srmagura/why-were-breaking-up-wiht-css-in-js-4g9b), [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark)).
8. **Modes are orthogonal axes, not records** — DTCG needed a separate Resolver module ([Resolver 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-resolver-20251028/)).
9. **Never pin native metrics; they move** — macOS Tahoe resized controls; Android 14 made font scaling non-linear ([forum 791190](https://developer.apple.com/forums/thread/791190), [Flutter note](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration)).
10. **Overlays must carry the trigger's theme** — portals lose it in Radix/Headless UI ([Radix](https://radix-ui.com/themes/docs/overview/styling)); and brand vs user accent needs an explicit rule (Android harmonization, macOS user accent wins) ([Android](https://developer.android.com/develop/ui/views/theming/dynamic-colors)).

---

## Open questions this study could not close

- Exact M3 state-layer opacities in current Compose defaults (sources
  disagree; read `RippleDefaults` source).
- Whether Material's legacy roles (`surfaceVariant`, `background`) are
  formally deprecated — m3.material.io would not render.
- Exact Apple semantic-colour count per platform and whether SwiftUI
  `.environment(\.colorScheme)` reaches presented sheets in iOS 26.
- Figma's shipped (not announced) DTCG export behaviour in late 2026.
- Whether any token tool ships a stock contrast-pair lint.
