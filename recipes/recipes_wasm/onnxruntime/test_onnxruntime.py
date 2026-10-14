import base64
import os

import numpy as np
import pytest

# onnxruntime/python/datasets/mul_1.onnx
# Graph: Y = Mul(X, W) with W = [[1, 2], [3, 4], [5, 6]], float32, X shape (3, 2).
MUL_1_ONNX_B64 = "CAMSBmNoZW50YTpwChUKAVgKAVcSAVkaBW11bF8xIgNNdWwSCG11bCB0ZXN0KiMIAwgCEAEiGAAAgD8AAABAAABAQAAAgEAAAKBAAADAQEIBV1oTCgFYEg4KDAgBEggKAggDCgIIAmITCgFZEg4KDAgBEggKAggDCgIIAkIECgAQBw=="

MUL_1_W = np.array([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], dtype=np.float32)


def _model_path():
    path = os.path.join(os.getcwd(), "mul_1.onnx")
    with open(path, "wb") as fh:
        fh.write(base64.b64decode(MUL_1_ONNX_B64))
    return path


def test_import_and_version():
    import onnxruntime

    assert onnxruntime.__version__ == "1.31.0"
    assert callable(onnxruntime.get_available_providers)


def test_available_providers():
    import onnxruntime

    providers = onnxruntime.get_available_providers()
    assert isinstance(providers, list) and providers
    assert "CPUExecutionProvider" in providers


def test_inference_session_runs_mul_1():
    import onnxruntime

    sess = onnxruntime.InferenceSession(_model_path())
    x = np.array([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], dtype=np.float32)
    y = sess.run(None, {"X": x})[0]

    assert y.shape == (3, 2)
    assert y.dtype == np.float32
    assert np.allclose(y, x * MUL_1_W, atol=1e-5)


def test_session_options_roundtrip():
    import onnxruntime

    opts = onnxruntime.SessionOptions()
    opts.graph_optimization_level = onnxruntime.GraphOptimizationLevel.ORT_ENABLE_BASIC
    opts.intra_op_num_threads = 1
    sess = onnxruntime.InferenceSession(_model_path(), sess_options=opts)
    assert sess.get_inputs()[0].name == "X"
    assert sess.get_outputs()[0].name == "Y"


def test_invalid_model_raises_python_exception():
    """Catches must work in the side module: this is the observable check that
    WebAssembly exception catching is enabled (see contingency in the plan)."""
    import onnxruntime

    with pytest.raises(Exception):
        onnxruntime.InferenceSession(os.path.join(os.getcwd(), "does_not_exist.onnx"))
