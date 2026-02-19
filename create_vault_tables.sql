-- Digital Vault: Store identity documents for verification
CREATE TABLE IF NOT EXISTS public.user_documents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN ('driver_license', 'passport', 'id_card', 'other')),
    document_url TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    expiry_date DATE,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.user_documents ENABLE ROW LEVEL SECURITY;

-- User Policies
CREATE POLICY "Users can view and upload their own documents" ON public.user_documents
    FOR ALL USING (auth.uid() = user_id);

-- Admin Policy
CREATE POLICY "Admins have full access to user_documents" ON public.user_documents
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Storage bucket for documents (Supabase policy would be needed via Dashboard or SQL if enabled)
-- Insert document types for frontend selection
COMMENT ON TABLE public.user_documents IS 'Bóveda digital para validación de identidad y cumplimiento legal.';
