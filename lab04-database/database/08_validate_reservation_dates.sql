ALTER TABLE public.reservations
    ADD CONSTRAINT reservations_valid_dates
    CHECK (expires_on >= (requested_at AT TIME ZONE 'UTC')::date);
