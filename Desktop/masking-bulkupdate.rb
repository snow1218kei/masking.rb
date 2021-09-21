require "mysql2"
require "rubygems"
require "active_record"
require "activerecord-import"

$client = Mysql2::Client.new(host: ENV["DB_HOST"],
                             username: ENV["DB_USER"],
                             password: ENV["DB_PASSWORD"],
                             database: ENV["DB_NAME"])

ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  host: ENV["DB_HOST"],
  username: ENV["DB_USER"],
  password: ENV["DB_PASSWORD"],
  database: ENV["DB_NAME"],
)

class User < ActiveRecord::Base
  self.table_name = "users"
  validates_presence_of :username
  validates_presence_of :email
end

#id、username、emailの値を全件取得する
$users_data = $client.query("SELECT id, username, email FROM users;").to_a

#IDをダミーのユーザーネームに付け足すことで一意制約を回避
def masking_username(int)
  id = int + 1
  "dummy_username_" + id.to_s
end

#selectしたメルアドからドメインを取り出し、ダミーのメルアドに付け足す。一意制約を回避のためIDも付ける。
def masking_email(int)
  id = int + 1
  email_dm = $users_data[int]["email"].split("@")[1]
  "dummy_email_" + id.to_s + "@" + email_dm
end

#IDの最後の番号を取得する
def last_id
  max_id = $client.query("SELECT MAX(id) FROM users;").to_a
  max_id[0]["MAX(id)"]
end

cnt = 0

#username/emailカラムの各レコードに値を入れる
while cnt < last_id
  $users_data[cnt]["username"] = masking_username(cnt)
  $users_data[cnt]["email"] = masking_email(cnt)
  cnt += 1
end

#一括で更新する
User.import $users_data, on_duplicate_key_update: [:username, :email], validate: true
