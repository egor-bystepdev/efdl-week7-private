from concurrent import futures
import grpc
import pytest
import inference_pb2
import inference_pb2_grpc
import service


@pytest.fixture(scope="module")
def grpc_stub():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=2))

    class Servicer(inference_pb2_grpc.TextClassifierServicer):
        def Predict(self, req, context):
            return inference_pb2.TextClassificationOutput(
                is_toxic=service.predict_toxic(req.text)
            )

    inference_pb2_grpc.add_TextClassifierServicer_to_server(Servicer(), server)
    port = server.add_insecure_port("[::]:0")
    server.start()
    channel = grpc.insecure_channel(f"localhost:{port}")
    yield inference_pb2_grpc.TextClassifierStub(channel)
    channel.close()
    server.stop(0)


def test_grpc_toxic_true(grpc_stub):
    resp = grpc_stub.Predict(
        inference_pb2.TextClassificationInput(text="you are an idiot")
    )
    assert resp.is_toxic is True


def test_grpc_toxic_false(grpc_stub):
    resp = grpc_stub.Predict(
        inference_pb2.TextClassificationInput(text="you are a good man")
    )
    assert resp.is_toxic is False
