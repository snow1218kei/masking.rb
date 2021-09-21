require "mysql2"
require "active_record"
require "activerecord-import"

#グローバル変数を使わないようクラスを作成
class Mask
  attr_accessor :client, :users_data

  #IDをダミーのユーザーネームに付け足すことで一意制約を回避
  def masking_username(int)
    id = int + 1
    "dummy_username_" + id.to_s
  end

  #selectしたメルアドからドメインを取り出し、ダミーのメルアドに付け足す。一意制約を回避のためIDも付ける。
  def masking_email(int)
    id = int + 1
    email_dm = self.users_data[int]["email"].split("@")[1]
    "dummy_email_" + id.to_s + "@" + email_dm
  end

  #IDの最後の番号を取得する
  def last_id
    max_id = self.client.query("SELECT MAX(id) FROM users;").to_a
    max_id[0]["MAX(id)"]
  end
end

mask = Mask.new

#Mysql2::Clientのインスタンスを作成
mask.client = Mysql2::Client.new(host: ENV["DB_HOST"],
                                 username: ENV["DB_USER"],
                                 password: ENV["DB_PASSWORD"],
                                 database: ENV["DB_NAME"])

#id、username、emailの値を全件取得する
mask.users_data = mask.client.query("SELECT id, username, email FROM users;").to_a

cnt = 0

#username/emailカラムの各レコードに値を入れる
while cnt < mask.last_id
  mask.users_data[cnt]["username"] = mask.masking_username(cnt)
  mask.users_data[cnt]["email"] = mask.masking_email(cnt)
  cnt += 1
end

#DB接続設定
ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  host: ENV["DB_HOST"],
  username: ENV["DB_USER"],
  password: ENV["DB_PASSWORD"],
  database: ENV["DB_NAME"],
)

#Userクラスに継承
class User < ActiveRecord::Base
  self.table_name = "users"
  validates_presence_of :username
  validates_presence_of :email
end

#一括で更新する
User.import mask.users_data, on_duplicate_key_update: [:username, :email], validate: true
