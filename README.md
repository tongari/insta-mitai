# rails環境構築

### 参考url
[http://qiita.com/emadurandal/items/e43c4896be1df60caef0](http://qiita.com/emadurandal/items/e43c4896be1df60caef0)


- 事前準備
```
$ rbenv local 2.3.0
$ ndenv local v6.10.2
$ rbenv exec gem install bundler
```

- プロジェクトのフォルダのみにGemをインストールする

```
$ echo "source 'http://rubygems.org'" >> Gemfile
$ echo "gem 'rails', '4.2.3'" >> Gemfile
$ bundle install --path vendor/bundle
```
`※ nokogiriが結構インストールするのに時間かかる`


- railsプロジェクトを作成（turbolinksは最初から無効）
```
$ rails new ./ -d postgresql --skip-bundle --skip-turbolinks
$ bundle install --path vendor/bundle
$ rake db:create
```
`※ 事前にエイリアスで「bundle exec rails　-> rails」と「bundle exec rake　-> rake」は張り替えている`


- gitの管理対象から以下を外す
```
$ echo '/vendor/bundle' >> .gitignore
$ echo '.env' >> .gitignore
$ echo '.idea/' >> .gitignore
```

# ログイン機能を作成

- deviseをインストールする
```
$ echo "gem 'devise'" >> Gemfile
$ bundle install --path vendor/bundle
```

- deviseに必要な初期設定とそのファイルを生成
```
$ rails generate devise:install
```

- Userモデルを作成する
```
$ rails g devise user
$ rake db:migrate
```

- Viewを作成する
```
$ rails generate devise:views
```


# Deviseのエラーメッセージを日本語化する

- デフォルトの設定を日本語にする

`config/application.rb`に以下を記載
```
config.i18n.default_locale = :ja
```

- 日本語の辞書ファイルを作成する

`config/locales/devise.ja.yml`を作成
`config/locales/devise.ja.yml`に日本語に翻訳された辞書をセット

[参考辞書リストはこちら](https://gist.github.com/kaorumori/7276cec9c2d15940a3d93c6fcfab19f3)


# バリデーションエラーメッセージの日本語化

`config/locales/ja.yml`を作成

[参考辞書リストはこちら](https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/ja.yml)


# 写真投稿用の機能を作成

- controller作成
```
$ rails g controller picture index
```

- model作成
```
$ rails g model picture photo:string comment:text
```

## 画像アップローダーとしてcarrierwaveとmini_magickをインストールする

- homebrewにimagemagickをインストールする（すでに入っていれば必要ない）
```
$ brew update 
$ brew install imagemagick
```

- carrierwaveとmini_magickをインストールする
```
$ echo "gem 'carrierwave'" >> Gemfile
$ echo "gem 'mini_magick'" >> Gemfile
$ bundle install --path vendor/bundle
```

- carrierwaveの初期設定を行う。
```
$ rails generate uploader Photo
```

- models/picture.rbにcarrierwave用の設定を行う
```
mount_uploader :photo, PhotoUploader
```

- 画像のリサイズ
`app/uploaders/photo_uploader.rb`に以下を記載
```
include CarrierWave::MiniMagick
process resize_to_limit: [600, 600]
```

- 投稿するviewに以下を記載
`app/views/picture/_form.html.erb`
```
<%= f.file_field :photo %>
<%= f.hidden_field :photo_cache %><!-- バリデーションエラー時の対策 -->
```

- 一覧画面に投稿画像を表示
`app/views/picture/index.html.erb`
```
<% @pictures.each do |picture| %>
  <%= image_tag(picture.photo, alt: '') %>
  <p><%= picture.comment %></p>
<% end %>
```

- 一連のCURD処理を作成

`〜省略〜`

- 画像アップロード時にプレビューできるようにjsを書く

`app/assets/javascripts/picture.js`
```
var picUpLoadButton = document.querySelector('.js-picUpLoadButton');
var previewImg = document.querySelector('.js-previewPhoto');

picUpLoadButton && picUpLoadButton.addEventListener('change', function (e) {
  var file = e.target.files[0];
  var reader = new FileReader();

  reader.onload = (function(file) {
    return function(e) {
      previewImg.src = e.target.result;
    };
  })(file);
  reader.readAsDataURL(file);
});
```

`app/views/picture/_form.html.erb`
```
<div class="picture-preview">
  <%= image_tag(@picture.photo, alt: '', class: 'js-previewPhoto') %>
</div>
```

# ユーザ新規登録した際に認証メールが送信されるようにする

- ローカル開発確認用にletter_opener_webをインストールする
`Gemfile`
```
group :development do
  gem 'letter_opener_web'
end
```

- letter_opener_webのroutingを設定する

`config/routes.rb`
```
if Rails.env.development?
  mount LetterOpenerWeb::Engine, at: '/letter_opener'
end
```
- 開発環境でメール送信の際、letter_opener_webを使用するように設定する

`config/environments/development.rb`
```
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_mailer.delivery_method = :letter_opener_web
```

- Userモデルに`:confirmable`を追加

`app/models/user.rb`
```
devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
```

- メール認証に必要なカラムを追加

```
$ rails g migration add_confirmable_to_devise
```

- 上記コマンドで生成されたマイグレーションファイルを書き換える

```
class AddConfirmableToDevise < ActiveRecord::Migration
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true
    # User.reset_column_information # Need for some types of updates, but not for update_all.

    execute("UPDATE users SET confirmed_at = NOW()")
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_columns :users, :unconfirmed_email # Only if using reconfirmable
  end
end
```

migration fileを編集後`rake db:migrate`を実行
もし、すでにユーザを新規登録していた場合はRailsコンソールを立ち上げて`User.delete_all`で全部削除

# アソシエーション

- Pictureモデルに`user_id`カラムを追加
```
$ rails g migration AddUserIdToPictures user_id:integer
```

- UserモデルのレコードがPictureモデルのレコードを複数もつことを定義する

`app/models/user.rb`
```
has_many :pictures
```

# 自分の投稿にだけ、編集と削除をさせる

`app/views/picture/index.html.erb`
```
<% if picture.user_id == @userId %>
  <%= link_to '編集', edit_picture_path(picture.id) %>
  <%= link_to picture_path(picture.id), method: :delete ,data: { confirm: '本当に削除していいですか？' } do %>
      削除
  <% end %>
<% end %>
```

`app/controllers/picture_controller.rb`
```
def checkMatchUser
  if current_user.id != @picture.user_id
    redirect_to picture_index_path
  end
end
```
など


# UserとPictureをひも付けて誰がPictureを投稿したか分かるようする

- Userモデルに名前用のカラムを追加
```
$ rails g migration AddNameToUsers name:string
$ rake db:migrate
```

- Deviseのストロングパラメータにnameを追加

`app/controllers/application_controller.rb`
以下を追加
```
# before_actionで下で定義したメソッドを実行
before_action :configure_permitted_parameters, if: :devise_controller?

#変数PERMISSIBLE_ATTRIBUTESに配列[:name]を代入
PERMISSIBLE_ATTRIBUTES = %i(name)

protected
  #deviseのストロングパラメーターにカラム追加するメソッドを定義
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: PERMISSIBLE_ATTRIBUTES)
    devise_parameter_sanitizer.permit(:account_update, keys: PERMISSIBLE_ATTRIBUTES)
  end
```

- 新規ユーザ登録画面に名前の入力用のフィールドを追加

`app/views/devise/registrations/new.html.erb`
```
<div class="field">
  <%= f.email_field :email, autofocus: true, placeholder: "メールアドレス" %>
</div>

<!-- 名前入力用のフィールドを追加 -->
<div class="field">
  <%= f.text_field :name, placeholder: "名前" %>
</div>
```

- ユーザ編集画面に名前の入力用のフィールドを追加

`app/views/devise/registrations/edit.html.erb`
```
<div class="field">
  <%= f.label :メールアドレス %><br />
  <%= f.email_field :email, autofocus: true %>
</div>

<!-- 名前入力用のフィールドを追加 -->
<div class="field">
  <%= f.label :名前 %><br />
  <%= f.text_field :name %>
</div>

<% if devise_mapping.confirmable? && resource.pending_reconfirmation? %>
  <div>Currently waiting confirmation for: <%= resource.unconfirmed_email %></div>
<% end %>
```

# Modelのバリエーションエラー項目を日本語化する

- 辞書ファイル作成 
```
$ touch config/locales/model.ja.yml
```
```
ja:
  activerecord:
    models:
      picture: "写真投稿"
      user: "ユーザー"
    attributes:
      picture:
        photo: "写真"
        comment: "ひとこと"
      user:
        name: "名前"
        email: "メールアドレス"
        current_password: "現在のパスワード"
        password: "パスワード"
        password_confirmation: "確認用パスワード"
        remember_me: "ログインを記憶"
```

# 管理画面を作成する

### RailsAdminを導入する

- RailsAdminをインストールする

```
$ echo "gem 'rails_admin'" >> Gemfile
$ bundle install --path vendor/bundle
$ rails g rails_admin:install
```

`/admin`でアクセスしてみると管理画面を確認できる

- RailsAdminを日本語化する

```
$ touch config/locales/rails_admin.ja.yml
```

`参考url`

[https://gist.github.com/mshibuya/1662352](https://gist.github.com/mshibuya/1662352)

- 管理者のみ管理画面へアクセスできるようにする

usersテーブルに`admin`カラムを追加する
```
$ rails g migration AddAdminToUser admin
```

- 作成した、migration fileを編集
```
class AddAdminToUser < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean, :default => false
  end
end
```

- マイグレーションで適用 
```
$ rake db:migrate
```

### adminカラムがtrueの場合のみ管理画面へアクセスできるようにする

- `cancancan`をインストールする

```
$ echo "gem 'cancancan'" >> Gemfile
$ bundle install --path vendor/bundle
```
- cancancanの初期設定をする
```
$ rails g cancan:ability
```

- adminカラムがtrueのユーザのみ、管理画面にアクセスできるように設定

`app/models/ability.rb`に以下を追記
```
def initialize(user)
  # >>>>>>ここから
  if user && user.admin?
    can :access, :rails_admin   # grant access to rails_admin
    can :manage, :all           # allow superadmins to do anything
  end
  # =====ここまでを追記
  # 省略
end
```

`config/initializers/rails_admin.rb`の`Devise`と`Cancan`のとこのコメントを外す

```
RailsAdmin.config do |config|

  ### Popular gems integration

  # == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  # == Cancan ==
  config.authorize_with :cancan

  省略
  end
end
```

- 適当なユーザを管理者にする

```
$ rails c
user = User.find({適当なユーザID})
user.admin = true
user.save
```

# その他gem

- gem 'pry-rails'
- gem 'better_errors'
