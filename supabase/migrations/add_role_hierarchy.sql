-- =====================================================
-- MIGRATION: Add Complete Role Hierarchy System
-- Date: 2026-02-15
-- Description: Updates user_profiles table to support
--              12-role hierarchy with RLS policies
-- =====================================================

-- 1. Update role column to support all new roles
-- =====================================================
ALTER TABLE user_profiles 
  ALTER COLUMN role TYPE text;

-- 2. Add constraint for valid roles
-- =====================================================
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS valid_role_check;

ALTER TABLE user_profiles
  ADD CONSTRAINT valid_role_check CHECK (
    role IN (
      'super_admin',
      'admin',
      'operations_manager',
      'reservation_operator',
      'assistant',
      'dispatcher',
      'fleet_manager',
      'mechanic',
      'finance_manager',
      'driver',
      'client',
      'client_vip',
      'client_corp'
    )
  );

-- 3. Migrate existing roles to new values
-- =====================================================
-- Keep existing admin and driver roles as-is
-- Update any 'user' or 'customer' to 'client'
UPDATE user_profiles 
SET role = 'client' 
WHERE role IN ('user', 'customer');

-- 4. Add performance index
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_role 
ON user_profiles(role);

-- 5. Add additional useful columns
-- =====================================================
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- 6. Create index for active users
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_active 
ON user_profiles(is_active) WHERE is_active = true;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Super Admin full access" ON user_profiles;
DROP POLICY IF EXISTS "Admin can manage staff" ON user_profiles;
DROP POLICY IF EXISTS "Staff can view other staff" ON user_profiles;
DROP POLICY IF EXISTS "Drivers can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Clients can update own profile" ON user_profiles;

-- Policy 1: Users can view their own profile
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Policy 2: Super Admin has full access to everything
CREATE POLICY "Super Admin full access"
ON user_profiles FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role = 'super_admin' AND is_active = true
  )
);

-- Policy 3: Admin can manage all users except super_admin and other admins
CREATE POLICY "Admin can manage non-admin users"
ON user_profiles FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN ('admin', 'super_admin')
    AND is_active = true
  )
  AND role NOT IN ('super_admin', 'admin')
);

-- Policy 4: Staff can view other staff profiles (read-only)
CREATE POLICY "Staff can view other staff"
ON user_profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN (
      'super_admin', 'admin', 'operations_manager', 
      'fleet_manager', 'finance_manager', 'reservation_operator',
      'assistant', 'dispatcher', 'mechanic'
    )
    AND is_active = true
  )
);

-- Policy 5: Drivers can update their own profile (limited fields)
CREATE POLICY "Drivers can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id AND role = 'driver' AND is_active = true);

-- Policy 6: Clients can update their own profile (limited fields)
CREATE POLICY "Clients can update own profile"
ON user_profiles FOR UPDATE
USING (
  auth.uid() = id 
  AND role IN ('client', 'client_vip', 'client_corp')
  AND is_active = true
);

-- =====================================================
-- HELPER FUNCTIONS FOR RLS
-- =====================================================

-- Function to check if current user has a specific role
CREATE OR REPLACE FUNCTION has_role(required_role text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role = required_role
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is staff
CREATE OR REPLACE FUNCTION is_staff()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN (
      'super_admin', 'admin', 'operations_manager',
      'fleet_manager', 'finance_manager', 'reservation_operator',
      'assistant', 'dispatcher', 'mechanic'
    )
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is admin tier
CREATE OR REPLACE FUNCTION is_admin_tier()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN ('super_admin', 'admin')
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- AUDIT LOG
-- =====================================================
COMMENT ON TABLE user_profiles IS 'User profiles with 12-role hierarchy system';
COMMENT ON COLUMN user_profiles.role IS 'User role: super_admin, admin, operations_manager, reservation_operator, assistant, dispatcher, fleet_manager, mechanic, finance_manager, driver, client, client_vip, client_corp';
COMMENT ON COLUMN user_profiles.is_active IS 'Whether the user account is active';
COMMENT ON COLUMN user_profiles.last_login_at IS 'Timestamp of last successful login';
COMMENT ON COLUMN user_profiles.metadata IS 'Additional user metadata in JSON format';
