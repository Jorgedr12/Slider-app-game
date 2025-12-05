# 🚗💨 CarRush2D — Arcade Racing Reimagined

**CarRush2D** es un juego de carreras infinitas en 2D desarrollado en Flutter. Combina velocidad, cultura urbana, humor y personajes icónicos en una experiencia dinámica donde tu objetivo es simple: **seguir avanzando**.

Explora escenarios únicos, esquiva obstáculos, mejora tus reflejos y domina cada vehículo. No hay meta. Solo el camino.

---

## 🗺️ Mundos Disponibles

### 1. Mount Akina
Carretera montañosa rodeada de **puras rocas**, terreno árido y un camino retador que exige precisión en cada giro.

### 2. Slender Forest
Bosque verde y luminoso durante el día, con caminos naturales y vegetación ligera. Un escenario más relajado, pero con suficiente actividad para mantener la atención del jugador.

### 3. Ueno Park
Parque lleno de **cerezos cubiertos de nieve**, caminos fríos y un ambiente invernal combinado con pétalos rosados cayendo. Un escenario visualmente único.

---

## 👥 Conductores y Vehículos

Cada personaje posee estilo propio y un vehículo emblemático:

| Conductor | Vehículo | Descripción |
|-----------|----------|-------------|
| **Takumi Fujiwara** | Toyota Trueno GT-Apex AE86 | Preciso y ligero. Inspirado en leyendas del downhill. |
| **El Pirata de Culiacán** | Jeep Cherokee | Rudo, pesado y caótico. |
| **El Vítor** | Microbús Ruta 12 | Mucha actitud, poca aerodinámica. |
| **Hot Dogs Mano Puercas** | Carro de Dogos | Humor y velocidad combinados. |
| **Miguel The Creator** | Tsuru 1992 | Fiable y resistente. Un clásico mexicano. |
| **Cirett** | DeLorean DMC-12 | Retro-futurista. Único en su estilo. |

---

## 🎮 Mecánicas de Juego

### Recursos del Vehículo
- **⛽ Combustible**: se reduce con el tiempo.
- **🛞 Integridad del vehículo**: disminuye al chocar.

### Objetos en el Camino
- Tanques de gasolina
- Monedas para incrementar puntuación

### Dificultad Progresiva
La velocidad del juego aumenta mientras avanzas. No dejes de reaccionar.

### Modos de Pantalla
- **Vertical**: controles simples con una mano.
- **Horizontal**: vista panorámica, mayor campo visual.

---

## 🧩 Arquitectura del Proyecto

```
lib/
│ main.dart
└─ services/
      supabase_service.dart
```

### Supabase
- Autenticación
- Registro de puntuaciones

### Persistencia Local
- Personaje seleccionado
- Último mapa
- Ajustes de audio
- Preferencias del jugador

---

## 🔧 Configuración de Variables de Entorno

1. **Crear el archivo `.env`**:
   ```bash
   cp .env.example .env
   ```

2. **Agregar tu configuración**:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu_clave
   AUTH_EMAIL=tucorreo@example.com
   AUTH_PASSWORD=tu_password
   ```

⚠️ **Importante**: El archivo `.env` está en `.gitignore` y no debe subirse al repositorio.

---

## 🚀 Instalación

```bash
flutter pub get
flutter run
```

---

## 📦 Dependencias Principales

- `supabase_flutter`
- `flutter_dotenv`
- Librerías estándar de Flutter para animaciones, UI y lógica del juego.

---

## 🏁 Créditos

Proyecto desarrollado por:
- **DUARTE RUIZ JORGE LUIS**
- **ESTRADA NERI DANIEL IVAN**
- **MARTÍNEZ HARO KEVIN XANDÉ**

---

🎮 **¡Disfruta la carrera!** 🏁
