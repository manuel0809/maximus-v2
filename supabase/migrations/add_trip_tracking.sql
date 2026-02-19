-- =====================================================
-- MIGRATION: Google Maps Trip Tracking System
-- Date: 2026-02-15
-- Description: Tables for real-time trip tracking,
--              mileage verification, and fraud detection
-- =====================================================

-- 1. Active Trips Table
-- =====================================================
CREATE TABLE IF NOT EXISTS active_trips (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id uuid REFERENCES bookings(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES user_profiles(id),
  client_id uuid REFERENCES user_profiles(id),
  vehicle_id uuid REFERENCES vehicles(id),
  
  -- Pickup and Dropoff Locations
  pickup_lat numeric(10,8) NOT NULL,
  pickup_lng numeric(11,8) NOT NULL,
  dropoff_lat numeric(10,8) NOT NULL,
  dropoff_lng numeric(11,8) NOT NULL,
  
  -- Current Driver Location (updated every 5 seconds)
  current_driver_lat numeric(10,8),
  current_driver_lng numeric(11,8),
  
  -- Mileage Tracking (CRITICAL for billing)
  google_maps_distance_miles numeric(10,2) NOT NULL, -- Distance from Google Maps API
  real_gps_distance_miles numeric(10,2) DEFAULT 0.0, -- Actual GPS distance traveled
  charged_distance_miles numeric(10,2) NOT NULL,     -- What we charge (ALWAYS Google Maps)
  
  -- Route Data
  route_polyline text, -- Encoded polyline from Google Directions API
  gps_history jsonb DEFAULT '[]'::jsonb, -- Array of {lat, lng, timestamp, speed}
  
  -- Trip Status
  status text CHECK (status IN (
    'en_route_to_pickup',  -- Driver going to pick up client
    'waiting_at_pickup',   -- Driver arrived, waiting for client
    'in_progress',         -- Trip in progress
    'completed'            -- Trip finished
  )) DEFAULT 'en_route_to_pickup',
  
  -- Time Tracking
  start_time timestamptz NOT NULL DEFAULT now(),
  estimated_end_time timestamptz,
  actual_end_time timestamptz,
  
  -- Real-time Metrics
  current_speed_mph numeric(5,2) DEFAULT 0.0,
  deviation_percentage numeric(5,2) DEFAULT 0.0, -- % deviation from Google route
  
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_active_trips_driver 
  ON active_trips(driver_id) WHERE status != 'completed';

CREATE INDEX IF NOT EXISTS idx_active_trips_client 
  ON active_trips(client_id) WHERE status != 'completed';

CREATE INDEX IF NOT EXISTS idx_active_trips_status 
  ON active_trips(status);

CREATE INDEX IF NOT EXISTS idx_active_trips_updated 
  ON active_trips(updated_at DESC);

-- 2. Trip Alerts Table (Anti-Fraud System)
-- =====================================================
CREATE TABLE IF NOT EXISTS trip_alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id uuid REFERENCES active_trips(id) ON DELETE CASCADE,
  
  -- Alert Type
  alert_type text CHECK (alert_type IN (
    'route_deviation',     -- Driver deviated > 20% from optimal route
    'excessive_speed',     -- Driver going > 90 mph
    'stopped_too_long',    -- Driver stopped > 15 minutes
    'left_service_zone',   -- Driver left assigned service area
    'sos_button',          -- Emergency SOS pressed
    'gps_anomaly'          -- GPS showing impossible speeds/jumps
  )) NOT NULL,
  
  -- Severity Level
  severity text CHECK (severity IN ('low', 'medium', 'high', 'critical')) NOT NULL,
  
  -- Alert Details
  message text NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb, -- Additional data (speed, deviation %, etc)
  
  -- Resolution
  resolved boolean DEFAULT false,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES user_profiles(id),
  resolution_notes text,
  
  -- Timestamps
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trip_alerts_trip 
  ON trip_alerts(trip_id);

CREATE INDEX IF NOT EXISTS idx_trip_alerts_unresolved 
  ON trip_alerts(trip_id, resolved) WHERE resolved = false;

CREATE INDEX IF NOT EXISTS idx_trip_alerts_severity 
  ON trip_alerts(severity, created_at DESC) WHERE resolved = false;

-- 3. Geofence Zones Table
-- =====================================================
CREATE TABLE IF NOT EXISTS geofence_zones (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  
  -- Zone Type
  zone_type text CHECK (zone_type IN (
    'service_area',  -- Main service area (Miami-Dade, Broward, Orlando)
    'airport',       -- Airport zones with special pricing
    'restricted'     -- Restricted areas
  )) NOT NULL,
  
  -- Boundary (polygon coordinates)
  boundary_coordinates jsonb NOT NULL, -- Array of {lat, lng} points
  
  -- Rules for this zone
  rules jsonb DEFAULT '{}'::jsonb, -- {max_speed, special_pricing, etc}
  
  -- Status
  is_active boolean DEFAULT true,
  
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Trip History Archive (for completed trips)
-- =====================================================
-- This is automatically populated when a trip is completed
CREATE TABLE IF NOT EXISTS trip_history (
  id uuid PRIMARY KEY,
  booking_id uuid,
  driver_id uuid,
  client_id uuid,
  vehicle_id uuid,
  
  -- Locations
  pickup_lat numeric(10,8),
  pickup_lng numeric(11,8),
  dropoff_lat numeric(10,8),
  dropoff_lng numeric(11,8),
  
  -- Mileage (for billing verification)
  google_maps_distance_miles numeric(10,2),
  real_gps_distance_miles numeric(10,2),
  charged_distance_miles numeric(10,2),
  
  -- Route
  route_polyline text,
  gps_history jsonb,
  
  -- Metrics
  deviation_percentage numeric(5,2),
  max_speed_mph numeric(5,2),
  
  -- Duration
  start_time timestamptz,
  end_time timestamptz,
  duration_minutes integer,
  
  -- Archive timestamp
  archived_at timestamptz DEFAULT now()
);

-- Index for historical queries
CREATE INDEX IF NOT EXISTS idx_trip_history_driver 
  ON trip_history(driver_id, archived_at DESC);

CREATE INDEX IF NOT EXISTS idx_trip_history_client 
  ON trip_history(client_id, archived_at DESC);

-- 5. Function to archive completed trips
-- =====================================================
CREATE OR REPLACE FUNCTION archive_completed_trip()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO trip_history (
      id, booking_id, driver_id, client_id, vehicle_id,
      pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
      google_maps_distance_miles, real_gps_distance_miles, charged_distance_miles,
      route_polyline, gps_history,
      deviation_percentage,
      max_speed_mph,
      start_time, end_time,
      duration_minutes
    ) VALUES (
      NEW.id, NEW.booking_id, NEW.driver_id, NEW.client_id, NEW.vehicle_id,
      NEW.pickup_lat, NEW.pickup_lng, NEW.dropoff_lat, NEW.dropoff_lng,
      NEW.google_maps_distance_miles, NEW.real_gps_distance_miles, NEW.charged_distance_miles,
      NEW.route_polyline, NEW.gps_history,
      NEW.deviation_percentage,
      (
        SELECT MAX((point->>'speed')::numeric)
        FROM jsonb_array_elements(NEW.gps_history) AS point
      ),
      NEW.start_time, NEW.actual_end_time,
      EXTRACT(EPOCH FROM (NEW.actual_end_time - NEW.start_time)) / 60
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-archive on completion
DROP TRIGGER IF EXISTS trigger_archive_completed_trip ON active_trips;
CREATE TRIGGER trigger_archive_completed_trip
  AFTER UPDATE ON active_trips
  FOR EACH ROW
  EXECUTE FUNCTION archive_completed_trip();

-- 6. Row Level Security Policies
-- =====================================================

-- Enable RLS
ALTER TABLE active_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE geofence_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_history ENABLE ROW LEVEL SECURITY;

-- Active Trips Policies
CREATE POLICY "Drivers can view their own active trips"
  ON active_trips FOR SELECT
  USING (driver_id = auth.uid());

CREATE POLICY "Clients can view their own active trips"
  ON active_trips FOR SELECT
  USING (client_id = auth.uid());

CREATE POLICY "Staff can view all active trips"
  ON active_trips FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role IN (
        'super_admin', 'admin', 'operations_manager', 'dispatcher'
      )
    )
  );

CREATE POLICY "Drivers can update their own trip location"
  ON active_trips FOR UPDATE
  USING (driver_id = auth.uid());

-- Trip Alerts Policies
CREATE POLICY "Staff can view all alerts"
  ON trip_alerts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role IN (
        'super_admin', 'admin', 'operations_manager', 'dispatcher'
      )
    )
  );

