from unittest.mock import patch
from unittest.mock import MagicMock
import service


def client():
    service.app.config["TESTING"] = True
    return service.app.test_client()


def test_predict_toxic_true():
    assert service.predict_toxic("you are an idiot") is True


def test_predict_toxic_false():
    assert service.predict_toxic("you are a good man") is False


def test_get_predict_toxic():
    resp = client().get("/predict?text=you+are+an+idiot")
    assert resp.status_code == 200
    assert resp.get_json()["is_toxic"] is True


def test_get_predict_good():
    resp = client().get("/predict?text=you+are+a+good+mann")
    assert resp.status_code == 200
    assert resp.get_json()["is_toxic"] is False


def test_post_predict():
    resp = client().post("/predict", json={"text": "you are a good man"})
    assert resp.status_code == 200
    assert "is_toxic" in resp.get_json()
    assert resp.get_json()["is_toxic"] is False


def test_metrics():
    c = client()
    c.get("/predict?text=test")
    resp = c.get("/metrics")
    assert resp.status_code == 200
    assert b"app_http_inference_count_total" in resp.data


@patch("service.app.run")
def test_run_http(mock_run):
    service.run_http()
    mock_run.assert_called_once_with(host="0.0.0.0", port=5000)


@patch("service.grpc.server")
def test_run_grpc(mock_grpc_server):

    mock_server = MagicMock()
    mock_grpc_server.return_value = mock_server
    mock_server.wait_for_termination.side_effect = KeyboardInterrupt
    try:
        service.run_grpc()
    except KeyboardInterrupt:
        pass
    mock_server.start.assert_called_once()
    mock_server.add_insecure_port.assert_called_once_with("[::]:50051")
