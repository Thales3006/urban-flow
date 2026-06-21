#include "tflite_predictor.h"

#include <vector>

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void TFLitePredictor::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_model", "path"), &TFLitePredictor::load_model);
	ClassDB::bind_method(D_METHOD("predict", "input"), &TFLitePredictor::predict);
	ClassDB::bind_method(D_METHOD("unload"), &TFLitePredictor::unload);
}

TFLitePredictor::TFLitePredictor() {}

TFLitePredictor::~TFLitePredictor() {
	unload();
}

void TFLitePredictor::unload() {
	if (interpreter != nullptr) {
		TfLiteInterpreterDelete(interpreter);
		interpreter = nullptr;
	}
	if (model != nullptr) {
		TfLiteModelDelete(model);
		model = nullptr;
	}
	model_bytes.clear();
}

bool TFLitePredictor::load_model(const String &p_path) {
	unload();

	Ref<FileAccess> file = FileAccess::open(p_path, FileAccess::ModeFlags::READ);
	if (file.is_null()) {
		UtilityFunctions::push_error("TFLitePredictor: could not open model file: " + p_path);
		return false;
	}
	model_bytes = file->get_buffer(file->get_length());
	file->close();

	model = TfLiteModelCreate(model_bytes.ptr(), model_bytes.size());
	if (model == nullptr) {
		UtilityFunctions::push_error("TFLitePredictor: failed to parse TFLite model: " + p_path);
		return false;
	}

	TfLiteInterpreterOptions *options = TfLiteInterpreterOptionsCreate();
	TfLiteInterpreterOptionsSetNumThreads(options, 2);
	interpreter = TfLiteInterpreterCreate(model, options);
	TfLiteInterpreterOptionsDelete(options);

	if (interpreter == nullptr) {
		UtilityFunctions::push_error("TFLitePredictor: failed to create interpreter for: " + p_path);
		unload();
		return false;
	}

	// Some models (e.g. exported with a dynamic batch dimension) report a
	// shape_signature with -1 placeholders that the C API does not
	// auto-resolve like the Python wrapper does. Only resize if a dim is
	// genuinely unresolved -- calling ResizeInputTensor unconditionally
	// (even to the tensor's own already-concrete shape) flips its
	// allocation type to dynamic and breaks the Mean/GlobalAveragePool
	// kernel's shape preconditions at invoke time.
	TfLiteTensor *input_tensor = TfLiteInterpreterGetInputTensor(interpreter, 0);
	if (input_tensor != nullptr) {
		int32_t num_dims = TfLiteTensorNumDims(input_tensor);
		bool needs_resize = false;
		std::vector<int> dims(num_dims);
		for (int32_t i = 0; i < num_dims; i++) {
			int32_t d = TfLiteTensorDim(input_tensor, i);
			if (d <= 0) {
				needs_resize = true;
			}
			dims[i] = d > 0 ? d : 1;
		}
		if (needs_resize) {
			TfLiteInterpreterResizeInputTensor(interpreter, 0, dims.data(), num_dims);
		}
	}

	if (TfLiteInterpreterAllocateTensors(interpreter) != kTfLiteOk) {
		UtilityFunctions::push_error("TFLitePredictor: failed to allocate tensors for: " + p_path);
		unload();
		return false;
	}

	return true;
}

PackedFloat32Array TFLitePredictor::predict(const PackedFloat32Array &p_input) {
	PackedFloat32Array result;

	if (interpreter == nullptr) {
		UtilityFunctions::push_error("TFLitePredictor: predict() called before a model was loaded");
		return result;
	}

	TfLiteTensor *input_tensor = TfLiteInterpreterGetInputTensor(interpreter, 0);
	if (input_tensor == nullptr) {
		UtilityFunctions::push_error("TFLitePredictor: model has no input tensor");
		return result;
	}

	size_t expected_bytes = TfLiteTensorByteSize(input_tensor);
	size_t given_bytes = (size_t)p_input.size() * sizeof(float);
	if (given_bytes != expected_bytes) {
		UtilityFunctions::push_error(
				"TFLitePredictor: input size mismatch, expected " + String::num_int64((int64_t)expected_bytes) +
				" bytes, got " + String::num_int64((int64_t)given_bytes));
		return result;
	}

	if (TfLiteTensorCopyFromBuffer(input_tensor, p_input.ptr(), given_bytes) != kTfLiteOk) {
		UtilityFunctions::push_error("TFLitePredictor: failed to copy input data into tensor");
		return result;
	}

	if (TfLiteInterpreterInvoke(interpreter) != kTfLiteOk) {
		UtilityFunctions::push_error("TFLitePredictor: inference invoke failed");
		return result;
	}

	const TfLiteTensor *output_tensor = TfLiteInterpreterGetOutputTensor(interpreter, 0);
	if (output_tensor == nullptr) {
		UtilityFunctions::push_error("TFLitePredictor: model has no output tensor");
		return result;
	}

	size_t output_bytes = TfLiteTensorByteSize(output_tensor);
	result.resize((int)(output_bytes / sizeof(float)));

	if (TfLiteTensorCopyToBuffer(output_tensor, result.ptrw(), output_bytes) != kTfLiteOk) {
		UtilityFunctions::push_error("TFLitePredictor: failed to copy output data from tensor");
		result.clear();
		return result;
	}

	return result;
}
