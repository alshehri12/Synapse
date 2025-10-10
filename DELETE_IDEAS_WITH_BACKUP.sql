-- 🔒 SAFE VERSION: Delete all ideas with backup
-- This creates backup tables before deletion, so you can restore if needed
-- Run this in Supabase SQL Editor

-- ========================================
-- STEP 1: CREATE BACKUP TABLES
-- ========================================

-- Backup ideas
CREATE TABLE IF NOT EXISTS ideas_backup AS
SELECT * FROM ideas;

-- Backup comments
CREATE TABLE IF NOT EXISTS comments_backup AS
SELECT * FROM comments WHERE idea_id IN (SELECT id FROM ideas);

-- Backup likes
CREATE TABLE IF NOT EXISTS likes_backup AS
SELECT * FROM likes WHERE idea_id IN (SELECT id FROM ideas);

-- Backup favorites
CREATE TABLE IF NOT EXISTS favorites_backup AS
SELECT * FROM favorites WHERE idea_id IN (SELECT id FROM ideas);

-- Backup idea_tags
CREATE TABLE IF NOT EXISTS idea_tags_backup AS
SELECT * FROM idea_tags WHERE idea_id IN (SELECT id FROM ideas);

-- Check backup counts
SELECT
    (SELECT COUNT(*) FROM ideas_backup) as ideas_backed_up,
    (SELECT COUNT(*) FROM comments_backup) as comments_backed_up,
    (SELECT COUNT(*) FROM likes_backup) as likes_backed_up,
    (SELECT COUNT(*) FROM favorites_backup) as favorites_backed_up,
    (SELECT COUNT(*) FROM idea_tags_backup) as idea_tags_backed_up;

-- ========================================
-- STEP 2: DELETE ALL IDEAS (safely)
-- ========================================

-- Delete related data first (to avoid foreign key constraints)
DELETE FROM comments WHERE idea_id IN (SELECT id FROM ideas);
DELETE FROM likes WHERE idea_id IN (SELECT id FROM ideas);
DELETE FROM favorites WHERE idea_id IN (SELECT id FROM ideas);
DELETE FROM idea_tags WHERE idea_id IN (SELECT id FROM ideas);

-- Finally, delete all ideas
DELETE FROM ideas;

-- ========================================
-- STEP 3: VERIFY DELETION
-- ========================================

SELECT
    (SELECT COUNT(*) FROM ideas) as ideas_remaining,
    (SELECT COUNT(*) FROM comments) as comments_remaining,
    (SELECT COUNT(*) FROM likes) as likes_remaining,
    (SELECT COUNT(*) FROM favorites) as favorites_remaining,
    (SELECT COUNT(*) FROM idea_tags) as idea_tags_remaining;
-- All should return 0 (or close to 0 if you have other unrelated data)

-- ========================================
-- OPTIONAL: RESTORE FROM BACKUP (if needed)
-- ========================================

-- Uncomment these lines ONLY if you want to restore:

-- INSERT INTO ideas SELECT * FROM ideas_backup;
-- INSERT INTO comments SELECT * FROM comments_backup;
-- INSERT INTO likes SELECT * FROM likes_backup;
-- INSERT INTO favorites SELECT * FROM favorites_backup;
-- INSERT INTO idea_tags SELECT * FROM idea_tags_backup;

-- ========================================
-- OPTIONAL: DELETE BACKUP TABLES (after you're sure)
-- ========================================

-- Uncomment these lines ONLY after you're 100% sure you don't need the backup:

-- DROP TABLE IF EXISTS ideas_backup;
-- DROP TABLE IF EXISTS comments_backup;
-- DROP TABLE IF EXISTS likes_backup;
-- DROP TABLE IF EXISTS favorites_backup;
-- DROP TABLE IF EXISTS idea_tags_backup;

-- Done! ✅
