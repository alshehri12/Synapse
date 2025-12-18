# 🗑️ Quick Guide: Delete User from Supabase

## User to Delete: xmx1000@gmail.com

---

## 🚀 Easiest Method (One Command)

### Step 1: Open Supabase SQL Editor

1. Go to https://supabase.com/dashboard
2. Select your Synapse project
3. Click **SQL Editor** in left sidebar
4. Click **New Query**

### Step 2: Paste and Run This

```sql
-- Delete user xmx1000@gmail.com
DELETE FROM auth.users
WHERE email = 'xmx1000@gmail.com';
```

### Step 3: Click "Run" (or press Cmd + Enter)

✅ Done! User and all related data deleted.

---

## ✅ Verify Deletion

Run this to confirm user is gone:

```sql
SELECT * FROM auth.users WHERE email = 'xmx1000@gmail.com';
```

Should return **0 rows** = User deleted successfully! ✅

---

## 🆘 If You Get an Error

### Error: "Permission denied" or "violates foreign key constraint"

Use this more detailed script instead:

```sql
DO $$
DECLARE
    target_user_id uuid;
BEGIN
    -- Get user ID
    SELECT id INTO target_user_id
    FROM auth.users
    WHERE email = 'xmx1000@gmail.com';

    IF target_user_id IS NOT NULL THEN
        -- Delete related data first
        DELETE FROM public.user_profiles WHERE user_id = target_user_id;
        DELETE FROM public.pod_members WHERE user_id = target_user_id;
        DELETE FROM public.idea_sparks WHERE user_id = target_user_id;
        DELETE FROM public.idea_comments WHERE user_id = target_user_id;
        DELETE FROM public.idea_votes WHERE user_id = target_user_id;

        -- Delete auth user
        DELETE FROM auth.users WHERE id = target_user_id;

        RAISE NOTICE '✅ User deleted successfully';
    ELSE
        RAISE NOTICE '❌ User not found';
    END IF;
END $$;
```

---

## 🔄 Alternative: Just Disable User (Instead of Delete)

If you want to disable the user instead of permanently deleting:

```sql
-- Ban user until year 2099 (effectively permanent)
UPDATE auth.users
SET banned_until = '2099-12-31'
WHERE email = 'xmx1000@gmail.com';
```

User won't be able to login, but data is preserved.

---

## 📝 Summary

**Quick Delete:**
1. Supabase Dashboard → SQL Editor
2. `DELETE FROM auth.users WHERE email = 'xmx1000@gmail.com';`
3. Run
4. Done! ✅

See `delete_user.sql` for more detailed options.
