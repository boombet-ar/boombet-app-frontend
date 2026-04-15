# BoomBet — Guía de Sistema de Diseño

> Referencia visual completa para mantener consistencia en nuevas pantallas.
> Extraída del código fuente real en abril 2026.

---

## Identidad Visual

**Sensación:** Casino gaming premium oscuro con energía neon. Combina la frialdad del dark-UI con la intensidad del verde fluorescente. Transmite: *noche, adrenalina, exclusividad digital, apuesta seria pero accesible*.

**Estilo:** Dark glassmorphism suave + neon accent. No es grunge, no es flat puro — es una mezcla de **dark material + glow gaming**.

---

## 1. Paleta de Colores

### Primarios

| Token | Hex | RGB | Uso |
|---|---|---|---|
| `primaryGreen` | `#29FF5E` | `rgb(41,255,94)` | Acento principal, botones, iconos activos, glows |
| `darkBg` | `#121212` | `rgb(18,18,18)` | Fondo del scaffold |
| `darkAccent` | `#1A1A1A` | `rgb(26,26,26)` | Cards, superficies, modales |
| `darkCardBg` | `#2A2A2A` | `rgb(42,42,42)` | Cards más claras (segundo nivel) |
| `textDark` | `#E0E0E0` | `rgb(224,224,224)` | Texto principal en dark mode |

### Grises oscuros usados en widgets (hardcoded)

| Hex | Uso típico |
|---|---|
| `#080808` | AppBar, NavBar — el más oscuro de la jerarquía |
| `#0A0A0A` | Loading badge background |
| `#0E0E0E` | Dialog backgrounds |
| `#0F0F0F` | SearchBar background |
| `#111111` | SectionHeader gradient start |
| `#141414` | Form fields fill, AppBar icon buttons |
| `#171717` | SectionHeader gradient end |
| `#181818` | Raffle cards |
| `#272727` | Form field borders en reposo |
| `#1A1A1A` | Modales, bottom sheets |
| `#5A5A5A` | NavBar icons no seleccionados |

> **Regla:** La jerarquía oscura va de `#080808` (más profundo) a `#2A2A2A` (superficie más elevada). A mayor elevación conceptual del elemento, más claro.

### Semánticos

| Token | Color | Uso |
|---|---|---|
| `errorRed` | `Colors.red` / `#F44336` | Errores en forms, glow de error |
| `warningOrange` | `Colors.orange` / `#FF9800` | Advertencias |
| `successGreen` | `Colors.green` / `#4CAF50` | Estados positivos |

### Light Mode (existe pero es secundario)

| Token | Hex | Uso |
|---|---|---|
| `lightBg` | `#E3E3E3` | Fondo scaffold claro |
| `lightAccent` | `#D4D4D4` | Superficies claras |
| `lightCardBg` | `#EAEAEA` | Cards claras |
| `lightInputBg` | `#DDDDDD` | Fill de inputs |
| `lightInputBorder` | `#B0B0B0` | Borde normal |
| `lightInputBorderFocus` | `#7A7A7A` | Borde en focus |
| `lightDialogBg` | `#E9E9E9` | Diálogos |
| `lightHintText` | `#666666` | Placeholders |
| `lightDivider` | `#C6C6C6` | Separadores |

### Transparencias clave

```
Glow suave:         alpha 0.12 – 0.18   (efecto ambient)
Bordes neon:        alpha 0.18 – 0.30   (sutil, no agresivo)
Focus glow:         alpha 0.16          (form fields)
Error glow:         alpha 0.18          (form fields error)
Button shadow:      alpha 0.38          (visible bajo el botón)
Hover/selected bg:  alpha 0.12 – 0.15  (item seleccionado)
Texto secundario:   alpha 0.38 – 0.55  (hints, labels)
Texto terciario:    alpha 0.25 – 0.35  (muy suave)
Modal overlay:      alpha 0.75 – 0.90  (oscuro fuerte)
```

---

## 2. Tipografía

### Familia

