CREATE TABLE notes (
    id TEXT PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    scope TEXT,
    start_date TEXT,
    end_date TEXT,
    CHECK ((start_date IS NULL) = (end_date IS NULL))
);

CREATE UNIQUE INDEX notes_scope_period ON notes (scope, start_date, end_date) WHERE scope IS NOT NULL;

CREATE INDEX notes_dates ON notes (start_date, end_date);
