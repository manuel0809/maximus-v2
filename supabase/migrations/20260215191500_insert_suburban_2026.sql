-- Migration: Insert Chevrolet Suburban RST 2026 with Elite Pricing
-- Description: Adds the Suburban RST 2026 as a premium Black SUV with regional, tiered, and fixed-rate pricing models.

DO $$
DECLARE
    suv_id UUID;
BEGIN
    -- Get SUV category ID
    SELECT id INTO suv_id FROM public.vehicle_categories WHERE name = 'SUV' LIMIT 1;

    INSERT INTO public.vehicles (
        category_id, 
        brand, 
        model, 
        year, 
        name, 
        transmission, 
        fuel_type, 
        seats, 
        doors, 
        price_per_day, 
        is_available, 
        status,
        features,
        metadata,
        service_rates
    )
    VALUES (
        suv_id,
        'Chevrolet',
        'Suburban RST',
        2026,
        'Chevrolet Suburban RST 2026',
        'automatic',
        'gasoline',
        7,
        5,
        185.00, -- Daily rental fallback
        true,
        'available',
        ARRAY['Premium Audio', '4G LTE WiFi', 'Leather Seats', 'Black Edition', 'Rear Seat Entertainment'],
        jsonb_build_object(
            'passengers', 7,
            'bags', 5,
            'color', 'Black',
            'interior', 'Jet Black with Victory Red Stitching',
            'engine', '6.2L V8',
            'special_features', ARRAY['Magnetic Ride Control', 'Brembo Brakes', 'Panoramic Sunroof']
        ),
        jsonb_build_object(
            'black_suv_regional', jsonb_build_object(
                'miami_broward', jsonb_build_object(
                    'base', 20.00,
                    'per_mile', 5.25,
                    'min_tariff', 48.00,
                    'waiting_free_mins', 10,
                    'waiting_extra_min', 2.00
                ),
                'orlando', jsonb_build_object(
                    'base', 18.00,
                    'per_mile', 5.00,
                    'min_tariff', 45.00,
                    'waiting_free_mins', 10,
                    'waiting_extra_min', 2.00
                )
            ),
            'airport_fixed', jsonb_build_object(
                'mia', jsonb_build_object(
                    'South Beach', 100,
                    'Downtown / Brickell', 80,
                    'Doral', 68,
                    'Coral Gables', 75,
                    'Coconut Grove', 78,
                    'Aventura', 100,
                    'Sunny Isles', 105,
                    'Key Biscayne', 90,
                    'Kendall', 82,
                    'Homestead', 115,
                    'Wynwood', 75,
                    'Miami Gardens', 90,
                    'Fort Lauderdale', 128,
                    'Hollywood', 105,
                    'Weston', 120,
                    'Port of Miami', 75
                ),
                'fll', jsonb_build_object(
                    'Fort Lauderdale Beach', 58,
                    'Las Olas', 55,
                    'Hollywood', 58,
                    'Hallandale Beach', 65,
                    'Aventura', 80,
                    'South Beach', 125,
                    'Downtown Miami', 120,
                    'Boca Raton', 85,
                    'Pompano Beach', 55,
                    'Weston', 65,
                    'Coral Springs', 70,
                    'Sawgrass Mills', 58,
                    'Port Everglades', 52
                ),
                'mco', jsonb_build_object(
                    'International Drive', 72,
                    'Downtown Orlando', 68,
                    'Walt Disney World', 90,
                    'Universal Studios', 80,
                    'SeaWorld', 75,
                    'Convention Center', 70,
                    'Kissimmee', 85,
                    'Celebration', 88,
                    'Lake Buena Vista', 85,
                    'Port Canaveral', 148
                )
            ),
            'hourly_regional', jsonb_build_object(
                'miami_broward', jsonb_build_object(
                    'unit', 115,
                    'min_hours', 3,
                    'tiers', jsonb_build_object(
                        '4h', 440,
                        '6h', 630,
                        '8h', 820,
                        '10h', 1000,
                        '12h', 1150
                    ),
                    'extra_mile', 3.85,
                    'miles_included', 20
                ),
                'orlando', jsonb_build_object(
                    'unit', 105,
                    'min_hours', 3,
                    'tiers', jsonb_build_object(
                        '4h', 400,
                        '6h', 580,
                        '8h', 750,
                        '10h', 920,
                        '12h', 1060
                    ),
                    'extra_mile', 3.60,
                    'miles_included', 25
                )
            ),
            'event_regional', jsonb_build_object(
                'miami_broward', jsonb_build_object(
                    'tiers', jsonb_build_object(
                        '4h', 530,
                        '6h', 760,
                        '8h', 970,
                        '10h', 1180,
                        '12h', 1380,
                        '16h', 1750
                    )
                ),
                'orlando', jsonb_build_object(
                    'tiers', jsonb_build_object(
                        '4h', 490,
                        '6h', 700,
                        '8h', 900,
                        '10h', 1090,
                        '12h', 1270,
                        '16h', 1600
                    )
                )
            ),
            'inter_city', jsonb_build_object(
                'Miami <-> Fort Lauderdale', 138,
                'Miami <-> Hollywood', 108,
                'Miami <-> West Palm Beach', 235,
                'Miami <-> Orlando', 550,
                'Miami <-> Key West', 620,
                'Miami <-> Naples', 450,
                'Miami <-> Tampa', 580,
                'Fort Lauderdale <-> Orlando', 510,
                'Fort Lauderdale <-> Palm Beach', 128,
                'Orlando <-> Tampa', 268,
                'Orlando <-> Port Canaveral', 150,
                'Orlando <-> Daytona Beach', 210,
                'Orlando <-> Jacksonville', 450
            ),
            'surcharges', jsonb_build_object(
                'night', 0.20,
                'weekend_dawn', 0.30,
                'peak_season', 0.25,
                'holiday', 0.35,
                'special_event', 0.50
            )
        )
    );
END $$;