La app usa **Roboto** (Material default). No hay font custom activa en cuerpo de texto. La font `ThaleahFat` aparece en la memoria del proyecto pero no se encontró activa en TextStyles del código actual — verificar si está registrada en `pubspec.yaml`.

> **Sugerencia:** Si se quiere reforzar identidad gaming, aplicar ThaleahFat en títulos grandes y mantener Roboto para cuerpo.

### Escala tipográfica

| Token | Tamaño | Uso |
|---|---|---|
| `headingLarge` | 28px | Títulos de página principales |
| `headingMedium` | 22px | Subtítulos de sección |
| `headingSmall` | 18px | Encabezados de cards |
| `bodyLarge` | 16px | Cuerpo principal |
| `bodyMedium` | 14px | Cuerpo secundario, inputs |
| `bodySmall` | 13px | Texto auxiliar |
| `bodyExtraSmall` | 12px | Labels de form |
| `captionSize` | 11px | Captions, subtítulos de section headers |

### Tamaños especiales (hardcoded en contextos específicos)

| Tamaño | Contexto |
|---|---|
| 42px w900 letterSpacing 4 | Welcome title del tutorial |
| 22px w600 letterSpacing 3 | Subtítulo welcome tutorial |
| 16px w800 | Section header titles |
| 15px w600–w700 | Botones (AppButton) |
| 13px w500 | NavBar labels |
| 11.5px | Error text en forms |
| 10.5px w600 | NavBar label seleccionado |

### Pesos usados

```
w400  Regular    → Texto normal
w500  Medium     → Labels, hints
w600  SemiBold   → Botones, items seleccionados
w700  Bold       → Botones importantes
w800  ExtraBold  → Section headers
w900  Black      → Títulos de impacto (tutorial)
```

### Letter spacing

```
Normal texto:     0.1 px  (tracking mínimo)
Labels/botones:   0.3 px  (un poco de apertura)
Títulos grandes:  3–4 px  (muy abierto, impacto)
```

---

## 3. Efectos Visuales

### Glow / Box Shadows

El **glow verde es la firma visual** de la app. Se aplica en:

```dart
// Form field en focus
BoxShadow(
  color: primaryGreen.withAlpha(41),  // 0.16 alpha
  blurRadius: 16,
  spreadRadius: 0,
)

// AppButton activo
BoxShadow(
  color: primaryColor.withAlpha(97),  // 0.38 alpha
  blurRadius: 16,
  spreadRadius: 0,
  offset: Offset(0, 4),
)

// SectionHeader icon
BoxShadow(
  color: accent.withAlpha(64),        // 0.25 alpha
  blurRadius: 18,
  spreadRadius: 0,
  offset: Offset(0, 2),
)

// Form field en error
BoxShadow(
  color: Colors.red.withAlpha(46),    // 0.18 alpha
  blurRadius: 12,
  spreadRadius: 0,
)
```

### Gradientes

**Separador neon (AppBar y NavBar):**
```dart
LinearGradient(
  colors: [
    Colors.transparent,
    primaryGreen.withAlpha(64),   // 0.25
    primaryGreen.withAlpha(128),  // 0.50
    primaryGreen.withAlpha(64),   // 0.25
    Colors.transparent,
  ],
)
// Altura: 1px — efecto de línea que brilla en el centro
```

**AppButton:**
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [bgColor, bgColor.withAlpha(217)],  // 0.85 alpha en extremo
)
```

**SectionHeader background:**
```dart
// Dark mode
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF111111), Color(0xFF171717)],
)
```

**Scroll fade overlays:**
```dart
LinearGradient(
  colors: [bgColor.withAlpha(0), bgColor.withAlpha(235)],  // 0.92
)
```

### Bordes

```
Estilo dominante:    1–1.5px solid, con alpha entre 0.18 y 0.75
Normal:              borderColor.withAlpha(~46)   (muy sutil)
Focused/Selected:    primaryGreen.withAlpha(~191) (bien visible)
Error:               Colors.red.withAlpha(~153)
Buttons:             1px, primaryGreen.withAlpha(~71)
```

### Blur / Transparencia

No se usa `BackdropFilter` de forma generalizada. Las transparencias se logran con `withAlpha()` directo sobre contenedores oscuros, sin blur real.

> La app **no es glassmorphism con blur real** — simula el efecto con fondos semi-transparentes sobre fondos muy oscuros. Esto es más eficiente en mobile.

---

## 4. Componentes UI

### AppBar

```
Altura:           56px + 1px separador neon
Fondo:            #080808
Elevation:        0

