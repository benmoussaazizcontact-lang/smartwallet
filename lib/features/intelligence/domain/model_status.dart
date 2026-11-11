/// Interprets a model-service payload. A missing service stays on the baseline.
String modelServiceLabel(Map<dynamic, dynamic>? payload) {
  if (payload == null) return 'awaiting_deployment';
  if (payload['executed'] == true || payload['blocks_transaction'] == true) return 'refused';
  final status = payload['status'];
  if (status == 'experimental' || status == 'fitted_on_request' || status == 'statistical_baseline' || status == 'awaiting_deployment') {
    return status as String;
  }
  return 'statistical_baseline';
}

/// Fields the studio shows for one deployed prediction. Unsafe payloads are refused.
class ModelServiceReport {
  const ModelServiceReport({
    required this.task,
    required this.status,
    required this.model,
    required this.version,
    required this.reason,
    required this.realWorldValidated,
  });

  final String task;
  final String status;
  final String model;
  final String version;
  final String reason;
  final bool realWorldValidated;

  String get summary =>
      '$task\nstatus: $status\nmodel: $model\nversion: $version\nreason: $reason\nreal_world_validated: $realWorldValidated';
}

ModelServiceReport modelServiceReport(String task, Object? payload) {
  if (payload is! Map) {
    return ModelServiceReport(
      task: task,
      status: 'awaiting_deployment',
      model: 'none',
      version: 'none',
      reason: 'missing_response',
      realWorldValidated: false,
    );
  }
  final data = Map<dynamic, dynamic>.from(payload);
  if (data['executed'] == true || data['blocks_transaction'] == true) {
    return ModelServiceReport(
      task: task,
      status: 'refused',
      model: 'none',
      version: 'none',
      reason: 'unsafe_response',
      realWorldValidated: false,
    );
  }
  final model = data['model'];
  final version = data['version'];
  final reason = data['reason'];
  return ModelServiceReport(
    task: task,
    status: modelServiceLabel(data),
    model: model is String && model.isNotEmpty ? model : 'none',
    version: version is String && version.isNotEmpty ? version : 'none',
    reason: reason is String && reason.isNotEmpty ? reason : 'none',
    realWorldValidated: data['real_world_validated'] == true,
  );
}

/// Maps a failed invocation to a visible baseline. The thirty on-device cards stay available.
ModelServiceReport modelServiceFailure(String task, {required int? status}) {
  if (status == 401) {
    return ModelServiceReport(
      task: task,
      status: 'statistical_baseline',
      model: 'none',
      version: 'none',
      reason: 'authentication_required',
      realWorldValidated: false,
    );
  }
  if (status == null) {
    return ModelServiceReport(
      task: task,
      status: 'statistical_baseline',
      model: 'none',
      version: 'none',
      reason: 'network_error',
      realWorldValidated: false,
    );
  }
  return ModelServiceReport(
    task: task,
    status: 'statistical_baseline',
    model: 'none',
    version: 'none',
    reason: 'model_service_unavailable',
    realWorldValidated: false,
  );
}
