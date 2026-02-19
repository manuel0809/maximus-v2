-- Migration: Add "BLACK" Sedan Service Rates to Premium SUVs
-- Description: Enables the "Upgrade to SUV" strategy by adding sedan-tier pricing to premium vehicles.

DO $$
BEGIN
    UPDATE public.vehicles
    SET service_rates = service_rates || jsonb_build_object(
        'black', jsonb_build_object(
            'miami_broward', jsonb_build_object(
                'base', 12.00,
                'per_mile', 4.00,
                'min_tariff', 35.00,
                'waiting_free_mins', 8,
                'waiting_extra_min', 1.50
            ),
            'orlando', jsonb_build_object(
                'base', 10.00,
                'per_mile', 3.75,
                'min_tariff', 32.00,
                'waiting_free_mins', 8,
                'waiting_extra_min', 1.50
            )
        ),
        'black_airport_fixed', jsonb_build_object(
            'mia', jsonb_build_object(
                'South Beach', 75,
                'Downtown / Brickell', 58,
                'Doral', 48,
                'Coral Gables', 55,
                'Coconut Grove', 58,
                'Aventura', 75,
                'Sunny Isles', 80,
                'Key Biscayne', 68,
                'Kendall', 60,
                'Homestead', 88,
                'Wynwood', 55,
                'Miami Gardens', 68,
                'Fort Lauderdale', 100,
                'Hollywood', 82,
                'Weston', 95,
                'Port of Miami', 55
            ),
            'fll', jsonb_build_object(
                'Fort Lauderdale Beach', 42,
                'Las Olas', 38,
                'Hollywood', 42,
                'Hallandale Beach', 48,
                'Aventura', 60,
                'South Beach', 98,
                'Downtown Miami', 95,
                'Boca Raton', 65,
                'Pompano Beach', 40,
                'Weston', 48,
                'Coral Springs', 52,
                'Port Everglades', 35
            ),
            'mco', jsonb_build_object(
                'International Drive', 52,
                'Downtown Orlando', 48,
                'Walt Disney World', 68,
                'Universal Studios', 58,
                'SeaWorld', 55,
                'Convention Center', 50,
                'Kissimmee', 62,
                'Celebration', 65,
                'Lake Buena Vista', 62,
                'Port Canaveral', 115
            )
        ),
        'black_hourly', jsonb_build_object(
            'miami_broward', jsonb_build_object(
                'unit', 85,
                'min_hours', 3,
                'tiers', jsonb_build_object(
                    '4h', 320,
                    '6h', 460,
                    '8h', 600,
                    '10h', 730,
                    '12h', 850
                ),
                'extra_mile', 3.00,
                'miles_included', 25
            ),
            'orlando', jsonb_build_object(
                'unit', 78,
                'min_hours', 3,
                'tiers', jsonb_build_object(
                    '4h', 295,
                    '6h', 425,
                    '8h', 555,
                    '10h', 675,
                    '12h', 790
                ),
                'extra_mile', 2.75,
                'miles_included', 30
            )
        ),
        'black_event', jsonb_build_object(
            'miami_broward', jsonb_build_object(
                'tiers', jsonb_build_object(
                    '4h', 380,
                    '6h', 550,
                    '8h', 700,
                    '10h', 850,
                    '12h', 990,
                    '16h', 1250
                )
            ),
            'orlando', jsonb_build_object(
                'tiers', jsonb_build_object(
                    '4h', 350,
                    '6h', 505,
                    '8h', 650,
                    '10h', 790,
                    '12h', 920,
                    '16h', 1150
                )
            )
        ),
        'black_inter_city', jsonb_build_object(
            'Miami <-> Fort Lauderdale', 105,
            'Miami <-> Hollywood', 82,
            'Miami <-> West Palm Beach', 185,
            'Miami <-> Orlando', 420,
            'Miami <-> Key West', 480,
            'Miami <-> Naples', 350,
            'Miami <-> Tampa', 450,
            'Fort Lauderdale <-> Orlando', 390,
            'Fort Lauderdale <-> Palm Beach', 100,
            'Orlando <-> Tampa', 210,
            'Orlando <-> Port Canaveral', 118,
            'Orlando <-> Daytona Beach', 165
        )
    )
    WHERE brand IN ('Chevrolet', 'GMC', 'Cadillac');
END $$;