-- Geofence Zones Policies
CREATE POLICY "Everyone can view active geofence zones"
  ON geofence_zones FOR SELECT
  USING (is_active = true);

CREATE POLICY "Only admins can manage geofence zones"
  ON geofence_zones FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role IN ('super_admin', 'admin')
    )
  );

-- Trip History Policies
CREATE POLICY "Users can view their own trip history"
  ON trip_history FOR SELECT
  USING (
    driver_id = auth.uid() OR client_id = auth.uid()
  );

CREATE POLICY "Staff can view all trip history"
  ON trip_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role IN (
        'super_admin', 'admin', 'operations_manager', 'finance_manager'
      )
    )
  );

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================
COMMENT ON TABLE active_trips IS 'Real-time trip tracking with GPS updates every 5 seconds';
COMMENT ON COLUMN active_trips.google_maps_distance_miles IS 'Distance from Google Maps API - used for billing';
COMMENT ON COLUMN active_trips.real_gps_distance_miles IS 'Actual GPS distance traveled by driver';
COMMENT ON COLUMN active_trips.charged_distance_miles IS 'Distance charged to client (ALWAYS Google Maps distance)';
COMMENT ON COLUMN active_trips.gps_history IS 'Array of GPS points: [{lat, lng, timestamp, speed}]';
COMMENT ON COLUMN active_trips.deviation_percentage IS 'Percentage deviation from optimal Google Maps route';

COMMENT ON TABLE trip_alerts IS 'Anti-fraud alerts for route deviation, speed, GPS anomalies';
COMMENT ON TABLE geofence_zones IS 'Service area boundaries and special zones (airports, etc)';
COMMENT ON TABLE trip_history IS 'Archive of completed trips for billing verification and disputes';
