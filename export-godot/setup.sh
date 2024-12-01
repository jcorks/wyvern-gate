cd ./godot-cpp/
git clone https://github.com/godotengine/godot-cpp
cd ./godot-cpp/
git checkout godot-4.3-stable
cd ../
mv ./godot-cpp/* ./
mv ./godot-cpp/.* ./
scons platform="windows" custom_api_file="../extension_api.json"
