-- Migration 007: Seasons table for ranked play
CREATE TABLE IF NOT EXISTS seasons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT FALSE
);

-- Index for quick lookup of active season
CREATE INDEX IF NOT EXISTS idx_seasons_active ON seasons (is_active) WHERE is_active = TRUE;
