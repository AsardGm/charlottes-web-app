-- QUANTUM Cognitive Testing Extension
-- Extends cognitive_test_results to support QUANTUM test suite

-- Add QUANTUM-specific columns to cognitive_test_results
ALTER TABLE cognitive_test_results
ADD COLUMN IF NOT EXISTS quantum_reaction JSONB,
ADD COLUMN IF NOT EXISTS quantum_memory JSONB,
ADD COLUMN IF NOT EXISTS quantum_focus JSONB;

-- QUANTUM Reaction Test structure:
-- {
--   "reaction_times_ms": [int],  // All 5 attempts
--   "average_ms": int,
--   "best_ms": int,
--   "worst_ms": int,
--   "score": int (0-100)
-- }

-- QUANTUM Memory Test structure:
-- {
--   "max_level": int,            // Highest level reached
--   "correct_rounds": int,       // Number of successful rounds
--   "sequence_length": int,      // Length of final sequence
--   "score": int (0-100)
-- }

-- QUANTUM Focus Test structure:
-- {
--   "targets_shown": int,        // Total targets displayed
--   "targets_hit": int,          // Successfully clicked
--   "false_positives": int,      // Wrong clicks
--   "accuracy": float,           // Hit rate 0-1
--   "score": int (0-100)
-- }

-- Create index for QUANTUM tests
CREATE INDEX IF NOT EXISTS idx_cognitive_quantum_tests
ON cognitive_test_results(user_id, timestamp DESC)
WHERE quantum_reaction IS NOT NULL
   OR quantum_memory IS NOT NULL
   OR quantum_focus IS NOT NULL;

-- Comments
COMMENT ON COLUMN cognitive_test_results.quantum_reaction IS 'QUANTUM Reaction Time Test results - visual stimulus response time';
COMMENT ON COLUMN cognitive_test_results.quantum_memory IS 'QUANTUM Memory Sequence Test results - working memory capacity';
COMMENT ON COLUMN cognitive_test_results.quantum_focus IS 'QUANTUM Sustained Focus Test results - attention span and impulse control';
