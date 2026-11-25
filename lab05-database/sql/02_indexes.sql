CREATE INDEX lab05_loans_reader_issued_idx ON loans (reader_id, issued_on DESC);
CREATE INDEX lab05_loans_issued_idx ON loans (issued_on);
CREATE INDEX lab05_reservations_reader_requested_idx ON reservations (reader_id, requested_at DESC);
ANALYZE loans;
ANALYZE reservations;
