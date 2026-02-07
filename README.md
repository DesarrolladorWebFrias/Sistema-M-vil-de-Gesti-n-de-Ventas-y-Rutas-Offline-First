# LactoPOS: Sistema Móvil de Gestión de Ventas y Rutas Offline-First

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) 
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

**LactoPOS** es una solución de Punto de Venta (POS) móvil de nivel empresarial desarrollada en **Flutter**, diseñada para optimizar la cadena de suministro y distribución de productos lácteos en rutas comerciales.

## 🚀 Características Principales

*   **Operación 100% Offline**: Arquitectura basada en **SQLite** que garantiza la continuidad del negocio sin conexión a internet.
*   **Gestión de Inventario en Tiempo Real**: Control preciso de stock por **Cajas** y **Piezas** sueltas.
*   **Punto de Venta (POS) Ágil**: Interfaz optimizada con carrusel de productos y feedback auditivo para ventas rápidas.
*   **Módulo de Reabastecimiento**: Registro detallado de entradas de stock en ruta ("Alta por Reabastecimiento").
*   **Arqueo de Caja Inteligente**: 
    *   Conteo de efectivo desglosado (billetes/monedas).
    *   Separación automática de "Venta del Día" vs "Fondo de Caja".
*   **Reportes Financieros**: Generación y exportación de reportes en **Excel** y **PDF** directamente desde el dispositivo.
*   **Seguridad**: Módulos administrativos protegidos y gestión de activos (imágenes) segura.

## 🛠️ Stack Tecnológico

*   **Lenguaje**: Dart
*   **Framework**: Flutter
*   **Arquitectura**: Clean Architecture + MVVM
*   **Gestión de Estado**: Provider
*   **Base de Datos**: sqflite (SQLite)
*   **Otras Librerías**: 
    *   `path_provider` (Sistema de archivos)
    *   `audioplayers` (Feedback UX)
    *   `image_picker` (Gestión de imágenes)
    *   `pdf` & `excel` (Reportes)

## 📸 Capturas de Pantalla

*(Próximamente)*

## 📦 Instalación

1.  Clonar el repositorio:
    ```bash
    git clone https://github.com/DesarrolladorWebFrias/Sistema-M-vil-de-Gesti-n-de-Ventas-y-Rutas-Offline-First.git
    ```
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```
3.  Ejecutar la aplicación:
    ```bash
    flutter run
    ```

---
Desarrollado con ❤️ por **[DesarrolladorWebFrias](https://github.com/DesarrolladorWebFrias)**
