-- Migration: Ratings & Reviews System
-- Purpose: Enable comprehensive feedback management for completed trips with photo documentation and historical tracking

-- 1. Types
DROP TYPE IF EXISTS public.service_category CASCADE;
CREATE TYPE public.service_category AS ENUM ('punctuality', 'cleanliness', 'professionalism', 'vehicle_condition');

DROP TYPE IF EXISTS public.trip_status CASCADE;
CREATE TYPE public.trip_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

-- 2. Core Tables

-- Completed trips table (for linking reviews to trips)
DO $$
BEGIN
    -- Create trips table if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'trips') THEN
        CREATE TABLE public.trips (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
            driver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
            service_type TEXT NOT NULL,
            vehicle_type TEXT,
            pickup_location TEXT NOT NULL,
            dropoff_location TEXT NOT NULL,
            trip_date TIMESTAMPTZ NOT NULL,
            duration_minutes INTEGER,
            distance_km DECIMAL(10, 2),
            cost DECIMAL(10, 2),
            status public.trip_status DEFAULT 'scheduled'::public.trip_status,
            completed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
    ELSE
        -- Add missing columns if table exists
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'status') THEN
            ALTER TABLE public.trips ADD COLUMN status public.trip_status DEFAULT 'scheduled'::public.trip_status;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'user_id') THEN
            ALTER TABLE public.trips ADD COLUMN user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'driver_id') THEN
            ALTER TABLE public.trips ADD COLUMN driver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'service_type') THEN
            ALTER TABLE public.trips ADD COLUMN service_type TEXT NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'vehicle_type') THEN
            ALTER TABLE public.trips ADD COLUMN vehicle_type TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'pickup_location') THEN
            ALTER TABLE public.trips ADD COLUMN pickup_location TEXT NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'dropoff_location') THEN
            ALTER TABLE public.trips ADD COLUMN dropoff_location TEXT NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'trip_date') THEN
            ALTER TABLE public.trips ADD COLUMN trip_date TIMESTAMPTZ NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'duration_minutes') THEN
            ALTER TABLE public.trips ADD COLUMN duration_minutes INTEGER;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'distance_km') THEN
            ALTER TABLE public.trips ADD COLUMN distance_km DECIMAL(10, 2);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'cost') THEN
            ALTER TABLE public.trips ADD COLUMN cost DECIMAL(10, 2);
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'completed_at') THEN
            ALTER TABLE public.trips ADD COLUMN completed_at TIMESTAMPTZ;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'created_at') THEN
            ALTER TABLE public.trips ADD COLUMN created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'trips' AND column_name = 'updated_at') THEN
            ALTER TABLE public.trips ADD COLUMN updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
        END IF;
    END IF;
END;
$$;

-- Reviews table for storing ratings and feedback
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    overall_rating INTEGER NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
    punctuality_rating INTEGER CHECK (punctuality_rating >= 1 AND punctuality_rating <= 5),
    cleanliness_rating INTEGER CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
    professionalism_rating INTEGER CHECK (professionalism_rating >= 1 AND professionalism_rating <= 5),
    vehicle_condition_rating INTEGER CHECK (vehicle_condition_rating >= 1 AND vehicle_condition_rating <= 5),
    review_text TEXT,
    provider_response TEXT,
    provider_response_at TIMESTAMPTZ,
    is_edited BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trip_id)
);

-- Review photos table for storing multiple images per review
CREATE TABLE IF NOT EXISTS public.review_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    caption TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON public.trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver_id ON public.trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON public.trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_completed_at ON public.trips(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_trip_id ON public.reviews(trip_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_driver_id ON public.reviews(driver_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_review_photos_review_id ON public.review_photos(review_id);

-- 4. Functions (BEFORE RLS policies)

-- Function to calculate average rating for a driver
CREATE OR REPLACE FUNCTION public.get_driver_average_rating(p_driver_id UUID)
RETURNS DECIMAL(3, 2)
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(AVG(overall_rating), 0.0)::DECIMAL(3, 2)
    FROM public.reviews
    WHERE driver_id = p_driver_id;
$$;

-- Function to calculate category average ratings for a user
CREATE OR REPLACE FUNCTION public.get_user_category_averages(p_user_id UUID)
RETURNS TABLE(
    punctuality DECIMAL(3, 2),
    cleanliness DECIMAL(3, 2),
    professionalism DECIMAL(3, 2),
    vehicle_condition DECIMAL(3, 2)
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        COALESCE(AVG(punctuality_rating), 0.0)::DECIMAL(3, 2) AS punctuality,
        COALESCE(AVG(cleanliness_rating), 0.0)::DECIMAL(3, 2) AS cleanliness,
        COALESCE(AVG(professionalism_rating), 0.0)::DECIMAL(3, 2) AS professionalism,
        COALESCE(AVG(vehicle_condition_rating), 0.0)::DECIMAL(3, 2) AS vehicle_condition
    FROM public.reviews
    WHERE user_id = p_user_id;
$$;

-- 5. Enable RLS
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_photos ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies

-- Trips: Users can view their own trips and drivers can view assigned trips
DROP POLICY IF EXISTS "users_view_own_trips" ON public.trips;
CREATE POLICY "users_view_own_trips"
ON public.trips
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR driver_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "users_create_trips" ON public.trips;
CREATE POLICY "users_create_trips"
ON public.trips
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "users_update_own_trips" ON public.trips;
CREATE POLICY "users_update_own_trips"
ON public.trips
FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR driver_id = auth.uid() OR public.is_admin())
WITH CHECK (user_id = auth.uid() OR driver_id = auth.uid() OR public.is_admin());

-- Reviews: Users can view and manage their own reviews
DROP POLICY IF EXISTS "users_view_reviews" ON public.reviews;
CREATE POLICY "users_view_reviews"
ON public.reviews
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR driver_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "users_create_reviews" ON public.reviews;
CREATE POLICY "users_create_reviews"
ON public.reviews
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_reviews" ON public.reviews;
CREATE POLICY "users_update_own_reviews"
ON public.reviews
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_delete_own_reviews" ON public.reviews;
CREATE POLICY "users_delete_own_reviews"
ON public.reviews
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Review photos: Users can manage photos for their own reviews
DROP POLICY IF EXISTS "users_view_review_photos" ON public.review_photos;
CREATE POLICY "users_view_review_photos"
ON public.review_photos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = review_id
        AND (r.user_id = auth.uid() OR r.driver_id = auth.uid() OR public.is_admin())
    )
);

DROP POLICY IF EXISTS "users_create_review_photos" ON public.review_photos;
CREATE POLICY "users_create_review_photos"
ON public.review_photos
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = review_id
        AND r.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "users_delete_review_photos" ON public.review_photos;
CREATE POLICY "users_delete_review_photos"
ON public.review_photos
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = review_id
        AND r.user_id = auth.uid()
    )
);

