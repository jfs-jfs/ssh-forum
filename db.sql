DROP TABLE IF EXISTS board;
CREATE TABLE board (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name CHAR(100) NOT NULL,
    description CHAR(256) NOT NULL
);

DROP TABLE IF EXISTS thread;
CREATE TABLE thread (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    board_id INTEGER,
    is_pinned BOOLEAN NOT NULL CHECK (is_pinned IN (0,1)) DEFAULT 0,
    author CHAR(256) NOT NULL DEFAULT 'Pagan',
    author_ip CHAR(15) NOT NULL DEFAULT '0.0.0.0',
    title CHAR(256) NOT NULL,
    body TEXT NOT NULL,
    creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_reply DATETIME DEFAULT CURRENT_TIMESTAMP,
    num_replies INTEGER NOT NULL DEFAULT 0,
    processed_op TEXT,
    FOREIGN KEY(board_id) REFERENCES board(id)
);

DROP TABLE IF EXISTS post;
CREATE TABLE post(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    thread_id INTEGER,
    author CHAR(256) NOT NULL DEFAULT 'Pagan',
    author_ip CHAR(15) NOT NULL DEFAULT '0.0.0.0',
    creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    body TEXT NOT NULL,
    processed_text TEXT,
    FOREIGN KEY(thread_id) REFERENCES thread(id)
);

CREATE TRIGGER update_replies_and_preprocess
AFTER INSERT ON post
BEGIN
    -- Update the counter
    UPDATE thread
    SET last_reply=CURRENT_TIMESTAMP , num_replies = num_replies + 1
    WHERE id=new.thread_id;

    -- Preprocess the text
    UPDATE post SET processed_text = '\\n     \Z4\Zr\Zb[ID]:'
        || new.id || '[AUTHOR]:' || new.author || '[CREATION]:'
        || new.creation || '\Zn\\n' || '\\n' || new.body || '\\n\\n'
    WHERE id = new.id;
END;

CREATE TRIGGER preprocess_thread
AFTER INSERT ON thread
BEGIN
    -- Preprocess the OP and Menu entry
    UPDATE thread
    SET
        processed_op = '\Zr\Zb[' || new.title ||'] :: ['|| new.author ||'] :: ['
            || new.creation ||'] :: [' || new.id || '] (Scroll: j-k)\Zn'
    WHERE id = new.id;
END;