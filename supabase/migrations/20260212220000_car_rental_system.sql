-- Car Rental System Migration
-- Creates tables for vehicle categories, vehicles, and rental bookings

-- STEP 1: Create vehicle categories table
CREATE TABLE IF NOT EXISTS public.vehicle_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    base_price_per_day NUMERIC(10,2) NOT NULL,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- STEP 2: Create vehicles table
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.vehicle_categories(id) ON DELETE CASCADE,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER,
    plate TEXT UNIQUE,
    color TEXT,
    seats INTEGER DEFAULT 5,
    transmission TEXT CHECK (transmission IN ('manual', 'automático')),
    fuel_type TEXT CHECK (fuel_type IN ('gasolina', 'diésel', 'híbrido', 'eléctrico')),
    price_per_day NUMERIC(10,2) NOT NULL,
    image_urls TEXT[],
    features TEXT[],
    is_available BOOLEAN DEFAULT true,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- STEP 3: Create rentals table
CREATE TABLE IF NOT EXISTS public.rentals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE CASCADE,
    pickup_location TEXT NOT NULL,
    dropoff_location TEXT NOT NULL,
    pickup_date TIMESTAMPTZ NOT NULL,
    dropoff_date TIMESTAMPTZ NOT NULL,
    total_days INTEGER,
    price_per_day NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2),
    insurance NUMERIC(10,2) DEFAULT 0,
    tax NUMERIC(10,2),
    total NUMERIC(10,2),
    status TEXT DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'confirmada', 'en_curso', 'completada', 'cancelada')),
    payment_status TEXT DEFAULT 'pendiente' CHECK (payment_status IN ('pendiente', 'pagado', 'reembolsado')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- STEP 4: Create indexes
CREATE INDEX IF NOT EXISTS idx_vehicles_category_id ON public.vehicles(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_is_available ON public.vehicles(is_available);
CREATE INDEX IF NOT EXISTS idx_rentals_user_id ON public.rentals(user_id);
CREATE INDEX IF NOT EXISTS idx_rentals_vehicle_id ON public.rentals(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_rentals_status ON public.rentals(status);

-- STEP 5: Create function to calculate rental totals
CREATE OR REPLACE FUNCTION public.calculate_rental_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Calculate total days
    NEW.total_days := EXTRACT(DAY FROM (NEW.dropoff_date - NEW.pickup_date));
    
    -- Calculate subtotal
    NEW.subtotal := NEW.price_per_day * NEW.total_days;
    
    -- Calculate tax (16%)
    NEW.tax := NEW.subtotal * 0.16;
    
    -- Calculate total
    NEW.total := NEW.subtotal + COALESCE(NEW.insurance, 0) + NEW.tax;
    
    RETURN NEW;
END;
$$;

-- STEP 6: Enable RLS
ALTER TABLE public.vehicle_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;

-- STEP 7: Create RLS policies

-- Vehicle categories - viewable by all
DROP POLICY IF EXISTS "categories_viewable_by_all" ON public.vehicle_categories;
CREATE POLICY "categories_viewable_by_all"
ON public.vehicle_categories
FOR SELECT
TO public
USING (true);

-- Vehicles - viewable by all
DROP POLICY IF EXISTS "vehicles_viewable_by_all" ON public.vehicles;
CREATE POLICY "vehicles_viewable_by_all"
ON public.vehicles
FOR SELECT
TO public
USING (true);

-- Rentals - users can view own rentals
DROP POLICY IF EXISTS "users_view_own_rentals" ON public.rentals;
CREATE POLICY "users_view_own_rentals"
ON public.rentals
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Rentals - users can create rentals
DROP POLICY IF EXISTS "users_create_rentals" ON public.rentals;
CREATE POLICY "users_create_rentals"
ON public.rentals
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Rentals - users can update own rentals
DROP POLICY IF EXISTS "users_update_own_rentals" ON public.rentals;
CREATE POLICY "users_update_own_rentals"
ON public.rentals
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- STEP 8: Create trigger for rental calculations
DROP TRIGGER IF EXISTS calculate_rental_totals_trigger ON public.rentals;
CREATE TRIGGER calculate_rental_totals_trigger
BEFORE INSERT OR UPDATE ON public.rentals
FOR EACH ROW
EXECUTE FUNCTION public.calculate_rental_totals();

-- STEP 9: Insert vehicle categories
DO $$
BEGIN
    INSERT INTO public.vehicle_categories (name, description, icon, base_price_per_day, sort_order)
    VALUES
        ('Económico', 'Autos eficientes, ideales para ciudad', '💰', 25.00, 1),
        ('SUV', 'Espacio y comodidad para toda la familia', '🚙', 45.00, 2),
        ('Lujo', 'Experiencia premium con los mejores modelos', '✨', 85.00, 3)
    ON CONFLICT (name) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Category insertion failed: %', SQLERRM;
END $$;

-- STEP 10: Insert sample vehicles
DO $$
DECLARE
    economico_id UUID;
    suv_id UUID;
    lujo_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO economico_id FROM public.vehicle_categories WHERE name = 'Económico' LIMIT 1;
    SELECT id INTO suv_id FROM public.vehicle_categories WHERE name = 'SUV' LIMIT 1;
    SELECT id INTO lujo_id FROM public.vehicle_categories WHERE name = 'Lujo' LIMIT 1;
    
    IF economico_id IS NOT NULL AND suv_id IS NOT NULL AND lujo_id IS NOT NULL THEN
        -- Insert Económico vehicles
        INSERT INTO public.vehicles (category_id, brand, model, year, seats, transmission, fuel_type, price_per_day, features, image_urls, is_available)
        VALUES
            (economico_id, 'Nissan', 'Versa', 2023, 5, 'automático', 'gasolina', 28.00, 
             ARRAY['Aire acondicionado', 'Bluetooth', 'Cámara trasera', 'Económico'], 
             ARRAY['https://images.unsplash.com/photo-1555215695-3004980ad54e'], true),
            (economico_id, 'Chevrolet', 'Onix', 2024, 5, 'manual', 'gasolina', 25.00, 
             ARRAY['Aire acondicionado', 'Dirección hidráulica'], 
             ARRAY['https://images.unsplash.com/photo-1549317661-bd32c8ce0db2'], true),
        
        -- Insert SUV vehicles
            (suv_id, 'Toyota', 'RAV4', 2024, 5, 'automático', 'híbrido', 48.00, 
             ARRAY['Aire acondicionado', 'Bluetooth', 'Cámara 360°', 'Techo panorámico', 'Asientos de cuero'], 
             ARRAY['https://images.unsplash.com/photo-1568844293986-ca9dca6a3e0a'], true),
            (suv_id, 'Honda', 'CR-V', 2023, 7, 'automático', 'gasolina', 45.00, 
             ARRAY['Aire acondicionado', 'Bluetooth', '7 asientos', 'Pantalla táctil'], 
             ARRAY['https://images.unsplash.com/photo-1519641471654-76ce0107ad1b'], true),
        
        -- Insert Lujo vehicles
            (lujo_id, 'Mercedes-Benz', 'Clase C', 2024, 5, 'automático', 'híbrido', 89.00, 
             ARRAY['Asientos de cuero', 'Techo panorámico', 'Asientos calefactados', 'Sonido premium', 'Asistente de conducción'], 
             ARRAY['https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8'], true),
            (lujo_id, 'BMW', 'Serie 3', 2024, 5, 'automático', 'híbrido', 95.00, 
             ARRAY['Cuero', 'Head-up display', 'Sonido Harman Kardon', 'Asientos con masaje'], 
             ARRAY['https://images.unsplash.com/photo-1556189250-72ba954cfc2b'], true)
        ON CONFLICT (plate) DO NOTHING;
    ELSE
        RAISE NOTICE 'Categories not found. Cannot insert vehicles.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Vehicle insertion failed: %', SQLERRM;
END $$;