/// Outcome of a save attempt, so the caller can tell a cancelled dialog from a
/// download that the platform cannot name.
enum SaveOutcome { cancelled, savedToLocation, downloadStarted }

/// What came of handing one or more results to the platform.
class SaveResult {
  const SaveResult({
    required this.outcome,
    this.location,
    this.savedCount = 1,
  });

  /// Nothing left the app: the user closed the dialog.
  const SaveResult.cancelled()
      : outcome = SaveOutcome.cancelled,
        location = null,
        savedCount = 0;

  final SaveOutcome outcome;

  /// Set only when [outcome] is [SaveOutcome.savedToLocation].
  final String? location;

  /// How many files actually landed. Always `1` for a single save; a batch
  /// reports the count so the confirmation can be specific.
  final int savedCount;
}
