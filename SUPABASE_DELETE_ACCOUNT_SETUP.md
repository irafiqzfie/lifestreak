# Supabase Account Deletion Setup

## Option 1: Database Function (Recommended)

The SQL function in `supabase/migrations/delete_user_account_function.sql` needs to be run in your Supabase project.

### Steps:
1. Go to **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy and paste the contents of `delete_user_account_function.sql`
4. Click **Run**

### Important:
Update the function to delete from your actual tables. The current function includes example table names that need to be replaced with your real schema.

## Option 2: Edge Function (Alternative)

If you prefer using Edge Functions instead of Database Functions, you can create an Edge Function using the Supabase CLI.

### Required Edge Function Code:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')!
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get user from JWT
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Delete user data (customize based on your schema)
    // await supabaseClient.from('habit_logs').delete().eq('user_id', user.id)
    // await supabaseClient.from('habits').delete().eq('user_id', user.id)
    
    // Delete auth user
    const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

## Which Option to Use?

- **Database Function**: Simpler, no CLI needed, runs in SQL Editor
- **Edge Function**: More flexible, better for complex logic

For most cases, the Database Function (Option 1) is recommended.
