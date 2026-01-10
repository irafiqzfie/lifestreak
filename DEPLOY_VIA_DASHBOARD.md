# QUICK FIX: Deploy Edge Function via Supabase Dashboard

The CLI deployment failed. Use the Dashboard instead (easier):

## Step 1: Go to Edge Functions
https://app.supabase.com/project/ovjhpwaraktkrmgpdwyn/functions

## Step 2: Create New Function
1. Click **"Create a new function"**
2. Name: `delete-account`
3. Click **"Create function"**

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Prefer Authorization header, fall back to body token
    const authHeader = req.headers.get('Authorization')
    let token = authHeader?.replace('Bearer ', '')

    if (!token) {
      const body = await req.json().catch(() => ({}))
      token = body?.token
    }

    if (!token) {
      return new Response(
        JSON.stringify({ error: 'No token provided' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
      return new Response(
        JSON.stringify({ error: 'Failed to delete user' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: 'Server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Unable to delete account. Please try again.' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
```

## Step 4: Deploy
1. Click **"Deploy"** button (top right)
2. Wait for "Successfully deployed"
3. Close the editor

## Step 5: Test in Your App
1. Refresh your Flutter app
2. Go to Settings → Delete Account
3. Confirm deletion
4. Should work now!

---

**Direct link**: https://app.supabase.com/project/ovjhpwaraktkrmgpdwyn/functions