Icon buttons:
  Tamaño:         36×36px
  Fondo:          #141414
  Borde:          1px, primaryGreen α18%
  Border radius:  10px
  Icono:          19px, primaryGreen

Separador inferior: gradiente neon 1px (ver §Gradientes)
```

### NavBar

```
Altura:           76px
Fondo:            #080808
Separador:        gradiente neon 1px (igual que AppBar)

Item seleccionado:
  Fondo:          primaryGreen α14%
  Borde:          1px, primaryGreen α22%
  Border radius:  12px
  Icono:          26px, primaryGreen
  Label:          10.5px w600, primaryGreen

Item normal:
  Sin fondo ni borde
  Icono:          26px, #5A5A5A
  Label:          10.5px w500, #5A5A5A

Transición:       180ms
```

### AppButton (botón primario)

```
Altura:           52–56px (configurable, default 56)
Border radius:    14px
Width:            full width

Normal:
  Fondo:          gradient topLeft→bottomRight
                  [primaryColor → primaryColor α85%]
  Sombra:         primaryColor α38%, blur 16, offset Y+4
  Texto:          15px w600–w700, letterSpacing 0.3, negro

Disabled:
  Fondo:          color plano α45%
  Sin sombra

Loading:
  Spinner strokeWidth 2.5 + label
```

### Form Fields

```
Border radius:    12px
Fill:             #141414
Transición:       220ms Curves.easeOut

Reposo:
  Borde:          1.5px, #272727
  Sin glow

Focus:
  Borde:          1.5px, primaryGreen α75%
  Glow:           primaryGreen α16%, blur 16

Error:
  Borde:          1.5px, red α60%
  Glow:           red α18%, blur 12

Label:            12px w500 α55% letterSpacing 0.3
Input text:       15px
Hint:             14px α28%
Error text:       11.5px α85%

Prefix icon container:
  Margin:         9px all
  Padding:        6px all
  Border radius:  8px
  Icono:          17px
```

### SearchBar

```
Fondo:            #0F0F0F
Border radius:    25px (pillow)
Borde:            1.2px, primaryGreen α20%
Sombra:           primaryGreen α7%, blur 12, offset Y+3

Ícono buscar:     19px, primaryGreen α50%
Texto:            14px, letterSpacing 0.1
Hint:             13px, textDark α65%

Botón buscar:
  Fondo:          primaryGreen α14%
  Borde:          1px, primaryGreen α28%
  Border radius:  18px
  Icono:          17px, primaryGreen
```

### SectionHeader

```
Barra lateral izquierda:
  Ancho:          3px
  Gradiente:      accent → accent α15%
  Glow:           accent α50%, blur 10, spread 2

