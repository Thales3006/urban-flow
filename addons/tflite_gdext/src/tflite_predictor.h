#ifndef TFLITE_PREDICTOR_H
#define TFLITE_PREDICTOR_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include "tensorflow/lite/c/c_api.h"

namespace godot {

class TFLitePredictor : public RefCounted {
	GDCLASS(TFLitePredictor, RefCounted)

private:
	// TfLiteModelCreate() does NOT copy the buffer it's given -- the
	// FlatBufferModel it builds keeps a non-owning view into it, so this
	// must stay alive for as long as `model`/`interpreter` do.
	PackedByteArray model_bytes;
	TfLiteModel *model = nullptr;
	TfLiteInterpreter *interpreter = nullptr;

protected:
	static void _bind_methods();

public:
	TFLitePredictor();
	~TFLitePredictor();

	bool load_model(const String &p_path);
	PackedFloat32Array predict(const PackedFloat32Array &p_input);
	void unload();
};

} // namespace godot

#endif // TFLITE_PREDICTOR_H
