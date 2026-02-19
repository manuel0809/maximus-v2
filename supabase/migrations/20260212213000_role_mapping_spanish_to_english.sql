-- Migration: Role Mapping for Spanish to English
-- Purpose: Map Spanish role names from UI to English database values
-- Timestamp: 20260212213000 (higher than existing migrations)

-- Update trigger function to map Spanish roles to English
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role_value TEXT;
    mapped_role public.user_role;
BEGIN
    -- Get role from metadata
    user_role_value := COALESCE(NEW.raw_user_meta_data->>'role', 'cliente');
    
    -- Map Spanish roles to English database values
    CASE user_role_value
        WHEN 'cliente' THEN mapped_role := 'client'::public.user_role;
        WHEN 'administrador' THEN mapped_role := 'admin'::public.user_role;
        WHEN 'client' THEN mapped_role := 'client'::public.user_role;
        WHEN 'admin' THEN mapped_role := 'admin'::public.user_role;
        WHEN 'driver' THEN mapped_role := 'driver'::public.user_role;
        ELSE mapped_role := 'client'::public.user_role;
    END CASE;
    
    -- Insert user profile with mapped role
    INSERT INTO public.user_profiles (id, email, full_name, role, phone, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        mapped_role,
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Update is_admin function to check for both Spanish and English role values
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (
        au.raw_user_meta_data->>'role' IN ('admin', 'administrador')
        OR au.raw_app_meta_data->>'role' IN ('admin', 'administrador')
    )
)
$$;