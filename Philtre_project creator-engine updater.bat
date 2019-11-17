@echo off
cd .git
if errorlevel 1 (
	echo No git repository here, initializing...
	git init
) else (
	echo Git repository detected.
	cd..
)

if not exist philtre/nul (
	echo No philtre folder found, adding Philtre...
	git submodule add -b master https://github.com/JoshuaGrams/philtre2d.git philtre
	git commit -m "Add Philtre"
) else (
	echo Updating Philtre...
	git submodule update --remote --merge
)
echo.
pause