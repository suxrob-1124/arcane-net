# CLAUDE.md

## Project Overview
Arcane Net — изометрическая action-RPG.
- **Engine**: Godot 4.6 (Forward Plus, .NET-сборка)
- **Language**: GDScript (typed) — основной; C# доступен через mono-сборку
- **Main scene**: `res://scenes/main/Main.tscn`
- **Tests**: GUT (`addons/gut/`) — устанавливается через AssetLib, не коммитится в репозиторий
- **GDD**: `Technical_GDD_v1.1.docx` (источник истины по структуре каталогов и системам)

## Commands
```bash
# IMPORTANT: проект использует .NET-сборку Godot — путь зашит в команды ниже
GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"

# Запуск проекта (главная сцена)
"$GODOT" --path /Users/sukhrobshukurov/Dev/godot-test-game

# Запуск конкретной сцены
"$GODOT" --path . scenes/main/Main.tscn

# Переимпорт ресурсов — ОБЯЗАТЕЛЬНО после добавления .gd с class_name,
# иначе тесты упадут "Could not find type"
"$GODOT" --path . --headless --import

# Все GUT-тесты
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/

# Один тестовый файл
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_spawner_logic.gd
```

## Architecture

### AutoLoad-синглтоны (порядок загрузки важен)
| Singleton | Path | Role |
|---|---|---|
| `GameState` | `scripts/core/GameState.gd` | Режим игры (`HUB / DUNGEON / SPECTATOR`), ссылка на текущую сцену |
| `EventBus` | `scripts/core/EventBus.gd` | Глобальные сигналы между несвязанными системами |
| `SpectatorState` | `scripts/spectator/SpectatorState.gd` | Счётчик живых зрителей-людей, `echo_should_be_active()` |
| `InputManager` | `scripts/core/InputManager.gd` | Платформо-зависимая обработка ввода |

`InputManager` грузится последним — в `_ready()` читает `GameState.current_mode`.

### Directory Map (по GDD 2.1)
| Path | Purpose |
|---|---|
| `scripts/core/` | AutoLoad-синглтоны (`GameState`, `EventBus`, `InputManager`) |
| `scripts/combat/` | `Player`, `MovementComponent`, `DashComponent`, `IsoCamera` |
| `scripts/progression/` | Уровни, прокачка, статы |
| `scripts/dungeon_gen/` | Процедурная генерация подземелий |
| `scripts/spectator/` | Режим зрителя; `SpectatorState` (AutoLoad), `EchoCompanion` |
| `scripts/spectator/actions/` | Priority-действия Эха: `SpectatorAction` (base), `HealAction`, stubs |
| `scripts/network/` | Мультиплеер |
| `scripts/ui/` | UI-логика |
| `scripts/data/` | Data-классы и парсинг ресурсов |
| `scenes/main/` | Стартовая сцена |
| `scenes/{hub,dungeon,ui}/` | Сцены по режимам |
| `resources/{skills,enemies,rooms}/` | Resource-файлы |
| `tests/` | GUT-тесты |

IMPORTANT: папки `shaders/`, `entities/`, `systems/` **не создавать** — их нет в GDD 2.1.

### IsoCamera (`scripts/combat/IsoCamera.gd`)
- `Camera3D`, ортографический режим, `size = 10`.
- **Following**: `global_position.lerp(desired, 1.0 - pow(smoothing, delta))` — frame-rate independent. `smoothing` = «доля оставшегося отставания за секунду», диапазон `0.001..0.01`.
- **Orientation**: задаётся через `look_at(target.global_position)` в `_ready()`, не через `rotation_degrees` — гарантирует точный взгляд при любом `offset`.
- **Screen shake**: `h_offset` / `v_offset` с линейным затуханием. Повторный `shake()` берёт `max` по интенсивности — новые удары не поглощаются затухающими.
- В `Main.tscn`: `current = true`, `target_path = NodePath("../Player")`.

### Player & Movement (`scripts/combat/`)
`Player.gd` — `CharacterBody3D`-фасад: только флаги `is_invulnerable`, `is_dashing` и `@onready` ссылки на `Visuals`, `MovementComponent`, `DashComponent`. Вся логика — в компонентах.

