# Local Windows hosting with SQL Server Express

## 1) Install SQL Server Express
1. Download **SQL Server Express (2019/2022)** from Microsoft.
2. Choose **Basic** installation.
3. Capture the instance name (default is `SQLEXPRESS`).
4. Install **SQL Server Management Studio (SSMS)** for database administration.

## 2) Create the database
Open SSMS and run:

```sql
CREATE DATABASE ChangeMgmt;
GO
```

## 3) Create a SQL login (optional)
Use Windows Authentication if possible. If SQL Authentication is required:

```sql
CREATE LOGIN ChangeMgmtApp WITH PASSWORD = 'UseA_Strong_Password!';
GO
USE ChangeMgmt;
CREATE USER ChangeMgmtApp FOR LOGIN ChangeMgmtApp;
EXEC sp_addrolemember 'db_owner', 'ChangeMgmtApp';
GO
```

## 4) Example connection strings
- **Windows Auth**
  ```
  Server=localhost\SQLEXPRESS;Database=ChangeMgmt;Trusted_Connection=True;TrustServerCertificate=True;
  ```

- **SQL Auth**
  ```
  Server=localhost\SQLEXPRESS;Database=ChangeMgmt;User Id=ChangeMgmtApp;Password=UseA_Strong_Password!;TrustServerCertificate=True;
  ```

## 5) Local hosting options (static UI)
This repo currently contains static HTML/CSS only. You can host it locally via:

### Option A: Python static server
```bash
cd C:\ChangeMgmt\public
python -m http.server 8000
```
Then open `http://localhost:8000/index.html`.

### Option B: IIS
1. Install IIS and ensure **Static Content** role is enabled.
2. Create a site pointing to `C:\ChangeMgmt\public`.
3. Browse to `http://localhost`.

## 6) Wiring the UI to a backend (next step)
To connect the UI to SQL Server Express, introduce a backend API (e.g., .NET, Node.js) that:
- Reads connection settings from `appsettings.json` or environment variables.
- Uses parameterized queries or an ORM to manage `db_changerequest`, `changetask`, and approvals.
- Exposes REST endpoints for the UI to call.

## 7) Admin settings page
Use `public/admin.html` as the admin console mockup for:
- Managing the SQL connection string.
- Testing connectivity.
- Managing hosting service status and roles.

## 8) Login page
Use `public/login.html` as the sign-in mockup, wired to your identity provider (Entra ID or local AD) once the backend is implemented.
