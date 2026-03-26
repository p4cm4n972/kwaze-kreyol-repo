-- ================================================================
-- Migration: Fonction RPC pour la liste des inscrits (admin only)
-- Joins public.users avec auth.users pour récupérer last_sign_in_at
-- SECURITY DEFINER : s'exécute avec les droits du propriétaire
--                    (accès à auth.users impossible sinon depuis le client)
-- ================================================================

CREATE OR REPLACE FUNCTION get_admin_user_list(
  search_query TEXT    DEFAULT NULL,
  page_offset  INT     DEFAULT 0,
  page_limit   INT     DEFAULT 50,
  sort_by      TEXT    DEFAULT 'created_at',
  sort_desc    BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
  id               UUID,
  username         TEXT,
  email            TEXT,
  role             TEXT,
  created_at       TIMESTAMPTZ,
  last_sign_in_at  TIMESTAMPTZ,
  total_count      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Vérification d'accès : admin uniquement
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE public.users.id = auth.uid()
      AND public.users.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Accès non autorisé : rôle admin requis';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.username,
    au.email::TEXT,
    u.role,
    u.created_at,
    au.last_sign_in_at,
    COUNT(*) OVER() AS total_count
  FROM public.users u
  JOIN auth.users au ON u.id = au.id
  WHERE
    search_query IS NULL
    OR u.username ILIKE '%' || search_query || '%'
    OR au.email   ILIKE '%' || search_query || '%'
  ORDER BY
    CASE WHEN sort_by = 'username'        AND NOT sort_desc THEN u.username          END ASC  NULLS LAST,
    CASE WHEN sort_by = 'username'        AND     sort_desc THEN u.username          END DESC NULLS LAST,
    CASE WHEN sort_by = 'created_at'      AND NOT sort_desc THEN u.created_at        END ASC  NULLS LAST,
    CASE WHEN sort_by = 'created_at'      AND     sort_desc THEN u.created_at        END DESC NULLS LAST,
    CASE WHEN sort_by = 'last_sign_in_at' AND NOT sort_desc THEN au.last_sign_in_at  END ASC  NULLS LAST,
    CASE WHEN sort_by = 'last_sign_in_at' AND     sort_desc THEN au.last_sign_in_at  END DESC NULLS LAST,
    u.created_at DESC
  LIMIT  page_limit
  OFFSET page_offset;
END;
$$;

-- Autoriser les utilisateurs authentifiés à appeler cette fonction
-- (la vérification admin est faite à l'intérieur)
GRANT EXECUTE ON FUNCTION get_admin_user_list(TEXT, INT, INT, TEXT, BOOLEAN)
  TO authenticated;
