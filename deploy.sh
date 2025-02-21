#!/bin/bash

# Flutter 웹 빌드
echo "🔨 Building Flutter web app..."
flutter build web --base-href "/oz_text_converter_web/"

# gh-pages 브랜치로 전환
echo "🔄 Switching to gh-pages branch..."
git checkout -B gh-pages

# 빌드된 웹 파일들을 루트로 이동
echo "📦 Moving build files..."
cp -R build/web/* .

# 파일 추가 및 커밋
echo "📝 Committing changes..."
git add .
git commit -m "Deploy web app to GitHub Pages"

# GitHub에 푸시
echo "🚀 Pushing to GitHub..."
git push -f origin gh-pages

# 원래 브랜치로 돌아가기
echo "🔙 Switching back to original branch..."
git checkout -

echo "✅ Deployment complete!" 