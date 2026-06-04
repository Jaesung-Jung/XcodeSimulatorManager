import SimControlDomain

extension SimulatorRepository {
  func keyedByID<Value: Identifiable>(_ values: [Value]) -> [String: Value] where Value.ID == String {
    var result: [String: Value] = [:]
    for value in values where result[value.id] == nil {
      result[value.id] = value
    }
    return result
  }

  func warning(
    id: String,
    severity: SimulatorWarning.Severity,
    category: SimulatorWarning.Category,
    message: String,
    relatedID: String?
  ) -> SimulatorWarning {
    SimulatorWarning(
      id: id,
      severity: severity,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }
}
