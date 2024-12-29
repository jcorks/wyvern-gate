#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/sprite2d.hpp>
#include <../../export-cli/matte/src/matte.h>

namespace godot {

class Matte : public Node2D {
	GDCLASS(Matte, Node2D)

private:
	double time_passed;
	matte_t * ctx;
	matteValue_t sendInputMatteCall;

protected:
	static void _bind_methods();

public:
	Matte();
	~Matte();


	void initializeVM();
	void sendInput(int input);
	void sendLine(int index, const std::string & line);
	void sendError(const std::string & line);
	void sendSettings(const std::string & line);
	void enableDebugging();
	void requestExit();

	void _process(double delta) override;
};

}

#endif