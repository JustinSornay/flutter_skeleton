# Flutter Skeleton

Squelette d'application Flutter reprenant l'architecture de l'app **Bhumist** :
widgets MVVM découpés en `part` / `part of`, couche API typée (`Http` → DTO →
service), providers `ChangeNotifier`, `go_router` avec `ShellRoute`, i18n
`easy_localization`, générateurs de code et gate qualité branchée sur Claude Code.

Une petite fonctionnalité de démonstration (liste de tâches paginée + détail
éditable, servie par [JSONPlaceholder](https://jsonplaceholder.typicode.com))
traverse toutes les couches pour montrer comment elles s'assemblent.

## Prérequis

- Flutter **3.41.7** (Dart 3.11) — même version que Bhumist.

## Démarrage

```bash
flutter pub get
flutter run -d chrome        # ou linux / windows / macos / un appareil mobile
```

L'app lit `.env.local` au démarrage. Par défaut il pointe vers JSONPlaceholder,
la démo fonctionne donc sans backend.

> ⚠️ `.env.local` est embarqué dans l'application comme asset : n'y mettez
> **jamais** de secret.

## Ce qui est inclus

| Domaine | Contenu |
|---|---|
| **API** (`lib/api/`) | `Http` (5 points d'entrée : `output`, `listOutput`, `input`, `request`, `listen`), `HttpOutput` (accès typé strict), `ApiException`, hooks d'auth (token Bearer, refresh + retry sur 401, callback de déconnexion), `ApiFilterBuilder`, interfaces DTO, contrôleurs (`api/controllers/` : toasts, redirections, modale de confirmation autour des appels de service) |
| **State** (`lib/providers/`) | `ErrorProvider` (toasts globaux), `ConnectivityProvider` (hors ligne), `ModalProvider` (modales globales), `BaseAsyncProvider`, helpers `renderConsumer` / `renderSelector` |
| **Routing** (`lib/routing/`) | `GoRouter` + `ShellRoute` (header + modales), page 404, transitions courtes désactivées en « réduire les animations », gabarits de page `FullPageTemplate` (un panneau), `SplittedPageTemplate` (deux panneaux côte à côte, empilés sur écran étroit) et `FollowUpPageTemplate` (page de suite d'action : retour, contenu défilant, actions épinglées en bas) |
| **Widgets** (`lib/widgets/`) | Layout (`AppHeader` responsive, `OfflineBanner`, `ErrorToastCard`, `AppModal`, `ModalConsumer`, `PageTitleBar`), `Listing<T>` (pagination lazy, états vide / erreur / retry), `Loader`, `SkeletonPulse`, et 89 widgets génériques dans `custom/` (feuilles, saisie et sélection, badges, barres, graphiques `fl_chart`, cartes `flutter_map`, états vides / verrouillés…) : catalogue dans [`lib/widgets/custom/README.md`](lib/widgets/custom/README.md) |
| **Thème** (`lib/theme/`) | Material 3 clair + sombre depuis une couleur de marque, tokens `ColorScheme` uniquement, extension `StatusTones` (tons de statut contrastés ≥ 4.5:1 en clair et en sombre) |
| **i18n** | Français (référence) + anglais, test de parité des clés |
| **Outillage** | Générateurs de widgets et de services (`cli/`), lints stricts + `solid_lints`, gate qualité (`tooling/hooks/test-gate.sh`) branchée sur le hook `Stop` de Claude Code |
| **Tests** | 3 096 tests unitaires et widgets (Http sans réseau via `MockClient`, Listing, layout, démo, routeur avec vraies traductions, un fichier de test par widget de `custom/`, contraste des tons de statut) |

## Architecture

```
lib/
  api/          dtos/ · http/ · services/
  data/         configuration statique (navigation, locales)
  providers/    ChangeNotifier globaux
  routing/      pages/ · router/ · templates/
  theme/        AppTheme
  utils/        Env, LoadState, ActionState, requireAuth, Coords, géo, parsers, extensions, builders
  widgets/      core/render · core/decorators · custom · layout
  main.dart
```

Toutes les conventions (pattern MVVM, règles DTO / services, navigation
`context.go()` uniquement, accessibilité, animations…) sont décrites dans
[`CLAUDE.md`](CLAUDE.md), et chaque dossier clé a son propre `README.md`.

## Générateurs

```bash
# Widget MVVM (stateful : index + view_model + view)
dart cli/generation/widget/index.dart --className MyWidget --path core/render

# Widget stateless (index + view)
dart cli/generation/widget/index.dart --className MyBadge --path custom --stateless

# Service + 4 DTOs (detail/list output, post/put input)
dart cli/generation/service/index.dart --className MyEntity --route my-entities
```

Voir [`cli/README.md`](cli/README.md).

## Tests et qualité

```bash
flutter analyze
dart run custom_lint
flutter test
bash tooling/hooks/test-gate.sh --force   # les trois d'un coup
```

Avec Claude Code, la gate tourne automatiquement à la fin de chaque tour
(hook `Stop` dans `.claude/settings.json`) et bloque tant qu'elle est rouge.

## Partir de ce squelette

### 1. Renommer le projet

```bash
NEW=my_app
ORG=com.acme

# Nom du package Dart (imports, templates des générateurs, docs)
grep -rl "flutter_skeleton" --include=*.dart --include=*.yaml --include=*.jinja --include=*.md \
  lib test cli pubspec.yaml CLAUDE.md | xargs sed -i "s/flutter_skeleton/$NEW/g"

# Identifiants natifs (applicationId, bundle id…) : on régénère les dossiers plateformes
rm -rf android ios linux macos web windows
flutter create --org "$ORG" --project-name "$NEW" --platforms android,ios,web,linux,macos,windows .
rm test/widget_test.dart   # créé par flutter create, inutile ici
```

Puis adaptez `app.title` dans `assets/translations/*.json`.

### 2. Retirer la démo

Supprimez `lib/api/dtos/todo/`, `lib/api/services/todo_service.dart`,
`lib/widgets/core/render/TodoList/`, `lib/widgets/core/render/TodoDetail/`,
`lib/routing/pages/todo_page.dart`, les tests associés
(`test/unit/dtos/todo_dto_test.dart`, `test/widget/core/todo_*_test.dart`),
la route `todos/:id` et le contenu de `HomePage`, ainsi que les clés
`todos.*` / `todo.*` des traductions. Pointez ensuite `API_API_URL` vers votre backend.

## Volontairement non repris de Bhumist

Ces briques dépendent d'un choix de produit ou d'infrastructure : elles sont à
ajouter selon le projet.

- Authentification (Firebase Auth, 2FA) — `Http` expose déjà les hooks de token.
- Observabilité / analytics (Sentry, PostHog), notifications push (FCM).
- Caches locaux (Hive, cache de tuiles de carte), export PDF / CSV.
- Golden tests et leur image Docker, Widgetbook, tests d'intégration ChromeDriver, MCP Flutter Driver.
