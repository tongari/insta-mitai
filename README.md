# rails環境構築

### 参考url
[http://qiita.com/emadurandal/items/e43c4896be1df60caef0](http://qiita.com/emadurandal/items/e43c4896be1df60caef0)


- 事前準備
```bash
$ rbenv local 2.3.0
$ ndenv local v6.10.2
$ rbenv exec gem install bundler
```

- プロジェクトのフォルダのみにGemをインストールする

```bash
$ echo "source 'http://rubygems.org'" >> Gemfile
$ echo "gem 'rails', '4.2.3'" >> Gemfile
$ bundle install --path vendor/bundle
```
`※ nokogiriが結構インストールするのに時間かかる`


- railsプロジェクトを作成（turbolinksは最初から無効）
```bash
$ rails new ./ -d postgresql --skip-bundle --skip-turbolinks
$ bundle install --path vendor/bundle
$ rake db:create
```
`※ 事前にエイリアスで「bundle exec rails　-> rails」と「bundle exec rake　-> rake」は張り替えている`


- gitの管理対象から以下を外す
```bash
$ echo '/vendor/bundle' >> .gitignore
$ echo '.env' >> .gitignore
$ echo '.idea/' >> .gitignore
```

# ログイン機能を作成

- deviseをインストールする
```bash
$ echo "gem 'devise'" >> Gemfile
$ bundle install --path vendor/bundle
```

- deviseに必要な初期設定とそのファイルを生成
```bash
$ rails generate devise:install
```

- Userモデルを作成する
```bash
$ rails g devise user
$ rake db:migrate
```

- Viewを作成する
```bash
$ rails generate devise:views
```


# Deviseのエラーメッセージを日本語化する

- デフォルトの設定を日本語にする

`config/application.rb`に以下を記載
```ruby
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
```bash
$ rails g controller picture index
```

- model作成
```bash
$ rails g model picture photo:string comment:text
```

## 画像アップローダーとしてcarrierwaveとmini_magickをインストールする

- homebrewにimagemagickをインストールする（すでに入っていれば必要ない）
```bash
$ brew update 
$ brew install imagemagick
```

- carrierwaveとmini_magickをインストールする
```bash
$ echo "gem 'carrierwave'" >> Gemfile
$ echo "gem 'mini_magick'" >> Gemfile
$ bundle install --path vendor/bundle
```

- carrierwaveの初期設定を行う。
```bash
$ rails generate uploader Photo
```

- models/picture.rbにcarrierwave用の設定を行う
```ruby
mount_uploader :photo, PhotoUploader
```

- 画像のリサイズ
`app/uploaders/photo_uploader.rb`に以下を記載
```ruby
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
```javascript
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
```ruby
group :development do
  gem 'letter_opener_web'
end
```

- letter_opener_webのroutingを設定する

`config/routes.rb`
```ruby
if Rails.env.development?
  mount LetterOpenerWeb::Engine, at: '/letter_opener'
end
```
- 開発環境でメール送信の際、letter_opener_webを使用するように設定する

`config/environments/development.rb`
```ruby
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_mailer.delivery_method = :letter_opener_web
```

- Userモデルに`:confirmable`を追加

`app/models/user.rb`
```ruby
devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
```

- メール認証に必要なカラムを追加

```bash
$ rails g migration add_confirmable_to_devise
```

- 上記コマンドで生成されたマイグレーションファイルを書き換える

```ruby
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
```bash
$ rails g migration AddUserIdToPictures user_id:integer
```

- UserモデルのレコードがPictureモデルのレコードを複数もつことを定義する

`app/models/user.rb`
```ruby
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
```ruby
def checkMatchUser
  if current_user.id != @picture.user_id
    redirect_to picture_index_path
  end
end
```
など


# UserとPictureをひも付けて誰がPictureを投稿したか分かるようする

- Userモデルに名前用のカラムを追加
```bash
$ rails g migration AddNameToUsers name:string
$ rake db:migrate
```

- Deviseのストロングパラメータにnameを追加

`app/controllers/application_controller.rb`
以下を追加
```ruby
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
```yaml
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

```bash
$ echo "gem 'rails_admin'" >> Gemfile
$ bundle install --path vendor/bundle
$ rails g rails_admin:install
```

`/admin`でアクセスしてみると管理画面を確認できる

- RailsAdminを日本語化する

```bash
$ touch config/locales/rails_admin.ja.yml
```

`参考url`

[https://gist.github.com/mshibuya/1662352](https://gist.github.com/mshibuya/1662352)

- 管理者のみ管理画面へアクセスできるようにする

usersテーブルに`admin`カラムを追加する
```bash
$ rails g migration AddAdminToUser admin
```

- 作成した、migration fileを編集
```ruby
class AddAdminToUser < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean, :default => false
  end
end
```

- マイグレーションで適用 
```bash
$ rake db:migrate
```

### adminカラムがtrueの場合のみ管理画面へアクセスできるようにする

- `cancancan`をインストールする

```bash
$ echo "gem 'cancancan'" >> Gemfile
$ bundle install --path vendor/bundle
```
- cancancanの初期設定をする
```bash
$ rails g cancan:ability
```

- adminカラムがtrueのユーザのみ、管理画面にアクセスできるように設定

`app/models/ability.rb`に以下を追記
```ruby
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

```ruby
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

```bash
$ rails c
user = User.find({適当なユーザID})
user.admin = true
user.save
```


# エラー系のページを作成

- 適宜エラーページを作成する
`自由に作る`

- 開発環境で本番環境と同様のエラー画面を表示させるために、以下の設定をする

`config/environments/development.rb`
```ruby
config.consider_all_requests_local = false(trueからfalseに)
```

# 本番環境（heroku）にSendGridをいれる

- プラグインを導入
```bash
$ heroku login
$ heroku create
$ heroku addons:create sendgrid:starter
```

- 設定用にSendgridの情報を取得
```bash
$ heroku config:get SENDGRID_USERNAME
$ heroku config:get SENDGRID_PASSWORD
```

- 環境変数の設定

```bash
$ heroku config:set SENDGRID_USERNAME=(調べたSENDGRID_USERNAME)
$ heroku config:set SENDGRID_PASSWORD=(調べたSENDGRID_PASSWORD)
$ heroku config
```

- `config/environments/production.rb`を以下に変更

```ruby
config.action_mailer.default_url_options = { host: '自分のHerokuアプリのドメイン' }
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings =
{
 user_name: ENV['SENDGRID_USERNAME'],
 password: ENV['SENDGRID_PASSWORD'],
 domain: "heroku.com",
 address: "smtp.sendgrid.net",
 port: 587,
 authentication: :plain,
 enable_starttls_auto: true
}
```

- `config/initializers/devise.rb`の記述を変更

config.mailer_senderの値を`noreply@yourdomain`に変更する。


# SNSログインの実装

- omniauthをインストール

```bash
$ echo "gem 'omniauth'" >> Gemfile
$ echo "gem 'omniauth-twitter'" >> Gemfile
$ echo "gem 'omniauth-facebook'" >> Gemfile
$ bundle install --path vendor/bundle
```

- `:omniauthable`の定義を有効にする

`app/models/user.rb`
```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable
# 省略
end
```

- ルーティング定義を追加

`/config/routes.rb`

```ruby
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
end
```

- Facebookのアプリ登録

https://developers.facebook.com/

`開発環境用`と`本番用`２つ作成

```
本番環境（production)のみ、アプリレビューより ☓☓☓を公開しますか？をはいにする
```

- Twitterのアプリ登録

https://dev.twitter.com/ 

`開発環境用`と`本番用`２つ作成


- `config/initializers/devise.rb`に以下を追記

```ruby
Devise.setup do |config|
  if Rails.env.production?
    config.omniauth :facebook, ENV['FACEBOOK_ID_PROD'], ENV['FACEBOOK_SECRET_PROD'], scope: 'email', display: 'popup', info_fields: 'name, email'
    config.omniauth :twitter, ENV['TWITTER_ID_PROD'], ENV['TWITTER_SECRET_PROD'], scope: 'email', display: 'popup', info_fields: 'name, email'
  else
    config.omniauth :facebook, ENV['FACEBOOK_ID_DEV'], ENV['FACEBOOK_SECRET_DEV'], scope: 'email', display: 'popup', info_fields: 'name, email'
    config.omniauth :twitter, ENV['TWITTER_ID_DEV'], ENV['TWITTER_SECRET_DEV'], scope: 'email', display: 'popup', info_fields: 'name, email'
  end
