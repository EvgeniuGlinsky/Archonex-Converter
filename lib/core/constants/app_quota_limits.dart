/// How much converting the free tier includes.
///
/// Unlike everything in `AppFileLimits`, none of this is a technical bound.
/// The file *size* ceilings are the real maximum each platform can carry and
/// are offered in full — the product is gated by how many files are converted,
/// never by how large they are.
class AppQuotaLimits {
  const AppQuotaLimits._();

  /// Source files the free tier may convert per calendar month.
  ///
  /// Counted on the input rather than the output: a batch of five photos is
  /// five, and one PDF exploded into twelve pages is one. What the user handed
  /// over is what they can predict; how many files come back out is a property
  /// of the conversion they chose.
  static const int freeFilesPerMonth = 10;

  /// The subscription lifts the count entirely rather than raising it.
  ///
  /// Represented as its own name so no call site has to know that "unlimited"
  /// is spelled with a sentinel number.
  static const int unlimited = -1;
}
