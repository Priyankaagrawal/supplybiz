// T-172: native semantics/200% smoke; manual TalkBack journeys remain separate.
import 'package:integration_test/integration_test.dart';
import '../test/accessibility/audit_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerAccessibilityAudit(native: true);
}