end
```

### 開発環境用において、dotenvを使用して環境変数化を行う（※.envをgithubにあがらないように.gitignoreに必ず記載する！！！）

- dotenvをインストール

`Gemfile`
```ruby
group :development do
省略
  gem 'dotenv-rails'
end
```

```
$ bundle install --path vendor/bundle
```
- dotenvにIDとAppSecretを記述（開発環境用）

`.env`
```
FACEBOOK_ID_DEV={登録したアプリのID}
FACEBOOK_SECRET_DEV={登録したアプリのapp secret}
TWITTER_ID_DEV={登録したアプリのID}
TWITTER_SECRET_DEV={登録したアプリのapp secret}
```

- herokuにもIDとAppSecretを記述（本番環境用）

```bash
$ heroku config:add FACEBOOK_ID_PROD={登録したアプリのID}
$ heroku config:add FACEBOOK_SECRET_PROD={登録したアプリのapp secret}
$ heroku config:add TWITTER_ID_PROD={登録したアプリのID}
$ heroku config:add TWITTER_SECRET_PROD={登録したアプリのapp secret}
```

- SNSログインで必要なカラムをUsersテーブルに追加する

```bash
$ rails g migration AddOmniauthColumnsToUsers uid provider image_url
```

```ruby
class AddOmniauthColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uid, :string, null: false, default: ""
    add_column :users, :provider, :string, null: false, default: ""
    add_column :users, :image_url, :string

    add_index :users, [:uid, :provider], unique: true
  end
