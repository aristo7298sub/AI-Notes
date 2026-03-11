<#
.SYNOPSIS
    交互式创建新文章，基于模板自动生成文件。
.DESCRIPTION
    选择文章类型 → 输入标题和标签 → 自动生成文件到对应目录。
.EXAMPLE
    .\_scripts\new-article.ps1
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 文章类型映射
$types = [ordered]@{
    '1' = @{ Name = 'Deep Dive (原创深度解析)';       Template = 'deep-dive.md';              Dir = 'deep-dives' }
    '2' = @{ Name = 'Commentary (双语解读)';           Template = 'bilingual-commentary.md';   Dir = 'commentaries' }
    '3' = @{ Name = 'Insight (随笔/观点)';             Template = 'insight.md';                Dir = 'insights' }
    '4' = @{ Name = 'Learning Note - Paper (论文)';    Template = 'learning-note.md';          Dir = 'learning-notes/papers' }
    '5' = @{ Name = 'Learning Note - Course (课程)';   Template = 'learning-note.md';          Dir = 'learning-notes/courses' }
    '6' = @{ Name = 'Learning Note - Book (书籍)';     Template = 'learning-note.md';          Dir = 'learning-notes/books' }
    '7' = @{ Name = 'Tool Guide (工具教程)';           Template = 'tool-guide.md';             Dir = 'tool-guides' }
    '8' = @{ Name = 'Project Practice (项目实践)';     Template = 'project-practice.md';       Dir = 'projects' }
}

Write-Host "`n=== AI Notes - 新建文章 ===" -ForegroundColor Cyan
Write-Host ""
foreach ($key in $types.Keys) {
    Write-Host "  $key. $($types[$key].Name)"
}
Write-Host ""
$choice = Read-Host "选择文章类型 (1-8)"

if (-not $types.ContainsKey($choice)) {
    Write-Host "无效选择，退出。" -ForegroundColor Red
    exit 1
}

$selected = $types[$choice]

$title = Read-Host "文章标题"
if ([string]::IsNullOrWhiteSpace($title)) {
    Write-Host "标题不能为空，退出。" -ForegroundColor Red
    exit 1
}

$tagsInput = Read-Host "标签 (逗号分隔, 如: AI, LLM, Agent)"
$tags = ($tagsInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join ', '

# 生成文件名: 小写、空格/特殊字符转连字符
$fileName = ($title -replace '[^\w\s-]', '' -replace '\s+', '-').Trim('-')
# 如果标题全是中文，用拼音首字母或保留原样
if ($fileName -eq '') {
    $fileName = "article-$(Get-Date -Format 'yyyyMMdd-HHmm')"
}
$fileName = "$fileName.md"

$targetDir = Join-Path $root $selected.Dir
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
$targetPath = Join-Path $targetDir $fileName

if (Test-Path $targetPath) {
    Write-Host "文件已存在: $targetPath" -ForegroundColor Red
    exit 1
}

# 读取模板并替换占位符
$templatePath = Join-Path $root "_templates" $selected.Template
$content = Get-Content $templatePath -Raw -Encoding UTF8

$today = Get-Date -Format 'yyyy-MM-dd'
$content = $content -replace '\{\{DATE\}\}', $today
$content = $content -replace 'title: ".*?"', "title: `"$title`""
$content = $content -replace 'tags: \[.*?\]', "tags: [$tags]"

# 替换正文标题
$content = $content -replace '(?m)^# .+$', "# $title"

# 学习笔记子分类
if ($choice -in '4','5','6') {
    $subCat = switch ($choice) { '4' { 'papers' } '5' { 'courses' } '6' { 'books' } }
    $content = $content -replace 'sub-category: \w+', "sub-category: $subCat"
}

$content | Set-Content $targetPath -Encoding UTF8

Write-Host "`n✅ 文章已创建: $targetPath" -ForegroundColor Green
Write-Host "   模板: $($selected.Template)" -ForegroundColor DarkGray
Write-Host "   标签: [$tags]" -ForegroundColor DarkGray
