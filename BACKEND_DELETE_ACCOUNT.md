# Backend API Implementation for Delete Account

## Overview
The Delete Account feature requires two components:
1. **Backend API Endpoint** (`POST /account/delete`) - Deletes user data from your database
2. **Supabase Function** (`delete_user_account`) - Deletes the auth user

## Backend API Endpoint

### Required Endpoint
Add this endpoint to your backend API at `api.lifestreak.app`:

**Endpoint**: `POST /account/delete`
**Auth**: Bearer token required (same as other endpoints)

### Example Implementation (Node.js/Express)

```javascript
app.post('/account/delete', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id; // From JWT token
    
    // Delete all user data from your database
    // Order matters: delete child records before parent records
    
    // 1. Delete habit logs
    await db.query('DELETE FROM habit_logs WHERE user_id = $1', [userId]);
    
    // 2. Delete sessions
    await db.query('DELETE FROM sessions WHERE user_id = $1', [userId]);
    
    // 3. Delete friend requests
    await db.query('DELETE FROM friend_requests WHERE sender_id = $1 OR receiver_id = $1', [userId]);
    
    // 4. Delete friendships
    await db.query('DELETE FROM friends WHERE user_id = $1 OR friend_id = $1', [userId]);
    
    // 5. Delete habits
    await db.query('DELETE FROM habits WHERE user_id = $1', [userId]);
    
    // 6. Delete user profile (if you have one)
    await db.query('DELETE FROM users WHERE id = $1', [userId]);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting user data:', error);
    res.status(500).json({ error: 'Failed to delete user data' });
  }
});
```

### Security Considerations

1. **Authentication Required**: Endpoint must verify the JWT token
2. **User ID from Token**: NEVER accept user_id as a parameter - get it from the verified JWT
3. **Transaction**: Wrap all deletions in a database transaction for atomicity
4. **Logging**: Log deletion requests for audit trail (but not personal data)

### Testing the Endpoint

```bash
# Get a valid token first (sign in to your app)
TOKEN="your_jwt_token_here"

# Test the delete endpoint
curl -X POST https://api.lifestreak.app/account/delete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# Expected response
{"success": true}
```

## Alternative: If Backend Endpoint Doesn't Exist Yet

The Flutter app is designed to handle the case where the backend endpoint doesn't exist yet:

```dart
try {
  await apiClient.deleteAccount(token: session.token);
} catch (e) {
  // Continue even if API deletion fails
  debugPrint('Backend deletion failed: $e');
}
```

**What This Means**:
- ✅ App won't crash if endpoint is missing
- ✅ Supabase auth user will still be deleted
- ⚠️ Backend data will NOT be deleted (orphaned data)

**For Apple App Review**:
- If your backend doesn't store much user data yet, this might be acceptable
- The auth account deletion is the critical part for App Review
- Add backend endpoint BEFORE production release

## Database Schema Considerations

### Find Your Tables
To determine which tables need deletion, query your database:

```sql
-- PostgreSQL example
SELECT table_name 
FROM information_schema.columns 
WHERE column_name = 'user_id';

-- MySQL example
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME = 'user_id';
```

### Deletion Order
Delete in reverse order of dependencies:
1. Child tables (with foreign keys)
2. Junction tables (many-to-many)
3. Parent tables
4. User table (last)

### Foreign Key Constraints
If you have `ON DELETE CASCADE` configured, you might only need to delete the user record:

```sql
-- If properly configured with cascading deletes
DELETE FROM users WHERE id = $1;
-- This will automatically delete all related records
```

## Testing Checklist

### Backend API Testing
- [ ] Endpoint requires authentication
- [ ] Returns 401 for unauthenticated requests
- [ ] Deletes all user data
- [ ] Returns success response
- [ ] Handles errors gracefully
- [ ] Works in database transaction

### Integration Testing
- [ ] Create test account
- [ ] Add some data (habits, logs)
- [ ] Call delete account from app
- [ ] Verify backend data deleted
- [ ] Verify Supabase auth user deleted
- [ ] Verify app returns to login screen
- [ ] Verify cannot sign in with deleted account

### Apple App Review Simulation
1. Create new account
2. Add test data
3. Navigate to Settings
4. Tap "Delete Account"
5. Confirm deletion
6. Verify:
   - App returns to login
   - Cannot sign in with deleted email
   - All data is gone

## Deployment Steps

### 1. Deploy Backend Endpoint
```bash
# Deploy to your backend server
git add .
git commit -m "Add delete account endpoint"
git push

# Or deploy via your hosting platform (Heroku, Railway, etc.)
```

### 2. Deploy Supabase Function
1. Go to Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste `supabase/migrations/delete_user_account_function.sql`
4. Click Run

### 3. Test End-to-End
1. Build and run the app
2. Create test account
3. Test deletion flow
4. Verify complete data removal

## Monitoring

### Log Deletion Events
```javascript
// In your backend
console.log(`User deletion requested: ${userId} at ${new Date().toISOString()}`);
```

### Track Deletion Stats
```sql
-- Count deletions per day
SELECT DATE(deleted_at), COUNT(*) 
FROM deletion_log 
GROUP BY DATE(deleted_at);
```

## Troubleshooting

### "Endpoint not found" (404)
- Backend doesn't have `/account/delete` endpoint yet
- Deploy the endpoint to your backend
- Or wait - the app will still delete auth user

### "Permission denied" (403)
- JWT token invalid or expired
- Sign out and sign in again
- Check token format in request headers

### "Foreign key constraint" Error
- Deleting in wrong order
- Delete child tables before parent tables
- Or add `ON DELETE CASCADE` to foreign keys

### Data Not Deleted
- Backend endpoint not called
- Check network logs in app
- Verify endpoint is deployed
- Test endpoint directly with curl

## Summary

**Required Components**:
1. ✅ Supabase function (provided in `supabase/migrations/`)
2. ⚠️ Backend API endpoint (you need to implement this)

**Current Status**:
- Flutter app ready
- Supabase function ready
- Backend endpoint needs implementation

**For Apple App Review**:
- Auth deletion is sufficient if you don't have much user data yet
- Full data deletion should be implemented before production release
- Test the complete flow before submitting to App Store

**Next Steps**:
1. Implement backend endpoint at `POST /account/delete`
2. Deploy Supabase function via SQL Editor
3. Test end-to-end deletion
4. Submit to App Store
