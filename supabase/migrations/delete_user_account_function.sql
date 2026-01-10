-- Enable the necessary extensions
create extension if not exists "uuid-ossp";

-- Function to delete user auth account
-- Note: This app stores data in an external API (api.lifestreak.app), not in Supabase tables.
-- Data deletion should be handled by calling your backend API before calling this function.
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
  
  -- Delete user data from Supabase tables (if any)
  -- Since this app uses an external API for data storage, 
  -- you may not have any Supabase tables to delete from.
  -- If you DO have Supabase tables, add DELETE statements here:
  -- 
  -- Example (uncomment and modify if you have Supabase tables):
  -- delete from public.user_profiles where user_id = user_id;
  -- delete from public.user_settings where user_id = user_id;
  
  -- Delete the auth user (this is the main operation for this app)
  delete from auth.users where id = user_id;
  
  return json_build_object('success', true);
exception
  when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function delete_user_account() to authenticated;
