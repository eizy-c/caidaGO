# 🚀 CaidaGO - Servidor Multijugador Online

Servidor en la nube en tiempo real (WebSockets + HTTP) para orquestar salas públicas y privadas con PIN, emparejamiento 1 vs 1, 3 jugadores y 2 vs 2 en parejas, sincronización de cartas, cantos, y personalizaciones (marcos y avatares de cada jugador).

---

## 🚂 Despliegue en Railway.com (Paso a Paso)

1. Entra a [railway.com](https://railway.com) e inicia sesión con tu cuenta de **GitHub**.
2. Pulsa en **"New Project"** ➔ **"Deploy from GitHub repo"**.
3. Selecciona tu repositorio: `eizy-c/caidaGO`.
4. Una vez creado el servicio, haz clic sobre él y entra en la pestaña **"Settings"**:
   - En la sección **Build**:
     - Busca **"Root Directory"** y cámbialo a: `/server`
     - (Railway detectará automáticamente el archivo `Dockerfile` y `railway.json`).
   - En la sección **Networking**:
     - Haz clic en **"Generate Domain"** (o "Public Networking").
     - Railway te asignará una URL pública con HTTPS y WSS protegida por SSL, por ejemplo:
       `caidago-production.up.railway.app`
5. ¡Listo! El servidor se compilará y quedará activo 24/7.
6. Tu enlace WebSocket para el juego será:
   ```text
   wss://tu-dominio.up.railway.app/ws
   ```
   (Simplemente copias esa URL y la colocas en el botón del engranaje / servidor de la pantalla de Salas en Flutter).

---

## 💻 Ejecutar localmente en tu PC (Para Pruebas)

Desde la raíz de la carpeta `server/`:

```bash
cd server
dart pub get
dart run bin/server.dart
```

El servidor iniciará en el puerto `8080`:
- **Health Check:** `http://localhost:8080/health`
- **Salas Públicas:** `http://localhost:8080/rooms`
- **WebSocket:** `ws://localhost:8080/ws`

---

## ☁️ Alternativa: Despliegue en Render.com

1. Entra a [render.com](https://render.com) e inicia sesión con tu cuenta de **GitHub**.
2. Pulsa en **"New +"** ➔ **"Web Service"**.
3. Selecciona tu repositorio: `eizy-c/caidaGO`.
4. Configura:
   - **Root Directory:** `server`
   - **Runtime:** `Docker`
   - **Instance Type:** `Free`
5. URL resultante: `wss://tu-servicio.onrender.com/ws`
