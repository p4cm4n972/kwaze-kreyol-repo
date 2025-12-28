-- ================================================
-- FRIENDS MANAGEMENT SYSTEM - MIGRATION
-- ================================================

-- ================================================
-- 1. ADD FRIEND_CODE TO USERS TABLE
-- ================================================

-- Add friend_code column (6 alphanumeric characters, unique)
ALTER TABLE users ADD COLUMN IF NOT EXISTS friend_code TEXT UNIQUE;

-- Index for fast friend code lookup
CREATE INDEX IF NOT EXISTS idx_users_friend_code ON users(friend_code) WHERE friend_code IS NOT NULL;

-- Function to generate unique friend code
CREATE OR REPLACE FUNCTION generate_friend_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude ambiguous characters (0,O,1,I)
  result TEXT := '';
  i INTEGER;
  code_exists BOOLEAN;
BEGIN
  LOOP
    result := '';
    FOR i IN 1..6 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM users WHERE friend_code = result) INTO code_exists;

    IF NOT code_exists THEN
      EXIT;
    END IF;
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate friend code on user creation
CREATE OR REPLACE FUNCTION assign_friend_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.friend_code IS NULL THEN
    NEW.friend_code := generate_friend_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_assign_friend_code ON users;
CREATE TRIGGER trigger_assign_friend_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION assign_friend_code();

-- Backfill existing users with friend codes
UPDATE users SET friend_code = generate_friend_code() WHERE friend_code IS NULL;

-- ================================================
-- 2. FRIENDSHIPS TABLE (Bidirectional relationships)
-- ================================================

CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Bidirectional pattern: user_id_a < user_id_b (alphabetically)
  user_id_a UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id_b UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT friendships_no_self_friend CHECK (user_id_a != user_id_b),
  CONSTRAINT friendships_ordered CHECK (user_id_a < user_id_b),
  CONSTRAINT friendships_unique UNIQUE (user_id_a, user_id_b)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_friendships_user_a ON friendships(user_id_a);
CREATE INDEX IF NOT EXISTS idx_friendships_user_b ON friendships(user_id_b);

-- RLS Policies
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own friendships" ON friendships;
CREATE POLICY "Users can view their own friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id_a OR auth.uid() = user_id_b);

DROP POLICY IF EXISTS "Users can delete their own friendships" ON friendships;
CREATE POLICY "Users can delete their own friendships"
  ON friendships FOR DELETE
  USING (auth.uid() = user_id_a OR auth.uid() = user_id_b);

-- ================================================
-- 3. FRIEND_REQUESTS TABLE
-- ================================================

CREATE TABLE IF NOT EXISTS friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT friend_requests_no_self CHECK (sender_id != receiver_id),
  CONSTRAINT friend_requests_unique UNIQUE (sender_id, receiver_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_friend_requests_sender ON friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver ON friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);

-- Unique index: only one pending request between two users (either direction)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_request
  ON friend_requests(LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id))
  WHERE status = 'pending';

-- RLS Policies
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their sent and received requests" ON friend_requests;
CREATE POLICY "Users can view their sent and received requests"
  ON friend_requests FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can create friend requests" ON friend_requests;
CREATE POLICY "Users can create friend requests"
  ON friend_requests FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can update their received requests" ON friend_requests;
