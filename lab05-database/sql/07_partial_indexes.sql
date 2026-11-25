CREATE INDEX lab05_loans_open_due_idx ON loans (due_on, loan_id)
WHERE returned_on IS NULL;
CREATE INDEX lab05_reservations_pending_expiry_idx ON reservations (expires_on, reservation_id)
WHERE status = 'pending';
ANALYZE loans;
ANALYZE reservations;
