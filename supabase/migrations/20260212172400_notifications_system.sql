-- Migration: Real-Time Push Notifications System
-- Purpose: Enable comprehensive push notification management for booking updates, driver assignments, trip completions, and promotions

-- 1. Types
DROP TYPE IF EXISTS public.notification_type CASCADE;
CREATE TYPE public.notification_type AS ENUM ('booking_status', 'driver_assigned', 'trip_completed', 'promotion');

DROP TYPE IF EXISTS public.notification_priority CASCADE;
CREATE TYPE public.notification_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- 2. Core Tables

-- Notifications table for storing all user notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    type public.notification_type NOT NULL,
    priority public.notification_priority DEFAULT 'medium'::public.notification_priority,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Notification preferences table for user settings
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    
    -- Booking notifications
    booking_confirmations BOOLEAN DEFAULT true,
    booking_cancellations BOOLEAN DEFAULT true,
    booking_modifications BOOLEAN DEFAULT true,
    booking_payment_receipts BOOLEAN DEFAULT true,
    booking_status_updates BOOLEAN DEFAULT true,
    booking_sound_enabled BOOLEAN DEFAULT true,
    booking_vibration_enabled BOOLEAN DEFAULT true,
    
    -- Driver notifications
    driver_assignment_alerts BOOLEAN DEFAULT true,
    driver_arrival_notifications BOOLEAN DEFAULT true,
    driver_location_updates BOOLEAN DEFAULT true,
    driver_communication_requests BOOLEAN DEFAULT true,
    driver_lead_time_minutes INTEGER DEFAULT 10,
    driver_sound_enabled BOOLEAN DEFAULT true,
    driver_vibration_enabled BOOLEAN DEFAULT true,
    
    -- Trip completion notifications
    trip_completion_alerts BOOLEAN DEFAULT true,
    trip_rating_reminders BOOLEAN DEFAULT true,
    trip_receipt_delivery BOOLEAN DEFAULT true,
    trip_sound_enabled BOOLEAN DEFAULT true,
    trip_vibration_enabled BOOLEAN DEFAULT true,
    
    -- Promotional notifications
    promo_enabled BOOLEAN DEFAULT true,
    promo_frequency TEXT DEFAULT 'immediate',
    promo_discounts BOOLEAN DEFAULT true,
    promo_new_services BOOLEAN DEFAULT true,
    promo_special_events BOOLEAN DEFAULT true,
    promo_sound_enabled BOOLEAN DEFAULT false,
    promo_vibration_enabled BOOLEAN DEFAULT false,
    
    -- Advanced settings
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    quiet_hours_weekdays_only BOOLEAN DEFAULT false,
    bypass_quiet_hours_urgent BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON public.notification_preferences(user_id);

-- 4. Functions (BEFORE RLS policies)

