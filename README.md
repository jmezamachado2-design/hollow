# Hollow

Metroidvania 2D en **Godot 4** + **GDScript**, inspirado en Hollow Knight.  
Resolución lógica **320×180** escalada a **1280×720** (pixel art, filtro nearest).

## Requisitos

- [Godot 4.3+](https://godotengine.org/download)

## Cómo abrir

1. Clona o abre esta carpeta.
2. En Godot: **Import** → selecciona `project.godot` → **Import & Edit**.
3. Pulsa **F5** para ejecutar `Main.tscn`.

## Controles

| Acción | Teclas |
|--------|--------|
| Mover izquierda | ← (A = aguijón onírico, no movimiento) |
| Mover derecha | → o D |
| Mover arriba / abajo | ↑↓ o W/S |
| Saltar | Espacio |
| Atacar | C o clic izquierdo (dirección = movimiento activo) |
| Concentración (focus) | Mantener X o clic derecho |
| Dash | Z o Shift |
| Aguijón onírico | A |
| Inventario | Tab |
| Checkpoint | E |
| Pausa | Escape |

InputMap registrado en código: `scripts/autoload/InputHandler.gd`

## Estructura

```
hollow/
├── project.godot          # Config, autoloads, viewport, inputs
├── scenes/
│   ├── Main.tscn          # Escena de entrada (mundo de prueba)
│   ├── player/Player.tscn
│   ├── levels/            # Salas del metroidvania
│   ├── enemies/
│   └── ui/
├── scripts/
│   ├── autoload/GameManager.gd
│   ├── combat/HealthComponent.gd, Hitbox.gd, CameraShake.gd
│   ├── player/Player.gd
│   └── enemies/Enemy.gd, Crawler.gd, Soul.gd, states/*.gd
└── assets/
    ├── sprites/
    ├── tilesets/
    └── audio/
```

## Capas de física

| Capa | Nombre | Uso |
|------|--------|-----|
| 1 | player | Personaje |
| 2 | enemies | Enemigos |
| 3 | world | Suelo y plataformas |
| 4 | player_attack | Hitbox de ataque |

## Enemigos (FSM)

Estados: `Idle` → `Patrol` ↔ `Chase` → `Attack`; cualquier estado vivo → `Hurt` → …; muerte → `Dead` → suelta `Soul`.

Primer tipo: **Crawler** (`scenes/enemies/Crawler.tscn`) — patrulla entre marcadores `Patrol/Left` y `Patrol/Right`, detecta a 200px, ataca a 40px (CD 1.5s).

## Salas (metroidvania)

- `scenes/levels/Room.tscn` — base: TileMap, CameraLimit, EntryPoints, Transitions, Entities
- `Room_A` ↔ `Room_B` conectadas por bordes (fade vía GameManager)
- `Checkpoint.tscn` — **E** guarda sala, entrada y vida
- `Hazard.gd` — muerte instantánea → respawn en checkpoint
