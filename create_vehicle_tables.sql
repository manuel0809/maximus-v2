-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create vehicle_categories table
CREATE TABLE IF NOT EXISTS public.vehicle_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create vehicles table
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category_id UUID REFERENCES public.vehicle_categories(id),
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER NOT NULL,
    color TEXT,
    transmission TEXT CHECK (transmission IN ('automatic', 'manual')),
    fuel_type TEXT CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid')),
    seats INTEGER NOT NULL,
    doors INTEGER NOT NULL,
    price_per_day DECIMAL(10, 2) NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    features TEXT[], -- Array of strings for features like 'GPS', 'Bluetooth', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create rentals table
CREATE TABLE IF NOT EXISTS public.rentals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id),
    vehicle_id UUID REFERENCES public.vehicles(id),
    pickup_location TEXT NOT NULL,
    dropoff_location TEXT NOT NULL,
    pickup_date TIMESTAMP WITH TIME ZONE NOT NULL,
    dropoff_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled')),
    price_per_day DECIMAL(10, 2) NOT NULL,
    insurance DECIMAL(10, 2) DEFAULT 0,
    total_price DECIMAL(10, 2), -- Calculated field for record
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.vehicle_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;

-- Policies for vehicle_categories (Public read, Admin write)
CREATE POLICY "Public categories are viewable by everyone" ON public.vehicle_categories
    FOR SELECT USING (true);

-- Policies for vehicles (Public read, Admin write)
CREATE POLICY "Public vehicles are viewable by everyone" ON public.vehicles
    FOR SELECT USING (true);

-- Policies for rentals (Users can view/create their own, Admins can view/edit all)
CREATE POLICY "Users can view own rentals" ON public.rentals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own rentals" ON public.rentals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Insert sample data for vehicle_categories
INSERT INTO public.vehicle_categories (name, description, image_url, sort_order)
VALUES
    ('Económico', 'Vehículos compactos y eficientes en combustible ideal para ciudad.', 'https://example.com/economy.png', 1),
    ('SUV', 'Espaciosos y cómodos para viajes familiares o terrenos difíciles.', 'https://example.com/suv.png', 2),
    ('Lujo', 'Viaja con estilo y máximo confort en nuestros vehículos premium.', 'https://example.com/luxury.png', 3),
    ('Deportivo', 'Potencia y diseño para una experiencia de conducción emocionante.', 'https://example.com/sport.png', 4);

-- Insert sample data for vehicles (Needs valid category IDs, so we use a subquery or do it dynamically in a real seed script, but for simplicity here we assume the above inserts worked sequentially or use a DO block)

DO $$
DECLARE
    econ_id UUID;
    suv_id UUID;
    lux_id UUID;
    sport_id UUID;
BEGIN
    SELECT id INTO econ_id FROM public.vehicle_categories WHERE name = 'Económico' LIMIT 1;
    SELECT id INTO suv_id FROM public.vehicle_categories WHERE name = 'SUV' LIMIT 1;
    SELECT id INTO lux_id FROM public.vehicle_categories WHERE name = 'Lujo' LIMIT 1;
    SELECT id INTO sport_id FROM public.vehicle_categories WHERE name = 'Deportivo' LIMIT 1;

    INSERT INTO public.vehicles (category_id, name, brand, model, year, transmission, fuel_type, seats, doors, price_per_day, image_url, features)
    VALUES
        (econ_id, 'Toyota Yaris', 'Toyota', 'Yaris', 2023, 'automatic', 'gasoline', 5, 4, 35.00, 'https://example.com/yaris.png', ARRAY['Bluetooth', 'USB', 'AC']),
        (suv_id, 'Toyota RAV4', 'Toyota', 'RAV4', 2024, 'automatic', 'hybrid', 5, 4, 65.00, 'https://example.com/rav4.png', ARRAY['Bluetooth', 'GPS', 'Leather Seats', 'Sunroof']),
        (lux_id, 'Mercedes-Benz C-Class', 'Mercedes-Benz', 'C300', 2023, 'automatic', 'gasoline', 5, 4, 120.00, 'https://example.com/c300.png', ARRAY['Premium Audio', 'Heated Seats', 'Navigation', 'Autopilot']),
        (sport_id, 'Ford Mustang', 'Ford', 'Mustang GT', 2024, 'automatic', 'gasoline', 4, 2, 95.00, 'https://example.com/mustang.png', ARRAY['V8 Engine', 'Sport Mode', 'Convertible']);
END $$;
