# mac-bootstrap

macOS のユーザー作成後に、開発環境を再現可能な形でセットアップするための bootstrap script を管理します。

このリポジトリは public です。個人情報、認証情報、秘密鍵、端末固有の設定値はコミットしません。コミット前の検査には [gitleaks](https://github.com/gitleaks/gitleaks) と [pre-commit](https://pre-commit.com/) を使用します。

## 開発準備

```sh
brew install gitleaks pre-commit
pre-commit install
```

全ファイルを検査する場合は、次を実行します。

```sh
pre-commit run --all-files
```
