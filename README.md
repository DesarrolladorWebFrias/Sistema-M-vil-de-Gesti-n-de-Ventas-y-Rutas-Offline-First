# 🥛 LactoPOS Pro

**Sistema Móvil de Gestión de Ventas y Rutas (Offline-First)**

> **Versión Actual**: v1.0 (Release Candidate)
> **Desarrollado con**: Flutter & Dart

LactoPOS Pro es una solución integral diseñada para optimizar la venta y distribución de productos lácteos en ruta. Funciona completamente offline, permitiendo a los vendedores gestionar inventario, realizar ventas rápidas y generar reportes financieros sin necesidad de conexión a internet.

---

## 📱 Características Principales

### 🛒 Punto de Venta (POS) Ágil
*   **Carrusel de Productos**: Interfaz visual intuitiva para selección rápida.
*   **Feedback Auditivo**: Confirmación sonora ("Dring") al agregar productos.
*   **Doble Unidad de Medida**: Venta por **Cajas** o **Piezas** sueltas.
*   **Carrito Dinámico**: Cálculo automático de totales y cambio.

### 📦 Gestión de Inventario (Admin)
*   **Base de Datos Local**: Persistencia robusta con **SQLite**.
*   **CRUD de Productos**: Alta, baja y modificación de precios/costos.
*   **Reabastecimiento en Ruta**: Registro de entradas de stock con etiqueta de trazabilidad.
*   **Imágenes Personalizadas**: Carga de fotos desde cámara o galería.

### 💰 Finanzas y Reportes
*   **Cierre de Caja (Arqueo)**: Conteo detallado de billetes y monedas.
*   **Conciliación Automática**: Comparativa entre Sistema vs Real.
*   **Exportación Profesional**:
    *   📄 **PDF**: Resumen ejecutivo del día.
    *   📊 **Excel**: Detalle transaccional para contabilidad.

---

## 🛠️ Stack Tecnológico

*   **Frontend**: Flutter (Mobile).
*   **Lenguaje**: Dart.
*   **Arquitectura**: Clean Architecture + MVVM.
*   **Estado**: Provider.
*   **Persistencia**: SQflite (SQLite).
*   **Utilerías**:
    *   `pdf` & `printing`: Generación de documentos.
    *   `excel`: Exportación de datos.
    *   `audioplayers`: Efectos de sonito.
    *   `image_picker`: Gestión de multimedia.

---

## 🚀 Instalación y Despliegue

### Requisitos Previos
*   Flutter SDK (v3.0+)
*   Dart SDK
*   Android Studio / VS Code

### Configuración del Entorno
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

## 🔐 Acceso Administrativo
Para acceder al módulo de gestión, utilice las credenciales maestras:
*   **Contraseña**: `Lu15Fr1@52026`

---

## 📅 Historial de Versiones

*   **v0.5**: Módulo de Reportes (PDF/Excel) y Cierre de Caja.
*   **v0.4**: Interfaz de Venta (POS) y Lógica de Carrito.
*   **v0.3**: Panel Administrativo y Gestión de Inventario.
*   **v0.2**: Persistencia de Datos (SQLite) y Modelos.
*   **v0.1**: Estructura inicial del proyecto.

---
**Desarrollado por**: DesarrolladorWebFrias
*Luisfriasdesarrollador@gmail.com*