CREATE POLICY "Users can update their received requests"
  ON friend_requests FOR UPDATE
  USING (auth.uid() = receiver_id OR auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can delete their sent requests" ON friend_requests;
CREATE POLICY "Users can delete their sent requests"
  ON friend_requests FOR DELETE
  USING (auth.uid() = sender_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_friend_requests_updated_at ON friend_requests;
CREATE TRIGGER update_friend_requests_updated_at
  BEFORE UPDATE ON friend_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 4. FRIEND_INVITATIONS TABLE (Email invitations)
-- ================================================

CREATE TABLE IF NOT EXISTS friend_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,

  status TEXT NOT NULL DEFAULT 'sent'
    CHECK (status IN ('sent', 'accepted', 'expired')),

  invitation_token TEXT NOT NULL UNIQUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days'),
  accepted_at TIMESTAMPTZ,
  accepted_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Email validation constraint
  CONSTRAINT friend_invitations_valid_email
    CHECK (invitee_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_friend_invitations_inviter ON friend_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_friend_invitations_email ON friend_invitations(invitee_email);
CREATE INDEX IF NOT EXISTS idx_friend_invitations_token ON friend_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_friend_invitations_status ON friend_invitations(status);

-- RLS Policies
ALTER TABLE friend_invitations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their sent invitations" ON friend_invitations;
CREATE POLICY "Users can view their sent invitations"
  ON friend_invitations FOR SELECT
  USING (auth.uid() = inviter_id);

DROP POLICY IF EXISTS "Users can create invitations" ON friend_invitations;
CREATE POLICY "Users can create invitations"
  ON friend_invitations FOR INSERT
  WITH CHECK (auth.uid() = inviter_id);

-- Function to generate invitation token
CREATE OR REPLACE FUNCTION generate_invitation_token()
RETURNS TEXT AS $$
BEGIN
  RETURN encode(gen_random_bytes(32), 'base64');
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- 5. POSTGRESQL FUNCTIONS
-- ================================================

-- Send friend request
CREATE OR REPLACE FUNCTION send_friend_request(
  p_sender_id UUID,
  p_receiver_id UUID
)
RETURNS UUID AS $$
DECLARE
  request_id UUID;
  existing_friendship BOOLEAN;
  existing_request BOOLEAN;
BEGIN
  -- Check if already friends
  SELECT EXISTS(
    SELECT 1 FROM friendships
    WHERE (user_id_a = LEAST(p_sender_id, p_receiver_id)
       AND user_id_b = GREATEST(p_sender_id, p_receiver_id))
  ) INTO existing_friendship;

  IF existing_friendship THEN
    RAISE EXCEPTION 'Vous êtes déjà amis avec cet utilisateur';
  END IF;

  -- Check for existing pending request (either direction)
  SELECT EXISTS(
    SELECT 1 FROM friend_requests
    WHERE ((sender_id = p_sender_id AND receiver_id = p_receiver_id)
        OR (sender_id = p_receiver_id AND receiver_id = p_sender_id))
      AND status = 'pending'
  ) INTO existing_request;

  IF existing_request THEN
    RAISE EXCEPTION 'Une demande d''amitié est déjà en attente';
  END IF;

  -- Create request
  INSERT INTO friend_requests (sender_id, receiver_id, status)
  VALUES (p_sender_id, p_receiver_id, 'pending')
  RETURNING id INTO request_id;

  RETURN request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accept friend request
CREATE OR REPLACE FUNCTION accept_friend_request(
  p_request_id UUID,
  p_user_id UUID
)
RETURNS UUID AS $$
DECLARE
  request_record RECORD;
  friendship_id UUID;
BEGIN
  -- Get request and verify receiver
  SELECT * INTO request_record
  FROM friend_requests
  WHERE id = p_request_id AND receiver_id = p_user_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande d''amitié introuvable ou déjà traitée';
  END IF;

  -- Update request status
  UPDATE friend_requests
  SET status = 'accepted', responded_at = now()
  WHERE id = p_request_id;

  -- Create friendship (bidirectional)
  INSERT INTO friendships (user_id_a, user_id_b)
  VALUES (
    LEAST(request_record.sender_id, request_record.receiver_id),
    GREATEST(request_record.sender_id, request_record.receiver_id)
  )
  RETURNING id INTO friendship_id;

  RETURN friendship_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decline friend request
CREATE OR REPLACE FUNCTION decline_friend_request(
  p_request_id UUID,
  p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE friend_requests
  SET status = 'declined', responded_at = now()
  WHERE id = p_request_id AND receiver_id = p_user_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande d''amitié introuvable ou déjà traitée';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get friends list
CREATE OR REPLACE FUNCTION get_friends_list(p_user_id UUID)
RETURNS TABLE (
  friend_id UUID,
  username TEXT,
  avatar_url TEXT,
  friend_code TEXT,
  friendship_created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN f.user_id_a = p_user_id THEN f.user_id_b
      ELSE f.user_id_a
    END as friend_id,
    u.username,
    u.avatar_url,
    u.friend_code,
    f.created_at as friendship_created_at
  FROM friendships f
  JOIN users u ON u.id = CASE
    WHEN f.user_id_a = p_user_id THEN f.user_id_b
    ELSE f.user_id_a
  END
  WHERE f.user_id_a = p_user_id OR f.user_id_b = p_user_id
  ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search users by username (excluding friends and self)
CREATE OR REPLACE FUNCTION search_users_for_friends(
  p_user_id UUID,
  p_query TEXT,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  friend_code TEXT,
  is_friend BOOLEAN,
  has_pending_request BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id as user_id,
    u.username,
    u.avatar_url,
    u.friend_code,
    EXISTS(
      SELECT 1 FROM friendships f
      WHERE (f.user_id_a = LEAST(p_user_id, u.id) AND f.user_id_b = GREATEST(p_user_id, u.id))
    ) as is_friend,
    EXISTS(
      SELECT 1 FROM friend_requests fr
      WHERE ((fr.sender_id = p_user_id AND fr.receiver_id = u.id)
          OR (fr.sender_id = u.id AND fr.receiver_id = p_user_id))
        AND fr.status = 'pending'
    ) as has_pending_request
  FROM users u
  WHERE u.id != p_user_id
    AND u.username ILIKE '%' || p_query || '%'
  ORDER BY u.username
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search user by friend code
CREATE OR REPLACE FUNCTION search_user_by_friend_code(
  p_user_id UUID,
  p_friend_code TEXT
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  friend_code TEXT,
  is_friend BOOLEAN,
  has_pending_request BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id as user_id,
    u.username,
    u.avatar_url,
    u.friend_code,
    EXISTS(
      SELECT 1 FROM friendships f
      WHERE (f.user_id_a = LEAST(p_user_id, u.id) AND f.user_id_b = GREATEST(p_user_id, u.id))
    ) as is_friend,
    EXISTS(
      SELECT 1 FROM friend_requests fr
      WHERE ((fr.sender_id = p_user_id AND fr.receiver_id = u.id)
          OR (fr.sender_id = u.id AND fr.receiver_id = p_user_id))
        AND fr.status = 'pending'
    ) as has_pending_request
  FROM users u
  WHERE u.friend_code = UPPER(p_friend_code)
    AND u.id != p_user_id
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove friendship
CREATE OR REPLACE FUNCTION remove_friendship(
  p_user_id UUID,
  p_friend_id UUID
)
RETURNS VOID AS $$
BEGIN
  DELETE FROM friendships
  WHERE (user_id_a = LEAST(p_user_id, p_friend_id)
     AND user_id_b = GREATEST(p_user_id, p_friend_id));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Amitié introuvable';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Met Double leaderboard filtered by friends
CREATE OR REPLACE FUNCTION get_met_double_friends_leaderboard(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  total_sessions INTEGER,
  total_wins INTEGER,
  total_cochons_given INTEGER,
  total_cochons_received INTEGER,
  win_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH friend_ids AS (
    SELECT
      CASE
        WHEN f.user_id_a = p_user_id THEN f.user_id_b
        ELSE f.user_id_a
      END as friend_id
    FROM friendships f
    WHERE f.user_id_a = p_user_id OR f.user_id_b = p_user_id
  ),
  sessions_stats AS (
    SELECT
      p.user_id,
      COUNT(DISTINCT s.id) as sessions_played,
      COUNT(*) FILTER (WHERE s.winner_id = p.user_id) as wins
    FROM met_double_sessions s
    JOIN met_double_participants p ON p.session_id = s.id
    WHERE s.status = 'completed'
      AND p.user_id IN (SELECT friend_id FROM friend_ids)
    GROUP BY p.user_id
  ),
  cochons_stats AS (
    SELECT
      p.user_id,
      COUNT(*) FILTER (WHERE r.winner_participant_id = p.id) as cochons_given,
      COUNT(*) FILTER (WHERE p.id = ANY(r.cochon_participant_ids)) as cochons_received
    FROM met_double_participants p
    JOIN met_double_rounds r ON r.session_id = p.session_id
    WHERE p.user_id IN (SELECT friend_id FROM friend_ids)
    GROUP BY p.user_id
  )
  SELECT
    u.id,
    u.username,
    COALESCE(ss.sessions_played, 0)::INTEGER,
    COALESCE(ss.wins, 0)::INTEGER,
    COALESCE(cs.cochons_given, 0)::INTEGER,
    COALESCE(cs.cochons_received, 0)::INTEGER,
    CASE
      WHEN COALESCE(ss.sessions_played, 0) > 0
      THEN ROUND((COALESCE(ss.wins, 0)::NUMERIC / ss.sessions_played) * 100, 2)
      ELSE 0
    END as win_rate
  FROM users u
  LEFT JOIN sessions_stats ss ON ss.user_id = u.id
  LEFT JOIN cochons_stats cs ON cs.user_id = u.id
  WHERE u.id IN (SELECT friend_id FROM friend_ids)
  ORDER BY COALESCE(ss.wins, 0) DESC, win_rate DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
