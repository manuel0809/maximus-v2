-- Loyalty Program: Track points and membership levels
CREATE TABLE IF NOT EXISTS public.loyalty_profiles (
    user_id UUID REFERENCES public.user_profiles(id) PRIMARY KEY,
    points INTEGER DEFAULT 0,
    tier TEXT DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    total_spent DECIMAL(12, 2) DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Coupons: Manage discount codes
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    discount_percent INTEGER CHECK (discount_percent > 0 AND discount_percent <= 100),
    max_discount_amount DECIMAL(10, 2),
    min_purchase_amount DECIMAL(10, 2) DEFAULT 0,
    expiry_date DATE,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.loyalty_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- Loyalty Profile Policies
CREATE POLICY "Users can view their own loyalty profile" ON public.loyalty_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Coupons Policies
CREATE POLICY "Anyone can view active coupons" ON public.coupons
    FOR SELECT USING (is_active = true AND (expiry_date IS NULL OR expiry_date >= CURRENT_DATE));

CREATE POLICY "Admins full access to coupons" ON public.coupons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Function to automatically update tier based on total spent
CREATE OR REPLACE FUNCTION public.update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_spent >= 10000 THEN
        NEW.tier := 'platinum';
    ELSIF NEW.total_spent >= 5000 THEN
        NEW.tier := 'gold';
    ELSIF NEW.total_spent >= 2000 THEN
        NEW.tier := 'silver';
    ELSE
        NEW.tier := 'bronze';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_loyalty_tier
BEFORE INSERT OR UPDATE ON public.loyalty_profiles
FOR EACH ROW EXECUTE FUNCTION public.update_loyalty_tier();
