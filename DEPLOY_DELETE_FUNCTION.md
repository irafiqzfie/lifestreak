# Fix: Deploy Delete Account Function to Supabase

## The Error You're Seeing
```
Could not find the function public.delete_user_account without parameters
```

This means the SQL function hasn't been created in your Supabase database yet.

## Quick Fix (2 minutes)

### Step 1: Copy the SQL
The SQL code is in: `supabase/migrations/delete_user_account_function.sql`

Or copy this directly:

```sql
-- Enable the necessary extensions
create extension if not exists "uuid-ossp";

-- Function to delete user auth account
create or replace function delete_user_account()
returns json
language plpgsql
security definer
as $$
declare
  user_id uuid;
  result json;
begin
  -- Get the current user's ID
  user_id := auth.uid();
  
  -- Check if user is authenticated
  if user_id is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;
  
  -- Delete the auth user
  delete from auth.users where id = user_id;
  
  return json_build_object('success', true);
exception
  when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function delete_user_account() to authenticated;
```

### Step 2: Deploy to Supabase
1. Go to: https://app.supabase.com/project/ovjhpwaraktkrmgpdwyn/sql/new
2. Paste the SQL above
3. Click **RUN** (or press Ctrl+Enter)
4. Wait for "Success. No rows returned"

### Step 3: Test Again
1. Refresh your app
2. Try deleting account again
3. It should work now!

## Verify It Worked
In Supabase SQL Editor, run:
```sql
select proname from pg_proc where proname = 'delete_user_account';
```

Should return: `delete_user_account`

---

**That's it!** The function will now exist and your delete account feature will work.
