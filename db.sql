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
    FOREIGN KEY(thread_id) REFERENCES thread(id)
);

CREATE TRIGGER update_replies
AFTER INSERT ON post
BEGIN
    UPDATE thread
    SET last_reply=CURRENT_TIMESTAMP , num_replies = num_replies + 1
    WHERE id=new.thread_id;
END;