-- 7. Triggers

-- Trigger to update updated_at timestamp on trips
DROP TRIGGER IF EXISTS update_trips_updated_at ON public.trips;
CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger to update updated_at timestamp on reviews
DROP TRIGGER IF EXISTS update_reviews_updated_at ON public.reviews;
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 8. Mock Data
DO $$
DECLARE
    client_uuid UUID;
    driver_uuid UUID;
    trip1_uuid UUID := gen_random_uuid();
    trip2_uuid UUID := gen_random_uuid();
    trip3_uuid UUID := gen_random_uuid();
    review1_uuid UUID := gen_random_uuid();
    review2_uuid UUID := gen_random_uuid();
BEGIN
    -- Get existing client and driver UUIDs
    SELECT id INTO client_uuid FROM public.user_profiles WHERE email = 'client@maximus.com' LIMIT 1;
    SELECT id INTO driver_uuid FROM public.user_profiles WHERE email = 'driver@maximus.com' LIMIT 1;

    -- Skip if users don't exist
    IF client_uuid IS NULL OR driver_uuid IS NULL THEN
        RAISE NOTICE 'Skipping mock data: Required users not found';
        RETURN;
    END IF;

    -- Insert completed trips
    INSERT INTO public.trips (id, user_id, driver_id, service_type, vehicle_type, pickup_location, dropoff_location, trip_date, duration_minutes, distance_km, cost, status, completed_at)
    VALUES
        (trip1_uuid, client_uuid, driver_uuid, 'Transporte Personal', 'Mercedes-Benz Clase S', 'Aeropuerto Madrid-Barajas', 'Hotel Ritz Madrid', '2026-02-10 14:30:00+00', 45, 18.5, 85.00, 'completed'::public.trip_status, '2026-02-10 15:15:00+00'),
        (trip2_uuid, client_uuid, driver_uuid, 'Alquiler de Coches', 'BMW Serie 7', 'Hotel Ritz Madrid', 'Centro Comercial La Vaguada', '2026-02-08 10:00:00+00', 30, 12.3, 65.00, 'completed'::public.trip_status, '2026-02-08 10:30:00+00'),
        (trip3_uuid, client_uuid, driver_uuid, 'Transporte Personal', 'Audi A8', 'Oficina Central', 'Restaurante DiverXO', '2026-02-05 19:00:00+00', 25, 8.7, 55.00, 'completed'::public.trip_status, '2026-02-05 19:25:00+00')
    ON CONFLICT (id) DO NOTHING;

    -- Insert reviews for completed trips
    INSERT INTO public.reviews (id, trip_id, user_id, driver_id, overall_rating, punctuality_rating, cleanliness_rating, professionalism_rating, vehicle_condition_rating, review_text, created_at)
    VALUES
        (review1_uuid, trip1_uuid, client_uuid, driver_uuid, 5, 5, 5, 5, 5, 'Servicio excepcional. El conductor fue muy profesional y el vehículo estaba impecable. Llegó puntual y el viaje fue muy cómodo.', '2026-02-10 16:00:00+00'),
        (review2_uuid, trip2_uuid, client_uuid, driver_uuid, 4, 4, 5, 4, 4, 'Muy buen servicio en general. El coche estaba limpio y el conductor fue amable. Solo una pequeña demora en la recogida.', '2026-02-08 11:30:00+00')
    ON CONFLICT (trip_id) DO NOTHING;

    -- Insert review photos
    INSERT INTO public.review_photos (review_id, photo_url, caption, display_order)
    VALUES
        (review1_uuid, 'https://images.unsplash.com/photo-1639927659853-4c53905a22ad', 'Interior del Mercedes-Benz Clase S', 1),
        (review1_uuid, 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2', 'Vista exterior del vehículo', 2),
        (review2_uuid, 'https://images.unsplash.com/photo-1555215695-3004980ad54e', 'BMW Serie 7 en el punto de recogida', 1)
    ON CONFLICT DO NOTHING;

END;
$$;