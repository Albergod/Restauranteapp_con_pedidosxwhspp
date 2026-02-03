# Bot de WhatsApp - Restaurante

Bot de WhatsApp para recibir pedidos automáticamente.

## Requisitos

- Node.js 18+
- La app Flutter debe haberse ejecutado al menos una vez (para crear la base de datos)

## Instalación

```bash
cd whatsapp_bot
npm install
```

## Ejecución

```bash
npm start
```

1. Al iniciar, aparecerá un código QR en la terminal
2. Abre WhatsApp en tu teléfono
3. Ve a **Configuración > Dispositivos vinculados > Vincular dispositivo**
4. Escanea el código QR
5. ¡Listo! El bot responderá automáticamente a los mensajes

## Flujo del Bot

1. **Cliente escribe "menú"** → Bot muestra lista de platos numerados
2. **Cliente escribe números** (ej: "1, 3") → Bot confirma selección y pide dirección
3. **Cliente escribe dirección** → Bot crea el pedido y confirma

### Comandos

| Comando | Descripción |
|---------|-------------|
| `menú`, `menu`, `carta` | Muestra el menú del día |
| `1`, `1, 2`, `1 y 3` | Selecciona platos por número |
| `cancelar` | Cancela el pedido actual |

### Notas en el pedido

El cliente puede agregar notas escribiendo texto después de los números:
```
1, 2 sin sopa y la ensalada aparte
```

## Estructura de Archivos

```
whatsapp_bot/
├── index.js      # Punto de entrada y cliente de WhatsApp
├── bot.js        # Lógica del chatbot
├── database.js   # Conexión a SQLite
└── package.json  # Dependencias
```

## Notas

- El bot solo responde a mensajes privados (ignora grupos)
- Los pedidos se guardan en la misma base de datos de la app Flutter
- Al cerrar el bot con Ctrl+C, la sesión se guarda para no escanear QR nuevamente
