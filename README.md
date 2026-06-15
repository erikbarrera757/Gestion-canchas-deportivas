# SportManager Pro — Sistema de Gestión Deportiva

Este repositorio contiene el proyecto unificado de **SportManager Pro**, que incluye la aplicación frontend en **Flutter**, la API backend en **PHP** y el script de base de datos **MySQL**.

---

## 📁 Estructura del Proyecto

Cuando abras esta carpeta, encontrarás los siguientes elementos esenciales:
1. `softwareproject/`: Código fuente de la aplicación móvil y web construida en **Flutter**.
2. `sportmanager_api/`: Código fuente del backend construido en **PHP** (REST API).
3. `sportmanager_db.sql`: Archivo SQL para la base de datos **MySQL**.

---

## Abrir el módulo de incidencias e ir al formulario de registro. Capturar el formulario vacío o con datos de prueba (ID cancha, tipo de problema, descripción).
1.	Enviar el formulario y capturar la confirmación con el número de ticket asignado.
2.	Abrir el panel del administrador y capturar la notificación de nueva solicitud recibida.

* *Herramientas: PDO MySQL Driver, phpMyAdmin, XAMPP.*

---

### 1. Configuración del Backend (PHP API)
1. **Copiar la carpeta de la API:**
   * Copia la carpeta `sportmanager_api` de este repositorio.
   * Pégala directamente dentro del directorio de servidor de XAMPP:
     `C:\xampp\htdocs\sportmanager_api`

---

### 2. Ejecutar la Aplicación (Flutter Frontend)
1. Abre tu terminal o editor de código (como VS Code) en la ruta del frontend:
   `PoyectoSoftware/softwareproject`
2. Asegúrate de descargar las dependencias del proyecto ejecutando:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación en modo Web (Chrome) con el siguiente comando:
   ```bash
   flutter run -d chrome
   ```

---

## 🔑 Credenciales de Acceso de Prueba
Una vez iniciada la aplicación, puedes acceder utilizando las siguientes cuentas de prueba:

* **Administrador:**
  * **Email:** `admin@canchas.com`
  * **Contraseña:** `admin123`

* **Cliente:**
  * **Email:** `cliente@canchas.com`
  * **Contraseña:** `cliente123`

* **Personal de Mantenimiento / Técnico:**
  * **Email:** `tecnico@canchas.com`
  * **Contraseña:** `tecnico123`

* **Vendedor de Snacks:**
  * **Email:** `snack@canchas.com`
  * **Contraseña:** `snack123`

* **Encargado de Tienda:**
  * **Email:** `tienda@canchas.com`
  * **Contraseña:** `tienda123`
