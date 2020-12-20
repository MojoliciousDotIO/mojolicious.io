-- 1 up
PRAGMA foreign_keys = ON;

create table users (
  id integer primary key autoincrement,
  name text not null unique
);

create table items (
  id integer primary key autoincrement,
  title text,
  url text,
  purchased integer not null default 0,
  user_id integer not null,
  foreign key(user_id) references users(id)
);

-- 1 down

PRAGMA foreign_keys = OFF;
drop table if exists users;
drop table if exists items;

