# mac-bootstrap

macOS のユーザー作成後に、開発環境を再現可能な形でセットアップするための bootstrap script を管理します。

## マシン単位のセットアップ

Homebrewの所有者がMacごとに1回だけ実行します。Homebrewが未導入の場合は、[公式のインストーラー](https://docs.brew.sh/Installation)を実行します。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

続けて、リポジトリのルートでアプリとCLIをインストールします。

```sh
brew bundle --file ./Brewfile
```

`Brewfile`でインストールするアプリは`/Applications`に配置され、Macのユーザー間で共有されます。アプリの初回起動、ログイン、権限付与は各ユーザーが行います。

## ユーザー単位のセットアップ

各OSユーザーは、Macに対応するHomebrewの設定を`~/.zprofile`に追加します。

Apple Siliconの場合:

```sh
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Intel Macの場合:

```sh
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

その後、ユーザーごとのOh My ZshとmacOS設定を適用します。`apply.sh`はHomebrewのインストール、更新、所有権変更、`Brewfile`の適用を行いません。既存の`~/.zshrc`は保持します。

```sh
./apply.sh
```

キーリピート速度とリピート開始までの待ち時間は、システム設定で選択できる最速値に設定されます。

Caps Lockキーは、接続中のキーボードごとにControlキーへ割り当てられます。新しいキーボードを追加した場合は、`apply.sh`をもう一度実行してください。

## 開発準備

```sh
brew install gitleaks pre-commit
pre-commit install
```

全ファイルを検査する場合は、次を実行します。

```sh
pre-commit run --all-files
```
