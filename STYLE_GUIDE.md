# BoomBet — Guía de Estilo Visual

Sistema de diseño completo del proyecto. Sirve como referencia para replicar el look & feel en otro proyecto Flutter.

---

## 1. Paleta de Colores

### Primarios

| Nombre | Hex / Valor | Uso |
|--------|------------|-----|
| `primaryGreen` | `#29FF5E` | Acento principal, botones, íconos activos, glow |
| `darkBg` | `#121212` | Fondo de scaffold |
| `darkAccent` | `#1A1A1A` | Surface secundaria, borders en dark |
| `darkCardBg` | `#2A2A2A` | Cards generales |
| `textDark` | `#E0E0E0` | Texto principal en dark mode |

### Superficies internas

| Nombre | Hex | Uso |
|--------|-----|-----|
| AppBar / Navbar BG | `#080808` | Fondo de la barra superior e inferior |
| Field fill | `#141414` | Fondo de campos de texto y botones de nav |
| Field border | `#272727` | Borde default de inputs |
| Dialog BG | `#0E0E0E` / `#1A1A1A` | Fondos de dialogs y pickers |

### Colores de estado

```dart
errorRed   = Colors.red
warningOrange = Colors.orange
successGreen  = Colors.green
```

> **Nota:** El proyecto es **solo dark mode**. Los colores light existen en las constantes pero no se usan actualmente.

---

## 2. Tipografía

### Font family

- **`ThaleahFat`** — fuente custom en `assets/fonts/ThaleahFat.ttf`. Se usa en títulos de juegos, texto hero y pantallas de bienvenida. Siempre con `fontWeight: FontWeight.w900` y `letterSpacing` amplio (ej: `4`).
- **Sistema (Roboto)** — para todo el resto de la app (body, labels, inputs).

### Escala de tamaños

| Token | Valor | Uso típico |
|-------|-------|------------|
| `headingLarge` | `28.0` | Títulos de pantalla |
| `headingMedium` | `22.0` | Subtítulos principales |
| `headingSmall` | `18.0` | Encabezados de sección |
| `bodyLarge` | `16.0` | Texto prominente |
| `bodyMedium` | `14.0` | Texto general |
| `bodySmall` | `13.0` | Labels secundarios |
| `bodyExtraSmall` | `12.0` | Metadata, timestamps |
| `captionSize` | `11.0` | Captions, badges |

### Uso especial de ThaleahFat

```dart
// Títulos neon (pantalla de bienvenida, scores de juegos)
TextStyle(
  fontFamily: 'ThaleahFat',
  fontSize: 42,
  fontWeight: FontWeight.w900,
  color: Color(0xFF29FF5E),
  letterSpacing: 4,
)
```

---

## 3. Espaciado y Dimensiones

### Padding / Spacing

| Token | Valor |
|-------|-------|
| `paddingXSmall` | `4.0` |
| `paddingSmall` | `8.0` |
| `paddingMedium` | `12.0` |
| `paddingLarge` | `16.0` |
| `paddingXLarge` | `24.0` |
| `paddingXXLarge` | `32.0` |

### Dimensiones fijas

| Token | Valor | Uso |
|-------|-------|-----|
| `borderRadius` | `12.0` | Radio general de componentes |
| Botones | `14.0` | Radio ligeramente mayor |
| Dialogs | `16-18px` | Radio de diálogos y pickers |
| `appBarHeight` | `56.0` | Altura del AppBar |
| `buttonHeight` | `52-56px` | Altura de botones principales |
| Navbar height | `76.0` | Altura de la barra inferior |
| Nav icon buttons | `36×36 px` | Botones de ícono en AppBar |

### Íconos

| Token | Valor |
|-------|-------|
| `smallIconSize` | `18.0` |
| `mediumIconSize` | `24.0` |
| `largeIconSize` | `32.0` |
| `extraLargeIconSize` | `80.0` |

---

## 4. Efectos Visuales

### Glow / Neon (el efecto más identitario del diseño)

El verde neon se usa con transparencia para crear halos luminosos. Los valores de alpha más comunes:

| Alpha | Uso |
|-------|-----|
| `0.07` | Sombra de glow muy sutil (search bar) |
| `0.14` | Fill de botón seleccionado / campo activo |
| `0.16-0.18` | Glow de focus en inputs / borders de dialog |
| `0.20-0.22` | Borders de componentes interactivos |
| `0.25-0.50` | Líneas separadoras con gradiente neon |
| `0.38` | Shadow de botones primarios |
| `0.65` | Shadow del punto pulsante en section headers |

### Box Shadow — patrón estándar

```dart
// Sombra de botón primario
BoxShadow(
  color: primaryGreen.withValues(alpha: 0.38),
  blurRadius: 16,
  spreadRadius: 0,
  offset: Offset(0, 4),
)

// Sombra de elemento seleccionado (ej: gender selector)
BoxShadow(
  color: primaryGreen.withValues(alpha: 0.18),
  blurRadius: 14,
  spreadRadius: 0,
)

// Sombra de ícono neon
BoxShadow(
  color: accent.withValues(alpha: 0.25),
  blurRadius: 18,
)
```

### Línea separadora neon (gradiente horizontal)

```dart
Container(
  height: 1,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.transparent,
        primaryGreen.withValues(alpha: 0.25),
        primaryGreen.withValues(alpha: 0.50),
        primaryGreen.withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ),
  ),
)
```

### Barra lateral neon (section headers)

```dart
Container(
  width: 3,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [accent, accent.withValues(alpha: 0.15)],
    ),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.5),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  ),
)
```

---

## 5. Componentes

### AppBar