Contenedor body:
  Padding:        14 izq / 10 vertical / 12 der
  Fondo:          gradiente sutil (#111 → #171)
  Borde inferior: 1px, white α5%

Ícono animado:
  Padding:        11px
  Fondo:          accent α10%
  Borde:          1px, accent α32%
  Border radius:  14px
  Sombra:         accent α25%, blur 18
  Animación:      scale 0.88→1.0 + fade, 150ms Curves.easeOut

Dot pulsante:
  Tamaño:         6×6px, circle
  Color:          accent
  Glow:           accent α65%, blur 7, spread 1
  Animación:      scale 1.0→1.55 + opacity 0.9→0.4, 1400ms reverse

Título:           16px w800 letterSpacing 0.2
Subtítulo:        11px α38% letterSpacing 0.1
```

### Cards / Modales

```
Cards oscuras:
  Fondo:          #181818 – #2A2A2A (según profundidad)
  Border radius:  16–20px
  Borde:          1px, white α5–8%

Bottom sheets:
  Fondo:          #1A1A1A
  Border radius:  24px (top only)

Diálogos:
  Fondo:          #0E0E0E
  Border radius:  16px
  Sombra:         black α30%, blur 20, offset Y+10
```

### Loading Overlay

```
Fondo:            Colors.black54
Contenedor:
  Padding:        32px horiz / 24px vert
  Fondo:          #1A1A1A
  Border radius:  16px
  Sombra:         black α30%, blur 20
Spinner:          primaryGreen, strokeWidth 3
```

---

## 5. Espaciados y Layout

### Escala base

| Token | Valor | Uso |
|---|---|---|
| `paddingXSmall` | 4px | Micro gaps |
| `paddingSmall` | 8px | Separación interna pequeña |
| `paddingMedium` | 12px | Estándar entre elementos |
| `paddingLarge` | 16px | Padding de contenedores |
| `paddingXLarge` | 24px | Secciones grandes |
| `paddingXXLarge` | 32px | Pantallas / sections |

### Reglas de layout

```
Screen horizontal padding:   16px (mobile) / 20–40px (tablet/web)
Entre secciones verticales:  16–24px
Entre cards en grid:         16–20px
Max width contenido web:     1200px (centrado)
```

### Border Radii

```
Pequeño (iconos internos):   7–8px
Estándar (cards, inputs):    12px
Botones:                     14px
Section header icons:        14px
AppBar buttons:              10px
NavBar items:                12px
Dialogs:                     16px
Raffle cards:                20px
SearchBar:                   25px (pillow)
Bottom sheets:               24px (solo arriba)
```

---

## 6. Animaciones y Microinteracciones

### Principios

- **Velocidades de respuesta:** 150–220ms (transiciones de estado). El usuario siente respuesta inmediata.
- **Transiciones de pantalla:** `Curves.fastOutSlowIn` (Material estándar).
- **Efectos decorativos:** 850–1600ms con `repeat reverse` — lentos, ambient, no distractivos.

### Catálogo de animaciones

| Elemento | Tipo | Duración | Curva |
|---|---|---|---|
| Theme change | Fade implícito | 150ms | fastOutSlowIn |
| Form field glow | AnimatedContainer | 220ms | easeOut |
| Gender button select | AnimatedContainer | 220ms | easeOut |
| NavBar item select | AnimatedContainer | 180ms | — |
| SectionHeader icon enter | Scale + Opacity | 150ms | easeOut / easeIn |
| SectionHeader dot pulse | Scale 1→1.55 + Opacity | 1400ms ∞ | easeInOut |
| NavBar chevron pulse | Opacity 0.35→1.0 | 850ms ∞ | easeInOut |
| Tutorial welcome enter | Scale 0.7→1.0 + Fade | 900ms | elasticOut |
| Tutorial welcome exit | Fade | 500ms | easeOut |
| Tutorial glow | Shadow intensity | 1600ms ∞ | easeInOut |
| Tutorial button pulse | Scale/Opacity | 900ms ∞ | easeInOut |
| NavBar swipe hint | Translate X (TweenSequence) | 1600ms ∞ | easeInOut |

### Regla para nuevas animaciones

```
Interacción usuario    → 150–250ms, curva easeOut
Estado loading         → Spinner continuo, no duración
Efectos ambient/glow   → 850–1600ms, repeat reverse
Entrada de elemento    → 150–500ms, scale+fade
Salida de elemento     → 300–500ms, fade out
```

---

## 7. Responsive Design

```
Breakpoints:
  Mobile:    < 600px    → 1 columna
  Tablet:    600–1100px → 2 columnas
  Desktop:   > 1100px   → 3 columnas, max 1400px

NavBar:
  Mobile:    horizontal scroll con peek effect (22px)
  Web:       items visibles sin scroll (> 600px)

Contenido máximo:  1200px centrado (ResponsiveWrapper)
```

---

## 8. Inconsistencias y Mejoras Sugeridas

### Crítico

**1. Colores hardcoded dispersos**
Existen al menos 10 valores hex hardcoded en widgets (`#080808`, `#0F0F0F`, `#181818`, etc.) que no están en `AppConstants`. Si cambia el tema, hay que buscarlos manualmente.
> **Fix:** Agregar a `AppConstants`: `appBarBg = Color(0xFF080808)`, `searchBarBg = Color(0xFF0F0F0F)`, `raffleBg = Color(0xFF181818)`, `formFieldBg = Color(0xFF141414)`, `formFieldBorder = Color(0xFF272727)`.

**2. `buttonHeight` declarado como 56px pero AppButton usa 52px por defecto**
Hay un mismatch entre la constante `buttonHeight = 56.0` y el valor real usado en AppButton.
> **Fix:** Alinear ambos a 52px o 56px y usar la constante.

### Moderado

**3. Escala tipográfica sin escalón entre 22px y 28px**
El salto de `headingMedium (22)` a `headingLarge (28)` es grande. En pantallas de contenido denso se necesita un valor intermedio (≈ 24–25px).
> **Fix:** Agregar `headingLargeMedium = 24.0` o usar 25px como valor libre.

**4. Font ThaleahFat**
La memoria menciona esta fuente como parte de la identidad pero no se aplica sistemáticamente en títulos grandes del código actual. Hay inconsistencia entre lo declarado en identidad y lo implementado.
> **Fix:** Verificar si está registrada en `pubspec.yaml` y aplicarla en `headingLarge`/`headingMedium` para reforzar la identidad gaming.

**5. `successGreen` usa `Colors.green` (Material) en lugar del `primaryGreen` neon**
En dark mode el verde Material (`#4CAF50`) se ve genérico y no cohesionado con el neon de la app.
> **Fix:** Evaluar usar `primaryGreen` con menor opacidad para estados de éxito, o definir un verde éxito más cercano al neon (`#22E055`).

### Menor

**6. Light mode incompleto**
Hay tokens light definidos pero la experiencia light no está completa ni testeada a fondo. Varios widgets usan colores hardcoded que ignoran el tema claro.
> **Fix (si se prioriza):** Auditar todos los `Color(0xFF...)` hardcoded y reemplazar con condicionales `isDark ? darkColor : lightColor`.

**7. `borderRadius = 12` como única constante**
Se usan al menos 6 valores distintos de border-radius (8, 10, 12, 14, 16, 20, 24, 25) y solo uno está en AppConstants.
> **Fix:** Agregar `borderRadiusSmall = 8.0`, `borderRadiusMedium = 12.0`, `borderRadiusLarge = 16.0`, `borderRadiusXLarge = 24.0`.

**8. Ausencia de elevation/profundidad sistemática**
La jerarquía de profundidad (oscuro = más profundo) es intuitiva pero no está documentada ni codificada. Un nuevo developer podría elegir colores al azar.
> **Fix:** Documentar la escala de profundidad: `depth0 = #080808`, `depth1 = #0E0E0E`, `depth2 = #141414`, `depth3 = #1A1A1A`, `depth4 = #2A2A2A`.

---

## Resumen rápido — Cheatsheet para nuevas pantallas

```
Fondo pantalla:       #121212
Fondo AppBar/Nav:     #080808
Fondo cards:          #1A1A1A  (normal) / #181818 (darker) / #2A2A2A (lighter)
Fondo inputs:         #141414
Acento principal:     #29FF5E  (verde neon)
Texto principal:      #E0E0E0
Texto secundario:     #E0E0E0 α55%
Texto terciario:      #E0E0E0 α35%

Bordes sutiles:       #272727 (sin foco) | #29FF5E α18% (neon sutil)
Bordes activos:       #29FF5E α75%
Glow activo:          BoxShadow(#29FF5E α16%, blur 16)
Glow fuerte:          BoxShadow(#29FF5E α38%, blur 16, offset Y+4)

Border radius std:    12px (cards/inputs) | 14px (botones) | 16px (modales)
Padding horizontal:   16px mobile / 20–40px web
Transición estado:    220ms Curves.easeOut
Transición pantalla:  150ms Curves.fastOutSlowIn
```
