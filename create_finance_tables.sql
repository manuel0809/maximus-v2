-- Create vehicle_expenses table to track all costs associated with the fleet
CREATE TABLE IF NOT EXISTS public.vehicle_expenses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('maintenance', 'fuel', 'insurance', 'fine', 'cleaning', 'other')),
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT,
    date DATE DEFAULT CURRENT_DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_by UUID REFERENCES public.user_profiles(id)
);

-- Enable RLS
ALTER TABLE public.vehicle_expenses ENABLE ROW LEVEL SECURITY;

-- Admin Policy (Full Access)
CREATE POLICY "Admins have full access to vehicle_expenses" ON public.vehicle_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- View/Analysis Logic: Create a view for ROI per Vehicle
CREATE OR REPLACE VIEW public.vehicle_profitability AS
SELECT 
    v.id as vehicle_id,
    v.brand,
    v.model,
    COALESCE(SUM(r.total_price), 0) as total_revenue,
    COALESCE((SELECT SUM(amount) FROM public.vehicle_expenses WHERE vehicle_id = v.id), 0) as total_expenses,
    (COALESCE(SUM(r.total_price), 0) - COALESCE((SELECT SUM(amount) FROM public.vehicle_expenses WHERE vehicle_id = v.id), 0)) as net_profit
FROM 
    public.vehicles v
LEFT JOIN 
    public.rentals r ON v.id = r.vehicle_id AND r.status = 'completed'
GROUP BY 
    v.id, v.brand, v.model;