**MovementComponent**:
- Ввод: `Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")` в `_physics_process`.
- **Изометрический поворот ввода**: `+45°` по оси Y (`Basis(Vector3.UP, deg_to_rad(45.0))`). Знак привязан к `IsoCamera.offset = (8, 12, 8)` — при изменении offset пересчитать.
- `velocity.move_toward(target, rate * delta)`: `acceleration = 20.0`, `deceleration = 30.0`.
- Snap-поворот `Visuals.look_at(...)` — мгновенный, только при наличии ввода и `not is_dashing`.
- Public API для DashComponent: `get_input_iso_direction()`, `set_movement_enabled(enabled)`.

**DashComponent**:
- `DASH_SPEED = 20.0` (4.0 м / 0.2 с).
- Три `Timer` (one_shot): `DurationTimer` (0.2c), `CooldownTimer` (1.5c), `IframesTimer` (0.25c).
- Во время рывка: `Player.is_invulnerable = true`, `is_dashing = true`, `MovementComponent` выключается, dash сам зовёт `move_and_slide()`.
- Сигналы: `dash_started(direction: Vector3)`, `dash_ended()` — точки расширения для VFX/SFX/Health.
- Направление: текущий ввод, иначе `-Visuals.basis.z` (forward).

## Code Standards — you MUST follow these
- **Typed GDScript** везде: типизировать все переменные, параметры, возвраты.
- **Typed signals**: каждый аргумент сигнала — с явным типом.
- **StringName (`&"..."`)**: для имён нод и input-actions (`Input.is_action_pressed`, `push_warning`, `NodePath` literals).
- **Composition over inheritance**: каждый компонент решает одну задачу, `Player` — фасад.
- **AutoLoad — single responsibility**: новый AutoLoad только если функция глобальна и не привязывается к узлу.
- **Game Feel НЕ тестируется юнит-тестами** — только плейтестом (IsoCamera, shake, smoothing, dash).
- **Magic numbers** — в константы (`const DASH_SPEED := 20.0`), не в литералы по коду.

## Testing Rules
- Тесты — `extends GutTest`, лежат в `tests/`.
- После добавления нового `class_name` СНАЧАЛА `--headless --import`, затем тесты.
- Юнит-тесты покрывают логику (movement vector math, dash cooldown, dungeon gen, spawner). Не покрывают визуал, тайминги, плавность.

## AI Rules
- IMPORTANT: при нарушении архитектуры (например, бизнес-логика в `Player.gd` вместо компонента, или прямая связь `MovementComponent` → `DashComponent` без сигналов) — предупреждать сразу.
- Не выводи фазу разработки из этого файла — смотри `git log` и текущее состояние кода.
- Не создавай папки вне списка из GDD 2.1.
- `.gitkeep`: оставлять в пустых папках до появления кода; удалять сразу при первом коммите туда.
- Не коммить `.godot/` (импорт-кэш), `.import/`, `.mono/`, `.DS_Store`, бинарники сборки.
- Для интерактивного входа (`gh auth login` и т.п.) — попроси пользователя запустить `! <command>` в промпте.

<when_committing>
IMPORTANT: Conventional Commits — `<type>(<scope>): <subject>`
- Types: `feat` | `fix` | `refactor` | `perf` | `test` | `docs` | `chore` | `style`
- Scopes: `core` | `combat` | `camera` | `dungeon` | `ui` | `network` | `progression` | `tests` | `assets`
- Subject ≤ 72 символов, императив, без точки в конце
- Перед коммитом: `--headless --import` ✓ + `gut_cmdln.gd -gdir=res://tests/` ✓
- НИКОГДА `--no-verify`, не пропускай хуки. Чини корневую причину.
</when_committing>

<when_branching_or_opening_pr>
- Базовая ветка — `main`. Прямые коммиты в `main` запрещены.
- Naming: `feat/<slug>` | `fix/<slug>` | `refactor/<slug>` | `docs/<slug>` | `chore/<slug>` | `test/<slug>`
- GitHub Flow: ветка от `main` → коммиты → push → PR → squash merge → delete branch.
- PR-чеклист: импорт ресурсов проходит ✓, все GUT-тесты зелёные ✓, нет файлов из `.godot/`, `.DS_Store` в diff ✓.
- Remote: `origin` → GitHub repo `arcane-net` (public). Создаётся через `gh repo create`.
</when_branching_or_opening_pr>
