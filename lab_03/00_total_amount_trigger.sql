\set ON_ERROR_STOP on

BEGIN;

-- Поправка к сумме бронирования после изменения стоимости его перелетов.
CREATE OR REPLACE FUNCTION bookings.lab03_update_total_amount()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
	old_book_ref char(6);
	new_book_ref char(6);
	old_price numeric := 0;
	new_price numeric := 0;
	change record;
BEGIN
	IF TG_OP IN ('UPDATE', 'DELETE') THEN
		SELECT book_ref INTO STRICT old_book_ref
		FROM bookings.tickets
		WHERE ticket_no = OLD.ticket_no
		FOR SHARE;

		old_price := OLD.price;
	END IF;

	IF TG_OP IN ('INSERT', 'UPDATE') THEN
		SELECT book_ref INTO STRICT new_book_ref
		FROM bookings.tickets
		WHERE ticket_no = NEW.ticket_no
		FOR SHARE;

		new_price := NEW.price;
	END IF;

	-- При UPDATE старый и новый билеты могут принадлежать разным бронированиям.
	-- Для одного бронирования поправки объединяются в новую цену минус старую.
	FOR change IN
		SELECT
			book_ref,
			sum(delta) AS delta
		FROM (
			VALUES
				(old_book_ref, -old_price),
				(new_book_ref, new_price)
		) AS changes(book_ref, delta)
		WHERE book_ref IS NOT NULL
		GROUP BY book_ref
		ORDER BY book_ref
	LOOP
		UPDATE bookings.bookings
		SET total_amount = total_amount + change.delta
		WHERE book_ref = change.book_ref;
	END LOOP;

	RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER lab03_segments_total
	AFTER INSERT OR UPDATE OR DELETE ON bookings.segments
	FOR EACH ROW
	EXECUTE FUNCTION bookings.lab03_update_total_amount();

COMMIT;
