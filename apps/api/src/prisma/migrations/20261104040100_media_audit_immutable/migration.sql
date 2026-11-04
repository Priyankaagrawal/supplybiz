CREATE FUNCTION reject_media_access_event_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Media access events are append-only'; END $$;
CREATE TRIGGER media_access_events_immutable BEFORE UPDATE OR DELETE ON media_access_events
FOR EACH ROW EXECUTE FUNCTION reject_media_access_event_mutation();
