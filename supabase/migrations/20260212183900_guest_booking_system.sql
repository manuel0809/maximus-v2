-- Migration: Guest Booking System
-- Description: Adds support for guest bookings without user registration
-- Created: 2026-02-12 18:39:00

-- Create guest_bookings table for temporary guest booking data
CREATE TABLE IF NOT EXISTS public.guest_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guest_name TEXT NOT NULL,
  guest_email TEXT NOT NULL,
  guest_phone TEXT NOT NULL,
  service_type TEXT NOT NULL,
  vehicle_type TEXT,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  trip_date TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,
  distance_km NUMERIC(10,2),
  cost NUMERIC(10,2),
  passenger_count INTEGER DEFAULT 1,
  special_requirements TEXT,
  status TEXT DEFAULT 'pending',
  booking_reference TEXT UNIQUE NOT NULL,
  converted_to_user_id UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add index for booking reference lookups
CREATE INDEX IF NOT EXISTS idx_guest_bookings_reference ON public.guest_bookings(booking_reference);
CREATE INDEX IF NOT EXISTS idx_guest_bookings_email ON public.guest_bookings(guest_email);
CREATE INDEX IF NOT EXISTS idx_guest_bookings_status ON public.guest_bookings(status);

-- Enable RLS
ALTER TABLE public.guest_bookings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for guest_bookings
DO $$ 
BEGIN
  -- Allow anyone to insert guest bookings (no auth required)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'guest_bookings' 
    AND policyname = 'Allow anonymous guest booking creation'
  ) THEN
    CREATE POLICY "Allow anonymous guest booking creation"
      ON public.guest_bookings
      FOR INSERT
      TO anon
      WITH CHECK (true);
  END IF;

  -- Allow admins to view all guest bookings
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'guest_bookings' 
    AND policyname = 'Allow admins to view guest bookings'
  ) THEN
    CREATE POLICY "Allow admins to view guest bookings"
      ON public.guest_bookings
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles
          WHERE user_profiles.id = auth.uid()
          AND user_profiles.role = 'admin'
        )
      );
  END IF;

  -- Allow admins to update guest bookings
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'guest_bookings' 
    AND policyname = 'Allow admins to update guest bookings'
  ) THEN
    CREATE POLICY "Allow admins to update guest bookings"
      ON public.guest_bookings
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles
          WHERE user_profiles.id = auth.uid()
          AND user_profiles.role = 'admin'
        )
      );
  END IF;
END $$;

-- Function to generate unique booking reference
CREATE OR REPLACE FUNCTION public.generate_booking_reference()
RETURNS TEXT AS $$
DECLARE
  ref TEXT;
  exists_check INTEGER;
BEGIN
  LOOP
    ref := 'GB' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    SELECT COUNT(*) INTO exists_check FROM public.guest_bookings WHERE booking_reference = ref;
    EXIT WHEN exists_check = 0;
  END LOOP;
  RETURN ref;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_guest_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_guest_bookings_updated_at_trigger'
  ) THEN
    CREATE TRIGGER update_guest_bookings_updated_at_trigger
      BEFORE UPDATE ON public.guest_bookings
      FOR EACH ROW
      EXECUTE FUNCTION public.update_guest_bookings_updated_at();
  END IF;
END $$;