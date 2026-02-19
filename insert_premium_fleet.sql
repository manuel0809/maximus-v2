DO $$
DECLARE
    premium_cat_id UUID;
BEGIN
    -- Get or create Premium Transport category
    INSERT INTO public.vehicle_categories (name, description, sort_order)
    VALUES ('Premium Transport', 'Servicio de transporte de lujo con conductor, ideal para eventos y traslados VIP.', 0)
    ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description
    RETURNING id INTO premium_cat_id;

    -- VEHÍCULO T1 — GMC YUKON 2026
    INSERT INTO public.vehicles (category_id, name, brand, model, year, color, transmission, fuel_type, seats, price_per_day, image_url, features, metadata, service_rates)
    VALUES (
        premium_cat_id,
        'GMC Yukon T1',
        'GMC',
        'Yukon Denali Ultimate',
        2026,
        'Negro',
        'automatic',
        'gasoline',
        7,
        65.00,
        'https://images.unsplash.com/photo-1621932953986-15fcf084da0f?auto=format&fit=crop&q=80&w=1000',
        ARRAY['WiFi', 'Pantalla 12.6"', 'Asientos de cuero con masaje', 'Asientos calefacción', 'Sunroof panorámico', 'Carga inalámbrica', 'Apertura de puerta'],
        '{"bags": 5, "premium_audio": true}'::jsonb,
        '{
            "black_suv": {"base": 65, "per_km": 3.50, "min_tariff": 75, "msg": "Cancelación gratis hasta 1h antes"},
            "hourly": {"unit": 100, "min_hours": 3, "tiers": {"4h": 380, "8h": 700, "12h": 950}, "night_surcharge": 0.25},
            "event": {"tiers": {"4h": 500, "6h": 700, "8h": 900, "12h": 1200}}
        }'::jsonb
    );

    -- VEHÍCULO T2 — CHEVROLET SUBURBAN RST 2025
    INSERT INTO public.vehicles (category_id, name, brand, model, year, color, transmission, fuel_type, seats, price_per_day, image_url, features, metadata, service_rates)
    VALUES (
        premium_cat_id,
        'Chevrolet Suburban T2',
        'Chevrolet',
        'Suburban RST',
        2025,
        'Negro',
        'automatic',
        'gasoline',
        7,
        60.00,
        'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=1000',
        ARRAY['WiFi', 'Pantalla', 'Asientos de cuero', 'Asientos calefacción', 'Sunroof', 'Apertura de puerta'],
        '{"bags": 5}'::jsonb,
        '{
            "black_suv": {"base": 60, "per_km": 3.20, "min_tariff": 70, "msg": "Cancelación gratis hasta 1h antes"},
            "hourly": {"unit": 90, "min_hours": 3, "tiers": {"4h": 340, "8h": 640, "12h": 880}, "night_surcharge": 0.25},
            "event": {"tiers": {"4h": 450, "6h": 630, "8h": 800, "12h": 1100}}
        }'::jsonb
    );

    -- VEHÍCULO T3 — CADILLAC ESCALADE 2025
    INSERT INTO public.vehicles (category_id, name, brand, model, year, color, transmission, fuel_type, seats, price_per_day, image_url, features, metadata, service_rates)
    VALUES (
        premium_cat_id,
        'Cadillac Escalade T3',
        'Cadillac',
        'Escalade ESV Premium Luxury',
        2025,
        'Negro',
        'automatic',
        'gasoline',
        7,
        75.00,
        'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?auto=format&fit=crop&q=80&w=1000',
        ARRAY['WiFi alta velocidad', 'OLED 38"', 'Semi-anilina con masaje', 'Asientos calefacción', 'AKG 36 bocinas', 'Alfombra roja', 'Champagne', 'Apertura de puerta'],
        '{"bags": 5, "ultra_premium": true}'::jsonb,
        '{
            "black_suv": {"base": 75, "per_km": 4.00, "min_tariff": 90, "msg": "Cancelación gratis hasta 2h antes"},
            "hourly": {"unit": 130, "min_hours": 3, "tiers": {"4h": 480, "8h": 900, "12h": 1200}, "night_surcharge": 0.25},
            "event": {"tiers": {"4h": 650, "6h": 900, "8h": 1150, "12h": 1600}}
        }'::jsonb
    );

END $$;