- Fondo: `#080808`
- Elevation: `0`
- Botones de ícono: contenedor `36×36`, `BorderRadius.circular(10)`, fill `#141414`, borde `primaryGreen.withValues(alpha: 0.18)`, `width: 1`
- Línea inferior: separador neon con gradiente (ver §4)

### Navbar inferior

- Fondo: `#080808`
- Altura: `76px`
- Íconos inactivos: `#5A5A5A`
- Íconos activos: verde neon
- Item seleccionado: `AnimatedContainer` con fill `primaryGreen.withValues(alpha: 0.14)`, borde `alpha: 0.22`, `BorderRadius.circular(12)`, animación `180ms`
- Fade en los extremos con `LinearGradient` para scroll

### Inputs de texto

Decoración base:
```dart
// Fondo y borde
fill color:   Color(0xFF141414)
border color: Color(0xFF272727)  // estado normal
border width: 1.5

// Al tener foco → glow verde
BoxShadow(
  color: primaryGreen.withValues(alpha: 0.16),
  blurRadius: 16,
)

// Al tener error → glow rojo
BoxShadow(
  color: Colors.red.withValues(alpha: 0.18),
  blurRadius: 12,
)

borderRadius: 12.0
contentPadding: vertical 12, horizontal 16
transición de estado: AnimatedContainer 220ms
```

Íconos de prefix: contenedor con margin `9px`, border neon `alpha: 0.2`.

### Botones primarios

```dart
height: 52.0
borderRadius: 14.0

// Gradiente de fondo (usa el color del propio botón)
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [bgColor, bgColor.withValues(alpha: 0.85)],
)

// Sombra neon inferior
boxShadow: [
  BoxShadow(
    color: primaryColor.withValues(alpha: 0.38),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
]

// Estado deshabilitado / cargando
opacity: 0.45
loading spinner: 18×18, strokeWidth 2.5

// Animación de press
duration: 200ms
```

### Dialogs / AlertDialog

```dart
backgroundColor: Color(0xFF0E0E0E)  // o #1A1A1A según contexto
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: BorderSide(
    color: primaryGreen.withValues(alpha: 0.18-0.20),
    width: 1,
  ),
)
```

### Section Headers

- Barra vertical neon de `3px` de ancho a la izquierda
- Gradiente de fondo (`topLeft → bottomRight`)
- Ícono en contenedor con fill `alpha: 0.1`, borde `alpha: 0.32`, `BorderRadius.circular(14)`
- Punto pulsante animado (escala `1.0 → 1.55`, opacity `0.9 → 0.4`, duración `1400ms`, repeat)

### Search Bar

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFF0F0F0F),
    borderRadius: BorderRadius.circular(25),  // cápsula
    border: Border.all(
      color: primaryGreen.withValues(alpha: 0.20),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryGreen.withValues(alpha: 0.07),
        blurRadius: 12,
        offset: Offset(0, 3),
      ),
    ],
  ),
)

// Botón de búsqueda interno
fill: primaryGreen.withValues(alpha: 0.14)
border: primaryGreen.withValues(alpha: 0.28)
borderRadius: 18
```

### Cards de contenido

```dart
// Card genérica
color: Color(0xFF141414) o Color(0xFF2A2A2A)
borderRadius: 12.0
border: Border.all(color: primaryGreen.withValues(alpha: 0.18), width: 1)

// Card web / max-width
maxWidth: 430
borderRadius: 24.0
border: Colors.white.withOpacity(0.08)
boxShadow: Colors.black.withOpacity(0.4), blur 20, offset (0,8)
```

---

## 6. Animaciones y Transiciones

| Duración | Uso |
|---------|-----|
| `150ms` | Transición de tema |
| `180ms` | Íconos de navbar |
| `200ms` | Press de botones |
| `220ms` | Estados de input (focus/error) |
| `300ms` | Delay corto general |
| `500ms` | Fade de pantallas |
| `900ms` | Entrada con `elasticOut` (tutorial) |
| `1400ms` | Animaciones pulsantes (repeat) |
| `1600ms` | Glow pulsante (repeat) |

Curvas más usadas:
- `Curves.fastOutSlowIn` — transiciones de tema
- `Curves.elasticOut` — entrada de overlays
- `Curves.easeOut` — salida de overlays

---

## 7. ThemeData (MaterialApp)

```dart
ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFE0E0E0),
    elevation: 0,
  ),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF29FF5E),
    secondary: Color(0xFF1A1A1A),
    surface: Color(0xFF1A1A1A),
    onPrimary: Colors.black,
    onSecondary: Color(0xFFE0E0E0),
    onSurface: Color(0xFFE0E0E0),
  ),
  cardColor: Color(0xFF1A1A1A),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
    bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
  ),
)
```

---

## 8. Splash Screen

- Color de fondo: `#000000` (negro puro)
- Ícono: `assets/icons/splash_icon.png`

---

## 9. Principios de diseño

1. **Neon sobre negro.** El verde `#29FF5E` es el único color de acento. Todo lo demás es escala de grises muy oscura.
2. **Glow, no sólido.** Los borders y sombras usan alpha bajo del verde para dar sensación de luminosidad sin ser agresivos.
3. **Gradientes sutiles.** Siempre lineales, de topLeft a bottomRight o de transparent a color. Nunca radiales en UI (solo en juegos).
4. **Animaciones rápidas.** Transiciones de UI entre 150-220ms. Las animaciones decorativas (pulsantes, glows) van de 900ms a 1600ms.
5. **Bordes finos.** Siempre `width: 1` o `1.2`. Nunca gruesos.
6. **Sin elevación visible.** El appbar y surfaces usan elevation 0. La profundidad se genera con sombras y colores ligeramente distintos.
7. **ThaleahFat solo para momentos épicos.** No mezclar en texto corriente. Solo hero text, puntajes de juegos, pantallas de bienvenida.
