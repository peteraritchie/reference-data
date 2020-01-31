choco upgrade hub
git config --global hub.protocol https
setlocal

set REPO=English
md %REPO% & cd %REPO%
md src & pushd src

md Extensions & cd Extensions
dotnet new classlib --framework netstandard2.0 --language C#
cd ..
md Words & cd Words
dotnet new classlib --framework netstandard2.0 --language C#
dotnet add reference ..\Extensions\Extensions.csproj
cd ..
md Tests & cd Tests
dotnet new xunit --framework netcoreapp3.1 --language C#
dotnet add reference ..\Words\Words.csproj
cd ..
dotnet new sln -n %REPO%
for /R %%i in (*.csproj) DO dotnet sln add %%i
dotnet restore

popd

git init
md .github
md .github\workflows
curl --output ".gitignore" https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore 
curl -O https://raw.githubusercontent.com/github/VisualStudio/master/.gitattributes
curl --output "license.md" https://raw.githubusercontent.com/OpenSourceOrg/licenses/master/texts/plain/LGPL-3.0
curl --output ".github\workflows\dotnetcore.yml"  https://raw.githubusercontent.com/peteraritchie/reference-data/master/github-workflows/dotnet22core-personal-prerelease.yml

:restart
for %%i in (%cd%) do echo # %%~ni > readme.md
echo[ >> readme.md
for %%i in (%cd%) do echo ![.NET Core](https://github.com/peteraritchie/%%~ni/workflows/.NET%%20Core/badge.svg?branch=dev) >> readme.md

md docs
echo # Doc > docs\readme.md

git add .
git commit -m "initial commit"

pause
hub create
git push -u origin HEAD

exit /b