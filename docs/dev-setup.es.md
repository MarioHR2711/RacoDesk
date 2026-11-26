# Preparación del entorno de desarrollo

**Leer en otros idiomas:** [English](dev-setup.md)

Pasos para dejar un ordenador con Windows listo para trabajar en RacoDesk. Todas las tecnologías son provisionales (ver el [README](../README.es.md) principal).

## 1. Herramientas

Abre PowerShell e instala con `winget` lo que falte. Si algún identificador falla, busca el correcto con `winget search <nombre>`.

| Herramienta | Comando |
|---|---|
| Git | `winget install Git.Git` |
| Visual Studio Code | `winget install Microsoft.VisualStudioCode` |
| PHP (8.2 o superior) | `winget install PHP.PHP.8.3` |
| Composer | `winget install Composer.Composer` |
| Node.js (LTS) y npm | `winget install OpenJS.NodeJS.LTS` |
| PostgreSQL | `winget install PostgreSQL.PostgreSQL.16` |
| JDK 17 (lo necesita Android) | `winget install Microsoft.OpenJDK.17` |
| Android Studio | `winget install Google.AndroidStudio` |

Cierra y vuelve a abrir PowerShell después de instalar, para que encuentre los comandos nuevos.

## 2. Configurar

**Git**

```powershell
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo-de-github"
```

**PHP.** Laravel con PostgreSQL necesita estas extensiones activadas en `php.ini`: `pdo_pgsql`, `mbstring`, `openssl`, `fileinfo`, `curl`. Quita el `;` del principio de cada línea `extension=...`.

**PostgreSQL.** Anota la contraseña del usuario `postgres` que elijas al instalar. No la subas nunca al repositorio: va en el archivo `.env` local.

**Android Studio.** Ábrelo una vez, instala el SDK de Android y crea un emulador (Device Manager). Después define la variable de entorno `ANDROID_HOME` con la carpeta del SDK (normalmente `C:\Users\<tú>\AppData\Local\Android\Sdk`) y añade `%ANDROID_HOME%\platform-tools` al `Path`.

## 3. Obtener el proyecto

```powershell
git clone https://github.com/MarioHR2711/RacoDesk.git
cd RacoDesk
git switch develop
```

## 4. Comprobar que todo está

Desde la raíz del repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-env.ps1
```

El script lista lo que está instalado y lo que falta. Solo lee versiones, no cambia nada. Debe terminar con "Everything is ready."

## Todavía no hace falta

- Visual Studio con las cargas de trabajo de C++ y UWP, necesarias más adelante para la versión de Windows de la app de empleados (React Native for Windows).
- Docker: sin decidir.
