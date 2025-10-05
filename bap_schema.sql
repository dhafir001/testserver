-- SQL schema for the Sistem Informasi Manajemen Jadwal BAP.
--
-- This schema normalizes the data captured by the web forms
-- found in `ajukan.html`, `status.html`, and `admin.html`.  It
-- replaces the previous JSON/localStorage backend with a proper
-- relational database.  The database is designed with SQLite
-- syntax but should also work on most SQL engines with minor
-- adjustments (e.g. remove `AUTOINCREMENT` for MySQL).

--
-- Table: users
-- Stores administrative users who can log into the dashboard.  In
-- a simple deployment you might seed this table with a single
-- admin account (`username`='admin', `password_hash`='...') and
-- optionally store multiple roles.  Passwords should be hashed
-- using a secure algorithm (e.g. bcrypt) on the application side
-- before inserting into this table.

CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT    NOT NULL UNIQUE,
    password_hash   TEXT    NOT NULL,
    role            TEXT    NOT NULL DEFAULT 'admin',
    created_at      DATETIME NOT NULL DEFAULT (datetime('now')),
    updated_at      DATETIME NOT NULL DEFAULT (datetime('now'))
);

--
-- Table: requests
-- Each row represents a BAP request submitted through the
-- applicant form.  The `id` is stored as a UUID (text) to
-- simplify client‑side generation.  `nomor_permohonan` is the
-- human‑readable identifier (e.g. BAP-2025-ABCDE) and is marked
-- unique so that no two requests share the same code.
--
-- The `status` column captures the current state of the request:
--   • 'pending'       – waiting for admin review (default)
--   • 'approved'      – accepted by an admin
--   • 'rejected'      – declined by an admin
--   • 'rescheduled'   – applicant needs to submit another schedule
-- Additional statuses may be added as needed.  The
-- `catatan_admin` field stores any remarks from administrators.
--
-- `lampiran` stores the original filename of the uploaded KTP
-- scan.  `file_path` stores the server path where the file was
-- saved.  If you prefer to store attachments in a separate table
-- (see below), you can remove `file_path` here and reference the
-- `attachments` table instead.

CREATE TABLE IF NOT EXISTS requests (
    id               TEXT    PRIMARY KEY,
    nomor_permohonan TEXT    NOT NULL UNIQUE,
    nama             TEXT    NOT NULL,
    tanggal_lahir    DATE    NOT NULL,
    nomor_hp         TEXT    NOT NULL,
    email            TEXT,
    paspor           TEXT    NOT NULL,
    tujuan           TEXT    NOT NULL,
    lampiran         TEXT,
    file_path        TEXT,
    status           TEXT    NOT NULL DEFAULT 'pending',
    catatan_admin    TEXT,
    created_at       DATETIME NOT NULL DEFAULT (datetime('now')),
    updated_at       DATETIME NOT NULL DEFAULT (datetime('now'))
);

--
-- Table: schedules
-- Stores appointment information associated with a request.  A
-- request may have zero or one schedule.  Separating the
-- schedule into its own table allows the request record to remain
-- immutable even if the appointment details change.  Use a
-- `UNIQUE(request_id)` constraint to ensure a one‑to‑one
-- relationship.  If you foresee multiple appointments per
-- request, remove the unique constraint.

CREATE TABLE IF NOT EXISTS schedules (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id    TEXT    NOT NULL,
    tanggal       DATE,
    jam_mulai     TIME,
    jam_selesai   TIME,
    lokasi        TEXT,
    petugas       TEXT,
    created_at    DATETIME NOT NULL DEFAULT (datetime('now')),
    updated_at    DATETIME NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE,
    UNIQUE (request_id)
);

--
-- Table: attachments
-- Provides a place to store multiple uploaded files per request.
-- Each attachment references the request via `request_id`, stores
-- the original filename and the server file path.  The
-- `uploaded_at` timestamp records when the file was received.

CREATE TABLE IF NOT EXISTS attachments (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id   TEXT    NOT NULL,
    file_name    TEXT    NOT NULL,
    file_path    TEXT    NOT NULL,
    uploaded_at  DATETIME NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE
);

--
-- Table: status_log
-- Tracks every status change for a request.  Whenever an admin
-- updates the `status` or modifies the schedule, the
-- application should insert a new row into this table.  This
-- audit trail is useful for troubleshooting and accountability.

CREATE TABLE IF NOT EXISTS status_log (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id   TEXT    NOT NULL,
    old_status   TEXT,
    new_status   TEXT NOT NULL,
    changed_by   INTEGER,
    changed_at   DATETIME NOT NULL DEFAULT (datetime('now')),
    notes        TEXT,
    FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id)
);

--
-- Optional: seed an initial admin account.  Replace the
-- placeholder password hash with one generated by your
-- application.  The following example uses a bcrypt hash for
-- password '12345'.  To generate a hash in Python:
--    import bcrypt; bcrypt.hashpw(b'12345', bcrypt.gensalt()).decode('utf-8')
--
-- INSERT INTO users (username, password_hash, role) VALUES
--     ('admin', '$2b$12$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'admin');