end
```

- マイグレーション

オプションで`null: false`を設定したので、`rake db:migrate`コマンドではなく`rake db:migrate:reset`コマンドを実行

- FacebookとTwitterのアクションを作成する

```bash
$ mkdir app/controllers/users
$ rails g controller users::OmniauthCallbacks
```

- OmniauthCallbacksControllerの継承元をApplicationControllerからDeviseのコールバックコントローラへ書き換える

`app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
end
```

- Facebookログイン用のメソッドを作成する

`app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
```

- `find_for_facebook_oauth`/`find_for_twitter_oauth`メソッドをuser.rbに定義する

`app/models/user.rb`

```ruby
class User < ActiveRecord::Base
#省略
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    unless user
      user = User.new(
          name:     auth.extra.raw_info.name,
          provider: auth.provider,
          uid:      auth.uid,
          email:    auth.info.email ||= "#{auth.uid}-#{auth.provider}@example.com",
          image_url:   auth.info.image,
          password: Devise.friendly_token[0, 20]
      )
      user.skip_confirmation!
      user.save(validate: false)
    end
    user
  end
end
```

`app/controllers/users/omniauth_callback_controller.rb`

```ruby
def twitter
  # You need to implement the method below in your model
  @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)

  if @user.persisted?
    set_flash_message(:notice, :success, kind: "Twitter") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication
  else
    session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
    redirect_to new_user_registration_url
  end
end
```

`app/models/user.rb`
```ruby
def self.find_for_twitter_oauth(auth, signed_in_resource = nil)
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    unless user
      user = User.new(
          name:     auth.info.nickname,
          image_url: auth.info.image,
          provider: auth.provider,
          uid:      auth.uid,
          email:    auth.info.email ||= "#{auth.uid}-#{auth.provider}@example.com",
          password: Devise.friendly_token[0, 20]
      )
      user.skip_confirmation!
      user.save
    end
    user
  end
```


- users/registration_controllerを作成して、deviseのコントローラーを継承する

```bash
$ rails g controller users::registrations
```

`app/controllers/users/registration_controller`
```ruby
class Users::RegistrationsController < Devise::RegistrationsController
  def build_resource(hash=nil)
    hash[:uid] = User.create_unique_string
    super
  end
end
```

- create_unique_stringメソッドを作成

`app/models/user.rb`
```ruby
def self.create_unique_string
  SecureRandom.uuid
end
```

- 継承したregistration_controllerにアクションが起動するようにする

`config/routes.rb`
```ruby
devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
}
```

- ユーザープロフィール用のcarrierwaveの初期設定を行う。

```bash
$ rails generate uploader Avatar
```

- ユーザープロフィール画像を保存するためのカラムを作成する
```bash
$ rails g migration add_avatar_to_users avatar:string
$ rake db:migrate
```

- userモデルに、carrierwave用の設定を行う

`app/models/user.rb`
```ruby
mount_uploader :avatar, AvatarUploader #deviseの設定配下に追記
```


- SNSログインから取得してきた画像を表示させるヘルパーメソッドを作成

`app/helpers/application_helper.rb`
```ruby
module ApplicationHelper
  # 省略
  def profile_img(user)
    unless user.provider.blank?
      img_url = user.image_url
    else
      img_url = 'no_image.png'
    end
    image_tag(img_url, alt: user.name)
  end
  # 省略
end
```

- ユーザー編集ページで画像をアップロードできるようにする

`app/controllers/application_controller.rb`
```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  #省略

   PERMISSIBLE_ATTRIBUTES = %i(name avatar avatar_cache)

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: PERMISSIBLE_ATTRIBUTES)
      devise_parameter_sanitizer.permit(:account_update, keys: PERMISSIBLE_ATTRIBUTES)
    end
end
```
`avatar avatar_cache` をPERMISSIBLE_ATTRIBUTESに追加する


`app/views/devise/registations/edit.html.erb`

```
<!-- 省略 -->
  <div class="field">
    <%= f.label :現在のパスワード %><br />
    <%= f.password_field :current_password, autocomplete: "off", class: "form-control" %>
  </div>

  <div class="field">
    <%= profile_img(@user) if profile_img(@user) %>
    <%= f.file_field :avatar %>
    <%= f.hidden_field :avatar_cache %>
  </div>

  <div class="actions">
    <%= f.submit "更新", class: "btn btn-primary btn-block" %>
  </div>
<% end %>
<!-- 省略 -->
```

- omniauthでサインアップしたアカウントのユーザ情報の変更出来るようにする

`app/models/user.rb`
```ruby
def update_with_password(params, *options)
  if provider.blank?
    super
  else
    params.delete :current_password
    update_without_password(params, *options)
  end
end
```
update_with_passwordをオーバーライドする。<br>
providerが空だった時は、superでupdate_with_passwordに記述されている内容を上書きし<br>
providerが存在する場合は、current_passwordを削除してパスワードなしでも更新できるようにする。


# viewを整える

- bootstrap導入

```bash
$ echo "gem 'twitter-bootstrap-rails'" >> Gemfile
$ rails generate bootstrap:install static
```

# その他gem

- gem 'pry-rails'
- gem 'better_errors'
