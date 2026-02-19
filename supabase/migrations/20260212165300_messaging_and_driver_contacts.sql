-- Migration: Messaging System and Driver Contact Management
-- Purpose: Enable real-time messaging between clients and drivers, and admin management of driver phone numbers

-- 1. Types
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('client', 'driver', 'admin');

DROP TYPE IF EXISTS public.message_status CASCADE;
CREATE TYPE public.message_status AS ENUM ('sent', 'delivered', 'read');

-- 2. Core Tables

-- User profiles table (linked to auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'client'::public.user_role,
    phone TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Driver contact information (managed by admin)
CREATE TABLE IF NOT EXISTS public.driver_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(driver_id)
);

-- Messages table for client-driver communication
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status public.message_status DEFAULT 'sent'::public.message_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMPTZ,
    CONSTRAINT different_sender_receiver CHECK (sender_id != receiver_id)
);

-- Conversation tracking (for easier querying)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, driver_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_driver_contacts_driver_id ON public.driver_contacts(driver_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_client_id ON public.conversations(client_id);
CREATE INDEX IF NOT EXISTS idx_conversations_driver_id ON public.conversations(driver_id);

-- 4. Functions (BEFORE RLS policies)

-- Trigger function to create user_profiles when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, phone, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client'::public.user_role),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function to check if user is admin (for RLS policies)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (au.raw_user_meta_data->>'role' = 'admin'
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies

-- User profiles: Users can view their own profile, admins can view all
DROP POLICY IF EXISTS "users_view_own_profile" ON public.user_profiles;
CREATE POLICY "users_view_own_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
CREATE POLICY "users_update_own_profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "admins_manage_all_profiles" ON public.user_profiles;
CREATE POLICY "admins_manage_all_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Driver contacts: Only admins can manage
DROP POLICY IF EXISTS "admins_manage_driver_contacts" ON public.driver_contacts;
CREATE POLICY "admins_manage_driver_contacts"
ON public.driver_contacts
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "drivers_view_own_contact" ON public.driver_contacts;
CREATE POLICY "drivers_view_own_contact"
ON public.driver_contacts
FOR SELECT
TO authenticated
USING (driver_id = auth.uid());

-- Messages: Users can view messages they sent or received
DROP POLICY IF EXISTS "users_view_own_messages" ON public.messages;
CREATE POLICY "users_view_own_messages"
ON public.messages
FOR SELECT
TO authenticated
USING (sender_id = auth.uid() OR receiver_id = auth.uid());

DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_messages" ON public.messages;
CREATE POLICY "users_update_own_messages"
ON public.messages
FOR UPDATE
TO authenticated
USING (receiver_id = auth.uid())
WITH CHECK (receiver_id = auth.uid());

-- Conversations: Users can view conversations they are part of
DROP POLICY IF EXISTS "users_view_own_conversations" ON public.conversations;
CREATE POLICY "users_view_own_conversations"
ON public.conversations
FOR SELECT
TO authenticated
USING (client_id = auth.uid() OR driver_id = auth.uid());

DROP POLICY IF EXISTS "users_create_conversations" ON public.conversations;
CREATE POLICY "users_create_conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid() OR driver_id = auth.uid());

-- 7. Triggers

-- Trigger to create user_profiles when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Triggers to update updated_at timestamp
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_driver_contacts_updated_at ON public.driver_contacts;
CREATE TRIGGER update_driver_contacts_updated_at
    BEFORE UPDATE ON public.driver_contacts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 8. Mock Data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    client_uuid UUID := gen_random_uuid();
    driver_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users (trigger creates user_profiles automatically)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@maximus.com', crypt('Admin123!', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Administrador Maximus', 'role', 'admin', 'phone', '+1 (305) 555-0100'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (client_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'client@maximus.com', crypt('Client123!', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Juan Pérez', 'role', 'client', 'phone', '+1 (305) 555-0101'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (driver_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'driver@maximus.com', crypt('Driver123!', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Carlos Rodríguez', 'role', 'driver', 'phone', '+1 (305) 555-0123'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

    -- Create driver contact (managed by admin)
    INSERT INTO public.driver_contacts (id, driver_id, phone_number, is_active, notes, created_by)
    VALUES (
        gen_random_uuid(),
        driver_uuid,
        '+1 (305) 555-0123',
        true,
        'Conductor principal - Mercedes-Benz S-Class',
        admin_uuid
    )
    ON CONFLICT (driver_id) DO NOTHING;

    -- Create conversation
    INSERT INTO public.conversations (id, client_id, driver_id, last_message_at)
    VALUES (
        gen_random_uuid(),
        client_uuid,
        driver_uuid,
        now()
    )
    ON CONFLICT (client_id, driver_id) DO NOTHING;

    -- Create sample messages
    INSERT INTO public.messages (id, sender_id, receiver_id, content, status, created_at)
    VALUES
        (gen_random_uuid(), client_uuid, driver_uuid, 'Hola, estoy esperando en la entrada principal.', 'read'::public.message_status, now() - interval '10 minutes'),
        (gen_random_uuid(), driver_uuid, client_uuid, 'Perfecto, llego en 5 minutos.', 'read'::public.message_status, now() - interval '8 minutes'),
        (gen_random_uuid(), client_uuid, driver_uuid, 'Gracias, aquí te espero.', 'delivered'::public.message_status, now() - interval '5 minutes')
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;