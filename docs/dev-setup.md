# Development environment setup

**Read this in other languages:** [Español](dev-setup.es.md)

Steps to leave a Windows computer ready to work on RacoDesk. All technologies are provisional (see the main [README](../README.md)).

## 1. Tools

Open PowerShell and install what is missing with `winget`. If an identifier fails, look for the right one with `winget search <name>`.

| Tool | Command |
|---|---|
| Git | `winget install Git.Git` |
| Visual Studio Code | `winget install Microsoft.VisualStudioCode` |
| PHP (8.2 or higher) | `winget install PHP.PHP.8.3` |
| Composer | `winget install Composer.Composer` |
| Node.js (LTS) and npm | `winget install OpenJS.NodeJS.LTS` |
| PostgreSQL | `winget install PostgreSQL.PostgreSQL.16` |
| JDK 17 (needed by Android) | `winget install Microsoft.OpenJDK.17` |
| Android Studio | `winget install Google.AndroidStudio` |

Close and reopen PowerShell after installing so the new commands are found.

## 2. Configure

**Git**

```powershell
git config --global user.name "Your Name"
git config --global user.email "your-github-email"
```

**PHP.** Laravel with PostgreSQL needs these extensions enabled in `php.ini`: `pdo_pgsql`, `mbstring`, `openssl`, `fileinfo`, `curl`. Remove the `;` at the start of each `extension=...` line.

**PostgreSQL.** Remember the password of the `postgres` user chosen during installation. Never commit it; it goes in the local `.env` file.

**Android Studio.** Open it once, install the Android SDK and create an emulator (Device Manager). Then set the environment variable `ANDROID_HOME` to the SDK folder (usually `C:\Users\<you>\AppData\Local\Android\Sdk`) and add `%ANDROID_HOME%\platform-tools` to `Path`.

## 3. Get the project

```powershell
git clone https://github.com/MarioHR2711/RacoDesk.git
cd RacoDesk
git switch develop
```

## 4. Check everything

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-env.ps1
```

The script lists what is installed and what is missing. It only reads versions; it does not change anything. It must end with "Everything is ready."

## Not needed yet

- Visual Studio with the C++ and UWP workloads, needed later for the Windows version of the employee app (React Native for Windows).
- Docker: not decided.
