require "mysql2"

$client = Mysql2::Client.new(host: ENV["DB_HOST"],
                             username: ENV["DB_USER"],
                             password: ENV["DB_PASSWORD"],
                             database: ENV["DB_NAME"])

#IDをダミーのユーザーネームに付け足すことで一意制約を回避
def masking_username(id:)
  masked_name = "dummy_username_" + id.to_s
  return masked_name
end

#selectしたメルアドからドメインを取り出し、ダミーのメルアドに付け足す。一意制約を回避のためIDも付ける。
def masking_email(id:)
  select_email = $client.prepare("SELECT email FROM users WHERE id = ?;")
  change_email = select_email.execute(id).to_a
  email = change_email[0]["email"]

  email_dm = email.split("@")[1]
  masked_email = "dummy_email_" + id.to_s + "@" + email_dm
  return masked_email
end

#ユーザーネームとメルアドをアップデートする
def update_username_and_email(masked_name:, masked_email:, id:)
  update_sql = $client.prepare("UPDATE users SET username = ?, email = ? WHERE id = ?;")
  update_sql.execute(masked_name, masked_email, id)
end

first_id = 1

#IDの最後の番号を取得する
def last_id
  max_id = $client.query("SELECT MAX(id) FROM users;").to_a
  return max_id[0]["MAX(id)"]
end

#最初のID〜最後のIDまでループ
while first_id <= last_id
  username = masking_username(id: first_id)

  email = masking_email(id: first_id)

  update_username_and_email(masked_name: username, masked_email: email, id: first_id)

  first_id += 1
end
