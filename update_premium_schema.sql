-- Add service_rates column to vehicles to support complex pricing (Black SUV, Hourly, Event)
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS service_rates JSONB DEFAULT '{}'::jsonb;

-- Add transport_metadata for features like WiFi, Screens, Massage, etc.
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Update vehicle_categories to include 'Premium Transport'
INSERT INTO public.vehicle_categories (name, description, sort_order)
VALUES ('Premium Transport', 'Servicio de transporte de lujo con conductor, ideal para eventos y traslados VIP.', 0)
ON CONFLICT (id) DO NOTHING;

-- Note: In a real environment, the above category insert should be one-time.
-- I will use the ID of 'Premium Transport' for the new vehicles.