-- Function to create default notification preferences for new users
CREATE OR REPLACE FUNCTION public.create_default_notification_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Function to update updated_at timestamp for preferences
CREATE OR REPLACE FUNCTION public.update_notification_preferences_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(notification_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true, read_at = CURRENT_TIMESTAMP
    WHERE id = notification_id AND user_id = auth.uid();
END;
$$;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_notification_count()
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.notifications
    WHERE user_id = auth.uid() AND is_read = false;
$$;

-- 5. Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies

-- Notifications: Users can view and manage their own notifications
DROP POLICY IF EXISTS "users_view_own_notifications" ON public.notifications;
CREATE POLICY "users_view_own_notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notifications;
CREATE POLICY "users_update_own_notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_delete_own_notifications" ON public.notifications;
CREATE POLICY "users_delete_own_notifications"
ON public.notifications
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_notifications" ON public.notifications;
CREATE POLICY "system_insert_notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Notification preferences: Users can manage their own preferences
DROP POLICY IF EXISTS "users_manage_own_preferences" ON public.notification_preferences;
CREATE POLICY "users_manage_own_preferences"
ON public.notification_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers

-- Trigger to create default notification preferences when user profile is created
DROP TRIGGER IF EXISTS create_notification_preferences_on_user_profile ON public.user_profiles;
CREATE TRIGGER create_notification_preferences_on_user_profile
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.create_default_notification_preferences();

-- Trigger to update updated_at timestamp on preferences
DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON public.notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
    BEFORE UPDATE ON public.notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION public.update_notification_preferences_updated_at();

-- 8. Mock Data
DO $$
DECLARE
    existing_client_id UUID;
    existing_driver_id UUID;
    existing_admin_id UUID;
BEGIN
    -- Get existing users
    SELECT id INTO existing_client_id FROM public.user_profiles WHERE role = 'client' LIMIT 1;
    SELECT id INTO existing_driver_id FROM public.user_profiles WHERE role = 'driver' LIMIT 1;
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    
    IF existing_client_id IS NOT NULL THEN
        -- Create notification preferences for client (if not exists)
        INSERT INTO public.notification_preferences (user_id)
        VALUES (existing_client_id)
        ON CONFLICT (user_id) DO NOTHING;
        
        -- Create sample notifications for client
        INSERT INTO public.notifications (user_id, type, priority, title, body, data, is_read, created_at) VALUES
            (existing_client_id, 'booking_status'::public.notification_type, 'high'::public.notification_priority,
             'Reserva Confirmada',
             'Su reserva para el servicio de transporte personal ha sido confirmada para el 15 de febrero a las 10:00 AM.',
             jsonb_build_object('booking_id', gen_random_uuid(), 'service_type', 'personal_transport', 'date', '2026-02-15', 'time', '10:00'),
             false, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
            (existing_client_id, 'driver_assigned'::public.notification_type, 'high'::public.notification_priority,
             'Conductor Asignado',
             'Juan Pérez ha sido asignado como su conductor. Llegará en 15 minutos.',
             jsonb_build_object('driver_id', COALESCE(existing_driver_id, gen_random_uuid()), 'driver_name', 'Juan Pérez', 'eta_minutes', 15, 'vehicle', 'Mercedes-Benz S-Class'),
             false, CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
            (existing_client_id, 'trip_completed'::public.notification_type, 'medium'::public.notification_priority,
             'Viaje Completado',
             'Su viaje ha sido completado exitosamente. Por favor califique su experiencia.',
             jsonb_build_object('trip_id', gen_random_uuid(), 'duration_minutes', 45, 'distance_km', 32.5, 'cost', 85.00),
             true, CURRENT_TIMESTAMP - INTERVAL '1 day'),
            (existing_client_id, 'promotion'::public.notification_type, 'low'::public.notification_priority,
             'Oferta Especial: 20% de Descuento',
             'Disfrute de un 20% de descuento en su próximo alquiler de vehículo de lujo. Válido hasta el 28 de febrero.',
             jsonb_build_object('promo_code', 'LUXURY20', 'discount_percent', 20, 'valid_until', '2026-02-28', 'service_type', 'car_rental'),
             false, CURRENT_TIMESTAMP - INTERVAL '3 hours'),
            (existing_client_id, 'booking_status'::public.notification_type, 'medium'::public.notification_priority,
             'Recordatorio de Pago',
             'El pago de su reserva ha sido procesado exitosamente. Recibo enviado a su correo.',
             jsonb_build_object('payment_id', gen_random_uuid(), 'amount', 85.00, 'method', 'credit_card'),
             true, CURRENT_TIMESTAMP - INTERVAL '2 days')
        ON CONFLICT (id) DO NOTHING;
    END IF;
    
    IF existing_driver_id IS NOT NULL THEN
        -- Create notification preferences for driver
        INSERT INTO public.notification_preferences (user_id)
        VALUES (existing_driver_id)
        ON CONFLICT (user_id) DO NOTHING;
        
        -- Create sample notifications for driver
        INSERT INTO public.notifications (user_id, type, priority, title, body, data, is_read, created_at) VALUES
            (existing_driver_id, 'booking_status'::public.notification_type, 'high'::public.notification_priority,
             'Nueva Asignación de Servicio',
             'Se le ha asignado un nuevo servicio de transporte. Recoja al cliente en Calle 8, Miami Beach.',
             jsonb_build_object('booking_id', gen_random_uuid(), 'client_name', 'Carlos Martínez', 'pickup_location', 'Calle 8, Miami Beach', 'pickup_time', '10:00'),
             false, CURRENT_TIMESTAMP - INTERVAL '1 hour')
        ON CONFLICT (id) DO NOTHING;
    END IF;
    
    IF existing_admin_id IS NOT NULL THEN
        -- Create notification preferences for admin
        INSERT INTO public.notification_preferences (user_id)
        VALUES (existing_admin_id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock notification data insertion failed: %', SQLERRM;
END $$;