import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/event_evaluator.dart';
import '../core/pipeline/pass_record.dart';
import '../core/signal/pcm.dart';

/// Complete evaluation of one event window as used by the offline analysis
/// and the live mode. Later stages (Doppler, fusion) hook in here.
class EventPipeline {
  EventPipeline({required this.config, required this.setup})
    : _evaluator = EventEvaluator(config: config, setup: setup);

  final NyooomConfig config;
  final AnalysisSetup setup;
  final EventEvaluator _evaluator;

  PassRecord evaluate(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) => _evaluator.evaluate(window, event, windowStartS: windowStartS);
}
