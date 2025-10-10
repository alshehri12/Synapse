-- ⚠️ WARNING: This will DELETE ALL IDEAS permanently!
-- Use this to start fresh and remove all test/mistake data
-- Run this in Supabase SQL Editor

-- Step 1: Delete all comments on ideas (to avoid foreign key constraints)
DELETE FROM comments WHERE idea_id IN (SELECT id FROM ideas);

-- Step 2: Delete all likes on ideas
DELETE FROM likes WHERE idea_id IN (SELECT id FROM ideas);

-- Step 3: Delete all favorites
DELETE FROM favorites WHERE idea_id IN (SELECT id FROM ideas);

-- Step 4: Delete all idea_tags relationships
DELETE FROM idea_tags WHERE idea_id IN (SELECT id FROM ideas);

-- Step 5: Finally, delete all ideas
DELETE FROM ideas;

-- Optional: Reset the auto-increment counter (if you want IDs to start from 1 again)
-- ALTER SEQUENCE ideas_id_seq RESTART WITH 1;

-- Verify deletion
SELECT COUNT(*) as total_ideas_remaining FROM ideas;
-- Should return 0

-- Done! All ideas have been deleted.
