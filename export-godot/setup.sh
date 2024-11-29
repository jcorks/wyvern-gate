cd ./godot-cpp/
git clone https://github.com/godotengine/godot-cpp
mv ./godot-cpp/* ./
git checkout godot-4.3-stable
scons platform=windows custom_api_file=./extensin_api.json
