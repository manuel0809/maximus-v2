-- Payments & Invoices System Migration
-- Creates tables for payment transactions, invoices, and payment methods management

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Payment Methods Table
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  method_type TEXT NOT NULL CHECK (method_type IN ('credit_card', 'debit_card', 'digital_wallet', 'bank_account')),
  card_last_four TEXT,
  card_brand TEXT,
  card_exp_month INTEGER,
  card_exp_year INTEGER,
  wallet_provider TEXT,
  bank_name TEXT,
  account_last_four TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
  guest_booking_id UUID REFERENCES public.guest_bookings(id) ON DELETE SET NULL,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  payment_status TEXT NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled')) DEFAULT 'pending',
  transaction_reference TEXT UNIQUE,
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoices Table
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  invoice_number TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
  guest_booking_id UUID REFERENCES public.guest_bookings(id) ON DELETE SET NULL,
  
  -- Service details
  service_type TEXT NOT NULL,
  vehicle_type TEXT,
  pickup_location TEXT,
  dropoff_location TEXT,
  trip_date TIMESTAMPTZ,
  
  -- Cost breakdown
  base_fare DECIMAL(10, 2) DEFAULT 0,
  distance_cost DECIMAL(10, 2) DEFAULT 0,
  time_cost DECIMAL(10, 2) DEFAULT 0,
  airport_fee DECIMAL(10, 2) DEFAULT 0,
  peak_hour_charge DECIMAL(10, 2) DEFAULT 0,
  additional_fees DECIMAL(10, 2) DEFAULT 0,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  gratuity DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  
  -- Driver and route info
  driver_name TEXT,
  driver_phone TEXT,
  distance_km DECIMAL(10, 2),
  duration_minutes INTEGER,
  
  invoice_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON public.payment_methods(user_id, is_default) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_trip_id ON public.payments(trip_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_payments_date ON public.payments(payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_id ON public.invoices(payment_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON public.invoices(invoice_number);

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  new_number TEXT;
  counter INTEGER;
BEGIN
  SELECT COUNT(*) + 1 INTO counter FROM public.invoices;
  new_number := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 5, '0');
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Function to generate transaction reference
CREATE OR REPLACE FUNCTION generate_transaction_reference()
RETURNS TEXT AS $$
DECLARE
  new_reference TEXT;
BEGIN
  new_reference := 'TXN-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS') || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6);
  RETURN UPPER(new_reference);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist before creating new ones
DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON public.payment_methods;
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;
DROP TRIGGER IF EXISTS update_invoices_updated_at ON public.invoices;

-- Create triggers
CREATE TRIGGER update_payment_methods_updated_at
  BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can insert their own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can update their own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can delete their own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can view their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can insert their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can update their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can view their own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Users can insert their own invoices" ON public.invoices;

-- Payment Methods Policies
CREATE POLICY "Users can view their own payment methods"
  ON public.payment_methods FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment methods"
  ON public.payment_methods FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment methods"
  ON public.payment_methods FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own payment methods"
  ON public.payment_methods FOR DELETE
  USING (auth.uid() = user_id);

-- Payments Policies
CREATE POLICY "Users can view their own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payments"
  ON public.payments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payments"
  ON public.payments FOR UPDATE
  USING (auth.uid() = user_id);

-- Invoices Policies
CREATE POLICY "Users can view their own invoices"
  ON public.invoices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own invoices"
  ON public.invoices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Insert mock payment methods for testing
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- Get first user from auth.users
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Insert mock payment methods only if they don't exist
    INSERT INTO public.payment_methods (user_id, method_type, card_last_four, card_brand, card_exp_month, card_exp_year, is_default)
    SELECT test_user_id, 'credit_card', '4242', 'Visa', 12, 2026, true
    WHERE NOT EXISTS (SELECT 1 FROM public.payment_methods WHERE user_id = test_user_id AND card_last_four = '4242');
    
    INSERT INTO public.payment_methods (user_id, method_type, card_last_four, card_brand, card_exp_month, card_exp_year, is_default)
    SELECT test_user_id, 'credit_card', '5555', 'Mastercard', 8, 2025, false
    WHERE NOT EXISTS (SELECT 1 FROM public.payment_methods WHERE user_id = test_user_id AND card_last_four = '5555');
    
    INSERT INTO public.payment_methods (user_id, method_type, wallet_provider, is_default)
    SELECT test_user_id, 'digital_wallet', 'PayPal', false
    WHERE NOT EXISTS (SELECT 1 FROM public.payment_methods WHERE user_id = test_user_id AND wallet_provider = 'PayPal');
  END IF;
END $$;

-- Insert mock payments and invoices linked to existing trips
DO $$
DECLARE
  test_user_id UUID;
  test_trip_id UUID;
  test_payment_method_id UUID;
  test_payment_id UUID;
  test_trip_record RECORD;
BEGIN
  -- Get first user
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Get default payment method
    SELECT id INTO test_payment_method_id FROM public.payment_methods WHERE user_id = test_user_id AND is_default = true LIMIT 1;
    
    -- Get completed trips for this user
    FOR test_trip_record IN 
      SELECT id, service_type, vehicle_type, pickup_location, dropoff_location, trip_date, cost, distance_km, duration_minutes
      FROM public.trips 
      WHERE user_id = test_user_id AND status = 'completed'
      LIMIT 3
    LOOP
      -- Insert payment for this trip
      INSERT INTO public.payments (user_id, trip_id, payment_method_id, amount, payment_status, transaction_reference, payment_date)
      VALUES (
        test_user_id,
        test_trip_record.id,
        test_payment_method_id,
        test_trip_record.cost,
        'completed',
        generate_transaction_reference(),
        test_trip_record.trip_date
      )
      RETURNING id INTO test_payment_id;
      
      -- Insert invoice for this payment
      INSERT INTO public.invoices (
        payment_id, invoice_number, user_id, trip_id,
        service_type, vehicle_type, pickup_location, dropoff_location, trip_date,
        base_fare, distance_cost, time_cost, subtotal, tax_amount, gratuity, total_amount,
        distance_km, duration_minutes, invoice_date
      )
      VALUES (
        test_payment_id,
        generate_invoice_number(),
        test_user_id,
        test_trip_record.id,
        test_trip_record.service_type,
        test_trip_record.vehicle_type,
        test_trip_record.pickup_location,
        test_trip_record.dropoff_location,
        test_trip_record.trip_date,
        ROUND((test_trip_record.cost * 0.30)::numeric, 2),
        ROUND((test_trip_record.cost * 0.40)::numeric, 2),
        ROUND((test_trip_record.cost * 0.15)::numeric, 2),
        ROUND((test_trip_record.cost * 0.85)::numeric, 2),
        ROUND((test_trip_record.cost * 0.10)::numeric, 2),
        ROUND((test_trip_record.cost * 0.05)::numeric, 2),
        test_trip_record.cost,
        test_trip_record.distance_km,
        test_trip_record.duration_minutes,
        test_trip_record.trip_date
      );
    END LOOP;
  END IF;
END $$;